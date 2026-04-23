#!/bin/bash

# read-md.sh - Tool for extracting TOC and sections from markdown files
# Usage: 
#   ./read-md.sh toc <file.md>
#   ./read-md.sh section <file.md> <heading-text> [--with-subsections] [--depth N]

set -euo pipefail

MAX_CHARS=10000
MAX_LINES=200

# Color codes for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Error codes
ERR_INVALID_ARGS=1
ERR_FILE_NOT_FOUND=2
ERR_NO_TOC=3
ERR_NO_MATCH=4
ERR_FZF_NOT_FOUND=5

# Print error message to stderr
error() {
    echo -e "${RED}Error: $1${NC}" >&2
}

message() {
    echo -e "$1" >&2
}

# Print warning message to stderr
warning() {
    echo -e "${YELLOW}Warning: $1${NC}" >&2
}

# Show usage
usage() {
    cat << EOF
CLI tool to efficiently read markdown files. File too big? No worries.
- Use \`toc\` to read the table of contents or generate it if it does not exist.
- Use \`section\` to grep for section name with fuzzy matching.

Usage:
  $0 toc <file.md>
    Returns the Table of Contents if it exists, generates one otherwise.

  $0 section <file.md> <heading-text> [options]
    Returns a section from the markdown file.
    
    Options:
      --with-subsections    Include full text of subsections (default: headers only)
      --depth N            Subsection depth to include (default: 1)
      --exact              Exact match only (default: fuzzy with fzf)
      --grep PATTERN       Use grep pattern matching instead of fuzzy search
      
    Examples:
      $0 section doc.md "Introduction"
      $0 section doc.md "Methods" --with-subsections --depth 2
      $0 section doc.md "Results" --exact
      $0 section doc.md "^[0-9]" --grep

Exit Codes:
  0 - Success
  1 - Invalid arguments
  2 - File not found
  3 - No TOC found
  4 - No matching section found
  5 - fzf not found (required for fuzzy matching)
EOF
}

# Check if fzf is installed
check_fzf() {
    if ! command -v fzf &> /dev/null; then
        error "fzf is required but not installed. Install with: brew install fzf"
        exit $ERR_FZF_NOT_FOUND
    fi
}

# Generate TOC from headings
generate_toc() {
    local file="$1"
    
    awk '
    BEGIN {
        first_line = 0
        last_line = 0
    }
    
    /^#{1,6} / {
        if (first_line == 0) first_line = NR
        last_line = NR
        
        match($0, /^#+/)
        level = RLENGTH
        text = $0
        sub(/^#+ /, "", text)
        
        # Create indentation
        indent = ""
        for (i = 1; i < level; i++) {
            indent = indent "  "
        }
        
        printf "%s- %s *(line %d)*\n", indent, text, NR
    }
    
    END {
        if (first_line > 0) {
            print "" > "/dev/stderr"
            print "--- TOC extracted from lines " first_line "-" last_line " ---" > "/dev/stderr"
        }
    }
    ' "$file"
}

# Extract Table of Contents
extract_toc() {
    local file="$1"
    
    local toc
    toc=$(awk '
    BEGIN {
        in_toc = 0
        toc_found = 0
        toc_lines = ""
        blank_count = 0
        first_line = 0
        last_line = 0
    }
    
    # Skip frontmatter
    NR == 1 && /^---$/ {
        in_frontmatter = 1
        next
    }
    
    in_frontmatter && /^---$/ {
        in_frontmatter = 0
        next
    }
    
    in_frontmatter {
        next
    }
    
    # Look for TOC start - unordered list with links
    !in_toc && /^[[:space:]]*[-*+][[:space:]]+\[.+\]\(.+\)/ {
        in_toc = 1
        toc_found = 1
        if (first_line == 0) first_line = NR
        
        # Strip URL/anchor from TOC line
        line = $0
        gsub(/\]\([^)]+\)/, "]", line)
        gsub(/\[/, "", line)
        gsub(/\]/, "", line)
        
        toc_lines = toc_lines line "\n"
        blank_count = 0
        last_line = NR
        next
    }
    
    # Continue collecting TOC lines
    in_toc {
        # Empty line
        if (/^[[:space:]]*$/) {
            blank_count++
            if (blank_count >= 2) {
                # Two consecutive blank lines end TOC
                in_toc = 0
            }
            next
        }
        
        # TOC line (indented list with link)
        if (/^[[:space:]]*[-*+][[:space:]]+\[.+\]\(.+\)/) {
            # Strip URL/anchor from TOC line
            line = $0
            gsub(/\]\([^)]+\)/, "]", line)
            gsub(/\[/, "", line)
            gsub(/\]/, "", line)
            
            toc_lines = toc_lines line "\n"
            blank_count = 0
            last_line = NR
            next
        }
        
        # Not a TOC line anymore
        in_toc = 0
    }
    
    END {
        if (toc_found) {
            printf "%s", toc_lines
            if (first_line > 0) {
                print "" > "/dev/stderr"
                print "--- TOC extracted from lines " first_line "-" last_line " ---" > "/dev/stderr"
            }
        }
    }
    ' "$file")
    
    if [ -z "$toc" ]; then
        # Generate TOC from headings
        warning "No existing TOC found. Generating best-guess TOC from headings..."
        echo ""
        generate_toc "$file"
    else
        echo "$toc"
    fi
}

# Find matching heading with grep pattern
find_heading_grep() {
    local file="$1"
    local pattern="$2"
    
    awk -v pattern="$pattern" '
    /^#{1,6} / {
        match($0, /^#+/)
        level = RLENGTH
        text = $0
        sub(/^#+ /, "", text)
        
        # Store all headings
        headings[++count] = NR "|" level "|" text
    }
    
    END {
        matched = 0
        for (i = 1; i <= count; i++) {
            split(headings[i], parts, "|")
            text = parts[3]
            
            # Use system grep for pattern matching
            cmd = "echo \"" text "\" | grep -E \"" pattern "\" > /dev/null 2>&1"
            if (system(cmd) == 0) {
                if (!matched || parts[2] < best_level) {
                    best_match = headings[i]
                    best_level = parts[2]
                }
                matched = 1
            }
        }
        
        if (matched) {
            print best_match
        }
    }
    ' "$file"
}

# Find matching heading with fuzzy search
find_heading_fuzzy() {
    local file="$1"
    local search_text="$2"
    local min_length=5
    
    # If search text is too short, require exact match
    if [ ${#search_text} -lt $min_length ]; then
        warning "Search text too short (<$min_length chars), using exact match. If this not what you intended, try specifying more of the heading."
        find_heading_exact "$file" "$search_text"
        return $?
    fi
    
    # Extract all headings with line numbers and levels
    local headings
    headings=$(awk '
    /^#{1,6} / {
        match($0, /^#+/)
        level = RLENGTH
        text = $0
        sub(/^#+ /, "", text)
        printf "%d|%d|%s\n", NR, level, text
    }
    ' "$file")
    
    if [ -z "$headings" ]; then
        error "No headings found in file"
        return $ERR_NO_MATCH
    fi
    
    # Use fzf for fuzzy selection
    local selected
    selected=$(echo "$headings" | awk -F'|' '{print $3 " (level " $2 ", line " $1 ")"}' | \
        fzf --filter="$search_text" | head -1)
    
    if [ -z "$selected" ]; then
        error "No matching heading found for: $search_text"
        return $ERR_NO_MATCH
    fi
    
    # Extract line number from selection
    local line_num
    line_num=$(echo "$selected" | sed -E 's/.*line ([0-9]+).*/\1/')
    
    # Get the actual heading line and level
    echo "$headings" | awk -F'|' -v line="$line_num" '$1 == line {print $1 "|" $2 "|" $3}'
}

# Find heading with exact match
find_heading_exact() {
    local file="$1"
    local search_text="$2"
    
    awk -v search="$search_text" '
    /^#{1,6} / {
        match($0, /^#+/)
        level = RLENGTH
        text = $0
        sub(/^#+ /, "", text)
        
        if (text == search) {
            if (best_line == 0 || level < best_level) {
                best_line = NR
                best_level = level
                best_text = text
            }
        }
    }
    
    END {
        if (best_line > 0) {
            printf "%d|%d|%s\n", best_line, best_level, best_text
        }
    }
    ' "$file"
}

# Extract section content
extract_section() {
    local file="$1"
    local start_line="$2"
    local start_level="$3"
    local with_subsections="$4"
    local depth="$5"
    
    awk -v start="$start_line" \
        -v level="$start_level" \
        -v with_subs="$with_subsections" \
        -v max_depth="$depth" \
        -v max_chars="$MAX_CHARS" \
        -v max_lines="$MAX_LINES" '
    
    BEGIN {
        capturing = 0
        char_count = 0
        line_count = 0
        truncated = 0
        end_line = 0
    }
    
    NR == start {
        capturing = 1
        output[++line_count] = $0
        char_count += length($0) + 1
        next
    }
    
    capturing {
        # Check if we hit another heading at same or higher level
        if (/^#{1,6} /) {
            match($0, /^#+/)
            current_level = RLENGTH
            
            if (current_level <= level) {
                # End of our section
                end_line = NR - 1
                capturing = 0
                exit
            }
            
            # This is a subsection
            sub_depth = current_level - level
            
            if (sub_depth <= max_depth) {
                # Include this subsection header
                output[++line_count] = $0
                char_count += length($0) + 1
                
                # Check limits
                if (char_count > max_chars || line_count > max_lines) {
                    truncated = 1
                    if (char_count > max_chars) {
                        truncated_reason = "character limit"
                    } else {
                        truncated_reason = "line limit"
                    }
                    end_line = NR
                    exit
                }
                
                if (!with_subs) {
                    # Skip content until next heading at this level or higher
                    in_skip = 1
                    skip_until_level = current_level
                }
            } else {
                # Beyond our depth, skip
                in_skip = 1
                skip_until_level = current_level
            }
            next
        }
        
        # Handle content lines
        if (in_skip) {
            # We are skipping subsection content
            next
        }
        
        # Regular content line
        output[++line_count] = $0
        char_count += length($0) + 1
        
        # Check limits
        if (char_count > max_chars || line_count > max_lines) {
            truncated = 1
            if (char_count > max_chars) {
                truncated_reason = "character limit (" max_chars " chars)"
            } else {
                truncated_reason = "line limit (" max_lines " lines)"
            }
            end_line = NR
            exit
        }
    }
    
    END {
        if (end_line == 0) {
            end_line = NR
        }
        
        # Print line range header
        printf "--- Lines %d-%d ---\n", start, end_line
        
        # Print content
        for (i = 1; i <= line_count; i++) {
            print output[i]
        }
        
        # Print truncation warning if needed
        if (truncated) {
            print ""
            print "--- TRUNCATED: Exceeded " truncated_reason " ---"
            print "--- Full section: lines " start "-" end_line " (showing " line_count " lines, ~" char_count " chars) ---"
        }
    }
    ' "$file"
}

# Main command router
main() {
    if [ $# -lt 2 ]; then
        usage
        exit $ERR_INVALID_ARGS
    fi
    
    local command="$1"
    local file="$2"
    
    # Check if file exists
    if [ ! -f "$file" ]; then
        error "File not found: $file"
        exit $ERR_FILE_NOT_FOUND
    fi
    
    case "$command" in
        toc)
            extract_toc "$file"
            exit 0
            ;;
            
        section)
            if [ $# -lt 3 ]; then
                error "Missing heading text argument"
                usage
                exit $ERR_INVALID_ARGS
            fi
            
            local heading_text="$3"
            local with_subsections=0
            local depth=1
            local exact_match=0
            local use_grep=0
            
            # Parse options
            shift 3
            while [ $# -gt 0 ]; do
                case "$1" in
                    --with-subsections)
                        with_subsections=1
                        shift
                        ;;
                    --depth)
                        if [ $# -lt 2 ]; then
                            error "--depth requires a number"
                            exit $ERR_INVALID_ARGS
                        fi
                        depth="$2"
                        shift 2
                        ;;
                    --exact)
                        exact_match=1
                        shift
                        ;;
                    --grep)
                        use_grep=1
                        shift
                        ;;
                    *)
                        error "Unknown option: $1"
                        usage
                        exit $ERR_INVALID_ARGS
                        ;;
                esac
            done
            
            # Find the heading
            local match
            if [ $use_grep -eq 1 ]; then
                match=$(find_heading_grep "$file" "$heading_text")
            elif [ $exact_match -eq 1 ]; then
                match=$(find_heading_exact "$file" "$heading_text")
            elif echo "$heading_text" | grep -qE '^[0-9]+(\.[0-9]+)*'; then
                # Looks like a section number — use grep anchored to start of heading
                local escaped
                escaped=$(echo "$heading_text" | sed 's/\./\\./g')
                match=$(find_heading_grep "$file" "^${escaped}")
            else
                check_fzf
                match=$(find_heading_fuzzy "$file" "$heading_text")
            fi
            
            if [ -z "$match" ]; then
                exit $ERR_NO_MATCH
            fi
            
            # Parse match result
            local line_num level heading_full
            line_num=$(echo "$match" | cut -d'|' -f1)
            level=$(echo "$match" | cut -d'|' -f2)
            heading_full=$(echo "$match" | cut -d'|' -f3-)
            
            message "Found: '$heading_full' (level $level, line $line_num)" >&2
            echo "" >&2
            
            # Extract the section
            extract_section "$file" "$line_num" "$level" "$with_subsections" "$depth"
            exit 0
            ;;
            
        --help|-h)
            usage
            exit 0
            ;;
            
        *)
            error "Unknown command: $command"
            usage
            exit $ERR_INVALID_ARGS
            ;;
    esac
}

# Run main
main "$@"