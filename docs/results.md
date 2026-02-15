Now I have full context. This is review iteration 10. Let me perform a thorough, fresh review of all three documents (design spec, build spec, execution plan) against the requirements brief, looking for genuine issues the previous reviews may have missed or that still remain.

---

# Plan Review — ThoughtForge Design Specification, Build Spec, and Execution Plan

**Review Iteration:** 10

---

## 1. Writing That's Unclear

**[Major]** Design Specification, Phase 2 Conversation Mechanics (line 141):

> "The 'realign from here' command is not supported in Phase 2. If issued, it is ignored."

This is buried mid-paragraph and doesn't explain *why* it's unsupported in Phase 2 when it's a core Phase 1 feature. A builder will wonder whether this is intentional or an omission. The lack of rationale invites re-litigation during build.

**Replacement:**
> "The 'realign from here' command is not supported in Phase 2. If issued, it is ignored. Targeted corrections via chat handle all Phase 2 revisions."

---

**[Minor]** Design Specification, Phase 3 Code Mode (line 214):

> "The code builder then enters a test-fix cycle: run tests, pass failures back to the agent, agent fixes, re-run tests — repeating until all tests pass or stuck detection triggers."

The term "test-fix cycle" is introduced here but isn't used anywhere else in the document. Phase 4 Code Mode uses "iteration cycle" (line 283). A builder may wonder whether the Phase 3 test-fix cycle has the same two-commit pattern as Phase 4 iterations. It doesn't — Phase 3 commits once at completion (line 254). This should be made explicit.

**Replacement:**
> "The code builder then enters a test-fix cycle: run tests, pass failures back to the agent, agent fixes, re-run tests — repeating until all tests pass or stuck detection triggers. Unlike Phase 4 iterations, the Phase 3 test-fix cycle does not commit after each cycle — a single git commit is written when Phase 3 completes successfully."

---

**[Minor]** Build Spec, Code Builder Task Queue (lines 206–208):

> "On crash recovery, the code builder re-derives the task list from `spec.md` and the current project file state."

"Current project file state" is vague. Does this mean the files on disk in the project directory? The contents of `status.json`? Both? A builder implementing crash recovery needs to know what to inspect.

**Replacement:**
> "On crash recovery, the code builder re-derives the task list from `spec.md` and the current state of files in the project directory (e.g., which source files and test files already exist)."

---

**[Minor]** Execution Plan, Build Stage 8 note about Tasks 32, 38, 39 (line 110):

> "Tasks 32, 38, and 39 are implemented within the Task 30 orchestrator module, not as separate files. They are listed separately for progress tracking."

This is useful but the same convention should be stated for Task 31 (Zod validation flow), which is also logically part of the Task 30 orchestrator and depends on it identically. A builder may create a separate module for Task 31 unnecessarily.

**Replacement:**
> "Tasks 31, 32, 38, and 39 are implemented within the Task 30 orchestrator module, not as separate files. They are listed separately for progress tracking."

---

**[Minor]** Design Specification, Phase 4, Stagnation Guard (line 301):

> "Done (success — treated as converged plateau)."

The parenthetical implies that stagnation-as-success is a design choice, but doesn't explain the rationale. A builder may question why stagnation isn't treated as a halt condition like hallucination and fabrication.

**Replacement:**
> "Done (success — treated as converged plateau). The reviewer is still finding the same number of issues but they are different issues each iteration, indicating the deliverable has reached a quality plateau where further iteration yields diminishing returns."

Wait — re-reading the guard: stagnation triggers when the count is flat AND rotation is detected (new issues replacing old). The notification says "polish sufficient." This is already well-explained in the notification examples (line 478). The guard table itself is the only place where the rationale is thin. But this is a design decision (locked), and the behavior is clear enough. I'm below 80% confidence this is actually a problem.

**Withdrawn — does not meet the 80% threshold.**

---

## 2. Genuinely Missing Plan-Level Content

**[Major]** No specification for how the orchestrator handles `constraints.md` hot-reload when the file has been externally modified to contain invalid or empty acceptance criteria.

The design spec (line 149) states: "The pipeline re-reads `constraints.md` at the start of each Phase 4 iteration, so manual human edits to acceptance criteria or review rules are picked up automatically." It also states: "If `constraints.md` is unreadable or missing… the iteration halts." And if restructured: "ThoughtForge passes it to the AI reviewer as-is."

However, there's no guidance on what happens when `constraints.md` is readable and structurally present but the Acceptance Criteria section has been emptied by the human. The reviewer would receive a document with no acceptance criteria — meaning the review has no quality target. For plan mode this might produce a vacuously passing review; for code mode the acceptance tests (which still exist from Phase 3) would have no corresponding criteria to validate against.

**Proposed content to add** (Design Specification, Locked File Behavior, after the `constraints.md` hot-reload paragraph):

> If the human empties or removes the Acceptance Criteria section from `constraints.md`, the reviewer proceeds with whatever criteria remain (which may be none). This is treated as an intentional human override — the pipeline does not validate that acceptance criteria are present after the initial Phase 2 write. The human accepts responsibility for review quality when manually editing `constraints.md`.

---

**[Major]** No specification for what happens when the Vibe Kanban card creation fails during project initialization.

The design spec (line 438) covers VK CLI failure handling for visualization-only calls ("failure is logged as a warning and the pipeline continues") and for agent execution calls ("treated as an agent failure"). Project initialization (line 65) includes "registers the project on the Kanban board." But initialization happens *before* the pipeline starts — it's not a "visualization-only call" in the sense of a mid-pipeline status update, nor is it an agent execution call. The build spec's initialization sequence (line 483) says "If Vibe Kanban integration is enabled, create a corresponding Kanban card" without specifying failure behavior.

