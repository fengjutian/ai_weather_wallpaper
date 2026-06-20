# build.ps1 — Flutter Windows build script
#
# Builds the desktop application in release mode for Windows.
# Run from the repository root.

param (
    [string]$Mode = "release",
    [switch]$Clean
)

$ErrorActionPreference = "Stop"

Write-Host "=== AI Weather Wallpaper Build ===" -ForegroundColor Cyan

# Navigate to the desktop app directory
$desktopApp = Join-Path $PSScriptRoot ".." "apps" "desktop_app"
Set-Location (Resolve-Path $desktopApp)

if ($Clean) {
    Write-Host "Cleaning previous build..." -ForegroundColor Yellow
    flutter clean
    if ($LASTEXITCODE -ne 0) { throw "Flutter clean failed" }
}

Write-Host "Fetching dependencies..." -ForegroundColor Yellow
flutter pub get
if ($LASTEXITCODE -ne 0) { throw "Flutter pub get failed" }

Write-Host "Building Windows ($Mode)..." -ForegroundColor Yellow
flutter build windows --$Mode
if ($LASTEXITCODE -ne 0) { throw "Flutter build failed" }

Write-Host "Build complete." -ForegroundColor Green
Write-Host "Output: build\windows\$Mode\" -ForegroundColor Green
