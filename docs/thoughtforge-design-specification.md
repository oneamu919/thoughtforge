# ThoughtForge Pipeline Tool — Design Specification

> **Companion to:** [ThoughtForge Requirements Brief](./thoughtforge-requirements-brief.md)

---

## Overview

**What is being designed:** An autonomous pipeline tool that takes a human brain dump and produces a polished deliverable (plan document or working code) through structured phases with convergence-based polish loops.

---

## Functional Design

### Inputs

| Input | Source | Format | Required |
|-------|--------|--------|----------|
| Brain dump | Human via chat | Freeform text | Yes |
| Resources | Human drops into `/projects/{id}/resources/` | Text, PDF, images, code files | No |
| Notion pages | Human provides page URL(s) via chat or config | Pulled as Markdown | No |
| Google Drive documents | Human provides document URL(s) or folder ID via chat or config | Pulled as Markdown/text | No |
| Corrections | Human via chat | Natural language | Yes (Phase 1-2) |
| Confirmation | Human via Confirm button | Button press | Yes (phase advancement) |
| Plan document (chained) | Previous pipeline output in `/projects/{id}/resources/` | `.md` file | Code mode only (optional) |

### Outputs

| Output | Destination | Format |
|--------|-------------|--------|
| `intent.md` | `/projects/{id}/docs/` | Markdown — 6-section distillation |
| `spec.md` | `/projects/{id}/docs/` | Markdown — locked spec with all decisions |
| `constraints.md` | `/projects/{id}/docs/` | Markdown — review rules + acceptance criteria |
| Plan deliverable | `/projects/{id}/docs/` | Markdown — OPA-structured document |
| Code deliverable | `/projects/{id}/` | Working codebase with tests and logging |
| `polish_log.md` | `/projects/{id}/` | Markdown — iteration-by-iteration log |
| `polish_state.json` | `/projects/{id}/` | JSON — loop state for crash recovery |
| `status.json` | `/projects/{id}/` | JSON — current phase and metadata |

### Behavior

#### Phase 1 — Brain Dump & Discovery

**Primary Flow:**

0. **Project Initialization:** Human initiates a new project via the ThoughtForge chat interface (e.g., a "New Project" command or button). ThoughtForge generates a unique project ID, creates the `/projects/{id}/` directory structure (including `/docs/` and `/resources/` subdirectories), initializes a git repo, writes an initial `status.json` with phase `brain_dump`, and opens a new chat thread. If Vibe Kanban integration is enabled, a corresponding card is created at this point.

**Agent Assignment:** The agent specified in `config.yaml` `agents.default` is assigned to the project at initialization and stored in `status.json` as the `agent` field. This determines which AI agent is used for all pipeline phases. Per-project agent override is deferred — not a current build dependency.

1. Human brain dumps into chat
2. Human drops files/resources into `/resources/` directory
3. If external resource connectors are configured (Notion, Google Drive), the human provides page URLs or document links via chat. ThoughtForge pulls the content and saves it to `/resources/` as local files before proceeding to distillation. Connectors are optional — if none are configured, this step is skipped.
4. AI reads all resources (text, PDF, images via vision, code files) and the brain dump
5. AI distills into structured document: Deliverable Type, Objective, Assumptions, Constraints, Unknowns, Open Questions (max 5)
6. AI presents distillation to human in chat
7. Human corrects via chat → AI revises and re-presents
8. Human can say "realign from here" at any message in the correction thread — AI discards all revisions after that message and re-distills from that point forward. Does not restart from the original brain dump.
9. Human clicks **Confirm** button → advances to Phase 2
10. Output: `intent.md` written to `/docs/` and locked — no further modification by AI in subsequent phases. Human may still edit manually outside the pipeline.

**Brain Dump Intake Prompt Behavior:** The prompt enforces: organize only (no AI suggestions or improvements), structured output (6 sections as listed above), maximum 5 open questions (prioritized by blocking impact), ambiguities routed to Unknowns. Full prompt text in build spec.

**Confirmation model:** Chat-based corrections, button-based confirmation. Corrections are natural language in chat. Phase advancement uses an explicit Confirm button to eliminate misclassification. This applies to all human confirmation points.

