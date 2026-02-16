# 📱 Application Mobile CryptoCampus - Guide Complet

## ✅ Ce qui a été créé

J'ai créé une application mobile Flutter complète avec :

### 📂 Structure du projet
```
MobileApp/
├── lib/
│   ├── config/api_config.dart          # Configuration des URLs API
│   ├── models/                          # Modèles de données
│   │   ├── user_model.dart
│   │   ├── listing_model.dart
│   │   └── blockchain_account_model.dart
│   ├── providers/                       # Gestion d'état (Provider)
│   │   ├── auth_provider.dart
│   │   ├── blockchain_provider.dart
│   │   └── listings_provider.dart
│   ├── services/
│   │   └── api_service.dart            # Services API REST
│   ├── screens/
│   │   ├── splash_screen.dart          # Écran de démarrage
│   │   ├── auth/
│   │   │   ├── login_screen.dart       # Connexion
│   │   │   └── register_screen.dart    # Inscription
│   │   ├── home/
│   │   │   └── home_screen.dart        # Page d'accueil
│   │   ├── balance/
│   │   │   └── balance_screen.dart     # Wallet ETH
│   │   ├── shop/
│   │   │   ├── shop_screen.dart        # Liste des annonces
│   │   │   └── listing_detail_screen.dart  # Détail d'une annonce
│   │   └── create_request/
│   │       └── create_request_screen.dart  # Création d'annonce
│   └── main.dart                        # Point d'entrée
├── assets/
│   ├── images/
│   └── icons/
├── .env                                 # Configuration environnement
├── pubspec.yaml                         # Dépendances
├── README.md                            # Documentation complète
├── QUICKSTART.md                        # Guide de démarrage rapide
├── install.bat                          # Script d'installation
└── run.bat                              # Script de lancement
```

### 🎯 Fonctionnalités implémentées

✅ **Authentification**
- Inscription avec email/password
- Connexion
- Gestion de session avec SharedPreferences
- Choix du rôle (Étudiant/Tuteur)

✅ **Wallet Blockchain**
- Affichage de la balance ETH
- Liste de tous les comptes Ganache
- Envoi de transactions ETH
- Copie d'adresse
- Rafraîchissement du solde

✅ **Annonces de tutorat**
- Liste de toutes les annonces
- Recherche sémantique (connexion à Qdrant)
- Filtrage par matière et niveau
- Affichage détaillé d'une annonce
- Réservation et paiement en ETH

✅ **Création d'annonce**
- Formulaire complet
- Choix de la matière et du niveau
- Définition du prix par heure
- Validation des champs

✅ **UI/UX moderne**
- Design Material 3
- Couleurs personnalisées
- Animations fluides
- Police Google Fonts (Poppins)
- Responsive design

---

## 🚀 INSTALLATION - ÉTAPE PAR ÉTAPE

### Étape 1 : Installer Flutter

#### Sur Windows :

1. **Télécharger Flutter SDK**
   - Aller sur : https://docs.flutter.dev/get-started/install/windows
   - Télécharger le fichier ZIP
   - Extraire dans `C:\flutter`

2. **Ajouter Flutter au PATH**
   - Ouvrir **Panneau de configuration** > **Système** > **Paramètres système avancés**
   - Cliquer sur **Variables d'environnement**
   - Dans "Variables système", double-cliquer sur **Path**
   - Cliquer sur **Nouveau**
   - Ajouter : `C:\flutter\bin`
   - Cliquer **OK** sur toutes les fenêtres

3. **Vérifier l'installation**
   Ouvrir PowerShell et taper :
   ```powershell
   flutter doctor
   ```

### Étape 2 : Installer Android Studio

1. **Télécharger Android Studio**
   - Aller sur : https://developer.android.com/studio
   - Télécharger et installer

2. **Installer les composants SDK**
   Pendant l'installation, cocher :
   - Android SDK
   - Android SDK Platform
   - Android Virtual Device

3. **Accepter les licences Android**
   Dans PowerShell :
   ```powershell
   flutter doctor --android-licenses
   ```
   (Accepter toutes les licences en tapant `y`)

4. **Vérifier l'installation**
   ```powershell
   flutter doctor
   ```
   Tout devrait être ✓ (sauf iOS si vous êtes sur Windows)

### Étape 3 : Installer les dépendances du projet

1. **Ouvrir PowerShell dans le dossier MobileApp**
   ```powershell
   cd C:\Users\hsevp\Documents\5_01SAE_OnlyCode\SAE5A01\MobileApp
   ```

2. **Installer les packages Flutter**
   ```powershell
   flutter pub get
   ```

   OU double-cliquer sur `install.bat`

---

## 📱 VISUALISER L'APPLICATION - 3 OPTIONS

### 🎯 OPTION 1 : Émulateur Android (RECOMMANDÉ)

C'est la meilleure option pour tester l'application !

#### A. Créer un émulateur

1. **Ouvrir Android Studio**

