<template>
  <div class="page-container">
    <div class="container">
      <!-- Header Section -->
      <header class="page-header">
        <h1>🎓 {{ t('requestsList.title') }}</h1>
        <p class="subtitle">{{ t('requestsList.subtitle') }}</p>

        <!-- Search Section -->
        <div class="search-section">
          <input
            v-model="searchQuery"
            type="text"
            class="search-input"
            :placeholder="t('requestsList.searchPlaceholder')"
            @keypress.enter="searchListings"
            autocomplete="off"
          />
          <button class="btn btn-primary" @click="searchListings">
            🔍 {{ t('requestsList.search') }}
          </button>
          <button class="btn btn-secondary" @click="loadAllListings">
            📋 {{ t('requestsList.showAll') }}
          </button>
          <button class="btn btn-filter" @click="showFilters = !showFilters">
            {{ showFilters ? '❌ ' + t('requestsList.hideFilters') : '🛠️ ' + t('requestsList.filtersAndSort') }}
          </button>
        </div>

        <!-- Filters & Sort Section -->
        <div v-if="showFilters" class="filters-section">
          <div class="filter-group">
            <label class="filter-label">📚 {{ t('requestsList.subjectLabel') }}</label>
            <div class="filter-buttons">
              <button
                class="filter-btn"
                :class="{ active: subjectFilter === '' }"
                @click="subjectFilter = ''"
              >
                {{ t('requestsList.allSubjects') }}
              </button>
              <button
                v-for="subject in availableSubjects"
                :key="subject.value"
                class="filter-btn"
                :class="{ active: subjectFilter === subject.value }"
                @click="subjectFilter = subject.value"
              >
                {{ subject.label }}
              </button>
            </div>
          </div>

          <div class="filter-group">
            <label class="filter-label">🎯 {{ t('requestsList.levelLabel') }}</label>
            <div class="filter-buttons">
              <button
                class="filter-btn"
                :class="{ active: levelFilter === '' }"
                @click="levelFilter = ''"
              >
                {{ t('requestsList.allLevels') }}
              </button>
              <button
                v-for="level in availableLevels"
                :key="level.value"
                class="filter-btn"
                :class="{ active: levelFilter === level.value }"
                @click="levelFilter = level.value"
              >
                {{ level.label }}
              </button>
            </div>
          </div>

          <div class="sort-group">
            <label class="filter-label">🔀 {{ t('requestsList.sortBy') }}</label>
            <select v-model="sortBy" class="sort-select">
              <option value="">{{ t('requestsList.sortDefault') }}</option>
              <option value="price-asc">{{ t('requestsList.sortPriceAsc') }}</option>
              <option value="price-desc">{{ t('requestsList.sortPriceDesc') }}</option>
              <option value="title">{{ t('requestsList.sortTitle') }}</option>
            </select>
          </div>
        </div>

        <!-- Stats Section -->
        <div class="stats">
          <span class="stat-badge">{{ t('requestsList.listingsShown', { count: filteredListings.length }) }}</span>
          <span class="stat-badge">{{ searchStatus }}</span>
        </div>
      </header>

      <!-- Error Container -->
      <div v-if="errorMessage" class="error-container">
        <div class="error">
          ❌ {{ errorMessage }}
        </div>
      </div>

      <!-- Loading Container -->
      <div v-if="isLoading" class="loading-container">
        <div class="loading">⏳ {{ t('common.loading') }}</div>
      </div>

      <!-- Listings Grid -->
      <div v-if="!isLoading" class="listings-grid">
        <!-- Empty State -->
        <div v-if="filteredListings.length === 0" class="empty-state">
          <div class="empty-state-icon">🔍</div>
          <h2 class="empty-state-title">{{ t('requestsList.noListingsFound') }}</h2>
          <p class="empty-state-text">
            {{ currentQuery ? t('requestsList.noResultsFor', { query: currentQuery }) : t('requestsList.emptyDatabase') }}
          </p>
          <button v-if="currentQuery" class="btn btn-secondary" @click="loadAllListings">
            {{ t('requestsList.showAllListings') }}
          </button>
        </div>

        <!-- Listing Cards -->
        <div 
          v-for="listing in filteredListings" 
          :key="listing.id" 
          class="listing-card"
          @click="openListingDetails(listing)"
        >
          <div class="listing-header">
            <h3 class="listing-title">{{ localizedTitle(listing) }}</h3>
            <div class="listing-meta">
              <span class="badge badge-subject">📚 {{ listing.subject }}</span>
              <span class="badge badge-level">🎯 {{ listing.level }}</span>
              <span class="badge badge-price">💰 {{ listing.price }} CCT/h</span>
            </div>
          </div>
          <p class="listing-description">{{ localizedDescription(listing) }}</p>
          <div class="listing-footer">
            <span class="tutor-name">👨‍🏫 {{ listing.tutor_name }}</span>
            <span class="engagement">⭐ {{ t('requestsList.favoritesCount', { count: favoriteCounts[listing.id] || 0 }) }}</span>
            <span class="engagement">🙋 {{ t('requestsList.interestedCount', { count: interestCounts[listing.id] || 0 }) }}</span>
            <span v-if="showScores && listing.score !== undefined" class="score-badge">
              {{ t('requestsList.score') }}: {{ Math.round(listing.score * 100) }}%
            </span>
          </div>

          <div v-if="currentUserId" class="listing-actions" @click.stop>
            <button
              class="btn btn-favorite"
              :class="{ active: isFavorite(listing.id) }"
              @click="toggleFavorite(listing.id)"
            >
              {{ isFavorite(listing.id) ? '❤️' : '🤍' }} {{ t('requestsList.favorite') }}
            </button>

            <button
              v-if="canToggleInterest(listing)"
              class="btn btn-interest"
              :class="{ active: isInterested(listing.id) }"
              @click="toggleInterest(listing.id)"
            >
              🙋 {{ isInterested(listing.id) ? t('requestsList.interested') : t('requestsList.showInterest') }}
            </button>
          </div>
        </div>
      </div>

      <!-- Modal Détails de l'annonce -->
      <div v-if="showModal && selectedListing" class="modal-overlay" @click.self="closeModal">
        <div class="modal">
          <div class="modal-header">
            <h2>{{ localizedTitle(selectedListing) }}</h2>
            <button @click="closeModal" class="close-btn">×</button>
          </div>
          
          <div class="modal-body">
            <!-- Info du tuteur -->
            <div class="tutor-info">
              <h3>👨‍🏫 {{ t('requestsList.modal.tutor') }}</h3>
              <p class="tutor-name-large">{{ selectedListing.tutor_name }}</p>
              <p class="tutor-email">{{ selectedListing.tutor_email }}</p>
              <p class="tutor-email"><strong>{{ t('requestsList.modal.mode') }}:</strong> {{ selectedListing.tutor_lesson_mode || 'Visio' }}</p>
              <p class="tutor-email" v-if="selectedListing.tutor_lesson_mode === 'Visio' || selectedListing.tutor_lesson_mode === 'Hybride'">
                <strong>{{ t('requestsList.modal.tool') }}:</strong> {{ selectedListing.tutor_visio_tool || 'Zoom' }}
              </p>
              <p class="tutor-email"><strong>{{ t('requestsList.modal.places') }}:</strong> {{ formatPlaces(selectedListing.tutor_places) }}</p>
              <button
                v-if="currentUserId && selectedListing.tutor_user_id !== currentUserId"
                class="btn btn-interest"
                @click="contactTutor(selectedListing)"
              >
                💬 Contacter le tuteur
              </button>
            </div>

            <div class="course-details" style="margin-top: 1rem;">
              <h3>🙋 {{ t('requestsList.modal.interestTitle') }}</h3>
              <p>{{ t('requestsList.modal.interestedPeople', { count: selectedListingInterestCount }) }}</p>
              <div v-if="isCurrentUserListingOwner && selectedListingInterestPeople.length > 0" class="interest-emails">
                <p><strong>{{ t('requestsList.modal.interestedEmails') }}:</strong></p>
                <ul>
                  <li v-for="mail in selectedListingInterestPeople" :key="mail">{{ mail }}</li>
                </ul>
              </div>
              <button
                v-if="currentUserId && canToggleInterest(selectedListing)"
                class="btn btn-interest"
                :class="{ active: isInterested(selectedListing.id) }"
                @click="toggleInterest(selectedListing.id)"
              >
                {{ isInterested(selectedListing.id) ? t('requestsList.removeInterest') : t('requestsList.showInterest') }}
              </button>
            </div>

            <!-- Détails du cours -->
            <div class="course-details">
              <h3>📋 {{ t('requestsList.modal.courseDetails') }}</h3>
              <div class="detail-grid">
                <div class="detail-item">
                  <span class="detail-label">📚 {{ t('requestsList.subjectLabel') }}</span>
                  <span class="detail-value">{{ selectedListing.subject }}</span>
                </div>
                <div class="detail-item">
                  <span class="detail-label">🎯 {{ t('requestsList.levelLabel') }}</span>
                  <span class="detail-value">{{ selectedListing.level }}</span>
                </div>
                <div class="detail-item">
                  <span class="detail-label">💰 {{ t('requestsList.modal.price') }}:</span>
                  <span class="detail-value">{{ selectedListing.price }} CCT/{{ t('requestsList.modal.perHour') }}</span>
                </div>
              </div>

              <div class="description-section">
                <h4>{{ t('requestsList.modal.description') }}</h4>
                <p>{{ localizedDescription(selectedListing) }}</p>
              </div>
            </div>

            <!-- Connexion requise pour réserver -->
            <div v-if="!bookingSuccess && !currentUserId" class="booking-form">
              <h3>📅 {{ t('requestsList.booking.title') }}</h3>
              <div class="slots-empty">
                <p>🔒 {{ t('requestsList.booking.mustBeLoggedIn') }}</p>
                <router-link to="/login" class="btn btn-primary" @click="closeModal">{{ t('nav.login') }}</router-link>
              </div>
            </div>

            <!-- Formulaire de réservation -->
            <div v-if="!bookingSuccess && currentUserId" class="booking-form">
              <h3>📅 {{ t('requestsList.booking.title') }}</h3>
              <div v-if="bookingError" class="error-message">{{ bookingError }}</div>

              <!-- Loading slots -->
              <div v-if="loadingSlots" class="slots-loading">⏳ {{ t('requestsList.booking.loadingSlots') }}</div>

              <!-- No slots available -->
              <div v-else-if="availableSlots.length === 0" class="slots-empty">
                <p>😕 {{ t('requestsList.booking.noSlots') }}</p>
                <p>{{ t('requestsList.booking.comeBackLater') }}</p>
              </div>

              <!-- Slot picker -->
              <div v-else class="slots-section">
                <p class="slots-hint">{{ t('requestsList.booking.selectSlots') }}</p>
                <div class="slots-grid">
                  <div
                    v-for="slot in availableSlots"
                    :key="slot.slot_id"
                    :class="['slot-card', { selected: selectedSlotIds.includes(slot.slot_id) }]"
                    @click="toggleSlot(slot.slot_id)"
                  >
                    <div class="slot-date">{{ formatSlotDate(slot.start_time) }}</div>
                    <div class="slot-time">
                      {{ formatSlotTime(slot.start_time) }} – {{ formatSlotTime(slot.end_time) }}
                    </div>
                    <div class="slot-duration">{{ t('requestsList.booking.oneHour') }}</div>
                  </div>
                </div>
              </div>

              <div class="form-group" style="margin-top:1rem;">
                <label>{{ t('requestsList.booking.notes') }}</label>
                <textarea
                  v-model="bookingForm.notes"
                  rows="3"
                  :placeholder="t('requestsList.booking.notesPlaceholder')"
                ></textarea>
              </div>

              <div v-if="selectedSlotIds.length > 0" class="booking-summary">
                <p><strong>{{ t('requestsList.booking.selectedSlots') }}:</strong> {{ selectedSlotIds.length }}</p>
                <p><strong>{{ t('requestsList.booking.totalDuration') }}:</strong> {{ totalSelectedDuration }}</p>
                <p><strong>{{ t('requestsList.booking.estimatedPrice') }}:</strong> {{ totalSelectedPrice }} CCT</p>
              </div>
            </div>

            <!-- Message de succès -->
            <div v-if="bookingSuccess" class="success-message">
              <div class="success-icon">✅</div>
              <h3>{{ t('requestsList.booking.confirmed') }}</h3>
              <p>{{ t('requestsList.booking.confirmedText') }}</p>
              <router-link to="/agenda" class="btn btn-primary">
                {{ t('requestsList.booking.viewInAgenda') }}
              </router-link>
            </div>
          </div>

          <div v-if="!bookingSuccess" class="modal-footer">
            <button @click="closeModal" class="btn btn-secondary">{{ t('common.cancel') }}</button>
            <button
              v-if="currentUserId"
              @click="createBooking"
              class="btn btn-primary"
              :disabled="isBooking || selectedSlotIds.length === 0 || availableSlots.length === 0"
            >
              {{ isBooking ? t('requestsList.booking.booking') : t('requestsList.booking.confirm', { count: selectedSlotIds.length }) }}
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
import { useI18n } from 'vue-i18n'
import { useAuth } from '@/composables/useAuth'
import { useMessaging } from '@/composables/useMessaging'

