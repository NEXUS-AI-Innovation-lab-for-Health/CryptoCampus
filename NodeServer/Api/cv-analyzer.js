import pdfParse from 'pdf-parse';

// Dictionnaire de compétences par domaine
const skillsDatabase = {
    'Mathématiques': ['mathématiques', 'maths', 'algèbre', 'géométrie', 'calcul', 'statistiques', 'probabilités', 'analyse'],
    'Physique-Chimie': ['physique', 'chimie', 'mécanique', 'thermodynamique', 'électricité', 'optique'],
    'Informatique': ['programmation', 'python', 'java', 'javascript', 'c++', 'html', 'css', 'sql', 'développement', 'web', 'algorithme', 'data'],
    'Anglais': ['anglais', 'english', 'toefl', 'toeic', 'ielts', 'cambridge'],
    'Français': ['français', 'littérature', 'grammaire', 'orthographe', 'dissertation', 'commentaire'],
    'Espagnol': ['espagnol', 'español', 'castellano', 'dele'],
    'Allemand': ['allemand', 'deutsch', 'goethe'],
    'Histoire-Géographie': ['histoire', 'géographie', 'géopolitique', 'sciences politiques'],
    'Philosophie': ['philosophie', 'épistémologie', 'éthique', 'logique'],
    'Économie': ['économie', 'ses', 'gestion', 'finance', 'comptabilité', 'microéconomie', 'macroéconomie'],
    'SVT': ['biologie', 'svt', 'sciences de la vie', 'écologie', 'génétique', 'anatomie'],
    'Musique': ['musique', 'piano', 'guitare', 'chant', 'solfège', 'instrument'],
    'Arts': ['dessin', 'peinture', 'arts plastiques', 'photographie', 'design'],
    'Sport': ['sport', 'fitness', 'yoga', 'natation', 'football', 'basketball']
};

// Niveaux d'enseignement
const levels = ['Primaire', 'Collège', 'Lycée', 'Supérieur', 'Tous niveaux'];

// Analyser le PDF et extraire le texte
export async function extractTextFromPDF(buffer) {
    try {
        const data = await pdfParse(buffer);
        return data.text;
    } catch (error) {
        console.error('Erreur extraction PDF:', error);
        throw new Error('Impossible de lire le PDF');
    }
}

// Détecter les compétences dans le texte
export function detectSkills(text) {
    const detectedSkills = new Set();
    const normalizedText = text.toLowerCase();
    
    for (const [subject, keywords] of Object.entries(skillsDatabase)) {
        for (const keyword of keywords) {
            if (normalizedText.includes(keyword.toLowerCase())) {
                detectedSkills.add(subject);
                break;
            }
        }
    }
    
    return Array.from(detectedSkills);
}

// Détecter le niveau d'études du candidat
function detectLevel(text) {
    const normalizedText = text.toLowerCase();
    
    if (normalizedText.includes('doctorat') || normalizedText.includes('phd') || normalizedText.includes('thèse')) {
        return 'Supérieur';
    }
    if (normalizedText.includes('master') || normalizedText.includes('ingénieur') || normalizedText.includes('grande école')) {
        return 'Lycée/Supérieur';
    }
    if (normalizedText.includes('licence') || normalizedText.includes('bachelor')) {
        return 'Lycée';
    }
    if (normalizedText.includes('bac') || normalizedText.includes('terminale')) {
        return 'Collège/Lycée';
    }
    
    return 'Tous niveaux';
}

// Extraire le nom du candidat (heuristique simple)
function extractName(text) {
    const lines = text.split('\n').filter(line => line.trim().length > 0);
    
    // Souvent le nom est dans les premières lignes
    for (let i = 0; i < Math.min(5, lines.length); i++) {
        const line = lines[i].trim();
        // Si la ligne contient 2-3 mots et pas de caractères spéciaux
        const words = line.split(/\s+/);
        if (words.length >= 2 && words.length <= 3 && !/[0-9@]/.test(line)) {
            return line;
        }
    }
    
    return 'Tuteur Expert';
}

