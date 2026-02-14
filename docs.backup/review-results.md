# ThoughtForge Plan Review — Round 2

**Reviewer posture:** Senior dev who will eventually build from this plan.
**Documents reviewed:** Design Specification, Build Spec, Execution Plan (with Requirements Brief as context).
**Prior review:** 13 changes from Round 1 have been applied (commit `ca2b448`).

---

## 1. Writing That's Unclear

### Finding 1 — [Critical] Convergence thresholds contradict between requirements brief and design/build specs

The requirements brief uses strict-less-than (`<3 medium`, `<5 minor`), meaning 3 medium or 5 minor **fails**. The design spec and build spec use inclusive (`<=3`, `<=5`), meaning 3 medium or 5 minor **passes**. This is a one-off discrepancy that changes the pass/fail boundary.

**File:** `thoughtforge-requirements-brief.md`, Success Criteria table, Target column, row "Polish loop convergence"

**Replace:**
`0 critical, <3 medium, <5 minor`

**With:**
`0 critical, ≤3 medium, ≤5 minor (thresholds inclusive — matches config.yaml convergence settings)`

**Also in the same file**, line 9 (Outcome section):

**Replace:**
`0 critical errors, <3 medium, <5 minor`

**With:**
`0 critical errors, ≤3 medium, ≤5 minor`

---

### Finding 2 — [Major] `polish_state.json` description in design spec omits 3 of 7 schema fields

The design spec (Project State Files table, `polish_state.json` row) describes the schema as "Iteration number, error counts, convergence trajectory, timestamp." The build spec schema includes three additional fields critical to crash recovery and halt logic: `tests_passed`, `completed`, and `halt_reason`. A builder reading only the design spec cannot implement crash recovery correctly.

**File:** `thoughtforge-design-specification.md`, Project State Files table, `polish_state.json` row, Schema column.

**Replace:**
`Iteration number, error counts, convergence trajectory, timestamp`

**With:**
`Iteration number, error counts, convergence trajectory, tests passed (null for plan mode), completed flag, halt reason, timestamp. Full schema in build spec.`

---

### Finding 3 — [Major] `halted_reason` vs `halt_reason` — inconsistent field naming across state files

The `status.json` schema in the build spec uses `halted_reason`. The `polish_state.json` schema uses `halt_reason`. The design spec's natural language consistently uses "halt reason." Two different names for the same concept across two state files that builders implement side-by-side will cause confusion and naming drift.

**File:** `thoughtforge-build-spec.md`, `status.json` Schema section.

**Replace:**
`halted_reason: string | null;`

**With:**
`halt_reason: string | null;`

This aligns both state files to `halt_reason`, matching the design spec's natural language.

---

### Finding 4 — [Major] Kanban column mapping claim says "mirror directly" but `halted` is excluded

The design spec states "Vibe Kanban columns mirror these `status.json` values directly" immediately after the phase-to-state mapping table that includes `halted`. Later in the UI section, it explicitly says "Halted is a card state, not a column." The word "directly" is wrong and will mislead a builder into creating a Halted column.

**File:** `thoughtforge-design-specification.md`, after the Phase-to-State Mapping table.

**Replace:**
`Vibe Kanban columns mirror these status.json values directly.`

**With:**
`Vibe Kanban columns correspond to these status.json phase values, except halted — which is a card state indicator, not a separate column. See the UI section for full column mapping.`

---

### Finding 5 — [Minor] `PlanBuilderResponse.content` — design spec implies required, build spec marks optional

The design spec says "a `content` string (the drafted document content when not stuck)" — phrasing it as always-present. The build spec marks `content?: string` as optional with `?`. When `stuck: true`, content should be absent. When `stuck: false`, content should be required. Neither document captures this conditional requirement clearly.

**File:** `thoughtforge-design-specification.md`, Phase 3 Stuck Detection table, Plan mode row.

**Replace:**
`and a content string (the drafted document content when not stuck)`

**With:**
`and a content string (required when not stuck — contains the drafted document content; absent when stuck)`

---

## 2. Genuinely Missing Plan-Level Content

### Finding 6 — [Major] `reviewer.js` function signature has no way to receive test results for Code mode

The design spec explicitly states: "orchestrator passes the test results as additional context to the reviewer AI alongside the codebase and `constraints.md`." But the build spec's `reviewer.js` interface is `review(projectPath, constraints, agent)` — no parameter for test results. A builder implementing Code mode's Phase 4 iteration cycle cannot wire test results into the reviewer without guessing.

**File:** `thoughtforge-build-spec.md`, Plugin Interface Contract section, `reviewer.js` subsection.

