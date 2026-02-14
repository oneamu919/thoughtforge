# ThoughtForge Pipeline Tool — Execution Plan

> **Companion to:** [ThoughtForge Design Specification](./thoughtforge-design-specification.md) | [ThoughtForge Build Spec](./thoughtforge-build-spec.md)

---

## Overview

**What is being executed:** Build the ThoughtForge Pipeline Tool — an autonomous brain-dump-to-polished-deliverable pipeline integrated with Vibe Kanban.

**Design Specification Reference:** [thoughtforge-design-specification.md](./thoughtforge-design-specification.md)

**Target Completion:** TBD

---

## Task Breakdown

> **Estimates:** Task-level time estimates and milestone target dates will be populated before build begins. Current task breakdown reflects scope and dependencies only.

### Build Stage 1: Foundation & Project Scaffolding

| # | Task | Owner | Depends On | Estimate | Status |
|---|------|-------|------------|----------|--------|
| 1 | Initialize Node.js project, folder structure, `config.yaml` loader with Zod schema validation (exit with descriptive error on missing file, invalid YAML, or schema violations) | — | — | — | Not Started |
| 1a | Implement application entry point: Node.js server startup, config initialization, local web server for chat interface | — | Task 1 | — | Not Started |
| 1b | Implement first-run setup: `config.yaml.example` copied to `config.yaml` on first run if missing (with comment guidance), prerequisite check (Node.js version, agent CLIs on PATH), startup validation summary | — | Task 1 | — | Not Started |
| 2 | Implement project initialization: unique ID generation, `/projects/{id}/` directory scaffolding (including `/docs/` and `/resources/`), git repo init, initial `status.json` write, Vibe Kanban card creation (if enabled), and new chat thread creation | — | Task 1 | — | Not Started |
| 2a | Implement git commit at pipeline milestones: `intent.md` lock (end of Phase 1), `spec.md` and `constraints.md` lock (end of Phase 2), Phase 3 build completion. Phase 4 per-iteration commits are handled separately in Task 40. | — | Task 2 | — | Not Started |
| 3 | Implement project state module (`status.json`, `polish_state.json` read/write) with atomic write default (write to temp file, rename to target) for all state files | — | Task 1 | — | Not Started |
| 3a | Implement operational logging module (per-project `thoughtforge.log`, structured entries for agent calls, phase transitions, guard evaluations, halts, errors, config/plugin loading). All tasks that produce loggable events (Tasks 1, 6, 6a, 33–37, 41) must call this module — logging integration is the responsibility of each event-producing task, not a separate wiring task. | — | Task 1 | — | Not Started |
| 4 | Implement notification abstraction layer + ntfy.sh channel | — | Task 1 | — | Not Started |
| 5 | Implement phase transition notifications (ping human on every milestone) | — | Task 4 | — | Not Started |
| 6 | Set up plugin loader (reads `/plugins/{type}/`, validates interface contract) | — | Task 1 | — | Not Started |
| 6a | Implement pipeline orchestrator: phase sequencing based on `status.json`, plugin selection by `deliverable_type`, safety-rules enforcement (call plugin `validate(operation)` before every Phase 3/4 action), cross-cutting file system error handling (halt and notify on write failures — no retry) | — | Task 2, Task 3, Task 6 | — | Not Started |
| 6b | Implement Phase 2→3 transition: Plan Completeness Gate trigger for Code mode, advancement logic | — | Task 6a, Task 6d | — | Not Started |
| 6c | Implement Phase 3→4 automatic transition and Phase 3 stuck recovery interaction (Provide Input / Terminate buttons) | — | Task 6a, Task 7 | — | Not Started |
| 6d | Implement Plan Completeness Gate: assessment prompt for Code mode Phase 3 entry (loaded from `/prompts/completeness-gate.md`), halt with `plan_incomplete` on fail — human decides to override or create separate Plan project | — | Task 7a, Task 6e, Tasks 41–42 | — | Not Started |
| 6e | Draft `/prompts/completeness-gate.md` prompt text | — | Task 7a | — | Not Started |

> **Cross-stage dependency:** Agent Layer (Build Stage 7, Tasks 41–44) provides the core agent invocation mechanism used by Stages 2–6. Task 41 depends on Task 1 (foundation), so Build Stage 7 should begin as soon as Task 1 completes, overlapping with the remainder of Build Stage 1. Tasks 41–42 must be complete before any agent-invoking task begins (Tasks 8, 12, 15, 19, 21, and 30).

### Build Stage 2: Human Interaction Layer (Pipeline Phases 1–2)

