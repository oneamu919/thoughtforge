Now I have all four documents. Let me perform the detailed review as specified.

---

# Project Plan Review ΓÇö ThoughtForge

---

## 1. Writing That's Unclear

**[Minor]** Design Spec, Phase 4, "Code Mode Iteration Cycle" paragraph (lines 264): This is a single dense paragraph that describes the full code mode iteration cycle, commit strategy, and review JSON persistence. It buries critical sequencing information in a wall of text.

**Replacement:**

> **Code Mode Iteration Cycle:** Code mode extends the two-step cycle with a test execution step. The full cycle per iteration is:
>
> 1. **Test** ΓÇö Orchestrator runs tests via the code plugin's `test-runner.js` and captures results.
> 2. **Review** ΓÇö Orchestrator passes test results as additional context to the reviewer AI alongside the codebase and `constraints.md`. Reviewer outputs a JSON error report.
> 3. **Fix** ΓÇö Orchestrator passes the issue list to the fixer agent.
>
> Plan mode uses the two-step cycle (Review ΓåÆ Fix) with no test execution.
>
> **Commit pattern:** Both modes commit twice per iteration ΓÇö once after the review step (captures review artifacts and test results) and once after the fix step (captures applied fixes). This enables rollback of a bad fix while preserving the review that identified the issues.
>
> **Review JSON persistence:** The review JSON output is persisted as part of the `polish_state.json` update and the `polish_log.md` append at each iteration boundary ΓÇö it is not written as a separate file.

---

**[Minor]** Design Spec, Phase 4 Stagnation guard description (line 272): The phrase "the specific issues change between iterations while the total count stays flat" is a natural-language description that doesn't match the algorithmic definition in the Build Spec (70% rotation threshold with Levenshtein similarity). A builder reading only the Design Spec would not know what "issue rotation detected" means concretely.

**Replacement:**

> **Stagnation** | Same total error count for 3+ consecutive iterations AND issue rotation detected ΓÇö fewer than 70% of current issues match prior iteration issues by description similarity, indicating the loop is replacing old issues with new ones at the same rate. | Done (success). Notify human: "Polish sufficient. Ready for final review."

---

**[Minor]** Design Spec, Phase 1, step 9 "realign from here" (lines 89ΓÇô94): The description of "baseline identification" says "the last human message that is not a 'realign from here' command" but doesn't clarify what happens if there are multiple "realign from here" commands in sequence. The current wording could be read as only excluding the final one.

**Replacement for step 9.1:**

> 1. **Baseline identification:** The AI identifies the human's most recent substantive correction ΓÇö defined as the last human message that is not a "realign from here" command. If multiple "realign from here" commands were sent in sequence, all of them are skipped to find the substantive message.

---

**[Minor]** Design Spec, "Manual Edit Behavior" section (lines 140ΓÇô144): The statement about `spec.md` and `intent.md` says "the only way to pick up those changes is to create a new project" but doesn't say this clearly enough for a builder. It could be read as "there is a mechanism to restart" rather than "there is no mechanism."

**Replacement:**

> **`spec.md` and `intent.md` (static after creation):** These are read once at Phase 3 start and not re-read during later phases. If the human manually edits these files after their creation phase, the changes are silently ignored for the remainder of the pipeline run. There is no "restart from Phase N" capability in v1. The pipeline does not detect or warn about manual edits to any locked file.

---

**[Minor]** Design Spec, Concurrency limit enforcement (line 455): The paragraph says "Within a single project, the pipeline is single-threaded ΓÇö only one operation executes at a time. The orchestrator serializes operations per project." It doesn't clarify whether this means the orchestrator uses a lock, a queue, or simply assumes single-threaded Node.js event loop semantics.

**Replacement (append to existing sentence):**

> Within a single project, the pipeline is single-threaded ΓÇö only one operation (phase transition, polish iteration, button action) executes at a time. This is enforced by the sequential nature of the pipeline: each phase awaits completion before the next begins, and button presses are ignored while an operation is in progress. No explicit locking is required.

---

**[Minor]** Execution Plan, Task 2a description (line 29): "Phase 4 per-iteration commits are handled separately in Task 40" ΓÇö but the task list shows Task 40 as "Implement git auto-commit after each review and fix step." A builder could be confused about whether Task 2a or Task 40 handles the Phase 3ΓåÆ4 transition commit.

**Replacement for Task 2a:**

> Implement git commit at pipeline milestones: `intent.md` lock (end of Phase 1), `spec.md` and `constraints.md` lock (end of Phase 2), Phase 3 build completion (including the Phase 3ΓåÆ4 transition commit). Phase 4 per-iteration commits (after each review step and after each fix step) are handled in Task 40.

---

**[Minor]** Design Spec, "Fabrication Guard" description (line 273): The phrase "the system had previously approached convergence thresholds" is vague. The Build Spec defines "within 2├ù of the termination thresholds" but the Design Spec doesn't reference this.

**Replacement:**

> **Fabrication** | A severity category spikes significantly above its trailing 3-iteration average, AND the system had previously reached within 2├ù of convergence thresholds in at least one prior iteration ΓÇö suggesting the reviewer is manufacturing issues because nothing real remains | Halt. Notify human.

---

## 2. Genuinely Missing Plan-Level Content

**[Major]** Design Spec ΓÇö No error handling or behavior defined for concurrent button presses or rapid re-clicks. If a human clicks "Confirm" twice in rapid succession, or clicks "Distill" while distillation is already running, the behavior is unspecified. This will cause bugs at build time.

**Proposed content to add (under "Action Button Behavior"):**

