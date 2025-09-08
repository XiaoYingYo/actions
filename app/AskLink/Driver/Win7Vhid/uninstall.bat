@echo off
setlocal EnableExtensions EnableDelayedExpansion

:: ===== Windows 7 only =====
set "OSBUILD="
for /f "skip=2 tokens=2,*" %%A in ('reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v CurrentBuildNumber') do set "OSBUILD=%%B"
for /f "tokens=1 delims=." %%B in ("%OSBUILD%") do set "OSBUILD=%%B"
set /a _osb=%OSBUILD%+0 >nul 2>&1
if errorlevel 1 set "OSBUILD=0"
if %OSBUILD% LSS 7600 goto :END
if %OSBUILD% GEQ 9200 goto :END

:: ===== Locate devcon =====
set "DEVCON="
for %%P in ("devcon.exe" "devcon64.exe" "devcon_x64.exe" "devcon_x86.exe") do if exist "%~dp0%%~P" set "DEVCON=%~dp0%%~P"
if not defined DEVCON for /f "delims=" %%D in ('where devcon.exe 2^>nul') do if not defined DEVCON set "DEVCON=%%D"
if not defined DEVCON set "DEVCON=devcon.exe"

:: ===== Remove device instances =====
"%DEVCON%" remove "AskLink\AskLinkHid" >nul 2>&1
"%DEVCON%" remove "@AskLink\AskLinkHid" >nul 2>&1
"%DEVCON%" remove "*ASKLINKHID*" >nul 2>&1
"%DEVCON%" remove "@*ASKLINKHID*" >nul 2>&1

for /f "tokens=1 delims=:" %%I in ('"%DEVCON%" find "*ASKLINKHID*" 2^>nul ^| findstr /r /v /i "Matching"') do (
  set "ID=%%I"
  for /f "tokens=* delims= " %%Z in ("!ID!") do set "ID=%%Z"
  set "ID=!ID: =!"
  if defined ID "%DEVCON%" remove "@!ID!" >nul 2>&1
)

:: ===== Remove driver package(s) from Driver Store (Win7 syntax) =====
set "INF_DIR=%windir%\inf"
for /f "delims=" %%F in ('dir /b /a:-d "%INF_DIR%\oem*.inf"') do (
  set "HIT="
  (findstr /mic:"AskLink\AskLinkHid" "%INF_DIR%\%%F" >nul 2>&1) && (findstr /mic:"Class=HIDClass" "%INF_DIR%\%%F" >nul 2>&1) && set "HIT=1"
  if not defined HIT (
    (findstr /mic:"ASKLINKHID" "%INF_DIR%\%%F" >nul 2>&1) && (findstr /mic:"Class=HIDClass" "%INF_DIR%\%%F" >nul 2>&1) && set "HIT=1"
  )
  if defined HIT pnputil -f -d "%%F" >nul 2>&1
)

"%DEVCON%" rescan >nul 2>&1

:END
endlocal & exit /b 0