2. **Aller dans AVD Manager**
   - Cliquer sur les 3 points verticaux en haut à droite
   - Sélectionner **Virtual Device Manager**
   - OU : **Tools** > **Device Manager**

3. **Créer un appareil virtuel**
   - Cliquer sur **Create Device**
   - Choisir un modèle (recommandé : **Pixel 5**)
   - Cliquer **Next**

4. **Télécharger une image système**
   - Choisir **Tiramisu** (Android 13) ou **UpsideDownCake** (Android 14)
   - Cliquer sur l'icône de téléchargement à côté
   - Attendre le téléchargement (peut prendre quelques minutes)
   - Cliquer **Next**

5. **Finaliser**
   - Donner un nom (ex: "Pixel_5_API_33")
   - Cliquer **Finish**

#### B. Lancer l'émulateur

Dans Android Studio :
- Cliquer sur le bouton ▶️ à côté de l'émulateur créé
- Attendre que l'émulateur démarre (1-2 minutes la première fois)

#### C. Lancer l'application

Dans PowerShell (dans le dossier MobileApp) :
```powershell
flutter run
```

OU double-cliquer sur `run.bat`

L'application va se compiler et s'installer dans l'émulateur (2-3 minutes la première fois).

---

### 🎯 OPTION 2 : Appareil Android physique

#### A. Préparer le téléphone

1. **Activer le mode développeur**
   - Aller dans **Paramètres**
   - Chercher **À propos du téléphone**
   - Taper 7 fois sur **Numéro de build**
   - Un message "Vous êtes développeur" apparaît

2. **Activer le débogage USB**
   - Retourner dans **Paramètres**
   - Chercher **Options pour les développeurs**
   - Activer **Débogage USB**

3. **Connecter le téléphone**
   - Brancher le téléphone en USB à l'ordinateur
   - Sur le téléphone, autoriser le débogage USB

#### B. Configurer l'IP

1. **Trouver l'IP de votre ordinateur**
   Dans PowerShell :
   ```powershell
   ipconfig
   ```
   Chercher "Adresse IPv4" de votre connexion Wi-Fi (ex: 192.168.1.15)

2. **Modifier le fichier .env**
   Ouvrir `MobileApp\.env` et changer :
   ```env
   API_BASE_URL=http://192.168.1.15:81
   WEB_APP_URL=http://192.168.1.15:80
   ```
   (Remplacer par VOTRE IP)

3. **S'assurer d'être sur le même réseau Wi-Fi**
   - L'ordinateur et le téléphone doivent être sur le même réseau

#### C. Lancer l'application

```powershell
flutter run
```

---

### 🎯 OPTION 3 : Chrome (pour tester l'UI uniquement)

⚠️ **Limitation** : Chrome ne peut pas se connecter au backend localhost

```powershell
flutter run -d chrome
```

Cela ouvrira l'application dans Chrome, mais vous ne pourrez pas tester les fonctionnalités de connexion à l'API.

---

## 🎮 UTILISER L'APPLICATION

### 1️⃣ Premier lancement

1. **S'assurer que le backend est démarré**
   Dans un autre terminal :
   ```powershell
   cd ..\NodeServer
   docker-compose up -d
   ```

2. **Vérifier que les services sont accessibles**
   Ouvrir dans un navigateur :
   - http://localhost:81/listings (doit retourner des annonces)

3. **Lancer l'app mobile**
   ```powershell
   cd ..\MobileApp
   flutter run
   ```

### 2️⃣ Créer un compte

1. Sur l'écran de connexion, cliquer **S'inscrire**
2. Remplir le formulaire :
   - Prénom : Jean
   - Nom : Dupont
   - Email : jean.dupont@example.com
   - Mot de passe : password123
   - Rôle : **Étudiant** ou **Tuteur**
3. Cliquer **S'inscrire**

### 3️⃣ Explorer les fonctionnalités

#### Page d'accueil 🏠
- Voir votre profil
- Accès rapide aux 3 fonctions principales

#### Wallet 💰
1. Cliquer sur **Mon Wallet**
2. Voir votre balance ETH (les comptes Ganache ont 100 ETH par défaut)
3. Tester l'envoi d'ETH :
   - Cliquer sur **Envoyer**
   - Copier une adresse depuis la liste des comptes
   - Entrer un montant (ex: 0.5)
   - Envoyer
4. La balance se met à jour automatiquement

#### Annonces 📚
1. Cliquer sur **Annonces de tutorat**
2. Voir la liste des annonces
3. Utiliser la recherche (ex: "mathématiques lycée")
4. Cliquer sur une annonce pour voir les détails
5. Réserver des heures :
   - Cliquer sur **Réserver et payer**
   - Entrer le nombre d'heures
   - Confirmer le paiement en ETH

#### Créer une annonce ➕
1. Cliquer sur **Créer une demande**
2. Remplir :
   - Titre : "Cours de mathématiques niveau lycée"
   - Description : (au moins 50 caractères)
   - Matière : Mathématiques
   - Niveau : Lycée
   - Prix : 0.02 ETH/h
