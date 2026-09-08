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

## 3. Changes from the SQLite schema

| Prior | Now | Why |
| --- | --- | --- |
| `notation_tags` join table | `notations.tagIds: string[]`, `*tagIds` index | IndexedDB multi-entry index. One table fewer |
| `notation_instruments` join table | `notations.instrumentInstanceIds: string[]`, indexed | Same |
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
mutated; `RenderParams` applies at display time via `src/lib/render.ts`.

```ts
interface RenderParams {
  filter: 'original' | 'bw' | 'grayscale' | 'enhanced' | 'warm' | 'cool';
  rotationDegrees: 0 | 90 | 180 | 270;
  autoStraighten: boolean;
  crop: { left: number; top: number; right: number; bottom: number }; // normalized 0-1
}
```

Default (`filter: 'original', rotationDegrees: 0, autoStraighten: false, crop: full`)
is the un-edited state.
