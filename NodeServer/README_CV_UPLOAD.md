# 📄 Création d'Annonces depuis un CV

Cette fonctionnalité permet aux tuteurs de créer automatiquement des annonces de cours en uploadant simplement leur CV.

## 🎯 Fonctionnement

### 1. Upload du CV
- Format accepté : **PDF uniquement**
- Taille maximale : **5 MB**
- Drag & drop ou sélection de fichier

### 2. Analyse automatique
Le système analyse le CV pour :
- ✅ Extraire les **compétences** (maths, physique, informatique, langues, etc.)
- ✅ Détecter le **niveau d'études** du candidat
- ✅ Identifier le **nom** du tuteur

### 3. Suggestions de cours
Basé sur les compétences détectées, le système génère automatiquement :
- 📚 Des **titres de cours** adaptés
- 📝 Des **descriptions** pertinentes
- 💰 Des **prix suggérés** (15-30€/h selon la matière)
- 🎯 Des **niveaux cibles** (Collège, Lycée, Supérieur)

### 4. Validation et publication
- Le tuteur peut **cocher/décocher** les annonces suggérées
- En un clic, toutes les annonces sélectionnées sont **publiées sur Qdrant**
- Les annonces deviennent immédiatement **cherchables**

## 🔍 Compétences détectées

Le système reconnaît les domaines suivants :

| Domaine | Mots-clés détectés |
|---------|-------------------|
| **Mathématiques** | mathématiques, maths, algèbre, géométrie, calcul, statistiques |
| **Physique-Chimie** | physique, chimie, mécanique, thermodynamique, électricité |
| **Informatique** | programmation, python, java, javascript, web, algorithme |
| **Anglais** | anglais, english, toefl, toeic, ielts |
| **Français** | français, littérature, grammaire, orthographe |
| **Espagnol** | espagnol, español, dele |
| **Allemand** | allemand, deutsch, goethe |
| **Histoire-Géo** | histoire, géographie, géopolitique |
| **Philosophie** | philosophie, épistémologie, éthique |
| **Économie** | économie, ses, gestion, finance |
| **SVT** | biologie, svt, génétique, écologie |

## 🚀 Utilisation

### Accès à la page
```
http://localhost/create-listing-cv
```

### API Endpoint

**POST** `/analyze-cv`

**Request:**
- Content-Type: `multipart/form-data`
- Body: `cv` (fichier PDF)

**Response:**
```json
{
  "success": true,
  "skills": ["Mathématiques", "Physique-Chimie", "Informatique"],
  "suggestions": [
    {
      "title": "Cours de Mathématiques - Algèbre et Géométrie",
      "description": "Aide aux devoirs en mathématiques...",
      "subject": "Mathématiques",
      "level": "Lycée",
      "price": 18,
      "tutor_name": "Jean Dupont"
    }
  ],
  "tutorName": "Jean Dupont",
  "detectedLevel": "Lycée"
}
```

## 📦 Dépendances

```json
{
  "multer": "^1.4.5-lts.1",
  "pdf-parse": "^1.1.1"
}
```

## 🔧 Installation

1. Installer les dépendances :
```bash
docker exec api_crypto npm install
```

2. Redémarrer les conteneurs :
```bash
docker-compose restart app api
```

3. Accéder à la page :
```
http://localhost/create-listing-cv
```

## 💡 Exemples de CV

Pour tester, votre CV PDF devrait contenir :

**Exemple 1 - Profil scientifique :**
```
Jean Dupont
Master en Physique-Chimie
Université de Paris

Compétences :
- Mathématiques avancées
- Physique quantique
- Programmation Python
- Analyse de données
```

→ Génèrera des cours en Maths, Physique, Informatique

**Exemple 2 - Profil linguiste :**
```
Marie Martin
Licence LLCE Anglais
Certifications : TOEFL 110, Cambridge C2

Compétences :
- Anglais (bilingue)
- Espagnol (courant)
- Traduction
- Littérature
```

→ Génèrera des cours en Anglais, Espagnol, Français

## 🎨 Interface

L'interface propose :
- ✅ Upload par **drag & drop** ou clic
- ✅ Validation en temps réel (PDF uniquement)
- ✅ Affichage des **compétences détectées**
- ✅ **Cartes de suggestions** interactives
- ✅ Sélection **checkbox** des annonces
- ✅ Publication en **un clic**
- ✅ Message de **succès** avec lien vers les annonces

## 🔐 Améliorations futures

- [ ] Support de formats supplémentaires (DOCX, TXT)
- [ ] Extraction d'email et téléphone
- [ ] Détection du niveau de langue (A1-C2)
- [ ] Scoring de pertinence des suggestions
- [ ] Modification manuelle des suggestions
- [ ] Upload de photo de profil
- [ ] Sauvegarde du CV dans la BDD
- [ ] Authentification utilisateur

## 🐛 Dépannage

### Erreur "Aucune compétence détectée"
→ Vérifiez que votre CV contient des mots-clés reconnus (voir tableau ci-dessus)

### Erreur "Impossible de lire le PDF"
→ Le PDF est peut-être corrompu ou protégé par mot de passe

### Fichier refusé
→ Vérifiez que c'est bien un PDF (pas une image ou un scan)

## 📊 Workflow complet

```
1. Tuteur → Upload CV (PDF)
         ↓
2. Backend → Extraction texte (pdf-parse)
         ↓
3. Backend → Détection compétences (mots-clés)
         ↓
4. Backend → Génération suggestions (templates)
         ↓
5. Frontend → Affichage + Sélection
         ↓
6. Tuteur → Validation des annonces
         ↓
7. Backend → Publication sur Qdrant
         ↓
8. Annonces → Visibles dans la recherche
```

---

**Créé pour SAE5A01 - OnlyCode Platform**
