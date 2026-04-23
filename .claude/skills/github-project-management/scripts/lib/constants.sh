#!/usr/bin/env bash
# Shared constants and helper functions for GitHub project management scripts.
# Source this file in every script: source "$SCRIPT_DIR/lib/constants.sh"

# Bash version check
if [[ "${BASH_VERSINFO[0]}" -lt 4 ]]; then
  echo "ERROR: Bash 4.0+ required for associative arrays. Current version: $BASH_VERSION" >&2
  exit 1
fi

# =============================================================================
# Repository Constants (Swaralipi only)
# =============================================================================

readonly OWNER="Roudranil"
readonly REPO="swaralipi-app"
readonly PROJECT_NUMBER=4
readonly PROJECT_ID="PVT_kwHOA51EZs4BVe4H"

# =============================================================================
# Project Field IDs
# =============================================================================

readonly STATUS_FIELD_ID="PVTSSF_lAHOA51EZs4BVe4HzhQ6YbE"
readonly PRIORITY_FIELD_ID="PVTSSF_lAHOA51EZs4BVe4HzhQ6Yig"
readonly SIZE_FIELD_ID="PVTSSF_lAHOA51EZs4BVe4HzhQ6Yik"

# =============================================================================
# Option IDs: Status
# =============================================================================

declare -A STATUS_OPTS=(
  ["backlog"]="f75ad846"
  ["ready"]="e18bf179"
  ["in_progress"]="47fc9ee4"
  ["in_review"]="aba860b9"
  ["done"]="98236657"
)

# =============================================================================
# Option IDs: Priority (project field — mapped from p0..p5)
# =============================================================================

declare -A PRIORITY_OPTS=(
  ["P0"]="79628723"
  ["P1"]="0a877460"
  ["P2"]="da944a9c"
)

# =============================================================================
# Option IDs: Size
# =============================================================================

declare -A SIZE_OPTS=(
  ["xs"]="911790be"
  ["s"]="b277fb01"
  ["m"]="86db8eb3"
  ["l"]="853c8207"
  ["xl"]="2d0801e2"
)

# =============================================================================
# Label Taxonomy: 14 labels with hex colors and descriptions
# =============================================================================

declare -A LABEL_COLOR=(
  ["epic"]="7B2FBE"
  ["feature"]="9B59B6"
  ["story"]="B185DB"
  ["task"]="D2A8FF"
  ["bug"]="E74C3C"
  ["planned"]="F1C40F"
  ["in-progress"]="E67E22"
  ["blocked"]="C0392B"
  ["p0"]="C0392B"
  ["p1"]="E74C3C"
  ["p2"]="E67E22"
  ["p3"]="F39C12"
  ["p4"]="2980B9"
  ["p5"]="95A5A6"
)

declare -A LABEL_DESC=(
  ["epic"]="Top-level initiative spanning multiple features"
  ["feature"]="Major capability; sub-issue of an epic"
  ["story"]="User-observable slice of a feature"
  ["task"]="Atomic technical work item"
  ["bug"]="Defect or functional regression"
  ["planned"]="Scoped but not started"
  ["in-progress"]="Actively being worked on"
  ["blocked"]="Blocked — blocker named in comments"
  ["p0"]="Critical — drop everything"
  ["p1"]="High — current sprint"
  ["p2"]="Medium-high — next sprint"
  ["p3"]="Medium — backlog top"
  ["p4"]="Low — backlog"
  ["p5"]="Negligible — someday/maybe"
)

# =============================================================================
# Helper Functions
# =============================================================================

# Print error to stderr and exit with code 1
die() {
  local script_name
  script_name="$(basename "$0")"
  echo "ERROR [$script_name]: $*" >&2
  exit 1
}

# Print message to stderr (preserving stdout for JSON output)
log() {
  echo "[$(basename "$0")] $*" >&2
}

# Assert a command exists or die
require_cmd() {
  if ! command -v "$1" &> /dev/null; then
    die "Required command not found: $1"
  fi
}

# Execute a command or print it if DRY_RUN=1
dry_run_or_exec() {
  if [[ "${DRY_RUN:-0}" == "1" ]]; then
    log "DRY-RUN: $*"
  else
    "$@"
  fi
}

# Construct issue URL
issue_url() {
  local issue_number=$1
  echo "https://github.com/$OWNER/$REPO/issues/$issue_number"
}

# Print JSON to stdout
json_output() {
  echo "$1"
}

# Convert priority label (p0..p5) to project field option (P0, P1, P2)
priority_to_project() {
  local priority=$1
  case "$priority" in
    p0) echo "P0" ;;
    p1) echo "P1" ;;
    p2|p3|p4|p5) echo "P2" ;;
    *) die "Invalid priority: $priority" ;;
  esac
}

# Map a priority to its project field option ID
priority_to_option_id() {
  local project_priority=$1
  echo "${PRIORITY_OPTS[$project_priority]:-$(die "Unknown priority: $project_priority")}"
}

# Map a status to its option ID
status_to_option_id() {
  local status=$1
  echo "${STATUS_OPTS[$status]:-$(die "Unknown status: $status")}"
}

# Map a size to its option ID
size_to_option_id() {
  local size=$1
  echo "${SIZE_OPTS[$size]:-$(die "Unknown size: $size")}"
}

# Extract issue number from a GitHub issue URL
extract_issue_number() {
  local url=$1
  echo "$url" | grep -oE '[0-9]+$' || die "Could not extract issue number from URL: $url"
}

# Escape JSON string (basic escaping)
json_escape() {
  local str=$1
  # Replace backslashes, quotes, newlines, tabs
  str="${str//\\/\\\\}"
  str="${str//\"/\\\"}"
  str="${str//$'\n'/\\n}"
  str="${str//$'\t'/\\t}"
  echo "$str"
}
