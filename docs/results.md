I've read all four documents thoroughly. Now let me produce the review.

---

# ThoughtForge Plan Review ΓÇö Findings

## 1. Writing That's Unclear

**[Minor] Design Spec, Phase 4 ΓÇö Stagnation guard "done (success)" vs. Fabrication "halt" language is inconsistent with guard action terminology.**

The design spec uses "Done" and "Halt" as guard outcomes, but the stagnation guard says "Done (success)" while hallucination and fabrication say "Halt." The convergence guard table uses "Done. Notify human." and "Halt. Notify human." ΓÇö but the Halt Recovery section only addresses halted states. A reader implementing this will ask: does "Done" from stagnation trigger the same notification path as "Done" from termination? The answer is yes (based on context), but the language should be explicit.

**Replacement (Design Spec, Phase 4 Convergence Guards table, Stagnation row, Action column):**
> Done (success). Notify human ΓÇö same notification path as Termination success: status set to `done`, human notified with final error counts and iteration summary.

---

**[Minor] Design Spec, Phase 4 ΓÇö "issue rotation detected" definition is split between two documents.**

The design spec says "fewer than 70% of current issues match prior iteration issues by description similarity" but the match definition (Levenshtein similarity ΓëÑ 0.8) only appears in the build spec. The design spec should state what "match" means at the concept level.

**Replacement (Design Spec, Phase 4 Convergence Guards table, Stagnation row, Condition column):**
> Same total error count for 3+ consecutive iterations AND issue rotation detected ΓÇö fewer than 70% of current issues match prior iteration issues (match = issues with substantially similar descriptions, as determined by string similarity). Algorithmic parameters (similarity threshold, window sizes) defined in build spec.

---

**[Minor] Design Spec, Phase 2 ΓÇö "challenges weak or risky decisions present in `intent.md`" is vague about what constitutes "weak."**

Step 2 says the AI "challenges weak or risky decisions" but doesn't define what qualifies. The examples (missing dependencies, unrealistic constraints, scope gaps, contradictions) are parenthetical and feel like illustrations rather than the definition. A builder implementing the Phase 2 prompt will need clearer guidance.

**Replacement (Design Spec, Phase 2, step 2):**
> AI evaluates `intent.md` for: missing dependencies, unrealistic constraints, scope gaps, internal contradictions, unvalidated assumptions, and ambiguous priorities. Each flagged issue is presented to the human with specific reasoning. The AI does not rubber-stamp ΓÇö it must surface concerns even if the human's intent seems clear.

---

**[Minor] Design Spec, "Manual Edit Behavior" ΓÇö The phrase "silently ignored" for `spec.md` and `intent.md` manual edits is misleading.**

It says changes are "silently ignored for the remainder of the pipeline run." This could be read as the pipeline detecting edits and choosing to ignore them, when the reality is simpler: the files are just not re-read. The word "silently" implies detection without action.

**Replacement:**
> **`spec.md` and `intent.md` (static after creation):** These are read once at Phase 3 start and not re-read during later phases. If the human manually edits these files after their creation phase, the pipeline will not see those changes ΓÇö it works from its in-memory copy. There is no "restart from Phase N" capability in v1. The pipeline does not detect or warn about manual edits to any locked file.

---

**[Minor] Design Spec, Phase 1 ΓÇö Step 4 says "Human clicks Distill button" but the button hasn't been introduced yet in the document flow.**

The Distill button first appears in step 4 of Phase 1, but its definition and confirmation model appear later in the "Confirmation model" and "Action Button Behavior" sections. A reader may not understand what "Distill button" is at that point.

**Replacement (add before step 1 or after step 0):**
> **Interaction model:** Phase 1 uses two explicit actions: a **Distill** button (signals that all inputs are provided and the AI should begin processing) and a **Confirm** button (advances to Phase 2). Both use button presses, not chat commands ΓÇö see Confirmation Model below.

---

