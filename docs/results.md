I've now read all four documents in full. Let me produce the review.

---

# Plan Review — ThoughtForge Design Specification, Build Spec, and Execution Plan

Reviewed against: `thoughtforge-requirements-brief.md` (context), `thoughtforge-design-specification.md`, `thoughtforge-build-spec.md`, `thoughtforge-execution-plan.md`

---

## 1. Writing That's Unclear

**[Major] Fix Regression guard description contradicts between design spec and execution plan Task 33a.**

The design spec (Phase 4 Convergence Guards table) describes Fix Regression as comparing "the current iteration's total error count against the previous iteration's total error count" — meaning it compares review-to-review across iterations. The execution plan Task 33a says "compare post-fix error count to pre-fix review count" — meaning it compares within the same iteration. These are two different comparisons. The design spec's description is the authoritative one based on the surrounding explanation ("iteration N's review reveals the error state after iteration N-1's fix"). Task 33a must match.

**Replacement text for Task 33a:**
> Implement convergence guard: fix regression (per-iteration check — compare current iteration's review error count to prior iteration's review error count, warn on single increase, halt on 2 consecutive increases). Evaluated after each review step, before other convergence guards.

---

**[Major] Critical path chain includes Task 15 between Task 13 and Task 6c, but Task 6c's declared dependency is on Tasks 5, 6a, and 7 — not Task 15 or Task 13.**

The critical path section states "Task 13 → Task 15 → Task 6c" and adds a parenthetical justification, but the explanation conflates functional exercisability with dependency. If this is meant to represent the functional critical path for testing (not the code dependency chain), the writing is unclear. A builder following the task table will not see this link.

**Replacement text:**
> The functional critical path extends beyond the declared code dependencies. While Task 6c's code dependencies are Tasks 5, 6a, and 7, the Phase 3→4 transition cannot be end-to-end exercised without Phase 2 outputs (Task 13: `spec.md`, `constraints.md`) and a Phase 3 builder (Task 15 for Plan mode, Task 21 for Code mode). The exercisable critical path is therefore: Task 1 → [Task 41 → Task 42 | Task 2 → Task 3 | Task 6] → Task 6a → Task 8 → Task 9 → Task 11 → Task 12 → Task 13 → Task 15 → Task 30 → Tasks 33–37 → Task 51. Task 6c is on this chain implicitly — its code can be built after Task 6a, but cannot be validated until Task 15 produces deliverables.

---

**[Major] Concurrency limit: design spec says `halted` is not terminal and counts toward the limit, but also says `done` is the only way to free a slot. The `status.json` schema table says `done` "Does not count toward concurrency limit" — implying `done` frees a slot. But the design spec concurrency section says "The only way to free a concurrency slot is for the project to reach `done` status or for the operator to manually delete the project directory." This means `human_terminated` projects (which use `halted` state) permanently consume a concurrency slot until manually deleted.**

This is a design decision, but the consequence is unstated and will surprise the builder. A terminated project that is functionally finished still blocks a concurrency slot.

**Add this clarification to the design spec concurrency section, after "Halted projects and concurrency":**
> **Terminated projects and concurrency:** Projects terminated by the human (`halt_reason: "human_terminated"`) are functionally finished but use the `halted` state, which counts toward the concurrency limit. To free the slot, the operator must manually delete the project directory. There is no "archive" or "close" action in v1 that moves a terminated project to a non-counting state.

---

**[Minor] Design spec Phase 2 step 4 says "The validation gate enforces a minimum of 1 criterion; the target range of 5–10 is guidance for the AI prompt, not an enforced threshold." But the `constraints.md` structure table in the same document says "At least 1, target 5–10 statements." The build spec `constraints.md` structure says "5–10 statements of what the deliverable must contain or do" with no mention of the minimum-1 enforcement.**

The build spec template should match the design spec's clarified language.

**Replacement text for the build spec `constraints.md` Structure, Acceptance Criteria line:**
> `{At least 1 (enforced at creation), target 5–10 statements of what the deliverable must contain or do}`

---

**[Minor] Execution plan parallelism note says "After Tasks 41–42: All prompt drafting tasks (7a, 7f, 6e, 15a, 21a, 30a, 30b) — depend only on Task 7a."**

Task 7a depends on Task 1, not Tasks 41–42. The prompt drafting tasks can begin after Task 1 (via Task 7a), not after Tasks 41–42. The "After Tasks 41–42" grouping is misleading.

