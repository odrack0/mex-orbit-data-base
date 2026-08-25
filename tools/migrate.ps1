# Runner minimo de migraciones contra el MySQL de dev (3307, BD mexorbit_dev).
# Uso:  .\tools\migrate.ps1 -Version 2026.08.25.1              (rollout)
#       .\tools\migrate.ps1 -Version 2026.08.25.1 -Rollback    (rollback)
# El runner definitivo (aplicacion ordenada de N versiones) llega con E2; este
# aplica UNA version y respeta el registro en schema_migration del propio SQL.
param(
    [Parameter(Mandatory = $true)][string]$Version,
    [switch]$Rollback
)

$raiz = Split-Path -Parent $PSScriptRoot
$mysql = 'C:\Tools\mysql8\bin\mysql.exe'
$archivo = if ($Rollback) { 'rollback.sql' } else { 'rollout.sql' }
$sql = Join-Path $raiz "migrations\$Version\$archivo"

if (-not (Test-Path $sql)) { Write-Error "No existe $sql"; exit 1 }
if (-not (Test-Path $mysql)) { Write-Error "No existe $mysql - correr tools\dev-mysql.ps1 primero"; exit 1 }

& $mysql -u root --port=3307 --protocol=TCP -e 'CREATE DATABASE IF NOT EXISTS mexorbit_dev CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;'
Get-Content $sql -Raw | & $mysql -u root --port=3307 --protocol=TCP mexorbit_dev
if ($LASTEXITCODE -ne 0) { Write-Error "$archivo de $Version fallo"; exit 1 }
Write-Host "$archivo de $Version aplicado en mexorbit_dev."
