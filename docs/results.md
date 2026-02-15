Now I have all four documents in full. Let me conduct the review systematically across the design specification, build spec, and execution plan — scrutinizing against the requirements brief.

---

# Project Plan Review — ThoughtForge Pipeline Tool

Reviewing: `thoughtforge-design-specification.md`, `thoughtforge-build-spec.md`, `thoughtforge-execution-plan.md`
Against: `thoughtforge-requirements-brief.md`

---

## 1. Writing That's Unclear

**[Major] Design Spec, Phase 4, Stagnation Guard — "fewer than 70%" phrasing is ambiguous about directionality.**

The sentence: *"Issue rotation detected (fewer than 70% of issues in the current iteration have a Levenshtein similarity ≥ 0.8 match on `description` against the immediately prior iteration's issues)"*

The build spec clarifies this correctly, but the design spec phrasing reads as if 70% is the *minimum* for rotation, when rotation means most issues are *new*. The design spec should match the build spec's clearer phrasing.

**Replacement text (Design Spec line 351):**
> Issue rotation is detected when fewer than 70% of current-iteration issues can be matched (Levenshtein similarity ≥ 0.8 on `description`) to any issue in the immediately prior iteration — meaning more than 30% of issues are new, indicating the reviewer is cycling rather than converging.

---

**[Major] Design Spec, Phase 3 Code Builder — "test-fix cycle" vs Phase 4 "iteration" terminology risks builder confusion.**

The paragraph at lines 251 describes the Phase 3 test-fix cycle, but uses "iteration" and "cycle" interchangeably while Phase 4 has formal "iterations" with different semantics (review+fix+commit). A builder could conflate the two.

**Replacement text (Design Spec, line 251, first sentence):**
> The code builder then enters a **test-fix cycle** (distinct from Phase 4's review-fix iterations): run tests, pass failures back to the agent, agent fixes, re-run tests — repeating until all tests pass or stuck detection triggers.

---

**[Major] Design Spec, Phase 4, Fix Regression Guard — "2 back-to-back iterations" vs "2 consecutive" language inconsistency.**

Line 349 uses "2 back-to-back iterations" while the build spec (line 285) says "2 consecutive iterations." Consistent terminology matters for a builder.

**Replacement text (Design Spec, line 349, relevant clause):**
> If the fix step increases total error count in 2 consecutive iterations (the two most recent fix steps both produced higher error counts than their respective review inputs), halt and notify.

---

**[Minor] Design Spec, line 11 — "Terminology" note buries an important convention.**

The terminology note about "human" vs "operator" appears once and is easy to miss. It should be more prominent or repeated in a conventions section.

**Replacement text:**
> **Terminology convention (applies throughout all ThoughtForge documents):** "Human" and "operator" refer to the same person — the solo user. "Human" is used in pipeline flow descriptions. "Operator" is used in system administration contexts.

---

**[Minor] Design Spec, OPA Framework section — two OPA acronyms create confusion.**

Line 19 explains both "OPA Table" and "OPA Framework (Outcome/Purpose/Action)" but a builder encountering "OPA" for the first time in the codebase may not know which is meant. The requirements brief's OPA and the deliverable's OPA table need distinct labels.

**Replacement text (first sentence of line 19):**
> Plan mode deliverables use an **OPA Table** structure — **Objective → Plan → Assessment** — for every major section. This is distinct from the requirements brief's use of "OPA" (Outcome • Purpose • Action, Tony Robbins' RPM System), which is a document organization framework, not a deliverable content structure. To avoid ambiguity: "OPA Table" always refers to the deliverable structure; "OPA Framework" in the requirements brief refers to the brief's own organization.

---

**[Minor] Build Spec, line 207 — Code Builder Task Queue crash recovery is confusingly conditional.**

"Whether to persist is a Task 21 implementation decision — but crash recovery must produce a compatible task ordering" mixes implementation guidance with requirements. A builder reading this can't tell what's required.

**Replacement text:**
> The code builder persists the initial task list to `task_queue.json` in the project directory at derivation time. On crash recovery, the builder re-reads `task_queue.json` rather than re-deriving from `spec.md`, ensuring deterministic task ordering across restarts.