**[Minor] Design Spec, "Server Restart Behavior" ΓÇö "autonomous states" list omits `building` context.**

The restart section says projects in `distilling`, `building`, `polishing` are set to `halted`. But `building` spans both Code mode (which is autonomous) and Plan mode (which is also autonomous). This is correct, but it reads as if it might be Phase 2 `spec_building` since that's also "building" colloquially. The list is fine ΓÇö but confirming `spec_building` is in the human-interactive list (it is) makes the distinction clearer.

**Replacement:**
> Projects in human-interactive states (`brain_dump`, `human_review`, `spec_building`) resume normally ΓÇö they are waiting for human input and no action is needed. Projects in autonomous states (`distilling`, `building`, `polishing`) ΓÇö where the AI was actively processing without human interaction ΓÇö are set to `halted` with `halt_reason: "server_restart"` and the human is notified.

---

**[Minor] Execution Plan, Task 19 description is confusingly similar to Task 18 but for a different plugin.**

Task 18: "Implement `safety-rules.js` ΓÇö hard-block all code execution in plan mode." Task 19: "Implement Code mode safety-rules validation at orchestrator level." Task 23: "Implement `safety-rules.js` ΓÇö Code mode permissions." The distinction between Task 19 (orchestrator-side enforcement) and Task 23 (plugin-side rule definition) is clear to someone who read the design spec carefully, but the task descriptions alone don't make it obvious.

**Replacement (Task 19):**
> Implement orchestrator-level safety-rules enforcement for Code mode: before each Phase 3/4 agent invocation, call the code plugin's `safety-rules.js` `validate(operation)` and block disallowed operations. This is the enforcement mechanism; the rules themselves are defined in Task 23.

---

## 2. Genuinely Missing Plan-Level Content

**[Critical] Design Spec ΓÇö No specification of how the concurrency limit interacts with server restart recovery.**

On restart, the server scans `/projects/` for non-terminal projects and halts autonomous ones. But there's no mention of what happens if the number of non-terminal projects exceeds `max_parallel_runs` after restart. If three projects were running, two were halted by restart, and two new projects were created before the halted ones were resolved ΓÇö the concurrency model needs to state whether halted projects count toward the limit.

**Proposed content (add to "Concurrency limit enforcement" paragraph in Design Spec):**
> **Halted projects and concurrency:** Projects with `halted` status count toward the active project limit until the human either resumes them (returning to active pipeline state) or terminates them (setting them to terminal state). This prevents the operator from creating unlimited projects while ignoring halted ones.

---

**[Major] Design Spec ΓÇö No specification of how Phase 3 Code mode "stuck" detection tracks "same task" or "same tests."**

The stuck condition for Code mode says "2 consecutive non-zero exits on the same task" and "3 consecutive identical test failures." But neither the design spec nor the build spec defines what "same task" means in this context (same prompt? same file? same build step?) or what "identical test failures" means (same test name? same error message? same failing test count?).

**Proposed content (add to Design Spec Phase 3 Stuck Detection table, Code row, or to Build Spec as a new section):**
> **Code mode stuck tracking:** "Same task" means consecutive agent invocations with the same prompt intent (e.g., "implement feature X" or "fix test Y") ΓÇö tracked by the code builder's internal task queue. "Identical test failures" means the same set of test names appear in the failed list across consecutive fix-and-retest cycles, compared by exact test name string match.

---

**[Major] Design Spec / Build Spec ΓÇö No specification of how the Plan builder structures multi-turn interaction for large plans.**

Phase 3 Plan mode says the builder "fills every section ΓÇö no placeholders, no TBD." For a complex plan (e.g., a wedding plan with 20+ OPA sections), a single AI call may not produce the full document. The design spec doesn't address whether the builder calls the agent once (with the full template), iteratively per section, or in chunks. The stuck signal schema (`PlanBuilderResponse`) implies single-response interaction, but doesn't prohibit multi-turn. This matters for implementation.

