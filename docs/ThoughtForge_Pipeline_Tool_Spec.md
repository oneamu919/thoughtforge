# ThoughtForge Pipeline Tool
## Design Specification

---

## OPA Framework

| | |
|---|---|
| **Outcome** | A personal tool that takes a human brain dump and autonomously produces a polished deliverable — either a **plan** (wedding, event, engineering design, business strategy, etc.) or **working code**. Reduces human touchpoints to 3-4 per project. Multiple projects run in parallel via Vibe Kanban with race stats. The polish loop that currently takes ~12 hours of manual work runs unattended to convergence: 0 critical errors, <3 medium, <5 minor. |
| **Purpose** | Eliminates the repetitive manual labor of iterative AI review — for any type of project, not just code. The human focuses only on intent, direction, and final review. Everything between is autonomous. Designed for a solo operator using flat-rate AI subscriptions via multiple coding agents (Claude Code CLI, Gemini CLI, Codex CLI). If it works well, redesign to ship as a product for others. |
| **Action Scope** | Accept brain dump and resources, distill intent with human correction, discover constraints through AI self-negotiation, autonomously build the deliverable (plan or code), run automated polish loop with convergence detection and hallucination guards, notify human when done or stuck. Vibe Kanban handles task visualization, parallel execution, and agent orchestration. ThoughtForge handles the intelligence: brain dump intake, plan mode, constraint discovery, polish loop logic, and convergence guards. |

> **OPA Framework** adapted from Tony Robbins' RPM system. Every section answers: What result? Why does it matter? What specific steps?

---

## Project Types & Pipeline Chaining

Every project card has a **deliverable type** set during Phase 1:

| Type | Deliverable | Polish Loop Reviews For | Examples |
|---|---|---|---|
| **Plan** | A polished document — complete, detailed, actionable. | Completeness, logical gaps, missing details, contradictions, feasibility issues, unclear responsibilities, missing timelines/budgets. | Wedding plan, event logistics, engineering design, business strategy, product roadmap, marketing campaign. |
| **Code** | A working, polished codebase. | Code quality (best practices, security, error handling) + functional acceptance criteria (features exist and work). | Web apps, CLI tools, APIs, scripts, automation. |

### Pipeline Chaining: Plan → Code

A plan and its code implementation are **two separate pipeline runs**, not one.

**Why:** A plan must be fully complete, polished, and human-approved before anyone — human or AI — starts building from it. If the plan is half-baked, the code will be garbage no matter how good the polish loop is.

**How it works:**

1. **Pipeline 1 (Plan mode):** Human brain dumps → AI distills → human corrects → plan is built → plan is polished → plan is **Done**. Human reviews and approves the finished plan.
2. **Pipeline 2 (Code mode):** Human creates a new project card. The completed plan from Pipeline 1 goes into the `/resources/` directory as input. The brain dump is: "Build this." Phase 1 distills the plan into a code-focused intent. Phase 2 produces the build spec and technical decisions. Phase 3 codes it. Phase 4 polishes it.

The tool does NOT automatically chain these. The human decides when a plan is ready and manually kicks off the code pipeline with the finished plan as input. This is a deliberate human touchpoint — the plan must pass the human's judgment before it becomes a build spec for AI coders.

**This also means:** A plan can spawn multiple code pipelines (e.g., a product roadmap spawns separate pipelines for frontend, backend, and infrastructure). Or a plan can stay a plan forever and never become code (e.g., a wedding plan).

### Plan Completeness Gate

When a Code mode pipeline starts and receives a plan document as input (from `/resources/`), the AI must first assess whether the plan is actually complete — or if it's a brain dump, a rough outline, or a half-fleshed idea pretending to be a plan. If the plan isn't ready, building from it will produce garbage and waste the human's time.

**Assessment Prompt (runs automatically at the start of Phase 1 in Code mode when a plan document is detected in `/resources/`):**

