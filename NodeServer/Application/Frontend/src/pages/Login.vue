<template>
  <div class="login-container">
    <div class="card">
      <h1>CryptoCampus</h1>
      <p class="subtitle">Plateforme d'entraide étudiante</p>

      <div class="form-container">
        <div class="tabs">
          <button
            class="tab"
            :class="{ active: activeTab === 'login' }"
            @click="activeTab = 'login'"
          >
            Connexion
          </button>
          <button
            class="tab"
            :class="{ active: activeTab === 'register' }"
            @click="activeTab = 'register'"
          >
            Créer un compte
          </button>
        </div>

        <!-- Login Form -->
        <form v-if="activeTab === 'login'" @submit.prevent="handleLogin" class="form active">
          <div v-if="error" class="error-message">{{ error }}</div>
          <div class="form-group">
            <label for="loginEmail">Email</label>
            <input
              v-model="loginForm.email"
              type="email"
              id="loginEmail"
              placeholder="email@exemple.com"
              required
            />
          </div>
          <div class="form-group">
            <label for="loginPassword">Mot de passe</label>
            <div class="password-wrapper">
              <input
                v-model="loginForm.password"
                :type="showLoginPassword ? 'text' : 'password'"
                id="loginPassword"
                placeholder="Votre mot de passe"
                required
              />
              <button type="button" class="toggle-password" @click="showLoginPassword = !showLoginPassword" :aria-label="showLoginPassword ? 'Masquer le mot de passe' : 'Afficher le mot de passe'">
                <svg v-if="!showLoginPassword" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>
                <svg v-else xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19m-6.72-1.07a3 3 0 1 1-4.24-4.24"/><line x1="1" y1="1" x2="23" y2="23"/></svg>
              </button>
            </div>
          </div>
          <button type="submit" class="btn-primary" :disabled="isLoading">
            {{ isLoading ? 'Connexion en cours...' : 'Se connecter' }}
          </button>
        </form>

        <!-- Register Form -->
        <form v-if="activeTab === 'register'" @submit.prevent="handleRegister" class="form active">
          <div v-if="error" class="error-message">{{ error }}</div>
          <div v-if="successMessage" class="success-message">{{ successMessage }}</div>
          
          <div class="form-row">
            <div class="form-group">
              <label for="registerFirstName">Prénom *</label>
              <input
                v-model="registerForm.first_name"
                type="text"
                id="registerFirstName"
                placeholder="Votre prénom"
                required
              />
            </div>
            <div class="form-group">
              <label for="registerLastName">Nom *</label>
              <input
                v-model="registerForm.last_name"
                type="text"
                id="registerLastName"
                placeholder="Votre nom"
                required
              />
            </div>
          </div>
          
          <div class="form-group">
            <label for="registerEmail">Email *</label>
            <input
              v-model="registerForm.email"
              type="email"
              id="registerEmail"
              placeholder="email@exemple.com"
              required
            />
          </div>
          
          <div class="form-group">
            <label for="registerPassword">Mot de passe *</label>
            <div class="password-wrapper">
              <input
                v-model="registerForm.password"
                :type="showRegisterPassword ? 'text' : 'password'"
                id="registerPassword"
                placeholder="Minimum 8 caractères"
                minlength="8"
                required
              />
              <button type="button" class="toggle-password" @click="showRegisterPassword = !showRegisterPassword" :aria-label="showRegisterPassword ? 'Masquer le mot de passe' : 'Afficher le mot de passe'">
                <svg v-if="!showRegisterPassword" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>
                <svg v-else xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19m-6.72-1.07a3 3 0 1 1-4.24-4.24"/><line x1="1" y1="1" x2="23" y2="23"/></svg>
              </button>
            </div>
            <small class="password-hint">Au moins 8 caractères</small>
          </div>
          
          <div class="form-group">
            <label for="registerRole">Je suis un(e) *</label>
            <select v-model="registerForm.role" id="registerRole" required>
              <option value="student">Étudiant(e)</option>
              <option value="tutor">Tuteur/Tutrice</option>
            </select>
          </div>

          <div v-if="registerForm.role === 'tutor'" class="tutor-location-fields">
            <div class="form-group">
              <label for="registerLessonMode">Mode principal des cours *</label>
              <select v-model="registerForm.lesson_mode" id="registerLessonMode" required>
                <option value="Visio">Visio</option>
                <option value="Presentiel">Presentiel</option>
                <option value="Hybride">Hybride</option>
              </select>
            </div>

            <div class="form-group" v-if="registerForm.lesson_mode === 'Visio' || registerForm.lesson_mode === 'Hybride'">
              <label for="registerVisioTool">Outil visio *</label>
              <select v-model="registerForm.visio_tool" id="registerVisioTool" required>
                <option value="Zoom">Zoom</option>
                <option value="Teams">Teams</option>
                <option value="Google Meet">Google Meet</option>
                <option value="Discord">Discord</option>
                <option value="Autre">Autre</option>
              </select>
            </div>

            <div class="form-group">
              <label for="registerPlaces">Lieux (separes par des virgules)</label>
              <input
                v-model="registerForm.lesson_places_raw"
                type="text"
                id="registerPlaces"
                placeholder="Visio, Bibliotheque, Domicile..."
              />
            </div>
          </div>
          
          <button type="submit" class="btn-primary" :disabled="isLoading">
            {{ isLoading ? 'Création en cours...' : 'Créer mon compte' }}
          </button>
        </form>
      </div>
    </div>
  </div>
