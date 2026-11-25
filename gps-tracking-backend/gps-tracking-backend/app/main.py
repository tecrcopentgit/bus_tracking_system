import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

import app.models  # noqa: F401  (register tables)
from app.api.routes import admin, auth, gps, me, resources
from app.core.config import get_settings
from app.db.base import Base
from app.db.seed import seed
from app.db.session import SessionLocal, engine
from app.services.mqtt_client import MqttIngestor

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(name)s: %(message)s")
settings = get_settings()


@asynccontextmanager
async def lifespan(_: FastAPI):
    # For a real deployment replace create_all with Alembic migrations.
    Base.metadata.create_all(engine)
    if settings.seed_on_startup:
        with SessionLocal() as db:
            seed(db)
    ingestor = MqttIngestor(settings) if settings.mqtt_enabled else None
    if ingestor:
        ingestor.start()
    yield
    if ingestor:
        ingestor.stop()


app = FastAPI(title=settings.app_name, version="1.0.0", lifespan=lifespan)
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_methods=["*"],
    allow_headers=["*"],
)

API_PREFIX = "/api/v1"
for module in (auth, me, resources, gps, admin):
    app.include_router(module.router, prefix=API_PREFIX)


@app.get("/health", tags=["meta"])
def health():
    return {"status": "ok"}
