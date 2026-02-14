# ThoughtForge Pipeline Tool — Build Spec

> **Companion to:** [ThoughtForge Design Specification](./thoughtforge-design-specification.md) | [ThoughtForge Execution Plan](./thoughtforge-execution-plan.md)
>
> **Purpose:** Implementation reference for AI coders. Contains schemas, prompts, function signatures, file structures, and configuration templates extracted from the design specification. The design spec describes *what* each component does and *why*. This document provides the *how*.

---

## Prompt File Directory

**Used by:** Task 7b (prompt management UI), all tasks that invoke AI agents

All pipeline prompts are stored as external `.md` files in `/prompts/`. The orchestrator reads prompts from this directory at invocation time — never from embedded strings. The Settings UI in the chat interface reads from and writes to these files.

```
/prompts/
  brain-dump-intake.md      # Phase 1: distillation prompt
  plan-review.md            # Phase 4: plan mode review prompt
  code-review.md            # Phase 4: code mode review prompt
  plan-fix.md               # Phase 4: plan mode fix prompt
  code-fix.md               # Phase 4: code mode fix prompt
  spec-building.md          # Phase 2: spec and constraint discovery prompt
  completeness-gate.md      # Plan completeness assessment for Code mode entry
  plan-build.md             # Phase 3: plan mode document drafting prompt
  code-build.md             # Phase 3: code mode build prompt
```

New prompts added to this directory are automatically picked up by the Settings UI.

---

## Phase 1 System Prompt — Brain Dump Intake

**File:** `/prompts/brain-dump-intake.md`
**Used by:** Task 8 (Phase 1 brain dump intake)
**Called via:** Agent invocation layer (Tasks 41–42)

```
You are receiving a raw brain dump from a human. It will be messy, incomplete,
and possibly contradictory. That's expected.

Your job is to eat everything they gave you — text, files, resources — and
produce a single structured document with these sections:

1. DELIVERABLE TYPE — Is the human asking for a Plan (a document: strategy,
   event plan, engineering design, etc.) or Code (working software)? State
   which one and why you think so.
2. OBJECTIVE — What does the human want to exist when this is done? State it plainly.
3. ASSUMPTIONS — What does the human seem to believe is true that hasn't been
   verified? Flag anything you're inferring, not just what they stated.
4. CONSTRAINTS — Any limitations they mentioned: OS, language, tools, budget,
   timeline, "only this," "not that."
5. UNKNOWNS — What hasn't been addressed but needs to be decided before building?
   These are the gaps.
6. OPEN QUESTIONS — Things you genuinely don't understand from the brain dump.
   Ask them here. Maximum 5 questions. If you have more than 5, pick the 5
   that block the most progress.

Rules:
- Do not add your own ideas, suggestions, or improvements. Only organize what
  the human gave you.
- If something is ambiguous, put it in UNKNOWNS with a note about what's unclear.
- Keep each section short. Bullet points are fine.
- Do not say "great idea" or "interesting concept." Just organize.
```

---

## Phase 2 System Prompt — Spec Building

**File:** `/prompts/spec-building.md`
**Used by:** Task 12 (Phase 2 spec building)
**Called via:** Agent invocation layer (Tasks 41–42)

**Status:** To be drafted by the AI coder as the first step of the task that depends on this prompt (see "Used by" reference above). The human reviews and edits via the Settings UI after initial draft.

---

## Phase 4 System Prompt — Plan Review

**File:** `/prompts/plan-review.md`
**Used by:** Task 30 (polish loop orchestrator, Plan mode)
**Called via:** Agent invocation layer (Tasks 41–42)

**Status:** To be drafted by the AI coder as the first step of the task that depends on this prompt (see "Used by" reference above). The human reviews and edits via the Settings UI after initial draft.

---

## Phase 4 System Prompt — Code Review

**File:** `/prompts/code-review.md`
**Used by:** Task 30 (polish loop orchestrator, Code mode)
**Called via:** Agent invocation layer (Tasks 41–42)

**Status:** To be drafted by the AI coder as the first step of the task that depends on this prompt (see "Used by" reference above). The human reviews and edits via the Settings UI after initial draft.

---

## Phase 4 System Prompt — Plan Fix

**File:** `/prompts/plan-fix.md`
**Used by:** Task 30 (polish loop orchestrator, Plan mode)
**Called via:** Agent invocation layer (Tasks 41–42)

