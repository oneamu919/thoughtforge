# Apply Review Findings

Apply every change listed below to the source files. Each change includes the target file, the location, and the exact replacement or addition. Do not interpret or improvise — apply as written.

**Do NOT modify files in `docs.backup/`.** Only modify the primary files in `docs/`.

---

## Source files

- **Design spec:** `docs/thoughtforge-design-specification.md`
- **Build spec:** `docs/thoughtforge-build-spec.md`
- **Execution plan:** `docs/thoughtforge-execution-plan.md`

Read ALL three files in full before making any edits.

---

## Changes to Apply

### 1. [Minor] Design spec — Move "Locked File Behavior" block before Phase 1

**File:** `docs/thoughtforge-design-specification.md`

**Action:** Find the full "Locked File Behavior" block (currently under Phase 2, approximately lines 171–193). Cut it and move it to a standalone section under "Behavior" BEFORE Phase 1, titled "Locked File Behavior." Then find both inline references to locked file behavior (one in Phase 1 around line 98, one in Phase 2 around line 169) and replace each with:

> "Locked" means the AI pipeline will not modify these files after their creation phase — see Locked File Behavior above.

---

### 2. [Minor] Design spec — Clarify "test-fix cycle" vs "build iteration" in Phase 3 Code Mode

**File:** `docs/thoughtforge-design-specification.md`

**Action:** Find the paragraph around line 263 in Phase 3 Code Mode that mentions "a single invocation or multi-turn session, depending on how Vibe Kanban executes." Replace it with:

> The agent is responsible for scaffolding, implementation, and initial test writing. This initial build is either a single agent invocation (VK disabled) or a multi-turn VK-managed session (VK enabled). After the initial build invocation completes, the code builder enters the test-fix cycle described below.

---

### 3. [Minor] Design spec — Fix Stagnation Guard notification example

**File:** `docs/thoughtforge-design-specification.md`

**Action:** Find the notification example around line 588 that says `"polish sufficient"`. Replace that notification example string with:

> `"Project 'CLI Tool' — stagnation convergence. Error count stable at {N} for {M} iterations with issue rotation. Treated as converged. Ready for final review."`

---

### 4. [Minor] Execution plan — Clarify Task 12 dependency on Task 25

**File:** `docs/thoughtforge-execution-plan.md`

**Action:** Find Task 12's "Depends On" column (around line 77). Replace its dependency list with:

> `Task 6a, Task 10, Task 11, Task 7a, Task 7f, Tasks 41–42; Task 25 (Code mode only — Plan mode can proceed without it)`

---

### 5. [Minor] Build spec — Define `constraints.md` truncation strategy

**File:** `docs/thoughtforge-build-spec.md`

**Action:** Find the sentence around line 926 that says "exceeds the available context budget when combined with other review context." Replace the surrounding paragraph/sentence describing the truncation strategy with:

> If `constraints.md` combined with other review context (deliverable content, test results, and the review prompt) exceeds the agent's `context_window_tokens` as estimated by `character_count / 4`, `constraints.md` is truncated from the middle — the Context and Deliverable Type sections (top) and the Acceptance Criteria section (bottom) are preserved, and middle sections (Priorities, Exclusions, Severity Definitions, Scope) are removed in reverse order until the total fits. A warning is logged identifying which sections were removed.

---

### 6. [Minor] Design spec + Build spec — Fix Regression guard wording

**File:** `docs/thoughtforge-design-specification.md`

**Action:** Find the Fix Regression guard table entry around line 386. Replace its description with:

> **Fix Regression (per-iteration):** Evaluated at the start of each iteration (after the review step produces error counts), comparing the current iteration's total error count against the previous iteration's total error count. If the current count is higher than the previous, the most recent fix step made things worse. **Single occurrence:** Log a warning but continue. **Consecutive occurrences:** If the two most recent iterations both show increased total error counts compared to their respective prior iterations, halt and notify.

**File:** `docs/thoughtforge-build-spec.md`

**Action:** Find the corresponding Fix Regression description around lines 285-286. Replace it with:

> **Fix Regression** (per-iteration) — checked after each review step produces error counts. Compares current iteration's total error count to the prior iteration's total error count. If the current count is higher, the prior iteration's fix step introduced more issues than it resolved. If 2 consecutive iterations show increases, halt and notify.

---

### 7. [Minor] Design spec — Remove redundant button description block

**File:** `docs/thoughtforge-design-specification.md`

**Action:** Find and delete the "Phase 1 has two action buttons" block (around lines 78-81) entirely. The interaction model paragraph (around line 71) and the confirmation model paragraph (around line 112) already cover this content.

---

### 8. [Critical] Design spec — Add Fix Regression guard evaluation mechanism

**File:** `docs/thoughtforge-design-specification.md`

**Action:** In the Phase 4 Convergence Guards section, add the following new paragraph BEFORE the guard table:

> **Fix Regression evaluation mechanism:** The Fix Regression guard does not run a second review within the same iteration. Instead, it compares consecutive iterations: iteration N's review reveals the error state after iteration N-1's fix. If iteration N's total error count exceeds iteration N-1's total error count, the prior fix introduced more issues than it resolved. "Two consecutive regressions" means iterations N and N+1 both show higher counts than their respective predecessors (N-1 and N).

---

### 9. [Major] Execution plan — Add Phase 3 test-fix cycle stuck detection task

**File:** `docs/thoughtforge-execution-plan.md`

**Action:** Add a new task row after Task 21 in Build Stage 4:

