---
phase: 07-learnings-propagation
plan: 02
subsystem: infra
tags: [learnings, agents-md, shell, claude-prompt, integration]

# Dependency graph
requires:
  - phase: 07-01
    provides: learnings.sh library with AGENTS.md management functions
provides:
  - Learning injection into Claude prompt via invoke.sh
  - Learning extraction after successful iteration in ralph.sh
  - Full integration of learnings loop in outer loop
affects: [08-dynamic-escalation]

# Tech tracking
tech-stack:
  added: []
  patterns: [optional-dependency-pattern, safe-type-check]

key-files:
  created: []
  modified:
    - bin/ralph.sh
    - bin/lib/invoke.sh

key-decisions:
  - "Safe optional dependency using type check (type func &>/dev/null)"
  - "Learnings injected under '## Project Learnings' header in Claude prompt"
  - "Learning extraction happens before checkpoint commit (included in commit)"
  - "Use find command to locate SUMMARY.md by task_id pattern"

patterns-established:
  - "Optional dependency pattern: type check before calling functions from optional libs"
  - "Learning injection happens during prompt building in invoke_claude"
  - "Learning extraction runs on success path before checkpoint commit"

# Metrics
duration: 4min
completed: 2026-01-19
---

# Phase 7 Plan 02: Learning Integration Summary

**Wire learnings.sh into ralph loop: inject learnings into Claude prompt, extract from SUMMARY.md after success**

## Performance

- **Duration:** 4 min
- **Started:** 2026-01-19
- **Completed:** 2026-01-19
- **Tasks:** 3/3
- **Files modified:** 2

## Accomplishments
- Added learnings.sh to ralph.sh source block after recovery.sh
- Modified invoke_claude() to inject phase-relevant learnings into Claude prompt
- Added learning extraction after successful iteration in success handler
- Used safe optional dependency pattern (type check) for graceful degradation
- Learnings extraction happens before checkpoint, so new learnings are included in commit

## Task Commits

Each task was committed atomically:

1. **Task 1: Source learnings.sh in ralph.sh** - `5cc358b` (feat)
2. **Task 2: Inject learnings into Claude prompt** - `0c1eaa1` (feat)
3. **Task 3: Extract learnings after successful iteration** - `75dfce4` (feat)

## Files Modified
- `bin/ralph.sh` - Added learnings.sh source, added extraction in success handler
- `bin/lib/invoke.sh` - Added learning injection into Claude prompt

## Decisions Made
- Safe optional dependency: Use `type func &>/dev/null` before calling optional functions
- Learnings header: Added under `## Project Learnings (apply when relevant)` in prompt
- Extraction timing: Before checkpoint commit so learnings are included in checkpoint
- File discovery: Use find command with task_id pattern to locate SUMMARY.md

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - integration uses existing functions from learnings.sh.

## Next Phase Readiness
- Phase 7 complete: learnings loop fully integrated
- Ready for Phase 8: Dynamic Escalation
- Learnings will now propagate between Claude instances

---
*Phase: 07-learnings-propagation*
*Completed: 2026-01-19*
