I've now read all four documents in their entirety. Let me compile my findings.

---

## Review Findings

### 1. Writing That's Unclear

**[Major] Design Spec, Phase 3, Plan Mode Completion Signal GÇö No defined signal for the orchestrator to know the plan builder has finished successfully.**

The Phase 3 Plan Mode section (design-specification.md, lines 156GÇô168) lists steps 1GÇô8 but never defines a completion signal. Code mode has clear signals (tests passing, non-zero exit on failure), but plan mode relies on the builder... just stopping? The orchestrator needs a way to distinguish "builder finished drafting" from "builder crashed silently" to trigger the Phase 3GåÆ4 transition.

**Replace** design-specification.md lines 164GÇô165 (steps 7GÇô8):

```
7. Builder returns structured completion signal: `{ stuck: false, content: "..." }` (using the Plan Builder Response schema defined in the build spec). If `stuck: true`, stuck detection triggers per the table below.
8. Orchestrator validates that the output file exists and is non-empty, writes output to `/docs/`, and marks Phase 3 complete.
9. If stuck on a decision requiring human input: notifies and waits
10. Output: complete but unpolished plan document (`.md`) in `/docs/`
```

---

**[Major] Design Spec, Phase 3GåÆ4 Transition GÇö No error handling for the automatic transition.**

Design-specification.md line 204 describes the Phase 3GåÆ4 transition as: "the orchestrator writes a git commit, updates `status.json` to `polishing`, sends a milestone notification, and immediately begins Phase 4." This involves three operations (git commit, status write, notification) that can each fail. No error handling is specified.

**Add** after the existing Phase 3GåÆ4 Transition paragraph (design-specification.md, after line 204):

```
**Phase 3GåÆ4 Transition Error Handling:**

| Condition | Action |
|---|---|
| Git commit fails | Log the error, continue transition. The deliverable exists but lacks a snapshot. Do not halt GÇö the polish loop will create its own commits. |
| `status.json` write fails | Halt and notify human. Phase state is ambiguous without this file. |
| Milestone notification fails | Log the error, continue transition. Notification failure is non-blocking. |
```

---

**[Major] Design Spec & Build Spec GÇö No project ID format defined.**

Project IDs are generated at project creation (design-specification.md line 58) and used for directory names, git repos, `status.json`, and Vibe Kanban task IDs. No format is specified anywhere. A builder would have to guess.

**Add** to the build spec, as a new section after the `status.json` Schema section:

```
## Project ID Format

**Used by:** Task 2 (project initialization)

Project IDs are generated as `{timestamp}-{random}` where:
- `{timestamp}` is compact ISO date-time: `YYYYMMDD-HHmmss`
- `{random}` is 6 lowercase alphanumeric characters (a-z0-9)
- Example: `20260213-143052-a7k2m9`

This format is filesystem-safe, sortable by creation time, and collision-resistant for a single-operator tool.
```

---

**[Minor] Design Spec, Phase 1, Step 0 GÇö Project name extraction timing is buried in a dense paragraph.**

Design-specification.md line 58 is a single long paragraph covering project init, directory creation, git init, status.json, chat thread, project name extraction, and Vibe Kanban card update. The project name extraction detail is easy to miss.

**Replace** the sentence starting "After Phase 1 distillation locks `intent.md`..." (line 58, mid-paragraph) by breaking it out:

```
**Project Name Derivation:** After Phase 1 distillation locks `intent.md`, the project name is extracted from the `intent.md` title and written to `status.json` as `project_name`. If Vibe Kanban is enabled, the card name is updated at the same time.
```

---

**[Minor] Design Spec, Convergence Guards GÇö "Spikes sharply" and "well above" are vague in the design spec table.**

Design-specification.md lines 229 and 231 use phrases like "spikes sharply" (hallucination) and "spikes well above its recent average" (fabrication). While the build spec defines exact thresholds, a builder reading the design spec table in isolation would have no sense of what "sharp" or "well above" means.

**Replace** the Hallucination Guard description (line 229):

