#!/usr/bin/env bash
# Add an issue to the project board and set Status, Priority, and/or Size fields.
# Output: JSON report with project item ID and fields set.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/constants.sh"

# =============================================================================
# Globals
# =============================================================================

ISSUE_NUMBER=""
STATUS=""
PRIORITY=""
SIZE=""
ITEM_ID=""
DRY_RUN=${DRY_RUN:-0}

# =============================================================================
# Usage
# =============================================================================

usage() {
  cat <<EOF
Usage: $(basename "$0") --issue NUMBER [OPTIONS]

Add an issue to the project board and set Status, Priority, and/or Size fields.

REQUIRED OPTIONS:
  --issue NUMBER      Issue number

OPTIONAL OPTIONS:
  --status STATUS     Status field: backlog, ready, in_progress, in_review, done
  --priority PRIORITY Priority field: P0, P1, P2 (uppercase)
  --size SIZE         Size field: xs, s, m, l, xl
  --item-id ID        Skip item-add if project item ID already known (optimization)
  --dry-run           Print gh calls without executing
  --help              Print this help message

EXAMPLES:
  # Add issue 42 to project with status
  set-project-fields.sh --issue 42 --status in_progress

  # Add and set multiple fields
  set-project-fields.sh --issue 42 --status ready --priority P1 --size m

EOF
}

# =============================================================================
# Parse Arguments
# =============================================================================

while [[ $# -gt 0 ]]; do
  case "$1" in
    --issue) ISSUE_NUMBER="$2"; shift 2 ;;
    --status) STATUS="$2"; shift 2 ;;
    --priority) PRIORITY="$2"; shift 2 ;;
    --size) SIZE="$2"; shift 2 ;;
    --item-id) ITEM_ID="$2"; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    --help|-h) usage; exit 0 ;;
    *) die "Unknown option: $1" ;;
  esac
done

# =============================================================================
# Validate Arguments
# =============================================================================

[[ -n "$ISSUE_NUMBER" ]] || die "Missing required option: --issue"
[[ "$ISSUE_NUMBER" =~ ^[0-9]+$ ]] || die "Invalid issue number: $ISSUE_NUMBER"

# =============================================================================
# Verify Tools
# =============================================================================

require_cmd gh
require_cmd jq

# =============================================================================
# Get or Create Project Item
# =============================================================================

if [[ -z "$ITEM_ID" ]]; then
  log "Adding issue #$ISSUE_NUMBER to project..."

  issue_url=$(issue_url "$ISSUE_NUMBER")

  item_output=$(dry_run_or_exec gh project item-add "$PROJECT_NUMBER" \
    --owner "$OWNER" \
    --url "$issue_url" \
    --format json 2>/dev/null || die "Failed to add issue #$ISSUE_NUMBER to project")

  ITEM_ID=$(echo "$item_output" | jq -r '.id')
  [[ -n "$ITEM_ID" ]] || die "Could not extract item ID from project response"

  log "Project item ID: $ITEM_ID"
fi

# =============================================================================
# Set Fields
# =============================================================================

fields_set=$(cat <<EOF
{
  "status": null,
  "priority": null,
  "size": null
}
EOF
)

# Status field
if [[ -n "$STATUS" ]]; then
  log "Setting status field to: $STATUS"
  status_option_id=$(status_to_option_id "$STATUS")

  dry_run_or_exec gh project item-edit \
    --id "$ITEM_ID" \
    --project-id "$PROJECT_ID" \
    --field-id "$STATUS_FIELD_ID" \
    --single-select-option-id "$status_option_id" \
    || die "Failed to set status field"

  fields_set=$(echo "$fields_set" | jq ".status = \"$STATUS\"")
fi

# Priority field
if [[ -n "$PRIORITY" ]]; then
  log "Setting priority field to: $PRIORITY"
  priority_option_id=$(priority_to_option_id "$PRIORITY")

  dry_run_or_exec gh project item-edit \
    --id "$ITEM_ID" \
    --project-id "$PROJECT_ID" \
    --field-id "$PRIORITY_FIELD_ID" \
    --single-select-option-id "$priority_option_id" \
    || die "Failed to set priority field"

  fields_set=$(echo "$fields_set" | jq ".priority = \"$PRIORITY\"")
fi

# Size field
if [[ -n "$SIZE" ]]; then
  log "Setting size field to: $SIZE"
  size_option_id=$(size_to_option_id "$SIZE")

  dry_run_or_exec gh project item-edit \
    --id "$ITEM_ID" \
    --project-id "$PROJECT_ID" \
    --field-id "$SIZE_FIELD_ID" \
    --single-select-option-id "$size_option_id" \
    || die "Failed to set size field"

  fields_set=$(echo "$fields_set" | jq ".size = \"$SIZE\"")
fi

# =============================================================================
# Output JSON Report
# =============================================================================

report=$(cat <<EOF
{
  "issue_number": $ISSUE_NUMBER,
  "project_item_id": "$ITEM_ID",
  "fields_set": $fields_set
}
EOF
)

json_output "$report"
