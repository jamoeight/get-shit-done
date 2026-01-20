# Phase 10: Execution Commands - Research

**Researched:** 2026-01-19
**Domain:** GSD Lazy Mode Command Architecture
**Confidence:** HIGH

## Summary

Phase 10 implements the `/gsd:autopilot` command - a unified command that consolidates the originally planned separate commands (plan-milestone-all, ralph, run-milestone) into a single user-facing entry point. The user has made clear decisions in 10-CONTEXT.md: one command, interactive prompts every time, no --yes flag, progress after each iteration, graceful Ctrl+C handling with resume capability.

The existing infrastructure is comprehensive. We have:
- **ralph.sh** - The complete outer loop with iteration control, failure handling, exit conditions
- **mode.sh** - Mode read/write functions (get_mode, set_mode, require_mode)
- **budget.sh** - Budget prompting and persistence
- **planning.sh** - Planning session management
- **state.sh** - STATE.md manipulation including planning progress tracking

The autopilot command wraps these existing components, adding: settings prompts, plan existence detection, incomplete run detection, progress reporting, and graceful shutdown.

**Primary recommendation:** Create a single `commands/gsd/autopilot.md` skill command that orchestrates settings prompt, plan detection, resume detection, and spawns ralph.sh for execution. The command should be mostly orchestration logic - the heavy lifting is already implemented.

## Standard Stack

The established libraries/tools for this domain:

### Core (Already Implemented)
| Library | Location | Purpose | Status |
|---------|----------|---------|--------|
| ralph.sh | bin/ralph.sh | Outer loop execution | Complete |
| mode.sh | bin/lib/mode.sh | Mode read/write | Complete |
| budget.sh | bin/lib/budget.sh | Budget config | Complete |
| state.sh | bin/lib/state.sh | STATE.md manipulation | Complete |
| planning.sh | bin/lib/planning.sh | Planning session mgmt | Complete |
| parse.sh | bin/lib/parse.sh | ROADMAP/STATE parsing | Complete |
| checkpoint.sh | bin/lib/checkpoint.sh | Git checkpointing | Complete |
| exit.sh | bin/lib/exit.sh | Exit conditions | Complete |

### Supporting (Already Implemented)
| Library | Location | Purpose |
|---------|----------|---------|
| display.sh | bin/lib/display.sh | Terminal colors, spinner |
| recovery.sh | bin/lib/recovery.sh | Stuck analysis |
| learnings.sh | bin/lib/learnings.sh | AGENTS.md integration |
| invoke.sh | bin/lib/invoke.sh | Claude CLI invocation |
| failfast.sh | bin/lib/failfast.sh | Error handling |

### New Components Needed
| Component | Purpose | Why Needed |
|-----------|---------|------------|
| commands/gsd/autopilot.md | User-facing skill command | Entry point for unified workflow |
| Config extensions in .ralph-config | Circuit breaker threshold, stuck threshold | User-configurable safety settings |

**Installation:** No new external dependencies required.

## Architecture Patterns

### Recommended Command Structure

The autopilot command should follow the established GSD skill command pattern (see lazy-mode.md, plan-milestone-all.md):

```
commands/gsd/autopilot.md
---
name: gsd:autopilot
description: Plan and execute milestone autonomously
allowed-tools:
  - Read
  - Write
  - Bash
  - Glob
  - Task
---

<objective>...</objective>
<context>...</context>
<process>
  Step 0: Validate mode (lazy only)
  Step 1: Detect existing plans
  Step 2: Detect incomplete runs
  Step 3: Prompt for settings
  Step 4: Save settings to .ralph-config
  Step 5: Execute (spawn ralph.sh or plan-milestone-all first)
  Step 6: Handle completion/interruption
</process>
<success_criteria>...</success_criteria>
```

### Pattern 1: State Detection via STATE.md

**What:** Check STATE.md for incomplete runs by examining:
- Iteration History section (has entries = prior run exists)
- Next Action section (COMPLETE vs specific plan)
- Planning Progress section (completed vs in_progress)

**When to use:** At autopilot startup to determine resume vs fresh start