```
| Hallucination | Error count increases >20% after GëÑ2 iterations of sustained decrease | Halt. Notify human: "Fix-regress cycle detected. Errors trending down then spiked. Iteration [N]: [X] total (was [Y]). Review needed." |
```

**Replace** the Fabrication Guard description (line 231):

```
| Fabrication | A severity category spikes >50% above its trailing 3-iteration average (minimum absolute increase of 2), AND the system had previously approached within 2+ù of termination thresholds | Halt. Notify human. |
```

---

**[Minor] Design Spec, `chat_history.json` GÇö "Cleared after each phase advancement confirmation" is ambiguous about which phase transitions.**

Design-specification.md line 395 says "Cleared after each phase advancement confirmation (Phase 1 GåÆ Phase 2 and Phase 2 GåÆ Phase 3)." This is clear to someone who reads it carefully, but the parenthetical reads like examples rather than an exhaustive list.

**Replace** (design-specification.md line 395):

```
Cleared only on Phase 1GåÆPhase 2 and Phase 2GåÆPhase 3 confirmation button presses. These are the only two clearings GÇö Phase 3GåÆPhase 4 is automatic and does NOT clear chat history. Phase 3 stuck recovery messages and Phase 4 halt recovery messages persist.
```

---

**[Minor] Execution Plan, Build Stage 1 cross-stage dependency note GÇö "Should begin as soon as Task 1 completes" is advisory, not captured in task dependencies.**

Execution-plan.md lines 38 say Build Stage 7 should overlap with Build Stage 1, but the dependency table for Tasks 41GÇô44 already shows Task 41 depends on Task 1. The advisory text adds no information the dependency column doesn't already express, and "should begin" language could confuse a builder about whether it's a scheduling suggestion or a hard constraint.

**Replace** (execution-plan.md lines 38):

```
> **Cross-stage dependency:** Agent Layer (Build Stage 7, Tasks 41GÇô44) depends on Task 1 (foundation) and can proceed in parallel with the remainder of Build Stage 1. Tasks 41GÇô42 must be complete before any agent-invoking task begins (Tasks 8, 12, 15, 19, 21, and 30).
```

---

**[Minor] Design Spec, Phase 2, Step 2 GÇö "challenges weak or risky decisions present in intent.md" is unclear about what gets challenged.**

Design-specification.md line 107 says "AI challenges weak or risky decisions" then lists examples. The word "decisions" is misleading because `intent.md` is a distillation of human input GÇö it contains assumptions and constraints, not decisions. Decisions are made in Phase 2.

**Replace** (design-specification.md line 107):

```
2. AI challenges weak assumptions, risky constraints, and gaps in `intent.md` GÇö missing dependencies, unrealistic constraints, scope gaps, contradictions GÇö with specific reasoning. Does not rubber-stamp.
```

---

**[Minor] Design Spec, Phase 4 Code Mode Iteration Cycle GÇö The three-step cycle description references "test results" twice with slightly different phrasing.**

Design-specification.md line 222 says "(1) Orchestrator runs tests... (2) Review GÇö orchestrator passes the test results as additional context to the reviewer AI alongside the codebase and `constraints.md`. Reviewer outputs JSON error report including test results." The phrase "including test results" at the end could be read as the reviewer JSON containing raw test output rather than the `tests` field in the Zod schema.

**Replace** the last sentence of step (2) (design-specification.md line 222):

```
Reviewer outputs JSON error report (validated against the Code Review Zod schema, which includes the `tests` field for pass/fail counts).
```

---

**[Minor] Build Spec, `test-runner.js` contract GÇö return type details field purpose is unclear.**

Build-spec.md line 200 says `details: string` contains "raw test runner output for inclusion in review context." A builder might question whether this is stdout, stderr, or a formatted summary.

**Replace** (build-spec.md line 200):

```
- `runTests(projectPath)` GåÆ `Promise<{ total: number, passed: number, failed: number, details: string }>` GÇö Executes all tests in the project, returns structured results. The `details` field contains the combined stdout + stderr from the test runner process, included verbatim in the review prompt as additional context. Called by the orchestrator before each Phase 4 Code mode review step, and during Phase 3 Code mode build iteration.
```