> **Note:** Task 12 depends on Task 25 (OSS discovery) for Code mode Phase 2 only. Plan mode Phase 2 does not use OSS discovery and can be implemented and tested before Task 25 is complete.

| # | Task | Owner | Depends On | Estimate | Status |
|---|------|-------|------------|----------|--------|
| 7 | Build ThoughtForge web chat interface: core chat panel with per-project thread, AI message streaming via WebSocket, messages labeled by phase | — | Task 1a | — | Not Started |
| 7g | Implement project list sidebar: list active projects with current phase, click to switch, "New Project" action | — | Task 7, Task 2 | — | Not Started |
| 7h | Implement file/resource dropping in chat interface (upload to `/resources/`). Validate that resolved file paths stay within the project's `/resources/` directory — reject uploads with path traversal components (`..`, absolute paths). | — | Task 7 | — | Not Started |
| 7a | Externalize all pipeline prompts to `/prompts/` directory as `.md` files (brain-dump-intake, plan-review, code-review, plan-fix, code-fix, plan-build, code-build, spec-building, completeness-gate) | — | Task 1 | — | Not Started |
| 7b | Implement Settings button in chat interface — prompt editor that lists, views, and saves all prompt files from `/prompts/` directory | — | Task 7, Task 7a | — | Not Started |
| 7c | Implement resource connector abstraction layer — config-driven loader, connector interface (pull → save to `/resources/`), error handling (auth failure, not found → log and continue) | — | Task 1 | — | Not Started |
| 7d | Implement Notion connector — authenticate via API token, pull page content as Markdown, save to `/resources/` | — | Task 7c | — | Not Started |
| 7e | Implement Google Drive connector — authenticate via service account or OAuth, pull document content as text/Markdown, save to `/resources/` | — | Task 7c | — | Not Started |
| 7f | Draft `/prompts/spec-building.md` prompt text | — | Task 7a | — | Not Started |
| 8 | Implement Phase 1: brain dump intake (including empty/trivially-short input guard — block distillation and prompt for more detail), resource reading (log and skip unreadable files, notify human, proceed with available inputs), distillation prompt (loaded from `/prompts/brain-dump-intake.md`), Phase 1 sub-state transitions in `status.json` (`brain_dump` → `distilling` on Distill button → `human_review` on distillation complete) | — | Task 6a, Task 7, Task 7a, Task 7c, Tasks 41–42 | — | Not Started |
| 9 | Implement correction loop: chat-based revisions with AI re-presentation, and "realign from here" command (discard post-correction AI revisions, re-distill from brain dump + corrections up to baseline message) | — | Task 8 | — | Not Started |
| 9a | Implement `chat_history.json` persistence: append after each chat message, clear on Phase 1→2 and Phase 2→3 confirmation only (NOT on Phase 3→4 automatic transition), resume from last recorded message on crash | — | Task 3, Task 7 | — | Not Started |
| 10 | Implement action buttons: Distill (Phase 1 intake trigger) and Confirm (phase advancement mechanism) | — | Task 7 | — | Not Started |
| 11 | Implement intent.md generation and locking, project name derivation (extract from H1 or AI-generate), status.json project_name update, and Vibe Kanban card name update (if enabled) | — | Task 9, Task 2a, Task 26 | — | Not Started |
| 12 | Implement Phase 2: spec building with mode-specific behavior (Plan mode: propose OPA-structured plan sections; Code mode: propose architecture/language/framework/tools with OSS discovery integration from Task 25), AI challenge of weak or risky decisions in `intent.md` (does not rubber-stamp), constraint discovery, acceptance criteria extraction (5–10 per design spec), human review/override of proposed decisions, human review of acceptance criteria, Unknown/Open Question resolution validation gate (block Confirm if unresolved items remain), Confirm to advance | — | Task 6a, Task 10, Task 11, Task 7a, Task 7f, Task 25, Tasks 41–42 | — | Not Started |
| 13 | Implement `spec.md` and `constraints.md` generation | — | Task 12, Task 2a | — | Not Started |

### Build Stage 3: Plan Mode Plugin

