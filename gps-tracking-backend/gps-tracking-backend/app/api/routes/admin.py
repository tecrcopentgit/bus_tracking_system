"""Administrator API: manage users, routes, vehicles and watch the whole fleet.

Every endpoint requires an authenticated user with is_admin = true.
"""
from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import func, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.api.deps import require_admin
from app.core.security import hash_password
from app.db.session import get_db
from app.models import Route, RouteStop, User, Vehicle, VehicleLatestLocation
from app.schemas.admin import (
    AdminRouteOut,
    AdminUserCreate,
    AdminUserOut,
    AdminUserUpdate,
    AdminVehicleOut,
    FleetOverview,
    RouteWrite,
    VehicleCreate,
    VehicleUpdate,
)
from app.schemas.auth import AssignmentRequest
from app.schemas.tracking import HistoryOut, LocationOut
from app.services import tracking_service as svc
from app.services.assignment import AssignmentError, assign_user

router = APIRouter(prefix="/admin", tags=["admin"], dependencies=[Depends(require_admin)])


def _conflict(msg: str) -> HTTPException:
    return HTTPException(status.HTTP_409_CONFLICT, msg)


def _not_found(what: str) -> HTTPException:
    return HTTPException(status.HTTP_404_NOT_FOUND, f"{what} not found")


# ------------------------------------------------------------------ users
def _user_out(u: User) -> AdminUserOut:
    return AdminUserOut(
        id=u.id,
        email=u.email,
        full_name=u.full_name,
        is_active=u.is_active,
        is_admin=u.is_admin,
        route_id=u.route_id,
        vehicle_id=u.vehicle_id,
        route_name=u.route.name if u.route else None,
        vehicle_code=u.vehicle.code if u.vehicle else None,
    )


@router.get("/users", response_model=list[AdminUserOut])
def list_users(
    q: str | None = Query(None, description="search name or email"),
    db: Session = Depends(get_db),
):
    stmt = select(User).order_by(User.id)
    if q:
        like = f"%{q.strip().lower()}%"
        stmt = stmt.where(func.lower(User.email).like(like) | func.lower(User.full_name).like(like))
    return [_user_out(u) for u in db.scalars(stmt)]


@router.post("/users", response_model=AdminUserOut, status_code=status.HTTP_201_CREATED)
def create_user(body: AdminUserCreate, db: Session = Depends(get_db)):
    if db.scalar(select(User.id).where(User.email == body.email)):
        raise _conflict("An account with this email already exists")
    user = User(
        email=body.email,
        full_name=body.full_name,
        hashed_password=hash_password(body.password),
        is_admin=body.is_admin,
    )
    if body.route_id is not None or body.vehicle_id is not None:
        route = db.get(Route, body.route_id) if body.route_id is not None else None
        vehicle = db.get(Vehicle, body.vehicle_id) if body.vehicle_id is not None else None
        if route is None or vehicle is None:
            raise HTTPException(status.HTTP_422_UNPROCESSABLE_ENTITY, "Provide both a valid route and vehicle")
        try:
            assign_user(user, route, vehicle)
        except AssignmentError as exc:
            raise HTTPException(status.HTTP_422_UNPROCESSABLE_ENTITY, str(exc))
    db.add(user)
    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        raise _conflict("An account with this email already exists")
    return _user_out(user)


@router.patch("/users/{user_id}", response_model=AdminUserOut)
def update_user(
    user_id: int,
    body: AdminUserUpdate,
    admin: User = Depends(require_admin),
    db: Session = Depends(get_db),
):
    user = db.get(User, user_id)
    if user is None:
        raise _not_found("User")
    if user.id == admin.id and (body.is_active is False or body.is_admin is False):
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "You cannot deactivate or demote your own account")
    if body.full_name is not None:
        user.full_name = body.full_name.strip()
    if body.is_active is not None:
        user.is_active = body.is_active
    if body.is_admin is not None:
        user.is_admin = body.is_admin
    if body.password is not None:
        user.hashed_password = hash_password(body.password)
    db.commit()
    return _user_out(user)