3. Publier

---

## 🔥 Fonctionnalités avancées

### Hot Reload (rechargement à chaud)

Pendant que l'app tourne :
- Modifier du code dans `lib/`
- Appuyer sur `r` dans le terminal
- L'app se recharge instantanément sans perdre l'état !

### Voir les logs

```powershell
flutter run -v
```

### Build de l'APK

Pour créer un fichier APK installable :

```powershell
# APK de debug (avec logs)
flutter build apk --debug

# APK de release (optimisé)
flutter build apk --release
```

Le fichier APK sera dans :
```
build\app\outputs\flutter-apk\app-release.apk
```

Vous pouvez l'installer sur n'importe quel téléphone Android !

---

## 🐛 Dépannage

### ❌ "Unable to connect to API"

**Causes possibles :**
1. Le backend Docker n'est pas démarré
2. Mauvaise URL dans `.env`

**Solutions :**
```powershell
# Vérifier que Docker tourne
docker ps

# Pour émulateur Android, utiliser :
API_BASE_URL=http://10.0.2.2:81

# Pour appareil physique, utiliser l'IP de votre PC :
API_BASE_URL=http://192.168.1.XXX:81
```

### ❌ "No devices found"

**Solution :**
1. Vérifier les appareils :
   ```powershell
   flutter devices
   ```

2. Si vide, soit :
   - Lancer un émulateur Android
   - Connecter un téléphone en USB

### ❌ Erreur de compilation

```powershell
flutter clean
flutter pub get
flutter run
```

### ❌ "Waiting for another flutter command to release the startup lock"

```powershell
# Supprimer le fichier de verrouillage
del %LOCALAPPDATA%\Pub\Cache\.flutter_tool_state
```

### ❌ L'émulateur est lent

**Solutions :**
1. Activer la virtualisation dans le BIOS (VT-x/AMD-V)
2. Utiliser un émulateur x86_64 au lieu de ARM
3. Allouer plus de RAM dans AVD Manager

---

## 📊 Commandes utiles

```powershell
# Vérifier l'installation Flutter
flutter doctor

# Liste des appareils
flutter devices

# Liste des émulateurs
flutter emulators

# Lancer un émulateur spécifique
flutter emulators --launch <emulator_id>

# Installer les dépendances
flutter pub get

# Nettoyer le projet
flutter clean

# Lancer l'app
flutter run

# Lancer en mode verbose
flutter run -v

# Build APK
flutter build apk --release

# Analyser le code
flutter analyze
```

---

## 🎨 Personnalisation

### Changer les couleurs

Modifier dans [lib/main.dart](lib/main.dart) :

```dart
colorScheme: ColorScheme.fromSeed(
  seedColor: const Color(0xFF6C63FF),  // Couleur principale
  primary: const Color(0xFF6C63FF),
  secondary: const Color(0xFF4CAF50),  // Couleur secondaire
),
```

### Changer la police

```dart
textTheme: GoogleFonts.robotoTextTheme(),  // Au lieu de poppins
```

### Ajouter des images

1. Placer les images dans `assets/images/`
2. Les déclarer dans `pubspec.yaml` (déjà fait)
3. Les utiliser dans le code :
   ```dart
   Image.asset('assets/images/logo.png')
   ```

---

## 📚 Documentation

- **README.md** : Documentation complète et détaillée
- **QUICKSTART.md** : Guide de démarrage rapide
- Ce fichier : Guide d'installation et visualisation

### Ressources Flutter

- Documentation officielle : https://flutter.dev/docs
- Tutoriels : https://flutter.dev/learn
- Packages : https://pub.dev
- Codelabs : https://codelabs.developers.google.com/?product=flutter

---

## ✅ Checklist de démarrage

- [ ] Flutter SDK installé (`flutter doctor` fonctionne)
- [ ] Android Studio installé
- [ ] Un émulateur Android créé
- [ ] Dépendances installées (`flutter pub get`)
- [ ] Backend Docker démarré (`docker-compose up -d`)
- [ ] Application lancée (`flutter run`)
- [ ] Un compte créé dans l'app
- [ ] Wallet testé (envoi d'ETH)
- [ ] Annonces visualisées
- [ ] Recherche testée

---

## 🎯 Prochaines étapes

L'application est complète et fonctionnelle. Vous pouvez maintenant :

1. **Tester toutes les fonctionnalités**
2. **Personnaliser le design (couleurs, logo, etc.)**
3. **Ajouter de nouvelles fonctionnalités** :
   - Upload de CV pour l'analyse
   - Chat entre étudiants et tuteurs
   - Notifications push
   - Historique des transactions
   - Système de notation/avis
   - Mode sombre

4. **Optimiser pour la production** :
   - Gestion des erreurs réseau
   - Système de refresh token
   - Cache des données
   - Analytics
   - Crash reporting

---

**🎉 Félicitations ! Votre application mobile CryptoCampus est prête ! 🎉**

Pour toute question, consultez les fichiers README ou la documentation Flutter.
