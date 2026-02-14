Good G현 I have the full prior review context. Now I've read every document end-to-end. Let me compile my review.

---

# ThoughtForge Plan Review

**Documents reviewed:** Requirements Brief, Design Specification, Execution Plan, Build Spec

**Prior review context:** 15 findings from a previous iteration were noted in `state/findings.md`. I am treating the current state of all documents as the baseline and evaluating fresh.

---

## 1. Writing That's Unclear

**[Minor] Design Spec, Phase 1 step 0 G현 Project Initialization is a wall of text**

The project initialization paragraph (design spec line 58) packs ~8 distinct operations into a single sentence. A builder will have to re-read it multiple times to extract the sequence.

**Replacement text:**
> 0. **Project Initialization:**
>    1. Human initiates a new project via the ThoughtForge chat interface (e.g., a "New Project" command or button).
>    2. ThoughtForge generates a unique project ID and creates the `/projects/{id}/` directory structure (including `/docs/` and `/resources/` subdirectories).
>    3. Initializes a git repo in the project directory.
>    4. Writes initial `status.json` with phase `brain_dump` and `project_name` as empty string.
>    5. Opens a new chat thread.
>    6. If Vibe Kanban integration is enabled, creates a corresponding card.
>    7. After Phase 1 distillation locks `intent.md`, the project name is extracted from the `intent.md` title and written to `status.json`. If Vibe Kanban is enabled, the card name is updated at the same time.

---

**[Minor] Design Spec, Phase 4 Code Mode Iteration Cycle G현 dense inline description**

The code mode iteration cycle (design spec line 222) describes a three-step process in a single paragraph that's hard to scan. The parenthetical nesting makes it worse.

**Replacement text:**
> **Code Mode Iteration Cycle:** Code mode adds a test execution step to each iteration. The full cycle per iteration is:
>
> 1. **Test** G현 Orchestrator runs tests via the code plugin's `test-runner.js` and captures results.
> 2. **Review** G현 Orchestrator passes test results as additional context to the reviewer AI, alongside the codebase and `constraints.md`. Reviewer outputs JSON error report including test results.
> 3. **Fix** G현 Orchestrator passes issue list to fixer agent. Git commit after fix.
>
> This three-step cycle repeats until a convergence guard triggers. Plan mode iterations use the two-step cycle (Review G樣 Fix) with no test execution.

---

**[Minor] Design Spec, Stagnation Guard description G현 "issue rotation" is under-explained at the plan level**

The stagnation guard (design spec line 230) says "specific issues change between iterations even though the total stays flat" but doesn't clarify the *intent* of why rotation matters G현 a builder reading only the design spec would wonder why changing issues with the same count means success rather than failure.

**Replacement text for the stagnation guard row's Action cell:**
> Done (success). The loop is producing different issues each iteration at the same count G현 it's not fixing the same problems but finding new ones at the same rate, indicating the autonomous loop has reached diminishing returns. Notify human: "Polish sufficient. Ready for final review."

---

**[Minor] Execution Plan, Task 30 dependency list G현 hard to parse**

Task 30 (line 102) depends on `Task 3, Task 6a, Task 6c, Task 17, Task 22, Tasks 30aG혀30b, Tasks 41G혀42`. This is the longest dependency chain in the plan and mixes foundation, orchestrator, both plugin reviewers, prompts, and agent layer. It's correct but a builder scanning the table will struggle to understand *why* all these are needed.

No replacement text needed G현 this is a minor readability note. Consider adding a one-line comment above Task 30's row: `> Task 30 is the main polish loop G현 it wires together the orchestrator, both plugin reviewers, review/fix prompts, and agent layer.`

---

**[Minor] Design Spec, `chat_history.json` clearing behavior G현 split across two locations**

The clearing rules appear in both the Phase-to-State Mapping table (line 98 area, implicitly) and the Project State Files section (line 395). The state files section is authoritative but the clearing semantics ("Cleared after each phase advancement confirmation (Phase 1 G樣 Phase 2 and Phase 2 G樣 Phase 3). Phase 3G樣4 is automatic and does NOT clear chat history") are only fully stated in the state files section. A builder implementing Phase 2 might not find it.

