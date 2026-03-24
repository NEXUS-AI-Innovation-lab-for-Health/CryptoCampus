<template>
  <div class="page-container">
    <div class="container">
      <header class="page-header">
        <h1>?? Mes Cours</h1>
        <p class="subtitle">G�rez les annonces que vous avez publi�es</p>
      </header>

      <div v-if="isLoading" class="loading-state">Chargement de vos annonces...</div>
      
      <div v-else-if="myListings.length === 0" class="empty-state">
        <p>Vous n'avez publi� aucune annonce pour le moment.</p>
        <router-link to="/create_request" class="btn btn-primary" style="margin-top: 20px; display: inline-block;">
          Cr�er ma premi�re annonce
        </router-link>
      </div>

      <div v-else class="listings-grid">
        <div v-for="listing in myListings" :key="listing.id" class="listing-card">
          <div class="card-header">
            <h3>{{ listing.title }}</h3>
            <span class="price-badge">{{ listing.price }} CC</span>
          </div>
          
          <div class="card-body">
            <p class="description">{{ listing.description }}</p>
            
            <div class="meta-info">
              <span class="tag subject">?? {{ listing.subject || 'G�n�ral' }}</span>
              <span class="tag level">?? {{ listing.level || 'Tous niveaux' }}</span>
            </div>
            
            <p class="score" style="margin-top: 15px; color: #888; font-size: 0.9em;">
              Publi�e le {{ formatDate(listing.created_at) }}
            </p>
          </div>
          
          <div class="card-footer" style="display: flex; gap: 10px; margin-top: 15px;">
             <!-- <button class="btn btn-secondary" @click="editListing(listing)">Modifier</button> -->
             <button class="btn btn-delete" style="background:#e74c3c; color:white; border:none; padding:8px 12px; border-radius:4px; cursor:pointer;" @click="deleteListing(listing.id)">Supprimer</button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'

const myListings = ref([])
const isLoading = ref(true)

const fetchMyListings = async () => {
  try {
    isLoading.value = true
    const res = await fetch('/api/listings/mine', { credentials: 'include' })
    if (res.ok) {
      const data = await res.json()
      myListings.value = data.listings || []
    }
  } catch (err) {
    console.error('Erreur r�cup�ration annonces:', err)
  } finally {
    isLoading.value = false
  }
}

const deleteListing = async (id) => {
  if (!confirm('Voulez-vous vraiment supprimer cette annonce ?')) return;

  try {
    const res = await fetch('/api/listings/' + id, {
      method: 'DELETE',
      credentials: 'include'
    })
    if (res.ok) {
      myListings.value = myListings.value.filter(l => l.id !== id)
    } else {
      alert('Erreur lors de la suppression')
    }
  } catch (err) {
    console.error('Erreur suppression:', err)
  }
}

const formatDate = (dateStr) => {
  if (!dateStr) return 'Inconnue'
  return new Date(dateStr).toLocaleDateString('fr-FR', {
    day: 'numeric', month: 'long', year: 'numeric'
  })
}

onMounted(() => {
  fetchMyListings()
})
</script>

<style scoped>
.page-container {
  padding: 40px 20px;
  background-color: #f8f9fa;
  min-height: calc(100vh - 60px);
}
.container {
  max-width: 1200px;
  margin: 0 auto;
}
.page-header {
  text-align: center;
  margin-bottom: 40px;
}
.page-header h1 {
  font-size: 2.5em;
  color: #2c3e50;
  margin-bottom: 10px;
}
.subtitle {
  color: #7f8c8d;
  font-size: 1.2em;
}
.listings-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
  gap: 25px;
}
.listing-card {
  background: white;
  border-radius: 12px;
  padding: 25px;
  box-shadow: 0 4px 6px rgba(0,0,0,0.05);
  transition: transform 0.2s, box-shadow 0.2s;
  display: flex;
  flex-direction: column;
}
.listing-card:hover {
  transform: translateY(-5px);
  box-shadow: 0 8px 15px rgba(0,0,0,0.1);
}
.card-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 15px;
}
.card-header h3 {
  margin: 0;
  font-size: 1.4em;
  color: #2c3e50;
}
.price-badge {
  background: #e8f5e9;
  color: #2ecc71;
  padding: 5px 12px;
  border-radius: 20px;
  font-weight: bold;
  font-size: 1.1em;
}
.description {
  color: #555;
  line-height: 1.6;
  margin-bottom: 20px;
  flex-grow: 1;
}
.meta-info {
  display: flex;
  gap: 10px;
  flex-wrap: wrap;
}
.tag {
  background: #f1f2f6;
  padding: 5px 10px;
  border-radius: 6px;
  font-size: 0.9em;
  color: #2c3e50;
}
.loading-state, .empty-state {
  text-align: center;
  padding: 40px;
  background: white;
  border-radius: 12px;
  color: #7f8c8d;
  font-size: 1.2em;
}
</style>
