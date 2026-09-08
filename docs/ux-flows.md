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
| `CaptureScreen` | `/capture` |

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
FAB (bottom-right)          <- laptop width mounts it in the nav rail instead, see §4.1
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

One out-of-shell screen for the whole flow — not the separate page-editor and
metadata-form screens an earlier draft of this doc described. See
`docs/modules/capture.md` for the full component/data breakdown; this section
covers the user-facing flow only.

### 4.1 Entry point

An extended FAB ("Add notation"), placement per width tier:

- **Phone (`< 840px`):** bottom-right on `LibraryScreen`, above the bottom
  nav bar's safe area.
- **Laptop (`>= 840px`):** inside the nav rail, below the rail's own
  expand/collapse toggle and above the nav items (Gmail's placement) — tied
  to the rail's `expanded` state, so it collapses to a circle with the rail.

Tapping it navigates to `/capture`, which immediately opens the device's file
picker (`<input type="file" multiple accept="image/*">`) if the draft has no
pages yet. There is no Gallery/Camera chooser sheet — camera capture is out
of scope for this pass (an M3 FAB menu is reserved for 2+ actions and is
never paired with an extended FAB; with exactly one action, a plain picker is
the direct path). Selected images arrive as pages, in selection order.

### 4.2 Layout

```
[Title]                    [v]     <- required, expands the musical-basics panel
  Artist(s) | Date written | Time signature | Key signature   <- only when expanded
Active page preview                <- large, with prev/next arrows
Thumbnail carousel (or a mode's action row — see §4.4)
Tool row: Crop | Rotate | Resize | Reorder | Delete | Add more pages
```

The metadata panel holds only the fields already on `Notation` that are
musical basics — artists, date written, time signature, key signature.
Languages, tags, instruments, personal notes, and custom fields are **not**
captured here; editing those is a separate future feature.

### 4.3 Selecting and stepping through pages

Tap a carousel thumbnail, or the prev/next arrows beside the preview, to
change the active page. The selected thumbnail gets a ring in the accent
colour, matching the selection indicator used elsewhere in the app.

### 4.4 Tools

Tapping a tool replaces the thumbnail carousel with that tool's action row;
tapping the same tool again (or finishing its action) returns to the
carousel. A tool's mode **persists across the prev/next arrows** — stepping
to another page while in Crop mode keeps Crop mode active on that page.

| Tool | Action row | Behavior |
| --- | --- | --- |
| Crop | `No crop` / `Save cropped region` | A drag box (4 corners + 4 edges + whole-box move) appears over the un-cropped, still-rotated image. `No crop` resets to full-frame. Rectangle-only, free aspect ratio, in this pass. |
| Rotate | `Rotate left` / `Rotate right` | Steps 0 -> 90 -> 180 -> 270 -> 0 in either direction. A crop set before rotating stays over the same region of the page. |
| Resize | `Original` `A3` `A4` `A5` `A6` | Fits the page into the chosen ISO preset, aspect preserved, white padding filling the rest. Always re-derives from the original image — switching presets does not compound. Fixed-orientation presets; no auto-rotate-to-match. |
| Reorder | *(opens a full-screen grid, not an action row)* | 2 columns on phone, 4 on laptop, drag to reorder with an animated shift; keyboard-reachable. |
| Delete | `Keep this image` (neutral) / `Delete this image` (destructive) | Removes the active page from the draft. |
| Add more pages | *(opens the file picker directly)* | Appends newly selected images after the current last page, in selection order. |

Filter presets and auto-straighten, named in an earlier draft of this
section, are not part of the app — dropped, not deferred.

### 4.5 Save / discard

The close (`X`) button in the top bar discards the draft with no confirmation
and returns to Library — nothing is written until Save. Save is disabled
until Title is non-empty and at least one page exists; on Save, blobs are
written via `blobStore`, `Notation` and `NotationPage` rows are written in
one transaction, and the screen navigates back to `/`. The new notation
appears at the top under the default sort.

## 5. Notation Detail View

Route: `/notation/:notationId` · In shell.

```
Top bar: [Back]  [Edit]  [Delete]
Page stack preview (center, decorative, tappable)
Metadata block: title, artists, date written, language, key/time sig, tags
[Play button] (large, bottom)
```

Tapping the page stack or Play navigates to `PlayerScreen`, increments
`playCount`, and sets `lastPlayedAt`.

## 6. Notation Player

Route: `/notation/:notationId/play` · Out-of-shell.

### 6.1 Entry & exit

Entry: Play button or page-preview tap in Detail View. Exit: back button
returns to Detail View.

### 6.2 Controls

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

### 6.3 Auto-scroll

`CLAUDE.md` requirement 6 requires auto-scroll — this supersedes the prior
Flutter spec, which had deferred it. A `requestAnimationFrame` loop advances
`scrollTop` at a configurable speed (Settings > Appearance or an in-player
slider). Toggling auto-scroll off stops the loop; manual scroll pauses it
until re-enabled.

### 6.4 Chrome fade

Title and toolbar visible on entry, fade out after 2s of inactivity. Tap
anywhere to restore chrome for 2s.

## 7. Edit Notation

Entry points: swipe-left Edit badge, long-press Edit, Detail View Edit icon.
Opens `CaptureScreen` with pages and metadata pre-loaded (add/delete/reorder/
re-crop/re-rotate/re-resize available) -> Save -> back to Detail View.
Unchanged images are not rewritten to the blob store.

## 8. Delete Notation (soft delete)

Entry points: swipe-left Delete badge, long-press Delete, Detail View Delete
icon. Confirmation dialog "Move to Trash?" -> sets `deletedAt`, removes from
the Library list, shows a snackbar with Undo (clears `deletedAt`). Auto-purge
permanently deletes 30 days after `deletedAt` — see §12.

## 9. Duplicate Notation

Long-press context menu -> Duplicate. Creates a new notation row, copies
blobs to new paths, sets title to "Copy of <original>", copies all metadata,
opens immediately in `CaptureScreen` (edit mode) for the new notation.

## 10. Tags

Route: `/settings/tags`.

Pre-seeded defaults (editable, not locked): practice, raag, song, classical,
piece. Create/Edit open a form with Name (required) and Color (Catppuccin
palette, required). Delete confirms "Delete tag? Removes from all
notations." and cascades via `untagAllNotations` (see `docs/data-model.md`
§4). Apply Tag from Library: long-press a row -> Add Tag -> tap chips in a
bottom sheet -> Done.

