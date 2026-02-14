# ThoughtForge Plan Review — Round 3

**Reviewer posture:** Senior dev who will eventually build from this plan.
**Documents reviewed:** Design Specification, Build Spec, Execution Plan (with Requirements Brief as context).
**Prior reviews:** Round 1 (13 changes, commit `ca2b448`), Round 2 (9 findings, commit `039ce06`, applied in `b03eb60`).

---

## 1. Writing That's Unclear

### Finding 1 — [Critical] `builder.js` returns `Promise<void>` but orchestrator depends on stuck signal return data

The design spec describes Plan mode stuck detection as: "AI returns a JSON response containing a `stuck` boolean... The orchestrator parses this JSON to detect stuck status. Schema in build spec (`PlanBuilderResponse`)." The build spec defines `PlanBuilderResponse` with `stuck`, `reason?`, and `content?` fields. But the build spec's `builder.js` interface contract says:

```
build(projectPath, intent, spec, constraints, agent) → Promise<void>
```

`Promise<void>` provides no mechanism to return the `PlanBuilderResponse` to the orchestrator. The orchestrator cannot differentiate successful completion from a stuck condition. For Code mode, the design spec describes stuck detection via exit codes and consecutive test failures — also not communicable through `Promise<void>`.

**File:** `thoughtforge-build-spec.md`, Plugin Interface Contract section, `builder.js` subsection.

**Replace:**
```
- `build(projectPath, intent, spec, constraints, agent)` → `Promise<void>`
```

**With:**
```
- `build(projectPath, intent, spec, constraints, agent)` → `Promise<BuildResult>`

Return type varies by plugin:
- **Plan plugin** returns `Promise<{ stuck: boolean, reason?: string, content?: string }>` — matches `PlanBuilderResponse` schema. Orchestrator checks `stuck` flag to detect stuck condition.
- **Code plugin** returns `Promise<{ stuck: boolean, reason?: string }>` — orchestrator detects stuck via the `stuck` flag (set after 2 consecutive non-zero exits on the same task, or 3 consecutive identical test failures).
```

---

### Finding 2 — [Major] `convergence_speed` referenced in design spec but absent from `polish_state.json` schema

The design spec (Agent Performance Comparison paragraph) says: "ThoughtForge enables comparison by writing iteration count, convergence speed, and final error counts to `polish_state.json`." The build spec's `PolishState` interface has `convergence_trajectory` (an array of per-iteration data) but no `convergence_speed` field. These are different things: trajectory is raw data, speed is a derived metric.

**File:** `thoughtforge-design-specification.md`, Agent Performance Comparison paragraph.

**Replace:**
`ThoughtForge enables comparison by writing iteration count, convergence speed, and final error counts to polish_state.json, which Vibe Kanban reads per-card.`

**With:**
`ThoughtForge enables comparison by writing iteration count, convergence trajectory, and final error counts to polish_state.json, which Vibe Kanban reads per-card.`

---

### Finding 3 — [Major] "Realign from here" behavior has three ambiguities a builder cannot resolve

The design spec (Phase 1, step 9) describes "realign from here" but leaves three mechanical questions unanswered:

1. "Last non-command human message" — the only command defined in Phase 1 is "realign from here" itself. If the human sends "realign from here" twice consecutively, the baseline is undefined.
2. "All AI revisions produced after that correction are discarded" — does not specify the mechanical operation. Are messages deleted from `chat_history.json`, flagged as invalidated, or excluded from context when re-distilling?
3. No handling for the case where the human sends "realign from here" before making any corrections (immediately after the initial distillation). There is no "most recent substantive correction" to use as baseline.

**File:** `thoughtforge-design-specification.md`, Phase 1, step 9.

**Replace:**
`Human can type "realign from here" as a chat message. The AI treats the human's most recent substantive correction (the last non-command human message before "realign from here") as the new baseline. All AI revisions produced after that correction are discarded. The AI re-distills from the original brain dump plus all human corrections up to and including that baseline message. Does not restart from the original brain dump alone.`

**With:**
`Human can type "realign from here" as a chat message. The AI identifies the human's most recent substantive correction — defined as the last human message that is not a "realign from here" command. All messages after that correction (both AI and human) are excluded from the working context but remain in chat_history.json for audit purposes. The AI re-distills from the original brain dump plus all human corrections up to and including that baseline message. Does not restart from the original brain dump alone. If no human corrections exist yet (i.e., "realign from here" is sent before any corrections), the command is ignored and the AI responds asking the human to provide a correction first.`

---

### Finding 4 — [Major] `ChatMessage.phase` enum excludes `halted`, creating ambiguity for Phase 4 halt recovery messages

The build spec's `ChatMessage` interface defines `phase` as:
```
phase: "brain_dump" | "distilling" | "human_review" | "spec_building" | "building" | "polishing";
```

During Phase 4 halt recovery, `status.json` phase is `halted`. Chat messages are persisted during halt recovery (per design spec), but the `ChatMessage.phase` enum has no valid value for them. Phase 3 stuck recovery avoids this because `status.json` remains in `building` state. Phase 4 halt recovery has no equivalent — the project is in `halted` state.