**Proposed fix:** Add a single sentence to Phase 2 step 8 (design spec line 113):
> Human clicks **Confirm** G樣 advances to Phase 3. Chat history is cleared on confirmation (Phase 3 stuck recovery starts with a fresh thread).

---

## 2. Genuinely Missing Plan-Level Content

**[Major] No project ID format specified**

The design spec says "ThoughtForge generates a unique project ID" and uses `{id}` throughout but never states the format. This affects directory names, `status.json`, Vibe Kanban card IDs, and any future URL routing. A builder will have to invent it.

**Proposed addition** (Design Spec, after the Project Initialization numbered list):
> **Project ID Format:** UUIDv4 (e.g., `a3f1b2c4-...`). Used for directory names, `status.json` identity, and Vibe Kanban card IDs. Human-readable project names are stored separately in `status.json` `project_name`.

---

**[Major] Safety rules operation vocabulary undefined**

The design spec says the orchestrator calls `safety-rules.js` `validate(operation)` but never defines what `operation` values exist. The build spec shows `blockedOperations` as `string[]` with example values `["shell_exec", "file_create_source", "package_install"]` but these are examples, not a defined vocabulary. Two independent builders would produce incompatible taxonomies.

**Proposed addition** (Build Spec, under the `safety-rules.js` section):
> **Operation Vocabulary (v1):**
>
> | Operation | Meaning |
> |---|---|
> | `shell_exec` | Execute a shell command or subprocess |
> | `file_create_source` | Create a source code file (`.js`, `.py`, `.ts`, `.sh`, etc.) |
> | `file_create_doc` | Create a document file (`.md`, `.json` state files) |
> | `package_install` | Install a package via npm, pip, etc. |
> | `agent_invoke` | Invoke a coding agent for code generation |
> | `test_run` | Execute a test suite |
>
> Plan mode blocks: `shell_exec`, `file_create_source`, `package_install`, `agent_invoke`, `test_run`. Allows: `file_create_doc`.
> Code mode blocks: none (all operations allowed).

---

**[Major] Phase 4 fix step failure handling missing**

The design spec defines error handling for the *review* step (Zod validation failure G樣 retry G樣 halt) but says nothing about what happens when the *fix* step fails. If the fixer agent crashes, times out, or produces empty output, the builder has no guidance.

**Proposed addition** (Design Spec, after the Phase 4 two-step description):
> **Fix Step Failure Handling:** If the fixer agent returns a non-zero exit, times out, or produces empty output, the same agent communication failure handling applies: retry once, halt and notify human on second failure. The failed iteration's review results are preserved in `polish_state.json` G현 on resume, the orchestrator re-attempts the fix step using the same review output rather than re-running the review.

---

**[Major] Test runner contract underspecified G현 what command does it actually run?**

The build spec defines `test-runner.js` returning `{ total, passed, failed, details }` but never says what underlying test command it invokes. `npm test`? `jest`? Whatever is in `package.json`? The design spec says "Runs all tests" but the builder needs to know the contract.

**Proposed addition** (Build Spec, under `test-runner.js`):
> **Test Execution Strategy:** `test-runner.js` invokes the project's test command as defined in the project's `package.json` `scripts.test` field (or equivalent for non-Node projects). It runs the command as a subprocess, parses the output for pass/fail counts (parser is agent/framework-specific G현 initially supports Jest output format), and returns the structured result. If no test command is defined, returns `{ total: 0, passed: 0, failed: 0, details: "No test command configured" }`.

---

**[Minor] No explicit error handling for the notification layer itself**

The design spec defines notification content and channels but never says what happens if notification delivery fails (ntfy.sh unreachable, HTTP timeout). Notifications are non-critical but a silent failure with no logging would make debugging harder.

**Proposed addition** (Design Spec, Notification Content section):
> **Notification Failure Handling:** If a notification send fails (HTTP error, timeout, unreachable endpoint), the failure is logged to `thoughtforge.log` as a `warn`-level event. The pipeline does not halt or retry G현 notifications are best-effort. The human can review missed notifications via the project's state files.

