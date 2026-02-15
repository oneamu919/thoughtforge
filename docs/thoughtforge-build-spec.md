# ThoughtForge Pipeline Tool — Build Spec

> **Companion to:** [ThoughtForge Design Specification](./thoughtforge-design-specification.md) | [ThoughtForge Execution Plan](./thoughtforge-execution-plan.md)
>
> **Purpose:** Implementation reference for AI coders. Contains schemas, prompts, function signatures, file structures, and configuration templates extracted from the design specification. The design spec describes *what* each component does and *why*. This document provides the *how*.

---

## Prompt File Directory

**Used by:** Task 7b (prompt management UI), all tasks that invoke AI agents

All pipeline prompts are stored as external `.md` files in `./prompts/` (relative to project root). The orchestrator reads prompts from this directory at invocation time — never from embedded strings. The Settings UI in the chat interface reads from and writes to these files.

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
**Used by:** Task 6d (Plan Completeness Gate)
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

**Used by:** Task 6 (plugin loader), Tasks 14–18 (plan plugin), Tasks 20–25 (code plugin)

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
- **Plan plugin** returns `Promise<{ stuck: boolean, reason?: string, content: string }>` — matches `PlanBuilderResponse` schema. Orchestrator checks `stuck` flag to detect stuck condition.
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

### Code Builder Task Queue

The code builder maintains an ordered list of build tasks derived from `spec.md` (e.g., implement feature X, write tests for Y). Each task has a string identifier used for stuck detection — consecutive agent invocations against the same task identifier increment the retry counter. The task list format and derivation logic are internal to the code builder and are not persisted to state files. On crash recovery, the code builder re-derives the task list from `spec.md` and the current state of files in the project directory (e.g., which source files and test files already exist).

### Operation Type Taxonomy

Every orchestrator action in Phase 3/4 is classified into one of these operation types before calling `safety-rules.js` `validate()`:

| Operation Type | Description | Example Actions |
|---|---|---|
| `shell_exec` | Execute a shell command or subprocess (excluding agent invocations) | Run build script, install package |
| `file_create_source` | Create a source code file (`.js`, `.py`, `.ts`, `.sh`, etc.) | Scaffold project, write boilerplate |
| `file_create_doc` | Create a documentation file (`.md`) | Write plan section, draft document |
| `file_create_state` | Create or update a state file (`.json`) | Write `status.json`, `polish_state.json` |
| `agent_invoke` | Invoke an AI agent for content generation | Call Claude for plan section, call Codex for code |
| `package_install` | Install a dependency via package manager | `npm install`, `pip install` |
| `test_exec` | Execute a test suite | Run `npm test`, `pytest` |
| `git_commit` | Create a git commit | Milestone commit, iteration commit |

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

### Guard Evaluation Order

Guards are evaluated in the following order after each iteration. The first guard that triggers ends evaluation — subsequent guards are not checked.

1. **Termination** (success) — checked first so that a successful outcome is never overridden by a halt
2. **Hallucination** — checked before stagnation/fabrication because a spike after a downward trend is the strongest anomaly signal
3. **Fabrication** — checked before stagnation because fabricated issues would produce false plateau signals
4. **Stagnation** (success) — checked after halt guards to ensure the plateau is genuine
5. **Max iterations** — checked last as the backstop

If no guard triggers, the loop proceeds to the next iteration.

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

**Shell safety:** Prompt content is passed to agent subprocesses via file descriptor or stdin pipe — never through shell argument expansion or interpolation. The agent invocation layer must not use shell string concatenation for prompt content. This prevents accidental command execution from shell metacharacters in brain dump text or resource files.

### Output Normalization

Agent-specific adapters handle output format differences and normalize to ThoughtForge's internal format. Each adapter lives alongside the agent config and is responsible for:

- Stripping agent-specific wrapper text or metadata from stdout
- Extracting the JSON or diff payload from the raw response
- Normalizing error/exit conditions to a standard format the orchestrator expects

