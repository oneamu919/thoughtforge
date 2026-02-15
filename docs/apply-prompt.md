# Apply Review Findings from results.md (Iteration 6)

Apply every change listed below to the source files. Each change is a direct replacement, addition, or extraction. Do not interpret or improvise — apply exactly what is specified.

Read all three source files and `results.md` before making changes so you have full context.

**Source files (all in `docs/`):**
- `docs/thoughtforge-design-specification.md` (referred to as "Design Spec")
- `docs/thoughtforge-build-spec.md` (referred to as "Build Spec")
- `docs/thoughtforge-execution-plan.md` (referred to as "Execution Plan")

---

## Section 1: Unclear Writing — Replacements

### 1.1 [Minor] Design Spec — Phase 1, Step 9 — "realign from here" scope

**Find:**
> Human can type "realign from here" in chat. The AI identifies the most recent substantive correction, discards all AI and human messages after that point from the working context (retaining them in `chat_history.json` for audit), and re-distills from the original brain dump plus all corrections up to that baseline.

**Replace with:**
> Human can type "realign from here" in chat. The AI scans backwards through chat history past any sequential "realign from here" commands to find the most recent human correction message. It discards all AI and human messages after that point from the working context (retaining them in `chat_history.json` for audit), and re-distills from the original brain dump plus all corrections up to that baseline.

### 1.2 [Minor] Design Spec — Phase 4, Stagnation guard row

**Find the Stagnation row in the Phase 4 convergence/termination table. Replace:**
> Stagnation | Same total error count for 3+ consecutive iterations AND issue rotation detected — fewer than 70% of current issues match prior iteration issues (match = issues with substantially similar descriptions, as determined by string similarity). Algorithmic parameters (similarity threshold, window sizes) defined in build spec. | Done (success). Notify human — same notification path as Termination success: status set to `done`, human notified with final error counts and iteration summary.

**With:**
> Stagnation | Same total error count for 3+ consecutive iterations AND issue rotation detected — fewer than 70% of current issues match prior iteration issues by description similarity. Algorithmic parameters (similarity threshold, window sizes) defined in build spec. | Done (success). Notify human — same notification path as Termination success: status set to `done`, human notified with final error counts and iteration summary.

### 1.3 [Minor] Design Spec — Notification Content table, `project_name` row

**Find the `project_name` row's Description cell** (which restates the derivation logic about extracting from intent.md and storing in status.json).

**Replace the Description cell with:**
> Human-readable project name. Derived during Phase 1 — see Project Name Derivation (Phase 1, step 0).

### 1.4 [Minor] Design Spec — Phase 2, step 3 — Unknown resolution guidance

**Find:**
> AI resolves Unknowns and Open Questions from `intent.md` — either by making a reasoned decision (stated in `spec.md`) or by asking the human during the Phase 2 chat. No unresolved unknowns may carry into `spec.md`.

**Replace with:**
> AI resolves Unknowns and Open Questions from `intent.md` — either by making a reasoned decision (stated in `spec.md`) or by asking the human during the Phase 2 chat. The Phase 2 prompt (`spec-building.md`) governs when the AI should decide autonomously vs. escalate to the human. No unresolved unknowns may carry into `spec.md`.

### 1.5 [Minor] Design Spec — Phase 3, Code Mode, step 3 — Logging

**Find:**
> Implements logging throughout the codebase (mandatory)

**Replace with:**
> Implements structured logging throughout the codebase (mandatory) — sufficient for production debugging. Logging framework and approach are determined by the Phase 2 spec.

### 1.6 [Minor] Execution Plan — Task 19

**Find Task 19 description:**
> Implement orchestrator-level safety-rules enforcement for Code mode: before each Phase 3/4 agent invocation, call the code plugin's `safety-rules.js` `validate(operation)` and block disallowed operations. This is the enforcement mechanism; the rules themselves are defined in Task 23.

**Apply one of these two options (prefer option a):**

**(a) Remove Task 19 entirely** — Task 6a already specifies safety-rules enforcement via `validate(operation)`. Delete the task row.

