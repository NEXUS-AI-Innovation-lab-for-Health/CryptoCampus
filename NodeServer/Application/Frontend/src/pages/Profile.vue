<template>
  <div class="container">
    <!-- Profile Header -->
    <div class="profile-header">
      <div class="profile-avatar-wrapper">
        <img :src="userInfo.avatar_url || defaultAvatar" alt="Profil" class="profile-avatar" />
        <button
          type="button"
          class="avatar-edit-btn"
          title="Changer ma photo de profil"
          :disabled="isUploadingAvatar"
          @click="avatarInput?.click()"
        >📷</button>
        <input
          ref="avatarInput"
          type="file"
          accept="image/jpeg,image/png,image/webp"
          class="avatar-input-hidden"
          @change="handleAvatarChange"
        />
      </div>
      <div class="profile-info">
        <h1>{{ userInfo.first_name }} {{ userInfo.last_name }}</h1>
        <p class="email">{{ userInfo.email }}</p>
        <p class="status-text">Statut : <strong>{{ getRoleLabel(userInfo.role) }}</strong></p>
        <p class="join-date">Membre depuis {{ formatDate(userInfo.created_at) }}</p>
        <p v-if="avatarError" class="error-message avatar-error">{{ avatarError }}</p>
        <button v-if="userInfo.avatar_url" type="button" class="avatar-remove-link" @click="removeAvatar">
          Retirer ma photo de profil
        </button>
      </div>
    </div>

    <!-- Main Content Grid -->
    <div class="main-grid">
      <!-- Left Column: Balance & Statistics -->
      <div class="left-column">
        <div class="balance-stats-section">
          <h2 class="section-title">
            <span class="title-icon">💰</span>
            Solde & Statistiques
          </h2>
          
          <!-- Balance Card -->
          <div class="balance-card">
            <div class="balance-content">
              <p class="balance-label">Mon solde de StudyCoins</p>
              <div class="balance-amount">
                <span class="coin-icon">🪙</span>
                <span id="balanceValue" class="balance-value">{{ balance.toFixed(4) }}</span>
                <span class="coin-label">CCT</span>
              </div>
            </div>
          </div>

          <!-- Blockchain Address Card -->
          <div v-if="blockchainAddress" class="blockchain-card">
            <div class="blockchain-header">
              <span class="blockchain-icon">🔗</span>
              <span class="blockchain-label">Adresse Blockchain</span>
            </div>
            <div class="blockchain-address">
              <code>{{ blockchainAddress }}</code>
            </div>
          </div>

          <!-- Referral Code Card -->
          <div class="blockchain-card">
            <div class="blockchain-header">
              <span class="blockchain-icon">🎁</span>
              <span class="blockchain-label">Mon code de parrainage</span>
            </div>
            <div class="blockchain-address">
              <code>{{ userInfo.referral_code || '...' }}</code>
              <button type="button" class="btn-copy" @click="copyReferralCode">
                {{ referralCopied ? 'Copié !' : 'Copier' }}
              </button>
            </div>
            <p class="referral-hint">Partagez ce code : il permet à un(e) étudiant(e) de créer son compte.</p>
          </div>

          <!-- Beneficiaries Card -->
          <div class="beneficiaries-section">
            <h2 class="section-title">
              <span class="title-icon">👥</span>
              Bénéficiaires
            </h2>

            <div v-if="beneficiaryError" class="error-message">{{ beneficiaryError }}</div>
            <div v-if="beneficiarySuccess" class="success-message">{{ beneficiarySuccess }}</div>

            <ul class="beneficiary-list" v-if="beneficiaries.length > 0">
              <li v-for="b in beneficiaries" :key="b.beneficiary_id" class="beneficiary-item">
                <div class="beneficiary-info">
                  <strong>{{ b.label }}</strong>
                  <code>{{ b.address }}</code>
                </div>
                <div class="beneficiary-actions">
                  <input
                    type="number"
                    min="0"
                    step="0.01"
                    v-model="sendAmounts[b.beneficiary_id]"
                    placeholder="Montant CCT"
                    class="beneficiary-amount"
                  />
                  <button
                    type="button"
                    class="btn-update"
                    :disabled="sendingTo === b.beneficiary_id"
                    @click="sendToBeneficiary(b)"
                  >
                    {{ sendingTo === b.beneficiary_id ? 'Envoi...' : 'Envoyer' }}
                  </button>
                  <button type="button" class="btn-delete-account" @click="removeBeneficiary(b.beneficiary_id)">
                    Retirer
                  </button>
                </div>
              </li>
            </ul>
            <p v-else class="no-beneficiaries">Aucun bénéficiaire enregistré pour le moment.</p>

            <div class="password-form">
              <div class="form-group">
                <label for="beneficiaryLabel">Nom du bénéficiaire</label>
                <input id="beneficiaryLabel" v-model="newBeneficiary.label" type="text" placeholder="Ex : Marie Dupont" />
              </div>
              <div class="form-group">
                <label for="beneficiaryAddress">Adresse blockchain</label>
                <input id="beneficiaryAddress" v-model="newBeneficiary.address" type="text" placeholder="0x..." />
              </div>
              <button type="button" class="btn-update" :disabled="isAddingBeneficiary" @click="addBeneficiary">
                {{ isAddingBeneficiary ? 'Ajout...' : '+ Ajouter un bénéficiaire' }}
              </button>
            </div>
          </div>

          <!-- Stats Grid -->
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
                <p>Coins gagnés</p>
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
        </div>
      </div>

      <!-- Right Column: Security & Account -->
      <div class="right-column">
        <div class="security-section">
          <h2 class="section-title">
            <span class="title-icon">🔒</span>
            Sécurité & Compte
          </h2>

          <!-- Password Reset Section -->
          <div class="password-reset-card">
            <h3 class="card-subtitle">Réinitialiser le mot de passe</h3>
            <div class="password-form">
              <div v-if="passwordError" class="error-message">{{ passwordError }}</div>
              <div v-if="passwordSuccess" class="success-message">{{ passwordSuccess }}</div>

              <div class="form-group">
                <label for="currentPassword">Mot de passe actuel</label>
                <input
                  v-model="passwordForm.currentPassword"
                  type="password"
                  id="currentPassword"
                  placeholder="Entrez votre mot de passe actuel"
                />
              </div>

              <div class="form-group">
                <label for="newPassword">Nouveau mot de passe</label>
                <input
                  v-model="passwordForm.newPassword"
                  type="password"
                  id="newPassword"
                  placeholder="Entrez votre nouveau mot de passe"
                />
              </div>

              <div class="form-group">
                <label for="confirmPassword">Confirmer le nouveau mot de passe</label>
                <input
                  v-model="passwordForm.confirmPassword"
                  type="password"
                  id="confirmPassword"
                  placeholder="Confirmez votre nouveau mot de passe"
                />
              </div>

              <button
                @click="resetPassword"
                class="btn-update"
                :disabled="isResettingPassword"
              >
                {{ isResettingPassword ? 'Mise à jour en cours...' : 'Mettre à jour le mot de passe' }}
              </button>
            </div>
          </div>

          <div v-if="userInfo.role === 'TUTOR'" class="password-reset-card">
            <h3 class="card-subtitle">Lieux et modalites de cours</h3>
            <div class="password-form">
              <div v-if="locationError" class="error-message">{{ locationError }}</div>
              <div v-if="locationSuccess" class="success-message">{{ locationSuccess }}</div>

              <div class="form-group">
                <label for="lessonMode">Mode principal</label>
                <select id="lessonMode" v-model="locationForm.lesson_mode">
                  <option value="Visio">Visio</option>
                  <option value="Presentiel">Presentiel</option>
                  <option value="Hybride">Hybride</option>
                </select>
              </div>

              <div class="form-group" v-if="locationForm.lesson_mode === 'Visio' || locationForm.lesson_mode === 'Hybride'">
                <label for="visioTool">Outil visio</label>
                <select id="visioTool" v-model="locationForm.visio_tool">
                  <option value="Zoom">Zoom</option>
                  <option value="Teams">Teams</option>
                  <option value="Google Meet">Google Meet</option>
                  <option value="Discord">Discord</option>
                  <option value="Autre">Autre</option>
                </select>
              </div>

              <div class="form-group">
                <label for="lessonPlaces">Lieux (separes par des virgules)</label>
                <input
                  id="lessonPlaces"
                  v-model="locationForm.lesson_places_raw"
                  type="text"
                  placeholder="Visio, Bibliotheque, Domicile..."
                />
              </div>

              <button @click="saveLessonLocations" class="btn-update" :disabled="isSavingLocations">
                {{ isSavingLocations ? 'Enregistrement...' : 'Enregistrer les lieux de cours' }}
              </button>
            </div>
          </div>

          <!-- LinkedIn (tuteurs uniquement) -->
          <div v-if="userInfo.role === 'TUTOR'" class="password-reset-card">
            <h3 class="card-subtitle">Compte LinkedIn</h3>
            <div class="password-form">
              <div v-if="linkedinMessage" class="success-message">{{ linkedinMessage }}</div>
              <div v-if="linkedinError" class="error-message">{{ linkedinError }}</div>

              <p v-if="userInfo.linkedin_email" class="linkedin-status">
                ✅ Lié à <strong>{{ userInfo.linkedin_email }}</strong>
              </p>
              <p v-else class="linkedin-status">Aucun compte LinkedIn lié pour le moment.</p>

              <button v-if="!userInfo.linkedin_email" @click="linkLinkedIn" class="btn-update">
                🔗 Lier mon compte LinkedIn
              </button>
              <button v-else @click="unlinkLinkedIn" class="btn-delete-account">
                Délier mon compte LinkedIn
              </button>
            </div>
          </div>

          <!-- Devenir tuteur (étudiants uniquement) -->
          <div v-if="userInfo.role === 'STUDENT'" class="password-reset-card">
            <h3 class="card-subtitle">Devenir tuteur / tutrice</h3>
            <div class="password-form">
              <div v-if="becomeTutorError" class="error-message">{{ becomeTutorError }}</div>
              <p class="linkedin-status">
                Vous souhaitez donner des cours à votre tour ? Vous pouvez transformer votre
                compte étudiant en compte tuteur. <strong>Cette action est définitive.</strong>
              </p>

              <div v-if="showBecomeTutorForm">
                <div class="form-group">
                  <label for="becomeTutorMode">Mode principal des cours</label>
                  <select id="becomeTutorMode" v-model="becomeTutorForm.lesson_mode">
                    <option value="Visio">Visio</option>
                    <option value="Presentiel">Presentiel</option>
                    <option value="Hybride">Hybride</option>
                  </select>
                </div>
                <div class="form-group" v-if="becomeTutorForm.lesson_mode === 'Visio' || becomeTutorForm.lesson_mode === 'Hybride'">
                  <label for="becomeTutorVisio">Outil visio</label>
                  <select id="becomeTutorVisio" v-model="becomeTutorForm.visio_tool">
                    <option value="Zoom">Zoom</option>
                    <option value="Teams">Teams</option>
                    <option value="Google Meet">Google Meet</option>
                    <option value="Discord">Discord</option>
                    <option value="Autre">Autre</option>
                  </select>
                </div>
                <div class="form-group">
                  <label for="becomeTutorPlaces">Lieux (separes par des virgules)</label>
                  <input id="becomeTutorPlaces" v-model="becomeTutorForm.lesson_places_raw" type="text" placeholder="Visio, Bibliotheque, Domicile..." />
                </div>
                <button @click="confirmBecomeTutor" class="btn-delete-account" :disabled="isBecomingTutor">
                  {{ isBecomingTutor ? 'Conversion en cours...' : '⚠️ Confirmer : devenir tuteur définitivement' }}
                </button>
              </div>
              <button v-else @click="showBecomeTutorForm = true" class="btn-update">
                Devenir tuteur / tutrice
              </button>
            </div>
          </div>

          <!-- Logout Section -->
          <div class="logout-card">
            <div class="logout-content">
              <div class="logout-info">
                <h3 class="card-subtitle">Déconnexion</h3>
                <p class="logout-description">Se déconnecter de votre compte CryptoCampus</p>
              </div>
              <button @click="logout" class="btn-logout">
                <span class="logout-icon">🚪</span>
                Déconnexion
              </button>
            </div>
          </div>

          <!-- Delete Account Section -->
          <div class="delete-account-card">
            <div class="delete-account-content">
              <div class="delete-account-info">
                <h3 class="card-subtitle danger">Supprimer mon compte</h3>
                <p class="delete-account-description">⚠️ Cette action est irréversible. Toutes vos données seront définitivement supprimées.</p>
              </div>
              <button @click="confirmDeleteAccount" class="btn-delete-account">
                <span class="delete-icon">🗑️</span>
                Supprimer le compte
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { ref, onMounted } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import defaultAvatar from '@/assets/utilisateur.png'

