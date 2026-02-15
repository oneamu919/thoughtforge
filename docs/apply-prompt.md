# Apply Review Findings from results.md

You are an AI coder. Apply every change listed below to the source files. Each change is taken directly from the review findings in `docs/results.md`. Do not interpret or improvise — apply the replacements, additions, and extractions exactly as specified.

Read all target files before editing. After all changes are applied, git commit and sync to remote.

---

## Target Files

- `docs/thoughtforge-design-specification.md` (referred to as "Design Spec")
- `docs/thoughtforge-build-spec.md` (referred to as "Build Spec")
- `docs/thoughtforge-execution-plan.md` (referred to as "Execution Plan")

Read all three files before making any edits.

---

## Changes to Design Spec (`docs/thoughtforge-design-specification.md`)

### Change 1 — Phase 1 step 9: "realign from here" trigger mechanism (Minor)

**Find** the existing text describing the "realign from here" behavior in Phase 1, step 9.

**Replace with:**

> Human can type "realign from here" in chat. Unlike phase advancement actions (which use buttons to prevent misinterpretation), "realign from here" is a chat-parsed command because it does not advance the pipeline — it re-processes within the current phase. The AI rolls back to the most recent substantive correction and re-distills from the original brain dump plus all corrections up to that point. If no corrections exist yet, the command is ignored with a prompt to provide a correction first. Implementation algorithm in build spec.

---

### Change 2 — Phase 2 step 3: AI resolves Unknowns escalation criteria (Minor)

**Find** the existing Phase 2 step 3 text about AI resolving Unknowns and Open Questions (the text that references `spec-building.md` governing when the AI should decide autonomously vs. escalate).

**Replace with:**

> AI resolves Unknowns and Open Questions from `intent.md` — either by making a reasoned decision (stated in `spec.md`) or by asking the human during the Phase 2 chat. The governing principle: the AI decides autonomously when the decision is low-risk, reversible, or has a clearly dominant option based on the constraints — and escalates to the human when the decision is high-impact, preference-dependent, or has multiple viable options with material trade-offs. The Phase 2 prompt (`spec-building.md`) operationalizes this principle. No unresolved unknowns may carry into `spec.md`.

---

### Change 3 — Phase 3 Code Mode: test-fix cycle iteration limit (Minor)

**Find** the existing code builder paragraph in Phase 3 that describes the test-fix cycle (the one mentioning "test-fix cycle: run tests, pass failures back to the agent, agent fixes, re-run tests").

**Append** the following text to the end of that paragraph:

> The Phase 3 test-fix cycle does not have its own iteration cap — it terminates only via stuck detection (3 consecutive identical test failures or 2 consecutive non-zero exits on the same task). Since each cycle produces different failing tests, the stuck detector will not trigger on rotating failures. In practice, the code builder's test-fix cycle is bounded by the agent timeout and the human's ability to terminate via the Phase 3 stuck recovery buttons. A hard cap on Phase 3 test-fix cycles is deferred — not a current build dependency.

---

### Change 4 — Stagnation guard: "same total error count" clarification (Minor)

**Find** the existing stagnation guard text that says "Same total error count for a configured number of consecutive iterations."

**Replace with:**

> **Stagnation:** Same total error count (sum of critical + medium + minor) for a configured number of consecutive iterations (stagnation limit) AND issue rotation detected. The comparison uses total count only, not per-severity breakdown — a shift in severity composition at the same total is still treated as stagnation if the rotation threshold is also met.

---

### Change 5 — Locked File Behavior: restart recovery for spec.md and intent.md (Minor)

**Find** the existing paragraph about `spec.md` and `intent.md` being "read once at Phase 3 start and not re-read during later phases."

**Append** the following text to the end of that paragraph:

> On server restart, the in-memory copies are lost. When the human resumes a halted Phase 4 project, the orchestrator re-reads `spec.md` and `intent.md` from disk to reconstruct working context. If the human manually edited these files while the project was halted, the resumed pipeline will use the edited versions. This is an acceptable side effect of the restart recovery model.

---

### Change 6 — Phase 4: Review and Fix agent assignment (Major)

**Location:** In Phase 4, after the "Each Iteration — Two Steps" section.

**Add this new content:**

> **Agent assignment for review and fix steps:** Both the review and fix steps use the same agent assigned to the project (from `status.json` `agent` field). The review prompt instructs the agent to produce a JSON error report only — no fixes. The fix prompt instructs the agent to apply fixes from the provided issue list only — no new review. Prompt separation enforces the behavioral boundary. Using separate agents for review vs. fix is deferred — not a current build dependency.

---

### Change 7 — Phase 3 Code Mode: code builder context assembly (Major)

**Location:** In the Phase 3 Code Mode section, after step 1.

**Add this new content:**

> **Code builder context assembly:** The code builder passes the following files to the coding agent as build context: `spec.md` (architecture, decisions, dependencies), `constraints.md` (acceptance criteria, scope, priorities), and optionally the plan document from `/resources/` if one was identified by the Plan Completeness Gate. `intent.md` is not passed — its content is already distilled into `spec.md`. Resource files from `/resources/` (other than a chained plan document) are not passed to the code builder — they were consumed during Phase 1 distillation.