**Example:**
```bash
# Check for incomplete run (iteration history has entries but not COMPLETE)
grep -q "<!-- HISTORY_START -->" .planning/STATE.md || exit 0  # No history section

# Extract next action status
NEXT_TASK=$(grep "^Description:" .planning/STATE.md | head -1 | grep -oE '[0-9]{2}-[0-9]{2}')

# If next task exists and is not COMPLETE, there's an incomplete run
if [[ -n "$NEXT_TASK" && "$NEXT_TASK" != "COMPLETE" ]]; then
    INCOMPLETE_RUN=true
fi
```

### Pattern 2: Plan Existence Detection

**What:** Check if PLAN.md files exist for all phases in ROADMAP.md

**When to use:** To determine if planning is needed before execution

**Example:**
```bash
# Use existing parse.sh functions
source bin/lib/parse.sh
UNPLANNED=$(get_unplanned_phases)

if [[ -n "$UNPLANNED" ]]; then
    echo "Phases without plans: $UNPLANNED"
    PLANS_NEEDED=true
else
    PLANS_EXIST=true
fi
```

### Pattern 3: Interactive Settings Prompt

**What:** Prompt user for settings, show defaults, validate input

**When to use:** Every autopilot invocation (per CONTEXT.md - no --yes flag)

**Example (from existing budget.sh pattern):**
```bash
prompt_settings() {
    echo "=== Autopilot Configuration ==="
    echo ""

    # Load current values as defaults
    source .planning/.ralph-config 2>/dev/null || true

    # Prompt with editable defaults
    read -e -p "Max iterations [${MAX_ITERATIONS:-50}]: " -i "${MAX_ITERATIONS:-50}" input
    MAX_ITERATIONS="${input:-${MAX_ITERATIONS:-50}}"

    read -e -p "Timeout hours [${TIMEOUT_HOURS:-8}]: " -i "${TIMEOUT_HOURS:-8}" input
    TIMEOUT_HOURS="${input:-${TIMEOUT_HOURS:-8}}"

    # New settings from CONTEXT.md
    read -e -p "Circuit breaker threshold [${CIRCUIT_BREAKER_THRESHOLD:-5}]: " -i "${CIRCUIT_BREAKER_THRESHOLD:-5}" input
    CIRCUIT_BREAKER_THRESHOLD="${input:-${CIRCUIT_BREAKER_THRESHOLD:-5}}"

    read -e -p "Stuck threshold [${STUCK_THRESHOLD:-3}]: " -i "${STUCK_THRESHOLD:-3}" input
    STUCK_THRESHOLD="${input:-${STUCK_THRESHOLD:-3}}"
}
```

### Pattern 4: Progress Reporting (One-Line Format)

**What:** Display iteration progress in one-line format after each iteration

**When to use:** During ralph.sh execution via callback or wrapper

**Example (from CONTEXT.md):**
```
[5/50] SUCCESS 03-02 Claude invocation (2m 34s)
[6/50] FAILURE 03-03 Cross-platform (45s) - Retry
```

Note: ralph.sh already has show_status and spinner functions. The progress format may need adjustment to match CONTEXT.md specification.

### Pattern 5: Graceful Interrupt Handling

**What:** Ctrl+C triggers graceful stop, checkpoint commit, exit with resume info

**When to use:** Throughout ralph.sh execution (already implemented)

**Existing implementation in exit.sh:**
```bash
# Signal handler (already exists)
handle_interrupt() {
    if [[ "$IN_CRITICAL_SECTION" == "true" ]]; then
        INTERRUPTED=true
        echo "Interrupt received - will exit after critical section completes"
    else
        INTERRUPTED=true
        echo "Interrupt received - will exit at next safe point"
    fi
}

# Critical section protection (already exists)
enter_critical_section()   # Before checkpoint commit
exit_critical_section()    # After checkpoint commit
```

### Anti-Patterns to Avoid

- **Direct exit() in functions:** Functions return exit codes; caller decides to exit (project convention)
- **Blocking on mode unset:** plan-milestone-all allows unset mode; autopilot should follow same pattern
- **Hardcoding thresholds:** Use .ralph-config for all configurable values
- **Skipping checkpoint commits:** Every successful iteration MUST commit (crash safety)

## Don't Hand-Roll