```
You are receiving a document that is supposed to be a completed plan ready
for code implementation. Before proceeding, assess whether this plan is
actually complete enough to build from.

Check for these signals:

COMPLETE PLAN (proceed to Code mode):
- Follows OPA Framework structure — opens with Outcome/Purpose/Action Scope table
- Has clear, specific objectives — not vague aspirations
- Decisions are made, not listed as options ("we will use X" not "we could use X or Y")
- Contains enough detail that a developer could build without guessing intent
- Acceptance criteria or success conditions are defined
- No sections with "TBD," placeholders, or "to be decided"
- Scope boundaries are clear — what's included and what's not
- Dependencies and requirements are listed, not assumed

INCOMPLETE — REDIRECT TO PLAN MODE:
- Missing OPA Framework structure — no Outcome/Purpose/Action Scope table
- Reads like a brain dump: stream of consciousness, scattered ideas, no structure
- Vague objectives: "make something that handles users" instead of specific features
- Open decisions: "we might use React or Vue" — decisions not locked
- Missing sections: no timeline, no constraints, no acceptance criteria
- Placeholder content: "TBD," "figure this out later," empty sections
- Scope is unclear: can't tell what's in vs. out
- Feels like the first draft of an idea, not the final version of a plan

OUTPUT one of:
1. "PLAN COMPLETE — ready for Code mode." Then proceed with Phase 1 distillation.
2. "PLAN INCOMPLETE — redirecting to Plan mode." Then list the specific gaps
   found and explain why this needs to go through a Plan pipeline first.
   Do NOT proceed with Code mode.

Be strict. A plan that is 80% complete is not complete. If you have to guess
what the human meant in more than 2 places, it's not ready.
```

**If the assessment returns INCOMPLETE:**
- The tool creates a new Plan mode card automatically
- Moves the document into the new Plan card's `/resources/` directory
- Notifies the human via Telegram: "This plan isn't ready for code. Redirected to Plan mode. Here's what's missing: [gaps list]"
- The human can override and force Code mode if they disagree, but the default is redirect

### Plan Mode Safety Guardrails

**Plan mode NEVER builds, executes, compiles, installs, or runs code. Ever.**

A plan is a document. It may contain code snippets, architecture diagrams described in text, CLI examples, or config samples — those are illustrative content inside the document, not executable artifacts. The tool must enforce the following hard rules in Plan mode:

| Rule | What It Prevents |
|---|---|
| **No CLI agent execution** | AI cannot invoke any coding agent (Claude Code, Gemini CLI, Codex, etc.), run shell commands, install packages, or execute anything during Plan mode Phases 3 or 4. The only tool is document generation. |
| **No file creation outside the plan document and project state files** | AI cannot create `.js`, `.py`, `.ts`, `.sh`, or any source code files. Only `.md` files in `/docs/`, `.json` state files, and project state files are written. |
| **No "let me build a quick prototype"** | If the AI suggests building something to validate the plan, the tool blocks it. Validation in Plan mode is review and reasoning only. |
| **No test execution** | AI cannot write and run tests. Plan quality is assessed by the review loop checking for completeness, logic, and acceptance criteria — not by running anything. |
| **Phase 3 in Plan mode = document drafting only** | The AI writes the plan document. It does not scaffold projects, generate boilerplate, or set up repos for code. |
| **Phase 4 in Plan mode = document review only** | The reviewer checks for gaps, contradictions, missing details, and acceptance criteria. It does not evaluate whether code snippets inside the plan would compile or run. |

**Why this matters:** If Plan mode accidentally starts building code, the human gets pulled into debugging and iterating on code that wasn't supposed to exist yet. The entire point of Plan → Code separation is that the plan is complete and human-approved BEFORE any code pipeline starts. A Plan mode run that builds code is a total failure — it wastes human time and energy on the wrong thing at the wrong phase.

**Enforcement:** The orchestrator checks the deliverable type from `intent.md` before every Phase 3 and Phase 4 action. If deliverable type is Plan, execution-related calls are blocked at the orchestrator level, not just by prompting the AI to behave. Prompts can be ignored. Orchestrator-level blocks cannot.

---

## Stack

### Architecture: Two Layers

