from app.models import Route, User, Vehicle


class AssignmentError(ValueError):
    pass


def assign_user(user: User, route: Route, vehicle: Vehicle) -> None:
    """Give a user exactly one route + vehicle. The vehicle must run that route."""
    if vehicle.route_id != route.id:
        raise AssignmentError(
            f"Vehicle {vehicle.code} does not operate on route '{route.name}'"
        )
    user.route_id = route.id
    user.vehicle_id = vehicle.id
