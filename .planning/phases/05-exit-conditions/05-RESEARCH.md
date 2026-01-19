# Phase 5: Exit Conditions - Research

**Researched:** 2026-01-19
**Domain:** Bash signal handling, exit codes, state tracking
**Confidence:** HIGH

## Summary

Phase 5 implements exit conditions for the Ralph autonomous loop. The key challenges are: (1) detecting test-based completion by parsing output, (2) tracking consecutive failures on the same task for stuck detection, (3) implementing a dual-exit gate that requires both completion markers AND explicit signals, and (4) handling Ctrl+C gracefully.

The research confirms that bash provides robust mechanisms for all requirements. The `trap` command handles graceful shutdown with SIGINT. Consecutive failure tracking requires careful state management with task identity comparison. Exit codes should follow Unix conventions with meaningful distinctions between completion states.

**Primary recommendation:** Implement exit detection in a new `exit.sh` library with functions for each exit condition check. Use trap for SIGINT handling. Track consecutive failures with explicit task ID comparison and counter variables.

## Standard Stack

The established libraries/tools for this domain:

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| bash `trap` | builtin | Signal handling for Ctrl+C | POSIX standard, universally available |
| bash arithmetic | builtin | Counter tracking | Native bash, no dependencies |
| grep -c | coreutils | Count test pass/fail lines | Standard Unix, cross-platform |
| bash exit codes | builtin | Communicate termination reason | Unix convention |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| jq | any | Parse JSON test output if available | When test frameworks emit JSON |
| grep -oE | coreutils | Extract specific patterns from output | Parse test counts from various formats |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| grep for test parsing | awk | awk more powerful but grep simpler for count patterns |
| trap SIGINT | trap EXIT | EXIT trap only fires on normal exit in some shells |
| manual counter | external tool | external tools add dependencies, counter is trivial |

**Installation:**
```bash
# No installation needed - all builtins and coreutils
```

## Architecture Patterns

### Recommended Project Structure
```
bin/lib/
├── exit.sh              # NEW: Exit condition detection functions
├── failfast.sh          # Existing: retry logic, checkpoint
├── state.sh             # Existing: STATE.md updates
├── display.sh           # Existing: terminal output
└── checkpoint.sh        # Existing: git checkpointing

# State tracked in ralph.sh main loop:
#   - CONSECUTIVE_FAILURES (counter)
#   - LAST_FAILED_TASK (task ID for comparison)
#   - INTERRUPTED (flag for Ctrl+C)
```

### Pattern 1: Signal Trap for Graceful Exit
**What:** Use bash trap to intercept SIGINT (Ctrl+C) and set a flag instead of immediate exit
**When to use:** When you need to finish current iteration before exiting
**Example:**
```bash
# Source: https://mywiki.wooledge.org/SignalTrap
INTERRUPTED=false

# Set up trap BEFORE entering main loop
trap 'INTERRUPTED=true' INT

while true; do
    # Main loop work...

    # Check at safe point (end of iteration)
    if [[ "$INTERRUPTED" == "true" ]]; then
        echo "Ctrl+C received, exiting gracefully..."
        # Perform cleanup, create final checkpoint
        exit 3  # INTERRUPTED exit code
    fi
done
```

### Pattern 2: Consecutive Failure Tracking
**What:** Track failures on the SAME task, reset counter when task changes
**When to use:** Stuck detection - same task failing repeatedly
**Example:**
```bash
# Source: Bash scripting best practices
CONSECUTIVE_FAILURES=0
LAST_FAILED_TASK=""
STUCK_THRESHOLD=3

handle_task_failure() {
    local task_id="$1"

    if [[ "$task_id" == "$LAST_FAILED_TASK" ]]; then
        ((CONSECUTIVE_FAILURES++))
        if [[ $CONSECUTIVE_FAILURES -ge $STUCK_THRESHOLD ]]; then
            return 1  # Signal stuck condition
        fi
    else
        # Different task failed - reset counter
        CONSECUTIVE_FAILURES=1
        LAST_FAILED_TASK="$task_id"
    fi

    return 0  # Not stuck yet
}
```

