Now I have all four documents. Let me process this comprehensive review. Given the volume and complexity, I'll work through the three documents systematically.

---

# Project Plan Review — ThoughtForge Pipeline Tool

**Documents reviewed:** Design Specification, Build Spec, Execution Plan

---

## 1. Writing That's Unclear

**[Minor]** Design Spec, Phase 1 Step 3 — "Connector URL Identification" paragraph is a wall of logic that mixes three behaviors in one sentence.

**Current text (line 82):**
> "URLs matching an enabled connector pattern are pulled automatically. URLs matching a disabled connector pattern are ignored. Unrecognized URLs are treated as regular brain dump text."

**Replacement:**
> "The AI matches each URL against the known patterns for enabled connectors:
> - **Match + enabled:** URL is pulled automatically via the connector.
> - **Match + disabled:** URL is silently ignored (not pulled, not treated as text).
> - **No match:** URL is treated as regular brain dump text and included in distillation context."

---

**[Minor]** Design Spec, Stagnation Guard description (line 334) — the parenthetical about severity composition shift is buried mid-sentence and easy to misread.

**Current text (partial):**
> "The comparison uses total count only — a shift in severity composition at the same total still qualifies as stagnation if the rotation threshold is also met."

**Replacement:**
> "Stagnation compares total error count only, not per-severity breakdowns. A shift in severity composition (e.g., fewer criticals but more minors) at the same total still qualifies as stagnation, provided the rotation threshold is also met."

---

**[Minor]** Design Spec, Fabrication Guard (line 335) — the phrase "specifically: critical ≤ 0 (2 × 0), medium ≤ 6 (2 × 3), minor ≤ 10 (2 × 5) using default config values" is hardcoded math embedded in a behavioral description. A builder reading this needs to know whether these are literal constants or derived from config.

**Replacement:**
> "...every severity category was at or below twice its convergence threshold — that is, critical ≤ 2 × `critical_max`, medium ≤ 2 × `medium_max`, minor ≤ 2 × `minor_max` (using default config: ≤0 critical, ≤6 medium, ≤10 minor). These values are derived from `config.yaml` at runtime, not hardcoded."

---

**[Minor]** Design Spec, Phase 3 Code Builder Interaction Model (line 237) — the sentence about stuck detection has a parenthetical exception about "rotating failures" that contradicts the preceding sentence without enough explanation.

**Current text:**
> "Since each cycle produces different failing tests, the stuck detector will not trigger on rotating failures."

**Replacement:**
> "If each test-fix cycle produces *different* failing tests (rotating failures rather than the same tests failing repeatedly), the stuck detector does not trigger — it only fires on 3 consecutive cycles with the *identical* set of failing test names."

---

**[Minor]** Design Spec, Locked File Behavior section (line 166) — the phrase "the in-memory copies are lost" is ambiguous about what "in-memory copies" refers to, since no prior sentence establishes that ThoughtForge caches these files in memory.

**Current text:**
> "On server restart, the in-memory copies are lost."

**Replacement:**
> "On server restart, the orchestrator's in-memory working copies of `spec.md` and `intent.md` (loaded at Phase 3 start) are discarded."

---

**[Minor]** Execution Plan, Critical Path (line 192) — the path lists Task 15 → Task 16 → Task 30 but Task 30 depends on Task 17 (reviewer.js), not Task 16 (templates). The critical path description is inaccurate.

**Current text:**
> "Task 1 → Task 41 → Task 42 → Task 6a → Task 8 → Task 9 → Task 11 → Task 12 → Task 13 → Task 15 → Task 16 → Task 30 → Tasks 33–37 → Task 51"

**Replacement:**
> "Task 1 → Task 41 → Task 42 → Task 6a → Task 8 → Task 9 → Task 11 → Task 12 → Task 13 → Task 15 → Task 30 → Tasks 33–37 → Task 51
>
> Note: Task 30 depends on Task 17 (plan reviewer) and Task 6c (Phase 3→4 transition), not Task 16 (templates). Task 16 (templates) feeds Task 15 at runtime but is not on the critical path — templates can be created after the builder module. Task 17 runs in parallel with Task 15 and must complete before Task 30."

---

**[Minor]** Build Spec, Code Builder Task Queue section (line 208) — "The exact parsing and ordering logic is an implementation detail of Task 21, but must produce a deterministic task list from the same `spec.md` input" sets a requirement (deterministic output) without explaining *why* determinism matters.

**Replacement:**
> "The exact parsing and ordering logic is an implementation detail of Task 21, but must produce a deterministic task list from the same `spec.md` input — this ensures crash recovery (re-deriving the task list after restart) produces the same task ordering and can correctly identify which tasks were already completed."

---

**[Minor]** Design Spec, Hallucination Guard description (line 333) — the notification message template says "Errors trending down then spiked" but the guard condition allows a trend of only 2 iterations, which is barely a trend. A builder might question whether 2 is truly "trending down."