| # | Task | Owner | Depends On | Estimate | Status |
|---|------|-------|------------|----------|--------|
| 14 | Create `/plugins/plan/` folder structure | — | Task 6 | — | Not Started |
| 15 | Implement `builder.js` — Handlebars template-driven document drafting, including template rendering failure handling (halt immediately, no retry) | — | Task 6a, Task 14, Task 15a, Tasks 41–42 | — | Not Started |
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
| 22 | Implement `reviewer.js` — Code review Zod schema + severity definitions | — | Task 20 | — | Not Started |
| 23 | Implement `safety-rules.js` — Code mode permissions | — | Task 20 | — | Not Started |
| 24 | Implement `test-runner.js` — test execution, result logging | — | Task 20 | — | Not Started |
| 25 | Implement `discovery.js` — OSS qualification scorecard for Phase 2 Code mode | — | Task 20 | — | Not Started |

### Build Stage 5: Vibe Kanban Integration

| # | Task | Owner | Depends On | Estimate | Status |
|---|------|-------|------------|----------|--------|
| 26 | Build `vibekanban-adapter.js` — centralized CLI wrapper | — | Task 1 | — | Not Started |
| 27 | Implement task create, update, run, result read operations | — | Task 26 | — | Not Started |
| 28 | Map ThoughtForge phases to Vibe Kanban columns | — | Task 27 | — | Not Started |
| 29 | Test parallel execution with multiple concurrent projects | — | Task 28 | — | Not Started |
| 29a | Implement VK-disabled fallback: direct agent invocation path when `vibekanban.enabled` is false | — | Task 26, Tasks 41–42 | — | Not Started |

### Build Stage 6: Polish Loop Engine

| # | Task | Owner | Depends On | Estimate | Status |
|---|------|-------|------------|----------|--------|
| 30 | Implement orchestrator loop: review call → parse → validate → fix call → commit | — | Task 3, Task 6a, Task 6c, Task 17, Task 22, Tasks 30a–30b, Tasks 41–42 | — | Not Started |
| 30a | Draft `/prompts/plan-review.md` and `/prompts/plan-fix.md` prompt text | — | Task 7a | — | Not Started |
| 30b | Draft `/prompts/code-review.md` and `/prompts/code-fix.md` prompt text | — | Task 7a | — | Not Started |
| 30c | Implement Code mode iteration cycle: test execution via `test-runner.js` before review, test results passed as reviewer context. Distinguish test runner crashes (process error — retry once, halt on second) from test assertion failures (pass to reviewer as context). | — | Task 24, Task 30 | — | Not Started |
| 31 | Implement Zod validation flow (safeParse, retry on failure, halt after max retries) | — | Task 30 | — | Not Started |
| 32 | Implement count derivation from issues array (ignore top-level counts) | — | Task 30 | — | Not Started |
| 33 | Implement convergence guard: termination (success) | — | Task 30 | — | Not Started |
| 34 | Implement convergence guard: hallucination detection | — | Task 30 | — | Not Started |
| 35 | Implement convergence guard: stagnation (count + issue rotation via Levenshtein) | — | Task 30 | — | Not Started |
| 36 | Implement convergence guard: fabrication detection | — | Task 30 | — | Not Started |
| 37 | Implement max iteration ceiling | — | Task 30 | — | Not Started |
| 38 | Implement `polish_state.json` persistence + crash recovery (resume from last iteration) | — | Task 30 | — | Not Started |
| 39 | Implement `polish_log.md` append after each iteration | — | Task 30 | — | Not Started |
| 40 | Implement git auto-commit after each review and fix step | — | Task 30 | — | Not Started |
| 40a | Implement Phase 4 halt recovery interaction (resume, override, terminate buttons in chat) | — | Task 30, Task 7 | — | Not Started |

### Build Stage 7: Agent Layer

| # | Task | Owner | Depends On | Estimate | Status |
|---|------|-------|------------|----------|--------|
| 41 | Implement agent invocation: prompt file → subprocess via stdin pipe (no shell interpolation of prompt content) → capture stdout | — | Task 1 | — | Not Started |
| 42 | Implement agent-specific adapters (Claude, Gemini, Codex output normalization) | — | Task 41 | — | Not Started |
| 43 | Implement failure handling: retry once, halt on second failure | — | Task 41 | — | Not Started |
| 44 | Implement configurable timeout + subprocess kill | — | Task 41 | — | Not Started |

### Build Stage 8: Integration Testing & Polish