</template>

<script>
import { ref } from 'vue'
import { useRouter } from 'vue-router'

export default {
  name: 'Login',
  setup() {
    const router = useRouter()
    const activeTab = ref('login')
    const isLoading = ref(false)
    const error = ref('')
    const successMessage = ref('')
    const showLoginPassword = ref(false)
    const showRegisterPassword = ref(false)

    const loginForm = ref({
      email: '',
      password: '',
    })

    const registerForm = ref({
      first_name: '',
      last_name: '',
      email: '',
      password: '',
      role: 'student',
      lesson_mode: 'Visio',
      visio_tool: 'Zoom',
      lesson_places_raw: 'Visio',
    })

    const handleLogin = async () => {
      error.value = ''
      successMessage.value = ''
      isLoading.value = true

      try {
        const response = await fetch('/api/login', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
          },
          body: JSON.stringify(loginForm.value),
          credentials: 'include',
        })

        const data = await response.json()

        if (response.ok) {
          // Sauvegarder les infos utilisateur dans le localStorage
          localStorage.setItem('userId', data.userId)
          localStorage.setItem('userEmail', data.email)
          localStorage.setItem('userName', `${data.firstName} ${data.lastName}`)
          
          router.push('/home')
        } else {
          error.value = data.error || 'Connexion échouée'
        }
      } catch (err) {
        error.value = 'Erreur lors de la connexion'
        console.error(err)
      } finally {
        isLoading.value = false
      }
    }

    const handleRegister = async () => {
      error.value = ''
      successMessage.value = ''
      isLoading.value = true

      try {
        const response = await fetch('/api/register', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            ...registerForm.value,
            lesson_places: registerForm.value.lesson_places_raw
              .split(',')
              .map((value) => value.trim())
              .filter((value) => value.length > 0),
          }),
          credentials: 'include',
        })

        const data = await response.json()

        if (response.ok) {
          // Basculer vers l'onglet connexion avec les credentials pré-remplis
          activeTab.value = 'login'
          loginForm.value.email = registerForm.value.email
          loginForm.value.password = registerForm.value.password
          
          // Réinitialiser le formulaire d'inscription
          registerForm.value = {
            first_name: '',
            last_name: '',
            email: '',
            password: '',
            role: 'student',
            lesson_mode: 'Visio',
            visio_tool: 'Zoom',
            lesson_places_raw: 'Visio',
          }
          
          successMessage.value = '✅ Compte créé avec succès ! Connexion en cours...'
          
          // Auto-login après inscription
          setTimeout(async () => {
            await handleLogin()
          }, 1000)
        } else {
          error.value = data.error || 'Création du compte échouée'
        }
      } catch (err) {
        error.value = 'Erreur lors de la création du compte'
        console.error(err)
      } finally {
        isLoading.value = false
      }
    }

    return {
      activeTab,
      isLoading,
      error,
      successMessage,
      loginForm,
      registerForm,
      handleLogin,
      handleRegister,
      showLoginPassword,
      showRegisterPassword,
    }
  }
}
</script>

