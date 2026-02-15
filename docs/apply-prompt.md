# Apply Review Findings from results.md

Apply every change listed below to the source files. Each change is either a **replacement** (swap existing text for new text), an **addition** (insert new content at a specified location), or an **extraction** (move content from one file to another). Do not interpret or improvise — apply as written.

**Do NOT modify files in `docs.backup/`.** Only modify the primary files in `docs/`.

---

## Source Files

- **Design Spec:** `docs/thoughtforge-design-specification.md`
- **Build Spec:** `docs/thoughtforge-build-spec.md`
- **Execution Plan:** `docs/thoughtforge-execution-plan.md`

Read ALL three files in full before making any edits.

---

## Section 1: Replacements — Unclear Writing

### 1.1 — Phase 4 Stagnation Guard: "Issue rotation" phrasing (Design Spec, ~line 388)

**Find** the text describing issue rotation that reads approximately:
> (2) Issue rotation: Fewer than 70% of current-iteration issues match any issue in the immediately prior iteration

**Replace with:**
> (2) **Issue rotation:** More than 30% of current-iteration issues are new — i.e., fewer than 70% of current-iteration issues match any issue in the immediately prior iteration (match = Levenshtein similarity >= 0.8 on `description`). When both conditions are true, the reviewer is cycling cosmetic issues rather than finding genuine regressions.

---

### 1.2 — Fix Regression guard: evaluation timing note (Design Spec, ~line 392)

**Find** the evaluation timing note that reads approximately:
> Fix Regression is evaluated immediately after each fix step (before other guards).