**Replacement for the notification template only:**
> `"Project '{name}' — fix-regress cycle detected. Errors decreased for {N} iterations ({trajectory}) then spiked to {X} at iteration {current}. Review needed."`

This replaces the narrative with data, avoiding the "trending" characterization for short trends.

---

## 2. Genuinely Missing Plan-Level Content

**[Critical]** Design Spec — No error handling for Phase 2 Confirm button when `constraints.md` Acceptance Criteria section is empty at confirmation time. The spec says "5–10 acceptance criteria" in the constraints structure and that Phase 4 uses these for review, but nothing prevents Phase 2 from completing with zero acceptance criteria. The "unvalidated after creation" policy applies *after* Phase 2 write, but the initial write should enforce a minimum.

**Proposed addition** (Design Spec, Phase 2, step 7, after the Unknowns validation gate):

> **Acceptance Criteria Validation Gate:** Before Phase 2 Confirm advances to Phase 3, the orchestrator validates that the Acceptance Criteria section of the proposed `constraints.md` contains at least 1 criterion. If the section is empty, the Confirm button is blocked and the AI prompts the human: "At least one acceptance criterion is required before proceeding. Add acceptance criteria or confirm the AI's proposed set." This gate enforces the minimum at creation time only — after `constraints.md` is written, the human may freely edit it (including emptying the section) per the unvalidated-after-creation policy.

---

**[Major]** Design Spec / Execution Plan — No specification for what happens when the Vibe Kanban toggle is changed in `config.yaml` while projects are in progress. If an operator starts a project with VK enabled, then disables VK mid-project, the adapter will fail on status updates for a card that exists. Conversely, enabling VK mid-project means the card was never created.

**Proposed addition** (Design Spec, Vibe Kanban Integration Interface section, after the toggle behavior table):

> **Toggle Change During Active Projects:** The `vibekanban.enabled` toggle is read at each operation, not cached at project creation. If VK is disabled after a project was created with VK enabled, subsequent VK status update calls will succeed (updating an existing card) but new project creation will skip card creation. If VK is enabled after a project was created without it, VK status calls will fail (no card exists) and will be logged and ignored per standard VK failure handling. Toggling VK mid-project does not halt or disrupt the pipeline — VK calls are never on the critical path.

---

**[Major]** Design Spec — No specification for handling a `polish_state.json` that is unreadable, missing, or invalid at the start of a Phase 4 resume. The design spec covers `status.json` corruption exhaustively ("halt and notify") and `chat_history.json` ("halt and notify"), but `polish_state.json` corruption handling is only implied by the crash recovery mention.

**Proposed addition** (Design Spec, Phase 4 Error Handling table):

> | `polish_state.json` unreadable, missing, or invalid at Phase 4 resume | Halt and notify the operator with the file path and the specific error (parse failure, missing file, invalid schema). Do not attempt recovery or partial loading — the operator must fix or recreate the file. Same behavior as `status.json` and `chat_history.json` corruption handling. |

---

**[Major]** Design Spec / Build Spec — No specification for how the code builder's `test-runner.js` determines *which* test command to run. The build spec says "The `test-runner.js` module executes tests using the framework specified in `spec.md`" but doesn't explain how `test-runner.js` extracts or receives the test command from `spec.md`. This is a plan-level gap — the builder needs to know the contract between spec.md content and test execution.

**Proposed addition** (Design Spec, Phase 3 Code Mode, after the test framework selection paragraph):

> **Test Command Discovery:** The code builder's `test-runner.js` does not parse `spec.md` to discover the test command. Instead, the coding agent is instructed (via the `/prompts/code-build.md` prompt) to create a standard `npm test` script in the project's `package.json` (or the language-equivalent test entry point). `test-runner.js` always invokes the project's standard test entry point (`npm test` for Node.js projects). The specific test framework is an implementation detail of the deliverable codebase, not of ThoughtForge's `test-runner.js`. If the test command exits non-zero, `test-runner.js` treats it as test failures and captures stdout/stderr as the `details` field.

---

**[Major]** Execution Plan — No task for implementing the Phase 1 connector URL identification behavior described in Design Spec Phase 1 step 3 ("The AI identifies connector URLs in chat messages by matching against known URL patterns for each enabled connector"). Task 8 mentions "Connector integration (Task 7c) is optional" but doesn't cover the URL-matching behavior in chat messages. Task 7c covers the abstraction layer but not the chat-message URL scanning.

**Proposed addition** (Execution Plan, Build Stage 2, after Task 8):

> | 8a | Implement chat-message URL scanning for resource connectors: match URLs in brain dump chat messages against enabled connector URL patterns (from build spec), auto-pull matched URLs via connector layer, ignore matches for disabled connectors, pass unmatched URLs through as brain dump text | — | Task 8, Task 7c | — | Not Started |

---

**[Minor]** Execution Plan — No task for implementing the deliverable type ambiguity handling from Design Spec ("If the brain dump contains signals for both Plan and Code, the AI defaults to Plan and flags the ambiguity in the Open Questions section"). This is prompt-level behavior but the execution plan doesn't reference it in Task 8 or Task 11.