---

**[Minor] No guidance on what happens when the human edits locked files manually**

The design spec says `intent.md`, `spec.md`, and `constraints.md` are "locked G현 no further modification by AI in subsequent phases. Human may still edit manually outside the pipeline." But it doesn't say what happens if the human does edit them. Does the polish loop re-read them each iteration? Would manual edits take effect, or is the AI working from a cached version?

**Proposed addition** (Design Spec, after Phase 2 outputs):
> **Manual Edit Behavior:** The orchestrator re-reads `constraints.md` at the start of each Phase 4 iteration. Manual human edits to locked files between iterations will take effect on the next iteration. No cache G현 always reads from disk.

---

**[Minor] Execution Plan has no testing strategy for the chat UI itself**

Build Stage 8 has unit tests for state, plugins, guards, agents, connectors, notifications, and prompt editor. It has e2e tests for the full pipeline. But there's no mention of testing the web chat interface G현 WebSocket streaming, button interactions, project switching, file dropping. For a solo-operator tool this is low risk, but it's a gap against standard practice.

**Proposed addition** (Execution Plan, Build Stage 8 table):
> | 58a | Integration tests: chat interface (WebSocket connection, message streaming, button actions, project switching, file upload to `/resources/`) | G현 | Task 7, Task 10 | G현 | Not Started |

---

## 3. Build Spec Material That Should Be Extracted

**No findings.** The design spec and build spec boundary is well-maintained. Implementation details (schemas, prompts, CLI commands, function signatures) are already in the build spec. The design spec stays at the "what and why" level. Nothing to extract.

---

## Summary

| Severity | Count |
|---|---|
| Critical | 0 |
| Major | 4 |
| Minor | 7 |

The plan is solid. No blockers. The 4 major findings are all cases where a builder would have to invent something that should be decided at the plan level: project ID format, safety operation vocabulary, fix-step failure handling, and test runner invocation strategy. The minor findings are clarity improvements that reduce re-reading and prevent misinterpretation.

---

## Consolidated Coder Prompt

Below is the prompt you can hand directly to an AI coder to apply all changes:

---

**Apply the following changes to the ThoughtForge plan documents. Each change specifies the target file, the location, and the exact content to add or replace. Do not interpret G현 apply exactly as written.**

### Changes to `thoughtforge-design-specification.md`

**Change 1 G현 Replace Phase 1 step 0 paragraph (line 58)**
Find the paragraph starting with `0. **Project Initialization:** Human initiates...` and replace it with:

```
0. **Project Initialization:**
   1. Human initiates a new project via the ThoughtForge chat interface (e.g., a "New Project" command or button).
   2. ThoughtForge generates a unique project ID and creates the `/projects/{id}/` directory structure (including `/docs/` and `/resources/` subdirectories).
   3. Initializes a git repo in the project directory.
   4. Writes initial `status.json` with phase `brain_dump` and `project_name` as empty string.
   5. Opens a new chat thread.
   6. If Vibe Kanban integration is enabled, creates a corresponding card.
   7. After Phase 1 distillation locks `intent.md`, the project name is extracted from the `intent.md` title and written to `status.json`. If Vibe Kanban is enabled, the card name is updated at the same time.

**Project ID Format:** UUIDv4 (e.g., `a3f1b2c4-...`). Used for directory names, `status.json` identity, and Vibe Kanban card IDs. Human-readable project names are stored separately in `status.json` `project_name`.
```

**Change 2 G현 Replace Code Mode Iteration Cycle paragraph (line 222)**
Find the paragraph starting with `**Code Mode Iteration Cycle:** Code mode adds a test execution step...` and replace it with:

```
**Code Mode Iteration Cycle:** Code mode adds a test execution step to each iteration. The full cycle per iteration is:

1. **Test** G현 Orchestrator runs tests via the code plugin's `test-runner.js` and captures results.
2. **Review** G현 Orchestrator passes test results as additional context to the reviewer AI, alongside the codebase and `constraints.md`. Reviewer outputs JSON error report including test results.
3. **Fix** G현 Orchestrator passes issue list to fixer agent. Git commit after fix.

This three-step cycle repeats until a convergence guard triggers. Plan mode iterations use the two-step cycle (Review G樣 Fix) with no test execution.
```

**Change 3 G현 Replace Stagnation guard Action cell (line 230)**
In the Convergence Guards table, replace the stagnation guard's Action cell with:

```
Done (success). The loop is producing different issues each iteration at the same count G현 it's not fixing the same problems but finding new ones at the same rate, indicating the autonomous loop has reached diminishing returns. Notify human: "Polish sufficient. Ready for final review."
```

**Change 4 G현 Add fix step failure handling after Phase 4 description**
After the line `**Step 2 G현 Fix (apply recommendations):** Orchestrator passes JSON issue list to fixer agent, which applies fixes. Git commit snapshot after each step.`, add:

```
**Fix Step Failure Handling:** If the fixer agent returns a non-zero exit, times out, or produces empty output, the same agent communication failure handling applies: retry once, halt and notify human on second failure. The failed iteration's review results are preserved in `polish_state.json` G현 on resume, the orchestrator re-attempts the fix step using the same review output rather than re-running the review.
```

**Change 5 G현 Add notification failure handling**
After the Notification Examples list, add:

```
**Notification Failure Handling:** If a notification send fails (HTTP error, timeout, unreachable endpoint), the failure is logged to `thoughtforge.log` as a `warn`-level event. The pipeline does not halt or retry G현 notifications are best-effort. The human can review missed notifications via the project's state files.
```

**Change 6 G현 Add manual edit behavior after Phase 2 outputs**
After the line `9. Outputs: `spec.md` and `constraints.md` written to `/docs/` and locked...`, add:

```
**Manual Edit Behavior:** The orchestrator re-reads `constraints.md` at the start of each Phase 4 iteration. Manual human edits to locked files between iterations will take effect on the next iteration. No cache G현 always reads from disk.
```

**Change 7 G현 Add chat history clearing note to Phase 2 step 8**
Replace:
```
8. Human clicks **Confirm** G樣 advances to Phase 3
```
With:
```
8. Human clicks **Confirm** G樣 advances to Phase 3. Chat history is cleared on confirmation (Phase 3 stuck recovery starts with a fresh thread).
```

### Changes to `thoughtforge-build-spec.md`

**Change 8 G현 Add operation vocabulary under safety-rules.js section**
After the `safety-rules.js` interface definition (`validate(operation)` line), add:

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

**Change 9 G현 Add test execution strategy under test-runner.js**
After the `test-runner.js` interface definition, add:

```
**Test Execution Strategy:** `test-runner.js` invokes the project's test command as defined in the project's `package.json` `scripts.test` field (or equivalent for non-Node projects). It runs the command as a subprocess, parses the output for pass/fail counts (parser is agent/framework-specific G현 initially supports Jest output format), and returns the structured result. If no test command is defined, returns `{ total: 0, passed: 0, failed: 0, details: "No test command configured" }`.
```

### Changes to `thoughtforge-execution-plan.md`

**Change 10 G현 Add chat UI integration test**
In the Build Stage 8 table, after Task 58, add:

```
| 58a | Integration tests: chat interface (WebSocket connection, message streaming, button actions, project switching, file upload to `/resources/`) | G현 | Task 7, Task 10 | G현 | Not Started |
```

**Change 11 G현 Add context comment above Task 30**
Before Task 30's row in the Build Stage 6 table, add as a blockquote:

```
> Task 30 is the main polish loop G현 it wires together the orchestrator, both plugin reviewers, review/fix prompts, and agent layer.
```

### After all changes are applied

Run `git add thoughtforge-design-specification.md thoughtforge-build-spec.md thoughtforge-execution-plan.md && git commit -m "polish: iteration 2 G현 apply review findings (4 major, 7 minor)" && git push`.
