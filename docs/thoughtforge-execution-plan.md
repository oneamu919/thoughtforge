# ThoughtForge Pipeline Tool — Execution Plan

> **Companion to:** [ThoughtForge Design Specification](./thoughtforge-design-specification.md) | [ThoughtForge Build Spec](./thoughtforge-build-spec.md)

---

## Overview

**What is being executed:** Build the ThoughtForge Pipeline Tool — an autonomous brain-dump-to-polished-deliverable pipeline integrated with Vibe Kanban.

**Design Specification Reference:** [thoughtforge-design-specification.md](./thoughtforge-design-specification.md)

**Target Completion:** TBD

---

## Design Decisions

**Implementation language:** The codebase uses TypeScript. Zod schemas and interface definitions in the build spec use TypeScript syntax. The build toolchain includes `tsc` compilation. (If JavaScript-only is preferred, replace TypeScript interfaces with JSDoc type annotations and use Zod's runtime-only validation.)

**Module system:** ESM (`"type": "module"` in `package.json`). All imports use ESM `import` syntax. `tsconfig.json` uses `"module": "nodenext"` and `"moduleResolution": "nodenext"`. This aligns with Vitest's native ESM support and Node.js ≥18's stable ESM implementation.

**Pre-build decision: Test framework.** Choose Vitest or Jest before Task 1 begins. Both are compatible. Vitest is recommended for ESM-native support and faster execution with TypeScript projects (no separate compilation step for tests).

**TypeScript execution model:** ThoughtForge runs via `tsx` (or `ts-node`) during development and compiles to JavaScript via `tsc` for production deployment. Vitest handles TypeScript natively for tests (no separate compilation step). The `package.json` `start` script runs the compiled output; a `dev` script runs via `tsx` for live development.

---

## Task Breakdown

> **Estimates:** Task-level time estimates and milestone target dates will be populated before build begins. Current task breakdown reflects scope and dependencies only.

### Build Stage 1: Foundation & Project Scaffolding

| # | Task | Owner | Depends On | Estimate | Status |
|---|------|-------|------------|----------|--------|
| 1 | Initialize Node.js project with TypeScript: `tsconfig.json` (`"module": "nodenext"`, `"moduleResolution": "nodenext"`), `package.json` with ESM (`"type": "module"`), `start` script targeting compiled output, `dev` script using `tsx` for development, `build` script running `tsc`, and folder structure. Install initial dependencies (per build spec Initial Dependencies). Implement `config.yaml` loader with Zod schema validation. | — | — | — | Not Started |
| 1a | Implement application entry point: Node.js server startup, config initialization, local web server for chat interface. Including graceful shutdown handler: on SIGTERM/SIGINT, send WebSocket close frame (code 1001) to all connected clients, wait for in-progress agent subprocesses (up to configured timeout), then exit. | — | Task 1 | — | Not Started |
| 1b | Implement first-run setup: `config.yaml.example` copied to `config.yaml` on first run if missing (with comment guidance), prerequisite check (Node.js ≥18 LTS, agent CLIs on PATH), startup validation summary | — | Task 1 | — | Not Started |
| 1c | Implement server restart recovery (per design spec Server Restart Behavior): resume interactive-state projects, halt autonomous-state projects, notify human for halted projects | — | Task 1a, Task 3, Task 5 | — | Not Started |
| 2 | Implement project initialization sequence (per build spec Project Initialization Sequence): ID generation, directory scaffolding, git init, initial state, Vibe Kanban card (if enabled), chat thread creation | — | Task 1 | — | Not Started |
| 2a | Implement git commit at pipeline milestones: `intent.md` lock (end of Phase 1), `spec.md` and `constraints.md` lock (end of Phase 2), Phase 3 build completion (including the Phase 3→4 transition commit). Phase 4 per-iteration commits (after each review step and after each fix step) are handled in Task 40. | — | Task 2 | — | Not Started |
| 3 | Implement project state module (`status.json`, `polish_state.json` read/write) with atomic write default (write to temp file, rename to target) for all state files. Include `status.json` error handling: halt and notify on unreadable, missing, or invalid status.json (parse failure, missing file, invalid phase value) — no recovery or partial loading | — | Task 1 | — | Not Started |
| 3a | Implement operational logging module (per-project `thoughtforge.log`, structured entries for agent calls, phase transitions, guard evaluations, halts, errors, config/plugin loading). All tasks that produce loggable events (Tasks 1, 6, 6a, 33–37, 41) must call this module — logging integration is the responsibility of each event-producing task, not a separate wiring task. | — | Task 1 | — | Not Started |
| 4 | Implement notification abstraction layer + ntfy.sh channel | — | Task 1 | — | Not Started |
| 5 | Implement phase transition notifications (ping human on every milestone) | — | Task 3, Task 4 | — | Not Started |
| 6 | Set up plugin loader (reads `/plugins/{type}/`, validates interface contract) | — | Task 1 | — | Not Started |
| 6a | Implement pipeline orchestrator: phase sequencing based on `status.json`, plugin selection by `deliverable_type`, safety-rules enforcement (call plugin `validate(operation)` before every Phase 3/4 action), cross-cutting file system error handling (halt and notify on file system failures — both read failures on critical state files and write failures — no retry) | — | Task 2, Task 3, Task 6 | — | Not Started |
| 6b | Implement Phase 2→3 transition: Plan Completeness Gate trigger for Code mode, advancement logic | — | Task 6a, Task 6d | — | Not Started |
| 6c | Implement Phase 3→4 automatic transition including output validation (per design spec Phase 3→4 Transition Error Handling: verify expected output files exist and meet `config.yaml` `phase3_completeness` criteria before entering Phase 4), Phase 3 stuck recovery interaction (Provide Input / Terminate buttons), and milestone notification. Implement `phase3_completeness` config-driven validation: Plan mode checks deliverable character count against `config.yaml` `phase3_completeness.plan_min_chars`. Code mode checks for at least one test file when `phase3_completeness.code_require_tests` is true. Both checks run before Phase 4 entry. | — | Task 5, Task 6a, Task 7 | — | Not Started |
| 6d | Implement Plan Completeness Gate: assessment prompt for Code mode Phase 3 entry (loaded from `/prompts/completeness-gate.md`), halt with `plan_incomplete` on fail, present Override and Terminate buttons in chat (Override resumes build, Terminate halts permanently) | — | Task 7a, Task 6e, Tasks 41–42 | — | Not Started |
| 6e | Draft `/prompts/completeness-gate.md` prompt text | — | Task 7a | — | Not Started |

### Build Stage 2: Human Interaction Layer (Pipeline Phases 1–2)

> **Cross-stage dependency:** Task 12 depends on Task 25 (OSS discovery, Build Stage 4) for Code mode Phase 2 only. Plan mode Phase 2 does not use OSS discovery and can be implemented and tested before Task 25 is complete.

| # | Task | Owner | Depends On | Estimate | Status |
|---|------|-------|------------|----------|--------|
| 7 | Build ThoughtForge web chat interface: core chat panel with per-project thread, AI message streaming via WebSocket, messages labeled by phase, WebSocket disconnection handling with auto-reconnect and state recovery from `status.json` and `chat_history.json`. Create `/public/` directory with static assets: `index.html` (single-page chat interface), `style.css`, and `app.js` (vanilla JavaScript for WebSocket client, DOM manipulation, project switching, and action buttons). These are served by Express directly — no build tooling or bundler required. | — | Task 1a | — | Not Started |
| 2b | Implement concurrency limit enforcement: block new project creation when active project count (all non-terminal states including `halted`) reaches `config.yaml` `concurrency.max_parallel_runs`, disable "New Project" action in sidebar with message, re-enable when a project reaches terminal state. Note: `halted` is not terminal — halted projects count toward the limit. | — | Task 2, Task 7g | — | Not Started |
| 7g | Implement project list sidebar: list active projects with current phase, click to switch, "New Project" action. Include mid-stream project switch handling: when the human switches projects during AI response streaming, stop rendering the stream for the previous project. Server-side processing continues uninterrupted per design spec. | — | Task 7, Task 2 | — | Not Started |
| 7h | Implement file/resource dropping in chat interface (upload to `/resources/`). Validate that resolved file paths stay within the project's `/resources/` directory — reject uploads with path traversal components (`..`, absolute paths). | — | Task 7 | — | Not Started |
| 7a | Externalize all pipeline prompts to `/prompts/` directory as `.md` files (brain-dump-intake, plan-review, code-review, plan-fix, code-fix, plan-build, code-build, spec-building, completeness-gate) | — | Task 1 | — | Not Started |
| 7b | Implement Settings button in chat interface — prompt editor that lists, views, and saves all prompt files from `/prompts/` directory | — | Task 7, Task 7a | — | Not Started |
| 7c | Implement resource connector abstraction layer — config-driven loader, connector interface (pull → save to `/resources/`), error handling (auth failure, not found → log and continue) | — | Task 1 | — | Not Started |
| 7d | Implement Notion connector — authenticate via API token, pull page content as Markdown, save to `/resources/` | — | Task 7c | — | Not Started |
| 7e | Implement Google Drive connector — authenticate via service account or OAuth, pull document content as text/Markdown, save to `/resources/` | — | Task 7c | — | Not Started |
| 7f | Draft `/prompts/spec-building.md` prompt text | — | Task 7a | — | Not Started |
| 7i | Implement server-side WebSocket reconnection handler: on client reconnect receive project ID, respond with current `status.json` and `chat_history.json`, handle invalid project ID by returning project list | — | Task 7, Task 3 | — | Not Started |
| 8 | Implement Phase 1: brain dump intake (including empty/trivially-short input guard — block distillation and prompt for more detail), resource reading (log and skip unreadable files, notify human, proceed with available inputs), distillation prompt (loaded from `/prompts/brain-dump-intake.md`), Phase 1 sub-state transitions in `status.json` (`brain_dump` → `distilling` on Distill button → `human_review` on distillation complete). Connector integration (Task 7c) is optional — Phase 1 functions fully without connectors. Include ambiguous deliverable type handling per design spec: when brain dump signals both Plan and Code, AI defaults to Plan and flags in Open Questions. Include mid-processing human input queuing: if the human sends a chat message while the AI is processing, queue the message in `chat_history.json` and include it in the next AI invocation's context (per design spec Phase 1 Mid-Processing Human Input). | — | Task 6a, Task 7, Task 7a, Tasks 41–42 | — | Not Started |
| 8a | Implement chat-message URL scanning for resource connectors: match URLs in brain dump chat messages against enabled connector URL patterns (from build spec), auto-pull matched URLs via connector layer, ignore matches for disabled connectors, pass unmatched URLs through as brain dump text | — | Task 8, Task 7c | — | Not Started |
| 9 | Implement correction loop: chat-based revisions with AI re-presentation, and "realign from here" command (per build spec Realign Algorithm) | — | Task 8 | — | Not Started |
| 9a | Implement `chat_history.json` persistence: append after each chat message, clear on Phase 1→2 and Phase 2→3 confirmation only (NOT on Phase 3→4 automatic transition), resume from last recorded message on crash. Include context window truncation logic per build spec Chat History Truncation Algorithm: Phase 1 retains brain dump messages, Phase 2 retains initial AI proposal, Phase 3–4 truncate from beginning with no anchor. Log a warning when truncation occurs. **Include error handling: halt and notify on unreadable, missing, or invalid `chat_history.json` (same behavior as `status.json` corruption).** | — | Task 3, Task 7 | — | Not Started |
| 10 | Implement action buttons: Distill (Phase 1 intake trigger) and Confirm (phase advancement mechanism). Include button debounce: disable on press until operation completes, server-side duplicate request detection (ignore duplicates, return current state). | — | Task 7 | — | Not Started |
| 11 | Implement intent.md generation and locking, project name derivation (extract from H1 or AI-generate), `deliverable_type` derivation (from Deliverable Type section of confirmed intent.md — `"plan"` or `"code"` in status.json), status.json `project_name` and `deliverable_type` update, and Vibe Kanban card name update (if enabled). Include deliverable type parse failure handling: reject values other than "Plan" or "Code", notify human in chat, do not advance. | — | Task 9, Task 2a, Task 26, Tasks 41–42 | — | Not Started |
| 12 | Implement Phase 2: spec building per design spec Phase 2 behavior. Includes mode-specific proposal (Plan: OPA structure; Code: architecture with OSS discovery from Task 25), AI challenge of intent decisions, constraint discovery, acceptance criteria extraction, human review/override, Unknown resolution validation gate, and Confirm advancement. Prompt loaded from `/prompts/spec-building.md`. Including: Unknown resolution validation gate (block Confirm if unresolved Unknowns or Open Questions remain, present remaining items to human), Acceptance Criteria validation gate (block Confirm if Acceptance Criteria section is empty or missing, re-invoke AI once if section heading absent, halt on second failure). | — | Task 6a, Task 10, Task 11, Task 7a, Task 7f, Tasks 41–42; Task 25 (Code mode only — Plan mode can proceed without it) | — | Not Started |
| 13 | Implement `spec.md` and `constraints.md` generation | — | Task 12, Task 2a | — | Not Started |

### Build Stage 3: Plan Mode Plugin

> **Prompt drafting tasks** (15a, 21a) depend only on Task 7a (prompt file directory), not on the surrounding stage tasks. They can begin as soon as Task 7a completes.

| # | Task | Owner | Depends On | Estimate | Status |
|---|------|-------|------------|----------|--------|
| 14 | Create `/plugins/plan/` folder structure | — | Task 6 | — | Not Started |
| 15 | Implement `builder.js` — Handlebars template-driven document drafting, including content escaping for Handlebars syntax characters in AI-generated content, including template rendering failure handling (halt immediately, no retry) | — | Task 6a, Task 14, Task 15a, Tasks 41–42 | — | Not Started |
| 15a | Draft `/prompts/plan-build.md` prompt text | — | Task 7a | — | Not Started |
| 16 | Create OPA skeleton Handlebars templates (generic, wedding, strategy, engineering) | — | Task 15 | — | Not Started |
| 17 | Implement `reviewer.js` — Plan review Zod schema + severity definitions | — | Task 14 | — | Not Started |
| 18 | Implement `safety-rules.js` — hard-block all code execution in plan mode | — | Task 14 | — | Not Started |

### Build Stage 4: Code Mode Plugin

> **Cross-stage dependency:** Code mode builder (Task 21) depends on Vibe Kanban operations (Task 27, Build Stage 5). Build Stage 5 Tasks 26–27 must be completed before Task 21 can begin. Remaining Build Stage 4 tasks (22–25) have no cross-stage dependencies.

| # | Task | Owner | Depends On | Estimate | Status |
|---|------|-------|------------|----------|--------|
| 20 | Create `/plugins/code/` folder structure | — | Task 6 | — | Not Started |
| 21 | Implement `builder.js` — agent-driven coding (via Vibe Kanban when enabled, direct agent invocation when disabled) | — | Task 6a, Task 20, Task 21a, Task 27, Task 29a, Tasks 41–42 | — | Not Started |
| 21a | Draft `/prompts/code-build.md` prompt text | — | Task 7a | — | Not Started |
| 21b | Implement Code mode Phase 3 test-fix cycle: run tests → pass failures to agent → fix → retest loop. Including stuck detection: halt after 2 consecutive non-zero exits on same task, or 3 consecutive identical failing test sets (exact string match on test names). | — | Task 21, Task 24 | — | Not Started |
| 22 | Implement `reviewer.js` — Code review Zod schema + severity definitions | — | Task 20 | — | Not Started |
| 23 | Implement `safety-rules.js` — Code mode permissions | — | Task 20 | — | Not Started |
| 24 | Implement `test-runner.js` — test execution, result logging | — | Task 20 | — | Not Started |
| 25 | Implement `discovery.js` — OSS qualification scorecard for Phase 2 Code mode | — | Task 20 | — | Not Started |

### Build Stage 5: Vibe Kanban Integration

| # | Task | Owner | Depends On | Estimate | Status |
|---|------|-------|------------|----------|--------|
| 25a | Verify Vibe Kanban CLI interface: confirm actual commands, flags, and output format match assumed interface in build spec. Update build spec if discrepancies found. | — | — | — | Not Started |
| 26 | Build `vibekanban-adapter.js` — centralized CLI wrapper | — | Task 1 | — | Not Started |
| 27 | Implement task create, update, run, result read operations | — | Task 26 | — | Not Started |
| 28 | Map ThoughtForge phases to Vibe Kanban columns | — | Task 27 | — | Not Started |
| 29 | Integration test: Vibe Kanban adapter handles concurrent card creation, status updates, and agent execution for 2+ projects without interference | — | Task 28 | — | Not Started |
| 29a | Implement VK-disabled fallback: direct agent invocation path when `vibekanban.enabled` is false | — | Task 26, Tasks 41–42 | — | Not Started |

### Build Stage 6: Polish Loop Engine

| # | Task | Owner | Depends On | Estimate | Status |
|---|------|-------|------------|----------|--------|
| 30 | Implement orchestrator loop: review call → parse → validate → fix call → commit. Guard evaluation per build spec Guard Evaluation Order (first trigger ends evaluation). Include plan mode fix output validation per design spec: after each plan mode fix, validate the returned content is non-empty and not less than 50% of the pre-fix document size. Reject invalid fix output, preserve pre-fix document, log warning. Halt after 2 consecutive rejected fix outputs. | — | Task 3, Task 6a, Task 6c, Task 17, Task 22, Tasks 30a–30b, Tasks 41–42 | — | Not Started |

> **Note:** Tasks 31, 32, 38, and 39 are implemented within the Task 30 orchestrator module, not as separate files. They are listed separately for progress tracking.

| 30a | Draft `/prompts/plan-review.md` and `/prompts/plan-fix.md` prompt text | — | Task 7a | — | Not Started |
| 30b | Draft `/prompts/code-review.md` and `/prompts/code-fix.md` prompt text | — | Task 7a | — | Not Started |
| 30c | Implement Code mode iteration cycle: test execution via `test-runner.js` before review, test results passed as reviewer context. Distinguish test runner crashes (process error — retry once, halt on second) from test assertion failures (pass to reviewer as context). | — | Task 24, Task 30 | — | Not Started |
| 31 | Implement Zod validation flow (safeParse, retry on failure, halt after max retries) | — | Task 30 | — | Not Started |
| 32 | Implement count derivation from issues array (ignore top-level counts) — extends Task 30 orchestrator | — | Task 30 | — | Not Started |
| 33 | Implement convergence guard: termination (success) | — | Task 30 | — | Not Started |
| 33a | Implement convergence guard: fix regression (per-iteration check — compare post-fix error count to pre-fix review count, warn on single occurrence, halt on 2 consecutive regressions). Evaluated immediately after each fix step, before other guards. | — | Task 30 | — | Not Started |
| 34 | Implement convergence guard: hallucination detection | — | Task 30 | — | Not Started |
| 35 | Implement convergence guard: stagnation (count + issue rotation via Levenshtein) | — | Task 30 | — | Not Started |
| 36 | Implement convergence guard: fabrication detection | — | Task 30 | — | Not Started |
| 37 | Implement max iteration ceiling | — | Task 30 | — | Not Started |
| 38 | Implement `polish_state.json` persistence + crash recovery (resume from last iteration) — extends Task 30 orchestrator | — | Task 30 | — | Not Started |
| 39 | Implement `polish_log.md` append after each iteration — extends Task 30 orchestrator | — | Task 30 | — | Not Started |
| 40 | Implement Phase 4 per-iteration git auto-commits: commit after each review step and after each fix step (two commits per iteration) | — | Task 30 | — | Not Started |
| 40a | Implement Phase 4 halt recovery interaction (resume, override, terminate buttons in chat) | — | Task 30, Task 7 | — | Not Started |
| 40b | Implement Phase 3/4 live status display in chat panel: Phase 4 shows iteration number, error counts, trajectory direction, guard result after each iteration; Phase 3 shows current build step. Read from `polish_state.json` and builder progress. Update via WebSocket push after each iteration/step completes. | — | Task 7, Task 30, Task 38 | — | Not Started |

### Build Stage 7: Agent Layer

| # | Task | Owner | Depends On | Estimate | Status |
|---|------|-------|------------|----------|--------|
| 41 | Implement agent invocation: prompt file → subprocess via stdin pipe (no shell interpolation of prompt content) → capture stdout | — | Task 1 | — | Not Started |
| 42 | Implement agent-specific adapters (Claude, Gemini, Codex output normalization) | — | Task 41 | — | Not Started |
| 43 | Implement failure handling: retry once, halt on second failure | — | Task 41 | — | Not Started |
| 44 | Implement configurable timeout + subprocess kill | — | Task 41 | — | Not Started |

### Build Stage 8: Integration Testing & Polish

**Testing Strategy:** Unit tests (Tasks 45–50c, 58–58k) use mocked dependencies — no real agent CLI calls, no real file system for state tests, no real API calls for connectors. End-to-end tests (Tasks 51–57) run the full pipeline with real agent invocations against a test project. Synthetic convergence guard tests (Task 54) use fabricated `polish_state.json` data, not real polish loop runs.

| # | Task | Owner | Depends On | Estimate | Status |
|---|------|-------|------------|----------|--------|
| 45 | Unit tests: project state module (`status.json`, `polish_state.json` read/write, crash recovery) | — | Task 3, Task 38 | — | Not Started |
| 46 | Unit tests: plugin loader (interface contract validation, missing plugin handling) | — | Task 6 | — | Not Started |
| 47 | Unit tests: convergence guards (termination, hallucination, stagnation, fabrication, max iterations — each with synthetic inputs) | — | Tasks 33–37, Task 33a | — | Not Started |
| 47b | Unit tests: fix regression guard (single regression logs warning, 2 consecutive regressions halt, non-consecutive regressions reset counter, first iteration has no prior to compare) | — | Task 33a | — | Not Started |
| 47a | Unit tests: count derivation (derives counts from issues array, ignores top-level count fields, handles empty issues array, handles mismatched top-level counts) | — | Task 32 | — | Not Started |
| 48 | Unit tests: agent adapters (output normalization, failure handling, timeout) | — | Tasks 41–44 | — | Not Started |
| 49 | Unit tests: resource connectors (pull success, auth failure, not found — with mocked API responses) | — | Tasks 7c–7e | — | Not Started |
| 50 | Unit tests: notification layer (channel routing, structured context, send failure handling) | — | Tasks 4–5 | — | Not Started |
| 50a | Unit tests: config loader (missing file exits with path, invalid YAML exits with error, schema violations exit identifying invalid key, no partial loading) | — | Task 1 | — | Not Started |
| 51 | End-to-end test: Plan mode pipeline (brain dump → polished plan) | — | All above | — | Not Started |
| 52 | End-to-end test: Code mode pipeline (brain dump → polished code) | — | All above | — | Not Started |
| 53 | End-to-end test: Plan → Code chaining (finished plan as Code mode input) | — | Task 51, Task 52 | — | Not Started |
| 53a | End-to-end test: Plan Completeness Gate (pass with complete plan, fail with incomplete plan, Override proceeds to build, Terminate halts project) | — | Task 6d, Task 53 | — | Not Started |
| 54 | Test all convergence guards with synthetic edge cases | — | Tasks 33–37 | — | Not Started |
| 55 | Test crash recovery (kill mid-loop, verify resume) | — | Task 38 | — | Not Started |
| 56 | Test parallel execution (3 concurrent projects, different agents) | — | Task 29 | — | Not Started |
| 57 | Test VK-disabled fallback (full pipeline without Vibe Kanban) | — | Task 29a | — | Not Started |
| 58 | Unit tests: prompt editor (list prompt files, read content, save edits, handle missing/corrupt files) | — | Task 7b | — | Not Started |
| 58a | Unit tests: chat interface (WebSocket message delivery, AI response streaming, phase-labeled messages, project thread switching) | — | Task 7, Task 7g | — | Not Started |
| 58b | Unit tests: action buttons (Distill triggers distillation, Confirm advances phase, button state disabled during processing, server-side duplicate request ignored and returns current state, Phase 4 halt recovery buttons, Phase 3 stuck recovery buttons) | — | Task 10, Task 40a | — | Not Started |
| 58c | Unit tests: file/resource dropping (upload to `/resources/`, unsupported file handling, concurrent uploads) | — | Task 7h | — | Not Started |
| 58d | Unit tests: "realign from here" command (identifies correct baseline message, excludes post-correction messages, re-distills with corrections, ignores command when no prior corrections exist) | — | Task 9 | — | Not Started |
| 58e | Unit tests: Phase 3 stuck recovery (Provide Input resumes builder with human input while staying in `building` state, Terminate sets `halted`, stuck detection triggers correctly for both Plan and Code modes) | — | Task 6c | — | Not Started |
| 58f | Unit tests: WebSocket reconnection (auto-reconnect on disconnect, state sync from `status.json` and `chat_history.json` on reconnect, connection status indicator shown during disconnect, in-flight responses not replayed, server handles invalid project ID on reconnect) | — | Task 7i | — | Not Started |
| 58g | Unit tests: concurrency limit enforcement (block new project at max, count halted as active, re-enable on terminal state, sidebar message displayed) | — | Task 2b | — | Not Started |
| 58h | Unit tests: server restart recovery (interactive states resume, autonomous states halted with `server_restart` reason, notifications sent for halted projects, terminal states ignored) | — | Task 1c | — | Not Started |
| 58i | Unit tests: resource file processing (text read, PDF extraction, image vision routing, unsupported format skip, file size limit enforcement) | — | Task 8 | — | Not Started |
| 58j | Unit tests: plan mode safety guardrails (`safety-rules.js` blocks `shell_exec`, `file_create_source`, `package_install`, `test_exec` operations; allows `file_create_doc`, `file_create_state`, `agent_invoke`, `git_commit`) | — | Task 18 | — | Not Started |
| 58k | Unit tests: Vibe Kanban adapter failure handling (visualization-only call failures logged and pipeline continues, agent execution call failures trigger retry-once-then-halt, VK disabled skips all calls) | — | Tasks 26–29a | — | Not Started |
| 50b | Unit tests: first-run setup (missing config creates from example, prerequisite check reports missing CLIs, valid config passes startup) | — | Task 1b | — | Not Started |
| 50c | Unit tests: operational logging module (log file creation, structured JSON format, log levels, event types, file append failure handling) | — | Task 3a | — | Not Started |
| 58l | Unit tests: chat history truncation (Phase 1 truncation retains brain dump messages, drops middle messages, retains recent; Phase 2 truncation retains initial proposal; warning logged on truncation; empty history handled; history below window size passed through unchanged) | — | Task 9a | — | Not Started |
| 58m | Unit tests: OSS discovery scorecard (8-signal evaluation, red flag detection on Age/Last Updated/License, minimum 6-of-8 qualification threshold, handles missing signal data gracefully) | — | Task 25 | — | Not Started |

---

## Critical Path

The longest dependency chain determines the minimum build duration regardless of parallelism:

**Task 1 → Task 41 → Task 42 → Task 6a → Task 8 → Task 9 → Task 11 → Task 12 → Task 13 → Task 15 → Task 6c → Task 30 → Tasks 33–37 → Task 51**

The functional critical path includes Task 13 → Task 15 → Task 6c even though Task 6c's code dependency is on Task 6a, because Phase 3→4 transition cannot be exercised without Phase 2 outputs (spec.md, constraints.md) and a Phase 3 builder producing deliverables.

This chain runs from foundation through agent layer, human interaction, plan plugin, polish loop, to plan-mode e2e validation.

**Secondary critical chain (Code mode):** Task 1 → Task 41 → Task 42 (parallel with Task 26 → Task 27) → Task 6a → Task 21 → Task 30c → Task 52. The agent layer (41–42) and VK adapter (26–27) are parallel branches that both feed into Task 21.

Build schedule and parallelism decisions should optimize for keeping the critical path unblocked.

## Parallelism Opportunities

The following task groups can be executed concurrently:
- **After Task 1:** Stage 1 foundation (Tasks 2–6a, 3a, 4–5) and Stage 7 agent layer (Tasks 41–44) — no cross-dependencies
- **After Tasks 41–42:** All prompt drafting tasks (7a, 7f, 6e, 15a, 21a, 30a, 30b) — depend only on Task 7a
- **After Task 6:** Stage 3 (Tasks 14–18) and Stage 4 (Tasks 20, 22–25) — independent plugin implementations
- **After Task 26:** Task 27 (VK operations) and Task 29a (VK-disabled fallback) — independent paths
- **Stage 8 unit tests:** All unit test tasks within a stage are independent and can run in parallel once their source tasks complete

**Parallelism note:** Tasks 41-42 (agent invocation layer) gate every task that calls an AI agent. These should be prioritized immediately after Task 1 completes, as they are the single biggest bottleneck across both critical paths. All Build Stage 1 foundation tasks (2-6a) and Stage 7 tasks (41-44) can run in parallel once Task 1 is done.

---

## Task Acceptance Criteria

Each task is complete when:
1. The described functionality works as specified in the design specification and build spec sections referenced by the task
2. The task's own unit tests (if a corresponding test task exists in Build Stage 8) pass with mocked dependencies
3. Any logging events produced by the task are routed through the operational logging module (Task 3a)
4. The implementation follows the interface contracts defined in the build spec (plugin interface, connector interface, notification payload, state file schemas)
5. For tasks that depend on a "To be drafted" prompt (identified in the build spec by "Used by" references): the AI coder drafts the prompt text as the first step of the task, writes it to the `/prompts/` directory, and the human reviews and edits via the Settings UI before the task proceeds to implementation. The prompt text is committed alongside the task's implementation code.

AI coders should reference the "Used by" annotations in the build spec to identify the authoritative specification for each task.

### Prompt Drafting Guidelines

Each "To be drafted" prompt must:
1. Implement all behavioral requirements from the design spec section it serves (e.g., `/prompts/spec-building.md` must implement the Phase 2 autonomy principle: decide autonomously for low-risk decisions, escalate high-impact ones).
2. Require structured output where the design spec mandates it (e.g., `PlanBuilderResponse` JSON for plan-build, review JSON for review prompts).
3. Include the `constraints.md` re-read instruction for Phase 4 prompts (review and fix).
4. Reference the specific Zod schema the AI's output must conform to (for review prompts).
5. Be testable — the prompt's expected behavior should be verifiable during e2e tests (Tasks 51–53).

### Prompt Validation Strategy

Each pipeline prompt ("To be drafted" prompts in build spec) is validated during the end-to-end tests (Tasks 51–53). The e2e tests serve as the primary prompt quality gate — if the pipeline produces acceptable deliverables end-to-end, the prompts are working. If an e2e test fails due to poor AI output quality (rather than code bugs), the prompt is revised and the test re-run. Prompt iteration is expected during Build Stage 8 and is not a sign of implementation failure.

---

## Milestones

| Milestone | Target Date | Deliverable | Exit Criteria |
|-----------|-------------|-------------|---------------|
| Foundation complete | TBD | Project scaffolding, state module, config, notifications, plugin loader, orchestrator core | Tasks 1–6a, 3a, and 4–5 done. Tasks 6b–6e complete after their Stage 2 dependencies. |
| Human interaction working | TBD | Phase 1 & 2 chat flow functional | Brain dump → intent → spec → constraints flow works end-to-end |
| Plan mode functional | TBD | Full Plan pipeline runs | Brain dump → polished plan document with OPA structure |
| Code mode functional | TBD | Full Code pipeline runs | Brain dump → polished codebase with tests |
| Polish loop hardened | TBD | All convergence guards active | All guards tested with synthetic edge cases, crash recovery works |
| v1 complete | TBD | Full tool operational | All e2e tests pass, parallel execution works, agent comparison works |

---

## Dependencies & Blockers

| Item | Type | Owner | Status | Resolution |
|------|------|-------|--------|------------|
| Vibe Kanban installed and CLI accessible | Dependency | — | — | Install before Build Stage 5 |
| Node.js available (via OpenClaw) | Dependency | — | — | Pre-existing |
| Claude Code CLI / Gemini CLI / Codex CLI access | Dependency | — | — | Flat-rate subscriptions active |
| ntfy.sh accessible (cloud or self-hosted) | Dependency | — | — | Free cloud tier or self-host |
| Vibe Kanban CLI interface documented | Dependency | — | — | Verify actual CLI matches assumed commands in adapter |
| Notion API token (integration token with read access to target pages) | Dependency | — | — | Create Notion integration before connector build |
| Google Drive API credentials (service account or OAuth client) | Dependency | — | — | Set up credentials before connector build |
| Node.js version ≥18 LTS | Dependency | — | — | Required for native fetch, stable ES module support |
| Package manager: npm | Dependency | — | — | Default Node.js package manager, no additional install |

---

## Risk Register

| Risk | Probability | Impact | Contingency |
|------|------------|--------|-------------|
| Vibe Kanban CLI differs from assumed interface | Medium | Medium | All calls through adapter — single update point |
| Polish loop doesn't converge on real projects | Medium | High | Test with multiple real brain dumps during Phase 8 |
| Agent output formats change across versions | Low | Medium | Agent adapters isolate format changes |
| Handlebars templates too rigid for some plan types | Low | Low | Add new templates, adjust slot flexibility |
| Agent CLI changes mid-build (flag deprecation, output format change) | Low | High | Agent adapters isolate changes. Pin agent CLI versions during build. Run adapter unit tests on each agent update. |
| Cross-stage dependency chain delays (Stage 7 → Stage 2 → Stage 4) | Medium | Medium | Begin Build Stage 7 (agent layer) immediately after Task 1. Track critical path separately from stage numbering. |

---

## Rollback Strategy

Each project's per-milestone git commits enable rollback at the project level. For ThoughtForge's own codebase during build:
- Each completed task should be committed to the ThoughtForge repo before starting the next task
- If a task introduces regressions (breaks previously passing tests), revert the task's commit and reattempt
- The builder should not proceed to the next task if the current task's tests fail

---

## Communication

**Status Updates:** TBD — frequency and channel

**Escalation Path:** TBD

---

## Completion Checklist

- [ ] All tasks in Task Breakdown marked complete
- [ ] Plan mode e2e: brain dump → polished OPA-structured plan
- [ ] Code mode e2e: brain dump → polished codebase with tests and logging
- [ ] Plan → Code chaining: finished plan as code input, completeness gate works
- [ ] All 6 convergence guards (including Fix Regression per-iteration check) tested and functional
- [ ] Crash recovery verified (kill mid-loop, resume works)
- [ ] Parallel execution: 3 concurrent projects, different agents
- [ ] Notifications fire with structured context on all event types
- [ ] Plugin interface contract validated (plan + code plugins)
- [ ] Unit tests pass for all core modules (state, plugins, guards, agents, connectors, notifications)
- [ ] `config.yaml` controls all configurable values
- [ ] First-run setup works: `config.yaml.example` copied, prerequisites checked, startup validates
- [ ] Prompt editor: list, view, edit, and save prompt files via Settings UI
- [ ] Retrospective / lessons learned captured (manual activity — not a build task)
- [ ] Chat interface tests pass (WebSocket, streaming, buttons, file drop, project switching)
- [ ] Resource connectors: Notion and Google Drive pull, auth failure handling, disabled connector behavior

---

*Template Version: 1.0 | Last Updated: February 2026*
