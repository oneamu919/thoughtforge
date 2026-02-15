I've now read all four documents thoroughly. Let me produce the review.

---

# ThoughtForge Design Specification — Plan Review

Reviewed as: senior dev who will eventually build from this plan.

Documents reviewed: `thoughtforge-design-specification.md`, `thoughtforge-execution-plan.md` (scrutinized). Context from `thoughtforge-requirements-brief.md` and `thoughtforge-build-spec.md` (reference).

---

## 1. Writing That's Unclear

**[Minor]** Design spec, Phase 1, step 9 — "realign from here" trigger mechanism is inconsistent with the confirmation model.

The plan states that all phase-critical actions use button presses to avoid misinterpreting chat messages, yet "realign from here" is a magic string typed into chat that triggers a pipeline action (rollback and re-distillation). This creates an inconsistency a builder would need to reconcile.

**Replacement text:**
> Human can type "realign from here" in chat. Unlike phase advancement actions (which use buttons to prevent misinterpretation), "realign from here" is a chat-parsed command because it does not advance the pipeline — it re-processes within the current phase. The AI rolls back to the most recent substantive correction and re-distills from the original brain dump plus all corrections up to that point. If no corrections exist yet, the command is ignored with a prompt to provide a correction first. Implementation algorithm in build spec.

---

**[Minor]** Design spec, Phase 2 — "AI resolves Unknowns and Open Questions" escalation criteria are deferred to a prompt that doesn't exist yet.

Step 3 says: "The Phase 2 prompt (`spec-building.md`) governs when the AI should decide autonomously vs. escalate to the human." But the build spec lists `spec-building.md` as "Status: To be drafted by the AI coder." A builder reading the design spec expects guidance on the escalation criteria at the plan level — instead they find a forward reference to an empty file. The design spec should state the principle; the prompt file implements it.

**Replacement text for design spec, Phase 2, step 3:**
> AI resolves Unknowns and Open Questions from `intent.md` — either by making a reasoned decision (stated in `spec.md`) or by asking the human during the Phase 2 chat. The governing principle: the AI decides autonomously when the decision is low-risk, reversible, or has a clearly dominant option based on the constraints — and escalates to the human when the decision is high-impact, preference-dependent, or has multiple viable options with material trade-offs. The Phase 2 prompt (`spec-building.md`) operationalizes this principle. No unresolved unknowns may carry into `spec.md`.

---

**[Minor]** Design spec, Phase 3 Code Mode — "test-fix cycle" iteration limit is unspecified.

The Phase 3 code builder enters "a test-fix cycle: run tests, pass failures back to the agent, agent fixes, re-run tests — repeating until all tests pass or stuck detection triggers." The stuck detection section specifies "3 consecutive identical test failures" for the stuck condition, but it's not clear whether the test-fix cycle has its own iteration cap independent of the Phase 4 max iterations guard. A builder could interpret this as potentially infinite if the test failures keep changing each cycle.

**Replacement text (append to the existing code builder paragraph):**
> The Phase 3 test-fix cycle does not have its own iteration cap — it terminates only via stuck detection (3 consecutive identical test failures or 2 consecutive non-zero exits on the same task). Since each cycle produces different failing tests, the stuck detector will not trigger on rotating failures. In practice, the code builder's test-fix cycle is bounded by the agent timeout and the human's ability to terminate via the Phase 3 stuck recovery buttons. A hard cap on Phase 3 test-fix cycles is deferred — not a current build dependency.

---

**[Minor]** Design spec, Stagnation guard — "same total error count" could be misread.

The stagnation guard says "Same total error count for a configured number of consecutive iterations." A builder might reasonably ask: same total, or same per-severity breakdown? If critical goes from 1→0 while minor goes from 4→5, the total is unchanged but the composition shifted. This matters for determining if the plateau is genuine.

**Replacement text:**
> **Stagnation:** Same total error count (sum of critical + medium + minor) for a configured number of consecutive iterations (stagnation limit) AND issue rotation detected. The comparison uses total count only, not per-severity breakdown — a shift in severity composition at the same total is still treated as stagnation if the rotation threshold is also met.

---

**[Minor]** Design spec, Locked File Behavior — `spec.md` and `intent.md` inconsistency with restart recovery.

The plan says these files are "read once at Phase 3 start and not re-read during later phases." But server restart recovery (which sets autonomous-state projects to `halted`) means a project halted mid-Phase-4 and then resumed would need to re-read `spec.md` somewhere. The plan doesn't clarify whether the in-memory copy survives a restart — it doesn't, since the process is dead.