A builder will need to decide: does VK card creation failure during init block the project or continue without a card?

**Proposed content to add** (Build Spec, Project Initialization Sequence, after step 5):

> If Vibe Kanban card creation fails during initialization, log a warning and continue. The project proceeds without a Kanban card. Subsequent VK status update calls for this project will also fail (card does not exist) and will be logged and ignored per standard VK failure handling. The pipeline is fully functional without VK visualization.

---

**[Minor]** No specification for the `chat_history.json` behavior when Phase 4 terminates successfully (convergence or stagnation).

The design spec (line 503) specifies when `chat_history.json` is cleared: "Cleared after each phase advancement confirmation (Phase 1 → Phase 2 and Phase 2 → Phase 3)." It also specifies that Phase 3→4 does NOT clear it. But it doesn't specify whether anything happens to chat history when the pipeline reaches `done`. This matters for the project's post-completion state — if someone opens the project chat after completion, do they see the Phase 3/4 recovery messages?

**Proposed content to add** (Design Specification, Project State Files, `chat_history.json` row):

> Chat history is never cleared on pipeline completion (`done`) or halt. The full Phase 3 and Phase 4 chat history (including any recovery conversations) persists in the completed project for human reference.

---

**[Minor]** No specification for resource file path validation on upload.

The design spec (line 34 in Inputs table) says resources are dropped into `/projects/{id}/resources/`. The build spec's Action Button Behavior doesn't cover file drops. The execution plan Task 7h says "Implement file/resource dropping in chat interface (upload to `/resources/`)." But there's no specification for path traversal prevention — if the upload mechanism allows arbitrary filenames, a malformed filename could write outside `/resources/`.

**Proposed content to add** (Execution Plan, Task 7h):

Current: "Implement file/resource dropping in chat interface (upload to `/resources/`)"

**Replacement:**
> "Implement file/resource dropping in chat interface (upload to `/resources/`). Validate that resolved file paths stay within the project's `/resources/` directory — reject uploads with path traversal components (`..`, absolute paths)."

---

**[Minor]** Execution Plan has no task for testing the operational logging module (`thoughtforge.log`).

Build Stage 8 has unit tests for: project state (Task 45), plugin loader (Task 46), convergence guards (Task 47), agent adapters (Task 48), resource connectors (Task 49), notification layer (Task 50), config loader (Task 50a), first-run setup (Task 50b), prompt editor (Task 58), chat interface (Task 58a), action buttons (Task 58b), file drop (Task 58c), realign (Task 58d), stuck recovery (Task 58e), WebSocket reconnection (Task 58f), concurrency (Task 58g), server restart (Task 58h), resource file processing (Task 58i).

Missing: unit tests for the operational logging module (Task 3a). This module is called by every event-producing task. If it silently fails (e.g., file write error, malformed JSON), debugging becomes impossible.

**Proposed content to add** (Execution Plan, Build Stage 8 table, new row):

> | 50c | Unit tests: operational logging module (log file creation, structured JSON format, log levels, event types, file append failure handling) | — | Task 3a | — | Not Started |

---

## 3. Build Spec Material That Should Be Extracted

**[Minor]** Design Specification, Phase 1 step 3, Connector URL Identification (line 80):

> "The AI identifies connector URLs in chat messages by matching against known URL patterns for each enabled connector (e.g., `notion.so/` or `notion.site/` for Notion, `docs.google.com/` or `drive.google.com/` for Google Drive). URLs matching an enabled connector pattern are pulled automatically. URLs matching a disabled connector pattern are ignored. Unrecognized URLs are treated as regular brain dump text."

The specific URL patterns (`notion.so/`, `notion.site/`, `docs.google.com/`, `drive.google.com/`) are implementation details. The design spec should state the *behavior* (AI identifies connector URLs by pattern matching), and the build spec should define the actual patterns. The build spec's Resource Connector Interface section (lines 419–438) already describes each connector but doesn't list the URL patterns, meaning these patterns exist only in the design spec — the wrong document.

**Recommendation:** Move the URL pattern list to the build spec's Resource Connector Interface section. Replace the design spec text with:

> "The AI identifies connector URLs in chat messages by matching against known URL patterns for each enabled connector. Pattern definitions are in the build spec. URLs matching an enabled connector pattern are pulled automatically. URLs matching a disabled connector pattern are ignored. Unrecognized URLs are treated as regular brain dump text."

And add to the build spec under each connector:

> **Notion Connector URL patterns:** `notion.so/`, `notion.site/`
> **Google Drive Connector URL patterns:** `docs.google.com/`, `drive.google.com/`

---

**[Minor]** Design Specification, Phase 4, Code Mode Iteration Cycle (lines 283–289):

> "1. **Test** — Orchestrator runs tests via the code plugin's `test-runner.js`..."

The reference to `test-runner.js` as a specific filename is build-spec-level detail. The design spec already references this correctly in the Plugin Folder Structure section (line 442) as "test runner for Code" and in the Plugin Interface Contract (line 446). This Phase 4 reference to the specific module filename is minor but inconsistent with how other modules are referenced in behavioral descriptions.

This is cosmetic and below the 80% threshold.

**Withdrawn — does not meet the 80% threshold.**

---

That concludes the review. Three lists, findings sorted by severity within each.
