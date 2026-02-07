import { initQdrantCollection, indexListing } from './qdrant-service.js';

// Données de test : annonces d'aide aux devoirs
const sampleListings = [
  {
    id: 1,
    title: "Cours de Mathématiques - Algèbre et Géométrie",
    description: "Aide aux devoirs en mathématiques pour les élèves de collège. Je peux vous aider avec l'algèbre, la géométrie, les équations et les problèmes.",
    subject: "Mathématiques",
    level: "Collège",
    price: 15,
    tutor_name: "Sophie Martin",
    created_at: new Date().toISOString()
  },
  {
    id: 2,
    title: "Soutien en Physique-Chimie niveau Lycée",
    description: "Étudiant en école d'ingénieur propose des cours de physique-chimie pour lycéens. Préparation au bac, aide aux exercices et expériences.",
    subject: "Physique-Chimie",
    level: "Lycée",
    price: 20,
    tutor_name: "Thomas Dubois",
    created_at: new Date().toISOString()
  },
  {
    id: 3,
    title: "Anglais - Conversation et Grammaire",
    description: "Professeur certifié d'anglais donne des cours particuliers. Amélioration de l'oral, grammaire, préparation aux examens TOEFL et TOEIC.",
    subject: "Anglais",
    level: "Tous niveaux",
    price: 18,
    tutor_name: "Emma Wilson",
    created_at: new Date().toISOString()
  },
  {
    id: 4,
    title: "Français - Littérature et Dissertation",
    description: "Aide en français : analyse de texte, dissertation, commentaire composé. Préparation bac français et amélioration de l'expression écrite.",
    subject: "Français",
    level: "Lycée",
    price: 17,
    tutor_name: "Pierre Lefebvre",
    created_at: new Date().toISOString()
  },
  {
    id: 5,
    title: "Informatique - Programmation Python",
    description: "Cours de programmation en Python pour débutants et intermédiaires. Algorithmique, structures de données, projets pratiques.",
    subject: "Informatique",
    level: "Lycée/Supérieur",
    price: 25,
    tutor_name: "Alex Chen",
    created_at: new Date().toISOString()
  },
  {
    id: 6,
    title: "Histoire-Géographie - Préparation Brevet",
    description: "Soutien en histoire-géo pour les élèves de 3ème. Méthodologie, fiches de révision, entraînement aux épreuves du brevet.",
    subject: "Histoire-Géographie",
    level: "Collège",
    price: 14,
    tutor_name: "Marie Rousseau",
    created_at: new Date().toISOString()
  },
  {
    id: 7,
    title: "SVT - Biologie et Sciences de la Terre",
    description: "Cours de SVT pour collégiens et lycéens. Biologie cellulaire, génétique, géologie. Préparation contrôles et examens.",
    subject: "SVT",
    level: "Collège/Lycée",
    price: 16,
    tutor_name: "Julie Moreau",
    created_at: new Date().toISOString()
  },
  {
    id: 8,
    title: "Espagnol - Cours particuliers débutant",
    description: "Native espagnole donne cours d'espagnol. Conversation, grammaire, culture hispanophone. Méthode ludique et interactive.",
    subject: "Espagnol",
    level: "Débutant/Intermédiaire",
    price: 16,
    tutor_name: "Carmen García",
    created_at: new Date().toISOString()
  },
  {
    id: 9,
    title: "Mathématiques avancées - Terminale S",
    description: "Préparation bac S en mathématiques. Analyse, probabilités, suites, fonctions. Résolution d'exercices types et annales.",
    subject: "Mathématiques",
    level: "Terminale",
    price: 22,
    tutor_name: "Laurent Bernard",
    created_at: new Date().toISOString()
  },
  {
    id: 10,
    title: "Philosophie - Méthodologie et Concepts",
    description: "Cours de philosophie niveau terminale. Méthodologie de la dissertation, explication de texte, auteurs au programme.",
    subject: "Philosophie",
    level: "Terminale",
    price: 19,
    tutor_name: "Isabelle Fontaine",
    created_at: new Date().toISOString()
  },
  {
    id: 11,
    title: "Économie - SES Première et Terminale",
    description: "Sciences économiques et sociales : microéconomie, macroéconomie, sociologie. Graphiques, analyses de documents.",
    subject: "SES",
    level: "Lycée",
    price: 18,
    tutor_name: "Nicolas Petit",
    created_at: new Date().toISOString()
  },
  {
    id: 12,
    title: "Allemand - Cours tous niveaux",
    description: "Professeur d'allemand expérimenté. Grammaire, vocabulaire, compréhension orale et écrite. Préparation certifications.",
    subject: "Allemand",
    level: "Tous niveaux",
    price: 17,
    tutor_name: "Hans Schmidt",
    created_at: new Date().toISOString()
  }
];

async function seedQdrant() {
  try {
    console.log('🌱 Initialisation de Qdrant avec des données de test...\n');
    
    // Initialiser la collection
    await initQdrantCollection();
    
    console.log('\n📚 Indexation des annonces...\n');
    
    // Indexer toutes les annonces
    for (const listing of sampleListings) {
      await indexListing(listing);
    }
    
    console.log(`\n✅ ${sampleListings.length} annonces indexées avec succès !`);
    console.log('\n💡 Vous pouvez maintenant tester la recherche sur http://localhost:81/test-listings.html');
    
  } catch (error) {
    console.error('❌ Erreur lors du seed:', error);
    process.exit(1);
  }
}

// Exécuter le seed
seedQdrant();
