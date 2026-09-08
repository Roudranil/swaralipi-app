# Capture Module

## 1. Purpose and scope

`src/features/capture/` is the whole notation-capture surface: the extended
FAB entry point (mounted from `LibraryScreen` and `NavRail`, not owned by
this module itself — see §3), the one out-of-shell `/capture` screen, and
everything that screen composes. It exists because the app has no other way
to create a `Notation` row.

`docs/ux-flows.md` §4 describes what the shipped screen looks like to a
user; this doc describes how it's built — the render pipeline, the draft
state, the tool-mode contract — so a future change (adding filters, a
metadata field, an edit-existing-notation mode) follows the same shape.

## 2. The render pipeline

Split into two modules on purpose: `src/lib/renderGeometry.ts` is pure
crop/rotate/fit math with no DOM access, unit-tested directly
(`renderGeometry.test.ts`); `src/lib/render.ts` is the canvas-touching
counterpart that decodes a blob and draws through that math.

```ts
// src/db/types.ts
interface RenderParams {
  crop: CropRect;              // normalized 0-1, ORIGINAL image space
  rotationDegrees: 0|90|180|270;
  pageSize: IsoPageSize | null; // null = no page fitting
}
```

**Pipeline order is crop -> rotate -> fit-into-page**, and that order is
load-bearing:

- `crop` is always expressed against the *original* image, never the
  rotated or page-fitted result. A crop survives a later rotation change
  unaffected — the crop editor (§4.1) maps it through
  `rotateCropRect`/`unrotateCropRect` to match what's actually on screen,
  but the stored rect itself never moves just because rotation changed.
- `pageSize` is declarative, not an accumulated transform. Switching
  A4 -> A5 -> A4 re-derives both times from the *original* crop/rotate
  result, so it never compounds the way repeatedly "resizing the last
  resize" would.

`renderToCanvas` fills white (`#FFFFFF`, hardcoded — a printed page is white
in both light and dark mode) before drawing whenever `pageSize` is set. ISO
presets are fixed pixel boxes at 150dpi (`ISO_PAGE_PX` in
`renderGeometry.ts`): A3 1754x2480, A4 1240x1754, A5 874x1240, A6 620x874 —
sized so a 2400px-long-edge import (§2.1) is never upscaled by any preset.
Presets are fixed-orientation; there is no auto-rotate-to-match, by design —
rotating a landscape source before applying a portrait preset is on the
person capturing.

### 2.1 Import normalization

`src/features/capture/importImages.ts` runs once, at import, before a file
ever enters the draft: decode, downscale so the long edge is at most 2400px
(`MAX_LONG_EDGE`, never upscales), re-encode JPEG at quality 0.85
(`JPEG_QUALITY`). This is separate from `RenderParams` — it never touches the
blob again after import, while `RenderParams` re-renders from that same
normalized blob on every edit.

## 3. The FAB entry point

`src/components/Fab.tsx` is a shared component, not owned by this module —
it's mounted from two places because the FAB's placement genuinely differs
by tier:

| Tier | Mount point | `extended` source |
| --- | --- | --- |
| Phone (`< 840px`) | `LibraryScreen`, `fixed` bottom-right | always `true` |
| Laptop (`>= 840px`) | `NavRail`, below its toggle row, above nav items | tied to the rail's own `expanded` |

