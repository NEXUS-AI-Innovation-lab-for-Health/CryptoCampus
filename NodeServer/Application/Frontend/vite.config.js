import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import path from 'path'

export default defineConfig({
  plugins: [vue()],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },
  server: {
    proxy: {
      '/api': {
        target: 'http://api_crypto:3000',
        changeOrigin: true,
        ws: true, // requis pour l'upgrade WebSocket de Socket.io (/api/socket.io)
      }
    }
  },
  test: {
    environment: 'jsdom',
    globals: true,
  },
})
