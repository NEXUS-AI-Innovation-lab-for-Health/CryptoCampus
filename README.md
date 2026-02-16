# 🎓 CryptoCampus

Plateforme de tutorat décentralisée combinant recherche sémantique IA et transactions blockchain.

## 📋 Aperçu

CryptoCampus est une application web complète qui permet :

### 🎯 Fonctionnalités principales
- 🔍 **Recherche sémantique intelligente** d'annonces de tutorat (Qdrant)
- 💰 **Paiements décentralisés** via blockchain Ethereum (Ganache) 
- 📄 **Analyse automatique de CV** pour création d'annonces en un clic
- 📊 **Dashboard de monitoring** Qdrant pour visualiser les données vectorielles
- 🔐 **API REST sécurisée** avec endpoints blockchain et recherche sémantique
- 💳 **Transactions crypto en temps réel** avec suivi des soldes et historique
- 🤖 **Matching intelligent** entre tuteurs et étudiants par similarité de compétences
- 📈 **Gestion complète de base de données** via PgAdmin (interface graphique)
- 🔄 **Architecture microservices** containerisée avec Docker Compose
- 🚀 **Déploiement automatisé** avec scripts de démarrage/arrêt simplifiés

## 🏗️ Architecture

```
┌─────────────────┐
│   Frontend      │  ← Node.js + Express (Port 80)
│   (HTML/JS/CSS) │
└────────┬────────┘
         │
    ┌────▼─────────────────────────────────────┐
    │         API CryptoCampus (Port 81)       │
    │  ┌──────────┬──────────┬──────────────┐  │
    │  │ REST API │ Web3.js  │ Qdrant SDK   │  │
    │  └────┬─────┴────┬─────┴──────┬───────┘  │
    └───────┼──────────┼────────────┼──────────┘
            │          │            │
    ┌───────▼─────┐ ┌──▼────────┐ ┌▼──────────┐
    │ PostgreSQL  │ │  Ganache  │ │  Qdrant   │
    │  (Port      │ │ Blockchain│ │  Vector   │
    │   5432)     │ │(Port 8545)│ │  DB       │
    └─────────────┘ └───────────┘ └───────────┘
```

## 🚀 Démarrage rapide

### Prérequis

- Docker & Docker Compose
- Git

### Installation

```bash
# Cloner le dépôt
git clone https://github.com/ThomasLeBg94/SAE5A01.git
cd SAE5A01/NodeServer

# Lancer tous les services
./Scripts/startAll.sh
```

Les services seront disponibles sur :
- **Application** : http://localhost:80
- **API** : http://localhost:81
- **PgAdmin** : http://localhost:5050
- **Qdrant Dashboard** : http://localhost:6333/dashboard

### Arrêter les services

```bash
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
SAE5A01/
├── NodeServer/
│   ├── Api/                      # API REST
│   │   ├── server.js            # Serveur Express
│   │   └── blockchain-example.js # Logique blockchain
│   ├── Application/              # Frontend
│   │   ├── Front/               # Pages HTML/CSS/JS
│   │   └── Back/                # Serveur Node
│   ├── Docker/                   # Dockerfiles
│   │   ├── Api/                 # Config API
│   │   ├── Node/                # Config Frontend
│   │   └── PgAdmin/             # Config + DB backups
│   ├── Scripts/                  # Scripts de gestion
│   │   ├── startAll.sh          # Démarrer tout
│   │   ├── stopAll.sh           # Arrêter tout
│   │   └── restoreDB.sh         # Restaurer la DB
│   ├── docker-compose.yml        # Orchestration Docker
│   └── GUIDE_SERVICES.md         # Documentation détaillée
└── README.md
```

## 🛠️ Technologies

### Backend
- **Node.js** 24 (Alpine)
- **Express.js** 4.x
- **Web3.js** 4.x (Blockchain)
- **Qdrant Client** (Recherche vectorielle)
- **PostgreSQL** 16

### Frontend
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

## 🧪 Pages de test

- **Blockchain** : http://localhost:80/blockchain-test
- **Annonces Qdrant** : http://localhost:80/test-listings
- **Création avec CV** : http://localhost:80/create-listing-cv

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

- [Documentation Docker](https://docs.docker.com/)
- [Web3.js Documentation](https://web3js.readthedocs.io/)
- [Qdrant Documentation](https://qdrant.tech/documentation/)
- [Ganache Documentation](https://trufflesuite.com/docs/ganache/)
