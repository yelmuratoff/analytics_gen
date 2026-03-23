import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// https://vite.dev/config/
export default defineConfig({
  base: '/analytics_gen/',
  plugins: [react()],
  build: {
    outDir: 'dist',
    rollupOptions: {
      output: {
        manualChunks(id: string) {
          if (id.includes('@mui/material') || id.includes('@mui/icons-material') || id.includes('@emotion/')) return 'vendor-mui';
          if (id.includes('@rjsf/') || id.includes('ajv')) return 'vendor-rjsf';
          if (id.includes('js-yaml') || id.includes('jszip') || id.includes('file-saver')) return 'vendor-yaml';
          if (id.includes('zustand') || id.includes('zundo') || id.includes('immer')) return 'vendor-state';
        },
      },
    },
  },
  test: {
    environment: 'jsdom',
    globals: true,
    setupFiles: ['./src/__tests__/setup.ts', './src/__tests__/setup-schema.ts'],
  },
} as any)
