# Phase 1: Safety Foundation - Research

**Researched:** 2026-01-19
**Domain:** Budget configuration, fail-fast error handling, bash scripting patterns
**Confidence:** HIGH

## Summary

Phase 1 implements the safety infrastructure that prevents runaway token burn during autonomous execution. The research covers six key areas: runtime budget prompting, persistence of last-used values, retry logic patterns, Claude Code CLI success/failure detection, git rollback to clean checkpoints, and terminal progress display.

The implementation approach is straightforward bash scripting using proven patterns:
- **Budget prompting:** Use `read -e -i DEFAULT` for editable defaults that accept Enter
- **Persistence:** Store last-used values in a simple text file (`~/.gsd-ralph-config` or `.planning/.ralph-config`)
- **Retry logic:** Counter-based retry with max attempts, exit on 3 consecutive failures
- **Failure detection:** Check Claude Code CLI exit code (`$?`) - `0` means success, non-zero means failure
- **Rollback:** Use `git reset --hard` to last clean checkpoint commit
- **Progress display:** ANSI escape codes for colors, format string with iteration count and elapsed time

**Primary recommendation:** Keep it simple. Use bash's native `read` command for prompts, a plain text file for persistence, exit code checking for failure detection, and git for rollback. Avoid over-engineering with JSON configs or complex retry strategies.

## Standard Stack

The established patterns for this phase:

### Core

| Tool | Version | Purpose | Why Standard |
|------|---------|---------|--------------|
| Bash | 4.0+ | Script runtime | Cross-platform via Git Bash on Windows, zero dependencies |
| `read` builtin | N/A | User input prompting | Native bash, no external dependencies |
| File I/O | N/A | Persist last-used values | Simple, reliable, survives reboots |
| Claude Code CLI | Current | Headless invocation | Official tool, JSON output for parsing |
| Git | 2.0+ | Checkpoint/rollback | Already required by GSD |

### Supporting

| Tool | Purpose | When to Use |
|------|---------|-------------|
| `jq` | JSON parsing | Parse Claude CLI JSON output (optional, can use grep fallback) |
| ANSI escape codes | Terminal colors | Progress display formatting |
| `date` | Time tracking | Elapsed time calculation |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Plain text config | JSON config file | JSON adds parsing complexity, overkill for 2 values |
| `read -e -i` | Dialog/whiptail | External dependency, not needed for simple prompts |
| Exit code checking | JSON response parsing | Exit codes are simpler; JSON only for detailed error info |

**Installation:**
No new dependencies required. Uses bash builtins and existing git/claude-cli tools.

## Architecture Patterns

### Recommended Project Structure

The safety foundation adds these files to the existing GSD structure:

```
.planning/
  .ralph-config          # Persisted last-used values (local to project)
  STATE.md               # Extended with ralph fields (Phase 2)

~/.gsd-ralph-defaults    # User-level defaults (optional, cross-project)

bin/
  ralph.sh               # Outer loop script (Phase 3, but config read here)
```

### Pattern 1: Budget Prompting with Editable Defaults

**What:** Prompt user for budget values at `/run-milestone` invocation, showing last-used values as editable defaults.

**When to use:** Every time the outer loop starts.

**Example:**
```bash
# Source: bash `read` builtin documentation
# https://www.gnu.org/software/bash/manual/bash.html

# Load last-used values or defaults
CONFIG_FILE=".planning/.ralph-config"
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
else
    MAX_ITERATIONS=50
    TIMEOUT_HOURS=8
fi

# Prompt with editable defaults (user can edit in-place or press Enter)
read -e -p "Max iterations [default: $MAX_ITERATIONS]: " -i "$MAX_ITERATIONS" input_iterations
MAX_ITERATIONS="${input_iterations:-$MAX_ITERATIONS}"

read -e -p "Timeout (hours) [default: $TIMEOUT_HOURS]: " -i "$TIMEOUT_HOURS" input_timeout
TIMEOUT_HOURS="${input_timeout:-$TIMEOUT_HOURS}"

# Save for next run
echo "MAX_ITERATIONS=$MAX_ITERATIONS" > "$CONFIG_FILE"
echo "TIMEOUT_HOURS=$TIMEOUT_HOURS" >> "$CONFIG_FILE"
```

