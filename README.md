# GymLog

App web personal para registrar los entrenamientos del gimnasio, pensada para usarse desde el
celular. Autoalojada en un home lab con Proxmox y accesible por Tailscale.

**Estado:** fase 0a (esqueleto). Hay una página «Hola GymLog» y un endpoint `/healthz`.

## Stack

FastAPI · SQLAlchemy 2.0 + Alembic · PostgreSQL 16 · Jinja2 + HTMX + Tailwind · uv · Docker ·
GitHub Actions

## Estructura

```text
app/
├── main.py            # crea la app FastAPI
├── core/              # configuración, base de datos, logs
├── models/            # tablas (SQLAlchemy)
├── schemas/           # validación (Pydantic)
├── services/          # lógica de negocio
├── routers/
│   ├── health.py      # /healthz
│   └── web/           # páginas HTML
├── templates/         # Jinja2
└── static/css/        # Tailwind (input.css → app.css)
migrations/            # Alembic
tests/                 # pytest contra PostgreSQL real
.kiro/steering/        # convenciones para Kiro
```

## Desarrollo local

Requisitos: [uv](https://docs.astral.sh/uv/) y Docker.

```bash
cp .env.example .env              # y cambia la contraseña
docker compose up -d db           # PostgreSQL (crea también gymlog_test)
uv sync                           # dependencias
uv run alembic upgrade head       # migraciones
uv run uvicorn app.main:app --reload
```

La app queda en http://127.0.0.1:8000 y el estado en http://127.0.0.1:8000/healthz.

Para ver los estilos fuera de Docker, compila el CSS una vez con el
[binario standalone de Tailwind](https://github.com/tailwindlabs/tailwindcss/releases)
(en Windows, `tailwindcss-windows-x64.exe`):

```bash
./tailwindcss -i app/static/css/input.css -o app/static/css/app.css --watch
```

### Pruebas y calidad

Las pruebas usan una base de datos aparte, cuyo nombre debe terminar en `_test`:

```bash
DATABASE_URL=postgresql+psycopg://gymlog:<contraseña>@127.0.0.1:5432/gymlog_test uv run pytest
uv run ruff check .
uv run ruff format --check .
```

En PowerShell, la variable se define con `$env:DATABASE_URL="..."` antes de `uv run pytest`.

### Todo en Docker

```bash
docker compose up -d --build
docker compose run --rm app alembic upgrade head
```

## Migraciones

```bash
uv run alembic revision --autogenerate -m "descripcion corta"
uv run alembic upgrade head
```

Revisa siempre el archivo generado antes de aplicarlo.

## CI

Cada push y pull request corre ruff y pytest contra PostgreSQL. Cada push a `main` que pasa las
pruebas publica la imagen en `ghcr.io/<usuario>/gymlog` con las etiquetas `latest` y el SHA corto.
