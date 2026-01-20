# Testing Patterns

**Analysis Date:** 2026-01-19

## Test Framework

**Status:** No automated test framework configured

This is a meta-prompting system (markdown files + installer scripts), not an application with testable code. Testing happens through:
1. Manual verification of GSD workflows
2. Verification patterns embedded in plan execution
3. Structural verification by gsd-verifier agent

**No test runner, no test files, no coverage tools.**

## Verification Approach

Instead of unit tests, GSD uses goal-backward verification embedded in the execution workflow.

**Core Principle:**
> Existence does not equal Implementation

Verification checks four levels:
1. **Exists** - File is present at expected path
2. **Substantive** - Content is real implementation, not placeholder
3. **Wired** - Connected to the rest of the system
4. **Functional** - Actually works when invoked

Levels 1-3 verified programmatically. Level 4 often requires human verification.

## Verification Commands

**Phase Verification:**
```bash
/gsd:verify-work {phase}        # Verify a specific phase
/gsd:verify-work                # Verify current work
```

**Audit Milestone:**
```bash
/gsd:audit-milestone            # Full milestone audit
```

## Verification Patterns

**Stub Detection (Universal):**
```bash
# Comment-based stubs
grep -E "(TODO|FIXME|XXX|HACK|PLACEHOLDER)" "$file"
grep -E "implement|add later|coming soon|will be" "$file" -i

# Empty implementations
grep -E "return null|return undefined|return \{\}|return \[\]" "$file"

# Placeholder content
grep -E "placeholder|lorem ipsum|coming soon|under construction" "$file" -i
```

**React Component Verification:**
```bash
# Exists and exports component
grep -E "export (default |)function|export const.*=.*\(" "$component_path"

# Returns actual JSX, not placeholder
grep -E "return.*<" "$component_path" | grep -v "return.*null"

# Uses props or state (not static)
grep -E "props\.|useState|useEffect|useContext|\{.*\}" "$component_path"
```

**API Route Verification:**
```bash
# Exports HTTP method handlers
grep -E "export (async )?(function|const) (GET|POST|PUT|PATCH|DELETE)" "$route_path"

# Has actual logic
wc -l "$route_path"  # Should be >10-15 lines

# Interacts with data source
grep -E "prisma\.|db\.|mongoose\.|sql|query|find|create|update|delete" "$route_path" -i
```

**Wiring Verification:**
```bash
# Component calls API
grep -E "fetch\(['\"].*$api_path|axios\.(get|post).*$api_path" "$component"

# API queries database
grep -E "prisma\.$model|db\.$model|$model\.(find|create|update|delete)" "$route"
```

## Verification Agent

The `gsd-verifier` agent performs goal-backward verification:

**Location:** `~/.claude/agents/gsd-verifier.md`

**Purpose:** Verify phase goal achievement through goal-backward analysis

**Process:**
1. Load context from phase directory
2. Establish must-haves (from frontmatter or derived from goal)
3. Verify observable truths
4. Verify artifacts at three levels (exists, substantive, wired)
5. Verify key links (component->API, API->DB, form->handler)
6. Check requirements coverage
7. Scan for anti-patterns
8. Identify human verification needs
9. Determine overall status
10. Create VERIFICATION.md report

**Output:**
```markdown
---
phase: XX-name
verified: YYYY-MM-DDTHH:MM:SSZ
status: passed | gaps_found | human_needed
score: N/M must-haves verified
gaps: [structured gap analysis for planner]
---
```

## TDD Support

GSD supports Test-Driven Development for plans where it makes sense.

**When to Use TDD:**
- Business logic with defined inputs/outputs
- API endpoints with request/response contracts
- Data transformations, parsing, formatting
- Validation rules and constraints

**When to Skip TDD:**
- UI layout, styling, visual components
- Configuration changes
- Glue code connecting existing components
- Simple CRUD with no business logic

**TDD Plan Structure:**
```yaml
---
phase: XX-name
plan: NN
type: tdd
---
```

Plans with `type: tdd` follow RED-GREEN-REFACTOR cycle:
1. RED: Write failing test, commit: `test({phase}-{plan}): add failing test for [feature]`
2. GREEN: Implement to pass, commit: `feat({phase}-{plan}): implement [feature]`
3. REFACTOR: Clean up, commit: `refactor({phase}-{plan}): clean up [feature]`

**TDD Reference:** `~/.claude/get-shit-done/references/tdd.md`

## Human Verification Triggers

Some verifications require human testing:

**Always Human:**
- Visual appearance (does it look right?)
- User flow completion (can you do the full task?)
- Real-time behavior (WebSocket, SSE updates)
- External service integration (payments, email)
- Performance feel (does it feel fast?)
- Error message clarity

**Human if Uncertain:**
- Complex wiring that grep can't trace
- Dynamic behavior depending on state
- Edge cases and error states

**Format for Human Verification:**
```markdown
### 1. {Test Name}

**Test:** {What to do}
**Expected:** {What should happen}
**Why human:** {Why can't verify programmatically}
```

## Checkpoint Types

During plan execution, checkpoints pause for verification:

**checkpoint:human-verify (90%):**
- Visual/functional verification after automation
- User confirms: "approved" or describes issues

**checkpoint:decision (9%):**
- Implementation choices requiring user input
- Presents options with pros/cons

**checkpoint:human-action (1%):**
- Truly unavoidable manual steps (email link, 2FA)
- Provides exact steps and verification command

## Anti-Pattern Detection

Verification scans for these red flags:

**React Components:**
```javascript
// Stubs:
return <div>Component</div>
return <div>Placeholder</div>
return null
onClick={() => {}}
onChange={() => console.log('clicked')}
```

**API Routes:**
```typescript
// Stubs:
export async function POST() {
  return Response.json({ message: "Not implemented" })
}

export async function GET() {
  return Response.json([])  // Empty array with no DB query
}
```

**Wiring Red Flags:**
```typescript
// Fetch response ignored:
fetch('/api/messages')  // No await, no .then

// Query result not returned:
await prisma.message.findMany()
return Response.json({ ok: true })  // Static response
```

## Verification Checklist

**Component Checklist:**
- [ ] File exists at expected path
- [ ] Exports a function/const component
- [ ] Returns JSX (not null/empty)
- [ ] No placeholder text in render
- [ ] Uses props or state (not static)
- [ ] Event handlers have real implementations
- [ ] Used somewhere in the app

**API Route Checklist:**
- [ ] File exists at expected path
- [ ] Exports HTTP method handlers
- [ ] Handlers have more than 5 lines
- [ ] Queries database or service
- [ ] Returns meaningful response
- [ ] Has error handling
- [ ] Called from frontend

**Wiring Checklist:**
- [ ] Component -> API: fetch/axios call exists and uses response
- [ ] API -> Database: query exists and result returned
- [ ] Form -> Handler: onSubmit calls API/mutation
- [ ] State -> Render: state variables appear in JSX

## Coverage Requirements

**No Coverage Enforcement:**
- This is a meta-prompting system, not application code
- Verification happens through structural analysis and human testing
- Focus on goal achievement, not line coverage

**For Target Projects:**
- Coverage requirements documented in target project's TESTING.md
- GSD adapts to project's existing test patterns
- TDD plans produce tested code following project conventions

---

*Testing analysis: 2026-01-19*
