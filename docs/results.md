Good. I've now read the complete plan corpus G«ˆ all four documents plus the review prompt, prior findings, results, and check prompt. Let me do the full review.

---

# ThoughtForge Plan Review

**Documents reviewed:** Requirements Brief, Design Specification, Execution Plan, Build Spec
**Prior review context:** Two prior review iterations exist (findings.md, results.md). I'm reviewing the current state of all documents as the baseline. Where prior reviews flagged issues that remain unapplied in the source files, I'm re-flagging them.

---

## 1. Writing That's Unclear

**[Major] Design Spec, Phase 1 Step 0 G«ˆ Project Initialization is a wall of text**

Line 58 packs ~8 distinct operations into a single dense paragraph. Both prior reviews flagged this and proposed numbered sub-steps. The paragraph is unchanged in the source file.

**Replacement:**
```
0. **Project Initialization:**
   1. Human initiates a new project via the ThoughtForge chat interface (e.g., a "New Project" command or button).
   2. ThoughtForge generates a unique project ID and creates the `/projects/{id}/` directory structure (including `/docs/` and `/resources/` subdirectories).
   3. Initializes a git repo in the project directory.
   4. Writes an initial `status.json` with phase `brain_dump` and `project_name` as empty string.
   5. Opens a new chat thread.
   6. If Vibe Kanban integration is enabled, a corresponding card is created at this point.
   7. After Phase 1 distillation locks `intent.md`, the project name is extracted from the `intent.md` title and written to `status.json`. If Vibe Kanban is enabled, the card name is updated at the same time.
```

---

**[Major] Design Spec, Phase 4 Code Mode Iteration Cycle G«ˆ dense inline paragraph**

Line 222 describes a three-step process (Test GÂ∆ Review GÂ∆ Fix) in a single paragraph with nested parentheticals. Both prior reviews flagged this. Unchanged in source.

**Replacement:**
```
**Code Mode Iteration Cycle:** Code mode adds a test execution step to each iteration. The full cycle per iteration is:

1. **Test** G«ˆ Orchestrator runs tests via the code plugin's `test-runner.js` and captures results.
2. **Review** G«ˆ Orchestrator passes test results as additional context to the reviewer AI, alongside the codebase and `constraints.md`. Reviewer outputs JSON error report including test results.
3. **Fix** G«ˆ Orchestrator passes issue list to fixer agent. Git commit after fix.

This three-step cycle repeats until a convergence guard triggers. Plan mode iterations use the two-step cycle (Review GÂ∆ Fix) with no test execution.
```

---

**[Major] Design Spec, Stagnation Guard G«ˆ "issue rotation" is under-explained**

Line 230's Action cell says `Done. Notify human: "Polish sufficient. Ready for final review."` but doesn't explain *why* changing issues at the same count indicates success. A builder would question this. Both prior reviews flagged it.

**Replacement for the Stagnation guard row's Action cell:**
> Done (success). The loop is producing different issues each iteration at the same count G«ˆ it's not fixing the same problems but finding new ones at the same rate, indicating the autonomous loop has reached diminishing returns. Notify human: "Polish sufficient. Ready for final review."

---

**[Minor] Design Spec, Hallucination Guard G«ˆ "spikes sharply" is subjective**

Line 229 says "Error count spikes sharply after a sustained downward trend." The build spec defines this precisely (>20% increase after 2+ declining iterations). The plan-level text should give directional specificity so a builder doesn't have to cross-reference.

**Replacement:**
> Error count increases meaningfully (e.g., >20%) after a sustained downward trend of 2+ iterations

---

**[Minor] Design Spec, Fabrication Guard G«ˆ same vagueness problem**

Line 231 says "spikes well above its recent average" and "previously approached convergence thresholds." The build spec defines these as >50% above trailing 3-iteration average, within 2+˘ of termination thresholds. The plan-level text should indicate scale.

**Replacement:**
> A severity category spikes significantly above its trailing average (e.g., >50% increase), AND the system had previously reached near-convergence (within roughly 2+˘ of termination thresholds) G«ˆ suggesting the reviewer is manufacturing issues because nothing real remains

