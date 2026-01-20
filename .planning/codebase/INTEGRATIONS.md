# External Integrations

**Analysis Date:** 2025-01-19

## APIs & External Services

**npm Registry:**
- Purpose: Version checking for update notifications
- Client: `npm view get-shit-done-cc version` via `child_process.execSync`
- Auth: None required (public package)
- Location: `hooks/gsd-check-update.js`

**Claude Code CLI:**
- Purpose: Primary runtime platform - all GSD commands execute within Claude Code
- Integration: Slash commands via `.claude/commands/gsd/*.md`
- Hooks: SessionStart hook for update checks, statusline command
- Config: `settings.json` in Claude config directory

## Data Storage

**Databases:**
- None - All state is file-based

**File Storage:**
- Local filesystem only
- Installation target: `~/.claude/` (global) or `./.claude/` (local)
- Project artifacts: `.planning/` directory in user projects

**Caching:**
- Update check cache: `~/.claude/cache/gsd-update-check.json`
- Todo files: `~/.claude/todos/` directory (read by statusline)

## Authentication & Identity

**Auth Provider:**
- None - No authentication required
- Installation is local file copy operation

## Monitoring & Observability

**Error Tracking:**
- None - Silent fail pattern in hooks to avoid breaking Claude Code UI

**Logs:**
- Console output during installation only
- Hooks suppress errors (`try/catch` with empty catch blocks)

## CI/CD & Deployment

**Hosting:**
- npm registry for package distribution
- GitHub for source code (`github.com/glittercowboy/get-shit-done`)

**CI Pipeline:**
- None detected in repository
- Manual publishing to npm

**GitHub Integration:**
- Funding: GitHub Sponsors (`glittercowboy`)
- Location: `.github/FUNDING.yml`

## Environment Configuration

**Required env vars:**
- None required

**Optional env vars:**
- `CLAUDE_CONFIG_DIR` - Override Claude config directory path

**Secrets location:**
- No secrets required - public package, no authentication

## Webhooks & Callbacks

**Incoming:**
- None

**Outgoing:**
- None

## Claude Code Integration Points

**Slash Commands:**
- Location: `commands/gsd/*.md` (24 commands)
- Format: Markdown with YAML frontmatter
- Pattern: `---\nname: gsd:{command}\n---`

**Subagents:**
- Location: `agents/gsd-*.md` (11 agents)
- Spawned via Claude Code Task tool
- Examples: `gsd-executor`, `gsd-planner`, `gsd-verifier`

**Hooks:**
- SessionStart: `gsd-check-update.js` - Background version check
- Statusline: `statusline.js` - Display model, task, context usage

**Settings Integration:**
- Modifies: `~/.claude/settings.json`
- Adds: `hooks.SessionStart[]`, `statusLine` configuration

## File System Integrations

**Installation Targets:**
| Directory | Purpose |
|-----------|---------|
| `commands/gsd/` | Slash commands |
| `get-shit-done/` | Workflows, templates, references |
| `agents/` | Subagent definitions |
| `hooks/` | Session hooks, statusline |

**Runtime Artifacts (in user projects):**
| Path | Purpose |
|------|---------|
| `.planning/PROJECT.md` | Project vision |
| `.planning/ROADMAP.md` | Phase breakdown |
| `.planning/STATE.md` | Project memory |
| `.planning/config.json` | Workflow configuration |
| `.planning/phases/` | Plan and summary files |
| `.planning/codebase/` | Codebase analysis (brownfield) |

## Git Integration

**Commands Used:**
- `git status` - Check working tree state
- `git add` - Stage files (individual files only, never `-A` or `.`)
- `git commit` - Atomic commits per task
- `git diff` - Show changes
- `git log` - Commit history
- `git tag` - Milestone releases

**Commit Pattern:**
- Per-task: `{type}({phase}-{plan}): {task-name}`
- Per-plan: `docs({phase}-{plan}): complete [plan-name] plan`
- Per-phase: `docs({phase}): complete {phase-name} phase`

---

*Integration audit: 2025-01-19*
