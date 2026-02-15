Now I have all four documents. Let me proceed with the review. The requirements brief gives me context; the other three are the scrutiny targets.

---

# Plan Review — ThoughtForge Pipeline Tool

**Documents reviewed:** Design Specification, Build Spec, Execution Plan
**Context document:** Requirements Brief

---

## 1. Writing That's Unclear

**[Minor] Design Spec — Phase 4 Stagnation Guard: "Issue rotation" phrasing is inverted**

The design spec line 388 says: *"(2) Issue rotation: Fewer than 70% of current-iteration issues match any issue in the immediately prior iteration"*

The term "issue rotation" suggests issues are rotating (new ones replacing old ones), but "fewer than 70% match" means "more than 30% are new." The description is correct but the label is confusing — "rotation" and the matching threshold work in opposite directions without bridging language.

**Replacement text:**
> (2) **Issue rotation:** More than 30% of current-iteration issues are new — i.e., fewer than 70% of current-iteration issues match any issue in the immediately prior iteration (match = Levenshtein similarity >= 0.8 on `description`). When both conditions are true, the reviewer is cycling cosmetic issues rather than finding genuine regressions.

---

**[Minor] Design Spec — Fix Regression guard: "Evaluation timing note" contradicts Guard Evaluation Order**

Design spec line 392 says: *"Fix Regression is evaluated immediately after each fix step (before other guards)."* But the build spec Guard Evaluation Order (line 283-285) says Fix Regression is *"checked after each review step produces error counts"* — not after the fix step. These describe different timing.

The build spec version is correct (the review step reveals whether the *previous* fix regressed), but the design spec says "after each fix step."

