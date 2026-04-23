# GitHub CLI for Project Management

Testing and integration of `gh` CLI capabilities for Swaralipi project management.

## Overview

The `gh` CLI provides powerful project management features that complement the MCP tools. This document outlines tested capabilities and integration patterns.

## Tested Capabilities

All capabilities have been verified with dummy test issues (now closed).

### 1. Project Discovery

```bash
# List all projects for owner
gh project list --owner Roudranil

# Output:
# 4  Swaralipi  open  PVT_kwHOA51EZs4BVe4H
# 3  variance   open  PVT_kwHOA51EZs4BVe4H
# 2  Lattice    open  PVT_kwHOA51EZs4BVe4H
```

**Status:** ✅ Verified

### 2. Project Details

```bash
# View project information
gh project view 4 --owner Roudranil

# Returns:
# - Project title, description, visibility
# - Item count
# - Field list with types
# - Project URL
```

**Status:** ✅ Verified

### 3. Add Issue to Project

```bash
gh project item-add 4 --owner Roudranil \
  --url "https://github.com/Roudranil/swaralipi-app/issues/5"
```

**Notes:**
- Use `--url` flag (not `--id`)
- Issue must exist before adding to project
- No confirmation output on success

**Status:** ✅ Verified

### 4. Update Project Item Fields

#### Field IDs (Swaralipi Project #4)

Query available fields and options:

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

#### Supported Fields

| Field | Type | Options |
|---|---|---|
| Status | Single Select | Backlog, Ready, In progress, In review, Done |
| Priority | Single Select | P0, P1, P2 |
| Size | Single Select | XS, S, M, L, XL |

#### Update Syntax

```bash
gh project item-edit \
  --id PVTI_lAHOA51EZs4BVe4Hzgqxpms \
  --project-id PVT_kwHOA51EZs4BVe4H \
  --field-id PVTSSF_lAHOA51EZs4BVe4HzhQ6YbE \
  --single-select-option-id 47fc9ee4
```

**Parameters:**
- `--id`: Item ID from `gh project item-list` output
- `--project-id`: Project ID from `gh project view` or GraphQL query
- `--field-id`: Field ID from field query (single-select field)
- `--single-select-option-id`: Option ID for the value to set

**Status:** ✅ Verified for Status, Priority, and Size

### 5. Create Sub-Issues via GraphQL

Sub-issues cannot be created via `gh issue` flags. Use GraphQL mutation:

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
- `issueId` (required): Parent issue node ID (format: `I_kwDO...`)
- `subIssueUrl` (required): URL of child issue
- `replaceParent` (optional): Set true to replace existing parent

**Verification:**

```bash
gh api graphql -f query='
  query {
    repository(owner: "Roudranil", name: "swaralipi-app") {
      issue(number: 5) {
        subIssues(first: 10) {
          nodes {
            number
            title
          }
        }
      }
      issue(number: 6) {
        parent {
          ... on Issue {
            number
            title
          }
        }
      }
    }
  }
'

# Verified relationship:
# Issue #5: subIssues = [#6]
# Issue #6: parent = #5
```

**Status:** ✅ Verified

### 6. Create and Manage Issues

```bash
# Create issue with labels
gh issue create --repo Roudranil/swaralipi-app \
  --title "[Task] Description" \
  --body "Detailed description" \
  --label epic,planned,p1

# Close issues
gh issue close 5 --repo Roudranil/swaralipi-app
```

**Status:** ✅ Verified

## Integration Pattern: Complete Workflow

```bash
# 1. Create issue
ISSUE_URL=$(gh issue create --repo Roudranil/swaralipi-app \
  --title "[Task] Work item" \
  --body "Details" \
  --label task,planned,p1 \
  --json url --query .url)

ISSUE_NUMBER=$(echo $ISSUE_URL | grep -oP 'issues/\K\d+')

# 2. Add to project
gh project item-add 4 --owner Roudranil --url "$ISSUE_URL"

# 3. Get item ID from project (needed for field updates)
ITEM_ID=$(gh project item-list 4 --owner Roudranil | \
  grep "#$ISSUE_NUMBER" | awk '{print $NF}')

# 4. Update project fields
gh project item-edit \
  --id "$ITEM_ID" \
  --project-id PVT_kwHOA51EZs4BVe4H \
  --field-id PVTSSF_lAHOA51EZs4BVe4HzhQ6Yig \
  --single-select-option-id 0a877460  # P1

# 5. Link as sub-issue (if parent already exists)
PARENT_ID="I_kwDOSKa3F88AAAABAUB0IA"  # Issue #5 node ID
gh api graphql -f query="
  mutation {
    addSubIssue(input: {
      issueId: \"$PARENT_ID\"
      subIssueUrl: \"$ISSUE_URL\"
    }) {
      issue {
        number
        title
      }
    }
  }
"
```

## When to Use `gh` CLI vs MCP Tools

| Task | Tool | Why |
|---|---|---|
| Create issue | MCP (`issue_write`) | More control over templates/labels |
| Update issue fields | MCP (`issue_write`) | Simpler API for GitHub issues |
| Add issue to project | `gh` CLI | Native project support |
| Update project Status/Priority/Size | `gh` CLI (`project item-edit`) | Direct field manipulation |
| Link parent-child issues | GraphQL via `gh api graphql` | Native sub-issue support |
| Manage PR workflow | MCP (`pull_request_*`) | Rich PR-specific tools |
| Search issues | MCP (`search_issues`) | Better query syntax |

## Limitations & Gaps

| Capability | Status | Workaround |
|---|---|---|
| gh CLI sub-issue create flags | Not available | Use GraphQL `addSubIssue` mutation |
| Milestones via gh | Requires manual creation | Create in GitHub web UI, then link via `gh issue edit` |
| Custom field types | Limited support | Query GraphQL to understand field structure |
| Bulk operations | Limited | Use shell loops with gh commands |

## Reference

- **Swaralipi Project ID:** `4`
- **Project Node ID:** `PVT_kwHOA51EZs4BVe4H`
- **Repository:** Roudranil/swaralipi-app

## Resources

- `gh` CLI docs: `gh --help`, `gh project --help`
- GitHub GraphQL: `gh api graphql --help`
- Test results: Issues #5–6 (now closed)
