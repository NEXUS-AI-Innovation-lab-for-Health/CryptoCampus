<template>
  <div class="page-container">
    <div class="container">
      <header class="page-header">
        <h1>📚 Mes Cours</h1>
        <p class="subtitle">Gérez les annonces que vous avez publiées</p>
      </header>

      <div v-if="isLoading" class="loading-state">
        <div class="spinner"></div>
        Chargement de vos annonces...
      </div>
      
      <div v-else-if="myListings.length === 0" class="empty-state">
        <div class="empty-icon">📭</div>
        <h2>Aucune annonce publiée</h2>
        <p>Créez votre première annonce pour commencer à enseigner.</p>
        <router-link to="/create_request" class="btn btn-primary">
          + Créer ma première annonce
        </router-link>
      </div>

      <div v-else>
        <div class="listings-stats">
          <div class="stat-card">
            <span class="stat-value">{{ myListings.length }}</span>
            <span class="stat-label">Annonce{{ myListings.length > 1 ? 's' : '' }} publiée{{ myListings.length > 1 ? 's' : '' }}</span>
          </div>
        </div>

        <div class="listings-grid">
          <div v-for="listing in myListings" :key="listing.id" class="listing-card">
            <div class="card-header">
              <h3>{{ listing.title }}</h3>
              <span class="price-badge">{{ listing.price }} CCT/h</span>
            </div>
            
            <div class="card-body">
              <p class="description">{{ listing.description }}</p>
              
              <div class="meta-info">
                <span class="tag subject">📚 {{ listing.subject || 'Général' }}</span>
                <span class="tag level">🎯 {{ listing.level || 'Tous niveaux' }}</span>
              </div>
              
              <p class="date-published">
                Publiée le {{ formatDate(listing.created_at) }}
              </p>

              <div class="interest-section">
                <div class="interest-label">👥 Intéressés:</div>
                <div class="interest-content">
                  <span class="interest-count">{{ interestCounts[listing.id] || 0 }} étudiant{{ (interestCounts[listing.id] || 0) !== 1 ? 's' : '' }}</span>
                  <button 
                    v-if="(interestCounts[listing.id] || 0) > 0"
                    class="btn btn-secondary btn-sm" 
                    @click="showInterestedPeople(listing)"
                  >
                    Voir les emails
                  </button>
                </div>
              </div>
            </div>
            
            <div class="card-footer">
              <button class="btn btn-primary btn-sm" @click="editListing(listing)">✏️ Modifier</button>
              <button class="btn btn-danger btn-sm" @click="deleteListing(listing.id)">🗑️ Supprimer</button>
            </div>
          </div>
        </div>
      </div>

      <!-- Edit Modal -->
      <div v-if="editingListing" class="modal-overlay" @click.self="editingListing = null">
        <div class="modal-card">
          <div class="modal-header">
            <h3>Modifier l'annonce</h3>
            <button @click="editingListing = null" class="close-btn">×</button>
          </div>
          <div class="modal-body">
            <div class="form-group">
              <label>Titre</label>
              <input v-model="editForm.title" type="text" placeholder="Titre de l'annonce" />
            </div>
            <div class="form-group">
              <label>Description</label>
              <textarea v-model="editForm.description" rows="4" placeholder="Décrivez votre cours..."></textarea>
            </div>
            <div class="form-row">
              <div class="form-group">
                <label>Matière</label>
                <input v-model="editForm.subject" type="text" placeholder="Ex: Mathématiques" />
              </div>
              <div class="form-group">
                <label>Niveau</label>
                <input v-model="editForm.level" type="text" placeholder="Ex: Bac+2" />
              </div>
            </div>
            <div class="form-group">
              <label>Prix (CCT/h)</label>
              <input v-model.number="editForm.price" type="number" min="0" step="0.5" placeholder="50" />
            </div>

            <div class="modal-footer">
              <button class="btn btn-secondary" @click="editingListing = null">Annuler</button>
              <button class="btn btn-primary" @click="saveListingChanges">💾 Enregistrer</button>
            </div>
          </div>
        </div>
      </div>

      <!-- Interest Modal -->
      <div v-if="interestModal.open" class="modal-overlay" @click.self="interestModal.open = false">
        <div class="modal-card">
          <div class="modal-header">
            <h3>Étudiants intéressés ({{ filteredInterestedPeople.length }})</h3>
            <button @click="interestModal.open = false" class="close-btn">×</button>
          </div>
          <div class="modal-body">
            <div v-if="interestModal.people.length > 0" class="search-container">
              <input 
                v-model="interestSearchQuery"
                type="text" 
                class="search-input"
                placeholder="Rechercher par nom ou email..."
                @input="filterInterestedPeople"
              />
              <span class="search-results">{{ filteredInterestedPeople.length }} résultat{{ filteredInterestedPeople.length !== 1 ? 's' : '' }}</span>
            </div>

            <p v-if="interestModal.people.length === 0" class="no-items">
              Aucun étudiant intéressé pour le moment.
            </p>
            <ul v-else-if="filteredInterestedPeople.length > 0" class="people-list">
              <li v-for="person in filteredInterestedPeople" :key="person.email" class="person-item">
                <div class="person-info">
                  <div class="person-name">👤 {{ person.fullName }}</div>
                  <a :href="'mailto:' + person.email" class="person-email">{{ person.email }}</a>
                </div>
                <button 
                  class="btn-copy" 
                  @click="copyToClipboard(person.email)"
                  title="Copier l'email"
                >
                  📋
                </button>
              </li>
            </ul>
            <p v-else class="no-results">
              Aucun résultat correspondant à "{{ interestSearchQuery }}"
            </p>

            <div class="modal-footer">
              <button class="btn btn-secondary" @click="interestModal.open = false">Fermer</button>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'

