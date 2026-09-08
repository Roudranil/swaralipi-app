# Architecture

## 1. Layers

The prior MVVM layering collapses one layer. Dexie's `useLiveQuery` is a
reactive read that re-runs when IndexedDB changes — that was the only job
`ChangeNotifier` did.

| Layer | Prior (Flutter) | Now (React) |
| --- | --- | --- |
| View | `StatelessWidget` | React function component |
| Reactive read | `ViewModel` + `ChangeNotifier` | `useLiveQuery` |
| Write / business logic | Repository | Repository module (plain async functions) |
| Data source | Drift DAO | Dexie `Table` |

## 2. Infrastructure services

| Prior | Now |
| --- | --- |
| `AppDatabase` (Drift) | `src/db/db.ts` (Dexie) |
| `FileStorageService` | `src/db/blobStore.ts` |
| `ImageProcessingService` | `src/lib/render.ts` — Canvas 2D applies `RenderParams` |
| `SearchService` (SQLite FTS5) | `src/lib/search.ts` — Fuse.js over the loaded list |
| `AppLogger` | `src/lib/log.ts` — `console` behind a dev guard |

Non-destructive image editing is preserved: the stored blob is never mutated.
`RenderParams` (filter, rotation, auto-straighten, normalized crop rect) applies
at display time. See `docs/data-model.md` §4.

## 3. Directory structure

```
src/
  main.tsx              # theme init, router mount
  App.tsx               # adaptive shell: nav + <Outlet/>
  routes.tsx            # react-router route table
  db/
    db.ts               # Dexie subclass + schema
    types.ts            # entity interfaces + RenderParams
    blobStore.ts         # blob put/get/delete, object URL lifecycle
    repositories/        # notations, tags, instruments, customFields, trash, prefs
  features/
    library/             # home: greeting, list, search, sort, filter
    capture/              # file input, page editor, metadata form
    detail/               # notation detail view
    player/               # full-screen viewer, auto-scroll
    tags/
    instruments/
    trash/
    customFields/
    settings/
  lib/
    theme.ts              # seed color -> M3 tokens, light/dark
    catppuccin.ts          # Latte + Mocha palettes
    render.ts              # canvas RenderParams pipeline
    search.ts              # Fuse.js
    log.ts
  hooks/
    useBreakpoint.ts       # matchMedia against M3 breakpoints
    useCustomEvent.ts       # ref + addEventListener for mdui CustomEvents
  styles/
    index.css               # mdui.css, tailwind, @theme bridge
```

Only `features/library` and the shell exist so far. The rest are placeholders
in the route table until built.

## 4. Adaptive navigation

The prior app had a fixed bottom navigation bar. A PWA also runs at laptop
width, so navigation adapts by width using the M3 breakpoints
(0 / 600 / 840 / 1080 / 1440 / 1920):

| Width | Navigation |
| --- | --- |
| `< 840px` | Bottom navigation bar (`mdui-navigation-bar`) |
| `840px – 1079px` | Navigation rail (`mdui-navigation-rail`) |
| `>= 1080px` | Navigation drawer (`mdui-navigation-drawer`, non-modal) |

`src/hooks/useBreakpoint.ts` drives the switch via `matchMedia`. This is the
mechanism that makes both laptop and phone render correctly — no dev-only
preview harness is needed. See `docs/design-system.md` for the design-system
rationale behind the split between MDUI and the color token layer.

## 5. Routes

| Path | Screen | Status |
| --- | --- | --- |
| `/` | Library | Built (empty state + list) |
| `/settings` | Settings | Placeholder |
| `/notation/:id` | Notation detail | Not built |
| `/notation/:id/play` | Player | Not built |
| `/capture` | Capture / page editor | Not built |
| `/tags` | Tags | Not built |
| `/instruments` | Instruments | Not built |
| `/trash` | Trash | Not built |
| `/custom-fields` | Custom fields | Not built |
| `/settings/appearance` | Appearance | Not built |
