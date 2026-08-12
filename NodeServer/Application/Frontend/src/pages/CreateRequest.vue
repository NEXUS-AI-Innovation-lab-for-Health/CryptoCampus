<template>
  <div class="page-container">
    <div class="container">
      <!-- Main Card -->
      <div class="card">
        <h1>📄 Créer une annonce depuis votre CV</h1>
        <p class="subtitle">Uploadez votre CV et nous vous suggérons automatiquement des cours à proposer</p>

        <!-- Info Box -->
        <div class="info-box">
          <strong>ℹ️ Comment ça marche ?</strong><br>
          1. Uploadez votre CV (PDF uniquement)<br>
          2. Nous analysons vos compétences<br>
          3. Nous vous suggérons des cours adaptés<br>
          4. Validez les annonces qui vous intéressent
        </div>

        <!-- Error Message -->
        <div v-if="errorMessage" class="error-message">
          ❌ {{ errorMessage }}
        </div>

        <!-- Suggestion de liaison LinkedIn (tuteurs sans compte lié) -->
        <div v-if="showLinkedInBanner" class="info-box linkedin-banner">
          <span>💡 Astuce : liez votre compte LinkedIn pour renforcer la crédibilité de vos annonces.</span>
          <button type="button" class="btn btn-secondary" @click="linkLinkedIn">🔗 Lier LinkedIn</button>
        </div>

        <!-- Upload Section -->
        <div 
          v-if="!isAnalyzing && !showResults && !showSuccess" 
          class="upload-section"
          :class="{ dragover: isDragging }"
          @dragover.prevent="isDragging = true"
          @dragleave="isDragging = false"
          @drop.prevent="handleDrop"
        >
          <div class="upload-icon">📎</div>
          <h3>Glissez votre CV ici ou cliquez pour sélectionner</h3>
          <p class="upload-hint">Format accepté : PDF uniquement</p>
          <div class="file-input-wrapper">
            <label for="cvFile" class="btn btn-primary">
              📁 Sélectionner un fichier
            </label>
            <input 
              type="file" 
              id="cvFile" 
              accept=".pdf"
              @change="handleFileSelect"
              ref="fileInput"
            />
          </div>
          
          <!-- File Info -->
          <div v-if="selectedFile" class="file-info">
            <div class="file-name">
              📄 {{ selectedFile.name }} ({{ formatFileSize(selectedFile.size) }})
            </div>
            <button class="btn btn-danger" @click="clearFile">
              ❌ Supprimer
            </button>
          </div>
        </div>

        <!-- Loading Section -->
        <div v-if="isAnalyzing" class="loading-section">
          <div class="spinner"></div>
          <h3>Analyse de votre CV en cours...</h3>
          <p class="loading-text">Extraction des compétences et génération des suggestions</p>
        </div>

        <!-- Skills Section -->
        <div v-if="showResults && extractedSkills.length > 0" class="skills-section">
          <h2>🎯 Compétences détectées</h2>
          <div class="skills-list">
            <span v-for="(skill, index) in extractedSkills" :key="index" class="skill-badge">
              {{ skill }}
            </span>
          </div>
        </div>

        <!-- Suggestions Section -->
        <div v-if="showResults && suggestions.length > 0" class="suggestions-section">
          <h2>💡 Cours suggérés</h2>
          <p class="suggestions-subtitle">Sélectionnez les annonces que vous souhaitez publier</p>
          
          <div class="suggestions-list">
            <div 
              v-for="(suggestion, index) in suggestions" 
              :key="index" 
              class="suggestion-card"
            >
              <div class="suggestion-header">
                <input class="edit-input" v-model="suggestion.title" />
                <div class="suggestion-price">
                  <input class="price-input" v-model.number="suggestion.price" type="number" min="0" step="0.5" /> CCT/h
                </div>
              </div>
              <textarea class="edit-input description-input" v-model="suggestion.description" rows="3"></textarea>
              <div class="suggestion-meta">
                <span class="meta-badge badge-subject">📚 <input class="meta-input" v-model="suggestion.subject" /></span>
                <span class="meta-badge badge-level">🎯 <input class="meta-input" v-model="suggestion.level" /></span>
              </div>
              <div class="checkbox-wrapper">
                <input 
                  type="checkbox" 
                  :id="`suggestion-${index}`"
                  v-model="suggestion.selected"
                />
                <label :for="`suggestion-${index}`">Publier cette annonce</label>
              </div>
            </div>
          </div>

          <!-- Actions -->
          <div class="actions">
            <button 
              class="btn btn-success" 
              @click="publishSelectedListings"
              :disabled="isPublishing || selectedCount === 0"
            >
              {{ isPublishing ? '⏳ Publication en cours...' : `✅ Publier ${selectedCount} annonce${selectedCount > 1 ? 's' : ''} sélectionnée${selectedCount > 1 ? 's' : ''}` }}
            </button>
            <button class="btn btn-danger" @click="resetForm">
              🔄 Recommencer
            </button>
          </div>
        </div>

        <!-- Success Section -->
        <div v-if="showSuccess" class="success-section">
          <div class="success-icon">✅</div>
          <h2>Annonces publiées avec succès !</h2>
          <p class="success-text">Vos annonces sont maintenant visibles sur la plateforme</p>
          <div class="success-actions">
            <router-link to="/requetes" class="btn btn-primary">
              📋 Voir mes annonces
            </router-link>
            <button class="btn btn-secondary" @click="resetForm">
              ➕ Créer d'autres annonces
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'

