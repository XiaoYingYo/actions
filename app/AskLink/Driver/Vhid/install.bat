@echo off
setlocal EnableExtensions EnableDelayedExpansion

:: ---------- 架构与系统版本判定 ----------
set "ARCH=%PROCESSOR_ARCHITECTURE%"
if defined PROCESSOR_ARCHITEW6432 set "ARCH=%PROCESSOR_ARCHITEW6432%"
if /I "%ARCH%"=="ARM64" goto :END
if /I "%ARCH%"=="ARM"   goto :END

set "OSBUILD="
for /f "tokens=3" %%v in ('reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v CurrentBuildNumber 2^>nul ^| find /I "CurrentBuildNumber"') do set "OSBUILD=%%v"
set /a _osb=%OSBUILD%+0 >nul 2>&1
if errorlevel 1 set "OSBUILD=0"
if %OSBUILD% LSS 14393 goto :END

:: ---------- 环境 ----------
cd /d "%~dp0"
set "DEVCON=%~dp0devcon.exe"

:: 用设备名称粗略校验现状
set "_N1=AskLink HID D"
set "_N2=Linklook HID"

set "C1="
for /f %%C in ('cmd /d /v:on /c ^""%DEVCON%" findall * 2^>nul ^| find /I "!_N1!" ^| find /v /c ""^"') do set "C1=%%C"
if not defined C1 set "C1=0"

set "C2="
for /f %%C in ('cmd /d /v:on /c ^""%DEVCON%" findall * 2^>nul ^| find /I "!_N2!" ^| find /v /c ""^"') do set "C2=%%C"
if not defined C2 set "C2=0"

set "DO="
if not "%C1%"=="1" set "DO=1"
if not "%C2%"=="0" set "DO=1"

if defined DO (
    :: 先卸载（如果有卸载脚本）
    if exist "%~dp0uninstall.bat" (call "%~dp0uninstall.bat" >nul 2>&1)
    timeout /t 2 /nobreak >nul

    :: 安装
    "%DEVCON%" install "%~dp0AskLinkHid.inf" "AskLink\AskLinkHid" >nul 2>&1

    :: ========= 新增：安装完成后禁用 HID\AskLinkHidC&Col03 =========
    :: 等待设备枚举出来（最多 10 次，每次 1s）
    set "TRIES=10"
:WAIT_COL03
    "%DEVCON%" find "*HID\AskLinkHid&Col03*" >nul 2>&1
    if errorlevel 1 (
        set /a TRIES-=1
        if !TRIES! LEQ 0 goto :SKIP_DISABLE
        timeout /t 1 /nobreak >nul
        goto :WAIT_COL03
    )

    :: 找到后执行禁用
    "%DEVCON%" disable "*HID\AskLinkHid&Col03*" >nul 2>&1
:SKIP_DISABLE
    :: ========= 新增段落结束 =========
)

:END
endlocal & exit /b 0