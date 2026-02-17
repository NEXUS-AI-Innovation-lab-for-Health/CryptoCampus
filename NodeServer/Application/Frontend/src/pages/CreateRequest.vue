<template>
  <div class="container">
    <div class="form-card">
      <h2>Créer une nouvelle requête d'aide</h2>
      <p class="subtitle">Décrivez votre besoin et la récompense que vous offrez</p>

      <form @submit.prevent="submitForm" id="createRequestForm">
        <div v-if="error" class="error-message">{{ error }}</div>
        <div v-if="success" class="success-message">{{ success }}</div>

        <div class="form-group">
          <label for="subject">Matière *</label>
          <select v-model="form.subject" id="subject" required>
            <option value="">Sélectionnez une matière</option>
            <option value="math">Mathématiques</option>
            <option value="physics">Physique</option>
            <option value="chemistry">Chimie</option>
            <option value="programming">Programmation</option>
            <option value="french">Français</option>
            <option value="english">Anglais</option>
            <option value="biology">Biologie</option>
            <option value="history">Histoire</option>
            <option value="geography">Géographie</option>
            <option value="economics">Économie</option>
            <option value="other">Autre</option>
          </select>
        </div>

        <div class="form-group">
          <label for="title">Titre de la requête *</label>
          <input
            v-model="form.title"
            type="text"
            id="title"
            placeholder="Ex: Aide pour résoudre des équations du second degré"
            maxlength="100"
            required
          />
          <small class="char-count"><span>{{ form.title.length }}</span>/100 caractères</small>
        </div>

        <div class="form-group">
          <label for="description">Description détaillée *</label>
          <textarea
            v-model="form.description"
            id="description"
            rows="6"
            placeholder="Décrivez en détail votre besoin d'aide..."
            maxlength="500"
            required
          ></textarea>
          <small class="char-count"><span>{{ form.description.length }}</span>/500 caractères</small>
        </div>

        <div class="form-group">
          <label for="urgency">Niveau d'urgence</label>
          <select v-model="form.urgency" id="urgency">
            <option value="low">Faible - J'ai du temps</option>
            <option value="medium">Moyen - Quelques jours</option>
            <option value="high">Élevé - Urgent</option>
          </select>
        </div>

        <div class="form-group">
          <label for="reward">Récompense offerte (en coins) *</label>
          <input
            v-model.number="form.reward"
            type="number"
            id="reward"
            min="10"
            max="200"
            required
          />
          <small>Votre solde actuel: <span id="currentBalance">{{ currentBalance }}</span> coins</small>
          <div v-if="form.reward > currentBalance" class="error-message" style="margin-top: 0.5rem;">
            Solde insuffisant pour cette récompense
          </div>
        </div>

        <div class="form-group">
          <label for="deadline">Date limite (optionnel)</label>
          <input v-model="form.deadline" type="date" id="deadline" />
        </div>

        <div class="form-actions">
          <router-link to="/home" class="btn-secondary">Annuler</router-link>
          <button type="submit" class="btn-primary" :disabled="isLoading || form.reward > currentBalance">
            {{ isLoading ? 'Publication en cours...' : 'Publier la requête' }}
          </button>
        </div>
      </form>
    </div>

    <div class="info-card">
      <h3>💡 Conseils pour une bonne requête</h3>
      <ul>
        <li>Soyez précis dans votre description</li>
        <li>Indiquez le niveau d'études concerné</li>
        <li>Mentionnez les concepts spécifiques</li>
        <li>Proposez une récompense adaptée à la complexité</li>
        <li>Fixez une deadline réaliste</li>
      </ul>
    </div>
  </div>
</template>

<script>
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'

