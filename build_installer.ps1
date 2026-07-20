param(
  [switch]$SkipFlutter,   # Skip flutter build (use if release build already exists)
  [switch]$Debug          # Build debug instead of release
)

$ErrorActionPreference = "Stop"
$config = if ($Debug) { "debug" } else { "release" }
$configCap = if ($Debug) { "Debug" } else { "Release" }

Write-Host ""
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "  Kuma Anime Windows Installer Builder (Professional)" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""

if (-not $env:VCPKG_ROOT -and (Test-Path "C:\vcpkg")) {
  $env:VCPKG_ROOT = "C:\vcpkg"
  Write-Host "[1/3] Auto-setting VCPKG_ROOT=$env:VCPKG_ROOT" -ForegroundColor Yellow
}

if (-not $SkipFlutter) {
  Write-Host "[2/3] Building Flutter app ($configCap)..." -ForegroundColor Green
  & flutter build windows --$config -v
  if ($LASTEXITCODE -ne 0) {
    Write-Error "Flutter build failed (exit $LASTEXITCODE)"
    exit 1
  }
  Write-Host "      Flutter build OK" -ForegroundColor Green
} else {
  Write-Host "[2/3] Skipping Flutter build (--SkipFlutter)" -ForegroundColor Yellow
}

$issFile = "installer\kuma_setup.iss"
if (-not (Test-Path $issFile)) {
  Write-Error "Inno Setup script not found: $issFile"
  exit 1
}

# Ensure destination output dir exists
$outputDir = "build\windows\x64\installer\$configCap"
if (-not (Test-Path $outputDir)) {
  New-Item -ItemType Directory -Force -Path $outputDir | Out-Null
}

Write-Host "[3/3] Compiling Inno Setup installer..." -ForegroundColor Green

$isccPaths = @(
  "C:\Program Files (x86)\Inno Setup 6\ISCC.exe",
  "C:\Program Files\Inno Setup 6\ISCC.exe",
  "C:\Program Files (x86)\Inno Setup 7\ISCC.exe",
  "C:\Program Files\Inno Setup 7\ISCC.exe"
)

$iscc = $null
foreach ($p in $isccPaths) {
  if (Test-Path $p) { $iscc = $p; break }
}

if (-not $iscc) {
  Write-Error "ISCC.exe not found. Please install Inno Setup 6 or 7 from https://jrsoftware.org/isdl.php"
  exit 1
}

Write-Host "      Using ISCC: $iscc" -ForegroundColor Yellow
& $iscc $issFile
if ($LASTEXITCODE -ne 0) {
  Write-Error "ISCC compile failed (exit $LASTEXITCODE)"
  exit 1
}

$installer = Get-Item "$outputDir\*Setup.exe" -ErrorAction SilentlyContinue | Select-Object -First 1

Write-Host ""
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "  Build complete!" -ForegroundColor Cyan
if ($installer) {
  $sizeMb = [math]::Round($installer.Length / 1MB, 1)
  Write-Host "  Output : $($installer.FullName)" -ForegroundColor White
  Write-Host "  Size   : $sizeMb MB" -ForegroundColor White
}
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""
