<template>
  <div class="agenda-container">
    <header class="agenda-header">
      <h1>📅 Mon Agenda</h1>
      <p class="subtitle">Gérez vos cours et réservations</p>
    </header>

    <div class="main-layout">
      <!-- CALENDRIER À GAUCHE -->
      <div class="calendar-section">
        <!-- Navigation mensuelle -->
        <div class="calendar-navigation">
          <button @click="previousMonth" class="nav-btn">‹</button>
          <h2 class="current-month">{{ monthYearLabel }}</h2>
          <button @click="nextMonth" class="nav-btn">›</button>
        </div>

        <!-- Calendrier -->
        <div class="calendar-view">
          <div class="calendar-weekdays">
            <div v-for="day in weekdays" :key="day" class="weekday">{{ day }}</div>
          </div>
          
          <div class="calendar-grid">
            <div
              v-for="(day, index) in calendarDays"
              :key="index"
              :class="['calendar-day', {
                'other-month': day.otherMonth,
                'today': day.isToday,
                'has-bookings': day.bookings.length > 0,
                'selected': selectedDate && selectedDate.getTime() === day.fullDate.getTime()
              }]"
              @click="selectDay(day)"
            >
              <div class="day-number">{{ day.date }}</div>
              <div v-if="day.bookings.length > 0" class="day-indicator">
                <div class="booking-indicator">
                  <span v-if="day.bookings.length === 1" class="booking-dot"></span>
                  <span v-else class="booking-count">{{ day.bookings.length }}</span>
                </div>
              </div>
            </div>
          </div>
        </div>


      </div>

      <!-- PROCHAINS COURS À DROITE -->
      <div class="upcoming-section" :class="{ 'is-empty': upcomingBookings.length === 0 && !selectedDateBookings.length }">
        <div class="upcoming-header">
          <h2>Prochains cours</h2>
          <span class="course-count">{{ upcomingBookings.length }}</span>
        </div>

        <!-- État vide -->
        <div v-if="upcomingBookings.length === 0 && !selectedDateBookings.length" class="empty-state">
          <p>📭 Aucun cours à venir</p>
          <p class="empty-subtext">Réservez un cours pour commencer</p>
        </div>

        <!-- Liste des cours -->
        <div v-else class="bookings-container">
          <!-- Cours du jour sélectionné (si applicable) -->
          <div v-if="selectedDateBookings.length > 0" class="selected-date-section">
            <h3 class="selected-date-title">
              📅 {{ formatSelectedDate() }}
            </h3>
            <div class="bookings-list">
              <div
                v-for="booking in selectedDateBookings"
                :key="booking.booking_id"
                :class="['booking-card', `status-${booking.status}`]"
              >
                <div class="booking-header">
                  <div class="booking-time-large">{{ formatTime(booking.start_time) }}</div>
                  <span :class="['status-badge', `status-${booking.status}`]">
                    {{ getStatusLabel(booking.status) }}
                  </span>
                </div>
                <h4 class="booking-title">{{ booking.title }}</h4>
                <div class="booking-info">
                  <p v-if="booking.subject"><strong>📚</strong> {{ booking.subject }}</p>
                  <p v-if="booking.tutor_name"><strong>👨‍🏫</strong> {{ booking.tutor_name }}</p>
                  <p><strong>⏱️</strong> {{ formatDuration(booking.start_time, booking.end_time) }}</p>
                  <p v-if="booking.price"><strong>💰</strong> {{ booking.price }} CCT</p>
                </div>
                <div v-if="booking.description" class="booking-description">
                  {{ booking.description }}
                </div>
                <div class="booking-actions">
                  <button @click="editBooking(booking)" class="btn btn-secondary btn-sm">✏️ Éditer</button>
                  <button @click="cancelBooking(booking.booking_id)" class="btn btn-danger btn-sm">✕ Annuler</button>
                </div>
              </div>
            </div>
          </div>

          <!-- Cours à venir (scrollable avec arrows) -->
          <div v-if="upcomingBookings.length > 0" :class="['upcoming-list', { 'with-selected': selectedDateBookings.length > 0 }]">
            <div v-if="selectedDateBookings.length > 0" class="divider"></div>
            
            <div v-if="selectedDateBookings.length > 0" class="upcoming-label">
              <h3>À venir</h3>
            </div>

            <!-- Navigation Arrows + Scroll Container -->
            <div class="scroll-wrapper">
              <button 
                v-if="upcomingBookings.length > 1"
                @click="scrollLeft" 
                class="scroll-btn scroll-btn-left"
                :disabled="scrollPosition === 0"
              >
                ‹
              </button>

              <div class="bookings-scroll-container" ref="scrollContainer">
                <div
                  v-for="booking in upcomingBookings"
                  :key="booking.booking_id"
                  :class="['booking-card', `status-${booking.status}`, 'upcoming-card']"
                >
                  <div class="booking-header">
                    <div class="booking-time-large">{{ formatTime(booking.start_time) }}</div>
                    <span :class="['status-badge', `status-${booking.status}`]">
                      {{ getStatusLabel(booking.status) }}
                    </span>
                  </div>
                  <h4 class="booking-title">{{ booking.title }}</h4>
                  <div class="booking-date">
                    {{ formatDateTime(booking.start_time) }}
                  </div>
                  <div class="booking-info-compact">
                    <p v-if="booking.subject"><strong>📚</strong> {{ booking.subject }}</p>
                    <p v-if="booking.tutor_name"><strong>👨‍🏫</strong> {{ booking.tutor_name }}</p>
                  </div>
                  <div class="booking-actions">
                    <button @click="editBooking(booking)" class="btn btn-secondary btn-xs">✏️</button>
                    <button @click="cancelBooking(booking.booking_id)" class="btn btn-danger btn-xs">✕</button>
                  </div>
                </div>
              </div>

              <button 
                v-if="upcomingBookings.length > 1"
                @click="scrollRight" 
                class="scroll-btn scroll-btn-right"
                :disabled="isScrolledToEnd"
              >
                ›
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Modal for editing/creating bookings -->
    <div v-if="showModal" class="modal-overlay" @click.self="closeModal">
      <div class="modal">
        <div class="modal-header">
          <h3>{{ editingBooking ? 'Modifier la réservation' : 'Créer une réservation' }}</h3>
          <button @click="closeModal" class="close-btn">×</button>
        </div>
        <form @submit.prevent="saveBooking" class="modal-form">
          <div class="form-group">
            <label>Titre *</label>
            <input v-model="bookingForm.title" type="text" required placeholder="Ex: Cours de mathématiques">
          </div>
          
          <div class="form-group">
            <label>Description</label>
            <textarea v-model="bookingForm.description" placeholder="Détails du cours..."></textarea>
          </div>
          
          <div class="form-row">
            <div class="form-group">
              <label>Matière</label>
              <select v-model="bookingForm.subject">
                <option value="">Sélectionner</option>
                <option value="math">Mathématiques</option>
                <option value="physics">Physique</option>
                <option value="chemistry">Chimie</option>
                <option value="programming">Programmation</option>
                <option value="french">Français</option>
                <option value="english">Anglais</option>
              </select>
            </div>
            
            <div class="form-group">
              <label>Tuteur</label>
              <input v-model="bookingForm.tutor_name" type="text" placeholder="Nom du tuteur">
            </div>
          </div>
          
          <div class="form-row">
            <div class="form-group">
              <label>Date et heure de début *</label>
              <input v-model="bookingForm.start_time" type="datetime-local" required>
            </div>
            
            <div class="form-group">
              <label>Date et heure de fin *</label>
              <input v-model="bookingForm.end_time" type="datetime-local" required>
            </div>
          </div>
          
          <div class="form-row">
            <div class="form-group">
              <label>Prix (en CCT)</label>
              <input v-model.number="bookingForm.price" type="number" step="0.01" min="0" placeholder="0.00">
            </div>
            
            <div class="form-group">
              <label>Statut</label>
              <select v-model="bookingForm.status">
                <option value="pending">En attente</option>
                <option value="confirmed">Confirmé</option>
                <option value="completed">Terminé</option>
                <option value="cancelled">Annulé</option>
              </select>
            </div>
          </div>
          
          <div class="form-group">
            <label>Notes</label>
            <textarea v-model="bookingForm.notes" placeholder="Notes personnelles..."></textarea>
          </div>
          
          <div class="modal-actions">
            <button type="button" @click="closeModal" class="btn btn-secondary">Annuler</button>
            <button type="submit" class="btn btn-primary">{{ editingBooking ? 'Enregistrer' : 'Créer' }}</button>
          </div>
        </form>
      </div>
    </div>
  </div>
