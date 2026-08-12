<template>
  <div class="reservations-page">
    <div class="page-header">
      <h1>📋 Mes Réservations</h1>
      <p v-if="userRole === 'TUTOR'" class="subtitle">Gérez les réservations de cours de vos étudiants</p>
      <p v-else class="subtitle">Suivez vos cours réservés</p>
    </div>

    <!-- ═══════════════════════════════════════════════════════
         SECTION TUTEUR : GESTION DES DISPONIBILITÉS
         ═══════════════════════════════════════════════════════ -->
    <section v-if="userRole === 'TUTOR'" class="availability-section">
      <div class="availability-header">
        <h2>🗓️ Mes disponibilités</h2>
        <button @click="showSlotModal = true" class="btn btn-primary btn-sm">+ Ajouter un créneau</button>
      </div>

      <!-- Slot list -->
      <div v-if="mySlots.length === 0" class="slots-empty-msg">
        Vous n'avez aucun créneau défini. Ajoutez vos disponibilités pour que les étudiants puissent réserver.
      </div>
      <div v-else>
        <div class="calendar-toolbar">
          <button class="btn btn-secondary btn-sm" @click="changeWeek(-1)">← Semaine précédente</button>
          <div class="week-label">{{ weekLabel }}</div>
          <button class="btn btn-secondary btn-sm" @click="changeWeek(1)">Semaine suivante →</button>
          <button class="btn btn-outline btn-sm" @click="goToCurrentWeek">Aujourd'hui</button>
        </div>

        <div class="week-calendar">
          <div 
            v-for="day in weekDays" 
            :key="day.key"
            class="day-column"
            :class="{ 'has-slots': slotsByDay[day.key]?.length }"
            @click="selectedDayKey = day.key"
          >
            <div class="day-header">
              <div class="day-name">{{ day.label }}</div>
              <div class="day-date">{{ day.shortDate }}</div>
            </div>

            <div class="day-content">
              <div v-if="slotsByDay[day.key]?.length" class="day-indicator">
                <div class="slots-count">
                  {{ slotsByDay[day.key].length }} créneau{{ slotsByDay[day.key].length > 1 ? 'x' : '' }}
                </div>
                <div class="booked-count" v-if="getBookedSlotsCount(day.key) > 0">
                  {{ getBookedSlotsCount(day.key) }} réservé{{ getBookedSlotsCount(day.key) > 1 ? 's' : '' }}
                </div>
              </div>
              <div v-else class="day-empty">Aucun créneau</div>
            </div>
          </div>
        </div>
      </div>

      <!-- Modal showing day details -->
      <div v-if="selectedDayKey" class="modal-overlay" @click.self="selectedDayKey = null">
        <div class="modal modal-sm">
          <div class="modal-header">
            <h3>{{ formatDayTitle(selectedDayKey) }}</h3>
            <button @click="selectedDayKey = null" class="close-btn">×</button>
          </div>
          <div class="day-slots-modal">
            <div 
              v-if="!slotsByDay[selectedDayKey]?.length"
              class="no-slots-msg"
            >
              Aucun créneau pour ce jour.
            </div>
            <div 
              v-for="slot in slotsByDay[selectedDayKey]"
              :key="slot.slot_id"
              :class="['slot-item', slot.is_booked ? 'booked' : 'available']"
            >
              <div class="slot-time">{{ formatSlotTime(slot.start_time) }} – {{ formatSlotTime(slot.end_time) }}</div>
              <div class="slot-status">
                <span :class="['status-badge', slot.is_booked ? 'badge-booked' : 'badge-available']">
                  {{ slot.is_booked ? 'Réservé' : 'Libre' }}
                </span>
              </div>
              <button
                v-if="!slot.is_booked"
                @click="deleteSlot(slot.slot_id)"
                class="btn-icon-danger"
                title="Supprimer ce créneau"
              >✕</button>
            </div>
          </div>
        </div>
      </div>
    </section>

    <!-- Modal ajout créneau -->
    <div v-if="showSlotModal" class="modal-overlay" @click.self="showSlotModal = false">
      <div class="modal modal-sm">
        <div class="modal-header">
          <h3>Ajouter des créneaux de disponibilité</h3>
          <button @click="showSlotModal = false" class="close-btn">×</button>
        </div>
        <div v-if="slotError" class="error-msg">{{ slotError }}</div>
        <form @submit.prevent="createSlot" class="modal-form">
          <div class="form-group">
            <label>Date et heure de début *</label>
            <TimePickerInput 
              v-model="slotForm.start_time"
              :is-open="focusedPickerInput === 'start'"
              @update:is-open="focusedPickerInput = $event ? 'start' : null"
              :min-date-time="minSlotDateTime"
              placeholder="Cliquez pour sélectionner"
              :has-error="timeValidationErrors.start !== ''"
            />
            <small v-if="timeValidationErrors.start" class="error-hint">{{ timeValidationErrors.start }}</small>
          </div>
          <div class="form-group">
            <label>Date et heure de fin *</label>
            <TimePickerInput 
              v-model="slotForm.end_time"
              :is-open="focusedPickerInput === 'end'"
              @update:is-open="focusedPickerInput = $event ? 'end' : null"
              :min-date-time="slotForm.start_time || minSlotDateTime"
              placeholder="Cliquez pour sélectionner"
              :has-error="timeValidationErrors.end !== ''"
              :disabled="!slotForm.start_time"
              :locked-minute="lockedEndMinute"
            />
            <small v-if="timeValidationErrors.end" class="error-hint">{{ timeValidationErrors.end }}</small>
            <small v-if="!slotForm.start_time" class="help-text">Choisissez d'abord l'heure de debut.</small>
          </div>
          <p class="help-text">💡 Les créneaux seront automatiquement divisés en tranches d'1 heure</p>
          <div class="modal-actions">
            <button type="button" @click="showSlotModal = false" class="btn btn-secondary">Annuler</button>
            <button type="submit" class="btn btn-primary" :disabled="creatingSlot || !isSlotFormValid">
              {{ creatingSlot ? 'Création...' : 'Créer' }}
            </button>
          </div>
        </form>
      </div>
    </div>

    <!-- Filters -->
    <div class="filters-bar">
      <button 
        v-for="status in statusOptions" 
        :key="status.value"
        @click="statusFilter = status.value"
        :class="['filter-btn', { active: statusFilter === status.value }]"
      >
        {{ status.icon }} {{ status.label }}
      </button>
    </div>

    <!-- Loading State -->
    <div v-if="loading" class="loading-container">
      <div class="spinner"></div>
      <p>Chargement des réservations...</p>
    </div>

    <!-- Error State -->
    <div v-else-if="error" class="error-container">
      <div class="error-icon">⚠️</div>
      <p>{{ error }}</p>
      <button @click="fetchBookings" class="btn btn-primary">Réessayer</button>
    </div>

    <!-- Empty State -->
    <div v-else-if="filteredBookings.length === 0" class="empty-state">
      <div class="empty-icon">📭</div>
      <h3>Aucune réservation</h3>
      <p v-if="statusFilter === 'all'">
        {{ userRole === 'TUTOR' ? 'Vous n\'avez pas encore reçu de réservations.' : 'Vous n\'avez pas encore réservé de cours.' }}
      </p>
      <p v-else>Aucune réservation avec ce statut.</p>
      <router-link v-if="userRole === 'STUDENT'" to="/requetes" class="btn btn-primary">
        Parcourir les cours
      </router-link>
    </div>

    <!-- Bookings List -->
    <div v-else class="bookings-container">
      <div class="bookings-count">
        {{ filteredBookings.length }} réservation{{ filteredBookings.length > 1 ? 's' : '' }}
      </div>

      <div class="bookings-grid">
        <div 
          v-for="booking in filteredBookings" 
          :key="booking.booking_id"
          class="booking-card"
          :class="'status-' + booking.status"
        >
          <!-- Status Badge -->
          <div class="booking-status">
            <span :class="['status-badge', 'badge-' + booking.status]">
              {{ getStatusIcon(booking.status) }} {{ getStatusLabel(booking.status) }}
            </span>
          </div>

          <!-- Card Content -->
          <div class="booking-content">
            <div class="booking-header">
              <h3 class="booking-title">{{ booking.title }}</h3>
              <span class="booking-price">{{ booking.price }}CCT/h</span>
            </div>

            <div class="booking-info">
              <!-- Tutor/Student Info -->
              <div v-if="userRole === 'TUTOR'" class="info-item">
                <span class="info-label">👤 Étudiant:</span>
                <span class="info-value">{{ booking.student_name || 'N/A' }}</span>
              </div>
              <div v-else class="info-item">
                <span class="info-label">👨‍🏫 Tuteur:</span>
                <span class="info-value">{{ booking.tutor_name }}</span>
              </div>

              <!-- Subject -->
              <div class="info-item">
                <span class="info-label">📚 Matière:</span>
                <span class="info-value badge-subject">{{ booking.subject }}</span>
              </div>

              <!-- Date & Time -->
              <div class="info-item full-width">
                <span class="info-label">📅 Date:</span>
                <span class="info-value">{{ formatDateTime(booking.start_time) }}</span>
              </div>

              <div class="info-item full-width">
                <span class="info-label">⏰ Durée:</span>
                <span class="info-value">
                  {{ calculateDuration(booking.start_time, booking.end_time) }}
                </span>
              </div>

              <!-- Description -->
              <div v-if="booking.description" class="booking-description">
                <span class="info-label">📝 Description:</span>
                <p>{{ booking.description }}</p>
              </div>

              <!-- Notes -->
              <div v-if="booking.notes" class="booking-notes">
                <span class="info-label">💬 Notes:</span>
                <p>{{ booking.notes }}</p>
              </div>
            </div>

            <!-- Actions -->
            <div class="booking-actions">
              <!-- For Tutors: Confirm, Reject, Complete -->
              <template v-if="userRole === 'TUTOR'">
                <button 
                  v-if="booking.status === 'pending'"
                  @click="updateBookingStatus(booking.booking_id, 'confirmed')"
                  class="btn btn-success btn-sm"
                  :disabled="updating === booking.booking_id"
                >
                  ✓ Confirmer
                </button>
                <button 
                  v-if="booking.status === 'confirmed'"
                  @click="updateBookingStatus(booking.booking_id, 'completed')"
                  class="btn btn-primary btn-sm"
                  :disabled="updating === booking.booking_id"
                >
                  ✓ Marquer terminé
                </button>
                <button 
                  v-if="['pending', 'confirmed'].includes(booking.status)"
                  @click="updateBookingStatus(booking.booking_id, 'cancelled')"
                  class="btn btn-danger btn-sm"
                  :disabled="updating === booking.booking_id"
                >
                  ✕ Annuler
                </button>
              </template>

              <!-- For Students: Cancel if pending or confirmed -->
              <template v-else>
                <button 
                  v-if="['pending', 'confirmed'].includes(booking.status)"
                  @click="cancelBooking(booking.booking_id)"
                  class="btn btn-danger btn-sm"
                  :disabled="updating === booking.booking_id"
                >
                  ✕ Annuler ma réservation
                </button>
              </template>

              <!-- View in Agenda -->
              <router-link 
                to="/agenda" 
                class="btn btn-outline btn-sm"
              >
                📅 Voir dans l'agenda
              </router-link>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { ref, computed, onMounted, watch } from 'vue';
