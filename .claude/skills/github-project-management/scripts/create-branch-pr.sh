#!/usr/bin/env bash
# Create a branch using naming convention and open a draft PR with standard body template.
# Output: JSON report with branch and PR details.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/constants.sh"

# =============================================================================
# Globals
# =============================================================================

ISSUE_NUMBER=""
BRANCH_TYPE=""
SLUG=""
PR_TITLE=""
BASE_BRANCH="main"
FROM_BRANCH="main"
COMMIT_SCOPE=""
NO_DRAFT=0
DRY_RUN=${DRY_RUN:-0}

# =============================================================================
# PR Template
# =============================================================================

pr_template() {
  local issue=$1
  cat <<EOF
## Linked Issue
Closes #$issue

## Summary
<!-- What does this PR do? 2–4 bullets. -->
-
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
- [ ] \`flutter test --coverage\` passes locally
- [ ] Coverage ≥ 80%
- [ ] \`flutter analyze --fatal-infos --fatal-warnings\` clean
- [ ] \`dart format\` applied
- [ ] Tested on Samsung Galaxy S25 (if UI change)

## Screenshots / Recordings
<!-- Required for any UI change. -->

## Checklist
- [ ] No \`print\` statements (use \`dart:developer\` \`log\`)
- [ ] No relative imports
- [ ] No \`late\` without guaranteed init
- [ ] No bare \`catch (e)\`
- [ ] Generated files committed (\`.g.dart\`)
- [ ] No hardcoded secrets
EOF
}

# =============================================================================
# Usage
# =============================================================================

usage() {
  cat <<EOF
Usage: $(basename "$0") --issue NUMBER --type TYPE --slug SLUG [OPTIONS]

Create a branch using naming convention and open a draft PR.

REQUIRED OPTIONS:
  --issue NUMBER      Issue number
  --type TYPE         Branch type: feature, story, task, bug, chore, release
  --slug SLUG         Kebab-case branch name suffix (e.g., camerax-wiring)

OPTIONAL OPTIONS:
  --title TITLE       PR title (auto-generated if omitted)
  --base BRANCH       Base branch for PR (default: main)
  --from BRANCH       Branch to fork from (default: main)
  --scope SCOPE       Commit scope for auto-generated PR title
  --no-draft          Open as ready-for-review immediately
  --dry-run           Print gh calls without executing
  --help              Print this help message

BRANCH NAME CONSTRUCTION:
  feature/<issue>-<slug>    → feature/12-image-capture
  story/<issue>-<slug>      → story/15-camera-ui
  task/<issue>-<slug>       → task/18-camerax-wiring
  bug/<issue>-<slug>        → bug/23-crash-rotate
  chore/<slug>              → chore/update-flutter (no issue)
  release/<slug>            → release/1.2.0 (no issue)

EXAMPLES:
  # Create task branch and draft PR
  create-branch-pr.sh --issue 42 --type task --slug camerax-wiring --scope notation

  # Create chore branch
  create-branch-pr.sh --type chore --slug update-flutter

EOF
}

# =============================================================================
# Parse Arguments
# =============================================================================

while [[ $# -gt 0 ]]; do
  case "$1" in
    --issue) ISSUE_NUMBER="$2"; shift 2 ;;
    --type) BRANCH_TYPE="$2"; shift 2 ;;
    --slug) SLUG="$2"; shift 2 ;;
    --title) PR_TITLE="$2"; shift 2 ;;
    --base) BASE_BRANCH="$2"; shift 2 ;;
    --from) FROM_BRANCH="$2"; shift 2 ;;
    --scope) COMMIT_SCOPE="$2"; shift 2 ;;
    --no-draft) NO_DRAFT=1; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    --help|-h) usage; exit 0 ;;
    *) die "Unknown option: $1" ;;
  esac
done

# =============================================================================
# Validate Arguments
# =============================================================================

[[ -n "$BRANCH_TYPE" ]] || die "Missing required option: --type"
[[ -n "$SLUG" ]] || die "Missing required option: --slug"
[[ "$BRANCH_TYPE" =~ ^(feature|story|task|bug|chore|release)$ ]] || die "Invalid type: $BRANCH_TYPE"

# Issue number required for feature/story/task/bug
case "$BRANCH_TYPE" in
  chore|release) ;;
  *)
    [[ -n "$ISSUE_NUMBER" ]] || die "Missing required option: --issue for type $BRANCH_TYPE"
    [[ "$ISSUE_NUMBER" =~ ^[0-9]+$ ]] || die "Invalid issue number: $ISSUE_NUMBER"
    ;;
esac

# =============================================================================
# Verify Tools
# =============================================================================

require_cmd gh
require_cmd jq

# =============================================================================
# Construct Branch Name
# =============================================================================

case "$BRANCH_TYPE" in
  feature) BRANCH_NAME="feature/$ISSUE_NUMBER-$SLUG" ;;
  story) BRANCH_NAME="story/$ISSUE_NUMBER-$SLUG" ;;
  task) BRANCH_NAME="task/$ISSUE_NUMBER-$SLUG" ;;
  bug) BRANCH_NAME="bug/$ISSUE_NUMBER-$SLUG" ;;
  chore) BRANCH_NAME="chore/$SLUG" ;;
  release) BRANCH_NAME="release/$SLUG" ;;
esac

log "Branch name: $BRANCH_NAME"

# =============================================================================
# Construct PR Title (if not provided)
# =============================================================================

if [[ -z "$PR_TITLE" ]]; then
  # Convert slug to title case (hyphens → spaces)
  slug_title="${SLUG//-/ }"

  if [[ -n "$COMMIT_SCOPE" ]]; then
    PR_TITLE="feat($COMMIT_SCOPE): $slug_title"
  else
    PR_TITLE="feat: $slug_title"
  fi
fi

log "PR title: $PR_TITLE"

# =============================================================================
# Verify Base Branch Exists
# =============================================================================

log "Verifying base branch: $BASE_BRANCH"

base_sha=$(dry_run_or_exec gh api repos/"$OWNER"/"$REPO"/git/refs/heads/"$BASE_BRANCH" --jq '.object.sha' 2>/dev/null || die "Base branch '$BASE_BRANCH' not found")

log "Base branch SHA: $base_sha"

# =============================================================================
# Create Branch
# =============================================================================

log "Creating branch: $BRANCH_NAME"

dry_run_or_exec gh api repos/"$OWNER"/"$REPO"/git/refs \
  -X POST \
  -f ref="refs/heads/$BRANCH_NAME" \
  -f sha="$base_sha" \
  2>/dev/null || die "Failed to create branch"

log "Branch created successfully"

# =============================================================================
# Create Draft PR
# =============================================================================

log "Opening draft PR..."

pr_body=$(pr_template "${ISSUE_NUMBER:-}")

# Build gh pr create command
pr_cmd=(gh pr create --repo "$OWNER/$REPO" --title "$PR_TITLE" --head "$BRANCH_NAME" --base "$BASE_BRANCH" --body "$pr_body")
[[ "$NO_DRAFT" == "1" ]] || pr_cmd+=(--draft)

pr_output=$(dry_run_or_exec "${pr_cmd[@]}" 2>/dev/null || die "Failed to create PR")

# Extract PR number from URL (e.g., https://github.com/.../pull/123 → 123)
PR_NUMBER=$(extract_issue_number "$pr_output")
PR_URL=$(echo "$pr_output" | sed 's|/issues/|/pull/|')

log "PR created: #$PR_NUMBER"

# =============================================================================
# Output JSON Report
# =============================================================================

report=$(cat <<EOF
{
  "branch": "$BRANCH_NAME",
  "base": "$BASE_BRANCH",
  "pr_number": $PR_NUMBER,
  "pr_url": "$PR_URL",
  "pr_title": "$(json_escape "$PR_TITLE")",
  "draft": $([ "$NO_DRAFT" == "1" ] && echo "false" || echo "true"),
  "issue_number": $([ -n "$ISSUE_NUMBER" ] && echo "$ISSUE_NUMBER" || echo "null")
}
EOF
)

json_output "$report"
