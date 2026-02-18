import { Mistral } from '@mistralai/mistralai';

const apiKey = 'NF8sYhcEyrwcRzIwrHcqwfPzZmyWXsXh';
const client = new Mistral({ apiKey });

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

        const chatResponse = await client.chat.complete({
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
