#!/bin/bash
# Se ejecuta una sola vez, cuando el volumen de PostgreSQL está vacío.
set -euo pipefail
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-SQL
  CREATE DATABASE ${POSTGRES_DB}_test OWNER ${POSTGRES_USER};
SQL
