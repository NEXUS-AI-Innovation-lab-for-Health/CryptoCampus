// Script pour ajouter des annonces de démonstration dans Qdrant
import { indexListing } from './qdrant-service.js';

const demoListings = [
  {
    id: 1,
    title: "Cours de Mathématiques - Terminale ",
    description: "Cours particuliers de mathématiques pour lycéens en Terminale. Algèbre, analyse, géométrie. Préparation au bac.",
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
  },
  {
    id: 11,
    title: "Russe - Débutant et Intermédiaire",
    description: "Cours de russe complets. Alphabet cyrillique, grammaire, conversation. Immersion dans la culture russe.",
    subject: "Russe",
    level: "Débutant",
    price: 27,
    tutor_name: "Natalia Ivanova",
    created_at: new Date().toISOString()
  },
  {
    id: 12,
    title: "Mathématiques Expert - Prépa",
    description: "Mathématiques avancées pour classes préparatoires. Algèbre linéaire, analyse complexe, topologie.",
    subject: "Mathématiques",
    level: "Prépa",
    price: 45,
    tutor_name: "Jean-Marc Lefebvre",
    created_at: new Date().toISOString()
  },
  {
    id: 13,
    title: "Allemand - Conversation Avancée",
    description: "Perfectionnement en allemand. Conversation fluide, littérature, préparation Goethe-Zertifikat C1/C2.",
    subject: "Allemand",
    level: "Avancé",
    price: 30,
    tutor_name: "Friedrich Weber",
    created_at: new Date().toISOString()
  },
  {
    id: 14,
    title: "Philosophie - Terminale et Supérieur",
    description: "Cours de philosophie. Auteurs classiques, dissertation, commentaire de texte. Préparation bac et concours.",
    subject: "Philosophie",
    level: "Terminale",
    price: 32,
    tutor_name: "Antoine Mercier",
    created_at: new Date().toISOString()
  },
  {
    id: 15,
    title: "Chinois Mandarin - Initiation",
    description: "Découverte du chinois mandarin. Pinyin, caractères, conversation de base. Culture et calligraphie.",
    subject: "Chinois",
    level: "Débutant",
    price: 28,
    tutor_name: "Li Wei",
    created_at: new Date().toISOString()
  },
  {
    id: 16,
    title: "Économie - SES et Prépa HEC",
    description: "Cours d'économie pour lycéens et prépa. Micro/macroéconomie, actualité économique, dissertation.",
    subject: "Économie",
    level: "Lycée/Prépa",
    price: 38,
    tutor_name: "Isabelle Garnier",
    created_at: new Date().toISOString()
  },
  {
    id: 17,
    title: "Italien - Culture et Langue",
    description: "Cours d'italien tous niveaux. Grammaire, conversation, découverte de la culture italienne.",
    subject: "Italien",
    level: "Tous niveaux",
    price: 24,
    tutor_name: "Marco Rossi",
    created_at: new Date().toISOString()
  },
  {
    id: 18,
    title: "Data Science & Machine Learning",
    description: "Introduction au Data Science. Python, pandas, scikit-learn, deep learning. Projets d'analyse de données.",
    subject: "Informatique",
    level: "Avancé",
    price: 50,
    tutor_name: "Amélie Fontaine",
    created_at: new Date().toISOString()
  },
  {
    id: 19,
    title: "Guitare - Rock et Blues",
    description: "Cours de guitare électrique et acoustique. Techniques, improvisation, théorie musicale. Styles rock et blues.",
    subject: "Musique",
    level: "Intermédiaire",
    price: 30,
    tutor_name: "Marc Leroy",
    created_at: new Date().toISOString()
  },
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