**(b) If Task 19 must remain**, replace the description with:
> Implement Code-mode-specific safety-rules enforcement: before each Phase 3/4 agent invocation in Code mode, call the code plugin's `safety-rules.js` `validate(operation)` and block disallowed operations. This extends the generic enforcement from Task 6a with Code-mode-specific operation classifications. Depends on: Task 6a, Task 20, Task 23.

And add Task 23 as an explicit dependency.

---

## Section 2: Missing Content — Additions

### 2.1 [Major] Design Spec — Operation Taxonomy (new content)

**File:** Design Spec, Plan Mode Safety Guardrails section (after the existing blocking table)

**Add the following paragraph:**
> **Operation Taxonomy:** The orchestrator classifies every Phase 3/4 action into an operation type before invoking the plugin's `validate()`. Operation types include: `shell_exec` (any subprocess or CLI command), `file_create` (creating a new file — subdivided by extension/location), `file_modify` (modifying an existing file), `package_install` (dependency installation), and `agent_invoke` (invoking a coding agent). The complete operation type list and the mapping from orchestrator actions to operation types are defined in the build spec.

### 2.2 [Major] Design Spec — Template missing error handling (new row)

**File:** Design Spec, Phase 3 Error Handling table

**Add a new row:**
> | Template directory empty or `generic.hbs` missing | Halt and notify human: "No plan templates found. Ensure at least `generic.hbs` exists in `/plugins/plan/templates/`." No retry. |

### 2.3 [Minor] Execution Plan — Task 2b halted concurrency counting

**Find Task 2b's description** about concurrency limit enforcement (mentions "active (non-terminal) project count").

**Replace with:**
> Implement concurrency limit enforcement: block new project creation when active project count (all non-terminal states including `halted`) reaches `config.yaml` `concurrency.max_parallel_runs`, disable "New Project" action in sidebar with message, re-enable when a project reaches terminal state. Note: `halted` is not terminal — halted projects count toward the limit.

### 2.4 [Minor] Design Spec — constraints.md hot-reload error handling (new content)

**File:** Design Spec, Phase 4 section, after the `constraints.md` hot-reload description

**Add the following paragraph:**
> If `constraints.md` is unreadable or missing at the start of a Phase 4 iteration (due to manual deletion or file system error), the iteration halts and the human is notified. If the file is readable but has modified structure (missing sections, unexpected content), the AI reviewer processes it as-is — the reviewer prompt is responsible for handling structural variations. ThoughtForge does not validate `constraints.md` structure at reload time.

### 2.5 [Minor] Build Spec — PlanBuilderResponse interface fix

**File:** Build Spec (find the `PlanBuilderResponse` interface)

**Find:**
```typescript
interface PlanBuilderResponse {
  stuck: boolean;
  reason?: string;
  content?: string;
}
```

**Replace with:**
```typescript
interface PlanBuilderResponse {
  stuck: boolean;        // true if the AI cannot proceed without human input
  reason?: string;       // Required when stuck is true — what decision is needed
  content: string;       // The drafted content — required when stuck is false, empty string when stuck is true
}
```

(Remove the `?` from `content` — it is now required.)

---

## Section 3: Extractions — Move implementation details from Design Spec to Build Spec/Config

### 3.1 [Minor] Design Spec — Phase 1, 50MB file size limit

**Find:**
> Resource file exceeds reasonable size (>50MB)

**Replace with:**
> Resource file exceeds configurable size limit

**Also in the Build Spec or config.yaml:** define the default 50MB threshold as a configurable parameter (e.g., `resource.max_file_size_mb: 50`).

### 3.2 [Minor] Design Spec — Phase 1, brain dump minimum word count

**Find:**
> Brain dump is empty or trivially short (fewer than ~10 words)

**Replace with:**
> Brain dump is empty or trivially short (below configurable minimum length)

**Also in the Build Spec or config.yaml:** define the default 10-word minimum as a configurable parameter (e.g., `brain_dump.min_word_count: 10`).

### 3.3 [Minor] Design Spec — Phase 3→4 transition thresholds

**Find:**
> Phase 3 output exists but is empty or trivially small (Plan mode: deliverable under ~100 characters; Code mode: no test files found)

**Replace with:**
> Phase 3 output exists but is empty or trivially small (below minimum completeness thresholds)

**Also in the Build Spec:** define the specific thresholds (100 chars for plan mode, test file presence for code mode) as implementation parameters.

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
