import { fileURLToPath, URL } from 'node:url'
import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import tailwindcss from '@tailwindcss/vite'

function manualChunks(id) {
  if (!id.includes('node_modules')) {
    return undefined
  }

  if (id.includes('/node_modules/vue/') || id.includes('/node_modules/@vue/')) {
    return 'vue-core'
  }

  if (id.includes('/node_modules/vue-router/')) {
    return 'vue-router'
  }

  if (id.includes('/node_modules/pinia/')) {
    return 'pinia'
  }

  if (id.includes('/node_modules/axios/')) {
    return 'axios'
  }

  if (
    id.includes('/node_modules/chart.js/') ||
    id.includes('/node_modules/vue-chartjs/') ||
    id.includes('/node_modules/recharts/') ||
    id.includes('/node_modules/d3')
  ) {
    return 'charts'
  }

  return 'vendor'
}

export default defineConfig({
  base: '/',
  plugins: [vue(), tailwindcss()],
  resolve: {
    alias: {
      '@': fileURLToPath(new URL('./src', import.meta.url)),
    },
  },
  build: {
    outDir: 'dist',
    assetsDir: 'assets',
    emptyOutDir: true,
    manifest: false,
    sourcemap: false,
    cssCodeSplit: true,
    target: 'es2022',
    chunkSizeWarningLimit: 500,
    rollupOptions: {
      output: {
        manualChunks,
        entryFileNames: 'assets/[name]-[hash].js',
        chunkFileNames: 'assets/[name]-[hash].js',
        assetFileNames: 'assets/[name]-[hash][extname]',
      },
    },
  },
})
