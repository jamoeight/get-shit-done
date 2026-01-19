# Phase 5: Exit Conditions - Context

**Gathered:** 2026-01-19
**Status:** Ready for planning

<domain>
## Phase Boundary

Determine when autonomous execution should stop. Implement test-based completion detection, stuck detection, and dual-exit gate. Exit reason must be clearly logged for user review.

</domain>

<decisions>
## Implementation Decisions

### Stuck Detection
- Track consecutive failures on the SAME task only (different tasks failing doesn't trigger stuck)
- Hard exit with STUCK status when threshold reached — no retry, no skip, no pause
- User must review before any more iterations run

### Completion Signals
- Detect "all tests pass" by parsing test output for pass/fail count (not just exit code)
- Detect "all requirements complete" by checking BOTH:
  - ROADMAP.md checkboxes: all plan checkboxes [x] for the milestone
  - STATE.md position: no more tasks remaining
- Both signals must agree for completion
- If tests pass but requirements aren't checked off: continue iterating (work isn't done)

### Exit Logging
- Log exit reason to STATE.md AND terminal output
- Medium verbosity: reason + last task + stats (iteration count, duration, success rate)
- Three exit statuses:
  - COMPLETED: success — all tests pass AND all requirements done
  - STUCK: same task failed consecutively
  - ABORTED: iteration cap reached or user interrupt

### Graceful Exit
- Ctrl+C: finish current iteration, commit checkpoint, then exit cleanly
- No separate stop-file mechanism — Ctrl+C once is the graceful stop signal
- Distinct exit codes per reason:
  - 0 = COMPLETED
  - 1 = STUCK
  - 2 = ABORTED (cap reached)
  - 3 = INTERRUPTED (user Ctrl+C)

### Claude's Discretion
- Stuck detection threshold (3 vs 5 consecutive failures)
- Whether to track specific failure reasons for stuck diagnosis
- Whether to run a verification iteration after completion detected
- Whether exit logging includes next-steps guidance
- Whether final checkpoint commit includes exit status in message

</decisions>

<specifics>
## Specific Ideas

- Dual-exit gate concept: require BOTH completion markers AND explicit exit signal before stopping
- Exit codes should follow Unix conventions (0 = success, non-zero = various failure modes)
- Stats should help user understand what happened without being overwhelming

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 05-exit-conditions*
*Context gathered: 2026-01-19*
