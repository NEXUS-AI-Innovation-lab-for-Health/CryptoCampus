<template>
  <transition name="fade">
    <div v-if="isLoading" class="loading-overlay">
      <img :src="logo" alt="CryptoCampus" class="loading-logo" />
      <div class="loading-progress">
        <div class="loading-progress-bar"></div>
      </div>
    </div>
  </transition>
  <div class="home">
    <!-- Hero Section -->
    <section class="hero">
      <div class="hero-content">
        <h1>{{ t('home.hero.title') }}</h1>
        <p class="subtitle">{{ t('home.hero.subtitle') }}</p>
        <div class="cta-buttons">
          <router-link to="/requetes" class="btn btn-primary">{{ t('home.hero.browse') }}</router-link>
          <router-link to="/login" v-if="!isLogged" class="btn btn-secondary">{{ t('home.hero.login') }}</router-link>
          <router-link to="/create_request" v-if="isLogged && isTutor" class="btn btn-secondary">{{ t('home.hero.createRequest') }}</router-link>
        </div>
      </div>
    </section>

    <!-- Features Section -->
    <section class="features">
      <h2>{{ t('home.features.title') }}</h2>
      <div class="features-grid">
        <div class="feature-card">
          <div class="feature-icon">🤝</div>
          <h3>{{ t('home.features.mutualHelp.title') }}</h3>
          <p>{{ t('home.features.mutualHelp.description') }}</p>
        </div>
        <div class="feature-card">
          <div class="feature-icon">💰</div>
          <h3>{{ t('home.features.rewards.title') }}</h3>
          <p>{{ t('home.features.rewards.description') }}</p>
        </div>
        <div class="feature-card">
          <div class="feature-icon">🔐</div>
          <h3>{{ t('home.features.secure.title') }}</h3>
          <p>{{ t('home.features.secure.description') }}</p>
        </div>
        <div class="feature-card">
          <div class="feature-icon">📚</div>
          <h3>{{ t('home.features.subjects.title') }}</h3>
          <p>{{ t('home.features.subjects.description') }}</p>
        </div>
        <div class="feature-card">
          <div class="feature-icon">⚡</div>
          <h3>{{ t('home.features.fast.title') }}</h3>
          <p>{{ t('home.features.fast.description') }}</p>
        </div>
        <div class="feature-card">
          <div class="feature-icon">🎯</div>
          <h3>{{ t('home.features.quality.title') }}</h3>
          <p>{{ t('home.features.quality.description') }}</p>
        </div>
      </div>
    </section>

    <!-- How It Works Section -->
    <section class="how-it-works">
      <h2>{{ t('home.howItWorks.title') }}</h2>
      <div class="steps">
        <div class="step">
          <div class="step-number">1</div>
          <h3>{{ t('home.howItWorks.step1.title') }}</h3>
          <p>{{ t('home.howItWorks.step1.description') }}</p>
        </div>
        <div class="step">
          <div class="step-number">2</div>
          <h3>{{ t('home.howItWorks.step2.title') }}</h3>
          <p>{{ t('home.howItWorks.step2.description') }}</p>
        </div>
        <div class="step">
          <div class="step-number">3</div>
          <h3>{{ t('home.howItWorks.step3.title') }}</h3>
          <p>{{ t('home.howItWorks.step3.description') }}</p>
        </div>
        <div class="step">
          <div class="step-number">4</div>
          <h3>{{ t('home.howItWorks.step4.title') }}</h3>
          <p>{{ t('home.howItWorks.step4.description') }}</p>
        </div>
      </div>
    </section>

    <!-- Stats Section -->
    <section class="stats">
      <div class="stat">
        <h3>1000+</h3>
        <p>{{ t('home.stats.activeStudents') }}</p>
      </div>
      <div class="stat">
        <h3>5000+</h3>
        <p>{{ t('home.stats.resolvedRequests') }}</p>
      </div>
      <div class="stat">
        <h3>50+</h3>
        <p>{{ t('home.stats.subjects') }}</p>
      </div>
    </section>

    <!-- CTA Section -->
    <section class="final-cta">
      <h2>{{ t('home.finalCta.title') }}</h2>
      <p>{{ t('home.finalCta.subtitle') }}</p>
      <router-link to="/login" v-if="!isLogged" class="btn btn-primary btn-large">{{ t('home.finalCta.register') }}</router-link>
      <router-link to="/requetes" v-else class="btn btn-primary btn-large">{{ t('home.finalCta.browse') }}</router-link>
    </section>
  </div>
</template>

