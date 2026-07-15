param(
  [switch]$SkipFlutter,   # Lewati flutter build (gunakan jika sudah ada release build)
  [switch]$Debug          # Build debug instead of release
)

$ErrorActionPreference = "Stop"
$config = if ($Debug) { "debug" } else { "release" }
$configCap = if ($Debug) { "Debug" } else { "Release" }

Write-Host ""
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "  Kuma Anime Windows Installer Builder" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""

# ── 1. VCPKG ────────────────────────────────────────────────────────────────
if (-not $env:VCPKG_ROOT -and (Test-Path "C:\vcpkg")) {
  $env:VCPKG_ROOT = "C:\vcpkg"
  Write-Host "[1/4] Auto-setting VCPKG_ROOT=$env:VCPKG_ROOT" -ForegroundColor Yellow
}

# ── 2. Flutter build ─────────────────────────────────────────────────────────
if (-not $SkipFlutter) {
  Write-Host "[2/4] Building Flutter app ($configCap)..." -ForegroundColor Green
  & flutter build windows --$config
  if ($LASTEXITCODE -ne 0) {
    Write-Error "Flutter build failed (exit $LASTEXITCODE)"
    exit 1
  }
  Write-Host "      Flutter build OK" -ForegroundColor Green
} else {
  Write-Host "[2/4] Skipping Flutter build (--SkipFlutter)" -ForegroundColor Yellow
}

# ── 3. Generate ISS script via inno_bundle ────────────────────────────────────
Write-Host "[3/4] Generating Inno Setup script..." -ForegroundColor Green
& dart run inno_bundle:build --$config --no-app --no-install-inno
# inno_bundle mungkin exit 1 karena ISCC path bermasalah – kita tangani manual
# yang penting file .iss sudah terbentuk
$issFile = "build\windows\x64\installer\$configCap\inno-script.iss"
if (-not (Test-Path $issFile)) {
  Write-Error "ISS script tidak ditemukan: $issFile"
  exit 1
}
Write-Host "      ISS script OK: $issFile" -ForegroundColor Green

# Modify the .iss script to set DefaultGroupName to Kuma Anime, preventing (Default) folder name
$issContent = Get-Content $issFile -Raw
if ($issContent -notmatch "DefaultGroupName=") {
  $issContent = $issContent -replace "\[Setup\]", "[Setup]`r`nDefaultGroupName=Kuma Anime"
  Set-Content $issFile $issContent
  Write-Host "      Injected DefaultGroupName=Kuma Anime" -ForegroundColor Yellow
}


# ── 4. Compile installer dengan ISCC ─────────────────────────────────────────
Write-Host "[4/4] Compiling installer..." -ForegroundColor Green

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
  Write-Error "ISCC.exe tidak ditemukan. Install Inno Setup dari https://jrsoftware.org/isdl.php"
  exit 1
}

Write-Host "      Using ISCC: $iscc" -ForegroundColor Yellow
& $iscc $issFile
if ($LASTEXITCODE -ne 0) {
  Write-Error "ISCC compile failed (exit $LASTEXITCODE)"
  exit 1
}

# ── Done ─────────────────────────────────────────────────────────────────────
$outputDir = "build\windows\x64\installer\$configCap"
$installer = Get-Item "$outputDir\*Installer.exe" -ErrorAction SilentlyContinue | Select-Object -First 1

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
