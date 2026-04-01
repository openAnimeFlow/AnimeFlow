; =============================================================================
; AnimeFlow - Inno Setup 安装脚本
; =============================================================================
; 1. 构建 Release：
;      flutter build windows --release
; 2. 用 Inno Setup Compiler 打开本文件并编译
;
; 本地发布前：把下一行占位符 "version" 改成与 pubspec.yaml 一致的 x.y.z。
; CI（build.yml）会在编译安装包前自动将 "version" 替换为 pubspec 的 x.y.z。
; 覆盖升级：勿修改 MyAppGuid / AppId；仅提高版本号。检测到旧版时会默认沿用原安装目录并覆盖文件。
; =============================================================================

#define MyAppName       "AnimeFlow"
#define MyAppVersion    "version"
#define MyAppExeName    "AnimeFlow.exe"
#define MyAppPublisher  "AnimeFlow"
#define MyAppURL        "https://github.com/openAnimeFlow/AnimeFlow"

; Flutter Windows x64 构建输出目录（相对本 .iss 所在目录，即项目根目录）
#define BuildSourceDir  "build\windows\x64\runner\Release"

#define OutputBaseName  "AnimeFlow-Setup-" + MyAppVersion
#define OutputDir       "."

; 固定 AppId（GUID 本体，不含花括号）以便覆盖安装与干净卸载；勿随意更改
#define MyAppGuid       "B8E4F2A1-3C7D-5E9F-8A1B-2D4F6E8C0A9B"
#define AppIdEscaped    "{{" + MyAppGuid + "}}"

[Setup]
AppId={#AppIdEscaped}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={autopf64}\{#MyAppName}
DefaultGroupName={#MyAppName}
AllowNoIcons=yes
OutputDir={#OutputDir}
OutputBaseFilename={#OutputBaseName}
SetupIconFile=windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\{#MyAppExeName}
UninstallDisplayName={#MyAppName}
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=admin
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
; 覆盖安装 / 升级：与旧版共用 AppId 时沿用上次安装目录与开始菜单位置
UsePreviousAppDir=yes
UsePreviousGroup=yes
UsePreviousTasks=yes
UsePreviousSetupType=yes
; 已检测到旧版时自动跳过对应向导页，减少误选路径
DisableDirPage=auto
DisableProgramGroupPage=auto
DisableWelcomePage=no
CloseApplications=yes
; 互斥体勿含版本号，保证任意新版安装包与旧版不能同时跑两个安装向导
SetupMutex=AnimeFlowSetup_{#MyAppGuid}
RestartApplications=no
ShowLanguageDialog=yes
MinVersion=10.0
UsedUserAreasWarning=no
VersionInfoVersion={#MyAppVersion}.0
VersionInfoCompany={#MyAppPublisher}
VersionInfoDescription={#MyAppName} 
VersionInfoProductName={#MyAppName}
VersionInfoProductVersion={#MyAppVersion}

[Languages]
Name: "chinesesimp"; MessagesFile: "compiler:Languages\Chinese.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked
Name: "quicklaunch"; Description: "{cm:CreateQuickLaunchIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked; OnlyBelowVersion: 6.1; Check: not IsAdminInstallMode

[Files]
Source: "{#BuildSourceDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; WorkingDir: "{app}"
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; WorkingDir: "{app}"; Tasks: desktopicon
Name: "{userappdata}\Microsoft\Internet Explorer\Quick Launch\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; WorkingDir: "{app}"; Tasks: quicklaunch

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#MyAppName}}"; Flags: nowait postinstall skipifsilent
