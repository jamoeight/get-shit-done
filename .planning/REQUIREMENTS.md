# Requirements: v1.2 Terminal Path Resolution

**Defined:** 2026-01-21
**Core Value:** Plan once, walk away, wake up to done — autopilot must work regardless of Windows terminal config.

## v1.2 Requirements

Requirements for terminal path resolution bug fix. Enables autopilot on Windows regardless of user's Windows Terminal default profile.

### Terminal Detection

- [ ] **TERM-01**: wt.exe launcher checks Git Bash existence before attempting launch
- [ ] **TERM-02**: Try multiple Git Bash installation locations (standard, x86, user installs)
- [ ] **TERM-03**: Fall back to cmd.exe when Git Bash not found at any location

### Path Resolution

- [ ] **PATH-01**: ralph.sh detects bash environment at runtime (Git Bash, WSL, Cygwin)
- [ ] **PATH-02**: ralph.sh converts Windows paths using native tools (cygpath, wslpath)
- [ ] **PATH-03**: Fallback chain tries all path formats when native tools unavailable

### Error Handling

- [ ] **ERR-01**: Clear error message when no suitable terminal found
- [ ] **ERR-02**: Manual fallback instructions displayed when all terminal launchers fail

## Out of Scope

| Feature | Reason |
|---------|--------|
| Profile detection via settings.json | Complexity not justified; runtime resolution solves root cause |
| WSL-first terminal support | Git Bash is standard; WSL users can use runtime resolution |
| Cygwin-first terminal support | Rare configuration; runtime resolution handles it |
| wt.exe profile specification (`-p`) | Profile names vary by user; unreliable |

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
*Requirements defined: 2026-01-21*
*Last updated: 2026-01-21 - Roadmap created, traceability confirmed*
