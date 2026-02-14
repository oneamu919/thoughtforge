You are applying review changes to the ThoughtForge project plan documents. Apply every change below exactly as specified. Do not interpret or improvise — each change has explicit replacement or addition text.

## FILE: docs/thoughtforge-requirements-brief.md

### CHANGE 1 (RB-1): Fix convergence threshold notation in Outcome section
Location: Line 9 (Outcome paragraph).
Replace:
`0 critical errors, <3 medium, <5 minor`
With:
`0 critical errors, ≤3 medium, ≤5 minor`

### CHANGE 2 (RB-2): Fix convergence threshold notation in Success Criteria table
Location: Success Criteria table, "Polish loop convergence" row, Target column.
Replace:
`0 critical, <3 medium, <5 minor`
With:
`0 critical, ≤3 medium, ≤5 minor (thresholds inclusive — matches config.yaml convergence settings)`

---

## FILE: docs/thoughtforge-design-specification.md

### CHANGE 3 (DS-PS1): Fix polish_state.json schema description
Location: Project State Files table, `polish_state.json` row, Schema column.
Replace:
`Iteration number, error counts, convergence trajectory, timestamp`
With:
`Iteration number, error counts, convergence trajectory, tests passed (null for plan mode), completed flag, halt reason, timestamp. Full schema in build spec.`

### CHANGE 4 (DS-VK1): Fix "mirror directly" claim for Kanban columns
Location: After the Phase-to-State Mapping table (the line that reads "Vibe Kanban columns mirror these `status.json` values directly.").
Replace:
`Vibe Kanban columns mirror these status.json values directly.`
With:
`Vibe Kanban columns correspond to these status.json phase values, except halted — which is a card state indicator, not a separate column. See the UI section for full column mapping.`

### CHANGE 5 (DS-PB1): Clarify PlanBuilderResponse.content conditional requirement
Location: Phase 3 Stuck Detection table, Plan mode row. Within the cell text find:
`and a content string (the drafted document content when not stuck)`
Replace with:
`and a content string (required when not stuck — contains the drafted document content; absent when stuck)`

### CHANGE 6 (DS-PI1): Add test-runner.js to plugin interface contract listing
Location: Plugin Interface Contract section.
Replace:
`Plugin interface contract (function signatures, parameters, return types) defined in build spec. Includes builder.js (Phase 3), reviewer.js (Phase 4), safety-rules.js, and discovery.js (optional Phase 2 hook — used by Code plugin for OSS qualification scorecard).`
With:
`Plugin interface contract (function signatures, parameters, return types) defined in build spec. Includes builder.js (Phase 3), reviewer.js (Phase 4), safety-rules.js, discovery.js (optional Phase 2 hook — used by Code plugin for OSS qualification scorecard), and test-runner.js (Code plugin only — test execution for Phase 3 build iteration and Phase 4 review context).`

---

## FILE: docs/thoughtforge-build-spec.md

### CHANGE 7 (BS-HR1): Rename halted_reason to halt_reason in status.json schema
Location: `status.json` Schema section, TypeScript interface.
Replace:
`halted_reason: string | null;`
With:
`halt_reason: string | null;`

### CHANGE 8 (BS-RV1): Add testResults parameter to reviewer.js interface
Location: Plugin Interface Contract section, `reviewer.js` subsection.
Replace:
```
- `review(projectPath, constraints, agent)` → `Promise<object>` — one review pass, raw parsed JSON. Orchestrator validates via `schema.safeParse()`, retries on failure, halts after max retries.
```
With:
```
- `review(projectPath, constraints, agent, testResults?)` → `Promise<object>` — one review pass, raw parsed JSON. `testResults` is an optional parameter (required for Code mode, omitted for Plan mode) containing the structured output from `test-runner.js`. Orchestrator validates via `schema.safeParse()`, retries on failure, halts after max retries.
```

---

## FILE: docs/thoughtforge-execution-plan.md

### CHANGE 9 (EP-CD1): Add build spec as companion document
Location: Header section, the companion line.
Replace:
`> **Companion to:** [ThoughtForge Design Specification](./thoughtforge-design-specification.md)`
With:
`> **Companion to:** [ThoughtForge Design Specification](./thoughtforge-design-specification.md) | [ThoughtForge Build Spec](./thoughtforge-build-spec.md)`

### CHANGE 10 (EP-D25): Fix Task 25 dependency — remove circular dependency on Task 12
Location: Build Stage 4 table, Task 25 row.
Replace:
`| 25 | Implement discovery.js — OSS qualification scorecard for Phase 2 Code mode | — | Task 20, Task 12 | — | Not Started |`
With:
`| 25 | Implement discovery.js — OSS qualification scorecard for Phase 2 Code mode | — | Task 20 | — | Not Started |`

### CHANGE 11 (EP-D12): Add Task 25 as dependency of Task 12
Location: Build Stage 2 table, Task 12 row.
Replace:
`| 12 | Implement Phase 2: spec building, constraint discovery, acceptance criteria extraction, human review/override of proposed decisions, human review of acceptance criteria, Confirm to advance | — | Task 6a, Task 10, Task 11, Task 7a, Task 7f, Tasks 41–42 | — | Not Started |`
With:
`| 12 | Implement Phase 2: spec building, constraint discovery, acceptance criteria extraction, human review/override of proposed decisions, human review of acceptance criteria, Confirm to advance | — | Task 6a, Task 10, Task 11, Task 7a, Task 7f, Task 25, Tasks 41–42 | — | Not Started |`

---

## AFTER ALL CHANGES

Run: `git add docs/thoughtforge-requirements-brief.md docs/thoughtforge-design-specification.md docs/thoughtforge-build-spec.md docs/thoughtforge-execution-plan.md docs/review-results.md docs/apply-prompt-r2.md`
Run: `git commit -m "Apply plan review round 2 findings: 1 critical, 4 major, 3 minor across all four plan documents"`
Run: `git push`