**Normalized Agent Response:**
```typescript
interface AgentResponse {
  success: boolean;      // true if agent exited 0 and produced non-empty output
  output: string;        // Cleaned agent stdout — wrapper text and metadata stripped
  exitCode: number;      // Raw process exit code
  timedOut: boolean;     // true if killed by timeout
}
```
All agent adapters return this structure. The orchestrator and plugins consume only `AgentResponse`, never raw subprocess output.

### Failure Handling

- Non-zero exit, timeout, or empty output → retry once
- Second failure → halt and notify human
- Timeout configurable via `config.yaml` (`agents.call_timeout_seconds`, default 300)

---

## Plan Builder — Template Content Escaping

**Used by:** Task 15 (plan builder)

AI-generated content inserted into Handlebars template slots is escaped to prevent Handlebars syntax characters in plan text (e.g., literal `{{` or `}}`) from causing render failures. The plan builder escapes content before template rendering.

---

## Plan Mode Stuck Signal Schema

**Used by:** Task 15 (plan builder), Task 6c (stuck recovery)

The Phase 3 plan builder prompt requires the AI to include a structured stuck signal in every response:

```typescript
interface PlanBuilderResponse {
  stuck: boolean;        // true if the AI cannot proceed without human input
  reason?: string;       // Required when stuck is true — what decision is needed
  content: string;       // The drafted content — required when stuck is false, empty string when stuck is true
}
```

---

## Realign Algorithm

**Used by:** Task 9 (correction loop — "realign from here" command)

**Realign Algorithm (Phase 1, step 9):**
1. **Baseline identification:** Scan backwards through `chat_history.json` past any sequential "realign from here" commands to find the most recent substantive human correction.
2. **Context truncation:** Exclude all AI and human messages after the identified baseline from the working context. Retain excluded messages in `chat_history.json` for audit trail.
3. **Re-distillation scope:** Re-distill from the original brain dump plus all human corrections up to the identified baseline.
4. **No-correction guard:** If no human corrections exist yet (only the original brain dump), ignore the "realign from here" command and prompt the human to provide a correction first.

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
- **URL patterns:** `notion.so/`, `notion.site/`

### Google Drive Connector (`/connectors/google_drive.js`)

- Authenticates via `config.yaml` `connectors.google_drive.credentials_path`
- Accepts document URLs or IDs
- Pulls document content as plain text or Markdown via Google Drive API export
- Saves as `gdrive_{document_id}.md` in `/resources/`
- **URL patterns:** `docs.google.com/`, `drive.google.com/`

---

## Resource File Processing

**Used by:** Task 8 (Phase 1 brain dump intake)

| Format | Processing Method |
|---|---|
| `.md`, `.txt`, code files | Read as plain text, passed to AI as context |
| `.pdf` | Text extracted via PDF parsing library (e.g., `pdf-parse`). If extraction yields no text (scanned PDF), log a warning and skip the file. OCR is deferred. |
| Images (`.png`, `.jpg`, `.gif`) | Passed to the AI agent's vision capability if the configured agent supports it. If not, log a warning and skip. |
| Unsupported formats | Logged as unreadable per Phase 1 error handling |

---

## Action Button Behavior

**Used by:** Tasks 7, 10, 6c, 6d, 40a (chat interface, action buttons, stuck recovery, completeness gate, halt recovery)

