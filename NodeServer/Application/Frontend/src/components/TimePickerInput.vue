<template>
  <div class="time-picker-wrapper">
    <!-- Display area with button to open picker -->
    <div class="time-picker-display">
      <input 
        type="text"
        class="time-display-input"
        :value="displayValue"
        @click="showPicker = !showPicker"
        @focus="showPicker = true"
        readonly
        :placeholder="placeholder"
        :class="{ 'has-error': hasError }"
      />
      <button 
        type="button"
        class="time-picker-toggle-btn"
        @click="showPicker = !showPicker"
        title="Ouvrir le sélecteur d'heure"
      >
        📅
      </button>
    </div>

    <!-- Picker dropdown -->
    <transition name="fade">
      <div v-if="showPicker" class="time-picker-dropdown">
        <!-- Date selector -->
        <div class="picker-section">
          <label class="picker-label">📅 Date</label>
          <input 
            v-model="localDate" 
            type="date"
            class="date-input"
          />
        </div>

        <!-- Time selector -->
        <div class="time-inputs-row">
          <!-- Hours -->
          <div class="picker-section picker-time">
            <label class="picker-label">Heure</label>
            <div class="number-input-wrapper">
              <button 
                type="button"
                class="spinner-btn up"
                @click="decrementHour"
                title="Diminuer l'heure"
              >▲</button>
              <input 
                v-model.number="localHour" 
                type="number"
                min="0"
                max="23"
                class="hour-input"
                @change="validateHour"
              />
              <button 
                type="button"
                class="spinner-btn down"
                @click="incrementHour"
                title="Augmenter l'heure"
              >▼</button>
            </div>
            <div class="input-hint">{{ localHour.toString().padStart(2, '0') }}</div>
          </div>

          <!-- Minutes -->
          <div class="picker-section picker-time">
            <label class="picker-label">Minutes</label>
            <div class="minute-selector">
              <button 
                type="button"
                class="minute-btn"
                :class="{ active: localMinute === 0 }"
                @click="localMinute = 0"
              >
                00
              </button>
              <button 
                type="button"
                class="minute-btn"
                :class="{ active: localMinute === 30 }"
                @click="localMinute = 30"
              >
                30
              </button>
            </div>
            <div class="input-hint">{{ localMinute.toString().padStart(2, '0') }}</div>
          </div>
        </div>

        <!-- Time preview -->
        <div class="time-preview">
          <strong>📍 {{ previewDateTime }}</strong>
        </div>

        <!-- Actions -->
        <div class="picker-actions">
          <button 
            type="button"
            class="btn btn-secondary btn-sm"
            @click="closePicker"
          >
            Annuler
          </button>
          <button 
            type="button"
            class="btn btn-primary btn-sm"
            @click="confirmSelection"
          >
            ✓ Valider
          </button>
        </div>
      </div>
    </transition>
  </div>
</template>

<script setup>
import { ref, computed, watch } from 'vue'

const props = defineProps({
  modelValue: {
    type: String,
    default: ''
  },
  minDateTime: {
    type: String,
    default: ''
  },
  placeholder: {
    type: String,
    default: 'Sélectionner date et heure'
  },
  hasError: {
    type: Boolean,
    default: false
  }
})

const emit = defineEmits(['update:modelValue'])

const showPicker = ref(false)
const localDate = ref('')
const localHour = ref(0)
const localMinute = ref(0)

// Initialize from modelValue
watch(() => props.modelValue, (newVal) => {
  if (newVal) {
    const dt = new Date(newVal)
    localDate.value = newVal.split('T')[0]
    localHour.value = dt.getHours()
    localMinute.value = dt.getMinutes()
  }
})

// Set initial min date if provided
watch(() => props.minDateTime, (newVal) => {
  if (newVal && !localDate.value) {
    localDate.value = newVal.split('T')[0]
  }
})

const displayValue = computed(() => {
  if (!props.modelValue) return ''
  const dt = new Date(props.modelValue)
  return dt.toLocaleString('fr-FR', {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  })
})

const previewDateTime = computed(() => {
  if (!localDate.value) return 'Date non sélectionnée'
  const dt = new Date(`${localDate.value}T${localHour.value.toString().padStart(2, '0')}:${localMinute.value.toString().padStart(2, '0')}`)
  return dt.toLocaleString('fr-FR', {
    weekday: 'long',
    day: 'numeric',
    month: 'long',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  })
})

const incrementHour = () => {
  localHour.value = (localHour.value + 1) % 24
}

const decrementHour = () => {
  localHour.value = localHour.value === 0 ? 23 : localHour.value - 1
}

const validateHour = () => {
  if (localHour.value < 0) localHour.value = 0
  if (localHour.value > 23) localHour.value = 23
}

const confirmSelection = () => {
  if (!localDate.value) {
    alert('Veuillez sélectionner une date')
    return
  }
  const dateTimeLocal = `${localDate.value}T${localHour.value.toString().padStart(2, '0')}:${localMinute.value.toString().padStart(2, '0')}`
  emit('update:modelValue', dateTimeLocal)
  closePicker()
}

