#!/usr/bin/env bash
# Create a GitHub issue with full setup: labels, project board, sub-issue linking, field setting.
# Output: JSON report with issue details and linked/project status.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/constants.sh"

# =============================================================================
# Globals
# =============================================================================

ISSUE_TYPE=""
ISSUE_TITLE=""
ISSUE_BODY=""
PARENT_NUMBER=""
PRIORITY="p2"
STATUS="backlog"
SIZE=""
ASSIGNEE=""
NO_PROJECT=0
DRY_RUN=${DRY_RUN:-0}

# =============================================================================
# Default Issue Templates
# =============================================================================

template_epic() {
  cat <<'EOF'
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
<!-- p0–p5 -->

## Notes
EOF
}

template_feature() {
  cat <<'EOF'
## Parent Epic
<!-- #<epic-number> -->

## Goal
<!-- What capability does this feature add? -->

## Stories
- [ ] #<story-number>

## Acceptance Criteria
<!-- How do we know this is done? -->

## Priority
<!-- p0–p5 -->

## Notes
EOF
}

template_story() {
  cat <<'EOF'
## Parent Feature
<!-- #<feature-number> -->

## User Story
As a <role>, I can <action> so that <value>.

## Tasks
- [ ] #<task-number>

## Acceptance Criteria
<!-- How do we know this is done? -->

## Priority
<!-- p0–p5 -->
EOF
}

template_task() {
  cat <<'EOF'
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
<!-- p0–p5 -->
EOF
}

template_bug() {
  cat <<'EOF'
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
<!-- p0–p5 -->

## Linked Issue (if applicable)
<!-- #<issue-number> -->
EOF
}

# =============================================================================
# Usage
# =============================================================================

usage() {
  cat <<EOF
Usage: $(basename "$0") --type TYPE --title TITLE [OPTIONS]

Create a GitHub issue with full project setup (labels, project board, linking, fields).

REQUIRED OPTIONS:
  --type TYPE         Issue type: epic, feature, story, task, bug
  --title TITLE       Issue title (prefix like [Epic] auto-added)

OPTIONAL OPTIONS:
  --body TEXT         Issue body (uses type template if omitted)
  --body-file PATH    Read body from file instead
  --parent NUMBER     Parent issue number (creates sub-issue relationship)
  --priority P0..P5   Label priority (default: p2)
  --status STATUS     Project status: backlog, ready, in_progress, in_review, done (default: backlog)
  --size SIZE         Project size: xs, s, m, l, xl (omitted = unset)
  --assignee LOGIN    Assign to GitHub login
  --no-project        Skip adding to project (for standalone bugs)
  --dry-run           Print gh calls without executing
  --help              Print this help message

EXAMPLES:
  # Create a task linked to story 15
  create-issue.sh --type task --title "Wire CameraX to ViewModel" --parent 15 --priority p1

  # Create an epic with custom body
  create-issue.sh --type epic --title "Image Capture" --body-file ./epic-body.md

EOF
}

# =============================================================================
# Parse Arguments
# =============================================================================

while [[ $# -gt 0 ]]; do
  case "$1" in
    --type) ISSUE_TYPE="$2"; shift 2 ;;
    --title) ISSUE_TITLE="$2"; shift 2 ;;
    --body) ISSUE_BODY="$2"; shift 2 ;;
    --body-file) ISSUE_BODY=$(cat "$2" 2>/dev/null || die "Cannot read body file: $2"); shift 2 ;;
    --parent) PARENT_NUMBER="$2"; shift 2 ;;
    --priority) PRIORITY="$2"; shift 2 ;;
    --status) STATUS="$2"; shift 2 ;;
    --size) SIZE="$2"; shift 2 ;;
    --assignee) ASSIGNEE="$2"; shift 2 ;;
    --no-project) NO_PROJECT=1; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    --help|-h) usage; exit 0 ;;
    *) die "Unknown option: $1" ;;
  esac
done

# =============================================================================
# Validate Arguments
# =============================================================================

[[ -n "$ISSUE_TYPE" ]] || die "Missing required option: --type"
[[ -n "$ISSUE_TITLE" ]] || die "Missing required option: --title"

case "$ISSUE_TYPE" in
  epic|feature|story|task|bug) ;;
  *) die "Invalid issue type: $ISSUE_TYPE" ;;
esac

[[ "$PRIORITY" =~ ^p[0-5]$ ]] || die "Invalid priority: $PRIORITY"

# =============================================================================
# Verify Tools
# =============================================================================

require_cmd gh
require_cmd jq

# =============================================================================
# Prepare Issue Body
# =============================================================================

if [[ -z "$ISSUE_BODY" ]]; then
  case "$ISSUE_TYPE" in
    epic) ISSUE_BODY=$(template_epic) ;;
    feature) ISSUE_BODY=$(template_feature) ;;
    story) ISSUE_BODY=$(template_story) ;;
    task) ISSUE_BODY=$(template_task) ;;
    bug) ISSUE_BODY=$(template_bug) ;;
  esac
fi

# =============================================================================
# Prepare Title with Prefix
# =============================================================================

case "$ISSUE_TYPE" in
  epic) PREFIXED_TITLE="[Epic] $ISSUE_TITLE" ;;
  feature) PREFIXED_TITLE="[Feature] $ISSUE_TITLE" ;;
  story) PREFIXED_TITLE="[Story] $ISSUE_TITLE" ;;
  task) PREFIXED_TITLE="[Task] $ISSUE_TITLE" ;;
  bug) PREFIXED_TITLE="[Bug] $ISSUE_TITLE" ;;
