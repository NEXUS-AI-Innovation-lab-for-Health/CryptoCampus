<template>
  <div class="container">
    <header class="page-header">
      <div>
        <h2>Boutique de récompenses</h2>
        <p class="balance-display">Votre solde: <span id="userBalance">{{ userBalance }}</span> 💰</p>
      </div>
      <div class="filters">
        <select v-model="categoryFilter">
          <option value="">Toutes les catégories</option>
          <option value="giftcard">Cartes cadeaux</option>
          <option value="discount">Réductions</option>
          <option value="premium">Avantages premium</option>
          <option value="merchandise">Goodies</option>
        </select>
      </div>
    </header>

    <div id="productsList" class="products-list">
      <div v-if="filteredProducts.length === 0" class="empty-state">
        <p>Aucun produit disponible</p>
      </div>
      <div v-for="product in filteredProducts" :key="product.id" class="product-card">
        <div class="product-image">{{ product.emoji }}</div>
        <h3>{{ product.name }}</h3>
        <p>{{ product.description }}</p>
        <div class="product-footer">
          <span class="price">{{ product.price }} 💰</span>
          <button
            @click="openPurchaseModal(product)"
            :disabled="userBalance < product.price"
            class="btn-buy"
          >
            Acheter
          </button>
        </div>
      </div>
    </div>

    <!-- Purchase Modal -->
    <div v-if="selectedProduct" id="purchaseModal" class="modal">
      <div class="modal-content">
        <span class="close" @click="selectedProduct = null">&times;</span>
        <h3>Confirmer l'achat</h3>
        <div id="modalProductInfo" class="product-info">
          <p><strong>{{ selectedProduct.name }}</strong></p>
          <p>{{ selectedProduct.description }}</p>
          <p class="price">Prix: {{ selectedProduct.price }} 💰</p>
        </div>
        <div class="modal-actions">
          <button @click="confirmPurchase" class="btn-confirm">Confirmer</button>
          <button @click="selectedProduct = null" class="btn-cancel">Annuler</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { ref, computed, onMounted } from 'vue'

export default {
  name: 'Shop',
  setup() {
    const products = ref([])
    const userBalance = ref(0)
    const categoryFilter = ref('')
    const selectedProduct = ref(null)

    const filteredProducts = computed(() => {
      if (!categoryFilter.value) return products.value
      return products.value.filter(p => p.category === categoryFilter.value)
    })

    const loadShop = async () => {
      try {
        const response = await fetch('/api/shop', {
          credentials: 'include',
        })
        if (response.ok) {
          const data = await response.json()
          products.value = data.products || []
          userBalance.value = data.balance || 0
        }
      } catch (error) {
        console.error('Failed to load shop:', error)
      }
    }

    const openPurchaseModal = (product) => {
      if (userBalance.value >= product.price) {
        selectedProduct.value = product
      }
    }

    const confirmPurchase = async () => {
      if (!selectedProduct.value) return

      try {
        const response = await fetch('/api/purchase', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            productId: selectedProduct.value.id,
            amount: selectedProduct.value.price,
          }),
          credentials: 'include',
        })

        if (response.ok) {
          userBalance.value -= selectedProduct.value.price
          selectedProduct.value = null
          await loadShop()
        }
      } catch (error) {
        console.error('Purchase failed:', error)
      }
    }

    onMounted(() => {
      loadShop()
    })

    return {
      products,
      userBalance,
      categoryFilter,
      selectedProduct,
      filteredProducts,
      openPurchaseModal,
      confirmPurchase,
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
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 2rem;
  flex-wrap: wrap;
  gap: 1rem;
}

.page-header h2 {
  color: #2c3e50;
}

.balance-display {
  color: #7f8c8d;
  margin-top: 0.5rem;
  font-size: 1.1rem;
}

.filters {
  flex: 1;
  min-width: 200px;
}

.filters select {
  width: 100%;
  padding: 0.5rem 1rem;
  border: 1px solid #bdc3c7;
  border-radius: 4px;
  font-size: 1rem;
}

.products-list {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(250px, 1fr));
  gap: 1.5rem;
}

.product-card {
  background: white;
  padding: 1.5rem;
  border-radius: 8px;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
  transition: transform 0.3s, box-shadow 0.3s;
  text-align: center;
}

.product-card:hover {
  transform: translateY(-4px);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
}

.product-image {
  font-size: 3rem;
  margin-bottom: 1rem;
}

.product-card h3 {
  color: #2c3e50;
  margin-bottom: 0.5rem;
}

.product-card p {
  color: #7f8c8d;
  font-size: 0.9rem;
  margin-bottom: 1rem;
}

.product-footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-top: 1rem;
  padding-top: 1rem;
  border-top: 1px solid #ecf0f1;
}

.price {
  font-weight: bold;
  color: #27ae60;
  font-size: 1.1rem;
}

.btn-buy {
  background-color: #667eea;
  color: white;
  border: none;
  padding: 0.5rem 1rem;
  border-radius: 4px;
  cursor: pointer;
  transition: background-color 0.3s;
}

.btn-buy:hover:not(:disabled) {
  background-color: #5568d3;
}

.btn-buy:disabled {
  background-color: #bdc3c7;
  cursor: not-allowed;
}

.modal {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background-color: rgba(0, 0, 0, 0.5);
  display: flex;
  justify-content: center;
  align-items: center;
  z-index: 2000;
}

.modal-content {
  background: white;
  padding: 2rem;
  border-radius: 8px;
  max-width: 400px;
  width: 90%;
  position: relative;
}

.close {
  position: absolute;
  top: 1rem;
  right: 1rem;
  font-size: 1.5rem;
  cursor: pointer;
  color: #7f8c8d;
}

.modal-content h3 {
  margin-bottom: 1rem;
  color: #2c3e50;
}

.product-info {
  margin: 1.5rem 0;
  padding: 1rem;
  background-color: #ecf0f1;
  border-radius: 4px;
}

.product-info p {
  margin: 0.5rem 0;
  color: #2c3e50;
}

.product-info .price {
  font-weight: bold;
  color: #27ae60;
}

.modal-actions {
  display: flex;
  gap: 1rem;
  margin-top: 1rem;
}

.btn-confirm,
.btn-cancel {
  flex: 1;
  padding: 0.75rem;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  font-size: 1rem;
  transition: background-color 0.3s;
}

.btn-confirm {
  background-color: #27ae60;
  color: white;
}

.btn-confirm:hover {
  background-color: #229954;
}

.btn-cancel {
  background-color: #ecf0f1;
  color: #2c3e50;
}

.btn-cancel:hover {
  background-color: #bdc3c7;
}

.empty-state {
  grid-column: 1 / -1;
  text-align: center;
  padding: 2rem;
  color: #7f8c8d;
}
</style>
