"""Resource-style URLs. Same data as /me, but addressed by id and therefore
guarded by explicit ownership checks (403 unless it is the caller's own)."""
from datetime import datetime

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.api.deps import authorize_route, authorize_vehicle
from app.db.session import get_db
from app.models import Route, Vehicle
from app.schemas.tracking import HistoryOut, LocationOut, RouteOut, VehicleOut
from app.services import tracking_service as svc

router = APIRouter(tags=["resources"])


@router.get("/routes/{route_id}", response_model=RouteOut)
def get_route(route: Route = Depends(authorize_route)):
    return route


@router.get("/vehicles/{vehicle_id}", response_model=VehicleOut)
def get_vehicle(vehicle: Vehicle = Depends(authorize_vehicle), db: Session = Depends(get_db)):
    return svc.vehicle_details(db, vehicle)


@router.get("/vehicles/{vehicle_id}/location", response_model=LocationOut)
def get_vehicle_location(
    vehicle: Vehicle = Depends(authorize_vehicle), db: Session = Depends(get_db)
):
    return svc.current_location(db, vehicle)


@router.get("/vehicles/{vehicle_id}/history", response_model=HistoryOut)
def get_vehicle_history(
    start: datetime | None = Query(None),
    end: datetime | None = Query(None),
    limit: int = Query(500, ge=1, le=5000),
    vehicle: Vehicle = Depends(authorize_vehicle),
    db: Session = Depends(get_db),
):
    return svc.location_history(db, vehicle, start, end, limit)
