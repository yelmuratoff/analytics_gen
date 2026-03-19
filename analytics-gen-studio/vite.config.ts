import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// https://vite.dev/config/
export default defineConfig({
  base: '/analytics_gen/',
  plugins: [react()],
  build: {
    outDir: 'dist',
  },
})
