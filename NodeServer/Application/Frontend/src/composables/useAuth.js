import { ref, computed } from 'vue'

// État partagé (singleton) : tous les composants qui appellent useAuth() lisent/écrivent
// les mêmes refs, évitant de dupliquer la logique "vérifier qui est connecté" sur
// chaque page (App.vue, Home.vue, Reservations.vue, Agenda.vue s'en servaient
// chacune à leur façon avant ce composable).
const isLogged = ref(null)
const userId = ref('')
const userRole = ref('')
const userEmail = ref('')
const userAvatarUrl = ref('')

async function checkAuth() {
  try {
    const response = await fetch('/api/check-auth', { credentials: 'include' })
    const data = await response.json()

    isLogged.value = !!data.isAuthenticated
    userId.value = data.userId || ''
    userRole.value = data.role || ''
    userEmail.value = data.email || ''
    userAvatarUrl.value = data.avatarUrl || ''

    return data
  } catch (error) {
    console.error('Auth check failed:', error)
    isLogged.value = false
    userId.value = ''
    userRole.value = ''
    userEmail.value = ''
    userAvatarUrl.value = ''
    return { isAuthenticated: false }
  }
}

export function useAuth() {
  const isTutor = computed(() => userRole.value === 'TUTOR')

  return {
    isLogged,
    userId,
    userRole,
    userEmail,
    userAvatarUrl,
    isTutor,
    checkAuth,
  }
}
