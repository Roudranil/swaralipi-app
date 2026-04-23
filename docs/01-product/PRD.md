# Swaralipi — Product Requirements Document

> **Status:** Draft v0.1  
> **Date:** 2026-04-23  
> **Author:** Roudranil (via PM session)

## 1. Overview

Single-user Android app. Musician. Hand-written sargam + sheet music. Digitize it. Find it. Play it.

No accounts. No cloud. No multi-tenancy. Everything on-device.

---

## 2. Goals

- Capture notation pages from camera or gallery
- Clean, order, and crop pages before saving
- Attach rich metadata to each notation
- Find notations fast (search, sort, filter)
- View notation full-screen while playing
- Track instruments, practice sessions, and play counts
- Look great. Feel premium.

---

## 3. Non-Goals

- No cloud sync
- No sharing / export (for now — see open questions)
- No multi-user
- No audio recording or playback
- No OCR / notation recognition

---

## 4. Users

One. You. Musician. Samsung Galaxy S25.

---

## 5. Feature Areas

---

### 5.1 Notation Capture

**What:** Bring pages into the app.

- Tap "Add Notation" → choose: **Camera** or **Gallery**
- Camera: in-app camera capture, multi-shot (capture multiple pages in one session)
- Gallery: multi-select from device gallery
- Both flows land in the **Page Editor** before save

**Page Editor (pre-save pipeline):**

| Step | What happens |
|---|---|
| Order | Drag-and-drop to reorder pages |
| Crop & Align | Per-page crop with corner handles + auto-straighten (like Adobe Scan) |
| Filter | Per-page or apply-to-all filter picker |
| Review | Thumbnail strip, tap to re-edit any page |

**Filters available:**

- Original (no filter)
- B&W (high contrast)
- Grayscale
- Enhanced (auto-contrast + brightness boost)
- Warm / Cool tint

After page editor → **Metadata Form** → Save.

---

### 5.2 Metadata

Every notation has:

| Field | Type | Notes |
|---|---|---|
| Title | Text (required) | |
| Artist(s) | Multi-text | Comma-separated or chip input |
| Date Written | Date picker | Defaults to today |
| Time Signature | Text / picker | e.g. 4/4, 6/8, free |
| Key Signature | Text / picker | e.g. C major, Yaman, Bhairavi |
| Language | Single-select | Hindi, Bengali, English, Sanskrit, Other |
| Tags | Multi-select + custom | `practice`, `raag`, `song`, `classical`, `piece` — user can add own |
| Instruments | Multi-select | From user's instrument list (see §5.5) |
| Personal Notes | Long text | Free-form |
| Custom Fields | Key-value pairs | User-defined; added in Settings |
| Created At | Auto | System timestamp |
| Updated At | Auto | System timestamp |

---

### 5.3 Library (Home Screen)

**Default view:** Grid of notation cards. Each card shows:

- Thumbnail of first page
- Title
- Artist(s)
- Tags (chips, truncated)
- Play-count badge

**Alternate view:** List (toggle in top bar).

#### Search

- Search bar always visible at top
- Fuzzy match on: title, artist, notes, tags, custom field values
- Exact match mode toggle (icon in search bar)
- Search highlights matched field in result

#### Sort

Sort by:
- Title (A–Z / Z–A)
- Date written (newest / oldest)
- Date added (newest / oldest)
- Play count (most / least)
- Last played

#### Filter

**Simple filter:** Tag chips above the list — tap to toggle.

**Advanced filter drawer:** Slide up from bottom.

- Filter by: tag(s), instrument(s), language, key signature, time signature, date range (written), date range (added), play count range, custom fields
- Conditions: AND / OR toggle
- Save filter as a named preset

---

### 5.4 Notation Viewer

Open a notation → full-screen image viewer.

- Pinch-to-zoom, pan
- Swipe left/right to move between pages
- Page indicator (1 / 3)
- Auto-scroll mode:
  - Tap auto-scroll button → speed slider appears
  - Scroll speed: slow / medium / fast (or manual px/sec)
  - Pause / resume with tap anywhere
- Portrait and landscape both work; image fills screen
- Toolbar fades after 2s of inactivity; tap to bring back
- Toolbar actions: Edit metadata, Share page (image), Delete, Play count +1 (manual increment)

**Play count:** Auto-increments by 1 each time viewer is opened. Manual +1 also available.

---

### 5.5 Instrument Tracker

**What:** Log which instruments you play. Notations can be tagged per-instrument.

Each instrument entry:

| Field | Type |
|---|---|
| Name | Text (required) |
| Photo | Camera or gallery (IRL photo or artwork) |
| Notes | Free text |

- Add / edit / delete instruments from Settings > My Instruments
- Shown as chips in notation metadata form (Instruments field)
- Shown as filter option in library

---

### 5.6 Practice Calendar

**What:** Log practice sessions. See them on a calendar.

