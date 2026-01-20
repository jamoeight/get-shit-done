---
name: gsd:autopilot
description: Plan and execute milestone autonomously
allowed-tools:
  - Read
  - Write
  - Bash
  - Glob
  - Grep
  - Task
---

<objective>
Single unified command for autonomous milestone execution in Lazy mode.

**UX Philosophy:** Self-driving car metaphor - confirm settings, press go, walk away.

This command:
1. Validates mode (must be Lazy or unset)
2. Prompts for all safety settings (no --yes flag, user must confirm)
3. Detects existing plans vs need to plan (Plan 02)
4. Detects incomplete runs for resume (Plan 02)
5. Executes planning then ralph.sh autonomously (Plan 02)
</objective>


<context>
@bin/lib/budget.sh
@bin/lib/mode.sh
@bin/lib/parse.sh
@bin/ralph.sh
@commands/gsd/plan-milestone-all.md
</context>


<process>

<step name="validate_mode">
**Step 0: Validate Mode**

Check that the user is in Lazy mode (or unset).

```bash
# Check for existing config
if [ -f ".planning/.ralph-config" ]; then
    source .planning/.ralph-config 2>/dev/null
fi
CURRENT_MODE="${GSD_MODE:-}"
```

**If CURRENT_MODE is "interactive":**
Show error and suggest alternative:

```
Error: /gsd:autopilot is only available in Lazy mode.

Current mode: interactive

In Interactive mode, use:
  /gsd:execute-phase  - Execute one phase at a time with supervision

Run /gsd:lazy-mode to switch to Lazy mode if you want autonomous execution.
```

**If CURRENT_MODE is "lazy" or empty:** Continue to next step.

The empty case is allowed (same pattern as plan-milestone-all) because the user may not have explicitly set a mode yet but intends to use autopilot.
</step>

<step name="prompt_settings">
**Step 1: Prompt for Settings**

ALWAYS prompt for all settings - no --yes flag or skip option.

Use prompt_all_settings pattern from budget.sh:

```bash
# Source budget library
source bin/lib/budget.sh

# Load existing config as defaults, then prompt for all 4 settings
prompt_all_settings
```

This prompts for:
- MAX_ITERATIONS (default: 50)
- TIMEOUT_HOURS (default: 8)
- CIRCUIT_BREAKER_THRESHOLD (default: 5)
- STUCK_THRESHOLD (default: 3)

Each value:
- Shows current/default value as editable default (read -e -i)
- Validates as positive integer
- Saves to .planning/.ralph-config after all confirmed

After prompts, show confirmation summary:

```
Settings configured:
  Max iterations:      50
  Timeout hours:       8
  Circuit breaker:     5 failures before halt
  Stuck threshold:     3 retries on same task

Configuration saved to .planning/.ralph-config
```

User must consciously confirm settings before autonomous run begins.
</step>

<step name="detect_plans">
**Step 2: Detect Existing Plans**

Check if plans exist for all phases.

```bash
# Count phases in ROADMAP.md
TOTAL_PHASES=$(grep -cE "^### Phase [0-9]" .planning/ROADMAP.md || echo 0)

# Count phases with PLAN.md files
PHASES_WITH_PLANS=$(find .planning/phases -name "*-*-PLAN.md" -type f 2>/dev/null | sed 's|.*phases/||;s|/.*||' | sort -u | wc -l | tr -d ' ')

if [[ "$PHASES_WITH_PLANS" -lt "$TOTAL_PHASES" ]]; then
    PLANS_NEEDED=true
    echo "Plans needed: $((TOTAL_PHASES - PHASES_WITH_PLANS)) phase(s) without plans"
fi
```

**If plans exist for all phases:**

Prompt the user:
```
Plans exist for all phases.
Use existing plans or regenerate? [use/regenerate]
```

- If user selects "use": Skip planning, proceed to Step 3
- If user selects "regenerate": Proceed to Step 2b (planning)

**If plans are missing:**

Display message and proceed to planning:
```
Planning needed for {count} phase(s)
Proceeding to generate plans...
```
</step>

<step name="execute_planning">
**Step 2b: Execute Planning (if needed)**

When planning is required (missing plans or user chose regenerate), spawn the planning orchestrator.

Use Task tool to spawn plan-milestone-all:
```
Task(
  prompt="Run /gsd:plan-milestone-all with --skip-research flag",
  subagent_type="orchestrator",
  description="Generate all phase plans"
)
```

Wait for planning completion before proceeding.