**ThoughtForge** is the intelligence layer — brain dump intake, plan mode, constraint discovery, polish loop logic, convergence guards. It creates and manages the work.

**Vibe Kanban** is the execution and visualization layer — kanban board, parallel task execution, agent spawning, git worktree isolation, dashboard, VS Code integration. It runs and displays the work.

ThoughtForge creates tasks → pushes them to Vibe Kanban → Vibe Kanban executes via coding agents → ThoughtForge monitors results and runs convergence logic.

### ThoughtForge Stack

| Component | Technology | Why |
|---|---|---|
| Runtime | Node.js | Already installed (via OpenClaw), single runtime for everything. This is the primary reason for choosing Node.js over Python. |
| ThoughtForge Core | Node.js CLI + orchestration logic | The intelligence layer: Phase 1-2 chat, polish loop logic, convergence guards, plan mode enforcement. ~200-400 lines of orchestration code. |
| AI Agents | Claude Code CLI, Gemini CLI, Codex CLI | Multi-agent support. Use different agents for different tasks or compare performance on the same task. Flat-rate subscriptions where available. |
| Project State | File-based: `/projects/{id}/` with `/docs/` subdirectory for all plans, specs, and constraints (`intent.md`, `spec.md`, `constraints.md`, plan documents). Project state files (`polish_log.md`, `polish_state.json`, `status.json`) live in the project root. | Simple, human-readable, git-trackable. State access wrapped in a single module so a DB can be swapped in later if shipped as product. |
| Version Control | Git — each project gets its own repo. Auto-commit after every polish iteration. | Rollback is built in. History is free. Separate repos per project for clean parallel isolation. |
| Notifications | Telegram bot (bot token, direct messages) | Push notification to phone when AI needs human or is done. |
| Config | `config.yaml` at project root | Thresholds, max iterations, concurrency limit, agent preferences. Human-editable. |

### Vibe Kanban (Execution Layer — Not Built, Integrated)

| What It Provides | How ThoughtForge Uses It |
|---|---|
| Kanban board UI | Visualize ThoughtForge pipeline phases as task cards moving across columns. |
| Parallel execution | Run multiple ThoughtForge projects simultaneously across different agents. |
| Git worktree isolation | Each task runs in its own worktree — clean parallel isolation without ThoughtForge managing it. |
| Multi-agent support | Claude Code, Gemini CLI, Codex, Amp, Cursor CLI, and more. Switch agents per task or compare. |
| VS Code extension | See task status inside the IDE. |
| Dashboard / stats | Task timing, agent performance, progress tracking — the race stats view. |

**What's NOT in the stack and why:**

- **No custom kanban UI, no Next.js, no dnd-kit, no Socket.io** — Vibe Kanban provides all of this. Building it from scratch would duplicate existing open-source tooling for no gain.
- **No Python** — Node.js is already installed (via OpenClaw) and handles everything needed. One runtime is cleaner than two.
- **No SQLite or any database** — Node.js handles file I/O and JSON parsing natively. State is `.md` and `.json` files, git is the history layer. A database adds a dependency for no gain. State access is wrapped in a single module so a DB can be swapped in later.
- **No LangGraph, AutoGen, CrewAI, or any agent framework** — the orchestration logic is straightforward. Vibe Kanban handles agent spawning. ThoughtForge handles the loop logic. No framework needed in between.

---

## Phase 1 — Brain Dump & Discovery

| | |
|---|---|
| **Outcome** | A locked `intent.md` document that accurately captures what the human wants — objectives, assumptions, scope, unknowns — validated by human confirmation. |
| **Purpose** | Without confirmed intent, everything downstream is garbage. This phase gets the messy, incomplete idea in the human's head into a structured form that AI can execute against. The human is also learning and refining during this phase. |
| **Action Scope** | Accept brain dump via chat. Read all files in project resource directory. Distill into structured objectives, assumptions, constraints, unknowns. Present to human. Accept corrections. Re-distill. Support "realign from here" resets without going back to zero. Exit when human explicitly confirms intent. |

### Trigger

