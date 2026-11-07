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
scripts/               # utilidades (scripts/test.ps1: pruebas sin tipear la contraseña)
tests/                 # pytest contra PostgreSQL real
.kiro/steering/        # convenciones para Kiro
```

## Desarrollo local

Las instrucciones de esta sección están pensadas para **Windows con PowerShell**.

### a. Requisitos

Necesitas Git, uv y Docker Desktop (con el backend de WSL 2). Instálalos desde una terminal de
PowerShell:

```powershell
# Git
winget install --id Git.Git -e

# uv (gestor de dependencias de Python)
powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"

# Docker Desktop
winget install --id Docker.DockerDesktop -e
```

Después de instalar:

- **Reabre PowerShell** para que `git` y `uv` queden en el `PATH`.
- **Abre Docker Desktop** y espera a que el panel inferior izquierdo muestre **«Engine running»**
  antes de usar `docker compose`. Docker Desktop usa WSL 2 como backend.

### b. Primera vez

```powershell
git clone https://github.com/luisAbadU/Gymlog.git
cd Gymlog
copy .env.example .env
```

Edita `.env` y cambia la contraseña en **las dos líneas** que la contienen,
`POSTGRES_PASSWORD` y `DATABASE_URL`, por **el mismo valor** (usa solo letras y números, sin
símbolos ni espacios para evitar problemas al escribirla en la URL):

```dotenv
POSTGRES_PASSWORD=miClave123
DATABASE_URL=postgresql+psycopg://gymlog:miClave123@127.0.0.1:5432/gymlog
```

Levanta la base de datos y la app, y aplica las migraciones:

```powershell
docker compose up -d --build
docker compose run --rm app alembic upgrade head
```

Verifica que todo quedó arriba:

```powershell
docker compose ps                           # ambos servicios deben verse "healthy"
curl.exe http://localhost:8000/healthz      # responde el estado en JSON
```

Abre también <http://localhost:8000> en el navegador: debe aparecer la página «Hola GymLog».

> **Importante:** la contraseña de PostgreSQL se fija **al crear el volumen de datos**, la primera
> vez que arranca el servicio `db`. Si cambias `POSTGRES_PASSWORD` en `.env` después de eso, el
> contenedor seguirá usando la contraseña vieja. Para que tome la nueva hay que borrar el volumen
> con `docker compose down -v` (**esto borra todos los datos**) y volver a levantar.

### c. Pruebas y calidad

Las pruebas se conectan a la base de datos, así que primero asegúrate de que el servicio `db`
esté arriba:

```powershell
docker compose up -d db
```

```powershell
uv sync                     # instala dependencias (crea el entorno .venv)
.\scripts\test.ps1          # corre las pruebas (pytest) contra gymlog_test
uv run ruff check .         # lint
uv run ruff format --check .  # formato
```

`scripts\test.ps1` lee la contraseña del `.env`, arma la `DATABASE_URL` apuntando a la base
**`gymlog_test`** y ejecuta `uv run pytest` por ti: no tienes que escribir la contraseña a mano.
Puedes pasarle argumentos extra, que llegan tal cual a pytest:

```powershell
.\scripts\test.ps1 -k health    # solo las pruebas que contienen "health"
.\scripts\test.ps1 -x           # se detiene en el primer fallo
```

Las pruebas usan la base `gymlog_test` (la crea `docker compose` la primera vez que arranca el
volumen) y **se niegan a correr contra una base cuyo nombre no contenga `_test`**, para no tocar
tus datos reales.

Si PowerShell bloquea la ejecución del script (`… no se puede cargar porque la ejecución de
scripts está deshabilitada`), habilítalo para tu usuario una sola vez:

```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```

…o ejecútalo puntualmente sin cambiar la política:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\test.ps1
```

### d. Desarrollo sin Docker para la app