esac

# =============================================================================
# Create Issue
# =============================================================================

log "Creating $ISSUE_TYPE issue: $PREFIXED_TITLE"

# Build label list
labels="$ISSUE_TYPE,planned,$PRIORITY"

# Build gh issue create command
gh_cmd=(gh issue create --repo "$OWNER/$REPO" --title "$PREFIXED_TITLE" --body "$ISSUE_BODY" --label "$labels")
[[ -n "$ASSIGNEE" ]] && gh_cmd+=(--assignee "$ASSIGNEE")

issue_output=$(dry_run_or_exec "${gh_cmd[@]}" 2>/dev/null || die "Failed to create issue")

# Extract issue number from URL (e.g., https://github.com/.../issues/42 → 42)
ISSUE_NUMBER=$(extract_issue_number "$issue_output")
ISSUE_URL=$(issue_url "$ISSUE_NUMBER")

log "Issue created: #$ISSUE_NUMBER"

# =============================================================================
# Get Issue Node ID
# =============================================================================

log "Fetching issue node ID..."

node_id=$(dry_run_or_exec gh issue view "$ISSUE_NUMBER" --repo "$OWNER/$REPO" --json nodeId --jq '.nodeId' 2>/dev/null || die "Failed to fetch node ID")

[[ -n "$node_id" ]] || die "Could not extract node ID"

log "Node ID: $node_id"

# =============================================================================
# Link to Parent (if specified)
# =============================================================================

parent_linked=false

if [[ -n "$PARENT_NUMBER" ]]; then
  log "Linking as sub-issue of #$PARENT_NUMBER..."

  parent_node_id=$(dry_run_or_exec gh api repos/"$OWNER"/"$REPO"/issues/"$PARENT_NUMBER" --jq '.node_id' 2>/dev/null || die "Failed to fetch parent node ID")

  graphql_mutation=$(cat <<EOF
mutation {
  addSubIssue(input: {
    issueId: "$parent_node_id"
    subIssueUrl: "$ISSUE_URL"
    replaceParent: false
  }) {
    issue { number }
  }
}
EOF
)

  dry_run_or_exec gh api graphql -f query="$graphql_mutation" 2>/dev/null || die "Failed to link sub-issue"

  parent_linked=true
  log "Linked to parent issue #$PARENT_NUMBER"
fi

# =============================================================================
# Add to Project (if not --no-project)
# =============================================================================

project_item_id=""
project_fields_set=""

if [[ "$NO_PROJECT" != "1" ]]; then
  log "Adding to project..."

  project_output=$(dry_run_or_exec gh project item-add "$PROJECT_NUMBER" \
    --owner "$OWNER" \
    --url "$ISSUE_URL" \
    --format json 2>/dev/null || die "Failed to add to project")

  project_item_id=$(echo "$project_output" | jq -r '.id')

  [[ -n "$project_item_id" ]] || die "Could not extract project item ID"

  log "Project item ID: $project_item_id"

  # =============================================================================
  # Set Project Fields
  # =============================================================================

  project_fields_set=$(cat <<EOF
{
  "status": "$STATUS",
  "priority": null,
  "size": null
}
EOF
)

  # Status field
  status_option_id=$(status_to_option_id "$STATUS")

  dry_run_or_exec gh project item-edit \
    --id "$project_item_id" \
    --project-id "$PROJECT_ID" \
    --field-id "$STATUS_FIELD_ID" \
    --single-select-option-id "$status_option_id" \
    || die "Failed to set status field"

  log "Set status to: $STATUS"

  # Priority field (convert p0..p5 to P0/P1/P2)
  project_priority=$(priority_to_project "$PRIORITY")
  priority_option_id=$(priority_to_option_id "$project_priority")

  dry_run_or_exec gh project item-edit \
    --id "$project_item_id" \
    --project-id "$PROJECT_ID" \
    --field-id "$PRIORITY_FIELD_ID" \
    --single-select-option-id "$priority_option_id" \
    || die "Failed to set priority field"

  log "Set priority to: $project_priority"

  project_fields_set=$(echo "$project_fields_set" | jq ".priority = \"$project_priority\"")

  # Size field (optional)
  if [[ -n "$SIZE" ]]; then
    size_option_id=$(size_to_option_id "$SIZE")

    dry_run_or_exec gh project item-edit \
      --id "$project_item_id" \
      --project-id "$PROJECT_ID" \
      --field-id "$SIZE_FIELD_ID" \
      --single-select-option-id "$size_option_id" \
      || die "Failed to set size field"

    log "Set size to: $SIZE"

    project_fields_set=$(echo "$project_fields_set" | jq ".size = \"$SIZE\"")
  fi
fi

# =============================================================================
# Output JSON Report
# =============================================================================

report=$(cat <<EOF
{
  "issue_number": $ISSUE_NUMBER,
  "node_id": "$node_id",
  "url": "$ISSUE_URL",
  "title": "$(json_escape "$PREFIXED_TITLE")",
  "type": "$ISSUE_TYPE",
  "labels": ["$ISSUE_TYPE", "planned", "$PRIORITY"],
  "parent_linked": $parent_linked,
  "parent_number": $([ -n "$PARENT_NUMBER" ] && echo "$PARENT_NUMBER" || echo "null"),
  "project_item_id": "$([ -n "$project_item_id" ] && echo "$project_item_id" || echo "")",
  "project_fields_set": $project_fields_set
}
EOF
)

json_output "$report"
