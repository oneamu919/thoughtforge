# Apply Review Findings from results.md

You are an AI coder. Apply every change listed below to the source files. Each change is taken directly from the review in `docs/results.md`. Do not interpret or improvise — apply exactly what is specified.

Read all three source files before making any changes:
- `docs/thoughtforge-design-specification.md`
- `docs/thoughtforge-build-spec.md`
- `docs/thoughtforge-execution-plan.md`

---

## Section 1: Writing That's Unclear

### 1A. Design spec — Phase 1 step 9, duplicate "realign from here" paragraph [Minor]

**File:** `docs/thoughtforge-design-specification.md`
**Location:** Phase 1 step 9
**Action:** Delete the second paragraph that begins with "The human types 'realign from here' in chat to trigger a re-distillation..." entirely. Keep the first paragraph that begins with "Human can type 'realign from here'". The clause about "messages containing the phrase alongside other text" is already covered in the build spec's exact-match rule and should not appear in the design spec.

---

### 1B. Design spec — Phase 1 step 3, duplicate connector URL identification text [Minor]

**File:** `docs/thoughtforge-design-specification.md`
**Location:** Phase 1 step 3, the "Step 3 Detail — Connector URL Identification" sub-section
**Action:** Replace the entire sub-section content with this single block:

> **Step 3 Detail — Connector URL Identification:** The AI matches URLs in chat messages against known URL patterns for each enabled connector and pulls content automatically. URL matching rules (enabled/disabled/unmatched behavior) are in the build spec.

---

### 1C. Design spec — Phase 1 step 0, misplaced "Project Name Derivation" paragraph [Minor]

**File:** `docs/thoughtforge-design-specification.md`
**Location:** Phase 1 step 0
**Action:** Move the "Project Name Derivation" paragraph from Phase 1 step 0 to after Phase 1 step 11b (where deliverable type is derived). In its original location in step 0, add a forward-reference: "Project name is derived later during Phase 1 — see step 11."

---

### 1D. Design spec — Locked File Behavior, wall of text for spec.md/intent.md [Minor]

**File:** `docs/thoughtforge-design-specification.md`
**Location:** Locked File Behavior section, the bullet point covering `spec.md` and `intent.md`
**Action:** Replace the single bullet with these sub-bullets:

> - **`spec.md` and `intent.md` (static after creation):**
>   - Read once at Phase 3 start. Not re-read during later phases.
>   - Manual human edits during active pipeline execution have no effect — the pipeline works from its in-memory copy.
>   - On server restart, in-memory copies are discarded. When a halted Phase 4 project is resumed, the orchestrator re-reads both files from disk. If the human edited them while the project was halted, the resumed pipeline uses the edited versions.
>   - There is no "restart from Phase N" capability in v1. The pipeline does not detect or warn about manual edits to any locked file.

---

### 1E. Design spec — Convergence Guards table, Stagnation guard cell [Minor]

**File:** `docs/thoughtforge-design-specification.md`
**Location:** Convergence Guards table, the Stagnation guard's "Condition" cell
**Action:** Simplify the table cell to:

> Same total error count for a configured number of consecutive iterations (stagnation limit), AND issue rotation detected (old issues resolved, new issues introduced at the same rate). When both conditions are true, the deliverable has reached a quality plateau. Severity composition shifts at the same total still qualify as stagnation if rotation threshold is also met. Parameters in build spec.

Move the detailed explanation currently in that cell (rotation threshold, similarity measure, "the reviewer is cycling through cosmetic issues") to a new subsection below the Convergence Guards table.

---

### 1F. Design spec — Convergence Guards table, Fabrication guard inline arithmetic [Minor]

**File:** `docs/thoughtforge-design-specification.md`
**Location:** Convergence Guards table, the Fabrication guard's "Condition" cell
**Action:** Replace the cell content with:

> A severity category spikes significantly above its trailing average (window size defined in build spec), AND in at least one prior iteration, every severity category was at or below twice its convergence threshold (i.e., critical ≤ 2 × `critical_max`, medium ≤ 2 × `medium_max`, minor ≤ 2 × `minor_max`). These multipliers are derived from `config.yaml` at runtime, not hardcoded. This ensures fabrication is only flagged after the deliverable was near-converged. Parameters in build spec.

Remove the parenthetical "(using default config: ≤0 critical, ≤6 medium, ≤10 minor)" from the cell.

---

### 1G. Build spec — Code Builder Task Queue, determinism claim [Minor]

**File:** `docs/thoughtforge-build-spec.md`
**Location:** Code Builder Task Queue section
**Action:** Find "must produce a deterministic task list from the same `spec.md` input" and replace with:

> should produce a consistent task list from the same `spec.md` input — the ordering logic must be stable so that crash recovery (re-deriving the task list after restart) produces a compatible ordering. If determinism cannot be guaranteed, the code builder should persist the derived task list to `task_queue.json` in the project directory for crash recovery.

---

## Section 2: Genuinely Missing Plan-Level Content

### 2A. [CRITICAL] Design spec — Add Fix Regression Guard

**File:** `docs/thoughtforge-design-specification.md`
**Location:** Convergence Guards section, insert as a new guard between Termination Success and Hallucination (position 1.5 in the guard evaluation order)
**Action:** Add this new guard:

> **Fix Regression Guard (per-iteration):** After each fix step, if the total error count increases compared to the review that prompted the fix (i.e., the fix made things worse), log a warning. If the fix step increases total errors for 2 consecutive iterations, halt and notify: "Fix step is introducing more issues than it resolves. Review needed." This guard evaluates per-iteration, not per-trend, and fires before the trend-based guards.

---

### 2B. [MAJOR] Execution plan — Add Prompt Drafting Guidelines section

**File:** `docs/thoughtforge-execution-plan.md`
**Location:** New section after "Task Acceptance Criteria"
**Action:** Add this new section:

> ### Prompt Drafting Guidelines
>
> Each "To be drafted" prompt must:
> 1. Implement all behavioral requirements from the design spec section it serves (e.g., `/prompts/spec-building.md` must implement the Phase 2 autonomy principle: decide autonomously for low-risk decisions, escalate high-impact ones).
> 2. Require structured output where the design spec mandates it (e.g., `PlanBuilderResponse` JSON for plan-build, review JSON for review prompts).
> 3. Include the `constraints.md` re-read instruction for Phase 4 prompts (review and fix).
> 4. Reference the specific Zod schema the AI's output must conform to (for review prompts).
> 5. Be testable — the prompt's expected behavior should be verifiable during e2e tests (Tasks 51–53).

---

### 2C. [MAJOR] Design spec — Add Phase 3 Stuck Recovery "Provide Input" flow

**File:** `docs/thoughtforge-design-specification.md`
**Location:** Phase 3 Stuck Recovery section, after the two-option description (Provide Input / Skip Task)
**Action:** Add this paragraph:

> **Provide Input Flow:** When the human clicks Provide Input and submits text, the orchestrator appends the human's message to `chat_history.json` and re-invokes the builder's current stuck task with the original prompt context plus the human's input appended as additional guidance. The builder's retry counter for the stuck task is reset — the human's input constitutes a new attempt, not a continuation of the failure sequence. If the builder remains stuck after receiving human input, stuck detection resumes from count 0 for that task.

---

### 2D. [MAJOR] Design spec — Add Graceful Shutdown behavior

**File:** `docs/thoughtforge-design-specification.md`
**Location:** Technical Design section, immediately after the "Server Restart Behavior" subsection
**Action:** Add this new subsection:

> **Graceful Shutdown:** On `SIGTERM` or `SIGINT`, the server stops accepting new operations and waits for any in-progress agent subprocess to complete (up to the configured `agents.call_timeout_seconds`). If the subprocess completes, the current iteration's state is written normally and `status.json` remains in its current phase. If the timeout expires, the subprocess is killed, the current iteration is abandoned (no state written), and the project is left in its last committed state. The server then exits. On next startup, the standard Server Restart Behavior applies.

