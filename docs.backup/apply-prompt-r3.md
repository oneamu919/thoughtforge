# Apply Prompt — Round 3 Review Changes

Apply all 14 changes below to the ThoughtForge plan documents. Each change specifies the exact file, location, and text. Apply them in order. Do not interpret, reword, or skip any change.

---

## Change 1 — Build Spec: `builder.js` return type (Critical)

**File:** `docs/thoughtforge-build-spec.md`
**Location:** Plugin Interface Contract section, `builder.js` subsection

**Find:**
```
- `build(projectPath, intent, spec, constraints, agent)` → `Promise<void>`
```

**Replace with:**
```
- `build(projectPath, intent, spec, constraints, agent)` → `Promise<BuildResult>`

Return type varies by plugin:
- **Plan plugin** returns `Promise<{ stuck: boolean, reason?: string, content?: string }>` — matches `PlanBuilderResponse` schema. Orchestrator checks `stuck` flag to detect stuck condition.
- **Code plugin** returns `Promise<{ stuck: boolean, reason?: string }>` — orchestrator detects stuck via the `stuck` flag (set after 2 consecutive non-zero exits on the same task, or 3 consecutive identical test failures).
```

---

## Change 2 — Design Spec: `convergence_speed` → `convergence_trajectory` (Major)

**File:** `docs/thoughtforge-design-specification.md`
**Location:** Agent Performance Comparison paragraph

**Find:**
`ThoughtForge enables comparison by writing iteration count, convergence speed, and final error counts to polish_state.json, which Vibe Kanban reads per-card.`

**Replace with:**
`ThoughtForge enables comparison by writing iteration count, convergence trajectory, and final error counts to polish_state.json, which Vibe Kanban reads per-card.`

---

## Change 3 — Design Spec: "Realign from here" specification (Major)

**File:** `docs/thoughtforge-design-specification.md`
**Location:** Phase 1, step 9

**Find:**
`Human can type "realign from here" as a chat message. The AI treats the human's most recent substantive correction (the last non-command human message before "realign from here") as the new baseline. All AI revisions produced after that correction are discarded. The AI re-distills from the original brain dump plus all human corrections up to and including that baseline message. Does not restart from the original brain dump alone.`

**Replace with:**
`Human can type "realign from here" as a chat message. The AI identifies the human's most recent substantive correction — defined as the last human message that is not a "realign from here" command. All messages after that correction (both AI and human) are excluded from the working context but remain in chat_history.json for audit purposes. The AI re-distills from the original brain dump plus all human corrections up to and including that baseline message. Does not restart from the original brain dump alone. If no human corrections exist yet (i.e., "realign from here" is sent before any corrections), the command is ignored and the AI responds asking the human to provide a correction first.`

---

## Change 4 — Build Spec: `ChatMessage.phase` enum add `halted` (Major)

**File:** `docs/thoughtforge-build-spec.md`
**Location:** `chat_history.json` Schema section, `ChatMessage` interface

**Find:**
```
  phase: "brain_dump" | "distilling" | "human_review" | "spec_building" | "building" | "polishing";
```

**Replace with:**
```
  phase: "brain_dump" | "distilling" | "human_review" | "spec_building" | "building" | "polishing" | "halted";
```

---

## Change 5 — Design Spec: Project naming sequencing fix (Major)

**File:** `docs/thoughtforge-design-specification.md`
**Location:** Phase 1, step 0, Project Initialization paragraph

**Find:**
`After Phase 1 distillation locks intent.md, the project name is set to the first heading (H1) of intent.md. If intent.md has no H1 heading, the AI generates a short descriptive name (2-4 words) from the brain dump content and uses that as both the intent.md title and the project name. The project name is written to status.json.`

**Replace with:**
`During Phase 1 distillation, the AI determines the project name: it uses the first heading (H1) of the distilled document. If no H1 heading is present, the AI generates a short descriptive name (2-4 words) from the brain dump content and includes it as the H1 heading. When intent.md is written and locked, the project name is extracted from its H1 heading and written to status.json.`

---

## Change 6 — Design Spec: Phase 4 error handling table (Major)

**File:** `docs/thoughtforge-design-specification.md`
**Location:** Phase 4 section, after the Halt Recovery Interaction paragraph (the paragraph ending with "...single confirmation step."), before the Count Derivation paragraph

**Insert the following new content between those two paragraphs:**

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

## Change 7 — Execution Plan: Task 11 add project name derivation (Major)

