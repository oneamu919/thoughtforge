I've now read the complete plan: Requirements Brief, Design Specification, Execution Plan, and Build Spec. Let me produce the review.

---

## 1. Writing That's Unclear

**[Minor] GÇö Design Spec, Phase 1 step 0: Project Initialization is a wall of text**

The project initialization paragraph (line 58) packs ~7 distinct operations into a single sentence. A builder will have to re-read it multiple times.

**Replacement text:**
> 0. **Project Initialization:**
>    1. Human initiates a new project via the ThoughtForge chat interface (e.g., a "New Project" command or button).
>    2. ThoughtForge generates a unique project ID.
>    3. Creates the `/projects/{id}/` directory structure (including `/docs/` and `/resources/` subdirectories).
>    4. Initializes a git repo in the project directory.
>    5. Writes an initial `status.json` with phase `brain_dump` and `project_name` as empty string.
>    6. Opens a new chat thread.
>    7. If Vibe Kanban integration is enabled, creates a corresponding Kanban card.
>
>    After Phase 1 distillation locks `intent.md`, the project name is extracted from the `intent.md` title and written to `status.json`. If Vibe Kanban is enabled, the card name is updated at the same time.

---

**[Minor] GÇö Design Spec, Phase 4 Code Mode Iteration Cycle: numbered list embedded in prose is hard to follow**

Line 222 describes a 3-step cycle as parenthetical prose. This should be a structured list to match the two-step plan mode pattern above it.

**Replacement text:**
> **Code Mode Iteration Cycle:** Code mode adds a test execution step to each iteration. The full cycle per iteration is:
>
> 1. **Test** GÇö Orchestrator runs tests via the code plugin's `test-runner.js` and captures results.
> 2. **Review** GÇö Orchestrator passes the test results as additional context to the reviewer AI alongside the codebase and `constraints.md`. Reviewer outputs JSON error report including test results.
> 3. **Fix** GÇö Orchestrator passes issue list to fixer agent. Git commit after fix.
>
> This three-step cycle repeats until a convergence guard triggers. Plan mode iterations use the two-step cycle (Review GåÆ Fix) with no test execution.

---

**[Minor] GÇö Design Spec, Stagnation Guard: "issue rotation" direction is ambiguous**

Line 230: "specific issues change between iterations even though the total stays flat" GÇö this parenthetical is the only human explanation, but the build spec's 70% threshold could be read as "70% match = rotation detected" or "70% match = NO rotation." The design spec should clarify the direction.

**Replacement text (Design Spec line 230):**
> Stagnation | Total count plateaus across consecutive iterations AND issue rotation detected (fewer than 70% of issues match the prior iteration GÇö meaning the loop is fixing old issues but finding new ones at the same rate, indicating the best quality achievable autonomously) | Done (success). Notify human: "Polish sufficient. Ready for final review."

---

**[Minor] GÇö Design Spec, `chat_history.json` clearing: implicit that "cleared" means the file is emptied, but could be read as "deleted"**

Line 395: "Cleared after each phase advancement confirmation" GÇö unclear whether "cleared" means truncated to empty array or file deleted and recreated.

**Replacement text (append to end of line 395):**
> Cleared (reset to empty array `[]`, file retained) after each phase advancement confirmation (Phase 1 GåÆ Phase 2 and Phase 2 GåÆ Phase 3).

---

**[Minor] GÇö Execution Plan, Build Stage 1 cross-stage dependency note: "overlapping with the remainder of Build Stage 1" is vague about what overlaps**

Line 38 says Build Stage 7 should "overlap" but doesn't clarify which Stage 1 tasks can run in parallel with Stage 7.

**Replacement text:**
> **Cross-stage dependency:** Agent Layer (Build Stage 7, Tasks 41GÇô44) provides the core agent invocation mechanism used by Stages 2GÇô6. Task 41 depends on Task 1 (foundation). Build Stage 7 should begin as soon as Task 1 completes and run in parallel with the remaining Stage 1 tasks (Tasks 2GÇô6c). Tasks 41GÇô42 must be complete before any agent-invoking task begins (Tasks 8, 12, 15, 19, 21, and 30).

---

**[Minor] GÇö Build Spec, `test-runner.js` contract: `details` field is described as "raw test runner output" but no contract for what the orchestrator does with it**