**Status:** To be drafted by the AI coder as the first step of the task that depends on this prompt (see "Used by" reference above). The human reviews and edits via the Settings UI after initial draft.

---

## Phase 4 System Prompt — Code Fix

**File:** `/prompts/code-fix.md`
**Used by:** Task 30 (polish loop orchestrator, Code mode)
**Called via:** Agent invocation layer (Tasks 41–42)

**Status:** To be drafted by the AI coder as the first step of the task that depends on this prompt (see "Used by" reference above). The human reviews and edits via the Settings UI after initial draft.

---

## Plan Completeness Gate Prompt

**File:** `/prompts/completeness-gate.md`
**Used by:** Task 19 (Plan Completeness Gate)
**Called via:** Agent invocation layer (Tasks 41–42)

**Status:** To be drafted by the AI coder as the first step of the task that depends on this prompt (see "Used by" reference above). The human reviews and edits via the Settings UI after initial draft.

---

## Phase 3 System Prompt — Plan Build

**File:** `/prompts/plan-build.md`
**Used by:** Task 15 (plan builder)
**Called via:** Agent invocation layer (Tasks 41–42)

**Status:** To be drafted by the AI coder as the first step of the task that depends on this prompt (see "Used by" reference above). The human reviews and edits via the Settings UI after initial draft.

---

## Phase 3 System Prompt — Code Build

**File:** `/prompts/code-build.md`
**Used by:** Task 21 (code builder)
**Called via:** Agent invocation layer (Tasks 41–42)

**Status:** To be drafted by the AI coder as the first step of the task that depends on this prompt (see "Used by" reference above). The human reviews and edits via the Settings UI after initial draft.

---

## Plugin Folder Structure

**Used by:** Task 6 (plugin loader), Tasks 14–19 (plan plugin), Tasks 20–25 (code plugin)

```
/plugins/
  plan/
    builder.js        # Phase 3: template-driven document drafting
    reviewer.js       # Phase 4: review schema (Zod) and severity definitions
    safety-rules.js   # Blocked operations (no code execution, no source files)
    discovery.js      # Phase 2: (optional) plan-type-specific discovery logic
    templates/        # OPA templates per plan type (wedding, strategy, engineering, etc.)
      generic.hbs     # Default fallback template
      wedding.hbs
      strategy.hbs
      engineering.hbs
  code/
    builder.js        # Phase 3: agent-driven coding, test writing, logging
    reviewer.js       # Phase 4: review schema (Zod) and severity definitions
    safety-rules.js   # Code mode permissions and constraints
    test-runner.js    # Test execution logic
    discovery.js      # Phase 2: OSS qualification scorecard (Task 25)
```

---

## Plugin Interface Contract

**Used by:** Tasks 6, 15, 17, 18, 21, 22, 23, 24, 25

### builder.js

- `build(projectPath, intent, spec, constraints, agent)` → `Promise<BuildResult>`

Return type varies by plugin:
- **Plan plugin** returns `Promise<{ stuck: boolean, reason?: string, content?: string }>` — matches `PlanBuilderResponse` schema. Orchestrator checks `stuck` flag to detect stuck condition.
- **Code plugin** returns `Promise<{ stuck: boolean, reason?: string }>` — orchestrator detects stuck via the `stuck` flag (set after 2 consecutive non-zero exits on the same task, or 3 consecutive identical test failures).

### reviewer.js

- `schema` → Zod schema object for validating review JSON
- `severityDefinitions` → object defining critical/medium/minor for this type
- `review(projectPath, constraints, agent, testResults?)` → `Promise<object>` — one review pass, raw parsed JSON. `testResults` is an optional parameter (required for Code mode, omitted for Plan mode) containing the structured output from `test-runner.js`. Orchestrator validates via `schema.safeParse()`, retries on failure, halts after max retries.

### safety-rules.js

- `blockedOperations` → `string[]` (e.g., `["shell_exec", "file_create_source", "package_install"]` for Plan mode)
- `validate(operation)` → `{ allowed: boolean, reason?: string }` — called by orchestrator before every Phase 3/4 action.

### discovery.js (optional)

- `discover(intent, constraints)` → `Promise<object>` — Phase 2 hook for type-specific discovery logic. Code plugin uses this for OSS qualification scorecard. Plan plugin may omit this file. If the file is absent, the plugin loader skips it.

