// Script pour ajouter des annonces de démonstration dans Qdrant
import { indexListing } from './qdrant-service.js';

const demoListings = [
  {
    id: 1,
    title: "Cours de Mathématiques - Terminale S",
    description: "Cours particuliers de mathématiques pour lycéens en Terminale S. Algèbre, analyse, géométrie. Préparation au bac.",
    subject: "Mathématiques",
    level: "Terminale",
    price: 30,
    tutor_name: "Marie Dupont",
    created_at: new Date().toISOString()
  },
  {
    id: 2,
    title: "Python pour Débutants",
    description: "Initiation à la programmation Python. Variables, boucles, fonctions, POO. Projets pratiques inclus.",
    subject: "Informatique",
    level: "Débutant",
    price: 25,
    tutor_name: "Thomas Martin",
    created_at: new Date().toISOString()
  },
  {
    id: 3,
    title: "Physique-Chimie Lycée",
    description: "Cours de physique et chimie pour lycéens. Mécanique, optique, chimie organique. Exercices corrigés.",
    subject: "Physique-Chimie",
    level: "Lycée",
    price: 28,
    tutor_name: "Sophie Bernard",
    created_at: new Date().toISOString()
  },
  {
    id: 4,
    title: "Anglais - Conversation et Grammaire",
    description: "Perfectionnement en anglais. Conversation, grammaire, préparation TOEFL/TOEIC. Tous niveaux.",
    subject: "Anglais",
    level: "Tous niveaux",
    price: 22,
    tutor_name: "John Smith",
    created_at: new Date().toISOString()
  },
  {
    id: 5,
    title: "JavaScript & React - Développement Web",
    description: "Développement web moderne avec JavaScript ES6+, React, Redux. Création d'applications web complètes.",
    subject: "Informatique",
    level: "Intermédiaire",
    price: 35,
    tutor_name: "Lucas Petit",
    created_at: new Date().toISOString()
  },
  {
    id: 6,
    title: "Histoire-Géographie Collège",
    description: "Soutien scolaire en histoire et géographie pour collégiens. Méthodologie, révisions, préparation examens.",
    subject: "Histoire-Géo",
    level: "Collège",
    price: 20,
    tutor_name: "Claire Dubois",
    created_at: new Date().toISOString()
  },
  {
    id: 7,
    title: "Espagnol - Tous Niveaux",
    description: "Cours d'espagnol personnalisés. Conversation, grammaire, culture hispanique. Préparation DELE.",
    subject: "Espagnol",
    level: "Tous niveaux",
    price: 23,
    tutor_name: "Carlos Rodriguez",
    created_at: new Date().toISOString()
  },
  {
    id: 8,
    title: "Biologie - Préparation Médecine",
    description: "Cours de biologie pour étudiants en PACES/médecine. Biologie cellulaire, génétique, physiologie.",
    subject: "Biologie",
    level: "Supérieur",
    price: 40,
    tutor_name: "Dr. Anne Laurent",
    created_at: new Date().toISOString()
  },
  {
    id: 9,
    title: "Piano - Débutant à Avancé",
    description: "Cours de piano classique et moderne. Solfège, technique, interprétation. Préparation concours.",
    subject: "Musique",
    level: "Tous niveaux",
    price: 35,
    tutor_name: "Pierre Moreau",
    created_at: new Date().toISOString()
  },
  {
    id: 10,
    title: "Aide aux Devoirs - Primaire",
    description: "Aide aux devoirs pour élèves de primaire. Toutes matières, méthodologie, confiance en soi.",
    subject: "Multidisciplinaire",
    level: "Primaire",
    price: 18,
    tutor_name: "Emma Rousseau",
    created_at: new Date().toISOString()
  }
];

async function seedDatabase() {
  console.log('🌱 Début de l\'insertion des données de démonstration...\n');
  
  for (const listing of demoListings) {
    try {
      await indexListing(listing);
      console.log(`✅ ${listing.title}`);
    } catch (error) {
      console.error(`❌ Erreur pour "${listing.title}":`, error.message);
    }
  }
  
  console.log('\n✨ Insertion terminée !');
  process.exit(0);
}

seedDatabase();
