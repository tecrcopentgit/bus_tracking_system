from tests.conftest import login

API = "/api/v1"


def admin_headers(client):
    return login(client, "admin@example.com", "admin12345")


def test_admin_endpoints_reject_regular_users_and_anonymous(client, alice):
    for method, path in (
        ("get", "/admin/overview"), ("get", "/admin/users"), ("get", "/admin/routes"),
        ("get", "/admin/vehicles"), ("post", "/admin/vehicles"), ("post", "/admin/routes"),
    ):
        assert getattr(client, method)(f"{API}{path}", headers=alice).status_code == 403, path
        assert getattr(client, method)(f"{API}{path}").status_code == 401, path


def test_overview_counts(client):
    h = admin_headers(client)
    o = client.get(f"{API}/admin/overview", headers=h).json()
    assert o["total_vehicles"] >= 3 and o["total_routes"] >= 2
    assert len(o["vehicles"]) == o["total_vehicles"]
    assert o["moving"] + o["idle"] + o["offline"] + o["no_data"] == o["active_vehicles"]
    assert {v["code"] for v in o["vehicles"]} >= {"BUS-001", "BUS-002", "BUS-003"}


def test_user_management(client):
    h = admin_headers(client)
    body = {"full_name": "Erin Admin-Made", "email": "Erin@Example.com", "password": "longpassword1"}
    r = client.post(f"{API}/admin/users", headers=h, json=body)
    assert r.status_code == 201 and r.json()["email"] == "erin@example.com"
    uid = r.json()["id"]
    assert client.post(f"{API}/admin/users", headers=h, json=body).status_code == 409

    # created already assigned
    r2 = client.post(f"{API}/admin/users", headers=h, json={
        "full_name": "Frank Assigned", "email": "frank@example.com", "password": "longpassword1",
        "route_id": 2, "vehicle_id": 2})
    assert r2.json()["route_name"] == "Route B" and r2.json()["vehicle_code"] == "BUS-002"
    # inconsistent pair rejected
    bad = client.post(f"{API}/admin/users", headers=h, json={
        "full_name": "Gina Bad", "email": "gina@example.com", "password": "longpassword1",
        "route_id": 1, "vehicle_id": 2})
    assert bad.status_code == 422

    # search
    found = client.get(f"{API}/admin/users", params={"q": "erin"}, headers=h).json()
    assert [u["email"] for u in found] == ["erin@example.com"]

    # assign / unassign
    ok = client.put(f"{API}/admin/users/{uid}/assignment", headers=h, json={"route_id": 1, "vehicle_id": 3})
    assert ok.json()["vehicle_code"] == "BUS-003"
    erin = login(client, "erin@example.com", "longpassword1")
    assert client.get(f"{API}/me/vehicle", headers=erin).json()["code"] == "BUS-003"
    cleared = client.delete(f"{API}/admin/users/{uid}/assignment", headers=h).json()
    assert cleared["route_id"] is None
    assert client.get(f"{API}/me/vehicle", headers=erin).status_code == 404

    # deactivate: existing token stops working and login is refused
    assert client.patch(f"{API}/admin/users/{uid}", headers=h, json={"is_active": False}).json()["is_active"] is False
    assert client.get(f"{API}/me", headers=erin).status_code == 401
    assert client.post(f"{API}/auth/login", json={"email": "erin@example.com", "password": "longpassword1"}).status_code == 401
    # reactivate + password reset
    client.patch(f"{API}/admin/users/{uid}", headers=h, json={"is_active": True, "password": "brandnewpass1"})
    assert client.post(f"{API}/auth/login", json={"email": "erin@example.com", "password": "brandnewpass1"}).status_code == 200


def test_admin_cannot_lock_themselves_out(client):
    h = admin_headers(client)
    me = client.get(f"{API}/me", headers=h).json()
    assert me["is_admin"] is True
    assert client.patch(f"{API}/admin/users/{me['id']}", headers=h, json={"is_active": False}).status_code == 400
    assert client.patch(f"{API}/admin/users/{me['id']}", headers=h, json={"is_admin": False}).status_code == 400


def test_route_crud(client):
    h = admin_headers(client)
    stops = [{"name": "A", "latitude": 12.9, "longitude": 80.1}, {"name": "B", "latitude": 13.0, "longitude": 80.2}]
    r = client.post(f"{API}/admin/routes", headers=h, json={"name": "Route Z", "description": "test", "stops": stops})
    assert r.status_code == 201 and [s["sequence"] for s in r.json()["stops"]] == [1, 2]
    rid = r.json()["id"]
    assert client.post(f"{API}/admin/routes", headers=h, json={"name": "Route Z", "stops": stops}).status_code == 409
    assert client.post(f"{API}/admin/routes", headers=h, json={"name": "One stop", "stops": stops[:1]}).status_code == 422

    upd = client.put(f"{API}/admin/routes/{rid}", headers=h, json={
        "name": "Route Z2", "description": "x", "stops": stops + [{"name": "C", "latitude": 13.1, "longitude": 80.3}]})
    assert upd.status_code == 200 and len(upd.json()["stops"]) == 3 and upd.json()["name"] == "Route Z2"

    # a vehicle on it blocks deletion
    v = client.post(f"{API}/admin/vehicles", headers=h, json={"code": "bus-900", "plate_number": "X-1", "route_id": rid})
    assert v.status_code == 201 and v.json()["code"] == "BUS-900" and v.json()["status"] == "no_data"
    assert client.delete(f"{API}/admin/routes/{rid}", headers=h).status_code == 409
    # ...but is deletable once unused (move the vehicle away first)
    assert client.patch(f"{API}/admin/vehicles/{v.json()['id']}", headers=h, json={"route_id": 1}).status_code == 200
    assert client.delete(f"{API}/admin/routes/{rid}", headers=h).status_code == 204


def test_vehicle_management_and_ingest_rules(client):
    h = admin_headers(client)
    assert client.post(f"{API}/admin/vehicles", headers=h, json={"code": "BUS-001", "route_id": 1}).status_code == 409
    assert client.post(f"{API}/admin/vehicles", headers=h, json={"code": "NEW-1", "route_id": 999}).status_code == 404
    v = client.post(f"{API}/admin/vehicles", headers=h, json={"code": "NEW-1", "route_id": 2}).json()

    # GPS accepted for an active vehicle, then rejected once deactivated
    key = {"X-Device-Key": "dev-device-key"}
    fix = {"vehicle_id": "NEW-1", "latitude": 12.9, "longitude": 80.1, "speed": 20}
    assert client.post(f"{API}/gps", json=fix, headers=key).status_code == 202
    loc = client.get(f"{API}/admin/vehicles/{v['id']}/location", headers=h).json()
    assert loc["status"] == "moving" and loc["latitude"] == 12.9
    assert client.get(f"{API}/admin/vehicles/{v['id']}/history", headers=h).json()["count"] == 1
    client.patch(f"{API}/admin/vehicles/{v['id']}", headers=h, json={"is_active": False})
    fix2 = {**fix, "latitude": 12.91}
    assert client.post(f"{API}/gps", json=fix2, headers=key).status_code == 404

    # cannot move a vehicle to another route while users ride it
    assert client.patch(f"{API}/admin/vehicles/2", headers=h, json={"route_id": 1}).status_code == 409
