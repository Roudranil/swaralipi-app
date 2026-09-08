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
    settings/             # registry-driven settings module — see docs/modules/settings.md
      registry.ts          # SETTINGS_SECTIONS — routes/rows/summaries derive from this
      settingsRoutes.tsx     # walks the registry into react-router RouteObjects
      nameField.ts          # personalisation name validation/formatting
      components/            # SettingsPage, SettingsRow, SettingsSection, SettingsGroup, SwatchGrid
      screens/                # SettingsIndexScreen, SettingsGroupScreen, AppearanceScreen,
                              # PersonalisationScreen, AboutScreen
  lib/
    theme.ts              # per-mode seeds -> M3 tokens; mdui-theme-* class
    catppuccin.ts          # Latte + Mocha palettes, swatch name -> seed hexes
    themeBoot.ts            # localStorage theme cache for first paint
    greeting.ts             # Library hero greeting, shared with the Personalisation preview
    render.ts              # canvas RenderParams pipeline
    search.ts              # Fuse.js
    log.ts
  hooks/
    useCustomEvent.ts       # ref + addEventListener for mdui CustomEvents
    usePreferences.ts       # useLiveQuery over the preferences table
    useAppliedTheme.ts       # reconciles DOM theme with preferences
    useResolvedThemeMode.ts  # resolves 'system' to the OS's live light/dark preference
  styles/
    index.css               # mdui.css, tailwind, @theme bridge
```

Only `features/library` and `features/settings` exist so far. The rest are
placeholders in the route table until built.

## 4. Adaptive navigation

The prior app had a fixed bottom navigation bar. A PWA also runs at laptop
width, so navigation adapts by width. The implementation is a two-tier,
CSS-only switch at the single `md:` (840px) breakpoint — not the three-tier,
`matchMedia`-driven switch an earlier draft of this doc described:

| Width | Navigation |
| --- | --- |
| `< 840px` | Bottom navigation bar — `src/components/shell/NavBar.tsx` |
| `>= 840px` | Collapsible navigation rail — `src/components/shell/NavRail.tsx` |

Both `NavBar` and `NavRail` always render; Tailwind's `md:hidden` /
`hidden md:flex` toggle visibility, so `<main>` never remounts and routed
screen state survives a resize across the breakpoint (`src/App.tsx`). There is
no navigation drawer tier and no `src/hooks/useBreakpoint.ts` — both are
planned-but-unbuilt, not currently in the codebase. `src/components/shell/navItems.ts`
is the single list of destinations shared by both navs; `activeNavValue()`
there prefix-matches, so a nested route like `/settings/appearance` still
highlights the `Settings` tab.

See `docs/design-system.md` for the design-system rationale behind the split
between MDUI and the color token layer.

## 5. Routes

| Path | Screen | Status |
| --- | --- | --- |
| `/` | Library | Built (empty state + list) |
| `/settings` | `SettingsIndexScreen` | Built |
| `/settings/personalisation` | Personalisation | Built |
| `/settings/appearance` | Appearance | Built |
| `/settings/about` | About | Built |
| `/settings/tags` | Tags | Registered, not built |
| `/settings/instruments` | Instruments | Registered, not built |
| `/settings/library` | Library defaults | Registered, not built |
| `/settings/custom-fields` | Custom fields | Registered, not built |
| `/settings/trash` | Trash | Registered, not built |
| `/settings/licenses` | Open source licences | Registered, not built |
| `/settings/backup` | Backup and sync | Registered, not built |
| `/notation/:id` | Notation detail | Not built |
| `/notation/:id/play` | Player | Not built |
| `/capture` | Capture / page editor | Not built |

"Registered, not built" entries exist in `src/features/settings/registry.ts`
with `status: 'planned'` — they render as a dimmed, inert row on the settings
list but have no route at all until their status flips to `'built'`. See
`docs/modules/settings.md` §3.