---

**[Minor] Execution Plan, Task 30 dependency list G«ˆ hard to parse at a glance**

Task 30 (line 102) has the longest dependency chain in the plan. Technically correct but would benefit from a brief contextual note.

**Proposed:** Add a blockquote above Task 30's row:
> Task 30 is the main polish loop G«ˆ it wires together the orchestrator, both plugin reviewers, review/fix prompts, and agent layer.

---

## 2. Genuinely Missing Plan-Level Content

**[Major] No project ID format specified**

The design spec says "ThoughtForge generates a unique project ID" (line 58) and uses `{id}` throughout but never states the format. This affects directory names, `status.json`, Vibe Kanban card IDs, and any future URL routing. Two builders would invent incompatible formats.

**Proposed addition** (Design Spec, after the Project Initialization section):
> **Project ID Format:** UUIDv4 via `crypto.randomUUID()`. Used for directory names, `status.json` identity, and Vibe Kanban card IDs. Human-readable project names are stored separately in `status.json` `project_name`.

---

**[Major] Safety rules operation vocabulary undefined**

The design spec says the orchestrator calls `safety-rules.js` `validate(operation)` (line 277) but never defines what `operation` values exist. The build spec shows `blockedOperations` as `string[]` with example values but these are examples, not a defined vocabulary. Two builders would produce incompatible operation taxonomies.

**Proposed addition** (Build Spec, under the `safety-rules.js` section):
```
**Operation Vocabulary (v1):**

| Operation | Meaning |
|---|---|
| `shell_exec` | Execute a shell command or subprocess |
| `file_create_source` | Create a source code file (`.js`, `.py`, `.ts`, `.sh`, etc.) |
| `file_create_doc` | Create a document file (`.md`, `.json` state files) |
| `package_install` | Install a package via npm, pip, etc. |
| `agent_invoke` | Invoke a coding agent for code generation |
| `test_run` | Execute a test suite |

Plan mode blocks: `shell_exec`, `file_create_source`, `package_install`, `agent_invoke`, `test_run`. Allows: `file_create_doc`.
Code mode blocks: none (all operations allowed).
```

---

**[Major] Phase 4 fix step failure handling missing**

The design spec defines error handling for the review step (Zod validation GÂ∆ retry GÂ∆ halt) and for the agent communication layer generally (retry once, halt on second). But Phase 4 has a specific nuance: if the fix step fails, should the orchestrator re-run the review before retrying the fix, or use the same review output? This is unspecified.

**Proposed addition** (Design Spec, after the Step 2 Fix description):
> **Fix Step Failure Handling:** If the fixer agent returns a non-zero exit, times out, or produces empty output, the same agent communication failure handling applies: retry once, halt and notify human on second failure. The failed iteration's review results are preserved in `polish_state.json` G«ˆ on resume, the orchestrator re-attempts the fix step using the same review output rather than re-running the review.

---

**[Major] No concurrency model for the web server**

The plan supports up to 3 parallel projects through a single Express/WebSocket server. But the design never specifies how multiple concurrent project chat sessions are handled. Is the WebSocket multiplexed by project ID? Does each project get its own connection? The project list sidebar is described but the underlying session model is absent.

**Proposed addition** (Design Spec, Technical Design section, after the ThoughtForge Stack table):
> **Concurrency Model:** The single Express/WebSocket server handles all active projects. Each WebSocket connection is scoped to a project ID G«ˆ the client sends the project ID on connection, and all subsequent messages are routed to that project's pipeline instance. Multiple browser tabs can connect to different projects simultaneously. Notification sends are stateless HTTP POSTs and require no concurrency coordination. The orchestrator runs one pipeline instance per active project; each instance operates on its own project directory and state files with no shared mutable state.

---

**[Major] No specification of how brain dump chat messages become distillation input**

Phase 1 describes "Human brain dumps into chat" (step 1) and "Human clicks Distill button" (step 4), then "AI reads all resources and the brain dump" (step 5). But the design never specifies how the chat messages are assembled into input for the distillation prompt. Are they concatenated? Separated? Pre-processed?

