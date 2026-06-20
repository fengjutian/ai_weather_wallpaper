# package.ps1 — Installer packaging script
#
# Generates a distributable installer using Inno Setup or
# a portable ZIP archive.

param (
    [string]$Version = "1.0.0",
    [ValidateSet("zip", "innosetup")]
    [string]$Format = "zip"
)

$ErrorActionPreference = "Stop"

Write-Host "=== AI Weather Wallpaper Package v$Version ===" -ForegroundColor Cyan

# Build release first
& "$PSScriptRoot\release.ps1" -Version $Version
if ($LASTEXITCODE -ne 0) { throw "Release step failed" }

$distDir = Resolve-Path (Join-Path $PSScriptRoot ".." "dist")
$releaseDir = Join-Path $distDir "AI_Weather_Wallpaper_v$Version"

if ($Format -eq "zip") {
    $zipPath = Join-Path $distDir "AI_Weather_Wallpaper_v$Version.zip"
    Write-Host "Creating ZIP archive: $zipPath" -ForegroundColor Yellow

    if (Test-Path $zipPath) { Remove-Item $zipPath }

    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::CreateFromDirectory($releaseDir, $zipPath)

    Write-Host "ZIP package created: $zipPath" -ForegroundColor Green
}
elseif ($Format -eq "innosetup") {
    Write-Host "Inno Setup packaging not yet implemented." -ForegroundColor Yellow
    Write-Host "TODO: Create an Inno Setup .iss script and invoke iscc.exe"
}

Write-Host "Packaging complete." -ForegroundColor Green
