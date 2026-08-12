import { Mistral } from '@mistralai/mistralai';

const apiKey = process.env.MISTRAL_API_KEY;
const client = apiKey ? new Mistral({ apiKey }) : null;

function ensureClient() {
    if (!client) {
        throw new Error('MISTRAL_API_KEY manquante : impossible de contacter Mistral AI');
    }
    return client;
}

// Analyser le CV avec Mistral AI
export async function analyzeCVWithMistral(cvText) {
    try {
        console.log('🤖 Envoi du CV à Mistral AI pour analyse...');
        
        const prompt = `Tu es un expert en éducation et en analyse de CV. Analyse le CV suivant et extrais :

1. Les compétences principales de la personne (matières qu'elle peut enseigner)
2. Pour chaque compétence, génère 2-3 suggestions de cours qu'elle pourrait proposer

Voici le CV :
---
${cvText}
---

Réponds UNIQUEMENT avec un objet JSON valide (sans markdown, sans \`\`\`json) dans ce format exact :
{
  "tutorName": "Nom de la personne",
  "skills": ["Compétence 1", "Compétence 2", "..."],
  "level": "Collège/Lycée/Supérieur/Tous niveaux",
  "suggestions": [
    {
      "title": "Titre du cours",
      "description": "Description détaillée du cours (2-3 phrases)",
      "subject": "Matière principale",
      "level": "Niveau cible",
      "price": 18
    }
  ]
}

Règles importantes :
- Les compétences doivent être des matières enseignables (Mathématiques, Physique, Informatique, Langues, etc.)
- Le prix doit être entre 15 CCT et 30 CCT selon la complexité (langues: 16-20 CCT, sciences: 18-25 CCT, informatique: 25-30 CCT)
- Les descriptions doivent être engageantes et professionnelles
- Le niveau doit correspondre aux capacités du tuteur
- Ne génère QUE des cours que la personne est réellement capable d'enseigner selon son CV`;

        const chatResponse = await ensureClient().chat.complete({
            model: 'mistral-small-latest',
            messages: [
                {
                    role: 'user',
                    content: prompt
                }
            ],
            temperature: 0.7,
            maxTokens: 2000
        });

        const responseText = chatResponse.choices[0].message.content.trim();
        console.log('📝 Réponse de Mistral:', responseText.substring(0, 200) + '...');

        // Parser la réponse JSON
        let result;
        try {
            // Nettoyer la réponse si elle contient des markdown
            let cleanJson = responseText;
            if (responseText.includes('```json')) {
                cleanJson = responseText.replace(/```json\n?/g, '').replace(/```\n?/g, '');
            }
            
            result = JSON.parse(cleanJson);
        } catch (parseError) {
            console.error('❌ Erreur de parsing JSON:', parseError);
            console.log('Réponse brute:', responseText);
            throw new Error('Impossible de parser la réponse de Mistral AI');
        }

        // Ajouter le nom du tuteur à chaque suggestion
        if (result.suggestions && result.tutorName) {
            result.suggestions = result.suggestions.map(suggestion => ({
                ...suggestion,
                tutor_name: result.tutorName
            }));
        }

        console.log(`✅ Analyse terminée : ${result.skills.length} compétences, ${result.suggestions.length} suggestions`);

        return {
            success: true,
            ...result
        };

    } catch (error) {
        console.error('❌ Erreur Mistral AI:', error);
        throw error;
    }
}

// Corrige l'orthographe/grammaire du titre et de la description d'une annonce
export async function correctListingText({ title, description }) {
    try {
        const prompt = `Tu es un correcteur orthographique et grammatical professionnel pour un site de cours particuliers.
Corrige uniquement l'orthographe, la grammaire, la ponctuation et les évidentes fautes de frappe du titre et de la description ci-dessous.
Ne change PAS le sens, le ton, la langue ni les informations (prix, niveau, matière...). Ne reformule pas ce qui est déjà correct.

Titre :
---
${title || ''}
---

Description :
---
${description || ''}
---

Réponds UNIQUEMENT avec un objet JSON valide (sans markdown, sans \`\`\`json) au format exact :
{
  "title": "titre corrigé",
  "description": "description corrigée",
  "hasChanges": true
}
"hasChanges" doit valoir false si aucune correction n'était nécessaire.`;

        const chatResponse = await ensureClient().chat.complete({
            model: 'mistral-small-latest',
            messages: [{ role: 'user', content: prompt }],
            temperature: 0.2,
            maxTokens: 1000
        });

        const responseText = chatResponse.choices[0].message.content.trim();
        let cleanJson = responseText;
        if (cleanJson.includes('```')) {
            cleanJson = cleanJson.replace(/```json\n?/g, '').replace(/```\n?/g, '');
        }

        const result = JSON.parse(cleanJson);
        return {
            success: true,
            title: result.title ?? title,
            description: result.description ?? description,
            hasChanges: !!result.hasChanges,
        };
    } catch (error) {
        console.error('❌ Erreur correction IA:', error);
        throw error;
    }
}

// Langues (hors français) dans lesquelles chaque annonce est automatiquement traduite
export const LISTING_TRANSLATION_LANGUAGES = {
    en: 'anglais',
    es: 'espagnol',
    pt: 'portugais',
    de: 'allemand',
    ja: 'japonais',
    zh: 'chinois (mandarin, caractères simplifiés)',
};

// Traduit le titre et la description d'une annonce (déjà en français) dans toutes les
// langues supportées par le site, en une seule requête.
export async function translateListingText({ title, description }) {
    try {
        const languageList = Object.entries(LISTING_TRANSLATION_LANGUAGES)
            .map(([code, name]) => `"${code}" (${name})`)
            .join(', ');

        const prompt = `Tu es un traducteur professionnel spécialisé dans les annonces de cours particuliers.
Traduis fidèlement le titre et la description ci-dessous (rédigés en français) dans chacune des langues suivantes : ${languageList}.
Garde un ton professionnel et engageant, adapté à une annonce de cours. Ne traduis pas les noms propres ni les prix.

Titre :
---
${title || ''}
---

Description :
---
${description || ''}
---

Réponds UNIQUEMENT avec un objet JSON valide (sans markdown, sans \`\`\`json) au format exact, une entrée par langue :
{
  "en": { "title": "...", "description": "..." },
  "es": { "title": "...", "description": "..." },
  "pt": { "title": "...", "description": "..." },
  "de": { "title": "...", "description": "..." },
  "ja": { "title": "...", "description": "..." },
  "zh": { "title": "...", "description": "..." }
}`;

        const chatResponse = await ensureClient().chat.complete({
            model: 'mistral-small-latest',
            messages: [{ role: 'user', content: prompt }],
            temperature: 0.2,
            maxTokens: 3000,
        });

        const responseText = chatResponse.choices[0].message.content.trim();
        let cleanJson = responseText;
        if (cleanJson.includes('```')) {
            cleanJson = cleanJson.replace(/```json\n?/g, '').replace(/```\n?/g, '');
        }

        const result = JSON.parse(cleanJson);
        const translations = {};
        for (const code of Object.keys(LISTING_TRANSLATION_LANGUAGES)) {
            translations[code] = {
                title: result[code]?.title || title,
                description: result[code]?.description || description,
            };
        }
        return translations;
    } catch (error) {
        console.error('❌ Erreur traduction annonce:', error);
        throw error;
    }
}