import TimePickerInput from '../components/TimePickerInput.vue';
import { useAuth } from '@/composables/useAuth';

export default {
  name: 'Reservations',
  components: { TimePickerInput },
  setup() {
    const { userRole, checkAuth } = useAuth();
    const bookings = ref([]);
    const loading = ref(true);
    const error = ref(null);
    const statusFilter = ref('all');
    const updating = ref(null);

    // ── Availability state ──────────────────────────────────────────
    const mySlots = ref([]);
    const showSlotModal = ref(false);
    const creatingSlot = ref(false);
    const slotError = ref('');
    const slotForm = ref({ start_time: '', end_time: '' });
    const timeValidationErrors = ref({ start: '', end: '' });
    const focusedPickerInput = ref(null); // 'start', 'end', or null
    const currentWeekStart = ref(new Date());
    const selectedDayKey = ref(null);

    const getStartOfWeek = (date) => {
      const d = new Date(date);
      const day = d.getDay();
      const diff = day === 0 ? -6 : 1 - day;
      d.setDate(d.getDate() + diff);
      d.setHours(0, 0, 0, 0);
      return d;
    };

    const toDayKey = (dateLike) => {
      const d = new Date(dateLike);
      const year = d.getFullYear();
      const month = String(d.getMonth() + 1).padStart(2, '0');
      const day = String(d.getDate()).padStart(2, '0');
      return `${year}-${month}-${day}`;
    };

    currentWeekStart.value = getStartOfWeek(new Date());

    const toDateTimeLocalValue = (date) => {
      const year = date.getFullYear();
      const month = String(date.getMonth() + 1).padStart(2, '0');
      const day = String(date.getDate()).padStart(2, '0');
      const hour = String(date.getHours()).padStart(2, '0');
      const minute = String(date.getMinutes()).padStart(2, '0');
      return `${year}-${month}-${day}T${hour}:${minute}`;
    };

    const isSlotFormValid = computed(() => {
      return slotForm.value.start_time && 
             slotForm.value.end_time && 
             !timeValidationErrors.value.start && 
             !timeValidationErrors.value.end;
    });

    const minSlotDateTime = computed(() => {
      const now = new Date();
      now.setMinutes(now.getMinutes() + 30);
      return toDateTimeLocalValue(now);
    });

    const lockedEndMinute = computed(() => {
      if (!slotForm.value.start_time) return null;
      const minute = new Date(slotForm.value.start_time).getMinutes();
      return minute === 0 || minute === 30 ? minute : null;
    });

    // Keep end minute aligned with start minute and block end input until start is chosen.
    watch(() => slotForm.value.start_time, (newStart) => {
      if (!newStart) {
        slotForm.value.end_time = '';
        timeValidationErrors.value.end = '';
        return;
      }

      // If end_time is empty, automatically set it to 1 hour after start_time
      if (!slotForm.value.end_time) {
        const startDate = new Date(newStart);
        const endDate = new Date(startDate);
        endDate.setHours(endDate.getHours() + 1);
        slotForm.value.end_time = toDateTimeLocalValue(endDate);
        return;
      }

      // If end_time is set, align its minutes with start_time minutes
      const startMinute = new Date(newStart).getMinutes();
      const endDate = new Date(slotForm.value.end_time);
      if (endDate.getMinutes() !== startMinute) {
        endDate.setMinutes(startMinute, 0, 0);
        slotForm.value.end_time = toDateTimeLocalValue(endDate);
      }
    });

    // Reset focused picker when modal closes
    watch(() => showSlotModal.value, (isOpen) => {
      if (!isOpen) {
        focusedPickerInput.value = null;
      }
    });

    const formatSlotDate = (dt) =>
      new Date(dt).toLocaleDateString('fr-FR', { weekday: 'long', day: 'numeric', month: 'long' });

    const formatSlotTime = (dt) =>
      new Date(dt).toLocaleTimeString('fr-FR', { hour: '2-digit', minute: '2-digit' });

    const weekDays = computed(() => {
      return Array.from({ length: 7 }).map((_, index) => {
        const day = new Date(currentWeekStart.value);
        day.setDate(day.getDate() + index);
        return {
          key: toDayKey(day),
          label: day.toLocaleDateString('fr-FR', { weekday: 'long' }),
          shortDate: day.toLocaleDateString('fr-FR', { day: '2-digit', month: '2-digit' }),
        };
      });
    });

    const weekLabel = computed(() => {
      const weekStart = new Date(currentWeekStart.value);
      const weekEnd = new Date(currentWeekStart.value);
      weekEnd.setDate(weekEnd.getDate() + 6);
      return `${weekStart.toLocaleDateString('fr-FR', { day: '2-digit', month: 'long' })} - ${weekEnd.toLocaleDateString('fr-FR', { day: '2-digit', month: 'long', year: 'numeric' })}`;
    });

    const slotsByDay = computed(() => {
      const start = new Date(currentWeekStart.value);
      const end = new Date(currentWeekStart.value);
      end.setDate(end.getDate() + 7);

      const grouped = {};
      for (const slot of mySlots.value) {
        const slotStart = new Date(slot.start_time);
        if (slotStart >= start && slotStart < end) {
          const key = toDayKey(slotStart);
          if (!grouped[key]) grouped[key] = [];
          grouped[key].push(slot);
        }
      }

      for (const key of Object.keys(grouped)) {
        grouped[key].sort((a, b) => new Date(a.start_time) - new Date(b.start_time));
      }

      return grouped;
    });

    const changeWeek = (delta) => {
      const next = new Date(currentWeekStart.value);
      next.setDate(next.getDate() + (delta * 7));
      currentWeekStart.value = getStartOfWeek(next);
    };

    const goToCurrentWeek = () => {
      currentWeekStart.value = getStartOfWeek(new Date());
    };

    // Validate that time is on round/half-hour boundary
    const validateSlotTime = (field) => {
      const timeStr = field === 'start' ? slotForm.value.start_time : slotForm.value.end_time;
      if (!timeStr) {
        timeValidationErrors.value[field] = '';
        return;
      }
      const date = new Date(timeStr);
      const minutes = date.getMinutes();
      if (minutes !== 0 && minutes !== 30) {
        timeValidationErrors.value[field] = 'Doit être à XX:00 ou XX:30';
      } else {
        timeValidationErrors.value[field] = '';
      }
    };

    const fetchMySlots = async () => {
      try {
        const res = await fetch('/api/availability/mine', { credentials: 'include' });
        if (res.ok) mySlots.value = await res.json();
      } catch (e) {
        console.error('Erreur chargement créneaux:', e);
      }
    };

    const createSlot = async () => {
      if (!slotForm.value.start_time || !slotForm.value.end_time) {
        slotError.value = 'Tous les champs sont requis';
        return;
      }

      // Validate times
      validateSlotTime('start');
      validateSlotTime('end');
      if (timeValidationErrors.value.start || timeValidationErrors.value.end) {
        slotError.value = 'Les heures doivent être à XX:00 ou XX:30';
        return;
      }

      const startDate = new Date(slotForm.value.start_time);
      const endDate = new Date(slotForm.value.end_time);
      if (endDate <= startDate) {
        slotError.value = 'La date/heure de fin doit être après le début';
        return;
      }

      creatingSlot.value = true;
      slotError.value = '';
      try {
        const res = await fetch('/api/availability', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          credentials: 'include',
          body: JSON.stringify({
            start_time: slotForm.value.start_time,
            end_time: slotForm.value.end_time,
          }),
        });
        if (!res.ok) {
          const err = await res.json();
          slotError.value = err.error || 'Erreur';
          return;
        }
        showSlotModal.value = false;
        slotForm.value = { start_time: '', end_time: '' };
        timeValidationErrors.value = { start: '', end: '' };
        await fetchMySlots();
      } catch (e) {
        slotError.value = e.message;
      } finally {
        creatingSlot.value = false;
      }
    };

    const deleteSlot = async (slotId) => {
      if (!confirm('Supprimer ce créneau ?')) return;
      try {
        const res = await fetch(`/api/availability/${slotId}`, {
          method: 'DELETE',
          credentials: 'include',
        });
        if (res.ok) {
          mySlots.value = mySlots.value.filter(s => s.slot_id !== slotId);
        } else {
          const err = await res.json();
          alert(err.error || 'Erreur lors de la suppression');
        }
      } catch (e) {
        alert(e.message);
      }
    };

    const statusOptions = [
      { value: 'all', label: 'Toutes', icon: '📋' },
      { value: 'pending', label: 'En attente', icon: '⏳' },
      { value: 'confirmed', label: 'Confirmées', icon: '✓' },
      { value: 'completed', label: 'Terminées', icon: '✓✓' },
      { value: 'cancelled', label: 'Annulées', icon: '✕' }
    ];

    const filteredBookings = computed(() => {
      if (statusFilter.value === 'all') {
        return bookings.value;
      }
      return bookings.value.filter(b => b.status === statusFilter.value);
    });

    const fetchBookings = async () => {
      loading.value = true;
      error.value = null;

      try {
        // Get user role first
        const authData = await checkAuth();
        const userId = authData.userId;
        if (!authData.isAuthenticated || !userId) {
          throw new Error('Utilisateur non authentifié');
        }

        if (userRole.value === 'TUTOR') {
          await fetchMySlots();
        }

        // Fetch bookings
        const response = await fetch(`/api/bookings?user_id=${encodeURIComponent(userId)}`, {
          credentials: 'include'
        });

        if (!response.ok) {
          throw new Error('Erreur lors du chargement des réservations');
        }

        const data = await response.json();
        bookings.value = data.sort((a, b) => 
          new Date(b.start_time) - new Date(a.start_time)
        );
      } catch (err) {
        console.error('Error fetching bookings:', err);
        error.value = err.message || 'Erreur de chargement';
      } finally {
        loading.value = false;
      }
    };

    const updateBookingStatus = async (bookingId, newStatus) => {
      if (updating.value) return;
      
      updating.value = bookingId;
      try {
        const response = await fetch(`/api/bookings/${bookingId}/status`, {
          method: 'PATCH',
          headers: { 'Content-Type': 'application/json' },
          credentials: 'include',
          body: JSON.stringify({ status: newStatus })
        });

        if (!response.ok) {
          throw new Error('Erreur lors de la mise à jour');
        }

        // Update local state
        const booking = bookings.value.find(b => b.booking_id === bookingId);
        if (booking) {
          booking.status = newStatus;
        }
      } catch (err) {
        console.error('Error updating status:', err);
        alert('Erreur lors de la mise à jour du statut');
      } finally {
        updating.value = null;
      }
    };

    const cancelBooking = async (bookingId) => {
      if (!confirm('Êtes-vous sûr de vouloir annuler cette réservation ?')) {
        return;
      }
      await updateBookingStatus(bookingId, 'cancelled');
    };

    const getStatusLabel = (status) => {
      const labels = {
        pending: 'En attente',
        confirmed: 'Confirmée',
        completed: 'Terminée',
        cancelled: 'Annulée'
      };
      return labels[status] || status;
    };

    const getStatusIcon = (status) => {
      const icons = {
        pending: '⏳',
        confirmed: '✓',
        completed: '✓✓',
        cancelled: '✕'
      };
      return icons[status] || '•';
    };

    const formatDateTime = (dateString) => {
      const date = new Date(dateString);
      return date.toLocaleString('fr-FR', {
        weekday: 'long',
        year: 'numeric',
        month: 'long',
        day: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
      });
    };

    const calculateDuration = (start, end) => {
      const startDate = new Date(start);
      const endDate = new Date(end);
      const hours = (endDate - startDate) / (1000 * 60 * 60);
      
      if (hours < 1) {
        const minutes = Math.round(hours * 60);
        return `${minutes} min`;
      }
      
      const wholeHours = Math.floor(hours);
      const minutes = Math.round((hours - wholeHours) * 60);
      
      if (minutes === 0) {
        return `${wholeHours}h`;
      }
      return `${wholeHours}h${minutes}`;
    };

    const getBookedSlotsCount = (dayKey) => {
      return (slotsByDay.value[dayKey] || []).filter(s => s.is_booked).length;
    };

    const formatDayTitle = (dayKey) => {
      const parts = dayKey.split('-');
      const date = new Date(parts[0], parseInt(parts[1]) - 1, parts[2]);
      return date.toLocaleDateString('fr-FR', { weekday: 'long', day: 'numeric', month: 'long', year: 'numeric' });
    };

    onMounted(() => {
      fetchBookings();
    });

    return {
      bookings,
      loading,
      error,
      statusFilter,
      statusOptions,
      filteredBookings,
      updating,
      userRole,
      fetchBookings,
      updateBookingStatus,
      cancelBooking,
      getStatusLabel,
      getStatusIcon,
      formatDateTime,
      calculateDuration,
      // availability
      mySlots,
      showSlotModal,
      creatingSlot,
      slotError,
      slotForm,
      timeValidationErrors,
      focusedPickerInput,
      isSlotFormValid,
      minSlotDateTime,
      lockedEndMinute,
      formatSlotDate,
      formatSlotTime,
      weekDays,
      weekLabel,
      slotsByDay,
      changeWeek,
      goToCurrentWeek,
      validateSlotTime,
      createSlot,
      deleteSlot,
      selectedDayKey,
      getBookedSlotsCount,
      formatDayTitle,
    };
  }
};
</script>

