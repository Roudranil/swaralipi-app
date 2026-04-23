#!/usr/bin/env bash
# Bootstrap GitHub labels: create all 14 taxonomy labels if missing, optionally delete defaults.
# Output: JSON report of created, existing, and deleted labels.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/constants.sh"

# =============================================================================
# Globals
# =============================================================================

DELETE_DEFAULTS=0
FORCE_UPDATE=0
DRY_RUN=${DRY_RUN:-0}

# =============================================================================
# Usage
# =============================================================================

usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Bootstrap all 14 GitHub labels for the Swaralipi project.

OPTIONS:
  --delete-defaults   Remove GitHub default labels (enhancement, good first issue, etc.)
  --force-update      Update color/description of existing labels
  --dry-run           Print operations without executing
  --help              Print this help message

EXAMPLES:
  # Create missing labels and delete defaults
  bootstrap-labels.sh --delete-defaults

  # Verify labels exist without changes
  bootstrap-labels.sh --dry-run

EOF
}

# =============================================================================
# Parse Arguments
# =============================================================================

while [[ $# -gt 0 ]]; do
  case "$1" in
    --delete-defaults) DELETE_DEFAULTS=1; shift ;;
    --force-update) FORCE_UPDATE=1; shift ;;
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

# =============================================================================
# Main
# =============================================================================

log "Fetching existing labels..."
existing_labels=$(dry_run_or_exec gh label list --repo "$OWNER/$REPO" --limit 100 --json name,color,description 2>/dev/null || echo "[]")

# Build a map of existing label names
declare -A existing_map
while IFS= read -r line; do
  [[ -z "$line" ]] && continue
  name=$(echo "$line" | jq -r '.name')
  existing_map["$name"]=1
done < <(echo "$existing_labels" | jq -c '.[]')

# Track results
created=()
already_existed=()
updated=()
deleted_defaults=()

# =============================================================================
# Create Missing Labels
# =============================================================================

log "Checking and creating labels..."

for label in epic feature story task bug planned in-progress blocked p0 p1 p2 p3 p4 p5; do
  color="${LABEL_COLOR[$label]}"
  description="${LABEL_DESC[$label]}"

  if [[ -v existing_map[$label] ]]; then
    already_existed+=("$label")

    # Check if color or description differs
    if [[ "$FORCE_UPDATE" == "1" ]]; then
      existing_entry=$(echo "$existing_labels" | jq ".[] | select(.name == \"$label\")")
      existing_color=$(echo "$existing_entry" | jq -r '.color // ""')
      existing_desc=$(echo "$existing_entry" | jq -r '.description // ""')

      if [[ "$existing_color" != "$color" ]] || [[ "$existing_desc" != "$description" ]]; then
        log "Updating label: $label"
        dry_run_or_exec gh label edit --repo "$OWNER/$REPO" --name "$label" \
          --color "$color" --description "$description" \
          || die "Failed to update label: $label"
        updated+=("$label")
      fi
    fi
  else
    log "Creating label: $label"
    dry_run_or_exec gh label create --repo "$OWNER/$REPO" \
      --name "$label" \
      --color "$color" \
      --description "$description" \
      || die "Failed to create label: $label"
    created+=("$label")
  fi
done

# =============================================================================
# Delete Default Labels (Optional)
# =============================================================================

if [[ "$DELETE_DEFAULTS" == "1" ]]; then
  log "Deleting GitHub default labels..."

  default_labels=(enhancement "good first issue" "help wanted" invalid question wontfix documentation)

  for default_label in "${default_labels[@]}"; do
    if [[ -v existing_map[$default_label] ]]; then
      log "Deleting default label: $default_label"
      dry_run_or_exec gh label delete --repo "$OWNER/$REPO" --name "$default_label" --yes \
        || log "Warning: Could not delete label $default_label"
      deleted_defaults+=("$default_label")
    fi
  done
fi

# =============================================================================
# Verify All 14 Labels Exist
# =============================================================================

log "Verifying all labels..."
final_labels=$(dry_run_or_exec gh label list --repo "$OWNER/$REPO" --limit 100 --json name 2>/dev/null || echo "[]")
final_count=$(echo "$final_labels" | jq 'length')

declare -A final_map
while IFS= read -r line; do
  [[ -z "$line" ]] && continue
  name=$(echo "$line" | jq -r '.name')
  final_map["$name"]=1
done < <(echo "$final_labels" | jq -c '.[]')

missing=()
for label in epic feature story task bug planned in-progress blocked p0 p1 p2 p3 p4 p5; do
  if [[ ! -v final_map[$label] ]]; then
    missing+=("$label")
  fi
done

# =============================================================================
# Output JSON Report
# =============================================================================

success=true
if [[ ${#missing[@]} -gt 0 ]]; then
  success=false
fi

report=$(cat <<EOF
{
  "created": $(printf '%s\n' "${created[@]}" | jq -R . | jq -s .),
  "already_existed": $(printf '%s\n' "${already_existed[@]}" | jq -R . | jq -s .),
  "updated": $(printf '%s\n' "${updated[@]}" | jq -R . | jq -s .),
  "deleted_defaults": $(printf '%s\n' "${deleted_defaults[@]}" | jq -R . | jq -s .),
  "missing_after": $(printf '%s\n' "${missing[@]}" | jq -R . | jq -s .),
  "success": $success
}
EOF
)

json_output "$report"
[[ "$success" == "true" ]] || exit 1