export default {
  name: 'Profile',
  setup() {
    const userId = localStorage.getItem('token')
    const router = useRouter()
    const route = useRoute()
    const balance = ref(0)
    const blockchainAddress = ref(null)
    const stats = ref({
      helpedCount: 0,
      totalEarned: 0,
      requestsCreated: 0,
    })
    const userInfo = ref({
      first_name: '',
      last_name: '',
      email: '',
      role: '',
      referral_code: '',
      linkedin_email: '',
      avatar_url: '',
      created_at: new Date().toISOString(),
    })
    const isResettingPassword = ref(false)
    const passwordError = ref('')
    const passwordSuccess = ref('')
    const isSavingLocations = ref(false)
    const locationError = ref('')
    const locationSuccess = ref('')
    const referralCopied = ref(false)
    const locationForm = ref({
      lesson_mode: 'Visio',
      visio_tool: 'Zoom',
      lesson_places_raw: 'Visio',
    })
    const passwordForm = ref({
      currentPassword: '',
      newPassword: '',
      confirmPassword: '',
    })

    // Photo de profil
    const avatarInput = ref(null)
    const isUploadingAvatar = ref(false)
    const avatarError = ref('')

    // Bénéficiaires (carnet d'adresses pour les transactions blockchain)
    const beneficiaries = ref([])
    const newBeneficiary = ref({ label: '', address: '' })
    const isAddingBeneficiary = ref(false)
    const beneficiaryError = ref('')
    const beneficiarySuccess = ref('')
    const sendAmounts = ref({})
    const sendingTo = ref(null)

    // LinkedIn (liaison, réservée aux tuteurs)
    const linkedinMessage = ref('')
    const linkedinError = ref('')

    // Bascule permanente étudiant -> tuteur
    const showBecomeTutorForm = ref(false)
    const isBecomingTutor = ref(false)
    const becomeTutorError = ref('')
    const becomeTutorForm = ref({
      lesson_mode: 'Visio',
      visio_tool: 'Zoom',
      lesson_places_raw: 'Visio',
    })

    const getRoleLabel = (role) => {
      const roleLabels = {
        'STUDENT': 'Étudiant',
        'TUTOR': 'Tuteur',
        'ADMIN': 'Administrateur'
      }
      return roleLabels[role] || role
    }

    const formatDate = (dateString) => {
      const date = new Date(dateString)
      return date.toLocaleDateString('fr-FR', {
        year: 'numeric',
        month: 'long',
        day: 'numeric',
      })
    }

    const loadProfileData = async () => {
      try {
        const response = await fetch('/api/profile', {
          credentials: 'include',
        })
        if (response.ok) {
          const data = await response.json()
          userInfo.value = {
            first_name: data.first_name || 'Utilisateur',
            last_name: data.last_name || 'Inconnu',
            email: data.email || 'Email non disponible',
            role: data.role || '',
            referral_code: data.referral_code || '',
            linkedin_email: data.linkedin_email || '',
            avatar_url: data.avatar_url || '',
            created_at: data.created_at || new Date().toISOString(),
          }
          locationForm.value.lesson_mode = data.lesson_mode || 'Visio'
          locationForm.value.visio_tool = data.visio_tool || 'Zoom'
          locationForm.value.lesson_places_raw = Array.isArray(data.lesson_places) && data.lesson_places.length > 0
            ? data.lesson_places.join(', ')
            : 'Visio'
          balance.value = data.balance || 0
          blockchainAddress.value = data.blockchainAddress || null
          stats.value = data.stats || stats.value
        }
      } catch (error) {
        console.error('Failed to load profile:', error)
      }
    }

    const saveLessonLocations = async () => {
      locationError.value = ''
      locationSuccess.value = ''

      if (!locationForm.value.lesson_mode) {
        locationError.value = 'Le mode principal est requis'
        return
      }

      isSavingLocations.value = true
      try {
        const response = await fetch('/api/profile/lesson-locations', {
          method: 'PUT',
          headers: {
            'Content-Type': 'application/json',
          },
          credentials: 'include',
          body: JSON.stringify({
            lesson_mode: locationForm.value.lesson_mode,
            visio_tool: locationForm.value.visio_tool,
            lesson_places: locationForm.value.lesson_places_raw
              .split(',')
              .map((value) => value.trim())
              .filter((value) => value.length > 0),
          }),
        })

        const data = await response.json()
        if (!response.ok) {
          throw new Error(data.error || 'Erreur lors de la mise a jour')
        }

        locationSuccess.value = 'Lieux de cours mis a jour avec succes'
      } catch (error) {
        locationError.value = error.message
      } finally {
        isSavingLocations.value = false
      }
    }

    const resetPassword = async () => {
      passwordError.value = ''
      passwordSuccess.value = ''

      // Validation
      if (!passwordForm.value.currentPassword) {
        passwordError.value = 'Veuillez entrer votre mot de passe actuel'
        return
      }

      if (!passwordForm.value.newPassword) {
        passwordError.value = 'Veuillez entrer un nouveau mot de passe'
        return
      }

      if (passwordForm.value.newPassword.length < 8) {
        passwordError.value = 'Le mot de passe doit contenir au moins 8 caractères'
        return
      }

      if (passwordForm.value.newPassword !== passwordForm.value.confirmPassword) {
        passwordError.value = 'Les mots de passe ne correspondent pas'
        return
      }

      isResettingPassword.value = true

      try {
        const response = await fetch('/api/reset-password', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            currentPassword: passwordForm.value.currentPassword,
            newPassword: passwordForm.value.newPassword,
          }),
          credentials: 'include',
        })

        if (response.ok) {
          passwordSuccess.value = 'Mot de passe mis à jour avec succès!'
          // Clear form
          passwordForm.value = {
            currentPassword: '',
            newPassword: '',
            confirmPassword: '',
          }
        } else {
          const data = await response.json()
          passwordError.value = data.error || 'Erreur lors de la mise à jour du mot de passe'
        }
      } catch (error) {
        passwordError.value = 'Erreur lors de la mise à jour du mot de passe'
        console.error(error)
      } finally {
        isResettingPassword.value = false
      }
    }

    const copyReferralCode = async () => {
      if (!userInfo.value.referral_code) return
      try {
        await navigator.clipboard.writeText(userInfo.value.referral_code)
        referralCopied.value = true
        setTimeout(() => { referralCopied.value = false }, 2000)
      } catch (error) {
        console.error('Copie impossible:', error)
      }
    }

    const loadBeneficiaries = async () => {
      try {
        const response = await fetch('/api/beneficiaries', { credentials: 'include' })
        if (response.ok) {
          const data = await response.json()
          beneficiaries.value = data.beneficiaries || []
        }
      } catch (error) {
        console.error('Failed to load beneficiaries:', error)
      }
    }

    const addBeneficiary = async () => {
      beneficiaryError.value = ''
      beneficiarySuccess.value = ''

      if (!newBeneficiary.value.label.trim() || !newBeneficiary.value.address.trim()) {
        beneficiaryError.value = 'Nom et adresse sont requis'
        return
      }

      isAddingBeneficiary.value = true
      try {
        const response = await fetch('/api/beneficiaries', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          credentials: 'include',
          body: JSON.stringify(newBeneficiary.value),
        })
        const data = await response.json()
        if (!response.ok) {
          throw new Error(data.error || 'Erreur lors de l\'ajout du bénéficiaire')
        }
        beneficiaries.value.push(data.beneficiary)
        newBeneficiary.value = { label: '', address: '' }
        beneficiarySuccess.value = 'Bénéficiaire ajouté avec succès'
      } catch (error) {
        beneficiaryError.value = error.message
      } finally {
        isAddingBeneficiary.value = false
      }
    }

    const removeBeneficiary = async (beneficiaryId) => {
      beneficiaryError.value = ''
      beneficiarySuccess.value = ''
      try {
        const response = await fetch(`/api/beneficiaries/${beneficiaryId}`, {
          method: 'DELETE',
          credentials: 'include',
        })
        if (!response.ok) {
          const data = await response.json()
          throw new Error(data.error || 'Erreur lors de la suppression')
        }
        beneficiaries.value = beneficiaries.value.filter((b) => b.beneficiary_id !== beneficiaryId)
      } catch (error) {
        beneficiaryError.value = error.message
      }
    }

    const sendToBeneficiary = async (beneficiary) => {
      beneficiaryError.value = ''
      beneficiarySuccess.value = ''

      const amount = parseFloat(sendAmounts.value[beneficiary.beneficiary_id])
      if (!amount || amount <= 0) {
        beneficiaryError.value = 'Indiquez un montant valide'
        return
      }

      sendingTo.value = beneficiary.beneficiary_id
      try {
        const response = await fetch('/api/blockchain/transaction', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          credentials: 'include',
          body: JSON.stringify({
            toAddress: beneficiary.address,
            amount,
          }),
        })
        const data = await response.json()
        if (!response.ok) {
          throw new Error(data.error || 'Transaction échouée')
        }
        beneficiarySuccess.value = `${amount} CCT envoyés à ${beneficiary.label}`
        sendAmounts.value[beneficiary.beneficiary_id] = ''
        await loadProfileData()
      } catch (error) {
        beneficiaryError.value = error.message
      } finally {
        sendingTo.value = null
      }
    }

    const handleAvatarChange = async (event) => {
      const file = event.target.files?.[0]
      if (!file) return

      avatarError.value = ''
      isUploadingAvatar.value = true

      try {
        const formData = new FormData()
        formData.append('avatar', file)

        const response = await fetch('/api/profile/avatar', {
          method: 'POST',
          credentials: 'include',
          body: formData,
        })

        const data = await response.json()
        if (!response.ok) {
          throw new Error(data.error || 'Erreur lors de l\'envoi de la photo')
        }

        userInfo.value.avatar_url = data.avatar_url
      } catch (error) {
        avatarError.value = error.message
      } finally {
        isUploadingAvatar.value = false
        if (avatarInput.value) avatarInput.value.value = ''
      }
    }

    const removeAvatar = async () => {
      avatarError.value = ''
      try {
        const response = await fetch('/api/profile/avatar', {
          method: 'DELETE',
          credentials: 'include',
        })
        if (!response.ok) {
          const data = await response.json()
          throw new Error(data.error || 'Erreur lors de la suppression de la photo')
        }
        userInfo.value.avatar_url = ''
      } catch (error) {
        avatarError.value = error.message
      }
    }

    const linkLinkedIn = () => {
      window.location.href = '/api/auth/linkedin/link?returnTo=/profile'
    }

    const unlinkLinkedIn = async () => {
      linkedinError.value = ''
      linkedinMessage.value = ''
      try {
        const response = await fetch('/api/auth/linkedin/link', {
          method: 'DELETE',
          credentials: 'include',
        })
        const data = await response.json()
        if (!response.ok) {
          throw new Error(data.error || 'Erreur lors de la déliaison')
        }
        userInfo.value.linkedin_email = ''
        linkedinMessage.value = 'Compte LinkedIn délié avec succès'
      } catch (error) {
        linkedinError.value = error.message
      }
    }

    const confirmBecomeTutor = async () => {
      becomeTutorError.value = ''

      const confirmed = confirm(
        '⚠️ ATTENTION ⚠️\n\n' +
        'Vous êtes sur le point de transformer votre compte étudiant en compte tuteur.\n\n' +
        'Cette action est DÉFINITIVE : vous ne pourrez plus redevenir étudiant(e) avec ce compte.\n\n' +
        'Voulez-vous continuer ?'
      )
      if (!confirmed) return

      isBecomingTutor.value = true
      try {
        const response = await fetch('/api/profile/become-tutor', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          credentials: 'include',
          body: JSON.stringify({
            lesson_mode: becomeTutorForm.value.lesson_mode,
            visio_tool: becomeTutorForm.value.visio_tool,
            lesson_places: becomeTutorForm.value.lesson_places_raw
              .split(',')
              .map((value) => value.trim())
              .filter((value) => value.length > 0),
          }),
        })
        const data = await response.json()
        if (!response.ok) {
          throw new Error(data.error || 'Erreur lors du changement de statut')
        }
        showBecomeTutorForm.value = false
        await loadProfileData()
      } catch (error) {
        becomeTutorError.value = error.message
      } finally {
        isBecomingTutor.value = false
      }
    }

    const logout = async () => {
      try {
        await fetch('/api/logout', {
          method: 'POST',
          credentials: 'include',
        })
        router.push('/home')
      } catch (error) {
        console.error('Logout failed:', error)
      }
    }

    const confirmDeleteAccount = async () => {
      const confirmed = confirm(
        '⚠️ ATTENTION ⚠️\n\n' +
        'Êtes-vous absolument sûr de vouloir supprimer votre compte ?\n\n' +
        'Cette action est IRRÉVERSIBLE et supprimera :\n' +
        '• Votre profil et vos informations personnelles\n' +
        '• Votre wallet et votre solde blockchain\n' +
        '• Tous vos services créés\n' +
        '• Toutes vos transactions\n' +
        '• Toutes vos annonces et messages\n\n' +
        'Tapez OK pour confirmer la suppression définitive.'
      )

      if (!confirmed) return

      const doubleConfirm = confirm(
        'Dernière confirmation : Voulez-vous vraiment supprimer votre compte de manière permanente ?'
      )

      if (!doubleConfirm) return

      try {
        const response = await fetch('/api/account', {
          method: 'DELETE',
          credentials: 'include',
        })

        if (response.ok) {
          alert('Votre compte a été supprimé avec succès.')
          router.push('/home')
        } else {
          const data = await response.json()
          alert('Erreur lors de la suppression du compte : ' + (data.error || 'Erreur inconnue'))
        }
      } catch (error) {
        console.error('Delete account failed:', error)
        alert('Erreur lors de la suppression du compte')
      }
    }

    onMounted(() => {
      loadProfileData()
      loadBeneficiaries()

      // Retour depuis le flux de liaison LinkedIn (?linkedin=linked|conflict)
      const linkedinStatus = route.query.linkedin
      if (linkedinStatus === 'linked') {
        linkedinMessage.value = 'Compte LinkedIn lié avec succès !'
      } else if (linkedinStatus === 'conflict') {
        linkedinError.value = 'Ce compte LinkedIn est déjà utilisé par un autre compte CryptoCampus'
      }
      if (linkedinStatus) {
        router.replace({ query: {} })
      }
    })

    return {
      balance,
      blockchainAddress,
      stats,
      userInfo,
      passwordForm,
      locationForm,
      isResettingPassword,
      isSavingLocations,
      passwordError,
      passwordSuccess,
      locationError,
      locationSuccess,
      referralCopied,
      formatDate,
      getRoleLabel,
      resetPassword,
      saveLessonLocations,
      logout,
      confirmDeleteAccount,
      copyReferralCode,
      beneficiaries,
      newBeneficiary,
      isAddingBeneficiary,
      beneficiaryError,
      beneficiarySuccess,
      sendAmounts,
      sendingTo,
      addBeneficiary,
      removeBeneficiary,
      sendToBeneficiary,
      linkedinMessage,
      linkedinError,
      linkLinkedIn,
      unlinkLinkedIn,
      showBecomeTutorForm,
      isBecomingTutor,
      becomeTutorError,
      becomeTutorForm,
      confirmBecomeTutor,
      defaultAvatar,
      avatarInput,
      isUploadingAvatar,
      avatarError,
      handleAvatarChange,
      removeAvatar,
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

/* Profile Header */
.profile-header {
  display: flex;
  align-items: center;
  gap: 2rem;
  background: white;
  padding: 2rem;
  border-radius: 16px;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.08);
  margin-bottom: 2.5rem;
}