<style scoped>
.reservations-page {
  max-width: 1200px;
  margin: 0 auto;
  padding: 2rem;
}

.page-header {
  text-align: center;
  margin-bottom: 3rem;
}

.page-header h1 {
  font-size: 2.5em;
  font-weight: 700;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  background-clip: text;
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  margin-bottom: 0.5rem;
}

.subtitle {
  color: #666;
  font-size: 1.1em;
}

.filters-bar {
  display: flex;
  gap: 1rem;
  justify-content: center;
  flex-wrap: wrap;
  margin-bottom: 2rem;
}

.filter-btn {
  padding: 0.75rem 1.5rem;
  border: 2px solid #e0e0e0;
  background: white;
  border-radius: 25px;
  font-size: 1rem;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.3s;
}

.filter-btn:hover {
  border-color: #667eea;
  color: #667eea;
}

.filter-btn.active {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  border-color: transparent;
}

.loading-container,
.error-container,
.empty-state {
  text-align: center;
  padding: 4rem 2rem;
}

.spinner {
  width: 50px;
  height: 50px;
  border: 5px solid #f3f3f3;
  border-top: 5px solid #667eea;
  border-radius: 50%;
  animation: spin 1s linear infinite;
  margin: 0 auto 1rem;
}

@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}

.error-icon,
.empty-icon {
  font-size: 4em;
  margin-bottom: 1rem;
}