**Proposed addition** (Design Spec, Phase 1, as a new step between current steps 4 and 5):
> When the human clicks **Distill**, the orchestrator concatenates all human chat messages from the current `brain_dump` phase (from `chat_history.json`) in chronological order, separated by newlines. This concatenated text, along with any files in `/resources/`, is passed to the distillation prompt as the brain dump input. No pre-processing or summarization is applied G«ˆ the AI receives the raw human text.

---

**[Minor] No notification failure handling**

The design spec defines notification content and channels but never says what happens if delivery fails. Notifications are non-critical, but silent failure with no logging would make debugging harder.

**Proposed addition** (Design Spec, after the Notification Examples list):
> **Notification Failure Handling:** If a notification send fails (HTTP error, timeout, unreachable endpoint), the failure is logged to `thoughtforge.log` as a `warn`-level event. The pipeline does not halt or retry G«ˆ notifications are best-effort. The human can review missed notifications via the project's state files.

---

**[Minor] No guidance on manual edits to locked files**

The design spec says locked files can be edited manually "outside the pipeline" but doesn't say whether those edits take effect. Does the polish loop re-read `constraints.md` each iteration or cache it?

**Proposed addition** (Design Spec, after Phase 2 outputs):
> **Manual Edit Behavior:** The orchestrator re-reads `constraints.md` at the start of each Phase 4 iteration. Manual human edits to locked files between iterations will take effect on the next iteration. No cache G«ˆ always reads from disk.

---

**[Minor] Execution Plan missing chat UI integration tests**

Build Stage 8 has unit tests for state, plugins, guards, agents, connectors, notifications, and prompt editor. It has e2e tests. But there's no mention of testing the web chat interface.

**Proposed addition** (Execution Plan, Build Stage 8 table, after Task 58):
> | 58a | Integration tests: chat interface (WebSocket connection, message streaming, button actions, project switching, file upload to `/resources/`) | G«ˆ | Task 7, Task 10 | G«ˆ | Not Started |

---

**[Minor] Execution Plan missing prompt drafting completion criteria**

Tasks 7f, 15a, 19a, 21a, 30a, 30b are all "Draft `/prompts/{name}.md` prompt text." No completion criteria defined. Is it written and committed? Tested against a real agent?

**Proposed addition** (Execution Plan, before Build Stage 2, as a convention note):
> **Prompt drafting convention:** A prompt task is complete when the prompt file is written to `/prompts/`, committed, and verified to produce the expected structured output format when tested against at least one agent with representative input. Prompts are iterable G«ˆ refinement continues during integration testing (Build Stage 8) G«ˆ but the initial draft must produce valid output.

---

## 3. Build Spec Material That Should Be Extracted

**No findings.** The design spec consistently defers implementation details to the build spec using explicit forward references. The separation is clean.

---

## Summary

| Severity | Count |
|---|---|
| Critical | 0 |
| Major | 8 |
| Minor | 6 |

The plan is structurally sound G«ˆ no blockers, no contradictions, architecture is coherent. The 8 major findings fall into two categories: (1) three clarity rewrites that were flagged in prior reviews but never applied to the source files, and (2) five genuinely missing plan-level specifications that a builder would have to invent (project ID format, safety operation vocabulary, fix step failure handling, concurrency model, brain dump assembly). The minor findings are standard completeness improvements.

---

## Consolidated Coder Prompt