> | 21b | Implement Code mode Phase 3 test-fix cycle: run tests → pass failures to agent → fix → retest loop. Including stuck detection: halt after 2 consecutive non-zero exits on same task, or 3 consecutive identical failing test sets (exact string match on test names). | — | Task 21, Task 24 | — | Not Started |

---

### 10. [Major] Design spec — Add `polish_state.json` initial state specification

**File:** `docs/thoughtforge-design-specification.md`

**Action:** In the Phase 4 Loop State Persistence section, after the existing description of `polish_state.json` (around line 402), add:

> **Initial state:** When Phase 4 begins (Phase 3→4 transition), `polish_state.json` does not exist yet. The orchestrator initializes it after the first iteration completes. Before the first iteration, the orchestrator operates with `iteration: 0` and empty `convergence_trajectory`. If the pipeline halts or crashes during the first iteration (before `polish_state.json` is written), the orchestrator creates the file with the initial state on resume and re-attempts the first iteration.

---

### 11. [Major] Execution plan — Add Phase 2 validation gate details to Task 12

**File:** `docs/thoughtforge-execution-plan.md`

**Action:** Find Task 12's description. Append to it:

> Including: Unknown resolution validation gate (block Confirm if unresolved Unknowns or Open Questions remain, present remaining items to human), Acceptance Criteria validation gate (block Confirm if Acceptance Criteria section is empty or missing, re-invoke AI once if section heading absent, halt on second failure).

---

### 12. [Minor] Design spec — Add Phase 3/4 live status display specification

**File:** `docs/thoughtforge-design-specification.md`

**Action:** Find the line around 325 that says "The human can view the project's chat history and current status." Add the following after it:

> During Phase 4, the chat panel displays a live status summary updated after each iteration: current iteration number, error counts (critical/medium/minor/total), convergence trajectory direction (improving/stable/worsening), and the most recent guard evaluation result. During Phase 3, the chat panel displays the current build step (e.g., "Building section 3 of 7" for Plan mode, or "Test-fix cycle, iteration 2" for Code mode). These are read from `polish_state.json` (Phase 4) and builder progress (Phase 3) respectively.

---

### 13. [Minor] Design spec — Add Code builder task decomposition strategy

**File:** `docs/thoughtforge-design-specification.md`

**Action:** In Phase 3 Code Mode, after the paragraph you replaced in Change 2 above, add:

> **Code builder task decomposition:** The code builder derives an ordered task list from `spec.md`'s Deliverable Structure section. Each major architectural component or feature becomes a build task. The task list is persisted to `task_queue.json` at derivation time for crash recovery (see build spec Code Builder Task Queue). The coding agent receives the full `spec.md` as context for each task but is instructed to focus on the current task. Task granularity is determined by the code builder, not prescribed — it depends on the architecture complexity described in `spec.md`.

---

### 14. [Minor] Execution plan — Add Phase 3/4 live status display task

**File:** `docs/thoughtforge-execution-plan.md`

**Action:** Add a new task row to Build Stage 6, after Task 40a:

> | 40b | Implement Phase 3/4 live status display in chat panel: Phase 4 shows iteration number, error counts, trajectory direction, guard result after each iteration; Phase 3 shows current build step. Read from `polish_state.json` and builder progress. Update via WebSocket push after each iteration/step completes. | — | Task 7, Task 30, Task 38 | — | Not Started |

---

### 15. [Minor] Design spec + Build spec — Extract fix agent context assembly detail

**File:** `docs/thoughtforge-design-specification.md`

**Action:** Find the paragraph around lines 355-356 starting "The fix agent receives the JSON issue list..." Locate the fragment `"parsed as relative paths from project root; line numbers are stripped before file lookup"`. Remove that fragment and replace the surrounding sentence with:

> The fix agent receives the issue list and the content of files referenced in each issue's location field.

**File:** `docs/thoughtforge-build-spec.md`

**Action:** Add a new subsection "Fix Agent Context Assembly" near the fix prompt section:

> **Fix Agent Context Assembly:** Location fields in the issue JSON are parsed as relative paths from the project root. Line numbers (if present) are stripped before file lookup. The fix agent receives the full content of each referenced file alongside the issue list.

---

### 16. [Minor] Design spec — Add template content escaping cross-reference

**File:** `docs/thoughtforge-design-specification.md`

**Action:** Find the line around 246 in Phase 3 Plan Mode that says "AI-generated content must not break template rendering." Append to it:

> Template content escaping strategy is defined in the build spec.

---

### 17. [Minor] Design spec + Build spec — Extract notification examples

**File:** `docs/thoughtforge-design-specification.md`

**Action:** Find the notification example messages block (around lines 586-594, containing ~9 example notification strings). Keep only 2-3 representative examples. Remove the rest and add after the remaining examples:

> Full notification message templates are in the build spec.

**File:** `docs/thoughtforge-build-spec.md`

**Action:** Find the `NotificationPayload` schema (around line 1050). Immediately after it, add a new subsection "Notification Message Templates" containing ALL the notification example strings that were removed from the design spec.

---

## After All Changes Are Applied

1. Re-read each modified file to verify no formatting was broken, no surrounding content was accidentally deleted or duplicated, and all changes landed correctly.
2. Git commit and sync:

```bash
git status -u
git diff --stat
git add docs/thoughtforge-design-specification.md docs/thoughtforge-build-spec.md docs/thoughtforge-execution-plan.md
git commit -m "Apply review findings"
git push
git pull
```