.empty-state h3 {
  color: #333;
  margin-bottom: 0.5rem;
}

.empty-state p {
  color: #666;
  margin-bottom: 1.5rem;
}

.bookings-count {
  text-align: center;
  font-size: 1.1em;
  color: #666;
  margin-bottom: 2rem;
  font-weight: 600;
}

.bookings-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(400px, 1fr));
  gap: 1.5rem;
}

.booking-card {
  background: white;
  border-radius: 15px;
  overflow: hidden;
  box-shadow: 0 5px 20px rgba(0, 0, 0, 0.1);
  transition: all 0.3s;
  position: relative;
}

.booking-card::before {
  content: '';
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  height: 4px;
}

.booking-card.status-pending::before {
  background: #ffc107;
}

.booking-card.status-confirmed::before {
  background: #4caf50;
}

.booking-card.status-completed::before {
  background: #2196f3;
}

.booking-card.status-cancelled::before {
  background: #f44336;
}

.booking-card:hover {
  transform: translateY(-5px);
  box-shadow: 0 10px 30px rgba(0, 0, 0, 0.15);
}

.booking-status {
  padding: 1rem 1.5rem;
  background: #f8f9ff;
  display: flex;
  justify-content: flex-end;
}

.status-badge {
  display: inline-block;
  padding: 0.5rem 1rem;
  border-radius: 20px;
  font-size: 0.9em;
  font-weight: 600;
}

