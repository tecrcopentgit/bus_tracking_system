from datetime import datetime
from typing import Literal

from pydantic import BaseModel, ConfigDict

VehicleStatus = Literal["moving", "idle", "offline", "no_data"]


class StopOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    sequence: int
    name: str
    latitude: float
    longitude: float


class RouteOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    name: str
    description: str
    stops: list[StopOut]


class VehicleOut(BaseModel):
    id: int
    code: str
    plate_number: str
    route_id: int
    is_active: bool
    status: VehicleStatus
    last_seen: datetime | None


class LocationOut(BaseModel):
    vehicle_id: int
    vehicle_code: str
    status: VehicleStatus
    # All null while status == "no_data".
    latitude: float | None = None
    longitude: float | None = None
    speed: float | None = None
    recorded_at: datetime | None = None


class HistoryPointOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    latitude: float
    longitude: float
    speed: float
    recorded_at: datetime


class HistoryOut(BaseModel):
    vehicle_id: int
    vehicle_code: str
    count: int
    points: list[HistoryPointOut]