- Calendar view: monthly, with dots on days that have logs
- Tap a day → see sessions logged that day
- Log a session:
  - Date (default today)
  - Duration (minutes)
  - Notations practiced (multi-select from library)
  - Instruments used (multi-select)
  - Free notes
- Stats visible from calendar screen:
  - Days practiced this month
  - Total minutes this month
  - Streak (consecutive days)

---

### 5.7 Stats

Dedicated Stats screen (tab or drawer item).

| Stat | Description |
|---|---|
| Total notations | Count |
| Most played | Top 5 notations by play count |
| Recently added | Last 5 |
| Practice streak | Consecutive days with a session |
| Sessions this month | Count + total minutes |
| By tag | Bar chart: notation count per tag |
| By instrument | Count of notations per instrument |
| Play count over time | Line chart: total plays per week/month |

Charts: use a lightweight Flutter charting lib (fl_chart or similar).

---

### 5.8 Edit, Delete, Copy

From notation detail or long-press in library:

- **Edit:** Re-open metadata form pre-filled. Pages also editable (re-order, re-crop, add pages, delete pages).
- **Delete:** Confirmation dialog. Soft delete → permanent after 30 days (trash bin).
- **Copy / Duplicate:** Creates new notation with same metadata + pages. Title prefixed with "Copy of".

---

### 5.9 Appearance & Theming

#### Theme Mode

- Light / Dark / System (follows device)
- Toggle in Settings or quick-access from app bar

#### Color Scheme

Two modes:

1. **Dynamic** — pulled from Android 12+ wallpaper (Material You / monet)
2. **Seed color** — user picks from preset palette

**Preset palette:**

- Dark mode presets → **Catppuccin Mocha** colors
- Light mode presets → **Catppuccin Latte** colors

Swatches shown as a color picker row in Settings. User picks one; app regenerates `ColorScheme.fromSeed` from it.

---

### 5.10 Settings

| Setting | Type | Notes |
|---|---|---|
| Theme mode | Light / Dark / System | |
| Color scheme | Dynamic / Seed | If Seed: show palette picker |
| Default sort | Picker | Applied on library open |
| Default view | Grid / List | |
| Auto-scroll default speed | Slider | |
| Custom metadata fields | Manage list | Add / remove key-value fields |
| My Instruments | Link to instrument list | |
| Trash | View soft-deleted notations | Restore or permanent delete |
| About | App version, licenses | |

---

## 6. Navigation Structure

```
Bottom nav / Nav drawer:
├── Library (home)
├── Calendar
├── Stats
└── Settings

Library → Notation Detail (viewer)
Library → Add Notation (capture flow)
Settings → My Instruments
Settings → Trash
Settings → Custom Fields
```

Founder vision:
- bottom nav bar has below buttongs
  - library (home)
  - settings
  - (v2) stats
- library:
  - at the top, "Hi <name>"
  - carousel of 5 recently played notations
  - list of notations below
    - preview image on the left in a square
    - on right, title and artist name one below the other
    - tags
  - swipe a notation to the left to get 2 colored option badges on the same row - edit/delete
  - long press a notation to get a floating menu to get the same edit/delete option
  - a FAb to add a new notation
  - new notation
    - bottom sliding sheet opens to show from gallery or camera
    - if gallery, the current material 3 google approved gallery picker shows up
    - if camera, then open device default camera app, take photos, and then come back to the app
    - show a window (decide how) with the photos that were takes (my idea is that you log the time at which the camera was opened and then when the user returns to the app, show the photos taken between those times) and allow to select
    - once photos selected, open notation creation window
      - big carousel of preview, left to right
      - for each page - filter, crop, rotate, take another photo (same gallery or app shenanigan), delete photo, reorder. on top save, discard
      - on top - show notation details, click to expand. dont allow to save with fields as blank
        - contents are in the metadata section as given above
      - once all done save
  - edit notation also opens this exact same window
  - click notation to open notation details view
    - preview
    - the metadata (title, artist, date, language, key and time sig)
    - on top edit and delete icon buttons
    - below play
    - on play
      - open a new window, full screen just the notation, with zoom options, adjust to page width, height screen options
      - change orientation option
      - title on top
- settings
  - settings categories
    - appearance
    - tags
    - instruments
    - will think of other things in v2
  - show about
  - show open source licenses
- tags:
  - window with list of tags
  - allow to edit name and color
  - same style as list of notifications
- instruments
  - show a preview image on the left and the name on the right
  - optional metadata includes instrument name, brand, model, price, display color
  - image select from gallery only
  - probably need some way to get svg of the instruments to be able to use those as icons.
  - all fields are editable
- all colors are to be chosen from the same catppuccin color palette

---

## 7. Data Model (High-Level)

