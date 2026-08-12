import { describe, it, expect, beforeEach, vi } from 'vitest'

// On ne monte jamais de composant ici : on ne fait que naviguer avec le routeur et
// inspecter route.meta.isFreshEntry. Cela suffit à vérifier la logique (voir
// router.js) sans avoir à mocker fetch/i18n pour chaque page importée.
describe('router - isFreshEntry', () => {
  beforeEach(() => {
    vi.resetModules()
  })

  it('marque la toute première navigation comme "fraîche", y compris à travers une redirection (/ -> /home)', async () => {
    const { default: router } = await import('./router.js')
    await router.push('/')
    expect(router.currentRoute.value.path).toBe('/home')
    expect(router.currentRoute.value.meta.isFreshEntry).toBe(true)
  })

  it("marque une deuxième navigation comme n'étant plus \"fraîche\" (navigation interne)", async () => {
    const { default: router } = await import('./router.js')
    await router.push('/home')
    await router.push('/login')
    expect(router.currentRoute.value.meta.isFreshEntry).toBe(false)
  })

  it('reste "fraîche" pendant toute la résolution de la première navigation, même vers une route directe (sans redirection)', async () => {
    const { default: router } = await import('./router.js')
    await router.push('/login')
    expect(router.currentRoute.value.meta.isFreshEntry).toBe(true)
  })
})