| Button | Context | `status.json` Effect | Chat UI After Press | Confirmation Required? |
|---|---|---|---|---|
| Distill | Phase 1 — after brain dump input | Phase set to `distilling` | Button disabled, spinner shown with "Distilling…" message. AI response streams in when ready. | No — single click. |
| Confirm (Phase 1) | Phase 1 — after human approves distillation | Phase set to `spec_building`. `project_name` and `deliverable_type` written. | Button disabled, chat shows "Intent locked. Moving to spec building." New Phase 2 context loads. | No — single click. |
| Confirm (Phase 2) | Phase 2 — after spec and constraints approved | Phase set to `building` | Button disabled, chat shows "Spec and constraints locked. Build starting." Phase 3 begins. | No — single click. |
| Provide Input | Phase 3 stuck recovery | Phase remains `building` | Button disabled, chat shows input prompt. Human types response, builder resumes. | No — single click opens input. |
| Terminate (Phase 3) | Phase 3 stuck recovery | Phase set to `halted`, `halt_reason: "human_terminated"` | Confirmation dialog: "This will permanently stop the project. Confirm?" On confirm: chat shows "Project terminated." Buttons removed. | Yes — single confirmation step. |
| Resume | Phase 4 halt recovery | Phase remains `polishing`, `halt_reason` cleared | Button disabled, chat shows "Resuming polish loop from iteration [N+1]." Loop restarts. | No — single click. |
| Override | Phase 4 halt recovery | Phase set to `done`, `halt_reason` cleared | Confirmation dialog: "Accept current state as final deliverable?" On confirm: chat shows "Deliverable accepted. Project complete." Buttons removed. | Yes — single confirmation step. |
| Terminate (Phase 4) | Phase 4 halt recovery | Phase set to `halted`, `halt_reason: "human_terminated"` | Confirmation dialog: "This will permanently stop the project. Confirm?" On confirm: chat shows "Project terminated." Buttons removed. | Yes — single confirmation step. |
| Override (Gate) | Plan Completeness Gate failure | Phase set to `building` (resumes Code mode build) | Confirmation dialog: "Proceed with Code mode despite incomplete plan?" On confirm: chat shows "Override accepted. Build starting." | Yes — single confirmation step. |
| Terminate (Gate) | Plan Completeness Gate failure | Phase set to `halted`, `halt_reason: "human_terminated"` | Confirmation dialog: "This will permanently stop the project. Confirm?" On confirm: chat shows "Project terminated." Buttons removed. | Yes — single confirmation step. |

### Button Debounce Implementation

Once an action button is pressed, it is immediately disabled in the UI and remains disabled until the triggered operation completes or fails. A second click on a disabled button has no effect. If the server receives a duplicate action request for a button that has already been processed (e.g., due to a race condition between client and server), the server ignores the duplicate and returns the current project state.

---

## Project Initialization Sequence

**Used by:** Task 2 (project initialization)

The following operations execute in order when a new project is created:

1. Generate a unique project ID (format: `{timestamp}-{random}`, e.g., `20260214-a3f2`)
2. Create the `/projects/{id}/` directory structure (including `/docs/` and `/resources/` subdirectories)
3. Initialize a git repo in the project directory
4. Write an initial `status.json` with phase `brain_dump` and `project_name` as empty string
5. If Vibe Kanban integration is enabled, create a corresponding Kanban card
6. Open a new chat thread for the project

If Vibe Kanban card creation fails during initialization, log a warning and continue. The project proceeds without a Kanban card. Subsequent VK status update calls for this project will also fail (card does not exist) and will be logged and ignored per standard VK failure handling. The pipeline is fully functional without VK visualization.

---

## Project Name Derivation

**Used by:** Task 11 (intent.md generation and locking)

The AI uses the first heading (H1) of the distilled `intent.md` document as the project name. If no H1 heading is present, the AI generates a short descriptive name (2–4 words) from the brain dump content and includes it as the H1 heading. When `intent.md` is written and locked, the project name is extracted from its H1 heading and written to `status.json`. If Vibe Kanban is enabled, the card name is updated at the same time.

### Deliverable Type Parsing

The `deliverable_type` field in `status.json` is set by parsing the Deliverable Type section of the confirmed `intent.md`. The AI's distillation always states exactly one of "Plan" or "Code" as the first word of this section. The orchestrator string-matches that first word (case-insensitive) to set the field to `"plan"` or `"code"`.

---

## WebSocket Reconnection Parameters

**Used by:** Task 7 (chat interface WebSocket implementation)

- **Initial backoff:** 1 second
- **Maximum backoff:** 30 seconds (cap)
- **Maximum retries:** Unlimited (no maximum retry limit)
- **Backoff strategy:** Exponential

---

## `status.json` Schema

**Used by:** Task 3 (project state module)
**Written:** Every phase transition and state change

### Phase-to-State Mapping

