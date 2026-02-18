<template>
  <div class="agenda-container">
    <header class="agenda-header">
      <h2>📅 Mon Agenda</h2>
      <p class="subtitle">Gérez vos cours et réservations</p>
    </header>

    <!-- Navigation mensuelle -->
    <div class="calendar-navigation">
      <button @click="previousMonth" class="nav-btn">‹</button>
      <h3 class="current-month">{{ monthYearLabel }}</h3>
      <button @click="nextMonth" class="nav-btn">›</button>
    </div>

    <!-- Vue du calendrier -->
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
            'has-bookings': day.bookings.length > 0
          }]"
        >
          <div class="day-number">{{ day.date }}</div>
          <div class="day-bookings">
            <div
              v-for="booking in day.bookings.slice(0, 2)"
              :key="booking.booking_id"
              :class="['booking-item', `status-${booking.status}`]"
              @click="showBookingDetails(booking)"
              :title="booking.title"
            >
              <span class="booking-time">{{ formatTime(booking.start_time) }}</span>
              <span class="booking-title">{{ booking.title }}</span>
            </div>
            <div v-if="day.bookings.length > 2" class="more-bookings">
              +{{ day.bookings.length - 2 }} autres
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Liste des réservations à venir -->
    <div class="upcoming-bookings">
      <h3>Prochains cours</h3>
      <div v-if="upcomingBookings.length === 0" class="empty-state">
        <p>Aucun cours à venir</p>
        <button @click="createNewBooking" class="btn btn-primary">Réserver un cours</button>
      </div>
      <div v-else class="bookings-list">
        <div
          v-for="booking in upcomingBookings"
          :key="booking.booking_id"
          :class="['booking-card', `status-${booking.status}`]"
        >
          <div class="booking-header">
            <h4>{{ booking.title }}</h4>
            <span :class="['status-badge', `status-${booking.status}`]">
              {{ getStatusLabel(booking.status) }}
            </span>
          </div>
          <div class="booking-details">
            <p><strong>📚 Matière:</strong> {{ booking.subject || 'Non spécifiée' }}</p>
            <p><strong>👤 Tuteur:</strong> {{ booking.tutor_name || 'Non assigné' }}</p>
            <p><strong>🕐 Début:</strong> {{ formatDateTime(booking.start_time) }}</p>
            <p><strong>🕑 Fin:</strong> {{ formatDateTime(booking.end_time) }}</p>
            <p v-if="booking.price"><strong>💰 Prix:</strong> {{ booking.price }} CCT</p>
            <p v-if="booking.description" class="booking-description">{{ booking.description }}</p>
          </div>
          <div class="booking-actions">
            <button @click="editBooking(booking)" class="btn btn-secondary">Modifier</button>
            <button @click="cancelBooking(booking.booking_id)" class="btn btn-danger">Annuler</button>
          </div>
        </div>
      </div>
    </div>

    <!-- Modal pour créer/modifier une réservation -->
    <div v-if="showModal" class="modal-overlay" @click.self="closeModal">
      <div class="modal">
        <div class="modal-header">
          <h3>{{ editingBooking ? 'Modifier la réservation' : 'Nouvelle réservation' }}</h3>
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

    // Computed
    const monthYearLabel = computed(() => {
      const options = { year: 'numeric', month: 'long' }
      return currentDate.value.toLocaleDateString('fr-FR', options)
    })

    const calendarDays = computed(() => {
      const year = currentDate.value.getFullYear()
      const month = currentDate.value.getMonth()
      
      // Premier jour du mois
      const firstDay = new Date(year, month, 1)
      const startingDayOfWeek = firstDay.getDay()
      
      // Dernier jour du mois
      const lastDay = new Date(year, month + 1, 0)
      const daysInMonth = lastDay.getDate()
      
      // Jours du mois précédent à afficher
      const daysFromPrevMonth = startingDayOfWeek
      const prevMonthLastDay = new Date(year, month, 0).getDate()
      
      const days = []
      const today = new Date()
      today.setHours(0, 0, 0, 0)
      
      // Jours du mois précédent
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
      
      // Jours du mois actuel
      for (let i = 1; i <= daysInMonth; i++) {
        const fullDate = new Date(year, month, i)
        const isToday = fullDate.getTime() === today.getTime()
        
        // Filtrer les réservations pour ce jour
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
      
      // Jours du mois suivant pour compléter la grille
      const remainingDays = 42 - days.length // Grille de 6 semaines
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

    const upcomingBookings = computed(() => {
      const now = new Date()
      return bookings.value
        .filter(b => new Date(b.start_time) >= now && b.status !== 'cancelled')
        .sort((a, b) => new Date(a.start_time) - new Date(b.start_time))
        .slice(0, 5)
    })

    // Methods
    const loadBookings = async () => {
      try {
        // Récupérer l'ID utilisateur depuis le localStorage ou session
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

    const formatTime = (datetime) => {
      const date = new Date(datetime)
      return date.toLocaleTimeString('fr-FR', { hour: '2-digit', minute: '2-digit' })
    }

    const formatDateTime = (datetime) => {
      const date = new Date(datetime)
      return date.toLocaleString('fr-FR', {
        weekday: 'short',
        day: 'numeric',
        month: 'short',
        hour: '2-digit',
        minute: '2-digit'
      })
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

    const showBookingDetails = (booking) => {
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
      showBookingDetails(booking)
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
          // Modifier une réservation existante
          response = await fetch(`/api/bookings/${editingBooking.value.booking_id}`, {
            method: 'PUT',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(bookingData)
          })
        } else {
          // Créer une nouvelle réservation
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

    // Lifecycle
    onMounted(() => {
      loadBookings()
    })

    return {
      bookings,
      currentDate,
      weekdays,
      monthYearLabel,
      calendarDays,
      upcomingBookings,
      showModal,
      editingBooking,
      bookingForm,
      previousMonth,
      nextMonth,
      formatTime,
      formatDateTime,
      getStatusLabel,
      showBookingDetails,
      createNewBooking,
      editBooking,
      closeModal,
      saveBooking,
      cancelBooking
    }
  }
}
</script>

<style scoped>
.agenda-container {
  max-width: 1400px;
  margin: 0 auto;
  padding: 2rem;
}

.agenda-header {
  text-align: center;
  margin-bottom: 2rem;
}

.agenda-header h2 {
  color: #2c3e50;
  font-size: 2.5rem;
  margin-bottom: 0.5rem;
}

.subtitle {
  color: #7f8c8d;
  font-size: 1.1rem;
}

/* Navigation du calendrier */
.calendar-navigation {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 1.5rem;
  padding: 1rem;
  background: white;
  border-radius: 8px;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
}

.current-month {
  color: #2c3e50;
  font-size: 1.5rem;
  margin: 0;
  text-transform: capitalize;
}

.nav-btn {
  background: #3498db;
  color: white;
  border: none;
  width: 40px;
  height: 40px;
  border-radius: 50%;
  font-size: 1.5rem;
  cursor: pointer;
  transition: background 0.3s;
}

.nav-btn:hover {
  background: #2980b9;
}

/* Vue du calendrier */
.calendar-view {
  background: white;
  border-radius: 8px;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
  padding: 1rem;
  margin-bottom: 2rem;
}

.calendar-weekdays {
  display: grid;
  grid-template-columns: repeat(7, 1fr);
  gap: 0.5rem;
  margin-bottom: 0.5rem;
}

.weekday {
  text-align: center;
  font-weight: bold;
  color: #7f8c8d;
  padding: 0.5rem;
}

.calendar-grid {
  display: grid;
  grid-template-columns: repeat(7, 1fr);
  gap: 0.5rem;
}

.calendar-day {
  min-height: 100px;
  border: 1px solid #ecf0f1;
  border-radius: 4px;
  padding: 0.5rem;
  background: white;
  transition: all 0.3s;
  cursor: pointer;
}

.calendar-day:hover {
  background: #f8f9fa;
  border-color: #3498db;
}

.calendar-day.other-month {
  opacity: 0.3;
}

.calendar-day.today {
  background: #e8f4fd;
  border-color: #3498db;
  font-weight: bold;
}

.calendar-day.has-bookings {
  border-color: #3498db;
}

.day-number {
  font-weight: bold;
  color: #2c3e50;
  margin-bottom: 0.25rem;
}

.day-bookings {
  font-size: 0.75rem;
}

.booking-item {
  background: #3498db;
  color: white;
  padding: 0.25rem;
  margin-bottom: 0.25rem;
  border-radius: 3px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  cursor: pointer;
  transition: background 0.3s;
}

.booking-item:hover {
  background: #2980b9;
}

.booking-item.status-pending {
  background: #f39c12;
}

.booking-item.status-confirmed {
  background: #27ae60;
}

.booking-item.status-completed {
  background: #95a5a6;
}

.booking-item.status-cancelled {
  background: #e74c3c;
}

.booking-time {
  font-weight: bold;
  margin-right: 0.25rem;
}

.more-bookings {
  color: #7f8c8d;
  font-size: 0.7rem;
  text-align: center;
  margin-top: 0.25rem;
}

/* Liste des réservations à venir */
.upcoming-bookings {
  background: white;
  border-radius: 8px;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
  padding: 2rem;
}

.upcoming-bookings h3 {
  color: #2c3e50;
  margin-bottom: 1.5rem;
}

.empty-state {
  text-align: center;
  padding: 2rem;
}

.empty-state p {
  color: #7f8c8d;
  margin-bottom: 1rem;
}

.bookings-list {
  display: grid;
  gap: 1rem;
}

.booking-card {
  border: 2px solid #ecf0f1;
  border-radius: 8px;
  padding: 1.5rem;
  transition: all 0.3s;
}

.booking-card:hover {
  border-color: #3498db;
  box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1);
}

.booking-card.status-pending {
  border-left: 4px solid #f39c12;
}

.booking-card.status-confirmed {
  border-left: 4px solid #27ae60;
}

.booking-card.status-completed {
  border-left: 4px solid #95a5a6;
}

.booking-card.status-cancelled {
  border-left: 4px solid #e74c3c;
  opacity: 0.6;
}

.booking-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 1rem;
}

.booking-header h4 {
  color: #2c3e50;
  margin: 0;
}

.status-badge {
  padding: 0.25rem 0.75rem;
  border-radius: 12px;
  font-size: 0.85rem;
  font-weight: bold;
}

.status-badge.status-pending {
  background: #f39c12;
  color: white;
}

.status-badge.status-confirmed {
  background: #27ae60;
  color: white;
}

.status-badge.status-completed {
  background: #95a5a6;
  color: white;
}

.status-badge.status-cancelled {
  background: #e74c3c;
  color: white;
}

.booking-details p {
  margin: 0.5rem 0;
  color: #555;
}

.booking-description {
  color: #7f8c8d;
  font-style: italic;
}

.booking-actions {
  display: flex;
  gap: 1rem;
  margin-top: 1rem;
}

/* Boutons */
.btn {
  padding: 0.75rem 1.5rem;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  font-size: 1rem;
  transition: all 0.3s;
  text-decoration: none;
  display: inline-block;
}

.btn-primary {
  background: #3498db;
  color: white;
}

.btn-primary:hover {
  background: #2980b9;
}

.btn-secondary {
  background: #95a5a6;
  color: white;
}

.btn-secondary:hover {
  background: #7f8c8d;
}

.btn-danger {
  background: #e74c3c;
  color: white;
}

.btn-danger:hover {
  background: #c0392b;
}

/* Modal */
.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.5);
  display: flex;
  justify-content: center;
  align-items: center;
  z-index: 1000;
}

.modal {
  background: white;
  border-radius: 8px;
  max-width: 600px;
  width: 90%;
  max-height: 90vh;
  overflow-y: auto;
  box-shadow: 0 4px 16px rgba(0, 0, 0, 0.2);
}

.modal-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1.5rem;
  border-bottom: 1px solid #ecf0f1;
}

.modal-header h3 {
  margin: 0;
  color: #2c3e50;
}

.close-btn {
  background: none;
  border: none;
  font-size: 2rem;
  color: #7f8c8d;
  cursor: pointer;
  padding: 0;
  width: 30px;
  height: 30px;
  line-height: 1;
}

.close-btn:hover {
  color: #2c3e50;
}

.modal-form {
  padding: 1.5rem;
}

.form-group {
  margin-bottom: 1.5rem;
}

.form-group label {
  display: block;
  margin-bottom: 0.5rem;
  color: #2c3e50;
  font-weight: bold;
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

.form-group textarea {
  resize: vertical;
  min-height: 80px;
}

.form-row {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 1rem;
}

.modal-actions {
  display: flex;
  justify-content: flex-end;
  gap: 1rem;
  margin-top: 2rem;
  padding-top: 1rem;
  border-top: 1px solid #ecf0f1;
}

@media (max-width: 768px) {
  .calendar-day {
    min-height: 80px;
    font-size: 0.85rem;
  }
  
  .form-row {
    grid-template-columns: 1fr;
  }
  
  .booking-actions {
    flex-direction: column;
  }
}
</style>
