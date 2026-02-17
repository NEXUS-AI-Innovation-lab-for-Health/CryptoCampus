<template>
  <div class="logout-container">
    <div class="card logout-card">
      <h1>Déconnexion</h1>
      <p class="subtitle">Êtes-vous sûr de vouloir vous déconnecter ?</p>

      <div class="logout-actions">
        <button @click="confirmLogout" class="btn-logout-confirm" :disabled="isLoading">
          {{ isLoading ? 'Déconnexion en cours...' : 'Confirmer la déconnexion' }}
        </button>
        <router-link to="/home" class="btn-cancel">Annuler</router-link>
      </div>
    </div>
  </div>
</template>

<script>
import { ref } from 'vue'
import { useRouter } from 'vue-router'

export default {
  name: 'Logout',
  setup() {
    const router = useRouter()
    const isLoading = ref(false)

    const confirmLogout = async () => {
      isLoading.value = true

      try {
        const response = await fetch('/api/logout', {
          method: 'POST',
          credentials: 'include',
        })

        if (response.ok) {
          router.push('/home')
        }
      } catch (error) {
        console.error('Logout failed:', error)
        isLoading.value = false
      }
    }

    return {
      confirmLogout,
      isLoading,
    }
  }
}
</script>

<style scoped>
.logout-container {
  display: flex;
  justify-content: center;
  align-items: center;
  min-height: calc(100vh - 80px);
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  padding: 2rem;
}

.card {
  background: white;
  padding: 2rem;
  border-radius: 8px;
  box-shadow: 0 10px 40px rgba(0, 0, 0, 0.2);
  max-width: 400px;
  width: 100%;
  text-align: center;
}

.card h1 {
  color: #2c3e50;
  margin-bottom: 0.5rem;
}

.subtitle {
  color: #7f8c8d;
  margin-bottom: 2rem;
}

.logout-actions {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.btn-logout-confirm,
.btn-cancel {
  padding: 0.75rem 1.5rem;
  border: none;
  border-radius: 4px;
  font-size: 1rem;
  cursor: pointer;
  text-decoration: none;
  display: block;
  transition: background-color 0.3s;
}

.btn-logout-confirm {
  background-color: #e74c3c;
  color: white;
}

.btn-logout-confirm:hover:not(:disabled) {
  background-color: #c0392b;
}

.btn-logout-confirm:disabled {
  opacity: 0.6;
}

.btn-cancel {
  background-color: #ecf0f1;
  color: #2c3e50;
}

.btn-cancel:hover {
  background-color: #bdc3c7;
}
</style>
