import { QdrantClient } from '@qdrant/js-client-rest';

const client = new QdrantClient({
  url: process.env.QDRANT_URL || 'http://qdrant:6333'
});

const COLLECTION_NAME = 'tutoring_listings';

// Initialiser la collection Qdrant
export async function initQdrantCollection() {
  try {
    // Vérifier si la collection existe
    const collections = await client.getCollections();
    const exists = collections.collections.some(c => c.name === COLLECTION_NAME);
    
    if (!exists) {
      // Créer la collection
      await client.createCollection(COLLECTION_NAME, {
        vectors: {
          size: 384, // Taille pour les embeddings (on utilisera une méthode simple)
          distance: 'Cosine'
        }
      });
      console.log(`✅ Collection "${COLLECTION_NAME}" créée`);
    } else {
      console.log(`✅ Collection "${COLLECTION_NAME}" existe déjà`);
    }
  } catch (error) {
    console.error('❌ Erreur initialisation Qdrant:', error.message);
    throw error;
  }
}

// Créer un embedding simple basé sur le texte (TF-IDF simplifié)
function createSimpleEmbedding(text, size = 384) {
  const normalized = text.toLowerCase();
  const words = normalized.split(/\s+/);
  const vector = new Array(size).fill(0);
  
  // Hash simple pour distribuer les mots dans le vecteur
  words.forEach(word => {
    for (let i = 0; i < word.length; i++) {
      const index = (word.charCodeAt(i) * (i + 1)) % size;
      vector[index] += 1 / (words.length + 1);
    }
  });
  
  // Normalisation
  const magnitude = Math.sqrt(vector.reduce((sum, val) => sum + val * val, 0));
  return vector.map(val => magnitude > 0 ? val / magnitude : 0);
}

// Indexer une annonce dans Qdrant
// `translations` (optionnel) : { en: {title, description}, es: {...}, ... } — permet
// d'afficher l'annonce dans la langue de l'utilisateur et de la retrouver en recherche
// sémantique quelle que soit la langue de la requête (voir createSimpleEmbedding plus bas).
export async function indexListing(listing) {
  try {
    const {
      id,
      title,
      description,
      subject,
      level,
      price,
      tutor_name,
      tutor_email,
      tutor_user_id,
      tutor_lesson_mode,
      tutor_visio_tool,
      tutor_places,
      translations,
    } = listing;

    // Texte combiné pour l'embedding : le français + toutes les traductions disponibles,
    // pour qu'une recherche dans n'importe quelle langue supportée trouve l'annonce.
    const translatedText = translations
      ? Object.values(translations).map((t) => `${t.title} ${t.description}`).join(' ')
      : '';
    const combinedText = `${title} ${description} ${subject} ${level} ${tutor_name} ${translatedText}`;
    const vector = createSimpleEmbedding(combinedText);

    const payload = {
      title,
      description,
      subject,
      level,
      price,
      tutor_name,
      tutor_email,
      tutor_user_id,
      tutor_lesson_mode: tutor_lesson_mode || 'Visio',
      tutor_visio_tool: tutor_visio_tool || 'Zoom',
      tutor_places: Array.isArray(tutor_places) && tutor_places.length > 0 ? tutor_places : ['Visio'],
      created_at: listing.created_at || new Date().toISOString()
    };

    // Aplati les traductions en title_en/description_en, title_es/description_es, etc.
    if (translations) {
      for (const [langCode, text] of Object.entries(translations)) {
        payload[`title_${langCode}`] = text.title;
        payload[`description_${langCode}`] = text.description;
      }
    }

    await client.upsert(COLLECTION_NAME, {
      wait: true,
      points: [
        {
          id: id,
          vector: vector,
          payload
        }
      ]
    });

    console.log(`✅ Annonce #${id} indexée dans Qdrant`);
    return true;
  } catch (error) {
    console.error('❌ Erreur indexation:', error.message);
    throw error;
  }
}

// Rechercher des annonces par mots-clés
export async function searchListings(query, limit = 10) {
  try {
    const vector = createSimpleEmbedding(query);
    
    const results = await client.search(COLLECTION_NAME, {
      vector: vector,
      limit: limit,
      with_payload: true
    });
    
    return results.map(result => ({
      id: result.id,
      score: result.score,
      ...result.payload
    }));
  } catch (error) {
    console.error('❌ Erreur recherche:', error.message);
    throw error;
  }
}

// Obtenir toutes les annonces
export async function getAllListings(limit = 50) {
  try {
    const results = await client.scroll(COLLECTION_NAME, {
      limit: limit,
      with_payload: true,
      with_vector: false
    });
    
    return results.points.map(point => ({
      id: point.id,
      ...point.payload
    }));
  } catch (error) {
    console.error('❌ Erreur récupération annonces:', error.message);
    throw error;
  }
}

// Supprimer une annonce
export async function deleteListing(id) {
  try {
    await client.delete(COLLECTION_NAME, {
      wait: true,
      points: [id]
    });
    console.log(`✅ Annonce #${id} supprimée`);
    return true;
  } catch (error) {
    console.error('❌ Erreur suppression:', error.message);
    throw error;
  }
}

