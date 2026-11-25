from sqlalchemy import ForeignKey, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base


class Vehicle(Base):
    __tablename__ = "vehicles"

    id: Mapped[int] = mapped_column(primary_key=True)
    # Public identifier used by the GPS devices, e.g. "BUS-001".
    code: Mapped[str] = mapped_column(String(50), unique=True, index=True)
    plate_number: Mapped[str] = mapped_column(String(30), default="")
    route_id: Mapped[int] = mapped_column(ForeignKey("routes.id"), index=True)
    is_active: Mapped[bool] = mapped_column(default=True)

    route = relationship("Route")