```
Notation
  id, title, artists[], date_written, time_sig, key_sig,
  language, tags[], instrument_ids[], notes,
  custom_fields{}, play_count, last_played_at,
  created_at, updated_at, deleted_at

NotationPage
  id, notation_id, page_order, image_path,
  filter_applied, crop_rect, created_at

Instrument
  id, name, photo_path, notes, created_at

PracticeSession
  id, date, duration_minutes, notation_ids[],
  instrument_ids[], notes, created_at

CustomField
  id, key_name, field_type (text/number/date)
```

---

## 8. Non-Functional Requirements

| Requirement | Target |
|---|---|
| Cold start | < 2s |
| Library load (100 notations) | < 500ms |
| Image display in viewer | < 300ms per page |
| Search response | < 200ms |
| Local storage | All images stored in app-private dir |
| Offline | 100% offline — zero network calls |
| Accessibility | TalkBack support; 4.5:1 contrast |
| Orientation | Portrait + Landscape throughout |

---

## 9. Open Questions

> These surface decisions that need your input before or during architecture phase.

| ID | Area | Question | Answers |
|---|---|---|---|
| OQ-01 | Capture | Multi-page camera: continuous capture (tap shutter for each page) or burst mode? | the way that i am thinking is, i want to click on + create notation, then popup - open camera or from gallery. if gallery, default gallery picker for material 3, pick and move on. else if camera open the device camera app and let the photos be taken. if i come back (that is press back on the camera) i come back to the app and then there is a window that hey you clicked these photos after opening the app, select the ones that you want |
| OQ-02 | Capture | After re-opening a notation for edit, can you add NEW pages to it, or only edit existing? | yep all the same changes that can be done when creating the notation |
| OQ-03 | Filters | Should filters be destructive (baked into saved image) or non-destructive (applied at display time)? | apply at display time |
| OQ-04 | Crop | Auto-straighten: always on, off, or user toggle per page? | per page toggle |
| OQ-05 | Viewer | Auto-scroll: scroll direction always top-to-bottom within a page, then advance to next page? Or only manual page swipe? | remove auto scroll |
| OQ-06 | Play count | Should opening the viewer ALWAYS increment play count, or only after a minimum view duration? | okay so i click on a notation, it opens a details page - an image preview (or macos like stack of papers), with details below with a pencil and a trash icon on top and a play button at the bottom. play increments the counter. no tracking time played. |
| OQ-07 | Calendar | One practice session per day, or multiple sessions per day allowed? | multiple. it is log as needed or may be move the practice logging to v2 |
| OQ-08 | Calendar | Should notations practiced in a session show play count contribution? | i will think about this later in v2 |
| OQ-09 | Trash | 30-day soft delete — should there be a manual "empty trash" option too? | yeah soft delete and manual empty trash |
| OQ-10 | Copy | When duplicating a notation, are images hard-copied (two separate files) or shared references? | images are hard copied |
| OQ-11 | Custom fields | Custom field types: just text, or also number, date, boolean? | yes all of them |
| OQ-12 | Tags | Are the 5 default tags (`practice`, `raag`, `song`, `classical`, `piece`) fixed or just defaults user can rename/delete? | another settings option idea then. allow user to choose color and name for tags. allow free edits, deletes and creation for tags. add tag option to be shown on contextual menu for the notation view |
| OQ-13 | Language field | Single language per notation, or multi? (Some pieces mix Hindi + Sanskrit) | multiple languages allowed |
| OQ-14 | Export | Any future need to export notation (PDF, image zip)? Even if not now, shapes storage design. | future v2 idea |
| OQ-15 | Stats | Play count over time: should this be derived from a play-event log, or just current count snapshot? (Log = richer stats, but more storage) | lets think this in v2 |
| OQ-16 | Instruments | Any limit on number of instruments? | nope none |
| OQ-17 | Appearance | Dynamic color (monet) only works on Android 12+. Fallback for older Android? (Probably moot for S25 but good to decide.) | no fallback |
| OQ-18 | Search | Should search also match against personal notes and custom field values, or just title/artist/tags? | search, filter and sort should work against all metadata fields |
| OQ-19 | Notation | Is there a concept of "sets" or "collections" — grouping multiple notations together (e.g. a full raga set)? | yeah collections is a good idea. v2 |
| OQ-20 | Calendar | Should the calendar also show notation anniversaries or reminders, or just manual session logs? | lets think about this in v2 |

---

## 10. Decisions Log

| ID | Decision | Date |
|---|---|---|
| D-01 | No backend, no cloud, no auth — fully on-device | 2026-04-23 |
| D-02 | Flutter + Material 3 + ChangeNotifier MVVM | 2026-04-23 |
| D-03 | Catppuccin Mocha/Latte as seed color presets | 2026-04-23 |
| D-04 | Soft delete with 30-day retention | 2026-04-23 |
| D-05 | Play count auto-increments on viewer open | 2026-04-23 (provisional — see OQ-06) |
