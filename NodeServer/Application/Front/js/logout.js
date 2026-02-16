document.addEventListener('DOMContentLoaded', () => {
    const confirmloginBtn = document.getElementById('confirmLogout');
    const loginBtn = document.getElementById('loginBtn');

    // Check if user is connected
    const isConnected = !!localStorage.getItem('token');

    // Update logout button based on connection status
    if (loginBtn) {
        if (isConnected) {
            loginBtn.textContent = 'Déconnexion';
            loginBtn.classList.remove('btn-login');
            loginBtn.classList.add('btn-logout');
        } else {
            loginBtn.textContent = 'Connexion';
            loginBtn.classList.remove('btn-logout');
            loginBtn.classList.add('btn-login');
            loginBtn.addEventListener('click', (e) => {
                e.preventDefault();
                window.location.href = '/login';
            });
        }
    }

    if (confirmloginBtn) {
        confirmloginBtn.addEventListener('click', () => {
            fetch('/logout', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' }
            }).then(response => {
                if (!response.ok) {
                    console.error('Logout failed');
                }
                localStorage.removeItem('token');
                window.location.href = '/home';
            });
        }
        )
    }
});