.badge-pending {
  background: #fff3cd;
  color: #856404;
}

.badge-confirmed {
  background: #d4edda;
  color: #155724;
}

.badge-completed {
  background: #d1ecf1;
  color: #0c5460;
}

.badge-cancelled {
  background: #f8d7da;
  color: #721c24;
}

.booking-content {
  padding: 1.5rem;
}

.booking-header {
  display: flex;
  justify-content: space-between;
  align-items: start;
  margin-bottom: 1.5rem;
}

.booking-title {
  font-size: 1.3em;
  color: #333;
  font-weight: 700;
  flex: 1;
  margin-right: 1rem;
}

.booking-price {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  padding: 0.5rem 1rem;
  border-radius: 20px;
  font-weight: 700;
  font-size: 1.1em;
  white-space: nowrap;
}

.booking-info {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 1rem;
  margin-bottom: 1.5rem;
}

.info-item {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
}

.info-item.full-width {
  grid-column: 1 / -1;
}

.info-label {
  font-weight: 600;
  color: #667eea;
  font-size: 0.9em;
}

.info-value {
  color: #333;
  font-weight: 500;
}

.badge-subject {
  background: #f0f4ff;
  color: #667eea;
  padding: 0.25rem 0.75rem;
  border-radius: 12px;
  font-size: 0.9em;
  display: inline-block;
}