@router.put("/users/{user_id}/assignment", response_model=AdminUserOut)
def set_assignment(user_id: int, body: AssignmentRequest, db: Session = Depends(get_db)):
    user = db.get(User, user_id)
    route = db.get(Route, body.route_id)
    vehicle = db.get(Vehicle, body.vehicle_id)
    if user is None:
        raise _not_found("User")
    if route is None or vehicle is None:
        raise _not_found("Route or vehicle")
    try:
        assign_user(user, route, vehicle)
    except AssignmentError as exc:
        raise HTTPException(status.HTTP_422_UNPROCESSABLE_ENTITY, str(exc))
    db.commit()
    return _user_out(user)


@router.delete("/users/{user_id}/assignment", response_model=AdminUserOut)
def clear_assignment(user_id: int, db: Session = Depends(get_db)):
    user = db.get(User, user_id)
    if user is None:
        raise _not_found("User")
    user.route_id = None
    user.vehicle_id = None
    db.commit()
    return _user_out(user)


# ----------------------------------------------------------------- routes
def _route_out(db: Session, r: Route) -> AdminRouteOut:
    return AdminRouteOut(
        id=r.id,
        name=r.name,
        description=r.description,
        stops=r.stops,  # type: ignore[arg-type]
        vehicle_count=db.scalar(select(func.count()).select_from(Vehicle).where(Vehicle.route_id == r.id)) or 0,
        user_count=db.scalar(select(func.count()).select_from(User).where(User.route_id == r.id)) or 0,
    )


def _fill_stops(db: Session, route: Route, body: RouteWrite) -> None:
    # Delete the old stops *before* inserting the new ones, otherwise the
    # (route_id, sequence) unique constraint fires (inserts run before deletes).
    if route.stops:
        route.stops.clear()
        db.flush()
    for i, s in enumerate(body.stops, start=1):
        route.stops.append(RouteStop(sequence=i, name=s.name.strip(), latitude=s.latitude, longitude=s.longitude))


@router.get("/routes", response_model=list[AdminRouteOut])
def list_routes(db: Session = Depends(get_db)):
    return [_route_out(db, r) for r in db.scalars(select(Route).order_by(Route.id))]


@router.post("/routes", response_model=AdminRouteOut, status_code=status.HTTP_201_CREATED)
def create_route(body: RouteWrite, db: Session = Depends(get_db)):
    if db.scalar(select(Route.id).where(Route.name == body.name)):
        raise _conflict("A route with this name already exists")
    route = Route(name=body.name, description=body.description)
    db.add(route)
    _fill_stops(db, route, body)
    db.commit()
    return _route_out(db, route)


@router.put("/routes/{route_id}", response_model=AdminRouteOut)
def update_route(route_id: int, body: RouteWrite, db: Session = Depends(get_db)):
    route = db.get(Route, route_id)
    if route is None:
        raise _not_found("Route")
    clash = db.scalar(select(Route.id).where(Route.name == body.name, Route.id != route_id))
    if clash:
        raise _conflict("A route with this name already exists")
    route.name = body.name
    route.description = body.description
    _fill_stops(db, route, body)
    db.commit()
    return _route_out(db, route)


