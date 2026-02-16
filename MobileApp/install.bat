@echo off
echo ========================================
echo Installation de CryptoCampus Mobile
echo ========================================
echo.

echo [1/4] Verification de Flutter...
flutter --version
if %errorlevel% neq 0 (
    echo ERREUR: Flutter n'est pas installe!
    echo Telechargez Flutter depuis: https://docs.flutter.dev/get-started/install/windows
    pause
    exit /b 1
)

echo.
echo [2/4] Installation des dependances...
cd /d "%~dp0"
call flutter pub get

echo.
echo [3/4] Verification des appareils...
call flutter devices

echo.
echo [4/4] Installation terminee!
echo.
echo ========================================
echo Pour lancer l'application:
echo    flutter run
echo ========================================
echo.
pause
