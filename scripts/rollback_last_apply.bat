@echo off
setlocal
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0rollback_last_apply.ps1" %*
exit /b %errorlevel%
