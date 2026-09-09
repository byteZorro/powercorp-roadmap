@echo off
REM Double-click this after editing anything in content\.
REM It regenerates index.html and press\index.html from your markdown.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0build.ps1"
echo.
pause
