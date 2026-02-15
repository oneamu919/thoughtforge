# Apply Review Findings from results.md

You are an AI coder. Apply every change listed below to the source files. Each change is either a **replacement** (swap existing text for new text), an **addition** (insert new content at a specified location), or an **extraction** (move content from one file to another). Do not interpret or improvise — apply as written.

**Do NOT modify files in `docs.backup/`.** Only modify the primary files in `docs/`.

---

## Source Files

- **Design Spec:** `docs/thoughtforge-design-specification.md`
- **Build Spec:** `docs/thoughtforge-build-spec.md`
- **Execution Plan:** `docs/thoughtforge-execution-plan.md`

Read ALL three files in full before making any edits.

---

## Section 1: Replacements — Unclear Writing

### 1.1 [Major] — Fix Task 33a description (Execution Plan)

**Find** Task 33a's description (contains "compare post-fix error count to pre-fix review count").

**Replace with:**

> Implement convergence guard: fix regression (per-iteration check — compare current iteration's review error count to prior iteration's review error count, warn on single increase, halt on 2 consecutive increases). Evaluated after each review step, before other convergence guards.

---

### 1.2 [Major] — Fix critical path description (Execution Plan)

**Find** the critical path section that contains "Task 13 → Task 15 → Task 6c" and its surrounding explanation.

**Replace with:**

> The functional critical path extends beyond the declared code dependencies. While Task 6c's code dependencies are Tasks 5, 6a, and 7, the Phase 3→4 transition cannot be end-to-end exercised without Phase 2 outputs (Task 13: `spec.md`, `constraints.md`) and a Phase 3 builder (Task 15 for Plan mode, Task 21 for Code mode). The exercisable critical path is therefore: Task 1 → [Task 41 → Task 42 | Task 2 → Task 3 | Task 6] → Task 6a → Task 8 → Task 9 → Task 11 → Task 12 → Task 13 → Task 15 → Task 30 → Tasks 33–37 → Task 51. Task 6c is on this chain implicitly — its code can be built after Task 6a, but cannot be validated until Task 15 produces deliverables.

---

### 1.3 [Major] — Add concurrency clarification (Design Spec)

**Find** the concurrency section paragraph about "Halted projects and concurrency."

**After** that paragraph, **add:**

> **Terminated projects and concurrency:** Projects terminated by the human (`halt_reason: "human_terminated"`) are functionally finished but use the `halted` state, which counts toward the concurrency limit. To free the slot, the operator must manually delete the project directory. There is no "archive" or "close" action in v1 that moves a terminated project to a non-counting state.

---

### 1.4 [Minor] — Fix constraints.md acceptance criteria line (Build Spec)

**Find** the `constraints.md` Structure section, Acceptance Criteria line (contains "5–10 statements of what the deliverable must contain or do" without the enforced-minimum language).

**Replace with:**

> `{At least 1 (enforced at creation), target 5–10 statements of what the deliverable must contain or do}`

---

### 1.5 [Minor] — Fix parallelism note (Execution Plan)

**Find** the parallelism note that says "After Tasks 41–42: All prompt drafting tasks (7a, 7f, 6e, 15a, 21a, 30a, 30b) — depend only on Task 7a."

**Replace with:**

> - **After Task 1 (via Task 7a):** All prompt drafting tasks (7f, 6e, 15a, 21a, 30a, 30b) — depend only on Task 7a, which depends on Task 1. These can be parallelized with Stage 7.

---

### 1.6 [Minor] — Fix config.yaml concurrency comment (Build Spec)

**Find** the `config.yaml` template concurrency section. Remove any comment referencing "managed by Vibe Kanban."

**Replace with:**

```yaml
# Parallel execution (enforced by ThoughtForge orchestrator)
concurrency:
  max_parallel_runs: 3
```

---

### 1.7 [Minor] — Fix Telegram section in config.yaml template (Build Spec)

**Find** the `telegram` section in the `config.yaml` template.

**Replace with:**

```yaml
    telegram:
      enabled: false   # Reserved for future implementation — not built in v1
      bot_token: ""
      chat_id: ""
```

---

## Section 2: Additions — Missing Plan-Level Content

### 2.1 [Critical] — Add Code Mode Safety Rules (Design Spec)

**Location:** After the "Plan Mode Safety Guardrails" section.

**Insert:**

> #### Code Mode Safety Rules
>
> Code mode permits all operations in the Operation Type Taxonomy: `shell_exec`, `file_create_source`, `file_create_doc`, `file_create_state`, `agent_invoke`, `package_install`, `test_exec`, `git_commit`. The `safety-rules.js` for Code mode returns `{ allowed: true }` for all operation types. The safety rules module exists to maintain the uniform plugin interface contract — the orchestrator calls `validate()` for every Phase 3/4 action regardless of mode. Future restrictions (e.g., blocking operations outside the project directory) can be added to Code mode's `safety-rules.js` without changing the orchestrator.

