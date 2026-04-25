#!/usr/bin/env bash
# read-references.sh — Fetch and concatenate doc sections from an issue's References field.
#
# For each markdown URL in the References section of a GitHub issue (story, task, or bug),
# this script calls read-md.sh section and concatenates the results.
#
# IMPORTANT: This script refuses to run on epics and features. It is designed for
# stories, tasks, and bugs only — issue types whose references are granular enough
# to be useful as targeted doc reads.
#
# Usage:
#   ./scripts/read-references.sh --issue ISSUE_NUMBER
#   ./scripts/read-references.sh --refs "- [Title](./path.md#anchor)\n- ..."
#   ./scripts/read-references.sh --issue ISSUE_NUMBER --dry-run
#
# Output format (stdout):
#   === reference content for <Reference Heading> ===
#
#   <section text from read-md.sh>
#
#   ... repeated for each reference
#
# Errors go to stderr. Exit codes:
#   0  — success
#   1  — invalid arguments / missing deps
#   2  — issue type is epic or feature (refused)
#   3  — no References section found
#   4  — one or more references failed to read (partial output still printed)

set -euo pipefail

# =============================================================================
# Constants
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
READ_MD="$SCRIPT_DIR/read-md.sh"
REPO="Roudranil/swaralipi-app"

# =============================================================================
# Globals
# =============================================================================

ISSUE_NUMBER=""
REFS_TEXT=""
DRY_RUN=${DRY_RUN:-0}

# =============================================================================
# Helpers
# =============================================================================

log() {
    echo "[read-references.sh] $*" >&2
}

error() {
    echo "ERROR [read-references.sh]: $*" >&2
}

die() {
    error "$*"
    exit 1
}

# =============================================================================
# Usage
# =============================================================================

