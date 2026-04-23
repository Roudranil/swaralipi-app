# Swaralipi — Product Requirements Document

> **Status:** Draft v0.2
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

Per-page actions available via toolbar beneath preview:

| Action | Detail |
|---|---|
| Filter | Pick from filter list; non-destructive — applied at display time, not baked into image |
| Crop | Corner handle crop with aspect lock toggle |
| Rotate | 90° CW / CCW |
| Auto-straighten | Per-page toggle; off by default |
| Add page | Opens gallery picker or camera flow for that slot |
| Delete page | Confirmation tap; removes from session |
| Reorder | Drag thumbnail in strip to reorder |

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
- Title (A–Z / Z–A)
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
- Center: page preview — macOS-like fanned paper stack visual (multiple pages visible, fanned slightly), tappable to enter player (§5.5)
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

**What:** Log instruments you own/play. Used to tag notations and filter the library.

Each instrument:

| Field | Type | Notes |
|---|---|---|
| Name | Text | Required |
| Brand | Text | Optional |
| Model | Text | Optional |
| Price | Number | Optional; stored as integer (₹ or $, currency TBD) |
| Display Color | Color pick | From Catppuccin palette only; used as accent in UI |
| Photo / Artwork | Image | Gallery only (no camera); shown as preview in list |
| Notes | Long text | Optional |

- No limit on number of instruments
- Instrument list view: square photo on left, name + brand on right, display color as left-border accent
- All fields editable after creation
- Deleting an instrument does not remove it from existing notations' metadata (stored as name string, not FK reference — resolve in architecture)

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
│   ├── Default sort
│   └── Default view (List / Grid)  ← Grid as optional alternate
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
  languages[], tags[], instrument_ids[], notes,
  custom_fields{}, play_count, last_played_at,
  created_at, updated_at, deleted_at

NotationPage
  id, notation_id, page_order, image_path,
  filter_applied, crop_rect, auto_straighten, created_at
  (filter and crop are non-destructive — applied at render time)

Tag
  id, name, color (Catppuccin hex)

Instrument
  id, name, brand, model, price, display_color,
  photo_path, notes, created_at, updated_at

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

## 9. Feature Gaps

> Missing, vague, or internally inconsistent requirements. Must be resolved before architecture phase.

### FG-01 — Camera flow: media timestamp query reliability

**Gap:** The camera flow relies on querying `MediaStore` for images with `date_added ≥ T` (where T = moment camera intent was launched). This is technically fragile: media indexing can lag, timestamps vary by manufacturer, and multiple camera sessions could bleed together.

**Need:** Architecture must define exact query strategy and how to handle edge cases (no new photos found, stale index, user took unrelated photos in camera app).

**Answer**: This is just a suggestion from my part. Feel free to use the best most optimised correct solution as you see fit.

---

### FG-02 — "Fanned paper stack" detail view: design undefined

**Gap:** §5.4 describes a "macOS-like fanned paper stack" for multi-page notation preview. No design spec exists. Behavior unclear: is it decorative only? Tappable per page? Swipeable?

**Need:** Design decision — static decoration (fan shows depth) vs interactive (tap top page to enter player on that page).

**Answer:** decorative only. just to show its like a single page or multiple pages. most of the times it will be a single page

---

### FG-03 — Instrument storage: FK vs name string

**Gap:** §5.6 notes that deleting an instrument "does not remove it from existing notations' metadata (stored as name string, not FK)." This is unresolved. If stored as FK, deletes cascade or orphan. If stored as name string, renames don't propagate.

**Need:** Architecture decision on reference integrity for instruments in notations.

**answer** acha we will think of it in v2 that how we can link notations to instruments

---

### FG-04 — "Add Tag" context menu: scope unclear

**Gap:** Long-press context menu includes "Add Tag." It is not clear if this opens a picker for existing tags only, or also allows creating a new tag inline from the library.

**Need:** Decision — existing tags only (simpler), or inline create (more powerful but adds complexity to the list view).

**answer** existing tags only

---

### FG-05 — Instrument display color: UI usage underspecified

**Gap:** `display_color` on Instrument is defined but its exact usage in the UI is not specified. Only the instrument list left-border accent is mentioned.

**Need:** Enumerate all places display color appears — library filter chips? notation metadata view? instrument card in settings?

