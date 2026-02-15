Now I have all four documents. Let me produce the review.

---

# Plan Review — Senior Dev Findings

Reviewing: `thoughtforge-design-specification.md`, `thoughtforge-build-spec.md`, `thoughtforge-execution-plan.md`

Reference context: `thoughtforge-requirements-brief.md`

---

## 1. Writing That's Unclear

**[Minor]** Design spec, Phase 1, step 11a — "locked" definition forward reference.

The sentence at line 98 says:
> "Locked" means the AI pipeline will not modify the file after its creation phase. See Locked File Behavior (Phase 2 section) for the full definition, including human edit consequences.

This forward reference appears inside Phase 1 but points to a subsection under Phase 2, creating a navigation burden. The concept is used before it is defined.

**Replacement:** Move the full "Locked File Behavior" block (currently under Phase 2, lines 171–193) to a standalone section under "Behavior" before Phase 1, titled "Locked File Behavior." Replace both inline references (Phase 1 line 98 and Phase 2 line 169) with: `"Locked" means the AI pipeline will not modify these files after their creation phase — see Locked File Behavior above.`

---

**[Minor]** Design spec, Phase 3, Code Mode — "test-fix cycle" vs "build iteration" ambiguity.

Lines 265–273 describe the "test-fix cycle" inside Phase 3, but line 263 refers to "a single invocation or multi-turn session, depending on how Vibe Kanban executes." It's unclear whether the test-fix cycle is part of the "single invocation" or a separate phase of Phase 3 that starts after the initial build invocation completes.

**Replacement** (line 263):
> The agent is responsible for scaffolding, implementation, and initial test writing. This initial build is either a single agent invocation (VK disabled) or a multi-turn VK-managed session (VK enabled). After the initial build invocation completes, the code builder enters the test-fix cycle described below.

---

**[Minor]** Design spec, Stagnation Guard — "done (success)" treatment could confuse implementers.

The stagnation guard description (line 388 and line 396) calls it a "successful convergence outcome" and "Done (success)," but the notification example on line 588 says `"polish sufficient"`. The word "sufficient" is not used anywhere in the design spec's convergence guard definitions.

**Replacement** for line 588:
> `"Project 'CLI Tool' — stagnation convergence. Error count stable at {N} for {M} iterations with issue rotation. Treated as converged. Ready for final review."`

---

**[Minor]** Execution plan, Task 12 dependency on Task 25.

The cross-stage dependency note above Build Stage 2 (execution plan line 56) says Task 12 depends on Task 25 for Code mode only, but the Task 12 row (line 77) lists Task 25 as a hard dependency. An implementer working on Plan mode Phase 2 would see the dependency and wait unnecessarily.

**Replacement** for Task 12's Depends On column:
> `Task 6a, Task 10, Task 11, Task 7a, Task 7f, Tasks 41–42; Task 25 (Code mode only — Plan mode can proceed without it)`

---

**[Minor]** Build spec, `constraints.md` Truncation Strategy — "available context budget" undefined.

Line 926 says "exceeds the available context budget when combined with other review context" but does not define what the budget is or how it is calculated relative to the agent's `context_window_tokens`.

**Replacement:**
> If `constraints.md` combined with other review context (deliverable content, test results, and the review prompt) exceeds the agent's `context_window_tokens` as estimated by `character_count / 4`, `constraints.md` is truncated from the middle — the Context and Deliverable Type sections (top) and the Acceptance Criteria section (bottom) are preserved, and middle sections (Priorities, Exclusions, Severity Definitions, Scope) are removed in reverse order until the total fits. A warning is logged identifying which sections were removed.

---

**[Minor]** Design spec, Phase 4 — Fix Regression guard wording.

Line 386 says: "Compares the post-fix total error count against the pre-fix review count for the same iteration." This is confusing because "pre-fix review count" could mean "the count from the review step that triggered the fix" or "the count from the prior iteration's review." The build spec (line 285) clarifies it means the same iteration, but the design spec should stand on its own.

**Replacement** for the Fix Regression table entry:
> Evaluated immediately after each fix step, before other guards. Compares the total error count derived from the current iteration's review JSON (before the fix was applied) against the total error count derived from a fresh review after the fix. **Single occurrence:** If the fix increased the total error count compared to its own iteration's pre-fix review, log a warning but continue.

Wait — re-reading, the guard compares the post-fix count to the *same iteration's review count*. But there's no "fresh review after the fix." The fix step doesn't produce a new review. The *next* iteration's review would show the post-fix state. This is actually unclear: how does the orchestrator know the post-fix error count without running another review?

**Revised replacement** — the intent is actually comparing *across* iterations (iteration N review count vs iteration N-1 review count). Re-reading line 285-286 of the build spec: "Compares the post-fix total error count against the pre-fix review count for the same iteration." But the fix step doesn't produce error counts — only the review step does. The fix step produces code changes, not a new error report. The only way to get a post-fix count is from the *next* iteration's review.