const closePicker = () => {
  showPicker.value = false
}
</script>

<style scoped>
.time-picker-wrapper {
  position: relative;
  width: 100%;
}

.time-picker-display {
  display: flex;
  gap: 8px;
  align-items: center;
}

.time-display-input {
  flex: 1;
  padding: 10px 12px;
  border: 2px solid #ddd;
  border-radius: 8px;
  font-size: 14px;
  background: white;
  cursor: pointer;
  transition: all 0.2s ease;
}

.time-display-input:hover {
  border-color: #0066cc;
}

.time-display-input:focus {
  outline: none;
  border-color: #0066cc;
  box-shadow: 0 0 0 3px rgba(0, 102, 204, 0.1);
}

.time-display-input.has-error {
  border-color: #dc3545;
  background-color: #fff5f5;
}

.time-picker-toggle-btn {
  padding: 10px 12px;
  border: 2px solid #ddd;
  border-radius: 8px;
  background: white;
  cursor: pointer;
  font-size: 16px;
  transition: all 0.2s ease;
}

.time-picker-toggle-btn:hover {
  border-color: #0066cc;
  background: #f0f7ff;
}

.time-picker-dropdown {
  position: absolute;
  top: 100%;
  left: 0;
  right: 0;
  margin-top: 8px;
  background: white;
  border: 2px solid #0066cc;
  border-radius: 12px;
  padding: 16px;
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.15);
  z-index: 1000;
  min-width: 320px;
}

.picker-section {
  margin-bottom: 16px;
}

.picker-label {
  display: block;
  font-weight: 600;
  margin-bottom: 8px;
  color: #333;
  font-size: 14px;
}

.date-input {
  width: 100%;
  padding: 10px 12px;
  border: 2px solid #ddd;
  border-radius: 8px;
  font-size: 14px;
  font-family: inherit;
  transition: border 0.2s ease;
}

.date-input:focus {
  outline: none;
  border-color: #0066cc;
}

.time-inputs-row {
  display: flex;
  gap: 16px;
  margin-bottom: 16px;
}

.picker-time {
  flex: 1;
  margin-bottom: 0;
}

.number-input-wrapper {
  display: flex;
  flex-direction: column;
  align-items: center;
}

.hour-input {
  width: 70px;
  padding: 8px;
  border: 2px solid #ddd;
  border-radius: 8px;
  font-size: 20px;
  font-weight: bold;
  text-align: center;
  font-family: 'Courier New', monospace;
  transition: border 0.2s ease;
}

.hour-input:focus {
  outline: none;
  border-color: #0066cc;
}

.spinner-btn {
  width: 40px;
  height: 28px;
  padding: 0;
  border: 2px solid #ddd;
  border-radius: 6px;
  background: white;
  cursor: pointer;
  font-size: 14px;
  font-weight: bold;
  color: #666;
  transition: all 0.2s ease;
}

.spinner-btn:hover {
  background: #f0f7ff;
  border-color: #0066cc;
  color: #0066cc;
}

.spinner-btn.up {
  border-bottom: none;
  border-radius: 6px 6px 0 0;
  margin-bottom: -2px;
}

.spinner-btn.down {
  border-top: none;
  border-radius: 0 0 6px 6px;
  margin-top: -2px;
}

.input-hint {
  font-size: 12px;
  color: #999;
  margin-top: 4px;
  font-weight: bold;
  font-family: 'Courier New', monospace;
}

.minute-selector {
  display: flex;
  gap: 8px;
}

.minute-btn {
  flex: 1;
  padding: 12px;
  border: 2px solid #ddd;
  border-radius: 8px;
  background: white;
  cursor: pointer;
  font-size: 16px;
  font-weight: bold;
  font-family: 'Courier New', monospace;
  transition: all 0.2s ease;
}

.minute-btn:hover {
  border-color: #0066cc;
  background: #f0f7ff;
}

.minute-btn.active {
  background: #0066cc;
  color: white;
  border-color: #0066cc;
}

.time-preview {
  background: #f0f7ff;
  border-left: 4px solid #0066cc;
  padding: 12px;
  border-radius: 6px;
  margin-bottom: 16px;
  font-size: 13px;
  color: #333;
}

.picker-actions {
  display: flex;
  gap: 8px;
  justify-content: flex-end;
  padding-top: 8px;
  border-top: 1px solid #eee;
}

.btn {
  padding: 8px 16px;
  border: none;
  border-radius: 6px;
  cursor: pointer;
  font-size: 14px;
  font-weight: 600;
  transition: all 0.2s ease;
}

.btn-primary {
  background: #0066cc;
  color: white;
}

.btn-primary:hover {
  background: #0052a3;
}

.btn-secondary {
  background: #f0f0f0;
  color: #333;
}

.btn-secondary:hover {
  background: #e0e0e0;
}

.btn-sm {
  padding: 6px 12px;
  font-size: 13px;
}

/* Fade transition */
.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.2s ease, transform 0.2s ease;
}

.fade-enter-from,
.fade-leave-to {
  opacity: 0;
  transform: translateY(-8px);
}
</style>
