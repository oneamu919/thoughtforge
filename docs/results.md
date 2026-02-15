Now I have all four documents fully read. Let me perform the thorough review. I'll cross-reference across all documents carefully before producing findings.

---

# Project Plan Review — ThoughtForge Pipeline Tool

Review scope: `thoughtforge-design-specification.md`, `thoughtforge-build-spec.md`, `thoughtforge-execution-plan.md` — reviewed as a unified plan set, evaluated against `thoughtforge-requirements-brief.md`.

---

## 1. Writing That's Unclear

**[Minor]** Design spec, Phase 1 step 9 — "realign from here" described twice in adjacent paragraphs with overlapping wording.

The two paragraphs beginning with "Human can type 'realign from here'" and "The human types 'realign from here'" say the same thing. The second paragraph reads as an accidental duplicate.

**Replacement:** Delete the second paragraph ("The human types 'realign from here' in chat to trigger a re-distillation from the original brain dump plus corrections up to a rollback point. Exact matching rules and algorithm in build spec. Messages containing the phrase alongside other text are treated as regular corrections.") entirely. The first paragraph already says everything needed. The "messages containing the phrase alongside other text" clause belongs in the build spec's Realign Algorithm section (where it is already covered by the exact-match rule).

---

**[Minor]** Design spec, Phase 1 step 3 — connector URL identification restated in the middle of the same step.

The text "The AI identifies connector URLs in chat messages by matching against known URL patterns for each enabled connector" is immediately followed by "The AI matches each URL against the known patterns for enabled connectors and pulls content automatically." These are the same statement with different words.

**Replacement:** Collapse to a single sentence. Replace the entire "Step 3 Detail — Connector URL Identification" sub-section with:

> **Step 3 Detail — Connector URL Identification:** The AI matches URLs in chat messages against known URL patterns for each enabled connector and pulls content automatically. URL matching rules (enabled/disabled/unmatched behavior) are in the build spec.

---

**[Minor]** Design spec, Phase 1 step 0 — "Project Name Derivation" parenthetical interrupts the initialization flow.

The project name derivation paragraph is placed inside Phase 1 step 0 (project initialization), but derivation happens later — after distillation completes and the human confirms. Its placement mid-initialization implies it happens during initialization.

**Replacement:** Move the "Project Name Derivation" paragraph from Phase 1 step 0 to after Phase 1 step 11b, where deliverable type is derived. This groups all post-confirmation outputs together. Add a forward-reference in step 0: "Project name is derived later during Phase 1 — see step 11."

---

**[Minor]** Design spec, Locked File Behavior — the bullet on `spec.md` and `intent.md` is a wall of text covering five distinct behaviors (read once, not re-read, human edits invisible during execution, restart discards in-memory copies, halted projects reload from disk).

**Replacement:** Break into sub-bullets:

> - **`spec.md` and `intent.md` (static after creation):**
>   - Read once at Phase 3 start. Not re-read during later phases.
>   - Manual human edits during active pipeline execution have no effect — the pipeline works from its in-memory copy.
>   - On server restart, in-memory copies are discarded. When a halted Phase 4 project is resumed, the orchestrator re-reads both files from disk. If the human edited them while the project was halted, the resumed pipeline uses the edited versions.
>   - There is no "restart from Phase N" capability in v1. The pipeline does not detect or warn about manual edits to any locked file.

---

**[Minor]** Design spec, Convergence Guards table — the Stagnation guard's "Condition" cell packs a complex multi-clause definition into a single table cell, making it harder to parse than the other guards.

**Replacement:** Simplify the table cell to:

> Same total error count for a configured number of consecutive iterations (stagnation limit), AND issue rotation detected (old issues resolved, new issues introduced at the same rate). When both conditions are true, the deliverable has reached a quality plateau. Severity composition shifts at the same total still qualify as stagnation if rotation threshold is also met. Parameters in build spec.

Move the detailed explanation that's currently in the cell (rotation threshold, similarity measure, "the reviewer is cycling through cosmetic issues") to a subsection below the table, parallel to how the other guards have their parameters detailed in the build spec.

---

**[Minor]** Design spec, Convergence Guards table — the Fabrication guard condition describes the "2× convergence threshold" check with inline arithmetic examples (≤0 critical, ≤6 medium, ≤10 minor) that are derived from default config values. This mixes runtime-derived values with the guard definition.

**Replacement:** Simplify the table cell to:

> A severity category spikes significantly above its trailing average (window size defined in build spec), AND in at least one prior iteration, every severity category was at or below twice its convergence threshold (i.e., critical ≤ 2 × `critical_max`, medium ≤ 2 × `medium_max`, minor ≤ 2 × `minor_max`). These multipliers are derived from `config.yaml` at runtime, not hardcoded. This ensures fabrication is only flagged after the deliverable was near-converged. Parameters in build spec.

Remove the parenthetical "(using default config: ≤0 critical, ≤6 medium, ≤10 minor)" — it adds nothing to the design and will be wrong the moment config values change.

---

