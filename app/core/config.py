from functools import lru_cache
from typing import Literal

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Configuración leída de variables de entorno (y de .env en desarrollo).

    Si falta una variable obligatoria, la app falla al arrancar en vez de fallar
    a mitad de una petición.
    """

    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    database_url: str
    app_env: Literal["development", "test", "production"] = "development"
    log_level: str = "INFO"


@lru_cache
def get_settings() -> Settings:
    return Settings()  # type: ignore[call-arg]