const { t, locale } = useI18n()
const router = useRouter()
const { startConversation } = useMessaging()

// Démarre (ou récupère) la conversation avec le tuteur de cette annonce, puis ouvre la
// messagerie directement sur ce fil.
const contactTutor = async (listing) => {
  try {
    await startConversation(listing.tutor_user_id)
    router.push({ path: '/messages', query: { with: listing.tutor_user_id } })
  } catch (error) {
    console.error('Impossible de contacter le tuteur:', error)
  }
}

// Les annonces sont traduites automatiquement à la création/modification (voir
// server.js). On affiche la version dans la langue active du site, avec repli sur
// le français si la traduction n'est pas disponible (ex : IA indisponible au moment
// de la création de l'annonce).
const localizedTitle = (listing) => {
  if (!listing) return ''
  return listing[`title_${locale.value}`] || listing.title
}
const localizedDescription = (listing) => {
  if (!listing) return ''
  return listing[`description_${locale.value}`] || listing.description
}

// State
const searchQuery = ref('')
const currentQuery = ref('')
const listings = ref([])
const isLoading = ref(false)
const errorMessage = ref('')
const showScores = ref(false)
const showFilters = ref(false)
const subjectFilter = ref('')
const levelFilter = ref('')
const sortBy = ref('')
const { userRole, userId: currentUserId, checkAuth } = useAuth()

