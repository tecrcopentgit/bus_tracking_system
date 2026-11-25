from datetime import datetime, timezone

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.config import get_settings
from app.models import GpsPoint, Vehicle, VehicleLatestLocation
from app.schemas.tracking import HistoryOut, LocationOut, VehicleOut


def vehicle_status(latest: VehicleLatestLocation | None, now: datetime | None = None) -> str:
    s = get_settings()
    if latest is None:
        return "no_data"
    now = now or datetime.now(timezone.utc)
    if (now - latest.recorded_at).total_seconds() > s.online_threshold_seconds:
        return "offline"
    return "moving" if latest.speed >= s.moving_speed_kmh else "idle"


def vehicle_details(db: Session, vehicle: Vehicle) -> VehicleOut:
    latest = db.get(VehicleLatestLocation, vehicle.id)
    return VehicleOut(
        id=vehicle.id,
        code=vehicle.code,
        plate_number=vehicle.plate_number,
        route_id=vehicle.route_id,
        is_active=vehicle.is_active,
        status=vehicle_status(latest),
        last_seen=latest.recorded_at if latest else None,
    )


def current_location(db: Session, vehicle: Vehicle) -> LocationOut:
    latest = db.get(VehicleLatestLocation, vehicle.id)
    status = vehicle_status(latest)
    if latest is None:
        return LocationOut(vehicle_id=vehicle.id, vehicle_code=vehicle.code, status=status)
    return LocationOut(
        vehicle_id=vehicle.id,
        vehicle_code=vehicle.code,
        status=status,
        latitude=latest.latitude,
        longitude=latest.longitude,
        speed=latest.speed,
        recorded_at=latest.recorded_at,
    )


def location_history(
    db: Session,
    vehicle: Vehicle,
    start: datetime | None,
    end: datetime | None,
    limit: int,
) -> HistoryOut:
    """Newest `limit` fixes inside [start, end], returned oldest -> newest."""
    stmt = select(GpsPoint).where(GpsPoint.vehicle_id == vehicle.id)
    if start:
        stmt = stmt.where(GpsPoint.recorded_at >= start)
    if end:
        stmt = stmt.where(GpsPoint.recorded_at <= end)
    rows = list(db.scalars(stmt.order_by(GpsPoint.recorded_at.desc()).limit(limit)))
    rows.reverse()
    return HistoryOut(
        vehicle_id=vehicle.id,
        vehicle_code=vehicle.code,
        count=len(rows),
        points=rows,  # type: ignore[arg-type]  (validated from attributes)
    )
