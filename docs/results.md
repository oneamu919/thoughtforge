Now I have all four documents in full. Let me perform the thorough review.

---

# Project Plan Review — ThoughtForge Pipeline Tool

Review scope: `thoughtforge-design-specification.md`, `thoughtforge-build-spec.md`, `thoughtforge-execution-plan.md` — evaluated against `thoughtforge-requirements-brief.md` as the source of truth for requirements.

---

## 1. Writing That's Unclear

**[Minor]** Design spec, line 345 — Stagnation Guard condition text conflates two distinct checks in a single run-on sentence that forces re-reading.

> Current: "Same total error count for a configured number of consecutive iterations (stagnation limit), AND issue rotation is detected when fewer than 70% of current-iteration issues can be matched (Levenshtein similarity ≥ 0.8 on `description`) to any issue in the immediately prior iteration — meaning more than 30% of issues are new, indicating the reviewer is cycling rather than converging."

Replacement:

> "Two conditions must both be true: (1) **Plateau:** Total error count is identical for `stagnation_limit` consecutive iterations. (2) **Issue rotation:** Fewer than 70% of current-iteration issues match any issue in the immediately prior iteration (match = Levenshtein similarity ≥ 0.8 on `description`). When both are true, the reviewer is cycling through new cosmetic issues at the same rate old ones are resolved — a quality plateau, not genuine regression."

---

**[Minor]** Design spec, line 242 — The Phase 3 Code mode test-fix cycle paragraph is 15 lines of unbroken prose covering cycle behavior, stuck detection, non-triggering rotation failures, and deferred hard cap. It's difficult to parse.

Replacement — restructure as sub-sections:

> **Code builder test-fix cycle:**
>
> After the initial build invocation, the code builder enters a test-fix cycle: run tests → pass failures to the agent → agent fixes → re-run tests. This repeats until all tests pass or stuck detection triggers.
>
> **Stuck detection within the cycle:** The stuck detector fires on 3 consecutive cycles with the *identical* set of failing test names (compared by exact string match). If each cycle produces *different* failing tests (rotating failures), the stuck detector does not trigger.
>
> **Cycle termination:** The test-fix cycle terminates via stuck detection or human intervention (Phase 3 stuck recovery buttons). A hard cap on test-fix iterations is deferred — not a current build dependency.
>
> **Commit behavior:** Unlike Phase 4, the Phase 3 test-fix cycle does not commit after each cycle. A single git commit is written when Phase 3 completes successfully.

---

**[Minor]** Design spec, line 346 — Fabrication Guard condition text uses nested parentheticals that obscure the multiplier derivation.

> Current: "...AND in at least one prior iteration, every severity category was at or below twice its convergence threshold (i.e., critical ≤ 2 × `critical_max`, medium ≤ 2 × `medium_max`, minor ≤ 2 × `minor_max`). These multipliers are derived from `config.yaml` at runtime, not hardcoded."

Replacement:

> "...AND in at least one prior iteration, every severity category was at or below twice its convergence threshold — meaning critical ≤ 2 × `config.yaml` `critical_max`, medium ≤ 2 × `medium_max`, minor ≤ 2 × `minor_max`. The `2×` factor is hardcoded; the thresholds it multiplies are read from `config.yaml` at runtime."

---

**[Minor]** Design spec, lines 162-176 — The locked file behavior section switches between `constraints.md`, `spec.md`, and `intent.md` with subsection headers that don't visually separate the three files. A reader skimming for "what happens when I edit spec.md" has to parse the full block.

Replacement — add explicit sub-headers:

> **Locked File Behavior:**
>
> "Locked" means the AI pipeline will not modify these files after their creation phase. The human may still edit them manually outside the pipeline, with the following consequences:
>
> #### `constraints.md` — Hot-Reloaded
> The pipeline re-reads `constraints.md` at the start of each Phase 4 iteration. Manual human edits to acceptance criteria or review rules are picked up automatically. [remainder of current constraints.md content...]
>
> #### `spec.md` and `intent.md` — Static After Creation
> Read at Phase 3 start and used by the Phase 3 builder. Not re-read during Phase 4 iterations... [remainder of current content...]