### Pattern 3: Dual-Exit Gate
**What:** Require BOTH completion markers AND explicit signal before exiting successfully
**When to use:** Prevent premature exit when tests pass but work remains
**Example:**
```bash
# Both conditions must be true for COMPLETED exit
check_completion() {
    local tests_pass=false
    local requirements_done=false

    # Check 1: All tests pass
    if check_tests_pass; then
        tests_pass=true
    fi

    # Check 2: All requirements marked complete
    if check_requirements_complete; then
        requirements_done=true
    fi

    # Dual gate: BOTH must be true
    if [[ "$tests_pass" == "true" && "$requirements_done" == "true" ]]; then
        return 0  # COMPLETED
    fi

    return 1  # Not complete yet
}
```

### Pattern 4: Exit Code Mapping
**What:** Map exit reasons to distinct codes following Unix convention
**When to use:** Always - enables callers to distinguish exit types
**Example:**
```bash
# Source: https://www.baeldung.com/linux/status-codes
# Exit code conventions (from 05-CONTEXT.md):
#   0 = COMPLETED (success)
#   1 = STUCK (same task failed consecutively)
#   2 = ABORTED (cap reached or fatal error)
#   3 = INTERRUPTED (user Ctrl+C)

exit_with_status() {
    local status="$1"
    local reason="$2"
    local last_task="$3"

    # Log to STATE.md
    log_exit_status "$status" "$reason" "$last_task"

    # Map status to exit code
    case "$status" in
        COMPLETED)   exit 0 ;;
        STUCK)       exit 1 ;;
        ABORTED)     exit 2 ;;
        INTERRUPTED) exit 3 ;;
        *)           exit 2 ;;  # Default to ABORTED
    esac
}
```

### Anti-Patterns to Avoid
- **Immediate exit on Ctrl+C:** Never `trap 'exit 1' INT`. This loses partial work. Set a flag and check it at safe points.
- **Checking exit code only for tests:** Exit code 0 from test command doesn't mean all tests pass - some frameworks return 0 with failed tests if they complete cleanly. Parse output.
- **Global failure counter:** Counting all failures doesn't detect stuck loops. Track failures per-task.
- **Trusting single completion signal:** Tests passing but requirements not done = incomplete. Always check both.

## Don't Hand-Roll

Problems that look simple but have existing solutions:

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Signal handling | Custom signal polling | bash `trap` builtin | trap is POSIX, handles edge cases |
| Exit code semantics | Arbitrary codes | Unix conventions 0-3 | Interoperability with other tools |
| Test output parsing | Custom parser per framework | grep -c with common patterns | Handles most test frameworks (pass/fail/ok/error) |

**Key insight:** Exit condition detection is primarily about state tracking and bash builtins. The codebase already has all the infrastructure needed - this phase is about wiring it together correctly.

## Common Pitfalls

### Pitfall 1: Subshell Counter Problem
**What goes wrong:** Counter variable incremented in a pipe or subshell doesn't persist
**Why it happens:** Bash runs each pipe segment in a subshell; variable changes don't propagate
**How to avoid:** Keep counter logic in main shell, not in functions called from pipes. Use `< <(command)` process substitution instead of pipes when needed.
**Warning signs:** Counter stays at initial value despite failure logic executing

### Pitfall 2: Trap Overwriting
**What goes wrong:** Multiple `trap` calls overwrite previous handlers
**Why it happens:** trap replaces handler for a signal, doesn't add to it
**How to avoid:** Use a single trap handler that calls multiple cleanup functions
**Warning signs:** Cleanup code stops running after adding new trap
```bash
# WRONG:
trap 'cleanup1' EXIT
trap 'cleanup2' EXIT  # This REPLACES cleanup1!

# RIGHT:
cleanup_all() {
    cleanup1
    cleanup2
}
trap 'cleanup_all' EXIT
```