Line 200: The `details` field is described but it's unclear how the orchestrator passes it to the reviewer. Is it injected into the prompt verbatim? Truncated?

**Replacement text (append after line 200):**
> The orchestrator passes the `details` string verbatim into the reviewer prompt as a fenced code block under a `## Test Results` heading. If `details` exceeds 5,000 characters, it is truncated to the last 5,000 characters with a `[truncated]` prefix.

---

## 2. Genuinely Missing Plan-Level Content

**[Major] GÇö No error handling for Phase 3 GåÆ Phase 4 transition failure**

The design spec describes Phase 3GåÆ4 as automatic (line 204): "orchestrator writes a git commit, updates `status.json` to `polishing`..." But there is no error handling for what happens if the git commit fails, or `status.json` write fails at this transition point. Every other phase transition and error scenario is documented. This one is not.

**Proposed addition (Design Spec, after line 204):**
> **Phase 3 GåÆ Phase 4 Transition Error Handling:**
>
> | Condition | Action |
> |---|---|
> | Git commit fails at Phase 3 completion | Retry once. On second failure, halt and notify human. The deliverable is still intact in the working directory. |
> | `status.json` write fails | Halt and notify human. On restart, the orchestrator detects `status.json` still shows `building` and the deliverable exists, and re-attempts the transition. |

---

**[Major] GÇö No specification of how the orchestrator determines Phase 3 "completion" in Plan mode**

Code mode Phase 3 completion is defined: "tests passing." Plan mode Phase 3 completion has no equivalent signal. The builder is told to "fill every section GÇö no placeholders, no TBD" (line 165), but there's no mechanism for the orchestrator to verify the builder is done. Does the AI return a completion signal? Does the orchestrator check the document for TBD strings? The stuck signal schema covers the stuck case but not the success case.

**Proposed addition (Design Spec, after line 164, under Plan Mode step 5):**
> 5a. **Completion Signal:** The plan builder's response uses the same `PlanBuilderResponse` schema as the stuck signal. When `stuck` is `false` and `content` is non-empty, the orchestrator treats the build as complete. The orchestrator performs a mechanical check on the rendered document: if any OPA table cell contains placeholder text ("TBD", "TODO", or is empty), the orchestrator re-invokes the builder with the incomplete sections identified. This is not an AI judgment GÇö it is a string scan.

---

**[Major] GÇö No definition of project ID format**

The design spec says "generates a unique project ID" (line 58) and the execution plan says "unique ID generation" (Task 2). But the format is never specified anywhere. Is it a UUID? A timestamp-based ID? A slug? This matters because it becomes directory names, git repo names, and Vibe Kanban task IDs.

**Proposed addition (Build Spec, new section after `status.json` Schema):**
> ## Project ID Format
>
> **Used by:** Task 2 (project initialization)
>
> Project IDs are generated as `{timestamp}_{short_random}` GÇö e.g., `20260213_a3f2`. Format: `YYYYMMDD` date + underscore + 4-character lowercase alphanumeric random suffix. This ensures chronological sorting by default, human readability in file paths, and collision avoidance. The ID becomes the directory name (`/projects/{id}/`) and the Vibe Kanban task ID.

---

**[Minor] GÇö No specification of what happens when the operator edits a locked file manually**

Design spec lines 72, 114: "Human may still edit manually outside the pipeline." This is stated but the consequences are unspecified. Does the orchestrator re-read these files at later phases? If so, does it use the edited version? Or does it cache the original?

**Proposed addition (Design Spec, after line 114):**
> **Manual Edits to Locked Files:** The orchestrator always reads `intent.md`, `spec.md`, and `constraints.md` from disk at the point of use, not from memory. If the human edits a locked file manually between phases, subsequent phases will use the edited version. ThoughtForge does not detect or warn about manual edits GÇö the human is assumed to know what they're doing.

---

**[Minor] GÇö Execution Plan has no task for `config.yaml` schema validation implementation**

Design spec line 476 specifies Zod-based config validation on startup with specific error behaviors. The execution plan Task 1 says "config.yaml loader" but doesn't explicitly include validation. There's no dedicated task for implementing the startup validation behavior described in the design spec.

**Proposed addition (Execution Plan, Build Stage 1 table, after Task 1):**
> | 1b | Implement config validation: Zod schema for `config.yaml`, startup validation with descriptive errors for missing file, invalid YAML, and schema violations | GÇö | Task 1 | GÇö | Not Started |

