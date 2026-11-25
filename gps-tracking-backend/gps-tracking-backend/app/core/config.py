from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    app_name: str = "GPS Vehicle Tracking API"
    database_url: str = "postgresql+psycopg2://gps:gps@localhost:5432/gps"

    jwt_secret: str = "change-me"
    jwt_algorithm: str = "HS256"
    access_token_expire_minutes: int = 60

    # Shared secret for the REST ingestion endpoint (devices / gateways).
    device_api_key: str = "dev-device-key"

    mqtt_enabled: bool = True
    mqtt_host: str = "localhost"
    mqtt_port: int = 1883
    mqtt_username: str | None = None
    mqtt_password: str | None = None
    mqtt_topic: str = "vehicles/+/gps"

    # A vehicle with no fix newer than this is reported "offline".
    online_threshold_seconds: int = 60
    # Speed (km/h) at or above which an online vehicle is "moving".
    moving_speed_kmh: float = 2.0
    # Reject GPS fixes timestamped further in the future than this.
    max_future_skew_seconds: int = 300

    cors_origins: list[str] = ["*"]
    seed_on_startup: bool = False


@lru_cache
def get_settings() -> Settings:
    return Settings()
