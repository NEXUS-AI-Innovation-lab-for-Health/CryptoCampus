import { createRouter, createWebHistory } from 'vue-router'
import Home from './pages/Home.vue'
import RequestsList from './pages/RequestsList.vue'
import Login from './pages/Login.vue'
import Balance from './pages/Balance.vue'
import Shop from './pages/Shop.vue'
import CreateRequest from './pages/CreateRequest.vue'
import Profile from './pages/Profile.vue'
import Logout from './pages/Logout.vue'
import Agenda from './pages/Agenda.vue'
import Reservations from './pages/Reservations.vue'

const routes = [
  { path: '/', redirect: '/home' },
  { path: '/home', component: Home },
  { path: '/requetes', component: RequestsList },
  { path: '/login', component: Login },
  { path: '/balance', component: Balance },
  { path: '/shop', component: Shop },
  { path: '/create_request', component: CreateRequest },
  { path: '/profile', component: Profile },
  { path: '/logout', component: Logout },
  { path: '/agenda', component: Agenda },
  { path: '/reservations', component: Reservations },
]

const router = createRouter({
  history: createWebHistory(),
  routes,
})

export default router