Clicking it always just `navigate('/capture')` — no `FileList` is handed
across the route change. `CaptureScreen` opens the device file picker itself
on mount, only when the draft has no pages yet. This means there is exactly
one code path for "the FAB was clicked" and "Add more pages was tapped
mid-edit": both call the same hidden `<input type="file" multiple
accept="image/*">`'s `.click()`.

No Gallery/Camera chooser sheet: an M3 FAB menu is reserved for 2-6 actions
and is never paired with an extended FAB, and camera capture is out of scope
for this pass, so a single action gets the direct picker rather than a menu
with one item in it.

## 4. Draft state

`src/features/capture/draft.ts` — a `useReducer` reducer (no state library;
`useReducer` is core React, per `CLAUDE.md`). Pure: every action returns a
new object, tested directly in `draft.test.ts`. Nothing here touches Dexie —
Save (§5) is the only point that reads the finished draft.

```ts
interface CaptureDraft {
  title: string;
  artists: readonly string[];
  dateWritten: string | null;   // seeded to today
  timeSig: string | null;
  keySig: string | null;
  pages: readonly DraftPage[];
  activeIndex: number;
}
```

Fields captured here are deliberately a subset of `Notation`
(`src/db/types.ts`) — title plus musical basics (artists, date written,
time/key signature). Language, tags, instruments, personal notes, and
custom fields are **not** collected on this screen; editing them is a
separate future feature, and `notationPages.ts` (§5) writes their empty
defaults.

Two invariants worth knowing if you touch the reducer:

- `deleteActivePage` clamps `activeIndex` — deleting the last page would
  otherwise leave it pointing past the end of the array.
- `reorderPages` follows the moved page with `activeIndex` when it was the
  active one, so the preview doesn't visibly jump to a different page after
  a drag.

## 5. Tool modes

`src/features/capture/toolMode.ts`:

```ts
type ToolMode = 'none' | 'crop' | 'rotate' | 'resize' | 'delete';
```

Reorder and "Add more pages" are **not** `ToolMode`s — one opens
`ReorderSheet` as a full-screen overlay, the other opens the file picker
directly (§3). `ToolRow` renders both as ordinary buttons alongside the four
real modes.

A `ToolMode` other than `'none'` replaces `PageCarousel` with
`ToolActionRow`'s mode-specific action row, and **the mode persists across
the prev/next page arrows** — stepping to another page while in Crop mode
keeps Crop mode active there too.

| Mode | Action row | Notes |
| --- | --- | --- |
| `crop` | `No crop` / `Save cropped region` | `PagePreview` renders with `crop` forced full-frame and `pageSize` forced `null` (rotation still applied) so `CropOverlay` sits over the un-cropped, rotated image. Crop is committed live as the box is dragged, via `rotateCropRect`/`unrotateCropRect` — there's no separate "pending" crop state to reconcile. |
| `rotate` | `Rotate left` / `Rotate right` | Steps the draft's `rotationDegrees` by ±90, wrapping at 0/360. |
| `resize` | `Original` `A3` `A4` `A5` `A6` | Dispatches `setPageSize` directly — always replaces, never compounds (§2). |
| `delete` | `Keep this image` / `Delete this image` | Dispatches `deleteActivePage` and returns to `'none'`. |

`CropOverlay` (`src/features/capture/components/CropOverlay.tsx`) is Pointer
Events (`setPointerCapture`) for one code path across touch, mouse, and
stylus, with 4 corner + 4 edge handles plus whole-box move, and a
`MIN_CROP_FRACTION` floor so the box can't collapse to nothing. v1 is
rectangle-only, free aspect ratio.

`ReorderSheet` uses `@dnd-kit/core` + `@dnd-kit/sortable` for the drag grid
(2 columns phone, 4 laptop, `rectSortingStrategy`), with a `KeyboardSensor`
so reorder is reachable without a pointer.

## 6. Save

`src/db/repositories/notationPages.ts`:

```ts
function createNotationWithPages(draft: CaptureDraft): Promise<string>;
function pagesForNotation(notationId: string): Promise<NotationPage[]>;
```

One `db.transaction('rw', db.notations, db.notationPages, db.blobs, ...)` —
a mid-write failure (e.g. IndexedDB quota) leaves nothing behind rather than
an orphaned notation with no pages. Blob paths follow
`notationPagePath(notationId, pageId)` in `blobStore.ts` ->
`notations/<notationId>/pages/<pageId>.jpg`. `pageOrder` is 0-based and
dense, matching the draft's array index.

Fields the screen doesn't collect are written as their `Notation` empty
defaults: `languages: []`, `notes: ''`, `tagIds: []`,
`instrumentInstanceIds: []`, `customFields: {}`, `playCount: 0`,
`lastPlayedAt: null`, and **`deletedAt: null` explicitly** —
`activeNotations()` compares `=== null`, so an `undefined` here would hide
the row from the Library list.

Save is enabled only when the title is non-empty **and** at least one page
exists.

## 7. Accessibility contract

- The tool row is `role="toolbar"`; each tool button has `aria-pressed`
  reflecting whether its mode is active.
- The page carousel is `role="listbox"` / `role="option"` with
  `aria-selected`.
- The crop overlay's handles are `role="slider"` with a per-handle
  `aria-label` (e.g. "Crop handle: nw").
- `ReorderSheet`'s `KeyboardSensor` makes drag-to-reorder reachable without
  a pointer, per `CLAUDE.md`'s explicit call-out for capture flows.
- All icon-only buttons (`mdui-button-icon` for prev/next, discard, the
  metadata chevron) carry `aria-label`.