const router = useRouter()

// State
const selectedFile = ref(null)
const isDragging = ref(false)
const isAnalyzing = ref(false)
const isPublishing = ref(false)
const showResults = ref(false)
const showSuccess = ref(false)
const errorMessage = ref('')
const extractedSkills = ref([])
const suggestions = ref([])
const fileInput = ref(null)
const showLinkedInBanner = ref(false)

// Suggère de lier LinkedIn uniquement aux tuteurs qui ne l'ont pas encore fait
const checkLinkedInStatus = async () => {
  try {
    const response = await fetch('/api/profile', { credentials: 'include' })
    if (!response.ok) return
    const data = await response.json()
    showLinkedInBanner.value = data.role === 'TUTOR' && !data.linkedin_email
  } catch (error) {
    console.error('Erreur vérification LinkedIn:', error)
  }
}

const linkLinkedIn = () => {
  window.location.href = '/api/auth/linkedin/link?returnTo=/create_request'
}

onMounted(checkLinkedInStatus)

// Computed
const selectedCount = computed(() => {
  return suggestions.value.filter(s => s.selected).length
})

// Methods
const formatFileSize = (bytes) => {
  return (bytes / 1024).toFixed(2) + ' KB'
}

const showError = (message) => {
  errorMessage.value = message
  setTimeout(() => {
    errorMessage.value = ''
  }, 5000)
}

const handleDrop = (e) => {
  isDragging.value = false
  const file = e.dataTransfer.files[0]
  if (file && file.type === 'application/pdf') {
    selectedFile.value = file
    analyzeCV(file)
  } else {
    showError('Veuillez sélectionner un fichier PDF')
  }
}

const handleFileSelect = (e) => {
  const file = e.target.files[0]
  if (file) {
    selectedFile.value = file
    analyzeCV(file)
  }
}

const clearFile = () => {
  selectedFile.value = null
  if (fileInput.value) {
    fileInput.value.value = ''
  }
  showResults.value = false
  extractedSkills.value = []
  suggestions.value = []
}

const analyzeCV = async (file) => {
  try {
    isAnalyzing.value = true
    errorMessage.value = ''

    const formData = new FormData()
    formData.append('cv', file)

    const response = await fetch('/api/analyze-cv', {
      method: 'POST',
      body: formData,
      credentials: 'include'
    })

    if (!response.ok) {
      throw new Error(`Erreur ${response.status}: ${response.statusText}`)
    }

    const data = await response.json()
    
    extractedSkills.value = data.skills || []
    suggestions.value = (data.suggestions || []).map(s => ({
      ...s,
      selected: true
    }))

    isAnalyzing.value = false
    showResults.value = true

  } catch (error) {
    console.error('Erreur:', error)
    showError(`Impossible d'analyser le CV: ${error.message}`)
    isAnalyzing.value = false
    clearFile()
  }
}

const publishSelectedListings = async () => {
  const selectedSuggestions = suggestions.value.filter(s => s.selected)

  if (selectedSuggestions.length === 0) {
    showError('Veuillez sélectionner au moins une annonce à publier')
    return
  }

  try {
    isPublishing.value = true

    // Publier chaque annonce
    for (const suggestion of selectedSuggestions) {
      const { selected, ...listingData } = suggestion
      await fetch('/api/listings', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify(listingData),
        credentials: 'include'
      })
    }

    isPublishing.value = false
    showResults.value = false
    showSuccess.value = true

  } catch (error) {
    console.error('Erreur:', error)
    showError(`Erreur lors de la publication: ${error.message}`)
    isPublishing.value = false
  }
}