Actually, re-reading more carefully: the Fix Regression guard says "If the fix increased the total error count." The mechanism must be: compare iteration N's review count to iteration N-1's review count. If N > N-1, the fix from iteration N-1 introduced more issues.

**Replacement** for design spec line 386, Fix Regression:
> **Fix Regression (per-iteration):** Evaluated at the start of each iteration (after the review step produces error counts), comparing the current iteration's total error count against the previous iteration's total error count. If the current count is higher than the previous, the most recent fix step made things worse. **Single occurrence:** Log a warning but continue. **Consecutive occurrences:** If the two most recent iterations both show increased total error counts compared to their respective prior iterations, halt and notify.

And build spec line 285-286 should be updated to match:
> **Fix Regression** (per-iteration) — checked after each review step produces error counts. Compares current iteration's total error count to the prior iteration's total error count. If the current count is higher, the prior iteration's fix step introduced more issues than it resolved. If 2 consecutive iterations show increases, halt and notify.

---

**[Minor]** Design spec, Phase 1 — "Distill" and "Confirm" buttons introduced across multiple paragraphs.

The Phase 1 button model is described three times: once in the "Interaction model" paragraph (line 71), once in the "Phase 1 has two action buttons" block (lines 78-81), and once in the "Confirmation model" paragraph (line 112). All three say roughly the same thing.

**Replacement:** Remove the "Phase 1 has two action buttons" block (lines 78-81) entirely. The interaction model paragraph (line 71) and the confirmation model paragraph (line 112) already cover the same content. The numbered steps (4 and 10) reference the buttons in context.

---

## 2. Genuinely Missing Plan-Level Content

**[Critical]** Design spec — No definition of how the fix agent gets post-fix error counts for the Fix Regression guard.

The Fix Regression guard (design spec line 386, build spec line 285) says it compares "post-fix total error count against the pre-fix review count for the same iteration." But within a single iteration, the sequence is Review → Fix. After the fix step, there is no second review to produce a post-fix count. The guard cannot function as described.

**Proposed content** (add to Phase 4 Convergence Guards section, before the guard table):

> **Fix Regression evaluation mechanism:** The Fix Regression guard does not run a second review within the same iteration. Instead, it compares consecutive iterations: iteration N's review reveals the error state after iteration N-1's fix. If iteration N's total error count exceeds iteration N-1's total error count, the prior fix introduced more issues than it resolved. "Two consecutive regressions" means iterations N and N+1 both show higher counts than their respective predecessors (N-1 and N).

---

**[Major]** Execution plan — No task for Phase 3 Code mode test-fix cycle stuck detection.

The design spec (lines 267-271) defines two stuck conditions for the Code mode test-fix cycle: (1) same build task fails after 2 consecutive retries, (2) identical test failures for 3 consecutive cycles. The execution plan has Task 21 (code builder) but no explicit task or acceptance criterion covering the stuck detection logic within the test-fix cycle.

**Proposed content** (add after Task 21 in Build Stage 4):

> | 21b | Implement Code mode Phase 3 test-fix cycle: run tests → pass failures to agent → fix → retest loop. Including stuck detection: halt after 2 consecutive non-zero exits on same task, or 3 consecutive identical failing test sets (exact string match on test names). | — | Task 21, Task 24 | — | Not Started |

---

**[Major]** Design spec — No specification of what happens when `polish_state.json` is missing at Phase 4 *start* (not resume).

The design spec covers `polish_state.json` unreadable at Phase 4 *resume* (line 430) but not the case where Phase 4 starts fresh and the file doesn't exist yet. The orchestrator presumably creates it after the first iteration, but the initial state isn't specified.

**Proposed content** (add to Phase 4 Loop State Persistence, after line 402):

> **Initial state:** When Phase 4 begins (Phase 3→4 transition), `polish_state.json` does not exist yet. The orchestrator initializes it after the first iteration completes. Before the first iteration, the orchestrator operates with `iteration: 0` and empty `convergence_trajectory`. If the pipeline halts or crashes during the first iteration (before `polish_state.json` is written), the orchestrator creates the file with the initial state on resume and re-attempts the first iteration.

---

**[Major]** Execution plan — No task for implementing the Phase 2 conversation sequencing and Unknown resolution validation gate.

The design spec (lines 159-166) describes specific Phase 2 behavior: the AI presents all elements in a single structured message, the Unknown resolution gate blocks Confirm if items remain unresolved, and the Acceptance Criteria validation gate blocks Confirm if criteria are empty. Task 12 mentions "Unknown resolution validation gate" in its description but there's no specific acceptance criterion covering the gate behavior (blocking Confirm, re-presenting unresolved items). This is a critical Phase 2 mechanism that controls data quality entering Phase 3.

**Proposed content** (add to Task 12 description):

