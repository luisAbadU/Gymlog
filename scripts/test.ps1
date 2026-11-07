#Requires -Version 5.1
<#
.SYNOPSIS
    Corre las pruebas (pytest) contra la base de pruebas sin tener que escribir la contrasena.

.DESCRIPTION
    Lee POSTGRES_USER, POSTGRES_PASSWORD y POSTGRES_DB del archivo .env de la raiz del proyecto,
    arma DATABASE_URL apuntando a la base <POSTGRES_DB>_test y ejecuta `uv run pytest`.
    Los argumentos extra se pasan tal cual a pytest (por ejemplo: .\scripts\test.ps1 -k health -x).

.EXAMPLE
    .\scripts\test.ps1
    .\scripts\test.ps1 -k health
    .\scripts\test.ps1 -x -q
#>

[CmdletBinding()]
param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]] $PytestArgs
)

$ErrorActionPreference = 'Stop'

# La raiz del proyecto es la carpeta padre de la carpeta que contiene este script.
# Asi el script funciona desde cualquier carpeta de trabajo.
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptDir
$envFile = Join-Path $projectRoot '.env'

if (-not (Test-Path -LiteralPath $envFile)) {
    Write-Error "No se encontro el archivo .env en '$projectRoot'. Copialo con 'copy .env.example .env' y define la contrasena."
    exit 1
}

# Valores por defecto (coinciden con docker-compose.yml y .env.example).
$envValues = @{
    POSTGRES_USER     = 'gymlog'
    POSTGRES_PASSWORD = $null
    POSTGRES_DB       = 'gymlog'
}

# Lee el .env: lineas CLAVE=VALOR, ignora comentarios y lineas vacias.
foreach ($line in Get-Content -LiteralPath $envFile) {
    $trimmed = $line.Trim()
    if ($trimmed -eq '' -or $trimmed.StartsWith('#')) { continue }

    $separator = $trimmed.IndexOf('=')
    if ($separator -lt 1) { continue }

    $key = $trimmed.Substring(0, $separator).Trim()
    $value = $trimmed.Substring($separator + 1).Trim()
    # Quita comillas envolventes si las hay.
    if ($value.Length -ge 2 -and
        (($value.StartsWith('"') -and $value.EndsWith('"')) -or
         ($value.StartsWith("'") -and $value.EndsWith("'")))) {
        $value = $value.Substring(1, $value.Length - 2)
    }

    if ($envValues.ContainsKey($key)) {
        $envValues[$key] = $value
    }
}

if ([string]::IsNullOrEmpty($envValues['POSTGRES_PASSWORD'])) {
    Write-Error "El archivo .env no define POSTGRES_PASSWORD. Edita '$envFile' y asigna una contrasena (solo letras y numeros)."
    exit 1
}

$user = $envValues['POSTGRES_USER']
$password = $envValues['POSTGRES_PASSWORD']
$db = $envValues['POSTGRES_DB']

# DATABASE_URL solo para este proceso: la base de pruebas es <POSTGRES_DB>_test.
$databaseUrl = "postgresql+psycopg://${user}:${password}@127.0.0.1:5432/${db}_test"
$env:DATABASE_URL = $databaseUrl

Write-Host "Pruebas contra la base '${db}_test' (usuario '${user}')." -ForegroundColor Cyan

# Ejecuta pytest con uv desde la raiz, pasando los argumentos extra.
& uv run pytest @PytestArgs
exit $LASTEXITCODE
