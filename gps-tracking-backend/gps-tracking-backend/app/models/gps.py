from datetime import datetime, timezone

from sqlalchemy import BigInteger, ForeignKey, Index, Integer, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base, UTCDateTime

_PK = BigInteger().with_variant(Integer, "sqlite")


def _utcnow() -> datetime:
    return datetime.now(timezone.utc)


class GpsPoint(Base):
    """Append-only history of every accepted GPS fix."""

    __tablename__ = "gps_points"
    __table_args__ = (
        UniqueConstraint("vehicle_id", "recorded_at", name="uq_gps_vehicle_time"),
        Index("ix_gps_vehicle_time", "vehicle_id", "recorded_at"),
    )

    id: Mapped[int] = mapped_column(_PK, primary_key=True, autoincrement=True)
    vehicle_id: Mapped[int] = mapped_column(ForeignKey("vehicles.id"))
    latitude: Mapped[float]
    longitude: Mapped[float]
    speed: Mapped[float] = mapped_column(default=0.0)  # km/h
    recorded_at: Mapped[datetime] = mapped_column(UTCDateTime)  # device time
    received_at: Mapped[datetime] = mapped_column(UTCDateTime, default=_utcnow)


class VehicleLatestLocation(Base):
    """One row per vehicle: the newest fix, for O(1) 'where is my bus?' reads."""

    __tablename__ = "vehicle_latest_locations"

    vehicle_id: Mapped[int] = mapped_column(ForeignKey("vehicles.id"), primary_key=True)
    latitude: Mapped[float]
    longitude: Mapped[float]
    speed: Mapped[float] = mapped_column(default=0.0)
    recorded_at: Mapped[datetime] = mapped_column(UTCDateTime)
    updated_at: Mapped[datetime] = mapped_column(UTCDateTime, default=_utcnow)
