#!/usr/bin/env bash
# Watch a running agent's JSONL output file in real time.
# Usage: ./scripts/watch-agent.sh <path-to-agent.output>

set -euo pipefail

FILE="${1:-}"
if [[ -z "$FILE" ]]; then
    echo "Usage: $0 <path-to-agent.output>" >&2
    exit 1
fi

if ! command -v jq &>/dev/null; then
    echo "Error: jq is required" >&2
    exit 1
fi

trunc() { echo "${1:0:20}"; }

dim='\033[2m'
cyan='\033[36m'
yellow='\033[33m'
green='\033[32m'
magenta='\033[35m'
reset='\033[0m'

parse_line() {
    local line="$1"

    # Must be valid JSON
    if ! echo "$line" | jq empty 2>/dev/null; then
        return
    fi

    local type
    type=$(echo "$line" | jq -r '.type // ""')

    case "$type" in

        # ── Tool invocation ──────────────────────────────────────────────
        tool_use)
            local name input
            name=$(echo "$line" | jq -r '.name // "?"')
            input=$(echo "$line" | jq -r '(.input // {}) | tostring' | tr -d '\n')
            printf "${cyan}[TOOL CALL ]${reset} %-30s  ${dim}input: %s…${reset}\n" \
                "$name" "$(trunc "$input")"
            ;;

        # ── Tool result ───────────────────────────────────────────────────
        tool_result)
            local content
            content=$(echo "$line" | jq -r '
                if .content | type == "array" then
                    (.content | map(.text // "") | join(" "))
                else
                    (.content // .output // "")
                end' | tr -d '\n')
            printf "${green}[TOOL OUT  ]${reset} ${dim}%s…${reset}\n" "$(trunc "$content")"
            ;;

        # ── Assistant text ────────────────────────────────────────────────
        text)
            local text
            text=$(echo "$line" | jq -r '.text // ""' | tr -d '\n')
            printf "${yellow}[TEXT      ]${reset} ${dim}%s…${reset}\n" "$(trunc "$text")"
            ;;

        # ── Full message object (assistant or user role) ──────────────────
        message)
            local role
            role=$(echo "$line" | jq -r '.role // "?"')
            # Walk content blocks
            while IFS= read -r block; do
                local btype bname
                btype=$(echo "$block" | jq -r '.type // ""')
                case "$btype" in
                    tool_use)
                        bname=$(echo "$block" | jq -r '.name // "?"')
                        local binput
                        binput=$(echo "$block" | jq -r '(.input // {}) | tostring' | tr -d '\n')
                        printf "${cyan}[TOOL CALL ]${reset} %-30s  ${dim}input: %s…${reset}\n" \
                            "$bname" "$(trunc "$binput")"
                        ;;
                    tool_result)
                        local btext
                        btext=$(echo "$block" | jq -r '
                            if .content | type == "array" then
                                (.content | map(.text // "") | join(" "))
                            else
                                (.content // "")
                            end' | tr -d '\n')
                        printf "${green}[TOOL OUT  ]${reset} ${dim}%s…${reset}\n" "$(trunc "$btext")"
                        ;;
                    text)
                        local btxt
                        btxt=$(echo "$block" | jq -r '.text // ""' | tr -d '\n')
                        [[ -z "$btxt" ]] && continue
                        printf "${yellow}[TEXT      ]${reset} ${dim}%s…${reset}\n" "$(trunc "$btxt")"
                        ;;
                esac
            done < <(echo "$line" | jq -c '.content[]? // empty')
            ;;

        # ── Generic fallback ──────────────────────────────────────────────
        *)
            [[ -z "$type" ]] && return
            local summary
            summary=$(echo "$line" | jq -r 'tostring' | tr -d '\n')
            printf "${magenta}[%-9s]${reset} ${dim}%s…${reset}\n" "$type" "$(trunc "$summary")"
            ;;
    esac
}

echo -e "${dim}Watching: $FILE${reset}"
echo -e "${dim}─────────────────────────────────────────────────${reset}"

# Replay existing lines, then follow new ones
tail -n +1 -f "$FILE" 2>/dev/null | while IFS= read -r line; do
    parse_line "$line"
done
