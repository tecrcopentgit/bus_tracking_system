from datetime import datetime

from pydantic import BaseModel, Field


class GpsIngest(BaseModel):
    """Payload published by a vehicle (MQTT) or POSTed by a gateway (REST).

    {"vehicle_id": "BUS-001", "latitude": 12.92, "longitude": 80.10,
     "speed": 34.5, "timestamp": "2026-09-01T10:00:00Z"}
    """

    vehicle_id: str = Field(min_length=1, max_length=50)
    latitude: float = Field(ge=-90, le=90)
    longitude: float = Field(ge=-180, le=180)
    speed: float = Field(default=0.0, ge=0, le=400, description="km/h")
    # ISO-8601 or unix epoch seconds. Defaults to server receive time.
    timestamp: datetime | None = None