> **Button Debounce:** Once an action button is pressed, it is immediately disabled in the UI and remains disabled until the triggered operation completes or fails. A second click on a disabled button has no effect. If the server receives a duplicate action request for a button that has already been processed (e.g., due to a race condition between client and server), the server ignores the duplicate and returns the current project state.

---

**[Major]** Design Spec and Execution Plan ΓÇö No definition of what "project deletion" or "project cleanup" looks like, even as a deferred item. The plan says "Project archival, deletion, and re-opening are deferred" but does not specify what happens to the `/projects/` directory over time. A builder needs to know whether to worry about disk space, stale project directories, or directory listing performance.

**Proposed content to add (under "Project Lifecycle After Completion"):**

> **Disk management:** Project directories accumulate indefinitely in v1. The operator is responsible for manually deleting completed or halted project directories when no longer needed. ThoughtForge does not track or limit total disk usage. Automated project archival and cleanup are deferred ΓÇö not a current build dependency.

---

**[Major]** Design Spec ΓÇö No behavior defined for what happens when the operator restarts the ThoughtForge server while projects are mid-pipeline. Projects in `building` or `polishing` state may have been mid-operation when the server stopped. The plan needs to specify whether the server resumes those projects automatically on restart or waits for human action.

**Proposed content to add (new section under Technical Design, after "Application Entry Point"):**

> **Server Restart Behavior:** On startup, the server scans `/projects/` for projects with non-terminal `status.json` states (`brain_dump`, `distilling`, `human_review`, `spec_building`, `building`, `polishing`). Projects in human-interactive states (`brain_dump`, `human_review`, `spec_building`) resume normally ΓÇö they are waiting for human input and no action is needed. Projects in autonomous states (`distilling`, `building`, `polishing`) are set to `halted` with `halt_reason: "server_restart"` and the human is notified. The human must explicitly resume these projects. The server does not automatically re-enter autonomous pipeline phases after a restart.

---

**[Minor]** Design Spec ΓÇö No specification for the project ID format. The plan says "Generate a unique project ID" but doesn't specify format (UUID, timestamp-based, slug, sequential). This affects directory naming, URL routing, and Vibe Kanban card IDs.

**Proposed content to add (under Phase 1, step 0.1):**

> **Project ID format:** A URL-safe, filesystem-safe string. Format: `{timestamp}-{random}` (e.g., `20260214-a3f2`). The timestamp prefix enables chronological sorting of project directories. The random suffix ensures uniqueness. No spaces, no special characters beyond hyphens.

---

**[Minor]** Execution Plan ΓÇö No testing task for the Plan Completeness Gate. Task 53 tests "Plan ΓåÆ Code chaining" but doesn't explicitly test the gate's pass/fail/override/terminate paths. The gate has non-trivial logic (multi-file scanning, AI assessment, two button paths) that warrants its own test coverage.

**Proposed content to add (new task after Task 53):**

> | 53a | End-to-end test: Plan Completeness Gate (pass with complete plan, fail with incomplete plan, Override proceeds to build, Terminate halts project) | ΓÇö | Task 6d, Task 53 | ΓÇö | Not Started |

---

**[Minor]** Design Spec ΓÇö No specification for maximum brain dump size or resource file size limits. If a user drops a 500MB file or pastes a 100,000-word brain dump, the behavior is undefined. This will affect agent prompt construction and could cause agent timeouts or failures.

**Proposed content to add (under Phase 1 Error Handling):**

> | Brain dump text exceeds agent context window | AI processes in chunks if the configured agent supports it, otherwise truncates to the agent's maximum input size with a warning in chat: "Brain dump exceeds maximum input size. Processing first {N} characters." |
> | Resource file exceeds reasonable size (>50MB) | Log a warning, skip the file, and notify the human in chat: "File '{filename}' exceeds 50MB size limit and was skipped." |

---

**[Minor]** Design Spec ΓÇö The WebSocket reconnection section specifies client-side behavior thoroughly but doesn't mention server-side session tracking. The server needs to know which project a reconnecting client was viewing in order to send the correct state on reconnect.

**Proposed content to add (append to WebSocket Disconnection section):**

> **Server-side session:** The server does not maintain persistent WebSocket session state. On reconnect, the client sends the project ID it was viewing. The server responds with the current `status.json` and latest `chat_history.json` for that project. If the project ID is invalid, the server responds with the project list.

---

## 3. Build Spec Material That Should Be Extracted

**[Minor]** Design Spec, Phase 1 step 0 ΓÇö Project Initialization sequence (lines 63ΓÇô76): The numbered sub-steps (1-6) describing the exact initialization sequence ΓÇö generate ID, create directories, init git, write initial status.json, create Kanban card, open chat thread ΓÇö are implementation ordering instructions. The plan should state what initialization produces, not the exact sequence. The sequence belongs in the build spec alongside Task 2's implementation details.

---

**[Minor]** Design Spec, "Reconnection behavior" (lines 473ΓÇô474): The specific exponential backoff parameters (starting at 1 second, capped at 30 seconds, no maximum retry limit) are implementation-level configuration, not plan-level design decisions. The plan should state "auto-reconnect with backoff." The specific parameters belong in the build spec.

---

**[Minor]** Design Spec, "Project Name Derivation" (lines 74): The rule "uses the first heading (H1) of the distilled document" and the fallback "generates a short descriptive name (2-4 words)" are implementation-level details about how name extraction works. The plan should state "project name is derived from the distilled intent." The extraction algorithm belongs in the build spec.

---

That concludes the review. The plan is thorough and well-structured. The critical and major items above are the ones that would cause real builder confusion or rework if left unaddressed before implementation begins.