export default {
  name: 'CreateRequest',
  setup() {
    const router = useRouter()
    const isLoading = ref(false)
    const error = ref('')
    const success = ref('')
    const currentBalance = ref(0)

    const form = ref({
      subject: '',
      title: '',
      description: '',
      urgency: 'medium',
      reward: 30,
      deadline: '',
    })

    const loadBalance = async () => {
      try {
        const response = await fetch('/api/balance', {
          credentials: 'include',
        })
        if (response.ok) {
          const data = await response.json()
          currentBalance.value = data.balance || 0
        }
      } catch (error) {
        console.error('Failed to load balance:', error)
      }
    }

    const submitForm = async () => {
      error.value = ''
      success.value = ''

      if (form.value.reward > currentBalance.value) {
        error.value = 'Solde insuffisant pour cette récompense'
        return
      }

      isLoading.value = true

      try {
        const response = await fetch('/api/create-request', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
          },
          body: JSON.stringify(form.value),
          credentials: 'include',
        })

        if (response.ok) {
          success.value = 'Requête créée avec succès!'
          setTimeout(() => {
            router.push('/home')
          }, 1500)
        } else {
          const data = await response.json()
          error.value = data.message || 'Erreur lors de la création de la requête'
        }
      } catch (err) {
        error.value = 'Erreur lors de la création de la requête'
        console.error(err)
      } finally {
        isLoading.value = false
      }
    }

    onMounted(() => {
      loadBalance()
    })

    return {
      form,
      isLoading,
      error,
      success,
      currentBalance,
      submitForm,
    }
  }
}
</script>

<style scoped>
.container {
  max-width: 900px;
  margin: 0 auto;
  padding: 2rem;
  display: grid;
  grid-template-columns: 2fr 1fr;
  gap: 2rem;
}

@media (max-width: 768px) {
  .container {
    grid-template-columns: 1fr;
  }
}

.form-card {
  background: white;
  padding: 2rem;
  border-radius: 8px;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
}

.form-card h2 {
  margin-bottom: 0.5rem;
  color: #2c3e50;
}

.subtitle {
  color: #7f8c8d;
  margin-bottom: 1.5rem;
}

.form-group {
  margin-bottom: 1.5rem;
}

.form-group label {
  display: block;
  margin-bottom: 0.5rem;
  color: #2c3e50;
  font-weight: 500;
}

.form-group input,
.form-group select,
.form-group textarea {
  width: 100%;
  padding: 0.75rem;
  border: 1px solid #bdc3c7;
  border-radius: 4px;
  font-size: 1rem;
  font-family: inherit;
}

.form-group input:focus,
.form-group select:focus,
.form-group textarea:focus {
  outline: none;
  border-color: #667eea;
  box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.1);
}

.char-count {
  display: block;
  margin-top: 0.25rem;
  color: #95a5a6;
  font-size: 0.9rem;
}

.form-actions {
  display: flex;
  gap: 1rem;
  margin-top: 2rem;
}

.btn-primary,
.btn-secondary {
  flex: 1;
  padding: 0.75rem;
  border: none;
  border-radius: 4px;
  font-size: 1rem;
  cursor: pointer;
  text-decoration: none;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: background-color 0.3s;
}

.btn-primary {
  background-color: #667eea;
  color: white;
}

.btn-primary:hover:not(:disabled) {
  background-color: #5568d3;
}

.btn-primary:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.btn-secondary {
  background-color: #ecf0f1;
  color: #2c3e50;
}

.btn-secondary:hover {
  background-color: #bdc3c7;
}

.error-message {
  color: #e74c3c;
  background-color: #fadbd8;
  padding: 1rem;
  border-radius: 4px;
  margin-bottom: 1rem;
}

.success-message {
  color: #27ae60;
  background-color: #d5f4e6;
  padding: 1rem;
  border-radius: 4px;
  margin-bottom: 1rem;
}

.info-card {
  background: white;
  padding: 1.5rem;
  border-radius: 8px;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
  height: fit-content;
}

.info-card h3 {
  margin-bottom: 1rem;
  color: #2c3e50;
}

.info-card ul {
  list-style: none;
}

.info-card li {
  padding: 0.5rem 0;
  color: #7f8c8d;
  padding-left: 1.5rem;
  position: relative;
}

.info-card li:before {
  content: '✓';
  position: absolute;
  left: 0;
  color: #27ae60;
  font-weight: bold;
}
</style>
