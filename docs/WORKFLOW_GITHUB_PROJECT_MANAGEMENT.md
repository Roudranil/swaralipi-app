# GitHub Project Management Workflow

Complete workflow for managing issues, branches, and PRs using the GitHub Project Management skill.

## Table of Contents

1. [Issue Hierarchy](#1-issue-hierarchy)
2. [Creating an Epic-Feature-Task Chain](#2-creating-an-epic-feature-task-chain)
3. [Branch Workflow](#3-branch-workflow)
4. [Implementation and Commits](#4-implementation-and-commits)
5. [Pull Requests](#5-pull-requests)
6. [Label Taxonomy](#6-label-taxonomy)

---

## 1. Issue Hierarchy

Issues follow a strict parent-child hierarchy:

```
Epic (label: epic)
 └── Feature (label: feature)
      └── Story (label: story)
           └── Task (label: task)
Bug (label: bug) — standalone or nested
```

**Rationale:**
- **Epic:** Top-level initiative (e.g., "Notation Management")
- **Feature:** Major capability (e.g., "Image Capture and Import")
- **Story:** User-observable slice (e.g., "Capture via camera", "Import from gallery")
- **Task:** Atomic work item (e.g., "Wire CameraX", "Write tests")
- **Bug:** Defect, linked only if scoped to a story/task

**Key principle:** Each level is independently trackable and closeable.

---

## 2. Creating an Epic-Feature-Task Chain

### Step 1: Create Epic

```bash
mcp__github__issue_write
  method: "create"
  title:  "[Epic] <short name>"
  body:   <epic template>
  labels: ["epic", "planned", "p1"]
```

**Epic Template:**

```markdown
## Goal
<!-- What outcome does this epic deliver? -->

## Scope
<!-- Features included. Add issue refs once created. -->
- [ ] #<feature-number>

## Out of Scope
<!-- Explicitly excluded. -->

## Acceptance Criteria
<!-- How do we know it's done? -->

## Priority
<!-- p0-p5 -->

## Notes
```

**Result:** Issue #N created with `node_id` I_kwA...xxx

### Step 2: Create Feature and Link to Epic

```bash
mcp__github__issue_write
  method: "create"
  title:  "[Feature] <short name>"
  body:   <feature template with Parent Epic: #N>
  labels: ["feature", "planned", "p1"]
```

**Feature Template:**

```markdown
## Parent Epic
#<epic-number>

## Goal
<!-- What capability does this feature add? -->

## Stories
- [ ] #<story-number>

## Acceptance Criteria

## Priority
<!-- p0-p5 -->

## Notes
```

**Link to Epic:**

```bash
mcp__github__issue_read
  method:       "get"
  issue_number: <epic-number>
  → extract node_id from response

mcp__github__sub_issue_write
  method:        "add"
  issue_number:  <epic-number>       ← parent
  sub_issue_id:  <feature-node-id>   ← child (node_id, NOT number)
```

### Step 3: Create Task and Link to Feature

```bash
mcp__github__issue_write
  method: "create"
  title:  "[Task] <technical description>"
  body:   <task template>
  labels: ["task", "planned", "p1"]
```

**Task Template:**

```markdown
## Parent Story
#<story-number>

## What
<!-- Concise technical description. -->

## Definition of Done
- [ ] Tests written and passing
- [ ] Coverage ≥ 80%
- [ ] `flutter analyze` clean
- [ ] `dart format` applied
- [ ] PR opened and linked

## Priority
<!-- p0-p5 -->
```

**Link to Feature:**

```bash
mcp__github__sub_issue_write
  method:        "add"
  issue_number:  <feature-number>
  sub_issue_id:  <task-node-id>
```

---

## 3. Branch Workflow

### Branch Naming Convention

Format: `<type>/<id>-<slug>`

| Type | Pattern | Example |
|---|---|---|
| Feature | `feature/<number>-<slug>` | `feature/2-readme` |
| Story | `story/<number>-<slug>` | `story/15-camera-ui` |
| Task | `task/<number>-<slug>` | `task/3-initial-readme` |
| Bug | `bug/<number>-<slug>` | `bug/23-crash-rotate` |
| Chore | `chore/<slug>` | `chore/update-flutter` |
| Release | `release/<version>` | `release/1.2.0` |

### Creating a Branch

```bash
# Create and checkout
git checkout -b task/3-initial-readme

# Or via GitHub API
mcp__github__create_branch
  branch:      "task/3-initial-readme"
  from_branch: "main"
```

### Branch Lifecycle

1. **Create:** Branch from `main`
2. **Implement:** Make commits locally
3. **Push:** `git push -u origin <branch-name>`
4. **PR:** Open pull request (see Section 5)
5. **Review:** Address feedback
6. **Merge:** Squash merge to `main` (see Section 5.3)
7. **Close:** Issue auto-closes when PR merges

---

## 4. Implementation and Commits

### Conventional Commits

Format:

```
<type>(<scope>): <imperative description>

[optional body — explain WHY, not WHAT]

Refs: #<issue-number>
```

**Types:** `feat`, `fix`, `refactor`, `docs`, `test`, `chore`, `perf`, `ci`

**Scopes (Swaralipi):**
- `notation` — image capture, import, display
- `metadata` — fields, search, filter
- `storage` — local DB, file system
- `ui` — widgets, theming, layout
- `nav` — GoRouter routes
- `vm` — ViewModels

### Examples

```bash
# Documentation
git commit -m "docs: add project README (#3)"

# Feature
git commit -m "feat(notation): wire CameraX to ImageCapture use-case (#18)"

# Bug fix
git commit -m "fix(metadata): prevent crash on empty search query (#23)"

# Chore
git commit -m "chore: bump Flutter to 3.24.5"
```

### Before Committing

1. Format code: `dart format .`
2. Analyze: `flutter analyze --fatal-infos --fatal-warnings`
3. Run tests: `flutter test --coverage`
4. Verify coverage ≥ 80%
5. Commit with linked issue: `git commit -m "type(scope): description (#N)"`

---

## 5. Pull Requests

### Creating a PR

```bash
mcp__github__create_pull_request
  title:  "docs: add project README"
  head:   "task/3-initial-readme"
  base:   "main"
  draft:  false
  body:   <pr template>
```

### PR Template

```markdown
## Linked Issue
Closes #<issue-number>

## Summary
<!-- What does this PR do? 2-4 bullets. -->
-
-

## Type of Change
- [ ] feat — new capability
- [ ] fix — bug fix
- [ ] refactor — no behavior change
- [ ] test — tests only
- [ ] docs — documentation only
- [ ] chore — build / tooling / deps

## Test Plan
- [ ] Unit tests written / updated
- [ ] `flutter test --coverage` passes
- [ ] Coverage ≥ 80%
- [ ] `flutter analyze --fatal-infos --fatal-warnings` clean
- [ ] `dart format` applied
- [ ] Tested on Samsung Galaxy S25 (if UI)

## Checklist
- [ ] No `print` statements
- [ ] No relative imports
- [ ] No `late` without guaranteed init
- [ ] No bare `catch (e)`
- [ ] Generated files committed
- [ ] No hardcoded secrets
```

### PR Merge Strategy

| Scenario | Method | Command |
|---|---|---|
| Task / Story → main | `squash` | Collapses branch noise; clean history |
| Feature → main | `squash` | Same rationale |
| Release → main | `merge` | Preserves merge commit marking release point |

```bash
mcp__github__merge_pull_request
  pullNumber:   <N>
  merge_method: "squash"
  commit_title: "feat(notation): wire CameraX to ImageCapture use-case (#18)"
```

### PR Workflow

1. **Draft:** Open as draft while implementing
2. **Ready for review:** Mark `draft: false` when CI passes
3. **Review:** Author addresses feedback
4. **Approve:** Reviewer approves
5. **Merge:** Use appropriate strategy (see table above)
6. **Close:** Related issue auto-closes

---

## 6. Label Taxonomy

### Hierarchy Labels

| Label | Color | Purpose |
|---|---|---|
| `epic` | 7B2FBE | Top-level initiative |
| `feature` | 9B59B6 | Major capability |
| `story` | B185DB | User-observable slice |
| `task` | D2A8FF | Atomic work item |
| `bug` | E74C3C | Defect |

### Status Labels

| Label | Color | Meaning |
|---|---|---|
| `planned` | F1C40F | Scoped, not started |
| `in-progress` | E67E22 | Actively worked |
| `blocked` | C0392B | Blocked (blocker named in comments) |

### Priority Labels

| Label | Color | Meaning |
|---|---|---|
| `p0` | C0392B | Critical — drop everything |
| `p1` | E74C3C | High — current sprint |
| `p2` | E67E22 | Medium-high — next sprint |
| `p3` | F39C12 | Medium — backlog top |
| `p4` | 2980B9 | Low — backlog |
| `p5` | 95A5A6 | Negligible — someday/maybe |

### Label Application

**On creation:**

```bash
labels: ["epic", "planned", "p1"]
labels: ["feature", "planned", "p1"]
labels: ["task", "planned", "p1"]
labels: ["bug", "p2"]
```

**When starting work:**

```bash
# Remove "planned", add "in-progress"
labels: ["task", "in-progress", "p1"]
```

**When blocked:**

```bash
labels: ["task", "blocked", "p1"]
# Also comment with blocker details
```

**When closed:**

```bash
# Remove status label; issue closes automatically
```

---

## Worked Example: Complete Flow

### Setup: Epic → Feature → Task

```bash
# 1. Create epic
mcp__github__issue_write method: create
  title:  "[Epic] Documentation"
  labels: ["epic", "planned", "p1"]
→ Issue #1

# 2. Create feature
mcp__github__issue_write method: create
  title:  "[Feature] README"
  body:   "## Parent Epic\n#1"
  labels: ["feature", "planned", "p1"]
→ Issue #2

# 3. Create task
mcp__github__issue_write method: create
  title:  "[Task] Create initial README.md"
  body:   "## Parent Story\n#2"
  labels: ["task", "planned", "p1"]
→ Issue #3
```

### Implementation

```bash
# 1. Create branch
git checkout -b task/3-initial-readme

# 2. Implement
# (create files, write code)

# 3. Commit
git commit -m "docs: add project README (#3)"

# 4. Push
git push -u origin task/3-initial-readme

# 5. Open PR
mcp__github__create_pull_request
  title:  "docs: add project README"
  head:   "task/3-initial-readme"
  base:   "main"
  body:   <template>
→ PR #4

# 6. Merge (when approved)
mcp__github__merge_pull_request
  pullNumber:   4
  merge_method: "squash"
```

### Lifecycle

- PR #4 merged → `task/3-initial-readme` deleted
- Issue #3 auto-closes
- Feature #2 remains open (no sibling stories yet)
- Epic #1 remains open (feature #2 still open)

---

## Tips and Best Practices

### When to Use Each Level

- **Epic:** Months-long initiatives (e.g., "Image Capture", "Search & Filter")
- **Feature:** Weeks-long capabilities (e.g., "Camera UI", "Database Schema")
- **Story:** Days-long user slices (e.g., "User can tap button to open camera")
- **Task:** Hours-long technical steps (e.g., "Wire CameraX", "Write tests", "Handle errors")

### Blocking and Dependencies

```bash
# When blocked
mcp__github__issue_write method: update
  issue_number: 5
  labels:       ["task", "blocked", "p1"]

mcp__github__add_issue_comment
  issue_number: 5
  body:         "🚫 Blocked by #7. Reason: awaiting API contract."
```

### Inspecting Hierarchy

```bash
# Sub-issues of a parent
mcp__github__issue_read
  method:       "get_sub_issues"
  issue_number: 1

# All open tasks
mcp__github__search_issues
  query: "repo:Roudranil/swaralipi-app is:open label:task"

# By priority
mcp__github__search_issues
  query: "repo:Roudranil/swaralipi-app is:open label:p0"
```

---

## Key Tools (MCP GitHub Skills)

| Tool | Purpose |
|---|---|
| `issue_write` | Create/update issues |
| `issue_read` | Read issue details and sub-issues |
| `sub_issue_write` | Link/unlink parent-child relationships |
| `create_pull_request` | Open PR |
| `merge_pull_request` | Merge PR with strategy |
| `create_branch` | Create branch via API |
| `label_write` | Create/update labels |
| `search_issues` | Find issues by query |

---

## Critical Notes

- **node_id vs issue_number:** `sub_issue_write` requires `sub_issue_id` (node_id), NOT issue number
- **Always fetch node_id:** Use `issue_read method: get` first to extract it
- **Branch naming:** Ties directly to issue tracking; always follow format
- **Squash merge:** Default for tasks/stories to keep main history clean
- **No attribution:** Commit messages never include `Co-Authored-By` lines
