import jwt
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.orm import Session

from app.core.security import decode_access_token
from app.db.session import get_db
from app.models import Route, User, Vehicle

bearer = HTTPBearer(auto_error=False)


def _unauthorized(detail: str) -> HTTPException:
    return HTTPException(
        status.HTTP_401_UNAUTHORIZED, detail, headers={"WWW-Authenticate": "Bearer"}
    )


def get_current_user(
    creds: HTTPAuthorizationCredentials | None = Depends(bearer),
    db: Session = Depends(get_db),
) -> User:
    if creds is None:
        raise _unauthorized("Not authenticated")
    try:
        user_id = decode_access_token(creds.credentials)
    except (jwt.PyJWTError, KeyError, ValueError):
        raise _unauthorized("Invalid or expired token")
    user = db.get(User, user_id)
    if user is None or not user.is_active:
        raise _unauthorized("Invalid or expired token")
    return user


def assigned_vehicle(
    user: User = Depends(get_current_user), db: Session = Depends(get_db)
) -> Vehicle:
    vehicle = db.get(Vehicle, user.vehicle_id) if user.vehicle_id else None
    if vehicle is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "No vehicle assigned to this user")
    return vehicle


def assigned_route(
    user: User = Depends(get_current_user), db: Session = Depends(get_db)
) -> Route:
    route = db.get(Route, user.route_id) if user.route_id else None
    if route is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "No route assigned to this user")
    return route


# --- Authorization for resource-style URLs (/vehicles/{id}, /routes/{id}) ---
# Unassigned AND non-existent ids both return 403, so ids can't be enumerated.

def authorize_vehicle(
    vehicle_id: int,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> Vehicle:
    if user.vehicle_id is None or vehicle_id != user.vehicle_id:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "You are not assigned to this vehicle")
    vehicle = db.get(Vehicle, vehicle_id)
    if vehicle is None:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "You are not assigned to this vehicle")
    return vehicle


def authorize_route(
    route_id: int,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> Route:
    if user.route_id is None or route_id != user.route_id:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "You are not assigned to this route")
    route = db.get(Route, route_id)
    if route is None:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "You are not assigned to this route")
    return route


def require_admin(user: User = Depends(get_current_user)) -> User:
    if not user.is_admin:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Administrator access required")
    return user
