import { describe, it, expect, vi, beforeEach } from 'vitest'
import { mount } from '@vue/test-utils'
import Login from './Login.vue'

vi.mock('vue-router', () => ({
  useRouter: () => ({ push: vi.fn(), replace: vi.fn() }),
  useRoute: () => ({ query: {} }),
}))

vi.mock('vue-i18n', () => ({
  useI18n: () => ({ t: (key) => key }),
}))

describe('Login.vue - choix du rôle à l\'inscription', () => {
  beforeEach(() => {
    global.fetch = vi.fn().mockResolvedValue({ json: async () => ({}) })
  })

  async function goToRegisterTab(wrapper) {
    await wrapper.find('.tabs .tab:nth-child(2)').trigger('click')
  }

  it("n'affiche ni le code de parrainage ni les infos de cours tant qu'aucun rôle n'est choisi", async () => {
    const wrapper = mount(Login)
    await goToRegisterTab(wrapper)

    expect(wrapper.find('#registerReferralCode').exists()).toBe(false)
    expect(wrapper.find('.tutor-location-fields').exists()).toBe(false)
  })

  it('affiche le champ code de parrainage (et pas les infos de cours) quand "étudiant" est choisi', async () => {
    const wrapper = mount(Login)
    await goToRegisterTab(wrapper)

    const studentBtn = wrapper.findAll('.role-choice .role-btn')[0]
    await studentBtn.trigger('click')

    expect(wrapper.find('#registerReferralCode').exists()).toBe(true)
    expect(wrapper.find('.tutor-location-fields').exists()).toBe(false)
  })

  it('affiche les infos de cours (et pas le code de parrainage) quand "tuteur" est choisi', async () => {
    const wrapper = mount(Login)
    await goToRegisterTab(wrapper)

    const tutorBtn = wrapper.findAll('.role-choice .role-btn')[1]
    await tutorBtn.trigger('click')

    expect(wrapper.find('.tutor-location-fields').exists()).toBe(true)
    expect(wrapper.find('#registerReferralCode').exists()).toBe(false)
  })

  it('désactive le bouton de création de compte tant que le code de parrainage est vide (rôle étudiant)', async () => {
    const wrapper = mount(Login)
    await goToRegisterTab(wrapper)

    await wrapper.findAll('.role-choice .role-btn')[0].trigger('click')
    const submitBtn = wrapper.find('form.active button[type="submit"]')
    expect(submitBtn.attributes('disabled')).toBeDefined()

    await wrapper.find('#registerReferralCode').setValue('ABCD1234')
    expect(wrapper.find('form.active button[type="submit"]').attributes('disabled')).toBeUndefined()
  })

  it('active le bouton de création de compte dès que "tuteur" est choisi (pas de code requis)', async () => {
    const wrapper = mount(Login)
    await goToRegisterTab(wrapper)

    await wrapper.findAll('.role-choice .role-btn')[1].trigger('click')
    const submitBtn = wrapper.find('form.active button[type="submit"]')
    expect(submitBtn.attributes('disabled')).toBeUndefined()
  })
})
