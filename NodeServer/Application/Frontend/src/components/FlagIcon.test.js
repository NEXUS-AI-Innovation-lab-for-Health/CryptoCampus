import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import FlagIcon from './FlagIcon.vue'

const CODES = ['fr', 'en', 'es', 'pt', 'de', 'ja', 'zh']

describe('FlagIcon', () => {
  it.each(CODES)('affiche un <svg> non vide pour le code "%s"', (code) => {
    const wrapper = mount(FlagIcon, { props: { code } })
    const svg = wrapper.find('svg')
    expect(svg.exists()).toBe(true)
    // Un drapeau doit contenir au moins une forme (rect/circle/polygon/path/use)
    expect(svg.element.querySelectorAll('rect, circle, polygon, path, use').length).toBeGreaterThan(0)
  })

  it('utilise le label fourni comme aria-label', () => {
    const wrapper = mount(FlagIcon, { props: { code: 'fr', label: 'Français' } })
    expect(wrapper.find('svg').attributes('aria-label')).toBe('Français')
  })

  it('retombe sur le code comme aria-label si aucun label fourni', () => {
    const wrapper = mount(FlagIcon, { props: { code: 'en' } })
    expect(wrapper.find('svg').attributes('aria-label')).toBe('en')
  })

  it('génère des identifiants uniques entre deux instances (pas de collision de <defs>)', () => {
    const a = mount(FlagIcon, { props: { code: 'en' } })
    const b = mount(FlagIcon, { props: { code: 'en' } })
    const idA = a.find('clipPath').attributes('id')
    const idB = b.find('clipPath').attributes('id')
    expect(idA).not.toBe(idB)
  })
})