| Phase | `status.json` Values | Transitions |
|---|---|---|
| Phase 1 | `brain_dump` → `distilling` → `human_review` | `brain_dump`: human providing inputs. `distilling`: triggered by Distill button, AI processing. `human_review`: human correcting distillation. |
| Phase 2 | `spec_building` | Entered on Phase 1 Confirm. |
| Phase 3 | `building` | Entered on Phase 2 Confirm. |
| Phase 4 | `polishing` | Entered automatically on Phase 3 completion. |
| Terminal | `done` | `done`: convergence or stagnation success. |
| Non-terminal halt | `halted` | `halted`: guard trigger, human terminate, or unrecoverable error. Counts toward concurrency limit. Human must resume or terminate to free the slot. |

```typescript
interface ProjectStatus {
  project_name: string;       // Empty string at creation. Derived from intent.md title after Phase 1 distillation.
  phase: "brain_dump" | "distilling" | "human_review" | "spec_building" | "building" | "polishing" | "done" | "halted";
  deliverable_type: "plan" | "code" | null;  // null until Phase 1 distillation determines type
  agent: string;
  created_at: string;   // ISO8601
  updated_at: string;   // ISO8601
  halt_reason: string | null;  // Known values: "plan_incomplete", "guard_hallucination", "guard_fabrication", "guard_max_iterations", "human_terminated", "agent_failure", "file_system_error", "phase3_output_missing", "phase3_output_incomplete", "server_restart"
}
```

**Single-project concurrency model:** The sequential nature of the pipeline enforces single-threaded operation per project: each phase awaits completion before the next begins, and button presses are ignored while an operation is in progress. No explicit locking or mutex is required. Concurrent access to a single project's state files is not supported and does not need locking.

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
  phase: "brain_dump" | "distilling" | "human_review" | "spec_building" | "building" | "polishing" | "halted";  // "done" excluded — no chat occurs after completion
  timestamp: string;  // ISO8601
}

type ChatHistory = ChatMessage[];
```

On crash, chat resumes from last recorded message. Cleared after Phase 1→Phase 2 and Phase 2→Phase 3 confirmation button presses only. Phase 3→Phase 4 transition is automatic and does NOT clear chat history — Phase 3 stuck recovery messages persist into Phase 4.

---

## Operational Log Format (`thoughtforge.log`)

**Used by:** Task 3a (operational logging module)
**Written:** Continuously during pipeline execution
**Implementation:** Custom structured JSON logger using Node.js `fs` for file append

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

## Build Toolchain

**ThoughtForge Build Toolchain:**
- Test framework: Vitest (or Jest — decide before build starts)
- Test execution: `npm test` runs all unit tests; `npm run test:e2e` runs end-to-end tests
- E2E tests require at least one configured agent CLI on PATH
- All unit tests use mocked dependencies (no real agent calls, no real file I/O for state tests)

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

# Resource intake thresholds
resource:
  max_file_size_mb: 50         # Skip resource files exceeding this size

# Brain dump intake thresholds
brain_dump:
  min_word_count: 10           # Minimum word count before distillation proceeds

# Phase 3→4 transition completeness thresholds
phase3_completeness:
  plan_min_chars: 100          # Plan mode: minimum deliverable character count
  code_require_tests: true     # Code mode: require at least one test file

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
      supports_vision: true
    gemini:
      command: "gemini"
      flags: ""
      supports_vision: true
    codex:
      command: "codex"
      flags: ""
      supports_vision: false

# The `supports_vision` field determines whether image resources are passed to
# this agent. If `false` or absent, image files are logged as skipped.

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
  host: "127.0.0.1"  # Bind to localhost only. Change to "0.0.0.0" for network access.
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
| Execute agent work | `vibekanban task run {task_id} --prompt-file {path}` | Code mode only: Phase 3 build, Phase 4 fix steps. Plan mode invokes agents directly via agent layer — VK is visualization only. |
| Read task result | `vibekanban task result {task_id}` | After each Code mode agent execution via VK |

**Note:** These commands are assumed from Vibe Kanban documentation. Verify actual CLI matches before build (see Risk Register in Execution Plan).

---

## Connector and Notification URL Validation

**Used by:** Task 1 (config loader startup validation), Tasks 4–5 (notification layer), Tasks 7c–7e (resource connectors)

### Startup Validation (Config Loader)

For each enabled notification channel: validate that `url` is present and is a well-formed URL (has scheme, host). For each enabled resource connector: validate that required credential fields are non-empty. Validation uses the same Zod schema approach as the rest of config validation — URL fields use `z.string().url()` for enabled channels/connectors. Disabled channels/connectors skip URL validation.

Specific error messages on validation failure:
- Notification channel URL missing or empty: Server exits with error: "Notification channel '{channel}' is enabled but has no URL configured."
- Notification channel URL malformed (e.g., missing scheme): Server exits with error: "Notification channel '{channel}' URL is malformed: {url}."
- Resource connector credentials missing when enabled: Server exits with error: "Connector '{connector}' is enabled but missing required credentials."

### Runtime Failure Handling

- **Notification send failure** (endpoint unreachable, HTTP error, timeout): Log a warning with the channel name and error. Retry once. On second failure, log and continue — do not halt the pipeline. Notification failures are never blocking.
- **Resource connector failure** (endpoint unreachable, API error, timeout): Already specified in connector interface — `pull()` returns `{ saved, failed }`. Failed targets include the reason. The orchestrator logs the failure, notifies the human in chat, and proceeds with available inputs.

---

## `spec.md` Structure

**Used by:** Task 13 (spec and constraints generation)
**Written:** End of Phase 2, locked after write

### Plan Mode

```markdown
# {Project Name} — Specification

