#!/bin/bash
# GSD Ralph - State Management
# Part of Phase 2: State Extensions
#
# Provides STATE.md manipulation functions for the ralph loop.
# Functions: atomic_write, update_section, update_current_position,
#            update_next_action, add_iteration_entry, get_iteration_count
#
# Usage:
#   source bin/lib/state.sh
#   add_iteration_entry 1 "SUCCESS" "02-01: Schema extensions"
#   update_next_action 2 "02-02" "Progress indicator"

# Configuration
STATE_FILE="${STATE_FILE:-.planning/STATE.md}"

# Color codes for error messages
STATE_RED='\e[31m'
STATE_GREEN='\e[32m'
STATE_YELLOW='\e[33m'
STATE_RESET='\e[0m'

# atomic_write - Write content to target file atomically
# Args: target (filepath), content (string)
# Returns: 0 on success, 1 on failure
# Uses write-to-temp-then-rename pattern for crash safety
atomic_write() {
    local target="$1"
    local content="$2"

    if [[ -z "$target" ]]; then
        echo -e "${STATE_RED}Error: atomic_write requires target path${STATE_RESET}" >&2
        return 1
    fi

    # Create temp file in same directory (same filesystem for atomic mv)
    local temp="${target}.tmp.$$"

    # Write content to temp file
    printf '%s' "$content" > "$temp"
    local write_result=$?

    if [[ $write_result -ne 0 ]]; then
        echo -e "${STATE_RED}Error: Failed to write to temp file${STATE_RESET}" >&2
        rm -f "$temp" 2>/dev/null
        return 1
    fi

    # Atomic rename
    mv "$temp" "$target"
    local mv_result=$?

    if [[ $mv_result -ne 0 ]]; then
        echo -e "${STATE_RED}Error: Failed to rename temp file to target${STATE_RESET}" >&2
        rm -f "$temp" 2>/dev/null
        return 1
    fi

    return 0
}

# update_section - Replace content between markers
# Args: file (filepath), start_marker (string), end_marker (string), new_content (string)
# Returns: 0 on success, 1 on failure
# Content between markers is replaced; markers are preserved
update_section() {
    local file="$1"
    local start_marker="$2"
    local end_marker="$3"
    local new_content="$4"

    if [[ ! -f "$file" ]]; then
        echo -e "${STATE_RED}Error: File not found: $file${STATE_RESET}" >&2
        return 1
    fi

    # Verify markers exist in file
    if ! grep -q "$start_marker" "$file"; then
        echo -e "${STATE_RED}Error: Start marker not found: $start_marker${STATE_RESET}" >&2
        return 1
    fi

    if ! grep -q "$end_marker" "$file"; then
        echo -e "${STATE_RED}Error: End marker not found: $end_marker${STATE_RESET}" >&2
        return 1
    fi

    # Create temp file
    local temp
    temp=$(mktemp)

    # Use awk to replace content between markers
    # - Print everything up to and including start marker
    # - Print new content
    # - Skip everything until end marker (exclusive)
    # - Print end marker and everything after
    awk -v start="$start_marker" -v end="$end_marker" -v content="$new_content" '
        BEGIN { in_section = 0 }
        index($0, start) > 0 {
            print
            print content
            in_section = 1
            next
        }
        index($0, end) > 0 {
            in_section = 0
        }
        !in_section { print }
    ' "$file" > "$temp"

    # Atomic replace
    mv "$temp" "$file"
    return $?
}