**If planning fails:**
```
==========================================
 PLANNING FAILED
==========================================

Error: Could not generate phase plans.

Check .planning/ for partial output.
Review error above and retry with /gsd:autopilot
==========================================
```

Exit without proceeding to execution.

**If planning succeeds:**
```
Planning complete. Proceeding to execution...
```

Continue to Step 3.
</step>

<step name="detect_resume">
**Step 3: Detect Incomplete Runs**

Check STATE.md for prior incomplete execution.

```bash
# Check for iteration history with incomplete status
if [[ -f ".planning/STATE.md" ]]; then
    # Extract next action - if it's a plan ID (NN-MM), run is incomplete
    NEXT_TASK=$(grep "^Description:" .planning/STATE.md | head -1 | grep -oE '[0-9]{2}-[0-9]{2}' || echo "")

    if [[ -n "$NEXT_TASK" ]]; then
        INCOMPLETE_RUN=true
        echo "Incomplete run detected. Last position: $NEXT_TASK"
    fi
fi
```

**If incomplete run detected:**

Prompt the user:
```
==========================================
 INCOMPLETE RUN DETECTED
==========================================

Previous execution stopped at: {NEXT_TASK}

Resume from this position or restart from the beginning?
[resume/restart]
```

- If user selects "resume": Proceed with existing STATE.md position
- If user selects "restart": Reset STATE.md position to first plan (01-01)

**If no incomplete run:**

Continue to Step 4 (fresh execution).
</step>

<step name="execute">
**Step 4: Start Execution**

Display launch confirmation with settings summary:

```
==========================================
 GSD AUTOPILOT - READY TO LAUNCH
==========================================

Mode: Lazy (autonomous)
Plans: {count} across {phases} phases
Settings:
  - Max iterations: {MAX_ITERATIONS}
  - Timeout: {TIMEOUT_HOURS}h
  - Circuit breaker: {CIRCUIT_BREAKER_THRESHOLD} failures
  - Stuck threshold: {STUCK_THRESHOLD} retries

Starting autonomous execution...
Press Ctrl+C at any time for graceful stop.
==========================================
```

Execute ralph.sh via Bash tool:

```bash
./bin/ralph.sh 2>&1
```

Capture the exit status for Step 5 handling.

**Exit codes from ralph.sh:**
- 0 = COMPLETED (all plans done, tests pass)
- 1 = STUCK (same task failed STUCK_THRESHOLD times)
- 2 = ABORTED (user chose to abort or budget cap reached)
- 3 = INTERRUPTED (user pressed Ctrl+C, graceful stop)
</step>

<step name="completion">
**Step 5: Handle Completion**

Parse the exit status from ralph.sh and display appropriate completion message.

**Exit 0 - COMPLETED:**
```
==========================================
 GSD AUTOPILOT - COMPLETE
==========================================

All plans executed successfully!

Next steps:
- Review work in .planning/phases/
- Run /gsd:progress for summary
- Run /gsd:complete-milestone when ready
==========================================
```

**Exit 1 - STUCK:**
```
==========================================
 GSD AUTOPILOT - STUCK
==========================================

Execution stuck at: {task}
Reason: Same task failed {STUCK_THRESHOLD} times

Options:
- Resume: /gsd:autopilot (will offer to resume)
- Debug:  Review .planning/ralph.log for failure details
- Skip:   Manually mark task complete in STATE.md, then resume
==========================================
```

**Exit 2 - ABORTED:**
```
==========================================
 GSD AUTOPILOT - ABORTED
==========================================

Execution aborted.
Position saved: {task}

All progress up to this point has been committed.

Resume: /gsd:autopilot
==========================================
```

**Exit 3 - INTERRUPTED:**
```
==========================================
 GSD AUTOPILOT - INTERRUPTED
==========================================

Graceful stop completed.
All progress committed.

Position: {task}
Completed: {N} iterations

To continue from where you left off:
  /gsd:autopilot

The command will detect the incomplete run and offer to resume.
==========================================
```

Return the exit status code so the calling context (Claude) can reference it.
</step>

</process>


<success_criteria>
- [ ] Mode validated (lazy or unset, error on interactive)
- [ ] All 4 settings prompted and saved to .ralph-config
- [ ] Plan detection checks all phases have plans
- [ ] Planning triggered via plan-milestone-all when plans missing
- [ ] Resume detection checks STATE.md for incomplete runs
- [ ] Execution via ralph.sh with all exit status handling
- [ ] Clear completion/failure/interrupt messages with next steps
</success_criteria>
