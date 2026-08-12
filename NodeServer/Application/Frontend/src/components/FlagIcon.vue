<template>
  <svg
    class="flag-icon"
    viewBox="0 0 60 40"
    xmlns="http://www.w3.org/2000/svg"
    role="img"
    :aria-label="ariaLabel"
  >
    <defs>
      <!-- Étoile à 5 branches, unité (rayon 1), pointe vers le haut -->
      <path :id="`star5-${uid}`" d="M0,-1 L0.2245,-0.309 L0.9511,-0.309 L0.3633,0.118 L0.5878,0.809 L0,0.382 L-0.5878,0.809 L-0.3633,0.118 L-0.9511,-0.309 L-0.2245,-0.309 Z" />
      <!-- Découpe diagonale coin haut-gauche / coin bas-droit, comme le drapeau de référence -->
      <clipPath :id="`triUL-${uid}`"><polygon points="0,0 60,0 0,40" /></clipPath>
      <clipPath :id="`triLR-${uid}`"><polygon points="60,0 60,40 0,40" /></clipPath>
    </defs>

    <!-- Français -->
    <g v-if="code === 'fr'">
      <rect width="60" height="40" fill="#fff" />
      <rect width="20" height="40" fill="#0055A4" />
      <rect x="40" width="20" height="40" fill="#EF4135" />
    </g>

    <!-- English : moitié États-Unis (haut-gauche) / moitié Royaume-Uni (bas-droit) -->
    <g v-else-if="code === 'en'">
      <g :clip-path="`url(#triUL-${uid})`">
        <g v-for="(stripe, i) in usStripes" :key="'st' + i">
          <rect :y="stripe.y" width="60" :height="stripe.h" :fill="i % 2 === 0 ? '#B22234' : '#fff'" />
        </g>
        <rect width="24" :height="usCantonH" fill="#3C3B6E" />
        <use
          v-for="(s, i) in usStars"
          :key="'star' + i"
          :href="`#star5-${uid}`"
          fill="#fff"
          :transform="`translate(${s.x},${s.y}) scale(1.05)`"
        />
      </g>
      <g :clip-path="`url(#triLR-${uid})`">
        <rect width="60" height="40" fill="#00247D" />
        <line x1="0" y1="0" x2="60" y2="40" stroke="#fff" stroke-width="9" />
        <line x1="60" y1="0" x2="0" y2="40" stroke="#fff" stroke-width="9" />
        <line x1="0" y1="0" x2="60" y2="40" stroke="#CF142B" stroke-width="3.4" />
        <line x1="60" y1="0" x2="0" y2="40" stroke="#CF142B" stroke-width="3.4" />
        <rect y="15" width="60" height="10" fill="#fff" />
        <rect x="25" width="10" height="40" fill="#fff" />
        <rect y="17.5" width="60" height="5" fill="#CF142B" />
        <rect x="27.5" width="5" height="40" fill="#CF142B" />
      </g>
    </g>

    <!-- Español -->
    <g v-else-if="code === 'es'">
      <rect width="60" height="40" fill="#AA151B" />
      <rect y="10" width="60" height="20" fill="#F1BF00" />
    </g>

    <!-- Português : moitié Portugal (haut-gauche) / moitié Brésil (bas-droit) -->
    <g v-else-if="code === 'pt'">
      <g :clip-path="`url(#triUL-${uid})`">
        <rect width="24" height="40" fill="#046A38" />
        <rect x="24" width="36" height="40" fill="#DA291C" />
        <circle cx="16" cy="14" r="7" fill="#FFD100" stroke="#046A38" stroke-width="0.5" />
        <rect x="12.5" y="10.5" width="7" height="7" rx="1" fill="#fff" stroke="#DA291C" stroke-width="0.6" />
      </g>
      <g :clip-path="`url(#triLR-${uid})`">
        <rect width="60" height="40" fill="#009C3B" />
        <polygon points="42,16 58,27 42,37 26,27" fill="#FEDF00" />
        <circle cx="42" cy="27" r="8" fill="#002776" />
        <path d="M33,32 A 10 10 0 0 1 51,22" fill="none" stroke="#fff" stroke-width="1.3" />
        <use v-for="(s, i) in brazilStars" :key="'bstar' + i" :href="`#star5-${uid}`" fill="#fff" :transform="`translate(${s.x},${s.y}) scale(0.32)`" />
      </g>
    </g>

    <!-- Deutsch -->
    <g v-else-if="code === 'de'">
      <rect width="60" height="40" fill="#FFCE00" />
      <rect width="60" height="13.33" fill="#000" />
      <rect y="13.33" width="60" height="13.34" fill="#DD0000" />
    </g>

    <!-- 日本語 -->
    <g v-else-if="code === 'ja'">
      <rect width="60" height="40" fill="#fff" />
      <circle cx="30" cy="20" r="12" fill="#BC002D" />
    </g>

    <!-- 中文 -->
    <g v-else-if="code === 'zh'">
      <rect width="60" height="40" fill="#DE2910" />
      <use :href="`#star5-${uid}`" fill="#FFDE00" transform="translate(11,10) scale(5.2) rotate(0)" />
      <use
        v-for="(s, i) in chinaSmallStars"
        :key="'cstar' + i"
        :href="`#star5-${uid}`"
        fill="#FFDE00"
        :transform="`translate(${s.x},${s.y}) scale(1.5) rotate(${s.rot})`"
      />
    </g>
  </svg>
</template>

<script setup>
import { computed } from 'vue'

const props = defineProps({
  code: { type: String, required: true },
  label: { type: String, default: '' },
})

const ariaLabel = computed(() => props.label || props.code)

// Identifiant unique par instance : plusieurs <FlagIcon> (bouton + liste du
// sélecteur) peuvent afficher le même drapeau en même temps sur la page, il
// faut donc éviter les id dupliqués dans le <defs> (star5/clip-paths).
const uid = `fi-${Math.random().toString(36).slice(2, 9)}`

// ─── Drapeau américain (utilisé dans le triangle "en") ────────────────────
const STRIPE_H = 40 / 13
const usStripes = Array.from({ length: 13 }, (_, i) => ({ y: i * STRIPE_H, h: STRIPE_H }))
const usCantonH = (7 / 13) * 40

const usStars = (() => {
  const stars = []
  const rowY = Array.from({ length: 9 }, (_, i) => 1.2 + i * ((usCantonH) / 9))
  rowY.forEach((y, i) => {
    const xs = i % 2 === 0 ? [2, 6, 10, 14, 18, 22] : [4, 8, 12, 16, 20]
    xs.forEach((x) => stars.push({ x, y }))
  })
  return stars
})()

// ─── Petites étoiles autour de l'étoile principale du drapeau chinois ─────
const chinaSmallStars = [
  { x: 20, y: 4, rot: 23 },
  { x: 24, y: 9, rot: 45 },
  { x: 23, y: 15.5, rot: 69 },
  { x: 18, y: 19, rot: 110 },
]

// ─── Petites étoiles dans le cercle bleu du drapeau brésilien ─────────────
const brazilStars = [
  { x: 38, y: 24 }, { x: 44, y: 23 }, { x: 47, y: 28 },
  { x: 41, y: 31 }, { x: 36, y: 29 }, { x: 45, y: 33 },
]
</script>

<style scoped>
.flag-icon {
  width: 1.5em;
  height: 1em;
  border-radius: 2px;
  box-shadow: 0 0 0 1px rgba(0, 0, 0, 0.15);
  flex-shrink: 0;
  display: inline-block;
  vertical-align: middle;
}
</style>
