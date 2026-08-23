import { ref, watch } from 'vue'
import { io } from 'socket.io-client'
import { useAuth } from './useAuth'

// Connexion Socket.io singleton (comme useAuth : état partagé entre tous les appelants).
// Se connecte/déconnecte automatiquement en fonction de l'état de connexion utilisateur.
// path: '/api/socket.io' : reste sous le préfixe déjà proxifié par Nginx/Vite vers l'API
// (voir server.js, nginx.conf, vite.config.js) — pas de nouveau bloc proxy à maintenir.
let socket = null
const isConnected = ref(false)
const messageListeners = new Set()
const readListeners = new Set()

function connect() {
  if (socket) return
  socket = io({
    path: '/api/socket.io',
    withCredentials: true,
  })

  socket.on('connect', () => {
    isConnected.value = true
  })
  socket.on('disconnect', () => {
    isConnected.value = false
  })
  socket.on('message:new', (payload) => {
    messageListeners.forEach((cb) => cb(payload))
  })
  socket.on('message:read', (payload) => {
    readListeners.forEach((cb) => cb(payload))
  })
}

function disconnect() {
  if (socket) {
    socket.disconnect()
    socket = null
  }
  isConnected.value = false
}

let watcherStarted = false

export function useSocket() {
  const { isLogged } = useAuth()

  if (!watcherStarted) {
    watcherStarted = true
    watch(
      isLogged,
      (logged) => {
        if (logged) connect()
        else disconnect()
      },
      { immediate: true }
    )
  }

  function onNewMessage(callback) {
    messageListeners.add(callback)
    return () => messageListeners.delete(callback)
  }

  function onMessageRead(callback) {
    readListeners.add(callback)
    return () => readListeners.delete(callback)
  }

  return { isConnected, onNewMessage, onMessageRead }
}
