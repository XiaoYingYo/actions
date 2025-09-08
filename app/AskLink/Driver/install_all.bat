@echo off
setlocal enabledelayedexpansion

set "arch=%PROCESSOR_ARCHITECTURE%"
if /I "%arch%"=="ARM64" goto skip_install
if /I "%arch%"=="ARM"   goto skip_install

for /f "tokens=2,*" %%i in (
    'reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v CurrentBuildNumber ^| find "CurrentBuildNumber"'
) do set "OSBUILD=%%j"

if %OSBUILD% LSS 9200 (
    cd /d "%~dp0Win7Vhid"
    call install.bat >nul 2>&1
    cd ..
)

if %OSBUILD% GEQ 9200 (
    cd /d "%~dp0Vhid"
    call install.bat >nul 2>&1
    cd ..
)

if %OSBUILD% GEQ 14393 (
    cd /d "%~dp0Vgc"
    call install.bat >nul 2>&1
    cd ..
)

if %OSBUILD% GEQ 18362 (
    cd /d "%~dp0Ldd"
    call install.bat >nul 2>&1
    cd ..
)

:skip_install
devcon rescan >nul 2>&1
exit /b