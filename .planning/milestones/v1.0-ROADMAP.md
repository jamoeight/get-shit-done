# Roadmap: GSD Lazy Mode

## Overview

GSD Lazy Mode transforms the existing interactive GSD workflow into a "fire and forget" system where users plan everything upfront, then walk away while agents execute autonomously until the milestone is complete. This roadmap starts with safety infrastructure (budget controls, fail-fast handling) to prevent runaway token burn, then builds the outer loop machinery, exit conditions, and planning commands. The final phases wire everything together into user-facing commands that enable autonomous overnight execution.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [x] **Phase 1: Safety Foundation** - Hard iteration caps and fail-fast error handling to prevent runaway costs
- [x] **Phase 2: State Extensions** - Extended STATE.md with iteration tracking and progress indicators
- [x] **Phase 3: Outer Loop Core** - Bash script that spawns fresh Claude instances with retry logic
- [x] **Phase 4: Git Checkpointing** - Atomic commits as iteration boundaries for progress persistence
- [x] **Phase 5: Exit Conditions** - Test-based completion, stuck detection, and dual-exit gate
- [x] **Phase 6: Circuit Breaker & Recovery** - Pause after consecutive failures, analyze stuck state
- [x] **Phase 7: Learnings Propagation** - Write discovered patterns to AGENTS.md across iterations
- [x] **Phase 8: Upfront Planning** - Generate all PLAN.md files before autonomous execution begins
- [x] **Phase 9: Mode Selection & Base Commands** - Interactive vs Lazy mode selection at startup
- [x] **Phase 10: Execution Commands** - Unified autopilot command for autonomous milestone execution

## Phase Details

### Phase 1: Safety Foundation
**Goal**: Prevent runaway token burn with hard limits and immediate error surfacing
**Depends on**: Nothing (first phase)
**Requirements**: SAFE-01, SAFE-02
**Success Criteria** (what must be TRUE):
  1. User can configure a maximum iteration limit before starting autonomous execution
  2. Errors surface immediately to the outer loop instead of continuing silently
  3. .planning/.ralph-config stores budget configuration that the outer loop respects
  4. Outer loop aborts when iteration cap is reached, preserving progress made so far
**Plans**: 2 plans

Plans:
- [x] 01-01-PLAN.md — Budget configuration infrastructure (prompting, persistence, display)
- [x] 01-02-PLAN.md — Fail-fast error handling patterns (retry, checkpoint, rollback)

### Phase 2: State Extensions
**Goal**: Track iteration state and show progress across autonomous execution
**Depends on**: Phase 1
**Requirements**: STATE-01, STATE-03
**Success Criteria** (what must be TRUE):
  1. STATE.md includes iteration count, current phase, and outcome history
  2. Progress indicator updates after each iteration completes
  3. Fresh Claude instances can read STATE.md and know exactly where to resume
  4. Iteration history persists between sessions (survives crashes)
**Plans**: 2 plans

Plans:
- [x] 02-01-PLAN.md — STATE.md schema extensions and state.sh update library
- [x] 02-02-PLAN.md — Progress bar generation and history rolling/archiving

### Phase 3: Outer Loop Core
**Goal**: Execute a bash-based retry loop that spawns fresh Claude instances
**Depends on**: Phase 2
**Requirements**: LOOP-01, LOOP-02
**Success Criteria** (what must be TRUE):
  1. User can run ralph.sh and it iterates until completion or cap reached
  2. Each iteration spawns a fresh Claude Code instance with clean context
  3. Loop reads from STATE.md to determine next task
  4. Loop writes completion status back to STATE.md after each iteration
  5. Works on both Unix and Windows (via Git Bash)
**Plans**: 3 plans

Plans:
- [x] 03-01-PLAN.md — ralph.sh script skeleton with iteration control and STATE.md parsing
- [x] 03-02-PLAN.md — Claude CLI invocation with JSON output parsing and failure handling
- [x] 03-03-PLAN.md — Cross-platform compatibility (line endings, NO_COLOR support)

### Phase 4: Git Checkpointing
**Goal**: Use atomic git commits as progress checkpoints
**Depends on**: Phase 3
**Requirements**: STATE-02
**Success Criteria** (what must be TRUE):
  1. Each successful iteration creates an atomic git commit
  2. Commit message includes iteration number and task completed
  3. Progress can be reconstructed from git history if STATE.md is lost
  4. Partial work is not committed (only successful completions)
**Plans**: 2 plans

Plans:
- [x] 04-01-PLAN.md — Atomic commit integration (checkpoint.sh library, startup validation, commit after success)
- [x] 04-02-PLAN.md — History recovery (extract last task from git, validate STATE.md vs git history)

### Phase 5: Exit Conditions
**Goal**: Determine when autonomous execution should stop
**Depends on**: Phase 4
**Requirements**: EXIT-01, EXIT-02, EXIT-03
**Success Criteria** (what must be TRUE):
  1. Loop exits when all tests pass AND all requirements are marked complete
  2. Loop exits when same task fails 3+ times consecutively (stuck detection)
  3. Dual-exit gate requires BOTH completion markers AND explicit exit signal
  4. Exit reason is clearly logged in STATE.md for user review
**Plans**: 2 plans

