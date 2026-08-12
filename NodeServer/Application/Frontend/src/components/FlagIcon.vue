<template>
  <svg
    class="flag-icon"
    viewBox="0 0 24 18"
    xmlns="http://www.w3.org/2000/svg"
    role="img"
    :aria-label="ariaLabel"
  >
    <!-- Français -->
    <g v-if="code === 'fr'">
      <rect width="24" height="18" fill="#fff" />
      <rect width="8" height="18" fill="#0055A4" />
      <rect x="16" width="8" height="18" fill="#EF4135" />
    </g>

    <!-- English : moitié Royaume-Uni / moitié États-Unis -->
    <g v-else-if="code === 'en'">
      <clipPath id="en-left"><rect width="12" height="18" /></clipPath>
      <clipPath id="en-right"><rect x="12" width="12" height="18" /></clipPath>
      <g clip-path="url(#en-left)">
        <rect width="12" height="18" fill="#00247D" />
        <path d="M0,0 L12,18 M12,0 L0,18" stroke="#fff" stroke-width="3" />
        <path d="M0,0 L12,18 M12,0 L0,18" stroke="#CF142B" stroke-width="1.4" />
        <path d="M6,0 V18 M0,9 H12" stroke="#fff" stroke-width="4.4" />
        <path d="M6,0 V18 M0,9 H12" stroke="#CF142B" stroke-width="2.2" />
      </g>
      <g clip-path="url(#en-right)">
        <rect x="12" width="12" height="18" fill="#fff" />
        <rect x="12" y="0" width="12" height="1.4" fill="#B22234" />
        <rect x="12" y="2.8" width="12" height="1.4" fill="#B22234" />
        <rect x="12" y="5.6" width="12" height="1.4" fill="#B22234" />
        <rect x="12" y="8.4" width="12" height="1.4" fill="#B22234" />
        <rect x="12" y="11.2" width="12" height="1.4" fill="#B22234" />
        <rect x="12" y="14" width="12" height="1.4" fill="#B22234" />
        <rect x="12" y="16.8" width="12" height="1.2" fill="#B22234" />
        <rect x="12" width="6" height="9.7" fill="#3C3B6E" />
        <circle cx="14" cy="2.5" r="0.5" fill="#fff" />
        <circle cx="16.5" cy="2.5" r="0.5" fill="#fff" />
        <circle cx="15.2" cy="4.2" r="0.5" fill="#fff" />
        <circle cx="14" cy="6" r="0.5" fill="#fff" />
        <circle cx="16.5" cy="6" r="0.5" fill="#fff" />
        <circle cx="15.2" cy="7.8" r="0.5" fill="#fff" />
      </g>
    </g>

    <!-- Español -->
    <g v-else-if="code === 'es'">
      <rect width="24" height="18" fill="#AA151B" />
      <rect y="4.5" width="24" height="9" fill="#F1BF00" />
    </g>

    <!-- Português : moitié Portugal / moitié Brésil -->
    <g v-else-if="code === 'pt'">
      <clipPath id="pt-left"><rect width="12" height="18" /></clipPath>
      <clipPath id="pt-right"><rect x="12" width="12" height="18" /></clipPath>
      <g clip-path="url(#pt-left)">
        <rect width="4.8" height="18" fill="#046A38" />
        <rect x="4.8" width="7.2" height="18" fill="#DA291C" />
        <circle cx="4.8" cy="9" r="2.6" fill="#F1BF00" stroke="#fff" stroke-width="0.4" />
      </g>
      <g clip-path="url(#pt-right)">
        <rect x="12" width="12" height="18" fill="#009C3B" />
        <path d="M18,3.5 L23,9 L18,14.5 L13,9 Z" fill="#FEDF00" />
        <circle cx="18" cy="9" r="2.6" fill="#002776" />
      </g>
    </g>

    <!-- Deutsch -->
    <g v-else-if="code === 'de'">
      <rect width="24" height="18" fill="#FFCE00" />
      <rect width="24" height="6" fill="#000" />
      <rect y="6" width="24" height="6" fill="#DD0000" />
    </g>

    <!-- 日本語 -->
    <g v-else-if="code === 'ja'">
      <rect width="24" height="18" fill="#fff" />
      <circle cx="12" cy="9" r="5.2" fill="#BC002D" />
    </g>

    <!-- 中文 -->
    <g v-else-if="code === 'zh'">
      <rect width="24" height="18" fill="#DE2910" />
      <g fill="#FFDE00">
        <path d="M5,3 L5.9,5.7 L8.7,5.7 L6.4,7.3 L7.3,10 L5,8.4 L2.7,10 L3.6,7.3 L1.3,5.7 L4.1,5.7 Z" />
        <circle cx="9.5" cy="2.2" r="0.6" />
        <circle cx="11.2" cy="4.6" r="0.6" />
        <circle cx="11.2" cy="7.6" r="0.6" />
        <circle cx="9.3" cy="9.7" r="0.6" />
      </g>
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
</script>

<style scoped>
.flag-icon {
  width: 1.4em;
  height: 1.05em;
  border-radius: 2px;
  box-shadow: 0 0 0 1px rgba(0, 0, 0, 0.15);
  flex-shrink: 0;
  display: inline-block;
  vertical-align: middle;
}
</style>