| # | Task | Owner | Depends On | Estimate | Status |
|---|------|-------|------------|----------|--------|
| 45 | Unit tests: project state module (`status.json`, `polish_state.json` read/write, crash recovery) | — | Task 3, Task 38 | — | Not Started |
| 46 | Unit tests: plugin loader (interface contract validation, missing plugin handling) | — | Task 6 | — | Not Started |
| 47 | Unit tests: convergence guards (termination, hallucination, stagnation, fabrication, max iterations — each with synthetic inputs) | — | Tasks 33–37 | — | Not Started |
| 47a | Unit tests: count derivation (derives counts from issues array, ignores top-level count fields, handles empty issues array, handles mismatched top-level counts) | — | Task 32 | — | Not Started |
| 48 | Unit tests: agent adapters (output normalization, failure handling, timeout) | — | Tasks 41–44 | — | Not Started |
| 49 | Unit tests: resource connectors (pull success, auth failure, not found — with mocked API responses) | — | Tasks 7c–7e | — | Not Started |
| 50 | Unit tests: notification layer (channel routing, structured context, send failure handling) | — | Tasks 4–5 | — | Not Started |
| 50a | Unit tests: config loader (missing file exits with path, invalid YAML exits with error, schema violations exit identifying invalid key, no partial loading) | — | Task 1 | — | Not Started |
| 51 | End-to-end test: Plan mode pipeline (brain dump → polished plan) | — | All above | — | Not Started |
| 52 | End-to-end test: Code mode pipeline (brain dump → polished code) | — | All above | — | Not Started |
| 53 | End-to-end test: Plan → Code chaining (finished plan as Code mode input) | — | Task 51, Task 52 | — | Not Started |
| 54 | Test all convergence guards with synthetic edge cases | — | Tasks 33–37 | — | Not Started |
| 55 | Test crash recovery (kill mid-loop, verify resume) | — | Task 38 | — | Not Started |
| 56 | Test parallel execution (3 concurrent projects, different agents) | — | Task 29 | — | Not Started |
| 57 | Test VK-disabled fallback (full pipeline without Vibe Kanban) | — | Task 29a | — | Not Started |
| 58 | Unit tests: prompt editor (list prompt files, read content, save edits, handle missing/corrupt files) | — | Task 7b | — | Not Started |
| 58a | Unit tests: chat interface (WebSocket message delivery, AI response streaming, phase-labeled messages, project thread switching) | — | Task 7, Task 7g | — | Not Started |
| 58b | Unit tests: action buttons (Distill triggers distillation, Confirm advances phase, button state disabled during processing, Phase 4 halt recovery buttons) | — | Task 10, Task 40a | — | Not Started |
| 58c | Unit tests: file/resource dropping (upload to `/resources/`, unsupported file handling, concurrent uploads) | — | Task 7h | — | Not Started |
| 58d | Unit tests: "realign from here" command (identifies correct baseline message, excludes post-correction messages, re-distills with corrections, ignores command when no prior corrections exist) | — | Task 9 | — | Not Started |
| 58e | Unit tests: Phase 3 stuck recovery (Provide Input resumes builder with human input while staying in `building` state, Terminate sets `halted`, stuck detection triggers correctly for both Plan and Code modes) | — | Task 6c | — | Not Started |
| 50b | Unit tests: first-run setup (missing config creates from example, prerequisite check reports missing CLIs, valid config passes startup) | — | Task 1b | — | Not Started |

---

## Milestones

| Milestone | Target Date | Deliverable | Exit Criteria |
|-----------|-------------|-------------|---------------|
| Foundation complete | TBD | Project scaffolding, state module, config, notifications, plugin loader | All Build Stage 1 tasks done |
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

---

## Risk Register

| Risk | Probability | Impact | Contingency |
|------|------------|--------|-------------|
| Vibe Kanban CLI differs from assumed interface | Medium | Medium | All calls through adapter — single update point |
| Polish loop doesn't converge on real projects | Medium | High | Test with multiple real brain dumps during Phase 8 |
| Agent output formats change across versions | Low | Medium | Agent adapters isolate format changes |
| Handlebars templates too rigid for some plan types | Low | Low | Add new templates, adjust slot flexibility |

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
- [ ] All 5 convergence guards tested and functional
- [ ] Crash recovery verified (kill mid-loop, resume works)
- [ ] Parallel execution: 3 concurrent projects, different agents
- [ ] Notifications fire with structured context on all event types
- [ ] Plugin interface contract validated (plan + code plugins)
- [ ] Unit tests pass for all core modules (state, plugins, guards, agents, connectors, notifications)
- [ ] `config.yaml` controls all configurable values
- [ ] First-run setup works: `config.yaml.example` copied, prerequisites checked, startup validates
- [ ] Prompt editor: list, view, edit, and save prompt files via Settings UI
- [ ] Retrospective / lessons learned captured
- [ ] Chat interface tests pass (WebSocket, streaming, buttons, file drop, project switching)

---

*Template Version: 1.0 | Last Updated: February 2026*