**Replacement text (design spec line 392):**
> **Evaluation timing note:** Fix Regression is evaluated after each review step produces error counts (the review reveals the error state *after* the prior iteration's fix). It is checked before the other convergence guards. All other guards are evaluated after the full iteration cycle (review + fix) completes. See build spec Guard Evaluation Order for the complete sequence.

---

**[Minor] Design Spec — "Two consecutive regressions" definition is ambiguous**

Design spec line 381 says: *"Two consecutive regressions means iterations N and N+1 both show higher counts than their respective predecessors (N-1 and N)."*

This is correct but the table entry at line 386 says *"If the two most recent iterations both show increased total error counts compared to their respective prior iterations."* The subtle issue: "compared to their respective prior iterations" could be read as "compared to the iteration before them" or "compared to some other baseline." The parenthetical at 381 clarifies, but the table entry itself is ambiguous.

**Replacement text for the table entry (line 386):**
> If the current iteration and the immediately preceding iteration both show a total error count higher than the iteration before each of them (i.e., iteration N > iteration N-1 AND iteration N-1 > iteration N-2), halt and notify.

---

**[Minor] Design Spec — "Halted" projects and terminal state language is inconsistent**

Line 602 says halted projects count toward the active project limit *"until the human either resumes them (returning to active pipeline state) or terminates them (setting them to terminal state)."* But line 634 says terminated projects use the same `halted` state: *"Terminated projects (`halt_reason: 'human_terminated'`) are functionally finished but use the same `halted` state."*

So "terminates them (setting them to terminal state)" is misleading — `halted` is not a terminal state. `done` is the only terminal state. A terminated project stays `halted` and continues counting toward the limit. The only way to free the slot is for the operator to delete the project directory.

**Replacement text (line 602):**
> Halted projects and concurrency: Projects with `halted` status count toward the active project limit. This includes both recoverable halts and human-terminated projects (which also use the `halted` state). The only way to free a concurrency slot is for the project to reach `done` status or for the operator to manually delete the project directory. This prevents the operator from creating unlimited projects while ignoring halted ones.

---

**[Minor] Execution Plan — Critical path listing omits agent layer tasks that actually gate it**

Line 199 lists the critical path as: *"Task 1 → Task 41 → Task 42 → Task 6a → Task 8..."* but Task 6a depends on Task 2 (project init), Task 3 (state module), and Task 6 (plugin loader) — none of which appear in the chain. These are parallel with 41-42 but still required before 6a can start.

**Replacement text:**
> **Task 1 → [Task 41 → Task 42 | Task 2 → Task 3 | Task 6] → Task 6a → Task 8 → Task 9 → Task 11 → Task 12 → Task 13 → Task 15 → Task 6c → Task 30 → Tasks 33–37 → Task 51**
>
> Tasks in brackets are parallel branches that must all complete before Task 6a can begin. The longest of these branches (41 → 42) determines the critical path duration.

---

**[Minor] Build Spec — `constraints.md` truncation says "middle sections removed in reverse order" but doesn't specify reverse of what**

Line 934 says: *"middle sections (Priorities, Exclusions, Severity Definitions, Scope) are removed in reverse order until the total fits."*

Reverse of what — the order listed? Alphabetical? Document order? The listed order appears to be document order, but "reverse order" applied to that list means Scope is removed first, then Severity Definitions, etc.

**Replacement text:**
> middle sections are removed one at a time starting from the bottom of the document (Scope first, then Severity Definitions, then Exclusions, then Priorities) until the total fits.

---

**[Minor] Design Spec — "constraints.md — unvalidated after creation" paragraph is hard to parse**

Line 67-68: The sentence *"If the human restructures the file (missing sections, reordered content, added sections), ThoughtForge passes it to the AI reviewer as-is without schema validation"* is followed by *"If the human empties the Acceptance Criteria section, the reviewer proceeds with whatever criteria remain (which may be none)."*

The parenthetical "(which may be none)" is redundant with "empties" and makes the reader re-read to confirm. The real point — that the pipeline will not enforce criteria presence post-creation — gets buried.

**Replacement text:**
> **`constraints.md` — unvalidated after creation:** After initial creation, ThoughtForge does not validate `constraints.md` against any schema. If the human restructures the file, removes sections, or empties content, ThoughtForge passes the file to the AI reviewer as-is. This includes emptying the Acceptance Criteria section — the reviewer proceeds with zero criteria. This is treated as an intentional human override.

---

## 2. Genuinely Missing Plan-Level Content

**[Major] No error budget or quality gate for AI-drafted prompts**

The execution plan's "Prompt Validation Strategy" (lines 242-244) says prompts are validated only via e2e tests. If an e2e test fails due to poor AI output quality, the prompt is revised. But there is no definition of what "acceptable deliverable" means in e2e test terms. The plan has convergence thresholds for the polish loop but no acceptance criteria for the prompts themselves.

This matters because multiple build tasks depend on prompts that don't exist yet ("To be drafted"), and the execution plan treats prompt iteration as expected during Stage 8. Without criteria for when a prompt is "good enough," this iteration could become unbounded.

**Proposed content to add (Execution Plan, after "Prompt Validation Strategy" section):**

> ### Prompt Acceptance Criteria
>
> Each pipeline prompt is considered accepted when:
> 1. The e2e test using the prompt produces a deliverable that reaches Phase 4 convergence (termination or stagnation success) within the configured `max_iterations` (default 50).
> 2. The AI's structured outputs (review JSON, `PlanBuilderResponse`) pass Zod validation on the first attempt at least 80% of iterations (prompt is producing schema-compliant output reliably).
> 3. No more than 3 prompt revision cycles are needed per prompt. If a prompt requires more than 3 revisions to pass e2e, the prompt's behavioral requirements (from the design spec) should be re-examined for feasibility before further iteration.

---

**[Major] No handling defined for `task_queue.json` corruption or absence during Code mode Phase 3 crash recovery**

The build spec (line 206-207) says the code builder persists `task_queue.json` for crash recovery and re-reads it on resume. But neither the design spec nor build spec defines what happens if `task_queue.json` is unreadable, missing, or invalid on crash recovery — unlike `status.json`, `polish_state.json`, and `chat_history.json`, which all have explicit corruption handling (halt and notify).

**Proposed content to add (Design Spec, Phase 3 Error Handling table):**

> | `task_queue.json` unreadable, missing, or invalid at Phase 3 resume | Halt and notify the operator with the file path and the specific error (parse failure, missing file, invalid schema). Same behavior as `status.json` and `chat_history.json` corruption handling. Do not attempt recovery or re-derivation from `spec.md` — the operator must fix or recreate the file. |

---

**[Major] No logging or audit trail for safety-rules.js enforcement actions**

The design spec (line 463-465) defines the safety enforcement mechanism — every Phase 3/4 action is classified and validated against `safety-rules.js`. But there is no mention of logging blocked operations. If a blocked operation is attempted (especially in Plan mode), this should be logged for debugging. The operational logging module (Task 3a) logs agent calls, phase transitions, guard evaluations, errors, and halts — but not safety rule enforcement.

**Proposed content to add (Design Spec, Plan Mode Safety Guardrails section, after "Enforcement" paragraph):**

> **Safety enforcement logging:** Every `validate()` call is logged to `thoughtforge.log` with the operation type, the result (`allowed`/`blocked`), and the reason if blocked. Blocked operations are logged at `warn` level. This provides an audit trail for debugging unexpected pipeline behavior and verifying that Plan mode safety rules are enforced correctly.

**Corresponding addition to build spec Operation Type Taxonomy section:**

> The orchestrator logs every `validate()` call to the operational log: operation type, plugin type, and result. Blocked operations include the reason from the `validate()` return value.

---

**[Minor] No defined behavior for what happens when the operator manually deletes `polish_state.json` during an active Phase 4 run**

The design spec covers `polish_state.json` being unreadable/missing at Phase 4 *resume* (line 432), but not during an *active* run. If the file is deleted between iterations while the loop is running, the next iteration's write would recreate it, but the convergence guards that depend on trajectory history would have incomplete data.

**Proposed content to add (Design Spec, Phase 4 Error Handling table):**

> | `polish_state.json` missing during active Phase 4 iteration (deleted externally between iterations) | The orchestrator writes `polish_state.json` at each iteration boundary. If the file is missing when the orchestrator attempts to read convergence trajectory for guard evaluation, halt and notify the operator: "polish_state.json missing during active polish loop. File may have been deleted externally." Same behavior as Phase 4 resume corruption handling. |

---

**[Minor] No specification for how the Levenshtein similarity library/implementation is sourced**

The stagnation guard depends on Levenshtein similarity computation. The plan specifies the formula (build spec lines 305) but doesn't identify whether this is a dependency to install (e.g., an npm package) or implemented inline. The Initial Dependencies section doesn't include a Levenshtein package.

**Proposed content to add (Build Spec, Initial Dependencies section — as a note):**

> **Stagnation guard dependency:** Levenshtein distance computation for the stagnation guard's issue rotation detection. Either install a lightweight npm package (e.g., `fastest-levenshtein`, MIT, ~500 weekly downloads) or implement inline — the algorithm is ~15 lines.

---

**[Minor] No specification for the `phase` field value in `ChatMessage` during Phase 1 sub-states**

The `chat_history.json` schema (build spec line 692) includes `phase` values that mirror `status.json` phases. But Phase 1 has three sub-states (`brain_dump`, `distilling`, `human_review`). It's unclear whether chat messages during Phase 1 use the specific sub-state or a generic Phase 1 value. The schema includes all three sub-states in the enum, suggesting sub-states — but this is implicit, not explicit.

**Proposed content to add (Build Spec, `chat_history.json` Schema, after the interface definition):**

> The `phase` field records the `status.json` phase value at the time the message was sent. During Phase 1, this means messages will carry `brain_dump`, `distilling`, or `human_review` as appropriate — these are the actual `status.json` values, not a collapsed "phase_1" label.

---

## 3. Build Spec Material That Should Be Extracted

**[Minor] Design Spec — Project Initialization Sequence detail (lines 87-93)**

The design spec says: *"Project initialization creates the project directory structure, initializes version control, writes the initial project state, optionally registers on the Kanban board, and opens the chat interface. The full initialization sequence — including collision retry, field assignments, and error handling — is in the build spec."*

This is properly delegated. However, two sentences later: *"The project ID is used as the directory name and as `project_id` in notifications — not stored in `status.json` since it is always derivable from the project directory path."*

The decision that project ID is not stored in `status.json` is a design decision and belongs here. But the reasoning about derivability from the directory path is an implementation detail — the build spec already covers the `status.json` schema which excludes `project_id`. This sentence is fine as-is (borderline), but flagging for awareness.

**Verdict:** No extraction needed — the reasoning is brief enough to stay.

---

**[Minor] Design Spec — WebSocket reconnection parameters (line 623)**

The design spec says: *"Detailed reconnection behavior is in the build spec."* This is correctly delegated. No extraction needed.

---

**[Minor] Design Spec — HTTP API route table embedded in build spec is appropriate**

The build spec's HTTP API Surface (lines 599-616) is correctly placed as implementation reference. The design spec does not duplicate this. No issue.

---

**[Major] Design Spec — Plan mode fix output validation contains implementation thresholds (lines 358-359)**

The design spec states: *"the orchestrator validates that the returned content is non-empty and does not have fewer characters than 50% of the pre-fix plan document"* and *"If 2 consecutive iterations produce rejected fix output, the pipeline halts."*

The 50% threshold and the 2-consecutive-rejections limit are implementation-level tuning parameters. The *behavior* (validate fix output, reject bad output, preserve pre-fix state, halt on repeated failure) belongs in the design spec. The specific numeric thresholds belong in the build spec (and ideally in `config.yaml`).

**Recommendation:** Keep the behavioral description in the design spec. Move the numeric parameters to the build spec:

**Design spec replacement:**
> After the fix agent returns the updated plan document, the orchestrator validates that the returned content is non-empty and does not represent a significant reduction from the pre-fix document. If the check fails, the fix is rejected: the pre-fix plan document is preserved, a warning is logged, and the iteration proceeds using the pre-fix state. If consecutive iterations produce rejected fix output (exceeding the threshold defined in the build spec), the pipeline halts and notifies the human.

**Build spec addition (new section "Plan Mode Fix Output Validation Parameters"):**
> - **Minimum size ratio:** Fix output must be at least 50% of the pre-fix document's character count.
> - **Consecutive rejection limit:** 2 consecutive rejected fix outputs trigger a halt.

---

**[Minor] Design Spec — Stagnation guard Levenshtein similarity formula (lines 396)**

The formula `1 - (levenshtein_distance(a, b) / max(a.length, b.length))` and the `>=0.8` threshold are specified in both the design spec (line 388, 396) and the build spec (lines 303-305). The design spec should describe the *intent* (issues are considered matching when their descriptions are substantially similar). The formula and exact threshold are build spec material.

The build spec already contains this, so the duplication is the issue — not a missing extraction. The design spec's Stagnation Guard Detail paragraph could be simplified.

**Design spec replacement for the detail paragraph:**
> **Stagnation Guard Detail:** Stagnation compares total error count only (sum of critical + medium + minor), not per-severity breakdowns. Issue rotation is detected when a significant proportion of current-iteration issues do not match any issue in the prior iteration — i.e., the reviewer is flagging new cosmetic issues each cycle rather than persisting the same findings. Match definition and thresholds are specified in the build spec. When both conditions are true, the deliverable has reached a quality plateau. This is treated as a successful convergence outcome.

---

That concludes the review. Three lists, findings sorted by severity within each, each with specific proposed text.