.booking-description,
.booking-notes {
  grid-column: 1 / -1;
  background: #f8f9ff;
  padding: 1rem;
  border-radius: 8px;
}

.booking-description p,
.booking-notes p {
  color: #666;
  margin: 0.5rem 0 0 0;
  line-height: 1.5;
}

.booking-actions {
  display: flex;
  gap: 0.75rem;
  flex-wrap: wrap;
  padding-top: 1rem;
  border-top: 2px solid #f0f0f0;
}

.btn {
  padding: 0.75rem 1.25rem;
  border-radius: 8px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.3s;
  text-decoration: none;
  display: inline-block;
  text-align: center;
  border: none;
  font-size: 0.95em;
}

.btn-sm {
  padding: 0.5rem 1rem;
  font-size: 0.9em;
}

.btn-primary {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
}

.btn-primary:hover {
  transform: translateY(-2px);
  box-shadow: 0 5px 15px rgba(102, 126, 234, 0.3);
}

.btn-success {
  background: #4caf50;
  color: white;
}

.btn-success:hover {
  background: #45a049;
  transform: translateY(-2px);
}

.btn-danger {
  background: #f44336;
  color: white;
}

.btn-danger:hover {
  background: #da190b;
  transform: translateY(-2px);
}

.btn-outline {
  background: white;
  border: 2px solid #667eea;
  color: #667eea;
}