Human creates a new project card and brain dumps into chat panel. Drops files and resources into the project's `/resources/` directory.

### System Prompt — Brain Dump Intake

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

### AI Behavior

- Reads all resources in the project directory (text, PDF, images via vision, code files)
- Reads the brain dump
- Distills into the 5-section structured document
- Presents it back to human in chat

### Human Behavior

- Reads the distilled version
- Responds in chat: "approved" / "move forward" / "looks good" → advances to Phase 2
- Or: "item 3 is wrong, it should be XYZ" → AI revises and presents again
- If intent is fundamentally off: says "realign from here" — AI resets to that point, not to zero
- If incorrect assumptions keep reappearing: asks AI why, discovers unclear writing or wrong assumptions, adjusts

### Confirmation

Chat-based. The tool classifies the human's message as either a **correction** (loop back, revise) or a **confirmation** (advance to Phase 2). If the human says "approved," "move forward," "looks good, let's build," or equivalent — it advances. If they say "item X is wrong" or give corrections — it revises and presents again.

### Output

`intent.md` — locked intent document stored in `/docs/`, following OPA Framework structure, carried through all later phases. Includes the **deliverable type** (Plan or Code) determined from the brain dump.

---

## Phase 2 — Spec Building & Constraint Discovery

| | |
|---|---|
| **Outcome** | A locked `spec.md` with all decisions finalized, a `constraints.md` defining what the polish loop checks against, and a set of **acceptance criteria** that validate the deliverable meets the intent. |
| **Purpose** | Constraints prevent the polish loop from chasing its own tail. Without explicit rules for what counts as critical vs. minor, what's in scope vs. out, and what not to touch, the model invents stylistic preferences and never converges. Acceptance criteria prevent the polish loop from producing a clean deliverable that's missing what was asked for. |
| **Action Scope** | Propose the deliverable structure and decisions. Push back like a real expert with reasoning. Accept human overrides. Generate `constraints.md` and acceptance criteria from the accumulated decisions. |

### Trigger

Human confirms intent (Phase 1 complete).

### AI Behavior — Plan Mode

- Proposes the plan structure following the **OPA Framework**: every major section of the plan gets its own OPA table (Outcome, Purpose, Action Scope) before detail content. The top-level plan document opens with a master OPA table covering the entire plan.
- Pushes back like a real planner: "You need a vendor backup list for an outdoor wedding" or "This timeline is too aggressive for the scope"
- **Extracts 5-10 acceptance criteria from `intent.md`** — plain statements like:
  - "Plan includes a complete vendor list with contact info"
  - "Every task has an owner and a deadline"
  - "Budget breakdown covers all major categories"
  - "Contingency plan exists for outdoor weather risks"
  - "All sections follow OPA Framework structure"

### AI Behavior — Code Mode

- Proposes build spec: language, OS, framework, tools, dependencies, architecture
- Pushes back like a real engineer: "Node.js makes more sense here because X" or "Docker isn't needed for this, here's why"
- Discovers constraints through internal proposer/challenger reasoning
- **Extracts 5-10 functional acceptance criteria from `intent.md`** — plain statements like:
  - "User can create a project from the kanban board"
  - "Telegram notification fires when polish loop finishes"
  - "Cards move automatically when phase changes"
  - "Git commits after every polish iteration"
- Presents the build spec, constraints, and acceptance criteria to human

### Human Behavior

- Confirms or overrides specific decisions ("No, Python only." / "Yes, Docker is fine." / "I forgot to mention, Windows only.")
- Reviews acceptance criteria — adds missing ones, removes wrong ones
- One round is usually enough

### Exit Condition

Human confirms build spec.

### Outputs

- `spec.md` — spec with all decisions locked, stored in `/docs/` (plan structure or build spec depending on mode)
- `constraints.md` — review constraints with severity definitions, scope boundaries, exclusion rules, AND acceptance criteria, stored in `/docs/`

### What Goes Into `constraints.md`

