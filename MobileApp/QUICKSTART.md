# Guide de démarrage rapide - CryptoCampus Mobile

## 🚀 Démarrage en 5 minutes

### 1. Prérequis

Assurez-vous d'avoir installé :
- Flutter SDK
- Android Studio (pour l'émulateur)
- Docker Desktop (pour le backend)

### 2. Démarrer le backend

```powershell
cd NodeServer
docker-compose up -d
```

### 3. Installer les dépendances Flutter

```powershell
cd MobileApp
flutter pub get
```

### 4. Lancer l'application

```powershell
# Vérifier qu'un émulateur est disponible
flutter devices

# Lancer l'app
flutter run
```

### 5. Créer un compte et explorer !

L'application ouvrira sur l'écran de connexion. Créez un compte pour commencer.

---

## 📱 Visualiser l'application

### Option 1 : Émulateur Android (RECOMMANDÉ)

1. Ouvrir Android Studio
2. **Tools** > **AVD Manager** > **Create Virtual Device**
3. Choisir un device (ex: Pixel 5)
4. Choisir une image système (ex: Android 13)
5. Cliquer sur **Finish**
6. Lancer l'émulateur avec le bouton ▶️
7. Dans le terminal :
   ```powershell
   flutter run
   ```

### Option 2 : Chrome (pour tester l'UI)

```powershell
flutter run -d chrome
```

⚠️ **Note** : Chrome ne permet pas de se connecter à `localhost` backend. Juste pour visualiser l'UI.

### Option 3 : Appareil physique Android

1. Activer le mode développeur :
   - **Paramètres** > **À propos du téléphone**
   - Taper 7 fois sur **Numéro de build**

2. Activer le débogage USB :
   - **Paramètres** > **Options pour les développeurs**
   - Activer **Débogage USB**

3. Connecter via USB et autoriser l'ordinateur

4. Trouver l'IP de votre machine :
   ```powershell
   ipconfig
   # Chercher "Adresse IPv4"
   ```

5. Modifier `.env` :
   ```env
   API_BASE_URL=http://192.168.1.XXX:81
   ```

6. Lancer :
   ```powershell
   flutter run
   ```

---

## 🎯 Comptes de test

Vous pouvez créer un nouveau compte ou utiliser la base de données existante si vous avez des utilisateurs.

### Créer un compte de test :
1. Lancer l'app
2. Cliquer sur "S'inscrire"
3. Remplir :
   - Prénom : Test
   - Nom : User
   - Email : test@example.com
   - Mot de passe : password123
   - Rôle : Étudiant ou Tuteur

---

## 🔍 Tester les fonctionnalités

### 1. Wallet (Balance)
- Voir votre balance ETH
- Les comptes Ganache sont pré-chargés avec 100 ETH
- Envoyer de l'ETH à une autre adresse

### 2. Annonces (Shop)
- Parcourir les annonces de tutorat
- Utiliser la recherche sémantique
- Cliquer sur une annonce pour voir les détails
- Réserver et payer en ETH

### 3. Créer une annonce
- Si vous êtes tuteur, créer votre annonce
- Définir le titre, description, matière, niveau
- Fixer votre prix par heure

---

## ⚡ Commandes utiles

### Voir les logs en temps réel
```powershell
flutter run -v
```

### Hot Reload (pendant l'exécution)
- Appuyez sur `r` dans le terminal

### Restart complet
- Appuyez sur `R` dans le terminal

### Nettoyer le projet
```powershell
flutter clean
flutter pub get
```

### Build APK (Android)
```powershell
flutter build apk --release
# Fichier : build/app/outputs/flutter-apk/app-release.apk
```

---

## 🐛 Problèmes courants

### "Unable to connect to API"
- Vérifier que Docker est démarré : `docker ps`
- Vérifier l'URL dans `.env`
- Pour émulateur Android : `API_BASE_URL=http://10.0.2.2:81`
- Pour  émuler sur chrome : `API_BASE_URL=http://127.0.0.1:81`
### "No devices found"
- Lancer un émulateur Android
- OU connecter un appareil physique
- Vérifier avec : `flutter devices`

### Erreur de compilation
```powershell
flutter clean
flutter pub get
flutter run
```

---

## 📸 Screenshots de l'application

L'application contient :
- 🔐 Écran de connexion/inscription
- 🏠 Page d'accueil avec menu
- 💰 Wallet avec gestion ETH
- 🛒 Liste des annonces de tutorat
- 📄 Détails d'une annonce
- ➕ Création d'annonce

---

## 📞 Besoin d'aide ?

1. Consulter le README.md complet
2. Vérifier la documentation Flutter : https://flutter.dev
3. Vérifier que le backend est démarré : http://localhost:81/listings

---

**Bon développement ! 🚀**
