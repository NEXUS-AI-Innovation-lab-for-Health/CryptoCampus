import pdfParse from 'pdf-parse';
import { analyzeCVWithMistral } from './mistral-service.js';

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


// Fonction principale d'analyse avec Mistral AI
export async function analyzeCVAndGenerateSuggestions(pdfBuffer) {
    try {
        console.log('🚀 Début de l\'analyse du CV avec Mistral AI...');
        
        // 1. Extraire le texte du PDF
        const text = await extractTextFromPDF(pdfBuffer);
        
        console.log('📝 Texte extrait (premiers 500 caractères):', text.substring(0, 500));
        
        // 2. Analyser avec Mistral AI
        const result = await analyzeCVWithMistral(text);
        
        console.log('✨ Analyse Mistral terminée avec succès');
        
        return result;
        
    } catch (error) {
        console.error('❌ Erreur analyse CV:', error);
        throw error;
    }
}

