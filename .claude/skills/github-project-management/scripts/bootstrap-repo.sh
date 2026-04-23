#!/usr/bin/env bash
# Bootstrap entire repository: labels, issue templates, PR template.
# Reads canonical template content from .github/ — no embedded duplicates.
# Output: JSON report of what was created vs. already present.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/constants.sh"

# Canonical template sources (relative to this script)
CANONICAL_TEMPLATE_DIR="$SCRIPT_DIR/../../../.github/ISSUE_TEMPLATE"
PR_TEMPLATE_FILE="$SCRIPT_DIR/../../../.github/pull_request_template.md"

# =============================================================================
# Globals
# =============================================================================

SKIP_LABELS=0
SKIP_TEMPLATES=0
SKIP_PR_TEMPLATE=0
DELETE_DEFAULT_LABELS=0
TARGET_BRANCH="main"
DRY_RUN=${DRY_RUN:-0}

# =============================================================================
# Usage
# =============================================================================

usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Bootstrap repository: labels, issue templates, PR template.
CI workflows are managed separately — not in scope for this script.

OPTIONS:
  --skip-labels           Skip label bootstrap
  --skip-templates        Skip issue templates
  --skip-pr-template      Skip PR template
  --delete-default-labels Pass --delete-defaults to label bootstrap
  --branch BRANCH         Target branch (default: main)
  --dry-run               Print operations without executing
  --help                  Print this help message

EXAMPLES:
  # Dry-run full bootstrap
  bootstrap-repo.sh --dry-run

  # Full bootstrap and delete GitHub defaults
  bootstrap-repo.sh --delete-default-labels

  # Bootstrap only labels
  bootstrap-repo.sh --skip-templates --skip-pr-template

EOF
}

# =============================================================================
# Parse Arguments
# =============================================================================

while [[ $# -gt 0 ]]; do
  case "$1" in
    --skip-labels) SKIP_LABELS=1; shift ;;
    --skip-templates) SKIP_TEMPLATES=1; shift ;;
    --skip-pr-template) SKIP_PR_TEMPLATE=1; shift ;;
    --delete-default-labels) DELETE_DEFAULT_LABELS=1; shift ;;
    --branch) TARGET_BRANCH="$2"; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    --help|-h) usage; exit 0 ;;
    *) die "Unknown option: $1" ;;
  esac
done

# =============================================================================
# Verify Tools
# =============================================================================

require_cmd gh
require_cmd jq
require_cmd base64

# =============================================================================
# Bootstrap Labels
# =============================================================================

labels_report='{"created": 0, "existed": 0, "success": false}'

if [[ "$SKIP_LABELS" != "1" ]]; then
  log "Bootstrapping labels..."

  bootstrap_cmd=("$SCRIPT_DIR/bootstrap-labels.sh")
  [[ "$DRY_RUN" == "1" ]] && bootstrap_cmd+=(--dry-run)
  [[ "$DELETE_DEFAULT_LABELS" == "1" ]] && bootstrap_cmd+=(--delete-defaults)

  labels_report=$("${bootstrap_cmd[@]}" 2>/dev/null || echo '{"success": false}')
  log "Labels bootstrap complete"
fi

# =============================================================================
# Bootstrap Issue Templates
# =============================================================================

declare -A templates_status=(
  [epic]="existed"
  [feature]="existed"
  [story]="existed"
  [task]="existed"
  [bug]="existed"
)

if [[ "$SKIP_TEMPLATES" != "1" ]]; then
  log "Bootstrapping issue templates from canonical .github/ISSUE_TEMPLATE/ sources..."

  for template_type in epic feature story task bug; do
    template_path=".github/ISSUE_TEMPLATE/${template_type}.yml"
    canonical_file="$CANONICAL_TEMPLATE_DIR/${template_type}.yml"

    log "  Processing template: $template_type"

    [[ -f "$canonical_file" ]] || die "Canonical template not found: $canonical_file"

    # Fetch existing template SHA if present
    existing_sha=""
    existing=$(gh api repos/"$OWNER"/"$REPO"/contents/"$template_path" --jq '.sha' 2>/dev/null || echo "")
    [[ -n "$existing" ]] && existing_sha="$existing"

    # Read and encode canonical template content
    content_b64=$(base64 -w 0 < "$canonical_file")

    # PUT to repo (create or update)
    if [[ -z "$existing_sha" ]]; then
      log "    Creating template: $template_type"
      templates_status[$template_type]="created"

      dry_run_or_exec gh api repos/"$OWNER"/"$REPO"/contents/"$template_path" \
        -X PUT \
        -f message="chore: add $template_type issue template" \
        -f content="$content_b64" \
        -f branch="$TARGET_BRANCH" \
        2>/dev/null || log "    Warning: could not create template $template_type"
    else
      log "    Updating template: $template_type"

      dry_run_or_exec gh api repos/"$OWNER"/"$REPO"/contents/"$template_path" \
        -X PUT \
        -f message="chore: update $template_type issue template" \
        -f content="$content_b64" \
        -f sha="$existing_sha" \
        -f branch="$TARGET_BRANCH" \
        2>/dev/null || log "    Warning: could not update template $template_type"
    fi
  done

  log "Issue templates bootstrap complete"
fi

# =============================================================================
# Bootstrap PR Template
# =============================================================================

pr_template_status="existed"

if [[ "$SKIP_PR_TEMPLATE" != "1" ]]; then
  log "Bootstrapping PR template from canonical .github/pull_request_template.md..."

  [[ -f "$PR_TEMPLATE_FILE" ]] || die "Canonical PR template not found: $PR_TEMPLATE_FILE"

  pr_path=".github/pull_request_template.md"

  # Fetch existing SHA if present
  existing_sha=""
  existing=$(gh api repos/"$OWNER"/"$REPO"/contents/"$pr_path" --jq '.sha' 2>/dev/null || echo "")
  [[ -n "$existing" ]] && existing_sha="$existing"

  # Read and encode
  content_b64=$(base64 -w 0 < "$PR_TEMPLATE_FILE")

  # PUT to repo
  if [[ -z "$existing_sha" ]]; then
    log "  Creating PR template"
    pr_template_status="created"

    dry_run_or_exec gh api repos/"$OWNER"/"$REPO"/contents/"$pr_path" \
      -X PUT \
      -f message="chore: add PR template" \
      -f content="$content_b64" \
      -f branch="$TARGET_BRANCH" \
      2>/dev/null || log "  Warning: could not create PR template"
  else
    log "  Updating PR template"

    dry_run_or_exec gh api repos/"$OWNER"/"$REPO"/contents/"$pr_path" \
      -X PUT \
      -f message="chore: update PR template" \
      -f content="$content_b64" \
      -f sha="$existing_sha" \
      -f branch="$TARGET_BRANCH" \
      2>/dev/null || log "  Warning: could not update PR template"
  fi

  log "PR template bootstrap complete"
fi

# =============================================================================
# Build JSON Report
# =============================================================================

issue_templates_report=$(cat <<EOF
{
  "epic": "${templates_status[epic]}",
  "feature": "${templates_status[feature]}",
  "story": "${templates_status[story]}",
  "task": "${templates_status[task]}",
  "bug": "${templates_status[bug]}"
}
EOF
)

overall_success=$(echo "$labels_report" | jq '.success')

report=$(cat <<EOF
{
  "labels": $labels_report,
  "issue_templates": $issue_templates_report,
  "pr_template": "$pr_template_status",
  "overall_success": $overall_success
}
EOF
)

json_output "$report"
[[ "$overall_success" == "true" ]] || exit 1
