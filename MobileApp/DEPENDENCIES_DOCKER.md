# 🔗 Dépendances entre l'Application Mobile et les Containers Docker

## 📊 Architecture Simplifiée

```
┌─────────────────────────────────────────────────────┐
│           APPLICATION MOBILE FLUTTER                │
│              (Android/iOS)                          │
└───────────────────┬─────────────────────────────────┘
                    │
                    │ HTTP REST (Port 81)
                    │
                    ▼
┌─────────────────────────────────────────────────────┐
│         🐳 Container: api_crypto (Port 81)         │
│               API REST Principal                    │
└───┬─────────────┬────────────────┬──────────────────┘
    │             │                │
    │             │                │
    ▼             ▼                ▼
┌───────────┐ ┌──────────┐ ┌─────────────────┐
│🐳 db      │ │🐳 ganache│ │🐳 qdrant        │
│PostgreSQL │ │Blockchain│ │Recherche IA     │
│Port 5432  │ │Port 8545 │ │Port 6333        │
└───────────┘ └──────────┘ └─────────────────┘
```

---

## ✅ Containers OBLIGATOIRES pour l'App Mobile

### 1️⃣ **api_crypto** (Port 81) - 🔴 CRITIQUE
**Container :** `api_crypto`  
**Port :** `81`  
**Rôle :** API REST principale - **Point d'entrée unique de l'app mobile**

**Endpoints utilisés par l'app mobile :**
```
POST /users/register          → Inscription
POST /users/by-email          → Connexion
GET  /users/:user_id          → Profil utilisateur

GET  /blockchain/accounts     → Liste des comptes ETH
GET  /blockchain/balance/:adr → Balance d'un compte
POST /blockchain/transaction  → Envoyer ETH

GET  /listings                → Toutes les annonces
GET  /listings/search?q=...   → Recherche sémantique
```

**Sans ce container : L'app mobile ne peut PAS fonctionner du tout** ❌

---

### 2️⃣ **postgres-database** (Port 5432) - 🔴 CRITIQUE
**Container :** `db` (postgres-database)  
**Port :** `5432`  
**Rôle :** Base de données principale

**Données stockées :**
- 👤 **Users** : Comptes utilisateurs (email, password, nom, prénom, rôle)
- 📚 **Listings** : Annonces de tutorat (titre, description, prix, matière, niveau)
- 💸 Potentiellement : Transactions, Sessions, etc.

**Utilisé par :** L'API (`api_crypto`)

**Sans ce container :** 
- ❌ Impossible de se connecter/inscrire
- ❌ Impossible de voir les annonces
- ❌ Aucune donnée utilisateur

---

### 3️⃣ **ganache-blockchain** (Port 8545) - 🟠 IMPORTANT
**Container :** `ganache`  
**Port :** `8545`  
**Rôle :** Blockchain Ethereum locale (Ganache)

**Fonctionnalités :**
- 💰 Gestion des wallets ETH
- 💸 Transactions Ethereum
- 📊 Balance des comptes
- 10 comptes pré-générés avec 1000 ETH chacun

**Utilisé par :** L'API (`api_crypto`) via Web3.js

**Sans ce container :**
- ❌ Le Wallet ne fonctionne pas
- ❌ Impossible de voir la balance ETH
- ❌ Impossible d'envoyer des transactions
- ❌ Les paiements de tutorat ne marchent pas

---

### 4️⃣ **qdrant-database** (Port 6333) - 🟡 IMPORTANT (pour la recherche)
**Container :** `qdrant`  
**Port :** `6333`  
**Rôle :** Base de données vectorielle pour la recherche sémantique IA

**Fonctionnalités :**
- 🔍 Recherche sémantique intelligente
- 📚 Indexation des annonces de tutorat
- 🤖 Comprend le sens des requêtes (pas juste des mots-clés)

**Utilisé par :** L'API (`api_crypto`) pour `/listings/search`

**Sans ce container :**
- ✅ L'app fonctionne toujours
- ❌ La recherche sémantique ne marche pas
- ✅ La liste complète des annonces fonctionne (`GET /listings`)

---

## ❌ Containers NON utilisés par l'App Mobile

### 🟢 **node-app** (Port 80) - OPTIONNEL
**Container :** `app` (node-app)  
**Port :** `80`  
**Rôle :** Application web frontend (pages HTML/EJS)

**Pourquoi l'app mobile ne l'utilise PAS ?**
- L'app mobile a son propre frontend Flutter
- Elle se connecte **directement** à l'API (port 81)
- Elle ne passe **jamais** par le serveur Node (port 80)

**Vous pouvez l'éteindre sans problème pour l'app mobile** ✅

---

### 🟢 **pgadmin** (Port 5050) - OPTIONNEL
**Container :** `pgadmin`  
**Port :** `5050`  
**Rôle :** Interface d'administration PostgreSQL

**Pourquoi l'app mobile ne l'utilise PAS ?**
- C'est juste un outil de gestion de base de données
- L'app mobile ne s'y connecte jamais

**Vous pouvez l'éteindre sans problème pour l'app mobile** ✅

---

## 🚀 Commandes pour démarrer les containers nécessaires

### Option 1 : Démarrer TOUS les containers (recommandé)

```powershell
cd NodeServer
docker-compose up -d
```

Cela démarre tous les containers, y compris ceux optionnels.

---

### Option 2 : Démarrer UNIQUEMENT les containers nécessaires

```powershell
cd NodeServer
docker-compose up -d api db ganache qdrant
```