| Section | Description |
|---|---|
| Context | What this deliverable does (from `intent.md`) |
| Deliverable Type | Plan or Code |
| Priorities | What the human cares about (from Phase 1 corrections) |
| Exclusions | What not to touch, what not to flag |
| Severity Definitions | What counts as critical / medium / minor — specific to this project and deliverable type |
| Scope | **Plan mode:** which sections and topics are in scope. **Code mode:** which files and functions are targets. |
| **Acceptance Criteria** | **5-10 statements of what the deliverable must contain or do. Plan mode: completeness checks. Code mode: features that must exist and work. The polish loop reviewer validates these alongside quality.** |

---

## Phase 3 — Build

| | |
|---|---|
| **Outcome** | **Plan mode:** A complete first draft of the plan document — all sections filled, rough but comprehensive. **Code mode:** Working code that runs end-to-end — rough, unpolished, but functional. |
| **Purpose** | You can't polish what doesn't exist. This phase gets the deliverable to a state where automated review is meaningful — not perfect, just complete enough to review. |
| **Action Scope** | **Plan mode:** Draft the full plan document using `spec.md` and `intent.md`. Fill every section. **Code mode:** Code the project using the configured coding agent (Claude Code, Gemini CLI, Codex, etc.) via Vibe Kanban. Run and test. Fix errors. Iterate until functional. Ping human only when stuck on ambiguity not covered by spec. |

### Trigger

Build spec confirmed (Phase 2 complete).

### AI Behavior — Plan Mode (Autonomous)

- Drafts the complete plan document in `.md` format in `/docs/` based on `spec.md` structure and `intent.md` goals
- **All plan documents must follow the OPA Framework structure:** every plan opens with the OPA table (Outcome, Purpose, Action Scope) before any procedural or detail content. Reference: `.shareddocs/opa_framework.md` (included in repo)
- Fills every section — no placeholders, no "TBD"
- May include illustrative code snippets, config examples, or CLI references inside the document — these are content, not executed
- **Does NOT create source files, run commands, install packages, scaffold projects, or execute anything. Document drafting only. Enforced at orchestrator level.**
- If stuck on a decision that requires human input not covered by spec: pings human via Telegram and waits

### AI Behavior — Code Mode (Autonomous)

- Codes the project using the configured coding agent (Claude Code, Gemini CLI, Codex, etc.) via Vibe Kanban
- **Implements logging throughout the codebase** — every significant action, error, and state change gets logged. Logging is not optional. Without logs, debugging in Phase 4 and after delivery is blind guesswork.
- **Writes tests to validate the code works** — unit tests for core logic, integration tests for connected components, and end-to-end tests that confirm the acceptance criteria from `constraints.md` are met. Tests are part of the deliverable, not throwaway scaffolding.
- Runs all tests, fixes failures, iterates until passing
- If stuck or hitting an ambiguity not covered by spec: pings human via Telegram and waits

### Code Mode Testing Requirements

| Test Type | What It Covers | When It Runs |
|---|---|---|
| **Unit tests** | Core functions and logic in isolation | Phase 3 (during build) and Phase 4 (after each fix iteration) |
| **Integration tests** | Components working together (API routes, database calls, service interactions) | Phase 3 (during build) and Phase 4 (after each fix iteration) |
| **Acceptance tests** | Each acceptance criterion from `constraints.md` has a corresponding test that proves the feature exists and works | Phase 3 (during build) and Phase 4 (reviewer flags missing acceptance test coverage) |

**Phase 4 reviewer checks for test coverage.** If a feature exists but has no test, that's a medium flaw. If an acceptance criterion has no corresponding test, that's a critical flaw. The polish loop doesn't just polish the code — it polishes the tests too.

**All test results are logged.** Each Phase 4 iteration records: tests run, tests passed, tests failed, and which failures correspond to which issues in the review JSON.

### Human Behavior

- Only intervenes if pinged
- Answers specific questions, unblocks

### Exit Condition

**Plan mode:** All sections of the plan are drafted in `.md` format in `/docs/` — no empty sections, no placeholders. No source code files exist in the project directory.
**Code mode:** Code runs, all tests pass, logging is implemented, and every acceptance criterion has a corresponding test.

