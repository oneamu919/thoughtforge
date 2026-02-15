Now I have all four documents in full. Let me conduct the review.

---

# ThoughtForge Plan Review — Findings

## 1. Writing That's Unclear

**[Minor] Design spec, Phase 4 Convergence Guards — Fix Regression guard listed in table but never referenced in Guard Evaluation Order**

The design spec's convergence guard table (Phase 4) includes a "Fix Regression (per-iteration)" guard, but the build spec's Guard Evaluation Order section lists only five guards: Termination, Hallucination, Fabrication, Stagnation, Max Iterations. The fix regression guard is described as firing "before the trend-based guards" in the design spec table, but it does not appear in the ordered evaluation list. The completion checklist says "All 5 convergence guards" — confirming only 5, not 6.

**Replacement text** for build spec Guard Evaluation Order section, after the introductory paragraph:

> Guards are evaluated in the following order after each iteration. The first guard that triggers ends evaluation — subsequent guards are not checked.
>
> 0. **Fix Regression** (per-iteration) — checked first, immediately after each fix step. If total error count increased compared to the review that prompted the fix, log a warning. If 2 consecutive iterations show fix-step regression, halt and notify. This guard runs before the convergence guards below.
> 1. **Termination** (success) — checked first among convergence guards so that a successful outcome is never overridden by a halt
> 2. **Hallucination** — [rest unchanged]

Also update the completion checklist from "All 5 convergence guards" to "All 6 convergence guards" (or explicitly state that Fix Regression is a per-iteration check distinct from the 5 convergence guards, and name it separately in the checklist).

---

**[Minor] Design spec, Phase 2 — "AI evaluates intent.md for issues including but not limited to" merges two distinct behaviors without clear separation**

Step 2 describes the AI challenging intent decisions, and step 3 describes resolving Unknowns/Open Questions. But step 2 uses "including but not limited to" with a long list that blurs into step 3's territory (e.g., "unvalidated assumptions" vs. "Unknowns"). A builder reading this will wonder whether step 2 is a superset of step 3.

**Replacement text** for steps 2–3:

> 2. **Challenge:** AI evaluates `intent.md` for structural issues: missing dependencies, unrealistic constraints, scope gaps, internal contradictions, and ambiguous priorities. Each flagged issue is presented to the human with specific reasoning. The AI does not rubber-stamp — it must surface concerns even if the human's intent seems clear. This step does not resolve Unknowns — it identifies new problems.
> 3. **Resolve:** AI resolves Unknowns and Open Questions from `intent.md` — either by making a reasoned decision (stated in `spec.md`) or by asking the human during the Phase 2 chat. [rest unchanged]

---

**[Minor] Design spec, Stagnation guard — "same rate" is imprecise**

The stagnation guard description says "old issues resolved, new issues introduced at the same rate." The build spec clarifies with the 70%/Levenshtein threshold, but the design spec language creates ambiguity for a reader who starts there. Since the design spec is the primary document, it should match the precision of the build spec.

**Replacement text** in design spec stagnation guard row:

> Same total error count for a configured number of consecutive iterations (stagnation limit), AND issue rotation detected (fewer than 70% of current issues match prior iteration issues by Levenshtein similarity ≥ 0.8 on description). When both conditions are true, the deliverable has reached a quality plateau. Parameters in build spec.

---

**[Minor] Build spec, Code Builder Task Queue — contradictory guidance on persistence**

The section says "The task list format and derivation logic are internal to the code builder and are not persisted to state files" but the preceding paragraph says "If determinism cannot be guaranteed, the code builder should persist the derived task list to `task_queue.json`." These two statements conflict.

**Replacement text** — merge into a single paragraph:

> The code builder maintains an ordered list of build tasks derived from `spec.md`. Each task has a string identifier used for stuck detection. On crash recovery, the code builder attempts to re-derive the task list from `spec.md` and the current state of files in the project directory. If the re-derived task list differs from the pre-crash list (non-deterministic ordering), the code builder persists the initial task list to `task_queue.json` in the project directory at derivation time, and uses the persisted list for crash recovery. Whether to persist is a Task 21 implementation decision — but crash recovery must produce a compatible task ordering.

---

**[Minor] Design spec, config.yaml `phase3_completeness` — `code_require_tests` threshold is boolean, not a quantitative threshold**

The design spec says the Phase 3→4 transition verifies outputs "meet `config.yaml` `phase3_completeness` thresholds" (plural), but for code mode the only check is a boolean `code_require_tests: true`. The word "thresholds" implies numeric criteria. Meanwhile there's no minimum source file count or line count for code mode — only the plan mode has `plan_min_chars`.

**Replacement text** in design spec Phase 3→4 Transition Error Handling:

> verify expected output files exist and meet `config.yaml` `phase3_completeness` criteria before entering Phase 4

(Change "thresholds" to "criteria" — a minor wording fix that matches the actual config structure, where one criterion is numeric and one is boolean.)

---

