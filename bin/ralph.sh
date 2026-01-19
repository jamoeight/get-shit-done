#!/bin/bash
# GSD Ralph - Outer Loop Entry Point
# Part of Phase 3: Outer Loop Core
#
# Main script that spawns fresh Claude Code instances to execute plans sequentially.
# Reads STATE.md to determine next task, invokes Claude with full GSD context,
# parses results, updates state, and loops until completion or budget cap reached.
#
# Usage:
#   ./bin/ralph.sh                    # Start from current STATE.md position
#   ./bin/ralph.sh --start-from 03-02 # Override starting point

set -euo pipefail

# =============================================================================
# Script Setup
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source all lib files
source "${SCRIPT_DIR}/lib/budget.sh"
source "${SCRIPT_DIR}/lib/state.sh"
source "${SCRIPT_DIR}/lib/display.sh"
source "${SCRIPT_DIR}/lib/failfast.sh"
source "${SCRIPT_DIR}/lib/parse.sh"

# Log file configuration
LOG_FILE="${LOG_FILE:-.planning/ralph.log}"

# =============================================================================
# Logging Functions
# =============================================================================

# log_iteration - Append iteration entry to log file
# Args: iteration, status, task, summary, duration
log_iteration() {
    local iteration_num="$1"
    local status="$2"
    local task="$3"
    local summary="$4"
    local duration="$5"

    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    # Ensure log file directory exists
    local log_dir
    log_dir=$(dirname "$LOG_FILE")
    if [[ ! -d "$log_dir" ]]; then
        mkdir -p "$log_dir"
    fi

    # Append to log file
    {
        echo "---"
        echo "Iteration: $iteration_num"
        echo "Timestamp: $timestamp"
        echo "Task: $task"
        echo "Status: $status"
        echo "Duration: ${duration}s"
        echo "Summary: $summary"
    } >> "$LOG_FILE"
}

# handle_iteration_success - Process successful iteration
# Args: iteration, task, summary, duration
# Updates STATE.md and advances to next plan
handle_iteration_success() {
    local iteration_num="$1"
    local task="$2"
    local summary="$3"
    local duration="$4"

    # Log the iteration
    log_iteration "$iteration_num" "SUCCESS" "$task" "$summary" "$duration"

    # Add entry to STATE.md history
    add_iteration_entry "$iteration_num" "SUCCESS" "$task: $summary"

    # Determine next plan
    local next_plan
    next_plan=$(get_next_plan_after "$task")

    if [[ "$next_plan" == "COMPLETE" ]]; then
        # All plans done - update next action to reflect completion
        update_next_action "COMPLETE" "COMPLETE" "All plans executed"
    else
        # Advance to next plan
        local phase_num="${next_plan%%-*}"
        local plan_name
        plan_name=$(get_plan_name "$next_plan")
        update_next_action "$phase_num" "$next_plan" "$plan_name"
    fi

    # Update progress bar
    local completed total
    completed=$(get_plans_completed)
    total=$(get_total_plans)
    update_progress "$completed" "$total"
}

# handle_iteration_failure_state - Process failed iteration (state only)
# Args: iteration, task, error, duration
# Updates STATE.md but does NOT advance next_action (retry same task)
handle_iteration_failure_state() {
    local iteration_num="$1"
    local task="$2"
    local error="$3"
    local duration="$4"

    # Log the iteration
    log_iteration "$iteration_num" "FAILURE" "$task" "$error" "$duration"

    # Add entry to STATE.md history
    add_iteration_entry "$iteration_num" "FAILURE" "$task: $error"

    # Do NOT update next_action - stay on same task for retry
}

# =============================================================================
# Argument Parsing
# =============================================================================

START_FROM=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --start-from)
            if [[ -n "${2:-}" ]]; then
                START_FROM="$2"
                shift 2
            else
                echo -e "${RED}Error: --start-from requires a plan ID (e.g., 03-02)${RESET}" >&2
                exit 1
            fi
            ;;
        --help|-h)
            echo "Usage: ralph.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --start-from NN-MM  Override starting plan (e.g., 03-02)"
            echo "  --help, -h          Show this help message"
            echo ""
            echo "Ralph spawns fresh Claude instances to execute plans sequentially."
            echo "Reads STATE.md for next task, invokes Claude, updates state, and loops."
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${RESET}" >&2
            echo "Use --help for usage information." >&2
            exit 1
            ;;
    esac