---

**[Minor] GÇö No task in Execution Plan for implementing the "realign from here" baseline-reset mechanism**

Task 9 says "correction loop (chat-based revisions, 'realign from here')" but the realign mechanism described in design spec line 70 is non-trivial: it requires identifying "the last non-command human message," discarding AI revisions after it, and re-distilling. This is complex enough to warrant its own task or at minimum explicit subtask callout.

**Proposed addition (Execution Plan, Build Stage 2 table, modify Task 9):**
> | 9 | Implement correction loop: chat-based revisions and "realign from here" baseline-reset (identify last substantive correction, discard subsequent AI revisions, re-distill from original brain dump plus all corrections up to baseline) | GÇö | Task 8 | GÇö | Not Started |

---

**[Minor] GÇö Build Spec: no schema for the Phase 3 Plan builder stuck signal when NOT stuck**

The `PlanBuilderResponse` interface (build spec line 348-353) shows `content?: string` as optional, but doesn't specify what the content field contains on success. Is it the entire rendered document? A partial section? The relationship between this response and the Handlebars template rendering is unspecified.

**Proposed addition (Build Spec, after line 353):**
> When `stuck` is `false`: `content` contains the fully rendered plan document (all OPA sections filled). The orchestrator writes `content` to the plan deliverable file in `/docs/`. The `reason` field is omitted or null.
>
> When `stuck` is `true`: `content` is omitted or contains the partially completed document. `reason` is required and describes the specific decision or information needed from the human.

---

## 3. Build Spec Material That Should Be Extracted

**[Minor] GÇö Design Spec, Fabrication Guard near-convergence thresholds (line 231)**

The design spec includes specific numeric thresholds: "within 2+ù of the termination thresholds (Gëñ0 critical, Gëñ6 medium, Gëñ10 minor)." These calculated values are implementation detail GÇö the build spec already has the convergence guard parameters section. The design spec should describe the *concept* (prior near-convergence) and the build spec should contain the specific multiplier and derived values.

**Proposed change:**

Design Spec line 231, replace:
> "In at least one prior iteration, the system reached within 2+ù of the termination thresholds (Gëñ0 critical, Gëñ6 medium, Gëñ10 minor)."

With:
> "In at least one prior iteration, the system approached the termination thresholds (specific proximity factor defined in build spec)."

Build Spec Fabrication Guard section, add:
> - **Prior near-convergence proximity factor:** 2+ù the termination thresholds. Computed as: critical Gëñ `critical_max` (always 0), medium Gëñ `medium_max +ù 2`, minor Gëñ `minor_max +ù 2`. Using defaults: Gëñ0 critical, Gëñ6 medium, Gëñ10 minor.

---

**[Minor] GÇö Design Spec, Stagnation Guard Levenshtein threshold (line 230 parenthetical) and match percentage**

The build spec already documents these values. The design spec should reference the build spec rather than duplicating the "70%" and "0.8 similarity" numbers inline. Currently both documents have these numbers, creating a maintenance risk.

**Proposed change:**

Design Spec line 230, the stagnation guard description should read:
> Stagnation | Total count plateaus across consecutive iterations AND issue rotation detected (the loop is fixing old issues but finding new ones at the same rate GÇö the best quality achievable autonomously). Rotation detection parameters in build spec. | Done (success). Notify human: "Polish sufficient. Ready for final review."

(The build spec already has the correct detailed parameters.)

---

## Final Output GÇö Consolidated Coder Prompt

