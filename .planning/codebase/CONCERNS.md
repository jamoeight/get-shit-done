# Codebase Concerns

**Analysis Date:** 2026-01-19

## Tech Debt

**Large Agent Files:**
- Issue: Several agent files exceed 1000 lines, making them difficult to maintain and navigate
- Files:
  - `agents/gsd-planner.md` (1367 lines)
  - `agents/gsd-debugger.md` (1184 lines)
  - `agents/gsd-project-researcher.md` (865 lines)
  - `agents/gsd-verifier.md` (778 lines)
  - `agents/gsd-executor.md` (753 lines)
- Impact: Context loading overhead, harder to modify individual sections without introducing regressions
- Fix approach: Consider modularizing common patterns (e.g., checkpoint handling, state updates) into shared references

**Duplicated Philosophy/Pattern Content:**
- Issue: Similar patterns repeated across agent files (e.g., context efficiency philosophy, checkpoint protocols, deviation rules)
- Files:
  - `agents/gsd-executor.md` deviation rules section
  - `commands/gsd/execute-phase.md` deviation rules section
  - `get-shit-done/workflows/execute-phase.md` checkpoint handling
- Impact: Inconsistencies when updating patterns in one file but not others; increased maintenance burden
- Fix approach: Extract common patterns into `references/` files and use `@` imports

**Hardcoded Home Directory Paths:**
- Issue: Files reference `~/.claude/` paths that get replaced during installation
- Files: All `.md` files in `commands/`, `agents/`, `get-shit-done/`
- Impact: If path replacement fails during install, all @ references break silently
- Fix approach: Already handled by `copyWithPathReplacement()` in `bin/install.js`, but no verification that replacements succeeded

**No Automated Tests:**
- Issue: No test files exist for the JavaScript code or integration tests for the workflow system
- Files: `bin/install.js`, `hooks/statusline.js`, `hooks/gsd-check-update.js`
- Impact: Regressions discovered only in production; install failures on edge cases (e.g., WSL2 fix was manual discovery)
- Fix approach: Add unit tests for install.js functions, add integration tests for common install scenarios

## Known Bugs

**Date Inconsistencies in Changelog:**
- Symptoms: Some changelog entries show future dates (2026) while others show 2025
- Files: `CHANGELOG.md` lines 9, 36, 67, 121, 227, etc.
- Trigger: Manual editing of changelog with incorrect dates
- Workaround: None — cosmetic only but may confuse users

**Orphaned Hook Cleanup Incomplete:**
- Symptoms: `cleanupOrphanedFiles()` only handles `gsd-notify.sh`, other orphaned files from earlier versions may remain
- Files: `bin/install.js` lines 157-169
- Trigger: Upgrading from very old versions (pre-1.5)
- Workaround: Manual cleanup of `~/.claude/` directory

## Security Considerations

**Spawned Process Execution:**
- Risk: Update checker spawns a Node.js subprocess with inline code
- Files: `hooks/gsd-check-update.js` lines 21-46
- Current mitigation: Code is static (no user input), runs detached with ignored stdio
- Recommendations: Consider using a separate script file instead of inline `-e` code for auditability

**Git Commit Injection (Theoretical):**
- Risk: Commit messages constructed from user-provided content (phase names, task descriptions) could theoretically contain shell metacharacters
- Files: Multiple commit operations across `agents/gsd-executor.md`, `commands/gsd/execute-phase.md`
- Current mitigation: Content generally comes from trusted .planning/ files created by Claude
- Recommendations: Document that .planning/ files should not contain untrusted user input directly

**No Input Validation on CLI Args:**
- Risk: `--config-dir` and other args passed directly to filesystem operations
- Files: `bin/install.js` line 96-101 (`expandTilde`)
- Current mitigation: Only used for path construction, not shell execution
- Recommendations: Add path sanitization to reject paths with `..` traversal

## Performance Bottlenecks

**Synchronous File Operations:**
- Problem: Install script uses synchronous fs operations throughout
- Files: `bin/install.js` — all `fs.readFileSync`, `fs.writeFileSync`, `fs.copyFileSync`
- Cause: Sequential file copying blocks event loop during large installations
- Improvement path: Convert to async/await with Promise.all for parallel operations