**Phase 1 Error Handling:**

| Condition | Action |
|---|---|
| Agent failure during distillation (timeout, crash, empty response) | Same retry behavior as agent communication layer: retry once, halt and notify on second failure. Chat resumes from last recorded message. |
| Brain dump is empty or trivially short (fewer than ~10 words) | AI responds in chat asking the human to provide more detail. Does not advance to distillation. |
| Resource file unreadable (corrupted, unsupported format) | AI logs the unreadable file, notifies the human in chat specifying which file(s) could not be read, and proceeds with distillation using available inputs. |
| Connector authentication failure (expired token, missing credentials) | Log the failure, notify the human in chat specifying which connector failed and why, and proceed with distillation using available inputs. Do not halt the pipeline. |
| Connector target not found (deleted page, revoked access, invalid URL) | Log the failure, notify the human in chat specifying which resource could not be retrieved, and proceed with distillation using available inputs. |

**Phase-to-State Mapping:** Pipeline phases map to `status.json` phase values as follows: Phase 1 = `brain_dump` (initial intake) → `distilling` (AI processing brain dump) → `human_review` (human correcting distillation). Phase 2 = `spec_building`. Phase 3 = `building`. Phase 4 = `polishing`. Terminal states: `done` and `halted`. Vibe Kanban columns mirror these values directly.

**Project Lifecycle After Completion:** Once a project reaches `done` or `halted`, no further pipeline actions are taken. The project directory, git repo, and all state files remain in place for human reference. Project archival, deletion, and re-opening are deferred. Not a current build dependency.

#### Phase 2 — Spec Building & Constraint Discovery

**Primary Flow:**

1. AI proposes deliverable structure and key decisions based on `intent.md`
2. AI challenges weak or risky decisions present in `intent.md` — missing dependencies, unrealistic constraints, scope gaps, contradictions — with specific reasoning. Does not rubber-stamp.
3. AI resolves Unknowns and Open Questions from `intent.md` — either by making a reasoned decision (stated in `spec.md`) or by asking the human during the Phase 2 chat. No unresolved unknowns may carry into `spec.md`.
4. AI extracts 5-10 acceptance criteria from `intent.md`
5. Human confirms or overrides specific decisions
6. Human reviews acceptance criteria — adds/removes as needed
7. Before advancement: AI validates that all Unknowns and Open Questions from `intent.md` have been resolved (either by AI decision in `spec.md` or by human input during Phase 2 chat). If unresolved items remain, the Confirm button is blocked and the AI presents the remaining items to the human.
8. Human clicks **Confirm** → advances to Phase 3
9. Outputs: `spec.md` and `constraints.md` written to `/docs/` and locked — no further modification by AI in subsequent phases. Human may still edit manually outside the pipeline.

**Phase 2 Error Handling:**

| Condition | Action |
|---|---|
| AI cannot resolve an Unknown from `intent.md` through reasoning | AI presents the Unknown to the human in the Phase 2 chat for decision. No unresolved Unknowns may carry into `spec.md`. |
| Agent failure during Phase 2 conversation (timeout, crash, empty response) | Same retry behavior as agent communication layer: retry once, halt and notify on second failure. Chat resumes from last recorded message in `chat_history.json`. |
| Human has not responded to a Phase 2 question for an extended period | No automatic action. Project remains in `spec_building` state. Notification sent as a reminder (configurable — deferred, not a current build dependency). |

**Plan Mode behavior:** Proposes plan structure following OPA Framework — every major section gets its own OPA table. Pushes back like a real planner.

**Code Mode behavior:** Proposes build spec (language, OS, framework, tools, dependencies, architecture). Runs Open Source Discovery before proposing custom-built components. Every OSS recommendation includes the 8-signal qualification scorecard (signals, red flags, and minimum qualification threshold defined in build spec).

**`spec.md` structure:**

