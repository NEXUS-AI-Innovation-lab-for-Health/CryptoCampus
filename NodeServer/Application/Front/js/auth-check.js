// Check authentication status on page load
document.addEventListener('DOMContentLoaded', async () => {
  try {
    const response = await fetch('/api/check-auth');
    const { isAuthenticated } = await response.json();

    const token = localStorage.getItem('token');

    // If server says user is not authenticated but localStorage has a token, clear it
    if (!isAuthenticated && token) {
      console.log('Session expired or invalid. Clearing localStorage token.');
      localStorage.removeItem('token');
      location.reload(); // Reload to update UI
    }
  } catch (error) {
    console.error('Error checking authentication:', error);
  }
});