---

### Change 8 — Phase 4: fix agent context assembly (Major)

**Location:** In Phase 4, after the Step 2 (Fix) description.

**Add this new content:**

> **Fix agent context assembly:** The fix agent receives the JSON issue list and the relevant deliverable context. For Plan mode: the current plan document. For Code mode: the current codebase files referenced in the issue `location` fields, plus `constraints.md` for scope awareness. The fix agent does not receive the prior review JSON from previous iterations — only the current iteration's issue list. Full context assembly is specified in the fix prompts (`plan-fix.md`, `code-fix.md`).

---

### Change 9 — Phase 4 Code Mode: review context assembly (Major)

**Location:** In the Phase 4 Code Mode Iteration Cycle section.

**Add this new content:**

> **Code mode review context:** The review prompt includes `constraints.md`, test results, and a representation of the codebase. For codebases that fit within the agent's context window, the full source is included. For larger codebases, the reviewer receives a file manifest (list of all source files with sizes) plus the content of files that changed since the last iteration (identified via `git diff`). The review prompt (`code-review.md`) specifies the context assembly strategy. If the codebase exceeds the agent's context window even with diff-only strategy, the orchestrator logs a warning and proceeds with truncated context.

---

### Change 10 — Phase 4 Error Handling: fix commit failure after review committed (Minor)

**Location:** In the Phase 4 Error Handling table.

**Add this new row:**

> | Fix step git commit fails after review step committed successfully | Halt and notify human. The review commit is preserved. Un-committed fix changes remain in the working tree. On resume, the orchestrator does NOT re-run the review step — it re-attempts only the fix commit. If the commit succeeds on retry, the iteration proceeds normally. If the working tree has been manually modified by the human during the halt, the orchestrator commits whatever is present (the human is responsible for the state they left). |

---

### Change 11 — Chat history truncation: brain dump identification (Minor)

**Find** the existing truncation sentence that says "retaining the most recent messages and always retaining the original brain dump."

**Append** the following text after that sentence:

> The original brain dump messages are identified as all human messages before the first Distill button press in the chat history. During truncation, these messages are always retained at the beginning of the context, followed by the most recent messages that fit within the remaining window. Messages between the brain dump and the retained recent messages are dropped.

---

### Change 12 — Phase 1 step 11b: Extract deliverable type parsing to build spec (Minor)

**Find** the implementation-level parsing detail in Phase 1 step 11b — the sentence "The AI's distillation always states exactly one of 'Plan' or 'Code' as the first word of this section. The orchestrator string-matches that word to set the field."

**Replace with:**

> The deliverable type is derived from the confirmed intent and set in `status.json`.

Ensure the parsing algorithm (first-word string match) is present in the build spec. If it is already there, no build spec change needed. If not, add it to the relevant section of the build spec.

---

### Change 13 — Phase 1 step 9: Realign algorithm overlap (Minor)

After applying Change 1 above, verify that the design spec states only the *behavior* of realign (human can request re-distillation from a prior correction point) and defers the mechanism to the build spec. The partial algorithm description should live only in the build spec, not in both documents. Change 1's text includes "Implementation algorithm in build spec" — confirm this is the only reference to the algorithm in the design spec. If any duplicate algorithmic detail remains elsewhere in the design spec, remove it.

---

### Change 14 — Button Debounce: Extract implementation details to build spec (Minor)

**Find** the detailed button debounce paragraph that says: "Once an action button is pressed, it is immediately disabled in the UI and remains disabled until the triggered operation completes or fails. A second click on a disabled button has no effect. If the server receives a duplicate action request for a button that has already been processed (e.g., due to a race condition between client and server), the server ignores the duplicate and returns the current project state."

**Replace with:**

> Buttons prevent duplicate actions. Once pressed, a button cannot trigger a second action until the first completes or fails. Server-side deduplication handles race conditions.

Move the full implementation details (client-side disable timing, server-side dedup handling, race condition resolution) to the build spec if not already present there.

---

## Changes to Execution Plan (`docs/thoughtforge-execution-plan.md`)

### Change 15 — Critical Path: secondary chain correction (Minor)

**Find** the existing secondary critical chain text in the Critical Path section.

**Replace with:**

> **Secondary critical chain (Code mode):** Task 1 → Task 41 → Task 42 (parallel with Task 26 → Task 27) → Task 6a → Task 21 → Task 30c → Task 52. The agent layer (41–42) and VK adapter (26–27) are parallel branches that both feed into Task 21.

---

### Change 16 — Task Acceptance Criteria: "To be drafted" prompt handling (Minor)

**Find** the Task Acceptance Criteria section.

**Add** the following as a new numbered item:

> 5. For tasks that depend on a "To be drafted" prompt (identified in the build spec by "Used by" references): the AI coder drafts the prompt text as the first step of the task, writes it to the `/prompts/` directory, and the human reviews and edits via the Settings UI before the task proceeds to implementation. The prompt text is committed alongside the task's implementation code.

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
