# Swaralipi — Issue Index

> Auto-generated from GitHub issues. Do not edit manually.

## Table of Contents

- [Swaralipi — Issue Index](#swaralipi--issue-index)
  - [Table of Contents](#table-of-contents)
  - [Epic #7 — Infrastructure Foundation](#epic-7--infrastructure-foundation)
    - [Goal](#goal)
    - [Scope](#scope)
    - [Out of Scope](#out-of-scope)
    - [Acceptance Criteria](#acceptance-criteria)
    - [Notes](#notes)
    - [Feature #13 — SVC1 — AppDatabase](#feature-13--svc1--appdatabase)
      - [Goal](#goal-1)
      - [Scope](#scope-1)
      - [Out of Scope](#out-of-scope-1)
      - [Acceptance Criteria](#acceptance-criteria-1)
      - [Notes](#notes-1)
      - [Stories](#stories)
        - [Story #29 — SVC1-1: Define Drift table classes and entity relationships](#story-29--svc1-1-define-drift-table-classes-and-entity-relationships)
          - [User Story](#user-story)
          - [Acceptance Criteria](#acceptance-criteria-2)
          - [Definition of Done](#definition-of-done)
          - [References](#references)
        - [Story #30 — SVC1-2: Implement DAOs for all entities](#story-30--svc1-2-implement-daos-for-all-entities)
          - [User Story](#user-story-1)
          - [Acceptance Criteria](#acceptance-criteria-3)
          - [Definition of Done](#definition-of-done-1)
          - [References](#references-1)
        - [Story #31 — SVC1-3: Set up FTS5 virtual table and migration pipeline](#story-31--svc1-3-set-up-fts5-virtual-table-and-migration-pipeline)
          - [User Story](#user-story-2)
          - [Acceptance Criteria](#acceptance-criteria-4)
          - [Definition of Done](#definition-of-done-2)
          - [References](#references-2)
    - [Feature #14 — SVC2 — FileStorageService](#feature-14--svc2--filestorageservice)
      - [Goal](#goal-2)
      - [Scope](#scope-2)
      - [Out of Scope](#out-of-scope-2)
      - [Acceptance Criteria](#acceptance-criteria-5)
      - [Notes](#notes-2)
      - [Stories](#stories-1)
        - [Story #32 — SVC2-1: Implement JPEG save, retrieve, and delete under appDocDir](#story-32--svc2-1-implement-jpeg-save-retrieve-and-delete-under-appdocdir)
          - [User Story](#user-story-3)
          - [Acceptance Criteria](#acceptance-criteria-6)
          - [Definition of Done](#definition-of-done-3)
          - [References](#references-3)
        - [Story #33 — SVC2-2: Implement orphan cleanup and path-portability guarantees](#story-33--svc2-2-implement-orphan-cleanup-and-path-portability-guarantees)
          - [User Story](#user-story-4)
          - [Acceptance Criteria](#acceptance-criteria-7)
          - [Definition of Done](#definition-of-done-4)
          - [References](#references-4)
    - [Feature #15 — SVC3 — ImageProcessingService](#feature-15--svc3--imageprocessingservice)
      - [Goal](#goal-3)
      - [Scope](#scope-3)
      - [Out of Scope](#out-of-scope-3)
      - [Acceptance Criteria](#acceptance-criteria-8)
      - [Notes](#notes-3)
      - [Stories](#stories-2)
        - [Story #34 — SVC3-1: Define RenderParams model and implement filter rendering](#story-34--svc3-1-define-renderparams-model-and-implement-filter-rendering)
          - [User Story](#user-story-5)
          - [Acceptance Criteria](#acceptance-criteria-9)
          - [Definition of Done](#definition-of-done-5)
          - [References](#references-5)
        - [Story #35 — SVC3-2: Implement crop and rotate transforms; verify originals are never written](#story-35--svc3-2-implement-crop-and-rotate-transforms-verify-originals-are-never-written)
          - [User Story](#user-story-6)
          - [Acceptance Criteria](#acceptance-criteria-10)
          - [Definition of Done](#definition-of-done-6)
          - [References](#references-6)
    - [Feature #16 — SVC4 — SearchService](#feature-16--svc4--searchservice)
      - [Goal](#goal-4)
      - [Scope](#scope-4)
      - [Out of Scope](#out-of-scope-4)
      - [Acceptance Criteria](#acceptance-criteria-11)
      - [Notes](#notes-4)
      - [Stories](#stories-3)
        - [Story #36 — SVC4-1: Implement FTS5 ranked query with prefix matching and pagination](#story-36--svc4-1-implement-fts5-ranked-query-with-prefix-matching-and-pagination)
          - [User Story](#user-story-7)
          - [Acceptance Criteria](#acceptance-criteria-12)
          - [Definition of Done](#definition-of-done-7)
          - [References](#references-7)
  - [Epic #8 — Notation Capture \& Metadata](#epic-8--notation-capture--metadata)
    - [Goal](#goal-5)
    - [Scope](#scope-5)
    - [Out of Scope](#out-of-scope-5)
    - [Acceptance Criteria](#acceptance-criteria-13)
    - [Notes](#notes-5)
    - [Feature #17 — F07 — Tags](#feature-17--f07--tags)
      - [Goal](#goal-6)
      - [Scope](#scope-6)
      - [Out of Scope](#out-of-scope-6)
      - [Acceptance Criteria](#acceptance-criteria-14)
      - [Notes](#notes-6)
      - [Stories](#stories-4)
        - [Story #37 — F07-1: Tag CRUD with Catppuccin palette and 5 pre-seeded defaults](#story-37--f07-1-tag-crud-with-catppuccin-palette-and-5-pre-seeded-defaults)
          - [User Story](#user-story-8)
          - [Acceptance Criteria](#acceptance-criteria-15)
          - [Definition of Done](#definition-of-done-8)
          - [References](#references-8)
    - [Feature #22 — F02 — Metadata](#feature-22--f02--metadata)
      - [Goal](#goal-7)
      - [Scope](#scope-7)
      - [Out of Scope](#out-of-scope-7)
      - [Acceptance Criteria](#acceptance-criteria-16)
      - [Notes](#notes-7)
      - [Stories](#stories-5)
        - [Story #43 — F02-1: Metadata form UI with tag, instrument, and custom-field pickers](#story-43--f02-1-metadata-form-ui-with-tag-instrument-and-custom-field-pickers)
          - [User Story](#user-story-9)
          - [Acceptance Criteria](#acceptance-criteria-17)
          - [Definition of Done](#definition-of-done-9)
          - [References](#references-9)
        - [Story #44 — F02-2: MetadataRepository — save, update, and load notation records](#story-44--f02-2-metadatarepository--save-update-and-load-notation-records)
          - [User Story](#user-story-10)
          - [Acceptance Criteria](#acceptance-criteria-18)
          - [Definition of Done](#definition-of-done-10)
          - [References](#references-10)
    - [Feature #25 — F01 — Notation Capture](#feature-25--f01--notation-capture)
      - [Goal](#goal-8)
      - [Scope](#scope-8)
      - [Out of Scope](#out-of-scope-8)
      - [Acceptance Criteria](#acceptance-criteria-19)
      - [Notes](#notes-8)
      - [Stories](#stories-6)
        - [Story #45 — F01-1: Camera permission handling and CameraX in-app capture](#story-45--f01-1-camera-permission-handling-and-camerax-in-app-capture)
          - [User Story](#user-story-11)
          - [Acceptance Criteria](#acceptance-criteria-20)
          - [Definition of Done](#definition-of-done-11)
          - [References](#references-11)
        - [Story #46 — F01-2: Gallery import — multi-page picker](#story-46--f01-2-gallery-import--multi-page-picker)
          - [User Story](#user-story-12)
          - [Acceptance Criteria](#acceptance-criteria-21)
          - [Definition of Done](#definition-of-done-12)
          - [References](#references-12)
        - [Story #47 — F01-3: Per-page editor UI — filter, crop, rotate controls](#story-47--f01-3-per-page-editor-ui--filter-crop-rotate-controls)
          - [User Story](#user-story-13)
          - [Acceptance Criteria](#acceptance-criteria-22)
          - [Definition of Done](#definition-of-done-13)
          - [References](#references-13)
        - [Story #48 — F01-4: RenderParams pipeline integration per page](#story-48--f01-4-renderparams-pipeline-integration-per-page)
          - [User Story](#user-story-14)
          - [Acceptance Criteria](#acceptance-criteria-23)
          - [Definition of Done](#definition-of-done-14)
          - [References](#references-14)
        - [Story #49 — F01-5: End-to-end save flow — pages to disk, metadata to DB](#story-49--f01-5-end-to-end-save-flow--pages-to-disk-metadata-to-db)
          - [User Story](#user-story-15)
          - [Acceptance Criteria](#acceptance-criteria-24)
          - [Definition of Done](#definition-of-done-15)
          - [References](#references-15)
  - [Epic #9 — Notation Management](#epic-9--notation-management)
    - [Goal](#goal-9)
    - [Scope](#scope-9)
    - [Out of Scope](#out-of-scope-9)
    - [Acceptance Criteria](#acceptance-criteria-25)
    - [Notes](#notes-9)
    - [Feature #20 — F09 — Trash](#feature-20--f09--trash)
      - [Goal](#goal-10)
      - [Scope](#scope-10)
      - [Out of Scope](#out-of-scope-10)
      - [Acceptance Criteria](#acceptance-criteria-26)
      - [Notes](#notes-10)
      - [Stories](#stories-7)
        - [Story #40 — F09-1: Trash screen — list, restore, purge, auto-purge after 30 days](#story-40--f09-1-trash-screen--list-restore-purge-auto-purge-after-30-days)
          - [User Story](#user-story-16)
          - [Acceptance Criteria](#acceptance-criteria-27)
          - [Definition of Done](#definition-of-done-16)
          - [References](#references-16)
    - [Feature #24 — F08 — Edit / Delete / Copy](#feature-24--f08--edit--delete--copy)
      - [Goal](#goal-11)
      - [Scope](#scope-11)
      - [Out of Scope](#out-of-scope-11)
      - [Acceptance Criteria](#acceptance-criteria-28)
      - [Notes](#notes-11)
      - [Stories](#stories-8)
        - [Story #50 — F08-1: Edit notation — re-enter metadata form and page editor](#story-50--f08-1-edit-notation--re-enter-metadata-form-and-page-editor)
          - [User Story](#user-story-17)
          - [Acceptance Criteria](#acceptance-criteria-29)
          - [Definition of Done](#definition-of-done-17)
          - [References](#references-17)
        - [Story #51 — F08-2: Duplicate notation — copy files and create new DB record](#story-51--f08-2-duplicate-notation--copy-files-and-create-new-db-record)
          - [User Story](#user-story-18)
          - [Acceptance Criteria](#acceptance-criteria-30)
          - [Definition of Done](#definition-of-done-18)
          - [References](#references-18)
        - [Story #52 — F08-3: Soft-delete — move notation to Trash from Library and Detail View](#story-52--f08-3-soft-delete--move-notation-to-trash-from-library-and-detail-view)
          - [User Story](#user-story-19)
          - [Acceptance Criteria](#acceptance-criteria-31)
          - [Definition of Done](#definition-of-done-19)
          - [References](#references-19)
  - [Epic #10 — Notation Viewing \& Playback](#epic-10--notation-viewing--playback)
    - [Goal](#goal-12)
    - [Scope](#scope-12)
    - [Out of Scope](#out-of-scope-12)
    - [Acceptance Criteria](#acceptance-criteria-32)
    - [Notes](#notes-12)
    - [Feature #23 — F05 — Notation Player](#feature-23--f05--notation-player)
      - [Goal](#goal-13)
      - [Scope](#scope-13)
      - [Out of Scope](#out-of-scope-13)
      - [Acceptance Criteria](#acceptance-criteria-33)
      - [Notes](#notes-13)
      - [Stories](#stories-9)
        - [Story #53 — F05-1: Full-screen viewer — swipe between pages and pinch-zoom](#story-53--f05-1-full-screen-viewer--swipe-between-pages-and-pinch-zoom)
          - [User Story](#user-story-20)
          - [Acceptance Criteria](#acceptance-criteria-34)
          - [Definition of Done](#definition-of-done-20)
          - [References](#references-20)
        - [Story #54 — F05-2: Orientation lock and chrome fade on inactivity](#story-54--f05-2-orientation-lock-and-chrome-fade-on-inactivity)
          - [User Story](#user-story-21)
          - [Acceptance Criteria](#acceptance-criteria-35)
          - [Definition of Done](#definition-of-done-21)
          - [References](#references-21)
        - [Story #55 — F05-3: Auto-scroll at configurable speed with persisted preference](#story-55--f05-3-auto-scroll-at-configurable-speed-with-persisted-preference)
          - [User Story](#user-story-22)
          - [Acceptance Criteria](#acceptance-criteria-36)
          - [Definition of Done](#definition-of-done-22)
          - [References](#references-22)
    - [Feature #26 — F04 — Notation Detail View](#feature-26--f04--notation-detail-view)
      - [Goal](#goal-14)
      - [Scope](#scope-14)
      - [Out of Scope](#out-of-scope-14)
      - [Acceptance Criteria](#acceptance-criteria-37)
      - [Notes](#notes-14)
      - [Stories](#stories-10)
        - [Story #56 — F04-1: Read-only detail screen — metadata block, thumbnails, and action buttons](#story-56--f04-1-read-only-detail-screen--metadata-block-thumbnails-and-action-buttons)
          - [User Story](#user-story-23)
          - [Acceptance Criteria](#acceptance-criteria-38)
          - [Definition of Done](#definition-of-done-23)
          - [References](#references-23)
  - [Epic #11 — Library \& Search](#epic-11--library--search)
    - [Goal](#goal-15)
    - [Scope](#scope-15)
    - [Out of Scope](#out-of-scope-15)
    - [Acceptance Criteria](#acceptance-criteria-39)
    - [Notes](#notes-15)
    - [Feature #27 — F03 — Library](#feature-27--f03--library)
      - [Goal](#goal-16)
      - [Scope](#scope-16)
      - [Out of Scope](#out-of-scope-16)
      - [Acceptance Criteria](#acceptance-criteria-40)
      - [Notes](#notes-16)
      - [Stories](#stories-11)
        - [Story #57 — F03-1: Recently-played carousel and notation list with sort](#story-57--f03-1-recently-played-carousel-and-notation-list-with-sort)
          - [User Story](#user-story-24)
          - [Acceptance Criteria](#acceptance-criteria-41)
          - [Definition of Done](#definition-of-done-24)
          - [References](#references-24)
        - [Story #58 — F03-2: Fuzzy search bar with real-time results](#story-58--f03-2-fuzzy-search-bar-with-real-time-results)
          - [User Story](#user-story-25)
          - [Acceptance Criteria](#acceptance-criteria-42)
          - [Definition of Done](#definition-of-done-25)
          - [References](#references-25)
        - [Story #59 — F03-3: Tag filter panel with multi-select chips](#story-59--f03-3-tag-filter-panel-with-multi-select-chips)
          - [User Story](#user-story-26)
          - [Acceptance Criteria](#acceptance-criteria-43)
          - [Definition of Done](#definition-of-done-26)
          - [References](#references-26)
  - [Epic #12 — User Experience \& Settings](#epic-12--user-experience--settings)
    - [Goal](#goal-17)
    - [Scope](#scope-17)
    - [Out of Scope](#out-of-scope-17)
    - [Acceptance Criteria](#acceptance-criteria-44)
    - [Notes](#notes-17)
    - [Feature #18 — F12 — Custom Fields](#feature-18--f12--custom-fields)
      - [Goal](#goal-18)
      - [Scope](#scope-18)
      - [Out of Scope](#out-of-scope-18)
      - [Acceptance Criteria](#acceptance-criteria-45)
      - [Notes](#notes-18)
      - [Stories](#stories-12)
        - [Story #38 — F12-1: Custom field definition CRUD surfaced in metadata form](#story-38--f12-1-custom-field-definition-crud-surfaced-in-metadata-form)
          - [User Story](#user-story-27)
          - [Acceptance Criteria](#acceptance-criteria-46)
          - [Definition of Done](#definition-of-done-27)
          - [References](#references-27)
    - [Feature #19 — F10 — Appearance \& Theming](#feature-19--f10--appearance--theming)
      - [Goal](#goal-19)
      - [Scope](#scope-19)
      - [Out of Scope](#out-of-scope-19)
      - [Acceptance Criteria](#acceptance-criteria-47)
      - [Notes](#notes-19)
      - [Stories](#stories-13)
        - [Story #39 — F10-1: Light/Dark/System toggle and Catppuccin/Monet seed-color picker](#story-39--f10-1-lightdarksystem-toggle-and-catppuccinmonet-seed-color-picker)
          - [User Story](#user-story-28)
          - [Acceptance Criteria](#acceptance-criteria-48)
          - [Definition of Done](#definition-of-done-28)
          - [References](#references-28)
    - [Feature #21 — F06 — Instrument Tracker](#feature-21--f06--instrument-tracker)
      - [Goal](#goal-20)
      - [Scope](#scope-20)
      - [Out of Scope](#out-of-scope-20)
      - [Acceptance Criteria](#acceptance-criteria-49)
      - [Notes](#notes-20)
      - [Stories](#stories-14)
        - [Story #41 — F06-1: InstrumentClass CRUD with archive](#story-41--f06-1-instrumentclass-crud-with-archive)
          - [User Story](#user-story-29)
          - [Acceptance Criteria](#acceptance-criteria-50)
          - [Definition of Done](#definition-of-done-29)
          - [References](#references-29)
        - [Story #42 — F06-2: InstrumentInstance CRUD with photo capture and archive](#story-42--f06-2-instrumentinstance-crud-with-photo-capture-and-archive)
          - [User Story](#user-story-30)
          - [Acceptance Criteria](#acceptance-criteria-51)
          - [Definition of Done](#definition-of-done-30)
          - [References](#references-30)
    - [Feature #28 — F11 — Settings](#feature-28--f11--settings)
      - [Goal](#goal-21)
      - [Scope](#scope-21)
      - [Out of Scope](#out-of-scope-21)
      - [Acceptance Criteria](#acceptance-criteria-52)
      - [Notes](#notes-21)
      - [Stories](#stories-15)
        - [Story #60 — F11-1: Settings shell screen with navigation to sub-sections](#story-60--f11-1-settings-shell-screen-with-navigation-to-sub-sections)
          - [User Story](#user-story-31)
          - [Acceptance Criteria](#acceptance-criteria-53)
          - [Definition of Done](#definition-of-done-31)
          - [References](#references-31)
        - [Story #61 — F11-2: Integrate all Settings sub-sections and verify navigation](#story-61--f11-2-integrate-all-settings-sub-sections-and-verify-navigation)
          - [User Story](#user-story-32)
          - [Acceptance Criteria](#acceptance-criteria-54)
          - [Definition of Done](#definition-of-done-32)
          - [References](#references-32)
  - [Epic #1 — Documentation](#epic-1--documentation)
    - [Goal](#goal-22)
    - [Scope](#scope-22)
    - [Out of Scope](#out-of-scope-22)
    - [Acceptance Criteria](#acceptance-criteria-55)
    - [Notes](#notes-22)
    - [Feature #2 — README](#feature-2--readme)
      - [Goal](#goal-23)
      - [Acceptance Criteria](#acceptance-criteria-56)
      - [Notes](#notes-23)


---

## Epic #7 — Infrastructure Foundation

**Priority:** P0 | **GitHub:** [#7](https://github.com/Roudranil/swaralipi-app/issues/7)

### Goal

Establish all foundational data and service layers so every feature has a stable, tested platform to build on.

### Scope

- SVC1: AppDatabase (SQLite via Drift) — all entity schemas, migrations, FTS5 setup
- SVC2: FileStorageService — JPEG image persistence under `appDocDir/`, orphan cleanup, path portability
- SVC3: ImageProcessingService — non-destructive RenderParams pipeline (filter, crop, rotate) applied at display time
- SVC4: SearchService — FTS5 virtual table queries over title, artists, notes

### Out of Scope

- Any UI screens or navigation
- Feature-level business logic

### Acceptance Criteria

- [ ] Drift database initialises and runs all migrations successfully on a fresh install
- [ ] FTS5 virtual table is set up and returns correct ranked results for title/artist/notes queries
- [ ] FileStorageService saves, retrieves, and deletes JPEG files with stable paths across app restarts
- [ ] ImageProcessingService applies filter/crop/rotate non-destructively; original file is never modified
- [ ] All services have unit tests with ≥ 80% coverage
- [ ] `flutter analyze` passes with zero warnings

### Notes

On the critical path. SVC1 must complete before SVC2, SVC4, and most features can begin. SVC3 can start in parallel from day 1. High schema-migration risk — pin Drift version and write migration tests before adding any column.

### Feature #13 — SVC1 — AppDatabase

**Priority:** P0 | **GitHub:** [#13](https://github.com/Roudranil/swaralipi-app/issues/13)

#### Goal

Establish the SQLite database layer via Drift with all entity schemas, DAO interfaces, FTS5 virtual table, and a safe migration pipeline.

#### Scope

- Define all Drift table classes: Notations, Tags, NotationTags, Pages, InstrumentClasses, InstrumentInstances, CustomFieldDefs, CustomFieldValues, UserPreferences
- Implement DAOs: NotationDao, TagDao, InstrumentDao, CustomFieldDao, UserPreferencesDao
- Configure FTS5 virtual table over title, artists, notes columns
- Implement and test migration pipeline for schema evolution

#### Out of Scope

- Any UI screens or navigation
- Business logic above the DAO layer

#### Acceptance Criteria

- [ ] Drift database initialises on a fresh install with all tables present
- [ ] All DAOs expose CRUD operations with type-safe queries
- [ ] FTS5 virtual table is set up and returns ranked results for title/artist/notes queries
- [ ] Migration pipeline runs cleanly from schema version 1 to current
- [ ] Unit tests cover all DAOs at ≥ 80% coverage
- [ ] `flutter analyze` passes with zero warnings

#### Notes

Trunk. On the critical path — SVC4, F07, F06, F10, F09, F12, F02 all depend on SVC1. High risk due to schema migration complexity. Pin Drift version on first commit and write migration tests before adding any column.

#### Stories

| # | Title | Priority |
|---|-------|----------|
| [#29](https://github.com/Roudranil/swaralipi-app/issues/29) | SVC1-1: Define Drift table classes and entity relationships | P0 |
| [#30](https://github.com/Roudranil/swaralipi-app/issues/30) | SVC1-2: Implement DAOs for all entities | P0 |
| [#31](https://github.com/Roudranil/swaralipi-app/issues/31) | SVC1-3: Set up FTS5 virtual table and migration pipeline | P0 |

##### Story #29 — SVC1-1: Define Drift table classes and entity relationships

**Priority:** P0 | **GitHub:** [#29](https://github.com/Roudranil/swaralipi-app/issues/29)

###### User Story

As a developer, I want all Drift table classes and relationships defined so every feature has a type-safe, schema-correct data layer to build on.

###### Acceptance Criteria

- [ ] Drift table classes defined: Notations, Tags, NotationTags, Pages, InstrumentClasses, InstrumentInstances, CustomFieldDefs, CustomFieldValues, UserPreferences
- [ ] Foreign key relationships declared and enforced
- [ ] Generated code (`.g.dart`) compiles cleanly with zero errors
- [ ] `flutter analyze` passes with zero warnings

###### Definition of Done

- [ ] Implementation complete
- [ ] Unit tests added (80%+ coverage on new code)
- [ ] `dart format` + `flutter analyze` pass
- [ ] Code review: no CRITICAL or HIGH issues
- [ ] PR opened, linked to this issue

###### References

- [Feature DAG — §3.1 Infrastructure Services](./docs/02-technical/feature-dag.md#31-infrastructure-services)
- [Data Model](./docs/02-technical/data-model.md)
- [SDS — Architecture Overview](./docs/02-technical/sds.md)


##### Story #30 — SVC1-2: Implement DAOs for all entities

**Priority:** P0 | **GitHub:** [#30](https://github.com/Roudranil/swaralipi-app/issues/30)

###### User Story

As a developer, I want type-safe DAO interfaces for all entities so features can read and write data without touching raw SQL.

###### Acceptance Criteria

- [ ] NotationDao: insert, update, delete, getById, getAll, watchAll implemented
- [ ] TagDao: insert, update, delete, getAll, watchAll implemented
- [ ] InstrumentDao: insert, update, delete, getAll (classes and instances) implemented
- [ ] CustomFieldDao: insert, update, delete, getAll definitions and values implemented
- [ ] UserPreferencesDao: get and upsert preference record implemented
- [ ] All DAOs use Drift&#39;s type-safe query DSL — no raw SQL strings
- [ ] Unit tests cover all DAO methods at ≥ 80% coverage

###### Definition of Done

- [ ] Implementation complete
- [ ] Unit tests added (80%+ coverage on new code)
- [ ] `dart format` + `flutter analyze` pass
- [ ] Code review: no CRITICAL or HIGH issues
- [ ] PR opened, linked to this issue

###### References

- [Feature DAG — §3.1 Infrastructure Services](./docs/02-technical/feature-dag.md#31-infrastructure-services)
- [Data Model](./docs/02-technical/data-model.md)
- [SDS — Architecture Overview](./docs/02-technical/sds.md)


##### Story #31 — SVC1-3: Set up FTS5 virtual table and migration pipeline

**Priority:** P0 | **GitHub:** [#31](https://github.com/Roudranil/swaralipi-app/issues/31)

###### User Story

As a developer, I want an FTS5 virtual table over title, artists, and notes and a tested migration pipeline so search works correctly and schema changes are safe.

###### Acceptance Criteria

- [ ] FTS5 virtual table created in the initial schema migration
- [ ] FTS5 table kept in sync with the Notations table via triggers (or manual inserts in DAOs)
- [ ] Migration pipeline defined: schema v1 → current with `MigrationStrategy`
- [ ] Migration tests verify each step produces the correct schema
- [ ] `flutter analyze` passes with zero warnings

###### Definition of Done

- [ ] Implementation complete
- [ ] Unit tests added (80%+ coverage on new code)
- [ ] `dart format` + `flutter analyze` pass
- [ ] Code review: no CRITICAL or HIGH issues
- [ ] PR opened, linked to this issue

###### References

- [Feature DAG — §3.1 Infrastructure Services](./docs/02-technical/feature-dag.md#31-infrastructure-services)
- [Data Model](./docs/02-technical/data-model.md)
- [SDS — Architecture Overview](./docs/02-technical/sds.md)


### Feature #14 — SVC2 — FileStorageService

**Priority:** P0 | **GitHub:** [#14](https://github.com/Roudranil/swaralipi-app/issues/14)

#### Goal

Provide a reliable file I/O service for saving, retrieving, and deleting JPEG notation page images under `appDocDir/` with stable path guarantees and orphan cleanup.

#### Scope

- Save JPEG image files under `appDocDir/notations//pages/`
- Retrieve file paths by notation ID and page index
- Delete individual files and entire notation directories
- Orphan cleanup: detect and remove files not referenced by any DB record
- Path portability: paths stored as relative segments, resolved at runtime

#### Out of Scope

- Image processing or transformation (belongs to SVC3)
- Cloud or network I/O

#### Acceptance Criteria

- [ ] Save returns a stable relative path that resolves correctly after app restart
- [ ] Delete removes the file and returns success; idempotent on missing file
- [ ] Orphan cleanup identifies unreferenced files without deleting referenced ones
- [ ] Unit tests cover all public methods at ≥ 80% coverage
- [ ] `flutter analyze` passes with zero warnings

#### Notes

Trunk. Complexity M / Risk Medium. Depends on nothing — can start day 1 in parallel with SVC1 and SVC3.

#### Stories

| # | Title | Priority |
|---|-------|----------|
| [#32](https://github.com/Roudranil/swaralipi-app/issues/32) | SVC2-1: Implement JPEG save, retrieve, and delete under appDocDir | P0 |
| [#33](https://github.com/Roudranil/swaralipi-app/issues/33) | SVC2-2: Implement orphan cleanup and path-portability guarantees | P0 |

##### Story #32 — SVC2-1: Implement JPEG save, retrieve, and delete under appDocDir

**Priority:** P0 | **GitHub:** [#32](https://github.com/Roudranil/swaralipi-app/issues/32)

###### User Story

As a developer, I want a FileStorageService that saves, retrieves, and deletes JPEG files under `appDocDir/notations//pages/` so image data persists correctly across app restarts.

###### Acceptance Criteria

- [ ] `saveImage(Uint8List bytes, String notationId, int pageIndex)` returns a stable relative path
- [ ] `getImagePath(String notationId, int pageIndex)` resolves to an existing file
- [ ] `deletePage(String notationId, int pageIndex)` removes the file; idempotent on missing file
- [ ] `deleteNotation(String notationId)` removes the entire notation directory
- [ ] Relative paths resolve correctly after app restart (path re-rooted to current `appDocDir`)
- [ ] Unit tests at ≥ 80% coverage

###### Definition of Done

- [ ] Implementation complete
- [ ] Unit tests added (80%+ coverage on new code)
- [ ] `dart format` + `flutter analyze` pass
- [ ] Code review: no CRITICAL or HIGH issues
- [ ] PR opened, linked to this issue

###### References

- [Feature DAG — §3.1 Infrastructure Services](./docs/02-technical/feature-dag.md#31-infrastructure-services)
- [SDS — Architecture Overview](./docs/02-technical/sds.md)


##### Story #33 — SVC2-2: Implement orphan cleanup and path-portability guarantees

**Priority:** P0 | **GitHub:** [#33](https://github.com/Roudranil/swaralipi-app/issues/33)

###### User Story

As a developer, I want orphan file detection and cleanup so disk space is not wasted by unreferenced images after deletions or failed saves.

###### Acceptance Criteria

- [ ] `scanOrphans()` returns a list of file paths not referenced by any DB notation record
- [ ] `purgeOrphans()` deletes all orphaned files without touching any referenced file
- [ ] Orphan scan is called on app startup after DB is ready
- [ ] Unit tests cover orphan detection and purge at ≥ 80% coverage

###### Definition of Done

- [ ] Implementation complete
- [ ] Unit tests added (80%+ coverage on new code)
- [ ] `dart format` + `flutter analyze` pass
- [ ] Code review: no CRITICAL or HIGH issues
- [ ] PR opened, linked to this issue

###### References

- [Feature DAG — §3.1 Infrastructure Services](./docs/02-technical/feature-dag.md#31-infrastructure-services)
- [SDS — Architecture Overview](./docs/02-technical/sds.md)


### Feature #15 — SVC3 — ImageProcessingService

**Priority:** P0 | **GitHub:** [#15](https://github.com/Roudranil/swaralipi-app/issues/15)

#### Goal

Deliver a non-destructive image rendering pipeline that applies RenderParams (filter, crop, rotate) at display time without ever modifying the original JPEG on disk.

#### Scope

- Define `RenderParams` model: filter (enum), crop (Rect), rotation (0/90/180/270 degrees)
- Implement filter rendering using `ColorFiltered` widget or the `image` package
- Implement crop and rotate transforms applied in-memory at display time
- Verify original file bytes are never written during any render operation

#### Out of Scope

- File persistence of processed images
- UI controls for editing (those are in F01 per-page editor)

#### Acceptance Criteria

- [ ] `RenderParams` is immutable and serialisable (JSON)
- [ ] Applying a filter renders visually correctly; original file is unchanged
- [ ] Crop and rotate transforms are composable and produce correct output
- [ ] Unit tests cover all transform combinations at ≥ 80% coverage
- [ ] `flutter analyze` passes with zero warnings

#### Notes

Branch (day-1 parallel). Complexity L / Risk High. No DB dependency — can start immediately. F01 and F05 both depend on this service.

#### Stories

| # | Title | Priority |
|---|-------|----------|
| [#34](https://github.com/Roudranil/swaralipi-app/issues/34) | SVC3-1: Define RenderParams model and implement filter rendering | P0 |
| [#35](https://github.com/Roudranil/swaralipi-app/issues/35) | SVC3-2: Implement crop and rotate transforms; verify originals are never written | P0 |

##### Story #34 — SVC3-1: Define RenderParams model and implement filter rendering

**Priority:** P0 | **GitHub:** [#34](https://github.com/Roudranil/swaralipi-app/issues/34)

###### User Story

As a developer, I want an immutable RenderParams model and a filter rendering pipeline so notation pages can display with colour adjustments without modifying original files.

###### Acceptance Criteria

- [ ] `RenderParams` is an immutable class with `filter` (enum), `cropRect` (nullable Rect), `rotation` (0/90/180/270)
- [ ] `RenderParams` is JSON-serialisable via `json_serializable`
- [ ] Filter rendering applied via `ColorFiltered` widget or `image` package transform; original file bytes never written
- [ ] `applyFilter(Uint8List original, RenderParams params)` returns new bytes in-memory
- [ ] Unit tests cover all filter enum values at ≥ 80% coverage

###### Definition of Done

- [ ] Implementation complete
- [ ] Unit tests added (80%+ coverage on new code)
- [ ] `dart format` + `flutter analyze` pass
- [ ] Code review: no CRITICAL or HIGH issues
- [ ] PR opened, linked to this issue

###### References

- [Feature DAG — §3.1 Infrastructure Services](./docs/02-technical/feature-dag.md#31-infrastructure-services)
- [SDS — Architecture Overview](./docs/02-technical/sds.md)


##### Story #35 — SVC3-2: Implement crop and rotate transforms; verify originals are never written

**Priority:** P0 | **GitHub:** [#35](https://github.com/Roudranil/swaralipi-app/issues/35)

###### User Story

As a developer, I want crop and rotate transforms that compose with filter rendering so a page can be displayed with all three adjustments simultaneously, and I need a test that proves the original file is never modified.

###### Acceptance Criteria

- [ ] `applyCrop(Uint8List bytes, Rect cropRect)` returns cropped bytes; original unchanged
- [ ] `applyRotation(Uint8List bytes, int degrees)` returns rotated bytes; original unchanged
- [ ] Transforms are composable: filter → crop → rotate in a single pipeline call
- [ ] Test asserts original file hash matches before and after any transform combination
- [ ] Unit tests cover crop/rotate combinations at ≥ 80% coverage

###### Definition of Done

- [ ] Implementation complete
- [ ] Unit tests added (80%+ coverage on new code)
- [ ] `dart format` + `flutter analyze` pass
- [ ] Code review: no CRITICAL or HIGH issues
- [ ] PR opened, linked to this issue

###### References

- [Feature DAG — §3.1 Infrastructure Services](./docs/02-technical/feature-dag.md#31-infrastructure-services)
- [SDS — Architecture Overview](./docs/02-technical/sds.md)


### Feature #16 — SVC4 — SearchService

**Priority:** P0 | **GitHub:** [#16](https://github.com/Roudranil/swaralipi-app/issues/16)

#### Goal

Expose ranked full-text search over notation title, artists, and notes fields using the FTS5 virtual table provisioned by SVC1.

#### Scope

- Implement FTS5 ranked query over title, artists, notes columns
- Support partial/prefix matching (fuzzy-style)
- Result ranking by relevance score
- Pagination support (limit/offset)
- Tokeniser configuration (unicode61)

#### Out of Scope

- UI search bar (belongs to F03)
- Tag or instrument filtering (belongs to F03)

#### Acceptance Criteria

- [ ] Queries return results ranked by relevance score
- [ ] Prefix matching works (e.g., &#34;Bhai&#34; matches &#34;Bhairavi&#34;)
- [ ] Empty query returns all notations (unranked)
- [ ] Pagination returns correct pages with consistent ordering
- [ ] Unit tests cover all query paths at ≥ 80% coverage
- [ ] `flutter analyze` passes with zero warnings

#### Notes

Branch. Complexity M / Risk Medium. Depends on SVC1 (FTS5 table). Must complete before F03 Library feature.

#### Stories

| # | Title | Priority |
|---|-------|----------|
| [#36](https://github.com/Roudranil/swaralipi-app/issues/36) | SVC4-1: Implement FTS5 ranked query with prefix matching and pagination | P0 |

##### Story #36 — SVC4-1: Implement FTS5 ranked query with prefix matching and pagination

**Priority:** P0 | **GitHub:** [#36](https://github.com/Roudranil/swaralipi-app/issues/36)

###### User Story

As a developer, I want a SearchService that runs FTS5 queries over title, artists, and notes so the Library feature can return ranked, paginated search results.

###### Acceptance Criteria

- [ ] `search(String query, {int limit, int offset})` returns results ranked by BM25 score
- [ ] Prefix matching works: query &#34;Bhai&#34; matches notation titled &#34;Bhairavi&#34;
- [ ] Empty query returns all notations ordered by date modified (descending)
- [ ] Pagination returns consistent pages with no duplicates across pages
- [ ] Tokeniser configured as `unicode61` in FTS5 table definition
- [ ] Unit tests at ≥ 80% coverage

###### Definition of Done

- [ ] Implementation complete
- [ ] Unit tests added (80%+ coverage on new code)
- [ ] `dart format` + `flutter analyze` pass
- [ ] Code review: no CRITICAL or HIGH issues
- [ ] PR opened, linked to this issue

###### References

- [Feature DAG — §3.1 Infrastructure Services](./docs/02-technical/feature-dag.md#31-infrastructure-services)
- [SDS — Architecture Overview](./docs/02-technical/sds.md)
- [Data Model](./docs/02-technical/data-model.md)


---

## Epic #8 — Notation Capture & Metadata

**Priority:** P0 | **GitHub:** [#8](https://github.com/Roudranil/swaralipi-app/issues/8)

### Goal

Allow the musician to photograph or import notation pages, attach a full 13-field metadata schema, and organise notations with tags — transforming physical notebooks into searchable digital records.

### Scope

- F07 (Tags): Create, rename, recolor, and delete tags; Catppuccin palette; 5 pre-seeded defaults
- F02 (Metadata): 13-field schema — title, artists, timing, language, tags, instruments, custom fields; form UI
- F01 (Notation Capture): In-app camera capture and gallery import; per-page editor with filter/crop/rotate; metadata form submission

### Out of Scope

- OCR or automatic metadata extraction
- Cloud backup or sync

### Acceptance Criteria

- [ ] User can create, rename, recolor, and delete tags
- [ ] All 13 metadata fields are persisted correctly in the database
- [ ] User can capture a notation via camera or import from gallery
- [ ] Per-page editor applies non-destructive filter, crop, and rotate
- [ ] Metadata form validates required fields before saving
- [ ] All new code has ≥ 80% unit/widget test coverage

### Notes

F07 must complete before F02 (tags referenced in metadata). F02 must complete before F01. Depends on Epic 1 (Infrastructure Foundation) being complete. F01 is the highest-risk feature in the entire DAG (XL complexity, High risk) — plan for camera permission handling, lifecycle edge cases, and pipeline integration carefully.

### Feature #17 — F07 — Tags

**Priority:** P0 | **GitHub:** [#17](https://github.com/Roudranil/swaralipi-app/issues/17)

#### Goal

Allow the musician to create, rename, recolor, and delete tags using the Catppuccin color palette, with 5 pre-seeded default tags available on first launch.

#### Scope

- Tag CRUD: create, rename, recolor, delete
- Catppuccin Mocha palette as the color picker
- 5 pre-seeded default tags on first install
- Tag list screen in Settings
- Prevent deletion of tags currently assigned to notations (or cascade, per UX decision)

#### Out of Scope

- Tag assignment to notations (handled in F02 metadata form)
- Tag filtering in Library (handled in F03)

#### Acceptance Criteria

- [ ] User can create a tag with a name and a Catppuccin color
- [ ] User can rename and recolor an existing tag; changes reflect immediately across all notations
- [ ] User can delete a tag; it is removed from all assigned notations
- [ ] 5 default tags are present on a fresh install
- [ ] Unit and widget tests at ≥ 80% coverage on new code
- [ ] `flutter analyze` passes with zero warnings

#### Notes

Trunk. Complexity S / Risk Low. Depends on SVC1. Must complete before F02 (metadata form embeds tag picker).

#### Stories

| # | Title | Priority |
|---|-------|----------|
| [#37](https://github.com/Roudranil/swaralipi-app/issues/37) | F07-1: Tag CRUD with Catppuccin palette and 5 pre-seeded defaults | P0 |

##### Story #37 — F07-1: Tag CRUD with Catppuccin palette and 5 pre-seeded defaults

**Priority:** P0 | **GitHub:** [#37](https://github.com/Roudranil/swaralipi-app/issues/37)

###### User Story

As a musician, I want to create, rename, recolor, and delete tags using the Catppuccin palette so I can organise my notations with meaningful color-coded labels.

###### Acceptance Criteria

- [ ] Tag list screen shows all tags with their color swatch and name
- [ ] Create tag: name input + Catppuccin Mocha color picker; saved to DB via TagDao
- [ ] Rename tag: updates name in DB; reflects across all assigned notations immediately
- [ ] Recolor tag: updates color in DB; reflects in UI immediately
- [ ] Delete tag: removes tag from DB and all NotationTags join records
- [ ] 5 default tags seeded on first install (run once via UserPreferences flag)
- [ ] Unit and widget tests at ≥ 80% coverage

###### Definition of Done

- [ ] Implementation complete
- [ ] Unit tests added (80%+ coverage on new code)
- [ ] `dart format` + `flutter analyze` pass
- [ ] Code review: no CRITICAL or HIGH issues
- [ ] PR opened, linked to this issue

###### References

- [Feature DAG — §3.2 Features](./docs/02-technical/feature-dag.md#32-features)
- [Data Model](./docs/02-technical/data-model.md)
- [Feature DAG — §4 Dependency Table](./docs/02-technical/feature-dag.md#4-dependency-table)


### Feature #22 — F02 — Metadata

**Priority:** P0 | **GitHub:** [#22](https://github.com/Roudranil/swaralipi-app/issues/22)

#### Goal

Deliver the 13-field metadata schema and form UI with tag, instrument, and custom-field pickers, backed by a MetadataRepository that persists and loads notation records.

#### Scope

- Metadata form UI: title, artists, date, time signature, key signature, language, tags (multi-select), instruments (multi-select), notes (text), custom fields
- Field validation: title required; other fields optional
- Tag picker integrated with F07 tag list
- Instrument picker integrated with F06 instrument list
- Custom field inputs integrated with F12 field definitions
- MetadataRepository: save, update, load notation metadata

#### Out of Scope

- Camera or gallery capture (belongs to F01)
- Search or filtering by metadata (belongs to F03)

#### Acceptance Criteria

- [ ] All 13 standard metadata fields are present and persist correctly
- [ ] Tag multi-select shows F07 tags and allows assignment
- [ ] Instrument multi-select shows F06 instruments and allows assignment
- [ ] Custom field definitions from F12 render as additional inputs
- [ ] Required field (title) shows validation error on empty submit
- [ ] Unit and widget tests at ≥ 80% coverage on new code
- [ ] `flutter analyze` passes with zero warnings

#### Notes

Trunk. Complexity M / Risk Low. Depends on SVC1, F07, F06, F12. Must complete before F01 (capture submits the metadata form).

#### Stories

| # | Title | Priority |
|---|-------|----------|
| [#43](https://github.com/Roudranil/swaralipi-app/issues/43) | F02-1: Metadata form UI with tag, instrument, and custom-field pickers | P0 |
| [#44](https://github.com/Roudranil/swaralipi-app/issues/44) | F02-2: MetadataRepository — save, update, and load notation records | P0 |

##### Story #43 — F02-1: Metadata form UI with tag, instrument, and custom-field pickers

**Priority:** P0 | **GitHub:** [#43](https://github.com/Roudranil/swaralipi-app/issues/43)

###### User Story

As a musician, I want a metadata form with all 13 fields plus pickers for tags, instruments, and custom fields so I can fully describe a notation before saving it.

###### Acceptance Criteria

- [ ] Form fields: title (required), artists, date written, time signature, key signature, language, notes (multiline)
- [ ] Tag multi-select picker shows F07 tags with color swatches; supports add/remove
- [ ] Instrument multi-select picker shows F06 active instances; supports add/remove
- [ ] Custom field definitions from F12 render as additional typed inputs (text/number/date)
- [ ] Title field shows validation error on empty submit attempt
- [ ] Form state preserved on back-navigation (no accidental data loss)
- [ ] Unit and widget tests at ≥ 80% coverage

###### Definition of Done

- [ ] Implementation complete
- [ ] Unit tests added (80%+ coverage on new code)
- [ ] `dart format` + `flutter analyze` pass
- [ ] Code review: no CRITICAL or HIGH issues
- [ ] PR opened, linked to this issue

###### References

- [Feature DAG — §3.2 Features](./docs/02-technical/feature-dag.md#32-features)
- [Data Model](./docs/02-technical/data-model.md)
- [Feature DAG — §4 Dependency Table](./docs/02-technical/feature-dag.md#4-dependency-table)


##### Story #44 — F02-2: MetadataRepository — save, update, and load notation records

**Priority:** P0 | **GitHub:** [#44](https://github.com/Roudranil/swaralipi-app/issues/44)

###### User Story

As a developer, I want a MetadataRepository that persists and loads full notation records so the UI layer never touches DAOs directly.

###### Acceptance Criteria

- [ ] `saveNotation(NotationDraft draft)` writes notation + tags + custom field values atomically
- [ ] `updateNotation(String id, NotationDraft draft)` updates all fields; tags and custom values replaced
- [ ] `loadNotation(String id)` returns a fully-hydrated `NotationDetail` including tags, instruments, custom fields
- [ ] All operations run in a Drift transaction to ensure atomicity
- [ ] Unit tests cover save, update, load, and error paths at ≥ 80% coverage

###### Definition of Done

- [ ] Implementation complete
- [ ] Unit tests added (80%+ coverage on new code)
- [ ] `dart format` + `flutter analyze` pass
- [ ] Code review: no CRITICAL or HIGH issues
- [ ] PR opened, linked to this issue

###### References

- [Feature DAG — §3.2 Features](./docs/02-technical/feature-dag.md#32-features)
- [Data Model](./docs/02-technical/data-model.md)
- [SDS — Architecture Overview](./docs/02-technical/sds.md)


### Feature #25 — F01 — Notation Capture

**Priority:** P0 | **GitHub:** [#25](https://github.com/Roudranil/swaralipi-app/issues/25)

#### Goal

Allow the musician to photograph notation pages in-app or import them from the gallery, edit each page non-destructively, fill in metadata, and save the full notation to local storage.

#### Scope

- Camera permission handling and CameraX integration (in-app capture)
- Gallery import flow: multi-page picker using photo_manager or image_picker
- Per-page editor UI: filter, crop, rotate controls backed by SVC3 RenderParams
- RenderParams pipeline integration: each page carries its own RenderParams
- End-to-end save: pages written to disk via SVC2, metadata record written via F02/MetadataRepository
- Page reordering and deletion within the capture session

#### Out of Scope

- OCR or automatic metadata extraction
- Cloud backup

#### Acceptance Criteria

- [ ] Camera permission is requested correctly; denial shows an explanatory dialog
- [ ] In-app camera captures one or more pages sequentially
- [ ] Gallery import allows selecting multiple images at once
- [ ] Per-page editor applies filter/crop/rotate non-destructively; original file unchanged
- [ ] Pages can be reordered and deleted before saving
- [ ] Metadata form must be completed before the notation can be saved
- [ ] Saved notation appears immediately in the Library
- [ ] Unit and widget tests at ≥ 80% coverage on new code
- [ ] `flutter analyze` passes with zero warnings

#### Notes

Trunk. Complexity XL / Risk High. Depends on SVC1, SVC2, F02. Highest-risk feature in the DAG. Plan for camera permission edge cases, CameraX lifecycle, and pipeline integration carefully. F08 reuses this capture flow for edit.

#### Stories

| # | Title | Priority |
|---|-------|----------|
| [#45](https://github.com/Roudranil/swaralipi-app/issues/45) | F01-1: Camera permission handling and CameraX in-app capture | P0 |
| [#46](https://github.com/Roudranil/swaralipi-app/issues/46) | F01-2: Gallery import — multi-page picker | P0 |
| [#47](https://github.com/Roudranil/swaralipi-app/issues/47) | F01-3: Per-page editor UI — filter, crop, rotate controls | P0 |
| [#48](https://github.com/Roudranil/swaralipi-app/issues/48) | F01-4: RenderParams pipeline integration per page | P0 |
| [#49](https://github.com/Roudranil/swaralipi-app/issues/49) | F01-5: End-to-end save flow — pages to disk, metadata to DB | P0 |

##### Story #45 — F01-1: Camera permission handling and CameraX in-app capture

**Priority:** P0 | **GitHub:** [#45](https://github.com/Roudranil/swaralipi-app/issues/45)

###### User Story

As a musician, I want to capture notation pages using the device camera so I can digitise handwritten notations without leaving the app.

###### Acceptance Criteria

- [ ] Camera permission requested at first use; permanent denial shows an explanatory dialog with Settings deep-link
- [ ] In-app camera screen shows viewfinder with capture button
- [ ] Each capture adds a page thumbnail to the capture session list
- [ ] User can retake (replace) any captured page
- [ ] Camera lifecycle handled correctly: paused on background, resumed on foreground
- [ ] Unit and widget tests at ≥ 80% coverage (camera hardware mocked)

###### Definition of Done

- [ ] Implementation complete
- [ ] Unit tests added (80%+ coverage on new code)
- [ ] `dart format` + `flutter analyze` pass
- [ ] Code review: no CRITICAL or HIGH issues
- [ ] PR opened, linked to this issue

###### References

- [Feature DAG — §3.2 Features](./docs/02-technical/feature-dag.md#32-features)
- [Feature DAG — §4 Dependency Table](./docs/02-technical/feature-dag.md#4-dependency-table)
- [SDS — Architecture Overview](./docs/02-technical/sds.md)


##### Story #46 — F01-2: Gallery import — multi-page picker

**Priority:** P0 | **GitHub:** [#46](https://github.com/Roudranil/swaralipi-app/issues/46)

###### User Story

As a musician, I want to import multiple notation pages from my gallery at once so I can add existing photos to a new notation quickly.

###### Acceptance Criteria

- [ ] Gallery import triggered from the capture session screen
- [ ] Multi-image selection supported (via `image_picker` or `photo_manager`)
- [ ] Selected images added as pages to the current capture session
- [ ] Gallery permission handled correctly on Android 13+ (granular media permission)
- [ ] Unit and widget tests at ≥ 80% coverage (gallery access mocked)

###### Definition of Done

- [ ] Implementation complete
- [ ] Unit tests added (80%+ coverage on new code)
- [ ] `dart format` + `flutter analyze` pass
- [ ] Code review: no CRITICAL or HIGH issues
- [ ] PR opened, linked to this issue

###### References

- [Feature DAG — §3.2 Features](./docs/02-technical/feature-dag.md#32-features)
- [Feature DAG — §4 Dependency Table](./docs/02-technical/feature-dag.md#4-dependency-table)
- [SDS — Architecture Overview](./docs/02-technical/sds.md)


##### Story #47 — F01-3: Per-page editor UI — filter, crop, rotate controls

**Priority:** P0 | **GitHub:** [#47](https://github.com/Roudranil/swaralipi-app/issues/47)

###### User Story

As a musician, I want a per-page editor where I can apply filter, crop, and rotate adjustments so each notation page looks its best before saving.

###### Acceptance Criteria

- [ ] Per-page editor accessible by tapping a page thumbnail in the capture session
- [ ] Filter control: segmented chips for available filter enum values; live preview
- [ ] Crop control: draggable crop handles over the page image
- [ ] Rotate control: 90° clockwise / counter-clockwise buttons
- [ ] All adjustments stored as `RenderParams` — original file not written
- [ ] &#34;Reset&#34; button restores original RenderParams (no filter, full crop, 0° rotation)
- [ ] Unit and widget tests at ≥ 80% coverage

###### Definition of Done

- [ ] Implementation complete
- [ ] Unit tests added (80%+ coverage on new code)
- [ ] `dart format` + `flutter analyze` pass
- [ ] Code review: no CRITICAL or HIGH issues
- [ ] PR opened, linked to this issue

###### References

- [Feature DAG — §3.2 Features](./docs/02-technical/feature-dag.md#32-features)
- [SDS — Architecture Overview](./docs/02-technical/sds.md)


##### Story #48 — F01-4: RenderParams pipeline integration per page

**Priority:** P0 | **GitHub:** [#48](https://github.com/Roudranil/swaralipi-app/issues/48)

###### User Story

As a developer, I want each capture session page to carry its own `RenderParams` that flows through to the save pipeline so adjustments are persisted correctly.

###### Acceptance Criteria

- [ ] Each page in the capture session has an associated `RenderParams` (default: no-op)
- [ ] RenderParams updated by the per-page editor and reflected in live preview
- [ ] On save, RenderParams serialised to JSON and stored in the Pages DB record
- [ ] On load/display, RenderParams deserialised and passed to SVC3 for rendering
- [ ] Unit tests cover RenderParams round-trip (create → serialise → deserialise → render) at ≥ 80% coverage

###### Definition of Done

- [ ] Implementation complete
- [ ] Unit tests added (80%+ coverage on new code)
- [ ] `dart format` + `flutter analyze` pass
- [ ] Code review: no CRITICAL or HIGH issues
- [ ] PR opened, linked to this issue

###### References

- [Feature DAG — §3.2 Features](./docs/02-technical/feature-dag.md#32-features)
- [Data Model](./docs/02-technical/data-model.md)
- [SDS — Architecture Overview](./docs/02-technical/sds.md)


##### Story #49 — F01-5: End-to-end save flow — pages to disk, metadata to DB

**Priority:** P0 | **GitHub:** [#49](https://github.com/Roudranil/swaralipi-app/issues/49)

###### User Story

As a musician, I want to complete the metadata form and save so all pages are written to disk and the full notation record appears in my library immediately.

###### Acceptance Criteria

- [ ] &#34;Save&#34; button on metadata form triggers save pipeline
- [ ] All pages written to disk via SVC2 before DB record created (atomic: if any write fails, none committed)
- [ ] Notation record + page records + tags + custom field values written in a Drift transaction
- [ ] On success: navigation pops to Library; new notation appears at top of list
- [ ] On failure: error snackbar shown; no partial data persisted; temp files cleaned up
- [ ] Page reorder and delete within session reflected in final page index ordering
- [ ] Unit and widget tests at ≥ 80% coverage

###### Definition of Done

- [ ] Implementation complete
- [ ] Unit tests added (80%+ coverage on new code)
- [ ] `dart format` + `flutter analyze` pass
- [ ] Code review: no CRITICAL or HIGH issues
- [ ] PR opened, linked to this issue

###### References

- [Feature DAG — §3.2 Features](./docs/02-technical/feature-dag.md#32-features)
- [Data Model](./docs/02-technical/data-model.md)
- [SDS — Architecture Overview](./docs/02-technical/sds.md)


---

## Epic #9 — Notation Management

**Priority:** P0 | **GitHub:** [#9](https://github.com/Roudranil/swaralipi-app/issues/9)

### Goal

Give the musician full CRUD control over their notation library — editing metadata, duplicating entries, soft-deleting with a recoverable trash, and auto-purging stale deletions after 30 days.

### Scope

- F08 (Edit / Delete / Copy): Edit metadata, duplicate a notation (copies image files), soft-delete from Library and Detail View
- F09 (Trash): List soft-deleted notations; restore or permanently purge; auto-purge after 30 days

### Out of Scope

- Hard (immediate) deletion without trash
- Bulk operations in this epic

### Acceptance Criteria

- [ ] Editing a notation updates all 13 metadata fields and reflects changes immediately in the UI
- [ ] Duplicating a notation creates a new record with copies of all image files
- [ ] Deleting a notation moves it to Trash; it does not appear in the Library
- [ ] Trash screen lists all soft-deleted notations with deletion date
- [ ] User can restore a notation from Trash; it reappears in the Library
- [ ] User can permanently purge a single notation or all notations in Trash
- [ ] Notations older than 30 days in Trash are automatically purged
- [ ] All new code has ≥ 80% unit/widget test coverage

### Notes

Depends on Epic 1 (Infrastructure) and Epic 2 (Capture & Metadata). F09 (Trash) must be complete before F08 (Edit/Delete/Copy) because delete requires a trash destination. Entry points exist in both Library and Detail View screens.

### Feature #20 — F09 — Trash

**Priority:** P1 | **GitHub:** [#20](https://github.com/Roudranil/swaralipi-app/issues/20)

#### Goal

Provide a recoverable trash for soft-deleted notations, with restore, manual purge, and automatic 30-day expiry.

#### Scope

- Trash screen: list soft-deleted notations with deletion date
- Restore action: move notation back to Library
- Manual purge: permanently delete a single notation or all trash items
- Auto-purge: background task purges notations older than 30 days
- Purged notations remove image files via SVC2

#### Out of Scope

- Hard (immediate) deletion without trash
- Bulk restore

#### Acceptance Criteria

- [ ] Trash screen lists all soft-deleted notations with their deletion date
- [ ] Restore moves the notation back to the Library and removes it from Trash
- [ ] Manual purge permanently deletes selected notation(s) and their image files
- [ ] Auto-purge runs on app launch and removes entries older than 30 days
- [ ] Unit and widget tests at ≥ 80% coverage on new code
- [ ] `flutter analyze` passes with zero warnings

#### Notes

Branch. Complexity S / Risk Low. Depends on SVC1 and SVC2. Must complete before F08 (delete action requires a Trash destination).

#### Stories

| # | Title | Priority |
|---|-------|----------|
| [#40](https://github.com/Roudranil/swaralipi-app/issues/40) | F09-1: Trash screen — list, restore, purge, auto-purge after 30 days | P1 |

##### Story #40 — F09-1: Trash screen — list, restore, purge, auto-purge after 30 days

**Priority:** P1 | **GitHub:** [#40](https://github.com/Roudranil/swaralipi-app/issues/40)

###### User Story

As a musician, I want a Trash screen where I can see deleted notations, restore them, or permanently purge them so I never accidentally lose work.

###### Acceptance Criteria

- [ ] Trash screen lists soft-deleted notations with name and deletion date, ordered by deletion date descending
- [ ] Restore action clears `deletedAt`; notation reappears in Library immediately
- [ ] Purge single: permanently deletes DB record and image files via SVC2
- [ ] Purge all: clears entire Trash in one action with confirmation dialog
- [ ] Auto-purge runs on app launch: deletes all records where `deletedAt` < now − 30 days
- [ ] Empty state shown when Trash is empty
- [ ] Unit and widget tests at ≥ 80% coverage

###### Definition of Done

- [ ] Implementation complete
- [ ] Unit tests added (80%+ coverage on new code)
- [ ] `dart format` + `flutter analyze` pass
- [ ] Code review: no CRITICAL or HIGH issues
- [ ] PR opened, linked to this issue

###### References

- [Feature DAG — §3.2 Features](./docs/02-technical/feature-dag.md#32-features)
- [Data Model](./docs/02-technical/data-model.md)
- [Feature DAG — §4 Dependency Table](./docs/02-technical/feature-dag.md#4-dependency-table)


### Feature #24 — F08 — Edit / Delete / Copy

**Priority:** P1 | **GitHub:** [#24](https://github.com/Roudranil/swaralipi-app/issues/24)

#### Goal

Provide entry points from both Library and Detail View to edit metadata, duplicate notations with file copies, and soft-delete notations to Trash.

#### Scope

- Edit: re-enter F02 metadata form (and optionally page editor) from Library/Detail View
- Duplicate: copy all image files via SVC2; create new DB record with copied metadata; open in edit mode
- Soft-delete: set `deletedAt` timestamp; remove from Library list; move to Trash
- Entry points: long-press on Library card, action buttons on Detail View

#### Out of Scope

- Hard deletion (handled in F09 Trash purge)
- Bulk operations

#### Acceptance Criteria

- [ ] Edit opens the metadata form pre-populated with existing values
- [ ] Saving an edit updates the DB record and reflects immediately in Library and Detail View
- [ ] Duplicate creates a new notation with copied files; original is unmodified
- [ ] Delete soft-deletes the notation; it disappears from Library and appears in Trash
- [ ] Unit and widget tests at ≥ 80% coverage on new code
- [ ] `flutter analyze` passes with zero warnings

#### Notes

Branch. Complexity M / Risk Medium. Depends on F01 (capture flow reused for edit) and F09 (trash destination for delete). Multi-entry-point design requires careful navigation state management.

#### Stories

| # | Title | Priority |
|---|-------|----------|
| [#50](https://github.com/Roudranil/swaralipi-app/issues/50) | F08-1: Edit notation — re-enter metadata form and page editor | P1 |
| [#51](https://github.com/Roudranil/swaralipi-app/issues/51) | F08-2: Duplicate notation — copy files and create new DB record | P1 |
| [#52](https://github.com/Roudranil/swaralipi-app/issues/52) | F08-3: Soft-delete — move notation to Trash from Library and Detail View | P1 |

##### Story #50 — F08-1: Edit notation — re-enter metadata form and page editor

**Priority:** P1 | **GitHub:** [#50](https://github.com/Roudranil/swaralipi-app/issues/50)

###### User Story

As a musician, I want to edit a notation&#39;s metadata and pages from the Library or Detail View so I can correct mistakes or update information.

###### Acceptance Criteria

- [ ] Edit action accessible from: Library card long-press menu, Detail View action button
- [ ] Metadata form pre-populated with existing notation values on open
- [ ] Saving updates DB record via MetadataRepository.updateNotation
- [ ] Changes reflected immediately in Library list and Detail View after save
- [ ] Page editor accessible within the edit flow; RenderParams updates persisted on save
- [ ] Unit and widget tests at ≥ 80% coverage

###### Definition of Done

- [ ] Implementation complete
- [ ] Unit tests added (80%+ coverage on new code)
- [ ] `dart format` + `flutter analyze` pass
- [ ] Code review: no CRITICAL or HIGH issues
- [ ] PR opened, linked to this issue

###### References

- [Feature DAG — §3.2 Features](./docs/02-technical/feature-dag.md#32-features)
- [Feature DAG — §4 Dependency Table](./docs/02-technical/feature-dag.md#4-dependency-table)
- [SDS — Architecture Overview](./docs/02-technical/sds.md)


##### Story #51 — F08-2: Duplicate notation — copy files and create new DB record

**Priority:** P1 | **GitHub:** [#51](https://github.com/Roudranil/swaralipi-app/issues/51)

###### User Story

As a musician, I want to duplicate a notation so I can create a variation without modifying the original.

###### Acceptance Criteria

- [ ] Duplicate action accessible from Library card long-press menu
- [ ] All image files copied to a new UUID directory via SVC2
- [ ] New DB record created with copied metadata; title suffixed with &#34; (copy)&#34;
- [ ] Original notation is unmodified after duplicate
- [ ] New notation appears immediately in Library
- [ ] On file copy failure: partial files cleaned up; error shown; no DB record created
- [ ] Unit tests at ≥ 80% coverage

###### Definition of Done

- [ ] Implementation complete
- [ ] Unit tests added (80%+ coverage on new code)
- [ ] `dart format` + `flutter analyze` pass
- [ ] Code review: no CRITICAL or HIGH issues
- [ ] PR opened, linked to this issue

###### References

- [Feature DAG — §3.2 Features](./docs/02-technical/feature-dag.md#32-features)
- [Feature DAG — §4 Dependency Table](./docs/02-technical/feature-dag.md#4-dependency-table)
- [SDS — Architecture Overview](./docs/02-technical/sds.md)


##### Story #52 — F08-3: Soft-delete — move notation to Trash from Library and Detail View

**Priority:** P1 | **GitHub:** [#52](https://github.com/Roudranil/swaralipi-app/issues/52)

###### User Story

As a musician, I want to delete a notation and have it go to Trash so I can recover it if I change my mind.

###### Acceptance Criteria

- [ ] Delete action accessible from: Library card long-press menu, Detail View delete button
- [ ] Delete sets `deletedAt` timestamp; notation removed from Library list immediately
- [ ] Deleted notation appears in Trash screen (F09)
- [ ] Confirmation dialog shown before delete action executes
- [ ] Navigation from Detail View returns to Library after delete
- [ ] Unit and widget tests at ≥ 80% coverage

###### Definition of Done

- [ ] Implementation complete
- [ ] Unit tests added (80%+ coverage on new code)
- [ ] `dart format` + `flutter analyze` pass
- [ ] Code review: no CRITICAL or HIGH issues
- [ ] PR opened, linked to this issue

###### References

- [Feature DAG — §3.2 Features](./docs/02-technical/feature-dag.md#32-features)
- [Feature DAG — §4 Dependency Table](./docs/02-technical/feature-dag.md#4-dependency-table)
- [Data Model](./docs/02-technical/data-model.md)


---

## Epic #10 — Notation Viewing & Playback

**Priority:** P1 | **GitHub:** [#10](https://github.com/Roudranil/swaralipi-app/issues/10)

### Goal

Enable the musician to view notation metadata at a glance and play through full-screen notation pages hands-free while practising.

### Scope

- F04 (Notation Detail View): Read-only single-notation view showing metadata block, page thumbnails, and action buttons (play, edit, delete)
- F05 (Notation Player): Full-screen image viewer with swipe-between-pages, pinch-zoom, portrait/landscape orientation lock, auto-scroll at configurable speed, and fade-chrome on interaction

### Out of Scope

- Audio playback or recording
- Annotation or mark-up on notation images

### Acceptance Criteria

- [ ] Detail View shows all 13 metadata fields and page thumbnails in a scrollable layout
- [ ] Tapping Play opens the full-screen player at the first page
- [ ] Player supports swipe-left/right to navigate pages
- [ ] Player supports pinch-zoom on individual pages
- [ ] Orientation can be locked to portrait or landscape from within the player
- [ ] Auto-scroll speed is configurable and persists across sessions
- [ ] Chrome (UI controls) fades after inactivity and reappears on tap
- [ ] All new code has ≥ 80% unit/widget test coverage

### Notes

F04 depends on Epic 3 (Management). F05 depends on SVC3 (ImageProcessingService) being complete. Pinch-zoom and orientation lock are Medium-risk; test on real Samsung Galaxy S25 hardware.

### Feature #23 — F05 — Notation Player

**Priority:** P1 | **GitHub:** [#23](https://github.com/Roudranil/swaralipi-app/issues/23)

#### Goal

Deliver a full-screen notation viewer with swipe navigation, pinch-zoom, orientation lock, auto-scroll, and chrome fade so the musician can play through pages hands-free.

#### Scope

- Full-screen page viewer: swipe left/right between pages
- Pinch-zoom on individual pages using InteractiveViewer
- Orientation lock: toggle portrait/landscape within the player
- Chrome fade: UI controls fade after inactivity, reappear on tap
- Auto-scroll: configurable speed (px/s), start/stop toggle
- Auto-scroll speed persisted to UserPreferences

#### Out of Scope

- Audio playback or recording
- Annotation/markup on pages
- Page reordering within the player

#### Acceptance Criteria

- [ ] Swipe navigates between all pages of the notation
- [ ] Pinch-zoom works on each page independently
- [ ] Orientation locks correctly without losing current page position
- [ ] Chrome fades after 3 seconds of inactivity; single tap restores it
- [ ] Auto-scroll scrolls continuously at the configured speed
- [ ] Speed preference persists across app restarts
- [ ] Unit and widget tests at ≥ 80% coverage on new code
- [ ] `flutter analyze` passes with zero warnings

#### Notes

Branch. Complexity L / Risk Medium. Depends on SVC1, SVC2, SVC3. Test pinch-zoom and orientation lock on real Samsung Galaxy S25 hardware.

#### Stories

| # | Title | Priority |
|---|-------|----------|
| [#53](https://github.com/Roudranil/swaralipi-app/issues/53) | F05-1: Full-screen viewer — swipe between pages and pinch-zoom | P1 |
| [#54](https://github.com/Roudranil/swaralipi-app/issues/54) | F05-2: Orientation lock and chrome fade on inactivity | P1 |
| [#55](https://github.com/Roudranil/swaralipi-app/issues/55) | F05-3: Auto-scroll at configurable speed with persisted preference | P1 |

##### Story #53 — F05-1: Full-screen viewer — swipe between pages and pinch-zoom

**Priority:** P1 | **GitHub:** [#53](https://github.com/Roudranil/swaralipi-app/issues/53)

###### User Story

As a musician, I want to view notation pages full-screen and swipe between them or zoom in so I can read the notation clearly while playing.

###### Acceptance Criteria

- [ ] Full-screen player opens at the correct start page (passed by caller)
- [ ] Swipe left/right navigates between pages; page indicator (e.g., &#34;2 / 5&#34;) visible
- [ ] `InteractiveViewer` enables pinch-zoom on each page independently; double-tap to reset zoom
- [ ] Pages rendered via SVC3 with their stored `RenderParams`
- [ ] Images loaded via SVC2 path resolution; loading placeholder shown while decoding
- [ ] Unit and widget tests at ≥ 80% coverage

###### Definition of Done

- [ ] Implementation complete
- [ ] Unit tests added (80%+ coverage on new code)
- [ ] `dart format` + `flutter analyze` pass
- [ ] Code review: no CRITICAL or HIGH issues
- [ ] PR opened, linked to this issue

###### References

- [Feature DAG — §3.2 Features](./docs/02-technical/feature-dag.md#32-features)
- [Feature DAG — §4 Dependency Table](./docs/02-technical/feature-dag.md#4-dependency-table)
- [SDS — Architecture Overview](./docs/02-technical/sds.md)


##### Story #54 — F05-2: Orientation lock and chrome fade on inactivity

**Priority:** P1 | **GitHub:** [#54](https://github.com/Roudranil/swaralipi-app/issues/54)

###### User Story

As a musician, I want to lock the screen orientation and have player controls fade away after a few seconds so the notation takes up the full screen without distractions.

###### Acceptance Criteria

- [ ] Orientation lock toggle in player chrome: Portrait / Landscape / Auto
- [ ] Lock applied via `SystemChrome.setPreferredOrientations`; persists until player is closed
- [ ] Chrome (page indicator, orientation button, auto-scroll controls) fades after 3 seconds of inactivity
- [ ] Single tap on the screen restores chrome; tap does not advance page
- [ ] Orientation lock state preserved across page swipes
- [ ] Unit and widget tests at ≥ 80% coverage

###### Definition of Done

- [ ] Implementation complete
- [ ] Unit tests added (80%+ coverage on new code)
- [ ] `dart format` + `flutter analyze` pass
- [ ] Code review: no CRITICAL or HIGH issues
- [ ] PR opened, linked to this issue

###### References

- [Feature DAG — §3.2 Features](./docs/02-technical/feature-dag.md#32-features)
- [SDS — Architecture Overview](./docs/02-technical/sds.md)


##### Story #55 — F05-3: Auto-scroll at configurable speed with persisted preference

**Priority:** P1 | **GitHub:** [#55](https://github.com/Roudranil/swaralipi-app/issues/55)

###### User Story

As a musician, I want the notation page to scroll automatically at a speed I set so I can follow along hands-free while playing.

###### Acceptance Criteria

- [ ] Auto-scroll start/stop button in player chrome
- [ ] Speed slider (range: slow to fast, in px/s) shown when chrome is visible
- [ ] Scrolling is smooth (`ScrollController` animation, not jumpy)
- [ ] Speed preference persisted to UserPreferences; restored on next player open
- [ ] Auto-scroll stops automatically when last page is fully scrolled
- [ ] Unit and widget tests at ≥ 80% coverage

###### Definition of Done

- [ ] Implementation complete
- [ ] Unit tests added (80%+ coverage on new code)
- [ ] `dart format` + `flutter analyze` pass
- [ ] Code review: no CRITICAL or HIGH issues
- [ ] PR opened, linked to this issue

###### References

- [Feature DAG — §3.2 Features](./docs/02-technical/feature-dag.md#32-features)
- [Data Model](./docs/02-technical/data-model.md)
- [SDS — Architecture Overview](./docs/02-technical/sds.md)


### Feature #26 — F04 — Notation Detail View

**Priority:** P1 | **GitHub:** [#26](https://github.com/Roudranil/swaralipi-app/issues/26)

#### Goal

Provide a read-only single-notation detail screen showing the full metadata block, page thumbnails, and action buttons for Play, Edit, and Delete.

#### Scope

- Full metadata display: all 13 standard fields + any custom fields
- Page thumbnail row (horizontal scroll)
- Action buttons: Play (launches F05), Edit (launches F08 edit flow), Delete (triggers F08 soft-delete)
- Loads notation record from DB via SVC1

#### Out of Scope

- Inline metadata editing (done via F08 → F02 form)
- Audio playback

#### Acceptance Criteria

- [ ] All 13 metadata fields display correctly with appropriate formatting
- [ ] Custom field values render below standard fields
- [ ] Page thumbnails are displayed in order; tapping one opens the player at that page
- [ ] Play button opens F05 at page 1
- [ ] Edit button navigates to F08 edit flow
- [ ] Delete button triggers soft-delete and navigates back to Library
- [ ] Unit and widget tests at ≥ 80% coverage on new code
- [ ] `flutter analyze` passes with zero warnings

#### Notes

Trunk. Complexity S / Risk Low. Depends on SVC1, F08, F05. Read-only screen with thin ViewModel — straightforward to implement once F05 and F08 are done.

#### Stories

| # | Title | Priority |
|---|-------|----------|
| [#56](https://github.com/Roudranil/swaralipi-app/issues/56) | F04-1: Read-only detail screen — metadata block, thumbnails, and action buttons | P1 |

##### Story #56 — F04-1: Read-only detail screen — metadata block, thumbnails, and action buttons

**Priority:** P1 | **GitHub:** [#56](https://github.com/Roudranil/swaralipi-app/issues/56)

###### User Story

As a musician, I want a detail screen that shows all notation metadata, page thumbnails, and action buttons so I can review a notation and decide what to do with it.

###### Acceptance Criteria

- [ ] Detail screen shows: title, artists, date, time signature, key signature, language, tags (chips), instruments (chips), notes, custom field values
- [ ] Horizontal scrolling page thumbnail row; tapping opens player at that page index
- [ ] Play button opens F05 at page 1
- [ ] Edit button navigates to F08 edit flow, pre-populated
- [ ] Delete button triggers F08 soft-delete with confirmation dialog; navigates back to Library on confirm
- [ ] Screen loads notation from DB via MetadataRepository.loadNotation
- [ ] Unit and widget tests at ≥ 80% coverage

###### Definition of Done

- [ ] Implementation complete
- [ ] Unit tests added (80%+ coverage on new code)
- [ ] `dart format` + `flutter analyze` pass
- [ ] Code review: no CRITICAL or HIGH issues
- [ ] PR opened, linked to this issue

###### References

- [Feature DAG — §3.2 Features](./docs/02-technical/feature-dag.md#32-features)
- [Feature DAG — §4 Dependency Table](./docs/02-technical/feature-dag.md#4-dependency-table)
- [SDS — Architecture Overview](./docs/02-technical/sds.md)


---

## Epic #11 — Library & Search

**Priority:** P0 | **GitHub:** [#11](https://github.com/Roudranil/swaralipi-app/issues/11)

### Goal

Surface the full notation library through an intuitive home screen with a recently-played carousel, fuzzy full-text search, sort options, and tag-based filtering so the musician can find any piece in seconds.

### Scope

- F03 (Library): Home screen — recently-played carousel (last 5 played), notation list with fuzzy search, sort (date, title, artist), and tag filter panel

### Out of Scope

- Saved search presets
- Cross-field advanced query builder

### Acceptance Criteria

- [ ] Home screen displays a recently-played carousel showing the last 5 notations opened
- [ ] Full notation list supports fuzzy search across title, artist, and notes fields
- [ ] User can sort the list by date created, date modified, title, and artist
- [ ] User can filter the list by one or more tags simultaneously
- [ ] Search and filter state is preserved when navigating away and returning
- [ ] List uses `ListView.builder` and is performant with 500+ items
- [ ] All new code has ≥ 80% unit/widget test coverage

### Notes

Depends on Epic 1 (SVC4/SearchService), Epic 2 (F01/F02), and Epic 3 (F08/F09). This is the final home screen — it is last on the critical path but the primary day-to-day entry point for the app.

### Feature #27 — F03 — Library

**Priority:** P0 | **GitHub:** [#27](https://github.com/Roudranil/swaralipi-app/issues/27)

#### Goal

Deliver the app&#39;s home screen with a recently-played carousel, a full notation list with sort and tag filter, and a fuzzy full-text search bar so the musician can find any piece in seconds.

#### Scope

- Recently-played carousel: horizontal scroll of last 5 opened notations
- Notation list: `ListView.builder`, sort by date created, date modified, title, artist
- Tag filter panel: multi-tag selection narrows the list
- Fuzzy search bar: delegates to SVC4 SearchService
- Search + filter state preserved on back-navigation
- Empty state and loading state handling

#### Out of Scope

- Saved search presets
- Advanced cross-field query builder

#### Acceptance Criteria

- [ ] Recently-played carousel shows the last 5 opened notations in order
- [ ] List is performant with 500+ notation records (`ListView.builder`)
- [ ] Sort by date created, date modified, title, and artist works correctly
- [ ] Tag filter narrows results to notations matching all selected tags
- [ ] Fuzzy search returns ranked results via SVC4
- [ ] Search and filter state is preserved when navigating away and returning
- [ ] Unit and widget tests at ≥ 80% coverage on new code
- [ ] `flutter analyze` passes with zero warnings

#### Notes

Trunk. Complexity L / Risk Medium. Depends on SVC4, F01, F07, F08, F04. Final home screen — last on the critical path but the primary day-to-day entry point for the app.

#### Stories

| # | Title | Priority |
|---|-------|----------|
| [#57](https://github.com/Roudranil/swaralipi-app/issues/57) | F03-1: Recently-played carousel and notation list with sort | P0 |
| [#58](https://github.com/Roudranil/swaralipi-app/issues/58) | F03-2: Fuzzy search bar with real-time results | P1 |
| [#59](https://github.com/Roudranil/swaralipi-app/issues/59) | F03-3: Tag filter panel with multi-select chips | P1 |

##### Story #57 — F03-1: Recently-played carousel and notation list with sort

**Priority:** P0 | **GitHub:** [#57](https://github.com/Roudranil/swaralipi-app/issues/57)

###### User Story

As a musician, I want a home screen that shows my recently-opened notations at the top and a full sortable list below so I can quickly pick up where I left off.

###### Acceptance Criteria

- [ ] Recently-played carousel: horizontal scroll of last 5 opened notations; tapping opens Detail View
- [ ] `lastOpenedAt` timestamp updated on each Detail View / Player open
- [ ] Notation list uses `ListView.builder`; performant with 500+ items
- [ ] Sort options: date created (desc), date modified (desc), title (asc), artist (asc)
- [ ] Sort preference persisted; restored on return to Library
- [ ] Empty state shown when no notations exist
- [ ] Unit and widget tests at ≥ 80% coverage

###### Definition of Done

- [ ] Implementation complete
- [ ] Unit tests added (80%+ coverage on new code)
- [ ] `dart format` + `flutter analyze` pass
- [ ] Code review: no CRITICAL or HIGH issues
- [ ] PR opened, linked to this issue

###### References

- [Feature DAG — §3.2 Features](./docs/02-technical/feature-dag.md#32-features)
- [Feature DAG — §4 Dependency Table](./docs/02-technical/feature-dag.md#4-dependency-table)
- [SDS — Architecture Overview](./docs/02-technical/sds.md)


##### Story #58 — F03-2: Fuzzy search bar with real-time results

**Priority:** P1 | **GitHub:** [#58](https://github.com/Roudranil/swaralipi-app/issues/58)

###### User Story

As a musician, I want to type a search query and see matching notations highlighted in real time so that I can quickly locate a piece without scrolling.

###### Acceptance Criteria

- [ ] Search bar appears at the top of the library screen with a clear affordance
- [ ] Debounced input (300 ms) triggers fuzzy search via the repository
- [ ] Matching notation titles and artist names are highlighted in results
- [ ] Empty-state message is shown when no results match
- [ ] Clearing the search bar restores the full notation list

###### Definition of Done

- [ ] Unit tests covering all ACs (80%+ coverage on new files)
- [ ] Widget tests for the search bar and results rendering
- [ ] `dart format` passes
- [ ] `flutter analyze` — zero warnings
- [ ] Code review: no CRITICAL or HIGH issues
- [ ] PR opened against main, linked to this issue

###### References

- [UX Flows — Library & Search Screen](./docs/02-technical/ux-flows.md#library--search-screen)
- [SDS — Full-Text Search (FTS5)](./docs/02-technical/sds.md#full-text-search-fts5)
- [Data Model — NotationSearchIndex](./docs/02-technical/data-model.md#notationsearchindex)


##### Story #59 — F03-3: Tag filter panel with multi-select chips

**Priority:** P1 | **GitHub:** [#59](https://github.com/Roudranil/swaralipi-app/issues/59)

###### User Story

As a musician, I want to filter my library by one or more tags so that I can browse only the notations that belong to a given category or mood.

###### Acceptance Criteria

- [ ] A filter panel (bottom sheet or expandable bar) shows all existing tags as chips
- [ ] Multiple tags can be selected simultaneously; results narrow on each selection
- [ ] Active filter chips are visually distinct from inactive ones
- [ ] Clearing all chips restores the unfiltered list
- [ ] Tag filter composes correctly with the fuzzy search bar (both active simultaneously)

###### Definition of Done

- [ ] Unit tests covering all ACs (80%+ coverage on new files)
- [ ] Widget tests for the filter panel, chip states, and combined search+filter
- [ ] `dart format` passes
- [ ] `flutter analyze` — zero warnings
- [ ] Code review: no CRITICAL or HIGH issues
- [ ] PR opened against main, linked to this issue

###### References

- [UX Flows — Library & Search Screen](./docs/02-technical/ux-flows.md#library--search-screen)
- [SDS — Tag Filtering](./docs/02-technical/sds.md#tag-filtering)
- [Data Model — Tag entity](./docs/02-technical/data-model.md#tag)


---

## Epic #12 — User Experience & Settings

**Priority:** P1 | **GitHub:** [#12](https://github.com/Roudranil/swaralipi-app/issues/12)

### Goal

Give the musician control over their instrument inventory, visual theme preferences, and app-wide settings from a single cohesive Settings shell.

### Scope

- F06 (Instrument Tracker): Two-level CRUD — InstrumentClass and InstrumentInstance; photo capture per instrument; soft-delete archive
- F10 (Appearance & Theming): Light / Dark / System toggle; Dynamic Monet or Catppuccin seed-color picker; persisted preference
- F11 (Settings shell): Top-level Settings screen aggregating Tags, Instruments, Trash, Appearance, Custom Fields, and app info sections

### Out of Scope

- Notification or reminder settings
- Export or backup settings

### Acceptance Criteria

- [ ] User can create, edit, and archive InstrumentClass entries (e.g., &#34;Sitar&#34;)
- [ ] User can add, edit, and archive InstrumentInstance entries under a class (e.g., &#34;Ravi Shankar Sitar — Model X&#34;)
- [ ] Each InstrumentInstance can have a photo captured in-app or imported from gallery
- [ ] Appearance toggle switches between Light, Dark, and System-default themes immediately
- [ ] Seed-color picker applies the selected Catppuccin palette or Monet dynamic color across the app
- [ ] Settings shell lists all sub-sections and navigates to each correctly
- [ ] All preferences persist across app restarts
- [ ] All new code has ≥ 80% unit/widget test coverage

### Notes

F06 and F10 are parallelisable branch work — both unblock after SVC1 completes. F11 is the shell that wires them together and depends on F07 (Tags), F06, F09 (Trash), and F10 all being done.

### Feature #18 — F12 — Custom Fields

**Priority:** P2 | **GitHub:** [#18](https://github.com/Roudranil/swaralipi-app/issues/18)

#### Goal

Allow the musician to define custom metadata fields (name + type) that appear in the notation metadata form.

#### Scope

- Custom field definition CRUD: create, rename, change type, delete
- Supported types: text, number, date
- Field definitions surfaced as additional inputs in the F02 metadata form
- Custom Fields screen in Settings

#### Out of Scope

- Rendering custom field values in search/filter (out of scope for this feature)
- Complex field types (checkboxes, multi-select, etc.)

#### Acceptance Criteria

- [ ] User can create a custom field with a name and type
- [ ] User can rename, change type, and delete a custom field definition
- [ ] Custom fields appear as additional inputs in the metadata form
- [ ] Deleting a definition removes values from all existing notations
- [ ] Unit and widget tests at ≥ 80% coverage on new code
- [ ] `flutter analyze` passes with zero warnings

#### Notes

Branch. Complexity S / Risk Low. Depends on SVC1. Must complete before F02 (metadata form embeds custom field inputs).

#### Stories

| # | Title | Priority |
|---|-------|----------|
| [#38](https://github.com/Roudranil/swaralipi-app/issues/38) | F12-1: Custom field definition CRUD surfaced in metadata form | P2 |

##### Story #38 — F12-1: Custom field definition CRUD surfaced in metadata form

**Priority:** P2 | **GitHub:** [#38](https://github.com/Roudranil/swaralipi-app/issues/38)

###### User Story

As a musician, I want to define my own metadata fields (name + type) so the notation form captures information specific to my practice.

###### Acceptance Criteria

- [ ] Custom Fields screen lists all defined field definitions
- [ ] Create field: name + type (text / number / date) saved via CustomFieldDao
- [ ] Rename and change type: updates definition; existing values remain (type coercion handled gracefully)
- [ ] Delete field: removes definition and all associated CustomFieldValues from DB
- [ ] Field definitions appear as additional form inputs in the metadata form (F02)
- [ ] Unit and widget tests at ≥ 80% coverage

###### Definition of Done

- [ ] Implementation complete
- [ ] Unit tests added (80%+ coverage on new code)
- [ ] `dart format` + `flutter analyze` pass
- [ ] Code review: no CRITICAL or HIGH issues
- [ ] PR opened, linked to this issue

###### References

- [Feature DAG — §3.2 Features](./docs/02-technical/feature-dag.md#32-features)
- [Data Model](./docs/02-technical/data-model.md)
- [Feature DAG — §4 Dependency Table](./docs/02-technical/feature-dag.md#4-dependency-table)


### Feature #19 — F10 — Appearance & Theming

**Priority:** P2 | **GitHub:** [#19](https://github.com/Roudranil/swaralipi-app/issues/19)

#### Goal

Give the musician control over the app&#39;s visual theme with Light/Dark/System toggle and a choice between Monet dynamic color or Catppuccin seed color, persisted across sessions.

#### Scope

- Light / Dark / System theme toggle
- Seed color picker: Dynamic Monet (Android 12+) or Catppuccin palette
- Theme preference persisted to UserPreferences via SVC1
- Immediate theme rebuild on selection without app restart

#### Out of Scope

- Font size or density settings
- Per-screen color overrides

#### Acceptance Criteria

- [ ] Switching between Light, Dark, and System modes applies immediately
- [ ] Selecting a Catppuccin seed color rebuilds the app&#39;s ColorScheme immediately
- [ ] On Android 12+, Dynamic Monet color is available as an option
- [ ] Theme preference persists across app restarts
- [ ] Unit and widget tests at ≥ 80% coverage on new code
- [ ] `flutter analyze` passes with zero warnings

#### Notes

Branch. Complexity S / Risk Low. Depends on SVC1 (UserPreferences table). Can be built in parallel with F06, F12, F09.

#### Stories

| # | Title | Priority |
|---|-------|----------|
| [#39](https://github.com/Roudranil/swaralipi-app/issues/39) | F10-1: Light/Dark/System toggle and Catppuccin/Monet seed-color picker | P2 |

##### Story #39 — F10-1: Light/Dark/System toggle and Catppuccin/Monet seed-color picker

**Priority:** P2 | **GitHub:** [#39](https://github.com/Roudranil/swaralipi-app/issues/39)

###### User Story

As a musician, I want to switch between Light, Dark, and System themes and pick a seed color so the app matches my visual preference.

###### Acceptance Criteria

- [ ] Appearance screen shows Light / Dark / System toggle segment buttons
- [ ] Switching theme mode rebuilds `MaterialApp` immediately without restart
- [ ] Catppuccin palette color picker shows all Mocha swatches; selecting one updates `ColorScheme.fromSeed`
- [ ] On Android 12+, Dynamic Monet option appears and uses `dynamicColorScheme`
- [ ] Preference (mode + seed) persisted to UserPreferences via UserPreferencesDao
- [ ] Preference loaded on app startup before first frame
- [ ] Unit and widget tests at ≥ 80% coverage

###### Definition of Done

- [ ] Implementation complete
- [ ] Unit tests added (80%+ coverage on new code)
- [ ] `dart format` + `flutter analyze` pass
- [ ] Code review: no CRITICAL or HIGH issues
- [ ] PR opened, linked to this issue

###### References

- [Feature DAG — §3.2 Features](./docs/02-technical/feature-dag.md#32-features)
- [Feature DAG — §4 Dependency Table](./docs/02-technical/feature-dag.md#4-dependency-table)
- [Data Model](./docs/02-technical/data-model.md)


### Feature #21 — F06 — Instrument Tracker

**Priority:** P2 | **GitHub:** [#21](https://github.com/Roudranil/swaralipi-app/issues/21)

#### Goal

Allow the musician to maintain a two-level instrument inventory (InstrumentClass + InstrumentInstance) with optional photos and soft-delete archiving.

#### Scope

- InstrumentClass CRUD: create, edit, archive (soft-delete)
- InstrumentInstance CRUD: create, edit, archive; linked to an InstrumentClass
- In-app camera capture or gallery import for InstrumentInstance photo
- Instrument list screens in Settings

#### Out of Scope

- Instrument assignment to notations (handled in F02 metadata form)
- Hard deletion of instruments

#### Acceptance Criteria

- [ ] User can create, edit, and archive InstrumentClass entries
- [ ] User can create, edit, and archive InstrumentInstance entries under a class
- [ ] Each InstrumentInstance can have a photo captured in-app or imported from gallery
- [ ] Archived instruments do not appear in the active instrument picker
- [ ] Unit and widget tests at ≥ 80% coverage on new code
- [ ] `flutter analyze` passes with zero warnings

#### Notes

Branch. Complexity M / Risk Low. Depends on SVC1 and SVC2. Must complete before F02 (metadata form embeds instrument picker).

#### Stories

| # | Title | Priority |
|---|-------|----------|
| [#41](https://github.com/Roudranil/swaralipi-app/issues/41) | F06-1: InstrumentClass CRUD with archive | P2 |
| [#42](https://github.com/Roudranil/swaralipi-app/issues/42) | F06-2: InstrumentInstance CRUD with photo capture and archive | P2 |

##### Story #41 — F06-1: InstrumentClass CRUD with archive

**Priority:** P2 | **GitHub:** [#41](https://github.com/Roudranil/swaralipi-app/issues/41)

###### User Story

As a musician, I want to create, edit, and archive instrument classes (e.g., &#34;Sitar&#34;) so I can organise my instrument inventory by type.

###### Acceptance Criteria

- [ ] Instrument Classes screen lists all active classes with name and instance count
- [ ] Create class: name input saved via InstrumentDao
- [ ] Edit class: name updated in DB; reflected in UI immediately
- [ ] Archive class: sets `archivedAt`; class hidden from active list and instrument picker
- [ ] Archived classes visible in a separate &#34;Archived&#34; section
- [ ] Unit and widget tests at ≥ 80% coverage

###### Definition of Done

- [ ] Implementation complete
- [ ] Unit tests added (80%+ coverage on new code)
- [ ] `dart format` + `flutter analyze` pass
- [ ] Code review: no CRITICAL or HIGH issues
- [ ] PR opened, linked to this issue

###### References

- [Feature DAG — §3.2 Features](./docs/02-technical/feature-dag.md#32-features)
- [Data Model](./docs/02-technical/data-model.md)
- [Feature DAG — §4 Dependency Table](./docs/02-technical/feature-dag.md#4-dependency-table)


##### Story #42 — F06-2: InstrumentInstance CRUD with photo capture and archive

**Priority:** P2 | **GitHub:** [#42](https://github.com/Roudranil/swaralipi-app/issues/42)

###### User Story

As a musician, I want to add, edit, and archive specific instrument instances with photos so I can track each individual instrument I own.

###### Acceptance Criteria

- [ ] Instrument Instances screen lists all active instances under their class with thumbnail photo
- [ ] Create instance: name, class (picker), optional photo (camera or gallery) saved via InstrumentDao + SVC2
- [ ] Edit instance: name and photo updatable; old photo file removed when replaced
- [ ] Archive instance: sets `archivedAt`; hidden from active list and metadata form picker
- [ ] Photo capture uses system camera intent or `image_picker`; saved via SVC2
- [ ] Unit and widget tests at ≥ 80% coverage

###### Definition of Done

- [ ] Implementation complete
- [ ] Unit tests added (80%+ coverage on new code)
- [ ] `dart format` + `flutter analyze` pass
- [ ] Code review: no CRITICAL or HIGH issues
- [ ] PR opened, linked to this issue

###### References

- [Feature DAG — §3.2 Features](./docs/02-technical/feature-dag.md#32-features)
- [Data Model](./docs/02-technical/data-model.md)
- [Feature DAG — §4 Dependency Table](./docs/02-technical/feature-dag.md#4-dependency-table)


### Feature #28 — F11 — Settings

**Priority:** P2 | **GitHub:** [#28](https://github.com/Roudranil/swaralipi-app/issues/28)

#### Goal

Provide a top-level Settings shell screen that aggregates navigation to Tags, Instruments, Trash, Appearance, Custom Fields, and app info sections.

#### Scope

- Settings shell screen with list of sub-sections
- Navigation to: Tags (F07), Instruments (F06), Trash (F09), Appearance & Theming (F10), Custom Fields (F12)
- App info section: version number, build, open-source licenses
- Correct back-navigation from each sub-section

#### Out of Scope

- Any new logic in sub-sections (those are owned by their respective features)
- Notification or export settings

#### Acceptance Criteria

- [ ] Settings shell lists all sub-sections with correct icons and titles
- [ ] Each sub-section navigates correctly and back-navigates to the shell
- [ ] App info section shows current version and build number
- [ ] State in sub-sections (e.g., tag list) is preserved when returning to shell
- [ ] Unit and widget tests at ≥ 80% coverage on new code
- [ ] `flutter analyze` passes with zero warnings

#### Notes

Branch. Complexity M / Risk Low. Depends on F07, F06, F09, F10, F12 all being complete. Shell only — no new data logic.

#### Stories

| # | Title | Priority |
|---|-------|----------|
| [#60](https://github.com/Roudranil/swaralipi-app/issues/60) | F11-1: Settings shell screen with navigation to sub-sections | P2 |
| [#61](https://github.com/Roudranil/swaralipi-app/issues/61) | F11-2: Integrate all Settings sub-sections and verify navigation | P2 |

##### Story #60 — F11-1: Settings shell screen with navigation to sub-sections

**Priority:** P2 | **GitHub:** [#60](https://github.com/Roudranil/swaralipi-app/issues/60)

###### User Story

As a musician, I want a dedicated settings screen that lets me navigate to all configuration sub-sections (Tags, Instruments, Trash, Appearance, Custom Fields, app info) so that I can manage my app preferences from one place.

###### Acceptance Criteria

- [ ] Settings screen is reachable from the main navigation
- [ ] Screen lists all sub-section entries: Tags, Instruments, Trash, Appearance, Custom Fields, About
- [ ] Each entry navigates to its respective screen using `go_router`
- [ ] Back navigation returns to the Settings shell without losing scroll position

###### Definition of Done

- [ ] Unit tests covering all ACs (80%+ coverage on new files)
- [ ] Widget tests for the settings list and navigation
- [ ] `dart format` passes
- [ ] `flutter analyze` — zero warnings
- [ ] Code review: no CRITICAL or HIGH issues
- [ ] PR opened against main, linked to this issue

###### References

- [UX Flows — Settings Screen](./docs/02-technical/ux-flows.md#settings-screen)
- [SDS — Navigation & Routing](./docs/02-technical/sds.md#navigation--routing)


##### Story #61 — F11-2: Integrate all Settings sub-sections and verify navigation

**Priority:** P2 | **GitHub:** [#61](https://github.com/Roudranil/swaralipi-app/issues/61)

###### User Story

As a musician, I want every settings sub-section to be fully wired so that changes I make in Tags, Instruments, Appearance, Trash, Custom Fields, and About are immediately reflected throughout the app.

###### Acceptance Criteria

- [ ] Tags sub-section: create, rename, delete tags; changes reflected in notation forms
- [ ] Instruments sub-section: manage instrument list used as metadata field
- [ ] Trash sub-section: restore or permanently delete soft-deleted notations
- [ ] Appearance sub-section: toggle light/dark theme; change persists across restarts
- [ ] Custom Fields sub-section: add/remove/rename user-defined metadata fields
- [ ] About sub-section: displays app version and build number
- [ ] Navigation state is preserved when returning to the Settings shell

###### Definition of Done

- [ ] Unit tests covering all ACs (80%+ coverage on new files)
- [ ] Widget tests for each sub-section screen and state preservation
- [ ] `dart format` passes
- [ ] `flutter analyze` — zero warnings
- [ ] Code review: no CRITICAL or HIGH issues
- [ ] PR opened against main, linked to this issue

###### References

- [UX Flows — Settings Screen](./docs/02-technical/ux-flows.md#settings-screen)
- [Data Model — Tag, CustomField entities](./docs/02-technical/data-model.md#tag)
- [SDS — Settings & Persistence](./docs/02-technical/sds.md#settings--persistence)


---

## Epic #1 — Documentation

**Priority:** P1 | **GitHub:** [#1](https://github.com/Roudranil/swaralipi-app/issues/1)

### Goal

Establish foundational project documentation for Swaralipi including README, contributing guides, and technical specs.

### Scope

- [ ] #

### Out of Scope

API documentation, inline code comments (handled separately).

### Acceptance Criteria

- README exists and is current
- Documentation structure is discoverable

### Notes

Foundation for public-facing project information.

### Feature #2 — README

**Priority:** P1 | **GitHub:** [#2](https://github.com/Roudranil/swaralipi-app/issues/2)

#### Goal

Create comprehensive README that explains Swaralipi, its purpose, setup, and usage.

#### Acceptance Criteria

- README.md exists at root
- Covers project purpose, tech stack, device requirements
- Clear for new developers or users

#### Notes

Primary entry point for understanding the project.