.btn-outline:hover {
  background: #667eea;
  color: white;
}

.btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

/* Responsive */
@media (max-width: 768px) {
  .reservations-page {
    padding: 1rem;
  }

  .page-header h1 {
    font-size: 2em;
  }

  .bookings-grid {
    grid-template-columns: 1fr;
  }

  .booking-info {
    grid-template-columns: 1fr;
  }

  .booking-actions {
    flex-direction: column;
  }

  .btn {
    width: 100%;
  }
}

/* ══════════════════════════════════════════════
   AVAILABILITY SECTION
   ══════════════════════════════════════════════ */
.availability-section {
  background: white;
  border-radius: 15px;
  padding: 1.5rem 2rem;
  margin-bottom: 2.5rem;
  box-shadow: 0 5px 20px rgba(0, 0, 0, 0.07);
}

.availability-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 1.25rem;
  flex-wrap: wrap;
  gap: 1rem;
}

.availability-header h2 {
  font-size: 1.4em;
  color: #333;
  flex: 1;
  min-width: 200px;
}

.slots-empty-msg {
  color: #888;
  font-style: italic;
  padding: 0.75rem 0;
}

.calendar-toolbar {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  flex-wrap: wrap;
  margin-bottom: 1rem;
}

.week-label {
  flex: 1;
  min-width: 220px;
  font-weight: 700;
  color: #334155;
  text-align: center;
}

.week-calendar {
  display: grid;
  grid-template-columns: repeat(7, 1fr);
  gap: 0.75rem;
  width: 100%;
}

.day-column {
  background: #f8fafc;
  border-radius: 10px;
  padding: 1rem;
  border: 2px solid #e2e8f0;
  cursor: pointer;
  transition: all 0.3s ease;
  min-height: 120px;
  display: flex;
  flex-direction: column;
  position: relative;
}

.day-column:hover {
  background: #f1f5f9;
  border-color: #667eea;
  box-shadow: 0 4px 12px rgba(102, 126, 234, 0.15);
  transform: translateY(-2px);
}