**[Minor] Execution plan, Critical Path — chain includes Task 15 between Tasks 13 and 30, but Task 30's "Depends On" does not list Task 15**

The critical path reads: `...Task 13 → Task 15 → Task 30 → ...`. But Task 30's dependency column lists `Task 3, Task 6a, Task 6c, Task 17, Task 22, Tasks 30a–30b, Tasks 41–42`. Task 15 (plan builder) is not a dependency of Task 30 (polish loop). The critical path should show the actual longest chain.

**Replacement text:**

> **Task 1 → Task 41 → Task 42 → Task 6a → Task 8 → Task 9 → Task 11 → Task 12 → Task 13 → Task 6c → Task 30 → Tasks 33–37 → Task 51**
>
> Note: Task 15 (plan builder) is not on the critical path — it runs in parallel with the Phase 1–2 human interaction chain and must complete before Task 51 (e2e test), but it does not gate Task 30. Task 30 depends on Task 6c (Phase 3→4 transition), which depends on Tasks 5, 6a, and 7. Task 6c is the critical dependency entering the polish loop.

---

## 2. Genuinely Missing Plan-Level Content

**[Major] No `package.json` dependency list or dependency management strategy**

The plan references specific npm packages by name (Zod, Handlebars, Express, ws, pdf-parse) and implies TypeScript compilation (tsc), but no document lists the expected `package.json` dependencies or addresses dependency management (lock files, version pinning, audit). A builder starting Task 1 has to guess the initial dependency set.

**Proposed content** — add to build spec after the Build Toolchain section:

> ## Initial Dependencies
>
> **Used by:** Task 1 (project initialization)
>
> ```json
> {
>   "dependencies": {
>     "express": "^4.x",
>     "ws": "^8.x",
>     "zod": "^3.x",
>     "handlebars": "^4.x",
>     "yaml": "^2.x",
>     "pdf-parse": "^1.x"
>   },
>   "devDependencies": {
>     "typescript": "^5.x",
>     "vitest": "^1.x"
>   }
> }
> ```
>
> Use `package-lock.json` for deterministic installs. Pin major versions. Run `npm audit` before v1 release.

---

**[Major] No definition of "context window" size or how ThoughtForge determines it per agent**

The plan references context window limits in multiple places (chat history truncation, template overflow, large codebase review, brain dump overflow) but never defines how ThoughtForge knows the context window size for the configured agent. Is it hardcoded per agent? Configured in `config.yaml`? Queried at runtime?

**Proposed content** — add to `config.yaml` template under the `agents.available` section:

> ```yaml
>     claude:
>       command: "claude"
>       flags: "--print"
>       supports_vision: true
>       context_window_tokens: 200000
>     gemini:
>       command: "gemini"
>       flags: ""
>       supports_vision: true
>       context_window_tokens: 1000000
>     codex:
>       command: "codex"
>       flags: ""
>       supports_vision: false
>       context_window_tokens: 200000
> ```

Add to design spec Agent Communication section:

> **Context window awareness:** Each agent's context window size is configured in `config.yaml` `agents.available.{agent}.context_window_tokens`. ThoughtForge uses this value to determine when to truncate chat history, plan builder context, and code review context. The token count is an approximation — ThoughtForge estimates tokens as `character_count / 4` (a standard rough heuristic). Exact tokenization is agent-specific and not worth the complexity for truncation decisions.

---

**[Major] No error handling for graceful shutdown with multiple concurrent projects**

The design spec defines graceful shutdown for a single in-progress agent subprocess, but with `max_parallel_runs: 3`, multiple projects could have active subprocesses. The shutdown behavior doesn't address whether all subprocesses are waited on, or just one.

**Proposed content** — replace the Graceful Shutdown paragraph in the design spec:

> **Graceful Shutdown:** On `SIGTERM` or `SIGINT`, the server stops accepting new operations and waits for all in-progress agent subprocesses to complete (up to the configured `agents.call_timeout_seconds`). Each project's subprocess is handled independently: if a subprocess completes within the timeout, its iteration state is written normally. If the timeout expires for any subprocess, that subprocess is killed and its current iteration is abandoned (no state written). After all subprocesses have either completed or been killed, the server exits. On next startup, the standard Server Restart Behavior applies to each project independently.

---

**[Minor] No explicit statement of what HTTP endpoints the Express server exposes**

The chat interface uses WebSocket and HTTP (settings UI, file upload), but no document lists the expected routes. A builder starting Task 1a/7 has to infer the API surface.

**Proposed content** — add to build spec after WebSocket Reconnection Parameters:

> ## HTTP API Surface
>
> **Used by:** Tasks 1a, 7, 7b, 7g, 7h (server, chat interface, settings, sidebar, file upload)
>
> | Method | Path | Purpose |
> |---|---|---|
> | GET | `/` | Serve chat interface HTML |
> | GET | `/api/projects` | List all projects with current status |
> | POST | `/api/projects` | Create new project |
> | GET | `/api/projects/:id/status` | Get project `status.json` |
> | GET | `/api/projects/:id/chat` | Get project `chat_history.json` |
> | POST | `/api/projects/:id/action` | Trigger button action (distill, confirm, resume, override, terminate, provide-input) |
> | POST | `/api/projects/:id/upload` | Upload resource file to `/resources/` |
> | GET | `/api/prompts` | List prompt files |
> | GET | `/api/prompts/:filename` | Read prompt file content |
> | PUT | `/api/prompts/:filename` | Save prompt file content |
> | WS | `/ws` | WebSocket for real-time chat streaming |
>
> Route structure is a build-time implementation detail — the above is guidance, not a rigid contract. The key requirement is that all project mutations go through the orchestrator (never direct file writes from HTTP handlers).

---

**[Minor] No mention of CORS policy or static file serving strategy for the chat UI**

The server is Express-based serving a single-page HTML app. Since it binds to localhost, CORS is likely a non-issue, but the plan doesn't confirm this or state the static file serving approach.

**Proposed content** — add a one-liner to the design spec under Chat UI (Frontend):

> Static assets (HTML, CSS, JS) are served directly by Express from a `/public/` directory. No CORS configuration is needed — the browser loads assets from the same origin as the WebSocket connection.

---

**[Minor] No definition of what `plan/discovery.js` does for plan mode (if anything)**

The plugin folder structure shows `discovery.js` in the plan plugin directory, and the interface contract says "Plan plugin may omit this file." But the plan plugin folder structure listing includes it. This creates ambiguity — should it exist or not?

**Proposed content** — remove `discovery.js` from the plan plugin folder structure in the build spec, since the interface contract already says it's optional and no plan-mode discovery behavior is defined anywhere:

Replace the plan plugin folder listing with:

> ```
> /plugins/
>   plan/
>     builder.js
>     reviewer.js
>     safety-rules.js
>     templates/
>       generic.hbs
>       wedding.hbs
>       strategy.hbs
>       engineering.hbs
> ```

---

## 3. Build Spec Material That Should Be Extracted

**[Minor] Design spec, Phase 1 — Brain dump intake prompt text (full prompt embedded)**

The design spec Phase 1 section includes the complete text of the brain dump intake system prompt ("You are receiving a raw brain dump from a human..."). This is implementation-level prompt text that belongs in the build spec (where it already has a corresponding section) and ultimately in `/prompts/brain-dump-intake.md`. The design spec should reference the prompt's behavioral requirements without embedding the full text.

**Why it belongs in the build spec:** The build spec already has a "Phase 1 System Prompt — Brain Dump Intake" section with the full prompt. The design spec's role is to specify the *behavior* the prompt must achieve (6-section structure, no AI suggestions, max 5 questions), which it already does in the "Brain Dump Intake Prompt Behavior" paragraph. The embedded prompt text is redundant with the build spec.

**Recommendation:** Replace the embedded prompt block in the design spec with a reference:

> Full prompt text is specified in the build spec under "Phase 1 System Prompt — Brain Dump Intake."

---

**[Minor] Design spec, Action Button Behavior — the full button inventory table with `status.json` effects**

The design spec says "Complete button inventory with `status.json` effects and UI behavior is specified in the build spec" and then the build spec contains the authoritative table. However, the design spec also includes scattered button descriptions throughout Phase 1, Phase 3, and Phase 4 sections that partially duplicate the build spec table (e.g., "Distill button signals that all inputs are provided," Phase 3 stuck recovery button descriptions). These inline descriptions are fine as behavioral context, but the design spec should avoid stating `status.json` field-level effects inline — those details are build spec material.

**Why it belongs in the build spec:** The design spec already correctly delegates the full button inventory to the build spec. The issue is that inline descriptions in the design spec sometimes specify `status.json` field values (e.g., "`halt_reason: "human_terminated"`"), creating two sources of truth. These field-level details should be in the build spec only.

**Recommendation:** No extraction needed — the build spec already has the table. But flag this to the builder: the build spec Action Button Behavior table is the single source of truth for `status.json` effects. If inline design spec descriptions conflict with the table, the table wins.

---

**[Minor] Build spec, `status.json` Schema — `halt_reason` known values list is implementation detail**

The `halt_reason` field in the `status.json` schema includes a comment listing all known values: `"plan_incomplete"`, `"guard_hallucination"`, `"guard_fabrication"`, `"guard_max_iterations"`, `"human_terminated"`, `"agent_failure"`, `"file_system_error"`, `"phase3_output_missing"`, `"phase3_output_incomplete"`, `"server_restart"`. This is appropriate for the build spec. However, the list is missing `"fix_regression"` (from the Fix Regression convergence guard in the design spec) and `"guard_stagnation"` is absent (stagnation is a success, not a halt — this is correct). Verify the list is exhaustive.

**Proposed addition** to the `halt_reason` comment in the build spec:

> Add `"fix_regression"` to the known values list (triggered by the Fix Regression per-iteration guard when 2 consecutive fix steps increase error count).

---

That concludes the review. Three lists, findings sorted by severity within each.
