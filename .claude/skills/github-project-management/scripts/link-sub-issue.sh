#!/usr/bin/env bash
# Link an existing child issue as a sub-issue of a parent using GraphQL addSubIssue mutation.
# Output: JSON report with parent and child details.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/constants.sh"

# =============================================================================
# Globals
# =============================================================================

PARENT_NUMBER=""
CHILD_NUMBER=""
REPLACE_PARENT=false
DRY_RUN=${DRY_RUN:-0}

# =============================================================================
# Usage
# =============================================================================

usage() {
  cat <<EOF
Usage: $(basename "$0") --parent NUMBER --child NUMBER [OPTIONS]

Link an existing child issue as a sub-issue of a parent.

REQUIRED OPTIONS:
  --parent NUMBER     Parent issue number
  --child NUMBER      Child issue number

OPTIONAL OPTIONS:
  --replace-parent    Replace existing parent relationship (default: false)
  --dry-run           Print GraphQL call without executing
  --help              Print this help message

EXAMPLES:
  # Link issue 12 as sub-issue of issue 5
  link-sub-issue.sh --parent 5 --child 12

  # Replace existing parent relationship
  link-sub-issue.sh --parent 3 --child 12 --replace-parent

EOF
}

# =============================================================================
# Parse Arguments
# =============================================================================

while [[ $# -gt 0 ]]; do
  case "$1" in
    --parent) PARENT_NUMBER="$2"; shift 2 ;;
    --child) CHILD_NUMBER="$2"; shift 2 ;;
    --replace-parent) REPLACE_PARENT=true; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    --help|-h) usage; exit 0 ;;
    *) die "Unknown option: $1" ;;
  esac
done

# =============================================================================
# Validate Arguments
# =============================================================================

[[ -n "$PARENT_NUMBER" ]] || die "Missing required option: --parent"
[[ -n "$CHILD_NUMBER" ]] || die "Missing required option: --child"
[[ "$PARENT_NUMBER" =~ ^[0-9]+$ ]] || die "Invalid parent number: $PARENT_NUMBER"
[[ "$CHILD_NUMBER" =~ ^[0-9]+$ ]] || die "Invalid child number: $CHILD_NUMBER"

# =============================================================================
# Verify Tools
# =============================================================================

require_cmd gh
require_cmd jq

# =============================================================================
# Resolve Parent Node ID
# =============================================================================

log "Resolving parent node ID for issue #$PARENT_NUMBER..."

parent_data=$(dry_run_or_exec gh api repos/"$OWNER"/"$REPO"/issues/"$PARENT_NUMBER" --jq '{number: .number, nodeId: .node_id, title: .title}' 2>/dev/null || die "Failed to fetch parent issue #$PARENT_NUMBER")

parent_node_id=$(echo "$parent_data" | jq -r '.nodeId')
parent_title=$(echo "$parent_data" | jq -r '.title')

[[ -n "$parent_node_id" ]] || die "Could not resolve parent node ID"

log "Parent: issue #$PARENT_NUMBER ($parent_title) → $parent_node_id"

# =============================================================================
# Build Child Issue URL
# =============================================================================

child_url=$(issue_url "$CHILD_NUMBER")
log "Child URL: $child_url"

# =============================================================================
# Execute GraphQL Mutation
# =============================================================================

log "Executing GraphQL addSubIssue mutation..."

graphql_mutation=$(cat <<EOF
mutation {
  addSubIssue(input: {
    issueId: "$parent_node_id"
    subIssueUrl: "$child_url"
    replaceParent: $REPLACE_PARENT
  }) {
    issue {
      id
      number
      title
    }
    subIssue {
      id
      number
      title
    }
  }
}
EOF
)

if [[ "$DRY_RUN" == "1" ]]; then
  log "DRY-RUN: GraphQL mutation:"
  echo "$graphql_mutation" | sed 's/^/  /' >&2
  result="{\"issue\": {\"number\": $PARENT_NUMBER, \"title\": \"$parent_title\"}, \"subIssue\": {\"number\": $CHILD_NUMBER}}"
else
  result=$(gh api graphql -f query="$graphql_mutation" 2>/dev/null || die "GraphQL mutation failed")
fi

# =============================================================================
# Output JSON Report
# =============================================================================

report=$(cat <<EOF
{
  "parent": {
    "number": $PARENT_NUMBER,
    "node_id": "$parent_node_id",
    "title": "$(json_escape "$parent_title")"
  },
  "child": {
    "number": $CHILD_NUMBER,
    "url": "$child_url"
  },
  "replace_parent": $REPLACE_PARENT,
  "success": true
}
EOF
)

json_output "$report"