const myListings = ref([])
const isLoading = ref(true)
const interestCounts = ref({})
const editingListing = ref(null)
const editForm = ref({
  title: '',
  description: '',
  subject: '',
  level: '',
  price: 0,
})
const interestModal = ref({
  open: false,
  people: [],
})
const interestSearchQuery = ref('')
const filteredInterestedPeople = ref([])

const fetchMyListings = async () => {
  try {
    isLoading.value = true
    const res = await fetch('/api/listings/mine', { credentials: 'include' })
    if (res.ok) {
      const data = await res.json()
      myListings.value = data.listings || []
      await loadInterestsCount()
    }
  } catch (err) {
    console.error('Erreur récupération annonces:', err)
  } finally {
    isLoading.value = false
  }
}

const loadInterestsCount = async () => {
  const entries = {}
  for (const listing of myListings.value) {
    try {
      const response = await fetch(`/api/listings/${listing.id}/interests`, {
        credentials: 'include',
      })
      if (response.ok) {
        const data = await response.json()
        entries[listing.id] = data.count || 0
      }
    } catch (error) {
      console.error('Erreur interests count:', error)
    }
  }
  interestCounts.value = entries
}

const editListing = (listing) => {
  editingListing.value = listing
  editForm.value = {
    title: listing.title || '',
    description: listing.description || '',
    subject: listing.subject || '',
    level: listing.level || '',
    price: listing.price || 0,
  }
}

const saveListingChanges = async () => {
  if (!editingListing.value) return
  try {
    const response = await fetch(`/api/listings/${editingListing.value.id}`, {
      method: 'PUT',
      headers: {
        'Content-Type': 'application/json',
      },
      credentials: 'include',
      body: JSON.stringify(editForm.value),
    })

    if (!response.ok) {
      const error = await response.json()
      throw new Error(error.error || 'Erreur mise à jour')
    }

    const data = await response.json()
    myListings.value = myListings.value.map((listing) =>
      listing.id === editingListing.value.id ? data.listing : listing
    )
    editingListing.value = null
  } catch (error) {
    alert(error.message)
  }
}

const showInterestedPeople = async (listing) => {
  try {
    const response = await fetch(`/api/listings/${listing.id}/interests`, {
      credentials: 'include',
    })
    if (!response.ok) {
      throw new Error('Erreur chargement des intéressés')
    }
    const data = await response.json()
    interestModal.value = {
      open: true,
      people: data.people || [],
    }
    filteredInterestedPeople.value = data.people || []
    interestSearchQuery.value = ''
    interestCounts.value[listing.id] = data.count || 0
  } catch (error) {
    alert(error.message)
  }
}

