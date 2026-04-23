---
name: github-project-management
description: >
    Full GitHub project management via MCP tools and gh CLI — label taxonomy (epic → feature → story → task / bug),
    issue hierarchy with sub-issue linking, PR workflow (branch naming, review, merge strategies),
    commit conventions (conventional commits extended), semantic versioning, and GitHub Actions setup.
    Includes gh CLI for project field management and GraphQL for sub-issue creation. Use whenever creating
    or managing issues, PRs, labels, releases, or repo scaffolding files on Swaralipi.
---

# GitHub Project Management via MCP Skill

## 1. Constants & Scope

Every tool call in this skill uses these values:

```
OWNER = Roudranil
REPO  = swaralipi-app
PROJECT = 4 (Swaralipi)
```

Do NOT repeat these in inline examples — they are inherited by all `mcp__github__*` calls.

**⚠️ CRITICAL BOUNDARY:**

This skill operates ONLY on the Swaralipi repository and project (#4). **Other projects (variance, Lattice) are strictly off-bounds.** Do not interact with them under any circumstances. Always verify you are working with:

- Repository: `Roudranil/swaralipi-app`
- Project: `4` (Swaralipi)

If a request references other projects, decline and redirect to Swaralipi work only.

---

## 2. MCP Tool Quick-Reference

| Purpose                 | Tool                                         | Key Parameters                                                                                                                         |
| ----------------------- | -------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------- |
| Create / update issue   | `mcp__github__issue_write`                   | `method` (`create`/`update`), `title`, `body`, `labels[]`, `assignees[]`, `issue_number` (for update)                                  |
| Read issue / sub-issues | `mcp__github__issue_read`                    | `method` (`get`/`get_comments`/`get_sub_issues`/`get_labels`), `issue_number`                                                          |
| List issues             | `mcp__github__list_issues`                   | `state` (`open`/`closed`), `labels[]`, `since`, `orderBy`, `direction`                                                                 |
| Search issues           | `mcp__github__search_issues`                 | `query` (GitHub search syntax: `is:open label:task label:p0`), `sort`, `order`                                                         |
| Comment on issue        | `mcp__github__add_issue_comment`             | `issue_number`, `body`                                                                                                                 |
| Link parent ↔ child     | `mcp__github__sub_issue_write`               | `method` (`add`/`remove`/`reprioritize`), `issue_number` (parent), `sub_issue_id` (child **node ID**, NOT number)                      |
| List issue types        | `mcp__github__list_issue_types`              | —                                                                                                                                      |
| Create label            | `mcp__github__label_write`                   | `method: create`, `name`, `color` (hex without `#`), `description`                                                                     |
| List labels             | `mcp__github__list_label`                    | —                                                                                                                                      |
| Get label               | `mcp__github__get_label`                     | `name`                                                                                                                                 |
| Create branch           | `mcp__github__create_branch`                 | `branch` (name), `from_branch` (defaults to repo default)                                                                              |
| Open PR                 | `mcp__github__create_pull_request`           | `title`, `head` (branch), `base` (branch), `body`, `draft` (boolean)                                                                   |
| Update PR               | `mcp__github__update_pull_request`           | `pullNumber`, `title`, `body`, `state` (`open`/`closed`), `draft`, `reviewers[]`, `base`                                               |
| Read PR                 | `mcp__github__pull_request_read`             | `method` (`get`/`get_diff`/`get_status`/`get_files`/`get_review_comments`/`get_reviews`/`get_comments`/`get_check_runs`), `pullNumber` |
| Start pending review    | `mcp__github__pull_request_review_write`     | `method: create`, `pullNumber` (no `event` = pending)                                                                                  |
| Add inline comment      | `mcp__github__add_comment_to_pending_review` | `pullNumber`, `path`, `line` (or `startLine`/`endLine` for range), `side` (`LEFT`/`RIGHT`), `subjectType` (`FILE`/`LINE`), `body`      |
| Submit review           | `mcp__github__pull_request_review_write`     | `method: submit_pending`, `pullNumber`, `event` (`APPROVE`/`REQUEST_CHANGES`/`COMMENT`), `body`                                        |
| Delete pending review   | `mcp__github__pull_request_review_write`     | `method: delete_pending`, `pullNumber`                                                                                                 |
| Resolve review thread   | `mcp__github__pull_request_review_write`     | `method: resolve_thread`, `threadId` (node ID from `get_review_comments`)                                                              |
| Merge PR                | `mcp__github__merge_pull_request`            | `pullNumber`, `merge_method` (`squash`/`merge`/`rebase`), `commit_title`, `commit_message`                                             |
| Update PR branch        | `mcp__github__update_pull_request_branch`    | `pullNumber`                                                                                                                           |
| Write file to repo      | `mcp__github__create_or_update_file`         | `path`, `content`, `message`, `branch`, `sha` (required if file exists; get via `get_file_contents`)                                   |
| Read file from repo     | `mcp__github__get_file_contents`             | `path`, `ref` (branch/tag/commit, defaults to default branch)                                                                          |
| Repo tree               | `mcp__github__get_repository_tree`           | `tree_sha` (branch/tag, defaults to default), `recursive` (boolean)                                                                    |
| Latest release          | `mcp__github__get_latest_release`            | —                                                                                                                                      |
| Release by tag          | `mcp__github__get_release_by_tag`            | `tag` (e.g., `v1.0.0`)                                                                                                                 |
| List releases           | `mcp__github__list_releases`                 | `page`, `perPage`                                                                                                                      |

**Critical callout:** `sub_issue_id` is the GitHub **node ID** (format: `I_kwDO...`), **NOT the issue number**. Always fetch via `issue_read method: get` first and extract the `node_id` field.

---

## 2.1 GitHub CLI (`gh`) Quick-Reference

The `gh` CLI provides complementary capabilities to MCP tools, especially for project management and sub-issue linking.

| Purpose                 | Command                                                                                                               | Parameters                               |
| ----------------------- | --------------------------------------------------------------------------------------------------------------------- | ---------------------------------------- |
| List projects           | `gh project list --owner Roudranil`                                                                                   | —                                        |
| View project details    | `gh project view 4 --owner Roudranil`                                                                                 | project number                           |
| List project items      | `gh project item-list 4 --owner Roudranil`                                                                            | project number                           |
| Add issue to project    | `gh project item-add 4 --owner Roudranil --url <issue-url>`                                                           | project number, issue URL                |
| Edit project item field | `gh project item-edit --id <item-id> --project-id <proj-id> --field-id <field-id> --single-select-option-id <opt-id>` | item ID, project ID, field ID, option ID |
| Create issue            | `gh issue create --repo Roudranil/swaralipi-app --title "<title>" --body "<body>" --label label1,label2`              | title, body, labels                      |
| Close issue             | `gh issue close <number> --repo Roudranil/swaralipi-app`                                                              | issue number                             |
| Add sub-issue (GraphQL) | `gh api graphql -f query='mutation { addSubIssue(input: {...}) { ... } }'`                                            | See Section 2.2                          |

### 2.2 Sub-Issue Management via GraphQL

**Note:** Sub-issues cannot be created via `gh issue` flags; use GraphQL `addSubIssue` mutation instead.

**Tested and working mutation:**

```bash
gh api graphql -f query='
  mutation {
    addSubIssue(input: {
      issueId: "I_kwDOSKa3F88AAAABAUB0IA"
      subIssueUrl: "https://github.com/Roudranil/swaralipi-app/issues/6"
      replaceParent: false
    }) {
      issue {
        id
        number
        title
      }
    }
  }
'
```

**Parameters:**

- `issueId` (required): Parent issue node ID
- `subIssueUrl` (required): URL of child issue to link
- `replaceParent` (optional): Set true to replace existing parent relationship

**To verify sub-issue relationship:**

```bash
gh api graphql -f query='
  query {
    repository(owner: "Roudranil", name: "swaralipi-app") {
      issue(number: 5) {
        number
        subIssues(first: 10) {
          nodes {
            number
            title
          }
        }
      }
    }
  }
'
```

### 2.3 Project Field Management via `gh project item-edit`

**Step 1: Get field IDs and option IDs** (one-time setup)

```bash
gh api graphql -f query='
  query {
    user(login: "Roudranil") {
      projectV2(number: 4) {
        id
        fields(first: 20) {
          nodes {
            ... on ProjectV2SingleSelectField {
              id
              name
              options {
                id
                name
              }
            }
          }
        }
      }
    }
  }
'
```

**Current Swaralipi Project field mapping (project ID: `PVT_kwHOA51EZs4BVe4H`):**

| Field    | Field ID                         | Option      | Option ID  |
| -------- | -------------------------------- | ----------- | ---------- |
| Status   | `PVTSSF_lAHOA51EZs4BVe4HzhQ6YbE` | Backlog     | `f75ad846` |
|          |                                  | Ready       | `e18bf179` |
|          |                                  | In progress | `47fc9ee4` |
|          |                                  | In review   | `aba860b9` |
|          |                                  | Done        | `98236657` |
| Priority | `PVTSSF_lAHOA51EZs4BVe4HzhQ6Yig` | P0          | `79628723` |
|          |                                  | P1          | `0a877460` |
|          |                                  | P2          | `da944a9c` |
| Size     | `PVTSSF_lAHOA51EZs4BVe4HzhQ6Yik` | XS          | `911790be` |
|          |                                  | S           | `b277fb01` |
|          |                                  | M           | `86db8eb3` |
|          |                                  | L           | `853c8207` |
|          |                                  | XL          | `2d0801e2` |

**Step 2: Update item field**

```bash
# Example: Set Status to "In progress" on item PVTI_lAHOA51EZs4BVe4Hzgqxpms
gh project item-edit \
  --id PVTI_lAHOA51EZs4BVe4Hzgqxpms \
  --project-id PVT_kwHOA51EZs4BVe4H \
  --field-id PVTSSF_lAHOA51EZs4BVe4HzhQ6YbE \
  --single-select-option-id 47fc9ee4
```

Repeat for Priority and Size fields using their respective field IDs and option IDs.

**Tested capabilities:**

- ✅ `gh project item-add` — adds issues to project
- ✅ `gh project item-edit` — updates Status, Priority, Size fields
- ✅ GraphQL `addSubIssue` — creates parent-child relationships
- ✅ Field values persisted correctly

---

## 3. Story-Level Assessment

**Decision: INCLUDE story level. Rationale:**

- **Features** span multiple UI screens, data models, and test surfaces → too coarse for atomic tasks
- **Stories** represent user-observable slices of a feature (e.g., "As a musician, I can capture a notation via camera") → independently shippable in 1-2 days
- **Tasks** are atomic technical steps within a story (e.g., "Wire CameraX to ViewModel", "Write unit tests") → 1-4 hours each
- **Without stories**, features collapse into 15+ unrelated tasks; narrative grouping and priority visibility is lost

**Final Hierarchy:**

```
Epic  (label: epic)
 └── Feature  (label: feature)     ← sub-issue of epic
      └── Story  (label: story)    ← sub-issue of feature
           └── Task  (label: task) ← sub-issue of story
Bug  (label: bug)                  ← standalone or linked to any level
```

---

## 4. Label Taxonomy

### 4.1 Color Palette

| Group     | Label       | Hex (no `#`) | Purpose                             |
| --------- | ----------- | ------------ | ----------------------------------- |
| Hierarchy | epic        | `7B2FBE`     | Top-level initiatives               |
| Hierarchy | feature     | `9B59B6`     | Major capabilities                  |
| Hierarchy | story       | `B185DB`     | User-observable slices              |
| Hierarchy | task        | `D2A8FF`     | Atomic work items                   |
| Hierarchy | bug         | `E74C3C`     | Defects                             |
| Status    | planned     | `F1C40F`     | Scoped, not started                 |
| Status    | in-progress | `E67E22`     | Actively being worked               |
| Status    | blocked     | `C0392B`     | Blocked — blocker named in comments |
| Priority  | p0          | `C0392B`     | Critical — drop everything          |
| Priority  | p1          | `E74C3C`     | High — current sprint               |
| Priority  | p2          | `E67E22`     | Medium-high — next sprint           |
| Priority  | p3          | `F39C12`     | Medium — backlog top                |
| Priority  | p4          | `2980B9`     | Low — backlog                       |
| Priority  | p5          | `95A5A6`     | Negligible — someday/maybe          |

### 4.2 Bootstrap SOP

Run once per fresh repo:

1. Call `mcp__github__list_label` to check existing labels
2. For each label above not in the result, call:

```
mcp__github__label_write
  method:      "create"
  name:        "<label>"
  color:       "<hex without #>"
  description: "<description>"
```

3. Verify: `mcp__github__list_label` → confirm all 14 labels present

**Gap:** No MCP tool to delete GitHub's default labels (`enhancement`, `good first issue`, etc.). Workaround: call `label_write method: delete` for each by exact name.

---

## 5. Issue Hierarchy & Body Templates

### 5.1 Body Templates

**Epic:**

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

**Feature:**

```markdown
## Parent Epic

<!-- #<epic-number> -->

## Goal

<!-- What capability does this feature add? -->

## Stories

- [ ] #<story-number>

## Acceptance Criteria

## Priority

<!-- p0-p5 -->

## Notes
```

**Story:**

```markdown
## Parent Feature

<!-- #<feature-number> -->

## User Story

As a <role>, I can <action> so that <value>.

## Tasks

- [ ] #<task-number>

## Acceptance Criteria

## Priority

<!-- p0-p5 -->
```

**Task:**

```markdown
## Parent Story

<!-- #<story-number> -->

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

**Bug:**

```markdown
## Summary

<!-- One-sentence description. -->

## Steps to Reproduce

1.
2.

## Expected Behavior

## Actual Behavior

## Environment

Device: Samsung Galaxy S25
Flutter version:
App version:

## Severity / Priority

<!-- p0-p5 -->

## Linked Issue (if applicable)

<!-- #<issue-number> -->
```

### 5.2 SOP: Create an Epic

1. Call:

```
mcp__github__issue_write
  method: "create"
  title:  "[Epic] <short name>"
  body:   <epic template filled>
  labels: ["epic", "planned", "p<N>"]
```

2. Note the returned `number` (issue number) and `node_id` (needed for sub-issues).

### 5.3 SOP: Create a Feature and Link to Epic

1. Create feature:

```
mcp__github__issue_write
  method: "create"
  title:  "[Feature] <short name>"
  body:   <feature template with Parent Epic: #<epic-number>>
  labels: ["feature", "planned", "p<N>"]
```

2. Note `node_id` of the new feature.

3. Get epic's `node_id` if not known:

```
mcp__github__issue_read
  method:       "get"
  issue_number: <epic-number>
```

4. Link feature to epic:

```
mcp__github__sub_issue_write
  method:        "add"
  issue_number:  <epic-number>       ← parent
  sub_issue_id:  <feature-node-id>   ← child (node_id, not number)
```

### 5.4 SOP: Create a Story and Link to Feature

1. Create story:

```
mcp__github__issue_write
  method: "create"
  title:  "[Story] <user-facing description>"
  body:   <story template>
  labels: ["story", "planned", "p<N>"]
```

2. Get feature's `node_id`:

```
mcp__github__issue_read
  method:       "get"
  issue_number: <feature-number>
```

3. Link to feature:

```
mcp__github__sub_issue_write
  method:        "add"
  issue_number:  <feature-number>
  sub_issue_id:  <story-node-id>
```

### 5.5 SOP: Create a Task and Link to Story

1. Create task:

```
mcp__github__issue_write
  method: "create"
  title:  "[Task] <technical description>"
  body:   <task template>
  labels: ["task", "planned", "p<N>"]
```

2. Link to story:

```
mcp__github__sub_issue_write
  method:        "add"
  issue_number:  <story-number>
  sub_issue_id:  <task-node-id>
```

### 5.6 SOP: Create a Bug

Bugs are standalone. Link as sub-issue only if the bug is clearly contained within a story/task:

```
mcp__github__issue_write
  method: "create"
  title:  "[Bug] <short description>"
  body:   <bug template>
  labels: ["bug", "p<N>"]
```

### 5.7 SOP: Update Issue Status

**When starting work:**

```
mcp__github__issue_write
  method:       "update"
  issue_number: <N>
  labels:       ["<type>", "in-progress", "p<N>"]
```

Remove `planned`, add `in-progress`. Pass full label set each time (no delta support).

**When blocked:**

```
mcp__github__issue_write
  method:       "update"
  issue_number: <N>
  labels:       ["<type>", "blocked", "p<N>"]
```

Also comment:

```
mcp__github__add_issue_comment
  issue_number: <N>
  body: "🚫 Blocked by #<blocker-number>. Reason: <one sentence>."
```

**When complete:**

```
mcp__github__issue_write
  method:       "update"
  issue_number: <N>
  state:        "closed"
  state_reason: "completed"
```

### 5.8 SOP: Inspect Hierarchy

**Sub-issues of a parent:**

```
mcp__github__issue_read
  method:       "get_sub_issues"
  issue_number: <parent-number>
```

**All open tasks:**

```
mcp__github__search_issues
  query: "repo:Roudranil/swaralipi-app is:open label:task"
```

**By priority:**

```
mcp__github__search_issues
  query: "repo:Roudranil/swaralipi-app is:open label:p0"
```

**Blocked issues:**

```
mcp__github__search_issues
  query: "repo:Roudranil/swaralipi-app is:open label:blocked"
```

---

## 6. Issue Templates (YAML)

**Gap:** MCP has no issue-type creation API. Workaround: write `.github/ISSUE_TEMPLATE/*.yml` files directly via `create_or_update_file`.

### 6.1 Template Locations

| Type    | File                                 |
| ------- | ------------------------------------ |
| Epic    | `.github/ISSUE_TEMPLATE/epic.yml`    |
| Feature | `.github/ISSUE_TEMPLATE/feature.yml` |
| Story   | `.github/ISSUE_TEMPLATE/story.yml`   |
| Task    | `.github/ISSUE_TEMPLATE/task.yml`    |
| Bug     | `.github/ISSUE_TEMPLATE/bug.yml`     |

### 6.2 SOP: Write a Template

1. Check if file exists:

```
mcp__github__get_file_contents
  path: ".github/ISSUE_TEMPLATE/epic.yml"
  ref:  "main"
```

2. If exists, note the `sha` field. Write (create or update):

```
mcp__github__create_or_update_file
  path:    ".github/ISSUE_TEMPLATE/epic.yml"
  branch:  "main"
  message: "chore: add epic issue template"
  sha:     <sha from step 1, omit if creating>
  content: <base64-encoded YAML below>
```

### 6.3 Template YAML Content

**Epic template (`epic.yml`):**

```yaml
name: Epic
description: Top-level initiative spanning multiple features
labels: ["epic", "planned"]
body:
    - type: textarea
      id: goal
      attributes:
          label: Goal
          description: What outcome does this epic deliver?
      validations:
          required: true
    - type: textarea
      id: scope
      attributes:
          label: Scope
          description: Features included (add issue refs once created)
    - type: textarea
      id: out_of_scope
      attributes:
          label: Out of Scope
    - type: textarea
      id: acceptance_criteria
      attributes:
          label: Acceptance Criteria
      validations:
          required: true
    - type: dropdown
      id: priority
      attributes:
          label: Priority
          options: ["p0", "p1", "p2", "p3", "p4", "p5"]
      validations:
          required: true
    - type: textarea
      id: notes
      attributes:
          label: Notes
```

**Feature template (`feature.yml`):**

```yaml
name: Feature
description: Product capability; sub-issue of an epic
labels: ["feature", "planned"]
body:
    - type: input
      id: parent_epic
      attributes:
          label: Parent Epic
          placeholder: "#123"
      validations:
          required: true
    - type: textarea
      id: goal
      attributes:
          label: Goal
          description: What capability does this feature add?
      validations:
          required: true
    - type: textarea
      id: stories
      attributes:
          label: Stories
          description: Add story issue refs once created (one per line)
    - type: textarea
      id: acceptance_criteria
      attributes:
          label: Acceptance Criteria
      validations:
          required: true
    - type: dropdown
      id: priority
      attributes:
          label: Priority
          options: ["p0", "p1", "p2", "p3", "p4", "p5"]
      validations:
          required: true
    - type: textarea
      id: notes
      attributes:
          label: Notes
```

**Story template (`story.yml`):**

```yaml
name: Story
description: User-observable slice of a feature
labels: ["story", "planned"]
body:
    - type: input
      id: parent_feature
      attributes:
          label: Parent Feature
          placeholder: "#123"
      validations:
          required: true
    - type: textarea
      id: user_story
      attributes:
          label: User Story
          description: "As a <role>, I can <action> so that <value>."
      validations:
          required: true
    - type: textarea
      id: tasks
      attributes:
          label: Tasks
          description: Add task issue refs once created (one per line)
    - type: textarea
      id: acceptance_criteria
      attributes:
          label: Acceptance Criteria
      validations:
          required: true
    - type: dropdown
      id: priority
      attributes:
          label: Priority
          options: ["p0", "p1", "p2", "p3", "p4", "p5"]
      validations:
          required: true
```

**Task template (`task.yml`):**

```yaml
name: Task
description: Atomic technical work item
labels: ["task", "planned"]
body:
    - type: input
      id: parent_story
      attributes:
          label: Parent Story
          placeholder: "#123"
      validations:
          required: true
    - type: textarea
      id: what
      attributes:
          label: What
          description: Concise technical description
      validations:
          required: true
    - type: textarea
      id: definition_of_done
      attributes:
          label: Definition of Done
          value: "- [ ] Tests written and passing\n- [ ] Coverage ≥ 80%\n- [ ] flutter analyze clean\n- [ ] dart format applied\n- [ ] PR opened and linked"
      validations:
          required: true
    - type: dropdown
      id: priority
      attributes:
          label: Priority
          options: ["p0", "p1", "p2", "p3", "p4", "p5"]
      validations:
          required: true
```

**Bug template (`bug.yml`):**

```yaml
name: Bug
description: Defect — functional regression or crash
labels: ["bug"]
body:
    - type: textarea
      id: summary
      attributes:
          label: Summary
          description: One-sentence description
      validations:
          required: true
    - type: textarea
      id: steps
      attributes:
          label: Steps to Reproduce
      validations:
          required: true
    - type: textarea
      id: expected
      attributes:
          label: Expected Behavior
    - type: textarea
      id: actual
      attributes:
          label: Actual Behavior
    - type: textarea
      id: environment
      attributes:
          label: Environment
          value: "Device: Samsung Galaxy S25\nFlutter version:\nApp version:"
      validations:
          required: true
    - type: dropdown
      id: priority
      attributes:
          label: Severity / Priority
          options: ["p0", "p1", "p2", "p3", "p4", "p5"]
      validations:
          required: true
    - type: input
      id: linked
      attributes:
          label: Linked Issue (optional)
          placeholder: "#123"
```

---

## 7. PR Workflow

### 7.1 Branch Naming Convention

| Issue type | Pattern                   | Example                    |
| ---------- | ------------------------- | -------------------------- |
| Feature    | `feature/<number>-<slug>` | `feature/12-image-capture` |
| Story      | `story/<number>-<slug>`   | `story/15-camera-ui`       |
| Task       | `task/<number>-<slug>`    | `task/18-camerax-wiring`   |
| Bug        | `bug/<number>-<slug>`     | `bug/23-crash-rotate`      |
| Chore      | `chore/<slug>`            | `chore/update-flutter`     |
| Release    | `release/<version>`       | `release/1.2.0`            |

### 7.2 SOP: Open a PR for a Task / Bug

1. Create branch:

```
mcp__github__create_branch
  branch:      "task/18-camerax-wiring"
  from_branch: "main"
```

2. Make commits locally (outside MCP scope).

3. Open as draft:

```
mcp__github__create_pull_request
  title:  "feat(notation): wire CameraX to ImageCapture use-case"
  head:   "task/18-camerax-wiring"
  base:   "main"
  draft:  true
  body:   <PR template body — see Section 7.4>
```

4. When CI passes and ready for review, mark ready:

```
mcp__github__update_pull_request
  pullNumber: <N>
  draft:      false
  reviewers:  ["Roudranil"]
```

### 7.3 Merge Strategies

| Scenario               | Method   | Rationale                                    |
| ---------------------- | -------- | -------------------------------------------- |
| Task / Story into main | `squash` | Clean linear history                         |
| Feature integration    | `squash` | Collapses branch noise                       |
| Release → main         | `merge`  | Preserves merge commit marking release point |
| Hotfix                 | `squash` | Same as task                                 |

```
mcp__github__merge_pull_request
  pullNumber:   <N>
  merge_method: "squash"
  commit_title: "feat(notation): wire CameraX to ImageCapture use-case (#18)"
```

For release merges: `merge_method: "merge"`.

### 7.4 PR Template

Write once to repo:

```
mcp__github__create_or_update_file
  path:    ".github/pull_request_template.md"
  branch:  "main"
  message: "chore: add PR template"
  sha:     <sha if updating>
  content: <content below, base64-encoded>
```

**Template content:**

```markdown
## Linked Issue

Closes #<issue-number>

## Summary

## <!-- What does this PR do? 2-4 bullets. -->

-

## Type of Change

- [ ] feat — new capability
- [ ] fix — bug fix
- [ ] refactor — no behavior change
- [ ] test — tests only
- [ ] docs — documentation only
- [ ] chore — build / tooling / deps
- [ ] ci — CI/CD changes

## Commit Convention

<!-- Verify your squash commit follows: type(scope): description (#issue) -->

## Test Plan

- [ ] Unit tests written / updated
- [ ] `flutter test --coverage` passes locally
- [ ] Coverage ≥ 80%
- [ ] `flutter analyze --fatal-infos --fatal-warnings` clean
- [ ] `dart format` applied
- [ ] Tested on Samsung Galaxy S25 (if UI change)

## Screenshots / Recordings

<!-- Required for any UI change. -->

## Checklist

- [ ] No `print` statements (use `dart:developer` `log`)
- [ ] No relative imports
- [ ] No `late` without guaranteed init
- [ ] No bare `catch (e)`
- [ ] Generated files committed (`.g.dart`)
- [ ] No hardcoded secrets
```

### 7.5 SOP: Conduct a PR Review

1. Read diff:

```
mcp__github__pull_request_read
  method:     "get_diff"
  pullNumber: <N>
```

2. Read changed files:

```
mcp__github__pull_request_read
  method:     "get_files"
  pullNumber: <N>
```

3. Check CI status:

```
mcp__github__pull_request_read
  method:     "get_check_runs"
  pullNumber: <N>
```

4. Start pending review (no `event` = pending):

```
mcp__github__pull_request_review_write
  method:     "create"
  pullNumber: <N>
```

5. Add inline comments (repeat per finding):

```
mcp__github__add_comment_to_pending_review
  pullNumber:  <N>
  path:        "lib/features/notation/camera_viewmodel.dart"
  line:        42
  side:        "RIGHT"
  subjectType: "LINE"
  body:        "Missing `context.mounted` check after `await`. See CLAUDE.md."
```

For file-level comments:

```
mcp__github__add_comment_to_pending_review
  pullNumber:  <N>
  path:        "lib/features/notation/camera_viewmodel.dart"
  subjectType: "FILE"
  body:        "File exceeds 800-line limit per CLAUDE.md. Split by responsibility."
```

6. Submit review:

```
mcp__github__pull_request_review_write
  method:     "submit_pending"
  pullNumber: <N>
  event:      "REQUEST_CHANGES"
  body:       "Summary: ... (numbered blockers)"
```

Or approve:

```
mcp__github__pull_request_review_write
  method:     "submit_pending"
  pullNumber: <N>
  event:      "APPROVE"
  body:       "LGTM."
```

7. After author addresses feedback:

```
mcp__github__pull_request_review_write
  method:     "submit_pending"
  pullNumber: <N>
  event:      "APPROVE"
  body:       "All feedback resolved. Approved."
```

### 7.6 SOP: Sync PR Branch with Base

When base branch has moved ahead:

```
mcp__github__update_pull_request_branch
  pullNumber: <N>
```

---

## 8. Commit Conventions

### 8.1 Format

```
<type>(<scope>): <imperative description>

[optional body — explain WHY, not WHAT]

[optional footer]
Refs: #<issue-number>
BREAKING CHANGE: <description>
```

### 8.2 Types

| Type       | When                                  |
| ---------- | ------------------------------------- |
| `feat`     | New user-visible capability           |
| `fix`      | Bug fix                               |
| `refactor` | Restructure without behavior change   |
| `docs`     | Documentation only                    |
| `test`     | Test code only                        |
| `chore`    | Build, deps, tooling, generated files |
| `perf`     | Performance improvement               |
| `ci`       | GitHub Actions / workflow files       |

### 8.3 Scopes (Swaralipi)

| Scope      | Covers                         |
| ---------- | ------------------------------ |
| `notation` | Image capture, import, display |
| `metadata` | Fields, search, filter         |
| `storage`  | Local DB, file system          |
| `ui`       | Widgets, theming, layout       |
| `nav`      | GoRouter routes                |
| `vm`       | ViewModels                     |
| `test`     | Test infrastructure            |
| `ci`       | Workflow files                 |

### 8.4 Breaking Changes

Two equivalent forms:

```
feat(storage)!: migrate schema to v2

OR in footer:

BREAKING CHANGE: all existing records require migration
```

### 8.5 Examples

```
feat(notation): add CameraX image capture flow

Wires CameraX ImageCapture use-case through NotationViewModel.
Returns Uri on success, surfaces CameraException on failure.

Refs: #18
```

```
fix(metadata): prevent crash on empty search query

Empty string passed to FTS caused SQLite exception. Added guard.

Refs: #23
```

```
chore: bump Flutter to 3.24.5
```

```
ci: add coverage threshold gate to pr-check workflow

Refs: #7
```

---

## 9. Semantic Versioning

### 9.1 Version Format

`MAJOR.MINOR.PATCH+BUILD` — matches Flutter pubspec.yaml standard.

| Segment | Bump when                                                               |
| ------- | ----------------------------------------------------------------------- |
| MAJOR   | Breaking data model change requiring migration; incompatible API change |
| MINOR   | New feature (epic or feature issue closed)                              |
| PATCH   | Bug fix, performance improvement, non-breaking refactor                 |
| BUILD   | Auto-injected by CI (`${{ github.run_number }}`) — never set manually   |

### 9.2 Version Decision Table

| Change                               | Version bump | Example           |
| ------------------------------------ | ------------ | ----------------- |
| Storage schema migration (v1→v2)     | MAJOR        | `1.0.0` → `2.0.0` |
| New image capture feature shipped    | MINOR        | `1.0.0` → `1.1.0` |
| Crash fix on rotate                  | PATCH        | `1.0.0` → `1.0.1` |
| Performance improvement (no new API) | PATCH        | `1.0.0` → `1.0.1` |

### 9.3 SOP: Create a Release

1. Check current latest release:

```
mcp__github__get_latest_release
```

2. Determine next version based on table above.

3. Update `pubspec.yaml` version field locally and commit:

```
chore: bump version to 1.2.0
```

4. Merge release branch to main using `merge` strategy (not squash).

5. Create git tag locally: `git tag v1.2.0 && git push origin v1.2.0`.

    **Gap:** MCP has no create-release or create-tag tool. The CI `release.yml` workflow creates GitHub Release automatically on tag push.

6. Monitor release — confirm creation:

```
mcp__github__get_release_by_tag
  tag: "v1.2.0"
```

7. Verify artifacts in release response.

### 9.4 Tag Strategy

| Tag             | Meaning                 |
| --------------- | ----------------------- |
| `v1.0.0`        | Full release            |
| `v1.0.0-beta.1` | Pre-release for testing |
| `v1.0.0-rc.1`   | Release candidate       |

---

## 10. GitHub Actions Workflows

**Gap:** MCP has no workflow trigger, dispatch, or run-status tools. Workarounds:

- Create / update workflow YAML files via `create_or_update_file`
- Check CI status on a PR via `pull_request_read method: get_check_runs`
- Cannot trigger `workflow_dispatch` or view Actions logs directly

### 10.1 SOP: Install PR Check Workflow

1. Check if file exists:

```
mcp__github__get_file_contents
  path: ".github/workflows/pr-check.yml"
  ref:  "main"
```

2. Write (note `sha` if updating):

```
mcp__github__create_or_update_file
  path:    ".github/workflows/pr-check.yml"
  branch:  "main"
  message: "ci: add PR check workflow"
  sha:     <sha if file exists>
  content: <base64-encoded YAML below>
```

**Workflow YAML (`pr-check.yml`):**

```yaml
name: PR Check

on:
    pull_request:
        branches: [main]

jobs:
    check:
        runs-on: ubuntu-latest

        steps:
            - uses: actions/checkout@v4

            - name: Setup Flutter
              uses: subosito/flutter-action@v2
              with:
                  flutter-version: "3.24.x"
                  channel: "stable"
                  cache: true

            - name: Install dependencies
              run: flutter pub get

            - name: Check formatting
              run: dart format --output=none --set-exit-if-changed .

            - name: Analyze
              run: flutter analyze --fatal-infos --fatal-warnings

            - name: Run code generation
              run: dart run build_runner build --delete-conflicting-outputs

            - name: Run tests
              run: flutter test --coverage --reporter=github

            - name: Check coverage threshold
              run: |
                  COVERAGE=$(lcov --summary coverage/lcov.info 2>&1 | grep "lines" | awk '{print $2}' | tr -d '%')
                  echo "Coverage: ${COVERAGE}%"
                  if (( $(echo "$COVERAGE < 80" | bc -l) )); then
                    echo "Coverage ${COVERAGE}% is below 80% threshold"
                    exit 1
                  fi

            - name: Build APK (debug)
              run: flutter build apk --debug
```

### 10.2 SOP: Install Release Workflow

Same pattern — path `.github/workflows/release.yml`:

```
mcp__github__create_or_update_file
  path:    ".github/workflows/release.yml"
  branch:  "main"
  message: "ci: add release build workflow"
  sha:     <sha if updating>
  content: <base64-encoded YAML below>
```

**Workflow YAML (`release.yml`):**

```yaml
name: Release Build

on:
    push:
        branches: [main]
    workflow_dispatch:
        inputs:
            version_bump:
                description: "Version bump type (patch|minor|major)"
                required: false
                default: "patch"

jobs:
    release:
        runs-on: ubuntu-latest

        steps:
            - uses: actions/checkout@v4

            - name: Setup Flutter
              uses: subosito/flutter-action@v2
              with:
                  flutter-version: "3.24.x"
                  channel: "stable"
                  cache: true

            - name: Install dependencies
              run: flutter pub get

            - name: Analyze
              run: flutter analyze --fatal-infos --fatal-warnings

            - name: Run code generation
              run: dart run build_runner build --delete-conflicting-outputs

            - name: Run tests
              run: flutter test --coverage

            - name: Build release AAB
              run: flutter build appbundle --release

            - name: Build release APK
              run: flutter build apk --release --split-per-abi

            - name: Upload artifacts
              uses: actions/upload-artifact@v4
              with:
                  name: swaralipi-release-${{ github.sha }}
                  path: |
                      build/app/outputs/bundle/release/app-release.aab
                      build/app/outputs/apk/release/app-arm64-v8a-release.apk
                  retention-days: 30
```

### 10.3 SOP: Check CI on a PR

After pushing commits:

```
mcp__github__pull_request_read
  method:     "get_check_runs"
  pullNumber: <N>
```

Check `conclusion` field per run: `success` / `failure` / `in_progress` / `neutral`. Do NOT merge if any check has `failure`.

---

## 11. Gaps and Workarounds

| Capability                    | MCP support                              | Workaround                                                             |
| ----------------------------- | ---------------------------------------- | ---------------------------------------------------------------------- |
| GitHub Milestones             | None                                     | Use `p0`-`p5` priority labels + epic/feature hierarchy                 |
| Branch protection rules       | None                                     | Set manually in GitHub web UI once                                     |
| GitHub Projects v2            | None                                     | Use `search_issues` with label filters as kanban view                  |
| Workflow trigger / dispatch   | None                                     | Push tag or commit; CI fires automatically                             |
| View Actions run logs         | None                                     | Use `get_check_runs` on PR for pass/fail only                          |
| Create GitHub Release         | None                                     | CI `release.yml` creates on tag push; confirm via `get_release_by_tag` |
| Milestone on issues           | `issue_write` supports `milestone` field | Milestone must be pre-created in GitHub web UI                         |
| Delete default labels         | `label_write method: delete`             | Call for each default label by exact name                              |
| Auto-assign reviewers on open | None                                     | Call `update_pull_request` with `reviewers` after opening              |
| `sub_issue_id` vs number      | Must be node ID                          | Always call `issue_read method: get` first; extract `node_id`          |

---

## 12. Worked Example: Epic → Feature → Stories → Tasks → PR → Merge

**Scenario:** Implement "Image Capture" feature for notation module.

**Step 1: Create Epic**

```
mcp__github__issue_write method: create
  title:  "[Epic] Notation Management"
  body:   <epic template>
  labels: ["epic", "planned", "p1"]

→ Response: number=1, node_id=I_kwA...aaa
```

**Step 2: Create Feature and Link to Epic**

```
mcp__github__issue_write method: create
  title:  "[Feature] Image Capture and Import"
  body:   <feature template, Parent Epic: #1>
  labels: ["feature", "planned", "p1"]

→ Response: number=2, node_id=I_kwA...bbb

mcp__github__sub_issue_write
  method:        add
  issue_number:  1
  sub_issue_id:  I_kwA...bbb
```

**Step 3: Create 2 Stories and Link to Feature**

```
mcp__github__issue_write method: create
  title:  "[Story] Capture notation image via in-app camera"
  body:   <story template>
  labels: ["story", "planned", "p1"]

→ Response: number=3, node_id=I_kwA...ccc

mcp__github__sub_issue_write
  method:        add
  issue_number:  2
  sub_issue_id:  I_kwA...ccc

--- repeat for second story ---

mcp__github__issue_write method: create
  title:  "[Story] Import notation image from gallery"
  body:   <story template>
  labels: ["story", "planned", "p1"]

→ Response: number=4, node_id=I_kwA...ddd

mcp__github__sub_issue_write
  method:        add
  issue_number:  2
  sub_issue_id:  I_kwA...ddd
```

**Step 4: Create 3 Tasks Under Story 3 and Link**

```
mcp__github__issue_write method: create
  title:  "[Task] Wire CameraX ImageCapture use-case"
  body:   <task template>
  labels: ["task", "planned", "p1"]

→ Response: number=5

mcp__github__sub_issue_write method: add, issue_number: 3, sub_issue_id: <node_id>

--- repeat for tasks 6, 7 ---
```

**Step 5: Start Work on Task 5**

```
mcp__github__issue_write method: update
  issue_number: 5
  labels:       ["task", "in-progress", "p1"]

mcp__github__create_branch
  branch:      "task/5-camerax-wiring"
  from_branch: "main"
```

**Step 6: Code Locally**

Commit with: `feat(notation): wire CameraX to ImageCapture use-case (#5)`

**Step 7: Open PR as Draft**

```
mcp__github__create_pull_request
  title:  "feat(notation): wire CameraX to ImageCapture use-case"
  head:   "task/5-camerax-wiring"
  base:   "main"
  draft:  true
  body:   "Closes #5\n\n## Summary\n- Wires CameraX to ViewModel\n- Returns Uri on success\n\n## Test Plan\n- [ ] Unit tests written\n- [ ] Coverage ≥ 80%\n..."

→ Response: number=123
```

**Step 8: Check CI**

```
mcp__github__pull_request_read method: get_check_runs
  pullNumber: 123

→ Confirm all checks: success
```

**Step 9: Mark Ready for Review**

```
mcp__github__update_pull_request
  pullNumber: 123
  draft:      false
  reviewers:  ["Roudranil"]
```

**Step 10: Review**

```
mcp__github__pull_request_read method: get_diff
  pullNumber: 123

--- inspect code ---

mcp__github__pull_request_review_write method: create
  pullNumber: 123

mcp__github__add_comment_to_pending_review
  pullNumber:  123
  path:        "lib/features/notation/camera_viewmodel.dart"
  line:        42
  side:        "RIGHT"
  subjectType: "LINE"
  body:        "Missing context.mounted check after await."

mcp__github__pull_request_review_write method: submit_pending
  pullNumber: 123
  event:      "REQUEST_CHANGES"
  body:       "Please add context.mounted check per CLAUDE.md."
```

**Step 11: Author Fixes, Reviewer Approves**

```
mcp__github__pull_request_review_write method: submit_pending
  pullNumber: 123
  event:      "APPROVE"
  body:       "LGTM."
```

**Step 12: Merge**

```
mcp__github__merge_pull_request
  pullNumber:   123
  merge_method: "squash"
  commit_title: "feat(notation): wire CameraX to ImageCapture use-case (#5)"
```

**Step 13: Close Task**

```
mcp__github__issue_write method: update
  issue_number: 5
  state:        "closed"
  state_reason: "completed"
```

**Step 14: Repeat for Tasks 6 & 7 → Story 3 auto-closes when all tasks closed → Feature 2 auto-closes when all stories closed → Epic 1 auto-closes when all features closed.**

---

## 13. Activation Checklist

**Shortcut:** Run the `bootstrap-repo.sh` script to execute all checklist items in a single command:

```bash
./.claude/skills/github-project-management/scripts/bootstrap-repo.sh --dry-run
# Review the JSON output, then:
./.claude/skills/github-project-management/scripts/bootstrap-repo.sh
```

**Manual checklist** (if not using the script):

- [ ] `OWNER = Roudranil`, `REPO = swaralipi-app` (or query with user if different repo)
- [ ] All 14 labels exist → run `mcp__github__list_label`; bootstrap if missing (Section 4.2)
- [ ] Issue templates exist at `.github/ISSUE_TEMPLATE/` → check via `get_repository_tree`; write if missing (Section 6)
- [ ] PR template exists at `.github/pull_request_template.md` → check via `get_file_contents`; write if missing (Section 7.4)
- [ ] Workflow files exist at `.github/workflows/pr-check.yml` and `release.yml` → check; write if missing (Section 10)
- [ ] **Critical:** `sub_issue_id` must be `node_id` (e.g., `I_kwDO...`), NOT issue number — always fetch `node_id` via `issue_read method: get` first

---

## 14. Scripts Reference

Seven production-ready bash scripts automate multi-step workflows, output machine-parseable JSON, and support `--dry-run` mode. Located in `.claude/skills/github-project-management/scripts/`.

### 14.1 `bootstrap-labels.sh`

**Purpose:** Create or verify all 14 taxonomy labels; optionally delete GitHub defaults.

**Usage:**

```bash
./bootstrap-labels.sh [--delete-defaults] [--force-update] [--dry-run]
```

**Output:** JSON with `created`, `already_existed`, `deleted_defaults`, `missing_after` arrays and `success` flag.

**When to use:** Before any project work; after merging SKILL.md label changes.

---

### 14.2 `create-issue.sh`

**Purpose:** Create GitHub issue + auto-link parent + add to project + set Status/Priority/Size fields (5-6 MCP calls → 1 command).

**Usage:**

```bash
./create-issue.sh --type <epic|feature|story|task|bug> --title "<title>" \
  [--parent <number>] [--priority <p0..p5>] [--status <status>] [--size <xs..xl>] \
  [--body <text> | --body-file <path>] [--assignee <login>] [--no-project] [--dry-run]
```

**Output:** JSON with `issue_number`, `node_id`, `url`, `labels`, `parent_linked`, `project_item_id`, `project_fields_set`.

**When to use:** In place of Sections 5.2-5.6 multi-step SOPs.

---

### 14.3 `link-sub-issue.sh`

**Purpose:** Link existing child to parent via GraphQL `addSubIssue` (2 calls → 1 command).

**Usage:**

```bash
./link-sub-issue.sh --parent <number> --child <number> [--replace-parent] [--dry-run]
```

**Output:** JSON with parent/child details and `success` flag.

**When to use:** In place of Section 2.2 / Section 5.3-5.5 step 3.

---

### 14.4 `set-project-fields.sh`

**Purpose:** Add issue to project + set Status/Priority/Size fields (4 calls → 1 command).

**Usage:**

```bash
./set-project-fields.sh --issue <number> \
  [--status <backlog|ready|in_progress|in_review|done>] \
  [--priority <P0|P1|P2>] [--size <xs|s|m|l|xl>] \
  [--item-id <id>] [--dry-run]
```

**Output:** JSON with `issue_number`, `project_item_id`, `fields_set` object.

**When to use:** In place of Section 2.3 manual project field edits.

---

### 14.5 `transition-issue.sh`

**Purpose:** Change issue state (update labels, set project Status, optionally close/comment) — delta label updates, not full replacement.

**Usage:**

```bash
./transition-issue.sh --issue <number> --to <ready|in_progress|in_review|done|blocked> \
  --type <epic|feature|story|task|bug> --priority <p0..p5> \
  [--blocked-by <number> --blocked-reason "<text>"] [--dry-run]
```

**Output:** JSON with `from_state`, `to_state`, `labels_updated`, `project_status_set`, `issue_closed`, `comment_posted` flags.

**When to use:** In place of Section 5.7 workflow transitions.

---

### 14.6 `create-branch-pr.sh`

**Purpose:** Create branch + open draft PR with pre-filled template (3 calls → 1 command).

**Usage:**

```bash
./create-branch-pr.sh --issue <number> --type <feature|story|task|bug|chore|release> --slug <kebab-slug> \
  [--title "<title>"] [--scope <scope>] [--base <branch>] [--from <branch>] [--no-draft] [--dry-run]
```

**Output:** JSON with `branch`, `pr_number`, `pr_url`, `pr_title`, `draft` flag.

**When to use:** In place of Section 7.2 manual branch + PR creation.

---

### 14.7 `bootstrap-repo.sh`

**Purpose:** One-command full repo setup: labels + issue templates + PR template + CI workflows.

**Usage:**

```bash
./bootstrap-repo.sh [--delete-default-labels] \
  [--skip-labels] [--skip-templates] [--skip-pr-template] [--skip-workflows] \
  [--branch <branch>] [--dry-run]
```

**Output:** JSON with nested reports for labels, issue templates, PR template, and workflows.

**When to use:** Fresh repo setup or Section 13 Activation Checklist.

---

### 14.8 Shared Library: `lib/constants.sh`

**Purpose:** Sourced by all scripts. Provides:

- Fixed IDs: `OWNER`, `REPO`, `PROJECT_NUMBER`, `PROJECT_ID`
- Field/option ID maps: `STATUS_OPTS`, `PRIORITY_OPTS`, `SIZE_OPTS` (bash associative arrays)
- Label taxonomy: `LABEL_COLOR`, `LABEL_DESC`
- Helper functions: `die()`, `log()`, `dry_run_or_exec()`, `json_output()`, etc.

**Never executed directly** — only sourced via `source "$SCRIPT_DIR/lib/constants.sh"` at the top of each script.

---

### 14.9 Common Patterns Across All Scripts

1. **Error handling:** `set -euo pipefail` + bash 4+ check (for associative arrays)
2. **Output discipline:**
    - **stdout:** Machine-parseable JSON only (for agent parsing)
    - **stderr:** Human-readable progress via `log()`, errors via `die()`
3. **Dry-run support:** Pass `--dry-run` flag or set `DRY_RUN=1` env var
4. **Help text:** Every script supports `--help` / `-h`
5. **Tools verification:** Each script calls `require_cmd gh jq` etc. at startup
6. **Idempotency:** `bootstrap-labels.sh`, `set-project-fields.sh`, and `bootstrap-repo.sh` are re-runnable; others create new state by design

---

### 14.10 Integration with SKILL.md Sections

| SKILL.md Section               | Corresponding Script    | Usage                                                                         |
| ------------------------------ | ----------------------- | ----------------------------------------------------------------------------- |
| 4.2 (Bootstrap SOP)            | `bootstrap-labels.sh`   | `./bootstrap-labels.sh [--delete-defaults]`                                   |
| 5.2-5.6 (Issue creation SOPs)  | `create-issue.sh`       | `./create-issue.sh --type <type> --title <title> [--parent <n>]`              |
| 2.2 (Sub-issue linking)        | `link-sub-issue.sh`     | `./link-sub-issue.sh --parent <n> --child <m>`                                |
| 2.3 (Project field management) | `set-project-fields.sh` | `./set-project-fields.sh --issue <n> --status <s> --priority <P>`             |
| 5.7 (Update issue status)      | `transition-issue.sh`   | `./transition-issue.sh --issue <n> --to <state> --type <type> --priority <p>` |
| 7.2 (Open a PR)                | `create-branch-pr.sh`   | `./create-branch-pr.sh --issue <n> --type <type> --slug <slug>`               |
| 13 (Activation Checklist)      | `bootstrap-repo.sh`     | `./bootstrap-repo.sh [--dry-run]`                                             |