---

**[Minor] Execution Plan, line 196-197 — Critical path annotation is confusing.**

"Note: Task 13 is not a declared code dependency of Task 6c, but Task 6c cannot be meaningfully tested without Phase 2 outputs" — this reads as a code-level concern, not a plan-level statement. The critical path should just state the functional chain.

**Replacement text:**
> The functional critical path includes Task 13 → Task 15 → Task 6c even though Task 6c's code dependency is on Task 6a, because Phase 3→4 transition cannot be exercised without Phase 2 outputs (spec.md, constraints.md) and a Phase 3 builder producing deliverables.

---

## 2. Genuinely Missing Plan-Level Content

**[Critical] Design Spec — No error handling for `constraints.md` missing at Phase 4 start (first iteration, not just subsequent iterations).**

The design spec at line 166 says: "If `constraints.md` is unreadable or missing at the start of a Phase 4 iteration, the iteration halts." But there's no specification for what happens if `constraints.md` is missing at Phase 4 *entry* — the Phase 3→4 automatic transition. The Phase 3→4 transition error handling table (lines 293-298) doesn't check for `constraints.md` existence. Since `constraints.md` is written in Phase 2 and Phase 3→4 is automatic, it should always exist — but the design spec should explicitly validate this at transition.

**Proposed content (add to Phase 3→4 Transition Error Handling table):**
> | `constraints.md` missing or unreadable at Phase 3→4 transition | Halt. Set `status.json` to `halted` with `halt_reason: "file_system_error"`. Notify human: "constraints.md missing or unreadable. Cannot start polish loop. Review project `/docs/` directory." Do not enter Phase 4. |

---

**[Critical] Design Spec / Build Spec — No specification for graceful shutdown's effect on Phase 1-2 (interactive states).**

The graceful shutdown section (Design Spec line 463) only discusses agent subprocesses. If a human is mid-chat in Phase 1-2 when `SIGTERM` arrives, the spec doesn't say what happens to the WebSocket connection or the in-progress chat. The WebSocket shutdown section (line 465) covers sending close frames, but doesn't clarify whether the human's last unsaved chat message is persisted.

**Proposed content (add after line 465):**
> **Interactive state shutdown:** For projects in human-interactive states (`brain_dump`, `human_review`, `spec_building`), no server-side processing is interrupted — the server is waiting for human input. The WebSocket close frame is sent as described above. Any chat message the human was composing but had not yet sent is lost (client-side only). The last persisted message in `chat_history.json` is the recovery point on restart.

---

**[Major] Design Spec — No specification for what happens when the human edits `constraints.md` to be excessively large (exceeds agent context window).**

Line 169 says: "If the file exceeds the agent's context window when combined with other review context, it is truncated with a warning logged." But it doesn't specify *how* it's truncated. For review prompts, truncating the wrong part of `constraints.md` (e.g., cutting the Acceptance Criteria section) could make the review meaningless.

**Proposed content (add after line 169):**
> **`constraints.md` truncation strategy:** If `constraints.md` exceeds the available context budget when combined with other review context, it is truncated from the middle — the Context and Deliverable Type sections (top) and the Acceptance Criteria section (bottom) are preserved, and middle sections (Priorities, Exclusions, Severity Definitions, Scope) are removed in reverse order until the file fits. A warning is logged identifying which sections were removed.

---

**[Major] Execution Plan — No task for implementing the Fix Regression guard.**

Tasks 33-37 cover: termination (33), hallucination (34), stagnation (35), fabrication (36), max iterations (37). But the Fix Regression guard (Design Spec line 349, Build Spec line 285) is a sixth guard evaluated *before* all others. It has no dedicated task.

**Proposed content (add to Build Stage 6):**
> | 33a | Implement convergence guard: fix regression (per-iteration check — compare post-fix error count to pre-fix review count, warn on single occurrence, halt on 2 consecutive regressions). Evaluated immediately after each fix step, before other guards. | — | Task 30 | — | Not Started |

Also update Task 47 dependency to include Task 33a, and add a unit test:
> | 47b | Unit tests: fix regression guard (single regression logs warning, 2 consecutive regressions halt, non-consecutive regressions reset counter, first iteration has no prior to compare) | — | Task 33a | — | Not Started |

