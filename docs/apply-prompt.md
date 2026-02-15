# Apply Review Findings from results.md

You are applying the review findings from `docs/results.md` to the ThoughtForge project documents. Apply every change below exactly as described. Do not interpret or improvise — each change specifies the target file, location, and replacement or addition text.

Read ALL target files before making any edits:
- `docs/thoughtforge-design-specification.md`
- `docs/thoughtforge-build-spec.md`
- `docs/thoughtforge-execution-plan.md`

---

## Section 1: Writing That's Unclear — Replacements (3 Major, 4 Minor)

### 1.1 [Major] Design Spec — Stagnation Guard phrasing (line ~351)

**File:** `docs/thoughtforge-design-specification.md`
**Location:** Phase 4, Stagnation Guard description (around line 351)
**Action:** Find the sentence about issue rotation detection that says "Issue rotation detected (fewer than 70% of issues in the current iteration have a Levenshtein similarity ≥ 0.8 match on `description` against the immediately prior iteration's issues)" and replace it with:

> Issue rotation is detected when fewer than 70% of current-iteration issues can be matched (Levenshtein similarity ≥ 0.8 on `description`) to any issue in the immediately prior iteration — meaning more than 30% of issues are new, indicating the reviewer is cycling rather than converging.

---

### 1.2 [Major] Design Spec — test-fix cycle terminology (line ~251)

**File:** `docs/thoughtforge-design-specification.md`
**Location:** Phase 3, test-fix cycle description (around line 251)
**Action:** Find the first sentence of the paragraph describing the Phase 3 test-fix cycle and replace it with:

> The code builder then enters a **test-fix cycle** (distinct from Phase 4's review-fix iterations): run tests, pass failures back to the agent, agent fixes, re-run tests — repeating until all tests pass or stuck detection triggers.

---

### 1.3 [Major] Design Spec — Fix Regression Guard language (line ~349)

**File:** `docs/thoughtforge-design-specification.md`
**Location:** Phase 4, Fix Regression Guard (around line 349)
**Action:** Find the clause that uses "2 back-to-back iterations" and replace the relevant clause with:

> If the fix step increases total error count in 2 consecutive iterations (the two most recent fix steps both produced higher error counts than their respective review inputs), halt and notify.

---

### 1.4 [Minor] Design Spec — Terminology note (line ~11)

**File:** `docs/thoughtforge-design-specification.md`
**Location:** Terminology note near line 11
**Action:** Find the terminology note and replace it with:

> **Terminology convention (applies throughout all ThoughtForge documents):** "Human" and "operator" refer to the same person — the solo user. "Human" is used in pipeline flow descriptions. "Operator" is used in system administration contexts.

---

### 1.5 [Minor] Design Spec — OPA acronym confusion (line ~19)

**File:** `docs/thoughtforge-design-specification.md`
**Location:** OPA Framework section (around line 19)
**Action:** Find the first sentence of the OPA Framework section and replace it with:

> Plan mode deliverables use an **OPA Table** structure — **Objective → Plan → Assessment** — for every major section. This is distinct from the requirements brief's use of "OPA" (Outcome • Purpose • Action, Tony Robbins' RPM System), which is a document organization framework, not a deliverable content structure. To avoid ambiguity: "OPA Table" always refers to the deliverable structure; "OPA Framework" in the requirements brief refers to the brief's own organization.

---

### 1.6 [Minor] Build Spec — Task Queue crash recovery (line ~207)

**File:** `docs/thoughtforge-build-spec.md`
**Location:** Code Builder Task Queue section (around line 207)
**Action:** Find the passage that says "Whether to persist is a Task 21 implementation decision — but crash recovery must produce a compatible task ordering" and replace the surrounding text with:

> The code builder persists the initial task list to `task_queue.json` in the project directory at derivation time. On crash recovery, the builder re-reads `task_queue.json` rather than re-deriving from `spec.md`, ensuring deterministic task ordering across restarts.

---

### 1.7 [Minor] Execution Plan — Critical path annotation (lines ~196-197)

**File:** `docs/thoughtforge-execution-plan.md`
**Location:** Critical path section (around lines 196-197)
**Action:** Find the note that says "Note: Task 13 is not a declared code dependency of Task 6c, but Task 6c cannot be meaningfully tested without Phase 2 outputs" and replace it with:

> The functional critical path includes Task 13 → Task 15 → Task 6c even though Task 6c's code dependency is on Task 6a, because Phase 3→4 transition cannot be exercised without Phase 2 outputs (spec.md, constraints.md) and a Phase 3 builder producing deliverables.

---

## Section 2: Missing Content — Additions (2 Critical, 5 Major, 3 Minor)

### 2.1 [Critical] Design Spec — constraints.md missing at Phase 3→4 transition