```
Apply the following changes from the plan review. Each change specifies the
target file and exact modification. Apply all changes, then git commit and push.

GòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉ
FILE: docs/thoughtforge-design-specification.md
GòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉ

CHANGE 1 GÇö Reformat Phase 1 Step 0 (Project Initialization)
Location: The paragraph starting with "0. **Project Initialization:**"
Replace the entire paragraph (from "0. **Project Initialization:**" through
"...the card name is updated at the same time.") with:

0. **Project Initialization:**
   1. Human initiates a new project via the ThoughtForge chat interface (e.g., a "New Project" command or button).
   2. ThoughtForge generates a unique project ID.
   3. Creates the `/projects/{id}/` directory structure (including `/docs/` and `/resources/` subdirectories).
   4. Initializes a git repo in the project directory.
   5. Writes an initial `status.json` with phase `brain_dump` and `project_name` as empty string.
   6. Opens a new chat thread.
   7. If Vibe Kanban integration is enabled, creates a corresponding Kanban card.

   After Phase 1 distillation locks `intent.md`, the project name is extracted from the `intent.md` title and written to `status.json`. If Vibe Kanban is enabled, the card name is updated at the same time.

GöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇ

CHANGE 2 GÇö Reformat Code Mode Iteration Cycle
Location: The sentence starting "**Code Mode Iteration Cycle:**" in Phase 4.
Replace the entire paragraph (from "**Code Mode Iteration Cycle:**" through
"...with no test execution.") with:

**Code Mode Iteration Cycle:** Code mode adds a test execution step to each iteration. The full cycle per iteration is:

1. **Test** GÇö Orchestrator runs tests via the code plugin's `test-runner.js` and captures results.
2. **Review** GÇö Orchestrator passes the test results as additional context to the reviewer AI alongside the codebase and `constraints.md`. Reviewer outputs JSON error report including test results.
3. **Fix** GÇö Orchestrator passes issue list to fixer agent. Git commit after fix.

This three-step cycle repeats until a convergence guard triggers. Plan mode iterations use the two-step cycle (Review GåÆ Fix) with no test execution.

GöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇ

CHANGE 3 GÇö Clarify Stagnation Guard description
Location: The Stagnation row in the Convergence Guards table.
Replace the Stagnation Condition cell with:

Total count plateaus across consecutive iterations AND issue rotation detected (the loop is fixing old issues but finding new ones at the same rate GÇö the best quality achievable autonomously). Rotation detection parameters in build spec.

GöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇ

CHANGE 4 GÇö Extract Fabrication Guard numeric thresholds to build spec
Location: The Fabrication row in the Convergence Guards table.
In the Condition cell, replace:
"suggesting the reviewer is manufacturing issues because nothing real remains"
with:
"suggesting the reviewer is manufacturing issues because nothing real remains. Specific proximity factor defined in build spec."

And replace the parenthetical:
"(Gëñ0 critical, Gëñ6 medium, Gëñ10 minor)"
with nothing GÇö remove it entirely from the design spec.

So the full Fabrication Condition cell reads:
A severity category spikes well above its recent average, AND the system had previously approached convergence thresholds GÇö suggesting the reviewer is manufacturing issues because nothing real remains. Specific proximity factor defined in build spec.

GöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇ

CHANGE 5 GÇö Clarify chat_history.json "cleared" meaning
Location: The `chat_history.json` row in Project State Files.
Replace:
"Cleared after each phase advancement confirmation (Phase 1 GåÆ Phase 2 and Phase 2 GåÆ Phase 3)."
with:
"Cleared (reset to empty array `[]`, file retained) after each phase advancement confirmation (Phase 1 GåÆ Phase 2 and Phase 2 GåÆ Phase 3)."

GöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇ

CHANGE 6 GÇö Add Plan Mode Phase 3 completion signal
Location: After Phase 3, Plan Mode, step 5 ("Fills every section GÇö no placeholders, no 'TBD'").
Add new step:

6. **Completion Signal:** The plan builder's response uses the same `PlanBuilderResponse` schema as the stuck signal. When `stuck` is `false` and `content` is non-empty, the orchestrator treats the build as complete. The orchestrator then performs a mechanical check on the rendered document: if any OPA table cell contains placeholder text ("TBD", "TODO", or is empty), the orchestrator re-invokes the builder with the incomplete sections identified. This is not an AI judgment GÇö it is a string scan.

Renumber the subsequent steps (current 6GåÆ7, 7GåÆ8, 8GåÆ9).

GöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇ

CHANGE 7 GÇö Add Phase 3GåÆ4 transition error handling
Location: After the "Phase 3 GåÆ Phase 4 Transition" paragraph.
Add:

**Phase 3 GåÆ Phase 4 Transition Error Handling:**

| Condition | Action |
|---|---|
| Git commit fails at Phase 3 completion | Retry once. On second failure, halt and notify human. The deliverable is still intact in the working directory. |
| `status.json` write fails | Halt and notify human. On restart, the orchestrator detects `status.json` still shows `building` and the deliverable exists, and re-attempts the transition. |

GöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇ

CHANGE 8 GÇö Add manual edit behavior for locked files
Location: After the Phase 2 outputs paragraph ending "Human may still edit manually outside the pipeline." (line 114 area).
Add:

**Manual Edits to Locked Files:** The orchestrator always reads `intent.md`, `spec.md`, and `constraints.md` from disk at the point of use, not from memory. If the human edits a locked file manually between phases, subsequent phases will use the edited version. ThoughtForge does not detect or warn about manual edits GÇö the human is assumed to know what they're doing.

GòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉ
FILE: docs/thoughtforge-execution-plan.md
GòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉ

CHANGE 9 GÇö Clarify cross-stage dependency note
Location: The "Cross-stage dependency" note after Build Stage 1 table.
Replace the entire note with:

> **Cross-stage dependency:** Agent Layer (Build Stage 7, Tasks 41GÇô44) provides the core agent invocation mechanism used by Stages 2GÇô6. Task 41 depends on Task 1 (foundation). Build Stage 7 should begin as soon as Task 1 completes and run in parallel with the remaining Stage 1 tasks (Tasks 2GÇô6c). Tasks 41GÇô42 must be complete before any agent-invoking task begins (Tasks 8, 12, 15, 19, 21, and 30).

GöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇ

CHANGE 10 GÇö Add config validation task
Location: Build Stage 1 table, after Task 1a row.
Add new row:

| 1b | Implement config validation: Zod schema for `config.yaml`, startup validation with descriptive errors for missing file, invalid YAML, and schema violations | GÇö | Task 1 | GÇö | Not Started |

GöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇ

CHANGE 11 GÇö Expand Task 9 description to cover realign complexity
Location: Build Stage 2 table, Task 9 row.
Replace the Task cell text with:

Implement correction loop: chat-based revisions and "realign from here" baseline-reset (identify last substantive correction, discard subsequent AI revisions, re-distill from original brain dump plus all corrections up to baseline)

GòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉ
FILE: docs/thoughtforge-build-spec.md
GòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉ

CHANGE 12 GÇö Add Project ID Format section
Location: After the `status.json` Schema section.
Add new section:

## Project ID Format

**Used by:** Task 2 (project initialization)

Project IDs are generated as `{timestamp}_{short_random}` GÇö e.g., `20260213_a3f2`. Format: `YYYYMMDD` date + underscore + 4-character lowercase alphanumeric random suffix. This ensures chronological sorting by default, human readability in file paths, and collision avoidance. The ID becomes the directory name (`/projects/{id}/`) and the Vibe Kanban task ID.

GöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇ

CHANGE 13 GÇö Add test-runner details truncation spec
Location: In the Plugin Interface Contract section, after the `test-runner.js`
description ending "Called by the orchestrator before each Phase 4 Code mode
review step, and during Phase 3 Code mode build iteration."
Add:

The orchestrator passes the `details` string verbatim into the reviewer prompt as a fenced code block under a `## Test Results` heading. If `details` exceeds 5,000 characters, it is truncated to the last 5,000 characters with a `[truncated]` prefix.

GöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇ

CHANGE 14 GÇö Add fabrication guard near-convergence proximity factor
Location: In the Convergence Guard Parameters section, Fabrication Guard,
after condition 2 ("Prior near-convergence").
Add:

- **Prior near-convergence proximity factor:** 2+ù the termination thresholds. Computed as: critical Gëñ `critical_max` (always 0), medium Gëñ `medium_max +ù 2`, minor Gëñ `minor_max +ù 2`. Using defaults: Gëñ0 critical, Gëñ6 medium, Gëñ10 minor.

GöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇGöÇ

CHANGE 15 GÇö Add PlanBuilderResponse success/stuck behavior spec
Location: After the PlanBuilderResponse interface definition.
Add:

When `stuck` is `false`: `content` contains the fully rendered plan document (all OPA sections filled). The orchestrator writes `content` to the plan deliverable file in `/docs/`. The `reason` field is omitted or null.

When `stuck` is `true`: `content` is omitted or contains the partially completed document. `reason` is required and describes the specific decision or information needed from the human.

GòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉGòÉ

After all changes are applied:
1. git add docs/thoughtforge-design-specification.md docs/thoughtforge-execution-plan.md docs/thoughtforge-build-spec.md
2. git commit with message:
   "Apply plan review findings: clarity rewrites, missing plan-level content, build spec extractions"
3. git push to remote
```
