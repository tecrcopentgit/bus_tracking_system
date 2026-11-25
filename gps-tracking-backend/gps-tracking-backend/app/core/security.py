from datetime import datetime, timedelta, timezone

import bcrypt
import jwt

from app.core.config import get_settings


def hash_password(password: str) -> str:
    return bcrypt.hashpw(password.encode()[:72], bcrypt.gensalt()).decode()


def verify_password(password: str, hashed: str) -> bool:
    try:
        return bcrypt.checkpw(password.encode()[:72], hashed.encode())
    except ValueError:
        return False


# Used to keep login timing similar whether or not the email exists.
DUMMY_HASH = hash_password("not-a-real-password")


def create_access_token(user_id: int) -> tuple[str, int]:
    s = get_settings()
    expires = timedelta(minutes=s.access_token_expire_minutes)
    now = datetime.now(timezone.utc)
    token = jwt.encode(
        {"sub": str(user_id), "iat": now, "exp": now + expires},
        s.jwt_secret,
        algorithm=s.jwt_algorithm,
    )
    return token, int(expires.total_seconds())


def decode_access_token(token: str) -> int:
    s = get_settings()
    payload = jwt.decode(token, s.jwt_secret, algorithms=[s.jwt_algorithm])
    return int(payload["sub"])