### Pattern 2: File-Based Persistence

**What:** Store configuration values in a plain text file using bash variable assignment format.

**When to use:** After user confirms budget values.

**Example:**
```bash
# Source: linuxvox.com persistent variables guide
# https://linuxvox.com/blog/variable-in-bash-script-that-keeps-it-value-from-the-last-time-running/

CONFIG_FILE=".planning/.ralph-config"

# Read (with defaults)
load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        # Source the file to load variables
        source "$CONFIG_FILE"
    fi
    # Apply defaults for any missing values
    MAX_ITERATIONS="${MAX_ITERATIONS:-50}"
    TIMEOUT_HOURS="${TIMEOUT_HOURS:-8}"
}

# Write
save_config() {
    cat > "$CONFIG_FILE" << EOF
MAX_ITERATIONS=$MAX_ITERATIONS
TIMEOUT_HOURS=$TIMEOUT_HOURS
LAST_RUN=$(date -Iseconds)
EOF
}
```

### Pattern 3: Retry with Hard Cap (Fail After 3)

**What:** Retry failed operations up to 3 times, then stop entirely (don't try next task).

**When to use:** After each Claude CLI invocation.

**Example:**
```bash
# Source: GitHub Gist bash retry function
# https://gist.github.com/sj26/88e1c6584397bb7c13bd11108a579746

MAX_RETRIES=3
CONSECUTIVE_FAILURES=0

run_iteration() {
    local task="$1"
    local attempt=1

    while [ $attempt -le $MAX_RETRIES ]; do
        echo "Attempt $attempt/$MAX_RETRIES for task: $task"

        # Run Claude CLI
        claude -p "$PROMPT" --output-format json > result.json 2>&1
        local exit_code=$?

        if [ $exit_code -eq 0 ]; then
            echo "Success"
            CONSECUTIVE_FAILURES=0
            return 0
        fi

        echo "Failed with exit code $exit_code"
        attempt=$((attempt + 1))

        if [ $attempt -le $MAX_RETRIES ]; then
            echo "Retrying in 5 seconds..."
            sleep 5
        fi
    done

    # All retries exhausted
    echo "Task failed after $MAX_RETRIES attempts"
    return 1
}

# In main loop
if ! run_iteration "$current_task"; then
    echo "STOPPING: Task failed after $MAX_RETRIES retries"
    rollback_to_checkpoint
    exit 1
fi
```

### Pattern 4: Exit Code-Based Failure Detection

**What:** Check Claude CLI exit code to determine success or failure.

**When to use:** After every `claude -p` invocation.

**Example:**
```bash
# Source: Claude Code CLI documentation
# https://code.claude.com/docs/en/headless

# Run Claude and capture exit code
claude -p "$PROMPT" \
    --output-format json \
    --max-turns 10 \
    --allowedTools "Read,Write,Edit,Bash,Grep,Glob" \
    > "$OUTPUT_FILE" 2>&1

EXIT_CODE=$?

# Check result
if [ $EXIT_CODE -eq 0 ]; then
    echo "Claude completed successfully"
    # Parse JSON for details if needed
    if command -v jq &> /dev/null; then
        RESULT=$(jq -r '.result' "$OUTPUT_FILE")
    fi
else
    echo "Claude failed with exit code: $EXIT_CODE"
    # Non-zero means error - treat as failure
fi
```

### Pattern 5: Git Rollback to Checkpoint

**What:** When limits hit or fatal error, reset to last clean checkpoint commit, discarding partial work.

**When to use:** When stopping execution due to failure or budget exhaustion.

**Example:**
```bash
# Source: Git documentation and best practices
# https://git-scm.com/docs/git-reset

# Track checkpoint commits
CHECKPOINT_COMMIT=""

mark_checkpoint() {
    CHECKPOINT_COMMIT=$(git rev-parse HEAD)
    echo "Checkpoint: $CHECKPOINT_COMMIT"
}

rollback_to_checkpoint() {
    if [ -n "$CHECKPOINT_COMMIT" ]; then
        echo "Rolling back to checkpoint: $CHECKPOINT_COMMIT"
        git reset --hard "$CHECKPOINT_COMMIT"
        echo "Rollback complete. Partial work discarded."
    else
        echo "No checkpoint set, cannot rollback"
    fi
}

# Usage in main loop
mark_checkpoint  # At start of each iteration

# ... do work ...

if [ $SHOULD_STOP -eq 1 ]; then
    rollback_to_checkpoint
    exit 1
fi

# On success, the new commit becomes the checkpoint
mark_checkpoint
```

### Pattern 6: Terminal Progress Display

**What:** Show formatted progress output with iteration count, elapsed time, and remaining budget.

**When to use:** At the start and end of each iteration.

**Example:**
```bash
# Source: FLOZz bash colors guide
# https://misc.flogisoft.com/bash/tip_colors_and_formatting

# Color codes
RED='\e[31m'
GREEN='\e[32m'
YELLOW='\e[33m'
CYAN='\e[36m'
BOLD='\e[1m'
RESET='\e[0m'

# Track timing
START_TIME=$(date +%s)

format_duration() {
    local seconds=$1
    local hours=$((seconds / 3600))
    local minutes=$(((seconds % 3600) / 60))
    printf "%dh%02dm" $hours $minutes
}

show_progress() {
    local iteration=$1
    local max_iterations=$2
    local current_task=$3
    local next_task=$4

    local now=$(date +%s)
    local elapsed=$((now - START_TIME))
    local elapsed_fmt=$(format_duration $elapsed)

    # Calculate remaining (based on timeout, not iterations)
    local timeout_seconds=$((TIMEOUT_HOURS * 3600))
    local remaining=$((timeout_seconds - elapsed))
    local remaining_fmt=$(format_duration $remaining)

    echo -e "${BOLD}${CYAN}Iteration $iteration/$max_iterations${RESET} | ${elapsed_fmt} elapsed | ${remaining_fmt} remaining"
    echo -e "  ${GREEN}Completed:${RESET} $current_task"
    if [ -n "$next_task" ]; then
        echo -e "  ${YELLOW}Starting:${RESET} $next_task"
    fi
    echo ""
}

# Usage
show_progress 5 50 "01-01: Budget configuration" "01-02: Error handling"
```

### Anti-Patterns to Avoid

- **Over-engineering the config:** Don't use JSON or YAML for 2 values. Plain text with `source` is simpler.
- **Complex retry strategies:** User specified "retry 3 times then stop." Don't add exponential backoff or jitter.
- **Parsing Claude output for success:** Use exit codes. Only parse JSON for detailed error messages.
- **Soft limits:** User specified "hard" caps. Don't add warnings before stopping.

## Don't Hand-Roll

Problems that look simple but have existing solutions:

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| User input with defaults | Custom input parsing | `read -e -i` | Native bash, handles editing and Enter |
| Config persistence | JSON parser, file format | Bash `source` with var assignments | Zero dependencies, native sourcing |
| Time formatting | Complex printf | `date +%s` and arithmetic | Reliable, standard |
| Exit code checking | JSON parsing for status | `$?` variable | Claude CLI uses standard conventions |
| Colored output | External library | ANSI escape codes | Universal terminal support |

**Key insight:** Bash provides all the primitives needed. External dependencies (jq, JSON configs) add complexity without benefit for this phase's scope.

## Common Pitfalls

### Pitfall 1: Not Validating User Input

**What goes wrong:** User enters non-numeric value for iterations, script breaks.
**Why it happens:** `read` accepts any string, arithmetic fails on non-numbers.
**How to avoid:** Validate input is numeric before using.
**Warning signs:** Script errors like "integer expression expected."

```bash
# Validation pattern
if ! [[ "$MAX_ITERATIONS" =~ ^[0-9]+$ ]]; then
    echo "Error: Max iterations must be a number"
    exit 1
fi
```

### Pitfall 2: Forgetting to Save Config

**What goes wrong:** User configures budget, but values don't persist to next run.
**Why it happens:** Save logic in wrong place or missing.
**How to avoid:** Save immediately after prompts, before any execution starts.
**Warning signs:** "Why am I being asked again?"

### Pitfall 3: Git Dirty State on Rollback

**What goes wrong:** Rollback fails because working directory has uncommitted changes.
**Why it happens:** `git reset --hard` requires clean state or will discard local changes.
**How to avoid:** This is actually desired behavior per requirements ("discard partial work"). Document it.
**Warning signs:** None - this is the intended behavior.

### Pitfall 4: Timeout Never Checked

**What goes wrong:** Loop runs forever because only iteration count is checked.
**Why it happens:** Timeout logic forgotten in main loop.
**How to avoid:** Check both iteration AND timeout at start of each iteration.
**Warning signs:** Script running longer than timeout hours.

```bash
# Check both limits
check_limits() {
    local now=$(date +%s)
    local elapsed=$((now - START_TIME))
    local timeout_seconds=$((TIMEOUT_HOURS * 3600))

    if [ $CURRENT_ITERATION -ge $MAX_ITERATIONS ]; then
        echo "Iteration limit reached"
        return 1
    fi

    if [ $elapsed -ge $timeout_seconds ]; then
        echo "Timeout reached"
        return 1
    fi

    return 0
}
```

### Pitfall 5: Windows Line Endings

**What goes wrong:** Script fails on Windows with weird errors.
**Why it happens:** Config file saved with CRLF, bash expects LF.
**How to avoid:** Use `printf` or ensure editor uses LF. Git can help with `.gitattributes`.
**Warning signs:** "command not found" errors, `$'\r'` in error messages.

## Code Examples

Verified patterns from official sources:

### Complete Budget Prompt Flow

```bash
# Source: Combined from bash docs and linuxvox persistence guide

#!/bin/bash

# Configuration
CONFIG_FILE=".planning/.ralph-config"

# Color codes
RED='\e[31m'
GREEN='\e[32m'
YELLOW='\e[33m'
RESET='\e[0m'

# Load existing config or defaults
load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
    fi
    MAX_ITERATIONS="${MAX_ITERATIONS:-50}"
    TIMEOUT_HOURS="${TIMEOUT_HOURS:-8}"
}

# Validate numeric input
validate_number() {
    local value="$1"
    local name="$2"
    if ! [[ "$value" =~ ^[0-9]+$ ]]; then
        echo -e "${RED}Error: $name must be a positive integer${RESET}"
        return 1
    fi
    if [ "$value" -lt 1 ]; then
        echo -e "${RED}Error: $name must be at least 1${RESET}"
        return 1
    fi
    return 0
}

# Save config
save_config() {
    mkdir -p "$(dirname "$CONFIG_FILE")"
    cat > "$CONFIG_FILE" << EOF
# GSD Ralph configuration
# Last updated: $(date)
MAX_ITERATIONS=$MAX_ITERATIONS
TIMEOUT_HOURS=$TIMEOUT_HOURS
EOF
    echo -e "${GREEN}Configuration saved${RESET}"
}

# Main prompt flow
prompt_budget() {
    load_config

    echo -e "${YELLOW}=== Budget Configuration ===${RESET}"
    echo ""

    # Prompt for max iterations
    while true; do
        read -e -p "Max iterations [default: $MAX_ITERATIONS]: " -i "$MAX_ITERATIONS" input
        input="${input:-$MAX_ITERATIONS}"
        if validate_number "$input" "Max iterations"; then
            MAX_ITERATIONS="$input"
            break
        fi
    done

    # Prompt for timeout
    while true; do
        read -e -p "Timeout hours [default: $TIMEOUT_HOURS]: " -i "$TIMEOUT_HOURS" input
        input="${input:-$TIMEOUT_HOURS}"
        if validate_number "$input" "Timeout"; then
            TIMEOUT_HOURS="$input"
            break
        fi
    done

    echo ""
    echo -e "Running with: ${GREEN}$MAX_ITERATIONS iterations${RESET}, ${GREEN}${TIMEOUT_HOURS}h timeout${RESET}"

    save_config
}
```

### Fail-Fast Iteration with Retry

```bash
# Source: GitHub Gist retry function + Claude Code docs

MAX_RETRIES=3

run_with_retry() {
    local prompt="$1"
    local attempt=1

    while [ $attempt -le $MAX_RETRIES ]; do
        echo "  Attempt $attempt/$MAX_RETRIES"

        # Run Claude CLI with budget limits
        local output_file=$(mktemp)
        claude -p "$prompt" \
            --output-format json \
            --max-turns 20 \
            > "$output_file" 2>&1

        local exit_code=$?

        if [ $exit_code -eq 0 ]; then
            # Success - check for actual completion if needed
            rm -f "$output_file"
            return 0
        fi

        # Log failure
        echo "  Failed (exit code: $exit_code)"

        attempt=$((attempt + 1))
        if [ $attempt -le $MAX_RETRIES ]; then
            echo "  Retrying in 5 seconds..."
            sleep 5
        fi

        rm -f "$output_file"
    done

    # All retries failed
    return 1
}

# Usage in main loop
if ! run_with_retry "$TASK_PROMPT"; then
    echo "FATAL: Task failed after $MAX_RETRIES attempts"
    echo "Stopping execution, rolling back to last checkpoint"
    rollback_to_checkpoint
    exit 1
fi
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Interactive prompts during execution | Budget prompts at start only | User decision | Simpler UX, fire-and-forget compatible |
| Config files parsed at runtime | `source` bash variable files | Standard practice | Zero-dependency config |
| Complex retry with backoff | Fixed retry count, fail-stop | User decision | Simpler, prevents token burn |

**Deprecated/outdated:**
- Using `--dangerously-skip-permissions` without `--max-turns`: Risky, could run forever
- Complex JSON config parsing in bash: Unnecessary complexity

## Open Questions

Things that couldn't be fully resolved:

1. **Default values for iterations and timeout**
   - What we know: User wants sensible defaults
   - What's unclear: What values are "sensible" for this project
   - Recommendation: Start with 50 iterations, 8 hours. Adjust based on testing.

2. **jq availability on Windows**
   - What we know: Git Bash doesn't include jq by default
   - What's unclear: Whether to require jq or provide fallback
   - Recommendation: Use grep/sed fallback for critical JSON parsing, jq optional for verbose output

3. **Checkpoint granularity**
   - What we know: Rollback to "last clean checkpoint"
   - What's unclear: Is checkpoint per-iteration or per-task?
   - Recommendation: Checkpoint at start of each iteration (before Claude runs)

## Sources

### Primary (HIGH confidence)
- [Claude Code CLI - Headless Mode](https://code.claude.com/docs/en/headless) - Exit codes, JSON output, --max-turns
- [GNU Bash Manual](https://www.gnu.org/software/bash/manual/bash.html) - `read` builtin, variable expansion
- [Git Reset Documentation](https://git-scm.com/docs/git-reset) - Rollback patterns

### Secondary (MEDIUM confidence)
- [LinuxVox - Persistent Variables](https://linuxvox.com/blog/variable-in-bash-script-that-keeps-it-value-from-the-last-time-running/) - File-based config storage
- [GitHub Gist - Retry Function](https://gist.github.com/sj26/88e1c6584397bb7c13bd11108a579746) - Retry pattern
- [FLOZz Bash Colors](https://misc.flogisoft.com/bash/tip_colors_and_formatting) - ANSI escape codes
- [ClaudeLog - max-turns](https://claudelog.com/faqs/what-is-max-turns-in-claude-code/) - Turn planning guidance

### Tertiary (LOW confidence)
- [Medium - 12 Bash Retry Scripts](https://medium.com/@obaff/12-bash-scripts-to-implement-intelligent-retry-backoff-error-recovery-a02ab682baae) - Pattern catalog (needs validation)

## Metadata

**Confidence breakdown:**
- Budget prompting: HIGH - Standard bash `read` patterns, well-documented
- Persistence: HIGH - Simple file I/O, proven approach
- Retry logic: HIGH - User specified exact behavior (3 retries, then stop)
- Failure detection: HIGH - Exit codes are standard Claude CLI behavior
- Git rollback: HIGH - Standard git commands
- Progress display: MEDIUM - ANSI codes are universal, but Windows terminal support varies

**Research date:** 2026-01-19
**Valid until:** 60 days (stable patterns, unlikely to change)