// Modal & Booking state
const showModal = ref(false)
const selectedListing = ref(null)
const isBooking = ref(false)
const bookingSuccess = ref(false)
const bookingError = ref('')
const bookingForm = ref({ notes: '' })

// Availability slots
const availableSlots = ref([])
const loadingSlots = ref(false)
const selectedSlotIds = ref([])
const interestCounts = ref({})
const favoriteCounts = ref({})
const myInterestIds = ref([])
const myFavoriteIds = ref([])
const selectedListingInterestCount = ref(0)
const selectedListingInterestPeople = ref([])

// Available filters
const availableSubjects = [
  { value: 'Mathématiques', label: 'Mathématiques' },
  { value: 'Physique', label: 'Physique' },
  { value: 'Chimie', label: 'Chimie' },
  { value: 'Informatique', label: 'Informatique' },
  { value: 'Anglais', label: 'Anglais' },
  { value: 'Français', label: 'Français' }
]

const availableLevels = [
  { value: 'Collège', label: 'Collège' },
  { value: 'Lycée', label: 'Lycée' },
  { value: 'Licence', label: 'Licence' },
  { value: 'Master', label: 'Master' }
]

// Computed
const filteredListings = computed(() => {
  let filtered = [...listings.value]
  
  // Apply subject filter
  if (subjectFilter.value) {
    filtered = filtered.filter(listing => 
      listing.subject === subjectFilter.value
    )
  }
  
  // Apply level filter
  if (levelFilter.value) {
    filtered = filtered.filter(listing => 
      listing.level === levelFilter.value
    )
  }
  
  // Apply sorting
  if (sortBy.value === 'price-asc') {
    filtered.sort((a, b) => a.price - b.price)
  } else if (sortBy.value === 'price-desc') {
    filtered.sort((a, b) => b.price - a.price)
  } else if (sortBy.value === 'title') {
    filtered.sort((a, b) => a.title.localeCompare(b.title))
  }
  
  return filtered
})

