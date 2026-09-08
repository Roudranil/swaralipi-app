# UX Flows

## 1. Overview

Canonical UX flow reference for Swaralipi. One user. PWA + Capacitor Android wrap. No auth, no cloud.

**Sources:** `docs/architecture.md` · `docs/data-model.md` · `docs/design-system.md`

## 2. Global Shell & Navigation

Shell wraps all in-shell screens. Navigation adapts by width (bottom bar /
rail / drawer) — see `docs/architecture.md` §4.

| Tab | Label | Route | Screen |
| --- | --- | --- | --- |
| 0 | Library | `/` | `LibraryScreen` |
| 1 | Settings | `/settings` | `SettingsScreen` |

Out-of-shell screens (full-screen, no nav chrome):

| Screen | Route |
| --- | --- |
| `PlayerScreen` | `/notation/:notationId/play` |
| `PageEditorScreen` | `/capture/editor` |
| `MetadataFormScreen` | `/capture/metadata` |

Tab switch: `navigate('/')` / `navigate('/settings')` via `react-router`.

## 3. Library — Home Screen

Route: `/` · In shell.

### 3.1 Default state

```
Top app bar
  "Hi, <name>"             <- name from Settings > Your Name
  [Sort control]
  [Search bar]
  [Tag chips row]          <- active filter shortcuts
Recently Played Carousel   <- hidden if nothing played yet
Notation List
FAB (bottom-right)
```

### 3.2 Recently Played Carousel

- Shows **<= 5** most recent by `lastPlayedAt` descending.
- Hidden when `lastPlayedAt` is null for every notation.
- Card: thumbnail + title. Tap -> `NotationDetailScreen` (`/notation/:id`).

### 3.3 Search

1. Tap search bar. Keyboard up. Type query.
2. Fuse.js runs a fuzzy search across: title, artists, notes, tags, language,
   key sig, time sig, custom field values.
3. List filters live. Matched field highlighted in row.
4. Exact-match toggle (icon in bar) switches to exact string match.
5. Clear query -> full list restores.

### 3.4 Sort

| Option | Default direction |
| --- | --- |
| Title | A-Z |
| Date written | Newest first |
| Date added | Newest first |
| Play count | Most first |
| Last played | Most recent first |

Tap option to select; tap again to toggle ascending/descending. Selection
persists in `preferences.defaultSort`.

### 3.5 Filter

**Quick tag filter** — tag chips row above the list. Tap toggles; multiple
active chips AND by default.

**Advanced filter drawer** — bottom sheet with tags, instruments, language
(multi-select chips), key/time signature (free text), date-written/date-added
ranges, play-count range, custom field values. AND/OR toggle per group.
`Apply` filters the list, `Save as Preset` names and stores the filter set,
`Reset` clears everything. Active filter shows a banner above the list with
a clear button. Session-scoped — a cold restart clears filters unless a
preset is loaded.

### 3.6 Notation row actions

**Swipe left** reveals Edit and Delete badges. **Long press** opens a context
menu: Edit, Delete, Add Tag, Duplicate. Add Tag opens a tag picker (existing
tags only) — tap to apply immediately.

## 4. Notation Capture

### 4.1 Entry point

Tap the FAB on `LibraryScreen` -> bottom sheet with two options: Gallery or
Camera.

### 4.2 Gallery flow

FAB -> Capture Entry Sheet -> Gallery -> browser file picker (multi-select,
`<input type="file" multiple accept="image/*">`) -> selected images arrive as
a page set in `PageEditorScreen`.

### 4.3 Camera flow

FAB -> Capture Entry Sheet -> Camera -> `<input type="file" accept="image/*"
capture="environment">` (mobile browsers route this to the native camera) ->
photo arrives as a page in `PageEditorScreen`. Capacitor's Camera plugin is a
candidate upgrade if the input-capture UX proves insufficient on-device —
not decided yet.

## 5. Page Editor

