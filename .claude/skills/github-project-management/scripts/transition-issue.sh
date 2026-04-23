#!/usr/bin/env bash
# Transition an issue's workflow state: labels, project status field, close, comment.
# Output: JSON report with state transition details.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/constants.sh"

# =============================================================================
# Globals
# =============================================================================

ISSUE_NUMBER=""
TARGET_STATE=""
ISSUE_TYPE=""
PRIORITY=""
BLOCKED_BY=""
BLOCKED_REASON=""
DRY_RUN=${DRY_RUN:-0}

# =============================================================================
# Usage
# =============================================================================

usage() {
  cat <<EOF
Usage: $(basename "$0") --issue NUMBER --to STATE --type TYPE --priority PRIORITY [OPTIONS]

Transition an issue's workflow state: update labels, project status, optionally close or comment.

REQUIRED OPTIONS:
  --issue NUMBER      Issue number
  --to STATE          Target state: ready, in_progress, in_review, done, blocked
  --type TYPE         Issue type: epic, feature, story, task, bug (to preserve type label)
  --priority PRIORITY Priority label: p0, p1, p2, p3, p4, p5 (to preserve in full set)

OPTIONAL OPTIONS:
  --blocked-by NUMBER Blocking issue number (required when --to blocked)
  --blocked-reason TEXT One-sentence reason for the block
  --dry-run           Print gh calls without executing
  --help              Print this help message

STATE DETAILS:
  ready       → Add 'planned' label, remove 'in-progress' and 'blocked'
  in_progress → Add 'in-progress' label, remove 'planned' and 'blocked'
  in_review   → Add 'in-progress' label, remove 'planned' and 'blocked', set project Status to 'in_review'
  done        → Remove 'planned', 'in-progress', 'blocked', close issue
  blocked     → Add 'blocked' label, remove 'planned' and 'in-progress', post comment

EXAMPLES:
  # Start working on a task
  transition-issue.sh --issue 42 --to in_progress --type task --priority p1

  # Mark as done and close
  transition-issue.sh --issue 42 --to done --type task --priority p1

  # Block and comment
  transition-issue.sh --issue 42 --to blocked --type task --priority p1 --blocked-by 50 --blocked-reason "Waiting for API design"

EOF
}

# =============================================================================
# Parse Arguments
# =============================================================================

while [[ $# -gt 0 ]]; do
  case "$1" in
    --issue) ISSUE_NUMBER="$2"; shift 2 ;;
    --to) TARGET_STATE="$2"; shift 2 ;;
    --type) ISSUE_TYPE="$2"; shift 2 ;;
    --priority) PRIORITY="$2"; shift 2 ;;
    --blocked-by) BLOCKED_BY="$2"; shift 2 ;;
    --blocked-reason) BLOCKED_REASON="$2"; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    --help|-h) usage; exit 0 ;;
    *) die "Unknown option: $1" ;;
  esac
done

# =============================================================================
# Validate Arguments
# =============================================================================

[[ -n "$ISSUE_NUMBER" ]] || die "Missing required option: --issue"
[[ -n "$TARGET_STATE" ]] || die "Missing required option: --to"
[[ -n "$ISSUE_TYPE" ]] || die "Missing required option: --type"
[[ -n "$PRIORITY" ]] || die "Missing required option: --priority"

[[ "$ISSUE_NUMBER" =~ ^[0-9]+$ ]] || die "Invalid issue number: $ISSUE_NUMBER"
[[ "$TARGET_STATE" =~ ^(ready|in_progress|in_review|done|blocked)$ ]] || die "Invalid state: $TARGET_STATE"
[[ "$ISSUE_TYPE" =~ ^(epic|feature|story|task|bug)$ ]] || die "Invalid type: $ISSUE_TYPE"
[[ "$PRIORITY" =~ ^p[0-5]$ ]] || die "Invalid priority: $PRIORITY"

if [[ "$TARGET_STATE" == "blocked" && -z "$BLOCKED_BY" ]]; then
  die "Option --blocked-by is required when --to blocked"
fi

# =============================================================================
# Verify Tools
# =============================================================================

require_cmd gh
require_cmd jq

# =============================================================================
# Fetch Current State
# =============================================================================

log "Fetching current issue state..."

issue_data=$(dry_run_or_exec gh issue view "$ISSUE_NUMBER" --repo "$OWNER/$REPO" --json labels --jq '{labels: [.labels[].name]}' 2>/dev/null || die "Failed to fetch issue")

current_labels=($(echo "$issue_data" | jq -r '.labels[]'))