**Replacement text:**
> - **After Task 1 (via Task 7a):** All prompt drafting tasks (7f, 6e, 15a, 21a, 30a, 30b) — depend only on Task 7a, which depends on Task 1. These can be parallelized with Stage 7.

---

**[Minor] Build spec `config.yaml` template comments say `concurrency.max_parallel_runs` is "managed by Vibe Kanban," but the design spec explicitly states "Enforcement is at the ThoughtForge orchestrator level, not delegated to Vibe Kanban."**

**Replacement text for the config.yaml template comment:**
```yaml
# Parallel execution (enforced by ThoughtForge orchestrator)
concurrency:
  max_parallel_runs: 3
```

---

**[Minor] Design spec says the Telegram notification channel is in the config template, but there is no plan-level mention of implementing a Telegram channel. The build spec config template includes `telegram` with `bot_token` and `chat_id` fields. No task in the execution plan covers Telegram implementation.**

If Telegram is v1 scope, it needs a task. If it's a config placeholder for future use, say so.

**Replacement text (add to config.yaml template, telegram section):**
```yaml
    telegram:
      enabled: false   # Reserved for future implementation — not built in v1
      bot_token: ""
      chat_id: ""
```

---

## 2. Genuinely Missing Plan-Level Content

**[Critical] No definition of what Code mode `safety-rules.js` allows and blocks.**

Plan mode safety rules are exhaustively defined: no shell exec, no source files, no package installs, no test exec. Code mode has Task 23 ("Implement `safety-rules.js` — Code mode permissions") but the design spec says only "Code mode permissions" with no specification of what operations are allowed or blocked. The Operation Type Taxonomy in the build spec lists all operation types, and the design spec defines Plan mode's rules against that taxonomy, but Code mode's rules are absent. The builder cannot implement Task 23 without knowing the policy.

**Proposed content (add to design spec, after Plan Mode Safety Guardrails section):**
> #### Code Mode Safety Rules
>
> Code mode permits all operations in the Operation Type Taxonomy: `shell_exec`, `file_create_source`, `file_create_doc`, `file_create_state`, `agent_invoke`, `package_install`, `test_exec`, `git_commit`. The `safety-rules.js` for Code mode returns `{ allowed: true }` for all operation types. The safety rules module exists to maintain the uniform plugin interface contract — the orchestrator calls `validate()` for every Phase 3/4 action regardless of mode. Future restrictions (e.g., blocking operations outside the project directory) can be added to Code mode's `safety-rules.js` without changing the orchestrator.

---

**[Major] No specification of how the code builder's `task_queue.json` is structured.**

The design spec mentions task decomposition and persisting to `task_queue.json`. The build spec mentions "Code Builder Task Queue" briefly. But there is no schema for `task_queue.json` — unlike `status.json`, `polish_state.json`, and `chat_history.json`, which all have TypeScript interface definitions. The builder needs to know the structure.

**Proposed content (add to build spec, after the Code Builder Task Queue paragraph):**
```typescript
interface TaskQueueEntry {
  id: string;           // Unique task identifier (e.g., "task_1", "task_2")
  description: string;  // What this task builds (derived from spec.md)
  status: "pending" | "in_progress" | "completed" | "failed";
  attempts: number;     // Consecutive failure count for stuck detection
}

type TaskQueue = TaskQueueEntry[];
```

---

**[Major] No specification for how Code mode Phase 3→4 transition validates "at least one test file" when `code_require_tests` is true.**

The config has `phase3_completeness.code_require_tests: true` and the design spec says Code mode checks for "at least one test file." But what constitutes a "test file" is unspecified. The builder needs a detection heuristic (file naming convention, directory convention, or `package.json` test script existence).

**Proposed content (add to design spec, Phase 3→4 Transition section, or build spec):**
> **Code mode test file detection:** A test file is identified by any of: filename contains `.test.` or `.spec.` (e.g., `app.test.ts`, `utils.spec.js`), or the file resides in a directory named `test/`, `tests/`, or `__tests__/`. The check scans the project directory recursively. If no files match and `code_require_tests` is true, the transition halts.

---

**[Major] No plan for how `tsx` (the TypeScript execution tool) is installed or managed.**

The execution plan Design Decisions section says "ThoughtForge runs via `tsx` (or `ts-node`) during development." But `tsx` is not in the Initial Dependencies list in the build spec. Neither is `ts-node`. The builder will hit this gap immediately at Task 1.

**Proposed content (add `tsx` to build spec Initial Dependencies, devDependencies):**
```json
"devDependencies": {
    "typescript": "^5.x",
    "vitest": "^1.x",
    "tsx": "^4.x"
}
```

