@echo off
chcp 65001 >nul
title AWS Network Scanner Pro
color 0A
echo.
echo  ╔═══════════════════════════════════════════════════════════════╗
echo  ║      AWS Network Scanner Pro - Starting...                    ║
echo  ╚═══════════════════════════════════════════════════════════════╝
echo.

cd /d "%~dp0"

powershell -NoProfile -ExecutionPolicy Bypass -File "AWS-Network-Scanner.ps1"

echo.
echo  Press any key to exit...
pause >nul