const filterInterestedPeople = () => {
  const query = interestSearchQuery.value.toLowerCase().trim()
  if (!query) {
    filteredInterestedPeople.value = interestModal.value.people
    return
  }
  
  filteredInterestedPeople.value = interestModal.value.people.filter((person) => {
    const fullName = (person.fullName || '').toLowerCase()
    const email = (person.email || '').toLowerCase()
    return fullName.includes(query) || email.includes(query)
  })
}

const copyToClipboard = (email) => {
  navigator.clipboard.writeText(email).then(() => {
    alert(`Email copié: ${email}`)
  }).catch(() => {
    alert('Impossible de copier l\'email')
  })
}

const deleteListing = async (id) => {
  if (!confirm('Voulez-vous vraiment supprimer cette annonce ?')) return;

  try {
    const res = await fetch('/api/listings/' + id, {
      method: 'DELETE',
      credentials: 'include'
    })
    if (res.ok) {
      myListings.value = myListings.value.filter(l => l.id !== id)
    } else {
      alert('Erreur lors de la suppression')
    }
  } catch (err) {
    console.error('Erreur suppression:', err)
  }
}

const formatDate = (dateStr) => {
  if (!dateStr) return 'Inconnue'
  return new Date(dateStr).toLocaleDateString('fr-FR', {
    day: 'numeric', month: 'long', year: 'numeric'
  })
}

onMounted(() => {
  fetchMyListings()
})
</script>

<style scoped>
.page-container {
  padding: 2.5rem 1.5rem;
  background: linear-gradient(135deg, #f8f9fa 0%, #f0f4ff 100%);
  min-height: calc(100vh - 60px);
}

.container {
  max-width: 1200px;
  margin: 0 auto;
}

.page-header {
  text-align: center;
  margin-bottom: 2.5rem;
}

.page-header h1 {
  font-size: 2.8em;
  font-weight: 700;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  background-clip: text;
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  margin-bottom: 0.5rem;
}

.subtitle {
  color: #64748b;
  font-size: 1.1em;
  font-weight: 500;
}

.loading-state {
  background: white;
  border-radius: 15px;
  padding: 3rem;
  text-align: center;
  color: #64748b;
  font-size: 1.1em;
  box-shadow: 0 5px 15px rgba(0, 0, 0, 0.08);
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 1rem;
}

.spinner {
  width: 40px;
  height: 40px;
  border: 4px solid #e2e8f0;
  border-top-color: #667eea;
  border-radius: 50%;
  animation: spin 0.8s linear infinite;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}

.empty-state {
  text-align: center;
  background: white;
  border-radius: 15px;
  padding: 4rem 2rem;
  box-shadow: 0 5px 15px rgba(0, 0, 0, 0.08);
}

.empty-icon {
  font-size: 4em;
  margin-bottom: 1rem;
}

.empty-state h2 {
  color: #1e293b;
  margin-bottom: 0.5rem;
  font-size: 1.6em;
}

.empty-state p {
  color: #64748b;
  margin-bottom: 1.5rem;
}

.listings-stats {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 1rem;
  margin-bottom: 2rem;
}

.stat-card {
  background: white;
  border-radius: 12px;
  padding: 1.5rem;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.08);
  text-align: center;
  border-left: 4px solid #667eea;
}

.stat-value {
  display: block;
  font-size: 2.2em;
  font-weight: 700;
  color: #667eea;
  margin-bottom: 0.5rem;
}

.stat-label {
  color: #64748b;
  font-size: 0.95em;
}

.listings-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(320px, 1fr));
  gap: 1.5rem;
}

.listing-card {
  background: white;
  border-radius: 15px;
  overflow: hidden;
  box-shadow: 0 5px 15px rgba(0, 0, 0, 0.08);
  transition: all 0.3s ease;
  display: flex;
  flex-direction: column;
}