.profile-avatar {
  width: 120px;
  height: 120px;
  border-radius: 50%;
  object-fit: cover;
  border: 4px solid #667eea;
  box-shadow: 0 4px 12px rgba(102, 126, 234, 0.3);
}

.profile-avatar-wrapper {
  position: relative;
  flex-shrink: 0;
  width: 120px;
  height: 120px;
}

.avatar-edit-btn {
  position: absolute;
  bottom: 0;
  right: 0;
  width: 36px;
  height: 36px;
  border-radius: 50%;
  border: 2px solid white;
  background: #667eea;
  color: white;
  font-size: 1rem;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  box-shadow: 0 2px 6px rgba(0, 0, 0, 0.2);
  transition: background 0.2s;
}

.avatar-edit-btn:hover:not(:disabled) {
  background: #5568d3;
}

.avatar-edit-btn:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.avatar-input-hidden {
  display: none;
}

.avatar-remove-link {
  border: none;
  background: none;
  color: #e74c3c;
  font-size: 0.85rem;
  cursor: pointer;
  padding: 0;
  margin-top: 0.5rem;
  text-decoration: underline;
}

.avatar-error {
  margin-top: 0.5rem;
}

.profile-info h1 {
  margin: 0;
  color: #2c3e50;
  font-size: 2rem;
  font-weight: 700;
}

