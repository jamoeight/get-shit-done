# Technology Stack

**Analysis Date:** 2025-01-19

## Languages

**Primary:**
- JavaScript (Node.js) - All runtime code (`bin/install.js`, `hooks/*.js`)

**Secondary:**
- Markdown - Commands, agents, workflows, templates, documentation (`commands/`, `agents/`, `get-shit-done/`)

## Runtime

**Environment:**
- Node.js >= 16.7.0 (specified in `package.json` engines field)

**Package Manager:**
- npm (distributed via npx)
- Lockfile: Not committed (gitignored)

## Frameworks

**Core:**
- None - Pure Node.js with built-in modules only

**Testing:**
- None detected - No test framework configured

**Build/Dev:**
- None - No build step required; JavaScript files run directly

## Key Dependencies

**Critical:**
- Zero external dependencies - Package has no `dependencies` or `devDependencies`

**Node.js Built-in Modules Used:**
- `fs` - File system operations for installation and hooks
- `path` - Path manipulation across platforms
- `os` - Home directory detection, platform info
- `readline` - Interactive prompts during installation
- `child_process` - Spawning background processes (update checks)

## Configuration

**Environment:**
- `CLAUDE_CONFIG_DIR` - Optional override for Claude config location
- Supports tilde expansion (`~/`) for home directory paths

**Build:**
- No build configuration - Source files are runtime files
- `bin/install.js` - npx entry point (shebang: `#!/usr/bin/env node`)

## Platform Requirements

**Development:**
- Node.js >= 16.7.0
- Git (for atomic commits during execution)
- Claude Code CLI (target platform for integration)

**Production:**
- Same as development - Runs within Claude Code environment
- Cross-platform: Mac, Windows, Linux

## Package Distribution

**npm Package:**
- Name: `get-shit-done-cc`
- Version: 1.6.4
- Binary: `get-shit-done-cc` → `bin/install.js`
- Files included: `bin/`, `commands/`, `get-shit-done/`, `agents/`, `hooks/`

**Installation Modes:**
- Global: `~/.claude/` or custom via `CLAUDE_CONFIG_DIR`
- Local: `./.claude/` in project directory

---

*Stack analysis: 2025-01-19*