Puedes dejar solo la base de datos en Docker y correr la app directamente con uv, que recarga al
guardar. Si antes levantaste todo con `docker compose up -d`, el contenedor de la app ya está
ocupando el puerto 8000, así que primero detenlo (`docker compose stop app`) para que uvicorn
pueda usar ese puerto:

```powershell
docker compose up -d db
docker compose stop app
uv run uvicorn app.main:app --reload
```

La app queda en <http://127.0.0.1:8000> y el estado en <http://127.0.0.1:8000/healthz>.

Fuera de Docker los estilos no se compilan solos. Descarga el
[binario standalone de Tailwind](https://github.com/tailwindlabs/tailwindcss/releases/tag/v4.3.5)
para Windows (`tailwindcss-windows-x64.exe`, **versión v4.3.5**, la misma que usa el `Dockerfile`),
renómbralo a `tailwindcss.exe` en la raíz del proyecto y déjalo compilando el CSS:

```powershell
.\tailwindcss.exe -i app/static/css/input.css -o app/static/css/app.css --watch
```

### e. Comandos de uso diario

| Acción | Comando |
| --- | --- |
| Levantar (base + app) | `docker compose up -d` |
| Reconstruir la imagen y levantar | `docker compose up -d --build` |
| Ver estado de los servicios | `docker compose ps` |
| Ver logs de la app | `docker compose logs -f app` |
| Aplicar migraciones | `docker compose run --rm app alembic upgrade head` |
| Apagar | `docker compose down` |
| Agregar una dependencia | `uv add <paquete>` |
| Agregar una dependencia de desarrollo | `uv add --dev <paquete>` |
| Corregir el formato | `uv run ruff format .` |

### f. Solución de problemas

| Síntoma | Causa | Solución |
| --- | --- | --- |
| `failed to connect to the docker API … dockerDesktopLinuxEngine` | Docker Desktop está cerrado o su motor no terminó de arrancar. | Abre Docker Desktop y espera a ver «Engine running»; luego repite el comando. |
| `uv : El término 'uv' no se reconoce …` | uv no está instalado, o instalaste uv sin reabrir PowerShell. | Instala uv (ver Requisitos) y abre una nueva ventana de PowerShell. |
| `password authentication failed for user "gymlog"` al correr las pruebas | La contraseña que usaste no coincide con la del `.env` (o la base se creó con otra). | Corre las pruebas con `.\scripts\test.ps1`, que toma la contraseña del `.env`. Si la cambiaste después de crear el volumen, recréalo con `docker compose down -v`. |
| El puerto 5432 está ocupado / `bind: address already in use` | Hay un PostgreSQL instalado en Windows ocupando el puerto. | Revisa con `Get-Service *postgres*` y detén el servicio, o cambia el puerto publicado. |
| El script de inicio de PostgreSQL falla con un error que menciona `\r` | Los `.sh` quedaron con finales de línea CRLF (Windows). | Clona el repo de nuevo: `.gitattributes` fuerza finales de línea LF para los scripts en clones nuevos. Como ese script de inicio solo corre la primera vez que arranca el volumen, recréalo con `docker compose down -v` (borra los datos) y vuelve a levantar. |
| Archivos «bloqueados», errores de permisos o Git muy lento | OneDrive está sincronizando la carpeta del proyecto. | Mueve el proyecto fuera de OneDrive o excluye esa carpeta de la sincronización. |

## Migraciones

```powershell
uv run alembic revision --autogenerate -m "descripcion corta"
uv run alembic upgrade head
```

Revisa siempre el archivo generado antes de aplicarlo.

## CI

Cada push y pull request corre ruff y pytest contra PostgreSQL. Cada push a `main` que pasa las
pruebas publica la imagen en `ghcr.io/luisabadu/gymlog` con las etiquetas `latest` y el SHA corto.
El paquete en GHCR queda **privado por defecto**: para usarlo desde otra máquina hay que hacer
login en el registro (o cambiar su visibilidad a público en GitHub).
