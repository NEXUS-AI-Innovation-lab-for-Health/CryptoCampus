<template>
  <div class="page-container">
    <div class="container">
      <header class="page-header">
        <h1>❤️ Cours favoris</h1>
        <p class="subtitle">Retrouvez toutes les annonces que vous avez sauvegardées.</p>
      </header>

      <div v-if="loading" class="loading-state">
        <div class="spinner"></div>
        Chargement des favoris...
      </div>

      <div v-else-if="favoriteListings.length === 0" class="empty-state">
        <div class="empty-icon">💔</div>
        <h2>Aucun cours favori</h2>
        <p>Découvrez des annonces et ajoutez-les à vos favoris pour les retrouver facilement.</p>
        <router-link to="/requetes" class="btn btn-primary">
          🔍 Découvrir des annonces
        </router-link>
      </div>

      <div v-else>
        <div class="favorites-header">
          <span class="count-badge">{{ favoriteListings.length }} favori{{ favoriteListings.length > 1 ? 's' : '' }}</span>
        </div>

        <div class="listings-grid">
          <article v-for="listing in favoriteListings" :key="listing.id" class="listing-card">
            <button class="favorite-button" @click="removeFavorite(listing.id)" title="Retirer des favoris">
              ❤️
            </button>

            <div class="card-header">
              <h3>{{ listing.title }}</h3>
            </div>

            <div class="card-body">
              <p class="description">{{ listing.description }}</p>
              
              <div class="price-section">
                <span class="price">{{ listing.price }} CCT/h</span>
              </div>

              <div class="tags">
                <span class="tag subject">📚 {{ listing.subject || 'Général' }}</span>
                <span class="tag level">🎯 {{ listing.level || 'Tous niveaux' }}</span>
              </div>

              <div class="tutor-info">
                <span class="tutor-name">👨‍🏫 {{ listing.tutor_name }}</span>
              </div>

              <div class="locations-section">
                <div class="location-item">
                  <span class="location-label">Mode:</span>
                  <span class="location-value">{{ listing.tutor_lesson_mode || 'Visio' }}</span>
                </div>
                <div v-if="listing.tutor_lesson_mode === 'Visio'" class="location-item">
                  <span class="location-label">Outil:</span>
                  <span class="location-value">{{ listing.tutor_visio_tool || 'Zoom' }}</span>
                </div>
                <div class="location-item">
                  <span class="location-label">Lieux:</span>
                  <span class="location-value">{{ formatPlaces(listing.tutor_places) }}</span>
                </div>
              </div>
            </div>

            <div class="card-footer">
              <button @click="openListingDetails(listing)" class="btn btn-secondary">
                📖 Voir les détails
              </button>
            </div>
          </article>
        </div>
      </div>
    </div>

    <!-- Modal Détails du cours -->
    <div v-if="showModal && selectedListing" class="modal-overlay" @click.self="closeModal">
      <div class="modal">
        <div class="modal-header">
          <h2>{{ selectedListing.title }}</h2>
          <button @click="closeModal" class="close-btn">×</button>
        </div>
        
        <div class="modal-body">
          <!-- Info du tuteur -->
          <div class="tutor-info">
            <h3>👨‍🏫 Tuteur</h3>
            <p class="tutor-name-large">{{ selectedListing.tutor_name }}</p>
            <p class="tutor-email">{{ selectedListing.tutor_email }}</p>
            <p class="tutor-email"><strong>Mode:</strong> {{ selectedListing.tutor_lesson_mode || 'Visio' }}</p>
            <p class="tutor-email" v-if="selectedListing.tutor_lesson_mode === 'Visio' || selectedListing.tutor_lesson_mode === 'Hybride'">
              <strong>Outil:</strong> {{ selectedListing.tutor_visio_tool || 'Zoom' }}
            </p>
            <p class="tutor-email"><strong>Lieux:</strong> {{ formatPlaces(selectedListing.tutor_places) }}</p>
          </div>

          <div class="course-details" style="margin-top: 1rem;">
            <h3>🙋 Interet pour ce cours</h3>
            <p><strong>{{ selectedListingInterestCount }}</strong> personne(s) interessee(s)</p>
            <button
              v-if="currentUserId && canToggleInterest(selectedListing)"
              class="btn btn-interest"
              :class="{ active: isInterested(selectedListing.id) }"
              @click="toggleInterest(selectedListing.id)"
            >
              {{ isInterested(selectedListing.id) ? 'Retirer mon interet' : 'Montrer mon interet' }}
            </button>
          </div>

          <!-- Détails du cours -->
          <div class="course-details">
            <h3>📋 Détails du cours</h3>
            <div class="detail-grid">
              <div class="detail-item">
                <span class="detail-label">📚 Matière :</span>
                <span class="detail-value">{{ selectedListing.subject }}</span>
              </div>
              <div class="detail-item">
                <span class="detail-label">🎯 Niveau :</span>
                <span class="detail-value">{{ selectedListing.level }}</span>
              </div>
              <div class="detail-item">
                <span class="detail-label">💰 Prix :</span>
                <span class="detail-value">{{ selectedListing.price }} CCT/heure</span>
              </div>
            </div>
            
            <div class="description-section">
              <h4>Description</h4>
              <p>{{ selectedListing.description }}</p>
            </div>
          </div>
        </div>

        <div class="modal-footer">
          <button @click="closeModal" class="btn btn-secondary">Fermer</button>
          <router-link :to="'/requetes?listing=' + selectedListing.id" class="btn btn-primary">
            Réserver ce cours
          </router-link>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useAuth } from '@/composables/useAuth'

