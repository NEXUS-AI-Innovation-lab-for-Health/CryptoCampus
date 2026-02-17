<template>
  <div class="container">
    <header class="page-header">
      <h2>Requêtes d'aide disponibles</h2>
      <div class="filters">
        <select v-model="subjectFilter">
          <option value="">Toutes les matières</option>
          <option value="math">Mathématiques</option>
          <option value="physics">Physique</option>
          <option value="chemistry">Chimie</option>
          <option value="programming">Programmation</option>
          <option value="french">Français</option>
          <option value="english">Anglais</option>
        </select>
        <select v-model="sortFilter">
          <option value="recent">Plus récentes</option>
          <option value="reward">Récompense</option>
        </select>
      </div>
    </header>

    <div id="requestsList" class="requests-list">
      <div v-if="requests.length === 0" class="empty-state">
        <p>Aucune requête disponible pour le moment</p>
      </div>
      <div v-for="request in filteredRequests" :key="request.id" class="request-card">
        <h3>{{ request.title }}</h3>
        <p>{{ request.description }}</p>
        <div class="request-meta">
          <span class="subject">{{ request.subject }}</span>
          <span class="reward">💰 {{ request.reward }} coins</span>
        </div>
      </div>
    </div>

    <div v-if="requests.length === 0" class="empty-state">
      <p>Aucune requête disponible pour le moment</p>
    </div>
  </div>
</template>

<script>
import { ref, computed, onMounted } from 'vue'

export default {
  name: 'RequestsList',
  setup() {
    const requests = ref([])
    const subjectFilter = ref('')
    const sortFilter = ref('recent')

    const filteredRequests = computed(() => {
      let filtered = requests.value

      if (subjectFilter.value) {
        filtered = filtered.filter(r => r.subject === subjectFilter.value)
      }

      if (sortFilter.value === 'recent') {
        filtered.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt))
      } else if (sortFilter.value === 'reward') {
        filtered.sort((a, b) => b.reward - a.reward)
      }

      return filtered
    })

    const loadRequests = async () => {
      try {
        const response = await fetch('/api/requests')
        if (response.ok) {
          requests.value = await response.json()
        }
      } catch (error) {
        console.error('Failed to load requests:', error)
        // Mock data for development
        requests.value = []
      }
    }

    onMounted(() => {
      loadRequests()
    })

    return {
      requests,
      subjectFilter,
      sortFilter,
      filteredRequests,
    }
  }
}
</script>

<style scoped>
.container {
  max-width: 1200px;
  margin: 0 auto;
  padding: 2rem;
}

.page-header {
  margin-bottom: 2rem;
}

.page-header h2 {
  margin-bottom: 1rem;
  color: #2c3e50;
}

.filters {
  display: flex;
  gap: 1rem;
}

.filters select {
  padding: 0.5rem 1rem;
  border: 1px solid #bdc3c7;
  border-radius: 4px;
  font-size: 1rem;
}

.requests-list {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
  gap: 1rem;
}

.request-card {
  background: white;
  padding: 1.5rem;
  border-radius: 8px;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
  transition: transform 0.3s, box-shadow 0.3s;
}

.request-card:hover {
  transform: translateY(-4px);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
}

.request-card h3 {
  margin-bottom: 0.5rem;
  color: #2c3e50;
}

.request-card p {
  color: #7f8c8d;
  margin-bottom: 1rem;
  font-size: 0.95rem;
}

.request-meta {
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-size: 0.9rem;
}

.subject {
  background-color: #ecf0f1;
  padding: 0.25rem 0.75rem;
  border-radius: 20px;
  color: #2c3e50;
}

.reward {
  color: #27ae60;
  font-weight: bold;
}

.empty-state {
  text-align: center;
  padding: 2rem;
  color: #7f8c8d;
}
</style>