### Pitfall 3: Race Condition with Interrupt Flag
**What goes wrong:** Ctrl+C during critical section (git commit) leaves repo in bad state
**Why it happens:** Flag gets set but code continues executing dangerous operations
**How to avoid:** Temporarily ignore SIGINT during critical sections with `trap '' INT`, restore after
**Warning signs:** Partial commits, corrupted STATE.md
```bash
# Protect critical section
trap '' INT  # Ignore during critical work
git commit -m "checkpoint"
trap 'INTERRUPTED=true' INT  # Restore handler
```

### Pitfall 4: Test Parsing Brittleness
**What goes wrong:** Test completion detection breaks when test framework updates output format
**Why it happens:** Grep pattern too specific to framework version
**How to avoid:** Use multiple common patterns; accept false negatives over false positives
**Warning signs:** Tests clearly passing but completion not detected
```bash
# Check multiple common patterns
if grep -qE '(PASS|OK|passed|success)' "$output"; then
    # Potentially passing
fi
if grep -qE '(FAIL|ERROR|failed|error)' "$output"; then
    # Definitely has failures
fi
```

### Pitfall 5: Exit Trap Not Firing on SIGINT
**What goes wrong:** EXIT trap doesn't run when script killed by Ctrl+C
**Why it happens:** Some shells (dash, zsh) only fire EXIT on normal termination
**How to avoid:** In bash, trap BOTH INT and EXIT, or re-raise signal after cleanup
**Warning signs:** Cleanup never runs on Ctrl+C
```bash
# Source: https://mywiki.wooledge.org/SignalTrap
trap 'cleanup; trap - INT; kill -INT $$' INT
```

## Code Examples

Verified patterns from official sources:

### Test Output Parsing
```bash
# Source: https://www.cyberciti.biz/faq/grep-count-lines-if-a-string-word-matches/

# Count pass/fail from test output
parse_test_results() {
    local output_file="$1"

    # Count failures (various frameworks)
    local fail_count
    fail_count=$(grep -ciE '(FAIL|ERROR|FAILED)' "$output_file" 2>/dev/null || echo "0")

    # Count passes (various frameworks)
    local pass_count
    pass_count=$(grep -ciE '(PASS|OK|PASSED|SUCCESS)' "$output_file" 2>/dev/null || echo "0")

    if [[ $fail_count -eq 0 && $pass_count -gt 0 ]]; then
        echo "TESTS_PASS"
        return 0
    elif [[ $fail_count -gt 0 ]]; then
        echo "TESTS_FAIL:$fail_count"
        return 1
    else
        echo "TESTS_UNKNOWN"
        return 2  # Could not determine
    fi
}
```

### ROADMAP.md Completion Check
```bash
# Check if all plans in current milestone are complete
# Uses existing ROADMAP.md checkbox pattern from codebase

check_all_plans_complete() {
    local roadmap="${ROADMAP_FILE:-.planning/ROADMAP.md}"

    # Count uncompleted plans: - [ ] NN-MM-PLAN.md
    local incomplete
    incomplete=$(grep -cE '^\s*- \[ \] [0-9]{2}-[0-9]{2}-PLAN\.md' "$roadmap" 2>/dev/null || echo "0")

    if [[ $incomplete -eq 0 ]]; then
        return 0  # All complete
    else
        return 1  # Still have incomplete plans
    fi
}
```

### Exit Logging to STATE.md
```bash
# Log exit status to STATE.md for user review

log_exit_status() {
    local status="$1"
    local reason="$2"
    local last_task="$3"
    local iteration_count="$4"
    local duration="$5"

    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    # Build status line
    local status_line="Status: $status"

    # Update STATE.md Status line
    sed -i "s/^Status: .*/Status: $status/" "$STATE_FILE"

    # Add to iteration history
    add_iteration_entry "$iteration_count" "$status" "$reason (last: $last_task)"

    # Terminal output with appropriate color
    case "$status" in
        COMPLETED)
            echo -e "${GREEN}${BOLD}=== Ralph Complete: $status ===${RESET}"
            ;;
        STUCK)
            echo -e "${RED}${BOLD}=== Ralph Stuck: $reason ===${RESET}"
            ;;
        *)
            echo -e "${YELLOW}${BOLD}=== Ralph Exited: $status ===${RESET}"
            ;;
    esac

    echo "Last task: $last_task"
    echo "Iterations: $iteration_count"
    echo "Duration: $duration"
}
```

