# release.ps1 — Release packaging script
#
# Builds, packages, and versions the application for distribution.

param (
    [string]$Version = "1.0.0",
    [switch]$SkipBuild
)

$ErrorActionPreference = "Stop"

Write-Host "=== AI Weather Wallpaper Release v$Version ===" -ForegroundColor Cyan

# Build if not skipped
if (-not $SkipBuild) {
    & "$PSScriptRoot\build.ps1" -Mode release
    if ($LASTEXITCODE -ne 0) { throw "Build failed" }
}

# Define paths
$buildDir = Resolve-Path (Join-Path $PSScriptRoot ".." "apps" "desktop_app" "build" "windows" "release")
$outputDir = Join-Path $PSScriptRoot ".." "dist" "AI_Weather_Wallpaper_v$Version"

Write-Host "Packaging release to: $outputDir" -ForegroundColor Yellow

# Create output directory
New-Item -ItemType Directory -Force -Path $outputDir | Out-Null

# Copy build output
Copy-Item -Recurse -Force "$buildDir\*" $outputDir

# Create version file
"$Version" | Out-File -FilePath (Join-Path $outputDir "version.txt")

Write-Host "Release v$Version packaged successfully." -ForegroundColor Green
Write-Host "Output: $outputDir" -ForegroundColor Green
