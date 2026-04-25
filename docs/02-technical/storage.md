---
title: Swaralipi — Storage
version: 0.1.0
status: draft
owner: architect
date: 2026-04-23
---

# Swaralipi — Storage

## 1. Storage Layers

| Layer | Technology | Managed By | Contents |
|---|---|---|---|
| Relational DB | SQLite via Drift | `AppDatabase` + DAOs | All metadata, preferences, relations |
| File system | `dart:io` | `FileStorageService` | Original notation images, instrument photos |
| In-memory | Dart heap | ViewModels | Ephemeral UI state, decoded image bytes |

**Single source of truth:** SQLite for all structured data. File system for binary blobs only. File paths in DB are always relative to `appDocDir`.

---

## 2. SQLite Database

| Property | Value |
|---|---|
| Engine | SQLite 3.x (bundled via `sqlite3_flutter_libs`) |
| ORM | Drift 2.x |
| File name | `swaralipi.db` |
| Location | `getApplicationDocumentsDirectory()/swaralipi.db` |
| WAL mode | Enabled (Drift default) — concurrent reads during writes |
| Foreign keys | `PRAGMA foreign_keys = ON` — enforced at connection open |
| Journal mode | WAL (`PRAGMA journal_mode = WAL`) |

**WAL (Write-Ahead Logging):**
- Reads do not block writes; writes do not block reads
- Critical for Drift reactive streams (continuous reads while library loads)
- WAL checkpoint runs automatically

---

## 3. File Storage

### 3.1 Directory Layout

```
<appDocDir>/                          ← getApplicationDocumentsDirectory()
├── swaralipi.db                      ← SQLite database
├── swaralipi.db-wal                  ← WAL file (auto-managed)
├── swaralipi.db-shm                  ← WAL index (auto-managed)
├── notations/
│   ├── <notation_uuid>/
│   │   ├── page_<page_uuid>.jpg      ← original, never mutated
│   │   └── page_<page_uuid>.jpg      ← (additional pages)
│   └── <notation_uuid>/
│       └── ...
└── instruments/
    └── instance_<instance_uuid>.jpg  ← instrument photo; nullable
```

### 3.2 File Naming Convention

| File | Pattern | Example |
|---|---|---|
| Notation page | `page_<page_uuid>.jpg` | `page_3fa85f64.jpg` |
| Instrument photo | `instance_<instance_uuid>.jpg` | `instance_9b7e1c2a.jpg` |

**Always JPEG.** `image_picker` returns JPEG by default on Android. No PNG conversion to minimize storage footprint.

**Relative paths stored in DB:**
- `notation_pages.image_path` = `notations/<notation_id>/page_<page_id>.jpg`
- `instrument_instances.photo_path` = `instruments/instance_<instance_id>.jpg`

`FileStorageService` prepends `appDocDir` at runtime; paths in DB are portable.

### 3.3 Write Protocol

**Notation capture (new):**

```
1. Generate notation UUID + page UUIDs at app layer
2. MetadataFormScreen.save() calls CaptureViewModel.saveNotation()
3. CaptureViewModel calls FileStorageService.saveNotationPages(notationId, pageFiles)
   a. Create directory: <appDocDir>/notations/<notationId>/
   b. For each page: copy XFile bytes → page_<pageId>.jpg
   c. Return relative paths
4. CaptureViewModel calls NotationRepository.create(notation, pages)
   a. DB transaction:
      INSERT INTO notations ...
      INSERT INTO notation_pages ... (with paths from step 3c)
      INSERT INTO notation_tags ...
5. On DB error: FileStorageService.deleteNotationDirectory(notationId) [cleanup orphans]
```

**Atomicity:** File write happens before DB insert. If DB insert fails, files are cleaned up. If file write fails, DB insert never runs. No orphaned DB rows without files; orphaned files (from crash after file write but before DB insert) are cleaned up at startup via reconciliation (see §5).

### 3.4 Delete Protocol

**Soft delete (move to Trash):**
- `deleted_at` set in DB
- Files **retained** — user may restore

**Hard delete (Trash purge or 30-day auto-purge):**

```
1. Query notation_pages WHERE notation_id = :id → collect image_paths
2. DELETE FROM notations WHERE id = :id  (cascades to notation_pages, notation_tags, notation_instruments, notation_custom_fields)
3. For each image_path: FileStorageService.deleteFile(path)
4. FileStorageService.deleteNotationDirectory(notationId) [removes now-empty dir]
```

File deletion is best-effort after DB delete. Orphaned files (from crash between steps 2-4) are cleaned at startup via reconciliation.

---

## 4. FileStorageService Contract

```dart
abstract class FileStorageService {
  /// Returns the absolute path for a given relative path.
  Future<String> absolutePath(String relativePath);

  /// Saves notation page files and returns their relative paths.
  Future<List<String>> saveNotationPages(
    String notationId,
    List<XFile> files,
    List<String> pageIds,
  );

  /// Reads raw bytes for a page (for ImageProcessingService).
  Future<Uint8List> readPageBytes(String relativePath);

  /// Saves an instrument photo and returns its relative path.
  Future<String> saveInstrumentPhoto(String instanceId, XFile file);

  /// Deletes a single file. Best-effort; logs error on failure.
  Future<void> deleteFile(String relativePath);

  /// Deletes an entire notation directory. Best-effort.
  Future<void> deleteNotationDirectory(String notationId);

  /// Returns all notation directory names present on disk.
  /// Used for startup reconciliation.
  Future<List<String>> listNotationIds();
}
```

---

## 5. Storage Lifecycle

### 5.1 App Startup Tasks (run once, background isolate)

```
1. Open AppDatabase (Drift applies migrations if needed)
2. PRAGMA foreign_keys = ON
3. Run 30-day auto-purge:
   SELECT id FROM notations WHERE deleted_at < :cutoff
   → hard-delete each (§3.4)
4. Reconcile orphaned files:
   diskIds = FileStorageService.listNotationIds()
   dbIds   = NotationRepository.allIds()  (includes soft-deleted)
   orphans = diskIds − dbIds
   → FileStorageService.deleteNotationDirectory() for each orphan
```

Startup tasks run in `compute()` or a Dart isolate; they do not block the UI.

### 5.2 App Termination

No special cleanup needed. SQLite WAL is checkpointed on connection close (Drift handles this). No in-flight writes are abandoned — all writes are awaited before navigation proceeds.

---

## 6. Quotas & Limits

| Limit | Value | Enforcement |
|---|---|---|
| Max pages per notation | 50 | App layer (CaptureViewModel) |
| Max image file size | None (original preserved) | N/A |
| Storage quota | None (app-private dir has no hard quota) | OS-level device storage |
| Max custom field definitions | 20 | App layer (CustomFieldRepository) |

**Storage estimate:** Average JPEG from S25 camera ≈ 3-8 MB. 100 notations × 3 pages × 5 MB = ~1.5 GB worst case. No automatic compression in v1; user is responsible for device storage.

---

## 7. Backup & Recovery

**v1: No backup.** Single-device, no cloud.

**OS-level backup (Android Auto Backup):**
- `allowBackup="false"` in `AndroidManifest.xml` — disables Android Auto Backup
- Reason: App-private directory is not backed up by default anyway; explicit opt-out prevents partial backups of DB without files.

**v2 candidates:** Export as zip (DB + images), Google Drive integration.