---

**[Minor] Design Spec, Configuration GÇö "Convergence thresholds" values in the table use inconsistent format.**

Design-specification.md line 463 lists thresholds inline: "`critical_max` (0), `medium_max` (3), `minor_max` (5) GÇö maximum allowed counts, inclusive." This is clear but the other config rows use simple descriptions. Not a gap, just mildly inconsistent with the table style.

No replacement needed GÇö flagging for awareness only. Withdraw if below threshold.

---

**[Minor] Execution Plan, Communication section GÇö placeholders remain.**

Execution-plan.md lines 188GÇô190 have "TBD" for Status Updates and Escalation Path. For a solo operator tool, this section is arguably irrelevant.

**Replace** (execution-plan.md lines 186GÇô190):

```
## Communication

**Status Updates:** Not applicable GÇö solo operator project.

**Escalation Path:** Not applicable GÇö solo operator project.
```

---

### 2. Genuinely Missing Plan-Level Content

**[Major GÇö previously identified in state/findings.md, still unresolved in source documents]**

All three Major findings from the previous review iteration (findings.md lines 6GÇô8) appear to still be present in the source documents based on my read-through. Specifically:

1. Phase 3 Plan mode completion signal GÇö addressed in Finding 1 above.
2. Phase 3GåÆ4 transition error handling GÇö addressed in Finding 2 above.
3. Project ID format GÇö addressed in Finding 3 above.

No new missing plan-level content identified beyond what's covered in section 1.

---

### 3. Build Spec Material That Should Be Extracted

No findings. The plan documents are clean of implementation detail. The build spec appropriately contains the schemas, prompts, function signatures, and config templates. Nothing in the requirements brief, design spec, or execution plan crosses into build spec territory.

---

## Consolidated Coder Prompt