---

### 2E. Design spec — Add Kanban column clarification for Phase 2 [Minor]

**File:** `docs/thoughtforge-design-specification.md`
**Location:** UI section, Kanban column mapping
**Action:** Add this note after the Kanban column mapping:

> Phase 2 uses a single `spec_building` state for both AI proposal and human correction cycles. On the Kanban board, the card remains in the Spec Building column for the duration of Phase 2. The halted indicator (if the project is halted during Phase 2) provides the only visual distinction. If finer-grained Phase 2 status visualization is needed, it is deferred.

---

### 2F. Execution plan — Add mid-stream project switch handling to Task 7g [Minor]

**File:** `docs/thoughtforge-execution-plan.md`
**Location:** Build Stage 2, Task 7g description
**Action:** Append to the task description:

> Include mid-stream project switch handling: when the human switches projects during AI response streaming, stop rendering the stream for the previous project. Server-side processing continues uninterrupted per design spec.

---

### 2G. Execution plan — Add truncation logic to Task 9a [Minor]

**File:** `docs/thoughtforge-execution-plan.md`
**Location:** Task 9a description
**Action:** Append to the task description:

> Include context window truncation logic per build spec Chat History Truncation Algorithm: Phase 1 retains brain dump messages, Phase 2 retains initial AI proposal, Phase 3–4 truncate from beginning with no anchor. Log a warning when truncation occurs.

---

## Section 3: Build Spec Material That Should Be Extracted

### 3A. Design spec — Realign algorithm overlap removal [Minor]

**File:** `docs/thoughtforge-design-specification.md`
**Location:** Phase 1 step 9
**Action:** After applying change 1A above, further simplify the remaining realign description so the design spec only says:

> Human can type "realign from here" in chat. Unlike phase advancement actions (which use buttons), this is a chat-parsed command that discards messages after the most recent substantive human correction and re-distills. Matching rules and algorithm in build spec.

Remove any remaining implementation-level matching logic from the design spec for this feature.

---

### 3B. [MAJOR] Design spec — Extract truncation algorithm details to build spec

**File:** `docs/thoughtforge-design-specification.md`
**Location:** `chat_history.json` Error Handling section (or wherever the truncation behaviors per phase are described)
**Action:** Replace the three phase-specific truncation descriptions:
- "Phase 1: older messages truncated while always retaining the original brain dump and the most recent messages."
- "Phase 2: older messages are truncated while always retaining the initial AI spec proposal."
- "Phase 3–4: older messages are truncated from the beginning with no anchoring message."

With this single paragraph:

> If a phase's chat history exceeds the agent's context window, the agent invocation layer truncates older messages using phase-specific anchoring rules. Truncation algorithms per phase are defined in the build spec. A warning is logged when truncation occurs.

Verify the build spec already contains the full truncation algorithm details (Phase 1 retains brain dump, Phase 2 retains initial proposal, Phase 3-4 no anchoring). If not, add them there.

---

## Items Confirmed Correct (No Action Needed)

These were reviewed and require no changes:
- Design spec, Phase 1 step 0 — Project ID format: already correctly split between design spec and build spec.
- Design spec, Agent Communication — shell safety rule: correctly present in both specs at appropriate abstraction levels.
- Design spec, WebSocket Disconnection — reconnection behavior: acceptable as design-level requirement.

---

## After All Changes Are Applied

1. Re-read each modified file to verify no formatting was broken and all changes were applied correctly.
2. `git status -u` — verify all modified files.
3. `git diff --stat` — confirm changes.
4. Git add only the files you modified.
5. Commit with message: `Apply review findings`
6. Push to remote: `git push`
7. `git pull` — confirm sync with remote. Do not leave commits unpushed.
