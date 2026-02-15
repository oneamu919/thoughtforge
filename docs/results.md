Now let me read all four documents carefully. I've read the requirements brief, design specification, build spec, and execution plan. Let me now produce the review.

---

# Plan Review Findings

## 1. Writing That's Unclear

**[Minor] Design Spec, Phase 2, Step 4 — "at least 1, target 5–10" is stated but the validation gate later says "at least 1 criterion."**

The Phase 2 behavior (line 151) says "derives acceptance criteria (at least 1, target 5–10)" and then the Acceptance Criteria Validation Gate (line 159) enforces "at least 1." The target range of 5–10 has no enforcement mechanism and reads as both a requirement and a suggestion. Clarify that the target is guidance, not a gate.

**Replacement text** (Design Spec, line 151):
> 4. AI derives acceptance criteria from the objective, assumptions, and constraints in `intent.md`. The validation gate enforces a minimum of 1 criterion; the target range of 5–10 is guidance for the AI prompt, not an enforced threshold. For Plan mode, criteria assess document completeness, logical coherence, and actionability. For Code mode, criteria assess functional requirements that map to testable acceptance tests in Phase 3.

---

**[Minor] Design Spec, Phase 3 Code Mode — "Stuck detection" uses "same task" inconsistently with "identical test failures."**

Lines 256–258 describe the test-fix cycle stuck detector as firing on 3 consecutive cycles with identical failing test names. Then the Phase 3 Stuck Detection table (lines 274–276) mentions "2 consecutive retries on the same task, OR test suite fails on the same tests for 3 consecutive fix attempts." These are two separate stuck conditions for Code mode but the test-fix cycle section only describes one. The relationship between the test-fix cycle stuck detector and the broader Code mode stuck detection table is unclear.

**Replacement text** (Design Spec, lines 254–259 — test-fix cycle section):
> **Stuck detection within the test-fix cycle:** Two conditions trigger stuck detection: (1) the build agent returns non-zero exit on the same build task after 2 consecutive retries, OR (2) the test suite fails on the identical set of test names for 3 consecutive fix-and-retest cycles (compared by exact string match). If each cycle produces different failing tests (rotating failures), condition (2) does not trigger.

Then remove the duplicate from the Phase 3 Stuck Detection table, Code row, so it reads:
> | Code | See test-fix cycle stuck detection above. | Notify and wait |

---

**[Minor] Design Spec, Phase 4 Convergence Guards — "Fix Regression" guard description is dense and hard to parse.**

The inline description (line 366) packs three behaviors (single-occurrence warning, consecutive halt, evaluation timing) into one cell. This is the hardest guard to understand on first read.

**Replacement text** (Design Spec, line 366):
> | Fix Regression (per-iteration) | Evaluated immediately after each fix step, before other guards. Compares the post-fix total error count against the pre-fix review count for the same iteration. **Single occurrence:** If the fix increased the total error count, log a warning but continue. **Consecutive occurrences:** If the two most recent fix steps both increased their respective error counts, halt and notify: "Fix step is introducing more issues than it resolves. Review needed." | Warn (single) or Halt (2 consecutive). Notify human. |

---

**[Minor] Design Spec, Stagnation Guard — "Two conditions must both be true" then describes them as "Plateau" and "Issue rotation" without clarifying the intended outcome.**

Line 368 says the stagnation guard fires when the reviewer "is cycling through new cosmetic issues at the same rate old ones are resolved." This is the key insight but it appears at the end of the description after the algorithmic detail. A builder encountering this section needs the intent first.

**Replacement text** (Design Spec, line 368, first sentence):
> | Stagnation | **Intent:** Detect when the deliverable has reached a quality plateau — the reviewer resolves old issues but introduces equally many new cosmetic issues each iteration, producing no net improvement. Two conditions must both be true: (1) **Plateau:** Total error count is identical for `stagnation_limit` consecutive iterations. (2) **Issue rotation:** Fewer than 70% of current-iteration issues match any issue in the immediately prior iteration (match = Levenshtein similarity ≥ 0.8 on `description`). When both are true, the deliverable is converged. | Done (success — treated as converged plateau). Notify human with final error counts and iteration summary. |

---

**[Minor] Design Spec, Fabrication Guard — "at least one prior iteration" with compound conditions is hard to follow.**

Line 369 describes two conditions with nested clauses. The sentence "AND in at least one prior iteration, every severity category was at or below twice its convergence threshold" requires multiple re-reads.

**Replacement text** (Design Spec, line 369):
> | Fabrication | Two conditions must both be true: (1) **Category spike:** A single severity category count exceeds its trailing average by more than 50% (with a minimum absolute increase of 2). Trailing window size defined in build spec. (2) **Prior near-convergence:** The system previously reached within 2× of the termination thresholds in at least one prior iteration (i.e., critical ≤ 0, medium ≤ 6, minor ≤ 10 with default config). This ensures fabrication is only flagged after the deliverable was demonstrably close to convergence — not during early volatile iterations. The `2×` multiplier is hardcoded; the base thresholds are read from `config.yaml` at runtime. Parameters in build spec. | Halt. Notify human. |

