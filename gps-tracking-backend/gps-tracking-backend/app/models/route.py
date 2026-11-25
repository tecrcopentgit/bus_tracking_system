from sqlalchemy import ForeignKey, String, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base


class Route(Base):
    __tablename__ = "routes"

    id: Mapped[int] = mapped_column(primary_key=True)
    name: Mapped[str] = mapped_column(String(100), unique=True)
    description: Mapped[str] = mapped_column(String(255), default="")

    stops: Mapped[list["RouteStop"]] = relationship(
        back_populates="route",
        order_by="RouteStop.sequence",
        cascade="all, delete-orphan",
    )


class RouteStop(Base):
    __tablename__ = "route_stops"
    __table_args__ = (UniqueConstraint("route_id", "sequence"),)

    id: Mapped[int] = mapped_column(primary_key=True)
    route_id: Mapped[int] = mapped_column(ForeignKey("routes.id"), index=True)
    sequence: Mapped[int]
    name: Mapped[str] = mapped_column(String(120))
    latitude: Mapped[float]
    longitude: Mapped[float]

    route: Mapped[Route] = relationship(back_populates="stops")
