@echo off
setlocal


:: ============ 配置区域 ============
set "MIN_BUILD_OS=10240"
set "MIN_BUILD_INSTALL=18362"

set "OLD_DEVICE_NAME=linklookIddDriver Device"
set "OLD_DRIVER_HWID=Root\linklookIddDriver"

set "NEW_DEVICE_NAME=AskLinkIddDriver Device"
set "NEW_DRIVER_HWID=Root\AskLinkIddDriver"

set "DRIVER_INF=AskLinkIddDriver.inf"

:: ========== 前置环境检查 ==========
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

:: ========== 分版本执行 ==========
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
    if %errorlevel% neq 0 goto :EOF
    goto :EOF
)

devcon findall "%NEW_DRIVER_HWID%" | findstr /c:"%NEW_DEVICE_NAME%" >nul 2>&1
if %errorlevel% equ 0 goto :EOF

devcon install "%DRIVER_INF%" "%NEW_DRIVER_HWID%" >nul 2>&1
if %errorlevel% neq 0 goto :EOF

endlocal
goto :EOF