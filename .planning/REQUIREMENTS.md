# Requirements: GSD Lazy Mode

**Defined:** 2026-01-19
**Core Value:** Plan once, walk away, wake up to done. No human needed at the computer after planning.

## v1.0 Requirements (Shipped)

All v1.0 requirements shipped on 2026-01-20. See `.planning/milestones/` for details.

## v1.1 Requirements

Requirements for v1.1 release. Each maps to roadmap phases.

### Execution Isolation

- [ ] **EXEC-01**: Autopilot auto-launches a new terminal window instead of running ralph.sh inline
- [ ] **EXEC-02**: Terminal launcher detects platform and uses appropriate terminal (cmd/PowerShell/Git Bash on Windows, Terminal.app on macOS, gnome-terminal/xterm on Linux)
- [ ] **EXEC-03**: If terminal detection fails, autopilot falls back to displaying manual run instructions
- [ ] **EXEC-04**: Ralph.sh runs in the spawned terminal as an independent process

### Failure Learnings

- [ ] **FAIL-01**: When a task fails, extract the failure reason from Claude's output
- [ ] **FAIL-02**: Structure failure context into a learnings format (what failed, why, what was attempted)
- [ ] **FAIL-03**: Append failure learnings to AGENTS.md under a "Failure Context" section
- [ ] **FAIL-04**: Next retry attempt includes failure learnings in its prompt context

## v2+ Requirements

Deferred to future release. Tracked but not in current roadmap.

### Monitoring

- **MON-01**: Cost tracking (tokens per iteration, cumulative spend)
- **MON-02**: Time-based cap (max run duration limit)
- **MON-03**: Progress notifications (email/webhook on completion/failure)

### Advanced Recovery

- **REC-01**: Multi-model verification (critic agent reviews work before exit)
- **REC-02**: Checkpointing with resume beyond git (serialize full execution state)
- **REC-03**: Parallel phase execution (independent phases run simultaneously)

### Execution Isolation (v2 enhancements)

- **EXEC-05**: Terminal preference configuration (user specifies preferred terminal)
- **EXEC-06**: Terminal output streaming to log file for later review

### Failure Learnings (v2 enhancements)

- **FAIL-05**: Categorize failure types (syntax error, missing dependency, logic error, etc.)
- **FAIL-06**: Suggest remediation approaches based on failure type

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
| EXEC-01 | TBD | Pending |
| EXEC-02 | TBD | Pending |
| EXEC-03 | TBD | Pending |
| EXEC-04 | TBD | Pending |
| FAIL-01 | TBD | Pending |
| FAIL-02 | TBD | Pending |
| FAIL-03 | TBD | Pending |
| FAIL-04 | TBD | Pending |

**Coverage:**
- v1.1 requirements: 8 total
- Mapped to phases: 0
- Unmapped: 8 (roadmap pending)

---
*Requirements defined: 2026-01-19*
*Last updated: 2026-01-20 after v1.1 milestone start*
