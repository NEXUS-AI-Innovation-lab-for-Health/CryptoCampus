import { createRouter, createWebHistory } from 'vue-router'
import Home from './pages/Home.vue'
import RequestsList from './pages/RequestsList.vue'
import Login from './pages/Login.vue'
import Balance from './pages/Balance.vue'
import Favorites from './pages/Favorites.vue'
import CreateRequest from './pages/CreateRequest.vue'
import Profile from './pages/Profile.vue'
import Logout from './pages/Logout.vue'
import Agenda from './pages/Agenda.vue'
import Reservations from './pages/Reservations.vue'
import MyCourses from './pages/MyCourses.vue'

const routes = [
  { path: '/', redirect: '/home' },
  { path: '/home', component: Home },
  { path: '/requetes', component: RequestsList },
  { path: '/login', component: Login },
  { path: '/balance', component: Balance },
  { path: '/favoris', component: Favorites },
  { path: '/shop', redirect: '/favoris' },
  { path: '/create_request', component: CreateRequest },
  { path: '/profile', component: Profile },
  { path: '/logout', component: Logout },
  { path: '/agenda', component: Agenda },
  { path: '/reservations', component: Reservations },
  { path: '/mes-cours', component: MyCourses },
]

const router = createRouter({
  history: createWebHistory(),
  routes,
})

// Marque chaque route traversée par la toute première navigation résolue par
// le routeur (celle déclenchée par le chargement réel du navigateur : URL
// tapée, lien externe, rafraîchissement...). Les navigations suivantes sont
// des changements de route internes à la SPA (clic sur un <router-link>) et
// ne doivent pas être considérées comme une arrivée "depuis l'extérieur".
// On flippe le flag dans afterEach (pas beforeEach) pour que les redirections
// internes (ex: '/' -> '/home') qui font partie de cette première navigation
// restent bien marquées comme fraîches.
let hasCompletedNavigation = false

router.beforeEach((to, from, next) => {
  to.meta.isFreshEntry = !hasCompletedNavigation
  next()
})

router.afterEach(() => {
  hasCompletedNavigation = true
})

export default router