### Output

**Plan mode:** Complete but unpolished plan document (`.md`) in `/docs/` subdirectory.
**Code mode:** Working but unpolished codebase.

---

## Phase 4 — Polish Loop (Fully Automated)

| | |
|---|---|
| **Outcome** | Polished deliverable with 0 critical errors, <3 medium errors, <5 minor errors. Convergence log showing the full error trajectory. |
| **Purpose** | This is the 12-hour manual grind being automated. The intent is locked, the spec is locked, the constraints are defined, the deliverable exists. Now it's purely mechanical: find flaws, fix flaws, check counts, repeat until clean. No human judgment needed. |
| **Action Scope** | Run review call (output JSON error report only). Run fix call (apply all fixes). Check termination thresholds. Detect hallucination, scope drift, and stagnation. Enforce max iteration ceiling. Log every iteration. Ping human when done or when guards trigger. |

### Trigger

Code is working (Phase 3 complete).

### Each Iteration — Two Steps

**Step 1 — Review (do not fix):**

"Here is the scoped deliverable and `constraints.md` (including acceptance criteria). Output ONLY a JSON report. Do not fix anything."

**Code mode example:**
```json
{
  "critical": 2,
  "medium": 5,
  "minor": 8,
  "tests": {
    "total": 24,
    "passed": 22,
    "failed": 2
  },
  "issues": [
    {
      "severity": "critical",
      "description": "SQL injection in user input handler",
      "location": "src/api/users.py:42",
      "recommendation": "Use parameterized queries"
    },
    {
      "severity": "critical",
      "description": "Missing feature: Telegram notification not wired up",
      "location": "N/A",
      "recommendation": "Implement Telegram bot integration per acceptance criteria #4"
    },
    {
      "severity": "medium",
      "description": "No logging in the polish loop orchestrator — failures will be impossible to debug",
      "location": "src/orchestrator.js",
      "recommendation": "Add structured logging for each iteration start, review result, fix result, and guard trigger"
    },
    {
      "severity": "medium",
      "description": "Acceptance criterion #3 has no corresponding test",
      "location": "tests/",
      "recommendation": "Add integration test verifying cards move automatically when phase changes"
    }
  ]
}
```

**Plan mode example:**
```json
{
  "critical": 1,
  "medium": 3,
  "minor": 4,
  "issues": [
    {
      "severity": "critical",
      "description": "No contingency plan for outdoor weather — acceptance criteria #5 not met",
      "location": "Section 4: Venue",
      "recommendation": "Add indoor backup venue option with cost comparison"
    },
    {
      "severity": "critical",
      "description": "OPA Framework missing — plan does not open with Outcome/Purpose/Action Scope table",
      "location": "Document header",
      "recommendation": "Add OPA table per framework template before all procedural content"
    },
    {
      "severity": "medium",
      "description": "Catering section lists vendors but no pricing or capacity info",
      "location": "Section 6: Catering",
      "recommendation": "Add estimated cost per head and max capacity for each vendor"
    }
  ]
}
```

**Step 2 — Fix (apply recommendations):**

The orchestrator passes the JSON issue list and recommendations to the fixer agent, which applies them to the scoped code.

### Convergence Guards

| Guard | Condition | Action |
|---|---|---|
| **Termination (success)** | `critical == 0` AND `medium < 3` AND `minor < 5` | Done. Ping human via Telegram. |
| **Hallucination** | Error count spikes after a downward trend | Stop. Flag it. Ping human. |
| **Scope drift** | Issues reference code outside target files/scope in `constraints.md` | Stop. Flag it. Ping human. |
| **Stagnation** | Same error count for 3+ consecutive iterations, no meaningful change | Stop. Flag it. Ping human. |
| **Fabrication** | Model starts inventing issues outside the target code or flagging non-issues just to report something | Stop. Flag it. Ping human. |
| **Max iterations** | Hard ceiling reached (configurable, default 50) | Stop. Ping human with current state. |

### Loop State Persistence

After each iteration, write to `polish_state.json`:

- Current iteration number
- Error counts (critical, medium, minor)
- Convergence trajectory (array of past counts)
- Timestamp

If the Node process crashes mid-loop, it reads `polish_state.json` on restart and resumes from the last completed iteration instead of starting over. Git history preserves the codebase state at each iteration.

### Orchestrator Logic

**Code mode** (Plan mode skips test execution):

```
for each iteration (max from config):
    run Review call → parse JSON
    log iteration number, error counts, test results, timestamp to polish_state.json

    if critical == 0 AND medium < 3 AND minor < 5 AND all tests pass → DONE
    if error count spiked after downward trend → HALT (hallucination)
    if same counts for 3+ iterations → HALT (stagnation)
    if issues reference out-of-scope code → HALT (scope drift)

    git commit snapshot
    run Fix call → write updated files
    run tests → log results
    git commit snapshot
```

**Plan mode:**

```
for each iteration (max from config):
    run Review call → parse JSON
    log iteration number, error counts, timestamp to polish_state.json

    if critical == 0 AND medium < 3 AND minor < 5 → DONE
    if error count spiked after downward trend → HALT (hallucination)
    if same counts for 3+ iterations → HALT (stagnation)
    if issues reference out-of-scope content → HALT (scope drift)

    git commit snapshot
    run Fix call → write updated document
    git commit snapshot
```

### Structured Output Validation

The review call must return valid JSON. The orchestrator:

- Validates the JSON parses correctly
- Validates the schema has the required fields (`critical`, `medium`, `minor`, `issues`)
- On malformed output: retries the review call (max 2 retries)
- On repeated failure: halts and pings human

### Output

- **Plan mode:** Polished plan document in `.md` format, stored in `/docs/` subdirectory of the project git repo. Ready for human final review. If the human approves, this plan can be fed into a new Code mode pipeline as input.
- **Code mode:** Polished codebase.
- `polish_log.md` — iteration-by-iteration error counts, convergence trajectory, total iterations, duration

---

## UI

### ThoughtForge Chat (Built)

ThoughtForge provides the chat interface for Phases 1 and 2 — where the human brain dumps, reviews, corrects, and confirms. This is a lightweight terminal or web chat, not a full app.

- Per-project chat thread
- Used for brain dump, corrections, confirmations, and AI pings
- Supports file/resource dropping (or references a project resource directory)
- AI messages labeled by phase (distilling, reviewing, building, polishing)
- Chat-based confirmation: human says "approved" to advance, or gives corrections to loop

### Vibe Kanban Dashboard (Integrated, Not Built)

Vibe Kanban provides the kanban board, dashboard, and execution visualization. ThoughtForge pushes tasks to Vibe Kanban and reads status back.

- Columns map to ThoughtForge phases: **Brain Dump → Distilling → Human Review → Confirmed → Spec Building → Coding → Polishing → Done**
- Each card = one ThoughtForge project or objective
- Cards move as Vibe Kanban tasks progress
- Cards show which agent is executing (Claude Code, Gemini CLI, Codex, etc.)
- VS Code extension for in-IDE visibility
- Parallel execution with git worktree isolation — handled by Vibe Kanban, not ThoughtForge

### Per-Card Stats (via Vibe Kanban + ThoughtForge Logs)

- Created timestamp
- Time spent in each phase
- Total duration
- Polish loop: iteration count, error counts per iteration, convergence trajectory (from `polish_log.md`)
- Status: running / waiting on human / done / stuck
- Agent used (for comparing performance across different AI agents on same task)

### Model/Agent Performance Comparison

- Same task run with different agents shows iteration count, time, and convergence speed differences
- Helps decide which agent performs best for which type of work
- Data comes from ThoughtForge's `polish_log.md` and `polish_state.json`, displayed via Vibe Kanban's dashboard or a simple ThoughtForge report

---

## Configuration

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
  telegram_bot_token: ""
  telegram_chat_id: ""

# AI Agents — configure which agents are available
agents:
  default: "claude"
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

# Vibe Kanban integration
vibekanban:
  enabled: true
