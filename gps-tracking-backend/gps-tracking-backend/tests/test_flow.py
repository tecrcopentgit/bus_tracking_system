from tests.conftest import login
import json
from datetime import datetime, timedelta, timezone

from app.services.mqtt_client import process_message

API = "/api/v1"


def publish(code, lat, lon, speed, ts, topic_code=None):
    payload = {"latitude": lat, "longitude": lon, "speed": speed, "timestamp": ts.isoformat()}
    return process_message(f"vehicles/{topic_code or code}/gps", json.dumps(payload).encode())


# ---------------- authentication ----------------
def test_login_rejects_bad_credentials(client):
    r = client.post(f"{API}/auth/login", json={"email": "alice@example.com", "password": "nope"})
    assert r.status_code == 401
    r = client.post(f"{API}/auth/login", json={"email": "ghost@example.com", "password": "x"})
    assert r.status_code == 401


def test_protected_endpoints_need_a_valid_token(client):
    assert client.get(f"{API}/me").status_code == 401
    assert client.get(f"{API}/me", headers={"Authorization": "Bearer garbage"}).status_code == 401


# ---------------- assignment + authorization ----------------
def test_each_user_sees_only_their_route_and_vehicle(client, alice, bob, carol):
    a = client.get(f"{API}/me/route", headers=alice).json()
    b = client.get(f"{API}/me/route", headers=bob).json()
    assert a["name"] == "Route A" and b["name"] == "Route B"
    assert len(a["stops"]) == 6 and a["stops"][0]["sequence"] == 1

    assert client.get(f"{API}/me/vehicle", headers=alice).json()["code"] == "BUS-001"
    assert client.get(f"{API}/me/vehicle", headers=bob).json()["code"] == "BUS-002"
    # Carol shares Route A with Alice but rides a different bus.
    assert client.get(f"{API}/me/route", headers=carol).json()["name"] == "Route A"
    assert client.get(f"{API}/me/vehicle", headers=carol).json()["code"] == "BUS-003"


def test_cross_user_access_is_forbidden_by_the_backend(client, alice, bob):
    bob_vehicle = client.get(f"{API}/me/vehicle", headers=bob).json()
    bob_route = client.get(f"{API}/me/route", headers=bob).json()
    for path in (
        f"/vehicles/{bob_vehicle['id']}",
        f"/vehicles/{bob_vehicle['id']}/location",
        f"/vehicles/{bob_vehicle['id']}/history",
        f"/routes/{bob_route['id']}",
        "/vehicles/99999",  # non-existent looks identical (no id enumeration)
    ):
        assert client.get(f"{API}{path}", headers=alice).status_code == 403, path
    # ...while the owner is fine.
    assert client.get(f"{API}/vehicles/{bob_vehicle['id']}", headers=bob).status_code == 200


# ---------------- GPS ingestion ----------------
def test_no_data_state_before_first_fix(client, bob):
    loc = client.get(f"{API}/me/vehicle/location", headers=bob).json()
    assert loc["status"] == "no_data" and loc["latitude"] is None
    assert client.get(f"{API}/me/vehicle", headers=bob).json()["status"] == "no_data"


def test_mqtt_ingest_latest_history_and_isolation(client, alice, bob):
    now = datetime.now(timezone.utc)
    assert publish("BUS-001", 12.95, 80.14, 30.0, now - timedelta(seconds=20))
    assert publish("BUS-001", 12.96, 80.15, 35.0, now - timedelta(seconds=10))
    assert publish("BUS-001", 12.97, 80.16, 40.0, now)

    loc = client.get(f"{API}/me/vehicle/location", headers=alice).json()
    assert (loc["latitude"], loc["longitude"], loc["speed"]) == (12.97, 80.16, 40.0)
    assert loc["status"] == "moving" and loc["vehicle_code"] == "BUS-001"

    hist = client.get(f"{API}/me/vehicle/history", headers=alice).json()
    assert hist["count"] == 3
    assert [p["latitude"] for p in hist["points"]] == [12.95, 12.96, 12.97]  # oldest -> newest

    limited = client.get(f"{API}/me/vehicle/history?limit=2", headers=alice).json()
    assert [p["latitude"] for p in limited["points"]] == [12.96, 12.97]  # newest 2

    start = (now - timedelta(seconds=15)).isoformat()
    ranged = client.get(f"{API}/me/vehicle/history", params={"start": start}, headers=alice).json()
    assert ranged["count"] == 2

    # Bob's bus got nothing: Alice's data never leaks across vehicles.
    assert client.get(f"{API}/me/vehicle/location", headers=bob).json()["status"] == "no_data"


def test_out_of_order_and_duplicate_fixes(client, alice):
    now = datetime.now(timezone.utc)
    before = client.get(f"{API}/me/vehicle/history", headers=alice).json()["count"]

    assert publish("BUS-001", 1.0, 1.0, 5.0, now - timedelta(hours=1))  # stored in history
    loc = client.get(f"{API}/me/vehicle/location", headers=alice).json()
    assert loc["latitude"] == 12.97  # latest NOT moved backwards

    assert not publish("BUS-001", 1.0, 1.0, 5.0, now - timedelta(hours=1))  # duplicate
    after = client.get(f"{API}/me/vehicle/history", headers=alice).json()["count"]
    assert after == before + 1


