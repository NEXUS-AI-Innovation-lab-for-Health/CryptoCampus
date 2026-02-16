@echo off
chcp 65001 > nul
echo ========================================
echo    🔧 RÉPARATION DE FLUTTER
echo ========================================
echo.

echo [1/5] Vérification de Flutter...
flutter --version
if %errorlevel% neq 0 (
    echo.
    echo ❌ ERREUR: Flutter n'est pas dans le PATH!
    echo.
    echo 📝 SOLUTION:
    echo 1. Appuyez sur Windows + R
    echo 2. Tapez: sysdm.cpl
    echo 3. Onglet "Avancé" ^> "Variables d'environnement"
    echo 4. Dans "Variables système", double-cliquez sur "Path"
    echo 5. Cliquez "Nouveau"
    echo 6. Ajoutez: C:\Flutter_SDK\flutter\bin
    echo 7. OK sur tout
    echo 8. FERMEZ et ROUVREZ VS Code
    echo 9. Relancez ce script
    echo.
    pause
    exit /b 1
)

echo.
echo [2/5] Configuration Android SDK...
flutter config --android-studio-dir="C:\Program Files\Android\Android Studio"
if %errorlevel% neq 0 (
    echo Essai du chemin alternatif...
    flutter config --android-studio-dir="C:\Program Files (x86)\Android\Android Studio"
)

echo.
echo [3/5] Acceptation des licences Android...
echo (Tapez 'y' pour accepter toutes les licences)
call flutter doctor --android-licenses

echo.
echo [4/5] Nettoyage du projet...
cd /d "%~dp0"
call flutter clean

echo.
echo [5/5] Installation des packages...
call flutter pub get

echo.
echo ========================================
echo    ✅ RÉPARATION TERMINÉE!
echo ========================================
echo.
echo 🎯 PROCHAINES ÉTAPES:
echo 1. FERMEZ VS Code complètement
echo 2. ROUVREZ VS Code
echo 3. Les erreurs rouges devraient disparaître
echo 4. Lancez: flutter run
echo.
echo 🔍 Vérification finale...
call flutter doctor

echo.
pause