// Générer des suggestions de cours basées sur les compétences
export function generateCourseSuggestions(skills, text) {
    const tutorName = extractName(text);
    const defaultLevel = detectLevel(text);
    const suggestions = [];
    
    const coursesTemplates = {
        'Mathématiques': {
            titles: [
                'Cours de Mathématiques - Algèbre et Géométrie',
                'Soutien en Mathématiques niveau {level}',
                'Préparation examens en Mathématiques'
            ],
            descriptions: [
                'Aide aux devoirs en mathématiques. Je peux vous aider avec l\'algèbre, la géométrie, les équations et les problèmes.',
                'Cours particuliers de mathématiques adaptés à votre niveau. Méthodologie, exercices pratiques et préparation aux examens.',
                'Soutien scolaire en maths : renforcement des bases, résolution de problèmes, préparation contrôles.'
            ],
            price: [15, 18, 20, 22]
        },
        'Physique-Chimie': {
            titles: [
                'Cours de Physique-Chimie niveau {level}',
                'Soutien en Sciences Physiques',
                'Aide aux devoirs en Physique-Chimie'
            ],
            descriptions: [
                'Cours de physique-chimie : mécanique, électricité, chimie organique. Expériences et exercices pratiques.',
                'Aide en physique et chimie. Explication des concepts, aide aux TP et préparation aux examens.',
                'Soutien scolaire en sciences physiques. Renforcement des acquis et méthodologie.'
            ],
            price: [18, 20, 22]
        },
        'Informatique': {
            titles: [
                'Programmation {skill} - Cours particuliers',
                'Initiation à l\'Informatique et au Code',
                'Développement Web et Programmation'
            ],
            descriptions: [
                'Cours de programmation pour débutants et intermédiaires. Algorithmique, structures de données, projets pratiques.',
                'Apprenez à coder : Python, JavaScript, développement web. Cours adaptés à tous niveaux.',
                'Formation en développement informatique. Création de sites web, applications, projets personnalisés.'
            ],
            price: [25, 28, 30]
        },
        'Anglais': {
            titles: [
                'Anglais - Conversation et Grammaire',
                'Cours d\'Anglais tous niveaux',
                'Préparation TOEFL/TOEIC/Cambridge'
            ],
            descriptions: [
                'Cours d\'anglais : amélioration de l\'oral, grammaire, vocabulaire. Méthode interactive et ludique.',
                'Perfectionnez votre anglais. Conversation, compréhension, expression écrite et orale.',
                'Préparation aux examens d\'anglais (TOEFL, TOEIC, Cambridge). Entraînement intensif.'
            ],
            price: [18, 20, 22]
        },
        'Français': {
            titles: [
                'Français - Littérature et Dissertation',
                'Cours de Français niveau {level}',
                'Aide en Français : Grammaire et Orthographe'
            ],
            descriptions: [
                'Cours de français : analyse de texte, dissertation, commentaire. Méthodologie et préparation examens.',
                'Soutien en français : grammaire, orthographe, expression écrite. Renforcement des bases.',
                'Aide aux devoirs en français. Littérature, conjugaison, amélioration de l\'écrit.'
            ],
            price: [16, 18, 20]
        },
        'Espagnol': {
            titles: [
                'Cours d\'Espagnol - Débutant à Avancé',
                'Espagnol : Conversation et Grammaire',
                'Espagnol - Cours particuliers'
            ],
            descriptions: [
                'Cours d\'espagnol tous niveaux. Conversation, grammaire, culture hispanophone. Méthode interactive.',
                'Apprenez l\'espagnol facilement. Cours adaptés, exercices pratiques, immersion culturelle.',
                'Perfectionnez votre espagnol. Oral, écrit, préparation examens (DELE).'
            ],
            price: [16, 18, 20]
        },
        'Allemand': {
            titles: [
                'Cours d\'Allemand tous niveaux',
                'Allemand - Grammaire et Conversation',
                'Soutien en Allemand'
            ],
            descriptions: [
                'Cours d\'allemand : grammaire, vocabulaire, compréhension. Préparation certifications Goethe.',
                'Apprenez l\'allemand efficacement. Méthode progressive, exercices pratiques, culture allemande.',
                'Aide en allemand : renforcement, conversation, préparation examens.'
            ],
            price: [17, 19, 21]
        },
        'Histoire-Géographie': {
            titles: [
                'Histoire-Géographie niveau {level}',
                'Cours d\'Histoire et Géographie',
                'Préparation Brevet/Bac en Histoire-Géo'
            ],
            descriptions: [
                'Cours d\'histoire-géographie : méthodologie, fiches de révision, entraînement aux épreuves.',
                'Soutien en histoire-géo. Compréhension des événements, analyse de documents, cartes.',
                'Aide aux devoirs en histoire et géographie. Renforcement des connaissances.'
            ],
            price: [14, 16, 18]
        },
        'Philosophie': {
            titles: [
                'Philosophie - Méthodologie et Concepts',
                'Cours de Philosophie niveau Terminale',
                'Préparation Bac Philosophie'
            ],
            descriptions: [
                'Cours de philosophie : méthodologie dissertation, explication de texte, auteurs au programme.',
                'Aide en philosophie. Compréhension des concepts, argumentation, exemples pratiques.',
                'Soutien en philo : renforcement méthodologique, entraînement aux épreuves.'
            ],
            price: [18, 20, 22]
        },
        'Économie': {
            titles: [
                'SES - Sciences Économiques et Sociales',
                'Cours d\'Économie niveau {level}',
                'Économie et Gestion'
            ],
            descriptions: [
                'Cours de SES : microéconomie, macroéconomie, sociologie. Graphiques, analyses de documents.',
                'Soutien en économie : concepts clés, exercices pratiques, préparation examens.',
                'Aide en sciences économiques. Compréhension des mécanismes économiques.'
            ],
            price: [18, 20, 22]
        },
        'SVT': {
            titles: [
                'SVT - Biologie et Sciences de la Terre',
                'Cours de SVT niveau {level}',
                'Sciences de la Vie et de la Terre'
            ],
            descriptions: [
                'Cours de SVT : biologie cellulaire, génétique, géologie. Préparation contrôles et examens.',
                'Aide en SVT. Compréhension des mécanismes biologiques, schémas, exercices.',
                'Soutien en sciences de la vie : renforcement, méthodologie, TP.'
            ],
            price: [16, 18, 20]
        }
    };
    
    // Générer 2-3 suggestions par compétence détectée
    skills.forEach(skill => {
        if (coursesTemplates[skill]) {
            const template = coursesTemplates[skill];
            const numSuggestions = Math.min(2, template.titles.length);
            
            for (let i = 0; i < numSuggestions; i++) {
                const title = template.titles[i].replace('{level}', defaultLevel).replace('{skill}', skill);
                const description = template.descriptions[i];
                const price = template.price[Math.floor(Math.random() * template.price.length)];
                
                suggestions.push({
                    title,
                    description,
                    subject: skill,
                    level: defaultLevel,
                    price,
                    tutor_name: tutorName
                });
            }
        }
    });
    
    return suggestions;
}

// Fonction principale d'analyse
export async function analyzeCVAndGenerateSuggestions(pdfBuffer) {
    try {
        // 1. Extraire le texte du PDF
        const text = await extractTextFromPDF(pdfBuffer);
        
        // 2. Détecter les compétences
        const skills = detectSkills(text);
        
        if (skills.length === 0) {
            throw new Error('Aucune compétence détectée dans le CV. Veuillez vérifier le contenu.');
        }
        
        // 3. Générer les suggestions de cours
        const suggestions = generateCourseSuggestions(skills, text);
        
        return {
            success: true,
            skills,
            suggestions,
            tutorName: extractName(text),
            detectedLevel: detectLevel(text)
        };
        
    } catch (error) {
        console.error('Erreur analyse CV:', error);
        throw error;
    }
}
