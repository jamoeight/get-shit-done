# Coding Conventions

**Analysis Date:** 2026-01-19

## Naming Patterns

**Files:**
- kebab-case for markdown files: `execute-phase.md`, `new-project.md`, `gsd-executor.md`
- kebab-case for JavaScript files: `install.js`, `statusline.js`, `gsd-check-update.js`
- UPPERCASE.md for codebase analysis documents: `CONVENTIONS.md`, `TESTING.md`, `ARCHITECTURE.md`
- UPPERCASE.md for project artifacts: `ROADMAP.md`, `STATE.md`, `REQUIREMENTS.md`, `PROJECT.md`

**Commands (slash commands):**
- Pattern: `gsd:kebab-case` for all GSD commands
- Examples: `gsd:execute-phase`, `gsd:new-project`, `gsd:plan-phase`

**Frontmatter Fields:**
- kebab-case for multi-word fields: `argument-hint`, `allowed-tools`
- snake_case for step name attributes: `name="load_project_state"`, `name="execute_tasks"`

**Bash Variables:**
- UPPER_SNAKE_CASE for all bash variables: `PHASE_ARG`, `PLAN_START_TIME`, `TASK_COMMIT`

**JavaScript:**
- camelCase for functions and variables: `readSettings`, `writeSettings`, `expandTilde`
- camelCase for constants: `cyan`, `green`, `yellow`, `reset` (ANSI colors)
- PascalCase not used (no classes)

## Code Style

**Formatting:**
- No Prettier or ESLint configuration (meta-prompting system, not application code)
- JavaScript uses 2-space indentation
- Markdown uses standard formatting
- Single quotes in JavaScript strings

**Markdown Structure:**
- XML tags for semantic containers: `<objective>`, `<process>`, `<step>`, `<success_criteria>`
- Markdown headers within XML for hierarchy
- Code blocks use triple backticks with language hints

**XML Tag Conventions:**
- kebab-case for tag names: `<execution_context>`, `<deviation_rules>`
- kebab-case for type attributes: `type="checkpoint:human-verify"`
- snake_case for step name attributes: `name="load_project_state"`

## Import Organization

**JavaScript (Node.js):**
- Order: Built-in modules first, then relative paths
- Pattern:
  ```javascript
  const fs = require('fs');
  const path = require('path');
  const os = require('os');
  const readline = require('readline');
  ```

**Markdown @-references:**
- Static references (always load):
  ```
  @~/.claude/get-shit-done/workflows/execute-phase.md
  @.planning/PROJECT.md
  ```
- Conditional references (based on existence):
  ```
  @.planning/DISCOVERY.md (if exists)
  ```

## Error Handling

**JavaScript Patterns:**
- try/catch for file operations
- Silent fallback for missing files: `catch (e) { return {}; }`
- Exit with error code for critical failures: `process.exit(1)`
- User-facing errors printed with color: `console.error(\`  \${yellow}Error message\${reset}\`)`

**Plan Execution:**
- Deviation rules handle unexpected issues automatically
- Rule 1: Auto-fix bugs without user permission
- Rule 2: Auto-add missing critical functionality
- Rule 3: Auto-fix blocking issues
- Rule 4: Stop and ask about architectural changes

**Checkpoint Protocol:**
- Return structured checkpoint message for orchestrator
- Include completed tasks table with commit hashes
- Specify current task and blocker

## Logging

**Framework:**
- console.log for installer output
- No structured logging (not a service)

**Patterns:**
- Color-coded output using ANSI escape codes
- Checkmarks for success: `${green}+${reset}`
- Warnings with yellow: `${yellow}!${reset}`
- Progress indicators for long operations

## Comments

**When to Comment:**
- Explain why, not what
- Document deviation rules and when they apply
- Explain checkpoint flow and continuation handling

**Markdown Documentation:**
- Use `<step>` elements with name attributes for process steps
- Include examples within step definitions
- Use tables for quick reference

**TODO Comments:**
- Not used in production files
- Deviation rule 1 auto-fixes TODOs found during execution

## Function Design

**JavaScript:**
- Functions kept small and focused
- Helper functions extracted for reuse: `expandTilde`, `readSettings`, `writeSettings`
- Options parsed at top of script

**Workflow Design:**
- Steps have clear names and purposes
- Priority attribute for ordering: `priority="first"`
- Conditional execution with `<if mode="...">` blocks

## Module Design

**Slash Commands:**
- YAML frontmatter for metadata: name, description, argument-hint, allowed-tools
- Sections in order: objective, execution_context, context, process, success_criteria
- Delegate detailed logic to workflows

**Workflows:**
- No YAML frontmatter
- Domain-specific tags based on purpose
- Common patterns: `<purpose>`, `<process>`, `<step>`, `<verification>`

**Agents:**
- YAML frontmatter: name, description, tools, color
- Role definition in `<role>` tag
- Execution flow in `<execution_flow>` with nested steps

**Templates:**
- Start with `# [Name] Template` header
- Include `<template>` block with actual template content
- Examples and guidelines sections

**References:**
- Outer XML container matching filename concept
- Internal organization varies (semantic sub-containers, markdown headers)

## Language & Tone

**Imperative Voice:**
- DO: "Execute tasks", "Create file", "Read STATE.md"
- DON'T: "Execution is performed", "The file should be created"

**No Filler:**
- Absent: "Let me", "Just", "Simply", "Basically", "I'd be happy to"
- Present: Direct instructions, technical precision

**No Sycophancy:**
- Absent: "Great!", "Awesome!", "Excellent!", "I'd love to help"
- Present: Factual statements, verification results, direct answers

**Brevity with Substance:**
- Good: "JWT auth with refresh rotation using jose library"
- Bad: "Phase complete" or "Authentication implemented"

## Commit Conventions

**Format:**
```
{type}({phase}-{plan}): {description}
```

**Types:**
| Type | Use |
|------|-----|
| `feat` | New feature |
| `fix` | Bug fix |
| `test` | Tests only (TDD RED) |
| `refactor` | Code cleanup (TDD REFACTOR) |
| `docs` | Documentation/metadata |
| `chore` | Config/dependencies |

**Rules:**
- One commit per task during execution
- Stage files individually (never `git add .`)
- Include Co-Authored-By line for Claude

## Anti-Patterns (Banned)

**Enterprise Patterns:**
- Story points, sprint ceremonies, RACI matrices
- Human dev time estimates (days/weeks)
- Team coordination, knowledge transfer docs

**Temporal Language (in implementation docs):**
- DON'T: "We changed X to Y", "Previously", "No longer"
- DO: Describe current state only
- Exception: CHANGELOG.md, git commits

**Generic XML:**
- DON'T: `<section>`, `<item>`, `<content>`
- DO: Semantic purpose tags: `<objective>`, `<verification>`, `<action>`

**Vague Tasks:**
- DON'T: "Add authentication", "Implement auth"
- DO: Specific files, actions, verification, done criteria

---

*Convention analysis: 2026-01-19*
