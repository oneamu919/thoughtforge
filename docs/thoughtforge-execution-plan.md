# ThoughtForge Pipeline Tool — Execution Plan

> **Companion to:** [ThoughtForge Design Specification](./thoughtforge-design-specification.md)

---

## Overview

**What is being executed:** Build the ThoughtForge Pipeline Tool — an autonomous brain-dump-to-polished-deliverable pipeline integrated with Vibe Kanban.

**Design Specification Reference:** [thoughtforge-design-specification.md](./thoughtforge-design-specification.md)

**Target Completion:** TBD

---

## Task Breakdown

### Build Stage 1: Foundation & Project Scaffolding

| # | Task | Owner | Depends On | Estimate | Status |
|---|------|-------|------------|----------|--------|
| 1 | Initialize Node.js project, folder structure, `config.yaml` loader | — | — | — | Not Started |
| 2 | Set up git repo structure (per-project repo creation logic) | — | Task 1 | — | Not Started |
| 3 | Implement project state module (`status.json`, `polish_state.json` read/write) | — | Task 1 | — | Not Started |
| 4 | Implement notification abstraction layer + ntfy.sh channel | — | Task 1 | — | Not Started |
| 5 | Implement phase transition notifications (ping human on every milestone) | — | Task 4 | — | Not Started |
| 6 | Set up plugin loader (reads `/plugins/{type}/`, validates interface contract) | — | Task 1 | — | Not Started |

> **Cross-stage dependency:** Agent Layer (Build Stage 7, Tasks 41–44) provides the core agent invocation mechanism used by Stages 2–6. Tasks 41–42 (agent invocation and adapters) must be completed before any task that invokes an AI agent. Specifically, Tasks 8, 12, 15, 21, and 30 depend on Tasks 41–42. Build Stage 7 should be started in parallel with Build Stage 1, or the builder should reorder stages to place the Agent Layer earlier.

### Build Stage 2: Human Interaction Layer (Pipeline Phases 1–2)

| # | Task | Owner | Depends On | Estimate | Status |
|---|------|-------|------------|----------|--------|
| 7 | Build ThoughtForge chat interface (terminal or lightweight web) | — | Task 1 | — | Not Started |
| 8 | Implement Phase 1: brain dump intake, resource reading, distillation prompt | — | Task 7, Task 41 | — | Not Started |
| 9 | Implement correction loop (chat-based revisions, "realign from here") | — | Task 8 | — | Not Started |
| 10 | Implement Confirm button (phase advancement mechanism) | — | Task 7 | — | Not Started |
| 11 | Implement `intent.md` generation and locking | — | Task 9 | — | Not Started |
| 12 | Implement Phase 2: spec building, constraint discovery, acceptance criteria extraction | — | Task 11, Task 41 | — | Not Started |
| 13 | Implement `spec.md` and `constraints.md` generation | — | Task 12 | — | Not Started |

### Build Stage 3: Plan Mode Plugin

| # | Task | Owner | Depends On | Estimate | Status |
|---|------|-------|------------|----------|--------|
| 14 | Create `/plugins/plan/` folder structure | — | Task 6 | — | Not Started |
| 15 | Implement `builder.js` — Handlebars template-driven document drafting | — | Task 14, Task 41 | — | Not Started |
| 16 | Create OPA skeleton Handlebars templates (generic, wedding, strategy, engineering) | — | Task 15 | — | Not Started |
| 17 | Implement `reviewer.js` — Plan review Zod schema + severity definitions | — | Task 14 | — | Not Started |
| 18 | Implement `safety-rules.js` — hard-block all code execution in plan mode | — | Task 14 | — | Not Started |
| 19 | Implement Plan Completeness Gate (assessment prompt for Code mode entry) | — | Task 18 | — | Not Started |

### Build Stage 4: Code Mode Plugin

> **Cross-stage dependency:** Code mode builder (Task 21) depends on Vibe Kanban operations (Task 27, Build Stage 5). Build Stage 5 Tasks 26–27 must be completed before Task 21 can begin. Remaining Build Stage 4 tasks (22–25) have no cross-stage dependencies.

