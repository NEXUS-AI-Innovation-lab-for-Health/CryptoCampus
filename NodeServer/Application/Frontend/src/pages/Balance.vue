<template>
  <div class="container">
    <div class="balance-card">
      <div class="balance-header">
        <h2>Mon solde de StudyCoins</h2>
        <div class="balance-amount">
          <span class="coin-icon">💰</span>
          <span id="balanceValue" class="balance-value">{{ balance }}</span>
          <span class="coin-label">CCT</span>
        </div>
      </div>
    </div>

    <div class="stats-grid">
      <div class="stat-card">
        <div class="stat-icon">📚</div>
        <div class="stat-info">
          <h3>{{ stats.helpedCount }}</h3>
          <p>Étudiants aidés</p>
        </div>
      </div>
      <div class="stat-card">
        <div class="stat-icon">⭐</div>
        <div class="stat-info">
          <h3>{{ stats.totalEarned }}</h3>
          <p>CCT gagnés au total</p>
        </div>
      </div>
      <div class="stat-card">
        <div class="stat-icon">🎯</div>
        <div class="stat-info">
          <h3>{{ stats.requestsCreated }}</h3>
          <p>Requêtes créées</p>
        </div>
      </div>
    </div>

    <div class="history-section">
      <h2>Historique des transactions</h2>
      <div v-if="transactions.length === 0" class="empty-state">
        <p>Aucune transaction pour le moment</p>
      </div>
      <div id="transactionsList" class="transactions-list">
        <div v-for="transaction in transactions" :key="transaction.id" class="transaction-item">
          <div class="transaction-info">
            <h4>{{ transaction.description }}</h4>
            <p>{{ formatDate(transaction.date) }}</p>
          </div>
          <div class="transaction-amount" :class="{ positive: transaction.amount > 0 }">
            {{ transaction.amount > 0 ? '+' : '' }}{{ transaction.amount }}
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { ref, onMounted } from 'vue'

export default {
  name: 'Balance',
  setup() {
    const balance = ref(0)
    const transactions = ref([])
    const stats = ref({
      helpedCount: 0,
      totalEarned: 0,
      requestsCreated: 0,
    })

    const formatDate = (dateString) => {
      const date = new Date(dateString)
      return date.toLocaleDateString('fr-FR')
    }

    const loadBalance = async () => {
      try {
        const response = await fetch('/api/balance', {
          credentials: 'include',
        })
        if (response.ok) {
          const data = await response.json()
          balance.value = data.balance
          stats.value = data.stats || stats.value
          transactions.value = data.transactions || []
        }
      } catch (error) {
        console.error('Failed to load balance:', error)
      }
    }

    onMounted(() => {
      loadBalance()
    })

    return {
      balance,
      transactions,
      stats,
      formatDate,
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

.balance-card {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  padding: 2rem;
  border-radius: 12px;
  margin-bottom: 2rem;
  box-shadow: 0 4px 15px rgba(0, 0, 0, 0.1);
}

.balance-header h2 {
  margin-bottom: 1rem;
  opacity: 0.9;
}

.balance-amount {
  display: flex;
  align-items: center;
  gap: 1rem;
}

.coin-icon {
  font-size: 2rem;
}

.balance-value {
  font-size: 2.5rem;
  font-weight: bold;
}

.coin-label {
  opacity: 0.9;
}

.stats-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  gap: 1.5rem;
  margin-bottom: 2rem;
}

.stat-card {
  background: white;
  padding: 1.5rem;
  border-radius: 8px;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
  display: flex;
  align-items: center;
  gap: 1rem;
}

.stat-icon {
  font-size: 2.5rem;
}

.stat-info h3 {
  color: #667eea;
  font-size: 1.5rem;
  margin-bottom: 0.25rem;
}

.stat-info p {
  color: #7f8c8d;
  font-size: 0.9rem;
}

.history-section {
  background: white;
  padding: 1.5rem;
  border-radius: 8px;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
}

.history-section h2 {
  margin-bottom: 1.5rem;
  color: #2c3e50;
}

.transactions-list {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.transaction-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1rem;
  border-bottom: 1px solid #ecf0f1;
  transition: background-color 0.3s;
}

.transaction-item:hover {
  background-color: #f8f9fa;
}

.transaction-item:last-child {
  border-bottom: none;
}

.transaction-info h4 {
  color: #2c3e50;
  margin-bottom: 0.25rem;
}

.transaction-info p {
  color: #95a5a6;
  font-size: 0.9rem;
}

.transaction-amount {
  font-weight: bold;
  color: #e74c3c;
  font-size: 1.1rem;
}

.transaction-amount.positive {
  color: #27ae60;
}

.empty-state {
  text-align: center;
  padding: 2rem;
  color: #7f8c8d;
}
</style>