### test-runner.js

- `runTests(projectPath)` → `Promise<{ total: number, passed: number, failed: number, details: string }>` — Executes all tests in the project, returns structured results. The `details` field contains raw test runner output for inclusion in review context. Called by the orchestrator before each Phase 4 Code mode review step, and during Phase 3 Code mode build iteration.

---

## Zod Review Schemas

**Used by:** Tasks 17 (plan reviewer), 22 (code reviewer), 30–31 (polish loop orchestrator)

### Code Mode (`/plugins/code/reviewer.js`)

```javascript
const CodeReviewSchema = z.object({
  critical: z.number().int().min(0),
  medium: z.number().int().min(0),
  minor: z.number().int().min(0),
  tests: z.object({
    total: z.number().int().min(0),
    passed: z.number().int().min(0),
    failed: z.number().int().min(0),
  }),
  issues: z.array(z.object({
    severity: z.enum(['critical', 'medium', 'minor']),
    description: z.string(),
    location: z.string(),
    recommendation: z.string(),
  })),
});
```

### Plan Mode (`/plugins/plan/reviewer.js`)

```javascript
const PlanReviewSchema = z.object({
  critical: z.number().int().min(0),
  medium: z.number().int().min(0),
  minor: z.number().int().min(0),
  issues: z.array(z.object({
    severity: z.enum(['critical', 'medium', 'minor']),
    description: z.string(),
    location: z.string(),
    recommendation: z.string(),
  })),
});
```

### Validation Flow

Parse AI response as JSON → validate via `schema.safeParse()` → on failure: Zod returns structured error messages → retry (max configurable via `config.yaml` `polish.retry_malformed_output`, default 2) → on repeated failure: halt and notify human.

### Count Derivation

The orchestrator ignores top-level count fields (`critical`, `medium`, `minor`) in the review JSON. It derives all counts from the `issues` array by counting per severity. Top-level counts remain in the schema for human readability in logs only and must not be used for convergence guard evaluation.

---

## Convergence Guard Parameters

**Used by:** Tasks 33–37 (convergence guards)

### Hallucination Guard

- **Spike threshold:** Error count increases >20% from the prior iteration
- **Minimum trend length:** At least 2 consecutive iterations of decreasing total error count before the spike
- Trigger: both conditions true → halt

### Stagnation Guard

- **Plateau window:** Same total error count for 3+ consecutive iterations (configurable via `config.yaml` `polish.stagnation_limit`)
- **Issue rotation detection:** Fewer than 70% of issues in the current iteration have a matching issue in the prior iteration (i.e., for each current issue, check if any prior issue has Levenshtein similarity ≥ 0.8 on the `description` field — if fewer than 70% of current issues find a match, rotation is detected)
- **Match definition:** Two issues "match" when their `description` fields have Levenshtein similarity ≥ 0.8
- Trigger: plateau AND rotation both true → done (success)

### Fabrication Guard

Two conditions must both be true:

1. **Category spike:** Any single severity category count exceeds its trailing 3-iteration average by more than 50%, with a minimum absolute increase of 2. If fewer than 3 prior iterations exist, use the available iterations for the average. The fabrication guard cannot trigger before iteration 4 (need at least 3 data points for a meaningful trailing average).
2. **Prior near-convergence:** In at least one prior iteration, the system reached within 2× of the termination thresholds (≤0 critical, ≤6 medium, ≤10 minor). This prevents false positives early in the loop when counts are still volatile.

Trigger: both conditions true → halt

### Termination Guard

- `critical <= 0` AND `medium <= 3` AND `minor <= 5` (thresholds from `config.yaml`, inclusive — the configured max is the highest allowed count)
- Code mode additionally requires all tests passing
- Trigger: all conditions true → done

### Max Iterations Guard

- Hard ceiling from `config.yaml` `polish.max_iterations` (default 50)
- Trigger: iteration count reaches ceiling → halt

---

## OSS Qualification Scorecard

**Used by:** Task 25 (Code mode discovery — OSS qualification)

Every OSS recommendation during Code mode Phase 2 includes this 8-signal qualification scorecard:

| Signal | What to Check | Red Flag |
|---|---|---|
| Age | When was v1.0 released? | Less than 6 months old |
| Last Updated | Date of most recent commit/release | No updates in 12+ months |
| GitHub Stars | Star count as popularity proxy | Under 500 for a general-purpose tool |
| Weekly Downloads | npm/PyPI weekly downloads | Under 1,000 |
| Open Issues vs. Closed | Issue resolution rate | More open than closed |
| License | MIT, Apache 2.0, BSD, etc. | GPL/AGPL — may conflict with shipping |
| Bus Factor | Active maintainers | Single maintainer with no activity |
| Breaking Changes | Major version frequency | Frequent major bumps, no migration path |

Minimum qualification: pass 6 of 8 with no red flags on Age, Last Updated, or License.

---

## Agent Communication

**Used by:** Tasks 41–44 (agent layer)

### Invocation Pattern

1. ThoughtForge writes prompt to temp file or passes via stdin
2. Agent invoked: `{command} {flags} < prompt`
3. ThoughtForge captures stdout
4. Response parsed/validated (Zod for review JSON, file diff detection for fix steps)

### Output Normalization

Agent-specific adapters handle output format differences and normalize to ThoughtForge's internal format. Each adapter lives alongside the agent config and is responsible for:

- Stripping agent-specific wrapper text or metadata from stdout
- Extracting the JSON or diff payload from the raw response
- Normalizing error/exit conditions to a standard format the orchestrator expects

### Failure Handling

- Non-zero exit, timeout, or empty output → retry once
- Second failure → halt and notify human
- Timeout configurable via `config.yaml` (`agents.call_timeout_seconds`, default 300)

---

## Plan Mode Stuck Signal Schema

**Used by:** Task 15 (plan builder), Task 6c (stuck recovery)

The Phase 3 plan builder prompt requires the AI to include a structured stuck signal in every response:

```typescript
interface PlanBuilderResponse {
  stuck: boolean;        // true if the AI cannot proceed without human input
  reason?: string;       // Required when stuck is true — what decision is needed
  content?: string;      // The drafted content (when not stuck)
}
```

---

## Resource Connector Interface

**Used by:** Tasks 7c–7e (resource connectors)

### Connector Interface

Each connector module in `/connectors/` implements:

- `pull(target, projectResourcesPath)` → `Promise<{ saved: string[], failed: string[] }>` — Pulls content from the external source, writes files to the project's `/resources/` directory, returns lists of saved file paths and failed targets with reasons.

### Notion Connector (`/connectors/notion.js`)

- Authenticates via `config.yaml` `connectors.notion.api_token`
- Accepts page URLs, extracts page IDs
- Pulls page content as Markdown via Notion API
- Saves as `notion_{page_id}.md` in `/resources/`

### Google Drive Connector (`/connectors/google_drive.js`)

- Authenticates via `config.yaml` `connectors.google_drive.credentials_path`
- Accepts document URLs or IDs
- Pulls document content as plain text or Markdown via Google Drive API export
- Saves as `gdrive_{document_id}.md` in `/resources/`

---

## `status.json` Schema

**Used by:** Task 3 (project state module)
**Written:** Every phase transition and state change

```typescript
interface ProjectStatus {
  project_name: string;       // Empty string at creation. Derived from intent.md title after Phase 1 distillation.
  phase: "brain_dump" | "distilling" | "human_review" | "spec_building" | "building" | "polishing" | "done" | "halted";
  deliverable_type: "plan" | "code" | null;  // null until Phase 1 distillation determines type
  agent: string;
  created_at: string;   // ISO8601
  updated_at: string;   // ISO8601
  halt_reason: string | null;
}
```

---

## `polish_state.json` Schema

**Used by:** Task 38 (polish state persistence + crash recovery)
**Written:** After each Phase 4 iteration

```typescript
interface PolishState {
  iteration: number;
  error_counts: {
    critical: number;
    medium: number;
    minor: number;
    total: number;
  };
  convergence_trajectory: Array<{
    iteration: number;
    critical: number;
    medium: number;
    minor: number;
    total: number;
    timestamp: string;  // ISO8601
  }>;
  tests_passed: boolean | null;  // null for plan mode (no tests)
  timestamp: string;             // ISO8601
  completed: boolean;
  halt_reason: string | null;
}
```

---

## `chat_history.json` Schema