const searchStatus = computed(() => {
  if (isLoading.value) return t('common.loading')
  if (currentQuery.value) return t('requestsList.searchingFor', { query: currentQuery.value })
  return t('requestsList.allListings')
})

const isCurrentUserListingOwner = computed(() => {
  if (!selectedListing.value || !currentUserId.value) return false
  return selectedListing.value.tutor_user_id === currentUserId.value
})

// Slot helpers
const slotDuration = (slot) => {
  const h = (new Date(slot.end_time) - new Date(slot.start_time)) / (1000 * 60 * 60)
  const wholeH = Math.floor(h)
  const mins = Math.round((h - wholeH) * 60)
  return mins === 0 ? `${wholeH}h` : `${wholeH}h${mins}`
}

const formatSlotDate = (dt) => {
  return new Date(dt).toLocaleDateString('fr-FR', { weekday: 'long', day: 'numeric', month: 'long', year: 'numeric' })
}

const formatSlotTime = (dt) => {
  return new Date(dt).toLocaleTimeString('fr-FR', { hour: '2-digit', minute: '2-digit' })
}

const totalSelectedDuration = computed(() => {
  const totalH = selectedSlotIds.value.reduce((sum, id) => {
    const slot = availableSlots.value.find(s => s.slot_id === id)
    if (!slot) return sum
    return sum + (new Date(slot.end_time) - new Date(slot.start_time)) / (1000 * 60 * 60)
  }, 0)
  const wholeH = Math.floor(totalH)
  const mins = Math.round((totalH - wholeH) * 60)
  return mins === 0 ? `${wholeH}h` : `${wholeH}h${mins}`
})

const totalSelectedPrice = computed(() => {
  if (!selectedListing.value) return '0'
  const totalH = selectedSlotIds.value.reduce((sum, id) => {
    const slot = availableSlots.value.find(s => s.slot_id === id)
    if (!slot) return sum
    return sum + (new Date(slot.end_time) - new Date(slot.start_time)) / (1000 * 60 * 60)
  }, 0)
  return (totalH * selectedListing.value.price).toFixed(2)
})

// Methods
const showError = (message) => {
  errorMessage.value = message
  setTimeout(() => {
    errorMessage.value = ''
  }, 5000)
}

const formatPlaces = (places) => {
  if (!Array.isArray(places) || places.length === 0) {
    return 'Visio'
  }
  return places.join(', ')
}

const canToggleInterest = (listing) => {
  if (!listing || !currentUserId.value) return false
  return listing.tutor_user_id !== currentUserId.value
}

const isInterested = (listingId) => {
  return myInterestIds.value.includes(Number(listingId))
}

const isFavorite = (listingId) => {
  return myFavoriteIds.value.includes(Number(listingId))
}

const loadAuthData = async () => {
  await checkAuth()
}

const loadEngagement = async () => {
  if (listings.value.length === 0) {
    interestCounts.value = {}
    favoriteCounts.value = {}
    return
  }

  const ids = listings.value.map((listing) => listing.id).join(',')
  try {
    const response = await fetch(`/api/listings/engagement?listing_ids=${ids}`, {
      credentials: 'include',
    })
    if (!response.ok) return
    const data = await response.json()
    interestCounts.value = data.interests || {}
    favoriteCounts.value = data.favorites || {}
    myInterestIds.value = data.myInterests || []
    myFavoriteIds.value = data.myFavorites || []
  } catch (error) {
    console.error('Erreur engagement:', error)
  }
}

const refreshSelectedListingInterests = async () => {
  if (!selectedListing.value) return
  try {
    const response = await fetch(`/api/listings/${selectedListing.value.id}/interests`, {
      credentials: 'include',
    })
    if (!response.ok) return
    const data = await response.json()
    selectedListingInterestCount.value = data.count || 0
    selectedListingInterestPeople.value = data.people || []
  } catch (error) {
    console.error('Erreur chargement interets:', error)
  }
}

