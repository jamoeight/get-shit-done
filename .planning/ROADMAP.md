# Roadmap: GSD Lazy Mode

## Overview

GSD Lazy Mode transforms the existing interactive GSD workflow into a "fire and forget" system where users plan everything upfront, then walk away while agents execute autonomously until the milestone is complete. This roadmap starts with safety infrastructure (budget controls, fail-fast handling) to prevent runaway token burn, then builds the outer loop machinery, exit conditions, and planning commands. The final phases wire everything together into user-facing commands that enable autonomous overnight execution.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [ ] **Phase 1: Safety Foundation** - Hard iteration caps and fail-fast error handling to prevent runaway costs
- [ ] **Phase 2: State Extensions** - Extended STATE.md with iteration tracking and progress indicators
- [ ] **Phase 3: Outer Loop Core** - Bash script that spawns fresh Claude instances with retry logic
- [ ] **Phase 4: Git Checkpointing** - Atomic commits as iteration boundaries for progress persistence
- [ ] **Phase 5: Exit Conditions** - Test-based completion, stuck detection, and dual-exit gate
- [ ] **Phase 6: Circuit Breaker & Recovery** - Pause after consecutive failures, analyze stuck state
- [ ] **Phase 7: Learnings Propagation** - Write discovered patterns to AGENTS.md across iterations
- [ ] **Phase 8: Upfront Planning** - Generate all PLAN.md files before autonomous execution begins
- [ ] **Phase 9: Mode Selection & Base Commands** - Interactive vs Lazy mode selection at startup
- [ ] **Phase 10: Execution Commands** - Full command set for autonomous milestone execution

## Phase Details

### Phase 1: Safety Foundation
**Goal**: Prevent runaway token burn with hard limits and immediate error surfacing
**Depends on**: Nothing (first phase)
**Requirements**: SAFE-01, SAFE-02
**Success Criteria** (what must be TRUE):
  1. User can configure a maximum iteration limit before starting autonomous execution
  2. Errors surface immediately to the outer loop instead of continuing silently
  3. CONFIG.json stores budget configuration that the outer loop respects
  4. Outer loop aborts when iteration cap is reached, preserving progress made so far
**Plans**: TBD

Plans:
- [ ] 01-01: Budget configuration infrastructure
- [ ] 01-02: Fail-fast error handling patterns

### Phase 2: State Extensions
**Goal**: Track iteration state and show progress across autonomous execution
**Depends on**: Phase 1
**Requirements**: STATE-01, STATE-03
**Success Criteria** (what must be TRUE):
  1. STATE.md includes iteration count, current phase, and outcome history
  2. Progress indicator updates after each iteration completes
  3. Fresh Claude instances can read STATE.md and know exactly where to resume
  4. Iteration history persists between sessions (survives crashes)
**Plans**: TBD

Plans:
- [ ] 02-01: STATE.md schema extensions for lazy mode
- [ ] 02-02: Progress indicator implementation

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
**Plans**: TBD

Plans:
- [ ] 03-01: ralph.sh script skeleton with iteration control
- [ ] 03-02: Claude CLI invocation with JSON output parsing
- [ ] 03-03: Cross-platform compatibility testing

### Phase 4: Git Checkpointing
**Goal**: Use atomic git commits as progress checkpoints
**Depends on**: Phase 3
**Requirements**: STATE-02
**Success Criteria** (what must be TRUE):
  1. Each successful iteration creates an atomic git commit
  2. Commit message includes iteration number and task completed
  3. Progress can be reconstructed from git history if STATE.md is lost
  4. Partial work is not committed (only successful completions)
**Plans**: TBD

Plans:
- [ ] 04-01: Atomic commit integration in outer loop
- [ ] 04-02: Commit message formatting and history recovery

### Phase 5: Exit Conditions
**Goal**: Determine when autonomous execution should stop
**Depends on**: Phase 4
**Requirements**: EXIT-01, EXIT-02, EXIT-03
**Success Criteria** (what must be TRUE):
  1. Loop exits when all tests pass AND all requirements are marked complete
  2. Loop exits when same task fails 3+ times consecutively (stuck detection)
  3. Dual-exit gate requires BOTH completion markers AND explicit exit signal
  4. Exit reason is clearly logged in STATE.md for user review
