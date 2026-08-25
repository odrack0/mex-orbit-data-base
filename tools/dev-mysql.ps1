# Arranca el MySQL 8 portable de desarrollo (C:\Tools\mysql8, puerto 3307).
# No toca la MariaDB del prototipo legado (3306). Primera vez: inicializa el datadir.
# Uso:  .\tools\dev-mysql.ps1          (arranca si no esta corriendo)
#       .\tools\dev-mysql.ps1 -Stop    (apagado limpio)
param([switch]$Stop)

$base = 'C:\Tools\mysql8'
$data = "$base\data"
$mysqld = "$base\bin\mysqld.exe"
$mysqladmin = "$base\bin\mysqladmin.exe"

if (-not (Test-Path $mysqld)) {
    Write-Error "No existe $mysqld - ver docs/esquema-v1.md para la instalacion portable."
    exit 1
}

if ($Stop) {
    & $mysqladmin -u root --port=3307 --protocol=TCP shutdown
    Write-Host 'MySQL de dev apagado.'
    exit 0
}

$vivo = Get-NetTCPConnection -LocalPort 3307 -State Listen -ErrorAction SilentlyContinue
if ($vivo) {
    Write-Host 'MySQL de dev ya esta corriendo en 3307.'
    exit 0
}

if (-not (Test-Path "$data\mysql")) {
    Write-Host 'Primera vez: inicializando datadir (root sin contrasena, solo dev local)...'
    & $mysqld --initialize-insecure --basedir=$base --datadir=$data | Out-Null
}

Start-Process -FilePath $mysqld -ArgumentList "--basedir=$base", "--datadir=$data", '--port=3307', '--console' -WindowStyle Hidden
Write-Host 'MySQL de dev arrancando en 3307 (root sin contrasena)...'
