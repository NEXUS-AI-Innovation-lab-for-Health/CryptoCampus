# 🚀 Guide des Services - CryptoCampus

## 🌐 URLs d'accès aux services
Page démo des annonces (Qdrant) : http://localhost:80/listings-demo
Page démo blockchain (Ganache) : http://localhost:80/blockchain-demo
uploadant simplement un CV PDF : http://localhost/create-listing-cv


| Service | URL | Description |
|---------|-----|-------------|
| **Node App** | http://localhost:80 | Application frontend principale |
| **API CryptoCampus** | http://localhost:81 | API REST avec endpoints blockchain et database |
| **PostgreSQL** | localhost:5432 | Base de données PostgreSQL (connexion directe) |
| **PgAdmin** | http://localhost:5050 | Interface de gestion PostgreSQL <br>📧 `onlycode-admin@gmail.com` <br>🔑 `Zongo94` |
| **Qdrant** | http://localhost:6333/dashboard | Base de données vectorielle pour IA |
| **Ganache** | http://localhost:8545 | Blockchain locale Ethereum avec RPC |

## 📄 Pages de démonstration

- **Annonces (Qdrant)** : http://localhost:80/listings-demo
- **Blockchain (Ganache)** : http://localhost:80/blockchain-demo
- **Création annonce avec CV** : http://localhost:80/create-listing-cv

---

## 🔗 Blockchain Ganache

### Endpoints API

| Endpoint | Méthode | Description |
|----------|---------|-------------|
| `/blockchain/accounts` | GET | Liste tous les comptes avec soldes |
| `/blockchain/balance/:address` | GET | Solde d'un compte spécifique |
| `/blockchain/transaction` | POST | Envoyer une transaction |
| `/blockchain/transaction/:hash` | GET | Détails d'une transaction |

### Exemple : Transaction entre 2 utilisateurs

```bash
# 1. Récupérer les comptes
curl http://localhost:81/blockchain/accounts

# 2. Envoyer 50 ETH
curl -X POST http://localhost:81/blockchain/transaction \
  -H "Content-Type: application/json" \
  -d '{
    "fromAddress": "0x90F8bf6A479f320ead074411a4B0e7944Ea8c9C1",
    "toAddress": "0xFFcf8FDEE72ac11b5c542428B35EEF5769C409f0",
    "amount": 50
  }'
```

---

## 🔍 Qdrant - Recherche sémantique

### Configuration
- **Collection** : `tutoring_listings`
- **Dimension** : 384
- **Distance** : Cosine

### Endpoints API

| Endpoint | Méthode | Description |
|----------|---------|-------------|
| `/listings` | GET | Toutes les annonces |
| `/listings/search?q=<query>` | GET | Recherche sémantique |
| `/analyze-cv` | POST | Analyse de CV (multipart/form-data) |

### Exemple : Recherche

```bash
# Recherche sémantique
curl "http://localhost:81/listings/search?q=mathematiques+lycee"

# Analyse de CV
curl -X POST http://localhost:81/analyze-cv \
  -F "cv=@/chemin/vers/CV.pdf"
```

---

## ⚠️ Notes importantes

- **Gas fees** : ~0.000042 ETH par transaction
- **Comptes déterministes** : Mêmes adresses à chaque démarrage
- **Recherche sémantique** : Qdrant comprend le sens, pas juste les mots-clés