**File:** `docs/thoughtforge-design-specification.md`
**Location:** Phase 3→4 Transition Error Handling table (near lines 293-298)
**Action:** Add a new row to the table:

> | `constraints.md` missing or unreadable at Phase 3→4 transition | Halt. Set `status.json` to `halted` with `halt_reason: "file_system_error"`. Notify human: "constraints.md missing or unreadable. Cannot start polish loop. Review project `/docs/` directory." Do not enter Phase 4. |

---

### 2.2 [Critical] Design Spec — Graceful shutdown effect on interactive states (Phase 1-2)

**File:** `docs/thoughtforge-design-specification.md`
**Location:** After the WebSocket shutdown section (after line ~465)
**Action:** Add the following paragraph:

> **Interactive state shutdown:** For projects in human-interactive states (`brain_dump`, `human_review`, `spec_building`), no server-side processing is interrupted — the server is waiting for human input. The WebSocket close frame is sent as described above. Any chat message the human was composing but had not yet sent is lost (client-side only). The last persisted message in `chat_history.json` is the recovery point on restart.

---

### 2.3 [Major] Design Spec — constraints.md truncation strategy (after line ~169)

**File:** `docs/thoughtforge-design-specification.md`
**Location:** After line 169 (about truncation with a warning logged)
**Action:** Add the following paragraph:

> **`constraints.md` truncation strategy:** If `constraints.md` exceeds the available context budget when combined with other review context, it is truncated from the middle — the Context and Deliverable Type sections (top) and the Acceptance Criteria section (bottom) are preserved, and middle sections (Priorities, Exclusions, Severity Definitions, Scope) are removed in reverse order until the file fits. A warning is logged identifying which sections were removed.

---

### 2.4 [Major] Execution Plan — Add task for Fix Regression guard

**File:** `docs/thoughtforge-execution-plan.md`
**Location:** Build Stage 6 task list (near Tasks 33-37)
**Action:** Add the following task row after Task 33:

> | 33a | Implement convergence guard: fix regression (per-iteration check — compare post-fix error count to pre-fix review count, warn on single occurrence, halt on 2 consecutive regressions). Evaluated immediately after each fix step, before other guards. | — | Task 30 | — | Not Started |

Also update Task 47's dependencies to include Task 33a, and add this test task row:

> | 47b | Unit tests: fix regression guard (single regression logs warning, 2 consecutive regressions halt, non-consecutive regressions reset counter, first iteration has no prior to compare) | — | Task 33a | — | Not Started |

---

### 2.5 [Major] Design Spec — Non-Node.js project handling (after line ~310)

**File:** `docs/thoughtforge-design-specification.md`
**Location:** Test Command Discovery section (after line ~310 mentioning `npm test`)
**Action:** Add the following paragraph:

> **Non-Node.js projects:** For deliverables in languages other than Node.js, the coding agent is instructed (via the `/prompts/code-build.md` prompt) to create a standard test entry point appropriate to the language (e.g., `Makefile` with `make test`, `pyproject.toml` with `pytest`, etc.). `test-runner.js` reads the project's `spec.md` Deliverable Structure section to determine the language and invokes the language-appropriate test command. The mapping from language to test command is a configuration in `test-runner.js`, not hardcoded to `npm test`.

---

### 2.6 [Major] Execution Plan — Amend Task 9a for chat_history.json error handling

**File:** `docs/thoughtforge-execution-plan.md`
**Location:** Task 9a description
**Action:** Append the following to the existing Task 9a description (do not replace, append):

> **Include error handling: halt and notify on unreadable, missing, or invalid `chat_history.json` (same behavior as `status.json` corruption).** Include context window truncation logic per build spec Chat History Truncation Algorithm.

---

### 2.7 [Major] Design Spec — Hard crash (ungraceful termination) handling (after line ~466)

**File:** `docs/thoughtforge-design-specification.md`
**Location:** After the graceful shutdown / WebSocket content (after line ~466)
**Action:** Add:

> **Hard crash (ungraceful termination):** If the server process terminates without sending a WebSocket close frame (kill -9, OOM, power loss), the client detects the dropped TCP connection via WebSocket `onerror` or `onclose` events. The same auto-reconnect behavior applies. The key difference from graceful shutdown: any agent subprocess that was running is killed by the OS (orphaned child process cleanup is OS-dependent). On restart, Server Restart Behavior applies — autonomous-state projects are halted. The client reconnects and syncs state normally.

---

### 2.8 [Minor] Build Spec — Levenshtein similarity formula (after line ~304)

**File:** `docs/thoughtforge-build-spec.md`
**Location:** After the Levenshtein similarity reference (near line 304)
**Action:** Add:

> **Levenshtein similarity formula:** Similarity is computed as `1 - (levenshtein_distance(a, b) / max(a.length, b.length))`. A result of 1.0 means identical strings; 0.0 means completely different. The ≥ 0.8 threshold means two descriptions match if they differ by no more than 20% of the longer string's length.

---

### 2.9 [Minor] Design Spec — Button display order (after line ~371)

**File:** `docs/thoughtforge-design-specification.md`
**Location:** Phase 4 halt recovery section (after line ~371)
**Action:** Add:

> **Button display order:** Recovery buttons are displayed left-to-right: Resume, Override, Terminate. Terminate is visually distinguished (e.g., red or separated by a divider) as the destructive option.

---

### 2.10 [Minor] Execution Plan — WebSocket close frame task (amend Task 1a)

**File:** `docs/thoughtforge-execution-plan.md`
**Location:** Task 1a description
**Action:** Append to the existing Task 1a description:

> Including graceful shutdown handler: on SIGTERM/SIGINT, send WebSocket close frame (code 1001) to all connected clients, wait for in-progress agent subprocesses (up to configured timeout), then exit.

---

## Section 3: Extractions — Move Implementation Detail to Build Spec (3 Major, 3 Minor)

### 3.1 [Major] Design Spec — Project Initialization Sequence (lines ~63-78)

**File:** `docs/thoughtforge-design-specification.md`
**Location:** Project Initialization Sequence (lines ~63-78)
**Action:** Remove the numbered implementation steps from lines 63-78. Replace with:

> Project initialization creates the project directory structure, initializes version control, writes the initial project state, optionally registers on the Kanban board, and opens the chat interface. The full initialization sequence is in the build spec.

**Keep** the Project ID collision handling (line ~69) and Git Initialization Failure (line ~75) — these are behavioral decisions that belong in the design spec.

---

### 3.2 [Major] Design Spec — Action Button Behavior (lines ~114-117)

**File:** `docs/thoughtforge-design-specification.md`
**Location:** Action Button Behavior section (lines ~114-117)
**Action:** Replace lines 114-117 with:

> Every action button follows the behavior contract defined in the build spec's Action Button Behavior inventory, which specifies `status.json` effects, UI feedback, and confirmation requirements for each button.

---

### 3.3 [Major] Design Spec — spec.md structure duplication (lines ~194-205)

**File:** `docs/thoughtforge-design-specification.md`
**Location:** `spec.md` structure table (lines ~194-205)
**Action:** Remove the `spec.md` structure table from lines 194-205. Replace with:

> **`spec.md` structure:** See build spec `spec.md` Structure section for the full template. Contains: Deliverable Overview, Deliverable Structure, Key Decisions, Resolved Unknowns, Dependencies, and Scope Boundaries.

**Keep** the Plan mode vs Code mode distinction sentence (line ~205).

---

### 3.4 [Minor] Design Spec — Zod validation flow (lines ~507-511)

**File:** `docs/thoughtforge-design-specification.md`
**Location:** Zod validation flow (lines ~507-511)
**Action:** Replace the step-by-step Zod validation flow with:

> Review JSON is validated against the Zod schema for the active deliverable type. Malformed responses are retried up to a configurable limit, then the pipeline halts and notifies the human. Validation flow and retry logic are in the build spec.

---

### 3.5 [Minor] Design Spec — Token estimation heuristic (line ~519)

**File:** `docs/thoughtforge-design-specification.md`
**Location:** Token estimation heuristic (line ~519)
**Action:** Remove the `character_count / 4` detail. Replace with:

> The token count is an approximation — the exact estimation method is in the build spec.

**Also add** to the build spec's Agent Communication section:

**File:** `docs/thoughtforge-build-spec.md`
**Location:** Agent Communication section
**Action:** Add:

> ThoughtForge estimates tokens as `character_count / 4` (a standard rough heuristic).

---

### 3.6 [Minor] Build Spec — Resolve test framework choice (lines ~706-712)

**File:** `docs/thoughtforge-build-spec.md`
**Location:** Build Toolchain section (lines ~706-712)
**Action:** Find "Test framework: Vitest (or Jest — decide before build starts)" and replace with:

> Test framework: Vitest

Remove the "(or Jest — decide before build starts)" equivocation.

---

## After All Changes Are Applied

1. Re-read each modified file to verify no formatting was broken and all changes landed correctly.
2. Run `git status -u` and `git diff --stat` to verify all modified files.
3. Stage all modified files: `git add docs/thoughtforge-design-specification.md docs/thoughtforge-build-spec.md docs/thoughtforge-execution-plan.md`
4. Commit with message: `Apply review findings`
5. Push to remote: `git push`
6. Run `git pull` to confirm sync with remote.
