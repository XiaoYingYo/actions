@echo off
setlocal enabledelayedexpansion

set "arch=%PROCESSOR_ARCHITECTURE%"
if /I "%arch%"=="ARM64" goto skip_uninstall
if /I "%arch%"=="ARM"   goto skip_uninstall

for /f "tokens=2,*" %%i in (
    'reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v CurrentBuildNumber ^| find "CurrentBuildNumber"'
) do set "OSBUILD=%%j"

if %OSBUILD% LSS 9200 (
    cd /d "%~dp0Win7Vhid"
    call uninstall.bat >nul 2>&1
    cd ..
)

if %OSBUILD% GEQ 9200 (
    cd /d "%~dp0Vhid"
    call uninstall.bat >nul 2>&1
    cd ..
)

if %OSBUILD% GEQ 14393 (
    cd /d "%~dp0Vgc"
    call uninstall.bat >nul 2>&1
    cd ..
)

if %OSBUILD% GEQ 18362 (
    cd /d "%~dp0Ldd"
    call uninstall.bat >nul 2>&1
    cd ..
)

:skip_uninstall
devcon rescan >nul 2>&1
exit /b