---

**[Minor] Design Spec, "Halt vs. Terminate" — the distinction is described mid-section with no structural call-out.**

Line 378 states the difference between halt and terminate but it's buried between convergence guard descriptions and halt recovery. A builder scanning for this distinction would miss it.

**Replacement text:** Move this paragraph to immediately before the "Halt Recovery" section and add a subheading:

> **Halt vs. Terminate Distinction:**
>
> When a convergence guard triggers a halt, the project is recoverable — the human can Resume or Override. When the human explicitly Terminates (via button), the project is permanently stopped (`halt_reason: "human_terminated"`). Both use the `halted` phase value in `status.json`; the `halt_reason` field distinguishes them. (Authoritative field values are in the build spec Action Button Behavior table.)

---

**[Minor] Design Spec, "Chat Interface" — "terminal-based alternative deferred" is a parenthetical that distracts.**

Line 609: "Lightweight web chat interface (terminal-based alternative deferred)." The parenthetical reads as an active consideration rather than a clear deferral.

**Replacement text:**
> **ThoughtForge Chat (Built):** Lightweight web chat interface. (A terminal-based alternative is deferred — not a current build dependency.)

---

## 2. Genuinely Missing Plan-Level Content

**[Major] Design Spec — No plan-level description of what happens when the human manually edits the deliverable (plan.md or codebase) during Phase 4.**

The design spec carefully addresses manual edits to `constraints.md` (hot-reloaded), `spec.md` (static), and `intent.md` (static). But it never addresses the human editing the actual deliverable — `plan.md` or source code files — while the polish loop is running. Phase 4 commits after each review and fix step. If the human edits between iterations, the behavior is undefined: does the reviewer see the human's edits? Does the fix agent overwrite them? Does git commit them silently?

**Proposed content** (add after "Locked File Behavior" section, before Phase 4):
> **Deliverable Edits During Phase 4:**
>
> If the human manually edits the deliverable (plan document or source code) between Phase 4 iterations, the edits are picked up by the next iteration's review step — the reviewer reads the current state of the deliverable from disk. The next fix step's git commit captures both the human's edits and the AI's fixes. The pipeline does not detect, warn about, or distinguish human edits from AI fixes. This is by design — the human has full authority to modify the deliverable at any time. The convergence trajectory may shift as a result (human edits could increase or decrease error counts). No special handling is needed.

---

**[Major] Design Spec / Execution Plan — No error handling or behavior defined for Handlebars template rendering when AI-generated content exceeds template slot expectations.**

The design spec describes Template Content Escaping (preventing `{{`/`}}` from breaking templates) and Template Context Window Overflow (when the template exceeds agent context). But there's no description of what happens when the AI returns content that is structurally valid but doesn't fit the template's expectations — for example, returning content for a slot that doesn't exist in the template, or returning empty content for a required slot. The build spec says to "escape content before template rendering" but doesn't address structural mismatches.

**Proposed content** (add to Design Spec, Phase 3 Plan Mode, after "Template Content Escaping"):
> **Template Slot Validation:** After each plan builder invocation, the orchestrator validates that the returned content corresponds to a valid template slot. If the AI returns content for a non-existent slot, the content is discarded with a warning logged. If a required template slot receives empty or placeholder content (containing "TBD", "TODO", or "placeholder" — case-insensitive), the builder re-invokes the AI for that slot (subject to the standard retry-once-then-halt behavior). After all invocations complete and the template is assembled, a final validation confirms all slots are filled. Any remaining empty slots halt the builder with a notification identifying the unfilled sections.

---

**[Major] Execution Plan — No mention of TypeScript compilation in the critical path or task breakdown.**

The execution plan states "The codebase uses TypeScript" and references `tsc` compilation, but no task in the Task Breakdown covers TypeScript setup (`tsconfig.json` configuration, `tsc` build scripts, the `tsx`/`ts-node` dev runner, or the `package.json` start/dev script distinction). Task 1 covers "Initialize Node.js project, folder structure, `config.yaml` loader" but doesn't mention TypeScript configuration.

**Proposed content** (add to Task 1 description):
> Initialize Node.js project with TypeScript: `tsconfig.json` (`"module": "nodenext"`, `"moduleResolution": "nodenext"`), `package.json` with ESM (`"type": "module"`), `start` script targeting compiled output, `dev` script using `tsx` for development, `build` script running `tsc`, and folder structure. Install initial dependencies (per build spec Initial Dependencies). Implement `config.yaml` loader with Zod schema validation.

---

**[Minor] Design Spec — No description of how the Phase 2 "Challenge" step results are persisted or communicated.**

Phase 2 step 2 (line 149) says the AI "evaluates `intent.md` for structural issues" and "each flagged issue is presented to the human with specific reasoning." But there's no mention of whether the AI's challenge findings appear only in chat (ephemeral) or are captured in `spec.md` or another artifact. If a flagged issue leads to a design change, the rationale lives only in chat history (which is cleared on Phase 2→3 transition).

