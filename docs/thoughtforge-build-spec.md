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

**Used by:** Tasks 6, 15, 17, 18, 21, 22, 23, 25

### builder.js

- `build(projectPath, intent, spec, constraints, agent)` → `Promise<void>`

### reviewer.js

- `schema` → Zod schema object for validating review JSON
- `severityDefinitions` → object defining critical/medium/minor for this type
- `review(projectPath, constraints, agent)` → `Promise<object>` — one review pass, raw parsed JSON. Orchestrator validates via `schema.safeParse()`, retries on failure, halts after max retries.

### safety-rules.js

- `blockedOperations` → `string[]` (e.g., `["shell_exec", "file_create_source", "package_install"]` for Plan mode)
- `validate(operation)` → `{ allowed: boolean, reason?: string }` — called by orchestrator before every Phase 3/4 action.

### discovery.js (optional)

- `discover(intent, constraints)` → `Promise<object>` — Phase 2 hook for type-specific discovery logic. Code plugin uses this for OSS qualification scorecard. Plan plugin may omit this file. If the file is absent, the plugin loader skips it.

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

## `status.json` Schema

**Used by:** Task 3 (project state module)
**Written:** Every phase transition and state change

```typescript
interface ProjectStatus {
  phase: "brain_dump" | "distilling" | "human_review" | "spec_building" | "building" | "polishing" | "done" | "halted";
  deliverable_type: "plan" | "code";
  agent: string;
  created_at: string;   // ISO8601
  updated_at: string;   // ISO8601
  halted_reason: string | null;
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

**Used by:** Tasks 7–9 (chat interface, correction loop)
**Written:** After each chat message during Phases 1–2

```typescript
interface ChatMessage {
  role: "human" | "ai";
  content: string;
  phase: "brain_dump" | "distilling" | "human_review" | "spec_building";
  timestamp: string;  // ISO8601
}

type ChatHistory = ChatMessage[];
```

On crash, chat resumes from last recorded message. Cleared after phase advancement confirmation.

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

# Templates
templates:
  directory: "./templates"

# Plugins
plugins:
  directory: "./plugins"

# Prompts
prompts:
  directory: "./prompts"

# Vibe Kanban integration
vibekanban:
  enabled: true
```

---

## Vibe Kanban CLI Interface

**Used by:** Tasks 26–28 (Vibe Kanban integration)

| ThoughtForge Action | Vibe Kanban CLI Command | When |
|---|---|---|
| Create task | `vibekanban task create --name "{project_name}" --agent {agent}` | Phase 3 start |
| Update task status | `vibekanban task update {task_id} --status {status}` | Every phase transition |
| Execute agent work | `vibekanban task run {task_id} --prompt-file {path}` | Phase 3 build, Phase 4 fix steps |
| Read task result | `vibekanban task result {task_id}` | After each agent execution |

**Note:** These commands are assumed from Vibe Kanban documentation. Verify actual CLI matches before build (see Risk Register in Execution Plan).

---

*Template Version: 1.0 | Last Updated: February 2026*
