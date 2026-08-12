import { createI18n } from 'vue-i18n'
import fr from './locales/fr.json'
import en from './locales/en.json'
import es from './locales/es.json'
import pt from './locales/pt.json'
import de from './locales/de.json'
import ja from './locales/ja.json'
import zh from './locales/zh.json'

// Langues gérées par le site, dans l'ordre d'affichage du sélecteur.
// `flag` référence une icône définie dans src/components/FlagIcon.vue
// (certains drapeaux sont composites : EN = Royaume-Uni + États-Unis,
// PT = Portugal + Brésil, comme demandé).
export const SUPPORTED_LOCALES = [
  { code: 'fr', label: 'Français', flag: 'fr' },
  { code: 'en', label: 'English', flag: 'en' },
  { code: 'es', label: 'Español', flag: 'es' },
  { code: 'pt', label: 'Português', flag: 'pt' },
  { code: 'de', label: 'Deutsch', flag: 'de' },
  { code: 'ja', label: '日本語', flag: 'ja' },
  { code: 'zh', label: '中文', flag: 'zh' },
]

export const DEFAULT_LOCALE = 'fr'
const STORAGE_KEY = 'cryptocampus-locale'

// Devine la langue à utiliser : préférence enregistrée manuellement > langue du
// navigateur (si supportée) > français par défaut.
function detectLocale() {
  const stored = localStorage.getItem(STORAGE_KEY)
  if (stored && SUPPORTED_LOCALES.some((l) => l.code === stored)) {
    return stored
  }

  const browserLanguages = navigator.languages && navigator.languages.length > 0
    ? navigator.languages
    : [navigator.language]

  for (const browserLang of browserLanguages) {
    const short = browserLang.slice(0, 2).toLowerCase()
    const match = SUPPORTED_LOCALES.find((l) => l.code === short)
    if (match) return match.code
  }

  return DEFAULT_LOCALE
}

export const i18n = createI18n({
  legacy: false,
  globalInjection: true,
  locale: detectLocale(),
  fallbackLocale: DEFAULT_LOCALE,
  messages: { fr, en, es, pt, de, ja, zh },
})

// Change la langue active et mémorise le choix (prioritaire sur la détection navigateur)
export function setLocale(code) {
  if (!SUPPORTED_LOCALES.some((l) => l.code === code)) return
  i18n.global.locale.value = code
  localStorage.setItem(STORAGE_KEY, code)
  document.documentElement.setAttribute('lang', code)
}

document.documentElement.setAttribute('lang', i18n.global.locale.value)