## Deliverable Overview
{Restated objective from intent.md}

## Deliverable Structure
{Proposed plan sections following OPA Framework — every major section gets an OPA table}

## Key Decisions
{Each decision the AI made or the human confirmed, with rationale}

## Resolved Unknowns
{Every Unknown and Open Question from intent.md, with resolution and source (AI-reasoned or human-provided)}

## Dependencies
{External tools, services, data, or prerequisites required}

## Scope Boundaries
{What is explicitly included and excluded}
```

### Code Mode

Same structure as Plan mode, except:
- **Deliverable Structure** contains proposed architecture, language, framework, and tools (including OSS qualification results where applicable)

---

## `constraints.md` Structure

**Used by:** Task 13 (spec and constraints generation), Task 30 (polish loop — re-read at each Phase 4 iteration start)
**Written:** End of Phase 2, locked after write (but human may manually edit; changes picked up at next Phase 4 iteration)

```markdown
# {Project Name} — Review Constraints

## Context
{What this deliverable does, from intent.md}

## Deliverable Type
{Plan or Code}

## Priorities
{What the human cares about}

## Exclusions
{What not to touch, what not to flag}

## Severity Definitions
{What counts as critical / medium / minor}

## Scope
{Plan mode: sections/topics in scope. Code mode: files/functions in scope.}

## Acceptance Criteria
{5–10 statements of what the deliverable must contain or do}
```

---

## `intent.md` Structure

**Used by:** Task 11 (intent.md generation and locking)
**Written:** End of Phase 1, locked after write

### Template

    # {Project Name}

    ## Deliverable Type
    {Plan or Code, with reasoning}

    ## Objective
    {What the human wants to exist when this is done}

    ## Assumptions
    {What the human seems to believe is true, both stated and inferred}

    ## Constraints
    {Limitations: OS, language, tools, budget, timeline, etc.}

    ## Unknowns
    {Gaps that need to be decided before building}

    ## Open Questions
    {Up to 5 questions the AI couldn't resolve from the brain dump, prioritized by blocking impact}

---

## Notification Payload Schema

**Used by:** Tasks 4–5 (notification layer + phase transition notifications)
**Sent:** Every phase transition, convergence event, error, and stuck/halt condition

```typescript
interface NotificationPayload {
  project_id: string;
  project_name: string;
  phase: string;
  event_type: "convergence_success" | "guard_triggered" | "human_needed" | "milestone_complete" | "error";
  summary: string;  // One-line description with actionable context
}
```

**Example payload:**
```json
{
  "project_id": "{id}",
  "project_name": "Wedding Plan",
  "phase": "polishing",
  "event_type": "convergence_success",
  "summary": "Polish loop converged. 0 critical, 1 medium, 3 minor. Ready for final review."
}
```

---

*Template Version: 1.0 | Last Updated: February 2026*
