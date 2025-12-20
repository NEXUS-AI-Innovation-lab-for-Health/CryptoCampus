// Données de test (à remplacer par un appel API)
const userData = {
    balance: 250,
    helpedCount: 8,
    totalEarned: 320,
    requestsCreated: 3
};

const transactions = [
    {
        id: 1,
        type: 'earned',
        title: 'Aide en mathématiques',
        description: 'Aide fournie à l\'étudiant #123456',
        amount: 50,
        date: 'Il y a 2 heures'
    },
    {
        id: 2,
        type: 'spent',
        title: 'Achat boutique',
        description: 'Bon cadeau Amazon 10€',
        amount: -100,
        date: 'Il y a 1 jour'
    },
    {
        id: 3,
        type: 'earned',
        title: 'Correction de code Python',
        description: 'Aide fournie à l\'étudiant #789012',
        amount: 30,
        date: 'Il y a 2 jours'
    },
    {
        id: 4,
        type: 'spent',
        title: 'Création de requête',
        description: 'Requête d\'aide en physique',
        amount: -40,
        date: 'Il y a 3 jours'
    }
];

// Déconnexion
document.getElementById('logoutBtn').addEventListener('click', () => {
    localStorage.removeItem('token');
    window.location.href = 'login.html';
});

// Chargement des données utilisateur
function loadUserData() {
    document.getElementById('balanceValue').textContent = userData.balance;
    document.getElementById('helpedCount').textContent = userData.helpedCount;
    document.getElementById('totalEarned').textContent = userData.totalEarned;
    document.getElementById('requestsCreated').textContent = userData.requestsCreated;
}

// Chargement des transactions
function loadTransactions() {
    const container = document.getElementById('transactionsList');
    const emptyState = document.getElementById('emptyTransactions');
    
    if (transactions.length === 0) {
        emptyState.style.display = 'block';
        return;
    }
    
    container.innerHTML = '';
    
    transactions.forEach(transaction => {
        const item = createTransactionItem(transaction);
        container.appendChild(item);
    });
}

// Création d'un élément de transaction
function createTransactionItem(transaction) {
    const item = document.createElement('div');
    item.className = 'transaction-item';
    
    const icon = transaction.type === 'earned' ? '💰' : '🛒';
    const amountClass = transaction.amount > 0 ? 'positive' : 'negative';
    const amountText = transaction.amount > 0 ? `+${transaction.amount}` : transaction.amount;
    
    item.innerHTML = `
        <div class="transaction-info">
            <div class="transaction-icon">${icon}</div>
            <div class="transaction-details">
                <h4>${transaction.title}</h4>
                <p>${transaction.description}</p>
                <p>${transaction.date}</p>
            </div>
        </div>
        <div class="transaction-amount ${amountClass}">
            ${amountText} coins
        </div>
    `;
    
    return item;
}

// Chargement initial
loadUserData();
loadTransactions();

// TODO: Récupérer les données depuis l'API
/*
async function fetchBalance() {
    try {
        const response = await fetch('/api/user/balance', {
            headers: {
                'Authorization': `Bearer ${localStorage.getItem('token')}`
            }
        });
        const data = await response.json();
        
        userData.balance = data.balance;
        userData.helpedCount = data.helpedCount;
        userData.totalEarned = data.totalEarned;
        userData.requestsCreated = data.requestsCreated;
        
        loadUserData();
    } catch (error) {
        console.error('Erreur:', error);
    }
}

async function fetchTransactions() {
    try {
        const response = await fetch('/api/user/transactions', {
            headers: {
                'Authorization': `Bearer ${localStorage.getItem('token')}`
            }
        });
        transactions = await response.json();
        loadTransactions();
    } catch (error) {
        console.error('Erreur:', error);
    }
}

fetchBalance();
fetchTransactions();
*/