**Proposed content (add to Design Spec Phase 3, Plan Mode, after step 5):**
> **Builder interaction model:** The plan builder may invoke the AI agent multiple times to fill the complete template ΓÇö for example, one invocation per major section or group of sections. The builder tracks which sections are complete and passes the partially-filled template as context for subsequent invocations. Each invocation returns a `PlanBuilderResponse`. The builder is complete when all template sections are filled with non-placeholder content.

---

**[Major] Execution Plan ΓÇö No task for implementing the concurrency limit enforcement described in the design spec.**

The design spec specifies: "When the number of active projects reaches `max_parallel_runs`, new project creation is blocked. The chat interface disables the 'New Project' action." No task in the execution plan covers implementing this enforcement logic ΓÇö neither in Task 2 (project initialization), Task 7g (project list sidebar), nor anywhere else.

**Proposed content (add to Build Stage 1 or Build Stage 2):**
> | 2b | Implement concurrency limit enforcement: block new project creation when active (non-terminal) project count reaches `config.yaml` `concurrency.max_parallel_runs`, disable "New Project" action in sidebar with message, re-enable when a project reaches terminal state | ΓÇö | Task 2, Task 7g | ΓÇö | Not Started |

---

**[Major] Execution Plan ΓÇö No task for implementing server restart behavior (scan projects, halt autonomous ones, notify).**

The design spec describes detailed restart behavior ΓÇö scanning `/projects/`, categorizing states, halting autonomous ones. No task covers this.

**Proposed content (add to Build Stage 1):**
> | 1c | Implement server restart recovery: on startup, scan `/projects/` for non-terminal projects, resume human-interactive states, halt autonomous states (`distilling`, `building`, `polishing`) with `halt_reason: "server_restart"`, notify human for each halted project | ΓÇö | Task 1a, Task 3, Task 5 | ΓÇö | Not Started |

---

**[Major] Execution Plan ΓÇö No task for implementing WebSocket disconnection handling on the server side.**

Task 7 mentions "WebSocket disconnection handling with auto-reconnect" which sounds client-side. The design spec describes server-side behavior: "The server does not maintain persistent WebSocket session state. On reconnect, the client sends the project ID... The server responds with current `status.json` and latest `chat_history.json`." This server-side reconnection endpoint/handler is not explicitly a separate task, and could be buried in Task 7, but the design spec's level of detail warrants a visible task.

**Proposed content (add to Build Stage 2):**
> | 7i | Implement server-side WebSocket reconnection handler: on client reconnect receive project ID, respond with current `status.json` and `chat_history.json`, handle invalid project ID by returning project list | ΓÇö | Task 7, Task 3 | ΓÇö | Not Started |

---

**[Major] Design Spec ΓÇö No specification for what happens if Vibe Kanban CLI calls fail.**

The design spec and build spec define the VK adapter and toggle behavior, but never specify error handling for VK CLI failures. If `vibekanban task create` or `vibekanban task update` returns non-zero, what happens? Is it a halt? A warning? The notification layer has defined failure handling (log and continue), but VK does not.

**Proposed content (add to Design Spec, Vibe Kanban Integration Interface section):**
> **Vibe Kanban CLI failure handling:** If a VK CLI call fails (non-zero exit, timeout, command not found), the adapter logs the error. For visualization-only calls (card creation, status updates), the failure is logged as a warning and the pipeline continues ΓÇö VK is not on the critical path. For agent execution calls (`vibekanban task run` in Code mode), the failure is treated as an agent failure and follows the standard agent retry-once-then-halt behavior.

---

**[Minor] Design Spec ΓÇö No mention of what test framework or runner is expected for Code mode.**

Phase 3 Code mode says "Writes tests: unit, integration, and acceptance" and `test-runner.js` executes them. But there's no guidance on what test framework is expected. Since the codebase being built could be any language/framework, the design spec should state that the test framework is determined during Phase 2 spec building (as part of the proposed architecture), and `test-runner.js` invokes whatever was decided.

