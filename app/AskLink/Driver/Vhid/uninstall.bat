@echo off
setlocal EnableExtensions EnableDelayedExpansion

rem ===== Detect OS Build & pnputil features =====
set "OSBUILD="
for /f "skip=2 tokens=2,*" %%A in ('reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v CurrentBuildNumber') do set "OSBUILD=%%B"
for /f "tokens=1 delims=." %%B in ("%OSBUILD%") do set "OSBUILD=%%B"
if "%OSBUILD%"=="" set "OSBUILD=0"

set "PNP_HAS_DELETE="
set "PNP_HAS_UNINSTALL="
for /f "delims=" %%A in ('pnputil /? ^| findstr /i /c:"delete-driver"') do set "PNP_HAS_DELETE=1"
for /f "delims=" %%A in ('pnputil /? ^| findstr /i /c:"/uninstall"') do set "PNP_HAS_UNINSTALL=1"

set "MODE=LEGACY"
if %OSBUILD% GEQ 15063 set "MODE=MODERN"
if not defined PNP_HAS_DELETE set "MODE=LEGACY"

goto :after_funcs

:RUN
setlocal EnableExtensions EnableDelayedExpansion
cmd /c %* >nul 2>&1
set "RC=!ERRORLEVEL!"
endlocal & exit /b %RC%

:RUN_DEVCON
setlocal EnableExtensions EnableDelayedExpansion
"%DEVCON%" %* >nul 2>&1
set "RC=!ERRORLEVEL!"
endlocal & exit /b %RC%

:UninstallViaINF
rem %~1 = oemXX.inf
setlocal EnableExtensions EnableDelayedExpansion
set "PKG=%~1"
set "INF=%windir%\inf\%PKG%"
if not exist "%INF%" endlocal & exit /b 1

set "SEC="
for %%S in (DefaultUninstall.NT DefaultUninstall Uninstall.NT Uninstall) do (
  findstr /i "^\[%%S\]" "%INF%" >nul 2>&1 && (set "SEC=%%S" & goto :foundSec)
)
:foundSec
if defined SEC call :RUN rundll32 setupapi,InstallHinfSection %SEC% 132 "%INF%"

if defined PNP_HAS_DELETE (
  call :RUN pnputil /delete-driver "%PKG%" /force
) else (
  call :RUN pnputil -f -d "%PKG%"
)
endlocal & exit /b %ERRORLEVEL%

:DelPkg
rem %~1 = oemXX.inf
setlocal EnableExtensions EnableDelayedExpansion
set "PKG=%~1"
set "RC=1"

if /i "%MODE%"=="MODERN" (
  if defined PNP_HAS_UNINSTALL (
    call :RUN pnputil /delete-driver "%PKG%" /uninstall /force
    set "RC=%ERRORLEVEL%"
    if not "!RC!"=="0" (
      call :RUN pnputil /delete-driver "%PKG%" /force
      set "RC=%ERRORLEVEL%"
    )
  ) else (
    call :RUN pnputil /delete-driver "%PKG%" /force
    set "RC=%ERRORLEVEL%"
  )
  if not "!RC!"=="0" (
    call :UninstallViaINF "%PKG%"
    set "RC=%ERRORLEVEL%"
  )
) else (
  call :UninstallViaINF "%PKG%"
  set "RC=%ERRORLEVEL%"
)
endlocal & exit /b %RC%

:DelPkgsFromReg
rem %~1 = HKLM\...\DeviceIds\...\DriverPackages
setlocal EnableExtensions EnableDelayedExpansion
set "REGKEY=%~1"
set "FOUND_LOCAL=0"

for /f "delims=" %%R in ('reg query "%REGKEY%" 2^>nul ^| findstr /ri "\\oem[0-9][0-9]*\.inf"') do (
  set "LINE=%%R"
  for %%P in ("!LINE!") do set "LAST=%%~nxP"
  for /f "delims=_" %%I in ("!LAST!") do set "PKG=%%I"
  set "TAG=!PKG:.=_!"
  if not defined SEEN_!TAG! (
    set "SEEN_!TAG!=1"
    call :DelPkg "!PKG!"
    if %ERRORLEVEL%==0 set /a FOUND+=1 & set /a FOUND_LOCAL+=1
  )
)
endlocal & exit /b 0

:ScanInfByContent
rem %~1 = HWID   %~2 = ALT
setlocal EnableExtensions EnableDelayedExpansion
set "HWID=%~1"
set "ALT=%~2"
set "INF_DIR=%windir%\inf"
set "HIT_ANY=0"
for /f "delims=" %%F in ('dir /b /a:-d "%INF_DIR%\oem*.inf"') do (
  set "HIT="
  (findstr /mic:"%HWID%" "%INF_DIR%\%%F" >nul 2>&1) && (findstr /mic:"Class=HIDClass" "%INF_DIR%\%%F" >nul 2>&1) && set "HIT=1"
  if not defined HIT if not "%ALT%"=="" (
    (findstr /mic:"%ALT%" "%INF_DIR%\%%F" >nul 2>&1) && (findstr /mic:"Class=HIDClass" "%INF_DIR%\%%F" >nul 2>&1) && set "HIT=1"
  )
  if defined HIT (
    call :DelPkg "%%F"
    if %ERRORLEVEL%==0 set /a FOUND+=1 & set "HIT_ANY=1"
  )
)
endlocal & exit /b 0

:DevconRemoveByPattern
rem %~1 = pattern
setlocal EnableExtensions EnableDelayedExpansion
set "PAT=%~1"

call :RUN_DEVCON remove %PAT%
call :RUN_DEVCON remove @%PAT%
call :RUN_DEVCON remove *%PAT%*
call :RUN_DEVCON remove @*%PAT%*

for /f "tokens=1 delims=:" %%I in ('cmd /d /c ^""%DEVCON%" find *%PAT%* 2^>nul ^| findstr /r /v /i "Matching"^"') do (
  set "ID=%%I"
  for /f "tokens=* delims= " %%Z in ("!ID!") do set "ID=%%Z"
  set "ID=!ID: =!"
  if defined ID call :RUN_DEVCON remove @!ID!
)
endlocal & exit /b 0

:ProcessHWID
rem %~1 = HWID   %~2 = ALT
set "HWID=%~1"
set "ALT=%~2"
set "FOUND=0"

call :DevconRemoveByPattern %HWID%
if not "%ALT%"=="" call :DevconRemoveByPattern %ALT%

set "KEY=HKLM\SYSTEM\DriverDatabase\DeviceIds\%HWID%\DriverPackages"
call :RUN reg query "%KEY%" /s
call :DelPkgsFromReg "%KEY%"

call :ScanInfByContent "%HWID%" "%ALT%"

call :DevconRemoveByPattern %HWID%
if not "%ALT%"=="" call :DevconRemoveByPattern %ALT%
call :RUN_DEVCON rescan
exit /b 0

:after_funcs
set "DEVCON="
for %%P in ("devcon.exe" "devcon64.exe" "devcon_x64.exe" "devcon_x86.exe") do (
  if exist "%~dp0%%~P" set "DEVCON=%~dp0%%~P"
)
if not defined DEVCON for /f "delims=" %%D in ('where devcon.exe 2^>nul') do if not defined DEVCON set "DEVCON=%%D"
if not defined DEVCON set "DEVCON=devcon.exe"

set "HWID1=AskLink\AskLinkHid"
if not "%~1"=="" set "HWID1=%~1"
call :ProcessHWID "%HWID1%" "ASKLINKHID"
call :ProcessHWID "HID\linklook" "LINKLOOK"

endlocal & exit /b 0