# Determine current state from labels
current_state="unknown"
if [[ " ${current_labels[@]} " =~ " planned " ]]; then
  current_state="ready"
elif [[ " ${current_labels[@]} " =~ " in-progress " ]] && [[ ! " ${current_labels[@]} " =~ " blocked " ]]; then
  current_state="in_progress"
elif [[ " ${current_labels[@]} " =~ " blocked " ]]; then
  current_state="blocked"
else
  current_state="other"
fi

log "Current state: $current_state (labels: ${current_labels[*]})"

# =============================================================================
# Determine Labels to Add/Remove
# =============================================================================

declare -a labels_to_add
declare -a labels_to_remove

case "$TARGET_STATE" in
  ready)
    labels_to_add=("planned")
    labels_to_remove=("in-progress" "blocked")
    ;;
  in_progress)
    labels_to_add=("in-progress")
    labels_to_remove=("planned" "blocked")
    ;;
  in_review)
    labels_to_add=("in-progress")
    labels_to_remove=("planned" "blocked")
    ;;
  done)
    labels_to_add=()
    labels_to_remove=("planned" "in-progress" "blocked")
    ;;
  blocked)
    labels_to_add=("blocked")
    labels_to_remove=("planned" "in-progress")
    ;;
esac

# =============================================================================
# Update Labels
# =============================================================================

log "Updating labels..."

labels_added_str=$(IFS=,; echo "${labels_to_add[*]}")
labels_removed_str=$(IFS=,; echo "${labels_to_remove[*]}")

if [[ -n "$labels_added_str" ]]; then
  log "Adding labels: $labels_added_str"
  dry_run_or_exec gh issue edit "$ISSUE_NUMBER" --repo "$OWNER/$REPO" --add-label "$labels_added_str" \
    || die "Failed to add labels"
fi

if [[ -n "$labels_removed_str" ]]; then
  log "Removing labels: $labels_removed_str"
  dry_run_or_exec gh issue edit "$ISSUE_NUMBER" --repo "$OWNER/$REPO" --remove-label "$labels_removed_str" \
    || die "Failed to remove labels"
fi

# =============================================================================
# Update Project Status Field
# =============================================================================

project_status_set=false

if [[ "$TARGET_STATE" != "blocked" ]]; then
  log "Setting project status to: $TARGET_STATE"

  status_option_id=$(status_to_option_id "$TARGET_STATE")

  # Get or create project item
  issue_url=$(issue_url "$ISSUE_NUMBER")
  project_output=$(dry_run_or_exec gh project item-add "$PROJECT_NUMBER" \
    --owner "$OWNER" \
    --url "$issue_url" \
    --format json 2>/dev/null || echo "{}")

  project_item_id=$(echo "$project_output" | jq -r '.id // ""')

  if [[ -n "$project_item_id" ]]; then
    dry_run_or_exec gh project item-edit \
      --id "$project_item_id" \
      --project-id "$PROJECT_ID" \
      --field-id "$STATUS_FIELD_ID" \
      --single-select-option-id "$status_option_id" \
      || die "Failed to set project status"

    project_status_set=true
    log "Project status set to: $TARGET_STATE"
  fi
fi

# =============================================================================
# Close Issue (if done)
# =============================================================================

issue_closed=false

if [[ "$TARGET_STATE" == "done" ]]; then
  log "Closing issue..."
  dry_run_or_exec gh issue close "$ISSUE_NUMBER" --repo "$OWNER/$REPO" --reason completed \
    || die "Failed to close issue"
  issue_closed=true
  log "Issue closed"
fi

# =============================================================================
# Post Comment (if blocked)
# =============================================================================

comment_posted=false

if [[ "$TARGET_STATE" == "blocked" ]]; then
  comment_body="🚫 Blocked by #$BLOCKED_BY"
  [[ -n "$BLOCKED_REASON" ]] && comment_body="$comment_body. Reason: $BLOCKED_REASON"

  log "Posting comment: $comment_body"
  dry_run_or_exec gh issue comment "$ISSUE_NUMBER" --repo "$OWNER/$REPO" --body "$comment_body" \
    || die "Failed to post comment"
  comment_posted=true
  log "Comment posted"
fi

# =============================================================================
# Output JSON Report
# =============================================================================

report=$(cat <<EOF
{
  "issue_number": $ISSUE_NUMBER,
  "from_state": "$current_state",
  "to_state": "$TARGET_STATE",
  "labels_updated": true,
  "project_status_set": $project_status_set,
  "issue_closed": $issue_closed,
  "comment_posted": $comment_posted
}
EOF
)

json_output "$report"
