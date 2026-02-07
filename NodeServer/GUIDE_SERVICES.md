# 🚀 Guide d'utilisation de la Blockchain Ganache

## 🌐 URLs d'accès aux services
Page de test des annonces (Qdrant) : http://localhost:81/test-listings.html
Page de test blockchain (Ganache) : http://localhost:81/blockchain-test.html

| Service | URL | Description |
|---------|-----|-------------|
| **Node App** | http://localhost:80 | Application frontend principale |
| **API CryptoCampus** | http://localhost:81 | API REST avec endpoints blockchain et database |
| **PostgreSQL** | localhost:5432 | Base de données PostgreSQL (connexion directe) |
| **PgAdmin** | http://localhost:5050 | Interface de gestion PostgreSQL <br>📧 Email: `onlycode-admin@gmail.com` <br>🔑 Password: `Zongo94` |
| **Qdrant** | http://localhost:6333 | Base de données vectorielle pour IA |
| **Ganache** | http://localhost:8545 | Blockchain locale Ethereum avec RPC |

---

## Configuration actuelle

Votre Ganache est configuré avec :
- **10 comptes** créés automatiquement
- **1000 ETH** de solde initial par compte
- **Network ID**: 1337
- **URL**: http://localhost:8545

## 📡 Endpoints API disponibles

### 1️⃣ Récupérer tous les comptes

```bash
curl http://localhost:81/blockchain/accounts
```

**Réponse exemple :**
```json
{
  "success": true,
  "totalAccounts": 10,
  "accounts": [
    {
      "index": 0,
      "address": "0x90F8bf6A479f320ead074411a4B0e7944Ea8c9C1",
      "balanceWei": "1000000000000000000000",
      "balanceEth": "1000"
    },
    {
      "index": 1,
      "address": "0xFFcf8FDEE72ac11b5c542428B35EEF5769C409f0",
      "balanceWei": "1000000000000000000000",
      "balanceEth": "1000"
    }
  ]
}
```

### 2️⃣ Vérifier le solde d'un compte spécifique

```bash
curl http://localhost:81/blockchain/balance/0x90F8bf6A479f320ead074411a4B0e7944Ea8c9C1
```

**Réponse exemple :**
```json
{
  "success": true,
  "address": "0x90F8bf6A479f320ead074411a4B0e7944Ea8c9C1",
  "balanceWei": "1000000000000000000000",
  "balanceEth": "1000"
}
```

### 3️⃣ Faire une transaction entre utilisateur 1 et utilisateur 2

**Étape 1 : Récupérer les adresses des comptes**

```bash
curl http://localhost:81/blockchain/accounts
```

**Étape 2 : Envoyer une transaction**

```bash
curl -X POST http://localhost:81/blockchain/transaction \
  -H "Content-Type: application/json" \
  -d '{
    "fromAddress": "0x90F8bf6A479f320ead074411a4B0e7944Ea8c9C1",
    "toAddress": "0xFFcf8FDEE72ac11b5c542428B35EEF5769C409f0",
    "amount": 50
  }'
```

**Réponse exemple :**
```json
{
  "success": true,
  "transactionHash": "0x1234567890abcdef...",
  "blockNumber": 1,
  "gasUsed": "21000",
  "from": {
    "address": "0x90F8bf6A479f320ead074411a4B0e7944Ea8c9C1",
    "balanceBefore": "1000",
    "balanceAfter": "949.999958"
  },
  "to": {
    "address": "0xFFcf8FDEE72ac11b5c542428B35EEF5769C409f0",
    "balanceBefore": "1000",
    "balanceAfter": "1050"
  },
  "amount": 50
}
```

### 4️⃣ Consulter les détails d'une transaction

```bash
curl http://localhost:81/blockchain/transaction/0x1234567890abcdef...
```

**Réponse exemple :**
```json
{
  "success": true,
  "transaction": {
    "hash": "0x1234567890abcdef...",
    "from": "0x90F8bf6A479f320ead074411a4B0e7944Ea8c9C1",
    "to": "0xFFcf8FDEE72ac11b5c542428B35EEF5769C409f0",
    "value": "50",
    "gas": "21000",
    "gasPrice": "2",
    "blockNumber": 1,
    "status": "Success",
    "gasUsed": "21000"
  }
}
```

## 🧪 Exemples de scénarios

### Scénario 1 : Transaction simple entre 2 utilisateurs

```javascript
// 1. Récupérer les comptes
const response = await fetch('http://localhost:81/blockchain/accounts');
const { accounts } = await response.json();

const user1 = accounts[0].address;
const user2 = accounts[1].address;

// 2. Envoyer 100 ETH de user1 vers user2
const transaction = await fetch('http://localhost:81/blockchain/transaction', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    fromAddress: user1,
    toAddress: user2,
    amount: 100
  })
});

const result = await transaction.json();
console.log('Transaction réussie !', result);
```

### Scénario 2 : Transactions multiples

```javascript
// User 1 envoie à plusieurs utilisateurs
const transactions = [
  { to: accounts[1].address, amount: 25 },
  { to: accounts[2].address, amount: 30 },
  { to: accounts[3].address, amount: 45 }
];

for (const tx of transactions) {
  const response = await fetch('http://localhost:81/blockchain/transaction', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      fromAddress: accounts[0].address,
      toAddress: tx.to,
      amount: tx.amount
    })
  });
  
  const result = await response.json();
  console.log(`Envoyé ${tx.amount} ETH à ${tx.to}`);
}
```

### Scénario 3 : Vérifier le solde après transaction

```javascript
async function checkBalanceChange(address, operation) {
  const before = await fetch(`http://localhost:81/blockchain/balance/${address}`);
  const beforeData = await before.json();
  
  console.log(`Solde avant: ${beforeData.balanceEth} ETH`);
  
  // Faire la transaction
  await operation();
  
  const after = await fetch(`http://localhost:81/blockchain/balance/${address}`);
  const afterData = await after.json();
  
  console.log(`Solde après: ${afterData.balanceEth} ETH`);
  console.log(`Différence: ${afterData.balanceEth - beforeData.balanceEth} ETH`);
}

// Utilisation
await checkBalanceChange(user1Address, async () => {
  await fetch('http://localhost:81/blockchain/transaction', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      fromAddress: user1Address,
      toAddress: user2Address,
      amount: 50
    })
  });
});
```

## 🛠️ Redémarrer avec les conteneurs

Pour redémarrer tous les services (incluant Ganache) :

```bash
cd /Users/sevohakobyan/Documents/5A01_SAE_OnlyCode/SAE5A01/NodeServer
./Scripts/stopAll.sh
./Scripts/startAll.sh
```

## ⚠️ Notes importantes

1. **Les frais de gas** : Chaque transaction coûte du gas (environ 0.000042 ETH pour une transaction simple)
2. **Comptes déterministes** : Avec `--deterministic`, les mêmes adresses sont générées à chaque redémarrage
3. **Reset** : Si vous redémarrez Ganache, tous les soldes reviennent à 1000 ETH
4. **Network ID** : Toujours utiliser 1337 pour se connecter à cette blockchain

## 📝 Pour reconstruire l'API avec Web3

```bash
cd /Users/sevohakobyan/Documents/5A01_SAE_OnlyCode/SAE5A01/NodeServer
docker compose down
docker compose build api --no-cache
docker compose up -d
```