Problems that look simple but have existing solutions:

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Iteration loop | Custom while loop | ralph.sh | Handles all edge cases, exit conditions, circuit breaker |
| State parsing | grep/sed on STATE.md | parse.sh functions | parse_next_task, get_next_plan_after, etc. |
| Plan enumeration | ls/find on phases/ | parse.sh functions | get_all_phases, get_unplanned_phases, phase_has_plans |
| Progress tracking | Custom STATE.md edits | state.sh functions | update_progress, add_iteration_entry, etc. |
| Budget prompting | Raw read statements | budget.sh pattern | validate_number, editable defaults |
| Mode checking | grep on .ralph-config | mode.sh functions | get_mode, set_mode, require_mode |
| Git checkpointing | git add/commit | checkpoint.sh | validate_git_state, create_checkpoint_commit |

**Key insight:** Phase 10 is orchestration, not implementation. 95% of the machinery exists. The autopilot command wires it together with a unified UX.

## Common Pitfalls

### Pitfall 1: Not Detecting Existing Plans Correctly

**What goes wrong:** User has some plans but not all; autopilot doesn't know what to do
**Why it happens:** Checking for "any" plans vs "all" plans
**How to avoid:** Use `get_unplanned_phases` from parse.sh - returns list of phases WITHOUT plans
**Warning signs:** Empty list != all planned; compare against `get_all_phases`

### Pitfall 2: Resume Detection False Positives

**What goes wrong:** Detecting "incomplete run" when user actually completed but STATE.md wasn't updated
**Why it happens:** Checking iteration history presence instead of actual completion state
**How to avoid:** Check BOTH: (a) iteration history exists AND (b) next action is NOT COMPLETE
**Warning signs:** User sees "Resume previous run?" when starting fresh project

### Pitfall 3: Settings Not Persisting

**What goes wrong:** User enters settings but ralph.sh uses different values
**Why it happens:** Settings written to wrong file or not sourced
**How to avoid:** Write to .planning/.ralph-config using same format as budget.sh; source before ralph.sh
**Warning signs:** Max iterations shown in prompt differs from actual loop behavior

### Pitfall 4: Interrupt During Planning Phase

**What goes wrong:** User Ctrl+C during plan-milestone-all, state is inconsistent
**Why it happens:** Planning doesn't use same checkpoint pattern as execution
**How to avoid:** Plan-milestone-all already commits after each phase; just needs graceful exit message
**Warning signs:** Incomplete PLAN.md files in phases directory

### Pitfall 5: Mode Validation Timing

**What goes wrong:** User in interactive mode can't use autopilot (correct) but sees confusing error
**Why it happens:** Mode check happens but alternative isn't clear
**How to avoid:** Match pattern from plan-phase.md/execute-phase.md - show mode, show alternative command
**Warning signs:** Error message doesn't tell user how to switch modes

## Code Examples

Verified patterns from official codebase:

### Mode Validation (from plan-phase.md)
```bash
# Read current mode
source .planning/.ralph-config 2>/dev/null || true
CURRENT_MODE="${GSD_MODE:-}"

if [[ "$CURRENT_MODE" == "interactive" ]]; then
    echo ""
    echo "Error: /gsd:autopilot is only available in Lazy mode."
    echo "Current mode: Interactive"
    echo ""
    echo "In Interactive mode, use /gsd:execute-phase for supervised execution."
    echo "Run /gsd:lazy-mode to switch to Lazy mode."
    # Exit - do not continue
fi
```

### Plan Detection (from parse.sh)
```bash
# Source the library
source bin/lib/parse.sh

# Get phases without plans
UNPLANNED=$(get_unplanned_phases)

if [[ -n "$UNPLANNED" ]]; then
    echo "The following phases need plans: $UNPLANNED"
    echo "Plans detected: Use existing or regenerate? [use/regenerate]"
else
    echo "All phases have plans."
fi
```

### Settings Persistence (from budget.sh pattern)
```bash
# Save config preserving existing values
save_autopilot_config() {
    cat > .planning/.ralph-config << EOF
# GSD Ralph configuration
# Last updated: $(date)
MAX_ITERATIONS=$MAX_ITERATIONS
TIMEOUT_HOURS=$TIMEOUT_HOURS
CIRCUIT_BREAKER_THRESHOLD=$CIRCUIT_BREAKER_THRESHOLD
STUCK_THRESHOLD=$STUCK_THRESHOLD
GSD_MODE=$GSD_MODE
EOF
}
```

