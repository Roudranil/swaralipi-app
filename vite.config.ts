import tailwindcss from '@tailwindcss/vite'
import react from '@vitejs/plugin-react'
import { defineConfig } from 'vite'
import { VitePWA } from 'vite-plugin-pwa'

// https://vite.dev/config/
export default defineConfig({
  plugins: [
    react(),
    tailwindcss(),
    VitePWA({
      registerType: 'autoUpdate',
      devOptions: { enabled: true },
      workbox: {
        // default glob omits woff2; only Rounded (the default variant) is
        // precached eagerly so SW install stays ~5MB, not ~13MB. Outlined
        // and Sharp are cached on first use via runtimeCaching below.
        globPatterns: ['**/*.{js,css,html,ico,png,svg}', '**/*rounded*.woff2'],
        // the rounded font is ~5.4MB, above workbox's 2MB precache default.
        maximumFileSizeToCacheInBytes: 6 * 1024 * 1024,
        runtimeCaching: [
          {
            urlPattern: /\.woff2$/,
            handler: 'CacheFirst',
            options: {
              cacheName: 'material-symbols-fonts',
              expiration: { maxEntries: 3, maxAgeSeconds: 60 * 60 * 24 * 365 },
            },
          },
        ],
      },
      manifest: {
        name: 'Swaralipi',
        short_name: 'Swaralipi',
        description: 'Digitize and navigate hand-written sargam notations',
        theme_color: '#8839ef',
        background_color: '#8839ef',
        display: 'standalone',
        icons: [
          {
            src: 'pwa-192x192.png',
            sizes: '192x192',
            type: 'image/png',
          },
          {
            src: 'pwa-512x512.png',
            sizes: '512x512',
            type: 'image/png',
          },
          {
            src: 'logov1.svg',
            sizes: 'any',
            type: 'image/svg+xml',
          },
        ],
      },
    }),
  ],
})