const resetForm = () => {
  selectedFile.value = null
  if (fileInput.value) {
    fileInput.value.value = ''
  }
  isDragging.value = false
  isAnalyzing.value = false
  isPublishing.value = false
  showResults.value = false
  showSuccess.value = false
  errorMessage.value = ''
  extractedSkills.value = []
  suggestions.value = []
}
</script>

<style scoped>
* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

.page-container {
  min-height: 100vh;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  padding: 2rem;
}

.container {
  max-width: 900px;
  margin: 0 auto;
}

/* Main Card */
.card {
  background: white;
  border-radius: 15px;
  padding: 2.5rem;
  box-shadow: 0 10px 40px rgba(0, 0, 0, 0.2);
}

h1 {
  color: #667eea;
  margin-bottom: 0.625rem;
  font-size: 2.2em;
  font-weight: 700;
}

.subtitle {
  color: #666;
  margin-bottom: 1.875rem;
  font-size: 1.1em;
}

/* Info Box */
.info-box {
  background: #fff3cd;
  border: 1px solid #ffc107;
  border-radius: 10px;
  padding: 1rem;
  margin-bottom: 1.25rem;
  line-height: 1.8;
}

.info-box strong {
  color: #856404;
}

.linkedin-banner {
  background: #e8f0fe;
  border-color: #0a66c2;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 1rem;
  flex-wrap: wrap;
}

.linkedin-banner .btn-secondary {
  white-space: nowrap;
}

/* Error Message */
.error-message {
  background: #ffebee;
  border: 2px solid #f44336;
  border-radius: 12px;
  padding: 1.25rem;
  margin-bottom: 1.25rem;
  color: #c62828;
  animation: slideIn 0.3s ease-out;
}

