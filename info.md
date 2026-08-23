# 📋 Compte Rendu du Projet CryptoCampus

Ce document résume l'intégralité de l'architecture, des technologies utilisées et des fonctionnalités implémentées dans le projet **CryptoCampus**. Il sert de base pour la rédaction de votre compte rendu final de solution pour la SAE 5A01.

---

## 🏗️ Architecture Globale & Microservices

Le projet repose sur une approche microservices orchestrée via **Docker Compose**, séparant clairement les responsabilités :
- **Frontend** : Application Web de gestion et de démonstration
- **Application Mobile** : Plateforme applicative destinée aux utilisateurs
- **API (Backend unifié)** : Point d'accès central (Express.js) regroupant les processus métier.
- **Base de Données Relationnelle** : PostgreSQL (historique, utilisateurs, réservation, notifications...)
- **Base de Données Vectorielle** : Qdrant (recherche sémantique des annonces)
- **Blockchain Locale** : Ganache (registre décentralisé et transactions)
- **Outil d'administration DB** : PgAdmin

---

## 🛠️ Stack Technologique Complète

### 1. Application Mobile (Dossier `MobileApp/`)
* **Framework :** Flutter (Dart)
* **Design & UI :** Material Design, Cupertino Icons, Google Fonts, Flutter SVG
* **State Management :** Provider (`provider: ^6.1.1`)
* **Réseau :** `http` & `dio` pour communiquer avec l'API
* **Stockage local :** `shared_preferences` (gestion des sessions, tokens)
* **Configuration :** `flutter_dotenv`

### 2. Application Web (Dossier `NodeServer/Application/Frontend/`)
* **Framework :** Vue.js 3 avec Composition API
* **Bundler & Tooling :** Vite (`@vitejs/plugin-vue`)
* **Routing :** Vue Router
* **Réseau :** Axios pour faire les requêtes à l'API Rest

### 3. Backend & API REST (Dossier `NodeServer/Api/`)
* **Environnement :** Node.js >= 18 (Serveur Express.js unifié `server.js`)
* **Middleware :** CORS, Helmet, Multer (pour l'upload de CV PDF), Express-session & Connect-pg-simple
* **Documentation :** Swagger (`swagger-autogen`, `swagger-ui-express`)
* **Sécurité :** `bcrypt` pour le hachage des mots de passe
* **Modules AI :** `@mistralai/mistralai` pour l'intelligence artificielle, `pdf-parse` pour lire les CV en PDF
* **Modules Blockchain :** `web3.js` pour communiquer avec le nœud RPC Ethereum

### 4. Infrastructure & Bases de données
* **PostgreSQL (v16) :** Base de données relationnelle (stocke les données structurées).
* **PgAdmin (Port 5050) :** GUI d'administration pour manager PostgreSQL.
* **Qdrant (Port 6333) :** Moteur de recherche et store vectoriel (`@qdrant/js-client-rest`).
* **Ganache (Port 8545) :** C'est un simulateur local de blockchain Ethereum utilisé pour reproduire le fonctionnement d'un registre décentralisé (`trufflesuite/ganache:latest`).
* **Divers :** Shell Scripts d'orchestration (`startAll.sh`, `dumpDB.sh`, etc.) pour la CI/CD locale.

---

## ✨ Fonctionnalités Implémentées

### 🧑‍🎓 Gestion des Utilisateurs & Authentification
- Création de rôles (`STUDENT`, `TUTOR`, `ADMIN`).
- Inscription (`/api/register`), connexion (`/api/login`), déconnexion et vérification de la session.
- Gestion du profil utilisateur (`GET/DELETE /api/account` et `/api/users/:id`).
- Protection des routes via un middleware d'authentification (`authGuard`).

### 📅 Réservations et Disponibilités (Système de Tutorat)
- Les tuteurs peuvent ajouter et supprimer leurs créneaux de disponibilité horaires (`POST /api/availability`).
- Vues des disponibilités liées aux tutorats et la possibilité pour les étudiants de faire une réservation (`GET /api/bookings`).
- Modèle relationnel robuste validé dans la DB (vérification de la chronologie avec contraintes SQL).

### 💬 Messagerie & Notifications
- Possibilité pour les utilisateurs d'avoir des conversations directes (modèle de données `conversations` et `messages` empêchant d'envoyer un DM à soi-même).
- Système de notifications pour alerter le tuteur des demandes de cours (`GET /api/tutor/notifications` et marqueurs en "lu").

### 💼 Services et Annonces (Listings)
- Ajout, édition, suppression, et listing des annonces (`GET/POST /api/listings`).
- Sauvegarde en base de données relationnelle et indexation synchrone dans la base vectorielle.

### 🧠 Intelligence Artificielle & IA Générative
- **Analyse de CV :** Endpoint (`POST /api/analyze-cv`) par lequel un utilisateur "Tuteur" upload son CV au format PDF. Le serveur extrait le texte via `pdf-parse` et l'envoie à l'API Mistral AI qui parse, analyse et génère une proposition d'annonce et relève les compétences associées.
- **Recherche Sémantique (Qdrant) :** Système simulant un espace de recommandation et de similarité (`/api/listings/search`). Lors de la création de l'annonce, l'API génère un modèle vectoriel par hash/TF-IDF combinant (titre, description, matière, niveau) puis indexe le payload. L'étudiant peut rechercher textuellement ("mathématiques lycée") et Qdrant ressort l'annonce avec les degrés de similarité Cosinus.

### ⛓️ Intégration Blockchain et Paiements (CryptoCampus)
- **Exploration des comptes :** L'API interroge le nœud RPC local (Ganache) pour lire les identifiants de portefeuilles ("Wallets") et afficher les balances en ETH (`GET /api/blockchain/accounts`, `GET /api/blockchain/balance/:address`).
- **Gestion des transactions :** Possibilité d'initier un transfert on-chain (ETH/Tokens) d'un wallet à un autre (`POST /api/blockchain/transaction`). L'API s'assure d'insérer le résultat dans la table SQL `transactions` à des fins d'historique ainsi qu'il l'émet sur la blockchain EVM (smart contract/ledger natif) nécessitant du « gas ».
- La base de données SQL maintient la liaison entre la clé ou adresse publique sur la Blockchain et l'identifiant (`user_id`) de l'étudiant/tuteur dans rel-db.

### 📱 Ecrans de l'application Mobile (`screens/`)
L'équipe a implémenté plusieurs écrans sur Flutter :
- `auth/` (Splash screen / Inscription / Connexion)
- `home/` (Dashboard principal)
- `shop/` (Boutique ou explorateur d'annonces de tutorat + détails par annonce)
- `balance/` (Interface pour visionner son solde de cryptomonnaie et gérer ses transactions de la wallet intégrée)
- `create_request/` et `bookings/` pour orchestrer la logistique du tutorat.

### 🔧 Outillage et Scripts DevOps locaux
Dossier complet (`NodeServer/Scripts/`) de facilitations et DevOps pour gérer l'environnement :
- `buildVueApp.sh` / `reloadContainerFront.sh` : Processus de build et de rafraichissement à chaud du frontal web.
- `dumpDB.sh` / `restoreDB.sh` : Outils de migration et sauvegarde de la base relationnelle postgres.
- `[quick]startAll.sh`, `stopAll.sh` : Points d'entrées confortables évitant les commandes Docker brutes.

---

> _Ce document synthétise tout le potentiel de **CryptoCampus**. Vous pouvez copier/coller ces sections pour rédiger les parties "technique et fonctionnelle" de votre CR final._