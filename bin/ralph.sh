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

    # Show iteration start
    show_status "[$iteration/$MAX_ITERATIONS] Starting $next_task..." "info"

    # PLACEHOLDER: Claude invocation will be added in 03-02
    # For now, just log and exit for testing
    echo "TODO: invoke_claude $next_task"
    break  # Exit after first iteration for now
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
