<template>
  <div class="login-container">
    <div class="card">
      <h1>CryptoCampus</h1>
      <p class="subtitle">{{ t('login.subtitle') }}</p>

      <div class="form-container">
        <!-- Étape de complétion du profil après connexion LinkedIn -->
        <div v-if="linkedinStep" class="form active linkedin-step">
          <div v-if="error" class="error-message">{{ error }}</div>
          <p class="linkedin-step-intro">
            🔗 {{ t('login.linkedinIntro') }}
          </p>

          <div class="form-group">
            <label>{{ t('login.roleChoice.label') }}</label>
            <div class="role-choice">
              <button
                type="button"
                class="role-btn"
                :class="{ active: linkedinForm.desired_role === 'student' }"
                @click="linkedinForm.desired_role = 'student'"
              >🎓 {{ t('login.roleChoice.student') }}</button>
              <button
                type="button"
                class="role-btn"
                :class="{ active: linkedinForm.desired_role === 'tutor' }"
                @click="linkedinForm.desired_role = 'tutor'"
              >👨‍🏫 {{ t('login.roleChoice.tutor') }}</button>
            </div>
          </div>

          <div v-if="linkedinForm.desired_role === 'student'" class="form-group">
            <label for="linkedinReferralCode">{{ t('login.referralCode.label') }}</label>
            <input
              v-model="linkedinForm.referral_code"
              type="text"
              id="linkedinReferralCode"
              :placeholder="t('login.referralCode.placeholder')"
              maxlength="20"
              style="text-transform: uppercase;"
              required
            />
            <small class="password-hint">{{ t('login.referralCode.hint') }}</small>
          </div>

          <div v-if="linkedinForm.desired_role === 'tutor'" class="tutor-location-fields">
            <div class="form-group">
              <label for="linkedinLessonMode">{{ t('login.tutorFields.lessonMode') }}</label>
              <select v-model="linkedinForm.lesson_mode" id="linkedinLessonMode" required>
                <option value="Visio">{{ t('login.tutorFields.visio') }}</option>
                <option value="Presentiel">{{ t('login.tutorFields.presentiel') }}</option>
                <option value="Hybride">{{ t('login.tutorFields.hybride') }}</option>
              </select>
            </div>

            <div class="form-group" v-if="linkedinForm.lesson_mode === 'Visio' || linkedinForm.lesson_mode === 'Hybride'">
              <label for="linkedinVisioTool">{{ t('login.tutorFields.visioTool') }}</label>
              <select v-model="linkedinForm.visio_tool" id="linkedinVisioTool" required>
                <option value="Zoom">Zoom</option>
                <option value="Teams">Teams</option>
                <option value="Google Meet">Google Meet</option>
                <option value="Discord">Discord</option>
                <option value="Autre">{{ t('login.tutorFields.autre') }}</option>
              </select>
            </div>

            <div class="form-group">
              <label for="linkedinPlaces">{{ t('login.tutorFields.places') }}</label>
              <input
                v-model="linkedinForm.lesson_places_raw"
                type="text"
                id="linkedinPlaces"
                :placeholder="t('login.tutorFields.placesPlaceholder')"
              />
            </div>
          </div>

          <button
            type="button"
            class="btn-primary"
            :disabled="isLoading || !linkedinForm.desired_role || (linkedinForm.desired_role === 'student' && !linkedinForm.referral_code.trim())"
            @click="completeLinkedInProfile"
          >
            {{ isLoading ? t('login.finalize.submitting') : t('login.finalize.submit') }}
          </button>
        </div>

        <template v-else>
        <div class="tabs">
          <button
            class="tab"
            :class="{ active: activeTab === 'login' }"
            @click="activeTab = 'login'"
          >
            {{ t('login.tabs.login') }}
          </button>
          <button
            class="tab"
            :class="{ active: activeTab === 'register' }"
            @click="activeTab = 'register'"
          >
            {{ t('login.tabs.register') }}
          </button>
        </div>

        <button type="button" class="btn-linkedin" @click="continueWithLinkedIn">
          <svg class="linkedin-icon" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
            <path d="M20.447 20.452h-3.554v-5.569c0-1.328-.027-3.037-1.852-3.037-1.853 0-2.136 1.445-2.136 2.939v5.667H9.351V9h3.414v1.561h.046c.477-.9 1.637-1.85 3.37-1.85 3.601 0 4.267 2.37 4.267 5.455v6.286zM5.337 7.433a2.062 2.062 0 1 1 0-4.124 2.062 2.062 0 0 1 0 4.124zM7.114 20.452H3.56V9h3.554v11.452zM22.225 0H1.771C.792 0 0 .774 0 1.729v20.542C0 23.227.792 24 1.771 24h20.451C23.2 24 24 23.227 24 22.271V1.729C24 .774 23.2 0 22.222 0h.003z"/>
          </svg>
          {{ t('login.continueWithLinkedIn') }}
        </button>
        <div class="divider"><span>{{ t('login.or') }}</span></div>

        <!-- Login Form -->
        <form v-if="activeTab === 'login'" @submit.prevent="handleLogin" class="form active">
          <div v-if="error" class="error-message">{{ error }}</div>
          <div class="form-group">
            <label for="loginEmail">{{ t('login.loginForm.email') }}</label>
            <input
              v-model="loginForm.email"
              type="email"
              id="loginEmail"
              placeholder="email@exemple.com"
              required
            />
          </div>
          <div class="form-group">
            <label for="loginPassword">{{ t('login.loginForm.password') }}</label>
            <div class="password-wrapper">
              <input
                v-model="loginForm.password"
                :type="showLoginPassword ? 'text' : 'password'"
                id="loginPassword"
                :placeholder="t('login.loginForm.passwordPlaceholder')"
                required
              />
              <button type="button" class="toggle-password" @click="showLoginPassword = !showLoginPassword" :aria-label="showLoginPassword ? t('login.hidePassword') : t('login.showPassword')">
                <svg v-if="!showLoginPassword" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>
                <svg v-else xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19m-6.72-1.07a3 3 0 1 1-4.24-4.24"/><line x1="1" y1="1" x2="23" y2="23"/></svg>
              </button>
            </div>
          </div>
          <button type="submit" class="btn-primary" :disabled="isLoading">
            {{ isLoading ? t('login.loginForm.submitting') : t('login.loginForm.submit') }}
          </button>
        </form>

        <!-- Register Form -->
        <form v-if="activeTab === 'register'" @submit.prevent="handleRegister" class="form active">
          <div v-if="error" class="error-message">{{ error }}</div>
          <div v-if="successMessage" class="success-message">{{ successMessage }}</div>

          <div class="form-row">
            <div class="form-group">
              <label for="registerFirstName">{{ t('login.registerForm.firstName') }}</label>
              <input
                v-model="registerForm.first_name"
                type="text"
                id="registerFirstName"
                :placeholder="t('login.registerForm.firstNamePlaceholder')"
                required
              />
            </div>
            <div class="form-group">
              <label for="registerLastName">{{ t('login.registerForm.lastName') }}</label>
              <input
                v-model="registerForm.last_name"
                type="text"
                id="registerLastName"
                :placeholder="t('login.registerForm.lastNamePlaceholder')"
                required
              />
            </div>
          </div>

          <div class="form-group">
            <label for="registerEmail">{{ t('login.registerForm.email') }}</label>
            <input
              v-model="registerForm.email"
              type="email"
              id="registerEmail"
              placeholder="email@exemple.com"
              required
            />
          </div>

          <div class="form-group">
            <label for="registerPassword">{{ t('login.registerForm.password') }}</label>
            <div class="password-wrapper">
              <input
                v-model="registerForm.password"
                :type="showRegisterPassword ? 'text' : 'password'"
                id="registerPassword"
                :placeholder="t('login.registerForm.passwordPlaceholder')"
                minlength="8"
                required
              />
              <button type="button" class="toggle-password" @click="showRegisterPassword = !showRegisterPassword" :aria-label="showRegisterPassword ? t('login.hidePassword') : t('login.showPassword')">
                <svg v-if="!showRegisterPassword" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>
                <svg v-else xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19m-6.72-1.07a3 3 0 1 1-4.24-4.24"/><line x1="1" y1="1" x2="23" y2="23"/></svg>
              </button>
            </div>
            <small class="password-hint">{{ t('login.registerForm.passwordHint') }}</small>
          </div>

          <div class="form-group">
            <label>{{ t('login.roleChoice.label') }}</label>
            <div class="role-choice">
              <button
                type="button"
                class="role-btn"
                :class="{ active: registerForm.desired_role === 'student' }"
                @click="registerForm.desired_role = 'student'"
              >🎓 {{ t('login.roleChoice.student') }}</button>
              <button
                type="button"
                class="role-btn"
                :class="{ active: registerForm.desired_role === 'tutor' }"
                @click="registerForm.desired_role = 'tutor'"
              >👨‍🏫 {{ t('login.roleChoice.tutor') }}</button>
            </div>
          </div>

          <div v-if="registerForm.desired_role === 'student'" class="form-group">
            <label for="registerReferralCode">{{ t('login.referralCode.label') }}</label>
            <input
              v-model="registerForm.referral_code"
              type="text"
              id="registerReferralCode"
              :placeholder="t('login.referralCode.placeholder')"
              maxlength="20"
              style="text-transform: uppercase;"
              required
            />
            <small class="password-hint">{{ t('login.referralCode.hint') }}</small>
          </div>

          <div v-if="registerForm.desired_role === 'tutor'" class="tutor-location-fields">
            <div class="form-group">
              <label for="registerLessonMode">{{ t('login.tutorFields.lessonMode') }}</label>
              <select v-model="registerForm.lesson_mode" id="registerLessonMode" required>
                <option value="Visio">{{ t('login.tutorFields.visio') }}</option>
                <option value="Presentiel">{{ t('login.tutorFields.presentiel') }}</option>
                <option value="Hybride">{{ t('login.tutorFields.hybride') }}</option>
              </select>
            </div>

            <div class="form-group" v-if="registerForm.lesson_mode === 'Visio' || registerForm.lesson_mode === 'Hybride'">
              <label for="registerVisioTool">{{ t('login.tutorFields.visioTool') }}</label>
              <select v-model="registerForm.visio_tool" id="registerVisioTool" required>
                <option value="Zoom">Zoom</option>
                <option value="Teams">Teams</option>
                <option value="Google Meet">Google Meet</option>
                <option value="Discord">Discord</option>
                <option value="Autre">{{ t('login.tutorFields.autre') }}</option>
              </select>
            </div>

            <div class="form-group">
              <label for="registerPlaces">{{ t('login.tutorFields.places') }}</label>
              <input
                v-model="registerForm.lesson_places_raw"
                type="text"
                id="registerPlaces"
                :placeholder="t('login.tutorFields.placesPlaceholder')"
              />
            </div>
          </div>

          <button
            type="submit"
            class="btn-primary"
            :disabled="isLoading || !registerForm.desired_role || (registerForm.desired_role === 'student' && !registerForm.referral_code.trim())"
          >
            {{ isLoading ? t('login.registerForm.submitting') : t('login.registerForm.submit') }}
          </button>
        </form>
        </template>
      </div>
    </div>
  </div>