---

**[Major] Design Spec / Build Spec — No specification for how the code builder handles non-Node.js projects.**

The design spec says the test command is `npm test` (line 310: "`test-runner.js` always invokes the project's standard test entry point (`npm test` for Node.js projects)"). But the requirements brief lists "Web apps, CLI tools, APIs, scripts, automation" as code project types, and the Phase 2 spec builder proposes "language, OS, framework, tools" — implying non-Node.js projects are possible. If the human's brain dump is for a Python CLI tool, `npm test` won't work.

**Proposed content (add to Design Spec, Test Command Discovery section, after line 310):**
> **Non-Node.js projects:** For deliverables in languages other than Node.js, the coding agent is instructed (via the `/prompts/code-build.md` prompt) to create a standard test entry point appropriate to the language (e.g., `Makefile` with `make test`, `pyproject.toml` with `pytest`, etc.). `test-runner.js` reads the project's `spec.md` Deliverable Structure section to determine the language and invokes the language-appropriate test command. The mapping from language to test command is a configuration in `test-runner.js`, not hardcoded to `npm test`.

---

**[Major] Execution Plan — No task for the `chat_history.json` error handling (corruption, missing).**

Design Spec line 132 specifies detailed error handling for `chat_history.json` corruption — halt and notify, same as `status.json`. But no task in the execution plan explicitly covers implementing this. Task 9a covers persistence and truncation but not the corruption/missing error handling path.

**Proposed content (amend Task 9a description):**
> Task 9a: Implement `chat_history.json` persistence: append after each chat message, clear on Phase 1→2 and Phase 2→3 confirmation only (NOT on Phase 3→4 automatic transition), resume from last recorded message on crash. **Include error handling: halt and notify on unreadable, missing, or invalid `chat_history.json` (same behavior as `status.json` corruption).** Include context window truncation logic per build spec Chat History Truncation Algorithm.

---

**[Major] Design Spec — No specification for what happens to in-flight WebSocket messages when the server crashes (not graceful shutdown).**

Graceful shutdown is covered (line 463-465). But hard crashes (OOM, kill -9, power loss) leave the WebSocket in an unknown state. The design spec doesn't address what the client experiences or how it recovers differently from a graceful shutdown.

**Proposed content (add after line 466):**
> **Hard crash (ungraceful termination):** If the server process terminates without sending a WebSocket close frame (kill -9, OOM, power loss), the client detects the dropped TCP connection via WebSocket `onerror` or `onclose` events. The same auto-reconnect behavior applies. The key difference from graceful shutdown: any agent subprocess that was running is killed by the OS (orphaned child process cleanup is OS-dependent). On restart, Server Restart Behavior applies — autonomous-state projects are halted. The client reconnects and syncs state normally.

---

**[Minor] Build Spec — No specification for how the Levenshtein similarity is computed for the stagnation guard.**

The build spec references Levenshtein similarity >= 0.8 (line 303-304) but doesn't define whether this is normalized Levenshtein distance, Levenshtein ratio, or raw edit distance divided by max length. These give different results.

**Proposed content (add after Build Spec line 304):**
> **Levenshtein similarity formula:** Similarity is computed as `1 - (levenshtein_distance(a, b) / max(a.length, b.length))`. A result of 1.0 means identical strings; 0.0 means completely different. The ≥ 0.8 threshold means two descriptions match if they differ by no more than 20% of the longer string's length.

---

**[Minor] Design Spec — No specification for the order of buttons presented during Phase 4 halt recovery.**

Line 367 says "Resume, Override, or Terminate" and the build spec defines each, but the display order and visual grouping aren't specified. Resume and Override are non-destructive; Terminate is destructive. UX convention would separate them.

**Proposed content (add after Design Spec line 371):**
> **Button display order:** Recovery buttons are displayed left-to-right: Resume, Override, Terminate. Terminate is visually distinguished (e.g., red or separated by a divider) as the destructive option.

---

**[Minor] Execution Plan — No task for implementing the WebSocket close frame on graceful shutdown.**