Cela démarre uniquement :
- ✅ `api_crypto` (API REST)
- ✅ `postgres-database` (PostgreSQL)
- ✅ `ganache-blockchain` (Blockchain)
- ✅ `qdrant-database` (Recherche IA)

---

### Option 3 : Démarrer sans la recherche sémantique

Si vous n'avez pas besoin de la recherche IA :

```powershell
cd NodeServer
docker-compose up -d api db ganache
```

**Conséquences :**
- ✅ Connexion/Inscription fonctionne
- ✅ Wallet fonctionne
- ✅ Liste des annonces fonctionne
- ❌ Recherche sémantique ne fonctionne pas

---

## 🔍 Vérifier que les containers tournent

```powershell
docker ps
```

**Vous devez voir :**

```
CONTAINER ID   IMAGE                          PORTS                    NAMES
xxxxx          api_crypto                     0.0.0.0:81->3000/tcp    api_crypto
xxxxx          postgres:16                    0.0.0.0:5432->5432/tcp  postgres-database
xxxxx          trufflesuite/ganache:latest    0.0.0.0:8545->8545/tcp  ganache-blockchain
xxxxx          qdrant/qdrant:latest           0.0.0.0:6333->6333/tcp  qdrant-database
```

---

## 🧪 Tester la connexion depuis l'app mobile

### 1. Tester l'API

Dans un navigateur ou avec `curl` :

```powershell
# Liste des annonces
curl http://localhost:81/listings

# Comptes blockchain
curl http://localhost:81/blockchain/accounts
```

### 2. Configuration de l'app mobile

**Pour émulateur Android :**
```env
# MobileApp/.env
API_BASE_URL=http://127.0.0.1:81
```

**Pour téléphone physique (même réseau Wi-Fi) :**
```env
# MobileApp/.env
API_BASE_URL=http://192.168.1.XXX:81
```
(Remplacer XXX par l'IP de votre PC)

---

## 📊 Résumé des Dépendances

| Container | Port | Utilisé par mobile | Critique | Fonction |
|-----------|------|-------------------|----------|----------|
| **api_crypto** | 81 | ✅ OUI (Direct) | 🔴 CRITIQUE | Point d'entrée unique |
| **postgres-database** | 5432 | ✅ OUI (Via API) | 🔴 CRITIQUE | Stockage des données |
| **ganache-blockchain** | 8545 | ✅ OUI (Via API) | 🟠 IMPORTANT | Wallet et transactions |
| **qdrant-database** | 6333 | ✅ OUI (Via API) | 🟡 IMPORTANT | Recherche sémantique |
| node-app | 80 | ❌ NON | 🟢 OPTIONNEL | Frontend web uniquement |
| pgadmin | 5050 | ❌ NON | 🟢 OPTIONNEL | Admin PostgreSQL |

---

## 🎯 Configuration Minimale

Pour faire fonctionner l'app mobile, il vous faut **AU MINIMUM** :

```powershell
docker-compose up -d api db ganache
```

**Résultat :**
- ✅ Connexion/Inscription
- ✅ Wallet ETH
- ✅ Transactions
- ✅ Annonces (liste complète)
- ❌ Recherche sémantique (nécessite `qdrant`)

---

## 🐛 Dépannage

### ❌ "Unable to connect to API" dans l'app mobile

**Vérifier que l'API tourne :**
```powershell
docker ps | grep api_crypto
```

**Vérifier que l'API répond :**
```powershell
curl http://localhost:81/listings
```

**Vérifier l'URL dans l'app :**
- Émulateur Android : `http://10.0.2.2:81` ✅
- Téléphone physique : `http://192.168.1.XXX:81` ✅
- `http://localhost:81` ❌ (ne marche PAS sur appareil mobile)

---

### ❌ "Database connection error"

L'API ne peut pas se connecter à PostgreSQL.

**Vérifier que PostgreSQL tourne :**
```powershell
docker ps | grep postgres
```

**Redémarrer les containers dans le bon ordre :**
```powershell
docker-compose down
docker-compose up -d
```

---

### ❌ "Blockchain connection error"

L'API ne peut pas se connecter à Ganache.

**Vérifier que Ganache tourne :**
```powershell
docker ps | grep ganache
```

**Vérifier les logs :**
```powershell
docker logs ganache-blockchain
```

---

## 📝 Ordre de démarrage

Docker Compose gère automatiquement l'ordre grâce à `depends_on`, mais voici la séquence logique :

1. **PostgreSQL** (`db`) démarre en premier
2. **Ganache** (`ganache`) démarre en parallèle
3. **Qdrant** (`qdrant`) démarre en parallèle
4. **API** (`api`) attend que PostgreSQL soit prêt (healthcheck)
5. **Node App** (`app`) peut démarrer (optionnel pour mobile)

---

## 🎉 Conclusion

**Pour l'application mobile Flutter, vous avez besoin de :**

### 🔴 OBLIGATOIRE (minimum vital)
- `api_crypto` sur le port **81**
- `postgres-database` sur le port **5432**
- `ganache-blockchain` sur le port **8545**

### 🟡 RECOMMANDÉ
- `qdrant-database` sur le port **6333** (pour la recherche)

### 🟢 PAS NÉCESSAIRE
- `node-app` (port 80) - Frontend web uniquement
- `pgadmin` (port 5050) - Admin PostgreSQL uniquement

**Commande simple :**
```powershell
cd NodeServer
docker-compose up -d
```

C'est tout ! L'app mobile se connecte uniquement à l'API (port 81), qui gère ensuite les connexions aux autres services. 🚀
