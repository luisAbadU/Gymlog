"""Tablas de SQLAlchemy. Importar aquí cada modelo nuevo para que Alembic lo detecte."""

from app.models.base import Base

__all__ = ["Base"]