const toggleFavorite = async (listingId) => {
  const isAlreadyFavorite = isFavorite(listingId)
  const endpoint = `/api/listings/${listingId}/favorite`

  try {
    const response = await fetch(endpoint, {
      method: isAlreadyFavorite ? 'DELETE' : 'POST',
      credentials: 'include',
    })

    if (!response.ok) {
      throw new Error('Impossible de modifier le favori')
    }

    if (isAlreadyFavorite) {
      myFavoriteIds.value = myFavoriteIds.value.filter((id) => id !== Number(listingId))
      favoriteCounts.value[listingId] = Math.max(0, (favoriteCounts.value[listingId] || 1) - 1)
    } else {
      myFavoriteIds.value.push(Number(listingId))
      favoriteCounts.value[listingId] = (favoriteCounts.value[listingId] || 0) + 1
    }
  } catch (error) {
    showError(error.message)
  }
}

const toggleInterest = async (listingId) => {
  const isAlreadyInterested = isInterested(listingId)
  const endpoint = `/api/listings/${listingId}/interests`

  try {
    const response = await fetch(endpoint, {
      method: isAlreadyInterested ? 'DELETE' : 'POST',
      credentials: 'include',
    })

    if (!response.ok) {
      const payload = await response.json()
      throw new Error(payload.error || 'Impossible de modifier l\'interet')
    }

    const data = await response.json()

    if (isAlreadyInterested) {
      myInterestIds.value = myInterestIds.value.filter((id) => id !== Number(listingId))
    } else {
      myInterestIds.value.push(Number(listingId))
    }

    interestCounts.value[listingId] = data.count || 0

    if (selectedListing.value && Number(selectedListing.value.id) === Number(listingId)) {
      await refreshSelectedListingInterests()
    }
  } catch (error) {
    showError(error.message)
  }
}

const loadAllListings = async () => {
  try {
    isLoading.value = true
    errorMessage.value = ''
    
    const response = await fetch('/api/listings', {
      credentials: 'include'
    })
    
    if (!response.ok) {
      throw new Error(`Erreur HTTP: ${response.status}`)
    }
    
    const data = await response.json()
    
    isLoading.value = false
    currentQuery.value = ''
    searchQuery.value = ''
    showScores.value = false
    
    listings.value = data.listings || []
    await loadEngagement()
  } catch (error) {
    isLoading.value = false
    showError(`Impossible de charger les annonces: ${error.message}`)
    console.error('Erreur:', error)
  }
}

const searchListings = async () => {
  const query = searchQuery.value.trim()
  
  if (!query) {
    showError('Veuillez entrer un terme de recherche')
    return
  }

  try {
    isLoading.value = true
    errorMessage.value = ''
    currentQuery.value = query
    
    const response = await fetch(`/api/listings/search?q=${encodeURIComponent(query)}&limit=20`, {
      credentials: 'include'
    })
    
    if (!response.ok) {
      throw new Error(`Erreur HTTP: ${response.status}`)
    }
    
    const data = await response.json()
    
    isLoading.value = false
    showScores.value = true
    
    listings.value = data.results || []
    await loadEngagement()
  } catch (error) {
    isLoading.value = false
    showError(`Erreur de recherche: ${error.message}`)
    console.error('Erreur:', error)
  }
}

// Modal & Booking methods
const openListingDetails = async (listing) => {
  selectedListing.value = listing
  showModal.value = true
  bookingSuccess.value = false
  bookingError.value = ''
  bookingForm.value = { notes: '' }
  selectedSlotIds.value = []
  selectedListingInterestCount.value = interestCounts.value[listing.id] || 0
  selectedListingInterestPeople.value = []
  await refreshSelectedListingInterests()

  // Fetch available slots for this listing
  loadingSlots.value = true
  availableSlots.value = []
  try {
    const res = await fetch(`/api/availability?tutor_user_id=${listing.tutor_user_id}`, { credentials: 'include' })
    if (res.ok) {
      availableSlots.value = await res.json()
    }
  } catch (e) {
    console.error('Erreur chargement créneaux:', e)
  } finally {
    loadingSlots.value = false
  }
}

const closeModal = () => {
  showModal.value = false
  selectedListing.value = null
  bookingSuccess.value = false
  bookingError.value = ''
  availableSlots.value = []
  selectedSlotIds.value = []
  selectedListingInterestCount.value = 0
  selectedListingInterestPeople.value = []
}

const toggleSlot = (slotId) => {
  const idx = selectedSlotIds.value.indexOf(slotId)
  if (idx >= 0) {
    selectedSlotIds.value.splice(idx, 1)
  } else {
    selectedSlotIds.value.push(slotId)
  }
}

const createBooking = async () => {
  if (!currentUserId.value) {
    bookingError.value = 'Vous devez être connecté(e) pour réserver un cours'
    return
  }

  if (selectedSlotIds.value.length === 0) {
    bookingError.value = 'Veuillez sélectionner au moins un créneau'
    return
  }

  try {
    isBooking.value = true
    bookingError.value = ''

    const response = await fetch('/api/bookings', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      credentials: 'include',
      body: JSON.stringify({
        slot_ids: selectedSlotIds.value,
        listing_id: selectedListing.value.id,
        title: selectedListing.value.title,
        description: selectedListing.value.description,
        subject: selectedListing.value.subject,
        tutor_name: selectedListing.value.tutor_name,
        tutor_email: selectedListing.value.tutor_email,
        price: selectedListing.value.price,
        notes: bookingForm.value.notes
      })
    })

    if (!response.ok) {
      const error = await response.json()
      throw new Error(error.error || 'Erreur lors de la réservation')
    }

    isBooking.value = false
    bookingSuccess.value = true

  } catch (error) {
    isBooking.value = false
    bookingError.value = error.message
    console.error('Erreur:', error)
  }
}

