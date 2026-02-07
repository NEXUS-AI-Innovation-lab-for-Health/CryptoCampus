# 🎓 Système d'Annonces d'Aide aux Devoirs avec Qdrant

Ce système permet de gérer et rechercher des annonces d'aide aux devoirs en utilisant **Qdrant** pour la recherche sémantique vectorielle.

## 🚀 Installation et Démarrage

### 1. Installer les dépendances

```powershell
cd NodeServer
docker-compose up -d
```

Cela démarre :
- PostgreSQL (base de données)
- pgAdmin (interface admin DB)
- Qdrant (base de données vectorielle)
- API Node.js

### 2. Installer les dépendances NPM dans le conteneur API

```powershell
docker exec -it api_crypto npm install
```

### 3. Peupler Qdrant avec des annonces de test

```powershell
docker exec -it api_crypto npm run seed
```

Cette commande :
- Crée la collection `tutoring_listings` dans Qdrant
- Indexe 12 annonces de test (maths, physique, anglais, etc.)

### 4. Accéder à la page de test

Ouvrez votre navigateur : **http://localhost:81/test-listings.html**

## 📋 Fonctionnalités

### Page de Test (`test-listings.html`)

- **Affichage de toutes les annonces** : Clic sur "Tout afficher"
- **Recherche sémantique** : Tapez des mots-clés et cliquez sur "Rechercher"
- **Score de pertinence** : Affiche le score de similarité pour chaque résultat

### Exemples de recherches

| Recherche | Résultats attendus |
|-----------|-------------------|
| `mathématiques lycée` | Cours de maths niveau lycée/terminale |
| `anglais conversation` | Cours d'anglais axés sur l'oral |
| `programmation python` | Cours d'informatique Python |
| `préparation bac` | Cours de préparation aux examens |
| `aide devoirs collège` | Soutien scolaire niveau collège |

## 🔌 API Endpoints

### Annonces (Listings)

#### GET `/listings`
Récupère toutes les annonces

**Paramètres query (optionnels)** :
- `limit` : nombre max de résultats (défaut: 50)

**Réponse** :
```json
{
  "success": true,
  "count": 12,
  "listings": [...]
}
```

#### GET `/listings/search?q=<query>`
Recherche des annonces par mots-clés (Qdrant)

**Paramètres query** :
- `q` : terme de recherche (requis)
- `limit` : nombre max de résultats (défaut: 10)

**Exemple** :
```
GET /listings/search?q=mathématiques&limit=5
```

**Réponse** :
```json
{
  "success": true,
  "query": "mathématiques",
  "count": 3,
  "results": [
    {
      "id": 1,
      "score": 0.92,
      "title": "Cours de Mathématiques - Algèbre",
      "description": "...",
      "subject": "Mathématiques",
      "level": "Collège",
      "price": 15,
      "tutor_name": "Sophie Martin"
    }
  ]
}
```

#### POST `/listings`
Créer une nouvelle annonce

**Body JSON** :
```json
{
  "title": "Cours de Physique Quantique",
  "description": "Cours de physique niveau universitaire...",
  "subject": "Physique",
  "level": "Supérieur",
  "price": 30,
  "tutor_name": "Dr. Albert Einstein"
}
```

**Réponse** :
```json
{
  "success": true,
  "listing": {
    "id": 1234567890,
    "title": "...",
    ...
  }
}
```

#### DELETE `/listings/:id`
Supprimer une annonce

**Exemple** :
```
DELETE /listings/1
```

## 🧪 Tests avec cURL ou Postman

### Créer une annonce
```powershell
curl -X POST http://localhost:81/listings `
  -H "Content-Type: application/json" `
  -d '{\"title\":\"Test Cours\",\"description\":\"Description test\",\"subject\":\"Test\",\"level\":\"Test\",\"price\":10,\"tutor_name\":\"Test User\"}'
```

### Rechercher
```powershell
curl "http://localhost:81/listings/search?q=mathématiques"
```

### Tout afficher
```powershell
curl http://localhost:81/listings
```

## 🛠️ Architecture

```
┌─────────────────────┐
│   Frontend HTML     │
│  (test-listings.html)│
└──────────┬──────────┘
           │ HTTP
           ▼
┌─────────────────────┐
│   API Node.js       │
│   (server.js)       │
└──────────┬──────────┘
           │
     ┌─────┴─────┐
     ▼           ▼
┌─────────┐  ┌─────────┐
│ Qdrant  │  │PostgreSQL│
│(search) │  │  (data)  │
└─────────┘  └─────────┘
```

## 📊 Structure des Données

### Collection Qdrant : `tutoring_listings`

- **Vecteur** : 384 dimensions (embedding du texte)
- **Distance** : Cosine similarity
- **Payload** :
  ```json
  {
    "title": "string",
    "description": "string",
    "subject": "string",
    "level": "string",
    "price": number,
    "tutor_name": "string",
    "created_at": "ISO timestamp"
  }
  ```

## 🔧 Configuration

### Variables d'environnement

Dans `NodeServer/.env` ou docker-compose :

```env
QDRANT_URL=http://qdrant-database:6333
```

## 📝 Notes

- Les embeddings sont générés avec un algorithme simple (TF-IDF like)
- Pour une production réelle, utiliser un modèle d'embedding pré-entraîné (Sentence Transformers, OpenAI Embeddings, etc.)
- La recherche Qdrant fonctionne en mode "sémantique" : elle trouve des annonces similaires même si les mots ne correspondent pas exactement

## 🎯 Prochaines Étapes

1. ✅ Système de recherche vectorielle Qdrant
2. 🔲 Intégrer avec PostgreSQL pour la persistence
3. 🔲 Ajouter un système de tokens (paiement)
4. 🔲 Interface utilisateur complète
5. 🔲 Authentification utilisateurs
6. 🔲 Système de réservation de cours
