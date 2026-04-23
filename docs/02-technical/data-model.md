---
title: Swaralipi — Data Model
version: 0.1.0
status: draft
owner: architect
date: 2026-04-23
---

# Swaralipi — Data Model

## Table of Contents

1. [Entity-Relationship Diagram](#1-entity-relationship-diagram)
2. [Schema Definition](#2-schema-definition)
   1. [notations](#21-notations)
   2. [notation_pages](#22-notation_pages)
   3. [tags](#23-tags)
   4. [notation_tags](#24-notation_tags)
   5. [instrument_classes](#25-instrument_classes)
   6. [instrument_instances](#26-instrument_instances)
   7. [notation_instruments](#27-notation_instruments)
   8. [custom_field_definitions](#28-custom_field_definitions)
   9. [notation_custom_fields](#29-notation_custom_fields)
   10. [user_preferences](#210-user_preferences)
   11. [FTS5 Virtual Table](#211-fts5-virtual-table)
3. [Normalization](#3-normalization)
4. [Indexes](#4-indexes)
5. [Constraints & Invariants](#5-constraints--invariants)
6. [Soft-Delete Policy](#6-soft-delete-policy)
7. [Migration Strategy](#7-migration-strategy)
8. [Query Patterns](#8-query-patterns)
9. [RenderParams Schema](#9-renderparams-schema)

---

## 1. Entity-Relationship Diagram

```
┌─────────────┐       ┌──────────────────┐
│  notations  │──1:N──│  notation_pages  │
│             │       └──────────────────┘
│             │──M:N──┤ notation_tags ├──M:N──┤ tags │
│             │       └───────────────┘       └──────┘
│             │──M:N──┤ notation_instruments ├──M:N──┤ instrument_instances │
│             │                                       └──────────────────────┘
│             │──1:N──┤ notation_custom_fields ├──N:1──┤ custom_field_definitions │
└─────────────┘       └────────────────────────┘       └──────────────────────────┘

┌─────────────────────┐──N:1──┤ instrument_classes │
│ instrument_instances│       └────────────────────┘
└─────────────────────┘

┌──────────────────┐   (singleton row, id = 1)
│ user_preferences │
└──────────────────┘
```

**Cardinality summary:**

| Relationship | Type |
|---|---|
| Notation → NotationPage | 1:N (ordered by page_order) |
| Notation ↔ Tag | M:N via `notation_tags` |
| Notation ↔ InstrumentInstance | M:N via `notation_instruments` |
| Notation → CustomFieldValue | 1:N via `notation_custom_fields` |
| InstrumentInstance → InstrumentClass | N:1 |

---

## 2. Schema Definition

### 2.1 `notations`

```sql
CREATE TABLE notations (
  id               TEXT PRIMARY KEY,          -- UUIDv4
  title            TEXT NOT NULL,
  artists          TEXT NOT NULL DEFAULT '[]', -- JSON array of strings
  date_written     TEXT,                       -- ISO 8601 date (YYYY-MM-DD); nullable
  time_sig         TEXT,                       -- e.g. '4/4', '6/8'; nullable
  key_sig          TEXT,                       -- e.g. 'C', 'Bb minor'; nullable
  languages        TEXT NOT NULL DEFAULT '[]', -- JSON array of strings
  notes            TEXT NOT NULL DEFAULT '',
  play_count       INTEGER NOT NULL DEFAULT 0,
  last_played_at   TEXT,                       -- ISO 8601 datetime; nullable
  created_at       TEXT NOT NULL,              -- ISO 8601 datetime
  updated_at       TEXT NOT NULL,              -- ISO 8601 datetime
  deleted_at       TEXT                        -- NULL = active; set = soft-deleted
);
```

**Notes:**
- `id`: UUIDv4 generated at app layer (not DB auto-increment). Sync-friendly; stable across schema migrations.
- `artists`, `languages`: JSON arrays stored as TEXT. SQLite has no native array type; queried via `json_each()` or loaded into Dart.
- `deleted_at`: soft-delete timestamp. All repository queries default-filter `WHERE deleted_at IS NULL`.

---

### 2.2 `notation_pages`

```sql
CREATE TABLE notation_pages (
  id               TEXT PRIMARY KEY,          -- UUIDv4
  notation_id      TEXT NOT NULL
                     REFERENCES notations(id) ON DELETE CASCADE,
  page_order       INTEGER NOT NULL,          -- 0-indexed; unique per notation
  image_path       TEXT NOT NULL,             -- relative path from appDocDir
  render_params    TEXT NOT NULL DEFAULT '{}', -- JSON: RenderParams (see §9)
  created_at       TEXT NOT NULL,
  UNIQUE (notation_id, page_order)
);
```

**Notes:**
- `ON DELETE CASCADE`: if a notation is hard-deleted (trash purge), pages cascade.
- `render_params`: serialized `RenderParams` — filter, crop rect, rotation, auto-straighten. Non-destructive; original at `image_path` never mutated.
- `image_path`: relative to `getApplicationDocumentsDirectory()`, e.g. `notations/<notation_id>/page_<id>_original.jpg`.

---

### 2.3 `tags`

```sql
CREATE TABLE tags (
  id         TEXT PRIMARY KEY,   -- UUIDv4
  name       TEXT NOT NULL UNIQUE,
  color_hex  TEXT NOT NULL,      -- Catppuccin hex, e.g. '#f38ba8'
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);
```

**Notes:**
- Seed data: 5 default tags inserted at DB initialization (migration v1).
- `color_hex`: validated at app layer to be a valid Catppuccin color.

---

### 2.4 `notation_tags`

```sql
CREATE TABLE notation_tags (
  notation_id TEXT NOT NULL REFERENCES notations(id) ON DELETE CASCADE,
  tag_id      TEXT NOT NULL REFERENCES tags(id) ON DELETE CASCADE,
  PRIMARY KEY (notation_id, tag_id)
);
```

**Notes:**
- `ON DELETE CASCADE` on `tag_id`: deleting a tag silently removes it from all notations (D-35). No block, no confirmation beyond the tag-delete confirmation itself.
- `ON DELETE CASCADE` on `notation_id`: soft-deleted notations retain tag rows; purge cascades.

---

### 2.5 `instrument_classes`

```sql
CREATE TABLE instrument_classes (
  id         TEXT PRIMARY KEY,   -- UUIDv4
  name       TEXT NOT NULL UNIQUE,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);
```

**Notes:**
- No `svg_path` in v1 (D-32).

---

### 2.6 `instrument_instances`

```sql
CREATE TABLE instrument_instances (
  id         TEXT PRIMARY KEY,   -- UUIDv4
  class_id   TEXT NOT NULL REFERENCES instrument_classes(id) ON DELETE RESTRICT,
  brand      TEXT,               -- nullable
  model      TEXT,               -- nullable
  color_hex  TEXT NOT NULL,      -- Catppuccin hex (D-31)
  price_inr  INTEGER,            -- INR integer; nullable (D-22)
  photo_path TEXT,               -- relative path; nullable
  notes      TEXT NOT NULL DEFAULT '',
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  deleted_at TEXT                -- NULL = active; set = archived (D-34)
);
```

**Notes:**
- Soft-delete (`deleted_at`) = archive. Archived instances remain visible on existing notations (D-34).
- `ON DELETE RESTRICT` on `class_id`: cannot delete a class while instances exist.

---

### 2.7 `notation_instruments`

```sql
CREATE TABLE notation_instruments (
  notation_id  TEXT NOT NULL REFERENCES notations(id) ON DELETE CASCADE,
  instance_id  TEXT NOT NULL REFERENCES instrument_instances(id) ON DELETE RESTRICT,
  PRIMARY KEY (notation_id, instance_id)
);
```

**Notes:**
- `ON DELETE RESTRICT` on `instance_id`: archived instances are not deleted, so this constraint is rarely triggered.
- AQ-02 (instrument reference integrity on notation delete) resolved here: `CASCADE` on notation side, `RESTRICT` on instrument side. Soft-delete of notation retains the join row; physical purge cascades.

---

### 2.8 `custom_field_definitions`

```sql
CREATE TABLE custom_field_definitions (
  id         TEXT PRIMARY KEY,   -- UUIDv4
  key_name   TEXT NOT NULL UNIQUE,
  field_type TEXT NOT NULL       -- CHECK constraint below
               CHECK (field_type IN ('text', 'number', 'date', 'boolean')),
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);
```

---

### 2.9 `notation_custom_fields`

```sql
CREATE TABLE notation_custom_fields (
  notation_id    TEXT NOT NULL REFERENCES notations(id) ON DELETE CASCADE,
  definition_id  TEXT NOT NULL REFERENCES custom_field_definitions(id) ON DELETE CASCADE,
  value_text     TEXT,    -- used when field_type = 'text'
  value_number   REAL,    -- used when field_type = 'number'
  value_date     TEXT,    -- ISO 8601 date; used when field_type = 'date'
  value_boolean  INTEGER, -- 0 or 1; used when field_type = 'boolean'
  PRIMARY KEY (notation_id, definition_id)
);
```

**Notes:**
- `ON DELETE CASCADE` on both FKs: deleting a notation or a definition removes values.
- Sparse column design: only the column matching `field_type` is populated; others are NULL.
- App layer enforces type-column alignment.

---

### 2.10 `user_preferences`

```sql
CREATE TABLE user_preferences (
  id                INTEGER PRIMARY KEY CHECK (id = 1), -- singleton
  user_name         TEXT NOT NULL DEFAULT 'Musician',
  theme_mode        TEXT NOT NULL DEFAULT 'system'
                      CHECK (theme_mode IN ('light', 'dark', 'system')),
  color_scheme_mode TEXT NOT NULL DEFAULT 'catppuccin'
                      CHECK (color_scheme_mode IN ('catppuccin', 'monet')),
  seed_color        TEXT,                               -- hex; used only when color_scheme_mode = 'custom' (v2)
  default_sort      TEXT NOT NULL DEFAULT 'updated_at_desc'
                      CHECK (default_sort IN (
                        'updated_at_desc', 'updated_at_asc',
                        'title_asc', 'title_desc',
                        'play_count_desc', 'last_played_at_desc'
                      )),
  default_view      TEXT NOT NULL DEFAULT 'list'
                      CHECK (default_view IN ('list'))  -- grid deferred to v2 (D-25)
);
```

**Notes:**
- `CHECK (id = 1)` enforces singleton at DB level.
- Inserted with default values at DB initialization (migration v1).

---

### 2.11 FTS5 Virtual Table

```sql
CREATE VIRTUAL TABLE notations_fts USING fts5(
  title,
  artists,
  notes,
  content='notations',
  content_rowid='rowid',
  tokenize='unicode61'
);

-- Triggers to keep FTS in sync
CREATE TRIGGER notations_ai AFTER INSERT ON notations BEGIN
  INSERT INTO notations_fts(rowid, title, artists, notes)
  VALUES (new.rowid, new.title, new.artists, new.notes);
END;

CREATE TRIGGER notations_ad AFTER DELETE ON notations BEGIN
  INSERT INTO notations_fts(notations_fts, rowid, title, artists, notes)
  VALUES ('delete', old.rowid, old.title, old.artists, old.notes);
END;

CREATE TRIGGER notations_au AFTER UPDATE ON notations BEGIN
  INSERT INTO notations_fts(notations_fts, rowid, title, artists, notes)
  VALUES ('delete', old.rowid, old.title, old.artists, old.notes);
  INSERT INTO notations_fts(rowid, title, artists, notes)
  VALUES (new.rowid, new.title, new.artists, new.notes);
END;
```

**Notes:**
- `unicode61` tokenizer: handles Unicode correctly for Hindi/Bengali text (AQ-04 resolved: unicode61 is sufficient for v1).
- Content table + triggers: FTS index stays in sync automatically; no app-layer sync needed.
- Soft-deleted notations remain in FTS index but are filtered out by `WHERE deleted_at IS NULL` in the main query join.

---

## 3. Normalization

**Target form:** 3NF throughout.

| Decision | Justification |
|---|---|
| `artists` and `languages` as JSON arrays in `notations` | Not normalized (1NF violation); accepted. Small bounded arrays, never queried by individual element in SQL — filtered in Dart after FTS. Avoids two extra junction tables for v1. |
| Custom field values as sparse columns | Avoids EAV anti-pattern's type unsafety while keeping schema flexible. Field count expected to be small (< 20). |
| No denormalization | Read patterns don't require it; Drift reactive streams handle incremental updates. |

---

## 4. Indexes

```sql
-- Hot query: library list (non-deleted, sorted)
CREATE INDEX idx_notations_active_updated
  ON notations (deleted_at, updated_at DESC)
  WHERE deleted_at IS NULL;

-- Hot query: recently played carousel
CREATE INDEX idx_notations_last_played
  ON notations (deleted_at, last_played_at DESC)
  WHERE deleted_at IS NULL AND last_played_at IS NOT NULL;

-- Hot query: trash screen (soft-deleted, sorted by deletion date)
CREATE INDEX idx_notations_deleted
  ON notations (deleted_at DESC)
  WHERE deleted_at IS NOT NULL;

-- Join performance: pages for a notation
CREATE INDEX idx_pages_notation_order
  ON notation_pages (notation_id, page_order ASC);

-- Join performance: tags for a notation
CREATE INDEX idx_notation_tags_notation
  ON notation_tags (notation_id);

-- Join performance: instruments for a notation
CREATE INDEX idx_notation_instruments_notation
  ON notation_instruments (notation_id);

-- Instrument instances by class
CREATE INDEX idx_instances_class
  ON instrument_instances (class_id, deleted_at);

-- Custom field values by notation
CREATE INDEX idx_custom_fields_notation
  ON notation_custom_fields (notation_id);
```

**Notes:**
- Partial indexes (`WHERE deleted_at IS NULL`) keep active-record queries fast; SQLite supports partial indexes.
- FTS5 index is maintained by triggers (§2.11).

---

## 5. Constraints & Invariants

| Invariant | Enforced At |
|---|---|
| Notation must have a title | DB: `NOT NULL` on `title` |
| `page_order` unique per notation | DB: `UNIQUE (notation_id, page_order)` |
| `user_preferences` is singleton | DB: `CHECK (id = 1)` |
| `custom_field_definitions.field_type` is an enum | DB: `CHECK` constraint |
| `user_preferences.theme_mode` is an enum | DB: `CHECK` constraint |
| `user_preferences.default_sort` is an enum | DB: `CHECK` constraint |
| Tag color is a valid Catppuccin hex | App layer (DAO receives validated model) |
| Instrument color is a valid Catppuccin hex | App layer |
| `notation_custom_fields` value column matches `field_type` | App layer |
| Soft-deleted notations excluded from library queries | Repository layer (default filter) |
| Soft-deleted instruments excluded from picker | Repository layer |
| Play count increments only on Play button press | App layer (ViewModel) |

---

## 6. Soft-Delete Policy

| Entity | Soft-Delete | Hard-Delete Trigger | Files on Purge |
|---|---|---|---|
| `notations` | `deleted_at = now()` | Manual "Empty Trash" or 30-day auto-purge | All `notation_pages.image_path` files deleted |
| `notation_pages` | Never individually; follows notation | Cascade from notation hard-delete | Image file deleted |
| `instrument_instances` | `deleted_at = now()` (archive) | Never hard-deleted in v1 (D-34) | Photo file retained |
| `tags` | Not soft-deleted | Hard delete; cascades from all notations (D-35) | N/A |
| `instrument_classes` | Not soft-deleted | Hard delete; blocked if instances exist (RESTRICT) | N/A |

**30-day auto-purge:** Implemented at app startup — query `WHERE deleted_at < now() - 30 days`, run hard-delete + file cleanup as background task.

---

## 7. Migration Strategy

**Tool:** Drift's built-in `MigrationStrategy`.

**Versioning:**

| Schema Version | Change |
|---|---|
| 1 | Initial schema: all tables, FTS5, triggers, indexes, seed data |
| 2+ | Additive only in v1 dev cycle |

**Rules:**
- Every schema change = new version number + migration function in `migrations/`
- Migrations run `onCreate` (fresh install) and `onUpgrade` (existing install)
- `onUpgrade` applies sequential migration functions from `from` to `to`
- No destructive migrations (no DROP TABLE, no DROP COLUMN) without a data-safe alternative
- Backward-compatibility: v1 is single-user, single-device — no rollback requirement

**Seed data (migration v1):**

```
tags: ['Sargam', 'Bandish', 'Bhajan', 'Ghazal', 'Folk']
  with Catppuccin Mocha accent colors
user_preferences: insert with all defaults (id = 1)
```

---

## 8. Query Patterns

### 8.1 Library List (default)

```sql
SELECT n.*, COUNT(np.id) AS page_count
FROM notations n
LEFT JOIN notation_pages np ON np.notation_id = n.id
WHERE n.deleted_at IS NULL
GROUP BY n.id
ORDER BY n.updated_at DESC
LIMIT 50 OFFSET :offset;
```

### 8.2 FTS Search

```sql
SELECT n.*
FROM notations n
JOIN notations_fts fts ON fts.rowid = n.rowid
WHERE notations_fts MATCH :query
  AND n.deleted_at IS NULL
ORDER BY rank;
```

Post-FTS, apply Dart-side filters: tags (set intersection), languages (set intersection), date range, time_sig, key_sig.

### 8.3 Recently Played Carousel

```sql
SELECT * FROM notations
WHERE deleted_at IS NULL
  AND last_played_at IS NOT NULL
ORDER BY last_played_at DESC
LIMIT 10;
```

### 8.4 Trash Screen

```sql
SELECT * FROM notations
WHERE deleted_at IS NOT NULL
ORDER BY deleted_at DESC;
```

### 8.5 Auto-Purge (startup task)

```sql
SELECT id FROM notations
WHERE deleted_at IS NOT NULL
  AND deleted_at < :cutoff;
-- Then: hard DELETE + file cleanup per id
```

### 8.6 Pages for Player

```sql
SELECT * FROM notation_pages
WHERE notation_id = :id
ORDER BY page_order ASC;
```

---

## 9. RenderParams Schema

Stored as JSON in `notation_pages.render_params`.

```json
{
  "filter": "original | bw | grayscale | enhanced | warm | cool",
  "rotation_degrees": 0,
  "auto_straighten": false,
  "crop": {
    "left": 0.0,
    "top": 0.0,
    "right": 1.0,
    "bottom": 1.0
  }
}
```

**Notes:**
- `crop` values are normalized (0.0-1.0 fractions of original dimensions). Device-resolution-independent.
- `rotation_degrees`: one of `0 | 90 | 180 | 270`.
- Default (`{}`): treated as `filter=original, rotation=0, auto_straighten=false, crop=full`.
- Deserialized into `RenderParams` Dart class (json_serializable); never constructed from raw JSON at display time.