| Section | Description |
|---|---|
| Deliverable Overview | What is being built/planned, restated from `intent.md` Objective |
| Deliverable Structure | Proposed structure of the deliverable (plan sections or code architecture) |
| Key Decisions | Each decision the AI made or the human confirmed, with rationale |
| Resolved Unknowns | Every Unknown and Open Question from `intent.md`, with resolution and source (AI-reasoned or human-provided) |
| Dependencies | External tools, services, data, or prerequisites required |
| Scope Boundaries | What is explicitly included and excluded |

Plan mode: Deliverable Structure contains proposed plan sections following OPA Framework. Code mode: Deliverable Structure contains proposed architecture, language, framework, and tools (including OSS qualification results where applicable).

**`constraints.md` structure:**

| Section | Description |
|---|---|
| Context | What this deliverable does (from `intent.md`) |
| Deliverable Type | Plan or Code |
| Priorities | What the human cares about |
| Exclusions | What not to touch, what not to flag |
| Severity Definitions | What counts as critical / medium / minor |
| Scope | Plan mode: sections/topics in scope. Code mode: files/functions in scope. |
| Acceptance Criteria | 5-10 statements of what the deliverable must contain or do |

#### Phase 3 — Build (Autonomous)

**Plan Mode:**

1. Orchestrator loads plan plugin (`/plugins/plan/builder.js`)
2. Selects appropriate Handlebars template from `/plugins/plan/templates/`
3. Template selection is driven by the Deliverable Type classification from `intent.md`. The template directory uses a naming convention (e.g., `wedding.hbs`, `engineering.hbs`, `strategy.hbs`). If no type-specific template matches, the `generic.hbs` template is used as the default. Template selection logic lives in the plan plugin's `builder.js`.
4. Template defines OPA skeleton as fixed structure — AI fills content slots but cannot break structure
5. Fills every section — no placeholders, no "TBD"
6. **NEVER creates source files, runs commands, installs packages, scaffolds projects, or executes anything. Document drafting only. Enforced at orchestrator level via plugin safety rules.**
7. If stuck on a decision requiring human input: notifies and waits
8. Output: complete but unpolished plan document (`.md`) in `/docs/`

**Code Mode:**

1. Orchestrator loads code plugin (`/plugins/code/builder.js`)
2. Codes the project using configured agent via Vibe Kanban
3. Implements logging throughout the codebase (mandatory)
4. Writes tests: unit, integration, and acceptance (each acceptance criterion from `constraints.md` must have a corresponding test)
5. Runs all tests, fixes failures, iterates until passing
6. If stuck: notifies and waits
7. Output: working but unpolished codebase

**Stuck Detection (Phase 3):**

| Mode | Stuck Condition | Action |
|---|---|---|
| Plan | AI response explicitly states it cannot proceed without human input (parsed from response) | Notify and wait |
| Code | Build agent returns non-zero exit after 2 consecutive retries on the same task, OR test suite fails on the same tests for 3 consecutive fix attempts | Notify and wait |

**Phase 3 Stuck Recovery:**

When Phase 3 stuck detection triggers, the human is notified with context (deliverable type, what the AI is stuck on, current build state). The human has two options, presented as buttons in the ThoughtForge chat interface:

| Option | What Happens |
|---|---|
| Provide Input | Human provides the needed decision or clarification via chat. The builder resumes from where it stopped using the human's input. `status.json` remains in `building` state. |
| Terminate | Human stops the project. Status set to `halted` permanently. |

Phase 3 does not offer an Override option — unlike Phase 4, there is no partially complete deliverable worth accepting. The builder either needs the input to continue or the project is abandoned.

Recovery follows the same confirmation model as Phase 4: explicit button presses, not chat-parsed commands. Terminate requires a single confirmation step.

**Phase 3 Error Handling:**

| Condition | Action |
|---|---|
| Agent failure (timeout, crash, empty response) during build | Same retry behavior as agent communication layer: retry once, halt and notify on second failure. |
| Template rendering failure (Plan mode) | Halt and notify human with error details. No retry — template errors indicate a structural problem, not a transient failure. |
| File system error (cannot write to project directory) | Halt and notify human immediately. No retry. |

