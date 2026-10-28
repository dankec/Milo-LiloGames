param([string]$Godot = "godot", [string]$Out = "dist\Milo-Lilo-debug.apk")
$ErrorActionPreference = "Stop"
$gameDir = Split-Path -Parent $PSScriptRoot
Set-Location $gameDir
if (-not (Test-Path "assets\characters\milo_idle.png")) {
    python -m pip install Pillow
    python tools\make_art.py
    python tools\make_audio.py
}
New-Item -ItemType Directory -Force -Path "dist" | Out-Null
& $Godot --headless --path . --editor --quit
if ($LASTEXITCODE -ne 0) { throw "Godot import failed" }
& $Godot --headless --path . --export-debug Android $Out
if ($LASTEXITCODE -ne 0) { throw "APK build failed" }
Write-Host "Built: $Out"