@router.delete("/routes/{route_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_route(route_id: int, db: Session = Depends(get_db)):
    route = db.get(Route, route_id)
    if route is None:
        raise _not_found("Route")
    in_use = db.scalar(select(func.count()).select_from(Vehicle).where(Vehicle.route_id == route_id)) or 0
    users = db.scalar(select(func.count()).select_from(User).where(User.route_id == route_id)) or 0
    if in_use or users:
        raise _conflict("Route is still used by vehicles or users; reassign them first")
    db.delete(route)
    db.commit()


# --------------------------------------------------------------- vehicles
def _vehicle_rows(db: Session) -> list[AdminVehicleOut]:
    latest = {l.vehicle_id: l for l in db.scalars(select(VehicleLatestLocation))}
    user_counts = dict(db.execute(select(User.vehicle_id, func.count()).where(User.vehicle_id.is_not(None)).group_by(User.vehicle_id)).all())
    out = []
    for v in db.scalars(select(Vehicle).order_by(Vehicle.id)):
        loc = latest.get(v.id)
        out.append(
            AdminVehicleOut(
                id=v.id,
                code=v.code,
                plate_number=v.plate_number,
                route_id=v.route_id,
                route_name=v.route.name if v.route else "",
                is_active=v.is_active,
                status=svc.vehicle_status(loc),  # type: ignore[arg-type]
                last_seen=loc.recorded_at if loc else None,
                latitude=loc.latitude if loc else None,
                longitude=loc.longitude if loc else None,
                speed=loc.speed if loc else None,
                user_count=user_counts.get(v.id, 0),
            )
        )
    return out


@router.get("/vehicles", response_model=list[AdminVehicleOut])
def list_vehicles(db: Session = Depends(get_db)):
    return _vehicle_rows(db)


@router.post("/vehicles", response_model=AdminVehicleOut, status_code=status.HTTP_201_CREATED)
def create_vehicle(body: VehicleCreate, db: Session = Depends(get_db)):
    if db.get(Route, body.route_id) is None:
        raise _not_found("Route")
    code = body.code.strip().upper()
    if db.scalar(select(Vehicle.id).where(Vehicle.code == code)):
        raise _conflict("A vehicle with this code already exists")
    vehicle = Vehicle(code=code, plate_number=body.plate_number.strip(), route_id=body.route_id)
    db.add(vehicle)
    db.commit()
    return next(v for v in _vehicle_rows(db) if v.id == vehicle.id)


@router.patch("/vehicles/{vehicle_id}", response_model=AdminVehicleOut)
def update_vehicle(vehicle_id: int, body: VehicleUpdate, db: Session = Depends(get_db)):
    vehicle = db.get(Vehicle, vehicle_id)
    if vehicle is None:
        raise _not_found("Vehicle")
    if body.route_id is not None and body.route_id != vehicle.route_id:
        if db.get(Route, body.route_id) is None:
            raise _not_found("Route")
        assigned = db.scalar(select(func.count()).select_from(User).where(User.vehicle_id == vehicle_id)) or 0
        if assigned:
            raise _conflict("Users are assigned to this vehicle; reassign them before changing its route")
        vehicle.route_id = body.route_id
    if body.plate_number is not None:
        vehicle.plate_number = body.plate_number.strip()
    if body.is_active is not None:
        vehicle.is_active = body.is_active
    db.commit()
    return next(v for v in _vehicle_rows(db) if v.id == vehicle_id)


@router.get("/vehicles/{vehicle_id}/location", response_model=LocationOut)
def vehicle_location(vehicle_id: int, db: Session = Depends(get_db)):
    vehicle = db.get(Vehicle, vehicle_id)
    if vehicle is None:
        raise _not_found("Vehicle")
    return svc.current_location(db, vehicle)


@router.get("/vehicles/{vehicle_id}/history", response_model=HistoryOut)
def vehicle_history(
    vehicle_id: int,
    start: datetime | None = Query(None),
    end: datetime | None = Query(None),
    limit: int = Query(500, ge=1, le=5000),
    db: Session = Depends(get_db),
):
    vehicle = db.get(Vehicle, vehicle_id)
    if vehicle is None:
        raise _not_found("Vehicle")
    return svc.location_history(db, vehicle, start, end, limit)


# --------------------------------------------------------------- overview
@router.get("/overview", response_model=FleetOverview)
def overview(db: Session = Depends(get_db)):
    vehicles = _vehicle_rows(db)
    active = [v for v in vehicles if v.is_active]
    count = lambda s: sum(1 for v in active if v.status == s)  # noqa: E731
    return FleetOverview(
        total_vehicles=len(vehicles),
        active_vehicles=len(active),
        moving=count("moving"),
        idle=count("idle"),
        offline=count("offline"),
        no_data=count("no_data"),
        total_users=db.scalar(select(func.count()).select_from(User)) or 0,
        unassigned_users=db.scalar(
            select(func.count()).select_from(User).where(User.vehicle_id.is_(None), User.is_admin.is_(False))
        ) or 0,
        total_routes=db.scalar(select(func.count()).select_from(Route)) or 0,
        vehicles=vehicles,
    )
