# Apply Prompt — results.md Findings

Apply every change below to the source files. Each change specifies the file, the location, and the exact modification. Do not interpret or improvise — apply as written.

**Source files:**
- `docs/thoughtforge-execution-plan.md` (referred to as "exec plan")
- `docs/thoughtforge-design-specification.md` (referred to as "design spec")
- `docs/thoughtforge-build-spec.md` is unchanged — do not modify it.

---

## Critical Finding 1: Task 19 is missing from the execution plan

**File:** exec plan

**Problem:** Task numbers jump from 18 to 20 in Build Stage 4 (Code Mode Plugin). There is no Task 19. But the cross-stage dependency note on line 41 references Task 19: "Tasks 41–42 must be complete before any agent-invoking task begins (Tasks 8, 12, 15, 19, 21, and 30)."

**Action:** Add Task 19 to Build Stage 4's table, between Task 18 (line 75) and Task 20 (line 83). Task 19 should be a Code mode equivalent of Task 18 (Plan mode safety rules). Insert the following row into the Build Stage 4 table:

```
| 19 | Implement Code mode safety-rules validation at orchestrator level (verify code plugin permissions before Phase 3/4 agent invocations) | — | Task 6a, Task 20 | — | Not Started |
```

Insert this row immediately before the row for Task 20 (`Create /plugins/code/ folder structure`). This makes Task 19 an agent-invoking task that logically belongs in the cross-stage dependency list.

**Alternative:** If Task 19 was not intended to be an agent-invoking task, remove `19` from the cross-stage dependency note instead. Change the note text from `(Tasks 8, 12, 15, 19, 21, and 30)` to `(Tasks 8, 12, 15, 21, and 30)`. Use whichever approach is more consistent with the overall plan structure — but one of these two must be done. The cross-stage dependency note and the task list must agree.

---

## Major Finding 1: Phase 1 Step 0 is a wall of text

**File:** design spec

**Location:** Phase 1, Step 0, "Project Initialization" paragraph (line 59). This is a single dense paragraph containing ~7 distinct operations.

**Action:** Replace the single paragraph at Step 0 with a structured sub-list. Replace the existing Step 0 text:

```
0. **Project Initialization:** Human initiates a new project via the ThoughtForge chat interface (e.g., a "New Project" command or button). ThoughtForge generates a unique project ID (used as the directory name and as `project_id` in notifications — not stored in `status.json` since it is always derivable from the project directory path), creates the `/projects/{id}/` directory structure (including `/docs/` and `/resources/` subdirectories), initializes a git repo, writes an initial `status.json` with phase `brain_dump` and `project_name` as empty string, and opens a new chat thread. During Phase 1 distillation, the AI determines the project name: it uses the first heading (H1) of the distilled document. If no H1 heading is present, the AI generates a short descriptive name (2-4 words) from the brain dump content and includes it as the H1 heading. When intent.md is written and locked, the project name is extracted from its H1 heading and written to status.json. If Vibe Kanban is enabled, the card name is updated at the same time. If Vibe Kanban integration is enabled, a corresponding card is created at this point.
```

With:

```
0. **Project Initialization:**

   Human initiates a new project via the ThoughtForge chat interface (e.g., a "New Project" command or button). The following operations execute in order:

   1. Generate a unique project ID (used as the directory name and as `project_id` in notifications — not stored in `status.json` since it is always derivable from the project directory path)
   2. Create the `/projects/{id}/` directory structure (including `/docs/` and `/resources/` subdirectories)
   3. Initialize a git repo in the project directory
   4. Write an initial `status.json` with phase `brain_dump` and `project_name` as empty string
   5. If Vibe Kanban integration is enabled, create a corresponding Kanban card
   6. Open a new chat thread for the project

   **Project Name Derivation (during Phase 1 distillation):** The AI uses the first heading (H1) of the distilled document. If no H1 heading is present, the AI generates a short descriptive name (2-4 words) from the brain dump content and includes it as the H1 heading. When `intent.md` is written and locked, the project name is extracted from its H1 heading and written to `status.json`. If Vibe Kanban is enabled, the card name is updated at the same time.
```