**Used by:** Tasks 7–9 (chat interface, correction loop), Task 6c (Phase 3 stuck recovery), Task 40a (Phase 4 halt recovery)
**Written:** After each chat message during Phases 1–2, Phase 3 stuck recovery, and Phase 4 halt recovery

```typescript
interface ChatMessage {
  role: "human" | "ai";
  content: string;
  phase: "brain_dump" | "distilling" | "human_review" | "spec_building" | "building" | "polishing" | "halted";
  timestamp: string;  // ISO8601
}

type ChatHistory = ChatMessage[];
```

On crash, chat resumes from last recorded message. Cleared after Phase 1→Phase 2 and Phase 2→Phase 3 confirmation button presses only. Phase 3→Phase 4 transition is automatic and does NOT clear chat history — Phase 3 stuck recovery messages persist into Phase 4.

---

## Operational Log Format (`thoughtforge.log`)

**Used by:** Task 3a (operational logging module)
**Written:** Continuously during pipeline execution

Each log line is a JSON object:

```json
{
  "timestamp": "2026-02-13T10:30:00.000Z",
  "level": "info",
  "event": "agent_call",
  "phase": "polishing",
  "detail": "Review call to claude, iteration 7"
}
```

Log levels: `info`, `warn`, `error`. Events include: `phase_transition`, `agent_call`, `agent_response`, `guard_evaluation`, `halt`, `error`, `config_loaded`, `plugin_loaded`.

---

## `polish_log.md` Entry Format

**Used by:** Task 39 (polish log append)
**Written:** Appended after each Phase 4 iteration

Each iteration is appended as a Markdown section:

```markdown
## Iteration {N}

**Timestamp:** {ISO8601}
**Error Counts:** {critical} critical, {medium} medium, {minor} minor ({total} total)
**Guard Evaluated:** {guard_name} — {result}
**Issues Found:** {summary}
**Fixes Applied:** {summary}
**Test Results:** {total} total, {passed} passed, {failed} failed (code mode only)
```

---

## `config.yaml` Template

**Used by:** Task 1 (config loader)

```yaml
# Polish loop thresholds
polish:
  critical_max: 0
  medium_max: 3
  minor_max: 5
  max_iterations: 50
  stagnation_limit: 3
  retry_malformed_output: 2

# Parallel execution (managed by Vibe Kanban)
concurrency:
  max_parallel_runs: 3

# Notifications
notifications:
  default_channel: "ntfy"
  channels:
    ntfy:
      enabled: true
      url: "https://ntfy.sh"
      topic: "thoughtforge"
    telegram:
      enabled: false
      bot_token: ""
      chat_id: ""

# Resource Connectors (Phase 1 external resource intake)
connectors:
  notion:
    enabled: false
    api_token: ""
  google_drive:
    enabled: false
    credentials_path: ""  # Path to service account JSON or OAuth client secret

# AI Agents
agents:
  default: "claude"
  call_timeout_seconds: 300
  available:
    claude:
      command: "claude"
      flags: "--print"
    gemini:
      command: "gemini"
      flags: ""
    codex:
      command: "codex"
      flags: ""

# Templates — plan mode templates live inside their plugin directory.
# This key is reserved for future cross-plugin shared templates. Not used in current scope.
# templates:
#   directory: "./plugins/plan/templates"

# Plugins
plugins:
  directory: "./plugins"

# Prompts
prompts:
  directory: "./prompts"

# Vibe Kanban integration
vibekanban:
  enabled: true

# Web server
server:
  port: 3000
```

---

## Vibe Kanban CLI Interface

**Used by:** Tasks 26–28 (Vibe Kanban integration)

| ThoughtForge Action | Vibe Kanban CLI Command | When |
|---|---|---|
| Create task | `vibekanban task create --id {project_id} --agent {agent}` | Project initialization |
| Update task name | `vibekanban task update {task_id} --name "{project_name}"` | After Phase 1 (project name derived) |
| Update task status | `vibekanban task update {task_id} --status {status}` | Every phase transition |
| Execute agent work | `vibekanban task run {task_id} --prompt-file {path}` | Phase 3 build, Phase 4 fix steps |
| Read task result | `vibekanban task result {task_id}` | After each agent execution |

**Note:** These commands are assumed from Vibe Kanban documentation. Verify actual CLI matches before build (see Risk Register in Execution Plan).

---

*Template Version: 1.0 | Last Updated: February 2026*
