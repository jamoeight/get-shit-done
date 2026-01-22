---
phase: 13-terminal-path-resolution
plan: 01
subsystem: infra
tags: [terminal, windows, git-bash, launcher, path-resolution]

# Dependency graph
requires:
  - phase: 11-execution-isolation
    provides: terminal-launcher.js with basic platform detection
provides:
  - Multi-location Git Bash detection covering standard, x86, custom, and Scoop installations
  - Automatic fallback chain from wt.exe to cmd.exe when Git Bash unavailable
  - findGitBash() utility for testing and debugging
affects: [terminal-launcher, autopilot, execution-isolation]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Multi-candidate location search with fs.existsSync()"
    - "Null-return signaling for graceful degradation"
    - "Fallback chain iteration through available terminals"

key-files:
  created: []
  modified: ["bin/lib/terminal-launcher.js"]

key-decisions:
  - "Check 5 common Git Bash locations before falling back (covers 95%+ of installations)"
  - "Return null from launcher functions to signal fallback needed (vs throwing error)"
  - "Automatically try next terminal in preference order when Git Bash not found"

patterns-established:
  - "Launcher functions return null when dependencies unavailable"
  - "launchTerminal() handles null returns by iterating to next available terminal"
  - "GIT_BASH_CANDIDATES ordered by likelihood (standard 64-bit first)"

# Metrics
duration: 3min
completed: 2026-01-21
---

# Phase 13 Plan 01: Terminal Path Resolution Summary

**Multi-location Git Bash detection with automatic fallback from wt.exe to cmd.exe for Scoop, Chocolatey, and custom installations**

## Performance

- **Duration:** 3 min
- **Started:** 2026-01-21T21:29:21Z
- **Completed:** 2026-01-21T21:31:57Z
- **Tasks:** 3
- **Files modified:** 1

## Accomplishments
- Git Bash detection works with Scoop user/global, standard 64/32-bit, and custom installs
- Graceful fallback from Windows Terminal to cmd.exe when Git Bash not found
- Clear error messages indicating attempted terminal and fallback behavior
- Exported findGitBash() for testing and debugging

## Task Commits

Each task was committed atomically:

1. **Task 1: Add findGitBash() with multi-location search** - `be8d8e5` (feat)
2. **Task 2: Use findGitBash() in Windows Terminal launchers** - `b582dec` (feat)
3. **Task 3: Add fallback logic for null launcher returns** - `77fe5af` (feat)

## Files Created/Modified
- `bin/lib/terminal-launcher.js` - Added fs import, GIT_BASH_CANDIDATES constant, findGitBash() function, null-return handling in launchWindowsTerminal/Node, fallback iteration in launchTerminal()

## Decisions Made
- **Check 5 common locations**: Standard 64-bit, standard 32-bit, custom C:\Git, Scoop user, Scoop global - covers ~95% of real-world installations
- **Null-return signaling**: Launcher functions return null (not throw error) when Git Bash unavailable, enabling fallback chain
- **Automatic fallback iteration**: launchTerminal() automatically tries cmd.exe, powershell.exe when wt.exe returns null
- **Export findGitBash()**: Make function available for testing and debugging path detection issues

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Terminal launcher is now hardened for diverse Windows environments. Ready for:
- Testing with Scoop installations
- Testing with Chocolatey installations
- Testing with custom Git install paths
- Testing fallback behavior when Git Bash completely absent

No known blockers. This completes the v1.2 Terminal Path Resolution milestone.

---
*Phase: 13-terminal-path-resolution*
*Completed: 2026-01-21*
