# React PWA rules

Supplement to `CLAUDE.md`. Read `docs/architecture.md`,
`docs/data-model.md`, and `docs/design-system.md` before touching
unfamiliar areas — they are the authoritative spec, this file is a quick
reference.

## Stack facts

- React 19, Vite 8, TypeScript, Tailwind v4 (no config file — tokens live in
  `src/styles/index.css` `@theme`), `mdui` components, color tokens from
  `@material/material-color-utilities` at the 2025 Expressive spec, Dexie
  for all persistence, `react-router`, Fuse.js, Capacitor for the Android
  wrap.
- `tsconfig.app.json` sets `erasableSyntaxOnly` — no `enum`, no constructor
  parameter properties.

## MDUI gotchas (see docs/design-system.md §10)

- `onChange`/`onInput`/`onOpen`/`onClose` etc. on an `mdui-*` element
  typechecks but never fires — React 19 does not bind synthetic events to
  CustomEvents. Use `src/hooks/useCustomEvent.ts` (ref + `addEventListener`)
  for anything other than native bubbling events (`click`, `focus`, `blur`,
  `keydown`).
- Tailwind classes on an `mdui-*` tag style only the host element — shadow
  DOM blocks everything else except `::part()`, exposed custom properties,
  and slots.
- Never call MDUI's `setColorScheme()` — it overwrites the 2025-spec tokens
  written by `src/lib/theme.ts` with MDUI's own 2021-spec generator.
- Cherry-pick component imports (`mdui/components/button.js`), not
  `import 'mdui'`.

## Data layer

- Components never import `db.ts` directly — go through a repository module
  in `src/db/repositories/`.
- Reads: `useLiveQuery`. Writes: plain async repository functions, wrapped
  in `db.transaction('rw', ...)` when more than one table changes together
  (cascade deletes, untagging, etc. — see `docs/data-model.md` §4).
- Blobs go through `src/db/blobStore.ts`, never `db.blobs` directly, so
  object-URL lifecycle stays centralized.

## Testing

Vitest covers the data layer only (`fake-indexeddb`) — repository cascade
logic and the blob round-trip. No component tests; this is a one-user app
verified by looking at it in the browser at both desktop and mobile widths.