**Replacement text (append to the `spec.md` and `intent.md` static paragraph):**
> On server restart, the in-memory copies are lost. When the human resumes a halted Phase 4 project, the orchestrator re-reads `spec.md` and `intent.md` from disk to reconstruct working context. If the human manually edited these files while the project was halted, the resumed pipeline will use the edited versions. This is an acceptable side effect of the restart recovery model.

---

**[Major]** Design spec, Phase 4 — Review and Fix steps use the same agent, with no guidance on prompt separation.

The plan describes Step 1 (Review) and Step 2 (Fix) as separate operations but doesn't state whether they use the same agent instance, the same agent type, or different agents. A builder would need to know: does the reviewer AI also do the fixing? If so, the fix prompt must explicitly avoid the reviewer's tendency to find new issues while fixing. If different agents, how are they selected?

**Replacement text (add after the "Each Iteration — Two Steps" section):**
> **Agent assignment for review and fix steps:** Both the review and fix steps use the same agent assigned to the project (from `status.json` `agent` field). The review prompt instructs the agent to produce a JSON error report only — no fixes. The fix prompt instructs the agent to apply fixes from the provided issue list only — no new review. Prompt separation enforces the behavioral boundary. Using separate agents for review vs. fix is deferred — not a current build dependency.

---

**[Minor]** Execution plan, Critical Path — secondary chain is incomplete.

The secondary critical chain is listed as: "Task 1 → Task 26 → Task 27 → Task 21 → Task 30c → Task 52." But Task 21 also depends on Tasks 41–42 (agent layer), Task 6a (orchestrator), and Task 20 (code plugin folder). The stated chain omits these, which could mislead scheduling decisions.

**Replacement text:**
> **Secondary critical chain (Code mode):** Task 1 → Task 41 → Task 42 (parallel with Task 26 → Task 27) → Task 6a → Task 21 → Task 30c → Task 52. The agent layer (41–42) and VK adapter (26–27) are parallel branches that both feed into Task 21.

---

## 2. Genuinely Missing Plan-Level Content

**[Major]** Design spec — No specification for how the Phase 3 code builder passes context to the coding agent.

The plan says the code builder "passes the full `spec.md` (architecture, dependencies, acceptance criteria) to the coding agent as a single build prompt." But `constraints.md` contains the acceptance criteria, not `spec.md`. `spec.md` contains the architecture and decisions. The plan doesn't specify which files constitute the build context and in what order. A builder needs to know: is it `intent.md` + `spec.md` + `constraints.md`? Just `spec.md`? What about resources from `/resources/`?

**Proposed content (add to Phase 3 Code Mode section, after step 1):**
> **Code builder context assembly:** The code builder passes the following files to the coding agent as build context: `spec.md` (architecture, decisions, dependencies), `constraints.md` (acceptance criteria, scope, priorities), and optionally the plan document from `/resources/` if one was identified by the Plan Completeness Gate. `intent.md` is not passed — its content is already distilled into `spec.md`. Resource files from `/resources/` (other than a chained plan document) are not passed to the code builder — they were consumed during Phase 1 distillation.

---

**[Major]** Design spec — No specification for what the Phase 4 fix agent receives as context.

The plan says "Orchestrator passes JSON issue list to fixer agent, which applies fixes." But what else does the fixer receive? For code mode: the full codebase? Just the files referenced in issue locations? For plan mode: the full document? The fixer agent needs enough context to apply fixes but the plan doesn't specify the fix prompt's input assembly.

**Proposed content (add to Phase 4, after the Step 2 description):**
> **Fix agent context assembly:** The fix agent receives the JSON issue list and the relevant deliverable context. For Plan mode: the current plan document. For Code mode: the current codebase files referenced in the issue `location` fields, plus `constraints.md` for scope awareness. The fix agent does not receive the prior review JSON from previous iterations — only the current iteration's issue list. Full context assembly is specified in the fix prompts (`plan-fix.md`, `code-fix.md`).

---

**[Major]** Design spec — No specification for how Code mode Phase 4 reviewer receives the codebase.

The Phase 4 Code mode cycle says the reviewer gets "the codebase and `constraints.md`" plus test results. But how does "the codebase" get passed to a CLI agent that receives input via stdin? The full codebase could be hundreds of files. The plan doesn't address context window limitations for large code projects during review.

**Proposed content (add to Phase 4 Code Mode Iteration Cycle section):**
> **Code mode review context:** The review prompt includes `constraints.md`, test results, and a representation of the codebase. For codebases that fit within the agent's context window, the full source is included. For larger codebases, the reviewer receives a file manifest (list of all source files with sizes) plus the content of files that changed since the last iteration (identified via `git diff`). The review prompt (`code-review.md`) specifies the context assembly strategy. If the codebase exceeds the agent's context window even with diff-only strategy, the orchestrator logs a warning and proceeds with truncated context.