// Lifecycle
onMounted(() => {
  loadAuthData()
  loadAllListings()
})
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
  max-width: 1200px;
  margin: 0 auto;
}

/* Header Styles */
.page-header {
  background: white;
  padding: 2rem;
  border-radius: 15px;
  box-shadow: 0 10px 30px rgba(0, 0, 0, 0.2);
  margin-bottom: 2rem;
}

.page-header h1 {
  color: #667eea;
  margin-bottom: 1rem;
  font-size: 2.5em;
  font-weight: 700;
}

.subtitle {
  color: #666;
  margin-bottom: 1.5rem;
  font-size: 1rem;
}

/* Search Section */
.search-section {
  display: flex;
  gap: 0.75rem;
  margin-bottom: 1.25rem;
  flex-wrap: wrap;
}

.search-input {
  flex: 1;
  min-width: 300px;
  padding: 1rem 1.25rem;
  font-size: 1rem;
  border: 2px solid #e0e0e0;
  border-radius: 10px;
  transition: all 0.3s;
  font-family: inherit;
}

.search-input:focus {
  outline: none;
  border-color: #667eea;
  box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.1);
}

.btn {
  padding: 1rem 1.875rem;
  font-size: 1rem;
  font-weight: 600;
  border: none;
  border-radius: 10px;
  cursor: pointer;
  transition: all 0.3s;
  font-family: inherit;
  white-space: nowrap;
}

.btn-primary {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
}

.btn-primary:hover {
  transform: translateY(-2px);
  box-shadow: 0 5px 15px rgba(102, 126, 234, 0.4);
}

.btn-secondary {
  background: #f5f5f5;
  color: #333;
}

.btn-secondary:hover {
  background: #e0e0e0;
}

.btn-filter {
  background: #fff3e0;
  color: #e65100;
  border: 2px solid #ffb74d;
}

.btn-filter:hover {
  background: #ffe0b2;
  border-color: #ff9800;
  transform: translateY(-2px);
}

/* Stats Section */
.stats {
  display: flex;
  gap: 1rem;
  flex-wrap: wrap;
}

.stat-badge {
  background: #f0f4ff;
  color: #667eea;
  padding: 0.5rem 1rem;
  border-radius: 20px;
  font-size: 0.875rem;
  font-weight: 600;
}

/* Filters & Sort Section */
.filters-section {
  margin: 1.5rem 0;
  padding: 1.5rem;
  background: #f8f9ff;
  border-radius: 12px;
  border: 2px solid #e8ebff;
  animation: slideDown 0.3s ease-out;
  overflow: hidden;
}

@keyframes slideDown {
  from {
    opacity: 0;
    max-height: 0;
    padding-top: 0;
    padding-bottom: 0;
    margin-top: 0;
    margin-bottom: 0;
  }
  to {
    opacity: 1;
    max-height: 1000px;
    padding-top: 1.5rem;
    padding-bottom: 1.5rem;
    margin-top: 1.5rem;
    margin-bottom: 1.5rem;
  }
}

.filter-group,
.sort-group {
  margin-bottom: 1.25rem;
}

.filter-group:last-child,
.sort-group:last-child {
  margin-bottom: 0;
}

.filter-label {
  display: block;
  font-weight: 600;
  color: #333;
  margin-bottom: 0.75rem;
  font-size: 0.95rem;
}

.filter-buttons {
  display: flex;
  gap: 0.5rem;
  flex-wrap: wrap;
}

.filter-btn {
  padding: 0.5rem 1rem;
  font-size: 0.875rem;
  font-weight: 600;
  border: 2px solid #e0e0e0;
  background: white;
  color: #666;
  border-radius: 8px;
  cursor: pointer;
  transition: all 0.3s;
  font-family: inherit;
}

.filter-btn:hover {
  border-color: #667eea;
  color: #667eea;
  transform: translateY(-1px);
}

.filter-btn.active {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  border-color: #667eea;
}

.sort-select {
  width: 100%;
  max-width: 300px;
  padding: 0.75rem 1rem;
  font-size: 0.95rem;
  border: 2px solid #e0e0e0;
  border-radius: 8px;
  background: white;
  color: #333;
  cursor: pointer;
  transition: all 0.3s;
  font-family: inherit;
}

.sort-select:focus {
  outline: none;
  border-color: #667eea;
  box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.1);
}

.sort-select:hover {
  border-color: #667eea;
}

/* Error & Loading */
.error-container {
  margin-bottom: 1.5rem;
}

.error {
  background: #ffebee;
  color: #c62828;
  padding: 1rem 1.25rem;
  border-radius: 10px;
  border-left: 4px solid #c62828;
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

.loading-container {
  text-align: center;
  padding: 3rem;
}

.loading {
  color: white;
  font-size: 1.5em;
  font-weight: 600;
}

/* Listings Grid */
.listings-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(350px, 1fr));
  gap: 1.5rem;
}