**Proposed content (add to Design Spec, Code Mode Testing Requirements, or Phase 3 Code Mode):**
> **Test framework selection:** The test framework is determined during Phase 2 as part of the proposed architecture (language, tools, dependencies). The `test-runner.js` module executes tests using the framework specified in `spec.md`. It is not prescriptive about which framework ΓÇö it adapts to whatever was decided during spec building.

---

**[Minor] Execution Plan ΓÇö No task for implementing the button debounce behavior described in the design spec.**

The design spec says: "Once an action button is pressed, it is immediately disabled in the UI and remains disabled until the triggered operation completes or fails. A second click on a disabled button has no effect. If the server receives a duplicate action request..." This is UI + server-side behavior. Task 10 covers "Implement action buttons: Distill and Confirm" but doesn't mention debounce. The build spec's action button table mentions "Button disabled" as UI behavior but no task explicitly covers the server-side duplicate detection.

**Proposed content (add to Task 10 description):**
> Implement action buttons: Distill (Phase 1 intake trigger) and Confirm (phase advancement mechanism). Include button debounce: disable on press until operation completes, server-side duplicate request detection (ignore duplicates, return current state).

---

## 3. Build Spec Material That Should Be Extracted

**[Minor] Design Spec, Phase 1 ΓÇö "realign from here" behavior (steps 9.1ΓÇô9.4) contains implementation-level algorithmic detail.**

Steps 9.1ΓÇô9.4 describe a specific algorithm: baseline identification by scanning backwards for non-"realign" messages, context truncation with audit trail preservation, re-distillation from original + corrections, and the no-correction guard. This is the *how*, not the *what*. The design spec should say "Human can realign by discarding AI revisions after their last substantive correction and re-distilling from that point. Implementation details in build spec."

**Specifically extract to build spec:**
- Baseline identification logic (scanning backwards past sequential "realign from here" commands)
- Context truncation mechanics (excluded from working context but retained in `chat_history.json`)
- Re-distillation scope (original brain dump + corrections up to baseline)
- No-correction guard (ignore if no corrections exist)

**Replacement in design spec (step 9):**
> Human can type "realign from here" in chat. The AI identifies the most recent substantive correction, discards all AI and human messages after that point from the working context (retaining them in `chat_history.json` for audit), and re-distills from the original brain dump plus all corrections up to that baseline. If no corrections exist yet, the command is ignored with a prompt to provide a correction first. Implementation algorithm in build spec.

---

**[Minor] Design Spec ΓÇö Project ID format specification is implementation detail.**

"Format: `{timestamp}-{random}` (e.g., `20260214-a3f2`). The timestamp prefix enables chronological sorting. The random suffix ensures uniqueness." This belongs in the build spec alongside the initialization sequence. The design spec should say "URL-safe, filesystem-safe, unique project identifier" and leave the format to the build spec.

**The build spec already has a Project Initialization Sequence section that references this format, so the detail is already duplicated.** Remove the format specification from the design spec and keep it only in the build spec.

**Replacement in design spec (Phase 1, step 0):**
> **Project ID format:** A URL-safe, filesystem-safe, unique string identifier. Format defined in build spec.

---

**[Minor] Design Spec ΓÇö WebSocket reconnection details (exponential backoff, "Reconnecting..." indicator) are implementation detail.**

The design spec describes the client reconnection strategy: "exponential backoff," "visible Reconnecting... indicator," "state synced from server." The reconnection *behavior* is plan-level (auto-reconnect and recover state), but the specific client UX and backoff strategy belong in the build spec (which already has a "WebSocket Reconnection Parameters" section with the exact numbers).

**Replacement in design spec:**
> **Reconnection behavior:** The client auto-reconnects on disconnection. During disconnection, the chat UI displays a visible connection status indicator. On successful reconnect, state is synced from the server. Reconnection parameters (backoff strategy, timing) are in the build spec.

---