---

**[Minor]** Execution plan — No mention of how AI coders should handle the "To be drafted" prompts.

The build spec lists 7 of 9 prompts as "Status: To be drafted by the AI coder as the first step of the task that depends on this prompt." The execution plan's task acceptance criteria don't mention prompt drafting as a deliverable. A builder needs to know: is the prompt text a separate review artifact? Does the human approve it before the task proceeds?

**Proposed content (add to Task Acceptance Criteria section):**
> 5. For tasks that depend on a "To be drafted" prompt (identified in the build spec by "Used by" references): the AI coder drafts the prompt text as the first step of the task, writes it to the `/prompts/` directory, and the human reviews and edits via the Settings UI before the task proceeds to implementation. The prompt text is committed alongside the task's implementation code.

---

**[Minor]** Design spec — No specification for what happens when a project's git commit fails during Phase 4 review step but the fix step has already produced changes.

The error handling table covers "Git commit failure after review step" and "File system error during git commit after fix" separately, which is correct. But there's no specification for what happens when the review commit succeeds but the fix commit fails — the review JSON is committed but the fix is in a dirty working tree. The crash recovery section says "on resume, the failed iteration is re-attempted from the beginning (review step)" — meaning the committed review would be redundant and the un-committed fix changes would still be in the working tree.

**Proposed content (add to Phase 4 Error Handling table):**
> | Fix step git commit fails after review step committed successfully | Halt and notify human. The review commit is preserved. Un-committed fix changes remain in the working tree. On resume, the orchestrator does NOT re-run the review step — it re-attempts only the fix commit. If the commit succeeds on retry, the iteration proceeds normally. If the working tree has been manually modified by the human during the halt, the orchestrator commits whatever is present (the human is responsible for the state they left). |

---

**[Minor]** Design spec — Chat history context window truncation lacks detail on how "always retaining the original brain dump" works.

The plan says when truncation occurs, "retaining the most recent messages and always retaining the original brain dump." But the brain dump could be multiple messages (step 1 says "one or more messages of freeform text"). The plan doesn't specify how the original brain dump messages are identified for retention during truncation.

**Proposed content (add after the truncation sentence):**
> The original brain dump messages are identified as all human messages before the first Distill button press in the chat history. During truncation, these messages are always retained at the beginning of the context, followed by the most recent messages that fit within the remaining window. Messages between the brain dump and the retained recent messages are dropped.

---

## 3. Build Spec Material That Should Be Extracted

**[Minor]** Design spec, Phase 1 step 11b — Deliverable type parsing implementation detail.

> "The AI's distillation always states exactly one of 'Plan' or 'Code' as the first word of this section. The orchestrator string-matches that word to set the field."

This is implementation-level parsing logic (string-match the first word). The design spec should say *what* happens (deliverable type is derived from the confirmed intent), not *how* the parsing works. The build spec already covers schemas and parsing; this belongs there.

**Why it belongs in the build spec:** It specifies a parsing algorithm (first-word string match) that a builder implements, not a design decision a stakeholder reviews.

---

**[Minor]** Design spec, Realign Algorithm reference.

The design spec (Phase 1, step 9) references the algorithm by name and the build spec contains the full algorithm. This is fine. However, the design spec also partially describes the algorithm: "rolls back to the most recent substantive correction and re-distills from the original brain dump plus all corrections up to that point." This partial description in the design spec could diverge from the build spec's full algorithm.

**Why it belongs in the build spec only:** The design spec should state the *behavior* ("human can request re-distillation from a prior correction point") and defer the mechanism to the build spec. Currently both documents describe overlapping portions of the same algorithm.

---

**[Minor]** Design spec, Button Debounce section.

> "Once an action button is pressed, it is immediately disabled in the UI and remains disabled until the triggered operation completes or fails. A second click on a disabled button has no effect. If the server receives a duplicate action request for a button that has already been processed (e.g., due to a race condition between client and server), the server ignores the duplicate and returns the current project state."

This is UI implementation behavior (client-side disable, server-side dedup). The design spec should state "buttons prevent duplicate actions" and defer the mechanism to the build spec.

**Why it belongs in the build spec:** Client-side disable timing, server-side dedup handling, and race condition resolution are implementation details, not design decisions.

---

That concludes the review. Three lists, severity-tagged, sorted by severity within each list.