usage() {
    cat <<EOF
read-references.sh — Fetch and concatenate referenced doc sections for an issue.

IMPORTANT: Only works on stories, tasks, and bugs.
           Epics and features are refused — their references are intentionally broad.

Usage:
  $(basename "$0") --issue ISSUE_NUMBER [--dry-run]
  $(basename "$0") --refs TEXT_BLOCK [--dry-run]

OPTIONS:
  --issue N        GitHub issue number. The script will fetch the issue body, extract
                   the References section, and read each referenced doc section.

  --refs TEXT      Raw text block containing a markdown list of references.
                   Useful for testing or when the issue body is already available.
                   Example:
                     --refs "- [SDS §3.2](./docs/02-technical/sds.md#32-data-layer)
                   - [Data Model](./docs/02-technical/data-model.md#notation)"

  --dry-run        Print the read-md.sh commands that would be run without executing them.

  --help, -h       Print this help and exit.

OUTPUT FORMAT:
  === reference content for <Reference Heading> ===

  <section text>

  ... repeated for each reference

EXAMPLES:
  # Read all references for issue 42 (story/task/bug)
  ./scripts/read-references.sh --issue 42

  # Dry run — see which read-md.sh calls would be made
  ./scripts/read-references.sh --issue 42 --dry-run

  # Pass a raw reference block directly
  ./scripts/read-references.sh --refs "- [SDS Data Layer](./docs/02-technical/sds.md#3-data-layer)"

EXIT CODES:
  0  success
  1  invalid arguments or missing dependencies
  2  issue is an epic or feature (refused)
  3  no References section found in the issue body
  4  one or more references failed to read (partial output still printed)
EOF
}

# =============================================================================
# Parse arguments
# =============================================================================

while [[ $# -gt 0 ]]; do
    case "$1" in
        --issue)
            [[ $# -ge 2 ]] || die "--issue requires a value"
            ISSUE_NUMBER="$2"
            shift 2
            ;;
        --refs)
            [[ $# -ge 2 ]] || die "--refs requires a value"
            REFS_TEXT="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=1
            shift
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        *)
            die "Unknown option: $1. Use --help for usage."
            ;;
    esac
done

# =============================================================================
# Validate inputs
# =============================================================================

[[ -n "$ISSUE_NUMBER" || -n "$REFS_TEXT" ]] \
    || die "Provide either --issue ISSUE_NUMBER or --refs TEXT_BLOCK"

[[ -n "$ISSUE_NUMBER" && -n "$REFS_TEXT" ]] \
    && die "Provide --issue OR --refs, not both"

# =============================================================================
# Verify dependencies
# =============================================================================

if ! command -v gh &>/dev/null; then
    die "gh (GitHub CLI) is required but not found. Install from https://cli.github.com/"
fi

if [[ ! -x "$READ_MD" ]]; then
    die "read-md.sh not found or not executable at: $READ_MD"
fi

# =============================================================================
# Fetch issue body and detect issue type (when --issue is used)
# =============================================================================

if [[ -n "$ISSUE_NUMBER" ]]; then
    log "Fetching issue #$ISSUE_NUMBER from $REPO..."

    issue_json=$(gh issue view "$ISSUE_NUMBER" \
        --repo "$REPO" \
        --json title,body,labels 2>/dev/null) \
        || die "Failed to fetch issue #$ISSUE_NUMBER. Check issue number and gh auth."

    issue_title=$(echo "$issue_json" | grep -o '"title":"[^"]*"' | head -1 | sed 's/"title":"//;s/"//')
    issue_body=$(echo "$issue_json" | python3 -c "
import json, sys
data = json.load(sys.stdin)
print(data.get('body', ''))
" 2>/dev/null || echo "$issue_json" | sed -n 's/.*"body":"\(.*\)","labels".*/\1/p')

    # Extract labels
    issue_labels=$(echo "$issue_json" | python3 -c "
import json, sys
data = json.load(sys.stdin)
labels = [l['name'] for l in data.get('labels', [])]
print(' '.join(labels))
" 2>/dev/null || echo "")

    log "Issue: $issue_title"
    log "Labels: $issue_labels"

    # =============================================================================
    # Guard: refuse to run on epics and features
    # =============================================================================

    for label in $issue_labels; do
        if [[ "$label" == "epic" || "$label" == "feature" ]]; then
            echo "" >&2
            echo "ERROR: read-references.sh refused for issue type: $label" >&2
            echo "" >&2
            echo "This script is only for stories, tasks, and bugs." >&2
            echo "Epics and features have broad, overarching references that are" >&2
            echo "not suitable for mass reference reading." >&2
            echo "" >&2
            exit 2
        fi
    done

    # =============================================================================
    # Extract the References section from the issue body
    # =============================================================================

    # Use Python for robust extraction (handles multi-line bodies, escaped chars, etc.)
    REFS_TEXT=$(echo "$issue_body" | python3 -c "
import sys, re

body = sys.stdin.read()
# Normalise Windows line endings
body = body.replace('\\\\r\\\\n', '\\n').replace('\\\\r', '\\n')
# Unescape \\n sequences that gh CLI may produce inside JSON strings
body = body.replace('\\\\n', '\\n')

# Find the References section: between ## References and the next ## heading
match = re.search(
    r'##\s+References\s*\n(.*?)(?=\n##\s|\Z)',
    body,
    re.DOTALL | re.IGNORECASE
)
if match:
    print(match.group(1).strip())
else:
    sys.exit(1)
" 2>/dev/null) || {
        error "No 'References' section found in issue #$ISSUE_NUMBER."
        error "Ensure the issue body contains a '## References' heading with markdown URL list items."
        exit 3
    }

    if [[ -z "$REFS_TEXT" ]]; then
        error "References section in issue #$ISSUE_NUMBER is empty."
        exit 3
    fi

    log "References block extracted ($(echo "$REFS_TEXT" | wc -l) lines)"
fi

# =============================================================================
# Parse the references text into individual (heading, file, anchor) tuples
# =============================================================================
# Expected format: - [Heading Text](./docs/path/to/file.md#anchor-or-empty)
# Lines that don't match this pattern are skipped with a warning.

parse_references() {
    python3 -c '
import sys, re

refs_text = sys.stdin.read()

# Pattern: - [Display text](./some/path.md#optional-anchor)
pattern = re.compile(
    r"^\s*-\s+\[([^\]]+)\]\(([^)]+)\)\s*$",
    re.MULTILINE
)

matches = pattern.findall(refs_text)
for heading, url in matches:
    heading = heading.strip()
    url = url.strip()

    # Split into file path and anchor
    if "#" in url:
        file_path, anchor = url.split("#", 1)
    else:
        file_path = url
        anchor = ""

    # Strip leading ./ from path
    file_path = file_path.lstrip("./")

    print(f"{heading}\t{file_path}\t{anchor}")
'
}

parsed=$(echo "$REFS_TEXT" | parse_references)

if [[ -z "$parsed" ]]; then
    error "No valid markdown URL references found in the References section."
    error "Expected format: - [Heading](./docs/path/to/file.md#optional-anchor)"
    error ""
    error "Raw References text was:"
    error "$REFS_TEXT"
    exit 3
fi

ref_count=$(echo "$parsed" | wc -l)
log "Parsed $ref_count reference(s)"

# =============================================================================
# For each reference: call read-md.sh and print output with header
# =============================================================================

failed=0

while IFS=$'\t' read -r heading file_path anchor; do
    echo ""
    echo "=== reference content for $heading ==="
    echo ""

    # Resolve file path relative to repo root
    abs_path="$REPO_ROOT/$file_path"

    if [[ ! -f "$abs_path" ]]; then
        echo "[read-references.sh] WARNING: File not found: $abs_path" >&2
        echo "(File not found: $file_path)"
        echo ""
        failed=1
        continue
    fi

    if [[ -n "$anchor" ]]; then
        # Convert GitHub anchor back to a heading search string:
        # anchor "321-notationrepository-interface" → "3.2.1 NotationRepository interface" (approx)
        # We use the anchor as a grep pattern since read-md.sh supports --grep
        search_term="$anchor"

        read_cmd=("$READ_MD" section "$abs_path" "$search_term" --grep --with-subsections)
    else
        # No anchor — read the entire file's TOC
        read_cmd=("$READ_MD" toc "$abs_path")
    fi

    if [[ "$DRY_RUN" == "1" ]]; then
        log "DRY-RUN: ${read_cmd[*]}"
        echo "(dry-run — command: ${read_cmd[*]})"
    else
        if ! output=$("${read_cmd[@]}" 2>/dev/null); then
            # Fallback: if anchor grep failed, try the last segment of the anchor as search
            if [[ -n "$anchor" ]]; then
                # Try the last word/phrase of the anchor as a fuzzy match
                fallback_term=$(echo "$anchor" | sed 's/-/ /g' | awk '{print $NF}')
                log "Anchor grep failed for '$anchor', retrying with fallback: '$fallback_term'"
                fallback_cmd=("$READ_MD" section "$abs_path" "$fallback_term" --with-subsections)
                output=$("${fallback_cmd[@]}" 2>/dev/null) || {
                    echo "(Could not read section '$anchor' from $file_path)" >&2
                    echo "(Could not read section '$anchor' from $file_path)"
                    failed=1
                    echo ""
                    continue
                }
            else
                echo "(Could not read $file_path)" >&2
                echo "(Could not read $file_path)"
                failed=1
                echo ""
                continue
            fi
        fi
        echo "$output"
    fi

    echo ""

done <<< "$parsed"

# =============================================================================
# Exit code
# =============================================================================

if [[ "$failed" -ne 0 ]]; then
    log "One or more references failed to read. Partial output was printed."
    exit 4
fi

log "Done. All $ref_count reference(s) read successfully."
exit 0