### Incomplete Run Detection
```bash
# Check for incomplete run
detect_incomplete_run() {
    if [[ ! -f ".planning/STATE.md" ]]; then
        echo "none"  # No state file = fresh start
        return
    fi

    # Check if iteration history has entries
    local history_count
    history_count=$(sed -n '/<!-- HISTORY_START -->/,/<!-- HISTORY_END -->/{
        /^| [0-9]/p
    }' .planning/STATE.md | wc -l | tr -d ' ')

    if [[ "$history_count" -eq 0 ]]; then
        echo "none"  # No history = fresh start
        return
    fi

    # Check next action
    local next_task
    next_task=$(grep "^Description:" .planning/STATE.md | head -1)

    if echo "$next_task" | grep -q "COMPLETE"; then
        echo "complete"  # Previous run finished
    else
        echo "incomplete"  # Previous run didn't finish
    fi
}
```

### Progress Line Format (from CONTEXT.md spec)
```bash
# One-line progress format
show_iteration_progress() {
    local iteration="$1"
    local max="$2"
    local status="$3"
    local plan_id="$4"
    local plan_name="$5"
    local duration="$6"

    local icon
    case "$status" in
        SUCCESS) icon="SUCCESS" ;;
        FAILURE) icon="FAILURE" ;;
        SKIPPED) icon="SKIPPED" ;;
    esac

    echo "[$iteration/$max] $icon $plan_id $plan_name (${duration}s)"
}
```

## State of the Art

| Old Approach (Original Requirements) | Current Approach (CONTEXT.md Decision) | Impact |
|--------------------------------------|----------------------------------------|--------|
| Three separate commands | Single `/gsd:autopilot` command | Simpler UX, one entry point |
| --yes flag for skip prompts | No --yes flag, always prompt | User always consciously confirms |
| Log files for progress | STATE.md is the record | Simpler, no extra files |
| Pause feature | Just stop/resume | Less complexity |

**What changed:** User decided in discuss-phase that the "self-driving car" metaphor fits best - confirm settings, press go, walk away. No need for three separate commands when one does everything.

## Open Questions

Things that couldn't be fully resolved:

1. **How should autopilot invoke ralph.sh?**
   - What we know: ralph.sh is a bash script that can be run directly
   - What's unclear: Should autopilot use Bash tool to run it, or should it inline the logic?
   - Recommendation: Use Bash tool to spawn `./bin/ralph.sh` - cleaner separation, ralph.sh already handles everything

2. **What if planning fails partway through?**
   - What we know: plan-milestone-all commits after each phase
   - What's unclear: Should autopilot retry the failed phase or exit?
   - Recommendation: Match plan-milestone-all behavior - retry with guidance option, or skip/abort

3. **Progress format integration**
   - What we know: CONTEXT.md specifies one-line format `[5/50] SUCCESS 03-02 Claude invocation (2m 34s)`
   - What's unclear: ralph.sh has its own display functions - modify ralph.sh or wrap output?
   - Recommendation: ralph.sh show_status already outputs similar format; may need minor adjustment

## Sources

### Primary (HIGH confidence)
- bin/ralph.sh - Complete outer loop implementation
- bin/lib/mode.sh - Mode infrastructure
- bin/lib/budget.sh - Budget prompting pattern
- bin/lib/state.sh - STATE.md manipulation
- bin/lib/parse.sh - Plan/phase enumeration
- bin/lib/exit.sh - Exit conditions and interrupt handling
- commands/gsd/plan-milestone-all.md - Existing planning orchestration
- commands/gsd/lazy-mode.md - Mode toggle command pattern

### Secondary (HIGH confidence - project documentation)
- .planning/phases/10-execution-commands/10-CONTEXT.md - User decisions
- .planning/REQUIREMENTS.md - CMD-02, CMD-03, CMD-04 requirements
- .planning/ROADMAP.md - Phase 10 success criteria

### Cross-referenced (HIGH confidence)
- commands/gsd/plan-phase.md - Mode gating pattern
- commands/gsd/execute-phase.md - Mode gating pattern
- commands/gsd/help.md - Current command documentation

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - all components exist and are documented in codebase
- Architecture: HIGH - patterns established in prior phases (especially Phase 9)
- Pitfalls: HIGH - based on actual implementation patterns observed

**Research date:** 2026-01-19
**Valid until:** Indefinite (internal project patterns, not external dependencies)
