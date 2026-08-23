import { ref, computed } from 'vue'
import { useAuth } from './useAuth'
import { useSocket } from './useSocket'

// État partagé (singleton, même pattern que useAuth/useSocket) : la liste des
// conversations et le compteur de non-lus doivent rester à jour partout dans l'app (badge
// de nav dans App.vue, page Messages.vue), pas seulement quand la page Messages est ouverte.
const conversations = ref([])
const loaded = ref(false)

const unreadTotal = computed(() =>
  conversations.value.reduce((sum, c) => sum + (c.unreadCount || 0), 0)
)

async function loadConversations() {
  try {
    const response = await fetch('/api/conversations', { credentials: 'include' })
    const data = await response.json()
    if (response.ok) {
      conversations.value = data.conversations || []
      loaded.value = true
    }
  } catch (error) {
    console.error('Erreur chargement conversations:', error)
  }
}

function applyIncomingMessage({ conversationId, message }) {
  const existing = conversations.value.find((c) => c.conversationId === conversationId)
  if (existing) {
    existing.lastMessage = { content: message.content, createdAt: message.created_at, senderId: message.sender_id }
    existing.unreadCount = (existing.unreadCount || 0) + 1
    // Fait remonter la conversation en tête de liste, comme le ferait le tri serveur.
    conversations.value = [existing, ...conversations.value.filter((c) => c !== existing)]
  } else {
    // Nouvelle conversation jamais vue par ce client : on recharge tout pour avoir les
    // infos du nouvel interlocuteur (nom, avatar...) sans les dupliquer ici.
    loadConversations()
  }
}

function applyReadReceipt({ conversationId }) {
  const existing = conversations.value.find((c) => c.conversationId === conversationId)
  if (existing) existing.unreadCount = 0
}

let listenersStarted = false

export function useMessaging() {
  const { isLogged } = useAuth()
  const { onNewMessage, onMessageRead } = useSocket()

  if (!listenersStarted) {
    listenersStarted = true
    onNewMessage(applyIncomingMessage)
    onMessageRead(applyReadReceipt)
  }

  if (isLogged.value && !loaded.value) {
    loadConversations()
  }

  async function startConversation(otherUserId) {
    const response = await fetch('/api/conversations', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      credentials: 'include',
      body: JSON.stringify({ other_user_id: otherUserId }),
    })
    const data = await response.json()
    if (!response.ok) {
      throw new Error(data.error || 'Impossible de démarrer la conversation')
    }
    await loadConversations()
    return data.conversationId
  }

  function markLocalConversationRead(conversationId) {
    const existing = conversations.value.find((c) => c.conversationId === conversationId)
    if (existing) existing.unreadCount = 0
  }

  return {
    conversations,
    unreadTotal,
    loadConversations,
    startConversation,
    markLocalConversationRead,
  }
}