**File:** `thoughtforge-build-spec.md`, `chat_history.json` Schema section, `ChatMessage` interface.

**Replace:**
```
  phase: "brain_dump" | "distilling" | "human_review" | "spec_building" | "building" | "polishing";
```

**With:**
```
  phase: "brain_dump" | "distilling" | "human_review" | "spec_building" | "building" | "polishing" | "halted";
```

---

### Finding 5 — [Major] Project naming sequencing contradiction — fallback name written to locked file

The design spec (Phase 1, step 0) says: "After Phase 1 distillation locks `intent.md`, the project name is set to the first heading (H1) of `intent.md`. If `intent.md` has no H1 heading, the AI generates a short descriptive name (2-4 words) from the brain dump content and uses that as both the `intent.md` title and the project name."

The second sentence contradicts the first. If `intent.md` has already been locked, the AI cannot modify it to add a title. The fallback name must be determined during distillation (before the file is written and locked), not after.

**File:** `thoughtforge-design-specification.md`, Phase 1, step 0, Project Initialization paragraph.

**Replace:**
`After Phase 1 distillation locks intent.md, the project name is set to the first heading (H1) of intent.md. If intent.md has no H1 heading, the AI generates a short descriptive name (2-4 words) from the brain dump content and uses that as both the intent.md title and the project name. The project name is written to status.json.`

**With:**
`During Phase 1 distillation, the AI determines the project name: it uses the first heading (H1) of the distilled document. If no H1 heading is present, the AI generates a short descriptive name (2-4 words) from the brain dump content and includes it as the H1 heading. When intent.md is written and locked, the project name is extracted from its H1 heading and written to status.json.`

---

### Finding 6 — [Minor] Design spec line 241 still has abbreviated `polish_state.json` field list

The Round 2 review correctly updated the Project State Files table (line 398) to list all 7 fields, but did not update the Loop State Persistence paragraph (line 241), which still lists only 4 fields. A builder reading the Phase 4 section encounters the incomplete list before reaching the authoritative table.

**File:** `thoughtforge-design-specification.md`, Loop State Persistence paragraph.

**Replace:**
`**Loop State Persistence:** polish_state.json written after each iteration (iteration number, error counts, convergence trajectory, timestamp). On crash, resumes from last completed iteration.`

**With:**
`**Loop State Persistence:** polish_state.json written after each iteration. Full field list in Project State Files table below. On crash, resumes from last completed iteration.`

---

### Finding 7 — [Minor] Notification examples show only the `summary` field, not the full structured object

The notification content schema defines five required fields (`project_id`, `project_name`, `phase`, `event_type`, `summary`). Every notification example shows only a single formatted string that embeds the project name. None show the full structured object. A builder could implement notifications as plain strings instead of structured objects.

**File:** `thoughtforge-design-specification.md`, immediately after the Notification Examples list (after line 391).

**Add after the examples list:**
`Each notification is sent as a structured object containing all five fields from the schema above. The examples show the summary field value only. The full object for the first example would be: { project_id: "{id}", project_name: "Wedding Plan", phase: "polishing", event_type: "convergence_success", summary: "Polish loop converged. 0 critical, 1 medium, 3 minor. Ready for final review." }`

---

## 2. Genuinely Missing Plan-Level Content

### Finding 8 — [Major] Phase 4 has no error handling table for operational failures during iterations

Phases 1, 2, and 3 each have dedicated error handling tables. Phase 4 has convergence guards (loop-level anomalies) and halt recovery (human response after halt), but no coverage for operational errors during a single iteration: agent failure during review step, agent failure during fix step, filesystem errors during git commit, test runner process crashes (distinct from test assertion failures).

The agent communication layer specifies generic retry behavior, but the other three phases explicitly re-state that behavior in their own context. Phase 4 should do the same because it has unique crash recovery semantics via `polish_state.json`.

**File:** `thoughtforge-design-specification.md`, Phase 4 section, after the Halt Recovery Interaction paragraph (after line 255).

**Add:**
```
**Phase 4 Error Handling:**

| Condition | Action |
|---|---|
| Agent failure during review or fix step (timeout, crash, empty response) | Same retry behavior as agent communication layer: retry once, halt and notify on second failure. `polish_state.json` preserves loop progress — on resume, the failed iteration is re-attempted from the beginning (review step). |
| Zod validation failure on review JSON | Retry up to `config.yaml` `polish.retry_malformed_output` (default 2). On repeated failure: halt and notify human. |
| File system error during git commit after fix | Halt and notify human immediately. `polish_state.json` for the current iteration is not written (last completed iteration preserved for recovery). |
| Test runner crash during Code mode iteration (process error, not test assertion failure) | Same retry behavior as agent communication layer: retry once, halt on second failure. Distinct from test assertion failures, which are passed to the reviewer as context. |
```

---

### Finding 9 — [Major] Project name derivation and VK card name update have no explicit task in execution plan