.listing-card:hover {
  transform: translateY(-8px);
  box-shadow: 0 15px 35px rgba(102, 126, 234, 0.15);
}

.card-header {
  background: linear-gradient(135deg, #f0f4ff 0%, #faf8ff 100%);
  padding: 1.25rem;
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  gap: 1rem;
  border-bottom: 2px solid #e2e8f0;
}

.card-header h3 {
  margin: 0;
  font-size: 1.3em;
  color: #1e293b;
  flex: 1;
  line-height: 1.3;
}

.price-badge {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  padding: 0.5rem 1rem;
  border-radius: 20px;
  font-weight: 700;
  font-size: 1em;
  white-space: nowrap;
  box-shadow: 0 4px 12px rgba(102, 126, 234, 0.2);
}

.card-body {
  padding: 1.25rem;
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.description {
  color: #475569;
  line-height: 1.6;
  margin: 0;
  flex: 1;
}

.meta-info {
  display: flex;
  gap: 0.75rem;
  flex-wrap: wrap;
}

.tag {
  background: #f0f4ff;
  color: #667eea;
  padding: 0.4rem 0.8rem;
  border-radius: 8px;
  font-size: 0.9em;
  font-weight: 500;
}

.tag.subject {
  background: #e0e7ff;
  border-left: 3px solid #667eea;
  padding-left: 0.5rem;
}

.tag.level {
  background: #f5f3ff;
  border-left: 3px solid #a78bfa;
  padding-left: 0.5rem;
}

.date-published {
  color: #94a3b8;
  font-size: 0.95em;
  margin: 0;
  padding: 0.75rem 0;
  border-top: 1px solid #e2e8f0;
}

.interest-section {
  background: #f8fafc;
  padding: 1rem;
  border-radius: 10px;
  border-left: 3px solid #f59e0b;
}

.interest-label {
  font-weight: 600;
  color: #1e293b;
  margin-bottom: 0.5rem;
  font-size: 0.95em;
}

.interest-content {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 0.75rem;
}

.interest-count {
  font-size: 1.2em;
  font-weight: 700;
  color: #f59e0b;
}

.card-footer {
  display: flex;
  gap: 0.75rem;
  padding: 1rem 1.25rem;
  background: #f8fafc;
  border-top: 1px solid #e2e8f0;
}

.btn {
  padding: 0.6rem 1rem;
  border-radius: 8px;
  font-weight: 600;
  border: none;
  cursor: pointer;
  transition: all 0.3s ease;
  font-size: 0.95em;
  text-decoration: none;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 0.4rem;
}

.btn-primary {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  flex: 1;
}

.btn-primary:hover {
  transform: translateY(-2px);
  box-shadow: 0 8px 16px rgba(102, 126, 234, 0.3);
}

.btn-secondary {
  background: #e2e8f0;
  color: #475569;
  flex: 1;
}

.btn-secondary:hover {
  background: #cbd5e1;
}

.btn-danger {
  background: #fecaca;
  color: #991b1b;
  flex: 1;
}

.btn-danger:hover {
  background: #fca5a5;
}

.btn-sm {
  padding: 0.5rem 0.8rem;
  font-size: 0.9em;
}

/* Modal Styles */
.modal-overlay {
  position: fixed;
  inset: 0;
  background: rgba(0, 0, 0, 0.5);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
  padding: 1rem;
}

.modal-card {
  background: white;
  border-radius: 15px;
  width: 100%;
  max-width: 520px;
  box-shadow: 0 20px 60px rgba(0, 0, 0, 0.2);
  overflow: hidden;
}

.modal-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1.5rem;
  background: linear-gradient(135deg, #f0f4ff 0%, #faf8ff 100%);
  border-bottom: 2px solid #e2e8f0;
}

.modal-header h3 {
  margin: 0;
  font-size: 1.3em;
  color: #1e293b;
}

.close-btn {
  background: none;
  border: none;
  font-size: 1.8em;
  cursor: pointer;
  color: #94a3b8;
  line-height: 1;
  transition: color 0.2s;
}

.close-btn:hover {
  color: #475569;
}

.modal-body {
  padding: 1.5rem;
  max-height: 60vh;
  overflow-y: auto;
}

.form-group {
  margin-bottom: 1rem;
}

.form-group label {
  display: block;
  font-weight: 600;
  color: #1e293b;
  margin-bottom: 0.5rem;
  font-size: 0.95em;
}

.form-group input,
.form-group textarea {
  width: 100%;
  padding: 0.75rem;
  border: 2px solid #e2e8f0;
  border-radius: 8px;
  font-size: 0.95em;
  font-family: inherit;
  transition: border-color 0.2s;
  box-sizing: border-box;
}

.form-group input:focus,
.form-group textarea:focus {
  outline: none;
  border-color: #667eea;
  box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.1);
}

.form-row {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 1rem;
}

.no-items {
  text-align: center;
  color: #94a3b8;
  padding: 2rem;
  margin: 0;
}

.no-results {
  text-align: center;
  color: #94a3b8;
  padding: 1.5rem 0;
  margin: 0;
  font-size: 0.95em;
}

.search-container {
  margin-bottom: 1.5rem;
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
}

.search-input {
  width: 100%;
  padding: 0.75rem 1rem;
  border: 2px solid #e2e8f0;
  border-radius: 8px;
  font-size: 0.95em;
  font-family: inherit;
  transition: border-color 0.2s;
  box-sizing: border-box;
}

.search-input:focus {
  outline: none;
  border-color: #667eea;
  box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.1);
}