**Agent Context Loading:**
- Problem: Large agent files (1000+ lines) consume significant context when spawned
- Files: `agents/gsd-planner.md`, `agents/gsd-debugger.md`
- Cause: Entire agent definition loaded into each subagent context
- Improvement path: Extract rarely-used reference sections into conditional loads

## Fragile Areas

**Path Resolution:**
- Files: `bin/install.js` lines 248-264, `hooks/statusline.js` lines 45-47
- Why fragile: Multiple path formats (explicit arg, env var, default) with tilde expansion and OS-specific handling
- Safe modification: Test on Windows, Mac, Linux, and WSL2 before releasing path changes
- Test coverage: No automated tests — manual testing only

**Frontmatter Parsing:**
- Files: `get-shit-done/workflows/execute-phase.md` lines 95-100
- Why fragile: YAML frontmatter parsed via grep/cut pipelines — whitespace sensitive
- Safe modification: Any changes to frontmatter format need corresponding parser updates
- Test coverage: None — discovered via runtime failures

**Phase Directory Matching:**
- Files: `get-shit-done/workflows/execute-phase.md` lines 42-48
- Why fragile: Handles both zero-padded (05-) and unpadded (5-) folder names via shell globbing
- Safe modification: Maintain both patterns in ls -d commands
- Test coverage: None — fixed via bug report in v1.5.28

**Session ID Handling in Statusline:**
- Files: `hooks/statusline.js` lines 47-59
- Why fragile: Assumes specific file naming pattern with session ID prefix
- Safe modification: Changes to todo file naming will break statusline task display
- Test coverage: None

## Scaling Limits

**Todo File Scanning:**
- Current capacity: Works fine with typical usage (< 100 files)
- Limit: Statusline reads/sorts all files matching pattern on every render
- Files: `hooks/statusline.js` lines 48-51
- Scaling path: Add caching or limit to most recent N files

**Planning Phase Count:**
- Current capacity: System designed for 3-12 phases per milestone
- Limit: Very large projects (20+ phases) may exceed context in orchestrators
- Files: `agents/gsd-roadmapper.md`, `commands/gsd/progress.md`
- Scaling path: Consider milestone subdivision for very large projects

## Dependencies at Risk

**None Detected:**
- Project has no npm dependencies beyond Node.js built-ins
- Package.json has no dependencies (intentional design choice)
- No bundling, no transpilation, no build step

## Missing Critical Features

**No Rollback Mechanism:**
- Problem: If execution fails mid-phase, no automated way to revert changes
- Blocks: Safe experimentation, recovery from bad states
- Workaround: Manual git revert operations

**No Cross-Platform Hook Support:**
- Problem: Hooks assume Node.js available, no fallback
- Files: `hooks/statusline.js`, `hooks/gsd-check-update.js`
- Blocks: Users without Node.js in PATH

**No Offline Mode:**
- Problem: Update checker calls npm registry on every session start
- Files: `hooks/gsd-check-update.js` line 35
- Blocks: Air-gapped environments
- Workaround: Runs in background with timeout, fails silently

## Test Coverage Gaps

**Install Script Functions:**
- What's not tested: `expandTilde()`, `copyWithPathReplacement()`, `cleanupOrphanedFiles()`, `verifyInstalled()`
- Files: `bin/install.js` lines 96-101, 128-152, 157-169, 215-231
- Risk: Edge cases in path handling, permission errors, partial installs
- Priority: High — install failures block all usage

**Statusline Parsing:**
- What's not tested: JSON input parsing, context percentage calculation, progress bar rendering
- Files: `hooks/statusline.js` lines 13-80
- Risk: Malformed input causes silent failure (by design, but untested)
- Priority: Low — fails gracefully

**Workflow State Transitions:**
- What's not tested: Checkpoint handling, continuation agents, wave execution
- Files: `get-shit-done/workflows/execute-phase.md`, `agents/gsd-executor.md`
- Risk: State corruption on interruption, incorrect resumption
- Priority: Medium — complex state machine with many edge cases

**Command Argument Parsing:**
- What's not tested: Phase number normalization, flag parsing (`--gaps`, `--skip-research`)
- Files: All command files in `commands/gsd/`
- Risk: Incorrect routing based on malformed input
- Priority: Medium

---

*Concerns audit: 2026-01-19*