The design spec describes a multi-step process after intent.md is locked: extract project name from H1 heading, fallback to AI-generated name, write to status.json, update Vibe Kanban card name if enabled. The build spec's VK CLI table includes `vibekanban task update {task_id} --name "{project_name}"` with timing "After Phase 1."

No execution plan task covers this. Task 11 says "Implement intent.md generation and locking" but does not mention name derivation, status.json name update, or VK card name update. Task 2 writes the initial empty-string project_name at creation time.

**File:** `thoughtforge-execution-plan.md`, Build Stage 2 table, Task 11 row.

**Replace:**
`| 11 | Implement intent.md generation and locking | — | Task 9, Task 2a | — | Not Started |`

**With:**
`| 11 | Implement intent.md generation and locking, project name derivation (extract from H1 or AI-generate), status.json project_name update, and Vibe Kanban card name update (if enabled) | — | Task 9, Task 2a, Task 26 | — | Not Started |`

---

### Finding 10 — [Major] Phase 2 validation gate not explicitly covered in Task 12 description

The design spec states: "Before advancement: AI validates that all Unknowns and Open Questions from intent.md have been resolved... If unresolved items remain, the Confirm button is blocked." This is a distinct UI behavior (button disabled state) and validation behavior (AI completeness check). Task 12 says "Confirm to advance" but does not describe blocking Confirm or validating resolution completeness. A builder could implement a simple Confirm flow that skips this gate.

**File:** `thoughtforge-execution-plan.md`, Build Stage 2 table, Task 12 row.

**Replace:**
`| 12 | Implement Phase 2: spec building, constraint discovery, acceptance criteria extraction, human review/override of proposed decisions, human review of acceptance criteria, Confirm to advance | — | Task 6a, Task 10, Task 11, Task 7a, Task 7f, Task 25, Tasks 41–42 | — | Not Started |`

**With:**
`| 12 | Implement Phase 2: spec building, constraint discovery, acceptance criteria extraction, human review/override of proposed decisions, human review of acceptance criteria, Unknown/Open Question resolution validation gate (block Confirm if unresolved items remain), Confirm to advance | — | Task 6a, Task 10, Task 11, Task 7a, Task 7f, Task 25, Tasks 41–42 | — | Not Started |`

---

### Finding 11 — [Major] No unit tests for config loader validation behavior

The design spec specifies three distinct config.yaml startup failure modes: missing file, invalid YAML syntax, and schema validation failure. Each has specific behavior (exit with descriptive error, no partial loading). Task 1 implements this, but Build Stage 8 has no test task for config validation. These are deterministic, easily testable behaviors that gate all other functionality.

**File:** `thoughtforge-execution-plan.md`, Build Stage 8 table, after Task 50 row.

**Add:**
`| 50a | Unit tests: config loader (missing file exits with path, invalid YAML exits with error, schema violations exit identifying invalid key, no partial loading) | — | Task 1 | — | Not Started |`

---

### Finding 12 — [Major] No unit tests for count derivation logic (Task 32)

The build spec states the orchestrator must derive counts from the issues array, not top-level count fields. If count derivation is wrong, every convergence guard fires on incorrect data. Task 47 tests convergence guards with synthetic inputs but assumes counts are already correctly computed. No test verifies the derivation itself.

**File:** `thoughtforge-execution-plan.md`, Build Stage 8 table, after Task 47 row.

**Add:**
`| 47a | Unit tests: count derivation (derives counts from issues array, ignores top-level count fields, handles empty issues array, handles mismatched top-level counts) | — | Task 32 | — | Not Started |`

---

### Finding 13 — [Minor] `chat_history.json` missing from Outputs table and has no specified file path

Every other state file and output file has an explicit path in the design spec Outputs table. `chat_history.json` appears in the Project State Files table with schema details but no directory path, and is absent from the Outputs table entirely. A builder implementing Task 9a must decide where to write the file.

**File:** `thoughtforge-design-specification.md`, Outputs table, after the `status.json` row.

**Add row:**
`| chat_history.json | /projects/{id}/ | JSON — per-phase chat messages for crash recovery |`

---

### Finding 14 — [Minor] Plugin Interface Contract "Used by" annotation missing Task 24

The build spec's Plugin Interface Contract section header says "Used by: Tasks 6, 15, 17, 18, 21, 22, 23, 25" but `test-runner.js` is defined within this section and its implementing task is Task 24, which is not listed.

**File:** `thoughtforge-build-spec.md`, Plugin Interface Contract section header.

**Replace:**
`**Used by:** Tasks 6, 15, 17, 18, 21, 22, 23, 25`

**With:**
`**Used by:** Tasks 6, 15, 17, 18, 21, 22, 23, 24, 25`

---

## 3. Build Spec Material That Should Be Extracted

### Finding 15 — [Minor] No build-spec material found in the plan documents

The current state of the design spec and execution plan is clean of implementation detail that belongs in the build spec. No extraction needed.

---

## Summary

| Severity | Count |
|----------|-------|
| Critical | 1 |
| Major | 8 |
| Minor | 5 |

---
