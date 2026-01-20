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

<step name="detect_plans" placeholder="true">
**Step 2: Detect Existing Plans** (Plan 02)

<!-- TODO: Implement in 10-02-PLAN.md
- Check if .planning/phases/ has PLAN.md files
- If plans exist: prompt "Plans exist. Use existing or regenerate?"
- If no plans: proceed to planning phase
-->

Placeholder - will be implemented in Plan 02.
</step>

<step name="detect_resume" placeholder="true">
**Step 3: Detect Incomplete Runs** (Plan 02)

<!-- TODO: Implement in 10-02-PLAN.md
- Check STATE.md for incomplete progress
- If incomplete: prompt "Resume previous run?"
- Track where execution stopped
-->

Placeholder - will be implemented in Plan 02.
</step>

<step name="execute" placeholder="true">
**Step 4: Execute** (Plan 02)

<!-- TODO: Implement in 10-02-PLAN.md
- If no plans: run plan-milestone-all first
- Then run ralph.sh with configured settings
- Handle Ctrl+C gracefully
-->

Placeholder - will be implemented in Plan 02.
</step>

<step name="completion" placeholder="true">
**Step 5: Handle Completion/Interruption** (Plan 02)

<!-- TODO: Implement in 10-02-PLAN.md
- On completion: show final summary
- On interruption: show progress + resume command
- Exit with appropriate code
-->

Placeholder - will be implemented in Plan 02.
</step>

</process>


<success_criteria>
- [ ] Mode validated (lazy or unset, error on interactive)
- [ ] All 4 settings prompted and saved to .ralph-config
- [ ] Ready for Plan 02 to add detection and execution logic
</success_criteria>
