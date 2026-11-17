; Inno Setup script for the Keyel Windows installer.
;
; This is what turns the portable Flutter bundle (keyel.exe + the DLLs + data\)
; into a real double-click `.exe` installer the user can run, install, and
; uninstall from "Apps & features".
;
; It is driven from CI (see .github/workflows/release.yml) with three defines:
;
;   ISCC.exe /DKeyelVersion=1.1.1 ^
;            /DKeyelBundle="C:\...\build\windows\x64\runner\Release" ^
;            /DKeyelOut="C:\...\dist" ^
;            packaging\windows\keyel.iss
;
; which produces dist\keyel-v<version>-windows-x64-setup.exe.
;
; Why Inno Setup: it is preinstalled on the windows-2022 GitHub runner image
; (6.7.1), it is a single self-contained compiler, and it produces a signed-able
; classic installer with an uninstaller, Start-menu entries and an optional
; desktop shortcut — everything a Windows user expects from a `.exe`.

#ifndef KeyelVersion
  #error KeyelVersion is required (e.g. /DKeyelVersion=1.1.1)
#endif
#ifndef KeyelBundle
  #error KeyelBundle is required (absolute path to the built Release directory)
#endif
#ifndef KeyelOut
  #error KeyelOut is required (absolute path to the output directory)
#endif

#define KeyelName "Keyel"
#define KeyelExe "keyel.exe"
#define KeyelUrl "https://github.com/Abdogouhmad/keyel"

[Setup]
; A STABLE AppId is what lets a newer installer upgrade (and the uninstaller
; clean up) an existing install; it must never change between releases.
AppId={{8F3A9C1E-4B7D-4E2A-9C6F-1A2B3C4D5E6F}
AppName={#KeyelName}
AppVersion={#KeyelVersion}
AppVerName={#KeyelName} {#KeyelVersion}
AppPublisher={#KeyelName}
AppPublisherURL={#KeyelUrl}
AppSupportURL={#KeyelUrl}
AppUpdatesURL={#KeyelUrl}/releases
DefaultDirName={autopf}\{#KeyelName}
DefaultGroupName={#KeyelName}
DisableProgramGroupPage=yes
; Per-user install: no UAC prompt, installs under %LOCALAPPDATA%\Programs,
; which suits a portable, privacy-first app that keeps its vault in user storage.
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
OutputDir={#KeyelOut}
OutputBaseFilename=keyel-v{#KeyelVersion}-windows-x64-setup
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
UninstallDisplayName={#KeyelName} {#KeyelVersion}
UninstallDisplayIcon={app}\{#KeyelExe}

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
; The whole Flutter bundle. `recursesubdirs createallsubdirs` walks data\ etc.
Source: "{#KeyelBundle}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#KeyelName}"; Filename: "{app}\{#KeyelExe}"
Name: "{group}\{cm:UninstallProgram,{#KeyelName}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#KeyelName}"; Filename: "{app}\{#KeyelExe}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#KeyelExe}"; Description: "{cm:LaunchProgram,{#KeyelName}}"; Flags: nowait postinstall skipifsilent
