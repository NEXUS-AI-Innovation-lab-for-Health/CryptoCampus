# 🎓 CryptoCampus

Plateforme de tutorat décentralisée combinant recherche sémantique IA et transactions blockchain.

## 📋 Aperçu

CryptoCampus est une application web et mobile complète qui permet :

### 🎯 Fonctionnalités principales
- � **Application mobile Flutter** (Android/iOS) avec interface native
- 🔍 **Recherche sémantique intelligente** d'annonces de tutorat (Qdrant)
- 💰 **Paiements décentralisés** via blockchain Ethereum (Ganache) 
- 📄 **Analyse automatique de CV** pour création d'annonces en un clic
- 🔐 **API REST sécurisée** avec endpoints blockchain et recherche sémantique
- 💳 **Transactions crypto en temps réel** avec suivi des soldes et historique
- 🤖 **Matching intelligent** entre tuteurs et étudiants par similarité de compétences
- 📈 **Gestion complète de base de données** via PgAdmin (interface graphique)
- 🔄 **Architecture microservices** containerisée avec Docker Compose
- 🚀 **Déploiement automatisé** avec scripts de démarrage/arrêt simplifiés

## 🏗️ Architecture

```
┌─────────────────┐     ┌─────────────────┐
│   Frontend Web  │     │  Mobile App     │
│  (HTML/JS/CSS)  │     │   (Flutter)     │
│   Port 80       │     │  Android/iOS    │
└────────┬────────┘     └────────┬────────┘
         │                       │
         └───────────┬───────────┘
                     │
    ┌────────────────▼──────────────────────┐
    │      API CryptoCampus (Port 81)      │
    │  ┌──────────┬──────────┬──────────┐  │
    │  │ REST API │ Web3.js  │ Qdrant   │  │
    │  └────┬─────┴────┬─────┴────┬─────┘  │
    └───────┼──────────┼──────────┼────────┘
            │          │          │
    ┌───────▼─────┐ ┌──▼──────┐ ┌▼────────┐
    │ PostgreSQL  │ │ Ganache │ │ Qdrant  │
    │ (Port 5432) │ │  (8545) │ │ (6333)  │
    └─────────────┘ └─────────┘ └─────────┘
```

## 🚀 Démarrage rapide

### Prérequis

