from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles

from app.core.config import get_settings
from app.core.logging import configure_logging
from app.routers import health
from app.routers.web import pages
from app.templating import APP_DIR


def create_app() -> FastAPI:
    settings = get_settings()
    configure_logging(settings.log_level)

    app = FastAPI(
        title="GymLog",
        # La documentación automática solo fuera de producción.
        docs_url=None if settings.app_env == "production" else "/docs",
        redoc_url=None,
    )
    app.mount("/static", StaticFiles(directory=APP_DIR / "static"), name="static")
    app.include_router(health.router)
    app.include_router(pages.router)
    return app


app = create_app()
