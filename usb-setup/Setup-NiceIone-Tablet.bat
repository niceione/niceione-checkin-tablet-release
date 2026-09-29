@echo off
setlocal
chcp 65001 >nul
title NiceIone 태블릿 초기 설정

echo ============================================================
echo  NiceIone 태블릿 Device Owner 초기 설정
echo ============================================================
echo.

powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0Setup-ProductionDeviceOwner.ps1" %*
set "NICEIONE_EXIT_CODE=%ERRORLEVEL%"

echo.
if not "%NICEIONE_EXIT_CODE%"=="0" (
    echo [실패] 위 오류 내용을 확인한 뒤 다시 실행해 주세요.
) else (
    echo [완료] USB 케이블을 분리하고 태블릿 동작을 확인하세요.
)
echo.
pause
exit /b %NICEIONE_EXIT_CODE%
