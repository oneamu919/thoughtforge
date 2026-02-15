Now I have a thorough understanding of all four documents. Let me perform the review as specified.

---

# ThoughtForge Plan Review — Findings

## 1. Writing That's Unclear

**[Minor]** Design Spec, Phase 1 Step 9 (line 95): The "realign from here" description says it "discards messages after the most recent substantive human correction and re-distills" but the build spec's Realign Algorithm says excluded messages are "retained in `chat_history.json` for audit trail." The design spec says "discards" while the build spec says "retained but excluded from working context." The design spec language is misleading.

**Replacement text:**
> 9. Human can type "realign from here" in chat. Unlike phase advancement actions (which use buttons), this is a chat-parsed command that excludes messages after the most recent substantive human correction from the working context and re-distills. Excluded messages are retained in `chat_history.json` for audit trail but not passed to the AI. Matching rules and algorithm in build spec.

---

**[Minor]** Design Spec, Phase 4 Stagnation Guard (line 347): The stagnation guard description says "Same total error count for a configured number of consecutive iterations (stagnation limit), AND issue rotation detected (fewer than 70% of current issues match prior iteration issues…)." The parenthetical "(fewer than 70% of current issues match prior iteration issues by Levenshtein similarity >= 0.8 on description)" appears to define rotation as "fewer than 70% match the prior iteration," but it's ambiguous whether this comparison is against only the immediately prior iteration or against all iterations in the plateau window.