Route: `/capture/editor` · Out-of-shell.

### 5.1 Layout

```
Top bar: [Save]  [Discard]
Active page preview        <- full-width, large
Per-page toolbar:
  Filter | Crop | Rotate | Auto-straighten | Delete page
Thumbnail strip (bottom)
  [+Add] [thumb1] [thumb2] ...
```

Swipe or tap a thumbnail to switch the active page. Thumbnail strip supports
drag-to-reorder.

### 5.2 Per-page actions

| Action | Behavior |
| --- | --- |
| Filter | Original, B&W, Grayscale, Enhanced, Warm Tint, Cool Tint. Apply-to-all shortcut. Non-destructive — applied at display time via `src/lib/render.ts`. |
| Crop | Corner-handle drag, aspect lock toggle, confirm/cancel. |
| Rotate | Cycles 0 -> 90 -> 180 -> 270 -> 0. |
| Auto-straighten | Per-page toggle, off by default. Skew correction applied at render. |
| Delete page | Confirm. If it's the last page, warn before allowing delete. |

### 5.3 Notation-level actions

Add page (`[+]` in the thumbnail strip, reopens the §4.1 sheet, appends after
the current last page) and reorder pages (drag in the strip).

### 5.4 Save / discard

Save locks pages in and navigates to `MetadataFormScreen`. Discard prompts
"Discard all pages?" -> yes returns to Library with nothing written.

## 6. Metadata Form

Route: `/capture/metadata` · Out-of-shell.

### 6.1 Fields

| Field | Input | Notes |
| --- | --- | --- |
| Title | Text | Required. Blocks save if empty. |
| Artist(s) | Chip input | Comma or Enter commits a chip. |
| Date written | `<input type="date">` | Defaults to today. |
| Time signature | Free text | e.g. 4/4, 6/8, free |
| Key signature | Free text | e.g. C major, Yaman |
| Language | Multi-select chips | Hindi, Bengali, English, Sanskrit, Other |
| Tags | Multi-select + inline create | Type to create new inline |
| Instruments | Multi-select chips | From the instrument list, §13 |
| Personal notes | Multi-line text | Free-form |
| Custom fields | Per-field input | Shown if defined in Settings, §17 |

### 6.2 Save gate

Save is disabled until Title is non-empty. On Save: write blobs via
`blobStore`, insert `Notation` + `NotationPage` rows, navigate back to `/`.
New notation appears at the top under the default sort.

## 7. Notation Detail View

Route: `/notation/:notationId` · In shell.

```
Top bar: [Back]  [Edit]  [Delete]
Page stack preview (center, decorative, tappable)
Metadata block: title, artists, date written, language, key/time sig, tags
[Play button] (large, bottom)
```

Tapping the page stack or Play navigates to `PlayerScreen`, increments
`playCount`, and sets `lastPlayedAt`.

## 8. Notation Player

Route: `/notation/:notationId/play` · Out-of-shell.

### 8.1 Entry & exit

Entry: Play button or page-preview tap in Detail View. Exit: back button
returns to Detail View.

### 8.2 Controls

```
Title (top, fades)
Notation page (full-screen)
  Swipe L/R: next/prev page
  Pinch: zoom; pan to scroll when zoomed
Page indicator: "2 / 5" (fades with chrome)
Toolbar (bottom, fades):
  Fit to width | Fit to height | Fit to screen
  Rotate / orientation lock
  Auto-scroll toggle + speed control
```

### 8.3 Auto-scroll

`CLAUDE.md` requirement 6 requires auto-scroll — this supersedes the prior
Flutter spec, which had deferred it. A `requestAnimationFrame` loop advances
`scrollTop` at a configurable speed (Settings > Appearance or an in-player
slider). Toggling auto-scroll off stops the loop; manual scroll pauses it
until re-enabled.

### 8.4 Chrome fade

Title and toolbar visible on entry, fade out after 2s of inactivity. Tap
anywhere to restore chrome for 2s.