.listing-card {
  background: white;
  border-radius: 15px;
  padding: 1.5rem;
  box-shadow: 0 5px 20px rgba(0, 0, 0, 0.1);
  transition: all 0.3s;
  position: relative;
  overflow: hidden;
  cursor: pointer;
}

.listing-card::before {
  content: '';
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  height: 4px;
  background: linear-gradient(90deg, #667eea 0%, #764ba2 100%);
}

.listing-card:hover {
  transform: translateY(-5px);
  box-shadow: 0 10px 30px rgba(0, 0, 0, 0.15);
}

.listing-actions {
  margin-top: 0.85rem;
  display: flex;
  gap: 0.6rem;
  flex-wrap: wrap;
}

.engagement {
  font-size: 0.82rem;
  color: #475569;
  background: #f1f5f9;
  border-radius: 999px;
  padding: 0.25rem 0.6rem;
}

.btn-favorite,
.btn-interest {
  padding: 0.55rem 0.9rem;
  border-radius: 8px;
  border: 2px solid #dbeafe;
  background: #f8fafc;
  color: #1f2937;
}

.btn-favorite.active,
.btn-interest.active {
  border-color: #667eea;
  background: #eef2ff;
}

.interest-emails {
  margin: 0.75rem 0;
  background: #f8fafc;
  border-radius: 10px;
  padding: 0.75rem;
}

.interest-emails ul {
  margin: 0.5rem 0 0;
  padding-left: 1.15rem;
}

/* Modal Styles */
.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.7);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
  padding: 1rem;
  animation: fadeIn 0.3s ease-out;
}

@keyframes fadeIn {
  from {
    opacity: 0;
  }
  to {
    opacity: 1;
  }
}

.modal {
  background: white;
  border-radius: 15px;
  max-width: 700px;
  width: 100%;
  max-height: 90vh;
  overflow-y: auto;
  box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
  animation: slideUp 0.3s ease-out;
}

@keyframes slideUp {
  from {
    transform: translateY(50px);
    opacity: 0;
  }
  to {
    transform: translateY(0);
    opacity: 1;
  }
}

.modal-header {
  padding: 2rem;
  border-bottom: 2px solid #f0f0f0;
  display: flex;
  justify-content: space-between;
  align-items: center;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  border-radius: 15px 15px 0 0;
}

.modal-header h2 {
  margin: 0;
  font-size: 1.5em;
  font-weight: 700;
}

.close-btn {
  background: rgba(255, 255, 255, 0.2);
  border: none;
  color: white;
  font-size: 2em;
  cursor: pointer;
  width: 40px;
  height: 40px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.3s;
}

.close-btn:hover {
  background: rgba(255, 255, 255, 0.3);
  transform: rotate(90deg);
}

.modal-body {
  padding: 2rem;
}

.tutor-info {
  background: #f8f9ff;
  padding: 1.5rem;
  border-radius: 12px;
  margin-bottom: 1.5rem;
  border-left: 4px solid #667eea;
}

.tutor-info h3 {
  color: #667eea;
  margin-bottom: 0.75rem;
  font-size: 1.1em;
}

.tutor-name-large {
  font-size: 1.3em;
  font-weight: 700;
  color: #333;
  margin-bottom: 0.5rem;
}

.tutor-email {
  color: #666;
  font-size: 0.95em;
}

.course-details {
  margin-bottom: 1.5rem;
}

.course-details h3 {
  color: #333;
  margin-bottom: 1rem;
  font-size: 1.1em;
}

.detail-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 1rem;
  margin-bottom: 1.5rem;
}

.detail-item {
  background: #f8f9ff;
  padding: 1rem;
  border-radius: 8px;
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.detail-label {
  font-weight: 600;
  color: #667eea;
  font-size: 0.9em;
}

.detail-value {
  color: #333;
  font-size: 1em;
  font-weight: 600;
}

.description-section {
  background: #f8f9ff;
  padding: 1.5rem;
  border-radius: 12px;
}

.description-section h4 {
  color: #667eea;
  margin-bottom: 0.75rem;
  font-size: 1em;
}

.description-section p {
  color: #666;
  line-height: 1.6;
}

.booking-form {
  background: #fff9f0;
  padding: 1.5rem;
  border-radius: 12px;
  border: 2px solid #ffc107;
}

.booking-form h3 {
  color: #e65100;
  margin-bottom: 1rem;
  font-size: 1.1em;
}

.form-group {
  margin-bottom: 1.25rem;
}

.form-group label {
  display: block;
  font-weight: 600;
  color: #333;
  margin-bottom: 0.5rem;
  font-size: 0.95em;
}

.form-group input,
.form-group textarea {
  width: 100%;
  padding: 0.75rem;
  border: 2px solid #e0e0e0;
  border-radius: 8px;
  font-size: 1rem;
  font-family: inherit;
  transition: all 0.3s;
}

.form-group input:focus,
.form-group textarea:focus {
  outline: none;
  border-color: #667eea;
  box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.1);
}

.booking-summary {
  background: white;
  padding: 1rem;
  border-radius: 8px;
  margin-top: 1rem;
  border: 2px solid #e0e0e0;
}

.booking-summary p {
  color: #333;
  margin: 0.5rem 0;
  font-size: 0.95em;
}

