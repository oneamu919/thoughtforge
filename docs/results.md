Now I have all four documents. Let me produce the review.

---

# Project Plan Review — ThoughtForge Execution Plan

Review performed against: `thoughtforge-execution-plan.md`, informed by the design specification, build spec, and requirements brief.

---

## 1. Writing That's Unclear

**[Minor] — "Task 21a depends on Task 7a but has no dependency on Task 21's other dependencies"**

The execution plan lists Task 21a (Draft `/prompts/code-build.md`) as depending only on Task 7a, but it sits visually inside Build Stage 4 alongside Task 21, creating ambiguity about whether it should start before or after Task 20. Same applies to Task 15a inside Build Stage 3. The "Depends On" column is correct, but the visual grouping misleads.

**Replacement:** Add a note above Build Stages 3 and 4 (matching the style of the cross-stage dependency note already used in Stage 1):

> **Prompt drafting tasks** (15a, 21a) depend only on Task 7a (prompt file directory), not on the surrounding stage tasks. They can begin as soon as Task 7a completes.

---

**[Minor] — Build Stage 8 testing strategy mixes unit and e2e definitions**

The line "Unit tests (Tasks 45–50b) use mocked dependencies" groups Task 50b but also 50c alongside tasks in the 45-50 range, yet Tasks 58a–58k are also labeled "Unit tests." The numeric grouping creates a false impression that 45–50 range and 58 range serve different test tiers.

**Replacement text for the testing strategy note:**

> **Testing Strategy:** Unit tests (Tasks 45–50c, 58–58k) use mocked dependencies — no real agent CLI calls, no real file system for state tests, no real API calls for connectors. End-to-end tests (Tasks 51–57) run the full pipeline with real agent invocations against a test project. Synthetic convergence guard tests (Task 54) use fabricated `polish_state.json` data, not real polish loop runs.

---

**[Minor] — "Test parallel execution with multiple concurrent projects" (Task 29, Build Stage 5) vs. Task 56 (Build Stage 8)**

Task 29 says "Test parallel execution with multiple concurrent projects" and Task 56 says "Test parallel execution (3 concurrent projects, different agents)." It's unclear whether Task 29 is an integration smoke test and Task 56 is the real e2e test, or if they duplicate.

**Replacement for Task 29 description:**

> Integration test: Vibe Kanban adapter handles concurrent card creation, status updates, and agent execution for 2+ projects without interference

This distinguishes it from Task 56 (full e2e pipeline parallelism).

---

**[Minor] — Cross-stage dependency note in Build Stage 1 says "Stage 1 Tasks 2–6e and Stage 7 Tasks 41–44 can proceed in parallel"**

This overstates parallelism. Tasks 6c, 6d depend on Task 7 (Stage 2). Task 6b depends on 6d. These can't proceed until Stage 2 begins. The note should be scoped to the tasks that genuinely parallelize with Stage 7.

**Replacement text:**

> **Cross-stage dependency:** Agent Layer (Build Stage 7, Tasks 41–44) provides the core agent invocation mechanism used by Stages 2–6. Task 41 depends only on Task 1 (foundation), so Build Stage 7 should begin as soon as Task 1 completes. Stage 1 foundation tasks (2–6a) and Stage 7 tasks (41–44) can proceed in parallel. Tasks 6b–6e have dependencies into Stages 2 and 7 — see individual task "Depends On" columns. Any task that invokes an AI agent (Tasks 8, 12, 15, 21, 30) must wait for Tasks 41–42 to complete.

---

**[Minor] — "All Build Stage 1 tasks done" as exit criteria for "Foundation complete" milestone**

Build Stage 1 includes Tasks 6c and 6d, which depend on the chat interface (Task 7, Build Stage 2). This means the "Foundation complete" milestone can never be reached before Stage 2 work begins, contradicting the milestone's purpose as a gate for starting Stage 2.

**Replacement for the Foundation Complete milestone row:**

| Foundation complete | TBD | Project scaffolding, state module, config, notifications, plugin loader, orchestrator core | Tasks 1–6a, 3a, and 4–5 done. Tasks 6b–6e complete after their Stage 2 dependencies. |

---

## 2. Genuinely Missing Plan-Level Content

**[Major] — No critical path identification**

The execution plan has 8 build stages, 70+ tasks, and multiple cross-stage dependencies, but does not identify the critical path — the longest chain of dependent tasks that determines minimum build duration. Without this, the builder cannot prioritize and the risk of delayed completion is high.

**Proposed content to add (new section after "Task Breakdown"):**

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