---

**[Minor] No specification of git commit message format for pipeline milestone commits and Phase 4 iteration commits.**

Task 2a implements milestone commits and Task 40 implements per-iteration commits. Neither the design spec nor build spec specifies what the commit messages should contain. Consistent commit messages are important for the rollback strategy to be usable (the human needs to identify which commit corresponds to which pipeline event).

**Proposed content (add to build spec, after the Git Commit Strategy mention, or as a new section):**
> **Git Commit Message Format:**
> - Phase 1 lock: `"ThoughtForge: intent.md locked"`
> - Phase 2 lock: `"ThoughtForge: spec.md and constraints.md locked"`
> - Phase 3 complete: `"ThoughtForge: Phase 3 build complete"`
> - Phase 4 review: `"ThoughtForge: Phase 4 iteration {N} — review ({critical}c/{medium}m/{minor}i)"`
> - Phase 4 fix: `"ThoughtForge: Phase 4 iteration {N} — fix applied"`
> - Phase 4 resume: `"ThoughtForge: Phase 4 resumed at iteration {N}"`

---

**[Minor] No plan-level guidance on what happens when the Levenshtein dependency decision (install package vs. implement inline) is made.**

The build spec says "Either install a lightweight npm package (e.g., `fastest-levenshtein`) or implement inline." This is a decision for the builder, but it's unresolved. Since the plan calls for a pre-build decision on the test framework, this small dependency decision should also be flagged.

**Proposed content (add to execution plan Design Decisions section):**
> **Pre-build decision: Levenshtein implementation.** Decide before Task 35 whether to install `fastest-levenshtein` (add to dependencies) or implement the ~15-line algorithm inline in the stagnation guard module. Inline is recommended to avoid an external dependency for a trivial algorithm.

---

**[Minor] Missing unit test task for `task_queue.json` persistence and crash recovery in Code mode.**

Build Stage 8 has unit tests for `status.json`, `polish_state.json`, and `chat_history.json` crash recovery, but no test task for `task_queue.json` crash recovery (which the design spec explicitly calls out: "On crash recovery, the builder re-reads `task_queue.json`").

**Proposed content (add to Build Stage 8):**
> | 58n | Unit tests: Code mode task queue (`task_queue.json` persistence, crash recovery resumes from correct task, completed tasks not re-executed, corrupted file halts with notification) | — | Task 21 | — | Not Started |

---

## 3. Build Spec Material That Should Be Extracted

**[Minor] Design spec "Phase 1 System Prompt — Brain Dump Intake" inline prompt text (lines 38–65 of the build spec).**

The full prompt text is already correctly placed in the build spec. However, the design spec section "Brain Dump Intake Prompt Behavior" (line 128) summarizes the prompt's rules — this summary is fine for a design spec. No extraction needed here; the current split is correct. Noting this as a false positive I considered and rejected.

**[Minor] Design spec "Template Context Window Overflow" paragraph (lines 239 of the design spec) contains the specific truncation strategy: "passes only the current section's OPA table slot, the `spec.md` context for that section, and the immediately preceding section."**

This level of context assembly detail — which specific pieces are included and excluded during truncation — is implementation guidance that belongs in the build spec alongside the existing `constraints.md` Truncation Strategy section.

**Recommendation:** Move this paragraph to the build spec as a new section "Plan Builder Context Window Truncation Strategy" and replace it in the design spec with: "If the partially-filled template exceeds the agent's context window, the builder truncates context to fit. Truncation strategy is defined in the build spec."

---

**[Minor] Design spec "Code mode review context" paragraph (line 374) specifies the exact context assembly strategy: "full source for small codebases, file manifest plus git diff for larger codebases."**

This is context assembly implementation detail — the same category of information as the Fix Agent Context Assembly and `constraints.md` Truncation Strategy sections already in the build spec.

**Recommendation:** Move this to the build spec as a new section "Code Mode Review Context Assembly Strategy" and replace in the design spec with: "The review prompt includes `constraints.md`, test results, and codebase content. Context assembly strategy (full source vs. diff-based) is defined in the build spec."

---

**[Minor] Build spec HTTP API Surface table (lines 609-624) is in the build spec, which is correct. But the build spec itself says "Route structure is a build-time implementation detail — the above is guidance, not a rigid contract." This disclaimer is fine — the table belongs in the build spec, not the design spec. No action needed.**

This was a false positive I reviewed and rejected. The API surface is appropriately placed.
