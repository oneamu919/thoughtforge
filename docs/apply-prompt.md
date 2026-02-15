# Apply Review Findings

Apply every change below to the source files. Each change specifies the target file, what to find, and what to replace or add. Do not interpret or reword — use the text exactly as given.

Read all three source files before making any changes:
- `docs/thoughtforge-design-specification.md`
- `docs/thoughtforge-build-spec.md`
- `docs/thoughtforge-execution-plan.md`

---

## Section 1: Writing That's Unclear (6 Minor replacements)

### 1A. Design Spec — Phase 1 Step 9 "realign from here" wording

**File:** `docs/thoughtforge-design-specification.md`
**Location:** Phase 1, Step 9 (around line 95)
**Action:** Find the step 9 description that says "realign from here" "discards messages after the most recent substantive human correction and re-distills." Replace the entire step 9 text with:

> 9. Human can type "realign from here" in chat. Unlike phase advancement actions (which use buttons), this is a chat-parsed command that excludes messages after the most recent substantive human correction from the working context and re-distills. Excluded messages are retained in `chat_history.json` for audit trail but not passed to the AI. Matching rules and algorithm in build spec.

---

### 1B. Design Spec — Phase 4 Stagnation Guard parenthetical

**File:** `docs/thoughtforge-design-specification.md`
**Location:** Convergence Guards table, Stagnation Guard row (around line 347)
**Action:** Find the parenthetical `(fewer than 70% of current issues match prior iteration issues by Levenshtein similarity >= 0.8 on description)` and replace with:

> (fewer than 70% of issues in the current iteration have a Levenshtein similarity ≥ 0.8 match on `description` against the immediately prior iteration's issues)

---

### 1C. Design Spec — Phase 4 Fix Regression Guard ambiguity

**File:** `docs/thoughtforge-design-specification.md`
**Location:** Fix Regression Guard description (around line 345)
**Action:** Find `If the fix step increases total errors for 2 consecutive iterations` and replace with:

> If the fix step increases total error count in 2 back-to-back iterations (the two most recent consecutive fix steps both made things worse), halt and notify.

---

### 1D. Design Spec — Locked File Behavior for spec.md and intent.md

**File:** `docs/thoughtforge-design-specification.md`
**Location:** Locked file behavior section (around lines 169-175)
**Action:** Find the block describing `spec.md` and `intent.md` locked file behavior (includes "Read once at Phase 3 start. Not re-read during later phases." and "On server restart, in-memory copies are discarded."). Replace the entire block with:

> - **`spec.md` and `intent.md` (static after creation):**
>   - Read at Phase 3 start and used by the Phase 3 builder. Not re-read during Phase 4 iterations — Phase 4 uses `constraints.md` and the deliverable itself.
>   - Manual human edits during active pipeline execution have no effect — the pipeline works from its Phase 3 context.
>   - On server restart, any in-memory Phase 3 context is discarded. When a halted project is resumed during Phase 3, the orchestrator re-reads both files from disk. When a halted project is resumed during Phase 4, neither file is re-read — Phase 4 operates from `constraints.md` and the current deliverable state.
>   - There is no "restart from Phase N" capability in v1. The pipeline does not detect or warn about manual edits to any locked file.

---

### 1E. Design Spec — Phase 3 Code Mode test-fix cycle bounding

**File:** `docs/thoughtforge-design-specification.md`
**Location:** Phase 3 Code Mode, test-fix cycle description (around line 247)
**Action:** Find the text about the test-fix cycle being "bounded by the agent timeout and the human's ability to terminate" and the following sentence about a deferred hard cap. Replace the entire passage with:

> In practice, the code builder's test-fix cycle is bounded by the stuck detector (which fires on repeated identical failures) and the human's ability to terminate via the Phase 3 stuck recovery buttons. A test-fix cycle that produces rotating failures (different tests failing each cycle) will not trigger stuck detection and will continue indefinitely until the human intervenes or the agent timeout kills a single invocation. A hard cap on Phase 3 test-fix cycles is deferred — not a current build dependency.

---

### 1F. Execution Plan — Critical Path correction

**File:** `docs/thoughtforge-execution-plan.md`
**Location:** Critical Path section (around line 193)
**Action:** Replace the current critical path chain (which lists "Task 13 → Task 6c") with:

> **Task 1 → Task 41 → Task 42 → Task 6a → Task 8 → Task 9 → Task 11 → Task 12 → Task 13 → Task 15 → Task 6c → Task 30 → Tasks 33–37 → Task 51**
>
> Note: Task 13 is not a declared code dependency of Task 6c, but Task 6c cannot be meaningfully tested without Phase 2 outputs (spec.md, constraints.md) existing. Task 15 (plan builder) must complete before Task 6c can be exercised in Plan mode. The critical path reflects the functional chain, not just the task-level code dependencies.

---

## Section 2: Genuinely Missing Plan-Level Content (2 Major + 5 Minor additions)

### 2A. [MAJOR] Design Spec — WebSocket Shutdown behavior

**File:** `docs/thoughtforge-design-specification.md`
**Location:** Immediately after the existing Graceful Shutdown paragraph (around line 457)
**Action:** Add the following new paragraph:

> **WebSocket Shutdown:** During graceful shutdown, the server sends a WebSocket close frame (code 1001, "Server shutting down") to all connected clients before stopping the HTTP listener. Clients receive the close event and display a "Server stopped" message instead of triggering the auto-reconnect loop. On server restart, clients reconnect normally.

---

### 2B. [MAJOR] Design Spec — Partial Plan Build Recovery

**File:** `docs/thoughtforge-design-specification.md`
**Location:** Phase 3 Error Handling table, or immediately after the builder interaction model paragraph that describes multi-invocation plan building ("the builder may invoke the AI multiple times to fill the complete template")
**Action:** Add the following:

> **Partial Plan Build Recovery:** If the plan builder halts mid-template (agent failure on section N of M), the orchestrator commits the partially-filled template before halting. On resume, the builder re-reads the partially-filled template from disk, identifies which sections are complete (non-empty, non-placeholder content), and resumes from the first incomplete section. Already-filled sections are not re-generated.

---

### 2C. [Minor] Design Spec — Project ID Collision handling

**File:** `docs/thoughtforge-design-specification.md`
**Location:** Project Initialization Sequence or Phase 1 section, near the Project ID format description (`{timestamp}-{random}`)
**Action:** Add:

> **Project ID Collision:** If the generated project directory already exists (extremely unlikely with timestamp + random), generate a new random suffix and retry. If the directory still exists after 3 retries, halt with error: "Could not generate unique project ID. Check projects directory for stale entries."

---

### 2D. [Minor] Execution Plan — TypeScript execution model

**File:** `docs/thoughtforge-execution-plan.md`
**Location:** Design Decisions or Build Toolchain section
**Action:** Add:

> **TypeScript execution model:** ThoughtForge runs via `tsx` (or `ts-node`) during development and compiles to JavaScript via `tsc` for production deployment. Vitest handles TypeScript natively for tests (no separate compilation step). The `package.json` `start` script runs the compiled output; a `dev` script runs via `tsx` for live development.

---

### 2E. [Minor] Design Spec — Convergence Guards evaluation timing note

**File:** `docs/thoughtforge-design-specification.md`
**Location:** Convergence Guards table (around lines 342-349), add as a note row or footnote after the table
**Action:** Add:

> **Evaluation timing note:** Fix Regression is evaluated immediately after each fix step (before other guards). All other guards are evaluated after the full iteration cycle (review + fix) completes. See build spec Guard Evaluation Order for the complete sequence.

---

## Section 3: No Action Required

Findings 12-14 from the "Build Spec Material That Should Be Extracted" section all concluded with "No extraction needed" or "No extraction recommended." No file changes required.

---

## After All Changes Are Applied

1. Re-read each modified file to verify no formatting was broken and all changes landed correctly.
2. `git status -u` — verify all modified files.
3. `git diff --stat` — confirm changes.
4. Git add only the files you modified.
5. Commit with message: `Apply review findings`
6. Push to remote: `git push`
7. `git pull` — confirm sync with remote.