@keyframes slideIn {
  from {
    opacity: 0;
    transform: translateY(-10px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

/* Upload Section */
.upload-section {
  border: 3px dashed #667eea;
  border-radius: 15px;
  padding: 2.5rem;
  text-align: center;
  transition: all 0.3s;
  background: #f8f9ff;
  margin-bottom: 1.875rem;
}

.upload-section:hover {
  border-color: #764ba2;
  background: #f0f2ff;
}

.upload-section.dragover {
  background: #e8ebff;
  border-color: #764ba2;
  transform: scale(1.02);
}

.upload-icon {
  font-size: 4em;
  margin-bottom: 1.25rem;
}

.upload-section h3 {
  color: #333;
  margin-bottom: 0.625rem;
  font-size: 1.3em;
}

.upload-hint {
  color: #666;
  margin: 1rem 0;
}

.file-input-wrapper {
  position: relative;
  display: inline-block;
}

input[type="file"] {
  display: none;
}

/* Buttons */
.btn {
  padding: 1rem 2.25rem;
  font-size: 1rem;
  font-weight: 600;
  border: none;
  border-radius: 10px;
  cursor: pointer;
  transition: all 0.3s;
  display: inline-flex;
  align-items: center;
  gap: 0.625rem;
  text-decoration: none;
  font-family: inherit;
}

.btn-primary {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
}

.btn-primary:hover:not(:disabled) {
  transform: translateY(-2px);
  box-shadow: 0 5px 20px rgba(102, 126, 234, 0.4);
}

.btn-success {
  background: #4caf50;
  color: white;
}

.btn-success:hover:not(:disabled) {
  background: #45a049;
  transform: translateY(-2px);
}

.btn-danger {
  background: #f44336;
  color: white;
}

.btn-danger:hover {
  background: #da190b;
}

.btn-secondary {
  background: #f5f5f5;
  color: #333;
}

.btn-secondary:hover {
  background: #e0e0e0;
}

.btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

/* File Info */
.file-info {
  margin-top: 1.25rem;
  padding: 1rem;
  background: #e8f5e9;
  border-radius: 10px;
}

.file-name {
  font-weight: 600;
  color: #2e7d32;
  font-size: 1.1em;
  margin-bottom: 0.625rem;
}

/* Loading Section */
.loading-section {
  text-align: center;
  padding: 3rem 1.875rem;
}

.spinner {
  border: 4px solid #f3f3f3;
  border-top: 4px solid #667eea;
  border-radius: 50%;
  width: 50px;
  height: 50px;
  animation: spin 1s linear infinite;
  margin: 0 auto 1.25rem;
}

@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}

.loading-section h3 {
  color: #333;
  margin-bottom: 0.625rem;
  font-size: 1.3em;
}

.loading-text {
  color: #666;
  margin-top: 0.625rem;
}

/* Skills Section */
.skills-section {
  margin-bottom: 1.875rem;
}

.skills-section h2 {
  color: #333;
  font-size: 1.5em;
  margin-bottom: 1.25rem;
  font-weight: 700;
}

.skills-list {
  display: flex;
  flex-wrap: wrap;
  gap: 0.625rem;
}

.skill-badge {
  background: #e3f2fd;
  color: #1976d2;
  padding: 0.625rem 1.25rem;
  border-radius: 20px;
  font-weight: 600;
  font-size: 0.875rem;
}

/* Suggestions Section */
.suggestions-section {
  margin-top: 1.875rem;
}

.suggestions-section h2 {
  color: #333;
  font-size: 1.5em;
  margin-bottom: 0.625rem;
  font-weight: 700;
}

.suggestions-subtitle {
  color: #666;
  margin-bottom: 1.25rem;
}

.suggestions-list {
  margin-bottom: 1.875rem;
}

.suggestion-card {
  background: #f8f9ff;
  border: 2px solid #e0e7ff;
  border-radius: 12px;
  padding: 1.25rem;
  margin-bottom: 1rem;
  transition: all 0.3s;
}

.suggestion-card:hover {
  border-color: #667eea;
  transform: translateX(5px);
}

.suggestion-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 1rem;
  gap: 1rem;
}

.suggestion-title {
  font-size: 1.2em;
  font-weight: 700;
  color: #333;
  flex: 1;
}

.edit-input {
  width: 100%;
  border: 1px solid #cbd5e1;
  border-radius: 8px;
  padding: 0.5rem;
  font-size: 1rem;
}

.description-input {
  margin-bottom: 1rem;
}

.price-input {
  width: 80px;
  border: 1px solid #ffcc80;
  border-radius: 6px;
  padding: 0.35rem;
  margin-right: 0.35rem;
}

.meta-input {
  border: none;
  background: transparent;
  min-width: 80px;
  font-weight: 600;
}

.meta-input:focus {
  outline: none;
}

.suggestion-price {
  background: #fff3e0;
  color: #e65100;
  padding: 0.5rem 1rem;
  border-radius: 10px;
  font-weight: 600;
  white-space: nowrap;
}

.suggestion-description {
  color: #666;
  margin-bottom: 1rem;
  line-height: 1.6;
}

.suggestion-meta {
  display: flex;
  gap: 0.625rem;
  flex-wrap: wrap;
  margin-bottom: 1rem;
}

.meta-badge {
  padding: 0.375rem 0.75rem;
  border-radius: 15px;
  font-size: 0.8125rem;
  font-weight: 600;
}

.badge-subject {
  background: #e3f2fd;
  color: #1976d2;
}

.badge-level {
  background: #f3e5f5;
  color: #7b1fa2;
}

.checkbox-wrapper {
  display: flex;
  align-items: center;
  gap: 0.625rem;
  padding-top: 1rem;
  border-top: 1px solid #e0e0e0;
}

.checkbox-wrapper input[type="checkbox"] {
  width: 20px;
  height: 20px;
  cursor: pointer;
}

.checkbox-wrapper label {
  cursor: pointer;
  font-weight: 600;
  color: #667eea;
}

/* Actions */
.actions {
  display: flex;
  gap: 1rem;
  flex-wrap: wrap;
}

/* Success Section */
.success-section {
  text-align: center;
  padding: 2rem;
}

.success-icon {
  font-size: 4em;
  color: #4caf50;
  margin-bottom: 1.25rem;
}

.success-section h2 {
  color: #333;
  font-size: 1.8em;
  margin-bottom: 0.625rem;
  font-weight: 700;
}

.success-text {
  color: #666;
  margin: 1.25rem 0;
  font-size: 1.1em;
}

.success-actions {
  display: flex;
  gap: 1rem;
  justify-content: center;
  flex-wrap: wrap;
  margin-top: 1.875rem;
}

/* Responsive */
@media (max-width: 768px) {
  .page-container {
    padding: 1rem;
  }

  .card {
    padding: 1.5rem;
  }

  h1 {
    font-size: 1.8em;
  }

  .upload-section {
    padding: 1.5rem;
  }

  .suggestion-header {
    flex-direction: column;
  }

  .actions,
  .success-actions {
    flex-direction: column;
  }

  .btn {
    width: 100%;
    justify-content: center;
  }
}

@media (max-width: 480px) {
  h1 {
    font-size: 1.5em;
  }

  .subtitle {
    font-size: 1rem;
  }

  .upload-icon {
    font-size: 3em;
  }
}
</style>