**[Minor]** Build spec, Code Builder Task Queue section — the phrase "must produce a deterministic task list from the same `spec.md` input" conflicts with the statement two sentences later that "the task list format and derivation logic are internal to the code builder and are not persisted to state files." If the logic is internal and not specified, determinism is an implementation hope, not a guarantee.

**Replacement:** Replace "must produce a deterministic task list from the same `spec.md` input" with:

> should produce a consistent task list from the same `spec.md` input — the ordering logic must be stable so that crash recovery (re-deriving the task list after restart) produces a compatible ordering. If determinism cannot be guaranteed, the code builder should persist the derived task list to `task_queue.json` in the project directory for crash recovery.

---

## 2. Genuinely Missing Plan-Level Content

**[Critical]** Design spec — no error handling for Phase 4 fix step producing regressions (new critical errors introduced by a fix).

The plan covers convergence guards for trends (hallucination, fabrication, stagnation) but none of these fire on a single iteration where the fix step introduces regressions worse than the review found. The hallucination guard requires "at least 2 consecutive iterations with decreasing total error count" before triggering — so a fix that doubles the error count on iteration 1 or 2 passes all guards and the loop continues. The fabrication guard requires prior near-convergence. There is no guard that fires on: "review found 5 issues, fix introduced 12."

**Proposed content to add (design spec, Convergence Guards section):**

> **Fix Regression Guard (per-iteration):** After each fix step, if the total error count increases compared to the review that prompted the fix (i.e., the fix made things worse), log a warning. If the fix step increases total errors for 2 consecutive iterations, halt and notify: "Fix step is introducing more issues than it resolves. Review needed." This guard evaluates per-iteration, not per-trend, and fires before the trend-based guards (insert as position 1.5 in the guard evaluation order — after termination success, before hallucination).

---

**[Major]** Execution plan — no guidance on how AI coders should handle the "To be drafted" prompts.

The build spec marks 7 of 9 prompts as "To be drafted by the AI coder as the first step of the task that depends on this prompt." The execution plan's Task Acceptance Criteria (point 5) says the AI coder drafts the prompt and the human reviews it. But there's no guidance on what makes a good prompt for this system — no quality criteria, no structural requirements, no references to the design spec's behavioral requirements that the prompt must implement.

**Proposed content to add (execution plan, new section after Task Acceptance Criteria):**

> ### Prompt Drafting Guidelines
>
> Each "To be drafted" prompt must:
> 1. Implement all behavioral requirements from the design spec section it serves (e.g., `/prompts/spec-building.md` must implement the Phase 2 autonomy principle: decide autonomously for low-risk decisions, escalate high-impact ones).
> 2. Require structured output where the design spec mandates it (e.g., `PlanBuilderResponse` JSON for plan-build, review JSON for review prompts).
> 3. Include the `constraints.md` re-read instruction for Phase 4 prompts (review and fix).
> 4. Reference the specific Zod schema the AI's output must conform to (for review prompts).
> 5. Be testable — the prompt's expected behavior should be verifiable during e2e tests (Tasks 51–53).

---

**[Major]** Design spec — no specification of what happens when the human provides input during Phase 3 stuck recovery.

The design spec says "Provide Input" is a button option during Phase 3 stuck recovery. The build spec's Action Button Behavior table says "Button disabled, chat shows input prompt. Human types response, builder resumes." But there is no specification of how the human's input reaches the builder — does it replace the stuck prompt? Append to context? Is the builder re-invoked with the original prompt plus the human's input? The Phase 3 code builder's test-fix cycle model doesn't describe how human intervention is injected.

**Proposed content to add (design spec, Phase 3 Stuck Recovery section, after the two-option description):**

> **Provide Input Flow:** When the human clicks Provide Input and submits text, the orchestrator appends the human's message to `chat_history.json` and re-invokes the builder's current stuck task with the original prompt context plus the human's input appended as additional guidance. The builder's retry counter for the stuck task is reset — the human's input constitutes a new attempt, not a continuation of the failure sequence. If the builder remains stuck after receiving human input, stuck detection resumes from count 0 for that task.

---

**[Major]** Design spec/execution plan — no specification of graceful shutdown behavior.

Server restart behavior is specified (scan for active projects, halt autonomous ones). But there is no specification of what happens during a graceful shutdown (e.g., `Ctrl+C`, `SIGTERM`). If a polish iteration is mid-execution, does the server wait for it to complete? Kill the subprocess? Write partial state?

**Proposed content to add (design spec, Technical Design section, after Server Restart Behavior):**

> **Graceful Shutdown:** On `SIGTERM` or `SIGINT`, the server stops accepting new operations and waits for any in-progress agent subprocess to complete (up to the configured `agents.call_timeout_seconds`). If the subprocess completes, the current iteration's state is written normally and `status.json` remains in its current phase. If the timeout expires, the subprocess is killed, the current iteration is abandoned (no state written), and the project is left in its last committed state. The server then exits. On next startup, the standard Server Restart Behavior applies.

---

**[Minor]** Design spec — no specification of the Kanban column for the "Spec Building" phase.

