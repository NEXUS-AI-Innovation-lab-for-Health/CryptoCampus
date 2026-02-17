// Données de test
let userBalance = 250;

const products = [
    {
        id: 1,
        name: 'Carte cadeau Amazon 10€',
        description: 'Code numérique pour achats Amazon',
        price: 100,
        category: 'giftcard',
        icon: '🎁'
    },
    {
        id: 2,
        name: 'Carte cadeau Amazon 25€',
        description: 'Code numérique pour achats Amazon',
        price: 250,
        category: 'giftcard',
        icon: '🎁'
    },
    {
        id: 3,
        name: 'Réduction cafétéria 20%',
        description: 'Bon de réduction valable 1 mois',
        price: 50,
        category: 'discount',
        icon: '☕'
    },
    {
        id: 4,
        name: 'Compte Premium 1 mois',
        description: 'Accès aux fonctionnalités premium',
        price: 150,
        category: 'premium',
        icon: '⭐'
    },
    {
        id: 5,
        name: 'T-shirt CryptoCampus',
        description: 'T-shirt officiel en coton bio',
        price: 200,
        category: 'merchandise',
        icon: '👕'
    },
    {
        id: 6,
        name: 'Mug CryptoCampus',
        description: 'Mug personnalisé pour vos pauses café',
        price: 80,
        category: 'merchandise',
        icon: '☕'
    }
];

let selectedProduct = null;

// Affichage du solde
function updateBalance() {
    document.getElementById('userBalance').textContent = userBalance;
}

// Chargement des produits
function loadProducts(filteredProducts = products) {
    const container = document.getElementById('productsList');
    container.innerHTML = '';
    
    filteredProducts.forEach(product => {
        const card = createProductCard(product);
        container.appendChild(card);
    });
}

// Création d'une carte produit
function createProductCard(product) {
    const card = document.createElement('div');
    card.className = 'product-card';
    
    const canAfford = userBalance >= product.price;
    
    card.innerHTML = `
        <div class="product-image">${product.icon}</div>
        <div class="product-info">
            <span class="product-category">${getCategoryName(product.category)}</span>
            <h3 class="product-name">${product.name}</h3>
            <p class="product-description">${product.description}</p>
            <div class="product-footer">
                <span class="product-price">💰 ${product.price}</span>
                <button class="btn-buy" ${!canAfford ? 'disabled' : ''} onclick="openPurchaseModal(${product.id})">
                    ${canAfford ? 'Acheter' : 'Solde insuffisant'}
                </button>
            </div>
        </div>
    `;
    
    return card;
}

// Conversion catégorie
function getCategoryName(category) {
    const categories = {
        'giftcard': 'Carte cadeau',
        'discount': 'Réduction',
        'premium': 'Premium',
        'merchandise': 'Goodies'
    };
    return categories[category] || category;
}

// Ouverture du modal
function openPurchaseModal(productId) {
    selectedProduct = products.find(p => p.id === productId);
    if (!selectedProduct) return;
    
    const modal = document.getElementById('purchaseModal');
    const modalInfo = document.getElementById('modalProductInfo');
    
    modalInfo.innerHTML = `
        <h4>${selectedProduct.name}</h4>
        <p>${selectedProduct.description}</p>
        <p style="margin-top: 15px;"><strong>Prix: 💰 ${selectedProduct.price} coins</strong></p>
        <p>Solde restant après achat: 💰 ${userBalance - selectedProduct.price} coins</p>
    `;
    
    modal.style.display = 'block';
}

// Fermeture du modal
function closePurchaseModal() {
    document.getElementById('purchaseModal').style.display = 'none';
    selectedProduct = null;
}

// Confirmation d'achat
document.getElementById('confirmPurchase').addEventListener('click', async () => {
    if (!selectedProduct) return;
    
    // TODO: Envoyer au serveur
    console.log('Achat du produit:', selectedProduct.id);
    
    /*
    try {
        const response = await fetch('/api/shop/purchase', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${localStorage.getItem('token')}`
            },
            body: JSON.stringify({ productId: selectedProduct.id })
        });
        
        if (response.ok) {
            const data = await response.json();
            userBalance = data.newBalance;
            updateBalance();
            loadProducts();
            alert('Achat effectué avec succès !');
        } else {
            alert('Erreur lors de l\'achat');
        }
    } catch (error) {
        console.error('Erreur:', error);
    }
    */
    
    // Simulation
    userBalance -= selectedProduct.price;
    updateBalance();
    loadProducts();
    alert(`Achat effectué avec succès !\n\n${selectedProduct.name}\n\nVotre code/bon sera envoyé par email.`);
    
    closePurchaseModal();
});

// Annulation
document.getElementById('cancelPurchase').addEventListener('click', closePurchaseModal);

// Fermeture par X
document.querySelector('.close').addEventListener('click', closePurchaseModal);

// Fermeture en cliquant en dehors
window.addEventListener('click', (e) => {
    const modal = document.getElementById('purchaseModal');
    if (e.target === modal) {
        closePurchaseModal();
    }
});

// Filtrage par catégorie
document.getElementById('categoryFilter').addEventListener('change', (e) => {
    const category = e.target.value;
    const filtered = category ? products.filter(p => p.category === category) : products;
    loadProducts(filtered);
});

// Chargement initial
updateBalance();
loadProducts();

// TODO: Récupérer les données depuis l'API
/*
async function fetchUserBalance() {
    try {
        const response = await fetch('/api/user/balance', {
            headers: { 'Authorization': `Bearer ${localStorage.getItem('token')}` }
        });
        const data = await response.json();
        userBalance = data.balance;
        updateBalance();
        loadProducts();
    } catch (error) {
        console.error('Erreur:', error);
    }
}
fetchUserBalance();
*/