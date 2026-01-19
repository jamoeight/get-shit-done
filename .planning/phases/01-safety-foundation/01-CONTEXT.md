# Phase 1: Safety Foundation - Context

**Gathered:** 2026-01-19
**Status:** Ready for planning

<domain>
## Phase Boundary

Prevent runaway token burn with hard iteration caps and fail-fast error handling. This phase creates the safety infrastructure that the outer loop (ralph.sh) respects — budget prompts at runtime, retry logic on failure, and clean rollback when limits are hit.

</domain>

<decisions>
## Implementation Decisions

### Budget Configuration UX
- No config file — prompt user at `/run-milestone` invocation
- Two budget variables: max iterations + timeout (hours)
- Show sensible defaults, user presses Enter to accept or types new values
- Remember last-used values as defaults for future runs

### Failure Behavior
- Retry up to 3 times on failure before giving up
- After 3 failed retries on a task, stop entirely (don't try next task)
- When limits hit: rollback to last clean checkpoint, discard partial work
- What counts as "failure": Claude's discretion — keep it simple

### Progress Visibility
- Terminal output only (no log file)
- Summary per iteration: "Iteration 5/50: Completed task X, starting Y"
- Show elapsed time and remaining budget: "Iteration 5/50 | 2h15m elapsed | 5h45m remaining"
- No system notifications — user checks terminal when ready

### Claude's Discretion
- Exact failure detection mechanism (keep it simple)
- Default values for iterations and timeout
- Terminal output formatting details

</decisions>

<specifics>
## Specific Ideas

- "Stick to simplicity" — user emphasized avoiding over-engineering
- Budget prompts happen at runtime, not via config files
- Last-used values remembered for quick re-runs

</specifics>

<deferred>
## Deferred Ideas

- `resume-milestone` command — ability to resume from where execution stopped (limits hit, failure, etc.)

</deferred>

---

*Phase: 01-safety-foundation*
*Context gathered: 2026-01-19*
