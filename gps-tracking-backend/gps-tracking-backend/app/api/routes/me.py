"""Everything the logged-in user may see, resolved from *their own* assignment.

There is no id in these URLs, so there is nothing for a client to tamper with.
"""
from datetime import datetime

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.api.deps import assigned_route, assigned_vehicle, get_current_user
from app.db.session import get_db
from app.models import Route, User, Vehicle
from app.schemas.auth import UserOut
from app.schemas.tracking import HistoryOut, LocationOut, RouteOut, VehicleOut
from app.services import tracking_service as svc

router = APIRouter(prefix="/me", tags=["me"])


@router.get("", response_model=UserOut)
def me(user: User = Depends(get_current_user)):
    return user


@router.get("/route", response_model=RouteOut)
def my_route(route: Route = Depends(assigned_route)):
    return route


@router.get("/vehicle", response_model=VehicleOut)
def my_vehicle(vehicle: Vehicle = Depends(assigned_vehicle), db: Session = Depends(get_db)):
    return svc.vehicle_details(db, vehicle)


@router.get("/vehicle/location", response_model=LocationOut)
def my_vehicle_location(
    vehicle: Vehicle = Depends(assigned_vehicle), db: Session = Depends(get_db)
):
    return svc.current_location(db, vehicle)


@router.get("/vehicle/history", response_model=HistoryOut)
def my_vehicle_history(
    start: datetime | None = Query(None, description="ISO-8601, inclusive"),
    end: datetime | None = Query(None, description="ISO-8601, inclusive"),
    limit: int = Query(500, ge=1, le=5000),
    vehicle: Vehicle = Depends(assigned_vehicle),
    db: Session = Depends(get_db),
):
    return svc.location_history(db, vehicle, start, end, limit)
