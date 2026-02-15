# Apply Review Findings

Apply every change listed below to the source files. Each change includes the target file, the location, and the exact replacement or addition. Do not interpret or improvise — apply as written.

---

## Source files

- **Design spec:** `docs/thoughtforge-design-specification.md`
- **Build spec:** `docs/thoughtforge-build-spec.md`
- **Execution plan:** `docs/thoughtforge-execution-plan.md`

Read ALL three files before making any edits.

---

## Changes to Apply

### 1. [Minor] Design spec, ~line 345 — Stagnation Guard clarity

Find the Stagnation Guard condition text containing:

> "Same total error count for a configured number of consecutive iterations (stagnation limit), AND issue rotation is detected when fewer than 70% of current-iteration issues can be matched (Levenshtein similarity ≥ 0.8 on `description`) to any issue in the immediately prior iteration — meaning more than 30% of issues are new, indicating the reviewer is cycling rather than converging."

Replace with:

> "Two conditions must both be true: (1) **Plateau:** Total error count is identical for `stagnation_limit` consecutive iterations. (2) **Issue rotation:** Fewer than 70% of current-iteration issues match any issue in the immediately prior iteration (match = Levenshtein similarity ≥ 0.8 on `description`). When both are true, the reviewer is cycling through new cosmetic issues at the same rate old ones are resolved — a quality plateau, not genuine regression."

---

### 2. [Minor] Design spec, ~line 242 — Phase 3 Code mode test-fix cycle restructure

Find the Phase 3 Code mode test-fix cycle paragraph (approximately 15 lines of unbroken prose covering cycle behavior, stuck detection, non-triggering rotation failures, and deferred hard cap).

Replace with the following sub-sectioned structure:

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

### 3. [Minor] Design spec, ~line 346 — Fabrication Guard nested parentheticals

Find the Fabrication Guard condition text containing:

> "...AND in at least one prior iteration, every severity category was at or below twice its convergence threshold (i.e., critical ≤ 2 × `critical_max`, medium ≤ 2 × `medium_max`, minor ≤ 2 × `minor_max`). These multipliers are derived from `config.yaml` at runtime, not hardcoded."

Replace with:

> "...AND in at least one prior iteration, every severity category was at or below twice its convergence threshold — meaning critical ≤ 2 × `config.yaml` `critical_max`, medium ≤ 2 × `medium_max`, minor ≤ 2 × `minor_max`. The `2×` factor is hardcoded; the thresholds it multiplies are read from `config.yaml` at runtime."

---

### 4. [Minor] Design spec, ~lines 162-176 — Locked file behavior sub-headers

Find the locked file behavior section that switches between `constraints.md`, `spec.md`, and `intent.md` without clear visual separation.

Restructure with explicit sub-headers:

> **Locked File Behavior:**
>
> "Locked" means the AI pipeline will not modify these files after their creation phase. The human may still edit them manually outside the pipeline, with the following consequences:
>
> #### `constraints.md` — Hot-Reloaded
> The pipeline re-reads `constraints.md` at the start of each Phase 4 iteration. Manual human edits to acceptance criteria or review rules are picked up automatically. [keep remainder of current constraints.md content]
>
> #### `spec.md` and `intent.md` — Static After Creation
> Read at Phase 3 start and used by the Phase 3 builder. Not re-read during Phase 4 iterations... [keep remainder of current content]

---

### 5. [Minor] Execution plan, ~line 74 — Task 9a duplicated sentence

Find in Task 9a description:

> "...Include context window truncation logic per build spec Chat History Truncation Algorithm: Phase 1 retains brain dump messages, Phase 2 retains initial AI proposal, Phase 3–4 truncate from beginning with no anchor. Log a warning when truncation occurs. **Include error handling: halt and notify on unreadable, missing, or invalid `chat_history.json` (same behavior as `status.json` corruption).** Include context window truncation logic per build spec Chat History Truncation Algorithm."

Remove the duplicated trailing sentence so it ends after the bold error handling sentence:

> "...Include context window truncation logic per build spec Chat History Truncation Algorithm: Phase 1 retains brain dump messages, Phase 2 retains initial AI proposal, Phase 3–4 truncate from beginning with no anchor. Log a warning when truncation occurs. **Include error handling: halt and notify on unreadable, missing, or invalid `chat_history.json` (same behavior as `status.json` corruption).**"

---

### 6. [Minor] Design spec, ~line 533 — Subprocess context list scannability

Find the sentence starting with "Each invocation passes the full working context" that lists context items in a parenthetical chain spanning ~4 lines.

Replace with:

> Each invocation passes the full working context:
> - The brain dump text and resources
> - Current distillation (Phase 1) or spec-in-progress (Phase 2)
> - All messages from `chat_history.json` for the current phase (subject to context window truncation)
>
> There is no persistent agent session — each turn is a stateless call with full context. This keeps the agent communication model uniform across all phases and avoids session management complexity.

