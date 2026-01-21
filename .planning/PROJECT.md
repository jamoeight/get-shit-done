# GSD Lazy Mode

## What This Is

An extension to GSD that adds autonomous "fire and forget" milestone execution. Users plan everything upfront in one intensive session, then walk away while ralph.sh spawns fresh Claude instances to work through all phases until the milestone is complete.

## Core Value

Plan once, walk away, wake up to done. No human needed at the computer after planning.

## Requirements

### Validated

- ✓ Interactive phase-by-phase planning — existing
- ✓ Parallel/sequential agent execution within phases — existing
- ✓ State persistence via markdown files (.planning/) — existing
- ✓ Subagent orchestration with fresh context per agent — existing
- ✓ Verification step after phase execution — existing
- ✓ Git atomic commits during execution — existing
- ✓ Mode selection at GSD startup (Interactive vs Lazy) — v1.0
- ✓ `/gsd:plan-milestone-all` command for upfront planning — v1.0
- ✓ Generate ALL PLAN.md files for ALL phases before execution — v1.0
- ✓ LLM-guided phase structure determination during planning — v1.0
- ✓ `/gsd:autopilot` command for configuration and execution — v1.0
- ✓ Max iteration limit for token budget control — v1.0
- ✓ Ralph loop at milestone level (retry incomplete work) — v1.0
- ✓ Exit condition: all requirements met + all tests pass — v1.0
- ✓ No human checkpoints during execution — v1.0
- ✓ Progress persistence between ralph iterations (via git + state files) — v1.0

### Active

- [ ] Auto-launch terminal for ralph.sh (execution isolation)
- [ ] Cross-platform terminal detection (Windows/macOS/Linux)
- [ ] Failure learnings propagation (extract failure context for retries)

## Current Milestone: v1.1 Execution Isolation & Failure Learnings

**Goal:** Prevent Claude from executing directly by auto-launching ralph.sh in a separate terminal, and improve retry intelligence by propagating failure learnings.

**Target features:**
- Auto-launch terminal window when /gsd:autopilot runs
- Cross-platform terminal detection (cmd, PowerShell, Git Bash, Terminal.app, gnome-terminal, etc.)
- Extract failure reasons from failed tasks and add structured context to AGENTS.md for retries

### Out of Scope

- Per-agent ralph loops — adds coordination complexity, milestone-level loop is simpler
- Real-time notifications/alerts — user walks away, checks results later
- Automatic token cost estimation — user sets max iterations manually
- Rollback on failure — ralph pattern retries forward, doesn't roll back

## Context

**Current State (v1.0 shipped):**
- 12 bash libraries + ralph.sh main script
- ~32,800 lines of code
- 10 phases, 22 plans completed
- Full audit passed: 22/22 requirements, 0 gaps

**Known Issue:** Claude may execute plans directly instead of delegating to ralph.sh. Workaround: run `./bin/ralph.sh` manually in terminal. Fix planned for v1.1 (EXEC-01).

## Constraints

- **Compatibility**: Must coexist with current Interactive mode — user chooses at startup
- **Context limits**: Each ralph iteration spawns fresh Claude, ~200k context per agent
- **Token budget**: Max iterations limit prevents runaway costs
- **Existing patterns**: Follow current GSD command/agent/workflow architecture

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Ralph loop at milestone level, not per-agent | Simpler coordination, matches ralph pattern (one loop, one task at a time) | ✓ Good |
| Generate all PLAN.md files upfront | Front-loads judgment while human present, execution becomes mechanical | ✓ Good |
| Mode selection at startup | Clean separation, lazy mode has different command set | ✓ Good |
| Fresh context per iteration (ralph pattern) | Prevents context degradation, inherited knowledge via state files | ✓ Good |
| Autopilot as unified command | Consolidated /gsd:ralph and /gsd:run-milestone into single /gsd:autopilot | ✓ Good |
| Learnings from successes only (v1.0) | Simpler implementation, failure learnings deferred to v1.1 | ⚠️ Revisit |

---
*Last updated: 2026-01-20 after starting v1.1 milestone*
