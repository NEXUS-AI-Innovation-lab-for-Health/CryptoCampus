<template>
  <div id="app" class="app">
    <nav class="navbar" v-if="isLogged !== null">
      <div class="nav-container">
        <router-link to="/home" class="logo">CryptoCampus</router-link>
        <div class="nav-links">
          <router-link
            to="/requetes"
            class="nav-link"
            :class="{ active: currentPage === 'requetes' }"
            >{{ t('nav.requests') }}</router-link
          >
          <router-link
            to="/reservations"
            class="nav-link"
            :class="{ active: currentPage === 'reservations' }"
            v-if="isLogged == true"
            >{{ t('nav.reservations') }}</router-link
          >
          <router-link
            to="/agenda"
            class="nav-link"
            :class="{ active: currentPage === 'agenda' }"
            v-if="isLogged == true"
            >{{ t('nav.agenda') }}</router-link
          >
          <router-link
            to="/favoris"
            class="nav-link"
            :class="{ active: currentPage === 'favoris' }"
            v-if="isLogged == true"
            >{{ t('nav.favorites') }}</router-link
          >
          <router-link
            to="/messages"
            class="nav-link nav-link-messages"
            :class="{ active: currentPage === 'messages' }"
            v-if="isLogged == true"
            >Messagerie<span v-if="unreadTotal > 0" class="nav-unread-badge">{{ unreadTotal }}</span></router-link
          >
          <router-link
            to="/mes-cours"
            class="nav-link"
            :class="{ active: currentPage === 'mes-cours' }"
            v-if="isLogged == true && isTutor"
            >{{ t('nav.myCourses') }}</router-link
          >
          <router-link
            to="/create_request"
            class="nav-link btn-create"
            :class="{ active: currentPage === 'create_request' }"
            v-if="isLogged == true && isTutor"
            >{{ t('nav.createRequest') }}</router-link
          >
          <LanguageSwitcher />
          <div v-if="isLogged" class="profile-button" @click="handleLoginClick">
            <img :src="userAvatarUrl || defaultAvatar" alt="Profil" class="profile-icon" />
            <span class="profile-email">{{ userEmail }}</span>
          </div>
          <button
            v-else
            id="loginBtn"
            class="btn-login"
            @click="handleLoginClick"
          >
            {{ t('nav.login') }}
          </button>
        </div>
      </div>
    </nav>

    <router-view />
  </div>
</template>

<script>
import { computed, onMounted, watch } from "vue";
import { useRouter, useRoute } from "vue-router";
import { useI18n } from "vue-i18n";
import { useAuth } from "@/composables/useAuth";
import { useMessaging } from "@/composables/useMessaging";
import defaultAvatar from "@/assets/utilisateur.png";
import LanguageSwitcher from "@/components/LanguageSwitcher.vue";

export default {
  name: "App",
  components: { LanguageSwitcher },
  setup() {
    const router = useRouter();
    const route = useRoute();
    const { t } = useI18n();
    const { isLogged, userEmail, userAvatarUrl, isTutor, checkAuth } = useAuth();
    const { unreadTotal } = useMessaging();
    const currentPage = computed(() => {
      const path = route.path;
      return path.replace("/", "");
    });

    const handleLoginClick = () => {
      if (isLogged.value) {
        router.push("/profile");
      } else {
        router.push("/login");
      }
    };

    onMounted(() => {
      checkAuth();
    });

    watch(
      () => route.path,
      () => {
        // Check auth on route change
        checkAuth();
      },
    );

    return {
      t,
      isLogged,
      userEmail,
      userAvatarUrl,
      defaultAvatar,
      isTutor,
      currentPage,
      handleLoginClick,
      unreadTotal,
    };
  },
};
</script>

<style>
* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

body {
  font-family: "Segoe UI", Tahoma, Geneva, Verdana, sans-serif;
  background-color: #f5f5f5;
  color: #333;
}

.navbar {
  background-color: #2c3e50;
  padding: 1rem 2rem;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
  position: sticky;
  top: 0;
  z-index: 1000;
}

.nav-container {
  max-width: 1200px;
  margin: 0 auto;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.logo {
  color: white;
  font-size: 1.5rem;
  font-weight: bold;
  text-decoration: none;
  cursor: pointer;
  transition: color 0.3s;
}

.logo:hover {
  color: #3498db;
}

.nav-links {
  display: flex;
  gap: 2rem;
  align-items: center;
}

.nav-link {
  color: #bdc3c7;
  text-decoration: none;
  transition: color 0.3s;
  padding: 0.5rem 1rem;
  border-radius: 4px;
}

.nav-link:hover,
.nav-link.active {
  color: #3498db;
  background-color: rgba(52, 152, 219, 0.1);
}

.nav-link-messages {
  position: relative;
}

.nav-unread-badge {
  display: inline-block;
  background: #e74c3c;
  color: white;
  font-size: 0.7rem;
  font-weight: bold;
  border-radius: 999px;
  padding: 0.1rem 0.45rem;
  margin-left: 0.35rem;
}

.btn-create {
  background-color: #27ae60;
  color: white !important;
  padding: 0.5rem 1rem;
  border-radius: 4px;
  transition: background-color 0.3s;
}

.btn-create:hover {
  background-color: #229954;
}

.btn-login {
  background-color: #3498db;
  color: white;
  padding: 0.5rem 1rem;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  transition: background-color 0.3s;
}

.btn-login:hover {
  background-color: #2980b9;
}

.btn-logout {
  background-color: #e74c3c;
}

.btn-logout:hover {
  background-color: #c0392b;
}

.profile-button {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 0.25rem;
  cursor: pointer;
  transition: transform 0.3s;
}

.profile-button:hover {
  transform: scale(1.05);
}

.profile-icon {
  width: 40px;
  height: 40px;
  border-radius: 50%;
  object-fit: cover;
  border: 2px solid #3498db;
  transition: border-color 0.3s;
}

.profile-button:hover .profile-icon {
  border-color: #2980b9;
}

.profile-email {
  color: #bdc3c7;
  font-size: 0.75rem;
  text-align: center;
  max-width: 50px;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  transition: color 0.3s;
}

.profile-button:hover .profile-email {
  color: #3498db;
}

.app {
  min-height: 100vh;
}
</style>
