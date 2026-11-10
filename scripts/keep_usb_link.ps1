# Garde la liaison USB entre le telephone et le backend du PC, meme apres un debranchement.
#
#   powershell -ExecutionPolicy Bypass -File scripts\keep_usb_link.ps1
#
# Android efface la liaison "adb reverse" a chaque debranchement du cable : le telephone ne
# joint plus localhost:8081 et l'application passe "Hors ligne". Ce script verifie toutes les
# 2 secondes et refait la liaison des que le telephone est rebranche. Ctrl+C pour l'arreter.
param(
    [int]$Port = 8081,
    [int]$EverySeconds = 2
)

$adb = (Get-Command adb -ErrorAction SilentlyContinue).Source
if (-not $adb) { $adb = Join-Path $env:LOCALAPPDATA 'Android\Sdk\platform-tools\adb.exe' }
if (-not (Test-Path $adb)) { throw "adb introuvable. Installez les Android SDK Platform-Tools." }

Write-Host "Surveillance de la liaison USB (port $Port). Ctrl+C pour arreter." -ForegroundColor Green
$linked = @{}
while ($true) {
    $devices = & $adb devices 2>$null | Select-Object -Skip 1 |
        Where-Object { $_ -match "`tdevice$" -and $_ -notmatch '^emulator-' } |
        ForEach-Object { ($_ -split "`t")[0] }
    foreach ($device in $devices) {
        $reverse = & $adb -s $device reverse --list 2>$null
        if (-not ($reverse -match "tcp:$Port")) {
            & $adb -s $device reverse "tcp:$Port" "tcp:$Port" 2>$null | Out-Null
            Write-Host ("[{0}] Liaison retablie : {1} -> backend du PC (port {2})" -f (Get-Date -Format 'HH:mm:ss'), $device, $Port) -ForegroundColor Green
        }
        $linked[$device] = $true
    }
    foreach ($device in @($linked.Keys)) {
        if ($devices -notcontains $device) {
            Write-Host ("[{0}] Telephone {1} debranche : liaison refaite au rebranchement." -f (Get-Date -Format 'HH:mm:ss'), $device) -ForegroundColor Yellow
            $linked.Remove($device)
        }
    }
    Start-Sleep -Seconds $EverySeconds
}