- Docker & Docker Compose
- Git
- Flutter SDK (pour l'app mobile)

### Installation Backend

```bash
# Cloner le dépôt
git clone https://github.com/NEXUS-AI-Innovation-lab-for-Health/CryptoCampus.git
cd CryptoCampus/NodeServer

# Lancer tous les services
./Scripts/startAll.sh
```

Les services seront disponibles sur :
- **Application Web** : http://localhost:80
- **API** : http://localhost:81
- **PgAdmin** : http://localhost:5050
- **Qdrant Dashboard** : http://localhost:6333/dashboard

### Installation App Mobile

```bash
# Depuis la racine du projet
cd MobileApp

# Installer les dépendances
flutter pub get

# Lancer l'app
flutter run
```

### Arrêter les services

```bash
cd NodeServer
./Scripts/stopAll.sh
```

## 🌐 Services disponibles

| Service | URL | Description |
|---------|-----|-------------|
| **Frontend** | http://localhost:80 | Application principale |
| **API** | http://localhost:81 | API REST + Blockchain + IA |
| **PostgreSQL** | localhost:5432 | Base de données |
| **PgAdmin** | http://localhost:5050 | Interface DB |
| **Qdrant** | http://localhost:6333 | Base vectorielle + Dashboard |
| **Ganache** | http://localhost:8545 | Blockchain Ethereum locale |

## 📦 Fonctionnalités

### 🔗 Blockchain (Ganache)

**Endpoints API :**
```bash
GET  /blockchain/accounts              # Liste des comptes
GET  /blockchain/balance/:address      # Solde d'un compte
POST /blockchain/transaction           # Nouvelle transaction
GET  /blockchain/transaction/:hash     # Détails transaction
```

**Exemple :**
```bash
# Envoyer 50 ETH
curl -X POST http://localhost:81/blockchain/transaction \
  -H "Content-Type: application/json" \
  -d '{
    "fromAddress": "0x90F8bf6A479f320ead074411a4B0e7944Ea8c9C1",
    "toAddress": "0xFFcf8FDEE72ac11b5c542428B35EEF5769C409f0",
    "amount": 50
  }'
```

### 🔍 Recherche sémantique (Qdrant)

- Recherche intelligente d'annonces
- Embeddings 384 dimensions
- Similarité cosinus
- Analyse de CV automatique

**Endpoints API :**
```bash
GET  /listings                    # Toutes les annonces
GET  /listings/search?q=<query>   # Recherche sémantique
POST /analyze-cv                  # Analyser un CV (PDF)
```

**Exemple :**
```bash
# Recherche
curl "http://localhost:81/listings/search?q=mathematiques+lycee"

# Analyse CV
curl -X POST http://localhost:81/analyze-cv \
  -F "cv=@chemin/vers/CV.pdf"
```

## 🗂️ Structure du projet

```
CryptoCampus/
├── MobileApp/                    # Application Flutter
│   ├── lib/
│   │   ├── main.dart            # Point d'entrée
│   │   ├── screens/             # Écrans (auth, home, shop, etc.)
│   │   ├── providers/           # State management
│   │   ├── models/              # Modèles de données
│   │   └── services/            # Services API
│   ├── android/                 # Config Android
│   ├── ios/                     # Config iOS
│   └── pubspec.yaml             # Dépendances Flutter
├── NodeServer/
│   ├── Api/                      # API REST
│   │   ├── server.js            # Serveur Express
│   │   └── blockchain.js        # Logique blockchain
│   ├── Application/              # Frontend Web
│   │   ├── Frontend/            # Pages HTML/CSS/JS
│   │   └── Backend/             # Serveur Node
│   ├── Docker/                   # Dockerfiles + Configs
│   ├── Scripts/                  # Scripts de gestion
│   │   ├── startAll.sh          # Démarrer tout
│   │   ├── stopAll.sh           # Arrêter tout
│   │   ├── dumpDB.sh            # Sauvegarder la DB
│   │   └── restoreDB.sh         # Restaurer la DB
│   └── docker-compose.yml        # Orchestration Docker
└── README.md
```

## 🛠️ Technologies

### Mobile
- **Flutter** 3.x (Dart)
- **Provider** (State management)
- **HTTP** (API calls)

### Backend
- **Node.js** 24 (Alpine)
- **Express.js** 4.x
- **Web3.js** 4.x (Blockchain)
- **Qdrant Client** (Recherche vectorielle)
- **PostgreSQL** 16

### Frontend Web
- HTML5 / CSS3 / JavaScript Vanilla
- Fetch API

### Infrastructure
- **Docker & Docker Compose**
- **Ganache** (Blockchain Ethereum)
- **Qdrant** (Base de données vectorielle)
- **PostgreSQL** (Base de données relationnelle)
- **PgAdmin** (Interface de gestion DB)

## 📚 Documentation

- [Guide des services](NodeServer/GUIDE_SERVICES.md) - Documentation complète des endpoints
- [Guide Mobile](MobileApp/README.md) - Documentation de l'app Flutter

## 🎨 Pages de démonstration

**Web :**
- **Blockchain** : http://localhost:80/blockchain-demo
- **Annonces Qdrant** : http://localhost:80/listings-demo
- **Création avec CV** : http://localhost:80/create-listing-cv

**Mobile :** Lancez l'app Flutter pour accéder à toutes les fonctionnalités

## 🔧 Commandes utiles

```bash
# Voir les logs
docker logs api_crypto --tail 50
docker logs node-app --tail 50

# Reconstruire un service
docker compose build api --no-cache
docker compose up -d api

# Redémarrer un service
docker restart api_crypto

# Accéder à un conteneur
docker exec -it api_crypto sh

# Voir l'état des conteneurs
docker ps
```

## ⚙️ Configuration

### Variables d'environnement

Les variables sont configurées dans le fichier `.env` (à créer) :

```env
DB_HOST=db
DB_USER=myuser
DB_PASSWORD=mypassword
DB_NAME=mydb
DB_PORT=5432

POSTGRES_USER=myuser
POSTGRES_PASSWORD=mypassword
POSTGRES_DB=mydb

BLOCKCHAIN_RPC=http://ganache:8545
```

## 🐛 Résolution de problèmes

### Les conteneurs ne démarrent pas
```bash
# Nettoyer et redémarrer
docker compose down -v
docker compose build --no-cache
docker compose up -d
```

### Erreur "No such image: postgres:16"
```bash
# Télécharger l'image manuellement
docker pull postgres:16
```

### Erreur CORS sur l'API
Le CORS est déjà configuré pour accepter toutes les origines en développement.

## 📄 Licence

Ce projet est développé dans le cadre de la SAE 5A01.

## 🔗 Liens utiles

- [Documentation Flutter](https://docs.flutter.dev/)
- [Documentation Docker](https://docs.docker.com/)
- [Web3.js Documentation](https://web3js.readthedocs.io/)
- [Qdrant Documentation](https://qdrant.tech/documentation/)
- [Ganache Documentation](https://trufflesuite.com/docs/ganache/)
