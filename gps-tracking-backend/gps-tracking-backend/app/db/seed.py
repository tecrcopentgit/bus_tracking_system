"""Idempotent demo data loader. `python -m app.db.seed` or SEED_ON_STARTUP=true."""
import json
import logging
from pathlib import Path

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.security import hash_password
from app.models import Route, RouteStop, User, Vehicle
from app.services.assignment import assign_user

SEED_FILE = Path(__file__).resolve().parents[2] / "data" / "seed.json"
log = logging.getLogger("gps.seed")


def seed(db: Session) -> None:
    data = json.loads(SEED_FILE.read_text())

    routes: dict[str, Route] = {}
    for r in data["routes"]:
        route = db.scalar(select(Route).where(Route.name == r["name"]))
        if route is None:
            route = Route(
                name=r["name"],
                description=r.get("description", ""),
                stops=[
                    RouteStop(
                        sequence=i,
                        name=s["name"],
                        latitude=s["latitude"],
                        longitude=s["longitude"],
                    )
                    for i, s in enumerate(r["stops"], start=1)
                ],
            )
            db.add(route)
        routes[r["name"]] = route
    db.flush()

    vehicles: dict[str, Vehicle] = {}
    for v in data["vehicles"]:
        vehicle = db.scalar(select(Vehicle).where(Vehicle.code == v["code"]))
        if vehicle is None:
            vehicle = Vehicle(
                code=v["code"],
                plate_number=v.get("plate_number", ""),
                route_id=routes[v["route"]].id,
            )
            db.add(vehicle)
        vehicles[v["code"]] = vehicle
    db.flush()

    for u in data["users"]:
        email = u["email"].lower()
        user = db.scalar(select(User).where(User.email == email))
        if user is None:
            user = User(
                email=email,
                full_name=u["full_name"],
                hashed_password=hash_password(u["password"]),
                is_admin=u.get("is_admin", False),
            )
            db.add(user)
        if "route" in u:  # admins / unassigned demo users may have none
            assign_user(user, routes[u["route"]], vehicles[u["vehicle"]])
    db.commit()
    log.info("Seed data loaded")


if __name__ == "__main__":
    from app.db.base import Base
    from app.db.session import SessionLocal, engine

    logging.basicConfig(level=logging.INFO)
    Base.metadata.create_all(engine)
    with SessionLocal() as session:
        seed(session)