**Proposed addition** (Execution Plan, Task 8 description, append):

> "Include ambiguous deliverable type handling per design spec: when brain dump signals both Plan and Code, AI defaults to Plan and flags in Open Questions."

---

**[Minor]** Design Spec — No specification for what happens when the human clicks "New Project" in the sidebar while a chat thread is active and the AI is mid-response (streaming). Does the current stream abort? Does the new project open in a separate panel?

**Proposed addition** (Design Spec, UI section, after the project list sidebar description):

> **Mid-Stream Project Switch:** If the human switches projects while an AI response is streaming, the client stops rendering the stream for the previous project's chat. Server-side processing continues uninterrupted — the AI response completes and is persisted to `chat_history.json` regardless of client-side display state. When the human returns to the project, the completed response is visible in the chat history.

---

**[Minor]** Execution Plan — No task for implementing the Phase 3→4 milestone notification ("Phase 3 complete. Deliverable built. Polish loop starting."). Task 6c mentions it in its description but the notification is dependent on Task 5 (phase transition notifications), which isn't listed as a dependency of Task 6c.

**Proposed correction** (Execution Plan, Task 6c Depends On):

> Change from: `Task 6a, Task 7`
> Change to: `Task 5, Task 6a, Task 7`

---

## 3. Build Spec Material That Should Be Extracted

**[Minor]** Design Spec, Phase 1 — "realign from here" algorithm details (line 92): "the AI re-distills from the original brain dump plus corrections up to a rollback point. Algorithm details in build spec." This is correctly deferred. However, the preceding sentence describes the matching rule: "The command is matched as an exact case-insensitive string: the entire chat message must be 'realign from here' with no additional text." This matching rule *is* an implementation detail (string matching behavior, case sensitivity, whole-message vs. substring) that belongs in the build spec alongside the algorithm.

**Recommendation:** Move the matching rule to the build spec's Realign Algorithm section. Replace with a plan-level statement: "The human types 'realign from here' in chat to trigger a re-distillation from the original brain dump plus corrections up to a rollback point. Exact matching rules and algorithm in build spec."

---

**[Minor]** Design Spec, lines 108-110 — "Action Button Behavior (All Buttons): Every action button in the chat interface follows these rules: (a) specific `status.json` update, (b) defined chat UI feedback, (c) stated confirmation requirement. Complete button inventory with `status.json` effects and UI behavior is specified in the build spec." This is correctly deferred to the build spec. No action needed — noted for completeness.

---

**[Minor]** Design Spec, Stagnation Guard (line 334) — The description includes algorithmic parameters inline: "70% of issues," "Levenshtein similarity ≥ 0.8." The design spec says "Algorithmic parameters for each guard are defined in the build spec" (line 338), but these values are stated *in the design spec itself* rather than only in the build spec. This creates two sources of truth.

**Recommendation:** Remove the inline parameter values from the design spec stagnation guard description. Replace with: "Issue rotation detected — old issues resolved, new issues introduced at the same rate (rotation threshold and similarity measure defined in build spec)." The build spec already has these values in the Convergence Guard Parameters section.

**Wait** — the design spec stagnation guard description at line 334 already says "rotation threshold and similarity measure defined in build spec." The build spec at line 305-306 then restates the same values. This is actually consistent — the design spec defers, and the build spec defines. However, the design spec *also* states the values inline in the same paragraph. Remove the inline values from the design spec to eliminate the dual-source issue.

**Current design spec text:**
> "Issue rotation detected — old issues resolved, new issues introduced at the same rate (rotation threshold and similarity measure defined in build spec)."

This is correct as written. The duplicate values are actually in the **build spec** (lines 305-306), which is where they belong. **No action needed** — I was mistaken. The design spec properly defers.

---

**[Minor]** Build Spec, WebSocket Reconnection Parameters section (lines 536-543) — These are implementation-level constants (1 second initial backoff, 30 second cap, exponential strategy). This is appropriate for the build spec and is correctly placed. No extraction needed.

---

**[Minor]** Design Spec, `chat_history.json` Error Handling section (line 126) — Contains truncation algorithm design: "the agent invocation layer truncates older messages while always retaining the original brain dump and the most recent messages." The build spec already has a dedicated "Chat History Truncation Algorithm" section. The design spec should describe the *behavior* (context window exceeded → truncation with anchor preservation) without describing the algorithm.

**Current text (design spec, line 126):**
> "If a single phase's chat history exceeds the agent's context window, the agent invocation layer truncates older messages while always retaining the original brain dump and the most recent messages. Truncation algorithm in build spec."

This is borderline — the phrase "truncates older messages while always retaining the original brain dump and the most recent messages" is behavioral enough for the design spec. The build spec adds the algorithm detail. **No action needed.**

---

That concludes the review. Three lists, sorted by severity within each list.