**File:** `docs/thoughtforge-execution-plan.md`
**Location:** Build Stage 2 table, Task 11 row

**Find:**
`| 11 | Implement intent.md generation and locking | — | Task 9, Task 2a | — | Not Started |`

**Replace with:**
`| 11 | Implement intent.md generation and locking, project name derivation (extract from H1 or AI-generate), status.json project_name update, and Vibe Kanban card name update (if enabled) | — | Task 9, Task 2a, Task 26 | — | Not Started |`

---

## Change 8 — Execution Plan: Task 12 add validation gate (Major)

**File:** `docs/thoughtforge-execution-plan.md`
**Location:** Build Stage 2 table, Task 12 row

**Find:**
`| 12 | Implement Phase 2: spec building, constraint discovery, acceptance criteria extraction, human review/override of proposed decisions, human review of acceptance criteria, Confirm to advance | — | Task 6a, Task 10, Task 11, Task 7a, Task 7f, Task 25, Tasks 41–42 | — | Not Started |`

**Replace with:**
`| 12 | Implement Phase 2: spec building, constraint discovery, acceptance criteria extraction, human review/override of proposed decisions, human review of acceptance criteria, Unknown/Open Question resolution validation gate (block Confirm if unresolved items remain), Confirm to advance | — | Task 6a, Task 10, Task 11, Task 7a, Task 7f, Task 25, Tasks 41–42 | — | Not Started |`

---

## Change 9 — Execution Plan: Add config loader unit tests (Major)

**File:** `docs/thoughtforge-execution-plan.md`
**Location:** Build Stage 8 table, after Task 50 row

**Insert new row:**
`| 50a | Unit tests: config loader (missing file exits with path, invalid YAML exits with error, schema violations exit identifying invalid key, no partial loading) | — | Task 1 | — | Not Started |`

---

## Change 10 — Execution Plan: Add count derivation unit tests (Major)

**File:** `docs/thoughtforge-execution-plan.md`
**Location:** Build Stage 8 table, after Task 47 row

**Insert new row:**
`| 47a | Unit tests: count derivation (derives counts from issues array, ignores top-level count fields, handles empty issues array, handles mismatched top-level counts) | — | Task 32 | — | Not Started |`

---

## Change 11 — Design Spec: Abbreviated `polish_state.json` field list (Minor)

**File:** `docs/thoughtforge-design-specification.md`
**Location:** Loop State Persistence paragraph

**Find:**
`**Loop State Persistence:** polish_state.json written after each iteration (iteration number, error counts, convergence trajectory, timestamp). On crash, resumes from last completed iteration.`

**Replace with:**
`**Loop State Persistence:** polish_state.json written after each iteration. Full field list in Project State Files table below. On crash, resumes from last completed iteration.`

---

## Change 12 — Design Spec: Notification example showing full structured object (Minor)

**File:** `docs/thoughtforge-design-specification.md`
**Location:** After the last notification example line (`"Project 'CLI Tool' — Phase 2 spec building..."`)

**Insert after that line:**

`Each notification is sent as a structured object containing all five fields from the schema above. The examples show the summary field value only. The full object for the first example would be: { project_id: "{id}", project_name: "Wedding Plan", phase: "polishing", event_type: "convergence_success", summary: "Polish loop converged. 0 critical, 1 medium, 3 minor. Ready for final review." }`

---

## Change 13 — Design Spec: Add `chat_history.json` to Outputs table (Minor)

**File:** `docs/thoughtforge-design-specification.md`
**Location:** Outputs table, after the `status.json` row

**Insert new row:**
`| chat_history.json | /projects/{id}/ | JSON — per-phase chat messages for crash recovery |`

---

## Change 14 — Build Spec: Plugin Interface Contract "Used by" add Task 24 (Minor)

**File:** `docs/thoughtforge-build-spec.md`
**Location:** Plugin Interface Contract section header

**Find:**
`**Used by:** Tasks 6, 15, 17, 18, 21, 22, 23, 25`

**Replace with:**
`**Used by:** Tasks 6, 15, 17, 18, 21, 22, 23, 24, 25`

---

## After All Changes

1. Verify all 14 changes have been applied by reading the modified sections of each file.
2. Git add the three modified files: `docs/thoughtforge-design-specification.md`, `docs/thoughtforge-build-spec.md`, `docs/thoughtforge-execution-plan.md`.
3. Commit with message: `Apply plan review round 3 findings: 1 critical, 8 major, 5 minor across all three plan documents`
4. Push to remote.