<script>
import { ref, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import { useI18n } from 'vue-i18n'
import { useAuth } from '@/composables/useAuth'
import logo from '@/assets/vrai_logo.png'

const MIN_SPLASH_DURATION = 2000

export default {
  name: 'Home',
  setup() {
    const route = useRoute()
    const { t } = useI18n()
    const { isLogged, isTutor, checkAuth } = useAuth()
    // La bannière de bienvenue ne s'affiche que lors d'une arrivée depuis
    // l'extérieur du site (URL tapée, lien externe, rafraîchissement) : voir
    // le flag `isFreshEntry` posé dans router.js. En navigation interne
    // (clic sur un lien depuis une autre page de la SPA), on charge la page
    // instantanément, sans écran de chargement.
    const isLoading = ref(route.meta.isFreshEntry === true)

    onMounted(async () => {
      if (!isLoading.value) {
        // Navigation interne : pas d'écran de chargement, juste la donnée en tâche de fond.
        checkAuth()
        return
      }

      const start = Date.now()
      await checkAuth()
      const remaining = MIN_SPLASH_DURATION - (Date.now() - start)
      if (remaining > 0) {
        await new Promise((resolve) => setTimeout(resolve, remaining))
      }
      isLoading.value = false
    })

    return {
      t,
      isLogged,
      isTutor,
      isLoading,
      logo,
    }
  }
}
</script>

<style scoped>
.fade-leave-active {
  transition: opacity 0.6s ease;
}

.fade-leave-to {
  opacity: 0;
}

.loading-overlay {
  position: fixed;
  inset: 0;
  z-index: 9999;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 2.5rem;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
}

.loading-logo {
  width: 340px;
  max-width: 80vw;
  height: auto;
  animation: loading-pulse 1.2s ease-in-out infinite;
}

@keyframes loading-pulse {
  0%, 100% {
    transform: scale(1.5);
    opacity: 1;
  }
  50% {
    transform: scale(1.25);
    opacity: 0.7;
  }
}

.loading-progress {
  width: 240px;
  max-width: 60vw;
  height: 6px;
  border-radius: 3px;
  background: rgba(255, 255, 255, 0.25);
  overflow: hidden;
}

.loading-progress-bar {
  height: 100%;
  width: 0%;
  background: white;
  border-radius: 3px;
  animation: loading-fill 2s linear forwards;
}

@keyframes loading-fill {
  from {
    width: 0%;
  }
  to {
    width: 100%;
  }
}

.home {
  width: 100%;
}

/* Hero Section */
.hero {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  padding: 6rem 2rem;
  text-align: center;
}

.hero-content h1 {
  font-size: 3rem;
  margin-bottom: 1rem;
  font-weight: bold;
}

.subtitle {
  font-size: 1.3rem;
  margin-bottom: 2rem;
  opacity: 0.9;
}

.cta-buttons {
  display: flex;
  gap: 1rem;
  justify-content: center;
  flex-wrap: wrap;
}

.btn {
  padding: 0.75rem 2rem;
  border-radius: 4px;
  text-decoration: none;
  font-weight: 500;
  transition: all 0.3s;
  display: inline-block;
}

.btn-primary {
  background-color: white;
  color: #667eea;
}

.btn-primary:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.2);
}

.btn-secondary {
  background-color: transparent;
  color: white;
  border: 2px solid white;
}

.btn-secondary:hover {
  background-color: white;
  color: #667eea;
  transform: translateY(-2px);
}

.btn-large {
  padding: 1rem 3rem;
  font-size: 1.1rem;
}

/* Features Section */
.features {
  padding: 4rem 2rem;
  max-width: 1200px;
  margin: 0 auto;
}

.features h2 {
  text-align: center;
  font-size: 2.5rem;
  margin-bottom: 3rem;
  color: #2c3e50;
}

.features-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
  gap: 2rem;
}

.feature-card {
  background: white;
  padding: 2rem;
  border-radius: 8px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
  text-align: center;
  transition: transform 0.3s, box-shadow 0.3s;
}

.feature-card:hover {
  transform: translateY(-8px);
  box-shadow: 0 8px 16px rgba(0, 0, 0, 0.15);
}

.feature-icon {
  font-size: 3rem;
  margin-bottom: 1rem;
}

.feature-card h3 {
  color: #2c3e50;
  margin-bottom: 0.5rem;
}

.feature-card p {
  color: #7f8c8d;
  line-height: 1.6;
}

/* How It Works Section */
.how-it-works {
  background-color: #f5f5f5;
  padding: 4rem 2rem;
}

.how-it-works h2 {
  text-align: center;
  font-size: 2.5rem;
  margin-bottom: 3rem;
  color: #2c3e50;
}

.steps {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  gap: 2rem;
  max-width: 1200px;
  margin: 0 auto;
}

.step {
  background: white;
  padding: 2rem;
  border-radius: 8px;
  text-align: center;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
}

.step-number {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 50px;
  height: 50px;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  border-radius: 50%;
  font-size: 1.5rem;
  font-weight: bold;
  margin-bottom: 1rem;
}

.step h3 {
  color: #2c3e50;
  margin-bottom: 0.5rem;
}

.step p {
  color: #7f8c8d;
}

/* Stats Section */
.stats {
  padding: 4rem 2rem;
  max-width: 1200px;
  margin: 0 auto;
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 2rem;
  text-align: center;
}

.stat h3 {
  font-size: 2.5rem;
  color: #667eea;
  margin-bottom: 0.5rem;
}

.stat p {
  color: #7f8c8d;
  font-size: 1.1rem;
}

/* Final CTA Section */
.final-cta {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  padding: 4rem 2rem;
  text-align: center;
}

.final-cta h2 {
  font-size: 2.5rem;
  margin-bottom: 1rem;
}

.final-cta p {
  font-size: 1.2rem;
  margin-bottom: 2rem;
  opacity: 0.9;
}

@media (max-width: 768px) {
  .hero-content h1 {
    font-size: 2rem;
  }

  .subtitle {
    font-size: 1rem;
  }

  .features h2,
  .how-it-works h2,
  .final-cta h2 {
    font-size: 2rem;
  }

  .cta-buttons {
    flex-direction: column;
  }

  .btn {
    width: 100%;
  }
}
</style>
