# Apply Review Findings to Source Files

Apply every change listed below to the source files. Each change is a direct replacement, addition, or extraction. Do not interpret or improvise — apply exactly what is specified.

Source files (all in `docs/`):
- `docs/thoughtforge-design-specification.md` (referred to as "Design Spec")
- `docs/thoughtforge-build-spec.md` (referred to as "Build Spec")
- `docs/thoughtforge-execution-plan.md` (referred to as "Execution Plan")

Read all three source files and `results.md` before making changes so you have full context.

---

## Section 1: Unclear Writing — Replacements

### 1.1 [Minor] Design Spec — Phase 4, "Code Mode Iteration Cycle" (around line 264)

Find the single dense paragraph describing the code mode iteration cycle, commit strategy, and review JSON persistence. Replace it with:

> **Code Mode Iteration Cycle:** Code mode extends the two-step cycle with a test execution step. The full cycle per iteration is:
>
> 1. **Test** — Orchestrator runs tests via the code plugin's `test-runner.js` and captures results.
> 2. **Review** — Orchestrator passes test results as additional context to the reviewer AI alongside the codebase and `constraints.md`. Reviewer outputs a JSON error report.
> 3. **Fix** — Orchestrator passes the issue list to the fixer agent.
>
> Plan mode uses the two-step cycle (Review → Fix) with no test execution.
>
> **Commit pattern:** Both modes commit twice per iteration — once after the review step (captures review artifacts and test results) and once after the fix step (captures applied fixes). This enables rollback of a bad fix while preserving the review that identified the issues.
>
> **Review JSON persistence:** The review JSON output is persisted as part of the `polish_state.json` update and the `polish_log.md` append at each iteration boundary — it is not written as a separate file.

### 1.2 [Minor] Design Spec — Phase 4, Stagnation guard (around line 272)

Find the stagnation guard table row or description containing "the specific issues change between iterations while the total count stays flat". Replace it with:

> **Stagnation** | Same total error count for 3+ consecutive iterations AND issue rotation detected — fewer than 70% of current issues match prior iteration issues by description similarity, indicating the loop is replacing old issues with new ones at the same rate. | Done (success). Notify human: "Polish sufficient. Ready for final review."

### 1.3 [Minor] Design Spec — Phase 1, step 9, "realign from here" baseline identification (around lines 89–94)

Find step 9.1 describing baseline identification with "the last human message that is not a 'realign from here' command". Replace it with:

> 1. **Baseline identification:** The AI identifies the human's most recent substantive correction — defined as the last human message that is not a "realign from here" command. If multiple "realign from here" commands were sent in sequence, all of them are skipped to find the substantive message.

### 1.4 [Minor] Design Spec — "Manual Edit Behavior" section (around lines 140–144)

Find the statement about `spec.md` and `intent.md` saying "the only way to pick up those changes is to create a new project". Replace the relevant paragraph with:

> **`spec.md` and `intent.md` (static after creation):** These are read once at Phase 3 start and not re-read during later phases. If the human manually edits these files after their creation phase, the changes are silently ignored for the remainder of the pipeline run. There is no "restart from Phase N" capability in v1. The pipeline does not detect or warn about manual edits to any locked file.

### 1.5 [Minor] Design Spec — Concurrency limit enforcement (around line 455)

Find the sentence "Within a single project, the pipeline is single-threaded — only one operation executes at a time. The orchestrator serializes operations per project." Replace it with:

> Within a single project, the pipeline is single-threaded — only one operation (phase transition, polish iteration, button action) executes at a time. This is enforced by the sequential nature of the pipeline: each phase awaits completion before the next begins, and button presses are ignored while an operation is in progress. No explicit locking is required.

### 1.6 [Minor] Execution Plan — Task 2a description (around line 29)

Find Task 2a's description about Phase 4 per-iteration commits. Replace the Task 2a description with:

> Implement git commit at pipeline milestones: `intent.md` lock (end of Phase 1), `spec.md` and `constraints.md` lock (end of Phase 2), Phase 3 build completion (including the Phase 3→4 transition commit). Phase 4 per-iteration commits (after each review step and after each fix step) are handled in Task 40.

### 1.7 [Minor] Design Spec — "Fabrication Guard" description (around line 273)

Find the fabrication guard description containing "the system had previously approached convergence thresholds". Replace it with:

> **Fabrication** | A severity category spikes significantly above its trailing 3-iteration average, AND the system had previously reached within 2× of convergence thresholds in at least one prior iteration — suggesting the reviewer is manufacturing issues because nothing real remains | Halt. Notify human.

---

## Section 2: Missing Content — Additions

### 2.1 [Major] Design Spec — Button Debounce

Add the following under the "Action Button Behavior" section in the Design Spec:

> **Button Debounce:** Once an action button is pressed, it is immediately disabled in the UI and remains disabled until the triggered operation completes or fails. A second click on a disabled button has no effect. If the server receives a duplicate action request for a button that has already been processed (e.g., due to a race condition between client and server), the server ignores the duplicate and returns the current project state.

### 2.2 [Major] Design Spec — Disk Management

Add the following as a new subsection under "Project Lifecycle After Completion" (or at the end of the project lifecycle section) in the Design Spec:

> **Disk management:** Project directories accumulate indefinitely in v1. The operator is responsible for manually deleting completed or halted project directories when no longer needed. ThoughtForge does not track or limit total disk usage. Automated project archival and cleanup are deferred — not a current build dependency.

### 2.3 [Major] Design Spec — Server Restart Behavior

Add the following as a new section under Technical Design, after "Application Entry Point" in the Design Spec:

> **Server Restart Behavior:** On startup, the server scans `/projects/` for projects with non-terminal `status.json` states (`brain_dump`, `distilling`, `human_review`, `spec_building`, `building`, `polishing`). Projects in human-interactive states (`brain_dump`, `human_review`, `spec_building`) resume normally — they are waiting for human input and no action is needed. Projects in autonomous states (`distilling`, `building`, `polishing`) are set to `halted` with `halt_reason: "server_restart"` and the human is notified. The human must explicitly resume these projects. The server does not automatically re-enter autonomous pipeline phases after a restart.

### 2.4 [Minor] Design Spec — Project ID Format

Add the following under Phase 1, step 0.1 (or adjacent to the "Generate a unique project ID" instruction) in the Design Spec:

> **Project ID format:** A URL-safe, filesystem-safe string. Format: `{timestamp}-{random}` (e.g., `20260214-a3f2`). The timestamp prefix enables chronological sorting of project directories. The random suffix ensures uniqueness. No spaces, no special characters beyond hyphens.

### 2.5 [Minor] Execution Plan — Plan Completeness Gate Test

Add the following new task row after Task 53 in the Execution Plan:

> | 53a | End-to-end test: Plan Completeness Gate (pass with complete plan, fail with incomplete plan, Override proceeds to build, Terminate halts project) | — | Task 6d, Task 53 | — | Not Started |

### 2.6 [Minor] Design Spec — Input Size Limits

Add the following to the Phase 1 Error Handling table in the Design Spec:

> | Brain dump text exceeds agent context window | AI processes in chunks if the configured agent supports it, otherwise truncates to the agent's maximum input size with a warning in chat: "Brain dump exceeds maximum input size. Processing first {N} characters." |
> | Resource file exceeds reasonable size (>50MB) | Log a warning, skip the file, and notify the human in chat: "File '{filename}' exceeds 50MB size limit and was skipped." |

### 2.7 [Minor] Design Spec — WebSocket Server-Side Session

Append the following to the WebSocket Disconnection/Reconnection section in the Design Spec:

> **Server-side session:** The server does not maintain persistent WebSocket session state. On reconnect, the client sends the project ID it was viewing. The server responds with the current `status.json` and latest `chat_history.json` for that project. If the project ID is invalid, the server responds with the project list.

---

## Section 3: Extractions — Move from Design Spec to Build Spec

### 3.1 [Minor] Design Spec — Phase 1 step 0, Project Initialization Sequence (around lines 63–76)

The numbered sub-steps (1-6) describing the exact initialization sequence (generate ID, create directories, init git, write initial status.json, create Kanban card, open chat thread) are implementation ordering. In the Design Spec, replace these detailed steps with a summary:

> **Project initialization** creates the project directory structure, initializes version control, writes the initial project state, registers the project on the Kanban board, and opens the chat interface.

Move the detailed numbered sequence into the Build Spec under Task 2's implementation details.

### 3.2 [Minor] Design Spec — Reconnection Backoff Parameters (around lines 473–474)

The specific exponential backoff parameters (starting at 1 second, capped at 30 seconds, no maximum retry limit) are implementation-level. In the Design Spec, replace with:

> The client auto-reconnects with exponential backoff.

Move the specific parameters (1s start, 30s cap, unlimited retries) into the Build Spec under the WebSocket implementation task.

### 3.3 [Minor] Design Spec — Project Name Derivation (around line 74)

The rule about using the first H1 heading and the 2-4 word fallback are implementation details. In the Design Spec, replace with:

> The project name is derived from the distilled intent document.

Move the extraction algorithm details (first H1 heading, 2-4 word fallback) into the Build Spec.

---

## After All Changes Are Applied

1. Re-read each modified file to confirm no formatting is broken (e.g., unclosed tables, orphaned headers).
2. Git add only files you actually modified:
   ```bash
   git add docs/thoughtforge-design-specification.md docs/thoughtforge-build-spec.md docs/thoughtforge-execution-plan.md
   ```
3. Commit with message: `Apply review findings`
4. Push to remote: `git push`
5. Confirm the push succeeded. Do not leave commits unpushed.
