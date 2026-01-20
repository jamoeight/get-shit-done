# Requirements: GSD Lazy Mode

**Defined:** 2026-01-19
**Core Value:** Plan once, walk away, wake up to done. No human needed at the computer after planning.

## v1 Requirements

Requirements for initial release. Each maps to roadmap phases.

### Core Loop

- [x] **LOOP-01**: Retry loop with configurable max iterations
- [x] **LOOP-02**: Fresh context per iteration (spawn new Claude instance each time)
- [x] **LOOP-03**: Circuit breaker pattern (pause after N consecutive failures)
- [x] **LOOP-04**: Intelligent stuck detection (analyze WHY stuck, try alternative approach)

### Exit Conditions

- [x] **EXIT-01**: Test-based success criteria (all tests pass = milestone complete)
- [x] **EXIT-02**: Stuck loop detection (3+ failures on same task triggers exit)
- [x] **EXIT-03**: Dual-exit gate (both completion markers AND explicit exit signal required)

### Safety

- [x] **SAFE-01**: Hard iteration cap (configurable maximum)
- [x] **SAFE-02**: Fail-fast error handling (surface failures immediately, don't continue silently)

### Upfront Planning

- [x] **PLAN-01**: Generate ALL PLAN.md files for ALL phases before execution starts
- [x] **PLAN-02**: LLM-guided phase structure determination
- [x] **PLAN-03**: Dependency analysis across phases
- [x] **PLAN-04**: Interactive refinement during planning session

### State & Persistence

- [x] **STATE-01**: State file persistence (STATE.md tracks iteration count, current phase, outcomes)
- [x] **STATE-02**: Git commits as checkpoints (atomic commit each iteration)
- [x] **STATE-03**: Progress indicator updated each iteration
- [x] **STATE-04**: Learnings propagation (discovered patterns written to AGENTS.md or equivalent)

### Commands

- [x] **CMD-01**: Mode selection at GSD startup (Interactive vs Lazy)
- [x] **CMD-02**: `/gsd:plan-milestone-all` command for upfront planning
- [x] **CMD-03**: `/gsd:autopilot` configures settings (consolidated from /gsd:ralph)
- [x] **CMD-04**: `/gsd:autopilot` starts autonomous execution (consolidated from /gsd:run-milestone)
- [x] **CMD-05**: All base GSD commands available in lazy mode (new-project, map-codebase, progress, etc.)

## v2 Requirements

Deferred to future release. Tracked but not in current roadmap.

### Monitoring

- **MON-01**: Cost tracking (tokens per iteration, cumulative spend)
- **MON-02**: Time-based cap (max run duration limit)
- **MON-03**: Progress notifications (email/webhook on completion/failure)

### Advanced Recovery

- **REC-01**: Multi-model verification (critic agent reviews work before exit)
- **REC-02**: Checkpointing with resume (serialize full execution state beyond git)
- **REC-03**: Parallel phase execution (independent phases run simultaneously)
- **REC-04**: Failure learnings propagation (extract "what went wrong" from failed attempts, feed to retry with structured context so next attempt has richer understanding of the failure)

### Execution Isolation

- **EXEC-01**: Auto-launch terminal for ralph.sh (autopilot opens new terminal window, runs ralph.sh as independent process, prevents Claude from "helpfully" executing plans directly instead of delegating)
- **EXEC-02**: Cross-platform terminal detection (Windows cmd/PowerShell/Git Bash, macOS Terminal, Linux gnome-terminal/xterm/etc.)

## Out of Scope

Explicitly excluded. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| Per-agent ralph loops | Coordination complexity explodes. Milestone-level loop is simpler. |
| Real-time dashboard/UI | User walks away. Dashboard unseen. Wasted effort. |
| Token cost estimation | Highly variable. Inaccurate estimates frustrate users. |
| Automatic rollback | "Forward-only" is simpler. Rollback requires understanding causality. |
| Human intervention points | Defeats "fire and forget." Use Interactive mode for checkpoints. |
| Complex scheduling | "Run at 2am" adds cron-like complexity. User starts when ready. |
| Multi-milestone orchestration | One milestone is enough scope. Chaining adds failure modes. |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| SAFE-01 | Phase 1: Safety Foundation | Complete |
| SAFE-02 | Phase 1: Safety Foundation | Complete |
| STATE-01 | Phase 2: State Extensions | Complete |
| STATE-03 | Phase 2: State Extensions | Complete |
| LOOP-01 | Phase 3: Outer Loop Core | Complete |
| LOOP-02 | Phase 3: Outer Loop Core | Complete |
| STATE-02 | Phase 4: Git Checkpointing | Complete |
| EXIT-01 | Phase 5: Exit Conditions | Complete |
| EXIT-02 | Phase 5: Exit Conditions | Complete |
| EXIT-03 | Phase 5: Exit Conditions | Complete |
| LOOP-03 | Phase 6: Circuit Breaker & Recovery | Complete |
| LOOP-04 | Phase 6: Circuit Breaker & Recovery | Complete |
| STATE-04 | Phase 7: Learnings Propagation | Complete |
| PLAN-01 | Phase 8: Upfront Planning | Complete |
| PLAN-02 | Phase 8: Upfront Planning | Complete |
| PLAN-03 | Phase 8: Upfront Planning | Complete |
| PLAN-04 | Phase 8: Upfront Planning | Complete |
| CMD-01 | Phase 9: Mode Selection & Base Commands | Complete |
| CMD-05 | Phase 9: Mode Selection & Base Commands | Complete |
| CMD-02 | Phase 10: Execution Commands | Complete |
| CMD-03 | Phase 10: Execution Commands | Complete |
| CMD-04 | Phase 10: Execution Commands | Complete |

**Coverage:**
- v1 requirements: 22 total
- Mapped to phases: 22
- Unmapped: 0

---
*Requirements defined: 2026-01-19*
*Last updated: 2026-01-20 after Phase 10 completion - All v1 requirements complete*
