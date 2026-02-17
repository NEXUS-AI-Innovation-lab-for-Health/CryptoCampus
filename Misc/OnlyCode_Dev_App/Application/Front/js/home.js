// Données de test (à remplacer par un appel API)
let requests = [
    {
        id: 1,
        title: "Aide en algèbre linéaire",
        description: "J'ai besoin d'aide pour comprendre les matrices et les déterminants",
        subject: "math",
        reward: 50,
        author: "Étudiant #123456",
        date: "Il y a 2h"
    },
    {
        id: 2,
        title: "Correction de code Python",
        description: "Mon algorithme de tri ne fonctionne pas correctement, besoin d'un regard extérieur",
        subject: "programming",
        reward: 30,
        author: "Étudiant #789012",
        date: "Il y a 5h"
    },
    {
        id: 3,
        title: "Exercices de mécanique",
        description: "Problèmes de cinématique et dynamique du point matériel",
        subject: "physics",
        reward: 40,
        author: "Étudiant #345678",
        date: "Il y a 1 jour"
    }
];

// Chargement des requêtes
function loadRequests(filteredRequests = requests) {
    const container = document.getElementById('requestsList');
    const emptyState = document.getElementById('emptyState');
    
    container.innerHTML = '';
    
    if (filteredRequests.length === 0) {
        emptyState.style.display = 'block';
        return;
    }
    
    emptyState.style.display = 'none';
    
    filteredRequests.forEach(request => {
        const card = createRequestCard(request);
        container.appendChild(card);
    });
}

// Création d'une carte de requête
function createRequestCard(request) {
    const card = document.createElement('div');
    card.className = 'request-card';
    
    card.innerHTML = `
        <div class="request-header">
            <span class="subject-badge">${getSubjectName(request.subject)}</span>
            <span class="reward">💰 ${request.reward} coins</span>
        </div>
        <h3 class="request-title">${request.title}</h3>
        <p class="request-description">${request.description}</p>
        <div class="request-meta">
            <span>👤 ${request.author}</span>
            <span>🕐 ${request.date}</span>
        </div>
        <button class="btn-apply" onclick="applyToRequest(${request.id})">
            Postuler pour aider
        </button>
    `;
    
    return card;
}

// Conversion du code matière en nom
function getSubjectName(subject) {
    const subjects = {
        'math': 'Mathématiques',
        'physics': 'Physique',
        'chemistry': 'Chimie',
        'programming': 'Programmation',
        'french': 'Français',
        'english': 'Anglais'
    };
    return subjects[subject] || subject;
}

// Postuler à une requête
function applyToRequest(requestId) {
    // TODO: Envoyer au serveur Node.js
    console.log('Postulation à la requête:', requestId);
    
    /*
    fetch(`/api/requests/${requestId}/apply`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${localStorage.getItem('token')}`
        }
    }).then(response => {
        if (response.ok) {
            alert('Candidature envoyée avec succès !');
        }
    });
    */
    
    alert('Candidature envoyée ! L\'étudiant sera notifié.');
}

// Filtrage par matière
document.getElementById('subjectFilter').addEventListener('change', (e) => {
    const subject = e.target.value;
    const filtered = subject ? requests.filter(r => r.subject === subject) : requests;
    loadRequests(filtered);
});

// Tri
document.getElementById('sortFilter').addEventListener('change', (e) => {
    const sortBy = e.target.value;
    let sorted = [...requests];
    
    if (sortBy === 'reward') {
        sorted.sort((a, b) => b.reward - a.reward);
    }
    
    loadRequests(sorted);
});

// Chargement initial
loadRequests();

// TODO: Récupérer les requêtes depuis l'API
/*
async function fetchRequests() {
    try {
        const response = await fetch('/api/requests', {
            headers: {
                'Authorization': `Bearer ${localStorage.getItem('token')}`
            }
        });
        requests = await response.json();
        loadRequests();
    } catch (error) {
        console.error('Erreur:', error);
    }
}
fetchRequests();
*/