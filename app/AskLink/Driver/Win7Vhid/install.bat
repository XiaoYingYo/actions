@echo off

for /f "tokens=2,*" %%i in (
    'reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v CurrentBuildNumber ^| find "CurrentBuildNumber"'
) do set "OSBUILD=%%j"

if %OSBUILD% LSS 9200 (
    devcon findall * 2>nul | findstr /I /C:"AskLink HID b" >nul
    if errorlevel 1 (
        call "%~dp0uninstall.bat" >nul 2>&1
        devcon install "%~dp0AskLinkHid.inf" "AskLink\AskLinkHid" >nul 2>&1
    )
)