```
Apply the following changes to the ThoughtForge plan documents. Each change specifies
the target file, the location, and the exact content to add or replace. Do not interpret G«ˆ
apply exactly as written. All file paths are relative to docs/.

GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…
File: thoughtforge-design-specification.md
GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…

CHANGE 1 G«ˆ Replace Phase 1 Step 0 paragraph (line 58)
Find the paragraph starting with:
  "0. **Project Initialization:** Human initiates a new project via the ThoughtForge chat interface"
Replace the ENTIRE paragraph (from "0. **Project Initialization:**" through "...a corresponding card is created at this point.") with:

0. **Project Initialization:**
   1. Human initiates a new project via the ThoughtForge chat interface (e.g., a "New Project" command or button).
   2. ThoughtForge generates a unique project ID and creates the `/projects/{id}/` directory structure (including `/docs/` and `/resources/` subdirectories).
   3. Initializes a git repo in the project directory.
   4. Writes an initial `status.json` with phase `brain_dump` and `project_name` as empty string.
   5. Opens a new chat thread.
   6. If Vibe Kanban integration is enabled, a corresponding card is created at this point.
   7. After Phase 1 distillation locks `intent.md`, the project name is extracted from the `intent.md` title and written to `status.json`. If Vibe Kanban is enabled, the card name is updated at the same time.

**Project ID Format:** UUIDv4 via `crypto.randomUUID()`. Used for directory names, `status.json` identity, and Vibe Kanban card IDs. Human-readable project names are stored separately in `status.json` `project_name`.


CHANGE 2 G«ˆ Insert brain dump assembly step
After the current step 4 ("Human clicks **Distill** button G«ˆ signals that all inputs...") and before step 5 ("AI reads all resources..."), insert as a new step:

4a. When the human clicks **Distill**, the orchestrator concatenates all human chat messages from the current `brain_dump` phase (from `chat_history.json`) in chronological order, separated by newlines. This concatenated text, along with any files in `/resources/`, is passed to the distillation prompt as the brain dump input. No pre-processing or summarization is applied G«ˆ the AI receives the raw human text.


CHANGE 3 G«ˆ Replace Code Mode Iteration Cycle paragraph (line 222)
Find the paragraph starting with:
  "**Code Mode Iteration Cycle:** Code mode adds a test execution step"
Replace the ENTIRE paragraph with:

**Code Mode Iteration Cycle:** Code mode adds a test execution step to each iteration. The full cycle per iteration is:

1. **Test** G«ˆ Orchestrator runs tests via the code plugin's `test-runner.js` and captures results.
2. **Review** G«ˆ Orchestrator passes test results as additional context to the reviewer AI, alongside the codebase and `constraints.md`. Reviewer outputs JSON error report including test results.
3. **Fix** G«ˆ Orchestrator passes issue list to fixer agent. Git commit after fix.

This three-step cycle repeats until a convergence guard triggers. Plan mode iterations use the two-step cycle (Review GÂ∆ Fix) with no test execution.


CHANGE 4 G«ˆ Add fix step failure handling
After the line "**Step 2 G«ˆ Fix (apply recommendations):** Orchestrator passes JSON issue list to fixer agent, which applies fixes. Git commit snapshot after each step.", add:

**Fix Step Failure Handling:** If the fixer agent returns a non-zero exit, times out, or produces empty output, the same agent communication failure handling applies: retry once, halt and notify human on second failure. The failed iteration's review results are preserved in `polish_state.json` G«ˆ on resume, the orchestrator re-attempts the fix step using the same review output rather than re-running the review.


CHANGE 5 G«ˆ Clarify Hallucination guard (Convergence Guards table, line 229)
Replace the Condition cell:
  "Error count spikes sharply after a sustained downward trend"
With:
  "Error count increases meaningfully (e.g., >20%) after a sustained downward trend of 2+ iterations"


CHANGE 6 G«ˆ Clarify Stagnation guard Action cell (line 230)
Replace the Action cell:
  "Done. Notify human: "Polish sufficient. Ready for final review.""
With:
  "Done (success). The loop is producing different issues each iteration at the same count G«ˆ it's not fixing the same problems but finding new ones at the same rate, indicating the autonomous loop has reached diminishing returns. Notify human: "Polish sufficient. Ready for final review.""


CHANGE 7 G«ˆ Clarify Fabrication guard (line 231)
Replace the Condition cell:
  "A severity category spikes well above its recent average, AND the system had previously approached convergence thresholds G«ˆ suggesting the reviewer is manufacturing issues because nothing real remains"
With:
  "A severity category spikes significantly above its trailing average (e.g., >50% increase), AND the system had previously reached near-convergence (within roughly 2+˘ of termination thresholds) G«ˆ suggesting the reviewer is manufacturing issues because nothing real remains"


CHANGE 8 G«ˆ Add concurrency model
In the Technical Design section, after the ThoughtForge Stack table and before the "### Vibe Kanban" heading, add:

**Concurrency Model:** The single Express/WebSocket server handles all active projects. Each WebSocket connection is scoped to a project ID G«ˆ the client sends the project ID on connection, and all subsequent messages are routed to that project's pipeline instance. Multiple browser tabs can connect to different projects simultaneously. Notification sends are stateless HTTP POSTs and require no concurrency coordination. The orchestrator runs one pipeline instance per active project; each instance operates on its own project directory and state files with no shared mutable state.


CHANGE 9 G«ˆ Add notification failure handling
After the Notification Examples list (after the last example bullet), add:

**Notification Failure Handling:** If a notification send fails (HTTP error, timeout, unreachable endpoint), the failure is logged to `thoughtforge.log` as a `warn`-level event. The pipeline does not halt or retry G«ˆ notifications are best-effort. The human can review missed notifications via the project's state files.


CHANGE 10 G«ˆ Add manual edit behavior
After Phase 2 step 9 ("Outputs: `spec.md` and `constraints.md` written to `/docs/` and locked..."), add:

**Manual Edit Behavior:** The orchestrator re-reads `constraints.md` at the start of each Phase 4 iteration. Manual human edits to locked files between iterations will take effect on the next iteration. No cache G«ˆ always reads from disk.


GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…
File: thoughtforge-build-spec.md
GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…

CHANGE 11 G«ˆ Add operation vocabulary under safety-rules.js
After the `safety-rules.js` interface definition (after the line "- `validate(operation)` GÂ∆ `{ allowed: boolean, reason?: string }` G«ˆ called by orchestrator before every Phase 3/4 action."), add:

**Operation Vocabulary (v1):**

| Operation | Meaning |
|---|---|
| `shell_exec` | Execute a shell command or subprocess |
| `file_create_source` | Create a source code file (`.js`, `.py`, `.ts`, `.sh`, etc.) |
| `file_create_doc` | Create a document file (`.md`, `.json` state files) |
| `package_install` | Install a package via npm, pip, etc. |
| `agent_invoke` | Invoke a coding agent for code generation |
| `test_run` | Execute a test suite |

Plan mode blocks: `shell_exec`, `file_create_source`, `package_install`, `agent_invoke`, `test_run`. Allows: `file_create_doc`.
Code mode blocks: none (all operations allowed).


GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…
File: thoughtforge-execution-plan.md
GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…

CHANGE 12 G«ˆ Add prompt drafting convention
Before the "### Build Stage 2" heading, add:

> **Prompt drafting convention:** A prompt task is complete when the prompt file is written to `/prompts/`, committed, and verified to produce the expected structured output format when tested against at least one agent with representative input. Prompts are iterable G«ˆ refinement continues during integration testing (Build Stage 8) G«ˆ but the initial draft must produce valid output.


CHANGE 13 G«ˆ Add context comment above Task 30
Before Task 30's row in the Build Stage 6 table, add as a blockquote:

> Task 30 is the main polish loop G«ˆ it wires together the orchestrator, both plugin reviewers, review/fix prompts, and agent layer.


CHANGE 14 G«ˆ Add chat UI integration test
In the Build Stage 8 table, after Task 58, add:

| 58a | Integration tests: chat interface (WebSocket connection, message streaming, button actions, project switching, file upload to `/resources/`) | G«ˆ | Task 7, Task 10 | G«ˆ | Not Started |


GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…
After all changes are applied
GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…GÚ…

1. Review each file to confirm no formatting was broken by the insertions.
2. git add docs/thoughtforge-design-specification.md docs/thoughtforge-build-spec.md docs/thoughtforge-execution-plan.md
3. git commit -m "polish: apply review iteration 3 G«ˆ 8 major, 6 minor findings"
4. git push
```