**Phase 3 → Phase 4 Transition:** Automatic. When the Phase 3 builder completes successfully (plan document drafted or codebase built and tests passing), the orchestrator writes a git commit, updates `status.json` to `polishing`, sends a milestone notification ("Phase 3 complete. Deliverable built. Polish loop starting."), and immediately begins Phase 4. No human confirmation is required — this is within the autonomous window between Touchpoints 3 and 4.

**Code Mode Testing Requirements:**

| Test Type | What It Covers | When It Runs |
|---|---|---|
| Unit tests | Core functions and logic in isolation | Phase 3 + Phase 4 |
| Integration tests | Components working together | Phase 3 + Phase 4 |
| Acceptance tests | Each acceptance criterion has a corresponding test | Phase 3 + Phase 4 |

#### Phase 4 — Polish Loop (Fully Automated)

**Each Iteration — Two Steps:**

**Step 1 — Review (do not fix):** AI reviews scoped deliverable + `constraints.md` (including acceptance criteria). Outputs ONLY a JSON error report. Does not fix anything.

**Step 2 — Fix (apply recommendations):** Orchestrator passes JSON issue list to fixer agent, which applies fixes. Git commit snapshot after each step.

**Convergence Guards:**

| Guard | Condition | Action |
|---|---|---|
| Termination (success) | Error counts within configured thresholds (+ all tests pass for code). Thresholds in `config.yaml`. | Done. Notify human. |
| Hallucination | Error count spikes sharply after a sustained downward trend | Halt. Notify human: "Fix-regress cycle detected. Errors trending down then spiked. Iteration [N]: [X] total (was [Y]). Review needed." |
| Stagnation | Total count plateaus across consecutive iterations AND issue rotation detected (new issues replacing old ones at the same rate — the loop is churning, not degrading) | Done (success). Notify human: "Polish sufficient. Ready for final review." |
| Fabrication | A severity category spikes well above its recent average, AND the system had previously approached convergence thresholds — suggesting the reviewer is manufacturing issues because nothing real remains | Halt. Notify human. |
| Max iterations | Hard ceiling reached (configurable, default 50) | Halt. Notify human: "Max [N] iterations reached. Avg flaws/iter: [X]. Lowest: [Y] at iter [Z]. Review needed." |

Algorithmic parameters for each guard (spike thresholds, similarity measures, window sizes) are defined in the build spec.

**Loop State Persistence:** `polish_state.json` written after each iteration (iteration number, error counts, convergence trajectory, timestamp). On crash, resumes from last completed iteration.

**Halt Recovery:**

When a convergence guard halts the loop, the human is notified with context (guard type, iteration number, error state). The human has three options:

| Option | What Happens |
|---|---|
| Resume | Human reviews the state, optionally makes manual edits to the deliverable, then resumes the polish loop from the next iteration. `polish_state.json` is preserved. |
| Override | Human marks the current state as acceptable. Loop terminates as successful. Equivalent to manual convergence. |
| Terminate | Human stops the project. Status set to `halted` permanently. |

Recovery is initiated through the ThoughtForge chat interface. The halted card remains in the Polishing column with a visual halted indicator until the human acts.

**Halt Recovery Interaction:** When the chat interface presents a halted state, it displays three action buttons: Resume, Override, and Terminate. These follow the same confirmation model as phase advancement — explicit button presses, not chat-parsed commands. Before Override or Terminate, the interface prompts the human to confirm the action (single confirmation step).

**Count Derivation:** Orchestrator ignores top-level count fields. Derives counts from the `issues` array by counting per severity. Top-level counts remain for human readability in logs only.

#### Plan Completeness Gate (Code Mode Entry)

When a Code mode pipeline starts and a plan document is detected in `/resources/`, the AI assesses whether the plan is complete enough to build from. This is a prompt-based AI judgment — not a mechanical gate. The AI is given the completeness signals below as evaluation criteria and returns a pass/fail recommendation with reasoning.

**Completeness signals (prompt guidance, not a scored rubric):** OPA Framework structure present, specific objectives (not vague), decisions made (not options listed), enough detail to build without guessing, acceptance criteria defined, no TBD/placeholders, clear scope boundaries, dependencies listed.

If the AI recommends fail: the tool automatically creates a Plan mode card, moves the document there, and notifies the human. Human can override, but default is redirect.