.day-column.has-slots {
  background: linear-gradient(135deg, #f0f4ff 0%, #faf8ff 100%);
  border-color: #667eea;
}

.day-header {
  padding-bottom: 0.75rem;
  border-bottom: 1px solid #cbd5e1;
  margin-bottom: 0.75rem;
}

.day-name {
  font-size: 0.95em;
  font-weight: 700;
  text-transform: capitalize;
  color: #1e293b;
}

.day-date {
  font-size: 0.85em;
  color: #64748b;
  margin-top: 0.2rem;
}

.day-content {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
}

.day-indicator {
  text-align: center;
}

.slots-count {
  font-size: 1.3em;
  font-weight: 700;
  color: #667eea;
}

.booked-count {
  font-size: 0.9em;
  color: #f59e0b;
  margin-top: 0.25rem;
}

.day-empty {
  font-size: 0.9em;
  color: #94a3b8;
  text-align: center;
}

.day-slots-modal {
  max-height: 400px;
  overflow-y: auto;
}

.no-slots-msg {
  text-align: center;
  padding: 1.5rem 0;
  color: #64748b;
}

.slot-item {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  padding: 0.75rem;
  margin-bottom: 0.5rem;
  border-radius: 8px;
  background: #f8fafc;
  border: 1px solid #e2e8f0;
}

.slot-item.available {
  background: #f1fdf2;
  border-color: #4caf50;
}

.slot-item.booked {
  background: #fffdf0;
  border-color: #f59e0b;
}

.slot-time {
  font-weight: 600;
  color: #1e293b;
  flex: 1;
}

.slot-status {
  display: flex;
  align-items: center;
}

@media (max-width: 1024px) {
  .week-calendar {
    grid-template-columns: repeat(auto-fit, minmax(100px, 1fr));
    gap: 0.5rem;
  }

  .day-column {
    padding: 0.75rem;
    min-height: 100px;
  }

  .day-name {
    font-size: 0.85em;
  }

  .day-date {
    font-size: 0.75em;
  }

  .slots-count {
    font-size: 1.1em;
  }
}

@media (max-width: 768px) {
  .week-calendar {
    grid-template-columns: repeat(auto-fit, minmax(80px, 1fr));
    gap: 0.4rem;
  }

  .day-column {
    padding: 0.5rem;
    min-height: 90px;
  }

  .day-header {
    padding-bottom: 0.5rem;
    margin-bottom: 0.5rem;
  }

  .day-name {
    font-size: 0.75em;
  }

  .day-date {
    font-size: 0.65em;
  }

  .slots-count {
    font-size: 1em;
  }

  .booked-count {
    font-size: 0.8em;
  }

  .calendar-toolbar {
    flex-direction: column;
    align-items: stretch;
  }

  .week-label {
    text-align: center;
  }
}

@media (max-width: 480px) {
  .week-calendar {
    grid-template-columns: repeat(2, 1fr);
    gap: 0.5rem;
  }

  .day-column {
    min-height: 85px;
  }

  .day-name {
    font-size: 0.7em;
  }
}

.my-slot-card {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  padding: 0.75rem 1rem;
  border-radius: 10px;
  border: 2px solid #e0e0e0;
  background: #fafafa;
  margin-bottom: 0;
}

.my-slot-card.available {
  border-color: #4caf50;
  background: #f1fdf2;
}

.my-slot-card.booked {
  border-color: #ffc107;
  background: #fffdf0;
  opacity: 0.8;
}

.slot-status-dot {
  width: 10px;
  height: 10px;
  border-radius: 50%;
  flex-shrink: 0;
  display: none;
}

.my-slot-card.available .slot-status-dot { background: #4caf50; }
.my-slot-card.booked   .slot-status-dot { background: #ffc107; }

.slot-info {
  flex: 1;
}

.slot-date-label {
  font-weight: 600;
  font-size: 0.85em;
  color: #555;
  text-transform: capitalize;
}

.slot-time-label {
  font-weight: 700;
  font-size: 1em;
  color: #333;
}

.slot-badge {
  padding: 0.2rem 0.6rem;
  border-radius: 12px;
  font-size: 0.78em;
  font-weight: 700;
  white-space: nowrap;
}

.badge-available {
  background: #d4edda;
  color: #155724;
}

.badge-booked {
  background: #fff3cd;
  color: #856404;
}

.btn-icon-danger {
  background: none;
  border: none;
  color: #f44336;
  font-size: 1.1em;
  cursor: pointer;
  padding: 0.25rem 0.5rem;
  border-radius: 4px;
  transition: background 0.2s;
  flex-shrink: 0;
}

.btn-icon-danger:hover {
  background: #fdecea;
}

/* Small modal */
.modal-overlay {
  position: fixed;
  inset: 0;
  background: rgba(0,0,0,0.45);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 999;
}

.modal {
  background: white;
  border-radius: 12px;
  padding: 1.5rem 2rem;
  width: 100%;
  max-width: 480px;
  box-shadow: 0 20px 60px rgba(0,0,0,0.2);
  margin: 1rem;
}

.modal-sm {
  max-width: 380px;
}

@media (max-width: 480px) {
  .modal {
    padding: 1.25rem 1.5rem;
    margin: 0.5rem;
  }
  
  .modal-sm {
    max-width: 100%;
  }
}

.modal-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 1.25rem;
}

.modal-header h3 {
  font-size: 1.15em;
  color: #333;
}

.close-btn {
  background: none;
  border: none;
  font-size: 1.5em;
  cursor: pointer;
  color: #888;
  line-height: 1;
}

.modal-form .form-group {
  margin-bottom: 1rem;
}

.modal-form label {
  display: block;
  font-weight: 600;
  color: #555;
  margin-bottom: 0.35rem;
  font-size: 0.9em;
}

.modal-form input {
  width: 100%;
  padding: 0.6rem 0.85rem;
  border: 2px solid #e0e0e0;
  border-radius: 8px;
  font-size: 0.95em;
  box-sizing: border-box;
  text-align: center;
}

.modal-form input:focus {
  outline: none;
  border-color: #667eea;
}

.modal-actions {
  display: flex;
  gap: 0.75rem;
  justify-content: flex-end;
  margin-top: 1.25rem;
}

.error-msg {
  background: #fdecea;
  color: #b71c1c;
  padding: 0.6rem 1rem;
  border-radius: 8px;
  margin-bottom: 1rem;
  font-size: 0.9em;
}

.error-hint {
  display: block;
  color: #d32f2f;
  font-size: 0.8em;
  margin-top: 0.25rem;
}

.help-text {
  font-size: 0.9em;
  color: #666;
  margin: 0.75rem 0;
  padding: 0.5rem 0.75rem;
  background: #f0f4ff;
  border-radius: 6px;
}
</style>
