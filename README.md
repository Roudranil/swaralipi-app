# Swaralipi

Single-user PWA for digitizing and navigating hand-written sargam notations
and sheet music. On-device only — no backend, no accounts, no cloud sync.

## Stack

| Layer | Choice |
| --- | --- |
| Framework | React 19 + Vite 8 + TypeScript |
| Components | `mdui` (Material 3) |
| Color | `@material/material-color-utilities` (2025 spec) |
| Styling | Tailwind CSS v4 |
| Offline | `vite-plugin-pwa` |
| Data | Dexie (IndexedDB) |
| Routing | `react-router` |
| Search | Fuse.js |
| Native wrap | Capacitor (Android) |

See `docs/stack.md` for exact versions and gotchas.

## Setup

```bash
npm install
```

## Commands

| Command | Effect |
| --- | --- |
| `npm run dev` | Dev server on the LAN (`--host`) — open on laptop and phone |
| `npm run build` | Type-check, then bundle to `dist/` |
| `npm run test` | Vitest, data layer only |
| `npx cap sync android` | Copy `dist/` into the Android project |
| `npx cap run android --live-reload --host <lan-ip> --port 5173` | Run on a device against the dev server |

## Project structure

```
src/
  App.tsx, routes.tsx, main.tsx   # adaptive shell + routing
  db/                              # Dexie schema, blob store, repositories
  features/                       # one directory per screen/flow
  lib/                             # theme, catppuccin, render, search, log
  hooks/                           # useBreakpoint, useCustomEvent
  styles/                          # index.css (mdui + tailwind + tokens)
```

## Docs

- `docs/stack.md` — packages, commands, gotchas
- `docs/architecture.md` — layers, directory structure, adaptive nav
- `docs/data-model.md` — Dexie schema, `RenderParams`, cascade rules
- `docs/design-system.md` — color, typography, shape, motion, MDUI integration
- `docs/ux-flows.md` — screen-by-screen behavior
- `docs/features.md` — feature list and build order