# update_current_position - Update the Current Position section
# Args: phase_num, plan_num, phase_name, status
# Returns: 0 on success, 1 on failure
# Updates Phase, Plan, Status, and Last activity lines (not Progress)
update_current_position() {
    local phase_num="$1"
    local plan_num="$2"
    local phase_name="$3"
    local status="$4"

    if [[ -z "$phase_num" || -z "$plan_num" || -z "$phase_name" || -z "$status" ]]; then
        echo -e "${STATE_RED}Error: update_current_position requires phase_num, plan_num, phase_name, status${STATE_RESET}" >&2
        return 1
    fi

    if [[ ! -f "$STATE_FILE" ]]; then
        echo -e "${STATE_RED}Error: STATE_FILE not found: $STATE_FILE${STATE_RESET}" >&2
        return 1
    fi

    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    # Create temp file
    local temp
    temp=$(mktemp)

    # Use awk to update specific lines in Current Position section
    awk -v phase="$phase_num" -v plan="$plan_num" -v pname="$phase_name" -v stat="$status" -v ts="$timestamp" '
        /^Phase: / && /of [0-9]+ \(/ {
            # Match "Phase: X of Y (Name)" pattern
            match($0, /of ([0-9]+)/, arr)
            total = arr[1]
            if (total == "") total = "10"
            print "Phase: " phase " of " total " (" pname ")"
            next
        }
        /^Plan: / && /of [0-9]+ in current phase/ {
            # Match "Plan: X of Y in current phase" pattern
            match($0, /of ([0-9]+) in/, arr)
            total = arr[1]
            if (total == "") total = "2"
            print "Plan: " plan " of " total " in current phase"
            next
        }
        /^Status: / {
            print "Status: " stat
            next
        }
        /^Last activity: / {
            print "Last activity: " ts
            next
        }
        { print }
    ' "$STATE_FILE" > "$temp"

    # Atomic replace
    mv "$temp" "$STATE_FILE"
    return $?
}

# update_next_action - Update the Next Action section
# Args: phase_num, plan_id (e.g., "02-02"), plan_name, [last_failure_note]
# Returns: 0 on success, 1 on failure
update_next_action() {
    local phase_num="$1"
    local plan_id="$2"
    local plan_name="$3"
    local last_failure_note="${4:-}"

    if [[ -z "$phase_num" || -z "$plan_id" || -z "$plan_name" ]]; then
        echo -e "${STATE_RED}Error: update_next_action requires phase_num, plan_id, plan_name${STATE_RESET}" >&2
        return 1
    fi

    if [[ ! -f "$STATE_FILE" ]]; then
        echo -e "${STATE_RED}Error: STATE_FILE not found: $STATE_FILE${STATE_RESET}" >&2
        return 1
    fi

    # Create temp file
    local temp
    temp=$(mktemp)

    # Build the new Next Action content
    local note_line=""
    if [[ -n "$last_failure_note" ]]; then
        note_line="
**Note:** $last_failure_note"
    fi

    # Use awk to replace the Next Action section content
    # We need to match lines between "## Next Action" and the next "##" section
    awk -v phase="$phase_num" -v planid="$plan_id" -v pname="$plan_name" -v note="$note_line" '
        BEGIN { in_section = 0 }
        /^## Next Action/ {
            print
            print ""
            print "Command: /gsd:execute-phase " phase
            print "Description: Execute plan " planid " (" pname ")"
            print "Read: ROADMAP.md, " planid "-PLAN.md"
            if (note != "") print note
            in_section = 1
            next
        }
        /^## / && in_section {
            in_section = 0
            print ""
            print
            next
        }
        !in_section { print }
    ' "$STATE_FILE" > "$temp"

    # Atomic replace
    mv "$temp" "$STATE_FILE"
    return $?
}

# add_iteration_entry - Add entry to Iteration History
# Args: iteration_num, outcome (SUCCESS/FAILURE/RETRY/SKIPPED), task_name
# Returns: 0 on success, 1 on failure
# Prepends new entry (newest first), preserves table header and markers
add_iteration_entry() {
    local iteration_num="$1"
    local outcome="$2"
    local task_name="$3"

    if [[ -z "$iteration_num" || -z "$outcome" || -z "$task_name" ]]; then
        echo -e "${STATE_RED}Error: add_iteration_entry requires iteration_num, outcome, task_name${STATE_RESET}" >&2
        return 1
    fi

    if [[ ! -f "$STATE_FILE" ]]; then
        echo -e "${STATE_RED}Error: STATE_FILE not found: $STATE_FILE${STATE_RESET}" >&2
        return 1
    fi

    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    # Format the new entry
    local entry="| $iteration_num | $timestamp | $outcome | $task_name |"

    # Extract existing entries (lines starting with | followed by number)
    local existing_entries
    existing_entries=$(sed -n '/<!-- HISTORY_START -->/,/<!-- HISTORY_END -->/{
        /^| [0-9]/p
    }' "$STATE_FILE")

    # Build new history content (table header + new entry + existing entries)
    local new_history="| # | Timestamp | Outcome | Task |
|---|-----------|---------|------|
$entry"

    # Append existing entries if any
    if [[ -n "$existing_entries" ]]; then
        new_history="$new_history
$existing_entries"
    fi

    # Update the section between markers
    update_section "$STATE_FILE" "<!-- HISTORY_START -->" "<!-- HISTORY_END -->" "$new_history"
    return $?
}