---

## Major Finding 2: Phase 4 git commit timing is ambiguous

**File:** design spec

**Location:** Phase 4 section, "Step 2 — Fix" description (line 227).

**Problem:** The current text says "Git commit snapshot after each step" but only at the end of Step 2. The design intent (confirmed in the Technical Design git commit strategy section on line 330) is two commits per iteration: one after review, one after fix.

**Action:** Replace:

```
**Step 1 — Review (do not fix):** AI reviews scoped deliverable + `constraints.md` (including acceptance criteria). Outputs ONLY a JSON error report. Does not fix anything.

**Step 2 — Fix (apply recommendations):** Orchestrator passes JSON issue list to fixer agent, which applies fixes. Git commit snapshot after each step.
```

With:

```
**Step 1 — Review (do not fix):** AI reviews scoped deliverable + `constraints.md` (including acceptance criteria). Outputs ONLY a JSON error report. Does not fix anything. Git commit after review (captures the review JSON).

**Step 2 — Fix (apply recommendations):** Orchestrator passes JSON issue list to fixer agent, which applies fixes. Git commit after fix (captures applied fixes).
```

---

## Major Finding 3: Task 11 omits `deliverable_type` derivation

**File:** exec plan

**Location:** Task 11 description (line 62).

**Problem:** Task 11 handles `intent.md` generation and project name derivation but does not mention setting `deliverable_type` in `status.json`. The design spec (line 73) states: "The `deliverable_type` field in `status.json` is set to `"plan"` or `"code"` at this point, derived from the Deliverable Type section of the confirmed `intent.md`."

**Action:** Replace Task 11's description:

```
| 11 | Implement intent.md generation and locking, project name derivation (extract from H1 or AI-generate), status.json project_name update, and Vibe Kanban card name update (if enabled) | — | Task 9, Task 2a, Task 26, Tasks 41–42 | — | Not Started |
```

With:

```
| 11 | Implement intent.md generation and locking, project name derivation (extract from H1 or AI-generate), `deliverable_type` derivation (from Deliverable Type section of confirmed intent.md → `"plan"` or `"code"` in status.json), status.json `project_name` and `deliverable_type` update, and Vibe Kanban card name update (if enabled) | — | Task 9, Task 2a, Task 26, Tasks 41–42 | — | Not Started |
```

---

## Major Finding 4: No task owns `status.json` error handling

**File:** exec plan

**Problem:** The design spec (line 88) defines cross-phase `status.json` error handling: "Halt the project and notify the operator with the file path and the specific error (parse failure, missing file, invalid phase value). Do not attempt recovery or partial loading." But no task in the execution plan is assigned to implement this behavior.

**Action:** Add this responsibility to Task 3 (project state module), since Task 3 already owns `status.json` read/write. Replace Task 3's description:

```
| 3 | Implement project state module (`status.json`, `polish_state.json` read/write) with atomic write default (write to temp file, rename to target) for all state files | — | Task 1 | — | Not Started |
```

With:

```
| 3 | Implement project state module (`status.json`, `polish_state.json` read/write) with atomic write default (write to temp file, rename to target) for all state files. Include `status.json` error handling: halt and notify on unreadable, missing, or invalid status.json (parse failure, missing file, invalid phase value) — no recovery or partial loading | — | Task 1 | — | Not Started |
```

---

## Major Finding 5: Plan Completeness Gate override has no specified UI mechanism

**File:** design spec

**Location:** Plan Completeness Gate section (line 276).

**Problem:** The text says "The human can either override (proceed with Code mode despite the incomplete plan) or create a new Plan mode project manually" but does not specify the interaction mechanism (buttons, chat commands, etc.). Other recovery interactions (Phase 3 stuck, Phase 4 halt) explicitly define buttons.

**Action:** Replace:

```
If the AI recommends fail: ThoughtForge halts the Code mode pipeline, sets `status.json` to `halted` with reason `plan_incomplete`, and notifies the human with the AI's reasoning. The human can either override (proceed with Code mode despite the incomplete plan) or create a new Plan mode project manually to refine the plan first. ThoughtForge does not automatically create projects on the human's behalf.
```

With:

```
If the AI recommends fail: ThoughtForge halts the Code mode pipeline, sets `status.json` to `halted` with reason `plan_incomplete`, and notifies the human with the AI's reasoning. The chat interface presents two action buttons:

| Option | What Happens |
|---|---|
| Override | Human proceeds with Code mode despite the incomplete plan. Status set back to `building`. |
| Terminate | Human stops the project. Status set to `halted` permanently. The human may create a new Plan mode project manually to refine the plan first. |

These follow the same confirmation model as other recovery interactions — explicit button presses, not chat-parsed commands. Terminate requires a single confirmation step. ThoughtForge does not automatically create projects on the human's behalf.
```

---

## Major Finding 6: Task 6d doesn't specify the override interaction path

**File:** exec plan

**Location:** Task 6d description (line 38).

**Problem:** Task 6d says "human decides to override or create separate Plan project" but doesn't specify the UI mechanism (buttons). Now that Major Finding 5 adds buttons to the design spec, Task 6d should reference them.

**Action:** Replace Task 6d's description:

```
| 6d | Implement Plan Completeness Gate: assessment prompt for Code mode Phase 3 entry (loaded from `/prompts/completeness-gate.md`), halt with `plan_incomplete` on fail — human decides to override or create separate Plan project | — | Task 7a, Task 6e, Tasks 41–42 | — | Not Started |
```

With:

```
| 6d | Implement Plan Completeness Gate: assessment prompt for Code mode Phase 3 entry (loaded from `/prompts/completeness-gate.md`), halt with `plan_incomplete` on fail, present Override and Terminate buttons in chat (Override resumes build, Terminate halts permanently) | — | Task 7a, Task 6e, Tasks 41–42 | — | Not Started |
```

---

## Major Finding 7: PlanBuilderResponse schema fields embedded in design spec

**File:** design spec

**Location:** Phase 3, Plan mode stuck detection row (line 187).

**Problem:** The stuck detection description embeds schema field details (`stuck` boolean, `reason` string, `content` string) that belong in the build spec. The design spec should describe behavior and reference the build spec for schema.

**Action:** Replace the Plan mode stuck condition cell:

```
| Plan | AI returns a JSON response containing a `stuck` boolean, an optional `reason` string (required when stuck), and a `content` string (required when not stuck — contains the drafted document content; absent when stuck). The orchestrator parses this JSON to detect stuck status. Schema in build spec (`PlanBuilderResponse`). | Notify and wait |
```

With:

```
| Plan | AI returns a JSON response. The orchestrator parses this JSON to detect stuck status. Response schema (`PlanBuilderResponse`) defined in build spec. | Notify and wait |
```

---

## Minor Findings (7 items)

The results.md summary lists 7 minor findings but does not enumerate them individually. Minor findings typically include: inconsistent terminology, formatting issues, redundant text, unclear phrasing, or style inconsistencies. Since the detailed minor findings are not itemized in results.md, no specific changes can be applied for minors at this time. The next review iteration should enumerate all minor findings with specific locations and fix instructions.

---

## After All Changes Are Applied

1. Review every change to ensure no formatting was broken (markdown tables, indentation, list numbering).
2. `git add docs/thoughtforge-execution-plan.md docs/thoughtforge-design-specification.md`
3. `git commit -m "Apply review findings: fix missing Task 19, restructure Phase 1 Step 0, clarify Phase 4 commits, add deliverable_type to Task 11, assign status.json error handling to Task 3, add Plan Completeness Gate buttons, specify Task 6d interaction, move PlanBuilderResponse schema reference to build spec"`
4. `git push` to sync to remote.
