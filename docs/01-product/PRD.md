# Swaralipi — Product Requirements Document

> **Status:** Final v1.0 — PRD closed; moving to Architecture phase
> **Date:** 2026-04-23
> **Author:** Roudranil (via PM session)

---

## Table of Contents

<!-- DO NOT FILL MANUALLY — use a TOC generator or leave for tooling -->

---

## 1. Overview

Single-user Android app. Musician. Hand-written sargam + sheet music. Digitize it. Find it. Play it.

No accounts. No cloud. No multi-tenancy. Everything on-device.

---

## 2. Goals

- Capture notation pages (camera or gallery), clean and tag before saving
- Find notations fast — search, sort, filter on all metadata
- Open a notation detail, then launch full-screen player
- Track instruments with photos and metadata
- Look great, feel premium — Material 3 with Catppuccin color palette

---

## 3. Non-Goals (v1)

- No cloud sync
- No export (PDF / image zip) — v2
- No multi-user
- No audio recording or playback
- No OCR / notation recognition
- No collections / sets — v2
- No SVG instrument class icons — v2
- No practice calendar / session logging — v2
- No play-event log for time-series stats — v2
- No stats screen — v2

---

## 4. Users

One. You. Musician. Samsung Galaxy S25.

---

## 5. Feature Areas

---

### 5.1 Notation Capture

#### Entry Point

FAB on Library screen → bottom sheet slides up → two options: **Gallery** or **Camera**.

#### Gallery Flow

- Taps "Gallery" → Android M3 system photo picker opens
- Multi-select allowed
- Selected photos → Page Editor (§5.1.3)

#### Camera Flow

- Taps "Camera" → app records current timestamp → device default camera app opens via intent
- User takes one or many photos in the native camera app
- User presses back → returns to Swaralipi
- App queries media store for images with `date_added ≥ launch_timestamp`
- Shows a selection screen: "Photos taken just now" — thumbnails of those images
- User selects which ones to include
- Selected photos → Page Editor (§5.1.3)

#### Page Editor

Full-screen editor. Pages shown in a horizontal carousel (big previews). Thumbnail strip at bottom for quick navigation.

**Per-page actions** (toolbar beneath active page preview):

| Action | Detail |
|---|---|
| Filter | Pick from filter list; non-destructive — applied at display time, not baked into image |
| Crop | Corner handle crop with aspect lock toggle |
| Rotate | 90° CW / CCW |
| Auto-straighten | Per-page toggle; off by default |
| Delete page | Confirmation tap; removes from session |

**Notation-level actions** (top bar or floating controls):

| Action | Detail |
|---|---|
| Add page | Opens same bottom sheet as initial capture (Gallery or Camera) |
| Reorder | Drag thumbnails in strip to reorder pages |

**Filters available (non-destructive):**

- Original (no filter)
- B&W (high contrast)
- Grayscale
- Enhanced (auto-contrast + brightness boost)
- Warm tint
- Cool tint

Apply-to-all shortcut available for filter selection.

**Top bar:** Save · Discard

#### Metadata Form

Slides in after page editor (or accessible via collapsible section on top of editor). Save is blocked until required fields are filled.

Required: **Title**. All other fields optional.

See §5.2 for full field list.

---

### 5.2 Metadata

| Field | Type | Notes |
|---|---|---|
| Title | Text | Required |
| Artist(s) | Multi-chip text | Chip input; one or many |
| Date Written | Date picker | Defaults to today |
| Time Signature | Free text | e.g. 4/4, 6/8, free |
| Key Signature | Free text | e.g. C major, Yaman, Bhairavi |
| Language | Multi-select | Hindi, Bengali, English, Sanskrit, Other; multiple allowed |
| Tags | Multi-select + create | From tag list (§5.7); user can add new tags inline |
| Instruments | Multi-select | From instrument list (§5.6) |
| Personal Notes | Long text | Free-form |
| Custom Fields | Key-value | User-defined in Settings; types: text, number, date, boolean |
| Created At | Auto | System timestamp |
| Updated At | Auto | System timestamp |

---

### 5.3 Library (Home Screen)

Default and only home screen. Bottom nav: **Library · Settings**.

#### Header