Plans:
- [x] 05-01-PLAN.md — Exit conditions library with stuck detection, interrupt handling, exit status logging
- [x] 05-02-PLAN.md — Completion detection and dual-exit gate implementation

### Phase 6: Circuit Breaker & Recovery
**Goal**: Intelligently handle repeated failures without burning tokens
**Depends on**: Phase 5
**Requirements**: LOOP-03, LOOP-04
**Success Criteria** (what must be TRUE):
  1. Loop pauses (not exits) after N consecutive failures on different tasks
  2. Stuck detection analyzes WHY the loop is stuck before retrying
  3. Alternative approaches are tried before giving up on a task
  4. User can review failure analysis and resume or abort
**Plans**: 2 plans

Plans:
- [x] 06-01-PLAN.md — Circuit breaker pattern with cross-task failure tracking and pause menu
- [x] 06-02-PLAN.md — Stuck analysis and alternative approach suggestions

### Phase 7: Learnings Propagation
**Goal**: Share discovered patterns across iterations via AGENTS.md
**Depends on**: Phase 6
**Requirements**: STATE-04
**Success Criteria** (what must be TRUE):
  1. Patterns discovered during execution are written to AGENTS.md
  2. Future iterations read AGENTS.md and benefit from learned patterns
  3. Learnings accumulate without causing context bloat
  4. User can review and edit accumulated learnings
**Plans**: 2 plans

Plans:
- [x] 07-01-PLAN.md — Learning extraction library (learnings.sh with init, get, append, extract, prune)
- [x] 07-02-PLAN.md — AGENTS.md integration into invoke and ralph loop

### Phase 8: Upfront Planning
**Goal**: Generate all PLAN.md files for all phases before autonomous execution
**Depends on**: Phase 7
**Requirements**: PLAN-01, PLAN-02, PLAN-03, PLAN-04
**Success Criteria** (what must be TRUE):
  1. User can generate all PLAN.md files in one interactive session
  2. LLM determines optimal phase structure during planning
  3. Dependencies between phases are analyzed and documented
  4. User can interactively refine plans before committing to execution
  5. All plans exist before run-milestone is invoked
**Plans**: 2 plans

Plans:
- [x] 08-01-PLAN.md — Planning infrastructure (planning.sh library, state.sh/parse.sh extensions)
- [x] 08-02-PLAN.md — plan-milestone-all command with orchestration and refinement loop

### Phase 9: Mode Selection & Base Commands
**Goal**: Enable users to choose Interactive vs Lazy mode at startup
**Depends on**: Phase 8
**Requirements**: CMD-01, CMD-05
**Success Criteria** (what must be TRUE):
  1. User can select mode at GSD startup (Interactive vs Lazy)
  2. All existing GSD commands work in lazy mode (new-project, map-codebase, progress)
  3. Mode persists across sessions until changed
  4. Help text shows mode-appropriate commands
**Plans**: 2 plans

Plans:
- [x] 09-01-PLAN.md — Mode infrastructure (mode.sh library, budget.sh extension, lazy-mode.md command)
- [x] 09-02-PLAN.md — Command updates (help.md mode labels, progress.md mode display, mode gating)

### Phase 10: Execution Commands
**Goal**: Unified autopilot command for autonomous milestone execution
**Depends on**: Phase 9
**Requirements**: CMD-02, CMD-03, CMD-04
**Success Criteria** (what must be TRUE):
  1. `/gsd:autopilot` provides unified entry point for lazy mode execution
  2. Autopilot prompts for settings (max iterations, timeout, thresholds) every run
  3. Autopilot detects existing plans or triggers planning automatically
  4. Autopilot detects incomplete runs and offers resume
  5. Ctrl+C triggers graceful stop with resume instructions
  6. End-to-end workflow: lazy-mode -> autopilot (plans if needed, then executes)
**Plans**: 3 plans

Plans:
- [x] 10-01-PLAN.md — Config extension and autopilot command skeleton
- [x] 10-02-PLAN.md — Plan detection, resume detection, and execution orchestration
- [x] 10-03-PLAN.md — Documentation updates (help.md, progress.md)

## Progress

**Execution Order:**
Phases execute in numeric order: 1 -> 2 -> 3 -> 4 -> 5 -> 6 -> 7 -> 8 -> 9 -> 10

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Safety Foundation | 2/2 | Complete | 2026-01-19 |
| 2. State Extensions | 2/2 | Complete | 2026-01-19 |
| 3. Outer Loop Core | 3/3 | Complete | 2026-01-19 |
| 4. Git Checkpointing | 2/2 | Complete | 2026-01-19 |
| 5. Exit Conditions | 2/2 | Complete | 2026-01-19 |
| 6. Circuit Breaker & Recovery | 2/2 | Complete | 2026-01-19 |
| 7. Learnings Propagation | 2/2 | Complete | 2026-01-19 |
| 8. Upfront Planning | 2/2 | Complete | 2026-01-19 |
| 9. Mode Selection & Base Commands | 2/2 | Complete | 2026-01-20 |
| 10. Execution Commands | 3/3 | Complete | 2026-01-20 |

---
*Roadmap created: 2026-01-19*
*Depth: Comprehensive (10 phases, 22 planned plans)*
