---
title: Swaralipi — Navigation Structure
version: 0.1.0
status: draft
owner: architect
date: 2026-04-23
---

# Swaralipi — Navigation Structure

## Table of Contents

1. [Navigation Architecture](#1-navigation-architecture)
2. [Route Registry](#2-route-registry)
3. [Shell Structure](#3-shell-structure)
4. [Route Definitions](#4-route-definitions)
   1. [ShellRoute — Bottom Nav](#41-shellroute--bottom-nav)
   2. [Library Branch](#42-library-branch)
   3. [Settings Branch](#43-settings-branch)
5. [Bottom Sheet Routes](#5-bottom-sheet-routes)
6. [Navigation Map Diagram](#6-navigation-map-diagram)
7. [Transition Animations](#7-transition-animations)
8. [State Persistence Rules](#8-state-persistence-rules)
9. [Error & Redirect Routes](#9-error--redirect-routes)

---

## 1. Navigation Architecture

**Router:** `go_router` v14.x
**Pattern:** Declarative path-based routing with `ShellRoute` for persistent bottom nav.

| Concern | Solution |
|---|---|
| Bottom nav persistence | `ShellRoute` wraps Library + Settings branches |
| Full-screen overlays (Player) | Top-level route outside `ShellRoute` — hides bottom nav |
| Bottom sheets (Capture entry) | Triggered via `showModalBottomSheet`; not a named route |
| Page Editor + Metadata | Full-screen routes; navigated via `context.go()` |
| Back stack | Platform back button handled by `go_router` automatically |

---

## 2. Route Registry

| Name | Path | Screen | In Shell |
|---|---|---|---|
| `library` | `/` | `LibraryScreen` | Yes |
| `notationDetail` | `/notation/:notationId` | `NotationDetailScreen` | Yes |
| `player` | `/notation/:notationId/player` | `PlayerScreen` | **No** |
| `captureEditor` | `/capture/editor` | `PageEditorScreen` | **No** |
| `captureMetadata` | `/capture/metadata` | `MetadataFormScreen` | **No** |
| `settings` | `/settings` | `SettingsScreen` | Yes |
| `tags` | `/settings/tags` | `TagsScreen` | Yes |
| `tagCreate` | `/settings/tags/new` | `TagFormScreen` | Yes |
| `tagEdit` | `/settings/tags/:tagId/edit` | `TagFormScreen` | Yes |
| `instruments` | `/settings/instruments` | `InstrumentsScreen` | Yes |
| `instrumentClassCreate` | `/settings/instruments/class/new` | `InstrumentClassFormScreen` | Yes |
| `instrumentInstanceCreate` | `/settings/instruments/instance/new` | `InstrumentInstanceFormScreen` | Yes |
| `instrumentInstanceDetail` | `/settings/instruments/instance/:instanceId` | `InstrumentInstanceDetailScreen` | Yes |
| `instrumentInstanceEdit` | `/settings/instruments/instance/:instanceId/edit` | `InstrumentInstanceFormScreen` | Yes |
| `trash` | `/settings/trash` | `TrashScreen` | Yes |
| `customFields` | `/settings/custom-fields` | `CustomFieldsScreen` | Yes |
| `error` | `/error` | `ErrorScreen` | **No** |

---

## 3. Shell Structure

```
GoRouter
├── ShellRoute (BottomNavShell)
│   ├── /                       → LibraryScreen
│   │   └── /notation/:id       → NotationDetailScreen
│   └── /settings               → SettingsScreen
│       ├── /settings/tags      → TagsScreen
│       │   ├── /new            → TagFormScreen
│       │   └── /:tagId/edit    → TagFormScreen
│       ├── /settings/instruments → InstrumentsScreen
│       │   ├── /class/new      → InstrumentClassFormScreen
│       │   ├── /instance/new   → InstrumentInstanceFormScreen
│       │   └── /instance/:id   → InstrumentInstanceDetailScreen
│       │       └── /edit       → InstrumentInstanceFormScreen
│       ├── /settings/trash     → TrashScreen
│       └── /settings/custom-fields → CustomFieldsScreen
│
├── /notation/:id/player        → PlayerScreen   (no bottom nav)
├── /capture/editor             → PageEditorScreen (no bottom nav)
├── /capture/metadata           → MetadataFormScreen (no bottom nav)
└── /error                      → ErrorScreen
```

---

## 4. Route Definitions

### 4.1 ShellRoute — Bottom Nav

```dart
ShellRoute(
  builder: (context, state, child) => BottomNavShell(child: child),
  routes: [ libraryBranch, settingsBranch ],
)
```

`BottomNavShell` renders `NavigationBar` with two destinations:
- **Library** (index 0) → `/`
- **Settings** (index 1) → `/settings`

Tab switch: `context.go('/')` or `context.go('/settings')`.

### 4.2 Library Branch

```
GoRoute path: /
  └── GoRoute path: notation/:notationId
```

**Notation Detail** receives `notationId` as path param; loads notation via ViewModel on mount.

### 4.3 Settings Branch

```
GoRoute path: /settings
  ├── GoRoute path: tags
  │   ├── GoRoute path: new
  │   └── GoRoute path: :tagId/edit
  ├── GoRoute path: instruments
  │   ├── GoRoute path: class/new
  │   ├── GoRoute path: instance/new
  │   └── GoRoute path: instance/:instanceId
  │       └── GoRoute path: edit
  ├── GoRoute path: trash
  └── GoRoute path: custom-fields
```

---

## 5. Bottom Sheet Routes

Bottom sheets are **not named routes** — launched via `showModalBottomSheet`. They do not participate in the back stack as routes; the platform back gesture dismisses them.

| Sheet | Trigger | Content |
|---|---|---|
| Capture Entry | FAB on `LibraryScreen` | Two options: Gallery / Camera |
| Add Page | "Add page" button in `PageEditorScreen` | Same two options as Capture Entry |
| Filter Picker | Filter button per page in `PageEditorScreen` | Filter list with preview |
| Sort Picker | Sort button on `LibraryScreen` | Sort options list |
| Filter Panel | Filter button on `LibraryScreen` | Multi-field filter UI |

---

## 6. Navigation Map Diagram

```
LibraryScreen (/)
│
├── [FAB] ──────────────────────────────────────────────────────────┐
│                                                                   ↓
│                                                     Capture Entry Sheet
│                                                     [Gallery] → PageEditorScreen (/capture/editor)
│                                                     [Camera]  → PageEditorScreen (/capture/editor)
│                                                                   ↓
│                                                       MetadataFormScreen (/capture/metadata)
│                                                                   ↓ [Save]
│                                                       LibraryScreen (back to /)
│
├── [Notation row tap] → NotationDetailScreen (/notation/:id)
│                              │
│                              ├── [Play button] → PlayerScreen (/notation/:id/player)
│                              │
│                              ├── [Edit swipe / Edit button] → PageEditorScreen (/capture/editor?notationId=:id)
│                              │                                  ↓
│                              │                               MetadataFormScreen
│                              │
│                              └── [Delete] → confirmation → soft-delete → back to /
│
└── [Bottom nav: Settings] → SettingsScreen (/settings)
                                    │
                                    ├── Tags → TagsScreen → TagFormScreen (create/edit)
                                    ├── Instruments → InstrumentsScreen
                                    │      ├── → InstrumentClassFormScreen (create class)
                                    │      └── → InstrumentInstanceDetailScreen
                                    │              └── → InstrumentInstanceFormScreen (edit)
                                    ├── Trash → TrashScreen
                                    └── Custom Fields → CustomFieldsScreen
```

---

## 7. Transition Animations

| Route pair | Animation |
|---|---|
| Library → Notation Detail | Shared-axis horizontal slide (Material 3) |
| Notation Detail → Player | Fade-through (full-screen modal feel) |
| Any → Capture Editor | Vertical slide up (sheet-like) |
| Settings sub-screens | Horizontal slide (standard push) |
| Bottom sheet open | Platform default (slide up from bottom) |

**Implementation:** `go_router`'s `pageBuilder` with `CustomTransitionPage`. Use `Curves.easeInOutCubicEmphasized` (Material 3 standard) for all custom transitions.

---

## 8. State Persistence Rules

| State | Persistence | Reset condition |
|---|---|---|
| Library scroll position | In-memory (ViewModel) | App killed |
| Search query | In-memory (ViewModel) | App killed or cold start (D-24) |
| Active filters | In-memory (ViewModel) | App killed or cold start (D-24) |
| Sort selection | In-memory (ViewModel) | App killed or cold start (D-24) |
| Player page position | In-memory (PlayerViewModel) | Screen pop |
| Capture session (unsaved) | In-memory (CaptureViewModel) | App killed; session discarded |

**No filter/sort/search state is persisted to DB in v1** (D-24). `PreferencesRepository` stores `default_sort` only; active session filters are ephemeral.

---

## 9. Error & Redirect Routes

| Scenario | Behavior |
|---|---|
| Unknown route | `go_router` `errorBuilder` → `ErrorScreen` |
| Notation not found (deleted while navigating) | `NotationDetailScreen` ViewModel emits `Failure` state → inline error UI + back button |
| Player route with missing notation | Same as above |
| Deep link to nonexistent notation | Redirect to `/` |

`go_router` `redirect` callback: none needed in v1 (no auth, no onboarding gate).
