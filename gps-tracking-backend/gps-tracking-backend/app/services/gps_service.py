from datetime import datetime, timedelta, timezone

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.config import get_settings
from app.models import GpsPoint, Vehicle, VehicleLatestLocation
from app.schemas.gps import GpsIngest


class UnknownVehicleError(LookupError):
    pass


class InvalidFixError(ValueError):
    pass


def ingest_point(db: Session, payload: GpsIngest) -> bool:
    """Persist one GPS fix. Returns False if it was a duplicate.

    * Every fix goes to `gps_points` (history).
    * `vehicle_latest_locations` is only advanced by fixes that are not older
      than what we already have, so delayed / out-of-order messages can never
      move the bus backwards on the map.
    * (vehicle, timestamp) is unique, which makes QoS-1 redeliveries idempotent.
    """
    settings = get_settings()
    vehicle = db.scalar(select(Vehicle).where(Vehicle.code == payload.vehicle_id))
    if vehicle is None or not vehicle.is_active:
        raise UnknownVehicleError(payload.vehicle_id)

    now = datetime.now(timezone.utc)
    ts = payload.timestamp or now
    if ts.tzinfo is None:
        ts = ts.replace(tzinfo=timezone.utc)
    ts = ts.astimezone(timezone.utc)
    if ts > now + timedelta(seconds=settings.max_future_skew_seconds):
        raise InvalidFixError("timestamp is too far in the future")

    exists = db.scalar(
        select(GpsPoint.id).where(
            GpsPoint.vehicle_id == vehicle.id, GpsPoint.recorded_at == ts
        )
    )
    if exists:
        return False

    db.add(
        GpsPoint(
            vehicle_id=vehicle.id,
            latitude=payload.latitude,
            longitude=payload.longitude,
            speed=payload.speed,
            recorded_at=ts,
            received_at=now,
        )
    )
    latest = db.get(VehicleLatestLocation, vehicle.id)
    if latest is None:
        db.add(
            VehicleLatestLocation(
                vehicle_id=vehicle.id,
                latitude=payload.latitude,
                longitude=payload.longitude,
                speed=payload.speed,
                recorded_at=ts,
                updated_at=now,
            )
        )
    elif ts >= latest.recorded_at:
        latest.latitude = payload.latitude
        latest.longitude = payload.longitude
        latest.speed = payload.speed
        latest.recorded_at = ts
        latest.updated_at = now
    db.commit()
    return True
