"""GPS simulator: drives each seeded bus back and forth along its route and
publishes a fix to MQTT every few seconds.

    python -m simulator.simulator --host localhost --interval 2          # via MQTT broker
    python -m simulator.simulator --rest http://localhost:8001            # no broker needed (REST)
"""
import argparse
import json
import math
import os
import random
import time
import urllib.error
import urllib.request
from datetime import datetime, timezone
from pathlib import Path

import paho.mqtt.client as mqtt

SEED_FILE = Path(__file__).resolve().parents[1] / "data" / "seed.json"


def haversine_km(a, b) -> float:
    (lat1, lon1), (lat2, lon2) = a, b
    p1, p2 = math.radians(lat1), math.radians(lat2)
    dphi, dlmb = p2 - p1, math.radians(lon2 - lon1)
    h = math.sin(dphi / 2) ** 2 + math.cos(p1) * math.cos(p2) * math.sin(dlmb / 2) ** 2
    return 2 * 6371.0 * math.asin(math.sqrt(h))


class SimVehicle:
    def __init__(self, code: str, stops: list[dict], base_speed: float, start: float):
        self.code = code
        self.base_speed = base_speed
        self.path = [(s["latitude"], s["longitude"]) for s in stops]
        self.segments = [haversine_km(a, b) for a, b in zip(self.path, self.path[1:])]
        self.total = sum(self.segments)
        self.distance = start * self.total
        self.direction = 1

    def position(self) -> tuple[float, float]:
        remaining = self.distance
        for (a, b), length in zip(zip(self.path, self.path[1:]), self.segments):
            if remaining <= length or (a, b) == (self.path[-2], self.path[-1]):
                t = min(1.0, remaining / length) if length else 0.0
                return a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t
            remaining -= length
        return self.path[-1]

    def step(self, dt: float) -> tuple[float, float, float]:
        speed = max(0.0, random.gauss(self.base_speed, 4.0))
        self.distance += self.direction * speed * dt / 3600.0
        if self.distance >= self.total:
            self.distance, self.direction = self.total, -1
        elif self.distance <= 0:
            self.distance, self.direction = 0.0, 1
        lat, lon = self.position()
        # ~3 m of GPS jitter
        return lat + random.gauss(0, 2.5e-5), lon + random.gauss(0, 2.5e-5), speed


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--host", default=os.getenv("MQTT_HOST", "localhost"))
    ap.add_argument("--port", type=int, default=int(os.getenv("MQTT_PORT", "1883")))
    ap.add_argument("--interval", type=float, default=2.0, help="seconds between fixes")
    ap.add_argument("--speed", type=float, default=35.0, help="average km/h")
    ap.add_argument("--time-scale", type=float, default=10.0,
                    help="simulated seconds per real second (makes buses visibly move)")
    ap.add_argument("--vehicles", nargs="*", help="only simulate these codes")
    ap.add_argument("--rest", metavar="API_URL", help="send fixes to POST API_URL/api/v1/gps instead of MQTT")
    ap.add_argument("--device-key", default=os.getenv("DEVICE_API_KEY", "dev-device-key"))
    args = ap.parse_args()

    data = json.loads(SEED_FILE.read_text())
    routes = {r["name"]: r["stops"] for r in data["routes"]}
    fleet = [
        SimVehicle(v["code"], routes[v["route"]], args.speed, start=random.random())
        for v in data["vehicles"]
        if not args.vehicles or v["code"] in args.vehicles
    ]

    client = None
    if not args.rest:
        client = mqtt.Client(mqtt.CallbackAPIVersion.VERSION2, client_id="gps-simulator")
        while True:
            try:
                client.connect(args.host, args.port, keepalive=30)
                break
            except OSError as exc:
                print(f"Broker {args.host}:{args.port} not ready ({exc}); retrying in 2s")
                time.sleep(2)
        client.loop_start()
        print(f"Simulating {[v.code for v in fleet]} -> MQTT {args.host}:{args.port}")
    else:
        print(f"Simulating {[v.code for v in fleet]} -> REST {args.rest}/api/v1/gps")

    def send(payload: dict) -> None:
        if client is not None:
            client.publish(f"vehicles/{payload['vehicle_id']}/gps", json.dumps(payload), qos=1)
            return
        req = urllib.request.Request(
            f"{args.rest.rstrip('/')}/api/v1/gps",
            data=json.dumps(payload).encode(),
            headers={"Content-Type": "application/json", "X-Device-Key": args.device_key},
            method="POST",
        )
        try:
            urllib.request.urlopen(req, timeout=5).read()
        except (urllib.error.URLError, OSError) as exc:
            print(f"  ! could not reach API ({exc}); will retry")

    try:
        while True:
            for bus in fleet:
                lat, lon, speed = bus.step(args.interval * args.time_scale)
                payload = {
                    "vehicle_id": bus.code,
                    "latitude": round(lat, 6),
                    "longitude": round(lon, 6),
                    "speed": round(speed, 1),
                    "timestamp": datetime.now(timezone.utc).isoformat(),
                }
                send(payload)
                print(f"{bus.code}: {payload['latitude']}, {payload['longitude']} @ {payload['speed']} km/h")
            time.sleep(args.interval)
    except KeyboardInterrupt:
        pass
    finally:
        if client is not None:
            client.loop_stop()
            client.disconnect()


if __name__ == "__main__":
    main()
