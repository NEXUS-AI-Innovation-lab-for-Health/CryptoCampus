<template>
  <div class="lang-switcher" v-click-outside="closeMenu">
    <button
      type="button"
      class="lang-switcher-btn"
      :aria-label="t('nav.chooseLanguage')"
      @click="isOpen = !isOpen"
    >
      <FlagIcon :code="currentLocale.flag" :label="currentLocale.label" />
    </button>

    <ul v-if="isOpen" class="lang-menu">
      <li v-for="locale in SUPPORTED_LOCALES" :key="locale.code">
        <button
          type="button"
          class="lang-option"
          :class="{ active: locale.code === current }"
          @click="selectLocale(locale.code)"
        >
          <FlagIcon :code="locale.flag" :label="locale.label" />
          <span>{{ locale.label }}</span>
        </button>
      </li>
    </ul>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { useI18n } from 'vue-i18n'
import { SUPPORTED_LOCALES, setLocale } from '@/i18n'
import FlagIcon from './FlagIcon.vue'

const { t, locale } = useI18n()
const isOpen = ref(false)

const current = computed(() => locale.value)
const currentLocale = computed(
  () => SUPPORTED_LOCALES.find((l) => l.code === current.value) || SUPPORTED_LOCALES[0]
)

const selectLocale = (code) => {
  setLocale(code)
  isOpen.value = false
}

const closeMenu = () => {
  isOpen.value = false
}

// Petite directive locale "cliquer en dehors pour fermer", pour ne pas dépendre
// d'une librairie externe pour un besoin aussi simple.
const vClickOutside = {
  mounted(el, binding) {
    el.__clickOutsideHandler__ = (event) => {
      if (!el.contains(event.target)) binding.value()
    }
    document.addEventListener('click', el.__clickOutsideHandler__)
  },
  unmounted(el) {
    document.removeEventListener('click', el.__clickOutsideHandler__)
  },
}
</script>

<style scoped>
.lang-switcher {
  position: relative;
}

.lang-switcher-btn {
  background: rgba(255, 255, 255, 0.08);
  border: 1px solid rgba(255, 255, 255, 0.2);
  border-radius: 6px;
  padding: 0.4rem 0.55rem;
  cursor: pointer;
  display: flex;
  align-items: center;
  transition: background 0.2s;
}

.lang-switcher-btn:hover {
  background: rgba(255, 255, 255, 0.18);
}

.lang-menu {
  position: absolute;
  top: calc(100% + 0.5rem);
  right: 0;
  background: white;
  border-radius: 10px;
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.2);
  list-style: none;
  padding: 0.4rem;
  margin: 0;
  min-width: 170px;
  z-index: 1100;
}

.lang-option {
  display: flex;
  align-items: center;
  gap: 0.6rem;
  width: 100%;
  padding: 0.55rem 0.7rem;
  border: none;
  background: none;
  border-radius: 6px;
  cursor: pointer;
  font-size: 0.9rem;
  color: #2c3e50;
  text-align: left;
  transition: background 0.15s;
}

.lang-option:hover {
  background: #f0f4ff;
}

.lang-option.active {
  background: #e8edff;
  font-weight: 600;
  color: #3498db;
}
</style>
