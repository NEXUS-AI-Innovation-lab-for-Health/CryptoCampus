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

      <!-- PROCHAINS COURS À DROITE - REWORKED -->
      <div class="upcoming-section" :class="{ 'is-empty': upcomingBookings.length === 0 && !selectedDateBookings.length }">
        <!-- Header avec titre et actions -->
        <div class="upcoming-header-new">
          <div class="header-content">
            <h2>📅 Prochains cours</h2>
            <span v-if="upcomingBookings.length > 0" class="course-count">{{ upcomingBookings.length }}</span>
          </div>
        </div>

        <!-- État vide -->
        <div v-if="upcomingBookings.length === 0 && !selectedDateBookings.length" class="empty-state-new">
          <div class="empty-icon">📭</div>
          <h3>Aucun cours à venir</h3>
          <p>Réservez un cours pour commencer votre parcours d'apprentissage</p>
        </div>

        <!-- Contenu principal -->
        <div v-else class="courses-main-content">
          <!-- Section : Cours du jour sélectionné -->
          <div v-if="selectedDateBookings.length > 0" class="courses-section">
            <div class="section-header">
              <h3 class="section-title">{{ formatSelectedDate() }}</h3>
              <span class="section-badge">{{ selectedDateBookings.length }} cours</span>
            </div>
            <div class="courses-grid">
              <div
                v-for="booking in selectedDateBookings"
                :key="booking.booking_id"
                :class="['course-card', `status-${booking.status}`, 'selected-date-card']"
              >
                <div class="card-time">
                  <span class="time-badge">{{ formatTime(booking.start_time) }}</span>
                  <span :class="['status-tag', `status-${booking.status}`]">
                    {{ getStatusLabel(booking.status) }}
                  </span>
                </div>
                <div class="card-title">{{ booking.title }}</div>
                <div class="card-meta">
                  <div v-if="booking.subject" class="meta-item"><span class="emoji">📚</span> {{ booking.subject }}</div>
                  <div v-if="booking.tutor_name" class="meta-item"><span class="emoji">👨‍🏫</span> {{ booking.tutor_name }}</div>
                  <div class="meta-item"><span class="emoji">⏱️</span> {{ formatDuration(booking.start_time, booking.end_time) }}</div>
                </div>
                <div v-if="booking.description" class="card-description">{{ booking.description }}</div>
                <div class="card-actions">
                  <button @click="editBooking(booking)" class="btn-action btn-edit" title="Éditer">✏️</button>
                  <button @click="cancelBooking(booking.booking_id)" class="btn-action btn-cancel" title="Annuler">✕</button>
                </div>
              </div>
            </div>
          </div>

          <!-- Divider -->
          <div v-if="selectedDateBookings.length > 0 && upcomingBookings.length > 0" class="section-divider"></div>

          <!-- Section : Cours à venir -->
          <div v-if="upcomingBookings.length > 0" class="courses-section">
            <div class="section-header">
              <h3 class="section-title" v-if="selectedDateBookings.length === 0">À venir</h3>
              <h3 class="section-title" v-else>Autres cours</h3>
              <span class="section-badge">{{ upcomingBookings.length }} cours</span>
            </div>
            <div class="courses-timeline">
              <div
                v-for="(booking, index) in upcomingBookings.slice(0, 5)"
                :key="booking.booking_id"
                :class="['timeline-item', `status-${booking.status}`, { 'is-first': index === 0 }]"
              >
                <div class="timeline-dot"></div>
                <div class="course-info">
                  <div class="info-header">
                    <div class="info-title">{{ booking.title }}</div>
                    <span :class="['info-status', `status-${booking.status}`]">
                      {{ getStatusLabel(booking.status) }}
                    </span>
                  </div>
                  <div class="info-date">{{ formatDateTime(booking.start_time) }}</div>
                  <div class="info-details">
                    <span v-if="booking.subject" class="detail-tag">{{ booking.subject }}</span>
                    <span v-if="booking.tutor_name" class="detail-instructor">{{ booking.tutor_name }}</span>
                  </div>
                  <div class="info-actions">
                    <button @click="editBooking(booking)" class="btn-mini" title="Éditer">✏️</button>
                    <button @click="cancelBooking(booking.booking_id)" class="btn-mini btn-danger-mini" title="Annuler">✕</button>
                  </div>
                </div>
              </div>
              <div v-if="upcomingBookings.length > 5" class="timeline-more">
                <div class="more-message">+{{ upcomingBookings.length - 5 }} autres cours à venir</div>
              </div>
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
      previousMonth,
      nextMonth,
      selectDay,
      formatTime,
      formatDateTime,
      formatSelectedDate,
      formatDuration,
      getStatusLabel,
      editBooking,
      closeModal,
      saveBooking,
      cancelBooking
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

/* UPCOMING SECTION - REWORKED */
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
  justify-content: center;
  align-items: center;
}

