# Apply Review Findings from results.md

Apply every change listed below to the source files. Each change is a direct replacement, addition, or extraction. Do not interpret or improvise — apply exactly what is specified.

Read all three source files and `results.md` before making changes so you have full context.

**Source files (all in `docs/`):**
- `docs/thoughtforge-design-specification.md` (referred to as "Design Spec")
- `docs/thoughtforge-build-spec.md` (referred to as "Build Spec")
- `docs/thoughtforge-execution-plan.md` (referred to as "Execution Plan")

---

## Section 1: Unclear Writing — Replacements

### 1.1 [Minor] Design Spec — Phase 4, Convergence Guards table, Stagnation row, Action column

Find the Stagnation row in the Phase 4 Convergence Guards table. Replace the Action column text with:

> Done (success). Notify human — same notification path as Termination success: status set to `done`, human notified with final error counts and iteration summary.

### 1.2 [Minor] Design Spec — Phase 4, Convergence Guards table, Stagnation row, Condition column

In the same Stagnation row, replace the Condition column text with:

> Same total error count for 3+ consecutive iterations AND issue rotation detected — fewer than 70% of current issues match prior iteration issues (match = issues with substantially similar descriptions, as determined by string similarity). Algorithmic parameters (similarity threshold, window sizes) defined in build spec.

### 1.3 [Minor] Design Spec — Phase 2, step 2

Find step 2 in Phase 2 that says the AI "challenges weak or risky decisions." Replace the entire step 2 text with:

> AI evaluates `intent.md` for: missing dependencies, unrealistic constraints, scope gaps, internal contradictions, unvalidated assumptions, and ambiguous priorities. Each flagged issue is presented to the human with specific reasoning. The AI does not rubber-stamp — it must surface concerns even if the human's intent seems clear.

### 1.4 [Minor] Design Spec — "Manual Edit Behavior" section

Find the paragraph about `spec.md` and `intent.md` that uses the phrase "silently ignored." Replace the relevant paragraph with:

> **`spec.md` and `intent.md` (static after creation):** These are read once at Phase 3 start and not re-read during later phases. If the human manually edits these files after their creation phase, the pipeline will not see those changes — it works from its in-memory copy. There is no "restart from Phase N" capability in v1. The pipeline does not detect or warn about manual edits to any locked file.

### 1.5 [Minor] Design Spec — Phase 1, before step 1

Add the following text before step 1 of Phase 1 (or after step 0):

> **Interaction model:** Phase 1 uses two explicit actions: a **Distill** button (signals that all inputs are provided and the AI should begin processing) and a **Confirm** button (advances to Phase 2). Both use button presses, not chat commands — see Confirmation Model below.

### 1.6 [Minor] Design Spec — "Server Restart Behavior" section

Find the text that lists which states resume and which are halted on restart. Replace it with:

> Projects in human-interactive states (`brain_dump`, `human_review`, `spec_building`) resume normally — they are waiting for human input and no action is needed. Projects in autonomous states (`distilling`, `building`, `polishing`) — where the AI was actively processing without human interaction — are set to `halted` with `halt_reason: "server_restart"` and the human is notified.

### 1.7 [Minor] Execution Plan — Task 19 description

Find Task 19's description. Replace it with:

> Implement orchestrator-level safety-rules enforcement for Code mode: before each Phase 3/4 agent invocation, call the code plugin's `safety-rules.js` `validate(operation)` and block disallowed operations. This is the enforcement mechanism; the rules themselves are defined in Task 23.

---

## Section 2: Missing Content — Additions

### 2.1 [Critical] Design Spec — Concurrency limit enforcement paragraph

Find the "Concurrency limit enforcement" paragraph. Add the following content to it:

> **Halted projects and concurrency:** Projects with `halted` status count toward the active project limit until the human either resumes them (returning to active pipeline state) or terminates them (setting them to terminal state). This prevents the operator from creating unlimited projects while ignoring halted ones.

### 2.2 [Major] Design Spec — Phase 3, Stuck Detection table or subsection

Find the Phase 3 Stuck Detection table (Code row). Add the following after the table or as a clarifying subsection:

> **Code mode stuck tracking:** "Same task" means consecutive agent invocations with the same prompt intent (e.g., "implement feature X" or "fix test Y") — tracked by the code builder's internal task queue. "Identical test failures" means the same set of test names appear in the failed list across consecutive fix-and-retest cycles, compared by exact test name string match.

### 2.3 [Major] Design Spec — Phase 3, Plan Mode, after step 5

Add the following after step 5 in Phase 3 Plan Mode:

> **Builder interaction model:** The plan builder may invoke the AI agent multiple times to fill the complete template — for example, one invocation per major section or group of sections. The builder tracks which sections are complete and passes the partially-filled template as context for subsequent invocations. Each invocation returns a `PlanBuilderResponse`. The builder is complete when all template sections are filled with non-placeholder content.

### 2.4 [Major] Execution Plan — Build Stage 1 or Build Stage 2 task table