**answer**: yeah wherever you think we can add an accent. its decorative

---

### FG-06 — Per-page "add photo" in editor: flow ambiguous

**Gap:** §5.1 page editor has an "Add page" action per slot. It is unclear whether this opens gallery only, camera only, or both (same bottom sheet as the initial capture entry).

**Need:** Decision — most likely both options, same bottom sheet, but confirm.

**answer** actually the add page and reorder page options are not per page but overall for the notation. add page opens the same flow as notation creation

---

### FG-07 — Currency field for instrument price

**Gap:** `price` field on Instrument is described as "integer (₹ or $, currency TBD)." Currency is unresolved.

**Need:** Decision — single currency (₹ only, since single user), or store as integer with no currency label?

**answer** its purely decorative. add a currency logo and the amount

---

### FG-08 — Recently played carousel: "played" definition edge case

**Gap:** Carousel shows "recently played" ordered by `last_played_at`. `last_played_at` is set when Play button is pressed. But notations that have never been played have no `last_played_at`. Carousel correctly hides when empty — but what if user opens detail view multiple times without pressing Play? Those never appear.

**Need:** Confirm this behavior is intentional (carousel = played only, not viewed).

**answer** yes intentional

---

### FG-09 — Filter state persistence between sessions

**Gap:** §5.3 says active filter resets on cold start unless a preset is loaded. This may be annoying in practice (user always uses the same filter).

**Need:** Decision — reset on cold start (current spec), or persist last-used filter state?

**answer** filter search sort dont persist. v2 we will think about adding filter presets

---

### FG-10 — Grid view still available?

**Gap:** §5.3 states default view is list. §5.11 Settings includes "Default view (List / Grid)" implying grid is an alternate. But the library design in the founder vision only specifies list layout. It is unclear if grid view is fully designed.

**Need:** Confirm grid view is in scope for v1, or defer to v2.

**answer** no grid layout

---

### FG-11 — Swipe-left "Edit" action behavior

**Gap:** Swipe left → Edit badge. Tapping Edit: does it open the full edit window (page editor + metadata), or a quick-edit sheet (metadata only)?

**Need:** Decision — full edit (consistent with detail view edit) is simpler to maintain.

**answer** full edit window

---

### FG-12 — Notation auto-scroll removed, but settings row remains

**Gap:** Auto-scroll was removed (per OQ-05). §5.11 Settings previously included "Auto-scroll default speed" — this has been removed in the updated settings table, but needs explicit confirmation it is gone entirely.

**Confirmed removed:** Auto-scroll default speed setting is not in v1.

**answer* i dont want auto scroll as a feature

---

## 10. Open Questions

| ID | Area | Question | Answer |
|---|---|---|---|
| OQ-A | Camera flow | Is the timestamp-based media query approach acceptable, or do you want to explore an alternative (e.g. custom in-app camera using CameraX instead of native intent)? | up to you. choose the best |
| OQ-B | Detail view | Fanned paper stack: decorative only, or tapping a page opens player starting at that page? | decorative. already mentioned |
| OQ-C | Instruments | FK reference or name string for instrument ↔ notation link? (Affects rename/delete behavior.) | already answered |
| OQ-D | Tags | "Add Tag" from context menu — existing tags only, or also allow creating new tag inline? | already answered |
| OQ-E | Instruments | Currency for price field — ₹ only, or label-free integer? | already answered |
| OQ-F | Library | Is grid view in scope for v1 or deferred to v2? | already answered |
| OQ-G | Library | Filter state — reset on cold start, or persist last-used filter? | already answered |
| OQ-H | Instrument SVG | You mentioned wanting SVG instrument icons. What is the source? Curated icon set bundled in app? User uploads SVG? This is unspecified. | since the app is for me, i will upload 3 svgs for the instruments i play |

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

## Founder vision

i need to clarify a bit on instruments
its like i play the mandolin, banjo, melodica
when i add an instrument, i can add one of these (or specify the instrument). lets maintain that as instruments (like instrument class)
then when i add one, i can add it like, hey i want to add a mandolin (instrument instance). its of the brand washburn and model m1sdlb and color is black and cost me 20K inr. think of how i can enter, edit and store this information
the svg that we are talking about is the svg of the instrument class and not the instance