### Graceful Interrupt Handler
```bash
# Source: https://mywiki.wooledge.org/SignalTrap

# Global state
INTERRUPTED=false
IN_CRITICAL_SECTION=false

# Interrupt handler
handle_interrupt() {
    if [[ "$IN_CRITICAL_SECTION" == "true" ]]; then
        # Defer handling until critical section complete
        INTERRUPTED=true
        return
    fi

    echo ""
    echo -e "${YELLOW}Interrupt received, finishing current iteration...${RESET}"
    INTERRUPTED=true
}

# Set up trap at script start
trap 'handle_interrupt' INT

# Use in critical sections
do_critical_work() {
    IN_CRITICAL_SECTION=true
    # Git commit, STATE.md write, etc.
    git commit -m "checkpoint"
    IN_CRITICAL_SECTION=false

    # Check if interrupt was deferred
    if [[ "$INTERRUPTED" == "true" ]]; then
        exit_with_status "INTERRUPTED" "User interrupt" "$current_task"
    fi
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Exit on any failure | Retry with stuck detection | Modern CI/CD | Enables autonomous recovery |
| Single exit code | Meaningful exit codes | Unix convention | Better scripting integration |
| trap EXIT only | trap INT + EXIT | Bash best practices | Reliable cleanup on interrupt |
| Parse test exit code | Parse test output | Test framework maturity | More accurate pass/fail detection |

**Deprecated/outdated:**
- `set -e` as error handling: Modern best practice is explicit error checking, not implicit exit on error
- Arbitrary exit codes: Should follow Unix conventions (0-3 for this use case)

## Open Questions

Things that couldn't be fully resolved:

1. **Test output format detection**
   - What we know: Common patterns (PASS/FAIL/OK/ERROR) cover most frameworks
   - What's unclear: Should we auto-detect framework type for better parsing?
   - Recommendation: Start with generic patterns; add framework-specific parsing later if needed (Claude's discretion)

2. **Verification iteration after completion**
   - What we know: CONTEXT.md marks this as Claude's discretion
   - What's unclear: Whether extra iteration adds value vs wastes tokens
   - Recommendation: Skip verification iteration initially; the dual-exit gate already provides safety

3. **Exit message next-steps guidance**
   - What we know: CONTEXT.md marks this as Claude's discretion
   - What's unclear: What guidance is most useful
   - Recommendation: Include brief next-steps based on exit status (e.g., "Review stuck task", "Run ralph.sh to continue")

## Sources

### Primary (HIGH confidence)
- [Greg's Wiki SignalTrap](https://mywiki.wooledge.org/SignalTrap) - Authoritative bash signal handling patterns
- [Baeldung Linux Status Codes](https://www.baeldung.com/linux/status-codes) - Unix exit code conventions
- [nixCraft grep tutorials](https://www.cyberciti.biz/faq/grep-count-lines-if-a-string-word-matches/) - Pattern matching and counting
- [Linuxize Bash Increment Variable](https://linuxize.com/post/bash-increment-decrement-variable/) - Counter tracking patterns

### Secondary (MEDIUM confidence)
- [Brandon Rozek Bash Traps](https://brandonrozek.com/blog/bash-traps-exit-error-sigint/) - Practical trap examples
- [TLDP Exit Codes](https://tldp.org/LDP/abs/html/exitcodes.html) - Reserved exit code ranges
- [Red Hat Exit Codes](https://www.redhat.com/en/blog/exit-codes-demystified) - Enterprise perspective on exit codes

### Tertiary (LOW confidence)
- None - all findings verified with primary sources

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - bash builtins and coreutils are well-documented
- Architecture: HIGH - patterns derived from official documentation
- Pitfalls: HIGH - documented in Greg's Wiki (authoritative bash reference)
- Test parsing: MEDIUM - patterns work for common frameworks, may need tuning

**Research date:** 2026-01-19
**Valid until:** 60 days (bash patterns are stable)