.email {
  color: #667eea;
  font-weight: 600;
  margin: 0.5rem 0 0 0;
  font-size: 1rem;
}

.join-date {
  color: #95a5a6;
  font-size: 0.9rem;
  margin: 0.25rem 0 0 0;
}

/* Status Text */
.status-text {
  color: #7f8c8d;
  font-size: 0.95rem;
  margin: 0.5rem 0 0 0;
}

.status-text strong {
  color: #2c3e50;
  font-weight: 600;
}

/* Main Grid Layout */
.main-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 2.5rem;
  align-items: start;
}

/* Section Titles */
.section-title {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  color: #2c3e50;
  font-size: 1.5rem;
  font-weight: 700;
  margin: 0 0 1.5rem 0;
}

.title-icon {
  font-size: 1.75rem;
}

.card-subtitle {
  color: #2c3e50;
  font-size: 1.1rem;
  font-weight: 600;
  margin: 0 0 1.25rem 0;
}

/* Left Column: Balance & Stats Section */
.balance-stats-section {
  background: white;
  padding: 2rem;
  border-radius: 16px;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.08);
}

/* Balance Card */
.balance-card {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  padding: 2rem;
  border-radius: 12px;
  margin-bottom: 2rem;
  box-shadow: 0 6px 20px rgba(102, 126, 234, 0.3);
}