const loading = ref(true)
const listings = ref([])
const favoriteIds = ref([])
const showModal = ref(false)
const selectedListing = ref(null)
const { userId: currentUserId, checkAuth } = useAuth()
const myInterestIds = ref([])
const selectedListingInterestCount = ref(0)

const favoriteListings = computed(() => {
  return listings.value.filter((listing) => favoriteIds.value.includes(Number(listing.id)))
})

const formatPlaces = (places) => {
  if (!Array.isArray(places) || places.length === 0) {
    return 'Visio'
  }
  return places.join(', ')
}

const canToggleInterest = (listing) => {
  if (!currentUserId.value) return false
  if (!listing.tutor_user_id) return true
  return listing.tutor_user_id !== currentUserId.value
}

const isInterested = (listingId) => {
  return myInterestIds.value.includes(Number(listingId))
}

const toggleInterest = async (listingId) => {
  if (!currentUserId.value) {
    alert('Connectez-vous pour montrer votre intérêt')
    return
  }

  try {
    const isAlreadyInterested = isInterested(listingId)
    const method = isAlreadyInterested ? 'DELETE' : 'POST'

    const response = await fetch(`/api/listings/${listingId}/interests`, {
      method,
      credentials: 'include'
    })

    if (response.ok) {
      if (isAlreadyInterested) {
        myInterestIds.value = myInterestIds.value.filter(id => id !== Number(listingId))
      } else {
        myInterestIds.value.push(Number(listingId))
      }
      
      // Update the count if modal is open
      if (selectedListing.value && selectedListing.value.id === listingId) {
        if (isAlreadyInterested) {
          selectedListingInterestCount.value--
        } else {
          selectedListingInterestCount.value++
        }
      }
    }
  } catch (err) {
    console.error('Erreur modification intérêt:', err)
  }
}

const openListingDetails = async (listing) => {
  selectedListing.value = listing
  showModal.value = true
  
  // Fetch interest count
  try {
    const response = await fetch(`/api/listings/${listing.id}/interests`, {
      credentials: 'include'
    })
    if (response.ok) {
      const data = await response.json()
      selectedListingInterestCount.value = data.interests?.length || 0
    }
  } catch (err) {
    console.error('Erreur chargement intérêts:', err)
  }
}

const closeModal = () => {
  showModal.value = false
  selectedListing.value = null
}

const loadFavorites = async () => {
  loading.value = true
  try {
    // Get current user
    await checkAuth()

    const [favoritesRes, listingsRes, interestsRes] = await Promise.all([
      fetch('/api/favorites', { credentials: 'include' }),
      fetch('/api/listings', { credentials: 'include' }),
      fetch('/api/interests', { credentials: 'include' })
    ])

    if (favoritesRes.ok) {
      const favoritesData = await favoritesRes.json()
      favoriteIds.value = favoritesData.listingIds || []
    }

    if (listingsRes.ok) {
      const listingsData = await listingsRes.json()
      listings.value = listingsData.listings || []
    }

    if (interestsRes.ok) {
      const interestsData = await interestsRes.json()
      myInterestIds.value = interestsData.listingIds || []
    }
  } catch (err) {
    console.error('Erreur chargement favoris:', err)
  } finally {
    loading.value = false
  }
}

const removeFavorite = async (listingId) => {
  try {
    const response = await fetch(`/api/listings/${listingId}/favorite`, {
      method: 'DELETE',
      credentials: 'include',
    })

    if (response.ok) {
      favoriteIds.value = favoriteIds.value.filter((id) => id !== Number(listingId))
    }
  } catch (err) {
    console.error('Erreur suppression favori:', err)
  }
}