"Hi, \<name\>" greeting at top. Name set in Settings (see §5.10).

#### Recently Played Carousel

Horizontal carousel of up to 5 most recently played notations (ordered by `last_played_at` descending). "Played" means Play button was pressed in detail view (§5.4). Carousel hidden if no notations have been played yet.

Each card: thumbnail, title.

#### Notation List

Below the carousel. Default view: **list**.

Each row:
- Square thumbnail on the left
- Title and artist name stacked on the right
- Tags as chips below the title/artist block

**Swipe left** on a row → two colored action badges appear inline: **Edit** · **Delete**.

**Long press** a row → floating context menu: Edit · Delete · Add Tag · Duplicate.

"Add Tag" in context menu: opens tag picker (existing tags only) to apply to that notation.

#### Search Bar

Always visible at top of list. Fuzzy match across all metadata fields: title, artists, notes, tags, language, key signature, time signature, custom field values. Exact match toggle (icon in search bar).

Search highlights matched field in result row.

#### Sort

Sort control in top bar. Options:
- Title (A-Z / Z-A)
- Date written (newest / oldest)
- Date added (newest / oldest)
- Play count (most / least)
- Last played (most recent first)

#### Filter

**Simple filter:** Tag chips above list — tap to toggle active tag filter.

**Advanced filter drawer:** Slide up from bottom.

- Filter by: tag(s), instrument(s), language, key signature, time signature, date range (written), date range (added), play count range, custom field values
- Conditions: AND / OR toggle per filter group
- Save filter as a named preset
- Filters work against all metadata fields

Active filter state persists within the session. Resets on app cold start unless a preset is loaded.

#### FAB

Fixed bottom-right. Tapping opens capture flow (§5.1).

---

### 5.4 Notation Detail View

Tap a notation row in the library → Detail View.

**Layout:**

- Top bar: Edit icon · Delete icon
- Center: page preview — macOS-like fanned paper stack visual (decorative; shows whether notation is single or multi-page), tappable to enter player (§5.5)
- Below preview: metadata block — title, artist, date written, language, key sig, time sig
- Bottom: large **Play** button

**Play button behavior:**
- Increments `play_count` by 1
- Sets `last_played_at` to now
- Opens the Notation Player (§5.5)

**Edit icon:** Opens notation creation/edit window (same as §5.1 page editor + metadata form, pre-filled).

**Delete icon:** Confirmation dialog → soft delete (§5.9).

---

### 5.5 Notation Player

Full-screen. Entered via Play button in Detail View (§5.4).

- Shows notation pages full-screen; no chrome
- Title shown at top (fades after 2s of inactivity; tap to restore)
- Swipe left/right to move between pages
- Page indicator (e.g. 1 / 3)
- Pinch-to-zoom, pan
- Toolbar (fades with title):
  - Fit to width
  - Fit to height
  - Fit to screen
  - Rotate / force orientation toggle (portrait ↔ landscape)
- No auto-scroll

---

### 5.6 Instrument Tracker

Accessed via Settings > Instruments.

**What:** Two-level model — Instrument Class and Instrument Instance.

#### 5.6.1 Instrument Class

The *type* of instrument (e.g., Mandolin, Banjo, Melodica).

| Field | Type | Notes |
|---|---|---|
| Name | Text | Required; e.g., "Mandolin" |

- User creates classes freely; no pre-seeded list
- SVG icon per class: v2

#### 5.6.2 Instrument Instance

A specific physical instrument the user owns within a class. Multiple instances of the same class allowed (e.g., two mandolins).

| Field | Type | Notes |
|---|---|---|
| Instrument Class | Select | Required; pick from class list |
| Brand | Text | Optional; e.g., "Washburn" |
| Model | Text | Optional; e.g., "M1SDLB" |
| Color | Color pick | From Catppuccin palette; serves as both the instrument's identifying color and its UI accent |
| Price | Integer | Optional; stored in INR; displayed as ₹ amount |
| Photo / Artwork | Image | Gallery only; shown as preview in list |
| Notes | Long text | Optional |

- No hard delete; instruments are soft-deleted (archived). Archived instruments no longer appear in notation pickers but still display on notations that reference them.
- No limit on instances or classes
- Instance list view: square photo on left, class name + brand/model on right, color as left-border accent
- All fields editable after creation