Add a new task row:

> | 2b | Implement concurrency limit enforcement: block new project creation when active (non-terminal) project count reaches `config.yaml` `concurrency.max_parallel_runs`, disable "New Project" action in sidebar with message, re-enable when a project reaches terminal state | — | Task 2, Task 7g | — | Not Started |

### 2.5 [Major] Execution Plan — Build Stage 1 task table

Add a new task row:

> | 1c | Implement server restart recovery: on startup, scan `/projects/` for non-terminal projects, resume human-interactive states, halt autonomous states (`distilling`, `building`, `polishing`) with `halt_reason: "server_restart"`, notify human for each halted project | — | Task 1a, Task 3, Task 5 | — | Not Started |

### 2.6 [Major] Execution Plan — Build Stage 2 task table

Add a new task row:

> | 7i | Implement server-side WebSocket reconnection handler: on client reconnect receive project ID, respond with current `status.json` and `chat_history.json`, handle invalid project ID by returning project list | — | Task 7, Task 3 | — | Not Started |

### 2.7 [Major] Design Spec — Vibe Kanban Integration Interface section

Add the following to the Vibe Kanban Integration Interface section:

> **Vibe Kanban CLI failure handling:** If a VK CLI call fails (non-zero exit, timeout, command not found), the adapter logs the error. For visualization-only calls (card creation, status updates), the failure is logged as a warning and the pipeline continues — VK is not on the critical path. For agent execution calls (`vibekanban task run` in Code mode), the failure is treated as an agent failure and follows the standard agent retry-once-then-halt behavior.

### 2.8 [Minor] Design Spec — Code Mode Testing Requirements or Phase 3 Code Mode

Add the following:

> **Test framework selection:** The test framework is determined during Phase 2 as part of the proposed architecture (language, tools, dependencies). The `test-runner.js` module executes tests using the framework specified in `spec.md`. It is not prescriptive about which framework — it adapts to whatever was decided during spec building.

### 2.9 [Minor] Execution Plan — Task 10 description

Replace Task 10's current description with:

> Implement action buttons: Distill (Phase 1 intake trigger) and Confirm (phase advancement mechanism). Include button debounce: disable on press until operation completes, server-side duplicate request detection (ignore duplicates, return current state).

---

## Section 3: Extractions — Move from Design Spec to Build Spec

### 3.1 [Minor] Design Spec — Phase 1, step 9 (steps 9.1–9.4 "realign from here" algorithm)

Replace the detailed steps 9.1–9.4 in the Design Spec with this summary:

> Human can type "realign from here" in chat. The AI identifies the most recent substantive correction, discards all AI and human messages after that point from the working context (retaining them in `chat_history.json` for audit), and re-distills from the original brain dump plus all corrections up to that baseline. If no corrections exist yet, the command is ignored with a prompt to provide a correction first. Implementation algorithm in build spec.

Then add the following to the Build Spec as a new subsection (e.g., under Phase 1 implementation details or as a "Realign Algorithm" section):

> **Realign Algorithm (Phase 1, step 9):**
> 1. **Baseline identification:** Scan backwards through `chat_history.json` past any sequential "realign from here" commands to find the most recent substantive human correction.
> 2. **Context truncation:** Exclude all AI and human messages after the identified baseline from the working context. Retain excluded messages in `chat_history.json` for audit trail.
> 3. **Re-distillation scope:** Re-distill from the original brain dump plus all human corrections up to the identified baseline.
> 4. **No-correction guard:** If no human corrections exist yet (only the original brain dump), ignore the "realign from here" command and prompt the human to provide a correction first.

### 3.2 [Minor] Design Spec — Phase 1, step 0, Project ID format

Find the project ID format specification (`{timestamp}-{random}`, e.g., `20260214-a3f2`). Replace it with:

> **Project ID format:** A URL-safe, filesystem-safe, unique string identifier. Format defined in build spec.

The build spec already has this detail in its Project Initialization Sequence section — no build spec change needed.

### 3.3 [Minor] Design Spec — WebSocket reconnection details

Find the WebSocket reconnection description mentioning exponential backoff, "Reconnecting..." indicator. Replace with:

> **Reconnection behavior:** The client auto-reconnects on disconnection. During disconnection, the chat UI displays a visible connection status indicator. On successful reconnect, state is synced from the server. Reconnection parameters (backoff strategy, timing) are in the build spec.

The build spec already has a "WebSocket Reconnection Parameters" section — no build spec change needed.

---

## After All Changes Are Applied

1. Re-read each modified file to confirm no formatting is broken (unclosed tables, orphaned headers, broken markdown).
2. Git add only files you actually modified:
   ```bash
   git add docs/thoughtforge-design-specification.md docs/thoughtforge-build-spec.md docs/thoughtforge-execution-plan.md
   ```
3. Commit with message: `Apply review findings`
4. Push to remote: `git push`
5. Confirm the push succeeded. Do not leave commits unpushed.
