# Data Model

Ported from the prior SQLite schema (10 tables + an FTS5 virtual table) to
Dexie (IndexedDB). Three changes: UUID keys stay, JSON array columns become
native arrays with multi-entry indexes, and FTS5 becomes Fuse.js.

## 1. Dexie schema

```ts
// src/db/db.ts
export class SwaralipiDB extends Dexie {
  notations!: Table<Notation, string>;
  notationPages!: Table<NotationPage, string>;
  tags!: Table<Tag, string>;
  instrumentClasses!: Table<InstrumentClass, string>;
  instrumentInstances!: Table<InstrumentInstance, string>;
  customFieldDefs!: Table<CustomFieldDefinition, string>;
  blobs!: Table<StoredBlob, string>;
  preferences!: Table<UserPreferences, number>;

  constructor() {
    super('swaralipi');
    this.version(1).stores({
      notations:
        'id, title, dateWritten, createdAt, updatedAt, deletedAt, ' +
        'playCount, lastPlayedAt, *tagIds, *artists, *languages',
      notationPages: 'id, notationId, [notationId+pageOrder]',
      tags: 'id, &name',
      instrumentClasses: 'id, &name',
      instrumentInstances: 'id, classId, deletedAt',
      customFieldDefs: 'id, &keyName',
      blobs: 'path',
      preferences: 'id',
    });
  }
}
```

## 2. Entities

| Table | Key fields |
| --- | --- |
| `notations` | `id`, `title`, `artists[]`, `dateWritten`, `timeSig`, `keySig`, `languages[]`, `notes`, `tagIds[]`, `instrumentInstanceIds[]`, `customFields`, `playCount`, `lastPlayedAt`, `createdAt`, `updatedAt`, `deletedAt` |
| `notationPages` | `id`, `notationId`, `pageOrder`, `blobPath`, `renderParams`, `createdAt` |
| `tags` | `id`, `name` (unique), `colorHex`, timestamps |
| `instrumentClasses` | `id`, `name` (unique), timestamps |
| `instrumentInstances` | `id`, `classId`, `brand`, `model`, `colorHex`, `priceInr`, `photoBlobPath`, `notes`, timestamps, `deletedAt` (archive) |
| `customFieldDefs` | `id`, `keyName` (unique), `fieldType` (`text` \| `number` \| `date` \| `boolean`), timestamps |
| `blobs` | `path` (key), `blob` |
| `preferences` | singleton row, `userName`, `themeMode`, `colorSchemeMode`, `seedColor` (Catppuccin swatch name, resolved to a light/dark hex pair by `swatchSeeds()`), `defaultSort`, `defaultView` |

`userName` carries no schema-level constraint — it is validated at the UI
boundary by `src/features/settings/nameField.ts` (one word, letters only in
any script, empty allowed) before `updatePreferences()` is ever called. An
empty string is a valid, intentional value: the Library greeting
(`src/lib/greeting.ts`) renders it as a plain `"Hi"` rather than `"Hi, "`.

## 3. Changes from the SQLite schema

| Prior | Now | Why |
| --- | --- | --- |
| `notation_tags` join table | `notations.tagIds: string[]`, `*tagIds` index | IndexedDB multi-entry index. One table fewer |
| `notation_instruments` join table | `notations.instrumentInstanceIds: string[]` | Same. Unlike `tagIds`/`artists`/`languages`, the `version(1).stores()` schema string has no `*instrumentInstanceIds` — not multi-entry indexed, since nothing queries by it yet |
| `notation_custom_fields` sparse columns | `notations.customFields: Record<string, CustomFieldValue>` | No SQL type columns to align |
| `artists` / `languages` JSON TEXT | Native `string[]`, `*` indexed | IndexedDB stores structured data |
| `notations_fts` + 3 triggers | Fuse.js over the loaded list | Dexie has no FTS. Dataset is one user's library |
| `image_path` on disk | `blobs.path` -> `Blob` in Dexie | No filesystem in a browser |
| `ON DELETE CASCADE` | Explicit cascade in the repository | IndexedDB has no foreign keys |
| `CHECK` constraints | TypeScript union types | Enforced at the app layer |

Preserved as-is: UUID primary keys, `deletedAt` soft-delete on `notations` and
`instrumentInstances`, the `RenderParams` shape, the singleton preferences
row, and the 30-day trash auto-purge.

## 4. Cascade rules, now in code

`ON DELETE CASCADE` / `RESTRICT` were database guarantees. They are now
repository functions run inside a Dexie transaction.

| Action | Behavior | Where |
| --- | --- | --- |
| Purge notation | Delete its pages, then their blobs, then the notation | `purgeNotation` |
| Delete tag | Remove its id from every `notations.tagIds` | `untagAllNotations` |
| Delete instrument class | Blocked while instances reference it (was `RESTRICT`) | not yet built |
| Archive instrument instance | Set `deletedAt`. Stays visible on notations | not yet built |
| Delete custom field definition | Remove its key from every `notations.customFields` | not yet built |

## 5. RenderParams

Non-destructive image editing. The original blob at `blobPath` is never
mutated; `RenderParams` applies at display time via `src/lib/render.ts`
(canvas I/O) over pure math in `src/lib/renderGeometry.ts`. See
`docs/modules/capture.md` for the full capture flow this feeds.

```ts
interface RenderParams {
  crop: { left: number; top: number; right: number; bottom: number }; // normalized 0-1, ORIGINAL image space
  rotationDegrees: 0 | 90 | 180 | 270;
  pageSize: 'a3' | 'a4' | 'a5' | 'a6' | null; // null = no page fitting
}
```

Default (`crop: full`, `rotationDegrees: 0`, `pageSize: null`) is the
un-edited state.

Earlier drafts of this schema carried `filter` (6 presets) and
`autoStraighten` fields inherited from the prior SQLite schema — both were
dropped rather than deferred; neither is implemented anywhere in the app.

Pipeline order is **crop -> rotate -> fit-into-page**, and that order is
deliberate: `crop` is always expressed in the *original* image's coordinate
space, so a crop survives a later rotation change unaffected (the crop editor
maps it through `rotateCropRect`/`unrotateCropRect` to match what's actually
displayed). `pageSize` is declarative rather than an accumulated transform,
so switching A4 -> A5 -> A4 re-derives from the original both times instead
of compounding.

`pageSize` fits the cropped-and-rotated image into a fixed portrait pixel
box, aspect preserved, with white padding filling the remainder — a printed
page is white in both light and dark mode, so the fill is hardcoded rather
than themed. Presets are fixed-orientation; a landscape image inside a
portrait preset gets heavy padding top and bottom — rotating first, if
needed, is on the person capturing, not something the pipeline infers.

```
ISO_PAGE_PX (150dpi, portrait) — src/lib/renderGeometry.ts
  a3: 1754x2480    a4: 1240x1754    a5: 874x1240    a6: 620x874
```

These are sized so a 2400px-long-edge import (see the import-normalization
note below) is never upscaled by any preset.

### 5.1 Import normalization

A freshly-picked file is never stored as-is: `src/features/capture/importImages.ts`
decodes it, downscales so its longest edge is at most 2400px (never
upscales), and re-encodes as JPEG at quality 0.85, before it ever enters the
capture draft. A phone camera's 10-20MB original becomes roughly a few
hundred KB per page. This happens once, at import — it is separate from the
`RenderParams` pipeline, which never touches the stored blob.
