# Features

12 features, ported from the prior feature DAG. Infrastructure services are
now the modules in `docs/architecture.md` §2, not separate build phases —
Dexie and the repository pattern make most of them near-free to stand up.

## 1. Feature list

| ID | Name | Status | Description |
| --- | --- | --- | --- |
| F01 | Notation Capture | Not built | Gallery/camera ingestion, per-page editor, filter/crop/rotate, metadata form |
| F02 | Metadata | Not built | Title, artists, timing, language, tags, instruments, custom fields |
| F03 | Library | Partial (empty-state shell built) | Home screen — recently played carousel, list, fuzzy search, sort, tag filter |
| F04 | Notation Detail View | Not built | Read view with metadata block, play entry, edit/delete actions |
| F05 | Notation Player | Not built | Full-screen viewer, swipe pages, pinch-zoom, orientation lock, fade chrome, **auto-scroll** |
| F06 | Instrument Tracker | Not built | Two-level CRUD (class + instance), photo, soft-delete archive |
| F07 | Tags | Not built | Create/rename/recolor/delete, Catppuccin palette, 5 pre-seeded defaults |
| F08 | Edit / Delete / Copy | Not built | CRUD entry points from Library and Detail View |
| F09 | Trash | Not built | Soft-deleted list, restore/purge, 30-day auto-purge |
| F10 | Appearance & Theming | Engine + persistence built, UI not built | Light/Dark/System toggle, Catppuccin seed color; dynamic color (Monet) deferred |
| F11 | Settings | Not built | Shell aggregating Tags, Instruments, Trash, Appearance, Custom Fields |
| F12 | Custom Fields | Not built | CRUD for user-defined field definitions (name + type) |

F05 gained auto-scroll in this pass (see `docs/ux-flows.md` §8.3) — the prior
Flutter spec had deferred it, but `CLAUDE.md` requirement 6 requires it, and
it is a `requestAnimationFrame` loop, not a platform capability gap.

## 2. Dependency table

| ID | Depends on | Why |
| --- | --- | --- |
| F07 | `db.ts` | tags persisted in Dexie |
| F06 | `db.ts`, `blobStore.ts` | instances persisted; photo as blob |
| F10 | `db.ts` | preferences written to Dexie |
| F09 | `db.ts`, `blobStore.ts` | soft-delete flag; blobs retained until purge |
| F12 | `db.ts` | custom field definitions persisted |
| F02 | F07, F06, F12 | metadata form embeds tag, instrument, custom field pickers |
| F01 | F02 | capture saves pages + metadata |
| F08 | F01, F09 | edit re-enters capture; delete lands in trash |
| F03 | F01, F07, F08, F04 | list needs saved notations, tag filter, search, nav target |
| F04 | F08, F05 | reads notation; hosts edit/delete; launches player |
| F05 | `render.ts` | renders pages through the non-destructive pipeline |
| F11 | F07, F06, F09, F10, F12 | settings shell aggregates all sub-sections |

## 3. Build order (trunk)

1. Tags (F07) — needed by metadata
2. Metadata (F02) — needed by capture
3. Notation Capture (F01) — populates the library
4. Trash (F09) — needed by delete
5. Edit / Delete / Copy (F08) — needed by detail view
6. Notation Detail View (F04) — navigation target from library
7. Library (F03) — final home screen, already has an empty-state shell

Branch work, parallelizable once its own dependency is done: Instrument
Tracker (F06), Appearance & Theming (F10), Custom Fields (F12), Notation
Player (F05), Settings (F11, last — needs F07/F06/F09/F10/F12).