---

### 7. [Major] Design spec — Add Plan mode fix output validation

After the "Plan mode fix interaction" content (~line 320), add this new section:

> **Plan mode fix output validation:** After the fix agent returns the updated plan document, the orchestrator validates that the returned content is non-empty and does not have fewer characters than 50% of the pre-fix plan document. If either check fails, the fix is rejected: the pre-fix plan document is preserved (no replacement), a warning is logged, and the iteration proceeds to convergence guard evaluation using the pre-fix state. If 2 consecutive iterations produce rejected fix output, the pipeline halts and notifies the human: "Fix agent returning invalid plan content. Review needed."

---

### 8. [Major] Design spec or Build spec — Add Code mode location field convention

After the "Code mode fix interaction" paragraph (or in the code-fix prompt spec section of the build spec), add:

> **Code mode `location` field convention:** For Code mode review JSON, the `location` field must contain the relative file path from the project root, optionally followed by `:line_number` (e.g., `src/server.ts:42`). The fix prompt (`code-fix.md`) instructs the fix agent to use these paths to locate and modify the relevant files. The reviewer prompt (`code-review.md`) instructs the reviewer to produce `location` values in this format. The orchestrator does not parse or validate `location` — it is a convention enforced by prompts, not code.

---

### 9. [Minor] Design spec — Add mid-processing human input behavior

Add to the Phase 1 behavior section or the UI section:

> **Mid-Processing Human Input:** If the human sends a chat message while the AI is processing a prior turn (e.g., typing a correction while distillation is streaming), the message is queued in `chat_history.json` and included in the next AI invocation's context. It does not interrupt the current processing. The chat input field remains active during AI processing to allow the human to queue messages.

---

### 10. [Minor] Execution plan — Add parallelism opportunities section

Add after the Critical Path section:

> ## Parallelism Opportunities
>
> The following task groups can be executed concurrently:
> - **After Task 1:** Stage 1 foundation (Tasks 2–6a, 3a, 4–5) and Stage 7 agent layer (Tasks 41–44) — no cross-dependencies
> - **After Tasks 41–42:** All prompt drafting tasks (7a, 7f, 6e, 15a, 21a, 30a, 30b) — depend only on Task 7a
> - **After Task 6:** Stage 3 (Tasks 14–18) and Stage 4 (Tasks 20, 22–25) — independent plugin implementations
> - **After Task 26:** Task 27 (VK operations) and Task 29a (VK-disabled fallback) — independent paths
> - **Stage 8 unit tests:** All unit test tasks within a stage are independent and can run in parallel once their source tasks complete

---

### 11. [Minor] Execution plan — Add module system to Design Decisions

Add to the Design Decisions section:

> **Module system:** ESM (`"type": "module"` in `package.json`). All imports use ESM `import` syntax. `tsconfig.json` uses `"module": "nodenext"` and `"moduleResolution": "nodenext"`. This aligns with Vitest's native ESM support and Node.js ≥18's stable ESM implementation.

---

### 12. [Minor] Design spec, ~lines 67-69 — Extract Project ID collision retry logic to build spec

In the design spec, find the Project ID collision retry logic:

> "If the generated project directory already exists... generate a new random suffix and retry. If the directory still exists after 3 retries, halt with error"

Replace in the design spec with a brief reference: "Project IDs must be unique; collision retry algorithm is specified in the build spec."

Then add the full retry logic text (removed from the design spec) to the build spec's Project Initialization Sequence section.

---

### 13. [Minor] Design spec, ~line 169 — Extract constraints.md truncation strategy to build spec

Find the `constraints.md` truncation strategy details (which sections to remove, in what order, to fit context window).

Replace in the design spec with: "If `constraints.md` exceeds the context window, it is truncated with priority given to Context/Deliverable Type and Acceptance Criteria sections. Truncation order is specified in the build spec."

Move the specific removal order details to the build spec.

---

### 14. [Minor] Design spec, ~lines 523-531 — Extract token estimation and validation details to build spec

Find the token estimation formula, `PlanBuilderResponse` validation flow (retry once, halt on second failure), and per-phase response format listing.

Replace in the design spec with: "Agent responses are validated where schemas exist; phases 1–2 use natural language reviewed by the human. Validation details, retry counts, and token estimation formula are specified in the build spec."

Move the removed implementation details to the appropriate build spec section.

---

## After All Changes Are Applied

1. Re-read each modified file to verify no formatting was broken and all changes landed correctly.
2. Git commit and sync:

```bash
git status -u
git diff --stat
git add docs/thoughtforge-design-specification.md docs/thoughtforge-build-spec.md docs/thoughtforge-execution-plan.md
git commit -m "Apply review findings"
git push
git pull
```
