---
version: 1.0
status: draft
owner: technical-program-manager
date: 2026-04-25
---

# Swaralipi — Implementation Roadmap

## Table of Contents

- [Swaralipi — Implementation Roadmap](#swaralipi--implementation-roadmap)
  - [Table of Contents](#table-of-contents)
  - [1. Executive Summary](#1-executive-summary)
  - [2. Dependency Graph Summary](#2-dependency-graph-summary)
  - [3. Epic Breakdown](#3-epic-breakdown)
    - [3.1. \[Epic #7\] Infrastructure Foundation](#31-epic-7-infrastructure-foundation)
    - [3.2. \[Epic #8\] Notation Capture \& Metadata](#32-epic-8-notation-capture--metadata)
    - [3.3. \[Epic #9\] Notation Management](#33-epic-9-notation-management)
    - [3.4. \[Epic #10\] Notation Viewing \& Playback](#34-epic-10-notation-viewing--playback)
    - [3.5. \[Epic #11\] Library \& Search](#35-epic-11-library--search)
    - [3.6. \[Epic #12\] User Experience \& Settings](#36-epic-12-user-experience--settings)
    - [3.7. \[Epic #1\] Documentation](#37-epic-1-documentation)
  - [4. Feature Breakdown](#4-feature-breakdown)
    - [4.1. \[Feature\] SVC1 — AppDatabase](#41-feature-svc1--appdatabase)
    - [4.2. \[Feature\] SVC2 — FileStorageService](#42-feature-svc2--filestorageservice)
    - [4.3. \[Feature\] SVC3 — ImageProcessingService](#43-feature-svc3--imageprocessingservice)
    - [4.4. \[Feature\] SVC4 — SearchService](#44-feature-svc4--searchservice)
    - [4.5. \[Feature\] F07 — Tags](#45-feature-f07--tags)
    - [4.6. \[Feature\] F12 — Custom Fields](#46-feature-f12--custom-fields)
    - [4.7. \[Feature\] F10 — Appearance \& Theming](#47-feature-f10--appearance--theming)
    - [4.8. \[Feature\] F09 — Trash](#48-feature-f09--trash)
    - [4.9. \[Feature\] F06 — Instrument Tracker](#49-feature-f06--instrument-tracker)
    - [4.10. \[Feature\] F02 — Metadata](#410-feature-f02--metadata)
    - [4.11. \[Feature\] F01 — Notation Capture](#411-feature-f01--notation-capture)
    - [4.12. \[Feature\] F08 — Edit / Delete / Copy](#412-feature-f08--edit--delete--copy)
    - [4.13. \[Feature\] F05 — Notation Player](#413-feature-f05--notation-player)
    - [4.14. \[Feature\] F04 — Notation Detail View](#414-feature-f04--notation-detail-view)
    - [4.15. \[Feature\] F03 — Library](#415-feature-f03--library)
    - [4.16. \[Feature\] F11 — Settings](#416-feature-f11--settings)
  - [5. Sprint Plan](#5-sprint-plan)
    - [Sprint 1 — Database Foundation](#sprint-1--database-foundation)
    - [Sprint 2 — File Storage, Image Processing \& Search](#sprint-2--file-storage-image-processing--search)
    - [Sprint 3 — Tags, Custom Fields, Appearance \& Trash (Branch Work)](#sprint-3--tags-custom-fields-appearance--trash-branch-work)
    - [Sprint 4 — Metadata Form \& Repository](#sprint-4--metadata-form--repository)
    - [Sprint 5 — Notation Capture: Camera \& Gallery](#sprint-5--notation-capture-camera--gallery)
    - [Sprint 6 — Notation Capture: Page Editor \& RenderParams](#sprint-6--notation-capture-page-editor--renderparams)
    - [Sprint 7 — Trash \& Edit/Delete/Copy](#sprint-7--trash--editdeletecopy)
    - [Sprint 8 — Notation Player (F05)](#sprint-8--notation-player-f05)
    - [Sprint 9 — Detail View \& Library](#sprint-9--detail-view--library)
    - [Sprint 10 — Settings \& Polish](#sprint-10--settings--polish)
    - [Backlog (unscheduled)](#backlog-unscheduled)
  - [6. Open Questions](#6-open-questions)
  - [7. Risks](#7-risks)

---

## 1. Executive Summary

- **7 epics** (6 product + 1 documentation), **16 features** (4 infrastructure services + 12 user-facing), **~34 stories**, **~124 tasks**
- **10 planned sprints** (2 weeks each, ~20 weeks total), single developer
- **Critical path**: SVC1 → SVC2 → F07 → F02 → F01 → F09 → F08 → F04 → F03 — cannot be parallelised away
- **Highest risk**: F01 (Notation Capture, XL/High) spans 2 sprints; SVC1 and SVC3 are each L/High and gate everything downstream
- **First shippable slice** (all core flows functional): end of Sprint 9 (~2026-08-31)

---

## 2. Dependency Graph Summary

```mermaid
flowchart TD
  SVC1([SVC1 · AppDatabase]):::svc
  SVC2([SVC2 · FileStorage]):::svc
  SVC3([SVC3 · ImageProcessing]):::svc
  SVC4([SVC4 · SearchService]):::svc

  F07[F07 · Tags]:::trunk
  F09[F09 · Trash]:::branch
  F12[F12 · Custom Fields]:::branch
  F10[F10 · Appearance]:::branch
  F06[F06 · Instruments]:::branch
  F02[F02 · Metadata]:::trunk
  F01[F01 · Capture]:::trunk
  F08[F08 · Edit/Delete/Copy]:::branch
  F05[F05 · Player]:::branch
  F04[F04 · Detail View]:::trunk
  F03[F03 · Library]:::trunk
  F11[F11 · Settings]:::branch

  SVC1 --> SVC4
  SVC1 --> F07
  SVC1 --> F09
  SVC1 --> F12
  SVC1 --> F10
  SVC1 --> F06
  SVC1 --> F02
  SVC1 --> F04
  SVC1 --> F05
  SVC2 --> F01
  SVC2 --> F05
  SVC2 --> F06
  SVC2 --> F09
  SVC3 --> F05
  F07 --> F02
  F06 --> F02
  F12 --> F02
  F02 --> F01
  F01 --> F08
  F01 --> F03
  F09 --> F08
  F07 --> F03
  F08 --> F03
  F08 --> F04
  F05 --> F04
  F04 --> F03
  F07 --> F11
  F06 --> F11
  F09 --> F11
  F10 --> F11
  F12 --> F11
  SVC4 --> F03

  classDef svc fill:#1e1e2e,stroke:#89b4fa,color:#cdd6f4
  classDef trunk fill:#1e1e2e,stroke:#a6e3a1,color:#cdd6f4
  classDef branch fill:#1e1e2e,stroke:#fab387,color:#cdd6f4
```

---

## 3. Epic Breakdown

### 3.1. [Epic #7] Infrastructure Foundation

- **Priority**: P0
- **Complexity**: L (SVC1, SVC3 each L/High; SVC2, SVC4 each M/Medium)
- **Features**: SVC1, SVC2, SVC3, SVC4
- **Critical path**: Yes — SVC1 blocks all feature work; SVC2/SVC3 block capture and player

### 3.2. [Epic #8] Notation Capture & Metadata

- **Priority**: P0
- **Complexity**: XL (F01 alone is XL/High)
- **Features**: F07, F12, F02, F01
- **Critical path**: Yes — F07 → F02 → F01 is the longest trunk chain

### 3.3. [Epic #9] Notation Management

- **Priority**: P0
- **Complexity**: M (F09 S/Low, F08 M/Medium)
- **Features**: F09, F08
- **Critical path**: Partially — F09 is required before F08; F08 gates F04 and F03

### 3.4. [Epic #10] Notation Viewing & Playback

- **Priority**: P1
- **Complexity**: L (F05 L/Medium, F04 S/Low)
- **Features**: F05, F04
- **Critical path**: Yes — F04 gates F03 (Library)

### 3.5. [Epic #11] Library & Search

- **Priority**: P0
- **Complexity**: L (F03 L/Medium)
- **Features**: F03
- **Critical path**: Yes — final trunk node; requires all preceding trunk complete

### 3.6. [Epic #12] User Experience & Settings

- **Priority**: P1
- **Complexity**: M (F06 M/Low, F10 S/Low, F11 M/Low, F12 S/Low)
- **Features**: F06, F10, F12, F11
- **Critical path**: No — all branch work; F12 must finish before F02

### 3.7. [Epic #1] Documentation

- **Priority**: P1
- **Complexity**: S
- **Features**: README, contributing guides, API docs
- **Critical path**: No

---

## 4. Feature Breakdown

### 4.1. [Feature] SVC1 — AppDatabase

- **Parent epic**: #7 Infrastructure Foundation
- **Depends on**: —
- **Trunk/Branch**: Trunk
- **Complexity**: L / Risk: High
- **Stories**:
  1. Define all Drift table classes and relationships
  2. Implement DAOs (NotationDao, TagDao, InstrumentDao, CustomFieldDao, UserPreferencesDao)
  3. Set up FTS5 virtual table and full migration pipeline

### 4.2. [Feature] SVC2 — FileStorageService

- **Parent epic**: #7 Infrastructure Foundation
- **Depends on**: —
- **Trunk/Branch**: Trunk
- **Complexity**: M / Risk: Medium
- **Stories**:
  1. Implement save/retrieve/delete JPEG under `appDocDir/`
  2. Implement orphan cleanup and path-portability guarantees

### 4.3. [Feature] SVC3 — ImageProcessingService

- **Parent epic**: #7 Infrastructure Foundation
- **Depends on**: —
- **Trunk/Branch**: Branch (day-1 parallel)
- **Complexity**: L / Risk: High
- **Stories**:
  1. Define RenderParams model (filter, crop, rotate)
  2. Implement non-destructive filter rendering (ColorFiltered widget + image package)
  3. Implement crop and rotate transforms; verify originals are never written

### 4.4. [Feature] SVC4 — SearchService

- **Parent epic**: #7 Infrastructure Foundation
- **Depends on**: SVC1
- **Trunk/Branch**: Branch
- **Complexity**: M / Risk: Medium
- **Stories**:
  1. Implement FTS5 ranked query over title, artists, notes
  2. Implement result ranking, pagination, and tokeniser config

### 4.5. [Feature] F07 — Tags

- **Parent epic**: #8 Notation Capture & Metadata
- **Depends on**: SVC1
- **Trunk/Branch**: Trunk
- **Complexity**: S / Risk: Low
- **Stories**:
  1. Tag CRUD (create, rename, recolor, delete) with Catppuccin palette and 5 pre-seeded defaults

### 4.6. [Feature] F12 — Custom Fields

- **Parent epic**: #12 User Experience & Settings
- **Depends on**: SVC1
- **Trunk/Branch**: Branch
- **Complexity**: S / Risk: Low
- **Stories**:
  1. Custom field definition CRUD (name + type); fields surfaced in metadata form

### 4.7. [Feature] F10 — Appearance & Theming

- **Parent epic**: #12 User Experience & Settings
- **Depends on**: SVC1
- **Trunk/Branch**: Branch
- **Complexity**: S / Risk: Low
- **Stories**:
  1. Light/Dark/System toggle and Catppuccin/Monet seed-color picker; persist to UserPreferences

### 4.8. [Feature] F09 — Trash

- **Parent epic**: #9 Notation Management
- **Depends on**: SVC1, SVC2
- **Trunk/Branch**: Branch
- **Complexity**: S / Risk: Low
- **Stories**:
  1. Trash screen — list soft-deleted notations, restore, purge, auto-purge after 30 days

### 4.9. [Feature] F06 — Instrument Tracker

- **Parent epic**: #12 User Experience & Settings
- **Depends on**: SVC1, SVC2
- **Trunk/Branch**: Branch
- **Complexity**: M / Risk: Low
- **Stories**:
  1. InstrumentClass CRUD (create, edit, archive)
  2. InstrumentInstance CRUD with in-app photo capture/import and soft-delete archive

### 4.10. [Feature] F02 — Metadata

- **Parent epic**: #8 Notation Capture & Metadata
- **Depends on**: SVC1, F07, F06, F12
- **Trunk/Branch**: Trunk
- **Complexity**: M / Risk: Low
- **Stories**:
  1. Metadata form UI — 13 fields, tag/instrument/custom-field pickers, validation
  2. MetadataRepository — save, update, load notation metadata

### 4.11. [Feature] F01 — Notation Capture

- **Parent epic**: #8 Notation Capture & Metadata
- **Depends on**: SVC1, SVC2, F02
- **Trunk/Branch**: Trunk
- **Complexity**: XL / Risk: High
- **Stories**:
  1. Camera permission handling and CameraX integration
  2. Gallery import flow (multi-page picker)
  3. Per-page editor UI (filter/crop/rotate controls)
  4. Non-destructive RenderParams pipeline integration per page
  5. End-to-end save flow (pages → disk, metadata → DB)

### 4.12. [Feature] F08 — Edit / Delete / Copy

- **Parent epic**: #9 Notation Management
- **Depends on**: F01, F09
- **Trunk/Branch**: Branch
- **Complexity**: M / Risk: Medium
- **Stories**:
  1. Edit notation — re-enter metadata form and page editor from Library/Detail View
  2. Duplicate notation — copy all image files; create new DB record
  3. Soft-delete — move to Trash from Library and Detail View entry points

### 4.13. [Feature] F05 — Notation Player

- **Parent epic**: #10 Notation Viewing & Playback
- **Depends on**: SVC1, SVC2, SVC3
- **Trunk/Branch**: Branch
- **Complexity**: L / Risk: Medium
- **Stories**:
  1. Full-screen viewer — swipe-between-pages, pinch-zoom
  2. Orientation lock (portrait / landscape) and chrome fade on inactivity
  3. Auto-scroll at configurable speed; persist speed preference

### 4.14. [Feature] F04 — Notation Detail View

- **Parent epic**: #10 Notation Viewing & Playback
- **Depends on**: SVC1, F08, F05
- **Trunk/Branch**: Trunk
- **Complexity**: S / Risk: Low
- **Stories**:
  1. Read-only detail screen — metadata block, page thumbnails, Play / Edit / Delete actions

### 4.15. [Feature] F03 — Library

- **Parent epic**: #11 Library & Search
- **Depends on**: SVC4, F01, F07, F08, F04
- **Trunk/Branch**: Trunk
- **Complexity**: L / Risk: Medium
- **Stories**:
  1. Recently-played carousel (last 5 opened)
  2. Notation list with `ListView.builder`, sort (date, title, artist)
  3. Fuzzy search bar and tag filter panel

### 4.16. [Feature] F11 — Settings

- **Parent epic**: #12 User Experience & Settings
- **Depends on**: F07, F06, F09, F10, F12
- **Trunk/Branch**: Branch
- **Complexity**: M / Risk: Low
- **Stories**:
  1. Settings shell screen — navigation to Tags, Instruments, Trash, Appearance, Custom Fields, app info
  2. Integrate all sub-sections into shell; verify navigation and state preservation

---

## 5. Sprint Plan

### Sprint 1 — Database Foundation

**Goal**: Establish the complete Drift schema, all DAOs, migration pipeline, and domain models so every upstream feature has a stable data layer.

**Start**: 2026-04-28 **End**: 2026-05-11

| Issue | Title | Type | Size | Priority | Depends On |
| ----- | ----- | ---- | ---- | -------- | ---------- |
| #62 | SVC1-1-T1: Define all Drift table classes | task | S | P0 | — | done
| #63 | SVC1-1-T2: Define immutable domain models with copyWith | task | S | P0 | #62 | done
| #64 | SVC1-2-T1: Implement NotationDao and NotationPageDao | task | M | P0 | #62 | done
| #65 | SVC1-2-T2: Implement TagDao, NotationTagDao, InstrumentDao | task | S | P0 | #62 | done
| #66 | SVC1-2-T3: Implement CustomFieldDao and UserPreferencesDao | task | S | P0 | #62 | done
| #67 | SVC1-3-T1: Create FTS5 virtual table and triggers | task | M | P0 | #64 | done
| #68 | SVC1-3-T2: Implement Drift MigrationStrategy | task | M | P0 | #67 | done

**Definition of Done for Sprint**:
- [x] All sprint issues closed or moved to backlog with documented reason
- [x] CI green on main
- [x] Regression test suite passes

---

### Sprint 2 — File Storage, Image Processing & Search

**Goal**: Complete the three remaining infrastructure services (SVC2, SVC3, SVC4) in parallel with Sprint 1 foundations, making the full infrastructure layer ready.

**Start**: 2026-05-12 **End**: 2026-05-25

| Issue | Title | Type | Size | Priority | Depends On |
| ----- | ----- | ---- | ---- | -------- | ---------- |
| #69 | SVC2-1-T1: Implement FileStorageService save/retrieve/delete | task | S | P0 | — | done
| #70 | SVC2-2-T1: Implement orphan file detection and purge | task | S | P0 | #69 | done
| #71 | SVC3-1-T1: Define RenderParams model and filter enum | task | S | P0 | — | done
| #72 | SVC3-1-T2: Implement filter rendering pipeline | task | M | P0 | #71 | done
| #73 | SVC3-2-T1: Implement crop, rotate, and composite pipeline | task | M | P0 | #72 | done
| #74 | SVC4-1-T1: Implement SearchService with FTS5 BM25 query | task | M | P0 | #67 | done

**Definition of Done for Sprint**:
- [x] All sprint issues closed or moved to backlog with documented reason
- [x] CI green on main
- [x] Regression test suite passes

---

### Sprint 3 — Tags, Custom Fields, Appearance & Trash (Branch Work)

**Goal**: Complete all four branch features that F02/F11 depend on, in parallel with F06 start. Unblocks the metadata form.

**Start**: 2026-05-26 **End**: 2026-06-08

| Issue | Title | Type | Size | Priority | Depends On |
| ----- | ----- | ---- | ---- | -------- | ---------- |
| #75 | F07-1-T1: Implement TagRepository and TagDao seed data | task | S | P0 | #65 |
| #76 | F07-1-T2: Implement TagsScreen and TagViewModel | task | S | P0 | #75 |
| #77 | F12-1-T1: Implement CustomFieldRepository and CustomFieldsScreen | task | S | P2 | #66 |
| #78 | F10-1-T1: Implement PreferencesRepository and AppearanceScreen | task | S | P2 | #66 |
| #79 | F09-1-T1: Implement TrashRepository and TrashScreen | task | S | P1 | #64 #69 |
| #80 | F06-1-T1: Implement InstrumentRepository and InstrumentClassScreen | task | S | P2 | #65 |
| #81 | F06-2-T1: Implement InstrumentInstance screens with photo capture | task | M | P2 | #80 |

**Definition of Done for Sprint**:
- [x] All sprint issues closed or moved to backlog with documented reason
- [x] CI green on main
- [x] Regression test suite passes

---

### Sprint 4 — Metadata Form & Repository

**Goal**: Build the F02 metadata form and repository, which unlocks the entire capture flow (F01).

**Start**: 2026-06-09 **End**: 2026-06-22

| Issue | Title | Type | Size | Priority | Depends On |
| ----- | ----- | ---- | ---- | -------- | ---------- |
| #83 | F02-2-T1: Implement NotationRepository with full metadata persistence | task | M | P0 | #64 #65 #66 |
| #82 | F02-1-T1: Implement MetadataFormScreen and MetadataFormViewModel | task | M | P0 | #76 #77 #80 #83 |

**Definition of Done for Sprint**:
- [ ] All sprint issues closed or moved to backlog with documented reason
- [ ] CI green on main
- [ ] Regression test suite passes

---

### Sprint 5 — Notation Capture: Camera & Gallery

**Goal**: Implement the first two slices of F01 — camera permission/capture and gallery import. Hard-cap: no page editor in this sprint.

**Start**: 2026-06-23 **End**: 2026-07-06

| Issue | Title | Type | Size | Priority | Depends On |
| ----- | ----- | ---- | ---- | -------- | ---------- |
| #84 | F01-1-T1: Implement camera permission handling and CameraX capture | task | M | P0 | #69 #82 |
| #85 | F01-2-T1: Implement gallery multi-page import flow | task | S | P0 | #84 |

**Definition of Done for Sprint**:
- [ ] All sprint issues closed or moved to backlog with documented reason
- [ ] CI green on main
- [ ] Regression test suite passes

---

### Sprint 6 — Notation Capture: Page Editor & RenderParams

**Goal**: Complete F01 — per-page editor UI, RenderParams pipeline, and end-to-end save flow.

**Start**: 2026-07-07 **End**: 2026-07-20

| Issue | Title | Type | Size | Priority | Depends On |
| ----- | ----- | ---- | ---- | -------- | ---------- |
| #86 | F01-3-T1: Implement PageEditorScreen with filter, crop, and rotate | task | M | P0 | #71 #72 #73 |
| #87 | F01-4-T1: Implement RenderParams pipeline integration per page | task | M | P0 | #86 |
| #88 | F01-5-T1: Implement end-to-end save flow — pages to disk and metadata to DB | task | M | P0 | #87 #83 |

**Definition of Done for Sprint**:
- [ ] All sprint issues closed or moved to backlog with documented reason
- [ ] CI green on main
- [ ] Regression test suite passes

---

### Sprint 7 — Trash & Edit/Delete/Copy

**Goal**: Complete F09 (Trash) and all three F08 stories, enabling the full notation management cycle.

**Start**: 2026-07-21 **End**: 2026-08-03

| Issue | Title | Type | Size | Priority | Depends On |
| ----- | ----- | ---- | ---- | -------- | ---------- |
| #91 | F08-3-T1: Implement soft-delete — move notation to Trash | task | S | P1 | #79 #88 |
| #89 | F08-1-T1: Implement edit notation flow | task | M | P1 | #88 |
| #90 | F08-2-T1: Implement duplicate notation — copy image files | task | M | P1 | #88 |

**Definition of Done for Sprint**:
- [ ] All sprint issues closed or moved to backlog with documented reason
- [ ] CI green on main
- [ ] Regression test suite passes

---

### Sprint 8 — Notation Player (F05)

**Goal**: Build the full-screen notation player with swipe, zoom, orientation lock, and auto-scroll.

**Start**: 2026-08-04 **End**: 2026-08-17

| Issue | Title | Type | Size | Priority | Depends On |
| ----- | ----- | ---- | ---- | -------- | ---------- |
| #92 | F05-1-T1: Implement full-screen viewer with swipe and pinch-zoom | task | L | P1 | #69 #71 #72 #73 #64 |
| #93 | F05-2-T1: Implement orientation lock and chrome fade on inactivity | task | M | P1 | #92 |
| #94 | F05-3-T1: Implement auto-scroll at configurable speed | task | M | P1 | #92 |

**Definition of Done for Sprint**:
- [ ] All sprint issues closed or moved to backlog with documented reason
- [ ] CI green on main
- [ ] Regression test suite passes

---

### Sprint 9 — Detail View & Library

**Goal**: Build F04 (Detail View) and all three F03 stories. This is the final trunk sprint — the app is end-to-end functional at sprint end.

**Start**: 2026-08-18 **End**: 2026-08-31

| Issue | Title | Type | Size | Priority | Depends On |
| ----- | ----- | ---- | ---- | -------- | ---------- |
| #95 | F04-1-T1: Implement NotationDetailScreen | task | M | P1 | #89 #90 #91 #92 |
| #96 | F03-1-T1: Implement recently-played carousel (last 5 opened) | task | S | P0 | #64 |
| #97 | F03-2-T1: Implement notation list with ListView.builder and sort | task | M | P0 | #95 |
| #98 | F03-3-T1: Implement fuzzy search bar and tag filter panel | task | M | P0 | #74 #97 |

**Definition of Done for Sprint**:
- [ ] All sprint issues closed or moved to backlog with documented reason
- [ ] CI green on main
- [ ] Regression test suite passes

---

### Sprint 10 — Settings & Polish

**Goal**: Wire the Settings shell and all sub-sections; close any remaining P2 branch items.

**Start**: 2026-09-01 **End**: 2026-09-14

| Issue | Title | Type | Size | Priority | Depends On |
| ----- | ----- | ---- | ---- | -------- | ---------- |
| #99 | F11-1-T1: Implement Settings shell screen | task | S | P2 | #76 #80 #79 #78 #77 |
| #100 | F11-2-T1: Integrate all Settings sub-sections and verify navigation | task | M | P2 | #99 |

**Definition of Done for Sprint**:
- [ ] All sprint issues closed or moved to backlog with documented reason
- [ ] CI green on main
- [ ] Regression test suite passes

---

### Backlog (unscheduled)

| Issue | Title | Type | Size | Priority | Reason Deferred |
| ----- | ----- | ---- | ---- | -------- | --------------- |
| — | Documentation (Epic #1) | epic | S | P1 | No code dependencies; can start any sprint |

---

## 6. Open Questions

| ID | Question | Impact | Status |
| --- | -------- | ------ | ------ |
| OQ-1 | FTS5 tokeniser for Hindi/Bengali script — `unicode61` vs trigram? Validate with mixed-script data in Sprint 2 | Search quality | Open |
| OQ-2 | `ColorFiltered` vs `image` package for filter rendering — benchmark on Galaxy S25 before committing to SVC3 implementation in Sprint 2 | Image quality / performance | Open |
| OQ-3 | `image_picker` vs `photo_manager` for multi-image gallery import — confirm API stability and Android 13+ media permission handling | F01 implementation risk | Open |
| OQ-4 | Auto-purge background job — `WorkManager` foreground service vs on-launch check. Samsung One UI battery optimiser may kill background jobs | F09 reliability | Open |

---

## 7. Risks

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| SVC1 schema migration breaks on upgrade | High | High | Pin Drift version; write migration tests for every schema version before adding any column |
| F01 camera integration (XL/High) overruns Sprint 6 | High | High | Hard-cap Sprint 6 to ingestion only; page editor + save in Sprint 7. Accept partial by end of Sprint 6. **Gallery import**: `photo_manager` (handles multi-image + Android 13+ permissions). |
| SVC3 filter quality unacceptable on Samsung S25 GPU | ~~Medium~~ **Resolved** | High | ~~Prototype `ColorFiltered` vs `image` package~~ **Decision**: Use `ColorFiltered` (built-in). Add `image` package only if disk-save of processed image is needed. |
| Samsung One UI battery optimizer kills background jobs | Medium | Medium | Deferred. Revisit when auto-purge feature is scoped. |
| F05 pinch-zoom + orientation lock interaction bugs | Medium | Medium | Test on physical Galaxy S25 in Sprint 9; file bugs before sprint ends |
| FTS5 tokeniser produces poor results for Hindi/Bengali script | ~~Low~~ **Resolved** | High | ~~Validate FTS5 with mixed-script test data~~ **Decision**: `unicode61` default. All text is English script only. |
| Single developer capacity — illness or block extends critical path | Medium | High | No mitigation beyond: keep branch work ready to pull forward; maintain clear "next task" at all times |
