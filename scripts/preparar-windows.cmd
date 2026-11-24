@echo off
powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File "%~dp0preparar-windows.ps1" %*
exit /b %errorlevel%