**Plans**: TBD

Plans:
- [ ] 05-01: Test-based completion detection
- [ ] 05-02: Stuck loop detection and exit
- [ ] 05-03: Dual-exit gate implementation

### Phase 6: Circuit Breaker & Recovery
**Goal**: Intelligently handle repeated failures without burning tokens
**Depends on**: Phase 5
**Requirements**: LOOP-03, LOOP-04
**Success Criteria** (what must be TRUE):
  1. Loop pauses (not exits) after N consecutive failures on different tasks
  2. Stuck detection analyzes WHY the loop is stuck before retrying
  3. Alternative approaches are tried before giving up on a task
  4. User can review failure analysis and resume or abort
**Plans**: TBD

Plans:
- [ ] 06-01: Circuit breaker pattern implementation
- [ ] 06-02: Stuck analysis and alternative approach selection

### Phase 7: Learnings Propagation
**Goal**: Share discovered patterns across iterations via AGENTS.md
**Depends on**: Phase 6
**Requirements**: STATE-04
**Success Criteria** (what must be TRUE):
  1. Patterns discovered during execution are written to AGENTS.md
  2. Future iterations read AGENTS.md and benefit from learned patterns
  3. Learnings accumulate without causing context bloat
  4. User can review and edit accumulated learnings
**Plans**: TBD

Plans:
- [ ] 07-01: Learning extraction from iteration outcomes
- [ ] 07-02: AGENTS.md integration and consumption

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
**Plans**: TBD

Plans:
- [ ] 08-01: plan-milestone-all workflow design
- [ ] 08-02: LLM-guided phase structure determination
- [ ] 08-03: Dependency analysis implementation
- [ ] 08-04: Interactive refinement loop

### Phase 9: Mode Selection & Base Commands
**Goal**: Enable users to choose Interactive vs Lazy mode at startup
**Depends on**: Phase 8
**Requirements**: CMD-01, CMD-05
**Success Criteria** (what must be TRUE):
  1. User can select mode at GSD startup (Interactive vs Lazy)
  2. All existing GSD commands work in lazy mode (new-project, map-codebase, progress)
  3. Mode persists across sessions until changed
  4. Help text shows mode-appropriate commands
**Plans**: TBD

Plans:
- [ ] 09-01: Mode selection command implementation
- [ ] 09-02: Base command compatibility verification

### Phase 10: Execution Commands
**Goal**: Complete user-facing command set for autonomous execution
**Depends on**: Phase 9
**Requirements**: CMD-02, CMD-03, CMD-04
**Success Criteria** (what must be TRUE):
  1. `/gsd:plan-milestone-all` generates all plans for the milestone
  2. `/gsd:ralph` configures retry loop settings (enable/disable, max iterations)
  3. `/gsd:run-milestone` starts autonomous execution and runs until completion
  4. Commands integrate with safety infrastructure from Phase 1
  5. End-to-end workflow: plan-milestone-all -> ralph configure -> run-milestone
**Plans**: TBD

Plans:
- [ ] 10-01: plan-milestone-all command
- [ ] 10-02: ralph configuration command
- [ ] 10-03: run-milestone command
- [ ] 10-04: End-to-end integration testing

## Progress

**Execution Order:**
Phases execute in numeric order: 1 -> 2 -> 3 -> 4 -> 5 -> 6 -> 7 -> 8 -> 9 -> 10

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Safety Foundation | 0/2 | Not started | - |
| 2. State Extensions | 0/2 | Not started | - |
| 3. Outer Loop Core | 0/3 | Not started | - |
| 4. Git Checkpointing | 0/2 | Not started | - |
| 5. Exit Conditions | 0/3 | Not started | - |
| 6. Circuit Breaker & Recovery | 0/2 | Not started | - |
| 7. Learnings Propagation | 0/2 | Not started | - |
| 8. Upfront Planning | 0/4 | Not started | - |
| 9. Mode Selection & Base Commands | 0/2 | Not started | - |
| 10. Execution Commands | 0/4 | Not started | - |

---
*Roadmap created: 2026-01-19*
*Depth: Comprehensive (10 phases, 26 planned plans)*
