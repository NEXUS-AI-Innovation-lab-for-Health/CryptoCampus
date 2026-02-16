# 🔧 Résolution des Erreurs Flutter - Guide Complet

## 🚨 Problèmes identifiés dans votre output

1. ❌ **Flutter n'est pas dans le PATH Windows**
2. ❌ **Android SDK non trouvé par Flutter**
3. ❌ **Packages Flutter non installés** (tout est rouge)

---

## ✅ SOLUTION 1 : Ajouter Flutter au PATH Windows

### Étape 1 : Ouvrir les Variables d'environnement

1. **Appuyez sur** `Windows + R`
2. **Tapez** : `sysdm.cpl` et appuyez sur **Entrée**
3. Allez dans l'onglet **"Avancé"**
4. Cliquez sur **"Variables d'environnement"**

### Étape 2 : Modifier le PATH

1. Dans **"Variables système"** (section du bas), trouvez **Path**
2. Double-cliquez sur **Path**
3. Cliquez sur **"Nouveau"**
4. Ajoutez : `C:\Flutter_SDK\flutter\bin`
5. Cliquez **OK** sur toutes les fenêtres

### Étape 3 : Redémarrer VS Code

⚠️ **IMPORTANT** : Fermez complètement VS Code et rouvrez-le !

### Étape 4 : Vérifier dans un nouveau terminal PowerShell

```powershell
flutter --version
dart --version
```

Vous devez voir les versions s'afficher sans erreur.

---

## ✅ SOLUTION 2 : Configurer Android SDK

Flutter ne trouve pas votre Android SDK même si Android Studio est installé.

### Option A : Laisser Flutter détecter automatiquement (RECOMMANDÉ)

```powershell
# Ouvrir PowerShell dans VS Code
flutter config --android-studio-dir="C:\Program Files\Android\Android Studio"
```

Si Android Studio n'est pas là, essayez :
```powershell
flutter config --android-studio-dir="C:\Program Files (x86)\Android\Android Studio"
```

### Option B : Configuration manuelle du SDK

1. **Trouver où est votre Android SDK**
   - Ouvrir Android Studio
   - **File** > **Settings** (ou **Ctrl+Alt+S**)
   - **Appearance & Behavior** > **System Settings** > **Android SDK**
   - Notez le chemin "Android SDK Location" (exemple : `C:\Users\hsevp\AppData\Local\Android\Sdk`)

2. **Configurer Flutter**
   ```powershell
   flutter config --android-sdk "C:\Users\hsevp\AppData\Local\Android\Sdk"
   ```
   (Remplacez par VOTRE chemin)

3. **Accepter les licences**
   ```powershell
   flutter doctor --android-licenses
   ```
   Tapez **y** pour tout accepter

---

## ✅ SOLUTION 3 : Installer les packages Flutter

Une fois le PATH configuré :

### Dans VS Code (Terminal PowerShell)

```powershell
# Aller dans le dossier MobileApp
cd c:\Users\hsevp\Documents\5_01SAE_OnlyCode\SAE5A01\MobileApp

# Nettoyer le projet
flutter clean

# Installer les packages
flutter pub get
```

⏳ **Cela va prendre 1-2 minutes** et télécharger tous les packages nécessaires.

---

## ✅ SOLUTION 4 : Vérifier que tout est OK

```powershell
flutter doctor -v
```

**Résultat attendu :**
```
[√] Flutter (Channel stable, 3.41.1, ...)
[√] Windows Version
[√] Android toolchain - develop for Android devices (Android SDK version 33)
[√] Chrome - develop for the web
[√] Android Studio (version 2024.x)
[√] VS Code (version 1.x.x)
[√] Connected device
[√] Network resources
```

---

## 🚀 GUIDE COMPLET ÉTAPE PAR ÉTAPE

### 📋 Checklist complète

#### 1. Ajouter Flutter au PATH ✋ **À FAIRE EN PREMIER**

```powershell
# Vérifier si Flutter est dans le PATH
flutter --version
```

- Si erreur ❌ → Suivre **SOLUTION 1** ci-dessus
- Si version s'affiche ✅ → Passer à l'étape suivante

#### 2. Configurer Android SDK

```powershell
# Détecter automatiquement Android Studio
flutter config --android-studio-dir="C:\Program Files\Android\Android Studio"

# Accepter les licences
flutter doctor --android-licenses
```

#### 3. Installer les packages

```powershell
cd c:\Users\hsevp\Documents\5_01SAE_OnlyCode\SAE5A01\MobileApp
flutter clean
flutter pub get
```

#### 4. Redémarrer VS Code

- Fermez VS Code complètement
- Rouvrez-le
- Les erreurs rouges devraient disparaître ! 🎉

#### 5. Vérifier l'émulateur

```powershell
# Lister les émulateurs
flutter emulators

# Lancer l'émulateur Pixel 5
flutter emulators --launch <nom_emulateur>
```

#### 6. Lancer l'application

```powershell
flutter run
```

---

## 🐛 Problèmes courants et solutions

### ❌ "flutter: command not found" après ajout au PATH

**Solution :**
1. Fermez **TOUTES** les fenêtres PowerShell/Terminal
2. Fermez VS Code complètement
3. Rouvrez VS Code
4. Ouvrez un nouveau terminal
5. Testez : `flutter --version`

---

### ❌ "Android SDK not found" persistant

**Solution détaillée :**

1. **Trouver le SDK manuellement**
   ```powershell
   # Vérifier les emplacements communs
   dir "C:\Users\hsevp\AppData\Local\Android\Sdk"
   dir "C:\Android\Sdk"
   dir "C:\Program Files\Android\Android Studio\sdk"
   ```