The Kanban column mapping lists: "Brain Dump → Distilling → Human Review → Spec Building → Building → Polishing → Done." But Phase 2 also has a human review component (the human corrects the spec). Unlike Phase 1 which has explicit sub-states (`distilling`, `human_review`), Phase 2 uses only `spec_building` for both AI proposal and human review. This is fine for `status.json`, but means there's no visual distinction on the Kanban board between "AI is proposing" and "waiting for human input" during Phase 2.

**Proposed content to add (design spec, UI section, Kanban column mapping):**

> Phase 2 uses a single `spec_building` state for both AI proposal and human correction cycles. On the Kanban board, the card remains in the Spec Building column for the duration of Phase 2. The halted indicator (if the project is halted during Phase 2) provides the only visual distinction. If finer-grained Phase 2 status visualization is needed, it is deferred.

---

**[Minor]** Execution plan — no task for implementing the mid-stream project switch behavior described in the design spec.

The design spec describes: "If the human switches projects while an AI response is streaming, the client stops rendering the stream for the previous project's chat." This is a specific UI behavior that needs implementation, but no task in Build Stage 2 covers it. Task 7g (project list sidebar) covers click-to-switch but not mid-stream switch handling.

**Proposed content to add (execution plan, Build Stage 2, Task 7g description, append):**

> Include mid-stream project switch handling: when the human switches projects during AI response streaming, stop rendering the stream for the previous project. Server-side processing continues uninterrupted per design spec.

---

**[Minor]** Execution plan — no task for the `chat_history.json` truncation algorithms.

The design spec describes three truncation behaviors (Phase 1 retains brain dump, Phase 2 retains initial proposal, Phase 3-4 no anchoring). The build spec has a "Chat History Truncation Algorithm" section. Task 58l tests the truncation. But no implementation task builds the truncation. Task 9a ("Implement `chat_history.json` persistence") covers append/clear/resume but doesn't mention truncation.

**Proposed content to add (execution plan, Task 9a description, append):**

> Include context window truncation logic per build spec Chat History Truncation Algorithm: Phase 1 retains brain dump messages, Phase 2 retains initial AI proposal, Phase 3–4 truncate from beginning with no anchor. Log a warning when truncation occurs.

---

## 3. Build Spec Material That Should Be Extracted

**[Minor]** Design spec, Phase 1 step 0 — Project ID format.

> "Project ID format: A URL-safe, filesystem-safe, unique string identifier. Format defined in build spec."

This is correctly deferred to the build spec. However, the *build spec* then defines it as `{timestamp}-{random}` with specific formatting rules (`YYYYMMDD`, 4-char hex). This is already in the build spec — no action needed. Included here only to confirm it was checked.

**No extraction needed — already correctly split.**

---

**[Minor]** Design spec, Phase 1 step 9 — Realign algorithm.

The design spec says "Exact matching rules and algorithm in build spec" but then includes behavioral detail that overlaps with the build spec's Realign Algorithm section: "Messages containing the phrase alongside other text are treated as regular corrections." This detail is implementation-level matching logic.

**Recommendation:** Remove from design spec. This is already covered by the build spec's "Command Matching" rule: "the entire chat message must be 'realign from here' with no additional text." The design spec should only say: "Human can type 'realign from here' in chat. Unlike phase advancement actions (which use buttons), this is a chat-parsed command that discards messages after the most recent substantive human correction and re-distills. Matching rules and algorithm in build spec."

---

**[Minor]** Design spec, Agent Communication section — "Shell safety: Prompt content is passed via stdin pipe or file — never through shell argument expansion."

This is a correct design-level safety requirement. However, the build spec repeats it nearly verbatim and adds implementation detail. No extraction needed — both instances serve their purpose. The design spec states the *rule*, the build spec states the *implementation*. Included here only to confirm it was checked.

**No extraction needed — already correctly split.**

---

**[Minor]** Design spec, WebSocket Disconnection section — the reconnection behavior paragraph includes implementation detail: "The client auto-reconnects on disconnection. During disconnection, the chat UI displays a visible connection status indicator."

This is borderline. The connection status indicator is a UI requirement (belongs in design spec). But the "reconnection parameters (backoff strategy, timing) are in the build spec" deferral is correct.

**No extraction needed — the line is acceptable as a design-level requirement.**

---

**[Major]** Design spec, `chat_history.json` Error Handling section — truncation algorithm details.

The design spec describes specific truncation behaviors per phase:

> "Phase 1: older messages truncated while always retaining the original brain dump and the most recent messages."
> "Phase 2: older messages are truncated while always retaining the initial AI spec proposal."
> "Phase 3–4: older messages are truncated from the beginning with no anchoring message."

These are algorithmic specifications that belong in the build spec. The design spec should state the *requirement* (chat history is truncated to fit agent context windows, with phase-specific anchoring rules) and defer the algorithm to the build spec.

**Recommendation:** Replace the three phase-specific truncation descriptions in the design spec with:

> If a phase's chat history exceeds the agent's context window, the agent invocation layer truncates older messages using phase-specific anchoring rules. Truncation algorithms per phase are defined in the build spec. A warning is logged when truncation occurs.
