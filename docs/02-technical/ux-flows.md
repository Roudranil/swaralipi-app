# Swaralipi — UX Flows

## Table of Contents

- [1. Overview](#1-overview)
- [2. Global Shell & Navigation](#2-global-shell--navigation)
- [3. Library — Home Screen](#3-library--home-screen)
  - [3.1 Default State](#31-default-state)
  - [3.2 Recently Played Carousel](#32-recently-played-carousel)
  - [3.3 Search](#33-search)
  - [3.4 Sort](#34-sort)
  - [3.5 Filter](#35-filter)
  - [3.6 Notation Row Actions](#36-notation-row-actions)
- [4. Notation Capture](#4-notation-capture)
  - [4.1 Entry Point](#41-entry-point)
  - [4.2 Gallery Flow](#42-gallery-flow)
  - [4.3 Camera Flow](#43-camera-flow)
- [5. Page Editor](#5-page-editor)
  - [5.1 Layout](#51-layout)
  - [5.2 Per-Page Actions](#52-per-page-actions)
  - [5.3 Notation-Level Actions](#53-notation-level-actions)
  - [5.4 Save / Discard](#54-save--discard)
- [6. Metadata Form](#6-metadata-form)
  - [6.1 Layout](#61-layout)
  - [6.2 Fields](#62-fields)
  - [6.3 Save Gate](#63-save-gate)
- [7. Notation Detail View](#7-notation-detail-view)
  - [7.1 Layout](#71-layout)
  - [7.2 Actions](#72-actions)
- [8. Notation Player](#8-notation-player)
  - [8.1 Entry & Exit](#81-entry--exit)
  - [8.2 Controls](#82-controls)
  - [8.3 Chrome Fade](#83-chrome-fade)
- [9. Edit Notation](#9-edit-notation)
- [10. Delete Notation (Soft Delete)](#10-delete-notation-soft-delete)
- [11. Duplicate Notation](#11-duplicate-notation)
- [12. Tags](#12-tags)
  - [12.1 Tag List](#121-tag-list)
  - [12.2 Create Tag](#122-create-tag)
  - [12.3 Edit Tag](#123-edit-tag)
  - [12.4 Delete Tag](#124-delete-tag)
  - [12.5 Apply Tag from Library](#125-apply-tag-from-library)
- [13. Instrument Tracker](#13-instrument-tracker)
  - [13.1 Instrument Class](#131-instrument-class)
  - [13.2 Instrument Instance](#132-instrument-instance)
  - [13.3 Archive Instance](#133-archive-instance)
- [14. Trash](#14-trash)
- [15. Settings](#15-settings)
- [16. Appearance & Theming](#16-appearance--theming)
- [17. Custom Fields](#17-custom-fields)

---

## 1. Overview

Canonical UX flow reference for Swaralipi V1. One user. Android only. No auth, no cloud.

**Sources:**
[PRD](../01-product/PRD.md) ·
[Navigation Structure](./navigation-structure.md) ·
[Feature DAG](./feature-dag.md) ·
[Data Model](./data-model.md)

---

## 2. Global Shell & Navigation

**Shell:** `BottomNavShell` wraps all in-shell screens. Two tabs.

| Tab | Label | Route | Screen |
|-----|-------|-------|--------|
| 0 | Library | `/` | `LibraryScreen` |
| 1 | Settings | `/settings` | `SettingsScreen` |

**Out-of-shell screens** (full-screen, no bottom nav):

| Screen | Route |
|--------|-------|
| `PlayerScreen` | `/notation/:notationId/player` |
| `PageEditorScreen` | `/capture/editor` |
| `MetadataFormScreen` | `/capture/metadata` |
| `ErrorScreen` | `/error` |

Tab switch: `context.go('/')` / `context.go('/settings')`.
Active tab state preserved via `StatefulShellRoute`. See [Navigation §3](./navigation-structure.md#3-shell-structure).

---

## 3. Library — Home Screen

Route: `/` · In shell. See [PRD §5.3](../01-product/PRD.md#53-library-home-screen).

### 3.1 Default State

```
AppBar
  "Hi, <name>"             ← name from Settings > Your Name
  [Sort control]
  [Search bar]
  [Tag chips row]          ← active filter shortcuts
Recently Played Carousel   ← hidden if nothing played yet
Notation List
FAB (bottom-right)
```

### 3.2 Recently Played Carousel

- Shows **≤ 5** most recent by `last_played_at DESC`.
- Hidden when `last_played_at IS NULL` for all notations.
- Card: thumbnail + title.
- Tap card → `NotationDetailScreen` (`/notation/:id`).

### 3.3 Search

1. User taps search bar.
2. Keyboard up. Type query.
3. App runs fuzzy search across: title, artists, notes, tags, language, key sig, time sig, custom field values.
4. List filters live. Matched field highlighted in row.
5. Exact-match toggle (icon in bar) → switches to exact string match.
6. Clear query → full list restores.

### 3.4 Sort

1. User taps sort control in AppBar.
2. Sheet / dropdown shows options:

| Option | Default direction |
|--------|-------------------|
| Title | A-Z |
| Date written | Newest first |
| Date added | Newest first |
| Play count | Most first |
| Last played | Most recent first |

3. Tap option → toggle ASC/DESC on re-tap.
4. List re-renders. Selection persists in session and across restarts (stored in Settings > Library > Default sort).

### 3.5 Filter

#### 3.5.1 Quick Tag Filter

- Tag chips row above list. One chip per tag that exists.
- Tap chip → toggle. Active = highlighted.
- Multiple chips active → AND logic by default.
- Tap active chip → deactivate.

#### 3.5.2 Advanced Filter Drawer

1. User taps filter icon → bottom sheet slides up.
2. Fields:

| Field | Input |
|-------|-------|
| Tags | Multi-select chips |
| Instruments | Multi-select chips |
| Language | Multi-select chips |
| Key signature | Free text |
| Time signature | Free text |
| Date written range | Two date pickers |
| Date added range | Two date pickers |
| Play count range | Number range |
| Custom field values | Per-field input |

3. AND / OR toggle per filter group.
4. **Apply** → sheet closes, list filters.
5. **Save as Preset** → prompt for name → stored; appears in preset list.
6. **Reset** → all filters cleared.
7. Active filter = banner above list with "Filtered" label + clear button.
8. Session-scoped. Cold restart clears unless preset loaded.

### 3.6 Notation Row Actions

#### Swipe Left

1. Swipe row left → two colored badges appear inline:
   - **Edit** (left badge)
   - **Delete** (right badge)
2. Tap **Edit** → [Edit Notation flow (§9)](#9-edit-notation).
3. Tap **Delete** → [Delete flow (§10)](#10-delete-notation-soft-delete).
4. Swipe right or tap elsewhere → dismiss badges.

#### Long Press

1. Long press row → floating context menu:
   - Edit
   - Delete
   - Add Tag
   - Duplicate
2. **Edit** → [§9](#9-edit-notation).
3. **Delete** → [§10](#10-delete-notation-soft-delete).
4. **Add Tag** → tag picker bottom sheet (existing tags only) → select → applied immediately.
5. **Duplicate** → [§11](#11-duplicate-notation).

---

## 4. Notation Capture

See [PRD §5.1](../01-product/PRD.md#51-notation-capture) · [Feature DAG F01](./feature-dag.md#32-features).

### 4.1 Entry Point

1. Tap FAB on `LibraryScreen`.
2. Bottom sheet slides up with two options:

| Option | Next step |
|--------|-----------|
| Gallery | [§4.2](#42-gallery-flow) |
| Camera | [§4.3](#43-camera-flow) |

### 4.2 Gallery Flow

```
FAB tap
  → Capture Entry Sheet
    → [Gallery]
      → Android system photo picker (multi-select)
        → user selects images
          → PageEditorScreen (/capture/editor)
```

- Multi-select allowed in system picker.
- Selected images arrive as a page set in the editor.

### 4.3 Camera Flow

```
FAB tap
  → Capture Entry Sheet
    → [Camera]
      → app records launch_timestamp
        → device camera app opens (intent)
          → user takes photos
            → user presses back
              → app queries MediaStore for images WHERE date_added >= launch_timestamp
                → "Photos taken just now" selection screen
                  → thumbnails shown
                    → user selects which to include
                      → [Confirm]
                        → PageEditorScreen (/capture/editor)
```

- If no images found after returning from camera → empty state message on selection screen with option to open gallery or retry camera.

---

## 5. Page Editor

Route: `/capture/editor` · Out-of-shell. See [PRD §5.1 Page Editor](../01-product/PRD.md#51-notation-capture).

### 5.1 Layout

```
TopBar: [Save]  [Discard]
─────────────────────────
Active Page Preview       ← full-width, large
─────────────────────────
Per-Page Toolbar:
  Filter | Crop | Rotate | Auto-straighten | Delete Page
─────────────────────────
Thumbnail Strip (bottom)
  [+Add] [thumb1] [thumb2] ...
```

- Horizontal carousel. Swipe or tap thumbnail to switch active page.
- Thumbnail strip: drag-to-reorder.

### 5.2 Per-Page Actions

| Action | Behavior |
|--------|----------|
| Filter | Opens filter picker. Options: Original · B&W · Grayscale · Enhanced · Warm Tint · Cool Tint. Apply-to-all shortcut available. Non-destructive — applied at display time only. |
| Crop | Corner-handle drag. Aspect lock toggle. Confirm or cancel. |
| Rotate | Taps cycle: 0° → 90° CW → 180° → 270° CW → 0°. |
| Auto-straighten | Per-page toggle. Off by default. When on, skew correction applied at render. |
| Delete page | Confirmation tap. Removes page from session. If last page → show warning before allowing delete. |

### 5.3 Notation-Level Actions

| Action | Behavior |
|--------|----------|
| Add page | Taps `[+]` in thumbnail strip → opens same bottom sheet as §4.1 (Gallery / Camera). New pages appended after current last page. |
| Reorder pages | Drag thumbnail in strip to new position. Active preview updates. |

### 5.4 Save / Discard

| Action | Behavior |
|--------|----------|
| Save | Pages locked in; navigate forward to `MetadataFormScreen` (`/capture/metadata`). |
| Discard | Confirmation dialog ("Discard all pages?") → yes → back to Library. No files written. |

---

## 6. Metadata Form

Route: `/capture/metadata` · Out-of-shell. See [PRD §5.2](../01-product/PRD.md#52-metadata).

### 6.1 Layout

```
TopBar: [Back to Editor]  [Save]
────────────────────────────────
Scrollable form fields
  Required: Title
  Optional: all others
────────────────────────────────
```

Back to Editor: returns to `PageEditorScreen` with pages intact.

### 6.2 Fields

| Field | Input Type | Notes |
|-------|------------|-------|
| Title | Text field | Required. Blocks save if empty. |
| Artist(s) | Chip input | One or many. Type + enter to add chip. |
| Date written | Date picker | Defaults to today. |
| Time signature | Free text | e.g. 4/4, 6/8, free |
| Key signature | Free text | e.g. C major, Yaman |
| Language | Multi-select chips | Hindi · Bengali · English · Sanskrit · Other |
| Tags | Multi-select + inline create | Existing tags shown as chips. Type to create new inline. |
| Instruments | Multi-select chips | From instrument list (§13). |
| Personal notes | Multi-line text | Free-form. |
| Custom fields | Per-field input | Shown if custom fields defined in Settings (§17). Types: text, number, date, boolean. |

### 6.3 Save Gate

- **Save** button disabled until Title is non-empty.
- On tap **Save**:
  1. Write image files to disk via `FileStorageService`.
  2. Insert `Notation` + `NotationPage` rows in DB.
  3. Navigate back to `/` (Library).
  4. New notation appears at top (sorted by date added desc by default).

---

## 7. Notation Detail View

Route: `/notation/:notationId` · In shell. See [PRD §5.4](../01-product/PRD.md#54-notation-detail-view).

### 7.1 Layout

```
TopBar: [Back]  [Edit icon]  [Delete icon]
──────────────────────────────────────────
Page stack preview (center, decorative)
  ← fanned-paper visual; tappable
──────────────────────────────────────────
Metadata block:
  Title (hero text)
  Artist(s)
  Date written · Language
  Key sig · Time sig
  Tags (chips)
──────────────────────────────────────────
[Play button] (large, bottom)
```

### 7.2 Actions

| Trigger | Action |
|---------|--------|
| Tap page stack preview | → `PlayerScreen` (`/notation/:id/player`). Increments `play_count`. Sets `last_played_at`. |
| Tap **Play** button | Same as above. |
| Tap **Edit icon** (top bar) | → [Edit Notation (§9)](#9-edit-notation). |
| Tap **Delete icon** (top bar) | → [Delete Notation (§10)](#10-delete-notation-soft-delete). |

---

## 8. Notation Player

Route: `/notation/:notationId/player` · Out-of-shell. See [PRD §5.5](../01-product/PRD.md#55-notation-player).

### 8.1 Entry & Exit

- Entry: Play button or page preview tap in Detail View.
- Exit: Tap back (hardware or software) → returns to `NotationDetailScreen`.

### 8.2 Controls

```
Title (top, fades)
───────────────────
Notation page (full-screen)
  Swipe L/R: next/prev page
  Pinch: zoom in/out
  Pan: scroll when zoomed
───────────────────
Page indicator: "2 / 5" (fades with chrome)
───────────────────
Toolbar (bottom, fades):
  Fit to width
  Fit to height
  Fit to screen
  Rotate / orientation lock (portrait ↔ landscape)
```

### 8.3 Chrome Fade

- Title + toolbar visible on entry.
- Fade out after **2 s** of inactivity.
- Tap anywhere → restore chrome for 2 s.
- No auto-scroll in V1.

---

## 9. Edit Notation

Entry points: swipe-left Edit badge · long-press Edit · Detail View Edit icon.

```
Entry point
  → PageEditorScreen (/capture/editor?notationId=:id)
    Pages pre-loaded. All per-page actions available.
    Can add, delete, reorder, re-crop, re-filter pages.
      → [Save]
        → MetadataFormScreen
          Form pre-filled with existing metadata.
          All fields editable.
            → [Save]
              → updated DB rows + any new/removed files
              → back to NotationDetailScreen (/notation/:id)
```

- Images changed: old files replaced, new files written. File paths updated in DB.
- Images unchanged: original files kept on disk. No re-write.

---

## 10. Delete Notation (Soft Delete)

Entry points: swipe-left Delete badge · long-press Delete · Detail View Delete icon.

```
Tap Delete
  → Confirmation dialog: "Move to Trash?"  [Cancel] [Delete]
    [Cancel] → dismiss, no change
    [Delete]
      → notation.deleted_at = now()
      → notation removed from Library list
      → if entered from Detail View: navigate back to /
      → notification snackbar: "Moved to Trash" + [Undo]
        [Undo] → deleted_at = null → notation restored to Library
```

Auto-purge: notation permanently deleted 30 days after `deleted_at`. See [Trash (§14)](#14-trash).

---

## 11. Duplicate Notation

Entry: long-press context menu → Duplicate.

```
Tap Duplicate
  → new Notation row created
  → image files copied to new paths on disk
  → title = "Copy of <original title>"
  → all metadata copied
  → opens immediately in PageEditorScreen (edit mode) for the new notation
```

User can edit the duplicate immediately or save as-is.

---

## 12. Tags

Route: `/settings/tags`. See [PRD §5.7](../01-product/PRD.md#57-tags) · [Feature DAG F07](./feature-dag.md#32-features).

### 12.1 Tag List

```
TagsScreen (/settings/tags)
  AppBar: "Tags"  [+ Create]
  ──────────────────────────
  List of tags
    Each row: colored chip · name · [Edit icon] · [Delete icon]
```

Pre-seeded defaults (editable, not locked): `practice` · `raag` · `song` · `classical` · `piece`.

### 12.2 Create Tag

```
Tap [+ Create]
  → TagFormScreen (/settings/tags/new)
    Fields:
      Name (text, required)
      Color (Catppuccin palette picker, required)
    [Save] → creates tag → back to TagsScreen
    [Cancel] → back, no change
```

### 12.3 Edit Tag

```
Tap Edit icon on row
  → TagFormScreen (/settings/tags/:tagId/edit)
    Pre-filled with existing name + color.
    Same fields as create.
    [Save] → updates tag → all notation chips update → back
    [Cancel] → back, no change
```

### 12.4 Delete Tag

```
Tap Delete icon on row
  → Confirmation dialog: "Delete tag? Removes from all notations."
    [Cancel] → dismiss
    [Delete]
      → tag row deleted
      → removed from all notation_tags junction rows
      → chips removed from all notation views
      → back to TagsScreen
```

### 12.5 Apply Tag from Library

```
Long press notation row → "Add Tag"
  → Bottom sheet: existing tags as chips
    Tap chip → applied immediately
    Already-applied tags shown as selected
    [Done] → sheet closes
```

---

## 13. Instrument Tracker

Route: `/settings/instruments`. See [PRD §5.6](../01-product/PRD.md#56-instrument-tracker) · [Feature DAG F06](./feature-dag.md#32-features).

### 13.1 Instrument Class

```
InstrumentsScreen (/settings/instruments)
  AppBar: "Instruments"  [+ New Class]
  ──────────────────────────────────────
  List of classes
    Each class: name · expand/collapse to show instances
    [+ Add Instance] button per class
```

#### Create Class

```
Tap [+ New Class]
  → InstrumentClassFormScreen (/settings/instruments/class/new)
    Fields:
      Name (text, required)
    [Save] → class created → back
    [Cancel] → back, no change
```

No pre-seeded classes. User creates freely.

### 13.2 Instrument Instance

#### Create Instance

```
Tap [+ Add Instance] on a class row (or via /settings/instruments/instance/new)
  → InstrumentInstanceFormScreen
    Fields:
      Instrument Class (pre-selected if entered from class row; else dropdown)
      Brand (text, optional)
      Model (text, optional)
      Color (Catppuccin palette picker)
      Price (integer, INR, optional)
      Photo / Artwork (gallery picker, optional)
      Notes (long text, optional)
    [Save] → instance created → back to InstrumentsScreen
    [Cancel] → back, no change
```

#### View Instance Detail

```
Tap instance row
  → InstrumentInstanceDetailScreen (/settings/instruments/instance/:instanceId)
    Shows all fields.
    [Edit] → InstrumentInstanceFormScreen (pre-filled)
    [Archive] → §13.3
```

#### Edit Instance

```
Tap [Edit] on detail screen or edit icon on row
  → InstrumentInstanceFormScreen (/settings/instruments/instance/:instanceId/edit)
    Pre-filled. All fields editable.
    [Save] → updated → back to detail
    [Cancel] → back, no change
```

### 13.3 Archive Instance

```
Tap [Archive] on InstrumentInstanceDetailScreen
  → Confirmation dialog: "Archive instrument? It will no longer appear in pickers."
    [Cancel] → dismiss
    [Archive]
      → instance.archived_at = now()
      → removed from notation metadata pickers
      → still displayed on existing notations that reference it (greyed out / badge)
      → back to InstrumentsScreen
```

No hard delete. Archived instances not shown in list by default; toggle to show archived.

---

## 14. Trash

Route: `/settings/trash`. See [PRD §5.9](../01-product/PRD.md#59-trash) · [Feature DAG F09](./feature-dag.md#32-features).

```
TrashScreen (/settings/trash)
  AppBar: "Trash"  [Empty Trash]
  ──────────────────────────────
  List of soft-deleted notations
    Each row: thumbnail · title · "Deleted X days ago"
    Per-row actions: [Restore] · [Delete Permanently]
```

| Action | Behavior |
|--------|----------|
| **Restore** | `deleted_at = null` → notation reappears in Library. Snackbar confirms. |
| **Delete Permanently** | Confirmation dialog → files deleted from disk + DB row removed. |
| **Empty Trash** | Confirmation dialog ("Permanently delete all items in Trash?") → all trash items purged. |

Auto-purge: cron / app-start job deletes notations where `deleted_at < now() - 30 days`.

---

## 15. Settings

Route: `/settings`. See [PRD §5.11](../01-product/PRD.md#511-settings) · [Navigation §4.3](./navigation-structure.md#43-settings-branch).

```
SettingsScreen (/settings)
  ──────────────────────
  Appearance              → /settings/appearance (in-screen section or sub-route)
  Tags                    → /settings/tags
  Instruments             → /settings/instruments
  Library
    Default sort          → inline picker
  Custom Fields           → /settings/custom-fields
  Your Name               → inline text field or dialog
  Trash                   → /settings/trash
  About                   → app version + build
  Open Source Licenses    → third-party license list
```

Tap any row → navigate to that sub-screen.

---

## 16. Appearance & Theming

Accessed via Settings > Appearance. See [PRD §5.10](../01-product/PRD.md#510-appearance--theming) · [Feature DAG F10](./feature-dag.md#32-features).

### 16.1 Theme Mode

```
Three-option toggle: Light · Dark · System
Tap → applies immediately. Persists to SharedPreferences.
```

### 16.2 Color Scheme

```
Two modes (radio):
  ○ Dynamic (Monet)   ← pulls from Android wallpaper
  ○ Seed Color        ← user picks swatch

[Dynamic selected]
  → ColorScheme.fromSeed built from Monet seed.

[Seed Color selected]
  → Swatch row appears.
    Light mode: Catppuccin Latte palette swatches.
    Dark mode: Catppuccin Mocha palette swatches.
    Tap swatch → ColorScheme.fromSeed(seedColor: tapped) regenerated.
    App re-themes instantly.
```

All other color pickers in-app (tags, instrument color) use Catppuccin palette only. No free-form color pickers anywhere.

---

## 17. Custom Fields

Route: `/settings/custom-fields`. See [PRD §5.2 Custom Fields](../01-product/PRD.md#52-metadata) · [Feature DAG F02](./feature-dag.md#32-features).

```
CustomFieldsScreen (/settings/custom-fields)
  AppBar: "Custom Fields"  [+ Add Field]
  ─────────────────────────────────────
  List of user-defined fields
    Each row: field name · type badge · [Edit] · [Delete]
```

#### Create Custom Field

```
Tap [+ Add Field]
  → Dialog / sheet:
    Field Name (text, required)
    Type (select): Text · Number · Date · Boolean
    [Save] → field added → appears in Metadata Form for all notations
    [Cancel] → dismiss
```

#### Edit Custom Field

```
Tap [Edit] on row
  → Same dialog, pre-filled.
  → Name editable. Type editable (with warning if existing data may be incompatible).
  [Save] → updated everywhere.
```

#### Delete Custom Field

```
Tap [Delete] on row
  → Confirmation: "Delete field? Data in all notations will be lost."
    [Cancel] → dismiss
    [Delete]
      → field definition deleted
      → all custom_field_value rows for this field deleted
      → field disappears from Metadata Form
```