</template>

<script>
import { ref, onMounted } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { useI18n } from 'vue-i18n'

export default {
  name: 'Login',
  setup() {
    const router = useRouter()
    const route = useRoute()
    const { t } = useI18n()
    const activeTab = ref('login')
    const isLoading = ref(false)
    const error = ref('')
    const successMessage = ref('')
    const showLoginPassword = ref(false)
    const showRegisterPassword = ref(false)
    const linkedinStep = ref(false)

    const loginForm = ref({
      email: '',
      password: '',
    })

    // Le rôle est choisi explicitement ('student' ou 'tutor') avant d'afficher le
    // reste du formulaire. Un code de parrainage valide est obligatoire pour un
    // compte étudiant ; le rôle est toujours re-vérifié côté serveur.
    const registerForm = ref({
      first_name: '',
      last_name: '',
      email: '',
      password: '',
      desired_role: '',
      referral_code: '',
      lesson_mode: 'Visio',
      visio_tool: 'Zoom',
      lesson_places_raw: 'Visio',
    })

    const linkedinForm = ref({
      desired_role: '',
      referral_code: '',
      lesson_mode: 'Visio',
      visio_tool: 'Zoom',
      lesson_places_raw: 'Visio',
    })

    const continueWithLinkedIn = () => {
      window.location.href = '/api/auth/linkedin'
    }

    const completeLinkedInProfile = async () => {
      error.value = ''
      successMessage.value = ''
      isLoading.value = true

      try {
        const response = await fetch('/api/auth/linkedin/complete-profile', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            desired_role: linkedinForm.value.desired_role,
            referral_code: linkedinForm.value.referral_code,
            lesson_mode: linkedinForm.value.lesson_mode,
            visio_tool: linkedinForm.value.visio_tool,
            lesson_places: linkedinForm.value.lesson_places_raw
              .split(',')
              .map((value) => value.trim())
              .filter((value) => value.length > 0),
          }),
          credentials: 'include',
        })

        const data = await response.json()

        if (response.ok) {
          router.push('/home')
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
            desired_role: '',
            referral_code: '',
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

    onMounted(() => {
      const linkedinStatus = route.query.linkedin

      if (linkedinStatus === 'connected') {
        router.replace('/home')
      } else if (linkedinStatus === 'complete-profile') {
        linkedinStep.value = true
        router.replace('/login')
      } else if (linkedinStatus === 'error') {
        error.value = 'Connexion LinkedIn impossible, réessayez ou utilisez le formulaire classique'
        router.replace('/login')
      }
    })

    return {
      t,
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
      linkedinStep,
      linkedinForm,
      continueWithLinkedIn,
      completeLinkedInProfile,
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

.role-choice {
  display: flex;
  gap: 0.75rem;
}

.role-btn {
  flex: 1;
  padding: 0.9rem;
  border: 2px solid #ecf0f1;
  border-radius: 8px;
  background: white;
  color: #7f8c8d;
  font-size: 0.95rem;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
}

.role-btn:hover {
  border-color: #667eea;
  color: #667eea;
}

.role-btn.active {
  border-color: #667eea;
  background: #667eea;
  color: white;
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

.divider {
  display: flex;
  align-items: center;
  text-align: center;
  color: #95a5a6;
  margin: 1.25rem 0;
}

.divider::before,
.divider::after {
  content: '';
  flex: 1;
  border-bottom: 1px solid #ecf0f1;
}

.divider span {
  padding: 0 0.75rem;
  font-size: 0.9rem;
}

.btn-linkedin {
  width: 100%;
  padding: 0.75rem;
  background-color: #0A66C2;
  color: white;
  border: none;
  border-radius: 4px;
  font-size: 1rem;
  cursor: pointer;
  transition: background-color 0.3s;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 0.5rem;
}

.btn-linkedin:hover {
  background-color: #084e96;
}

.linkedin-icon {
  width: 1.1rem;
  height: 1.1rem;
  flex-shrink: 0;
}

.linkedin-step-intro {
  color: #34495e;
  margin-bottom: 1.5rem;
  line-height: 1.5;
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
