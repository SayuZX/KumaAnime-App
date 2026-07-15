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

if (-not $env:VCPKG_ROOT -and (Test-Path "C:\vcpkg")) {
  $env:VCPKG_ROOT = "C:\vcpkg"
  Write-Host "[1/4] Auto-setting VCPKG_ROOT=$env:VCPKG_ROOT" -ForegroundColor Yellow
}

if (-not $SkipFlutter) {
  Write-Host "[2/4] Building Flutter app ($configCap)..." -ForegroundColor Green
  & flutter build windows --$config -v
  if ($LASTEXITCODE -ne 0) {
    Write-Error "Flutter build failed (exit $LASTEXITCODE)"
    exit 1
  }
  Write-Host "      Flutter build OK" -ForegroundColor Green
} else {
  Write-Host "[2/4] Skipping Flutter build (--SkipFlutter)" -ForegroundColor Yellow
}

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
  Write-Host "      Injected DefaultGroupName=Kuma Anime" -ForegroundColor Yellow
}

# Inject custom wizard sidebar image (WizardImageFile) and small image (WizardSmallImageFile)
$projectRoot = (Get-Item .).FullName
$installerAssets = "$projectRoot\assets\installer"
if ((Test-Path "$installerAssets\wizard_image.bmp") -and ($issContent -notmatch "WizardImageFile=")) {
  $wizardImageLine = "WizardImageFile=$installerAssets\wizard_image.bmp,$installerAssets\wizard_image_125.bmp,$installerAssets\wizard_image_150.bmp,$installerAssets\wizard_image_200.bmp"
  $wizardSmallLine = "WizardSmallImageFile=$installerAssets\wizard_small.bmp,$installerAssets\wizard_small_125.bmp,$installerAssets\wizard_small_150.bmp,$installerAssets\wizard_small_200.bmp"
  $issContent = $issContent -replace "\[Setup\]", "[Setup]`r`n$wizardImageLine`r`n$wizardSmallLine"
  Write-Host "      Injected custom WizardImageFile & WizardSmallImageFile" -ForegroundColor Yellow
}

# Inject GitHub update checking [Code] section into the .iss script
if ($issContent -notmatch "\[Code\]") {
  $updateCheckCode = @"

[Code]
const
  GITHUB_API = 'https://api.github.com/repos/SayuZX/KumaAnime-App/releases/latest';
  GITHUB_RELEASES = 'https://github.com/SayuZX/KumaAnime-App/releases/latest';

function GetLatestVersion: String;
var
  WinHttpReq: Variant;
  ResponseText: String;
  TagPos, TagEnd: Integer;
begin
  Result := '';
  try
    WinHttpReq := CreateOleObject('WinHttp.WinHttpRequest.5.1');
    WinHttpReq.Open('GET', GITHUB_API, False);
    WinHttpReq.SetRequestHeader('User-Agent', 'KumaAnime-Installer');
    WinHttpReq.SetRequestHeader('Accept', 'application/vnd.github.v3+json');
    WinHttpReq.Send('');
    if WinHttpReq.Status = 200 then
    begin
      ResponseText := WinHttpReq.ResponseText;
      TagPos := Pos('"tag_name":', ResponseText);
      if TagPos > 0 then
      begin
        TagPos := Pos('"', ResponseText, TagPos + 11) + 1;
        TagEnd := Pos('"', ResponseText, TagPos);
        Result := Copy(ResponseText, TagPos, TagEnd - TagPos);
        if (Length(Result) > 0) and (Result[1] = 'v') then
          Result := Copy(Result, 2, Length(Result) - 1);
      end;
    end;
  except
  end;
end;

function CompareVersions(V1, V2: String): Integer;
var
  P1, P2: Integer;
  S1, S2: String;
  N1, N2: Integer;
begin
  Result := 0;
  while (Length(V1) > 0) or (Length(V2) > 0) do
  begin
    P1 := Pos('.', V1);
    if P1 > 0 then begin S1 := Copy(V1, 1, P1-1); V1 := Copy(V1, P1+1, Length(V1)); end
    else begin S1 := V1; V1 := ''; end;
    P2 := Pos('.', V2);
    if P2 > 0 then begin S2 := Copy(V2, 1, P2-1); V2 := Copy(V2, P2+1, Length(V2)); end
    else begin S2 := V2; V2 := ''; end;
    N1 := StrToIntDef(S1, 0);
    N2 := StrToIntDef(S2, 0);
    if N1 < N2 then begin Result := -1; Exit; end;
    if N1 > N2 then begin Result := 1; Exit; end;
  end;
end;

function InitializeSetup: Boolean;
var
  LatestVer, CurrentVer: String;
  ErrorCode: Integer;
begin
  Result := True;
  CurrentVer := '{#SetupSetting("AppVersion")}';
  LatestVer := GetLatestVersion();
  if (LatestVer <> '') and (CompareVersions(CurrentVer, LatestVer) < 0) then
  begin
    if MsgBox(
      'A newer version of Kuma Anime is available!' + #13#10 + #13#10 +
      'Installed version: ' + CurrentVer + #13#10 +
      'Latest version: ' + LatestVer + #13#10 + #13#10 +
      'Would you like to download the latest version?' + #13#10 +
      '(Click Yes to open the download page, No to continue installation)',
      mbConfirmation, MB_YESNO) = IDYES then
    begin
      ShellExec('open', GITHUB_RELEASES, '', '', SW_SHOWNORMAL, ewNoWait, ErrorCode);
      Result := False;
    end;
  end;
end;
"@
  $issContent = $issContent + $updateCheckCode
  Write-Host "      Injected GitHub update checking [Code] section" -ForegroundColor Yellow
}

Set-Content $issFile $issContent

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
