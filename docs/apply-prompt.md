# Apply Review Findings from results.md

You are an AI coder. Apply every change listed below to the source files. Each change is taken directly from the review findings in `docs/results.md`. Do not interpret or improvise — apply the replacements, additions, and extractions exactly as specified.

Read all target files before editing. After all changes are applied, git commit and sync to remote.

---

## Target Files

- `docs/thoughtforge-design-specification.md` (referred to as "Design Spec")
- `docs/thoughtforge-build-spec.md` (referred to as "Build Spec")
- `docs/thoughtforge-execution-plan.md` (referred to as "Execution Plan")

Read all three files before making any edits.

---

## Changes to Design Spec (`docs/thoughtforge-design-specification.md`)

### Change 1 — Phase 1 Error Handling: Remove "Connector failure during distillation" redundancy [Minor]

**Action:** Find and delete the standalone paragraph "Connector failure during distillation" (around line 124). Then update the two connector error table rows:

- **Connector authentication failure** row — change the response column to:
  > Log the failure, notify the human in chat specifying which connector failed and why, and proceed with distillation using available inputs (if distillation is already in progress, no re-click of Distill is required). Do not halt the pipeline.

- **Connector target not found** row — change the response column to:
  > Log the failure, notify the human in chat specifying which resource could not be retrieved, and proceed with distillation using available inputs (if distillation is already in progress, no re-click of Distill is required).

---

### Change 2 — Phase 4 Convergence Guards: Hallucination guard wording [Minor]

**Find:** "Total error count increases by more than the configured spike threshold after at least the configured minimum number of consecutive iterations with decreasing total error count."

**Replace with:**
> Total error count increases by more than the configured spike threshold (`hallucination_spike_threshold`, defined in build spec) after at least the configured minimum number of consecutive iterations with decreasing total error count (`hallucination_min_trend`, defined in build spec).

---

### Change 3 — Phase 2: "AI evaluates intent.md for..." list ambiguity [Minor]

**Find:** The sentence in Phase 2 Step 2 that lists "missing dependencies, unrealistic constraints, scope gaps, internal contradictions, unvalidated assumptions, and ambiguous priorities" and its surrounding text.

**Replace with:**
> AI evaluates `intent.md` for issues including but not limited to: missing dependencies, unrealistic constraints, scope gaps, internal contradictions, unvalidated assumptions, and ambiguous priorities. Each flagged issue is presented to the human with specific reasoning. The AI does not rubber-stamp — it must surface concerns even if the human's intent seems clear.

---

### Change 4 — Technical Design: "VS Code integration" → "VS Code extension" [Minor]

**Find (around line 401):** "VS Code integration" in the Vibe Kanban description.

**Replace with:** "VS Code extension" so the line reads:
> **Vibe Kanban** is the execution and visualization layer — kanban board, parallel task execution, agent spawning, git worktree isolation, dashboard, VS Code extension. It runs and displays the work.

---

### Change 5 — Locked File Behavior: Add concise summary [Minor]

**Location:** After the detailed explanation of locked file behavior (the paragraph about `constraints.md` being hot-reloaded and `spec.md`/`intent.md` being read once).

**Add:**
> **In short:** Editing `constraints.md` during Phase 4 works. Editing `spec.md` or `intent.md` during active pipeline execution has no effect. Editing them while the project is halted works if the project is subsequently resumed.

---

### Change 6 — Phase 4: Add plan mode fix agent interaction [Major]

**Location:** In Phase 4, after the "Fix agent context assembly" section.

**Add:**
> **Plan mode fix interaction:** The fix agent receives the full plan document and the JSON issue list. It returns the complete updated plan document with fixes applied. The orchestrator replaces the existing plan file with the returned content. The fix agent does not return diffs or partial documents — full document replacement ensures structural integrity of the OPA template.

---

### Change 7 — Phase 3 Plan Mode: Add plan deliverable filename [Major]

**Location:** In Phase 3's Plan Mode output section.

**Add:**
> The plan deliverable filename is `plan.md`, written to `/projects/{id}/docs/plan.md`. This distinguishes it from pipeline artifacts (`intent.md`, `spec.md`, `constraints.md`) in the same directory. The Phase 4 reviewer and fixer reference this fixed filename.

---

### Change 8 — Phase 4: Add code mode fix agent interaction [Major]

**Location:** In Phase 4, after the "Fix agent context assembly" section (and after the plan mode fix interaction added in Change 6).

