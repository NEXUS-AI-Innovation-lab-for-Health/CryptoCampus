# 📱 CryptoCampus Mobile

Application mobile Flutter pour la plateforme de tutorat décentralisé CryptoCampus.

## 🎯 Fonctionnalités

- ✅ Authentification (Inscription/Connexion)
- 💰 Gestion de wallet Ethereum (Balance, Transactions)
- 📚 Recherche d'annonces de tutorat
- 🔍 Recherche sémantique avec Qdrant
- 💸 Paiements en ETH via blockchain Ganache
- ➕ Création d'annonces de tutorat

## 🛠️ Installation de Flutter

### Windows

1. **Télécharger Flutter SDK**
   - Aller sur https://docs.flutter.dev/get-started/install/windows
   - Télécharger le ZIP Flutter SDK
   - Extraire dans `C:\flutter`

2. **Ajouter Flutter au PATH**
   ```powershell
   # Ouvrir Paramètres système > Variables d'environnement
   # Ajouter C:\flutter\bin au PATH
   ```

3. **Vérifier l'installation**
   ```powershell
   flutter doctor
   ```

### Installer les dépendances Android

1. **Télécharger Android Studio**
   - https://developer.android.com/studio
   - Installer avec Android SDK

2. **Configurer Android SDK**
   ```powershell
   flutter doctor --android-licenses
   ```

## 🚀 Démarrage Rapide

### 1. Installation des dépendances

```powershell
cd MobileApp
flutter pub get
```

### 2. Démarrer le backend

Assurez-vous que les services backend sont démarrés :

```powershell
cd ..\NodeServer
docker-compose up -d
```

Vérifiez que les services sont accessibles :
- API : http://localhost:81
- Node App : http://localhost:80
- PostgreSQL : localhost:5432
- Ganache : http://localhost:8545

### 3. Configurer l'URL de l'API

Le fichier `.env` contient la configuration :

```env
API_BASE_URL=http://10.0.2.2:81
WEB_APP_URL=http://10.0.2.2:80
```

**Notes importantes :**
- `10.0.2.2` est l'adresse pour accéder à `localhost` depuis l'émulateur Android
- Pour iOS Simulator, utilisez `localhost` ou `127.0.0.1`
- Pour un appareil physique, utilisez l'IP de votre machine (ex: `192.168.1.100`)

### 4. Lancer l'application

#### Option A : Avec l'émulateur Android

```powershell
# Lister les émulateurs disponibles
flutter emulators

# Lancer un émulateur (si disponible)
flutter emulators --launch <emulator_id>

# Lancer l'application
flutter run
```

#### Option B : Avec Android Studio

1. Ouvrir Android Studio
2. Aller dans **Tools** > **AVD Manager**
3. Créer/Lancer un émulateur
4. Dans le terminal :
   ```powershell
   flutter run
   ```

#### Option C : Avec un appareil physique

1. Activer le mode développeur sur votre téléphone :
   - Aller dans **Paramètres** > **À propos du téléphone**
   - Appuyer 7 fois sur **Numéro de build**
   
2. Activer le débogage USB :
   - **Paramètres** > **Options pour les développeurs** > **Débogage USB**

3. Connecter le téléphone en USB

4. Vérifier la connexion :
   ```powershell
   flutter devices
   ```

5. Modifier le `.env` pour utiliser l'IP de votre machine :
   ```env
   API_BASE_URL=http://192.168.1.XXX:81
   ```

6. Lancer l'application :
   ```powershell
   flutter run
   ```

### 5. Mode Hot Reload

Pendant le développement, Flutter supporte le Hot Reload :
- Appuyez sur `r` dans le terminal pour recharger
- Appuyez sur `R` pour un redémarrage complet
- Appuyez sur `q` pour quitter

## 📱 Utilisation de l'application

### Première connexion

1. **Créer un compte**
   - Ouvrir l'app
   - Cliquer sur "S'inscrire"
   - Remplir le formulaire
   - Choisir le rôle (Étudiant ou Tuteur)

2. **Se connecter**
   - Utiliser l'email et mot de passe créés

### Navigation

L'application contient 5 écrans principaux :

1. **Accueil** 🏠
   - Vue d'ensemble du profil
   - Accès rapide aux fonctionnalités

2. **Mon Wallet** 💰
   - Voir votre balance ETH
   - Envoyer des ETH à une adresse
   - Gérer plusieurs comptes blockchain

3. **Annonces** 📚
   - Parcourir les annonces de tutorat
   - Recherche sémantique
   - Filtrer par matière et niveau
   - Réserver et payer un tuteur