**Plan → Code Chaining Workflow:** To chain a completed plan into a code pipeline, the human creates a new project and places the finished plan document into the new project's `/resources/` directory. The new project proceeds through Phase 1 as normal — the plan document is one of the resources the AI reads during brain dump intake. At Phase 3 entry, the Plan Completeness Gate evaluates the plan and either proceeds or redirects as described above. The two projects are independent — separate project IDs, directories, git repos, and pipeline states.

#### Plan Mode Safety Guardrails

**Plan mode NEVER builds, executes, compiles, installs, or runs code. Ever.**

| Rule | What It Prevents |
|---|---|
| No CLI agent execution | No coding agents, shell commands, package installs during Plan mode Phases 3-4 |
| No file creation outside plan docs | No `.js`, `.py`, `.ts`, `.sh` files. Only `.md` in `/docs/` and `.json` state files |
| No "quick prototype" | AI cannot build something to validate the plan |
| No test execution | Plan quality assessed by review loop only |
| Phase 3 = document drafting only | No project scaffolding or boilerplate |
| Phase 4 = document review only | Does not evaluate if code snippets would compile |

**Enforcement:** Orchestrator loads plugin's `safety-rules.js` which declares blocked operations. Enforced at orchestrator level, not by prompting.

---

## Technical Design

### Architecture — Two Layers

**ThoughtForge** is the intelligence layer — brain dump intake, plan mode, constraint discovery, polish loop logic, convergence guards. It creates and manages the work.

**Vibe Kanban** is the execution and visualization layer — kanban board, parallel task execution, agent spawning, git worktree isolation, dashboard, VS Code integration. It runs and displays the work.

ThoughtForge creates tasks → pushes them to Vibe Kanban → Vibe Kanban executes via coding agents → ThoughtForge monitors results and runs convergence logic.

### ThoughtForge Stack

| Component | Technology | Why |
|---|---|---|
| Runtime | Node.js | Already installed (via OpenClaw), single runtime |
| Core | Node.js CLI + orchestration logic | Intelligence layer: Phase 1-2 chat, polish loop, convergence guards, plan mode enforcement |
| AI Agents | Claude Code CLI, Gemini CLI, Codex CLI | Multi-agent support, flat-rate subscriptions |
| Project State | File-based: `/projects/{id}/` with `/docs/` subdirectory | Human-readable, git-trackable. State access wrapped in single module for future DB swap |
| Version Control | Git — each project gets its own repo | Rollback built in. Separate repos for clean parallel isolation |
| Notifications | ntfy.sh (Apache 2.0) with abstraction layer | One HTTP POST, no tokens needed. Abstraction supports adding channels via config |
| Resource Connectors | Notion API, Google Drive API — with abstraction layer | Optional external resource intake for Phase 1. Abstraction layer follows same pattern as notification channels: config-driven, pluggable. Connector pulls content and writes to local `/resources/` directory. |
| Config | `config.yaml` at project root | Thresholds, max iterations, concurrency, agent prefs, notification channels |
| Prompts | External `.md` files in `/prompts/` | Human-editable pipeline prompts. Not embedded in code. Settings UI reads/writes directly. |
| Schema Validation | Zod (MIT, TypeScript-first) | Single-source review JSON schema. Auto-validation with clear errors |
| Template Engine | Handlebars (MIT) | OPA skeleton as fixed structure. AI fills slots, can't break structure |
| Plugin Architecture | Convention-based: `/plugins/{type}/` | Self-contained per deliverable type. Orchestrator delegates, no if/else branching |
| Operational Logging | Node.js built-in (`console` or structured logger) | ThoughtForge logs its own operations — agent invocations, phase transitions, convergence guard evaluations, errors, and halt events — to a per-project `thoughtforge.log` file. Separate from `polish_log.md` (which is the human-readable iteration log). Used for debugging, not human review. |
| MCP (Future) | Model Context Protocol | Core actions as clean standalone functions for future MCP wrapping. Deferred. Not a current build dependency. |