## 9. Edit Notation

Entry points: swipe-left Edit badge, long-press Edit, Detail View Edit icon.
Opens `PageEditorScreen` with pages pre-loaded (add/delete/reorder/re-crop/
re-filter available) -> Save -> `MetadataFormScreen` pre-filled -> Save ->
back to Detail View. Unchanged images are not rewritten to the blob store.

## 10. Delete Notation (soft delete)

Entry points: swipe-left Delete badge, long-press Delete, Detail View Delete
icon. Confirmation dialog "Move to Trash?" -> sets `deletedAt`, removes from
the Library list, shows a snackbar with Undo (clears `deletedAt`). Auto-purge
permanently deletes 30 days after `deletedAt` — see §14.

## 11. Duplicate Notation

Long-press context menu -> Duplicate. Creates a new notation row, copies
blobs to new paths, sets title to "Copy of <original>", copies all metadata,
opens immediately in `PageEditorScreen` (edit mode) for the new notation.

## 12. Tags

Route: `/settings/tags`.

Pre-seeded defaults (editable, not locked): practice, raag, song, classical,
piece. Create/Edit open a form with Name (required) and Color (Catppuccin
palette, required). Delete confirms "Delete tag? Removes from all
notations." and cascades via `untagAllNotations` (see `docs/data-model.md`
§4). Apply Tag from Library: long-press a row -> Add Tag -> tap chips in a
bottom sheet -> Done.

## 13. Instrument Tracker

Route: `/settings/instruments`.

### 13.1 Instrument class

List of classes, each expandable to show instances, with a
per-class Add Instance action. Create Class: Name (required). No pre-seeded
classes.

### 13.2 Instrument instance

Create/Edit form: Instrument Class (pre-selected or dropdown), Brand,
Model (optional), Color (Catppuccin palette), Price (INR, optional), Photo
(gallery picker, optional), Notes (optional). Detail screen shows all fields
with Edit and Archive actions.

### 13.3 Archive instance

Confirmation "Archive instrument? It will no longer appear in pickers." Sets
`deletedAt`; the instance is removed from pickers but stays visible (greyed
out or badged) on notations that already reference it. No hard delete.

## 14. Trash

Route: `/settings/trash`.

List of soft-deleted notations with "Deleted X days ago" and per-row Restore
/ Delete Permanently actions. Restore clears `deletedAt`. Delete Permanently
and Empty Trash both confirm, then call `purgeNotation` (blobs + pages +
notation row). Auto-purge runs on app start for anything past 30 days.

## 15. Settings

Route: `/settings`. Rows: Appearance, Tags, Instruments, Library (default
sort), Custom Fields, Your Name, Trash, About.

## 16. Appearance & Theming

Route: `/settings/appearance`. Two steps, in order:

**1. Color mode** — Light / Dark / System toggle, applies immediately, persists
to `preferences.themeMode`.

**2. Seed color** — a swatch grid from the Catppuccin palette of the *active*
mode (Latte in light, Mocha in dark); persists as the swatch **name**, not a
hex, to `preferences.seedColor`, so the choice survives a mode switch (or a
live OS dark-mode flip under System). The app re-themes instantly via
`applyTheme()`/`applyThemeMode()` in `src/lib/theme.ts`. On Android only, a
third option sits alongside the grid — Dynamic color from wallpaper (Monet);
hidden on the web/desktop. **Not yet implemented** — no native plugin exists
yet, this is a placeholder in the flow.

All other color pickers in-app (tags, instrument color) use the Catppuccin
palette only. No free-form color pickers anywhere.

## 17. Custom Fields

Route: `/settings/custom-fields`.

List of user-defined fields with a type badge (Text, Number, Date, Boolean)
and Edit/Delete per row. Create/Edit: Name (required), Type. Delete confirms
"Delete field? Data in all notations will be lost." and removes the key from
every notation's `customFields` (see `docs/data-model.md` §4).
