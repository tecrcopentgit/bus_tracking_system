import os
from pathlib import Path

DB_FILE = Path(__file__).parent / "test_gps.db"
DB_FILE.unlink(missing_ok=True)
os.environ["DATABASE_URL"] = f"sqlite:///{DB_FILE}"
os.environ["MQTT_ENABLED"] = "false"
os.environ["SEED_ON_STARTUP"] = "true"
os.environ["JWT_SECRET"] = "test-secret-test-secret-test-secret"

import pytest  # noqa: E402
from fastapi.testclient import TestClient  # noqa: E402

from app.main import app  # noqa: E402


@pytest.fixture(scope="session")
def client():
    with TestClient(app) as c:  # runs lifespan: create tables + seed
        yield c


def login(client, email, password="password123"):
    r = client.post("/api/v1/auth/login", json={"email": email, "password": password})
    assert r.status_code == 200, r.text
    return {"Authorization": f"Bearer {r.json()['access_token']}"}


@pytest.fixture(scope="session")
def alice(client):
    return login(client, "alice@example.com")


@pytest.fixture(scope="session")
def bob(client):
    return login(client, "bob@example.com")


@pytest.fixture(scope="session")
def carol(client):
    return login(client, "carol@example.com")
