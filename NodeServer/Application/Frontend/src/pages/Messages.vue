<template>
  <div class="messages-page">
    <div class="messages-layout">
      <!-- Liste des conversations -->
      <aside class="conversations-panel" :class="{ 'hide-on-mobile': activeConversationId }">
        <div class="panel-header">
          <h2>Messagerie</h2>
        </div>
        <div v-if="conversations.length === 0" class="empty-state">
          <p>Aucune conversation pour le moment.</p>
          <p class="hint">
            Contactez un tuteur depuis une annonce, ou un étudiant intéressé depuis "Mes cours".
          </p>
        </div>
        <ul v-else class="conversation-list">
          <li
            v-for="conv in conversations"
            :key="conv.conversationId"
            class="conversation-item"
            :class="{ active: conv.conversationId === activeConversationId }"
            @click="openConversation(conv.conversationId)"
          >
            <img :src="conv.otherUser.avatarUrl || defaultAvatar" alt="" class="avatar" />
            <div class="conversation-info">
              <div class="conversation-top">
                <span class="name">{{ conv.otherUser.firstName }} {{ conv.otherUser.lastName }}</span>
                <span v-if="conv.lastMessage" class="time">{{ formatTime(conv.lastMessage.createdAt) }}</span>
              </div>
              <div class="conversation-bottom">
                <span class="preview">{{ conv.lastMessage ? conv.lastMessage.content : 'Nouvelle conversation' }}</span>
                <span v-if="conv.unreadCount > 0" class="unread-badge">{{ conv.unreadCount }}</span>
              </div>
            </div>
          </li>
        </ul>
      </aside>

      <!-- Fil de discussion -->
      <section class="thread-panel" :class="{ 'hide-on-mobile': !activeConversationId }">
        <template v-if="activeConversation">
          <div class="thread-header">
            <button class="back-btn" @click="closeThread">←</button>
            <img :src="activeConversation.otherUser.avatarUrl || defaultAvatar" alt="" class="avatar" />
            <div>
              <div class="name">{{ activeConversation.otherUser.firstName }} {{ activeConversation.otherUser.lastName }}</div>
              <div class="role">{{ activeConversation.otherUser.role === 'TUTOR' ? 'Tuteur' : 'Étudiant' }}</div>
            </div>
          </div>

          <div class="thread-messages" ref="messagesContainer">
            <div v-if="loadingMessages" class="loading">Chargement...</div>
            <div
              v-for="msg in messages"
              :key="msg.message_id"
              class="message-bubble"
              :class="{ mine: msg.sender_id === userId }"
            >
              <div class="bubble-content">{{ msg.content }}</div>
              <div class="bubble-time">{{ formatTime(msg.created_at) }}</div>
            </div>
          </div>

          <form class="compose-form" @submit.prevent="sendMessage">
            <input
              v-model="draft"
              type="text"
              placeholder="Écrire un message..."
              :disabled="sending"
            />
            <button type="submit" :disabled="sending || !draft.trim()">Envoyer</button>
          </form>
        </template>
        <div v-else class="empty-thread">
          <p>Sélectionnez une conversation pour l'ouvrir.</p>
        </div>
      </section>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, nextTick, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useAuth } from '@/composables/useAuth'
import { useMessaging } from '@/composables/useMessaging'
import { useSocket } from '@/composables/useSocket'
import defaultAvatar from '@/assets/utilisateur.png'

const route = useRoute()
const router = useRouter()
const { userId } = useAuth()
const { conversations, loadConversations, startConversation, markLocalConversationRead } = useMessaging()
const { onNewMessage } = useSocket()

const activeConversationId = ref(null)
const messages = ref([])
const loadingMessages = ref(false)
const draft = ref('')
const sending = ref(false)
const messagesContainer = ref(null)

const activeConversation = computed(() =>
  conversations.value.find((c) => c.conversationId === activeConversationId.value) || null
)

function formatTime(dateString) {
  const date = new Date(dateString)
  const now = new Date()
  const sameDay = date.toDateString() === now.toDateString()
  return sameDay
    ? date.toLocaleTimeString('fr-FR', { hour: '2-digit', minute: '2-digit' })
    : date.toLocaleDateString('fr-FR', { day: '2-digit', month: '2-digit' })
}

async function scrollToBottom() {
  await nextTick()
  if (messagesContainer.value) {
    messagesContainer.value.scrollTop = messagesContainer.value.scrollHeight
  }
}

async function openConversation(conversationId) {
  activeConversationId.value = conversationId
  loadingMessages.value = true
  messages.value = []
  try {
    const response = await fetch(`/api/conversations/${conversationId}/messages`, { credentials: 'include' })
    const data = await response.json()
    if (response.ok) {
      messages.value = data.messages || []
    }
    // Marque comme lu (best-effort, non bloquant pour l'affichage)
    fetch(`/api/conversations/${conversationId}/read`, { method: 'PUT', credentials: 'include' }).catch(() => {})
    markLocalConversationRead(conversationId)
  } finally {
    loadingMessages.value = false
    scrollToBottom()
  }
}

function closeThread() {
  activeConversationId.value = null
}

async function sendMessage() {
  const content = draft.value.trim()
  if (!content || !activeConversationId.value) return

  sending.value = true
  try {
    const response = await fetch(`/api/conversations/${activeConversationId.value}/messages`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      credentials: 'include',
      body: JSON.stringify({ content }),
    })
    const data = await response.json()
    if (response.ok) {
      messages.value.push(data.message)
      draft.value = ''
      scrollToBottom()
    }
  } finally {
    sending.value = false
  }
}

