import { describe, it, expect, vi, beforeEach } from 'vitest'
import { useAuth } from './useAuth'

describe('useAuth', () => {
  beforeEach(() => {
    global.fetch = vi.fn()
  })

  it('met à jour les refs quand /api/check-auth répond "connecté"', async () => {
    global.fetch.mockResolvedValueOnce({
      json: async () => ({
        isAuthenticated: true,
        userId: 'u1',
        role: 'TUTOR',
        email: 'tutor@example.com',
        avatarUrl: '/api/uploads/avatars/u1.png',
      }),
    })

    const { isLogged, userId, userRole, userEmail, userAvatarUrl, isTutor, checkAuth } = useAuth()
    await checkAuth()

    expect(isLogged.value).toBe(true)
    expect(userId.value).toBe('u1')
    expect(userRole.value).toBe('TUTOR')
    expect(userEmail.value).toBe('tutor@example.com')
    expect(userAvatarUrl.value).toBe('/api/uploads/avatars/u1.png')
    expect(isTutor.value).toBe(true)
  })

  it('réinitialise l\'état quand /api/check-auth répond "non connecté"', async () => {
    global.fetch.mockResolvedValueOnce({
      json: async () => ({ isAuthenticated: false }),
    })

    const { isLogged, userId, userRole, isTutor, checkAuth } = useAuth()
    await checkAuth()

    expect(isLogged.value).toBe(false)
    expect(userId.value).toBe('')
    expect(userRole.value).toBe('')
    expect(isTutor.value).toBe(false)
  })

  it('gère une erreur réseau sans lever d\'exception, en repassant "non connecté"', async () => {
    global.fetch.mockRejectedValueOnce(new Error('network down'))

    const { isLogged, checkAuth } = useAuth()
    const result = await checkAuth()

    expect(isLogged.value).toBe(false)
    expect(result.isAuthenticated).toBe(false)
  })

  it('partage le même état entre plusieurs appels à useAuth() (singleton)', async () => {
    global.fetch.mockResolvedValueOnce({
      json: async () => ({ isAuthenticated: true, userId: 'shared', role: 'STUDENT' }),
    })

    const a = useAuth()
    await a.checkAuth()

    const b = useAuth()
    expect(b.userId.value).toBe('shared')
    expect(b.isLogged.value).toBe(true)
  })
})
