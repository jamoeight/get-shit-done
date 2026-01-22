# Roadmap: v1.2 Terminal Path Resolution

**Goal:** Fix terminal path resolution bug that blocks autopilot on Windows when user's Windows Terminal default profile isn't Git Bash.

**Phases:** 1 (Phase 13)

---

## Current Milestone: v1.2

### Phase 13: Terminal Path Resolution Fix
**Goal:** Autopilot works on Windows regardless of terminal configuration
**Status:** Pending
**Depends on:** None (standalone bug fix)
**Plans:** TBD (plan-phase will determine, likely 2-3)

**Requirements:**
- TERM-01: wt.exe launcher checks Git Bash existence before attempting launch
- TERM-02: Try multiple Git Bash installation locations (standard, x86, user installs)
- TERM-03: Fall back to cmd.exe when Git Bash not found at any location
- PATH-01: ralph.sh detects bash environment at runtime (Git Bash, WSL, Cygwin)
- PATH-02: ralph.sh converts Windows paths using native tools (cygpath, wslpath)
- PATH-03: Fallback chain tries all path formats when native tools unavailable
- ERR-01: Clear error message when no suitable terminal found
- ERR-02: Manual fallback instructions displayed when all terminal launchers fail

**Success Criteria:**
1. User with Git Bash installed sees autopilot spawn correctly via wt.exe
2. User without Git Bash at standard location sees fallback to cmd.exe
3. User running ralph.sh in any bash variant (Git Bash, WSL, Cygwin) has paths resolve correctly
4. User sees actionable error message when no suitable terminal found
5. User can follow manual instructions to run autopilot when all launchers fail

**Why one phase:**
- All 8 requirements solve a single bug from two angles (Node.js launcher + bash script)
- Natural delivery boundary: either path resolution works or it doesn't
- No dependencies between requirements that would require phasing

**Implementation split (anticipated by plan-phase):**
- Plan A: Terminal launcher hardening (TERM-01, TERM-02, TERM-03, ERR-01, ERR-02) - Node.js
- Plan B: Runtime path resolution (PATH-01, PATH-02, PATH-03) - Bash

---

## Milestone History

| Version | Name | Phases | Status |
|---------|------|--------|--------|
| v1.0 | Lazy Mode MVP | 1-10 | Shipped 2026-01-20 |
| v1.1 | Execution Isolation & Failure Learnings | 11-12 | Shipped 2026-01-21 |
| v1.2 | Terminal Path Resolution | 13 | Current |

---

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| TERM-01 | Phase 13 | Pending |
| TERM-02 | Phase 13 | Pending |
| TERM-03 | Phase 13 | Pending |
| PATH-01 | Phase 13 | Pending |
| PATH-02 | Phase 13 | Pending |
| PATH-03 | Phase 13 | Pending |
| ERR-01 | Phase 13 | Pending |
| ERR-02 | Phase 13 | Pending |

**Coverage:**
- v1.2 requirements: 8 total
- Mapped to phases: 8
- Unmapped: 0

---
*Created: 2026-01-21*
*Milestone: v1.2 Terminal Path Resolution*
