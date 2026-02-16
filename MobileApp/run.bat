@echo off
echo ========================================
echo Demarrage de CryptoCampus Mobile
echo ========================================
echo.

cd /d "%~dp0"

echo Verification des appareils connectes...
call flutter devices

echo.
echo Lancement de l'application...
call flutter run

pause
