import { fileURLToPath, URL } from 'node:url'
import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

async function buildPlugins() {
  const plugins = [vue()]

  if (process.env.ANALYZE === 'true') {
    const { visualizer } = await import('rollup-plugin-visualizer')
    plugins.push(
      visualizer({
        filename: 'dist/stats.html',
        title: 'Nix Life OS Frontend Bundle Report',
        template: 'treemap',
        gzipSize: true,
        brotliSize: true,
        open: false,
      }),
    )
  }

  return plugins
}

function manualChunks(id) {
  if (!id.includes('node_modules')) return undefined

  if (id.includes('/vue/') || id.includes('/@vue/') || id.includes('/vue-router/')) {
    return 'vue-core'
  }

  if (id.includes('/chart.js/') || id.includes('/vue-chartjs/')) {
    return 'charts'
  }

  if (id.includes('/axios/')) return 'http'
  if (id.includes('/pinia/')) return 'state'
  if (id.includes('/dayjs/')) return 'date'
  if (id.includes('/zod/')) return 'validation'
  if (id.includes('/lucide-vue-next/')) return 'icons'

  return 'vendor'
}

export default defineConfig(async () => ({
  base: '/',
  plugins: await buildPlugins(),
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
    target: 'es2020',
    minify: 'esbuild',
    chunkSizeWarningLimit: 500,
    rollupOptions: {
      output: {
        compact: true,
        entryFileNames: 'assets/[name]-[hash].js',
        chunkFileNames: 'assets/[name]-[hash].js',
        assetFileNames: 'assets/[name]-[hash][extname]',
        manualChunks,
      },
    },
  },
}))