.upcoming-header-new {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 1.5rem;
  flex-shrink: 0;
  padding-bottom: 1rem;
  border-bottom: 2px solid #f0f4ff;
}

.header-content {
  display: flex;
  align-items: center;
  gap: 1rem;
  width: 100%;
}

.upcoming-header-new h2 {
  color: #1e293b;
  margin: 0;
  font-size: 1.5em;
  flex: 1;
}

.course-count {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  padding: 0.5rem 1rem;
  border-radius: 20px;
  font-weight: 700;
  font-size: 0.95em;
  white-space: nowrap;
}

.empty-state-new {
  text-align: center;
  padding: 3rem 1.5rem;
  color: #64748b;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
}

.empty-icon {
  font-size: 4em;
  margin-bottom: 1rem;
}

.empty-state-new h3 {
  color: #1e293b;
  margin: 0.5rem 0;
  font-size: 1.2em;
}

.empty-state-new p {
  color: #94a3b8;
  margin: 0.5rem 0;
}

.courses-main-content {
  flex: 1;
  overflow-y: auto;
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
}

.courses-section {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.section-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding-bottom: 0.75rem;
  border-bottom: 2px solid #f0f4ff;
}

.section-title {
  color: #1e293b;
  font-size: 1.1em;
  margin: 0;
  text-transform: capitalize;
  font-weight: 600;
}

.section-badge {
  background: #f0f4ff;
  color: #667eea;
  padding: 0.35rem 0.75rem;
  border-radius: 15px;
  font-size: 0.85em;
  font-weight: 600;
}