.search-results {
  font-size: 0.9em;
  color: #64748b;
  font-weight: 500;
}

.people-list {
  list-style: none;
  padding: 0;
  margin: 0;
}

.person-item {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 0.75rem;
  padding: 1rem;
  background: #f8fafc;
  border-radius: 8px;
  margin-bottom: 0.75rem;
  border-left: 3px solid #667eea;
  transition: all 0.2s;
}

.person-item:hover {
  background: #f1f5f9;
  box-shadow: 0 2px 8px rgba(102, 126, 234, 0.1);
}

.person-info {
  flex: 1;
  min-width: 0;
}

.person-name {
  font-weight: 600;
  color: #1e293b;
  margin-bottom: 0.25rem;
  font-size: 0.95em;
}

.person-email {
  color: #667eea;
  text-decoration: none;
  font-size: 0.9em;
  word-break: break-all;
  transition: color 0.2s;
}

.person-email:hover {
  color: #764ba2;
  text-decoration: underline;
}

.btn-copy {
  background: white;
  border: 2px solid #e2e8f0;
  color: #667eea;
  padding: 0.5rem 0.75rem;
  border-radius: 6px;
  cursor: pointer;
  font-size: 1rem;
  transition: all 0.2s;
  white-space: nowrap;
  flex-shrink: 0;
}

.btn-copy:hover {
  background: #667eea;
  color: white;
  border-color: #667eea;
}

.modal-footer {
  display: flex;
  gap: 0.75rem;
  padding: 1.5rem;
  background: #f8fafc;
  border-top: 1px solid #e2e8f0;
  justify-content: flex-end;
}

.modal-footer .btn {
  margin: 0;
}

/* Responsive */
@media (max-width: 768px) {
  .page-container {
    padding: 1.5rem 1rem;
  }

  .page-header h1 {
    font-size: 2em;
  }

  .listings-grid {
    grid-template-columns: 1fr;
  }

  .card-header {
    flex-direction: column;
  }

  .price-badge {
    align-self: flex-start;
  }

  .form-row {
    grid-template-columns: 1fr;
  }

  .modal-footer {
    flex-direction: column;
  }

  .modal-footer .btn {
    width: 100%;
  }
}

@media (max-width: 480px) {
  .page-header h1 {
    font-size: 1.8em;
  }

  .subtitle {
    font-size: 1em;
  }

  .listings-stats {
    grid-template-columns: 1fr;
  }

  .interest-content {
    flex-direction: column;
    align-items: stretch;
  }

  .card-footer {
    flex-direction: column;
  }

  .btn {
    width: 100%;
  }
}
</style>