---

### 5.7 Tags

Accessed via Settings > Tags.

- All tags fully editable: name and color
- Color pick from Catppuccin palette only
- Create, rename, recolor, delete any tag
- Deleting a tag removes it from all notations that have it
- Default tags (pre-seeded, not locked): `practice` · `raag` · `song` · `classical` · `piece`
- Tags shown as colored chips throughout the app
- "Add Tag" available from notation context menu (long press) in library

---

### 5.8 Edit, Delete, Copy

Accessible from: swipe-left in library list, long-press context menu, or detail view top bar.

- **Edit:** Opens page editor + metadata form pre-filled. Can add new pages, delete pages, reorder, re-crop, re-filter, and edit all metadata fields.
- **Delete:** Confirmation dialog → soft delete. Notation moves to Trash. Permanent after 30 days.
- **Duplicate:** Hard copy — new notation created with copied images (separate files on disk) and same metadata. Title prefixed with "Copy of". Opens immediately in edit mode.

---

### 5.9 Trash

Accessed via Settings > Trash.

- List of soft-deleted notations with deletion date
- Per-item: **Restore** or **Delete Permanently**
- **Empty Trash** button at top: permanently deletes all items
- Items auto-purged after 30 days

---

### 5.10 Appearance & Theming

#### Theme Mode

Three options: **Light · Dark · System**. Toggle in Settings > Appearance.

#### Color Scheme

Two modes:

1. **Dynamic (Monet)** — pulled from Android 12+ wallpaper. No fallback for older Android (S25 is Android 15, not a concern).
2. **Seed Color** — user picks from preset swatches.

**Preset swatches:**
- Dark mode → **Catppuccin Mocha** color palette
- Light mode → **Catppuccin Latte** color palette

All in-app color choices (tags, instrument display color, etc.) use the Catppuccin palette only — no free-form color pickers.

Swatches shown as a color picker row in Settings > Appearance. Picking a swatch regenerates `ColorScheme.fromSeed` from that color.

---

### 5.11 Settings

**Structure:**

```
Settings
├── Appearance
│   ├── Theme (Light / Dark / System)
│   └── Color Scheme (Dynamic / Seed → palette picker)
├── Tags           → tag list with edit/create/delete
├── Instruments    → instrument list (§5.6)
├── Library
│   └── Default sort
├── Custom Fields  → manage key-value metadata fields
├── Your Name      → name shown in library greeting
├── Trash          → §5.9
├── About          → app version
└── Open Source Licenses
```

---

## 6. Navigation Structure

```
Bottom Nav (v1):
├── Library (home)  [§5.3]
└── Settings        [§5.11]

Library
├── → Notation Detail View  [§5.4]
│       └── → Notation Player  [§5.5]
└── → Add Notation (capture flow)  [§5.1]

Settings
├── → Tags
├── → Instruments
├── → Trash
└── → Custom Fields
```

**V2 additions to nav (not in scope now):**
- Stats screen (bottom nav item)
- Practice Calendar (bottom nav item)
- Collections / Sets

---

## 7. Data Model (High-Level)

```
Notation
  id, title, artists[], date_written, time_sig, key_sig,
  languages[], tags[], instrument_instance_ids[], notes,
  custom_fields{}, play_count, last_played_at,
  created_at, updated_at, deleted_at

NotationPage
  id, notation_id, page_order, image_path,
  filter_applied, crop_rect, auto_straighten, created_at
  (filter and crop are non-destructive — applied at render time)

Tag
  id, name, color (Catppuccin hex)

InstrumentClass
  id, name, created_at, updated_at
  (svg_path: v2)

InstrumentInstance
  id, class_id, brand, model, color (Catppuccin hex),
  price_inr, photo_path, notes,
  created_at, updated_at, deleted_at (soft delete / archive)

CustomFieldDefinition
  id, key_name, field_type (text | number | date | boolean)

UserPreferences
  user_name, theme_mode, color_scheme_mode,
  seed_color, default_sort, default_view

-- V2 --
PracticeSession
  id, date, duration_minutes, notation_ids[],
  instrument_ids[], notes, created_at

PlayEvent
  id, notation_id, played_at
  (enables time-series play count stats)
```