> Including: Unknown resolution validation gate (block Confirm if unresolved Unknowns or Open Questions remain, present remaining items to human), Acceptance Criteria validation gate (block Confirm if Acceptance Criteria section is empty or missing, re-invoke AI once if section heading absent, halt on second failure).

---

**[Minor]** Design spec — No specification of what the chat interface shows during Phase 3 and Phase 4 autonomous execution.

Line 325 says "The human can view the project's chat history and current status" during autonomous phases, but doesn't specify what status information is displayed. The human needs to know iteration progress during the polish loop.

**Proposed content** (add after line 325):

> During Phase 4, the chat panel displays a live status summary updated after each iteration: current iteration number, error counts (critical/medium/minor/total), convergence trajectory direction (improving/stable/worsening), and the most recent guard evaluation result. During Phase 3, the chat panel displays the current build step (e.g., "Building section 3 of 7" for Plan mode, or "Test-fix cycle, iteration 2" for Code mode). These are read from `polish_state.json` (Phase 4) and builder progress (Phase 3) respectively.

---

**[Minor]** Design spec — No specification of the code builder's task decomposition strategy.

The build spec mentions a `task_queue.json` (line 207) for the code builder, but the design spec doesn't describe how the code builder decomposes `spec.md` into individual build tasks. The plan builder has explicit section-by-section decomposition; the code builder's strategy is unspecified.

**Proposed content** (add to Phase 3 Code Mode, after line 263):

> **Code builder task decomposition:** The code builder derives an ordered task list from `spec.md`'s Deliverable Structure section. Each major architectural component or feature becomes a build task. The task list is persisted to `task_queue.json` at derivation time for crash recovery (see build spec Code Builder Task Queue). The coding agent receives the full `spec.md` as context for each task but is instructed to focus on the current task. Task granularity is determined by the code builder, not prescribed — it depends on the architecture complexity described in `spec.md`.

---

**[Minor]** Execution plan — No task for implementing the chat UI's Phase 3/4 live status display.

The design spec describes what the human sees during autonomous phases, but no execution plan task covers building this UI component.

**Proposed content** (add to Build Stage 6, after Task 40a):

> | 40b | Implement Phase 3/4 live status display in chat panel: Phase 4 shows iteration number, error counts, trajectory direction, guard result after each iteration; Phase 3 shows current build step. Read from `polish_state.json` and builder progress. Update via WebSocket push after each iteration/step completes. | — | Task 7, Task 30, Task 38 | — | Not Started |

---

## 3. Build Spec Material That Should Be Extracted

**[Minor]** Design spec, Phase 1 — "Step 3 Detail — Connector URL Identification" (line 76).

> ThoughtForge matches URLs in chat messages against known URL patterns for each enabled connector and pulls content automatically. URL matching rules (enabled/disabled/unmatched behavior) are in the build spec.

This sentence is correctly placed as design-level intent. However, the surrounding detail about "URL patterns for each enabled connector" and the reference to matching rules is already fully specified in the build spec's URL Matching Behavior table (build spec lines 477-483). No action needed — this is properly split. Noting for completeness only.

*No extraction needed — correctly delegated.*

---

**[Minor]** Design spec, Phase 4 — Fix agent context assembly detail (lines 355-356).

The paragraph starting "The fix agent receives the JSON issue list..." contains implementation-level file parsing details:

> "parsed as relative paths from project root; line numbers are stripped before file lookup"

This is implementation detail (how to parse `location` fields) that belongs in the build spec's fix prompt section, not the design spec.

**Proposed extraction:** Move the sentence fragment `"parsed as relative paths from project root; line numbers are stripped before file lookup"` to the build spec under a new "Fix Agent Context Assembly" section. Replace in the design spec with: `"The fix agent receives the issue list and the content of files referenced in each issue's location field."` The parsing rules are an implementation detail for the build spec.

---

**[Minor]** Design spec, Phase 3, Plan Mode — Template Content Escaping (line 246).

The design spec says:

> AI-generated content must not break template rendering.

The build spec (line 406-408) already has a dedicated section: "Plan Builder — Template Content Escaping." The design spec line is a design intent statement (appropriate), but the mention in the design spec is the only reference — the build spec section is not cross-referenced.

**Proposed fix:** Add to design spec line 246: `"Template content escaping strategy is defined in the build spec."` This aligns with the document's pattern of referencing the build spec for implementation details.

---

**[Minor]** Design spec, Notification Content — Example messages (lines 586-594).

The 9 notification example strings are concrete message templates. They serve as specification for the notification `summary` field format. This is borderline — the design spec uses them to communicate intent, but an implementer would treat them as exact format requirements. They belong in the build spec alongside the `NotificationPayload` schema.

**Proposed extraction:** Move the notification examples to the build spec, immediately after the `NotificationPayload` schema (build spec line 1050). In the design spec, keep 2-3 examples to communicate intent and add: `"Full notification message templates are in the build spec."` This reduces design spec bulk while preserving intent communication.

---

That concludes the review. Three lists, all findings tagged by severity, sorted within each list.
