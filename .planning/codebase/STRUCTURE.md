# Codebase Structure

**Analysis Date:** 2026-01-19

## Directory Layout

```
get-shit-done/
├── agents/                    # Subagent definitions for Task spawning
├── assets/                    # Visual assets (terminal.svg)
├── bin/                       # Installation scripts
├── commands/                  # Slash command definitions
│   └── gsd/                   # All /gsd:* commands
├── get-shit-done/             # Core system files (installed to ~/.claude/get-shit-done/)
│   ├── references/            # Deep documentation on concepts
│   ├── templates/             # Document templates
│   │   ├── codebase/          # Templates for codebase mapping docs
│   │   └── research-project/  # Templates for research outputs
│   └── workflows/             # Multi-step process definitions
├── hooks/                     # Claude Code hook scripts
├── .planning/                 # Project planning artifacts (gitignored)
│   └── codebase/              # Codebase analysis documents
├── CHANGELOG.md               # Version history
├── GSD-STYLE.md               # Contribution style guide
├── LICENSE                    # MIT license
├── package.json               # npm package manifest
└── README.md                  # User documentation
```

## Directory Purposes

**agents/**
- Purpose: Subagent system prompts spawned by Task tool
- Contains: Markdown files defining specialized agent roles
- Key files:
  - `gsd-executor.md` - Executes PLAN.md with atomic commits
  - `gsd-planner.md` - Creates PLAN.md from phase requirements
  - `gsd-verifier.md` - Verifies phase goal achievement
  - `gsd-codebase-mapper.md` - Analyzes existing codebase
  - `gsd-debugger.md` - Systematic debugging workflow
  - `gsd-roadmapper.md` - Creates ROADMAP.md from requirements
  - `gsd-project-researcher.md` - Domain research (stack, features, pitfalls)
  - `gsd-phase-researcher.md` - Phase-specific research
  - `gsd-plan-checker.md` - Validates plans before execution
  - `gsd-integration-checker.md` - Cross-phase integration verification

**bin/**
- Purpose: Installation and CLI entry points
- Contains: Node.js scripts
- Key files:
  - `install.js` - Main installer, copies files to .claude/, configures hooks

**commands/gsd/**
- Purpose: Slash command definitions for Claude Code
- Contains: Markdown files with YAML frontmatter
- Key files:
  - `new-project.md` - Full project initialization flow
  - `plan-phase.md` - Create PLAN.md for a phase
  - `execute-phase.md` - Execute all plans in a phase
  - `verify-work.md` - User acceptance testing
  - `progress.md` - Show current status
  - `help.md` - List all commands

**get-shit-done/references/**
- Purpose: Deep documentation on specific concepts
- Contains: Detailed guidance markdown files
- Key files:
  - `questioning.md` - Deep questioning techniques
  - `checkpoints.md` - Checkpoint types and usage
  - `tdd.md` - Test-driven development patterns
  - `ui-brand.md` - Visual output formatting
  - `verification-patterns.md` - How to verify work

**get-shit-done/templates/**
- Purpose: Document structure templates
- Contains: Templates with placeholders
- Key files:
  - `project.md` - PROJECT.md template
  - `state.md` - STATE.md template
  - `summary.md` - SUMMARY.md template
  - `roadmap.md` - ROADMAP.md template
  - `phase-prompt.md` - PLAN.md structure
  - `codebase/*.md` - Templates for codebase mapping docs

**get-shit-done/workflows/**
- Purpose: Multi-step process definitions
- Contains: Detailed workflow logic in XML structure
- Key files:
  - `execute-phase.md` - Wave-based parallel execution
  - `execute-plan.md` - Single plan execution with commits
  - `map-codebase.md` - Parallel codebase analysis orchestration
  - `verify-phase.md` - Phase goal verification
  - `discovery-phase.md` - Technology discovery workflow
  - `discuss-phase.md` - User context gathering
  - `transition.md` - Phase transition handling

**hooks/**
- Purpose: Claude Code runtime integrations
- Contains: Node.js scripts executed by Claude Code
- Key files:
  - `statusline.js` - Shows model, task, context usage
  - `gsd-check-update.js` - Checks for GSD updates on session start

## Key File Locations

**Entry Points:**
- `bin/install.js`: Installation script (npm entry)
- `commands/gsd/*.md`: All slash commands
- `hooks/statusline.js`: Statusline hook

**Configuration:**
- `package.json`: npm package manifest
- `get-shit-done/templates/config.json`: Project config template

**Core Logic:**
- `get-shit-done/workflows/*.md`: All workflow processes
- `agents/*.md`: All subagent definitions

**Testing:**
- Not applicable (markdown-based meta-prompting system)

## Naming Conventions

**Files:**
- Commands: `kebab-case.md` (e.g., `execute-phase.md`, `new-project.md`)
- Agents: `gsd-kebab-case.md` (e.g., `gsd-executor.md`, `gsd-planner.md`)
- Workflows: `kebab-case.md` (e.g., `execute-plan.md`, `map-codebase.md`)
- Templates: `kebab-case.md` (e.g., `project.md`, `state.md`)

**Directories:**
- Lowercase with hyphens (e.g., `get-shit-done/`, `research-project/`)
- Single-word lowercase (e.g., `agents/`, `hooks/`, `templates/`)

**Planning Artifacts (user projects):**
- Phase directories: `{NN}-{name}/` (e.g., `01-foundation/`, `02-auth/`)
- Plans: `{phase}-{plan}-PLAN.md` (e.g., `01-01-PLAN.md`)
- Summaries: `{phase}-{plan}-SUMMARY.md` (e.g., `01-01-SUMMARY.md`)
- Phase context: `{phase}-CONTEXT.md` (e.g., `01-CONTEXT.md`)
- Research: `{phase}-RESEARCH.md` (e.g., `01-RESEARCH.md`)

## Where to Add New Code

**New Slash Command:**
- Create: `commands/gsd/{command-name}.md`
- Include: YAML frontmatter (name, description, allowed-tools)
- Include: XML structure (objective, execution_context, context, process, success_criteria)
- Pattern: Delegate heavy work to workflows

**New Agent:**
- Create: `agents/gsd-{agent-name}.md`
- Include: YAML frontmatter (name, description, tools, color)
- Include: Role definition, execution flow, structured returns
- Pattern: Fresh context for heavy work, return structured results

**New Workflow:**
- Create: `get-shit-done/workflows/{workflow-name}.md`
- Include: Purpose, process steps, success criteria
- Pattern: XML structure with named steps

**New Template:**
- Create: `get-shit-done/templates/{template-name}.md`
- Include: Template block with placeholders
- Include: Guidelines section explaining usage

**New Reference:**
- Create: `get-shit-done/references/{concept-name}.md`
- Include: Deep documentation on the concept
- Pattern: Outer XML container, detailed examples

**New Hook:**
- Create: `hooks/{hook-name}.js`
- Include: Node.js script reading stdin JSON
- Register: Add to install.js settings.json configuration

## Special Directories

**.planning/ (in user projects):**
- Purpose: All project planning artifacts
- Generated: Yes (by GSD commands)
- Committed: Yes (recommended)
- Structure:
  ```
  .planning/
  ├── PROJECT.md
  ├── REQUIREMENTS.md
  ├── ROADMAP.md
  ├── STATE.md
  ├── config.json
  ├── codebase/          # From /gsd:map-codebase
  ├── research/          # From /gsd:new-project research
  ├── phases/            # Phase directories
  │   ├── 01-foundation/
  │   │   ├── 01-CONTEXT.md
  │   │   ├── 01-RESEARCH.md
  │   │   ├── 01-01-PLAN.md
  │   │   ├── 01-01-SUMMARY.md
  │   │   └── 01-VERIFICATION.md
  │   └── 02-auth/
  └── todos/             # Captured ideas
  ```

**~/.claude/ (global install):**
- Purpose: Claude Code user configuration
- Contains: GSD files after installation
- Structure:
  ```
  ~/.claude/
  ├── commands/gsd/      # Slash commands
  ├── agents/            # Subagent definitions
  ├── get-shit-done/     # Core system
  ├── hooks/             # Hook scripts
  └── settings.json      # Claude Code settings
  ```

**./.claude/ (local install):**
- Purpose: Project-specific Claude Code configuration
- Contains: Same as global but for one project only
- Generated: By install.js with --local flag
- Committed: Optional (enables project-specific GSD version)

---

*Structure analysis: 2026-01-19*