**Proposed content** (add after Phase 2 step 2):
> Challenge findings that result in design changes are captured in the `spec.md` "Key Decisions" section with the original concern and resolution. Challenge findings that the human dismisses are not persisted beyond the chat history. Since chat history is cleared on Phase 2→3 transition, dismissed challenges are not available for later reference. This is acceptable — the human's decisions are captured in `spec.md`; the reasoning for rejected alternatives is not.

---

**[Minor] Execution Plan — No task for creating the `/public/` directory or static frontend assets (HTML, CSS, JS for the chat interface).**

Task 7 says "Build ThoughtForge web chat interface" but doesn't mention the static asset structure. The design spec (line 460) says "Static assets (HTML, CSS, JS) are served directly by Express from a `/public/` directory." The build spec doesn't include `/public/` in any file manifest. A builder starting Task 7 doesn't know if they're creating a single `index.html` or multiple files.

**Proposed content** (add to Task 7 description):
> Create `/public/` directory with static assets: `index.html` (single-page chat interface), `style.css`, and `app.js` (vanilla JavaScript for WebSocket client, DOM manipulation, project switching, and action buttons). These are served by Express directly — no build tooling or bundler required.

---

**[Minor] Design Spec — No behavior specified for what happens when `config.yaml` is modified while the server is running.**

The design spec specifies startup validation and first-run behavior for `config.yaml`. It states that the VK toggle is "read at each operation, not cached at project creation." But it never states whether other config values (convergence thresholds, agent defaults, notification channels) are read once at startup or re-read at each operation. A builder could implement either behavior.

**Proposed content** (add to Configuration section):
> **Config reload behavior:** `config.yaml` is read once at server startup and cached in memory for the duration of the server process. Changes to `config.yaml` require a server restart to take effect. The one exception is `vibekanban.enabled`, which is read at each VK operation (already specified in VK toggle behavior). Hot-reloading of config is deferred — not a current build dependency.

---

## 3. Build Spec Material That Should Be Extracted

**[Minor] Design Spec, lines 63–76 — Project Initialization Sequence detail belongs in build spec.**

The design spec's Phase 1 step 0 includes implementation details: "Project initialization creates the project directory structure, initializes version control, writes the initial project state, optionally registers on the Kanban board, and opens the chat interface. The full initialization sequence is in the build spec." Then it immediately follows with collision retry behavior, git init failure handling, and agent assignment specifics. The design spec already defers to the build spec ("The full initialization sequence is in the build spec") but then provides redundant implementation detail in the same section. The collision retry algorithm, agent field assignment ("copied to the project's `status.json` `agent` field"), and git init failure handling are implementation details that already exist in the build spec.

**Recommendation:** Trim Design Spec Phase 1 step 0 to the behavioral description and cross-reference. The detailed sequences are already in the build spec's "Project Initialization Sequence" section. Keep: what happens and why. Remove: the specific sequence of operations, field-level `status.json` assignments, and error recovery procedures that duplicate the build spec.

---

**[Minor] Design Spec, lines 502–520 — Vibe Kanban toggle behavior truth table is implementation detail.**

The 4-row truth table (VK enabled/disabled × Plan/Code) with specific behavioral descriptions per cell is implementation-level specificity. The design-level content is: "Both modes function fully with VK disabled. VK provides visualization and Code mode agent execution. Plan mode always invokes agents directly." The toggle-change-during-active-projects paragraph is also implementation detail (when the toggle is read, what happens to orphaned cards).

**Recommendation:** Reduce the design spec to the behavioral summary. Move the truth table and toggle-change handling to the build spec alongside the VK CLI Interface section.

---

**[Minor] Design Spec, lines 556–561 — "Phase 1-2 Chat Agent Model" is implementation detail.**

This section describes the subprocess invocation pattern ("prompt via stdin, response via stdout, one subprocess call per turn"), context assembly ("brain dump text and resources, current distillation, all messages from `chat_history.json`"), and the stateless-call model. This is how the agent layer works, not what the chat interaction does. The design-level content is: "Each chat turn is a stateless AI invocation with full context. There is no persistent agent session."

**Recommendation:** Keep the two-sentence behavioral summary in the design spec. Move the subprocess pattern and context assembly list to the build spec's Agent Communication section.

---

**[Minor] Design Spec, lines 614–621 — WebSocket reconnection implementation detail.**

The design spec describes reconnection behavior at an appropriate level but then specifies: "In-flight AI responses that were streaming when the connection dropped are not replayed — the human sees the last fully-received message. If the server-side operation completed during the disconnect, the reconnect state sync picks up the updated `status.json` and chat history. If the operation did not complete server-side, the human can re-trigger the action." This level of state-synchronization detail belongs in the build spec.

**Recommendation:** Keep: "The client auto-reconnects and syncs state from the server on reconnect." Move the in-flight response handling, operation-completion scenarios, and re-trigger behavior to the build spec's WebSocket Reconnection Parameters section (which already exists but only covers timing parameters).

---

That concludes the review. 13 findings total: 0 Critical, 4 Major, 9 Minor.