2. **Configurer manuellement**
   ```powershell
   flutter config --android-sdk "C:\Users\hsevp\AppData\Local\Android\Sdk"
   ```

3. **Installer les outils nécessaires**
   - Ouvrir Android Studio
   - **File** > **Settings** > **Android SDK**
   - Onglet **SDK Tools**
   - Cocher :
     - ✅ **Android SDK Build-Tools**
     - ✅ **Android SDK Command-line Tools**
     - ✅ **Android SDK Platform-Tools**
   - Cliquer **Apply** et installer

4. **Accepter les licences**
   ```powershell
   flutter doctor --android-licenses
   ```

---

### ❌ Erreurs rouges ne disparaissent pas après `flutter pub get`

**Solution :**

1. **Dans VS Code, ouvrir la palette de commandes** : `Ctrl+Shift+P`

2. **Taper** : `Dart: Restart Analysis Server`

3. **Appuyer sur Entrée**

4. **Si ça ne marche pas**, faire :
   ```powershell
   flutter clean
   flutter pub get
   ```

5. **Redémarrer VS Code**

---

### ❌ "Unable to find git in your PATH"

**Solution :**

1. Télécharger Git : https://git-scm.com/download/win
2. Installer avec les options par défaut
3. Redémarrer le terminal

---

### ❌ L'émulateur ne démarre pas

**Solution :**

1. **Ouvrir Android Studio**
2. **Tools** > **Device Manager**
3. **Cliquer sur le bouton ▶️** à côté de Pixel 5
4. Attendre que l'émulateur démarre (1-2 minutes)
5. Dans VS Code :
   ```powershell
   flutter devices
   ```
   Vous devriez voir l'émulateur
6. Lancer :
   ```powershell
   flutter run
   ```

---

## 📝 Commandes de dépannage complètes

```powershell
# 1. Vérifier l'installation
flutter doctor -v

# 2. Voir la configuration actuelle
flutter config

# 3. Nettoyer complètement le projet
cd MobileApp
flutter clean
del pubspec.lock
flutter pub get

# 4. Vérifier les appareils disponibles
flutter devices

# 5. Lister les émulateurs
flutter emulators

# 6. Redémarrer l'analyse Dart (dans VS Code)
# Ctrl+Shift+P > Dart: Restart Analysis Server

# 7. Vérifier les packages installés
flutter pub deps
```

---

## 🎯 Script PowerShell automatique

Créez un fichier `fix-flutter.ps1` avec ce contenu :

```powershell
Write-Host "=== Réparation de Flutter ===" -ForegroundColor Green

Write-Host "`n1. Configuration Android SDK..." -ForegroundColor Yellow
flutter config --android-studio-dir="C:\Program Files\Android\Android Studio"

Write-Host "`n2. Acceptation des licences..." -ForegroundColor Yellow
flutter doctor --android-licenses

Write-Host "`n3. Nettoyage du projet..." -ForegroundColor Yellow
cd c:\Users\hsevp\Documents\5_01SAE_OnlyCode\SAE5A01\MobileApp
flutter clean

Write-Host "`n4. Installation des packages..." -ForegroundColor Yellow
flutter pub get

Write-Host "`n5. Vérification finale..." -ForegroundColor Yellow
flutter doctor

Write-Host "`n=== Terminé ! ===" -ForegroundColor Green
Write-Host "Redémarrez VS Code pour appliquer tous les changements." -ForegroundColor Cyan
```

Lancez-le avec :
```powershell
powershell -ExecutionPolicy Bypass -File fix-flutter.ps1
```

---

## ✅ Ordre des actions recommandé

### 🎯 ÉTAPE PAR ÉTAPE (à suivre dans l'ordre)

#### Étape 1 : PATH (5 minutes)
1. Ajouter `C:\Flutter_SDK\flutter\bin` au PATH Windows
2. Redémarrer VS Code
3. Vérifier : `flutter --version`

#### Étape 2 : Android SDK (3 minutes)
```powershell
flutter config --android-studio-dir="C:\Program Files\Android\Android Studio"
flutter doctor --android-licenses  # Accepter tout
```

#### Étape 3 : Packages (2 minutes)
```powershell
cd MobileApp
flutter clean
flutter pub get
```

#### Étape 4 : Redémarrer (1 minute)
- Fermez VS Code
- Rouvrez VS Code
- Les erreurs rouges disparaissent ✅

#### Étape 5 : Test (5 minutes)
```powershell
flutter doctor -v
flutter devices
flutter run
```

---

## 🆘 Si rien ne marche

### Option nucléaire (réinstallation propre)

```powershell
# 1. Supprimer le cache Flutter
flutter clean

# 2. Supprimer le cache des packages
rm -r $env:LOCALAPPDATA\Pub\Cache -Force

# 3. Réinstaller les packages
flutter pub get

# 4. Redémarrer l'ordinateur

# 5. Rouvrir VS Code et relancer
flutter run
```

---

## 📞 Commandes de diagnostic

Si vous avez encore des problèmes, exécutez et envoyez-moi les résultats :

```powershell
# Diagnostic complet
flutter doctor -v > flutter-diagnostic.txt

# Configuration actuelle
flutter config > flutter-config.txt

# Packages installés
flutter pub deps > pub-deps.txt
```

---

## 🎉 Résultat attendu

Après avoir suivi toutes les étapes :

1. ✅ **Terminal** : `flutter --version` fonctionne
2. ✅ **VS Code** : Plus d'erreurs rouges dans le code
3. ✅ **Flutter Doctor** : Tout est en vert (sauf Visual Studio optionnel)
4. ✅ **Émulateur** : Visible avec `flutter devices`
5. ✅ **Application** : `flutter run` lance l'app

---

**🚀 Suivez les étapes dans l'ordre et tout devrait fonctionner !**
