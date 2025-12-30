// Gestion des onglets
const tabs = document.querySelectorAll('.tab');
const forms = document.querySelectorAll('.form');

tabs.forEach(tab => {
    tab.addEventListener('click', () => {
        const targetTab = tab.dataset.tab;
        
        tabs.forEach(t => t.classList.remove('active'));
        forms.forEach(f => f.classList.remove('active'));
        
        tab.classList.add('active');
        document.getElementById(targetTab + 'Form').classList.add('active');
    });
});

// Gestion du formulaire de connexion
document.getElementById('loginForm').addEventListener('submit', async (e) => {
    e.preventDefault();
    
    const studentId = document.getElementById('loginStudentId').value;
    const password = document.getElementById('loginPassword').value;
    
    // TODO: Connexion avec le serveur Node.js
    console.log('Connexion:', { studentId, password });
    
    // Exemple de requête (à adapter selon votre API)
    /*
    try {
        const response = await fetch('/api/login', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ studentId, password })
        });
        
        if (response.ok) {
            const data = await response.json();
            localStorage.setItem('token', data.token);
            window.location.href = 'home';
        } else {
            alert('Identifiants incorrects');
        }
    } catch (error) {
        console.error('Erreur:', error);
    }
    */
    
    // Redirection temporaire pour test
    alert('Connexion simulée');
    window.location.href = 'home';
});

// Gestion du formulaire d'inscription
document.getElementById('registerForm').addEventListener('submit', async (e) => {
    e.preventDefault();
    
    const studentId = document.getElementById('registerStudentId').value;
    const name = document.getElementById('registerName').value;
    const email = document.getElementById('registerEmail').value;
    const password = document.getElementById('registerPassword').value;
    
    // TODO: Inscription avec le serveur Node.js
    console.log('Inscription:', { studentId, name, email, password });
    
    // Exemple de requête (à adapter selon votre API)
    /*
    try {
        const response = await fetch('/api/register', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ studentId, name, email, password })
        });
        
        if (response.ok) {
            alert('Compte créé avec succès');
            tabs[0].click(); // Retour à l'onglet connexion
        } else {
            alert('Erreur lors de la création du compte');
        }
    } catch (error) {
        console.error('Erreur:', error);
    }
    */
    
    // Message temporaire pour test
    alert('Inscription simulée');
    tabs[0].click();
});