# GSD Lazy Mode

## What This Is

An extension to GSD that adds autonomous "fire and forget" milestone execution. Users plan everything upfront in one intensive session, then walk away while ralph.sh spawns fresh Claude instances in a separate terminal window to work through all phases until the milestone is complete. Failed tasks have their context extracted and propagated to retries for smarter recovery.

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
- ✓ Auto-launch terminal for ralph.sh (execution isolation) — v1.1
- ✓ Cross-platform terminal detection (Windows/macOS/Linux) — v1.1
- ✓ Failure learnings propagation (extract failure context for retries) — v1.1
- ✓ Universal path resolution for terminal spawning — v1.2

### Active

(None — planning next milestone)

### Out of Scope

- Per-agent ralph loops — adds coordination complexity, milestone-level loop is simpler
- Real-time notifications/alerts — user walks away, checks results later
- Automatic token cost estimation — user sets max iterations manually
- Rollback on failure — ralph pattern retries forward, doesn't roll back

## Context

**Current State (v1.2 shipped):**
- 13 bash libraries + 1 Node.js module + ralph.sh main script
- ~5,700 lines of executable code (bin/)
- +38,000 lines total with planning/docs
- 13 phases, 28 plans completed across 3 milestones
- Full audit passed: 8/8 v1.2 requirements, 0 gaps

**v1.2 additions:**
- bin/lib/terminal-launcher.js extended (+400 lines) — Multi-location Git Bash detection, fallback chain
- bin/lib/path-resolve.sh (185 lines) — Runtime bash environment detection, path conversion

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
| Learnings from successes only (v1.0) | Simpler implementation, failure learnings added in v1.1 | ✓ Good |
| command-exists for terminal detection | Reliable cross-platform detection vs custom PATH scanning | ✓ Good |
| Detached process spawning | subprocess.unref() enables true execution isolation | ✓ Good |
| Manual fallback instructions | Graceful degradation when terminal detection fails | ✓ Good |
| jq with grep/sed fallback | Universal compatibility — works with or without jq installed | ✓ Good |
| Phase-scoped failure subsections | Enables selective cleanup without affecting other phases | ✓ Good |
| 100-failure cap per phase | Prevents unbounded growth, drops oldest first | ✓ Good |

## Next Milestone

**Planning:** v2.0 features TBD

Run `/gsd:new-milestone` to define next milestone goals, requirements, and roadmap.

---
*Last updated: 2026-01-21 after v1.2 milestone shipped*
