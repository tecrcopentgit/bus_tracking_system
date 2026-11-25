"""REST fallback for GPS ingestion (MQTT is the primary path)."""
import secrets

from fastapi import APIRouter, Depends, Header, HTTPException, status
from sqlalchemy.orm import Session

from app.core.config import get_settings
from app.db.session import get_db
from app.schemas.gps import GpsIngest
from app.services.gps_service import InvalidFixError, UnknownVehicleError, ingest_point

router = APIRouter(prefix="/gps", tags=["gps-ingest"])


@router.post("", status_code=status.HTTP_202_ACCEPTED)
def ingest(
    body: GpsIngest,
    x_device_key: str = Header(..., description="Shared device/gateway API key"),
    db: Session = Depends(get_db),
):
    if not secrets.compare_digest(x_device_key, get_settings().device_api_key):
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Invalid device key")
    try:
        stored = ingest_point(db, body)
    except UnknownVehicleError:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Unknown vehicle")
    except InvalidFixError as exc:
        raise HTTPException(status.HTTP_422_UNPROCESSABLE_ENTITY, str(exc))
    return {"stored": stored}