Design Spec line 465 specifies specific behavior: "sends a WebSocket close frame (code 1001, 'Server shutting down')". No task covers this implementation.

**Proposed content (add to Build Stage 2 or amend Task 1a):**
> Amend Task 1a description to include: "Including graceful shutdown handler: on SIGTERM/SIGINT, send WebSocket close frame (code 1001) to all connected clients, wait for in-progress agent subprocesses (up to configured timeout), then exit."

---

## 3. Build Spec Material That Should Be Extracted

**[Major] Design Spec, lines 63-78 — Project Initialization Sequence includes implementation-level detail.**

The step-by-step initialization sequence (create directory, git init, write status.json, create kanban card, open chat thread) with retry logic and failure messages belongs in the build spec. The design spec should state *what* project initialization does, not the ordered implementation steps. The build spec already has a "Project Initialization Sequence" section that duplicates this.

**Recommendation:** Remove the numbered steps from Design Spec lines 63-78. Replace with: "Project initialization creates the project directory structure, initializes version control, writes the initial project state, optionally registers on the Kanban board, and opens the chat interface. The full initialization sequence is in the build spec." Keep the Project ID collision handling (line 69) and Git Initialization Failure (line 75) in the design spec since these are behavioral decisions.

---

**[Major] Design Spec, lines 114-117 — Action Button Behavior detail belongs in build spec.**

"Every action button in the chat interface follows these rules: (a) specific `status.json` update, (b) defined chat UI feedback, (c) stated confirmation requirement" — then defers to the build spec. The design spec should state the *policy* (buttons are the phase advancement mechanism, not chat commands) without specifying the three-part implementation contract. This is already fully specified in the build spec's Action Button Behavior table.

**Recommendation:** Replace lines 114-117 with: "Every action button follows the behavior contract defined in the build spec's Action Button Behavior inventory, which specifies `status.json` effects, UI feedback, and confirmation requirements for each button."

---

**[Major] Design Spec, lines 596-604 — `spec.md` structure section duplicates build spec.**

The `spec.md` table (Design Spec lines 194-205) and the identical structure in Build Spec lines 879-912 are fully duplicated. The design spec should reference the structure, not reproduce it.

**Recommendation:** Remove the `spec.md` structure table from Design Spec lines 194-205. Replace with: "**`spec.md` structure:** See build spec `spec.md` Structure section for the full template. Contains: Deliverable Overview, Deliverable Structure, Key Decisions, Resolved Unknowns, Dependencies, and Scope Boundaries." Keep the Plan mode vs Code mode distinction sentence (line 205).

---

**[Minor] Design Spec, lines 507-511 — Zod validation flow detail belongs in build spec.**

"Parse AI response as JSON → validate via Zod safeParse → on failure: retry (max configurable, default 2) → on repeated failure: halt and notify human" — this step-by-step validation flow is implementation detail. The design spec should state "Review JSON is validated via Zod schemas; malformed output is retried then halted." The build spec already has this flow fully specified.

**Recommendation:** Replace with: "Review JSON is validated against the Zod schema for the active deliverable type. Malformed responses are retried up to a configurable limit, then the pipeline halts and notifies the human. Validation flow and retry logic are in the build spec."

---

**[Minor] Design Spec, line 519 — Token estimation heuristic is implementation detail.**

"ThoughtForge estimates tokens as `character_count / 4` (a standard rough heuristic)" is an implementation detail that belongs in the build spec.

**Recommendation:** Move the heuristic to the build spec's Agent Communication section. Replace in design spec with: "The token count is an approximation — the exact estimation method is in the build spec."

---

**[Minor] Build Spec, lines 706-712 — Build Toolchain section mixes ThoughtForge's own tooling with guidance.**

"Test framework: Vitest (or Jest — decide before build starts)" — this decision should be resolved before the build spec is finalized. The execution plan says "Choose Vitest or Jest before Task 1 begins" and recommends Vitest. The build spec should state the chosen framework, not present an unresolved choice.

**Recommendation:** Resolve this before build begins. Replace with: "Test framework: Vitest" (or Jest, once decided). Remove the "(or Jest — decide before build starts)" equivocation.
