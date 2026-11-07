"""Las pruebas corren contra PostgreSQL real, nunca contra SQLite.

DATABASE_URL debe apuntar a una base de datos SOLO para pruebas (por ejemplo gymlog_test):
la sesión la deja en blanco al empezar y al terminar.
"""

import os
from collections.abc import Iterator

import pytest
from alembic import command
from alembic.config import Config
from fastapi.testclient import TestClient
from sqlalchemy import make_url

os.environ.setdefault("APP_ENV", "test")

if "_test" not in (make_url(os.environ.get("DATABASE_URL", "")).database or ""):
    pytest.exit(
        "DATABASE_URL debe apuntar a una base de datos de pruebas (nombre con '_test').",
        returncode=2,
    )


@pytest.fixture(scope="session")
def alembic_config() -> Config:
    return Config("alembic.ini")


@pytest.fixture(scope="session", autouse=True)
def migrated_db(alembic_config: Config) -> Iterator[None]:
    command.downgrade(alembic_config, "base")
    command.upgrade(alembic_config, "head")
    yield
    command.downgrade(alembic_config, "base")


@pytest.fixture
def client() -> Iterator[TestClient]:
    from app.main import app

    with TestClient(app) as test_client:
        yield test_client