# get_iteration_count - Get count of entries in Iteration History
# Returns: Number of iteration entries (prints to stdout)
# Return code: 0 on success, 1 on failure
get_iteration_count() {
    if [[ ! -f "$STATE_FILE" ]]; then
        echo -e "${STATE_RED}Error: STATE_FILE not found: $STATE_FILE${STATE_RESET}" >&2
        return 1
    fi

    # Count lines that match iteration entry pattern (| number | ...)
    local count
    count=$(sed -n '/<!-- HISTORY_START -->/,/<!-- HISTORY_END -->/{
        /^| [0-9]/p
    }' "$STATE_FILE" | wc -l)

    # Trim whitespace
    count=$(echo "$count" | tr -d ' ')

    echo "$count"
    return 0
}

# =============================================================================
# Progress Bar Functions (Plan 02-02)
# =============================================================================

# Configuration for progress bar
PROGRESS_WIDTH=30

# generate_progress_bar - Generate ASCII progress bar
# Args: completed (int), total (int), [width (int)]
# Returns: Bar string via stdout (e.g., "[##########                    ] 33%")
# Default width: 30 characters
generate_progress_bar() {
    local completed="$1"
    local total="$2"
    local width="${3:-$PROGRESS_WIDTH}"

    # Handle edge case: 0 total
    if [[ "$total" -eq 0 ]]; then
        printf '[%*s] 0%%\n' "$width" ""
        return 0
    fi

    # Calculate percentage (integer division)
    local percent=$((completed * 100 / total))

    # Calculate filled portion
    local filled=$((completed * width / total))
    local empty=$((width - filled))

    # Build the bar string
    local bar=""
    for ((i = 0; i < filled; i++)); do
        bar+="#"
    done
    for ((i = 0; i < empty; i++)); do
        bar+=" "
    done

    printf '[%s] %d%%\n' "$bar" "$percent"
    return 0
}

# update_progress - Update Progress line in STATE.md
# Args: completed (int), total (int)
# Returns: 0 on success, 1 on failure
update_progress() {
    local completed="$1"
    local total="$2"

    if [[ -z "$completed" || -z "$total" ]]; then
        echo -e "${STATE_RED}Error: update_progress requires completed and total${STATE_RESET}" >&2
        return 1
    fi

    if [[ ! -f "$STATE_FILE" ]]; then
        echo -e "${STATE_RED}Error: STATE_FILE not found: $STATE_FILE${STATE_RESET}" >&2
        return 1
    fi

    # Generate the progress bar
    local bar
    bar=$(generate_progress_bar "$completed" "$total")

    # Create temp file
    local temp
    temp=$(mktemp)

    # Use sed to replace the Progress line
    sed "s|^Progress: \[.*\] [0-9]*%$|Progress: $bar|" "$STATE_FILE" > "$temp"

    # Atomic replace
    mv "$temp" "$STATE_FILE"
    return $?
}

# get_plans_completed - Count completed plans from ROADMAP.md
# Returns: Number of completed plans (prints to stdout)
# Counts lines matching `- [x]` pattern in phase Plans sections
get_plans_completed() {
    local roadmap="${ROADMAP_FILE:-.planning/ROADMAP.md}"

    if [[ ! -f "$roadmap" ]]; then
        echo -e "${STATE_RED}Error: ROADMAP_FILE not found: $roadmap${STATE_RESET}" >&2
        return 1
    fi

    # Count lines matching "- [x]" pattern (completed plans)
    local count
    count=$(grep -c '^\- \[x\]' "$roadmap" 2>/dev/null || echo "0")

    # Trim whitespace
    count=$(echo "$count" | tr -d ' ')

    echo "$count"
    return 0
}

# get_total_plans - Count total plans from ROADMAP.md
# Returns: Number of total plans (prints to stdout)
# Counts lines matching `- [ ]` OR `- [x]` pattern
get_total_plans() {
    local roadmap="${ROADMAP_FILE:-.planning/ROADMAP.md}"

    if [[ ! -f "$roadmap" ]]; then
        echo -e "${STATE_RED}Error: ROADMAP_FILE not found: $roadmap${STATE_RESET}" >&2
        return 1
    fi

    # Count lines matching "- [ ]" or "- [x]" pattern (all plans)
    local count
    count=$(grep -cE '^\- \[(x| )\]' "$roadmap" 2>/dev/null || echo "0")

    # Trim whitespace
    count=$(echo "$count" | tr -d ' ')

    echo "$count"
    return 0
}
