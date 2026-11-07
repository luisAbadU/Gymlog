import logging
from typing import Annotated

from fastapi import APIRouter, Depends
from fastapi.responses import JSONResponse
from sqlalchemy import text
from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy.orm import Session

from app.core.db import get_db

router = APIRouter(tags=["health"])
logger = logging.getLogger(__name__)


@router.get("/healthz")
def healthz(db: Annotated[Session, Depends(get_db)]) -> JSONResponse:
    """Responde 200 solo si la base de datos contesta. Lo usan Docker y el latido."""
    try:
        db.execute(text("SELECT 1"))
    except SQLAlchemyError:
        logger.exception("healthz: la base de datos no responde")
        return JSONResponse({"status": "error", "database": "down"}, status_code=503)
    return JSONResponse({"status": "ok", "database": "up"})