```

---

## Human Touchpoints Summary

| Touchpoint | Phase | What Human Does |
|---|---|---|
| 1 | Brain Dump | Dumps idea + drops resources |
| 2 | Review | Corrects AI's distilled understanding (1-3 rounds via chat) |
| 3 | Confirm | Confirms intent is right, optionally overrides spec decisions and acceptance criteria |
| 4 | Final Review | Reviews finished polished output |

Everything between touchpoints 3 and 4 is fully autonomous.

---

## Key Design Decisions Log

These decisions were made across three design conversations and one audit review:

1. **Dual deliverable types: Plan and Code** — the tool handles both. Plans are documents (wedding, engineering design, strategy). Code is software. Each project card declares its type in Phase 1.
2. **Pipeline chaining: Plan must be complete before Code** — a plan and its code implementation are two separate pipeline runs. The plan must be fully polished and human-approved before it becomes input for a code pipeline. The tool does NOT auto-chain them. The human decides when a plan is ready and manually creates the code pipeline with the finished plan as input.
3. **Each parallel project gets its own git repo** — clean isolation, no shared mutable state.
4. **Chat-based confirmation over button UI** — "approved" or "item 3 is wrong" parsed by AI. Natural, no extra UI components.
5. **Acceptance criteria added to `constraints.md`** — prevents polish loop from producing a clean deliverable that's missing what was asked for. Reviewer checks both quality AND "does this meet the acceptance criteria."
6. **Structured output validation with retry** — JSON from review call is validated and retried on failure, not blindly trusted.
7. **Polish state persistence** — `polish_state.json` written after each iteration so the loop can resume after a crash.
8. **No agent frameworks** — Vibe Kanban handles agent spawning and execution. ThoughtForge handles the loop logic. No LangGraph/AutoGen/CrewAI needed in between.
9. **Phase 1 distillation prompt specified** — structured intake (objectives, assumptions, constraints, unknowns, open questions) reduces human correction rounds from 5 to 1-2.
10. **Plan mode hard-blocks all code execution at the orchestrator level** — not just prompt instructions. If deliverable type is Plan, the orchestrator refuses to spawn CLI processes, create source files, or run anything. A Plan mode run that accidentally builds code is a total failure that wastes human time on the wrong thing at the wrong phase.
11. **Code mode requires logging and tests as part of the deliverable** — logging is mandatory throughout the codebase. Tests (unit, integration, acceptance) are mandatory. Every acceptance criterion must have a corresponding test. The Phase 4 reviewer treats missing logging as a medium flaw and missing acceptance test coverage as a critical flaw. Tests run after every fix iteration.
12. **Plan Completeness Gate on Code mode entry** — when a Code mode pipeline receives a plan document as input, the AI assesses whether the plan is actually complete enough to build from. If it's a brain dump, rough outline, or has open decisions, the tool redirects to Plan mode automatically. Human can override, but the default is strict: 80% complete is not complete.
13. **All plan deliverables follow the OPA Framework** — every plan document opens with the OPA table (Outcome, Purpose, Action Scope) and every major section within the plan gets its own OPA table. This is both a structural requirement during Phase 3 drafting and a review criterion during Phase 4 polish. A plan missing OPA structure is a critical flaw. Reference: `.shareddocs/opa_framework.md`
14. **Vibe Kanban as the execution and visualization layer** — instead of building a custom kanban UI, ThoughtForge integrates with Vibe Kanban (free, open source, YC-backed). Vibe Kanban handles the kanban board, parallel task execution, git worktree isolation, multi-agent spawning, dashboard, and VS Code extension. ThoughtForge handles the intelligence: brain dump intake, plan mode, constraint discovery, polish loop logic, and convergence guards. This cuts build scope roughly in half.
15. **Multi-agent support: Claude Code CLI, Gemini CLI, Codex CLI** — not locked to one AI provider. Different agents can be used for different tasks or compared on the same task. Agent selection is per-project in config. Vibe Kanban natively supports all of these.

---

*ThoughtForge Pipeline Tool | OPA Framework (Tony Robbins' RPM System)*