**Replace:**
```
- `review(projectPath, constraints, agent)` → `Promise<object>` — one review pass, raw parsed JSON. Orchestrator validates via `schema.safeParse()`, retries on failure, halts after max retries.
```

**With:**
```
- `review(projectPath, constraints, agent, testResults?)` → `Promise<object>` — one review pass, raw parsed JSON. `testResults` is an optional parameter (required for Code mode, omitted for Plan mode) containing the structured output from `test-runner.js`. Orchestrator validates via `schema.safeParse()`, retries on failure, halts after max retries.
```

---

### Finding 7 — [Major] Plugin interface contract in design spec omits `test-runner.js`

The design spec lists four files as part of the plugin interface contract: `builder.js`, `reviewer.js`, `safety-rules.js`, and `discovery.js`. The build spec defines five, adding `test-runner.js` with its own function signature. Task 6 in the execution plan ("Set up plugin loader, validates interface contract") needs to know whether `test-runner.js` is part of the contract or not.

**File:** `thoughtforge-design-specification.md`, Plugin Interface Contract section.

**Replace:**
`Plugin interface contract (function signatures, parameters, return types) defined in build spec. Includes builder.js (Phase 3), reviewer.js (Phase 4), safety-rules.js, and discovery.js (optional Phase 2 hook — used by Code plugin for OSS qualification scorecard).`

**With:**
`Plugin interface contract (function signatures, parameters, return types) defined in build spec. Includes builder.js (Phase 3), reviewer.js (Phase 4), safety-rules.js, discovery.js (optional Phase 2 hook — used by Code plugin for OSS qualification scorecard), and test-runner.js (Code plugin only — test execution for Phase 3 build iteration and Phase 4 review context).`

---

### Finding 8 — [Minor] Execution plan does not reference build spec as companion document

The execution plan's header says "Companion to: ThoughtForge Design Specification" but does not reference the build spec. The execution plan's tasks directly reference build spec content (Zod schemas, prompt files, function signatures). A builder following the execution plan is not directed to the build spec.

**File:** `thoughtforge-execution-plan.md`, header section.

**Replace:**
`> **Companion to:** [ThoughtForge Design Specification](./thoughtforge-design-specification.md)`

**With:**
`> **Companion to:** [ThoughtForge Design Specification](./thoughtforge-design-specification.md) | [ThoughtForge Build Spec](./thoughtforge-build-spec.md)`

---

### Finding 9 — [Minor] Execution plan Task 25 dependency direction is inverted

Task 25 (`discovery.js` — OSS qualification scorecard) depends on Task 12 (Phase 2 spec building). But `discovery.js` is a Phase 2 hook that is **called during** Phase 2. Task 12 needs `discovery.js` to be available for the Code mode path. The dependency should be reversed, or at minimum Task 12 should also depend on Task 25.

**File:** `thoughtforge-execution-plan.md`, Build Stage 4 table, Task 25 row.

**Replace:**
`| 25 | Implement discovery.js — OSS qualification scorecard for Phase 2 Code mode | — | Task 20, Task 12 | — | Not Started |`

**With:**
`| 25 | Implement discovery.js — OSS qualification scorecard for Phase 2 Code mode | — | Task 20 | — | Not Started |`

**Also**, add Task 25 as a dependency of Task 12. In Build Stage 2, Task 12 row:

**Replace:**
`| 12 | Implement Phase 2: spec building, constraint discovery, acceptance criteria extraction, human review/override of proposed decisions, human review of acceptance criteria, Confirm to advance | — | Task 6a, Task 10, Task 11, Task 7a, Task 7f, Tasks 41–42 | — | Not Started |`

**With:**
`| 12 | Implement Phase 2: spec building, constraint discovery, acceptance criteria extraction, human review/override of proposed decisions, human review of acceptance criteria, Confirm to advance | — | Task 6a, Task 10, Task 11, Task 7a, Task 7f, Task 25, Tasks 41–42 | — | Not Started |`

---

## 3. Build Spec Material That Should Be Extracted

### Finding 10 — [Minor] No build-spec material found in the plan documents

The previous review round (Round 1, Change 8) already addressed prompt draft ownership. The current state of the design spec and execution plan is clean of implementation detail that belongs in the build spec. No extraction needed.

---

## Summary

| Severity | Count |
|----------|-------|
| Critical | 1 |
| Major | 4 |
| Minor | 3 |

---

## Consolidated Apply Prompt

See `apply-prompt-r2.md` for the consolidated prompt to hand to an AI coder.
