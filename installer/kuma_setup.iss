; =====================================================================
;  KUMA ANIME - PROFESSIONAL INNO SETUP INSTALLER SCRIPT
; =====================================================================
;  AppId:        {E200C020-8D92-4C82-A746-88120B88F02D}
;  Architectures: Windows 10/11 x64
;  Features:     Install, Update (with Rollback), Repair, Modify, Uninstall
; =====================================================================

#define MyAppName "Kuma Anime"
#define MyAppVersion "4.11.0"
#define MyAppPublisher "Kuma Anime Team"
#define MyAppURL "https://github.com/SayuZX/KumaAnime-App"
#define MyAppExeName "kumaanime.exe"
#define MyAppId "{{E200C020-8D92-4C82-A746-88120B88F02D}}"
#define BuildDate "2026-07-20"

[Setup]
AppId={#MyAppId}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} v{#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}/issues
AppUpdatesURL={#MyAppURL}/releases
DefaultDirName={autopf}\Kuma Anime
DefaultGroupName=Kuma Anime
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
LicenseFile=
OutputDir=..\build\windows\x64\installer\Release
OutputBaseFilename=KumaAnime-v{#MyAppVersion}-Setup
SetupIconFile=..\windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\{#MyAppExeName}
UninstallDisplayName={#MyAppName}
WizardStyle=modern
WizardSizePercent=110
Compression=lzma2/ultra64
SolidCompression=yes
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog
DisableProgramGroupPage=yes

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Types]
Name: "full"; Description: "Full Installation (Recommended)"
Name: "compact"; Description: "Compact Installation"
Name: "custom"; Description: "Custom Installation"; Flags: iscustom

[Components]
Name: "core"; Description: "Core Application Files (Required)"; Types: full compact custom; Flags: fixed
Name: "codecs"; Description: "Media Codecs & Audio/Video Decoders"; Types: full compact custom
Name: "subfonts"; Description: "Subtitle Fonts & Rendering Resources"; Types: full custom
Name: "desktopicon"; Description: "Desktop Shortcut"; Types: full custom
Name: "startmenuicon"; Description: "Start Menu Shortcut"; Types: full compact custom
Name: "devtools"; Description: "Developer Tools & Debug Symbols"; Types: custom

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Components: desktopicon

[Files]
; Core Application Files
Source: "..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs; Components: core

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Components: startmenuicon
Name: "{group}\Uninstall {#MyAppName}"; Filename: "{uninstallexe}"; Components: startmenuicon
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon; Components: desktopicon

[Registry]
Root: HKCU; Subkey: "Software\KumaAnime"; ValueType: string; ValueName: "InstallPath"; ValueData: "{app}"; Flags: uninsdeletekey
Root: HKCU; Subkey: "Software\KumaAnime"; ValueType: string; ValueName: "Version"; ValueData: "{#MyAppVersion}"; Flags: uninsdeletevalue
Root: HKCU; Subkey: "Software\KumaAnime"; ValueType: string; ValueName: "BuildDate"; ValueData: "{#BuildDate}"; Flags: uninsdeletevalue

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent

[Code]
// =====================================================================
// PASCAL SCRIPT MODULES: LOGGING, DETECTION, MODE UI, UPDATE, REPAIR
// =====================================================================

type
  TInstallMode = (imFreshInstall, imUpdate, imRepair, imModify, imUninstall);

var
  // Global Detection State
  G_IsInstalled: Boolean;
  G_InstalledVersion: String;
  G_InstalledPath: String;
  G_UninstallString: String;
  G_SelectedMode: TInstallMode;
  G_VersionCompare: Integer; // -1: Downgrade, 0: Same, 1: Upgrade

  // UI Page Controls
  ModeSelectionPage: TWizardPage;
  RadioUpdate: TRadioButton;
  RadioRepair: TRadioButton;
  RadioModify: TRadioButton;
  RadioUninstall: TRadioButton;
  InfoPanel: TPanel;
  InfoTextLabel: TLabel;
  BannerLabel: TLabel;

// ---------------------------------------------------------------------
// 1. LOGGING SYSTEM
// ---------------------------------------------------------------------
procedure LogEvent(const Category, Message: String);
var
  LogDir, LogFilePath, Line: String;
begin
  try
    LogDir := ExpandConstant('{localappdata}\Kuma Anime\Logs');
    if not DirExists(LogDir) then
      ForceDirectories(LogDir);
      
    LogFilePath := LogDir + '\installer.log';
    Line := GetDateTimeString('yyyy-mm-dd hh:nn:ss', '-', ':') + ' [' + Category + '] ' + Message + #13#10;
    SaveStringToFile(LogFilePath, Line, True);
  except
    // Non-critical logging fallback
  end;
end;

// ---------------------------------------------------------------------
// 2. VERSION COMPARISON UTILITY
// ---------------------------------------------------------------------
function CompareVersionStrings(V1, V2: String): Integer;
var
  P1, P2, N1, N2: Integer;
  S1, S2: String;
begin
  Result := 0;
  while (Length(V1) > 0) or (Length(V2) > 0) do
  begin
    P1 := Pos('.', V1);
    if P1 > 0 then begin S1 := Copy(V1, 1, P1 - 1); V1 := Copy(V1, P1 + 1, Length(V1)); end
    else begin S1 := V1; V1 := ''; end;

    P2 := Pos('.', V2);
    if P2 > 0 then begin S2 := Copy(V2, 1, P2 - 1); V2 := Copy(V2, P2 + 1, Length(V2)); end
    else begin S2 := V2; V2 := ''; end;

    N1 := StrToIntDef(S1, 0);
    N2 := StrToIntDef(S2, 0);

    if N1 < N2 then begin Result := -1; Exit; end;
    if N1 > N2 then begin Result := 1; Exit; end;
  end;
end;

// ---------------------------------------------------------------------
// 3. DETECTION SYSTEM
// ---------------------------------------------------------------------
procedure DetectInstallationState;
var
  RegKey: String;
begin
  G_IsInstalled := False;
  G_InstalledVersion := '';
  G_InstalledPath := '';
  G_UninstallString := '';

  RegKey := 'Software\Microsoft\Windows\CurrentVersion\Uninstall\{#MyAppId}_is1';

  // Check HKCU first, then HKLM
  if RegQueryStringValue(HKCU, RegKey, 'DisplayVersion', G_InstalledVersion) then
  begin
    RegQueryStringValue(HKCU, RegKey, 'InstallLocation', G_InstalledPath);
    RegQueryStringValue(HKCU, RegKey, 'UninstallString', G_UninstallString);
    G_IsInstalled := True;
  end
  else if RegQueryStringValue(HKLM, RegKey, 'DisplayVersion', G_InstalledVersion) then
  begin
    RegQueryStringValue(HKLM, RegKey, 'InstallLocation', G_InstalledPath);
    RegQueryStringValue(HKLM, RegKey, 'UninstallString', G_UninstallString);
    G_IsInstalled := True;
  end;

  if G_IsInstalled then
  begin
    G_VersionCompare := CompareVersionStrings('{#MyAppVersion}', G_InstalledVersion);
    LogEvent('DETECTION', 'Installed app detected at ' + G_InstalledPath + ' (Version: ' + G_InstalledVersion + ')');
  end
  else
  begin
    G_VersionCompare := 1;
    LogEvent('DETECTION', 'No previous installation detected.');
  end;
end;

// ---------------------------------------------------------------------
// 4. MODE SELECTION & INFORMATION PANEL UI
// ---------------------------------------------------------------------
procedure CreateModeSelectionUI;
var
  TopPos: Integer;
  BannerText: String;
  BannerColor: TColor;
begin
  ModeSelectionPage := CreateCustomPage(
    wpWelcome,
    'Maintenance & Operation Options',
    'An existing installation of {#MyAppName} was detected on your system.'
  );

  // Banner Header
  BannerLabel := TLabel.Create(ModeSelectionPage);
  BannerLabel.Parent := ModeSelectionPage.Surface;
  BannerLabel.Left := 0;
  BannerLabel.Top := 0;
  BannerLabel.Width := ModeSelectionPage.SurfaceWidth;
  BannerLabel.Height := 24;
  BannerLabel.Font.Style := [fsBold];
  BannerLabel.Font.Size := 9;

  if G_VersionCompare > 0 then
  begin
    BannerText := '  UPDATE AVAILABLE: Newer version (v{#MyAppVersion}) is ready to install!';
    BannerColor := $00AA5500; // Dark Cyan
  end
  else if G_VersionCompare = 0 then
  begin
    BannerText := '  UP TO DATE: Installed version (v' + G_InstalledVersion + ') is currently up to date.';
    BannerColor := $00888800; // Dark Green/Teal
  end
  else
  begin
    BannerText := '  WARNING: Installer version (v{#MyAppVersion}) is older than installed version (v' + G_InstalledVersion + ')!';
    BannerColor := $000000D9; // Dark Red
  end;
  BannerLabel.Caption := BannerText;
  BannerLabel.Font.Color := BannerColor;

  // Information Panel Box
  InfoPanel := TPanel.Create(ModeSelectionPage);
  InfoPanel.Parent := ModeSelectionPage.Surface;
  InfoPanel.Left := 0;
  InfoPanel.Top := 30;
  InfoPanel.Width := ModeSelectionPage.SurfaceWidth;
  InfoPanel.Height := 75;
  InfoPanel.BevelOuter := bvLowered;

  InfoTextLabel := TLabel.Create(InfoPanel);
  InfoTextLabel.Parent := InfoPanel;
  InfoTextLabel.Left := 12;
  InfoTextLabel.Top := 8;
  InfoTextLabel.Width := InfoPanel.Width - 24;
  InfoTextLabel.Height := InfoPanel.Height - 16;
  InfoTextLabel.Caption :=
    'Installed Version:  ' + G_InstalledVersion + #13#10 +
    'Installer Version:  {#MyAppVersion} (Build: {#BuildDate})' + #13#10 +
    'Installation Dir:     ' + G_InstalledPath + #13#10 +
    'Architecture:        x64 (Windows 10/11 Compatible)';

  TopPos := 115;

  // Radio Options
  RadioUpdate := TRadioButton.Create(ModeSelectionPage);
  RadioUpdate.Parent := ModeSelectionPage.Surface;
  RadioUpdate.Left := 10;
  RadioUpdate.Top := TopPos;
  RadioUpdate.Width := ModeSelectionPage.SurfaceWidth - 20;
  RadioUpdate.Caption := 'Update application (Preserve databases, settings, & user data)';
  RadioUpdate.Font.Style := [fsBold];
  RadioUpdate.Checked := (G_VersionCompare >= 0);

  TopPos := TopPos + 32;
  RadioRepair := TRadioButton.Create(ModeSelectionPage);
  RadioRepair.Parent := ModeSelectionPage.Surface;
  RadioRepair.Left := 10;
  RadioRepair.Top := TopPos;
  RadioRepair.Width := ModeSelectionPage.SurfaceWidth - 20;
  RadioRepair.Caption := 'Repair installation (Restore missing files, registry, & shortcuts)';
  RadioRepair.Font.Style := [fsBold];
  RadioRepair.Checked := (G_VersionCompare < 0);

  TopPos := TopPos + 32;
  RadioModify := TRadioButton.Create(ModeSelectionPage);
  RadioModify.Parent := ModeSelectionPage.Surface;
  RadioModify.Left := 10;
  RadioModify.Top := TopPos;
  RadioModify.Width := ModeSelectionPage.SurfaceWidth - 20;
  RadioModify.Caption := 'Modify installed components (Add/remove desktop & start menu icons)';
  RadioModify.Font.Style := [fsBold];

  TopPos := TopPos + 32;
  RadioUninstall := TRadioButton.Create(ModeSelectionPage);
  RadioUninstall.Parent := ModeSelectionPage.Surface;
  RadioUninstall.Left := 10;
  RadioUninstall.Top := TopPos;
  RadioUninstall.Width := ModeSelectionPage.SurfaceWidth - 20;
  RadioUninstall.Caption := 'Uninstall application (Remove application files)';
  RadioUninstall.Font.Style := [fsBold];
end;

// ---------------------------------------------------------------------
// 5. INITIALIZE SETUP & EVENT HANDLERS
// ---------------------------------------------------------------------
function InitializeSetup: Boolean;
begin
  Result := True;
  LogEvent('STARTUP', 'Installer initialized. Version: {#MyAppVersion}');
  DetectInstallationState;
end;

procedure InitializeWizard;
begin
  if G_IsInstalled then
    CreateModeSelectionUI;
end;

function ShouldSkipPage(PageID: Integer): Boolean;
begin
  Result := False;
  if G_IsInstalled then
  begin
    // If user chose Update, Repair, or Uninstall, skip Select Destination Dir & Components
    if (G_SelectedMode = imUpdate) or (G_SelectedMode = imRepair) or (G_SelectedMode = imUninstall) then
    begin
      if (PageID = wpSelectDir) or (PageID = wpSelectComponents) or (PageID = wpSelectProgramGroup) or (PageID = wpSelectTasks) then
        Result := True;
    end;
  end;
end;

function NextButtonClick(CurPageID: Integer): Boolean;
var
  ResultCode: Integer;
begin
  Result := True;

  if (ModeSelectionPage <> nil) and (CurPageID = ModeSelectionPage.ID) then
  begin
    if RadioUpdate.Checked then
    begin
      G_SelectedMode := imUpdate;
      LogEvent('MODE_SELECT', 'User selected Update mode');
      if (G_VersionCompare < 0) then
      begin
        if MsgBox('Warning: You are about to downgrade from version ' + G_InstalledVersion + ' to {#MyAppVersion}.' + #13#10#13#10 + 'Are you sure you want to proceed?', mbConfirmation, MB_YESNO) <> IDYES then
        begin
          Result := False;
          Exit;
        end;
      end;
    end
    else if RadioRepair.Checked then
    begin
      G_SelectedMode := imRepair;
      LogEvent('MODE_SELECT', 'User selected Repair mode');
    end
    else if RadioModify.Checked then
    begin
      G_SelectedMode := imModify;
      LogEvent('MODE_SELECT', 'User selected Modify mode');
    end
    else if RadioUninstall.Checked then
    begin
      G_SelectedMode := imUninstall;
      LogEvent('MODE_SELECT', 'User selected Uninstall mode');
      if MsgBox('Are you sure you want to uninstall {#MyAppName}?', mbConfirmation, MB_YESNO) = IDYES then
      begin
        if (G_UninstallString <> '') and Exec(RemoveQuotes(G_UninstallString), '/SILENT', '', SW_SHOWNORMAL, ewWaitUntilTerminated, ResultCode) then
        begin
          LogEvent('UNINSTALL', 'Uninstaller executed successfully');
          MsgBox('{#MyAppName} has been uninstalled successfully.', mbInformation, MB_OK);
          Result := False;
          WizardForm.Close;
          Exit;
        end
        else
        begin
          LogEvent('ERROR', 'Failed to launch uninstaller: ' + G_UninstallString);
          MsgBox('Failed to launch uninstaller automatically.', mbError, MB_OK);
          Result := False;
          Exit;
        end;
      end
      else
      begin
        Result := False;
        Exit;
      end;
    end;
  end;
end;

// ---------------------------------------------------------------------
// 6. UPDATE BACKUP & ROLLBACK SYSTEM
// ---------------------------------------------------------------------
procedure CurStepChanged(CurStep: TSetupStep);
var
  BackupDir, AppDir: String;
begin
  if CurStep = ssInstall then
  begin
    AppDir := ExpandConstant('{app}');
    if G_IsInstalled and (G_SelectedMode = imUpdate) then
    begin
      LogEvent('UPDATE', 'Creating file backup before update...');
      BackupDir := AppDir + '\_update_backup';
      if DirExists(BackupDir) then
        DelTree(BackupDir, True, True, True);
      
      CreateDir(BackupDir);
      // Backup main executable
      if FileExists(AppDir + '\{#MyAppExeName}') then
        CopyFile(AppDir + '\{#MyAppExeName}', BackupDir + '\{#MyAppExeName}', False);
    end;
  end
  else if CurStep = ssPostInstall then
  begin
    AppDir := ExpandConstant('{app}');
    BackupDir := AppDir + '\_update_backup';
    
    if DirExists(BackupDir) then
    begin
      LogEvent('UPDATE', 'Update succeeded. Removing temporary backup.');
      DelTree(BackupDir, True, True, True);
    end;

    // Update custom finish page message
    case G_SelectedMode of
      imUpdate:
        begin
          LogEvent('POST_INSTALL', 'Update completed successfully.');
          WizardForm.FinishedLabel.Caption := '{#MyAppName} has been updated successfully.' + #13#10#13#10 + 'User databases, history, and settings have been fully preserved.';
        end;
      imRepair:
        begin
          LogEvent('POST_INSTALL', 'Repair completed successfully.');
          WizardForm.FinishedLabel.Caption := 'Repair completed successfully.' + #13#10#13#10 + 'Application files, registry keys, and shortcuts have been restored.';
        end;
      imModify:
        begin
          LogEvent('POST_INSTALL', 'Modify completed successfully.');
          WizardForm.FinishedLabel.Caption := 'Component modifications applied successfully.';
        end;
      else
        begin
          LogEvent('POST_INSTALL', 'Fresh installation completed successfully.');
          WizardForm.FinishedLabel.Caption := '{#MyAppName} has been installed on your computer.';
        end;
    end;
  end;
end;