def test_stale_fix_is_offline_and_slow_is_idle(client, carol):
    now = datetime.now(timezone.utc)
    publish("BUS-003", 13.0, 80.2, 0.0, now)
    assert client.get(f"{API}/me/vehicle/location", headers=carol).json()["status"] == "idle"
    publish("BUS-003", 13.0, 80.2, 0.0, now + timedelta(seconds=1))  # keep newest fresh
    # An old-only vehicle is offline: verify with a vehicle whose newest fix is stale.
    from app.db.session import SessionLocal
    from app.models import VehicleLatestLocation
    with SessionLocal() as db:
        row = db.query(VehicleLatestLocation).filter_by(vehicle_id=3).one()
        row.recorded_at = now - timedelta(minutes=10)
        db.commit()
    assert client.get(f"{API}/me/vehicle/location", headers=carol).json()["status"] == "offline"


def test_invalid_messages_are_rejected(client):
    now = datetime.now(timezone.utc)
    assert not publish("BUS-999", 1, 1, 1, now)                         # unknown vehicle
    assert not process_message("vehicles/BUS-001/gps", b"not json")
    assert not process_message("vehicles/BUS-001/gps", json.dumps({"latitude": 999, "longitude": 0}).encode())
    assert not process_message("other/topic", b"{}")
    mismatch = {"vehicle_id": "BUS-002", "latitude": 1, "longitude": 1, "timestamp": now.isoformat()}
    assert not process_message("vehicles/BUS-001/gps", json.dumps(mismatch).encode())
    future = {"latitude": 1, "longitude": 1, "timestamp": (now + timedelta(days=1)).isoformat()}
    assert not process_message("vehicles/BUS-001/gps", json.dumps(future).encode())


def test_rest_ingest_requires_device_key(client, bob):
    body = {"vehicle_id": "BUS-002", "latitude": 12.9, "longitude": 80.1, "speed": 12}
    assert client.post(f"{API}/gps", json=body).status_code == 422          # header missing
    assert client.post(f"{API}/gps", json=body, headers={"X-Device-Key": "wrong"}).status_code == 401
    ok = client.post(f"{API}/gps", json=body, headers={"X-Device-Key": "dev-device-key"})
    assert ok.status_code == 202 and ok.json() == {"stored": True}
    assert client.get(f"{API}/me/vehicle/location", headers=bob).json()["latitude"] == 12.9
    unknown = {**body, "vehicle_id": "NOPE"}
    assert client.post(f"{API}/gps", json=unknown, headers={"X-Device-Key": "dev-device-key"}).status_code == 404


# ---------------- registration + admin assignment ----------------
def test_register_then_admin_assigns(client, alice):
    body = {"full_name": "Dave Tester", "email": "Dave@Example.com", "password": "s3cretpass"}
    r = client.post(f"{API}/auth/register", json=body)
    assert r.status_code == 201
    dave = {"Authorization": f"Bearer {r.json()['access_token']}"}

    # Same email (case-insensitive) is rejected.
    assert client.post(f"{API}/auth/register", json=body).status_code == 409
    # Weak password / bad email are rejected.
    assert client.post(f"{API}/auth/register", json={**body, "email": "x@y.zz", "password": "short"}).status_code == 422
    assert client.post(f"{API}/auth/register", json={**body, "email": "not-an-email"}).status_code == 422

    me = client.get(f"{API}/me", headers=dave).json()
    assert me["email"] == "dave@example.com" and me["route_id"] is None and not me["is_admin"]
    # Nothing assigned yet -> sees nothing.
    assert client.get(f"{API}/me/route", headers=dave).status_code == 404
    assert client.get(f"{API}/me/vehicle", headers=dave).status_code == 404

    # Regular users cannot use admin endpoints.
    assert client.get(f"{API}/admin/users", headers=alice).status_code == 403
    assert client.put(f"{API}/admin/users/{me['id']}/assignment", headers=dave,
                      json={"route_id": 1, "vehicle_id": 1}).status_code == 403

    admin = login(client, "admin@example.com", "admin12345")
    assert any(u["email"] == "dave@example.com" for u in client.get(f"{API}/admin/users", headers=admin).json())
    # Vehicle 2 (BUS-002) runs Route B, so pairing it with Route A (id 1) is invalid.
    bad = client.put(f"{API}/admin/users/{me['id']}/assignment", headers=admin, json={"route_id": 1, "vehicle_id": 2})
    assert bad.status_code == 422
    ok = client.put(f"{API}/admin/users/{me['id']}/assignment", headers=admin, json={"route_id": 2, "vehicle_id": 2})
    assert ok.status_code == 200

    assert client.get(f"{API}/me/route", headers=dave).json()["name"] == "Route B"
    assert client.get(f"{API}/me/vehicle", headers=dave).json()["code"] == "BUS-002"
    # ...and still cannot see Alice's bus.
    assert client.get(f"{API}/vehicles/1", headers=dave).status_code == 403
