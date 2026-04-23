---
name: github-project-management
description: >
    Full GitHub project management via MCP tools and gh CLI — label taxonomy (epic → feature → story → task / bug),
    issue hierarchy with sub-issue linking, PR workflow (branch naming, review, merge strategies),
    and GitHub Actions setup. Includes gh CLI for project field management and GraphQL for sub-issue creation.
    Use whenever creating or managing issues, PRs, labels, or repo scaffolding files on Swaralipi.
---

# GitHub Project Management via MCP Skill

## 1. Constants & Scope

Every tool call in this skill uses these values:

```
OWNER = Roudranil
REPO  = swaralipi-app
PROJECT = 4 (Swaralipi)
```

**⚠️ CRITICAL BOUNDARY:** This skill operates ONLY on `Roudranil/swaralipi-app` (project #4). Other projects (variance, Lattice) are strictly off-bounds.

---

## 2. MCP Tool Quick-Reference

| Purpose                 | Tool                                         | Key Parameters                                                                                                                         |
| ----------------------- | -------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------- |
| Create / update issue   | `mcp__github__issue_write`                   | `method` (`create`/`update`), `title`, `body`, `labels[]`, `assignees[]`, `issue_number` (for update)                                  |
| Read issue / sub-issues | `mcp__github__issue_read`                    | `method` (`get`/`get_comments`/`get_sub_issues`/`get_labels`), `issue_number`                                                          |
| List issues             | `mcp__github__list_issues`                   | `state`, `labels[]`, `since`, `orderBy`, `direction`                                                                                   |
| Search issues           | `mcp__github__search_issues`                 | `query` (GitHub search syntax: `is:open label:task label:p0`)                                                                          |
| Comment on issue        | `mcp__github__add_issue_comment`             | `issue_number`, `body`                                                                                                                 |
| Link parent ↔ child     | `mcp__github__sub_issue_write`               | `method` (`add`/`remove`/`reprioritize`), `issue_number` (parent), `sub_issue_id` (child **node ID**, NOT number)                      |
| Create label            | `mcp__github__label_write`                   | `method: create`, `name`, `color` (hex without `#`), `description`                                                                     |
| List labels             | `mcp__github__list_label`                    | —                                                                                                                                      |
| Create branch           | `mcp__github__create_branch`                 | `branch`, `from_branch`                                                                                                                 |
| Open PR                 | `mcp__github__create_pull_request`           | `title`, `head`, `base`, `body`, `draft`                                                                                               |
| Update PR               | `mcp__github__update_pull_request`           | `pullNumber`, `title`, `body`, `state`, `draft`, `reviewers[]`, `base`                                                                  |
| Read PR                 | `mcp__github__pull_request_read`             | `method` (`get`/`get_diff`/`get_status`/`get_files`/`get_review_comments`/`get_reviews`/`get_comments`/`get_check_runs`), `pullNumber` |
| Start pending review    | `mcp__github__pull_request_review_write`     | `method: create`, `pullNumber`                                                                                                          |
| Add inline comment      | `mcp__github__add_comment_to_pending_review` | `pullNumber`, `path`, `line`, `side` (`LEFT`/`RIGHT`), `subjectType` (`FILE`/`LINE`), `body`                                           |
| Submit review           | `mcp__github__pull_request_review_write`     | `method: submit_pending`, `pullNumber`, `event` (`APPROVE`/`REQUEST_CHANGES`/`COMMENT`), `body`                                        |
| Merge PR                | `mcp__github__merge_pull_request`            | `pullNumber`, `merge_method` (`squash`/`merge`/`rebase`), `commit_title`, `commit_message`                                             |
| Update PR branch        | `mcp__github__update_pull_request_branch`    | `pullNumber`                                                                                                                           |
| Write file to repo      | `mcp__github__create_or_update_file`         | `path`, `content`, `message`, `branch`, `sha` (required if file exists)                                                               |
| Read file from repo     | `mcp__github__get_file_contents`             | `path`, `ref`                                                                                                                          |
| Latest release          | `mcp__github__get_latest_release`            | —                                                                                                                                      |
| Release by tag          | `mcp__github__get_release_by_tag`            | `tag`                                                                                                                                  |

**Critical:** `sub_issue_id` is the GitHub **node ID** (`I_kwDO...`), NOT the issue number. Always fetch via `issue_read method: get` first.

---

## 2.1 GitHub CLI (`gh`) Quick-Reference

| Purpose                | Command                                                                                                               |
| ---------------------- | --------------------------------------------------------------------------------------------------------------------- |
| List project items     | `gh project item-list 4 --owner Roudranil`                                                                            |
| Add issue to project   | `gh project item-add 4 --owner Roudranil --url <issue-url>`                                                           |
| Edit project item field| `gh project item-edit --id <item-id> --project-id <proj-id> --field-id <field-id> --single-select-option-id <opt-id>` |
| Close issue            | `gh issue close <number> --repo Roudranil/swaralipi-app`                                                              |
| Add sub-issue (GraphQL)| `gh api graphql -f query='mutation { addSubIssue(input: {...}) { ... } }'` — see Section 2.2                         |

### 2.2 Sub-Issue Management via GraphQL

```bash
gh api graphql -f query='
  mutation {
    addSubIssue(input: {
      issueId: "<parent-node-id>"
      subIssueUrl: "https://github.com/Roudranil/swaralipi-app/issues/<child-number>"
      replaceParent: false
    }) {
      issue { id number title }
    }
  }
'
```

**Parameters:** `issueId` = parent node ID · `subIssueUrl` = child issue URL · `replaceParent` = set true to replace existing parent.

### 2.3 Project Field IDs (Swaralipi — project `PVT_kwHOA51EZs4BVe4H`)

| Field    | Field ID                           | Option      | Option ID  |
| -------- | ---------------------------------- | ----------- | ---------- |
| Status   | `PVTSSF_lAHOA51EZs4BVe4HzhQ6YbE`  | Backlog     | `f75ad846` |
|          |                                    | Ready       | `e18bf179` |
|          |                                    | In progress | `47fc9ee4` |
|          |                                    | In review   | `aba860b9` |
|          |                                    | Done        | `98236657` |
| Priority | `PVTSSF_lAHOA51EZs4BVe4HzhQ6Yig`  | P0          | `79628723` |
|          |                                    | P1          | `0a877460` |
|          |                                    | P2          | `da944a9c` |
| Size     | `PVTSSF_lAHOA51EZs4BVe4HzhQ6Yik`  | XS          | `911790be` |
|          |                                    | S           | `b277fb01` |
|          |                                    | M           | `86db8eb3` |
|          |                                    | L           | `853c8207` |
|          |                                    | XL          | `2d0801e2` |

---

## 3. Label Taxonomy

### 3.1 Color Palette

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

### 3.2 Bootstrap SOP

Run `bootstrap-labels.sh` (see Section 7). Manual alternative:

1. `mcp__github__list_label` — check existing
2. For each missing label: `mcp__github__label_write method: create`
3. Verify: `mcp__github__list_label` → confirm all 14 present

---

## 4. Issue Hierarchy

```
Epic  (label: epic)
 └── Feature  (label: feature)     ← sub-issue of epic
      └── Story  (label: story)    ← sub-issue of feature
           └── Task  (label: task) ← sub-issue of story
Bug  (label: bug)                  ← standalone or linked to any level
```

**Preferred:** use `create-issue.sh` script (Section 7). MCP-only fallback below.

### 4.1 Create an Issue (MCP fallback)

| Type    | Title prefix | Labels                      | Required `--body` sections                             |
| ------- | ------------ | --------------------------- | ------------------------------------------------------ |
| Epic    | `[Epic]`     | `epic, planned, p<N>`       | Goal, Scope, Out of Scope, AC, References, Notes       |
| Feature | `[Feature]`  | `feature, planned, p<N>`    | Parent Epic, Goal, Scope, Out of Scope, AC, References |
| Story   | `[Story]`    | `story, planned, p<N>`      | Parent Epic, Parent Feature, User Story, AC, References|
| Task    | `[Task]`     | `task, planned, p<N>`       | Parent Story, What, Definition of Done, References     |
| Bug     | `[Bug]`      | `bug, p<N>`                 | Summary, Steps, Expected, Actual, Env, Priority        |

```
mcp__github__issue_write
  method: "create"
  title:  "[Epic] <name>"
  body:   <filled template>
  labels: ["epic", "planned", "p1"]
```

After creation, note the returned `number` and `node_id`.

### 4.2 Link Child to Parent

```
mcp__github__sub_issue_write
  method:        "add"
  issue_number:  <parent-number>
  sub_issue_id:  <child-node-id>   ← must be node_id, not issue number
```

### 4.3 Update Issue Status

**When starting work:**
```
mcp__github__issue_write  method: update  issue_number: <N>  labels: ["<type>", "in-progress", "p<N>"]
```

**When blocked:**
```
mcp__github__issue_write  method: update  issue_number: <N>  labels: ["<type>", "blocked", "p<N>"]
mcp__github__add_issue_comment  issue_number: <N>  body: "🚫 Blocked by #<N>. Reason: <one sentence>."
```

**When complete:**
```
mcp__github__issue_write  method: update  issue_number: <N>  state: "closed"  state_reason: "completed"
```

### 4.4 Inspect Hierarchy

```
# Sub-issues of a parent
mcp__github__issue_read  method: "get_sub_issues"  issue_number: <parent-number>

# All open tasks
mcp__github__search_issues  query: "repo:Roudranil/swaralipi-app is:open label:task"

# By priority
mcp__github__search_issues  query: "repo:Roudranil/swaralipi-app is:open label:p0"

# Blocked
mcp__github__search_issues  query: "repo:Roudranil/swaralipi-app is:open label:blocked"
```

---

## 5. Issue Templates

Templates live in `.github/ISSUE_TEMPLATE/` (one file per type). Reference in this skill at `ISSUE_TEMPLATE/`:

| Type    | File           | Required fields                                                          |
| ------- | -------------- | ------------------------------------------------------------------------ |
| Epic    | `epic.yml`     | Goal, Scope, Out of Scope, Acceptance Criteria, References               |
| Feature | `feature.yml`  | Parent Epic, Goal, Scope, Out of Scope, Acceptance Criteria, References  |
| Story   | `story.yml`    | Parent Epic, Parent Feature, User Story, Acceptance Criteria, References |
| Task    | `task.yml`     | Parent Story, What, Definition of Done, References                       |
| Bug     | `bug.yml`      | Summary, Steps, Expected Behavior, Actual Behavior, Environment          |

To push/update templates to the repo, run `bootstrap-repo.sh` (reads canonical YML files). Manual alternative:

```
mcp__github__get_file_contents  path: ".github/ISSUE_TEMPLATE/epic.yml"  ref: "main"
# Note the `sha` field if the file exists, then:
mcp__github__create_or_update_file
  path:    ".github/ISSUE_TEMPLATE/epic.yml"
  branch:  "main"
  message: "chore: update epic issue template"
  sha:     <sha if updating>
  content: <base64-encoded YML>
```

---

## 6. PR Workflow

### 6.1 Branch Naming

| Type    | Pattern                   | Example                    |
| ------- | ------------------------- | -------------------------- |
| Feature | `feature/<number>-<slug>` | `feature/12-image-capture` |
| Story   | `story/<number>-<slug>`   | `story/15-camera-ui`       |
| Task    | `task/<number>-<slug>`    | `task/18-camerax-wiring`   |
| Bug     | `bug/<number>-<slug>`     | `bug/23-crash-rotate`      |
| Chore   | `chore/<slug>`            | `chore/update-flutter`     |
| Release | `release/<version>`       | `release/1.2.0`            |

### 6.2 Open a PR

**Preferred:** use `create-branch-pr.sh` (Section 7).

MCP fallback:

```
# 1. Create branch
mcp__github__create_branch  branch: "task/18-camerax-wiring"  from_branch: "main"

# 2. Open draft PR (body = pull_request_template.md content, Closes #<issue> filled in)
mcp__github__create_pull_request
  title: "feat(notation): wire CameraX to ImageCapture use-case"
  head:  "task/18-camerax-wiring"
  base:  "main"
  draft: true
  body:  <PR template filled>

# 3. When ready for review
mcp__github__update_pull_request  pullNumber: <N>  draft: false  reviewers: ["Roudranil"]
```

### 6.3 Merge Strategies

| Scenario               | Method   |
| ---------------------- | -------- |
| Task / Story / Bug     | `merge` |
| Feature / Release → main | `merge` |

```
mcp__github__merge_pull_request
  pullNumber:   <N>
  merge_method: "squash"
  commit_title: "feat(notation): wire CameraX to ImageCapture use-case (#18)"
```

### 6.4 PR Review SOP

```
# 1. Read diff
mcp__github__pull_request_read  method: "get_diff"  pullNumber: <N>

# 2. Check CI
mcp__github__pull_request_read  method: "get_check_runs"  pullNumber: <N>

# 3. Start pending review
mcp__github__pull_request_review_write  method: "create"  pullNumber: <N>

# 4. Add inline comment (repeat per finding)
mcp__github__add_comment_to_pending_review
  pullNumber: <N>  path: "lib/..."  line: 42  side: "RIGHT"  subjectType: "LINE"  body: "..."

# 5. Submit
mcp__github__pull_request_review_write
  method: "submit_pending"  pullNumber: <N>  event: "REQUEST_CHANGES"  body: "..."
  # or event: "APPROVE"
```

### 6.5 Sync PR Branch

```
mcp__github__update_pull_request_branch  pullNumber: <N>
```

### 6.6 PR Template

The PR template is at `.github/pull_request_template.md`. Sections: Linked Issue · Summary · Type of Change · Commit Convention · Test Plan · Screenshots/Recordings · Checklist.

Commit convention: `type(scope): description (#issue)` — squash commit must follow this format.

---

## 7. Scripts Reference

All scripts are in `.claude/skills/github-project-management/scripts/`. All support `--dry-run` and output machine-parseable JSON on stdout / progress on stderr.

| Script                | Purpose                                                         | Key flags                                                        |
| --------------------- | --------------------------------------------------------------- | ---------------------------------------------------------------- |
| `bootstrap-labels.sh` | Create/verify all 14 labels; optionally delete GitHub defaults  | `--delete-defaults` `--force-update`                             |
| `bootstrap-repo.sh`   | Push labels + issue templates + PR template to repo             | `--delete-default-labels` `--skip-labels` `--skip-templates` `--skip-pr-template` `--branch` |
| `create-issue.sh`     | Create issue + link parent + add to project + set fields        | `--type` `--title` `--parent` `--priority` `--status` `--size` `--body` `--body-file` `--assignee` `--no-project` |
| `link-sub-issue.sh`   | Link existing child to parent via GraphQL                       | `--parent` `--child` `--replace-parent`                          |
| `set-project-fields.sh`| Add issue to project + set Status/Priority/Size                | `--issue` `--status` `--priority` `--size` `--item-id`           |
| `transition-issue.sh` | Change issue state: labels + project status + close/comment     | `--issue` `--to` `--type` `--priority` `--blocked-by` `--blocked-reason` |
| `create-branch-pr.sh` | Create branch + open draft PR with pre-filled template          | `--issue` `--type` `--slug` `--title` `--scope` `--base` `--from` `--no-draft` |

**Common patterns:**
- `set -euo pipefail` + Bash 4+ check
- stdout: JSON only · stderr: `log()` progress, `die()` errors
- `DRY_RUN=1` env var or `--dry-run` flag
- `require_cmd gh jq` at startup
- `lib/constants.sh` sourced by all scripts (provides IDs, mappings, helpers)

---

## 8. Gaps & Workarounds

| Capability                    | MCP support | Workaround                                                                     |
| ----------------------------- | ----------- | ------------------------------------------------------------------------------ |
| GitHub Milestones             | None        | Use `p0`–`p5` labels + epic/feature hierarchy                                  |
| Branch protection rules       | None        | Set manually in GitHub web UI once                                             |
| Workflow trigger / dispatch   | None        | Push tag or commit; CI fires automatically                                     |
| View Actions run logs         | None        | Use `get_check_runs` on PR for pass/fail status                                |
| Create GitHub Release         | None        | CI `release.yml` creates on tag push; confirm via `get_release_by_tag`         |
| Delete default labels         | `label_write method: delete` | Call for each default label by exact name                     |
| Auto-assign reviewers         | None        | Call `update_pull_request` with `reviewers` after opening                      |
| `sub_issue_id` vs number      | Must be node ID | Always call `issue_read method: get` first; extract `node_id`              |

---

## 9. Activation Checklist

Run once on a fresh repo or to verify state:

```bash
# Dry-run first, then execute
./.claude/skills/github-project-management/scripts/bootstrap-repo.sh --dry-run
./.claude/skills/github-project-management/scripts/bootstrap-repo.sh
```

Manual verification:
- [ ] All 14 labels exist → `mcp__github__list_label`
- [ ] Issue templates at `.github/ISSUE_TEMPLATE/` → `mcp__github__get_repository_tree`
- [ ] PR template at `.github/pull_request_template.md` → `mcp__github__get_file_contents`
- [ ] **`sub_issue_id` must be `node_id`** — always fetch before linking

---

## 10. Worked Example (Epic → Task → PR → Merge)

| Step | Action | Tool / Script |
|------|--------|---------------|
| 1 | Create epic | `create-issue.sh --type epic --title "Notation Management" --priority p1` |
| 2 | Create feature, link to epic | `create-issue.sh --type feature --title "Image Capture" --parent <epic#> --priority p1` |
| 3 | Create stories, link to feature | `create-issue.sh --type story --title "..." --parent <feature#> --priority p1` |
| 4 | Create tasks, link to story | `create-issue.sh --type task --title "Wire CameraX" --parent <story#> --priority p1` |
| 5 | Start work — update state | `transition-issue.sh --issue <task#> --to in_progress --type task --priority p1` |
| 6 | Create branch + draft PR | `create-branch-pr.sh --issue <task#> --type task --slug camerax-wiring --scope notation` |
| 7 | Commit locally | `feat(notation): wire CameraX to ImageCapture use-case (#<task#>)` |
| 8 | Check CI | `mcp__github__pull_request_read method: get_check_runs pullNumber: <PR#>` |
| 9 | Mark ready, assign reviewer | `mcp__github__update_pull_request pullNumber: <PR#> draft: false reviewers: ["Roudranil"]` |
| 10 | Review + approve | `pull_request_review_write method: submit_pending event: APPROVE` |
| 11 | Squash merge | `mcp__github__merge_pull_request pullNumber: <PR#> merge_method: squash` |
| 12 | Close task | `transition-issue.sh --issue <task#> --to done --type task --priority p1` |
| 13 | Repeat for remaining tasks → stories → features → epic | — |
