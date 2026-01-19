---
phase: 06-circuit-breaker-recovery
plan: 02
subsystem: infra
tags: [stuck-analysis, recovery, pattern-detection, bash, shell]

# Dependency graph
requires:
  - phase: 06-circuit-breaker-recovery
    provides: circuit breaker pattern with Resume/Skip/Abort menu
provides:
  - Stuck analysis examining STATE.md failure history
  - Pattern detection for common errors, files, and phases
  - Alternative approach hints based on failure patterns
affects: [07-learnings-propagation]

# Tech tracking
tech-stack:
  added: []
  patterns: [failure-pattern-analysis]

key-files:
  created:
    - bin/lib/recovery.sh
  modified:
    - bin/lib/exit.sh
    - bin/ralph.sh

key-decisions:
  - "ANALYSIS_WINDOW=5 matches CIRCUIT_BREAKER_THRESHOLD for consistent window"
  - "Three pattern types analyzed: error keywords, file references, task prefixes"
  - "Analysis is conditional - uses type check for safe optional dependency"
  - "Alternative actions are pattern-aware, providing context-specific suggestions"

patterns-established:
  - "Stuck analysis: examine failure history, identify patterns, suggest alternatives"
  - "Safe optional dependency: use type check before calling external functions"

# Metrics
duration: 4min
completed: 2026-01-19
---

# Phase 6 Plan 02: Stuck Analysis and Alternative Approaches Summary

**Failure pattern analysis that examines STATE.md history for common errors, files, and phases, providing context-aware alternative action suggestions**

## Performance

- **Duration:** 4 min
- **Started:** 2026-01-19
- **Completed:** 2026-01-19
- **Tasks:** 3
- **Files modified:** 3

## Accomplishments
- Created recovery.sh library with stuck analysis functions
- Integrated analysis into circuit breaker pause screen (shown before menu)
- Pattern detection identifies common errors, affected files, and failing phases
- Context-aware alternative action hints help users decide Resume/Skip/Abort

## Task Commits

Each task was committed atomically:

1. **Task 1: Create recovery.sh library with stuck analysis** - `43e55cb` (feat)
2. **Task 2: Integrate analysis into circuit breaker pause** - `c553653` (feat)
3. **Task 3: Add alternative approach hint to analysis** - `218620d` (feat)

## Files Created/Modified
- `bin/lib/recovery.sh` - New library with get_recent_failures, parse_failure_patterns, generate_stuck_analysis functions
- `bin/lib/exit.sh` - Added generate_stuck_analysis call in handle_circuit_breaker_pause
- `bin/ralph.sh` - Sources recovery.sh library after exit.sh

## Decisions Made
- ANALYSIS_WINDOW=5: Matches CIRCUIT_BREAKER_THRESHOLD for consistent failure window analysis
- Three pattern types: Error keywords (grep for error/failed/cannot), file references (common extensions), task prefixes (same phase failing)
- Safe optional dependency: Uses `type generate_stuck_analysis &>/dev/null` check so exit.sh works even if recovery.sh not sourced
- Alternative actions vary by pattern: file pattern suggests git diff, error pattern suggests grep search, phase pattern suggests checking prerequisites

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Phase 6 Circuit Breaker & Recovery fully complete
- Circuit breaker pattern with stuck analysis integrated
- Ready for Phase 7 Learnings Propagation

---
*Phase: 06-circuit-breaker-recovery*
*Completed: 2026-01-19*