done

# Validate --start-from format if provided
if [[ -n "$START_FROM" ]]; then
    if ! [[ "$START_FROM" =~ ^[0-9]{2}-[0-9]{2}$ ]]; then
        echo -e "${RED}Error: --start-from must be in NN-MM format (e.g., 03-02)${RESET}" >&2
        exit 1
    fi
fi

# =============================================================================
# Startup Sequence
# =============================================================================

# Load configuration (sets MAX_ITERATIONS, TIMEOUT_HOURS)
load_config

# Record start time
START_TIME=$(date +%s)

# Show startup summary
show_startup_summary() {
    echo -e "${BOLD}${CYAN}=== Ralph Outer Loop ===${RESET}"
    echo ""
    echo -e "Config: ${GREEN}$MAX_ITERATIONS iterations${RESET}, ${GREEN}${TIMEOUT_HOURS}h timeout${RESET}"

    # Parse current position from STATE.md
    local phase plan status
    phase=$(grep "^Phase:" "$STATE_FILE" 2>/dev/null | head -1 | sed 's/Phase: //')
    plan=$(grep "^Plan:" "$STATE_FILE" 2>/dev/null | head -1 | sed 's/Plan: //')
    status=$(grep "^Status:" "$STATE_FILE" 2>/dev/null | head -1 | sed 's/Status: //')

    echo -e "Position: Phase ${phase:-unknown}, Plan ${plan:-unknown}"
    echo -e "Status: ${status:-unknown}"

    # Determine starting task
    local next_task
    if [[ -n "$START_FROM" ]]; then
        next_task="$START_FROM"
        echo -e "Starting from: ${YELLOW}${next_task}${RESET} (override)"
    else
        next_task=$(parse_next_task)
        echo -e "Next task: ${YELLOW}${next_task}${RESET}"
    fi

    echo ""
}

show_startup_summary

# Mark checkpoint for potential rollback
mark_checkpoint

# =============================================================================
# Main Loop
# =============================================================================

iteration=0
next_task=""
iteration_start=0
iteration_duration=0
while true; do
    iteration=$((iteration + 1))

    # Check budget limits
    if ! check_limits "$iteration"; then
        handle_limit_reached
        exit 1
    fi

    # Get next task
    if [[ -n "$START_FROM" && $iteration -eq 1 ]]; then
        # Use override for first iteration only
        next_task="$START_FROM"
    else
        next_task=$(parse_next_task)
    fi

    if [[ "$next_task" == "COMPLETE" || -z "$next_task" ]]; then
        show_status "All tasks complete!" "success"
        break
    fi

    # Record iteration start time
    iteration_start=$(date +%s)

    # Show iteration start
    show_status "[$iteration/$MAX_ITERATIONS] Starting $next_task..." "info"

    # PLACEHOLDER: Claude invocation will be added in 03-02
    # For now, simulate success and exit for testing
    # Real invocation will:
    # 1. Call invoke_claude "$next_task"
    # 2. Check exit code
    # 3. Parse response for summary
    # 4. Call handle_iteration_success or handle_iteration_failure_state

    # Calculate iteration duration
    iteration_duration=$(( $(date +%s) - iteration_start ))

    # Simulate success (placeholder - 03-02 will add real invocation)
    echo "TODO: invoke_claude $next_task"
    echo "(Simulating success for testing)"

    # For testing: call success handler with simulated summary
    handle_iteration_success "$iteration" "$next_task" "Test iteration completed" "$iteration_duration"

    break  # Exit after first iteration for now (remove when Claude invocation added)
done

# =============================================================================
# Post-Loop Cleanup
# =============================================================================

# Calculate duration
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
DURATION_FMT=$(format_duration "$DURATION")

echo ""
echo -e "${BOLD}${GREEN}=== Ralph Complete ===${RESET}"
echo -e "Iterations: $iteration"
echo -e "Duration: $DURATION_FMT"
echo ""