| # | Task | Owner | Depends On | Estimate | Status |
|---|------|-------|------------|----------|--------|
| 20 | Create `/plugins/code/` folder structure | — | Task 6 | — | Not Started |
| 21 | Implement `builder.js` — agent-driven coding via Vibe Kanban | — | Task 20, Task 27, Task 41 | — | Not Started |
| 22 | Implement `reviewer.js` — Code review Zod schema + severity definitions | — | Task 20 | — | Not Started |
| 23 | Implement `safety-rules.js` — Code mode permissions | — | Task 20 | — | Not Started |
| 24 | Implement `test-runner.js` — test execution, result logging | — | Task 20 | — | Not Started |
| 25 | Implement `discovery.js` — OSS qualification scorecard for Phase 2 Code mode | — | Task 20, Task 12 | — | Not Started |

### Build Stage 5: Vibe Kanban Integration

| # | Task | Owner | Depends On | Estimate | Status |
|---|------|-------|------------|----------|--------|
| 26 | Build `vibekanban-adapter.js` — centralized CLI wrapper | — | Task 1 | — | Not Started |
| 27 | Implement task create, update, run, result read operations | — | Task 26 | — | Not Started |
| 28 | Map ThoughtForge phases to Vibe Kanban columns | — | Task 27 | — | Not Started |
| 29 | Test parallel execution with multiple concurrent projects | — | Task 28 | — | Not Started |

### Build Stage 6: Polish Loop Engine

| # | Task | Owner | Depends On | Estimate | Status |
|---|------|-------|------------|----------|--------|
| 30 | Implement orchestrator loop: review call → parse → validate → fix call → commit | — | Task 3, Task 17, Task 22, Task 41 | — | Not Started |
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

### Build Stage 7: Agent Layer

| # | Task | Owner | Depends On | Estimate | Status |
|---|------|-------|------------|----------|--------|
| 41 | Implement agent invocation: prompt file → subprocess → capture stdout | — | Task 1 | — | Not Started |
| 42 | Implement agent-specific adapters (Claude, Gemini, Codex output normalization) | — | Task 41 | — | Not Started |
| 43 | Implement failure handling: retry once, halt on second failure | — | Task 41 | — | Not Started |
| 44 | Implement configurable timeout + subprocess kill | — | Task 41 | — | Not Started |

### Build Stage 8: Integration Testing & Polish

| # | Task | Owner | Depends On | Estimate | Status |
|---|------|-------|------------|----------|--------|
| 45 | End-to-end test: Plan mode pipeline (brain dump → polished plan) | — | All above | — | Not Started |
| 46 | End-to-end test: Code mode pipeline (brain dump → polished code) | — | All above | — | Not Started |
| 47 | End-to-end test: Plan → Code chaining (finished plan as Code mode input) | — | Task 45, Task 46 | — | Not Started |
| 48 | Test all convergence guards with synthetic edge cases | — | Tasks 33-37 | — | Not Started |
| 49 | Test crash recovery (kill mid-loop, verify resume) | — | Task 38 | — | Not Started |
| 50 | Test parallel execution (3 concurrent projects, different agents) | — | Task 29 | — | Not Started |

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
| Vibe Kanban installed and CLI accessible | Dependency | — | — | Install before Phase 5 |
| Node.js available (via OpenClaw) | Dependency | — | — | Pre-existing |
| Claude Code CLI / Gemini CLI / Codex CLI access | Dependency | — | — | Flat-rate subscriptions active |
| ntfy.sh accessible (cloud or self-hosted) | Dependency | — | — | Free cloud tier or self-host |
| Vibe Kanban CLI interface documented | Dependency | — | — | Verify actual CLI matches assumed commands in adapter |

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
- [ ] `config.yaml` controls all configurable values
- [ ] Retrospective / lessons learned captured

---

*Template Version: 1.0 | Last Updated: February 2026*
