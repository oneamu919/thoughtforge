# Apply Review Findings from results.md

You are an AI coder. Apply every change listed below to the source files. Each change is taken directly from the review findings in `docs/results.md`. Do not interpret or improvise — apply the replacements, additions, and extractions exactly as specified.

Read all target files before editing. After all changes are applied, git commit and sync to remote.

---

## Target File

- `docs/thoughtforge-execution-plan.md` (referred to as "Execution Plan")

Read this file before making any edits.

---

## Changes to Apply

### Change 1 — Add prompt-drafting clarification note (Minor)

**Location:** Above Build Stages 3 and 4 (before the task tables for those stages), matching the style of the cross-stage dependency note already used in Stage 1.

**Add this note:**

> **Prompt drafting tasks** (15a, 21a) depend only on Task 7a (prompt file directory), not on the surrounding stage tasks. They can begin as soon as Task 7a completes.

---

### Change 2 — Replace testing strategy note in Build Stage 8 (Minor)

**Location:** Build Stage 8, the existing testing strategy note.

**Replace with:**

> **Testing Strategy:** Unit tests (Tasks 45–50c, 58–58k) use mocked dependencies — no real agent CLI calls, no real file system for state tests, no real API calls for connectors. End-to-end tests (Tasks 51–57) run the full pipeline with real agent invocations against a test project. Synthetic convergence guard tests (Task 54) use fabricated `polish_state.json` data, not real polish loop runs.

---

### Change 3 — Replace Task 29 description (Minor)

**Location:** Task 29 in Build Stage 5, the task description column.

**Replace the description with:**

> Integration test: Vibe Kanban adapter handles concurrent card creation, status updates, and agent execution for 2+ projects without interference

---

### Change 4 — Replace cross-stage dependency note in Build Stage 1 (Minor)

**Location:** Build Stage 1, the existing cross-stage dependency note.

**Replace with:**

> **Cross-stage dependency:** Agent Layer (Build Stage 7, Tasks 41–44) provides the core agent invocation mechanism used by Stages 2–6. Task 41 depends only on Task 1 (foundation), so Build Stage 7 should begin as soon as Task 1 completes. Stage 1 foundation tasks (2–6a) and Stage 7 tasks (41–44) can proceed in parallel. Tasks 6b–6e have dependencies into Stages 2 and 7 — see individual task "Depends On" columns. Any task that invokes an AI agent (Tasks 8, 12, 15, 21, 30) must wait for Tasks 41–42 to complete.

---

### Change 5 — Replace "Foundation Complete" milestone row (Minor)

**Location:** The milestones table, the row for "Foundation complete."

**Replace with:**

| Foundation complete | TBD | Project scaffolding, state module, config, notifications, plugin loader, orchestrator core | Tasks 1–6a, 3a, and 4–5 done. Tasks 6b–6e complete after their Stage 2 dependencies. |

---

### Change 6 — Replace Task 1 description (Minor)

**Location:** Task 1 description in Build Stage 1.

**Replace with:**

> Initialize Node.js project, folder structure, `config.yaml` loader with Zod schema validation (per design spec Config Validation and build spec `config.yaml` Template sections)

---

### Change 7 — Replace Task 2 description (Minor)

**Location:** Task 2 description in Build Stage 1.

**Replace with:**

> Implement project initialization sequence (per build spec Project Initialization Sequence): ID generation, directory scaffolding, git init, initial state, Vibe Kanban card (if enabled), chat thread creation

---

### Change 8 — Replace Task 1c description (Minor)

**Location:** Task 1c description in Build Stage 1.

**Replace with:**

> Implement server restart recovery (per design spec Server Restart Behavior): resume interactive-state projects, halt autonomous-state projects, notify human for halted projects

---

### Change 9 — Replace Task 9 description (Minor)

**Location:** Task 9 description (wherever Task 9 resides in the execution plan).

**Replace with:**

> Implement correction loop: chat-based revisions with AI re-presentation, and "realign from here" command (per build spec Realign Algorithm)

---

### Change 10 — Replace Task 30 description (Minor)

**Location:** Task 30 description (wherever Task 30 resides in the execution plan).

**Replace with:**

> Implement orchestrator loop: review call → parse → validate → fix call → commit. Guard evaluation per build spec Guard Evaluation Order (first trigger ends evaluation).

---

### Change 11 — Add Critical Path section (Major)

**Location:** New section after "Task Breakdown" in the execution plan.

**Add:**

> ## Critical Path
>
> The longest dependency chain determines the minimum build duration regardless of parallelism:
>
> **Task 1 → Task 41 → Task 42 → Task 8 → Task 9 → Task 11 → Task 12 → Task 13 → Task 15 → Task 16 → Task 30 → Tasks 33–37 → Task 51**
>
> This chain runs from foundation through agent layer, human interaction, plan plugin, polish loop, to plan-mode e2e validation.
>
> **Secondary critical chain (Code mode):** Task 1 → Task 26 → Task 27 → Task 21 → Task 30c → Task 52
>
> Build schedule and parallelism decisions should optimize for keeping the critical path unblocked.

---

### Change 12 — Add Task Acceptance Criteria section (Major)

**Location:** New section after "Task Breakdown" (or after the Critical Path section added above).

**Add:**

> ## Task Acceptance Criteria
>
> Each task is complete when:
> 1. The described functionality works as specified in the design specification and build spec sections referenced by the task
> 2. The task's own unit tests (if a corresponding test task exists in Build Stage 8) pass with mocked dependencies
> 3. Any logging events produced by the task are routed through the operational logging module (Task 3a)
> 4. The implementation follows the interface contracts defined in the build spec (plugin interface, connector interface, notification payload, state file schemas)
>
> AI coders should reference the "Used by" annotations in the build spec to identify the authoritative specification for each task.

---

### Change 13 — Add Rollback Strategy section (Minor)

**Location:** New section after "Risk Register" in the execution plan.

**Add:**

> ## Rollback Strategy
>
> Each project's per-milestone git commits enable rollback at the project level. For ThoughtForge's own codebase during build:
> - Each completed task should be committed to the ThoughtForge repo before starting the next task
> - If a task introduces regressions (breaks previously passing tests), revert the task's commit and reattempt
> - The builder should not proceed to the next task if the current task's tests fail

---

### Change 14 — Add development environment prerequisites to Dependencies & Blockers table (Minor)

**Location:** The Dependencies & Blockers table in the execution plan. Add these rows:

| Node.js version ≥18 LTS | Dependency | — | — | Required for native fetch, stable ES module support |
| Package manager: npm | Dependency | — | — | Default Node.js package manager, no additional install |
| Language: TypeScript | Dependency | — | — | Implied by Zod schemas and interface definitions in build spec. Confirm or document as JavaScript-only with JSDoc types. |

---

## After All Changes Are Applied

1. Re-read the modified file to confirm no formatting is broken (unclosed tables, orphaned headers, broken markdown).
2. Git add only files you actually modified:
   ```bash
   git add docs/thoughtforge-execution-plan.md
   ```
3. Commit with message: `Apply review findings`
4. Push to remote: `git push`
5. Confirm the push succeeded. Do not leave commits unpushed.
