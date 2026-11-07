from collections.abc import Iterator

from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import Session

from app.core.db import get_db


def test_healthz_ok_when_database_up(client: TestClient) -> None:
    response = client.get("/healthz")

    assert response.status_code == 200
    assert response.json() == {"status": "ok", "database": "up"}


def test_healthz_503_when_database_down(client: TestClient) -> None:
    # Un puerto donde no escucha ninguna base de datos simula una caída.
    dead_engine = create_engine("postgresql+psycopg://x:x@127.0.0.1:1/x?connect_timeout=1")

    def broken_db() -> Iterator[Session]:
        with Session(dead_engine) as session:
            yield session

    client.app.dependency_overrides[get_db] = broken_db  # type: ignore[attr-defined]
    try:
        response = client.get("/healthz")
    finally:
        client.app.dependency_overrides.clear()  # type: ignore[attr-defined]

    assert response.status_code == 503
    assert response.json()["database"] == "down"