<style scoped>
.login-container {
  display: flex;
  justify-content: center;
  align-items: center;
  min-height: calc(100vh - 80px);
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  padding: 2rem;
}

.card {
  background: white;
  padding: 2rem;
  border-radius: 8px;
  box-shadow: 0 10px 40px rgba(0, 0, 0, 0.2);
  max-width: 500px;
  width: 100%;
}

.card h1 {
  text-align: center;
  color: #2c3e50;
  margin-bottom: 0.5rem;
}

.subtitle {
  text-align: center;
  color: #7f8c8d;
  margin-bottom: 2rem;
}

.form-container {
  margin-top: 2rem;
}

.tabs {
  display: flex;
  gap: 1rem;
  margin-bottom: 1rem;
  border-bottom: 2px solid #ecf0f1;
}

.tab {
  padding: 1rem;
  border: none;
  background: none;
  cursor: pointer;
  color: #7f8c8d;
  font-size: 1rem;
  border-bottom: 2px solid transparent;
  transition: all 0.3s;
}

.tab.active {
  color: #667eea;
  border-bottom-color: #667eea;
}

.form {
  display: none;
}

.form.active {
  display: block;
}

.form-group {
  margin-bottom: 1.5rem;
}

.form-group label {
  display: block;
  margin-bottom: 0.5rem;
  color: #2c3e50;
  font-weight: 500;
}

.form-group input {
  width: 100%;
  padding: 0.75rem;
  border: 1px solid #bdc3c7;
  border-radius: 4px;
  font-size: 1rem;
}

.form-group input:focus {
  outline: none;
  border-color: #667eea;
  box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.1);
}

.btn-primary {
  width: 100%;
  padding: 0.75rem;
  background-color: #667eea;
  color: white;
  border: none;
  border-radius: 4px;
  font-size: 1rem;
  cursor: pointer;
  transition: background-color 0.3s;
}

.btn-primary:hover:not(:disabled) {
  background-color: #5568d3;
}

.btn-primary:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.error-message {
  color: #e74c3c;
  background-color: #fadbd8;
  padding: 1rem;
  border-radius: 4px;
  margin-bottom: 1rem;
  text-align: center;
}

.success-message {
  color: #27ae60;
  background-color: #d5f4e6;
  padding: 1rem;
  border-radius: 4px;
  margin-bottom: 1rem;
  text-align: center;
  font-weight: 500;
}

.form-row {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 1rem;
}

.form-group select {
  width: 100%;
  padding: 0.75rem;
  border: 1px solid #bdc3c7;
  border-radius: 4px;
  font-size: 1rem;
  background-color: white;
  cursor: pointer;
}

.form-group select:focus {
  outline: none;
  border-color: #667eea;
  box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.1);
}

.password-hint {
  display: block;
  margin-top: 0.25rem;
  color: #7f8c8d;
  font-size: 0.85rem;
}

.password-wrapper {
  position: relative;
  display: flex;
  align-items: center;
}

.password-wrapper input {
  padding-right: 2.75rem;
}

.toggle-password {
  position: absolute;
  right: 0.75rem;
  background: none;
  border: none;
  cursor: pointer;
  padding: 0;
  color: #7f8c8d;
  display: flex;
  align-items: center;
  transition: color 0.2s;
}

.toggle-password:hover {
  color: #667eea;
}

.toggle-password svg {
  width: 1.1rem;
  height: 1.1rem;
}
</style>
