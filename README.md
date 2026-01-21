<div align="center">

# GET SHIT DONE 

**A light-weight and powerful meta-prompting, context engineering and spec-driven development system for Claude Code by TÂCHES.**

**Solves context rot — the quality degradation that happens as Claude fills its context window.**

[![npm version](https://img.shields.io/npm/v/get-shit-done-cc?style=for-the-badge&logo=npm&logoColor=white&color=CB3837)](https://www.npmjs.com/package/get-shit-done-cc)
[![npm downloads](https://img.shields.io/npm/dm/get-shit-done-cc?style=for-the-badge&logo=npm&logoColor=white&color=CB3837)](https://www.npmjs.com/package/get-shit-done-cc)
[![License](https://img.shields.io/badge/license-MIT-blue?style=for-the-badge)](LICENSE)
[![GitHub stars](https://img.shields.io/github/stars/glittercowboy/get-shit-done?style=for-the-badge&logo=github&color=181717)](https://github.com/glittercowboy/get-shit-done)

<br>

```bash
npx get-shit-done-cc
```

**Works on Mac, Windows, and Linux.**

<br>

![GSD Install](assets/terminal.svg)

<br>

*"If you know clearly what you want, this WILL build it for you. No bs."*

*"I've done SpecKit, OpenSpec and Taskmaster — this has produced the best results for me."*

*"By far the most powerful addition to my Claude Code. Nothing over-engineered. Literally just gets shit done."*

<br>

**Trusted by engineers at Amazon, Google, Shopify, and Webflow.**

[Why I Built This](#why-i-built-this) · [How It Works](#how-it-works) · [Commands](#commands) · [Why It Works](#why-it-works)

</div>

---

<div align="center">

## 🧪 Lazy Mode (Experimental)

**Fire and forget. Plan everything upfront, walk away, wake up to done.**

</div>

> [!WARNING]
> Lazy Mode is experimental. It works, but expect rough edges. Feedback welcome.

Lazy Mode flips the GSD workflow: instead of planning and executing phase-by-phase, you do **all planning in one session**, then let agents grind through execution autonomously.

### The Workflow

```
┌─────────────────────────────────────────────────────────────┐
│  YOU ARE HERE (planning session)                            │
│                                                             │
│  /gsd:lazy-mode          → Enable lazy mode                 │
│  /gsd:new-project        → Questions, research, roadmap     │
│  /gsd:plan-milestone-all → Generate ALL plans at once       │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│  WALK AWAY HERE ☕                                           │
│                                                             │
│  /gsd:autopilot          → Autonomous execution begins      │
│                                                             │
│  • Loops through all plans                                  │
│  • Fresh context per iteration                              │
│  • Commits after each success                               │
│  • Circuit breaker on repeated failures                     │
│  • Ctrl+C for graceful stop with resume                     │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│  WAKE UP TO DONE 🎉                                          │
│                                                             │
│  • All phases executed                                      │
│  • Clean git history                                        │
│  • Milestone complete                                       │
└─────────────────────────────────────────────────────────────┘
```

### Quick Start

```bash
# 1. Enable lazy mode
/gsd:lazy-mode

# 2. Initialize project (stay for this — ~15-30 min of questions + research)
/gsd:new-project

# 3. Generate all plans (stay for this — review and approve)
/gsd:plan-milestone-all

# 4. Walk away
/gsd:autopilot
```

### Commands

| Command | What it does |
|---------|--------------|
| `/gsd:lazy-mode` | Toggle between Interactive and Lazy mode |
| `/gsd:plan-milestone-all` | Generate ALL PLAN.md files in one session |
| `/gsd:autopilot` | Configure settings + start autonomous execution |

### Why Stay for Planning?

The "fire and forget" part starts at `/gsd:autopilot`. Before that, you're front-loading judgment:

- **Questions** — System needs to understand what you're building
- **Research** — AI investigates the domain so plans are informed
- **Roadmap review** — You approve the scope before execution
- **Plan generation** — You can refine plans before they run

This prevents waking up to "the AI built something I didn't want." Once you approve the plans, execution is mechanical — that's when you walk away.

---

## Why I Built This

I'm a solo developer. I don't write code — Claude Code does.

Other spec-driven development tools exist; BMAD, Speckit... But they all seem to make things way more complicated than they need to be (sprint ceremonies, story points, stakeholder syncs, retrospectives, Jira workflows) or lack real big picture understanding of what you're building. I'm not a 50-person software company. I don't want to play enterprise theater. I'm just a creative person trying to build great things that work.

So I built GSD. The complexity is in the system, not in your workflow. Behind the scenes: context engineering, XML prompt formatting, subagent orchestration, state management. What you see: a few commands that just work.

The system gives Claude everything it needs to do the work *and* verify it. I trust the workflow. It just does a good job.

That's what this is. No enterprise roleplay bullshit. Just an incredibly effective system for building cool stuff consistently using Claude Code.

— **TÂCHES**

---

Vibecoding has a bad reputation. You describe what you want, AI generates code, and you get inconsistent garbage that falls apart at scale.

GSD fixes that. It's the context engineering layer that makes Claude Code reliable. Describe your idea, let the system extract everything it needs to know, and let Claude Code get to work.

---

## Who This Is For

People who want to describe what they want and have it built correctly — without pretending they're running a 50-person engineering org.

---

## Getting Started

```bash
npx get-shit-done-cc
```

That's it. Verify with `/gsd:help` inside your Claude Code interface.

### Staying Updated

GSD evolves fast. Check for updates periodically:

```
/gsd:whats-new
```

Update with:

```bash
npx get-shit-done-cc@latest
```

<details>
<summary><strong>Non-interactive Install (Docker, CI, Scripts)</strong></summary>

```bash
npx get-shit-done-cc --global   # Install to ~/.claude/
npx get-shit-done-cc --local    # Install to ./.claude/
```

Use `--global` (`-g`) or `--local` (`-l`) to skip the interactive prompt.

</details>

<details>
<summary><strong>Development Installation</strong></summary>

Clone the repository and run the installer locally:

```bash
git clone https://github.com/glittercowboy/get-shit-done.git
cd get-shit-done
node bin/install.js --local
```

Installs to `./.claude/` for testing modifications before contributing.

</details>

### Recommended: Skip Permissions Mode

GSD is designed for frictionless automation. Run Claude Code with:

```bash
claude --dangerously-skip-permissions
```

> [!TIP]
> This is how GSD is intended to be used — stopping to approve `date` and `git commit` 50 times defeats the purpose.

<details>
<summary><strong>Alternative: Granular Permissions</strong></summary>

If you prefer not to use that flag, add this to your project's `.claude/settings.json`:

```json
{
  "permissions": {
    "allow": [
      "Bash(date:*)",
      "Bash(echo:*)",
      "Bash(cat:*)",
      "Bash(ls:*)",
      "Bash(mkdir:*)",
      "Bash(wc:*)",
      "Bash(head:*)",
      "Bash(tail:*)",
      "Bash(sort:*)",
      "Bash(grep:*)",
      "Bash(tr:*)",
      "Bash(git add:*)",
      "Bash(git commit:*)",
      "Bash(git status:*)",
      "Bash(git log:*)",
      "Bash(git diff:*)",
      "Bash(git tag:*)"
    ]
  }
}
```

</details>

---

## How It Works

> **Already have code?** Run `/gsd:map-codebase` first. It spawns parallel agents to analyze your stack, architecture, conventions, and concerns. Then `/gsd:new-project` knows your codebase — questions focus on what you're adding, and planning automatically loads your patterns.

### 1. Initialize Project

```
/gsd:new-project
```

One command, one flow. The system:

1. **Questions** — Asks until it understands your idea completely (goals, constraints, tech preferences, edge cases)
2. **Research** — Spawns parallel agents to investigate the domain (optional but recommended)
3. **Requirements** — Extracts what's v1, v2, and out of scope
4. **Roadmap** — Creates phases mapped to requirements

You approve the roadmap. Now you're ready to build.

**Creates:** `PROJECT.md`, `REQUIREMENTS.md`, `ROADMAP.md`, `STATE.md`, `.planning/research/`

---

### 2. Discuss Phase

```
/gsd:discuss-phase 1
```

**This is where you shape the implementation.**

Your roadmap has a sentence or two per phase. That's not enough context to build something the way *you* imagine it. This step captures your preferences before anything gets researched or planned.

The system analyzes the phase and identifies gray areas based on what's being built:

- **Visual features** → Layout, density, interactions, empty states
- **APIs/CLIs** → Response format, flags, error handling, verbosity
- **Content systems** → Structure, tone, depth, flow
- **Organization tasks** → Grouping criteria, naming, duplicates, exceptions

For each area you select, it asks until you're satisfied. The output — `CONTEXT.md` — feeds directly into the next two steps:

1. **Researcher reads it** — Knows what patterns to investigate ("user wants card layout" → research card component libraries)
2. **Planner reads it** — Knows what decisions are locked ("infinite scroll decided" → plan includes scroll handling)

The deeper you go here, the more the system builds what you actually want. Skip it and you get reasonable defaults. Use it and you get *your* vision.

**Creates:** `{phase}-CONTEXT.md`

---

### 3. Plan Phase

```
/gsd:plan-phase 1
```

The system:

1. **Researches** — Investigates how to implement this phase, guided by your CONTEXT.md decisions
2. **Plans** — Creates 2-3 atomic task plans with XML structure
3. **Verifies** — Checks plans against requirements, loops until they pass

Each plan is small enough to execute in a fresh context window. No degradation, no "I'll be more concise now."

**Creates:** `{phase}-RESEARCH.md`, `{phase}-{N}-PLAN.md`

---

### 4. Execute Phase

```
/gsd:execute-phase 1
```

The system:

1. **Runs plans in waves** — Parallel where possible, sequential when dependent
2. **Fresh context per plan** — 200k tokens purely for implementation, zero accumulated garbage
3. **Commits per task** — Every task gets its own atomic commit
4. **Verifies against goals** — Checks the codebase delivers what the phase promised

Walk away, come back to completed work with clean git history.

**Creates:** `{phase}-{N}-SUMMARY.md`, `{phase}-VERIFICATION.md`

---

### 5. Verify Work

```
/gsd:verify-work 1
```

**This is where you confirm it actually works.**

Automated verification checks that code exists and tests pass. But does the feature *work* the way you expected? This is your chance to use it.

The system:

1. **Extracts testable deliverables** — What you should be able to do now
2. **Walks you through one at a time** — "Can you log in with email?" Yes/no, or describe what's wrong
3. **Diagnoses failures automatically** — Spawns debug agents to find root causes
4. **Creates verified fix plans** — Ready for immediate re-execution

If everything passes, you move on. If something's broken, you don't manually debug — you just run `/gsd:execute-phase` again with the fix plans it created.

**Creates:** `{phase}-UAT.md`, fix plans if issues found

---

### 6. Repeat → Complete → Next Milestone

```
/gsd:discuss-phase 2
/gsd:plan-phase 2
/gsd:execute-phase 2
/gsd:verify-work 2
...
/gsd:complete-milestone
/gsd:new-milestone
```

Loop **discuss → plan → execute → verify** until milestone complete.

Each phase gets your input (discuss), proper research (plan), clean execution (execute), and human verification (verify). Context stays fresh. Quality stays high.

When all phases are done, `/gsd:complete-milestone` archives the milestone and tags the release.

Then `/gsd:new-milestone` starts the next version — same flow as `new-project` but for your existing codebase. You describe what you want to build next, the system researches the domain, you scope requirements, and it creates a fresh roadmap. Each milestone is a clean cycle: define → build → ship.

---

### Quick Mode

```
/gsd:quick
```

**For ad-hoc tasks that don't need full planning.**

Quick mode gives you GSD guarantees (atomic commits, state tracking) with a faster path:

- **Same agents** — Planner + executor, same quality
- **Skips optional steps** — No research, no plan checker, no verifier
- **Separate tracking** — Lives in `.planning/quick/`, not phases

Use for: bug fixes, small features, config changes, one-off tasks.

```
/gsd:quick
> What do you want to do? "Add dark mode toggle to settings"
```

**Creates:** `.planning/quick/001-add-dark-mode-toggle/PLAN.md`, `SUMMARY.md`

---

## Why It Works

### Codebase Intelligence

GSD learns your codebase patterns automatically. As Claude writes code, a PostToolUse hook indexes exports and imports, detects naming conventions, and builds a semantic understanding of your codebase.

**How it works:**

1. **Automatic learning** — Every time Claude writes or edits a JS/TS file, the hook extracts exports/imports and updates `.planning/intel/index.json`
2. **Convention detection** — Analyzes exports for naming patterns (camelCase, PascalCase, etc.), identifies directory purposes, detects file suffixes
3. **Graph database** — Stores entity relationships in SQLite for dependency analysis
4. **Context injection** — At session start, injects a summary into Claude's context so it knows your codebase structure and conventions

**For existing codebases:**

```
/gsd:analyze-codebase
```

Performs a bulk scan of your codebase to bootstrap the intelligence layer. Works standalone — no `/gsd:new-project` required. After initial analysis, hooks continue incremental learning.

**Query the graph:**

```
/gsd:query-intel dependents src/lib/db.ts   # What depends on this file?
/gsd:query-intel hotspots                    # Most-depended-on files
```

**Files created:**

| File | Purpose |
|------|---------|
| `.planning/intel/index.json` | File exports and imports index |
| `.planning/intel/conventions.json` | Detected patterns (naming, directories, suffixes) |
| `.planning/intel/graph.db` | SQLite database with entity relationships |
| `.planning/intel/summary.md` | Concise context for session injection |

**Benefits:**

- Claude follows your naming conventions automatically
- New files go in the right directories
- Consistency maintained across sessions
- Query blast radius before refactoring
- Identify high-impact hotspot files
- No manual documentation of patterns needed

### Context Engineering

Claude Code is incredibly powerful *if* you give it the context it needs. Most people don't.

GSD handles it for you:

| File | What it does |
|------|--------------|
| `PROJECT.md` | Project vision, always loaded |
| `research/` | Ecosystem knowledge (stack, features, architecture, pitfalls) |
| `REQUIREMENTS.md` | Scoped v1/v2 requirements with phase traceability |
| `ROADMAP.md` | Where you're going, what's done |
| `STATE.md` | Decisions, blockers, position — memory across sessions |
| `PLAN.md` | Atomic task with XML structure, verification steps |
| `SUMMARY.md` | What happened, what changed, committed to history |
| `todos/` | Captured ideas and tasks for later work |

Size limits based on where Claude's quality degrades. Stay under, get consistent excellence.

### XML Prompt Formatting

Every plan is structured XML optimized for Claude:

```xml
<task type="auto">
  <name>Create login endpoint</name>
  <files>src/app/api/auth/login/route.ts</files>
  <action>
    Use jose for JWT (not jsonwebtoken - CommonJS issues).
    Validate credentials against users table.
    Return httpOnly cookie on success.
  </action>
  <verify>curl -X POST localhost:3000/api/auth/login returns 200 + Set-Cookie</verify>
  <done>Valid credentials return cookie, invalid return 401</done>
</task>
```

Precise instructions. No guessing. Verification built in.

### Multi-Agent Orchestration

Every stage uses the same pattern: a thin orchestrator spawns specialized agents, collects results, and routes to the next step.

| Stage | Orchestrator does | Agents do |
|-------|------------------|-----------|
| Research | Coordinates, presents findings | 4 parallel researchers investigate stack, features, architecture, pitfalls |
| Planning | Validates, manages iteration | Planner creates plans, checker verifies, loop until pass |
| Execution | Groups into waves, tracks progress | Executors implement in parallel, each with fresh 200k context |
| Verification | Presents results, routes next | Verifier checks codebase against goals, debuggers diagnose failures |

The orchestrator never does heavy lifting. It spawns agents, waits, integrates results.

**The result:** You can run an entire phase — deep research, multiple plans created and verified, thousands of lines of code written across parallel executors, automated verification against goals — and your main context window stays at 30-40%. The work happens in fresh subagent contexts. Your session stays fast and responsive.

### Atomic Git Commits

Each task gets its own commit immediately after completion:

```bash
abc123f docs(08-02): complete user registration plan
def456g feat(08-02): add email confirmation flow
hij789k feat(08-02): implement password hashing
lmn012o feat(08-02): create registration endpoint
```

> [!NOTE]
> **Benefits:** Git bisect finds exact failing task. Each task independently revertable. Clear history for Claude in future sessions. Better observability in AI-automated workflow.

Every commit is surgical, traceable, and meaningful.

### Modular by Design

- Add phases to current milestone
- Insert urgent work between phases
- Complete milestones and start fresh
- Adjust plans without rebuilding everything

You're never locked in. The system adapts.

---

## Commands

### Core Workflow

| Command | What it does |
|---------|--------------|
| `/gsd:new-project` | Full initialization: questions → research → requirements → roadmap |
| `/gsd:discuss-phase [N]` | Capture implementation decisions before planning |
| `/gsd:plan-phase [N]` | Research + plan + verify for a phase |
| `/gsd:execute-phase <N>` | Execute all plans in parallel waves, verify when complete |
| `/gsd:verify-work [N]` | Manual user acceptance testing ¹ |
| `/gsd:audit-milestone` | Verify milestone achieved its definition of done |
| `/gsd:complete-milestone` | Archive milestone, tag release |
| `/gsd:new-milestone [name]` | Start next version: questions → research → requirements → roadmap |

### Navigation

| Command | What it does |
|---------|--------------|
| `/gsd:progress` | Where am I? What's next? |
| `/gsd:help` | Show all commands and usage guide |
| `/gsd:whats-new` | See what changed since your installed version |
| `/gsd:update` | Update GSD with changelog preview |

### Brownfield

| Command | What it does |
|---------|--------------|
| `/gsd:map-codebase` | Analyze existing codebase before new-project |
| `/gsd:analyze-codebase` | Bootstrap codebase intelligence for existing projects |
| `/gsd:query-intel <type>` | Query dependency graph (dependents, hotspots) |

### Phase Management

| Command | What it does |
|---------|--------------|
| `/gsd:add-phase` | Append phase to roadmap |
| `/gsd:insert-phase [N]` | Insert urgent work between phases |
| `/gsd:remove-phase [N]` | Remove future phase, renumber |
| `/gsd:list-phase-assumptions [N]` | See Claude's intended approach before planning |
| `/gsd:plan-milestone-gaps` | Create phases to close gaps from audit |

### Session

| Command | What it does |
|---------|--------------|
| `/gsd:pause-work` | Create handoff when stopping mid-phase |
| `/gsd:resume-work` | Restore from last session |

### Utilities

| Command | What it does |
|---------|--------------|
| `/gsd:settings` | Configure model profile and workflow agents |
| `/gsd:set-profile <profile>` | Switch model profile (quality/balanced/budget) |
| `/gsd:add-todo [desc]` | Capture idea for later |
| `/gsd:check-todos` | List pending todos |
| `/gsd:debug [desc]` | Systematic debugging with persistent state |
| `/gsd:quick` | Execute ad-hoc task with GSD guarantees |

<sup>¹ Contributed by reddit user OracleGreyBeard</sup>

---

## Configuration

GSD stores project settings in `.planning/config.json`. Configure during `/gsd:new-project` or update later with `/gsd:settings`.

### Core Settings

| Setting | Options | Default | What it controls |
|---------|---------|---------|------------------|
| `mode` | `yolo`, `interactive` | `interactive` | Auto-approve vs confirm at each step |
| `depth` | `quick`, `standard`, `comprehensive` | `standard` | Planning thoroughness (phases × plans) |

### Model Profiles

Control which Claude model each agent uses. Balance quality vs token spend.

| Profile | Planning | Execution | Verification |
|---------|----------|-----------|--------------|
| `quality` | Opus | Opus | Sonnet |
| `balanced` (default) | Opus | Sonnet | Sonnet |
| `budget` | Sonnet | Sonnet | Haiku |

Switch profiles:
```
/gsd:set-profile budget
```

Or configure via `/gsd:settings`.

### Workflow Agents

These spawn additional agents during planning/execution. They improve quality but add tokens and time.

| Setting | Default | What it does |
|---------|---------|--------------|
| `workflow.research` | `true` | Researches domain before planning each phase |
| `workflow.plan_check` | `true` | Verifies plans achieve phase goals before execution |
| `workflow.verifier` | `true` | Confirms must-haves were delivered after execution |

Use `/gsd:settings` to toggle these, or override per-invocation:
- `/gsd:plan-phase --skip-research`
- `/gsd:plan-phase --skip-verify`

### Execution

| Setting | Default | What it controls |
|---------|---------|------------------|
| `parallelization.enabled` | `true` | Run independent plans simultaneously |
| `planning.commit_docs` | `true` | Track `.planning/` in git |

---

## Troubleshooting

**Commands not found after install?**
- Restart Claude Code to reload slash commands
- Verify files exist in `~/.claude/commands/gsd/` (global) or `./.claude/commands/gsd/` (local)

**Commands not working as expected?**
- Run `/gsd:help` to verify installation
- Re-run `npx get-shit-done-cc` to reinstall

**Updating to the latest version?**
```bash
npx get-shit-done-cc@latest
```

**Using Docker or containerized environments?**

If file reads fail with tilde paths (`~/.claude/...`), set `CLAUDE_CONFIG_DIR` before installing:
```bash
CLAUDE_CONFIG_DIR=/home/youruser/.claude npx get-shit-done-cc --global
```
This ensures absolute paths are used instead of `~` which may not expand correctly in containers.

---

## Star History

<a href="https://star-history.com/#glittercowboy/get-shit-done&Date">
 <picture>
   <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/svg?repos=glittercowboy/get-shit-done&type=Date&theme=dark" />
   <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/svg?repos=glittercowboy/get-shit-done&type=Date" />
   <img alt="Star History Chart" src="https://api.star-history.com/svg?repos=glittercowboy/get-shit-done&type=Date" />
 </picture>
</a>

---

## License

MIT License. See [LICENSE](LICENSE) for details.

---

<div align="center">

**Claude Code is powerful. GSD makes it reliable.**

</div>