---

## 8. Non-Functional Requirements

| Requirement | Target |
|---|---|
| Cold start | < 2s |
| Library load (100 notations) | < 500ms |
| Image display in viewer | < 300ms per page |
| Search response | < 200ms |
| Local storage | All images in app-private directory |
| Offline | 100% offline — zero network calls |
| Accessibility | TalkBack support; 4.5:1 contrast min |
| Orientation | Portrait + Landscape throughout |
| Filter rendering | Non-destructive; original image always preserved |

---

## 9. Open Questions

None. PRD closed.

---

## 11. Decisions Log

| ID | Decision | Date |
|---|---|---|
| D-01 | No backend, no cloud, no auth — fully on-device | 2026-04-23 |
| D-02 | Flutter + Material 3 + ChangeNotifier MVVM | 2026-04-23 |
| D-03 | Catppuccin Mocha / Latte as the only color palette in the app | 2026-04-23 |
| D-04 | Soft delete with 30-day retention + manual empty trash | 2026-04-23 |
| D-05 | Play count increments only on Play button press, not on detail view open | 2026-04-23 |
| D-06 | Filters are non-destructive — applied at render time; original image preserved | 2026-04-23 |
| D-07 | Auto-straighten is a per-page toggle, off by default | 2026-04-23 |
| D-08 | Auto-scroll removed from v1 entirely | 2026-04-23 |
| D-09 | Camera flow: use device camera intent + MediaStore timestamp query | 2026-04-23 |
| D-10 | Language field supports multiple values per notation | 2026-04-23 |
| D-11 | Tags are fully user-editable (name + Catppuccin color); default 5 are seeds only | 2026-04-23 |
| D-12 | Instrument photo from gallery only (no in-app camera) | 2026-04-23 |
| D-13 | Duplicate notation = hard copy of images on disk | 2026-04-23 |
| D-14 | Dynamic Monet color: no fallback for older Android (S25 is the device) | 2026-04-23 |
| D-15 | Bottom nav v1: Library + Settings only. Stats and Calendar are v2. | 2026-04-23 |
| D-16 | Search and filter work against all metadata fields | 2026-04-23 |
| D-17 | Camera flow implementation: defer to architecture phase | 2026-04-23 |
| D-18 | Fanned paper stack = decorative only; no per-page tap | 2026-04-23 |
| D-19 | "Add Tag" from context menu = existing tags only | 2026-04-23 |
| D-20 | Display color is decorative accent; placement at architect's discretion | 2026-04-23 |
| D-21 | Add page + Reorder are notation-level, not per-page; Add page opens same bottom sheet as initial capture | 2026-04-23 |
| D-22 | Instrument price stored as INR integer; displayed with ₹; decorative | 2026-04-23 |
| D-23 | Recently played carousel = Play-button only; detail view open does not count | 2026-04-23 |
| D-24 | Filter/search/sort state resets on cold start; presets deferred to v2 | 2026-04-23 |
| D-25 | No grid view in v1; list only | 2026-04-23 |
| D-26 | Swipe-left Edit = full edit window (page editor + metadata) | 2026-04-23 |
| D-27 | Auto-scroll is not a feature | 2026-04-23 |
| D-28 | Instruments use Class/Instance model: InstrumentClass (type + SVG) + InstrumentInstance (physical item) | 2026-04-23 |
| D-29 | SVG icon is per InstrumentClass; user uploads their own SVG files | 2026-04-23 |
| D-30 | Instrument reference integrity on notation delete: deferred to architecture phase | 2026-04-23 |
| D-31 | Instrument color = single Catppuccin pick; serves as both identifying color and UI accent | 2026-04-23 |
| D-32 | SVG icons for InstrumentClass: v2 | 2026-04-23 |
| D-33 | Notation Instruments picker shows InstrumentInstances (not classes) | 2026-04-23 |
| D-34 | Instruments use soft delete only; archived instruments stay visible on existing notations | 2026-04-23 |
| D-35 | Tag delete cascades — tag removed from all notations automatically; no block | 2026-04-23 |