4. **Détail d'annonce** 📄
   - Informations complètes sur une annonce
   - Paiement direct en ETH
   - Réservation d'heures

5. **Créer une annonce** ➕
   - Créer votre propre annonce (si vous êtes tuteur)
   - Définir le prix par heure
   - Décrire votre expertise

## 🔧 Configuration avancée

### Utiliser un appareil physique avec IP personnalisée

1. Trouver l'IP de votre machine :
   ```powershell
   ipconfig
   # Chercher "Adresse IPv4" sur votre réseau Wi-Fi
   ```

2. Modifier `.env` :
   ```env
   API_BASE_URL=http://192.168.1.XXX:81
   WEB_APP_URL=http://192.168.1.XXX:80
   ```

3. Redémarrer l'app :
   ```powershell
   flutter run
   ```

### Build de l'APK (Android)

```powershell
# APK de debug
flutter build apk --debug

# APK de release
flutter build apk --release

# L'APK sera dans: build\app\outputs\flutter-apk\
```

### Build pour iOS (nécessite macOS)

```powershell
flutter build ios --release
```

## 🐛 Dépannage

### Erreur : "Unable to connect to API"

1. Vérifier que les services Docker sont démarrés
2. Vérifier l'URL dans `.env`
3. Pour émulateur Android : utiliser `10.0.2.2`
4. Pour appareil physique : utiliser l'IP de votre machine

### Erreur : "No devices found"

```powershell
# Vérifier les appareils connectés
flutter devices

# Relancer l'émulateur
flutter emulators --launch <emulator_id>
```

### Erreur de compilation

```powershell
# Nettoyer le projet
flutter clean

# Réinstaller les dépendances
flutter pub get

# Relancer
flutter run
```

### Problèmes avec les packages

```powershell
# Mettre à jour les packages
flutter pub upgrade

# Obtenir les packages sans cache
flutter pub get --no-precompile
```

## 📚 Structure du projet

```
MobileApp/
├── lib/
│   ├── config/          # Configuration (API URLs)
│   ├── models/          # Modèles de données
│   ├── providers/       # State management (Provider)
│   ├── screens/         # Écrans de l'application
│   │   ├── auth/        # Login, Register
│   │   ├── home/        # Page d'accueil
│   │   ├── balance/     # Wallet
│   │   ├── shop/        # Annonces
│   │   └── create_request/  # Création d'annonce
│   ├── services/        # Services API
│   └── main.dart        # Point d'entrée
├── assets/              # Images, icons
├── .env                 # Configuration environnement
├── pubspec.yaml         # Dépendances Flutter
└── README.md
```

## 🔗 APIs utilisées

L'application se connecte aux endpoints suivants :

### Authentification
- `POST /users/register` - Créer un compte
- `POST /users/by-email` - Connexion

### Blockchain
- `GET /blockchain/accounts` - Liste des comptes
- `GET /blockchain/balance/:address` - Balance d'un compte
- `POST /blockchain/transaction` - Envoyer une transaction

### Annonces
- `GET /listings` - Toutes les annonces
- `GET /listings/search?q=query` - Recherche sémantique

## 🎨 Personnalisation

### Changer les couleurs

Modifier dans `lib/main.dart` :

```dart
colorScheme: ColorScheme.fromSeed(
  seedColor: const Color(0xFF6C63FF),  // Couleur primaire
  primary: const Color(0xFF6C63FF),
  secondary: const Color(0xFF4CAF50),  // Couleur secondaire
),
```

### Changer la police

Modifier dans `lib/main.dart` :

```dart
textTheme: GoogleFonts.poppinsTextTheme(),  // Changer 'poppins' par une autre police
```

## 📝 TODO / Améliorations futures

- [ ] Ajouter la persistance de session avec refresh token
- [ ] Implémenter l'upload de CV pour l'analyse (endpoint /analyze-cv)
- [ ] Ajouter un système de notifications
- [ ] Implémenter le chat entre étudiants et tuteurs
- [ ] Ajouter un système de notation/avis
- [ ] Gérer l'historique des transactions
- [ ] Ajouter la gestion du profil utilisateur
- [ ] Support du mode sombre
- [ ] Internationalisation (multi-langues)

## 📞 Support

Pour toute question ou problème :
1. Vérifier la section Dépannage ci-dessus
2. Consulter la documentation Flutter : https://flutter.dev/docs
3. Vérifier que le backend est bien démarré

## 📄 Licence

Ce projet fait partie du SAE 5A01 - OnlyCode