**Git Commit Strategy:** Each project's git repo is initialized at project creation. Commits occur at: `intent.md` lock (end of Phase 1), `spec.md` and `constraints.md` lock (end of Phase 2), Phase 3 build completion, and after every Phase 4 review and fix step. This ensures rollback capability at every major pipeline milestone.

### Vibe Kanban (Execution Layer — Integrated, Not Built)

| What It Provides | How ThoughtForge Uses It |
|---|---|
| Kanban board UI | Visualize pipeline phases as cards moving across columns |
| Parallel execution | Run multiple projects simultaneously across agents |
| Git worktree isolation | Each task in its own worktree — clean parallel isolation |
| Multi-agent support | Claude Code, Gemini CLI, Codex, Amp, Cursor CLI |
| VS Code extension | Task status inside the IDE |
| Dashboard / stats | Timing, agent performance, progress tracking |

### Vibe Kanban Integration Interface

ThoughtForge communicates with Vibe Kanban via its CLI through four operations: task creation (project initialization), status updates (every phase transition), agent work execution (Phase 3 build, Phase 4 fix steps), and result reading (after each agent execution). All integration calls centralized in `vibekanban-adapter.js`. ThoughtForge never calls Vibe Kanban directly from orchestrator logic. Exact CLI commands and flags in build spec.

**Vibe Kanban toggle behavior:** The `vibekanban.enabled` config controls Kanban card creation, status updates, and dashboard visualization. When disabled, ThoughtForge invokes agents directly via the agent layer for all phases — no Kanban cards are created or updated. Parallel execution management without Vibe Kanban is the human's responsibility. Plan mode functions identically with the toggle on or off — the plan builder always invokes agents directly via the agent layer. Code mode, when VK is enabled, executes agent work through Vibe Kanban (`vibekanban task run`); when VK is disabled, the code builder invokes agents directly via the agent layer. Both modes function fully with the toggle off; the only loss is the Kanban board view and automated parallel execution.

### Plugin Folder Structure

Each plugin folder contains: a builder (Phase 3 drafting/coding), a reviewer (Phase 4 schema and severity definitions), safety rules (blocked operations), and any type-specific assets (e.g., Handlebars templates for Plan, test runner for Code). Full folder structure and filenames in build spec.

### Plugin Interface Contract

Plugin interface contract (function signatures, parameters, return types) defined in build spec. Includes builder.js (Phase 3), reviewer.js (Phase 4), safety-rules.js, and discovery.js (optional Phase 2 hook — used by Code plugin for OSS qualification scorecard).

### Zod Review Schemas

**Review JSON structure:** Both modes produce a JSON error report with per-severity issue counts and an issues array. Each issue includes severity, description, location, and recommendation. Code mode additionally includes test results (total, passed, failed). Exact Zod schemas in build spec.

**Validation flow:** Parse AI response as JSON → validate via Zod safeParse → on failure: retry (max configurable, default 2) → on repeated failure: halt and notify human.

### Agent Communication

ThoughtForge invokes agents via CLI subprocess calls, passing prompts via file or stdin. Agent-specific adapters normalize output format differences. Invocation details in build spec.

**Failure handling:**
- Non-zero exit, timeout, or empty output → retry once
- Second failure → halt and notify human
- Timeout configurable via `config.yaml` (`agents.call_timeout_seconds`, default 300)

### Notification Content

Every phase transition pings the human with a status update. Every notification includes structured context:

| Field | Description |
|---|---|
| project_id | Unique project identifier |
| project_name | Human-readable project name. Derived during Phase 1 distillation: the AI extracts or generates a short name from the brain dump and includes it as the title of `intent.md`. Stored in `status.json` as `project_name` after `intent.md` is locked. |
| phase | Current phase |
| event_type | `convergence_success`, `guard_triggered`, `human_needed`, `milestone_complete`, `error` |
| summary | One-line description with actionable context |

