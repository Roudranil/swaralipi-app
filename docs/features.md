# Features

12 features, ported from the prior feature DAG. Infrastructure services are
now the modules in `docs/architecture.md` §2, not separate build phases —
Dexie and the repository pattern make most of them near-free to stand up.

## 1. Feature list

| ID | Name | Status | Description |
| --- | --- | --- | --- |
| F01 | Notation Capture | Built | Extended-FAB entry, single-screen editor: crop/rotate/resize/reorder/delete/add pages |
| F02 | Metadata | Partial (musical basics only, in F01's screen) | Title, artists, timing, key sig built; language, tags, instruments, notes, custom fields not yet captured |
| F03 | Library | Partial (empty-state shell + dynamic greeting built) | Home screen — recently played carousel, list, fuzzy search, sort, tag filter |
| F04 | Notation Detail View | Not built | Read view with metadata block, play entry, edit/delete actions |
| F05 | Notation Player | Not built | Full-screen viewer, swipe pages, pinch-zoom, orientation lock, fade chrome, **auto-scroll** |
| F06 | Instrument Tracker | Not built | Two-level CRUD (class + instance), photo, soft-delete archive |
| F07 | Tags | Not built | Create/rename/recolor/delete, Catppuccin palette, 5 pre-seeded defaults |
| F08 | Edit / Delete / Copy | Not built | CRUD entry points from Library and Detail View |
| F09 | Trash | Not built | Soft-deleted list, restore/purge, 30-day auto-purge |
| F10 | Appearance & Theming | Built | Light/Dark/System segmented toggle, Catppuccin seed color, reset; dynamic color (Monet) deferred |
| F11 | Settings | Built (shell + registry) | Registry-driven list aggregating Personalisation, Appearance, About now; Tags, Instruments, Trash, Custom Fields, Library defaults, licences, backup registered but not built |
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
| F01 | `render.ts`, `renderGeometry.ts`, `blobStore.ts` | capture's own non-destructive pipeline and blob writes |
| F02 | F01 (musical basics), F07, F06, F12 (rest) | F01's screen captures title/artists/timing/key sig directly; language, tags, instruments, and custom fields still need their own picker UI added to it |
| F08 | F01, F09 | edit re-enters capture; delete lands in trash |
| F03 | F01, F07, F08, F04 | list needs saved notations, tag filter, search, nav target |
| F04 | F08, F05 | reads notation; hosts edit/delete; launches player |
| F05 | `render.ts` | renders pages through the non-destructive pipeline |
| F11 | F07, F06, F09, F10, F12 | settings shell aggregates all sub-sections |

Building F01 turned out not to need F02/F07/F12 first, unlike the original
plan — its screen only captures the `Notation` fields that don't require a
picker (title, artists, date, time/key sig), so it could ship directly
against `db.ts` and its own render pipeline.

## 3. Build order (trunk)

1. Notation Capture (F01) — built directly, ahead of the rest of Metadata
2. Tags (F07) — needed to extend Metadata's picker fields
3. Metadata (F02) — language/tag/instrument/custom-field pickers, added to F01's screen
4. Trash (F09) — needed by delete
5. Edit / Delete / Copy (F08) — needed by detail view
6. Notation Detail View (F04) — navigation target from library
7. Library (F03) — final home screen, already has an empty-state shell

Branch work, parallelizable once its own dependency is done: Instrument
Tracker (F06), Appearance & Theming (F10), Custom Fields (F12), Notation
Player (F05), Settings (F11, last — needs F07/F06/F09/F10/F12).
