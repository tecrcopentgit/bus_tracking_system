from datetime import datetime

from pydantic import BaseModel, Field, field_validator

from app.schemas.auth import RegisterRequest
from app.schemas.tracking import RouteOut, VehicleStatus


class AdminUserOut(BaseModel):
    id: int
    email: str
    full_name: str
    is_active: bool
    is_admin: bool
    route_id: int | None
    vehicle_id: int | None
    route_name: str | None = None
    vehicle_code: str | None = None


class AdminUserCreate(RegisterRequest):
    is_admin: bool = False
    route_id: int | None = None
    vehicle_id: int | None = None


class AdminUserUpdate(BaseModel):
    full_name: str | None = Field(default=None, min_length=2, max_length=120)
    is_active: bool | None = None
    is_admin: bool | None = None
    password: str | None = Field(default=None, min_length=8, max_length=72)


class StopIn(BaseModel):
    name: str = Field(min_length=1, max_length=120)
    latitude: float = Field(ge=-90, le=90)
    longitude: float = Field(ge=-180, le=180)


class RouteWrite(BaseModel):
    name: str = Field(min_length=1, max_length=100)
    description: str = Field(default="", max_length=255)
    stops: list[StopIn] = Field(min_length=2, max_length=60)

    @field_validator("name")
    @classmethod
    def _strip(cls, v: str) -> str:
        return v.strip()


class AdminRouteOut(RouteOut):
    vehicle_count: int = 0
    user_count: int = 0


class VehicleCreate(BaseModel):
    code: str = Field(min_length=2, max_length=50, pattern=r"^[A-Za-z0-9_\-]+$")
    plate_number: str = Field(default="", max_length=30)
    route_id: int


class VehicleUpdate(BaseModel):
    plate_number: str | None = Field(default=None, max_length=30)
    route_id: int | None = None
    is_active: bool | None = None


class AdminVehicleOut(BaseModel):
    id: int
    code: str
    plate_number: str
    route_id: int
    route_name: str
    is_active: bool
    status: VehicleStatus
    last_seen: datetime | None = None
    latitude: float | None = None
    longitude: float | None = None
    speed: float | None = None
    user_count: int = 0


class FleetOverview(BaseModel):
    total_vehicles: int
    active_vehicles: int
    moving: int
    idle: int
    offline: int
    no_data: int
    total_users: int
    unassigned_users: int
    total_routes: int
    vehicles: list[AdminVehicleOut]
