---
inclusion: always
---

# GymLog: convenciones del proyecto

App web personal para registrar entrenamientos del gimnasio. Se usa sobre todo desde el
celular, en el gimnasio. Este archivo es mínimo a propósito: se refina con las primeras specs.

## Stack (no cambiar sin decisión explícita)

- Python 3.13, FastAPI con endpoints síncronos (`def`, no `async def`).
- SQLAlchemy 2.0 síncrono + psycopg 3 + Alembic. PostgreSQL en todos los entornos; nunca SQLite.
- Jinja2 + HTMX + Tailwind (CLI standalone). Sin Node ni frameworks de frontend.
- uv para dependencias, ruff para lint y formato, pytest para pruebas.

## Arquitectura por capas

- `app/routers/web/`: rutas que devuelven HTML. Delgadas: validan entrada, llaman a un servicio
  y renderizan una plantilla. Sin SQL ni lógica de negocio.
- `app/routers/api/v1/`: rutas JSON. No crear hasta que haya un consumidor real.
- `app/services/`: lógica de negocio. No importa nada de FastAPI ni de las plantillas.
- `app/models/`: tablas. `app/schemas/`: validación con Pydantic.

## Reglas de datos y seguridad

- Toda consulta de un servicio filtra por `user_id`.
- Toda referencia a otro recurso se valida en el servicio: un ejercicio debe ser del catálogo
  público o del usuario, y una rutina debe ser del usuario.
- Fechas en `timestamptz` (UTC); se muestran en la zona horaria del usuario.
- Pesos en `numeric`, nunca float. Valores cerrados con restricciones CHECK.
- Secretos solo por variables de entorno, leídos con `app/core/config.py`.

## Cambios y pruebas

- Cada cambio de modelo trae su migración de Alembic (con `downgrade`) y sus pruebas.
- Cada recurso con dueño trae pruebas de aislamiento: el usuario B no puede leer, editar ni
  borrar el recurso del usuario A, ni usarlo en lo suyo.
- Las pruebas corren contra PostgreSQL real (`DATABASE_URL` con una base `*_test`).
- Antes de terminar una tarea: `uv run ruff check .`, `uv run ruff format --check .` y
  `uv run pytest` en verde.

## Idioma

- Código, nombres de tablas, variables y commits: inglés.
- Interfaz, mensajes al usuario y documentación: español.
- Cada spec incluye criterios de aceptación verificables en el celular.
