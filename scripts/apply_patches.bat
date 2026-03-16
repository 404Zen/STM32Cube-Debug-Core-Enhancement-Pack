@echo off
setlocal
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0apply_patches.ps1" %*
exit /b %errorlevel%