**Replace with:**
> **Evaluation timing note:** Fix Regression is evaluated after each review step produces error counts (the review reveals the error state *after* the prior iteration's fix). It is checked before the other convergence guards. All other guards are evaluated after the full iteration cycle (review + fix) completes. See build spec Guard Evaluation Order for the complete sequence.

---

### 1.3 — "Two consecutive regressions" table entry (Design Spec, ~line 386)

**Find** the table entry that reads approximately:
> If the two most recent iterations both show increased total error counts compared to their respective prior iterations.

**Replace with:**
> If the current iteration and the immediately preceding iteration both show a total error count higher than the iteration before each of them (i.e., iteration N > iteration N-1 AND iteration N-1 > iteration N-2), halt and notify.

---

### 1.4 — "Halted" projects and terminal state language (Design Spec, ~line 602)

**Find** the paragraph about halted projects counting toward the active project limit that mentions "terminates them (setting them to terminal state)."

**Replace the entire paragraph with:**
> Halted projects and concurrency: Projects with `halted` status count toward the active project limit. This includes both recoverable halts and human-terminated projects (which also use the `halted` state). The only way to free a concurrency slot is for the project to reach `done` status or for the operator to manually delete the project directory. This prevents the operator from creating unlimited projects while ignoring halted ones.

---

### 1.5 — Critical path listing (Execution Plan, ~line 199)

**Find** the critical path listing that reads approximately:
> Task 1 → Task 41 → Task 42 → Task 6a → Task 8...

**Replace with:**
> **Task 1 → [Task 41 → Task 42 | Task 2 → Task 3 | Task 6] → Task 6a → Task 8 → Task 9 → Task 11 → Task 12 → Task 13 → Task 15 → Task 6c → Task 30 → Tasks 33–37 → Task 51**
>
> Tasks in brackets are parallel branches that must all complete before Task 6a can begin. The longest of these branches (41 → 42) determines the critical path duration.

---

### 1.6 — `constraints.md` truncation wording (Build Spec, ~line 934)

**Find** the text that reads approximately:
> middle sections (Priorities, Exclusions, Severity Definitions, Scope) are removed in reverse order until the total fits.

**Replace with:**
> middle sections are removed one at a time starting from the bottom of the document (Scope first, then Severity Definitions, then Exclusions, then Priorities) until the total fits.

---

### 1.7 — `constraints.md` — unvalidated after creation paragraph (Design Spec, ~lines 67-68)

**Find** the paragraph about `constraints.md` being unvalidated after creation (contains "If the human restructures the file" and "If the human empties the Acceptance Criteria section").

**Replace with:**
> **`constraints.md` — unvalidated after creation:** After initial creation, ThoughtForge does not validate `constraints.md` against any schema. If the human restructures the file, removes sections, or empties content, ThoughtForge passes the file to the AI reviewer as-is. This includes emptying the Acceptance Criteria section — the reviewer proceeds with zero criteria. This is treated as an intentional human override.

---

## Section 2: Additions — Missing Plan-Level Content

### 2.1 — Prompt Acceptance Criteria (Execution Plan)

**Location:** Immediately after the existing "Prompt Validation Strategy" section.

**Insert:**

> ### Prompt Acceptance Criteria
>
> Each pipeline prompt is considered accepted when:
> 1. The e2e test using the prompt produces a deliverable that reaches Phase 4 convergence (termination or stagnation success) within the configured `max_iterations` (default 50).
> 2. The AI's structured outputs (review JSON, `PlanBuilderResponse`) pass Zod validation on the first attempt at least 80% of iterations (prompt is producing schema-compliant output reliably).
> 3. No more than 3 prompt revision cycles are needed per prompt. If a prompt requires more than 3 revisions to pass e2e, the prompt's behavioral requirements (from the design spec) should be re-examined for feasibility before further iteration.

---

### 2.2 — `task_queue.json` corruption handling (Design Spec)

**Location:** Add a new row to the Phase 3 Error Handling table.

**Insert row:**

> | `task_queue.json` unreadable, missing, or invalid at Phase 3 resume | Halt and notify the operator with the file path and the specific error (parse failure, missing file, invalid schema). Same behavior as `status.json` and `chat_history.json` corruption handling. Do not attempt recovery or re-derivation from `spec.md` — the operator must fix or recreate the file. |

---

### 2.3 — Safety enforcement logging (TWO files)

**Addition 1 — Design Spec:** Insert after the "Enforcement" paragraph in the Plan Mode Safety Guardrails section:

> **Safety enforcement logging:** Every `validate()` call is logged to `thoughtforge.log` with the operation type, the result (`allowed`/`blocked`), and the reason if blocked. Blocked operations are logged at `warn` level. This provides an audit trail for debugging unexpected pipeline behavior and verifying that Plan mode safety rules are enforced correctly.

**Addition 2 — Build Spec:** Insert in the Operation Type Taxonomy section:

> The orchestrator logs every `validate()` call to the operational log: operation type, plugin type, and result. Blocked operations include the reason from the `validate()` return value.

---

### 2.4 — `polish_state.json` missing during active run (Design Spec)

**Location:** Add a new row to the Phase 4 Error Handling table.

**Insert row:**

> | `polish_state.json` missing during active Phase 4 iteration (deleted externally between iterations) | The orchestrator writes `polish_state.json` at each iteration boundary. If the file is missing when the orchestrator attempts to read convergence trajectory for guard evaluation, halt and notify the operator: "polish_state.json missing during active polish loop. File may have been deleted externally." Same behavior as Phase 4 resume corruption handling. |

---

### 2.5 — Levenshtein dependency note (Build Spec)

**Location:** Add to the Initial Dependencies section.

**Insert:**

> **Stagnation guard dependency:** Levenshtein distance computation for the stagnation guard's issue rotation detection. Either install a lightweight npm package (e.g., `fastest-levenshtein`, MIT, ~500 weekly downloads) or implement inline — the algorithm is ~15 lines.

---

### 2.6 — `ChatMessage` phase field clarification (Build Spec)

**Location:** Insert after the `ChatMessage` interface definition in the `chat_history.json` Schema section.

**Insert:**

> The `phase` field records the `status.json` phase value at the time the message was sent. During Phase 1, this means messages will carry `brain_dump`, `distilling`, or `human_review` as appropriate — these are the actual `status.json` values, not a collapsed "phase_1" label.

---

## Section 3: Extractions — Move Content Between Files

### 3.1 — Plan mode fix output validation thresholds (Design Spec → Build Spec)

**In Design Spec (~lines 358-359)**, find the text about fix output validation that mentions "50% of the pre-fix plan document" and "If 2 consecutive iterations produce rejected fix output."

**Replace with:**
> After the fix agent returns the updated plan document, the orchestrator validates that the returned content is non-empty and does not represent a significant reduction from the pre-fix document. If the check fails, the fix is rejected: the pre-fix plan document is preserved, a warning is logged, and the iteration proceeds using the pre-fix state. If consecutive iterations produce rejected fix output (exceeding the threshold defined in the build spec), the pipeline halts and notifies the human.

**Add to Build Spec (new section "Plan Mode Fix Output Validation Parameters"):**

> ### Plan Mode Fix Output Validation Parameters
>
> - **Minimum size ratio:** Fix output must be at least 50% of the pre-fix document's character count.
> - **Consecutive rejection limit:** 2 consecutive rejected fix outputs trigger a halt.

---

### 3.2 — Stagnation guard Levenshtein formula duplication (Design Spec — simplify)

**In Design Spec**, find the Stagnation Guard Detail paragraph that contains the Levenshtein formula `1 - (levenshtein_distance(a, b) / max(a.length, b.length))` and the `>=0.8` threshold.

**Replace the entire detail paragraph with:**
> **Stagnation Guard Detail:** Stagnation compares total error count only (sum of critical + medium + minor), not per-severity breakdowns. Issue rotation is detected when a significant proportion of current-iteration issues do not match any issue in the prior iteration — i.e., the reviewer is flagging new cosmetic issues each cycle rather than persisting the same findings. Match definition and thresholds are specified in the build spec. When both conditions are true, the deliverable has reached a quality plateau. This is treated as a successful convergence outcome.

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