**Add:**
> **Code mode fix interaction:** The fix agent operates as a coding agent with write access to the project directory. It reads the issue list, modifies the relevant source files directly, and exits. The orchestrator then runs `git add` and commits the changes. The fix agent does not return modified file content — it applies changes in-place, consistent with how coding agents operate during Phase 3.

---

### Change 9 — Phase 1: Add resource lifecycle after step 11b [Minor]

**Location:** In Phase 1, after step 11b.

**Add:**
> **Resource lifecycle:** Files in `/resources/` persist for the lifetime of the project. They are not deleted or moved after Phase 1 consumption. The Plan Completeness Gate (Code mode entry) scans `/resources/` for plan documents. Non-plan resources remain for human reference but are not re-consumed by later pipeline phases.

---

### Change 10 — Add Phase 3–4 chat history truncation [Minor]

**Location:** After the "Phase 2 Chat History Truncation" section.

**Add:**
> **Phase 3–4 Chat History Truncation:** If Phase 3 or Phase 4 recovery chat history exceeds the agent context window, the agent invocation layer truncates older messages from the beginning, retaining the most recent messages. There is no anchoring message for these phases — unlike Phases 1–2, recovery conversations do not have a structural anchor that must be preserved. A warning is logged when truncation occurs.

---

### Change 11 — Realign algorithm: Extract detail to build spec [Minor]

**Find:** The text that reads "The AI rolls back to the most recent substantive correction and re-distills from the original brain dump plus all corrections up to that point. If no corrections exist yet, the command is ignored with a prompt to provide a correction first." and the sentence about scanning backwards through `chat_history.json`.

**Replace with:**
> The AI re-distills from the original brain dump plus corrections up to a rollback point. Algorithm details in build spec.

---

### Change 12 — Chat history truncation: Extract algorithm detail to build spec [Minor]

**Find:** "The original brain dump messages are identified as all human messages before the first Distill button press in the chat history. During truncation, these messages are always retained at the beginning of the context, followed by the most recent messages that fit within the remaining window. Messages between the brain dump and the retained recent messages are dropped."

**Replace with:**
> If a single phase's chat history exceeds the agent's context window, the agent invocation layer truncates older messages while always retaining the original brain dump and the most recent messages. Truncation algorithm in build spec.

---

## Changes to Build Spec (`docs/thoughtforge-build-spec.md`)

### Change 13 — Add Chat History Truncation Algorithm section [Minor]

**Location:** Alongside the existing Realign Algorithm section.

**Add new section:**
> ### Chat History Truncation Algorithm
>
> The original brain dump messages are identified as all human messages before the first Distill button press in the chat history. During truncation, these messages are always retained at the beginning of the context, followed by the most recent messages that fit within the remaining window. Messages between the brain dump and the retained recent messages are dropped.

---

## Changes to Execution Plan (`docs/thoughtforge-execution-plan.md`)

### Change 14 — Task 12: Break dense description into numbered list [Minor]

**Find:** Task 12's dense single-sentence description.

**Replace with:**
> Implement Phase 2: spec building.
> 1. Mode-specific proposal (Plan: OPA-structured plan sections; Code: architecture/language/framework/tools with OSS discovery from Task 25)
> 2. AI challenge of weak or risky decisions in `intent.md` (does not rubber-stamp)
> 3. Constraint discovery
> 4. Acceptance criteria extraction (5–10 per design spec)
> 5. Human review/override of proposed decisions and acceptance criteria
> 6. Unknown/Open Question resolution validation gate (block Confirm if unresolved items remain)
> 7. Confirm to advance

---

### Change 15 — Task 1b: Add Node.js version requirement [Minor]

**Find:** "prerequisite check (Node.js version, agent CLIs on PATH)"

**Replace with:**
> prerequisite check (Node.js ≥18 LTS, agent CLIs on PATH)

---

### Change 16 — Add Prompt Validation Strategy section [Major]

**Location:** After the "Task Acceptance Criteria" section.

**Add new subsection:**
> ### Prompt Validation Strategy
>
> Each pipeline prompt ("To be drafted" prompts in build spec) is validated during the end-to-end tests (Tasks 51–53). The e2e tests serve as the primary prompt quality gate — if the pipeline produces acceptable deliverables end-to-end, the prompts are working. If an e2e test fails due to poor AI output quality (rather than code bugs), the prompt is revised and the test re-run. Prompt iteration is expected during Build Stage 8 and is not a sign of implementation failure.

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