onMounted(() => {
  loadFavorites()
})
</script>

<style scoped>
.page-container {
  padding: 2.5rem 1.5rem;
  background: linear-gradient(135deg, #f8f9fa 0%, #fff5f7 100%);
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
  color: #ec4899;
  margin-bottom: 0.5rem;
  text-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
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
  border-top-color: #ec4899;
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

.favorites-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 2rem;
  flex-wrap: wrap;
  gap: 1rem;
}

.count-badge {
  background: linear-gradient(135deg, #ec4899 0%, #db2777 100%);
  color: white;
  padding: 0.6rem 1.2rem;
  border-radius: 25px;
  font-weight: 700;
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
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.08);
  transition: all 0.3s ease;
  display: flex;
  flex-direction: column;
  position: relative;
}

.listing-card:hover {
  transform: translateY(-8px);
  box-shadow: 0 15px 35px rgba(236, 72, 153, 0.15);
}

.favorite-button {
  position: absolute;
  top: 1rem;
  right: 1rem;
  background: white;
  border: 2px solid #fecdd3;
  color: #ec4899;
  font-size: 1.5em;
  width: 44px;
  height: 44px;
  border-radius: 50%;
  cursor: pointer;
  transition: all 0.3s ease;
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 10;
  box-shadow: 0 4px 12px rgba(236, 72, 153, 0.2);
}

.favorite-button:hover {
  background: #fecdd3;
  transform: scale(1.1);
}

.card-header {
  padding: 1.5rem 1.5rem 0.75rem 1.5rem;
  padding-top: 1rem;
}

.card-header h3 {
  margin: 0;
  font-size: 1.4em;
  color: #1e293b;
  line-height: 1.3;
  word-break: break-word;
}

.card-body {
  padding: 0.75rem 1.5rem;
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.description {
  color: #475569;
  line-height: 1.6;
  margin: 0;
  font-size: 0.95em;
}

.price-section {
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.price {
  font-weight: 700;
  color: #0f766e;
  font-size: 1.3em;
  background: #f0fdfa;
  padding: 0.4rem 0.8rem;
  border-radius: 8px;
}

.tags {
  display: flex;
  gap: 0.5rem;
  flex-wrap: wrap;
}

.tag {
  background: #f0f4ff;
  color: #667eea;
  border-radius: 6px;
  padding: 0.4rem 0.8rem;
  font-size: 0.9em;
  font-weight: 500;
  border-left: 3px solid #667eea;
  padding-left: 0.5rem;
}

.tag.subject {
  background: #e0e7ff;
}

.tag.level {
  background: #f5f3ff;
  color: #a78bfa;
  border-left-color: #a78bfa;
}

.tutor-info {
  padding: 0.75rem;
  background: #f8fafc;
  border-radius: 8px;
  border-left: 3px solid #667eea;
}

.tutor-name {
  font-weight: 600;
  color: #1e293b;
  font-size: 0.95em;
}

.locations-section {
  background: #f8fafc;
  padding: 1rem;
  border-radius: 10px;
  display: flex;
  flex-direction: column;
  gap: 0.6rem;
  border: 1px solid #e2e8f0;
  border-left: 3px solid #f59e0b;
}

.location-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-size: 0.9em;
  gap: 0.5rem;
}

.location-label {
  font-weight: 600;
  color: #64748b;
}

.location-value {
  color: #475569;
  text-align: right;
  flex: 1;
}

.card-footer {
  padding: 1rem 1.5rem;
  background: #f8fafc;
  border-top: 1px solid #e2e8f0;
  display: flex;
  gap: 0.75rem;
}

.btn {
  padding: 0.65rem 1.2rem;
  border-radius: 8px;
  font-weight: 600;
  border: none;
  cursor: pointer;
  transition: all 0.3s ease;
  text-decoration: none;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 0.4rem;
  flex: 1;
  font-size: 0.95em;
}

.btn-primary {
  background: linear-gradient(135deg, #ec4899 0%, #db2777 100%);
  color: white;
}

.btn-primary:hover {
  transform: translateY(-2px);
  box-shadow: 0 8px 16px rgba(236, 72, 153, 0.3);
}

.btn-secondary {
  background: #e2e8f0;
  color: #1e293b;
}

.btn-secondary:hover {
  background: #cbd5e1;
}

.btn-danger {
  background: #fecaca;
  color: #991b1b;
}

.btn-danger:hover {
  background: #fca5a5;
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

  .favorite-button {
    top: 0.75rem;
    right: 0.75rem;
    width: 40px;
    height: 40px;
    font-size: 1.3em;
  }
}

@media (max-width: 480px) {
  .page-header h1 {
    font-size: 1.8em;
  }

  .subtitle {
    font-size: 1em;
  }

  .card-header {
    padding: 0.75rem 1rem;
  }

  .card-body {
    padding: 0.5rem 1rem;
    gap: 0.75rem;
  }

  .card-footer {
    padding: 0.75rem 1rem;
    flex-direction: column;
  }

  .btn {
    width: 100%;
  }

  .favorite-button {
    width: 36px;
    height: 36px;
  }
}

/* MODAL STYLES */
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

.modal {
  background: white;
  border-radius: 15px;
  max-width: 600px;
  width: 100%;
  max-height: 90vh;
  overflow-y: auto;
  box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
}

.modal-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1.5rem;
  background: linear-gradient(135deg, #ec4899 0%, #db2777 100%);
  color: white;
  border-bottom: 2px solid #e2e8f0;
}

.modal-header h2 {
  margin: 0;
  font-size: 1.5em;
  flex: 1;
}

.close-btn {
  background: rgba(255, 255, 255, 0.2);
  border: none;
  color: white;
  font-size: 2em;
  cursor: pointer;
  width: 40px;
  height: 40px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 50%;
  transition: all 0.3s;
}

.close-btn:hover {
  background: rgba(255, 255, 255, 0.3);
}

.modal-body {
  padding: 2rem;
}

.tutor-info {
  background: #f8fafc;
  border-left: 4px solid #ec4899;
  padding: 1.5rem;
  border-radius: 10px;
  margin-bottom: 1.5rem;
}

.tutor-info h3 {
  color: #1e293b;
  margin: 0 0 1rem 0;
  font-size: 1.2em;
}

.tutor-name-large {
  font-weight: 700;
  color: #1e293b;
  margin: 0.5rem 0;
  font-size: 1.3em;
}

.tutor-email {
  color: #475569;
  margin: 0.5rem 0;
  font-size: 0.95em;
}

.course-details {
  margin-bottom: 1.5rem;
}

.course-details h3 {
  color: #1e293b;
  margin: 0 0 1rem 0;
  font-size: 1.2em;
}

.course-details > p {
  color: #475569;
  margin: 0 0 1rem 0;
}

.detail-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 1rem;
  margin-bottom: 1rem;
}

.detail-item {
  background: #f0f4ff;
  padding: 1rem;
  border-radius: 8px;
  border-left: 3px solid #667eea;
}

.detail-label {
  display: block;
  color: #667eea;
  font-weight: 600;
  font-size: 0.9em;
  margin-bottom: 0.3rem;
}

.detail-value {
  color: #1e293b;
  font-weight: 600;
  font-size: 1.05em;
}

.description-section {
  background: #f8fafc;
  padding: 1.5rem;
  border-radius: 10px;
  border: 1px solid #e2e8f0;
}

.description-section h4 {
  color: #1e293b;
  margin: 0 0 0.75rem 0;
}

.description-section p {
  color: #475569;
  line-height: 1.6;
  margin: 0;
}

.btn-interest {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  padding: 0.75rem 1.5rem;
  border-radius: 8px;
  border: none;
  cursor: pointer;
  font-weight: 600;
  transition: all 0.3s;
  margin-top: 1rem;
}

.btn-interest:hover {
  transform: translateY(-2px);
  box-shadow: 0 8px 16px rgba(102, 126, 234, 0.3);
}

.btn-interest.active {
  background: linear-gradient(135deg, #764ba2 0%, #667eea 100%);
}

.modal-footer {
  display: flex;
  gap: 1rem;
  padding: 1.5rem;
  background: #f8fafc;
  border-top: 2px solid #e2e8f0;
  justify-content: flex-end;
}

.btn {
  padding: 0.75rem 1.5rem;
  border-radius: 8px;
  font-weight: 600;
  border: none;
  cursor: pointer;
  transition: all 0.3s;
  text-decoration: none;
  display: inline-block;
  font-size: 0.95em;
}

@media (max-width: 600px) {
  .modal {
    margin: 0.5rem;
    max-height: calc(100vh - 1rem);
  }
  
  .modal-body {
    padding: 1.5rem;
  }
  
  .detail-grid {
    grid-template-columns: 1fr;
  }
  
  .modal-footer {
    flex-direction: column;
  }
  
  .modal-footer .btn {
    width: 100%;
  }
}
</style>