```
Apply the following changes to the ThoughtForge plan documents. Each change specifies the exact
file, location, and replacement text. Apply all changes, then commit and sync.

### File: thoughtforge-design-specification.md

CHANGE 1 GÇö Phase 3 Plan Mode (replace steps 7-8, ~lines 164-168):
Find:
  7. If stuck on a decision requiring human input: notifies and waits
  8. Output: complete but unpolished plan document (`.md`) in `/docs/`
Replace with:
  7. Builder returns structured completion signal: `{ stuck: false, content: "..." }` (using the Plan Builder Response schema defined in the build spec). If `stuck: true`, stuck detection triggers per the table below.
  8. Orchestrator validates that the output file exists and is non-empty, writes output to `/docs/`, and marks Phase 3 complete.
  9. If stuck on a decision requiring human input: notifies and waits
  10. Output: complete but unpolished plan document (`.md`) in `/docs/`

CHANGE 2 GÇö Phase 3GåÆ4 Transition Error Handling (insert after the existing "Phase 3 GåÆ Phase 4 Transition" paragraph, after line 204):
Add:
  **Phase 3GåÆ4 Transition Error Handling:**

  | Condition | Action |
  |---|---|
  | Git commit fails | Log the error, continue transition. The deliverable exists but lacks a snapshot. Do not halt GÇö the polish loop will create its own commits. |
  | `status.json` write fails | Halt and notify human. Phase state is ambiguous without this file. |
  | Milestone notification fails | Log the error, continue transition. Notification failure is non-blocking. |

CHANGE 3 GÇö Phase 1 Step 0: Break out project name derivation (line 58):
In the paragraph starting "0. **Project Initialization:**", replace the sentences:
  "After Phase 1 distillation locks `intent.md`, the project name is extracted from the `intent.md` title and written to `status.json`. If Vibe Kanban is enabled, the card name is updated at the same time."
With a separate bolded sub-line:
  **Project Name Derivation:** After Phase 1 distillation locks `intent.md`, the project name is extracted from the `intent.md` title and written to `status.json` as `project_name`. If Vibe Kanban is enabled, the card name is updated at the same time.

CHANGE 4 GÇö Convergence Guards table, Hallucination row (line 229):
Replace the Condition column text:
  "Error count spikes sharply after a sustained downward trend"
With:
  "Error count increases >20% after GëÑ2 iterations of sustained decrease"

CHANGE 5 GÇö Convergence Guards table, Fabrication row (line 231):
Replace the Condition column text:
  "A severity category spikes well above its recent average, AND the system had previously approached convergence thresholds GÇö suggesting the reviewer is manufacturing issues because nothing real remains"
With:
  "A severity category spikes >50% above its trailing 3-iteration average (minimum absolute increase of 2), AND the system had previously approached within 2+ù of termination thresholds"

CHANGE 6 GÇö chat_history.json description (line 395):
Replace:
  "Cleared after each phase advancement confirmation (Phase 1 GåÆ Phase 2 and Phase 2 GåÆ Phase 3)."
With:
  "Cleared only on Phase 1GåÆPhase 2 and Phase 2GåÆPhase 3 confirmation button presses. These are the only two clearings GÇö Phase 3GåÆPhase 4 is automatic and does NOT clear chat history. Phase 3 stuck recovery messages and Phase 4 halt recovery messages persist."

CHANGE 7 GÇö Phase 2 Step 2 (line 107):
Replace:
  "AI challenges weak or risky decisions present in `intent.md`"
With:
  "AI challenges weak assumptions, risky constraints, and gaps in `intent.md`"

CHANGE 8 GÇö Phase 4 Code Mode Iteration Cycle, step 2 ending (line 222):
Replace:
  "Reviewer outputs JSON error report including test results."
With:
  "Reviewer outputs JSON error report (validated against the Code Review Zod schema, which includes the `tests` field for pass/fail counts)."

### File: thoughtforge-build-spec.md

CHANGE 9 GÇö Add new section after `status.json` Schema section (after line 399):
Add:
  ## Project ID Format

  **Used by:** Task 2 (project initialization)

  Project IDs are generated as `{timestamp}-{random}` where:
  - `{timestamp}` is compact ISO date-time: `YYYYMMDD-HHmmss`
  - `{random}` is 6 lowercase alphanumeric characters (a-z0-9)
  - Example: `20260213-143052-a7k2m9`

  This format is filesystem-safe, sortable by creation time, and collision-resistant for a single-operator tool.

CHANGE 10 GÇö test-runner.js contract (line 200):
Replace:
  "The `details` field contains raw test runner output for inclusion in review context."
With:
  "The `details` field contains the combined stdout + stderr from the test runner process, included verbatim in the review prompt as additional context."

### File: thoughtforge-execution-plan.md

CHANGE 11 GÇö Cross-stage dependency note (line 38):
Replace:
  "> **Cross-stage dependency:** Agent Layer (Build Stage 7, Tasks 41GÇô44) provides the core agent invocation mechanism used by Stages 2GÇô6. Task 41 depends on Task 1 (foundation), so Build Stage 7 should begin as soon as Task 1 completes, overlapping with the remainder of Build Stage 1. Tasks 41GÇô42 must be complete before any agent-invoking task begins (Tasks 8, 12, 15, 19, 21, and 30)."
With:
  "> **Cross-stage dependency:** Agent Layer (Build Stage 7, Tasks 41GÇô44) depends on Task 1 (foundation) and can proceed in parallel with the remainder of Build Stage 1. Tasks 41GÇô42 must be complete before any agent-invoking task begins (Tasks 8, 12, 15, 19, 21, and 30)."

CHANGE 12 GÇö Communication section (lines 186-190):
Replace:
  ## Communication

  **Status Updates:** TBD GÇö frequency and channel

  **Escalation Path:** TBD
With:
  ## Communication

  **Status Updates:** Not applicable GÇö solo operator project.

  **Escalation Path:** Not applicable GÇö solo operator project.

### After all changes:
git add thoughtforge-design-specification.md thoughtforge-build-spec.md thoughtforge-execution-plan.md
git commit -m "Apply plan review findings: Phase 3 plan completion signal, Phase 3GåÆ4 error handling, project ID format, convergence guard precision, chat history clearing clarity, test-runner contract, cross-stage dep wording, communication section"
git push
```
