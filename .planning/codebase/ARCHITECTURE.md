# Architecture

**Analysis Date:** 2026-01-19

## Pattern Overview

**Overall:** Meta-Prompting System with Orchestrator-Agent Architecture

**Key Characteristics:**
- Commands are thin wrappers delegating to workflows
- Workflows orchestrate specialized subagents for heavy work
- State persists in markdown files (`.planning/`)
- Claude's context window treated as finite resource
- Plans are executable prompts, not documents to transform

## Layers

**Commands Layer:**
- Purpose: Entry points for user interaction via slash commands
- Location: `commands/gsd/*.md`
- Contains: YAML frontmatter + XML-structured instructions
- Depends on: Workflows, templates, references
- Used by: Claude Code slash command system

**Agents Layer:**
- Purpose: Specialized subagent definitions with role-specific behavior
- Location: `agents/gsd-*.md`
- Contains: Role definitions, execution flows, success criteria
- Depends on: Workflows, templates
- Used by: Task tool for subagent spawning

**Workflows Layer:**
- Purpose: Detailed process logic for multi-step operations
- Location: `get-shit-done/workflows/*.md`
- Contains: Step-by-step processes with XML structure
- Depends on: Templates, references
- Used by: Commands and agents

**Templates Layer:**
- Purpose: File structure definitions with placeholders
- Location: `get-shit-done/templates/*.md`
- Contains: Document templates for project artifacts
- Depends on: Nothing (leaf nodes)
- Used by: Workflows, agents

**References Layer:**
- Purpose: Deep documentation on specific concepts
- Location: `get-shit-done/references/*.md`
- Contains: Guidelines, patterns, rules
- Depends on: Nothing (leaf nodes)
- Used by: Commands, workflows, agents

**Hooks Layer:**
- Purpose: Runtime integrations with Claude Code
- Location: `hooks/*.js`
- Contains: Node.js scripts for statusline, update checking
- Depends on: Node.js fs/path modules
- Used by: Claude Code settings.json

## Data Flow

**Command Execution Flow:**

1. User invokes `/gsd:command-name`
2. Command reads context (@-references to workflows, templates)
3. Command delegates to workflow for process logic
4. Workflow spawns subagents via Task tool
5. Subagents execute with fresh 200k context each
6. Results written to `.planning/` directory
7. Control returns to orchestrator
8. User sees completion + next steps

**Subagent Orchestration Flow:**

```
Orchestrator (main context, ~15% usage)
    |
    +-- spawn --> Subagent 1 (fresh 200k context)
    +-- spawn --> Subagent 2 (fresh 200k context)
    +-- spawn --> Subagent 3 (fresh 200k context)
    |
    <-- collect results (SUMMARY.md files, confirmations)
    |
    Present completion to user
```

**State Management Flow:**

```
PROJECT.md (vision, requirements, constraints)
    |
    v
ROADMAP.md (phases, goals, success criteria)
    |
    v
STATE.md (position, progress, session memory)
    |
    v
PLAN.md files (executable prompts per phase)
    |
    v
SUMMARY.md files (execution results, decisions)
```

## Key Abstractions

**Slash Commands:**
- Purpose: User-facing entry points
- Examples: `commands/gsd/new-project.md`, `commands/gsd/execute-phase.md`
- Pattern: YAML frontmatter (name, description, allowed-tools) + XML body (objective, context, process, success_criteria)

**Subagents:**
- Purpose: Specialized workers with dedicated context
- Examples: `agents/gsd-executor.md`, `agents/gsd-planner.md`, `agents/gsd-verifier.md`
- Pattern: Role definition, execution flow, deviation rules, structured returns

**PLAN.md Files:**
- Purpose: Executable prompts for implementation
- Examples: `.planning/phases/01-foundation/01-01-PLAN.md`
- Pattern: Frontmatter (wave, depends_on, must_haves) + tasks with XML structure

**SUMMARY.md Files:**
- Purpose: Execution results with dependency graph
- Examples: `.planning/phases/01-foundation/01-01-SUMMARY.md`
- Pattern: Frontmatter (requires, provides, affects) + accomplishments, commits, decisions

## Entry Points

**Installation Entry:**
- Location: `bin/install.js`
- Triggers: `npx get-shit-done-cc` command
- Responsibilities: Copy files to ~/.claude/ or ./.claude/, configure settings.json, set up hooks

**Command Entry:**
- Location: `commands/gsd/*.md`
- Triggers: User typing `/gsd:command-name` in Claude Code
- Responsibilities: Parse arguments, validate state, delegate to workflow

**Hook Entry:**
- Location: `hooks/statusline.js`
- Triggers: Claude Code statusline refresh
- Responsibilities: Display model, current task, context usage

## Error Handling

**Strategy:** Graceful degradation with user prompting

**Patterns:**
- Missing files: Check existence, offer to create or abort
- Subagent failures: Detect missing SUMMARY.md, report and ask user
- Context limit: Plans designed for ~50% context, split if needed
- Checkpoint failures: Structured return to orchestrator, user decides next step

## Cross-Cutting Concerns

**Logging:** Markdown-based artifacts (SUMMARY.md, STATE.md) serve as execution logs

**Validation:** Commands validate environment before proceeding (check .planning/, check git, check phase exists)

**Authentication:** Authentication gates handled by executor via checkpoint returns (e.g., CLI auth needed)

**Context Management:** Quality degradation curve (0-30% peak, 30-50% good, 50-70% degrading, 70%+ poor) drives plan sizing

---

*Architecture analysis: 2026-01-19*