onNewMessage(({ conversationId, message }) => {
  if (conversationId === activeConversationId.value) {
    messages.value.push(message)
    scrollToBottom()
    fetch(`/api/conversations/${conversationId}/read`, { method: 'PUT', credentials: 'include' }).catch(() => {})
    markLocalConversationRead(conversationId)
  }
})

onMounted(async () => {
  await loadConversations()

  // ?with=<user_id> : arrivée depuis un bouton "Contacter" ailleurs dans l'app —
  // ouvre directement (ou crée) la conversation avec cette personne.
  const withUserId = route.query.with
  if (withUserId) {
    try {
      const conversationId = await startConversation(withUserId)
      await openConversation(conversationId)
    } catch (error) {
      console.error('Impossible de démarrer la conversation:', error)
    }
    router.replace({ query: {} })
  }
})
</script>

<style scoped>
.messages-page {
  max-width: 1200px;
  margin: 0 auto;
  padding: 1.5rem;
  height: calc(100vh - 100px);
}

.messages-layout {
  display: grid;
  grid-template-columns: 320px 1fr;
  gap: 1.5rem;
  height: 100%;
  background: white;
  border-radius: 12px;
  overflow: hidden;
  box-shadow: 0 2px 12px rgba(0, 0, 0, 0.08);
}

.conversations-panel {
  border-right: 1px solid #ecf0f1;
  display: flex;
  flex-direction: column;
  overflow-y: auto;
}

.panel-header {
  padding: 1.25rem;
  border-bottom: 1px solid #ecf0f1;
}

.panel-header h2 {
  margin: 0;
  color: #2c3e50;
}

.empty-state,
.empty-thread {
  padding: 2rem 1.25rem;
  color: #7f8c8d;
  text-align: center;
}

.empty-state .hint {
  font-size: 0.85rem;
  margin-top: 0.5rem;
}

.conversation-list {
  list-style: none;
  margin: 0;
  padding: 0;
}

.conversation-item {
  display: flex;
  gap: 0.75rem;
  padding: 0.9rem 1.25rem;
  cursor: pointer;
  border-bottom: 1px solid #f5f5f5;
  transition: background-color 0.15s;
}

.conversation-item:hover {
  background-color: #f8f9fa;
}

.conversation-item.active {
  background-color: #eef0ff;
}

.avatar {
  width: 44px;
  height: 44px;
  border-radius: 50%;
  object-fit: cover;
  flex-shrink: 0;
}

.conversation-info {
  min-width: 0;
  flex: 1;
}

.conversation-top,
.conversation-bottom {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 0.5rem;
}

.conversation-top .name {
  font-weight: 600;
  color: #2c3e50;
}

.conversation-top .time {
  font-size: 0.75rem;
  color: #95a5a6;
  flex-shrink: 0;
}

.conversation-bottom .preview {
  font-size: 0.85rem;
  color: #7f8c8d;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.unread-badge {
  background: #667eea;
  color: white;
  font-size: 0.7rem;
  font-weight: bold;
  border-radius: 999px;
  padding: 0.1rem 0.5rem;
  flex-shrink: 0;
}

.thread-panel {
  display: flex;
  flex-direction: column;
  min-width: 0;
}

.thread-header {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  padding: 1rem 1.25rem;
  border-bottom: 1px solid #ecf0f1;
}

.thread-header .name {
  font-weight: 600;
  color: #2c3e50;
}

.thread-header .role {
  font-size: 0.8rem;
  color: #7f8c8d;
}

.back-btn {
  display: none;
  border: none;
  background: none;
  font-size: 1.3rem;
  cursor: pointer;
  padding: 0 0.5rem 0 0;
}

.thread-messages {
  flex: 1;
  overflow-y: auto;
  padding: 1.25rem;
  display: flex;
  flex-direction: column;
  gap: 0.6rem;
}

.message-bubble {
  max-width: 65%;
  align-self: flex-start;
}

.message-bubble.mine {
  align-self: flex-end;
}

.bubble-content {
  background: #f1f2f6;
  padding: 0.6rem 0.9rem;
  border-radius: 14px 14px 14px 4px;
  color: #2c3e50;
  word-wrap: break-word;
}

.message-bubble.mine .bubble-content {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  border-radius: 14px 14px 4px 14px;
}

.bubble-time {
  font-size: 0.7rem;
  color: #aaa;
  margin-top: 0.2rem;
  text-align: right;
}

.compose-form {
  display: flex;
  gap: 0.75rem;
  padding: 1rem 1.25rem;
  border-top: 1px solid #ecf0f1;
}

.compose-form input {
  flex: 1;
  padding: 0.7rem 1rem;
  border: 1px solid #ddd;
  border-radius: 999px;
  outline: none;
}

.compose-form input:focus {
  border-color: #667eea;
}

.compose-form button {
  padding: 0.7rem 1.5rem;
  border: none;
  border-radius: 999px;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  font-weight: 600;
  cursor: pointer;
}

.compose-form button:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.loading {
  text-align: center;
  color: #7f8c8d;
  padding: 1rem;
}

@media (max-width: 768px) {
  .messages-layout {
    grid-template-columns: 1fr;
  }
  .conversations-panel.hide-on-mobile,
  .thread-panel.hide-on-mobile {
    display: none;
  }
  .back-btn {
    display: inline-block;
  }
}
</style>