---

### 2.2 [Major] — Add task_queue.json schema (Build Spec)

**Location:** After the "Code Builder Task Queue" paragraph.

**Insert:**

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

### 2.3 [Major] — Add Code mode test file detection (Design Spec)

**Location:** Phase 3→4 Transition section, near the `code_require_tests` reference.

**Insert:**

> **Code mode test file detection:** A test file is identified by any of: filename contains `.test.` or `.spec.` (e.g., `app.test.ts`, `utils.spec.js`), or the file resides in a directory named `test/`, `tests/`, or `__tests__/`. The check scans the project directory recursively. If no files match and `code_require_tests` is true, the transition halts.

---

### 2.4 [Major] — Add tsx to devDependencies (Build Spec)

**Location:** Initial Dependencies section, `devDependencies`.

**Add** `"tsx": "^4.x"` so the section reads:

```json
"devDependencies": {
    "typescript": "^5.x",
    "vitest": "^1.x",
    "tsx": "^4.x"
}
```

---

### 2.5 [Minor] — Add git commit message format (Build Spec)

**Location:** After the "Git Commit Strategy" section or mention.

**Insert:**

> **Git Commit Message Format:**
> - Phase 1 lock: `"ThoughtForge: intent.md locked"`
> - Phase 2 lock: `"ThoughtForge: spec.md and constraints.md locked"`
> - Phase 3 complete: `"ThoughtForge: Phase 3 build complete"`
> - Phase 4 review: `"ThoughtForge: Phase 4 iteration {N} — review ({critical}c/{medium}m/{minor}i)"`
> - Phase 4 fix: `"ThoughtForge: Phase 4 iteration {N} — fix applied"`
> - Phase 4 resume: `"ThoughtForge: Phase 4 resumed at iteration {N}"`

---

### 2.6 [Minor] — Add Levenshtein pre-build decision (Execution Plan)

**Location:** Design Decisions section.

**Insert:**

> **Pre-build decision: Levenshtein implementation.** Decide before Task 35 whether to install `fastest-levenshtein` (add to dependencies) or implement the ~15-line algorithm inline in the stagnation guard module. Inline is recommended to avoid an external dependency for a trivial algorithm.

---

### 2.7 [Minor] — Add task_queue.json unit test task to Build Stage 8 (Execution Plan)

**Location:** Build Stage 8 task table.

**Add row:**

> | 58n | Unit tests: Code mode task queue (`task_queue.json` persistence, crash recovery resumes from correct task, completed tasks not re-executed, corrupted file halts with notification) | — | Task 21 | — | Not Started |

---

## Section 3: Extractions — Move Content Between Files

### 3.1 [Minor] — Extract truncation strategy detail (Design Spec → Build Spec)

**In Design Spec**, find the "Template Context Window Overflow" paragraph (~line 239) that contains: "passes only the current section's OPA table slot, the `spec.md` context for that section, and the immediately preceding section."

**Replace in Design Spec with:**

> If the partially-filled template exceeds the agent's context window, the builder truncates context to fit. Truncation strategy is defined in the build spec.

**Add to Build Spec** (near the existing `constraints.md` Truncation Strategy section), new section:

> **Plan Builder Context Window Truncation Strategy:** When the partially-filled template exceeds the context window, the builder passes only the current section's OPA table slot, the `spec.md` context for that section, and the immediately preceding section.

---

### 3.2 [Minor] — Extract Code mode review context detail (Design Spec → Build Spec)

**In Design Spec**, find the "Code mode review context" paragraph (~line 374) that specifies "full source for small codebases, file manifest plus git diff for larger codebases."

**Replace in Design Spec with:**

> The review prompt includes `constraints.md`, test results, and codebase content. Context assembly strategy (full source vs. diff-based) is defined in the build spec.

**Add to Build Spec** (near the Fix Agent Context Assembly section), new section:

> **Code Mode Review Context Assembly Strategy:** The review agent receives full source for small codebases, or a file manifest plus git diff for larger codebases.

---

## After All Changes Are Applied

1. Re-read each modified file to verify no formatting was broken, no surrounding content was accidentally deleted or duplicated, and all changes landed correctly.
2. Git commit and sync:

```bash
git status -u
git diff --stat
git add docs/thoughtforge-design-specification.md docs/thoughtforge-build-spec.md docs/thoughtforge-execution-plan.md
git commit -m "Apply review findings"
git push
git pull
```

Do not skip the push step.
