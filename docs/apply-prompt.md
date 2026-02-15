# Apply Review Findings from results.md (Iteration 10)

You are an AI coder. Apply every change listed below to the source files. Each change is taken directly from the review findings in `results.md`. Do not interpret or improvise — apply the replacements, additions, and extractions exactly as specified.

Read all target files before editing. After all changes are applied, git commit and sync to remote.

---

## Target Files

- `docs/thoughtforge-design-specification.md` (referred to as "Design Spec")
- `docs/thoughtforge-build-spec.md` (referred to as "Build Spec")
- `docs/thoughtforge-execution-plan.md` (referred to as "Execution Plan")

Read all three files before making any edits.

---

## Changes to Apply

### Change 1 — Design Spec: Phase 2 "realign from here" rationale (Major)

**Location:** Phase 2 Conversation Mechanics (~line 141)

**Find:**
> The 'realign from here' command is not supported in Phase 2. If issued, it is ignored.

**Replace with:**
> The 'realign from here' command is not supported in Phase 2. If issued, it is ignored. Targeted corrections via chat handle all Phase 2 revisions.

---

### Change 2 — Design Spec: Phase 3 test-fix cycle clarification (Minor)

**Location:** Phase 3 Code Mode (~line 214)

**Find:**
> The code builder then enters a test-fix cycle: run tests, pass failures back to the agent, agent fixes, re-run tests — repeating until all tests pass or stuck detection triggers.

**Replace with:**
> The code builder then enters a test-fix cycle: run tests, pass failures back to the agent, agent fixes, re-run tests — repeating until all tests pass or stuck detection triggers. Unlike Phase 4 iterations, the Phase 3 test-fix cycle does not commit after each cycle — a single git commit is written when Phase 3 completes successfully.

---

### Change 3 — Build Spec: Crash recovery wording clarification (Minor)

**Location:** Code Builder Task Queue (~lines 206–208)

**Find:**
> On crash recovery, the code builder re-derives the task list from `spec.md` and the current project file state.

**Replace with:**
> On crash recovery, the code builder re-derives the task list from `spec.md` and the current state of files in the project directory (e.g., which source files and test files already exist).

---

### Change 4 — Execution Plan: Add Task 31 to orchestrator module note (Minor)

**Location:** Build Stage 8 note about Tasks 32, 38, 39 (~line 110)

**Find:**
> Tasks 32, 38, and 39 are implemented within the Task 30 orchestrator module, not as separate files. They are listed separately for progress tracking.

**Replace with:**
> Tasks 31, 32, 38, and 39 are implemented within the Task 30 orchestrator module, not as separate files. They are listed separately for progress tracking.

---

### Change 5 — Design Spec: Add `constraints.md` empty acceptance criteria handling (Major)

**Location:** Locked File Behavior section, after the `constraints.md` hot-reload paragraph (~line 149)

**Action:** Insert the following new paragraph immediately after the existing hot-reload paragraph:

> If the human empties or removes the Acceptance Criteria section from `constraints.md`, the reviewer proceeds with whatever criteria remain (which may be none). This is treated as an intentional human override — the pipeline does not validate that acceptance criteria are present after the initial Phase 2 write. The human accepts responsibility for review quality when manually editing `constraints.md`.

---

### Change 6 — Build Spec: Add VK card creation failure handling during initialization (Major)

**Location:** Project Initialization Sequence, after step 5 (~line 483)

**Action:** Insert the following new paragraph after the Kanban card creation step:

> If Vibe Kanban card creation fails during initialization, log a warning and continue. The project proceeds without a Kanban card. Subsequent VK status update calls for this project will also fail (card does not exist) and will be logged and ignored per standard VK failure handling. The pipeline is fully functional without VK visualization.

---

### Change 7 — Design Spec: Add `chat_history.json` completion behavior (Minor)

**Location:** Project State Files section, `chat_history.json` row (~line 503)

**Action:** Add the following to the `chat_history.json` description:

> Chat history is never cleared on pipeline completion (`done`) or halt. The full Phase 3 and Phase 4 chat history (including any recovery conversations) persists in the completed project for human reference.

---

### Change 8 — Execution Plan: Add path traversal validation to Task 7h (Minor)

**Location:** Task 7h in the execution plan

**Find:**
> Implement file/resource dropping in chat interface (upload to `/resources/`)

**Replace with:**
> Implement file/resource dropping in chat interface (upload to `/resources/`). Validate that resolved file paths stay within the project's `/resources/` directory — reject uploads with path traversal components (`..`, absolute paths).

---

### Change 9 — Execution Plan: Add unit test task for operational logging module (Minor)

**Location:** Build Stage 8 table, after the last test task row

**Action:** Add a new row to the table:

> | 50c | Unit tests: operational logging module (log file creation, structured JSON format, log levels, event types, file append failure handling) | — | Task 3a | — | Not Started |

---

### Change 10 — Extract connector URL patterns from Design Spec to Build Spec (Minor)

**Part A — Design Spec** (Phase 1 step 3, Connector URL Identification, ~line 80)

**Find:**
> The AI identifies connector URLs in chat messages by matching against known URL patterns for each enabled connector (e.g., `notion.so/` or `notion.site/` for Notion, `docs.google.com/` or `drive.google.com/` for Google Drive). URLs matching an enabled connector pattern are pulled automatically. URLs matching a disabled connector pattern are ignored. Unrecognized URLs are treated as regular brain dump text.

**Replace with:**
> The AI identifies connector URLs in chat messages by matching against known URL patterns for each enabled connector. Pattern definitions are in the build spec. URLs matching an enabled connector pattern are pulled automatically. URLs matching a disabled connector pattern are ignored. Unrecognized URLs are treated as regular brain dump text.

**Part B — Build Spec** (Resource Connector Interface section, ~lines 419–438)

**Add under the Notion Connector subsection:**
> **URL patterns:** `notion.so/`, `notion.site/`

**Add under the Google Drive Connector subsection:**
> **URL patterns:** `docs.google.com/`, `drive.google.com/`

---

## After All Changes Are Applied

1. Re-read each modified file to confirm no formatting is broken (unclosed tables, orphaned headers, broken markdown).
2. Git add only files you actually modified:
   ```bash
   git add docs/thoughtforge-design-specification.md docs/thoughtforge-build-spec.md docs/thoughtforge-execution-plan.md
   ```
3. Commit with message: `Apply review findings`
4. Push to remote: `git push`
5. Confirm the push succeeded. Do not leave commits unpushed.
