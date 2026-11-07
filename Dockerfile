# syntax=docker/dockerfile:1

ARG PYTHON_VERSION=3.13

# --- Etapa 1: compilar el CSS con el binario standalone de Tailwind (sin Node) ---
FROM python:${PYTHON_VERSION}-slim AS css
ARG TAILWIND_VERSION=v4.3.5
ARG TARGETARCH
WORKDIR /src
RUN case "${TARGETARCH:-amd64}" in \
      amd64) arch=x64 ;; \
      arm64) arch=arm64 ;; \
      *) echo "Arquitectura no soportada: ${TARGETARCH}" && exit 1 ;; \
    esac && \
    python -c "import urllib.request,sys; urllib.request.urlretrieve(sys.argv[1], '/usr/local/bin/tailwindcss')" \
      "https://github.com/tailwindlabs/tailwindcss/releases/download/${TAILWIND_VERSION}/tailwindcss-linux-${arch}" && \
    chmod +x /usr/local/bin/tailwindcss
COPY app/templates app/templates
COPY app/static/css/input.css app/static/css/input.css
RUN tailwindcss -i app/static/css/input.css -o app/static/css/app.css --minify

# --- Etapa 2: instalar dependencias con uv ---
FROM ghcr.io/astral-sh/uv:python${PYTHON_VERSION}-bookworm-slim AS deps
ENV UV_COMPILE_BYTECODE=1 UV_LINK_MODE=copy UV_PYTHON_DOWNLOADS=never
WORKDIR /app
COPY pyproject.toml uv.lock ./
RUN uv sync --frozen --no-dev --no-install-project

# --- Etapa 3: imagen final, mínima y sin root ---
FROM python:${PYTHON_VERSION}-slim AS runtime
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PATH="/app/.venv/bin:${PATH}"
WORKDIR /app
RUN useradd --create-home --uid 10001 gymlog
COPY --from=deps /app/.venv /app/.venv
COPY alembic.ini ./
COPY migrations migrations
COPY app app
COPY --from=css /src/app/static/css/app.css app/static/css/app.css
USER gymlog
EXPOSE 8000
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8000/healthz', timeout=4)"
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--proxy-headers"]