**Replacement text for the parenthetical:**
> …AND issue rotation detected (fewer than 70% of issues in the current iteration have a Levenshtein similarity ≥ 0.8 match on `description` against the immediately prior iteration's issues).

---

**[Minor]** Design Spec, Phase 4 Fix Regression Guard (line 345): "If the fix step increases total errors for 2 consecutive iterations" is ambiguous — does "2 consecutive iterations" mean 2 iterations where the fix made things worse (regardless of position), or 2 iterations in a row?

**Replacement text:**
> If the fix step increases total error count in 2 back-to-back iterations (the two most recent consecutive fix steps both made things worse), halt and notify.

---

**[Minor]** Design Spec, Locked File Behavior for `spec.md` and `intent.md` (lines 169–175): The text says "Read once at Phase 3 start. Not re-read during later phases." Then it says "On server restart, in-memory copies are discarded. When a halted Phase 4 project is resumed, the orchestrator re-reads both files from disk." This implies `spec.md` is re-read on resume. But the Polish Loop section says the fix agent receives `constraints.md` for scope awareness, not `spec.md`. If `spec.md` is re-read on resume, where is it used in Phase 4?

**Replacement text (lines 169–175):**
> - **`spec.md` and `intent.md` (static after creation):**
>   - Read at Phase 3 start and used by the Phase 3 builder. Not re-read during Phase 4 iterations — Phase 4 uses `constraints.md` and the deliverable itself.
>   - Manual human edits during active pipeline execution have no effect — the pipeline works from its Phase 3 context.
>   - On server restart, any in-memory Phase 3 context is discarded. When a halted project is resumed during Phase 3, the orchestrator re-reads both files from disk. When a halted project is resumed during Phase 4, neither file is re-read — Phase 4 operates from `constraints.md` and the current deliverable state.
>   - There is no "restart from Phase N" capability in v1. The pipeline does not detect or warn about manual edits to any locked file.

---

**[Minor]** Design Spec, Phase 3 Code Mode test-fix cycle (line 247): "A hard cap on Phase 3 test-fix cycles is deferred — not a current build dependency." This is clear, but the immediately preceding sentence says the cycle is "bounded by the agent timeout and the human's ability to terminate." The agent timeout bounds a single agent invocation, not the test-fix loop. The human's ability to terminate requires stuck detection to trigger first (which requires 2-3 consecutive failures of the same kind). There is a gap between "no hard cap" and "stuck detection only fires on specific patterns" — a rotating-failure scenario in Phase 3 could loop indefinitely.

**Replacement text:**
> In practice, the code builder's test-fix cycle is bounded by the stuck detector (which fires on repeated identical failures) and the human's ability to terminate via the Phase 3 stuck recovery buttons. A test-fix cycle that produces rotating failures (different tests failing each cycle) will not trigger stuck detection and will continue indefinitely until the human intervenes or the agent timeout kills a single invocation. A hard cap on Phase 3 test-fix cycles is deferred — not a current build dependency.

---

**[Minor]** Execution Plan, Critical Path (line 193): The critical path lists "Task 13 → Task 6c" but Task 6c's dependencies are "Task 5, Task 6a, Task 7" — Task 13 is not listed as a dependency of 6c. The critical path chain appears to assume that Phase 2 output (Task 13) must exist before Phase 3→4 transition (Task 6c) can be tested, which is logically true but not reflected in the declared dependency graph.

**Replacement text:**
> **Task 1 → Task 41 → Task 42 → Task 6a → Task 8 → Task 9 → Task 11 → Task 12 → Task 13 → Task 15 → Task 6c → Task 30 → Tasks 33–37 → Task 51**
>
> Note: Task 13 is not a declared code dependency of Task 6c, but Task 6c cannot be meaningfully tested without Phase 2 outputs (spec.md, constraints.md) existing. Task 15 (plan builder) must complete before Task 6c can be exercised in Plan mode. The critical path reflects the functional chain, not just the task-level code dependencies.

---

## 2. Genuinely Missing Plan-Level Content

**[Major]** Design Spec — No graceful shutdown behavior for WebSocket connections. The Graceful Shutdown section (line 457) covers agent subprocesses but does not mention active WebSocket connections. The chat interface section describes auto-reconnect for dropped connections but doesn't specify whether the server sends a close frame before shutting down. Without this, clients will see an unclean disconnection on every server restart.

**Proposed content (add after the Graceful Shutdown paragraph):**
> **WebSocket Shutdown:** During graceful shutdown, the server sends a WebSocket close frame (code 1001, "Server shutting down") to all connected clients before stopping the HTTP listener. Clients receive the close event and display a "Server stopped" message instead of triggering the auto-reconnect loop. On server restart, clients reconnect normally.

---

**[Major]** Design Spec / Execution Plan — No error handling for the Phase 3 Plan builder's multi-invocation model when a mid-section invocation fails. The design spec says the builder may invoke the AI "multiple times to fill the complete template — for example, one invocation per major section." The error handling table covers "Agent failure during build" with retry-once-then-halt, but doesn't address what happens to already-filled sections. Are they preserved? Is the partially-filled template committed before halting? On resume, does the builder restart from the failed section or from scratch?

**Proposed content (add to Phase 3 Error Handling table or after the builder interaction model paragraph):**
> **Partial Plan Build Recovery:** If the plan builder halts mid-template (agent failure on section N of M), the orchestrator commits the partially-filled template before halting. On resume, the builder re-reads the partially-filled template from disk, identifies which sections are complete (non-empty, non-placeholder content), and resumes from the first incomplete section. Already-filled sections are not re-generated.

---

**[Minor]** Design Spec — No specification for what happens if the project directory already exists during project initialization. The Project ID format uses `{timestamp}-{random}` which is very likely unique, but there's no stated behavior for the collision case.

**Proposed content (add to Project Initialization Sequence or Design Spec Phase 1):**
> **Project ID Collision:** If the generated project directory already exists (extremely unlikely with timestamp + random), generate a new random suffix and retry. If the directory still exists after 3 retries, halt with error: "Could not generate unique project ID. Check projects directory for stale entries."

---

**[Minor]** Execution Plan — No mention of how TypeScript compilation fits into the development workflow or CI. The execution plan states "The codebase uses TypeScript" and lists `typescript` as a dev dependency, but doesn't specify whether the build uses `tsc` for compilation, `tsx` for direct execution, or Vitest's built-in TypeScript support. This affects how every task is run and tested.

**Proposed content (add to Design Decisions or Build Toolchain section of the Execution Plan):**
> **TypeScript execution model:** ThoughtForge runs via `tsx` (or `ts-node`) during development and compiles to JavaScript via `tsc` for production deployment. Vitest handles TypeScript natively for tests (no separate compilation step). The `package.json` `start` script runs the compiled output; a `dev` script runs via `tsx` for live development.

---

**[Minor]** Design Spec — Fix Regression guard is described in the Convergence Guards table but is not explicitly included in the guard evaluation order list in the build spec. The build spec lists it as item 0 ("checked first, immediately after each fix step") which is correct, but the design spec's convergence guard table (lines 342-349) presents it at the same level as the other guards without clarifying that it operates on a different schedule (per-fix-step vs. per-iteration). This is addressed in the build spec, but the design spec's table layout implies all guards are evaluated at the same point.

**Proposed content (add a note row or footnote to the Design Spec Convergence Guards table):**
> **Evaluation timing note:** Fix Regression is evaluated immediately after each fix step (before other guards). All other guards are evaluated after the full iteration cycle (review + fix) completes. See build spec Guard Evaluation Order for the complete sequence.

---

## 3. Build Spec Material That Should Be Extracted

**[Minor]** Design Spec, Phase 1 Step 3 Detail (line 82): "The AI matches URLs in chat messages against known URL patterns for each enabled connector and pulls content automatically. URL matching rules (enabled/disabled/unmatched behavior) are in the build spec." — This sentence is fine as a design spec reference. However, the URL matching rules themselves already exist in the build spec (URL Matching Behavior table). No extraction needed here — this is correctly placed.

**[Minor]** Design Spec, OPA Framework section (lines 19-27): The Handlebars template mechanics ("Handlebars templates define the OPA skeleton — fixed section headings with OPA table placeholders. The AI fills the table content but cannot alter the structure.") belong in the design spec as architectural intent. However, the specific mention of "Handlebars" as the implementation technology is a build decision, not a design decision. The design spec should describe the behavior ("templates define fixed structure, AI fills content slots") and the build spec should specify the technology.

This is borderline — "Handlebars" is already listed as a design decision in the Design Decisions table (Decision 19) and in the ThoughtForge Stack table. Since it's an architectural choice rather than an implementation detail, it can stay. **No extraction recommended.**

**[Minor]** Build Spec, HTTP API Surface (lines 558-576): The statement "Route structure is a build-time implementation detail — the above is guidance, not a rigid contract" already appropriately frames this. However, the routes table is comprehensive enough that an AI coder might treat it as a rigid contract despite the disclaimer. Consider moving this to a separate section or adding a stronger marker.

**No extraction needed** — it's already in the build spec where it belongs.

---

**Summary:** 6 clarity findings (all Minor), 4 missing content findings (2 Major, 2 Minor), 0 items requiring extraction from design spec to build spec. The plan documents are thorough, well-cross-referenced, and clearly distinguish design-level from build-level concerns. The two Major findings (WebSocket shutdown and partial plan build recovery) are the only items I'd flag as requiring resolution before build begins — a coder encountering either of these mid-implementation would have to make an unguided decision.