.balance-content {
  color: white;
}

/* Blockchain Address Card */
.blockchain-card {
  background: linear-gradient(135deg, #2ecc71 0%, #27ae60 100%);
  padding: 1.5rem;
  border-radius: 12px;
  margin-bottom: 2rem;
  box-shadow: 0 4px 16px rgba(46, 204, 113, 0.25);
}

.blockchain-card h3 {
  color: white;
  font-size: 1rem;
  font-weight: 600;
  margin: 0 0 0.75rem 0;
  display: flex;
  align-items: center;
  gap: 0.5rem;
  opacity: 0.95;
  letter-spacing: 0.5px;
}

.blockchain-card code {
  display: block;
  background: rgba(255, 255, 255, 0.2);
  color: white;
  padding: 0.75rem 1rem;
  border-radius: 8px;
  font-family: 'Courier New', monospace;
  font-size: 0.9rem;
  word-break: break-all;
  font-weight: 500;
  border: 1px solid rgba(255, 255, 255, 0.3);
}

.balance-label {
  font-size: 0.95rem;
  opacity: 0.95;
  margin: 0 0 0.75rem 0;
  font-weight: 500;
  letter-spacing: 0.5px;
}

.balance-amount {
  display: flex;
  align-items: center;
  gap: 1rem;
}

.coin-icon {
  font-size: 2.5rem;
}

.balance-value {
  font-size: 3rem;
  font-weight: 700;
  line-height: 1;
}

.coin-label {
  opacity: 0.9;
  font-size: 1.1rem;
  font-weight: 500;
}

/* Stats Grid */
.stats-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 1rem;
}

