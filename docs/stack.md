# Stack

## 1. Packages

| Layer | Package | Version |
| --- | --- | --- |
| Framework | `react`, `react-dom` | 19.2 |
| Build | `vite` | 8.2 |
| Language | `typescript` | 6.0 |
| Components | `mdui` | 2.1.5 |
| Icons | `material-symbols` | 0.47.1 |
| Color tokens | `@material/material-color-utilities` | 0.4.0 |
| Utility styling | `tailwindcss`, `@tailwindcss/vite` | 4.3 |
| Offline | `vite-plugin-pwa` | 1.3 |
| Data | `dexie`, `dexie-react-hooks` | 4.4 |
| Routing | `react-router` | 8.3 |
| Search | `fuse.js` | 7.5 |
| Native wrap | `@capacitor/core`, `@capacitor/android`, `@capacitor/cli` | 8.5 |
| Reorder | `@dnd-kit/core`, `@dnd-kit/sortable`, `@dnd-kit/utilities` | 6.3 / 10.0 / 3.2 |
| Tests | `vitest`, `fake-indexeddb` | 5.0 / 6.2 |
| Lint | `oxlint` (bundled with the Vite `react-ts` template) | 1.79 |

## 2. Commands

| Command | Effect |
| --- | --- |
| `npm run dev` | Dev server on `--host`, reachable from a phone on the same LAN |
| `npm run build` | `tsc -b && vite build` — type-check, then bundle to `dist/` |
| `npm run lint` | `oxlint` |
| `npm run test` | `vitest run` — data layer only |
| `npx cap sync android` | Copies `dist/` into the Android project, updates plugins |
| `npx cap run android --live-reload --host <lan-ip> --port 5173` | Runs on a connected device/emulator against the Vite dev server |

## 3. Gotchas

| Gotcha | Detail |
| --- | --- |
| Tailwind v4 has no config file | Theme tokens live in `@theme` inside `src/styles/index.css` |
| `tsconfig.app.json` sets `erasableSyntaxOnly` | No `enum`, no constructor parameter properties |
| No `src/vite-env.d.ts` by default | Added manually: `vite/client`, `mdui/jsx.en.d.ts`, `vite-plugin-pwa/react` |
| `androidScheme: 'https'` in `capacitor.config.ts` | Required for a secure context — service workers need it |
| `cap run android --live-reload` defaults to port 3000 | Pass `--port 5173` to match Vite |
| `mdui.css` sets `:root { font-size: 16px }` | Overridden to `100%` in `src/styles/index.css` — otherwise browser text zoom breaks |
| React 19 does not bind synthetic events to custom elements' `CustomEvent`s | `onChange` on an `mdui-*` element typechecks and silently does nothing. Use `useCustomEvent`. See `docs/design-system.md` §10 |
| `@capacitor/cli`'s `xcode` dependency pulls a moderate-severity `uuid` advisory | Dev-only, iOS tooling unused on this Android-only project. Not fixed |
| `mdui-icon`'s shadow style hardcodes `font-family:'Material Icons'` | Can't be repointed from outside its shadow root. Use `src/components/Icon.tsx` in an `icon`/`active-icon` slot instead — see `docs/design-system.md` §12 |

## 4. Not done in this pass

Building and running the actual Android APK (`npx cap open android`) needs Android
Studio and a JDK. The Android project is scaffolded (`npx cap add android`) but not
built.
