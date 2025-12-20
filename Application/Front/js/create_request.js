// Solde utilisateur (à récupérer depuis l'API)
let userBalance = 250;

// Déconnexion
document.getElementById('logoutBtn').addEventListener('click', () => {
    localStorage.removeItem('token');
    window.location.href = 'login.html';
});

// Affichage du solde
document.getElementById('currentBalance').textContent = userBalance;

// Compteur de caractères pour le titre
const titleInput = document.getElementById('title');
const titleCount = document.getElementById('titleCount');

titleInput.addEventListener('input', () => {
    titleCount.textContent = titleInput.value.length;
});

// Compteur de caractères pour la description
const descInput = document.getElementById('description');
const descCount = document.getElementById('descCount');

descInput.addEventListener('input', () => {
    descCount.textContent = descInput.value.length;
});

// Validation de la récompense
const rewardInput = document.getElementById('reward');
const rewardError = document.getElementById('rewardError');

rewardInput.addEventListener('input', () => {
    const reward = parseInt(rewardInput.value);
    
    if (reward > userBalance) {
        rewardError.style.display = 'block';
        rewardInput.style.borderColor = '#e74c3c';
    } else {
        rewardError.style.display = 'none';
        rewardInput.style.borderColor = '#e0e0e0';
    }
});

// Date minimum (aujourd'hui)
const deadlineInput = document.getElementById('deadline');
const today = new Date().toISOString().split('T')[0];
deadlineInput.min = today;

// Soumission du formulaire
document.getElementById('createRequestForm').addEventListener('submit', async (e) => {
    e.preventDefault();
    
    // Récupération des données
    const formData = {
        subject: document.getElementById('subject').value,
        title: document.getElementById('title').value,
        description: document.getElementById('description').value,
        urgency: document.getElementById('urgency').value,
        reward: parseInt(document.getElementById('reward').value),
        deadline: document.getElementById('deadline').value || null
    };
    
    // Validation
    if (formData.reward > userBalance) {
        alert('Solde insuffisant pour cette récompense');
        return;
    }
    
    if (formData.reward < 10) {
        alert('La récompense minimale est de 10 coins');
        return;
    }
    
    // TODO: Envoyer au serveur Node.js
    console.log('Création de requête:', formData);
    
    /*
    try {
        const response = await fetch('/api/requests/create', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${localStorage.getItem('token')}`
            },
            body: JSON.stringify(formData)
        });
        
        if (response.ok) {
            const data = await response.json();
            alert('Requête créée avec succès !');
            window.location.href = 'home.html';
        } else {
            const error = await response.json();
            alert('Erreur: ' + error.message);
        }
    } catch (error) {
        console.error('Erreur:', error);
        alert('Erreur lors de la création de la requête');
    }
    */
    
    // Simulation
    alert('Requête créée avec succès !\n\nTitre: ' + formData.title + '\nRécompense: ' + formData.reward + ' coins\n\nVous serez notifié lorsqu\'un étudiant postulera.');
    window.location.href = 'home.html';
});

// TODO: Récupérer le solde depuis l'API
/*
async function fetchUserBalance() {
    try {
        const response = await fetch('/api/user/balance', {
            headers: {
                'Authorization': `Bearer ${localStorage.getItem('token')}`
            }
        });
        const data = await response.json();
        userBalance = data.balance;
        document.getElementById('currentBalance').textContent = userBalance;
    } catch (error) {
        console.error('Erreur:', error);
    }
}
fetchUserBalance();
*/