</template>

<script>
import { ref, computed, onMounted } from 'vue'

export default {
  name: 'Agenda',
  setup() {
    const bookings = ref([])
    const currentDate = ref(new Date())
    const selectedDate = ref(null)
    const showModal = ref(false)
    const editingBooking = ref(null)
    const weekdays = ['Dim', 'Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam']
    const scrollPosition = ref(0)
    const scrollContainer = ref(null)
    
    const bookingForm = ref({
      title: '',
      description: '',
      subject: '',
      start_time: '',
      end_time: '',
      tutor_name: '',
      price: null,
      status: 'pending',
      notes: ''
    })

    // Computed properties
    const monthYearLabel = computed(() => {
      const options = { year: 'numeric', month: 'long' }
      return currentDate.value.toLocaleDateString('fr-FR', options)
    })

    const calendarDays = computed(() => {
      const year = currentDate.value.getFullYear()
      const month = currentDate.value.getMonth()
      
      const firstDay = new Date(year, month, 1)
      const startingDayOfWeek = firstDay.getDay()
      const lastDay = new Date(year, month + 1, 0)
      const daysInMonth = lastDay.getDate()
      const daysFromPrevMonth = startingDayOfWeek
      const prevMonthLastDay = new Date(year, month, 0).getDate()
      
      const days = []
      const today = new Date()
      today.setHours(0, 0, 0, 0)
      
      for (let i = daysFromPrevMonth - 1; i >= 0; i--) {
        const date = prevMonthLastDay - i
        days.push({
          date,
          fullDate: new Date(year, month - 1, date),
          otherMonth: true,
          isToday: false,
          bookings: []
        })
      }
      
      for (let i = 1; i <= daysInMonth; i++) {
        const fullDate = new Date(year, month, i)
        const isToday = fullDate.getTime() === today.getTime()
        
        const dayBookings = bookings.value.filter(booking => {
          const bookingDate = new Date(booking.start_time)
          return bookingDate.getDate() === i &&
                 bookingDate.getMonth() === month &&
                 bookingDate.getFullYear() === year
        })
        
        days.push({
          date: i,
          fullDate,
          otherMonth: false,
          isToday,
          bookings: dayBookings
        })
      }
      
      const remainingDays = 42 - days.length
      for (let i = 1; i <= remainingDays; i++) {
        days.push({
          date: i,
          fullDate: new Date(year, month + 1, i),
          otherMonth: true,
          isToday: false,
          bookings: []
        })
      }
      
      return days
    })

    const selectedDateBookings = computed(() => {
      if (!selectedDate.value) return []
      const year = selectedDate.value.getFullYear()
      const month = selectedDate.value.getMonth()
      const date = selectedDate.value.getDate()
      
      return bookings.value.filter(booking => {
        const bookingDate = new Date(booking.start_time)
        return bookingDate.getDate() === date &&
               bookingDate.getMonth() === month &&
               bookingDate.getFullYear() === year &&
               booking.status !== 'cancelled'
      }).sort((a, b) => new Date(a.start_time) - new Date(b.start_time))
    })

    const upcomingBookings = computed(() => {
      const now = new Date()
      return bookings.value
        .filter(b => new Date(b.start_time) >= now && b.status !== 'cancelled')
        .sort((a, b) => new Date(a.start_time) - new Date(b.start_time))
    })

    const isScrolledToEnd = computed(() => {
      if (!scrollContainer.value) return true
      const container = scrollContainer.value
      return container.scrollLeft >= container.scrollWidth - container.clientWidth - 10
    })

    // Methods
    const loadBookings = async () => {
      try {
        const userId = localStorage.getItem('user_id')
        const url = userId ? `/api/bookings?user_id=${userId}` : '/api/bookings'
        const response = await fetch(url)
        
        if (response.ok) {
          bookings.value = await response.json()
        }
      } catch (error) {
        console.error('Erreur lors du chargement des réservations:', error)
      }
    }

    const previousMonth = () => {
      currentDate.value = new Date(
        currentDate.value.getFullYear(),
        currentDate.value.getMonth() - 1,
        1
      )
    }

    const nextMonth = () => {
      currentDate.value = new Date(
        currentDate.value.getFullYear(),
        currentDate.value.getMonth() + 1,
        1
      )
    }

    const selectDay = (day) => {
      if (day.otherMonth) return
      selectedDate.value = day.fullDate
    }

    const formatTime = (datetime) => {
      const date = new Date(datetime)
      return date.toLocaleTimeString('fr-FR', { hour: '2-digit', minute: '2-digit' })
    }

    const formatDateTime = (datetime) => {
      const date = new Date(datetime)
      return date.toLocaleDateString('fr-FR', {
        weekday: 'short',
        day: 'numeric',
        month: 'short',
        hour: '2-digit',
        minute: '2-digit'
      })
    }

    const formatSelectedDate = () => {
      if (!selectedDate.value) return ''
      return selectedDate.value.toLocaleDateString('fr-FR', {
        weekday: 'long',
        day: 'numeric',
        month: 'long',
        year: 'numeric'
      })
    }

    const formatDuration = (startTime, endTime) => {
      const start = new Date(startTime)
      const end = new Date(endTime)
      const diffMs = end - start
      const diffHours = Math.floor(diffMs / (1000 * 60 * 60))
      const diffMinutes = Math.floor((diffMs % (1000 * 60 * 60)) / (1000 * 60))
      
      if (diffHours > 0) {
        return `${diffHours}h${diffMinutes > 0 ? diffMinutes + 'm' : ''}`
      }
      return `${diffMinutes}m`
    }

    const getStatusLabel = (status) => {
      const labels = {
        pending: 'En attente',
        confirmed: 'Confirmé',
        completed: 'Terminé',
        cancelled: 'Annulé'
      }
      return labels[status] || status
    }

    const createNewBooking = () => {
      editingBooking.value = null
      bookingForm.value = {
        title: '',
        description: '',
        subject: '',
        start_time: '',
        end_time: '',
        tutor_name: '',
        price: null,
        status: 'pending',
        notes: ''
      }
      showModal.value = true
    }

    const editBooking = (booking) => {
      editingBooking.value = booking
      bookingForm.value = {
        title: booking.title,
        description: booking.description || '',
        subject: booking.subject || '',
        start_time: new Date(booking.start_time).toISOString().slice(0, 16),
        end_time: new Date(booking.end_time).toISOString().slice(0, 16),
        tutor_name: booking.tutor_name || '',
        price: booking.price || null,
        status: booking.status,
        notes: booking.notes || ''
      }
      showModal.value = true
    }

    const closeModal = () => {
      showModal.value = false
      editingBooking.value = null
    }

    const saveBooking = async () => {
      try {
        const userId = localStorage.getItem('user_id')
        if (!userId) {
          alert('Vous devez être connecté pour créer une réservation')
          return
        }

        const bookingData = {
          ...bookingForm.value,
          user_id: userId
        }

        let response
        if (editingBooking.value) {
          response = await fetch(`/api/bookings/${editingBooking.value.booking_id}`, {
            method: 'PUT',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(bookingData)
          })
        } else {
          response = await fetch('/api/bookings', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(bookingData)
          })
        }

        if (response.ok) {
          await loadBookings()
          closeModal()
        } else {
          const error = await response.json()
          alert('Erreur: ' + error.error)
        }
      } catch (error) {
        console.error('Erreur lors de l\'enregistrement:', error)
        alert('Erreur lors de l\'enregistrement de la réservation')
      }
    }

    const cancelBooking = async (bookingId) => {
      if (!confirm('Êtes-vous sûr de vouloir annuler cette réservation ?')) {
        return
      }

      try {
        const response = await fetch(`/api/bookings/${bookingId}/status`, {
          method: 'PATCH',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ status: 'cancelled' })
        })

        if (response.ok) {
          await loadBookings()
        }
      } catch (error) {
        console.error('Erreur lors de l\'annulation:', error)
      }
    }

    const scrollLeft = () => {
      if (scrollContainer.value) {
        scrollContainer.value.scrollBy({ left: -300, behavior: 'smooth' })
        scrollPosition.value = scrollContainer.value.scrollLeft
      }
    }

    const scrollRight = () => {
      if (scrollContainer.value) {
        scrollContainer.value.scrollBy({ left: 300, behavior: 'smooth' })
        scrollPosition.value = scrollContainer.value.scrollLeft
      }
    }

    onMounted(() => {
      loadBookings()
    })

    return {
      bookings,
      currentDate,
      selectedDate,
      weekdays,
      monthYearLabel,
      calendarDays,
      selectedDateBookings,
      upcomingBookings,
      showModal,
      editingBooking,
      bookingForm,
      scrollPosition,
      scrollContainer,
      isScrolledToEnd,
      previousMonth,
      nextMonth,
      selectDay,
      formatTime,
      formatDateTime,
      formatSelectedDate,
      formatDuration,
      getStatusLabel,
      createNewBooking,
      editBooking,
      closeModal,
      saveBooking,
      cancelBooking,
      scrollLeft,
      scrollRight
    }
  }
}
</script>

