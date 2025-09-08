@echo off
setlocal

set "MIN_BUILD_OS=10240"
set "MIN_BUILD_INSTALL=14393"

set "OLD_DEVICE_NAME=linklook Virtual Game Controller"
set "OLD_DRIVER_HWID=linklook\linklookVGC\Gen1"

set "NEW_DEVICE_NAME=AskLink Virtual Game Controller"
set "NEW_DRIVER_HWID=AskLink\AskLinkVGC\Gen1"

set "DRIVER_INF=AskLinkVGC.inf"

where devcon >nul 2>&1
if %errorlevel% neq 0 goto :EOF

set "BN="
for /f "skip=2 tokens=3" %%i in (
    'reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v CurrentBuildNumber 2^>nul'
) do (
    set "BN=%%i"
)
if "%BN%"=="" goto :EOF

set /a BN=%BN% >nul 2>&1
if %errorlevel% neq 0 goto :EOF

if %BN% LSS %MIN_BUILD_OS% goto :EOF

if %BN% LSS %MIN_BUILD_INSTALL% (
    devcon remove "%OLD_DRIVER_HWID%" >nul 2>&1
    devcon remove "%NEW_DRIVER_HWID%" >nul 2>&1
    goto :EOF
)

devcon findall "%OLD_DRIVER_HWID%" | findstr /c:"%OLD_DEVICE_NAME%" >nul 2>&1
if %errorlevel% equ 0 (
    devcon remove "%OLD_DRIVER_HWID%" >nul 2>&1
    if %errorlevel% neq 0 goto :EOF
    devcon rescan >nul 2>&1
    devcon install "%DRIVER_INF%" "%NEW_DRIVER_HWID%" >nul 2>&1
    goto :EOF
)

devcon findall "%NEW_DRIVER_HWID%" | findstr /c:"%NEW_DEVICE_NAME%" >nul 2>&1
if %errorlevel% equ 0 goto :EOF

devcon install "%DRIVER_INF%" "%NEW_DRIVER_HWID%" >nul 2>&1

endlocal
goto :EOF