## 11. Instrument Tracker

Route: `/settings/instruments`.

### 11.1 Instrument class

List of classes, each expandable to show instances, with a
per-class Add Instance action. Create Class: Name (required). No pre-seeded
classes.

### 11.2 Instrument instance

Create/Edit form: Instrument Class (pre-selected or dropdown), Brand,
Model (optional), Color (Catppuccin palette), Price (INR, optional), Photo
(gallery picker, optional), Notes (optional). Detail screen shows all fields
with Edit and Archive actions.

### 11.3 Archive instance

Confirmation "Archive instrument? It will no longer appear in pickers." Sets
`deletedAt`; the instance is removed from pickers but stays visible (greyed
out or badged) on notations that already reference it. No hard delete.

## 12. Trash

Route: `/settings/trash`.

List of soft-deleted notations with "Deleted X days ago" and per-row Restore
/ Delete Permanently actions. Restore clears `deletedAt`. Delete Permanently
and Empty Trash both confirm, then call `purgeNotation` (blobs + pages +
notation row). Auto-purge runs on app start for anything past 30 days.

## 13. Settings

Route: `/settings`. A declarative, section-divided list — see
`docs/modules/settings.md` for the full registry contract. Sections, in
order:

| Section | Rows | Status |
| --- | --- | --- |
| Personal | Personalisation, Appearance | Built |
| Library | Tags, Instruments, Library (default sort), Custom Fields | Registered, not built |
| Housekeeping | Trash (more expected here) | Registered, not built |
| Miscellaneous | About, Open source licences, Backup and sync | About built; rest registered, not built |

"Registered, not built" rows render dimmed and inert (§11.7 in
docs/design-system.md) rather than being omitted, so the settings list
already shows its intended final shape.

At laptop widths (`>= 840px`) the nav rail keeps the left edge; a settings
subscreen does not open a second nav column beside it. Content is capped at
640px and centred in the remaining space, identically to phone — see
docs/modules/settings.md §6 for why a rail-plus-list-detail three-column
layout was rejected.

### 13.1 Personalisation

Route: `/settings/personalisation`. One field, "Your name" — one word,
letters only (any script), empty allowed. Feeds the Library greeting
(`"Hi, <Name>"`, or a plain `"Hi"` when empty — §3.1). Unlike Appearance,
this commits via an explicit **Save** button rather than instantly: a name
is free text that needs validation before it is worth persisting. A live
preview of the exact greeting string sits between the field and the Save
button. Title-casing is applied on blur, not per keystroke, so it doesn't
fight the cursor mid-word.

## 14. Appearance & Theming

Route: `/settings/appearance`. Two groups, in order:

**1. Theme** — a single-select M3 segmented button (Light / Dark / System),
applies immediately, persists to `preferences.themeMode`.

**2. Accent colour** — a swatch grid from the Catppuccin palette of the
*active* mode (Latte in light, Mocha in dark); persists as the swatch
**name**, not a hex, to `preferences.seedColor`, so the choice survives a
mode switch (or a live OS dark-mode flip under System). The app re-themes
instantly via `applyTheme()`/`applyThemeMode()` in `src/lib/theme.ts`. On
Android only, a third option is meant to sit alongside the grid — Dynamic
color from wallpaper (Monet); hidden on the web/desktop. **Not yet
implemented** — no native plugin exists yet, and it does not appear in the
shipped screen at all, not even as a hidden stub.

A "Reset appearance" text button opens the §11.3 confirm dialog and restores
`themeMode: 'system'` and `seedColor: 'mauve'` (the defaults).

All other color pickers in-app (tags, instrument color) use the Catppuccin
palette only. No free-form color pickers anywhere.

## 15. Custom Fields

Route: `/settings/custom-fields`.

List of user-defined fields with a type badge (Text, Number, Date, Boolean)
and Edit/Delete per row. Create/Edit: Name (required), Type. Delete confirms
"Delete field? Data in all notations will be lost." and removes the key from
every notation's `customFields` (see `docs/data-model.md` §4).