**[Major] — No acceptance criteria or definition of done for individual tasks**

The plan defines completion checklist items for the entire project but has no acceptance criteria per task. When an AI coder picks up Task 8 ("Implement Phase 1: brain dump intake"), there is no stated definition of when that task is done. The "depends on" column tells ordering but not exit conditions.

**Proposed content to add (new section after "Task Breakdown" or as a note within it):**

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

**[Minor] — No rollback or revert strategy**

The design spec establishes git commits at every milestone and twice per polish iteration, explicitly for rollback capability. The execution plan never states how a failed task or bad build is reverted. For a build executed by AI agents, this matters.

**Proposed content to add (new section after Risk Register):**

> ## Rollback Strategy
>
> Each project's per-milestone git commits enable rollback at the project level. For ThoughtForge's own codebase during build:
> - Each completed task should be committed to the ThoughtForge repo before starting the next task
> - If a task introduces regressions (breaks previously passing tests), revert the task's commit and reattempt
> - The builder should not proceed to the next task if the current task's tests fail

---

**[Minor] — No mention of development environment setup or prerequisites for the builder**

The Dependencies & Blockers table lists runtime dependencies (Node.js, agent CLIs, Vibe Kanban) but does not state what the AI coder or human builder needs before starting Task 1 — for example, which Node.js version, whether to use npm or another package manager, whether TypeScript is used (Zod and the TypeScript interfaces in the build spec imply yes, but it's never stated).

**Proposed content to add to Dependencies & Blockers section:**

| Node.js version ≥18 LTS | Dependency | — | — | Required for native fetch, stable ES module support |
| Package manager: npm | Dependency | — | — | Default Node.js package manager, no additional install |
| Language: TypeScript | Dependency | — | — | Implied by Zod schemas and interface definitions in build spec. Confirm or document as JavaScript-only with JSDoc types. |

---

## 3. Build Spec Material That Should Be Extracted

**[Minor] — Task 1 description includes implementation detail: "exit with descriptive error on missing file, invalid YAML, or schema violations"**

This behavior is already fully specified in the build spec's config validation section and the design spec's Config Validation paragraph. The execution plan task description should reference what to build, not replicate how it behaves on error.

**Replacement task description:**

> Initialize Node.js project, folder structure, `config.yaml` loader with Zod schema validation (per design spec Config Validation and build spec `config.yaml` Template sections)

---

**[Minor] — Task 2 description includes implementation detail: "unique ID generation, `/projects/{id}/` directory scaffolding (including `/docs/` and `/resources/`), git repo init, initial `status.json` write"**

This sequence is already documented in the build spec's Project Initialization Sequence section. The execution plan task should reference that section rather than duplicate the steps.

**Replacement task description:**

> Implement project initialization sequence (per build spec Project Initialization Sequence): ID generation, directory scaffolding, git init, initial state, Vibe Kanban card (if enabled), chat thread creation

---

**[Minor] — Task 1c description includes full recovery algorithm: "scan `/projects/` for non-terminal projects, resume human-interactive states, halt autonomous states (`distilling`, `building`, `polishing`) with `halt_reason: server_restart`, notify human for each halted project"**

This is the full Server Restart Behavior algorithm from the design spec. In an execution plan, the task should state what to implement and reference where the spec lives, not re-state the algorithm.

**Replacement task description:**

> Implement server restart recovery (per design spec Server Restart Behavior): resume interactive-state projects, halt autonomous-state projects, notify human for halted projects

---

**[Minor] — Task 9 includes algorithm detail: "discard post-correction AI revisions, re-distill from brain dump + corrections up to baseline message"**

The Realign Algorithm is fully specified in the build spec. The task description should reference it, not repeat it.

**Replacement task description:**

> Implement correction loop: chat-based revisions with AI re-presentation, and "realign from here" command (per build spec Realign Algorithm)

---

**[Minor] — Task 30 description replicates guard evaluation order: "(Termination → Hallucination → Fabrication → Stagnation → Max iterations; first trigger ends evaluation)"**

This is fully specified in the build spec's Guard Evaluation Order section. The task should reference that, not repeat the sequence.

**Replacement task description:**

> Implement orchestrator loop: review call → parse → validate → fix call → commit. Guard evaluation per build spec Guard Evaluation Order (first trigger ends evaluation).

---

That concludes the review. The plan is comprehensive and well-structured. The two Major findings (critical path identification and per-task acceptance criteria) are the most important additions before build begins. The rest are clarity and deduplication improvements.