<style scoped>
* {
  box-sizing: border-box;
}

.agenda-container {
  min-height: 100vh;
  background: linear-gradient(135deg, #f8f9fa 0%, #f0f4ff 100%);
  padding: 2rem 1.5rem;
}

.agenda-header {
  text-align: center;
  margin-bottom: 2rem;
}

.agenda-header h1 {
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
}

/* MAIN LAYOUT */
.main-layout {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 2rem;
  max-width: 1600px;
  margin: 0 auto;
  height: calc(100vh - 200px);
}

/* CALENDRIER SECTION */
.calendar-section {
  background: white;
  border-radius: 15px;
  padding: 1.5rem;
  box-shadow: 0 5px 15px rgba(0, 0, 0, 0.08);
  display: flex;
  flex-direction: column;
  overflow: hidden;
}

.calendar-navigation {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 1.5rem;
  gap: 1rem;
}

.current-month {
  color: #1e293b;
  font-size: 1.3rem;
  margin: 0;
  text-transform: capitalize;
  flex: 1;
  text-align: center;
}

.nav-btn {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  border: none;
  width: 40px;
  height: 40px;
  border-radius: 50%;
  font-size: 1.3rem;
  cursor: pointer;
  transition: all 0.3s;
  flex-shrink: 0;
}

.nav-btn:hover {
  transform: scale(1.1);
  box-shadow: 0 4px 12px rgba(102, 126, 234, 0.3);
}

.calendar-view {
  flex: 1;
  display: flex;
  flex-direction: column;
  overflow-y: auto;
}

.calendar-weekdays {
  display: grid;
  grid-template-columns: repeat(7, 1fr);
  gap: 0.3rem;
  margin-bottom: 0.5rem;
  flex-shrink: 0;
}

.weekday {
  text-align: center;
  font-weight: 700;
  color: #64748b;
  padding: 0.5rem;
  font-size: 0.9em;
}

.calendar-grid {
  display: grid;
  grid-template-columns: repeat(7, 1fr);
  gap: 0.3rem;
  flex: 1;
}

.calendar-day {
  aspect-ratio: 1;
  border: 2px solid #e2e8f0;
  border-radius: 10px;
  padding: 0.5rem;
  background: white;
  cursor: pointer;
  transition: all 0.3s;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  position: relative;
  min-height: 60px;
}

.calendar-day:hover {
  border-color: #667eea;
  box-shadow: 0 4px 12px rgba(102, 126, 234, 0.15);
  background: #f8fafc;
}

.calendar-day.other-month {
  opacity: 0.3;
  cursor: default;
}

.calendar-day.other-month:hover {
  border-color: #e2e8f0;
  box-shadow: none;
  background: white;
}

.calendar-day.today {
  background: linear-gradient(135deg, #dbeafe 0%, #f0f4ff 100%);
  border-color: #667eea;
  font-weight: bold;
}

.calendar-day.has-bookings {
  border-color: #667eea;
  background: #f8fafc;
}

.calendar-day.selected {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  border-color: #667eea;
  color: white;
}

.calendar-day.selected .day-number,
.calendar-day.selected .booking-indicator {
  color: white;
}

.day-number {
  font-weight: 700;
  color: #1e293b;
  font-size: 0.75em;
  transition: color 0.3s;
}

.day-indicator {
  margin-top: 0.25rem;
}

.booking-indicator {
  display: flex;
  align-items: center;
  justify-content: center;
}

.booking-dot {
  display: inline-block;
  width: 6px;
  height: 6px;
  border-radius: 50%;
  background: #667eea;
  transition: background 0.3s;
}

.booking-count {
  display: inline-block;
  width: 18px;
  height: 18px;
  background: #667eea;
  color: white;
  border-radius: 50%;
  font-size: 0.6em;
  font-weight: 700;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: background 0.3s;
}

.calendar-day.selected .booking-count,
.calendar-day.selected .booking-dot {
  background: white;
}

/* UPCOMING SECTION */
.upcoming-section {
  background: white;
  border-radius: 15px;
  padding: 1.5rem;
  box-shadow: 0 5px 15px rgba(0, 0, 0, 0.08);
  display: flex;
  flex-direction: column;
  overflow: hidden;
}

.upcoming-section.is-empty {
  min-height: auto;
  max-height: 200px;
}

.upcoming-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 1.5rem;
  flex-shrink: 0;
}

.upcoming-header h2 {
  color: #1e293b;
  margin: 0;
  font-size: 1.5em;
}

.course-count {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  padding: 0.4rem 0.8rem;
  border-radius: 20px;
  font-weight: 700;
  font-size: 0.9em;
}

.empty-state {
  text-align: center;
  padding: 3rem 1.5rem;
  color: #64748b;
}

.empty-state p {
  margin: 0.5rem 0;
}

.empty-subtext {
  font-size: 0.95em;
  color: #94a3b8;
}

.bookings-container {
  flex: 1;
  overflow-y: auto;
  display: flex;
  flex-direction: column;
  min-height: 0;
}

.selected-date-section {
  flex-shrink: 0;
  margin-bottom: 1rem;
  padding-bottom: 1rem;
}

.selected-date-title {
  color: #667eea;
  font-size: 1.1em;
  margin: 0 0 1rem 0;
  text-transform: capitalize;
}

.bookings-list {
  display: flex;
  flex-direction: column;
  gap: 0.8rem;
}

.booking-card {
  background: linear-gradient(135deg, #f8fafc 0%, #f0f4ff 100%);
  border: 2px solid #e2e8f0;
  border-radius: 10px;
  padding: 1rem;
  transition: all 0.3s;
}

.booking-card:hover {
  border-color: #667eea;
  box-shadow: 0 4px 12px rgba(102, 126, 234, 0.15);
}

.booking-card.status-pending {
  border-left: 4px solid #f59e0b;
}

.booking-card.status-confirmed {
  border-left: 4px solid #10b981;
}

.booking-card.status-completed {
  border-left: 4px solid #6366f1;
}

.booking-card.status-cancelled {
  border-left: 4px solid #ef4444;
  opacity: 0.6;
}

.booking-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  gap: 0.5rem;
  margin-bottom: 0.5rem;
}

.booking-time-large {
  font-weight: 700;
  font-size: 1.1em;
  color: #667eea;
}

.status-badge {
  padding: 0.3rem 0.6rem;
  border-radius: 6px;
  font-size: 0.75em;
  font-weight: 600;
  white-space: nowrap;
}

.status-badge.status-pending {
  background: #fef3c7;
  color: #92400e;
}

.status-badge.status-confirmed {
  background: #d1fae5;
  color: #065f46;
}

.status-badge.status-completed {
  background: #e0e7ff;
  color: #3730a3;
}

.status-badge.status-cancelled {
  background: #fee2e2;
  color: #7f1d1d;
}

.booking-title {
  color: #1e293b;
  font-size: 1em;
  margin: 0.3rem 0;
  font-weight: 600;
}

.booking-date {
  font-size: 0.85em;
  color: #64748b;
  margin-bottom: 0.5rem;
}

.booking-info, .booking-info-compact {
  font-size: 0.85em;
  color: #475569;
  margin: 0.4rem 0;
}

.booking-info p, .booking-info-compact p {
  margin: 0.3rem 0;
  display: flex;
  align-items: center;
  gap: 0.4rem;
}

.booking-description {
  font-size: 0.85em;
  color: #64748b;
  font-style: italic;
  margin: 0.5rem 0;
  padding: 0.5rem;
  background: white;
  border-radius: 6px;
}

.booking-actions {
  display: flex;
  gap: 0.5rem;
  margin-top: 0.75rem;
}

.btn {
  padding: 0.5rem 1rem;
  border: none;
  border-radius: 6px;
  cursor: pointer;
  font-size: 0.9em;
  font-weight: 600;
  transition: all 0.3s;
  text-decoration: none;
  display: inline-block;
}

.btn-primary {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
}

.btn-primary:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(102, 126, 234, 0.3);
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

.btn-sm {
  padding: 0.4rem 0.75rem;
  font-size: 0.8em;
  flex: 1;
}

.btn-xs {
  padding: 0.3rem 0.5rem;
  font-size: 0.75em;
}

.full-width {
  width: 100%;
}

/* UPCOMING LIST WITH SCROLL */
.upcoming-list {
  flex: 1;
  overflow: hidden;
  display: flex;
  flex-direction: column;
}

.upcoming-list.with-selected {
  margin-top: 1rem;
}

.divider {
  height: 1px;
  background: #e2e8f0;
  margin-bottom: 1rem;
}

.upcoming-label {
  flex-shrink: 0;
  margin-bottom: 0.75rem;
}

.upcoming-label h3 {
  color: #1e293b;
  margin: 0;
  font-size: 1em;
}

.scroll-wrapper {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  flex: 1;
  min-height: 0;
}

.scroll-btn {
  flex-shrink: 0;
  width: 36px;
  height: 36px;
  border-radius: 50%;
  border: 2px solid #e2e8f0;
  background: white;
  color: #667eea;
  cursor: pointer;
  font-size: 1.2em;
  transition: all 0.3s;
}

.scroll-btn:hover:not(:disabled) {
  background: #667eea;
  color: white;
  border-color: #667eea;
}

.scroll-btn:disabled {
  opacity: 0.3;
  cursor: not-allowed;
}

.bookings-scroll-container {
  display: flex;
  gap: 0.8rem;
  overflow-x: auto;
  scroll-behavior: smooth;
  flex: 1;
  padding: 0.5rem 0;
  min-width: 0;
}

.bookings-scroll-container::-webkit-scrollbar {
  height: 4px;
}

.bookings-scroll-container::-webkit-scrollbar-track {
  background: #f1f5f9;
  border-radius: 10px;
}

.bookings-scroll-container::-webkit-scrollbar-thumb {
  background: #cbd5e1;
  border-radius: 10px;
}

.bookings-scroll-container::-webkit-scrollbar-thumb:hover {
  background: #94a3b8;
}

.booking-card.upcoming-card {
  flex: 0 0 250px;
  max-height: 100%;
  display: flex;
  flex-direction: column;
}

.booking-card.upcoming-card .booking-actions {
  margin-top: auto;
}

/* MODAL */
.modal-overlay {
  position: fixed;
  inset: 0;
  background: rgba(0, 0, 0, 0.5);
  display: flex;
  justify-content: center;
  align-items: center;
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
  background: linear-gradient(135deg, #f0f4ff 0%, #faf8ff 100%);
  border-bottom: 2px solid #e2e8f0;
}

.modal-header h3 {
  margin: 0;
  color: #1e293b;
  font-size: 1.3em;
}

.close-btn {
  background: none;
  border: none;
  font-size: 2rem;
  color: #94a3b8;
  cursor: pointer;
  padding: 0;
  width: 30px;
  height: 30px;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: color 0.3s;
}

.close-btn:hover {
  color: #1e293b;
}

.modal-form {
  padding: 1.5rem;
}

.form-group {
  margin-bottom: 1.5rem;
}

.form-group label {
  display: block;
  font-weight: 600;
  color: #1e293b;
  margin-bottom: 0.5rem;
  font-size: 0.95em;
}

.form-group input,
.form-group textarea,
.form-group select {
  width: 100%;
  padding: 0.75rem;
  border: 2px solid #e2e8f0;
  border-radius: 8px;
  font-size: 0.95em;
  font-family: inherit;
  transition: border-color 0.3s;
}

.form-group input:focus,
.form-group textarea:focus,
.form-group select:focus {
  outline: none;
  border-color: #667eea;
  box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.1);
}

.form-row {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 1rem;
}

.modal-actions {
  display: flex;
  gap: 1rem;
  justify-content: flex-end;
  margin-top: 2rem;
  padding-top: 1.5rem;
  border-top: 2px solid #e2e8f0;
}

/* RESPONSIVE */
@media (max-width: 1200px) {
  .main-layout {
    grid-template-columns: 1fr;
    height: auto;
    gap: 1.5rem;
  }
  
  .calendar-section, .upcoming-section {
    min-height: 400px;
  }
}

@media (max-width: 768px) {
  .agenda-container {
    padding: 1rem;
  }
  
  .agenda-header h1 {
    font-size: 2em;
  }
  
  .main-layout {
    gap: 1rem;
  }
  
  .calendar-section, .upcoming-section {
    padding: 1rem;
  }
  
  .calendar-day {
    min-height: 50px;
  }
  
  .form-row {
    grid-template-columns: 1fr;
  }
}
</style>