.section-divider {
  height: 1px;
  background: linear-gradient(to right, #f0f4ff, transparent);
  margin: 0.5rem 0;
}

/* COURSES GRID (pour jour sélectionné) */
.courses-grid {
  display: grid;
  grid-template-columns: 1fr;
  gap: 0.8rem;
}

/* COURSE CARD */
.course-card {
  background: linear-gradient(135deg, #f8fafc 0%, #f0f4ff 100%);
  border: 2px solid #e2e8f0;
  border-radius: 10px;
  padding: 1rem;
  transition: all 0.3s;
}

.course-card:hover {
  border-color: #667eea;
  box-shadow: 0 4px 12px rgba(102, 126, 234, 0.15);
  transform: translateY(-2px);
}

.course-card.status-pending {
  border-left: 4px solid #f59e0b;
}

.course-card.status-confirmed {
  border-left: 4px solid #10b981;
}

.course-card.status-completed {
  border-left: 4px solid #6366f1;
}

.course-card.status-cancelled {
  border-left: 4px solid #ef4444;
  opacity: 0.6;
}

.card-time {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 0.75rem;
  margin-bottom: 0.75rem;
}

.time-badge {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  padding: 0.4rem 0.75rem;
  border-radius: 6px;
  font-weight: 700;
  font-size: 0.9em;
}

.status-tag {
  padding: 0.3rem 0.6rem;
  border-radius: 4px;
  font-size: 0.75em;
  font-weight: 600;
  white-space: nowrap;
}

.status-tag.status-pending {
  background: #fef3c7;
  color: #92400e;
}

.status-tag.status-confirmed {
  background: #d1fae5;
  color: #065f46;
}

.status-tag.status-completed {
  background: #e0e7ff;
  color: #3730a3;
}

.status-tag.status-cancelled {
  background: #fee2e2;
  color: #7f1d1d;
}

.card-title {
  color: #1e293b;
  font-size: 1em;
  margin: 0.5rem 0;
  font-weight: 600;
}

.card-meta {
  display: flex;
  flex-direction: column;
  gap: 0.35rem;
  font-size: 0.85em;
  color: #64748b;
  margin: 0.75rem 0;
}

.meta-item {
  display: flex;
  align-items: center;
  gap: 0.4rem;
}

.meta-item .emoji {
  font-size: 1.1em;
}

.card-description {
  font-size: 0.85em;
  color: #64748b;
  font-style: italic;
  margin: 0.75rem 0;
  padding: 0.5rem;
  background: white;
  border-radius: 6px;
}

.card-actions {
  display: flex;
  gap: 0.5rem;
  margin-top: 0.75rem;
}

/* TIMELINE - Cours à venir */
.courses-timeline {
  display: flex;
  flex-direction: column;
  gap: 0;
  position: relative;
}

.courses-timeline::before {
  content: '';
  position: absolute;
  left: 12px;
  top: 30px;
  bottom: 0;
  width: 2px;
  background: linear-gradient(180deg, #667eea 0%, transparent 100%);
}

.timeline-item {
  display: flex;
  gap: 1rem;
  padding: 0.75rem 0 0.75rem 2.5rem;
  position: relative;
}

.timeline-item.is-first {
  padding-top: 0;
}

.timeline-item:last-of-type {
  padding-bottom: 0;
}

.timeline-dot {
  position: absolute;
  left: 0;
  top: 0.75rem;
  width: 24px;
  height: 24px;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  border: 3px solid white;
  border-radius: 50%;
  box-shadow: 0 2px 8px rgba(102, 126, 234, 0.3);
}

.course-info {
  flex: 1;
  padding: 0.75rem;
  background: linear-gradient(135deg, #f8fafc 0%, #f0f4ff 100%);
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  transition: all 0.3s;
}

.timeline-item:hover .course-info {
  border-color: #667eea;
  box-shadow: 0 4px 12px rgba(102, 126, 234, 0.1);
}

.info-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  gap: 0.5rem;
  margin-bottom: 0.35rem;
}

.info-title {
  color: #1e293b;
  font-weight: 600;
  font-size: 0.95em;
  flex: 1;
}

.info-status {
  padding: 0.2rem 0.5rem;
  border-radius: 4px;
  font-size: 0.7em;
  font-weight: 600;
  white-space: nowrap;
}

.info-status.status-pending {
  background: #fef3c7;
  color: #92400e;
}

.info-status.status-confirmed {
  background: #d1fae5;
  color: #065f46;
}

.info-status.status-completed {
  background: #e0e7ff;
  color: #3730a3;
}

.info-status.status-cancelled {
  background: #fee2e2;
  color: #7f1d1d;
}

.info-date {
  font-size: 0.8em;
  color: #667eea;
  font-weight: 600;
  margin-bottom: 0.35rem;
}

.info-details {
  display: flex;
  gap: 0.5rem;
  flex-wrap: wrap;
  margin-bottom: 0.5rem;
}

.detail-tag {
  background: white;
  color: #667eea;
  padding: 0.2rem 0.5rem;
  border-radius: 4px;
  font-size: 0.75em;
  font-weight: 600;
}

.detail-instructor {
  color: #64748b;
  font-size: 0.8em;
  padding: 0.2rem 0;
}

.info-actions {
  display: flex;
  gap: 0.4rem;
  margin-top: 0.5rem;
}

.timeline-more {
  padding: 1rem 0 0 2.5rem;
  text-align: center;
}

.more-message {
  color: #667eea;
  font-size: 0.85em;
  font-weight: 600;
  padding: 0.5rem;
}

/* ACTION BUTTONS */
.btn-action {
  width: 32px;
  height: 32px;
  border-radius: 6px;
  border: none;
  cursor: pointer;
  font-size: 1em;
  transition: all 0.3s;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.btn-edit {
  background: #e2e8f0;
  color: #1e293b;
  flex: 1;
}

.btn-edit:hover {
  background: #cbd5e1;
  transform: scale(1.05);
}

.btn-cancel {
  background: #fecaca;
  color: #991b1b;
  flex: 1;
}

.btn-cancel:hover {
  background: #fca5a5;
  transform: scale(1.05);
}

.btn-mini {
  width: 28px;
  height: 28px;
  border-radius: 4px;
  border: none;
  background: #e2e8f0;
  color: #1e293b;
  cursor: pointer;
  font-size: 0.85em;
  transition: all 0.2s;
  display: flex;
  align-items: center;
  justify-content: center;
}

.btn-mini:hover {
  background: #cbd5e1;
  transform: scale(1.1);
}

.btn-danger-mini {
  background: #fecaca;
  color: #991b1b;
}

.btn-danger-mini:hover {
  background: #fca5a5;
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
  font-size: 1.5em;
  color: #64748b;
  cursor: pointer;
  transition: color 0.3s;
}

.close-btn:hover {
  color: #1e293b;
}

.modal-form {
  padding: 1.5rem;
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
.form-group select,
.form-group textarea {
  width: 100%;
  padding: 0.75rem;
  border: 2px solid #e2e8f0;
  border-radius: 8px;
  font-size: 0.95em;
  transition: border-color 0.3s;
}

.form-group input:focus,
.form-group select:focus,
.form-group textarea:focus {
  outline: none;
  border-color: #667eea;
}

.form-row {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 1rem;
}

.form-group textarea {
  resize: vertical;
  min-height: 80px;
}

.modal-actions {
  display: flex;
  gap: 1rem;
  justify-content: flex-end;
  margin-top: 1.5rem;
  padding-top: 1rem;
  border-top: 2px solid #e2e8f0;
}

.btn {
  padding: 0.75rem 1.5rem;
  border: none;
  border-radius: 8px;
  cursor: pointer;
  font-size: 0.95em;
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

/* RESPONSIVE */
@media (max-width: 1024px) {
  .main-layout {
    grid-template-columns: 1fr;
    height: auto;
  }

  .upcoming-section {
    max-height: 500px;
  }
}

@media (max-width: 640px) {
  .agenda-header h1 {
    font-size: 2em;
  }

  .upcoming-header-new {
    flex-direction: column;
    align-items: flex-start;
  }

  .course-count {
    align-self: flex-end;
  }

  .form-row {
    grid-template-columns: 1fr;
  }

  .card-time {
    flex-direction: column;
    align-items: flex-start;
  }
}
</style>