.stat-card {
  background: linear-gradient(135deg, #f8f9fa 0%, #e9ecef 100%);
  padding: 1.5rem;
  border-radius: 12px;
  display: flex;
  flex-direction: column;
  align-items: center;
  text-align: center;
  gap: 0.75rem;
  transition: transform 0.2s, box-shadow 0.2s;
  border: 2px solid transparent;
}

.stat-card:hover {
  transform: translateY(-4px);
  box-shadow: 0 8px 16px rgba(0, 0, 0, 0.1);
  border-color: #667eea;
}

.stat-icon {
  font-size: 2.5rem;
}

.stat-info h3 {
  margin: 0;
  color: #667eea;
  font-size: 1.75rem;
  font-weight: 700;
}

.stat-info p {
  margin: 0;
  color: #7f8c8d;
  font-size: 0.85rem;
  font-weight: 500;
}

/* Right Column: Security Section */
.security-section {
  background: white;
  padding: 2rem;
  border-radius: 16px;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.08);
}

/* Password Reset Card */
.password-reset-card {
  padding-bottom: 2rem;
  border-bottom: 2px solid #f0f0f0;
  margin-bottom: 2rem;
}

.password-form {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.form-group {
  display: flex;
  flex-direction: column;
}

.form-group label {
  margin-bottom: 0.5rem;
  color: #2c3e50;
  font-weight: 600;
  font-size: 0.9rem;
}

.form-group input {
  padding: 0.875rem;
  border: 2px solid #e0e0e0;
  border-radius: 8px;
  font-size: 1rem;
  font-family: inherit;
  transition: border-color 0.3s, box-shadow 0.3s;
}

.form-group select {
  padding: 0.875rem;
  border: 2px solid #e0e0e0;
  border-radius: 8px;
  font-size: 1rem;
  font-family: inherit;
  background: white;
  transition: border-color 0.3s, box-shadow 0.3s;
}

.form-group input:focus {
  outline: none;
  border-color: #667eea;
  box-shadow: 0 0 0 4px rgba(102, 126, 234, 0.1);
}

.form-group select:focus {
  outline: none;
  border-color: #667eea;
  box-shadow: 0 0 0 4px rgba(102, 126, 234, 0.1);
}

.error-message {
  color: #e74c3c;
  background-color: #fadbd8;
  padding: 1rem;
  border-radius: 8px;
  margin-bottom: 0.5rem;
  font-size: 0.9rem;
  font-weight: 500;
  border-left: 4px solid #e74c3c;
}

.success-message {
  color: #27ae60;
  background-color: #d5f4e6;
  padding: 1rem;
  border-radius: 8px;
  margin-bottom: 0.5rem;
  font-size: 0.9rem;
  font-weight: 500;
  border-left: 4px solid #27ae60;
}

.btn-update {
  padding: 0.875rem 2rem;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  border: none;
  border-radius: 8px;
  font-size: 1rem;
  font-weight: 600;
  cursor: pointer;
  transition: transform 0.2s, box-shadow 0.3s;
  align-self: flex-start;
  box-shadow: 0 4px 12px rgba(102, 126, 234, 0.3);
}

.btn-update:hover:not(:disabled) {
  transform: translateY(-2px);
  box-shadow: 0 6px 16px rgba(102, 126, 234, 0.4);
}

.btn-update:disabled {
  opacity: 0.6;
  cursor: not-allowed;
  transform: none;
}

/* Logout Card */
.logout-card {
  background: linear-gradient(135deg, #fff5f5 0%, #ffe5e5 100%);
  padding: 1.75rem;
  border-radius: 12px;
  border: 2px solid #ffcccc;
}

.logout-content {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 1.5rem;
}

.logout-info {
  flex: 1;
}

.logout-description {
  color: #7f8c8d;
  font-size: 0.9rem;
  margin: 0;
}

.btn-logout {
  padding: 0.875rem 2rem;
  background: linear-gradient(135deg, #e74c3c 0%, #c0392b 100%);
  color: white;
  border: none;
  border-radius: 8px;
  font-size: 1rem;
  font-weight: 600;
  cursor: pointer;
  transition: transform 0.2s, box-shadow 0.3s;
  display: flex;
  align-items: center;
  gap: 0.5rem;
  box-shadow: 0 4px 12px rgba(231, 76, 60, 0.3);
  white-space: nowrap;
}

.btn-logout:hover {
  transform: translateY(-2px);
  box-shadow: 0 6px 16px rgba(231, 76, 60, 0.4);
}

.logout-icon {
  font-size: 1.1rem;
}

/* Delete Account Card */
.delete-account-card {
  background: linear-gradient(135deg, #fff0f0 0%, #ffe0e0 100%);
  padding: 1.75rem;
  border-radius: 12px;
  border: 2px solid #ff9999;
  margin-top: 1.5rem;
}

.delete-account-content {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 1.5rem;
}

.delete-account-info {
  flex: 1;
}

.card-subtitle.danger {
  color: #c0392b;
}

.delete-account-description {
  color: #7f8c8d;
  font-size: 0.9rem;
  margin: 0.5rem 0 0 0;
  line-height: 1.5;
}

.btn-delete-account {
  padding: 0.875rem 2rem;
  background: linear-gradient(135deg, #c0392b 0%, #8b0000 100%);
  color: white;
  border: none;
  border-radius: 8px;
  font-size: 1rem;
  font-weight: 600;
  cursor: pointer;
  transition: transform 0.2s, box-shadow 0.3s;
  display: flex;
  align-items: center;
  gap: 0.5rem;
  box-shadow: 0 4px 12px rgba(192, 57, 43, 0.4);
  white-space: nowrap;
}

.btn-delete-account:hover {
  transform: translateY(-2px);
  box-shadow: 0 6px 16px rgba(192, 57, 43, 0.5);
  background: linear-gradient(135deg, #a93226 0%, #6b0000 100%);
}

.delete-icon {
  font-size: 1.1rem;
}

/* Responsive Design */
@media (max-width: 968px) {
  .main-grid {
    grid-template-columns: 1fr;
    gap: 2rem;
  }

  .stats-grid {
    grid-template-columns: repeat(3, 1fr);
  }
}

@media (max-width: 768px) {
  .container {
    padding: 1rem;
  }

  .profile-header {
    flex-direction: column;
    text-align: center;
    padding: 1.5rem;
  }

  .profile-avatar {
    width: 100px;
    height: 100px;
  }

  .profile-info h1 {
    font-size: 1.5rem;
  }

  .section-title {
    font-size: 1.25rem;
  }

  .balance-stats-section,
  .security-section {
    padding: 1.5rem;
  }

  .stats-grid {
    grid-template-columns: 1fr;
  }

  .logout-content {
    flex-direction: column;
    align-items: stretch;
  }

  .btn-logout {
    width: 100%;
    justify-content: center;
  }
}

/* Referral & Beneficiaries */
.blockchain-address {
  display: flex;
  align-items: center;
  gap: 0.75rem;
}

.blockchain-address code {
  flex: 1;
}

.btn-copy {
  background: rgba(255, 255, 255, 0.25);
  color: white;
  border: 1px solid rgba(255, 255, 255, 0.4);
  border-radius: 8px;
  padding: 0.5rem 1rem;
  font-size: 0.85rem;
  cursor: pointer;
  white-space: nowrap;
  transition: background 0.2s;
}

.btn-copy:hover {
  background: rgba(255, 255, 255, 0.4);
}

.referral-hint {
  color: rgba(255, 255, 255, 0.9);
  font-size: 0.85rem;
  margin-top: 0.75rem;
}

.beneficiaries-section {
  background: white;
  padding: 2rem;
  border-radius: 16px;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.08);
  margin-top: 2rem;
}

.beneficiary-list {
  list-style: none;
  padding: 0;
  margin: 0 0 1.5rem 0;
}

.beneficiary-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  flex-wrap: wrap;
  gap: 1rem;
  padding: 1rem;
  border: 1px solid #eee;
  border-radius: 10px;
  margin-bottom: 0.75rem;
}

.beneficiary-info {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
  min-width: 0;
}

.beneficiary-info code {
  font-size: 0.8rem;
  color: #7f8c8d;
  word-break: break-all;
}

.beneficiary-actions {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  flex-wrap: wrap;
}

.beneficiary-amount {
  width: 110px;
  padding: 0.5rem;
  border: 1px solid #ddd;
  border-radius: 8px;
}

.no-beneficiaries {
  color: #7f8c8d;
  margin-bottom: 1.5rem;
}

.linkedin-status {
  color: #34495e;
  margin-bottom: 1rem;
  line-height: 1.5;
}
</style>