---

**[Minor]** Execution plan, line 74 — Task 9a description contains a duplicated sentence.

> Current: "...Include context window truncation logic per build spec Chat History Truncation Algorithm: Phase 1 retains brain dump messages, Phase 2 retains initial AI proposal, Phase 3–4 truncate from beginning with no anchor. Log a warning when truncation occurs. **Include error handling: halt and notify on unreadable, missing, or invalid `chat_history.json` (same behavior as `status.json` corruption).** Include context window truncation logic per build spec Chat History Truncation Algorithm."

Replacement — remove the duplicated sentence:

> "...Include context window truncation logic per build spec Chat History Truncation Algorithm: Phase 1 retains brain dump messages, Phase 2 retains initial AI proposal, Phase 3–4 truncate from beginning with no anchor. Log a warning when truncation occurs. **Include error handling: halt and notify on unreadable, missing, or invalid `chat_history.json` (same behavior as `status.json` corruption).**"

---

**[Minor]** Design spec, line 533 — "one subprocess call per turn" is clear, but the sentence starting with "Each invocation passes the full working context" then lists context items in a parenthetical chain that spans 4 lines. Break it out for scannability.

Replacement:

> Each invocation passes the full working context:
> - The brain dump text and resources
> - Current distillation (Phase 1) or spec-in-progress (Phase 2)
> - All messages from `chat_history.json` for the current phase (subject to context window truncation)
>
> There is no persistent agent session — each turn is a stateless call with full context. This keeps the agent communication model uniform across all phases and avoids session management complexity.

---

## 2. Genuinely Missing Plan-Level Content

**[Major]** Design spec — No specification of what happens when a Phase 4 fix step produces *invalid output* (for Plan mode, where the fix agent returns the full updated plan document). The design spec covers malformed *review* JSON (Zod validation, retry, halt) but never addresses what happens when the fix agent returns a malformed, truncated, or empty plan document. For Code mode this is less critical because the fix agent writes files in-place (observable via git status), but for Plan mode the orchestrator replaces the entire plan file with the returned content — a corrupt return silently destroys the deliverable.

Proposed content — add to the Phase 4 section after "Plan mode fix interaction" (line 320):

> **Plan mode fix output validation:** After the fix agent returns the updated plan document, the orchestrator validates that the returned content is non-empty and does not have fewer characters than 50% of the pre-fix plan document. If either check fails, the fix is rejected: the pre-fix plan document is preserved (no replacement), a warning is logged, and the iteration proceeds to convergence guard evaluation using the pre-fix state. If 2 consecutive iterations produce rejected fix output, the pipeline halts and notifies the human: "Fix agent returning invalid plan content. Review needed."

---

**[Major]** Design spec / execution plan — No specification for how the **code mode fix agent determines which files to modify**. The design spec says "The fix agent operates as a coding agent with write access to the project directory. It reads the issue list, modifies the relevant source files directly, and exits." The review JSON `location` field is a string, but there's no guidance on what that string contains for code mode (file path? file:line? function name?), and no specification for how the fix agent maps locations to files. Without this, fix agent prompts will be inconsistent.

Proposed content — add to the build spec after the "Code mode fix interaction" paragraph or in the code-fix prompt spec section:

> **Code mode `location` field convention:** For Code mode review JSON, the `location` field must contain the relative file path from the project root, optionally followed by `:line_number` (e.g., `src/server.ts:42`). The fix prompt (`code-fix.md`) instructs the fix agent to use these paths to locate and modify the relevant files. The reviewer prompt (`code-review.md`) instructs the reviewer to produce `location` values in this format. The orchestrator does not parse or validate `location` — it is a convention enforced by prompts, not code.

---

**[Minor]** Design spec — No specification for what happens when the human provides input during Phase 1 or Phase 2 while the AI is actively processing a prior turn (e.g., human sends a correction while distillation is still streaming). The design covers mid-stream *project switching* but not mid-stream *input within the same project*.

Proposed content — add to Phase 1 behavior or the UI section:

> **Mid-Processing Human Input:** If the human sends a chat message while the AI is processing a prior turn (e.g., typing a correction while distillation is streaming), the message is queued in `chat_history.json` and included in the next AI invocation's context. It does not interrupt the current processing. The chat input field remains active during AI processing to allow the human to queue messages.

---

**[Minor]** Execution plan — The critical path identifies the longest dependency chain but does not note which tasks can be parallelized within each stage. Lines 52 and 207 mention parallelism opportunities (Stages 1 and 7 can run in parallel), but the plan lacks a concise parallelism summary. For a builder managing task assignment, this matters.

Proposed content — add after the Critical Path section:

> ## Parallelism Opportunities
>
> The following task groups can be executed concurrently:
> - **After Task 1:** Stage 1 foundation (Tasks 2–6a, 3a, 4–5) and Stage 7 agent layer (Tasks 41–44) — no cross-dependencies
> - **After Tasks 41–42:** All prompt drafting tasks (7a, 7f, 6e, 15a, 21a, 30a, 30b) — depend only on Task 7a
> - **After Task 6:** Stage 3 (Tasks 14–18) and Stage 4 (Tasks 20, 22–25) — independent plugin implementations
> - **After Task 26:** Task 27 (VK operations) and Task 29a (VK-disabled fallback) — independent paths
> - **Stage 8 unit tests:** All unit test tasks within a stage are independent and can run in parallel once their source tasks complete

---

**[Minor]** Execution plan — No mention of development environment requirements beyond Node.js ≥18 and agent CLIs. A builder starting from scratch would benefit from knowing: does the project use ESM or CJS modules? What's the tsconfig target? The execution plan's Design Decisions section mentions TypeScript and tsx but doesn't state the module system.

Proposed content — add to the Design Decisions section:

> **Module system:** ESM (`"type": "module"` in `package.json`). All imports use ESM `import` syntax. `tsconfig.json` uses `"module": "nodenext"` and `"moduleResolution": "nodenext"`. This aligns with Vitest's native ESM support and Node.js ≥18's stable ESM implementation.

---

## 3. Build Spec Material That Should Be Extracted

**[Minor]** Design spec, line 67-69 — Project ID collision retry logic ("If the generated project directory already exists... generate a new random suffix and retry. If the directory still exists after 3 retries, halt with error") is implementation-level detail. The plan-level concern is "project IDs must be unique." The retry algorithm and error message belong in the build spec's Project Initialization Sequence section.

---

**[Minor]** Design spec, line 424 — The Realign Algorithm steps (scan backwards through chat history, context truncation, re-distillation scope, no-correction guard) are already duplicated in the build spec's Realign Algorithm section. The design spec should reference the build spec rather than reproducing the procedural steps.

Current (design spec line 95): "Human can type 'realign from here' in chat. Unlike phase advancement actions (which use buttons), this is a chat-parsed command that excludes messages after the most recent substantive human correction from the working context and re-distills."

This is the appropriate level of detail for the design spec. However, it then goes on to say "Excluded messages are retained in `chat_history.json` for audit trail but not passed to the AI. Matching rules and algorithm in build spec." — which is correctly pointing to the build spec. This is fine as-is. No extraction needed here upon closer reading.

Let me replace this finding: The Project ID collision retry logic (line 67-69) is the only genuine extraction candidate.

---

**[Minor]** Design spec, lines 169 — The `constraints.md` truncation strategy (which sections to remove, in what order, to fit context window) is implementation-level detail. The plan-level concern is "if constraints.md exceeds context, truncate with priority given to Context/Deliverable Type and Acceptance Criteria sections." The specific removal order belongs in the build spec.

---

**[Minor]** Design spec, line 523-531 — Token estimation formula, `PlanBuilderResponse` validation flow (retry once, halt on second failure), and the explicit listing of which phases use natural language vs. structured JSON are implementation details. The plan-level concern is "agent responses are validated where schemas exist; phases 1-2 use natural language reviewed by the human." The retry counts and per-phase response format classification belong in the build spec.

---

That completes the review. Three findings at Major severity, the remainder Minor. No Critical issues found — the plan is buildable as-is and the three documents are well cross-referenced. The design spec is notably thorough in its error handling coverage.