**Notification Examples:**
- `"Project 'Wedding Plan' — polish loop converged. 0 critical, 1 medium, 3 minor. Ready for final review."`
- `"Project 'API Backend' — fix-regress cycle detected. Errors trending down (42→28→19) then spiked to 31 at iteration 12. Review needed."`
- `"Project 'CLI Tool' — polish sufficient. Ready for final review."`
- `"Project 'Dashboard' — fabrication suspected at iteration 9. Errors were near-converged (0 critical, 2 medium, 4 minor) then spiked. The reviewer may be manufacturing issues because nothing real remains. Loop halted."`
- `"Project 'Mobile App' — max 50 iterations reached. Avg flaws/iter: 12. Lowest: 6 at iter 38. Review needed."`
- `"Project 'API Backend' — Phase 1 complete. Intent locked."`
- `"Project 'API Backend' — Phase 2 complete. Spec and constraints locked. Build starting."`
- `"Project 'API Backend' — Phase 3 complete. Deliverable built. Polish loop starting."`
- `"Project 'CLI Tool' — Phase 2 spec building. AI stuck on ambiguity: should auth use JWT or session cookies? Decision needed."`

### Project State Files

| File | Written When | Schema |
|---|---|---|
| `status.json` | Every phase transition and state change | Tracks project name, current phase, deliverable type, assigned agent, timestamps, and halt reason. Full schema in build spec. |
| `polish_state.json` | After each Phase 4 iteration | Iteration number, error counts, convergence trajectory, timestamp |
| `polish_log.md` | Appended after each Phase 4 iteration | Human-readable iteration log |
| `chat_history.json` | Appended after each chat message (Phases 1–2, Phase 3 stuck recovery, Phase 4 halt recovery) | Array of timestamped messages (role, content, phase). On crash, chat resumes from last message. Cleared after each phase advancement confirmation (Phase 1 → Phase 2 and Phase 2 → Phase 3), so each phase starts with a fresh chat history. Phase 3 and Phase 4 recovery conversations are also persisted. |

**`polish_log.md` entry format:** Each entry includes: iteration number, timestamp, error counts (critical/medium/minor/total), which convergence guard was evaluated and its result, summary of issues found, summary of fixes applied, and test results (code mode only). Entries are appended in Markdown with a heading per iteration (e.g., `## Iteration 7`).

### UI

**ThoughtForge Chat (Built):** Lightweight terminal or web chat. Primary use: Phases 1-2 (brain dump intake, spec building). Also used for Phase 4 halt recovery (resume, override, terminate actions). Per-project chat thread, file/resource dropping, AI messages labeled by phase, corrections via chat, advancement via Confirm button. During halt recovery, the chat presents the halted state context and the three recovery options — no free-form AI conversation.

**Prompt Management:** The chat interface includes a Settings button that opens a prompt editor. All pipeline prompts — brain dump intake, review, fix, and any future prompts — are listed, viewable, and editable by the human. Edits apply globally (all future projects use the updated prompts). Per-project prompt overrides are deferred. Not a current build dependency. Prompts are stored as external files in a `/prompts/` directory, not embedded in code. The prompt editor reads from and writes to these files.

**Vibe Kanban Dashboard (Integrated, Not Built):** Columns map to `status.json` phases: Brain Dump → Distilling → Human Review → Spec Building → Building → Polishing → Done. "Confirmed" is not a separate column — confirmation advances the card from Human Review to the next phase. Cards with `halted` status remain in their current column with a visual halted indicator; "Halted" is a card state, not a column. Each card = one project. Shows agent, status, parallel execution.

**Per-Card Stats:** Created timestamp, time per phase, total duration, status, and agent used are provided by Vibe Kanban's built-in dashboard. Polish loop metrics (iteration count, convergence trajectory, final error counts) are read from `polish_state.json` in each project directory. ThoughtForge does not push stats to Vibe Kanban — Vibe Kanban reads the project files directly.

**Plan vs. Code Column Display:** Plan mode cards pass through the same Kanban columns. The "Building" column represents Phase 3 (autonomous build) for both deliverable types — document drafting for Plans, coding for Code. Column labels are not mode-specific. The card's `deliverable_type` field in `status.json` distinguishes the two in the dashboard.

**Agent Performance Comparison:** Vibe Kanban's dashboard surfaces timing and agent data natively. ThoughtForge enables comparison by writing iteration count, convergence speed, and final error counts to `polish_state.json`, which Vibe Kanban reads per-card.

