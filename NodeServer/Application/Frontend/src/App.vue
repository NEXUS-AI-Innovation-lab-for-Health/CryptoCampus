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
            >Requêtes</router-link
          >
          <!-- <router-link
            to="/balance"
            class="nav-link"
            :class="{ active: currentPage === 'balance' }"
            v-if="isLogged == true"
            >Mon solde</router-link
          > -->
          <router-link
            to="/shop"
            class="nav-link"
            :class="{ active: currentPage === 'shop' }"
            v-if="isLogged == true"
            >Boutique</router-link
          >
          <router-link
            to="/create_request"
            class="nav-link btn-create"
            :class="{ active: currentPage === 'create_request' }"
            v-if="isLogged == true"
            >Créer une requête</router-link
          >
          <div v-if="isLogged" class="profile-button" @click="handleLoginClick">
            <img src="@/assets/utilisateur.png" alt="Profil" class="profile-icon" />
            <span class="profile-email">{{ userEmail }}</span>
          </div>
          <button
            v-else
            id="loginBtn"
            class="btn-login"
            @click="handleLoginClick"
          >
            Connexion
          </button>
        </div>
      </div>
    </nav>

    <router-view />
  </div>
</template>

<script>
import { ref, computed, onMounted, watch } from "vue";
import { useRouter, useRoute } from "vue-router";

export default {
  name: "App",
  setup() {
    const router = useRouter();
    const route = useRoute();
    const isLogged = ref(null);
    const userEmail = ref("");
    const currentPage = computed(() => {
      const path = route.path;
      return path.replace("/", "");
    });

    const checkAuth = async () => {
      try {
        const response = await fetch("/api/check-auth");
        const data = await response.json();
        isLogged.value = data.isAuthenticated;
        if (data.isAuthenticated && data.email) {
          userEmail.value = data.email;
        }
      } catch (error) {
        console.error("Auth check failed:", error);
        isLogged.value = false;
      }
    };

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
      isLogged,
      userEmail,
      currentPage,
      handleLoginClick,
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
