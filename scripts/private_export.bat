@echo off
setlocal
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0private_export.ps1" %*
exit /b %errorlevel%