### Future Extensibility: MCP

Orchestrator core actions (create project, check status, read polish log, trigger phase advance, read convergence state) are clean standalone functions with no CLI-specific coupling. Wrapping as MCP tools later is a thin adapter, not a refactor.

---

## Design Decisions

| # | Decision | Rationale |
|---|----------|-----------|
| 1 | Dual deliverable types: Plan and Code | Tool handles both documents and software via plugin architecture |
| 2 | Pipeline chaining: Plan must be complete before Code | Two separate runs. Plan polished and human-approved before becoming code input |
| 3 | Each project gets its own git repo | Clean isolation, no shared mutable state |
| 4 | Chat-based corrections, button-based confirmation | Natural corrections, unambiguous phase advancement |
| 5 | Acceptance criteria in `constraints.md` | Prevents polish loop from missing what was asked for |
| 6 | Zod for structured output validation | Single-source schema, auto-validation, clear errors |
| 7 | Polish state persistence | `polish_state.json` enables crash recovery |
| 8 | No agent frameworks | Vibe Kanban handles spawning, ThoughtForge handles logic |
| 9 | Structured Phase 1 distillation prompt | Reduces correction rounds from 5 to 1-2 |
| 10 | Plan mode hard-blocks code execution via plugin safety rules | Orchestrator-level enforcement, not prompt-level |
| 11 | Code mode requires logging and tests | Logging mandatory, acceptance criteria must have tests |
| 12 | Plan Completeness Gate on Code mode entry | AI assesses plan readiness, redirects if incomplete |
| 13 | All plans follow OPA Framework | Structural requirement and review criterion |
| 14 | Vibe Kanban as execution layer | Cuts build scope roughly in half |
| 15 | Multi-agent support | Not locked to one provider, agents compared on same task |
| 16 | ntfy.sh with abstraction layer | Open source, self-hostable, extensible via config |
| 17 | Zod over hand-written validation | MIT, TypeScript-first, standard in Node.js ecosystem |
| 18 | MCP-ready architecture (design-time only) | Clean functions now, thin adapter later |
| 19 | Handlebars for Plan mode templates | Fixed OPA skeleton, AI can't break structure |
| 20 | Plugin architecture for deliverable types | New type = new folder, orchestrator unchanged |
| 21 | OSS discovery with qualification scorecard | 8-signal assessment before recommending any tool |

---

## Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Polish loop never converges | Medium | High | Convergence guards (hallucination, fabrication, max iterations) halt and notify. Stagnation treated as successful plateau. |
| AI ignores plan mode safety rules | Low | High | Orchestrator-level enforcement via plugin safety-rules.js, not prompt-level |
| Vibe Kanban CLI changes break integration | Medium | Medium | All calls through `vibekanban-adapter.js` — single update point |
| Agent timeout blocks loop indefinitely | Medium | High | Configurable timeout (default 300s), subprocess killed on exceed |
| Review JSON malformed | Medium | Low | Zod validation + 2 retries, then halt |

---

## Configuration

| Config Area | What's Configurable | Defaults |
|---|---|---|
| Polish loop | Convergence thresholds (critical, medium, minor max), max iterations, stagnation limit, malformed output retries | 0 / 3 / 5 / 50 / 3 / 2 |
| Concurrency | Max parallel runs | 3 |
| Notifications | Channel selection (ntfy, telegram, etc.), channel-specific settings | ntfy enabled, topic "thoughtforge" |
| Resource Connectors | Connector selection (Notion, Google Drive, etc.), per-connector credentials and settings | All disabled by default |
| Agents | Default agent, call timeout, per-agent command and flags | claude, 300s |
| Templates | Template directory path | `./plugins/plan/templates` (plan mode templates live inside the plan plugin) |
| Plugins | Plugin directory path | `./plugins` |
| Prompts | Prompt directory path, individual prompt files | `/prompts/`, one `.md` file per prompt |
| Vibe Kanban | Enabled toggle | true |

Full `config.yaml` with all keys and structure in build spec.

---

*Template Version: 1.0 | Last Updated: February 2026*
