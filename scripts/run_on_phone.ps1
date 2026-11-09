# Lance l'application Pet Sitter sur un vrai telephone Android, branchee sur le backend du PC.
#
#   .\scripts\run_on_phone.ps1          # par cable USB (recommande) : aucun reglage reseau
#   .\scripts\run_on_phone.ps1 -Wifi    # par le Wi-Fi : PC et telephone sur le meme reseau
#
# Prerequis : MySQL (XAMPP) et le backend demarres (cd backend ; mvn spring-boot:run),
# telephone en mode developpeur avec le debogage USB autorise.
param(
    [switch]$Wifi,
    [string]$Device,
    [int]$Port = 8081
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot

# --- adb (outil Android) ---
$adb = (Get-Command adb -ErrorAction SilentlyContinue).Source
if (-not $adb) { $adb = Join-Path $env:LOCALAPPDATA 'Android\Sdk\platform-tools\adb.exe' }
if (-not (Test-Path $adb)) { throw "adb introuvable. Installez les Android SDK Platform-Tools." }

# --- Telephone : le premier appareil physique (pas un emulateur) ---
if (-not $Device) {
    $Device = & $adb devices |
        Select-Object -Skip 1 |
        Where-Object { $_ -match "`tdevice$" -and $_ -notmatch '^emulator-' } |
        ForEach-Object { ($_ -split "`t")[0] } |
        Select-Object -First 1
}
if (-not $Device) {
    throw "Aucun telephone detecte. Branchez-le en USB, activez le debogage USB et acceptez l'empreinte du PC sur l'ecran du telephone."
}
Write-Host "Telephone : $Device" -ForegroundColor Green

# --- Le backend repond-il sur le PC ? ---
function Test-Port([string]$HostName, [int]$P) {
    $client = New-Object System.Net.Sockets.TcpClient
    try { return $client.ConnectAsync($HostName, $P).Wait(1500) -and $client.Connected }
    catch { return $false }
    finally { $client.Dispose() }
}
if (-not (Test-Port 'localhost' $Port)) {
    Write-Warning "Le backend ne repond pas sur le port $Port. Demarrez MySQL (XAMPP) puis : cd backend ; mvn spring-boot:run"
}

# --- Adresse de l'API vue depuis le telephone ---
if ($Wifi) {
    $ip = Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
        Where-Object { $_.InterfaceAlias -like 'Wi-Fi*' -and $_.IPAddress -notlike '169.254.*' } |
        Select-Object -First 1 -ExpandProperty IPAddress
    if (-not $ip) { throw "Adresse Wi-Fi du PC introuvable. Le PC est-il connecte en Wi-Fi ?" }
    $api = "http://${ip}:$Port/api"
    Write-Host "Mode Wi-Fi : le telephone doit etre sur le meme reseau que le PC." -ForegroundColor Yellow
    Write-Host "Si l'app n'arrive pas a joindre le serveur, autorisez Java (port $Port) dans le pare-feu Windows." -ForegroundColor Yellow
} else {
    # Le port $Port du telephone est renvoye vers le PC par le cable USB.
    & $adb -s $Device reverse "tcp:$Port" "tcp:$Port" | Out-Null
    $api = "http://localhost:$Port/api"
    Write-Host "Mode USB : localhost:$Port du telephone -> backend du PC (gardez le cable branche)." -ForegroundColor Green
}

Write-Host "API : $api" -ForegroundColor Green
Set-Location $root
flutter run -d $Device "--dart-define=API_BASE_URL=$api"