/* ── Slot picker ──────────────────────────────────── */
.slots-loading,
.slots-empty {
  text-align: center;
  padding: 1.5rem;
  color: #666;
  background: #f8f9ff;
  border-radius: 8px;
}

.slots-hint {
  font-weight: 600;
  color: #555;
  margin-bottom: 0.75rem;
}

.slots-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(180px, 1fr));
  gap: 0.75rem;
}

.slot-card {
  border: 2px solid #e0e0e0;
  border-radius: 10px;
  padding: 0.75rem 1rem;
  cursor: pointer;
  transition: all 0.2s;
  background: white;
  text-align: center;
}

.slot-card:hover {
  border-color: #667eea;
  background: #f0f4ff;
}

.slot-card.selected {
  border-color: #667eea;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
}

.slot-date {
  font-size: 0.78em;
  font-weight: 600;
  margin-bottom: 0.25rem;
  text-transform: capitalize;
}

.slot-time {
  font-size: 1em;
  font-weight: 700;
}

.slot-duration {
  font-size: 0.8em;
  margin-top: 0.25rem;
  opacity: 0.75;
}

.success-message {
  text-align: center;
  padding: 2rem;
}

.success-icon {
  font-size: 4em;
  margin-bottom: 1rem;
  animation: scaleIn 0.5s ease-out;
}

@keyframes scaleIn {
  from {
    transform: scale(0);
  }
  to {
    transform: scale(1);
  }
}

.success-message h3 {
  color: #4caf50;
  margin-bottom: 0.75rem;
  font-size: 1.5em;
}

.success-message p {
  color: #666;
  margin-bottom: 1.5rem;
}

.modal-footer {
  padding: 1.5rem 2rem;
  border-top: 2px solid #f0f0f0;
  display: flex;
  gap: 1rem;
  justify-content: flex-end;
}

.modal-footer .btn {
  padding: 0.75rem 1.5rem;
}

.error-message {
  background: #ffebee;
  border: 2px solid #f44336;
  border-radius: 8px;
  padding: 1rem;
  margin-bottom: 1rem;
  color: #c62828;
}

/* Listing Card Styles */
.listing-card {
  background: white;
  border-radius: 15px;
  padding: 1.5rem;
  box-shadow: 0 5px 20px rgba(0, 0, 0, 0.1);
  transition: all 0.3s;
  position: relative;
  overflow: hidden;
}

.listing-card::before {
  content: '';
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  height: 4px;
  background: linear-gradient(90deg, #667eea 0%, #764ba2 100%);
}

.listing-card:hover {
  transform: translateY(-5px);
  box-shadow: 0 10px 30px rgba(0, 0, 0, 0.15);
}

.listing-header {
  margin-bottom: 1rem;
}

.listing-title {
  color: #333;
  font-size: 1.3em;
  font-weight: 700;
  margin-bottom: 0.75rem;
  line-height: 1.3;
}

.listing-meta {
  display: flex;
  gap: 0.625rem;
  flex-wrap: wrap;
  margin-bottom: 1rem;
}

.badge {
  padding: 0.375rem 0.75rem;
  border-radius: 15px;
  font-size: 0.75rem;
  font-weight: 600;
  white-space: nowrap;
}

.badge-subject {
  background: #e3f2fd;
  color: #1976d2;
}

.badge-level {
  background: #f3e5f5;
  color: #7b1fa2;
}

.badge-price {
  background: #fff3e0;
  color: #e65100;
}

.listing-description {
  color: #666;
  line-height: 1.6;
  margin-bottom: 1rem;
  font-size: 0.875rem;
}

.listing-footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding-top: 1rem;
  border-top: 1px solid #f0f0f0;
  gap: 0.5rem;
}

.tutor-name {
  color: #667eea;
  font-weight: 600;
  font-size: 0.875rem;
}

.score-badge {
  background: #4caf50;
  color: white;
  padding: 0.375rem 0.625rem;
  border-radius: 10px;
  font-size: 0.75rem;
  font-weight: 600;
  white-space: nowrap;
}

/* Empty State */
.empty-state {
  grid-column: 1 / -1;
  text-align: center;
  padding: 4rem 2rem;
  background: white;
  border-radius: 15px;
  box-shadow: 0 5px 20px rgba(0, 0, 0, 0.1);
}

.empty-state-icon {
  font-size: 4em;
  margin-bottom: 1.25rem;
}

.empty-state-title {
  font-size: 1.5em;
  color: #333;
  margin-bottom: 0.625rem;
  font-weight: 700;
}

.empty-state-text {
  color: #666;
  margin-bottom: 1.5rem;
  font-size: 1rem;
}

/* Responsive */
@media (max-width: 768px) {
  .page-container {
    padding: 1rem;
  }

  .page-header {
    padding: 1.5rem;
  }

  .page-header h1 {
    font-size: 1.8em;
  }

  .search-section {
    flex-direction: column;
  }

  .search-input {
    min-width: 100%;
  }

  .btn {
    width: 100%;
  }

  .listings-grid {
    grid-template-columns: 1fr;
  }
}

@media (max-width: 480px) {
  .page-header h1 {
    font-size: 1.5em;
  }

  .subtitle {
    font-size: 0.875rem;
  }

  .listing-title {
    font-size: 1.1em;
  }

  .empty-state {
    padding: 2rem 1rem;
  }
}
</style>
