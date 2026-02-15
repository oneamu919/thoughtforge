# Apply Review Findings from results.md

You are an AI coder. Apply every change listed below to the source files. Each change is taken directly from the review findings in `results.md`. Do not interpret or improvise — apply the replacements, additions, and extractions exactly as specified.

Read all target files before editing. After all changes are applied, git commit and sync to remote.

---

## Target Files

- `docs/thoughtforge-design-specification.md` (referred to as "Design Spec")
- `docs/thoughtforge-build-spec.md` (referred to as "Build Spec")
- `docs/thoughtforge-execution-plan.md` (referred to as "Execution Plan")

Read all three files before making any edits.

---

## Changes to Apply

### Change 1 — Design Spec: Stagnation Guard description (Minor)

**Location:** Phase 4, Stagnation Guard (~line 303)

**Find:**
> "Same total error count for consecutive iterations exceeding the configured stagnation limit AND issue replacement detected"

**Replace with:**
> "Same total error count persisting for a number of consecutive iterations equal to or greater than the configured stagnation limit AND issue replacement detected"

---

### Change 2 — Design Spec: Phase 1 Step 9 "Realign from here" (Minor)

**Location:** Phase 1 Step 9 (~line 90)

**Find:**
> "The AI resets to the most recent substantive correction, excluding subsequent conversation from the working context (retained in `chat_history.json` for audit trail), and re-distills from the original brain dump plus all corrections up to that point."

**Replace with:**
> "The AI resets to the most recent substantive correction, excluding all subsequent conversation from the working context (retained in `chat_history.json` for audit trail), and re-distills from the original brain dump plus all corrections up to and including that baseline correction."

---

### Change 3 — Design Spec: Hallucination Guard (Minor)

**Location:** Hallucination Guard (~line 302)

**Find:**
> "Error count increases significantly (threshold defined in build spec) after a consecutive downward trend (minimum trend length defined in build spec)"

**Replace with:**
> "Total error count increases by more than the configured spike threshold after at least the configured minimum number of consecutive iterations with decreasing total error count"

---

### Change 4 — Design Spec: Fabrication Guard (Minor)

**Location:** Fabrication Guard (~line 304)

**Find:**
> "the system had previously reached counts within a multiplier of convergence thresholds (multiplier defined in build spec) in at least one prior iteration — suggesting the reviewer is manufacturing issues because nothing real remains"

**Replace with:**
> "the system had previously reached counts no greater than a configured multiplier of the convergence thresholds in at least one prior iteration — indicating the deliverable was near-converged, and subsequent spikes likely represent manufactured issues"

---

### Change 5 — Design Spec: Code Builder Interaction Model (Minor)

**Location:** Code Builder Interaction Model (~line 216)

**Find:**
> "a single invocation or multi-turn session (depending on VK task execution behavior)"

**Replace with:**
> "a single invocation or multi-turn session, depending on how Vibe Kanban executes the task (if VK is enabled) or as a single invocation (if VK is disabled)"

---

### Change 6 — Build Spec: Fix `halted` status classification (Minor)

**Location:** Phase-to-State Mapping table (~line 524)

**Action:** Change the `Terminal` row so it only includes `done`:

> "| Terminal | `done` | `done`: convergence or stagnation success. |"

**Add a new row after it:**

> "| Non-terminal halt | `halted` | `halted`: guard trigger, human terminate, or unrecoverable error. Counts toward concurrency limit. Human must resume or terminate to free the slot. |"

---

### Change 7 — Design Spec: Add Phase 1-2 Chat Agent Model (Major)

**Location:** Under the Agent Communication section, add a new subsection titled "Phase 1-2 Chat Agent Model"

**Action:** Insert the following:

> **Phase 1-2 Chat Agent Model:** Phases 1 and 2 use the same agent invocation pattern as all other phases — prompt via stdin, response via stdout, one subprocess call per turn. Each invocation passes the full working context: the brain dump, resources, current distillation (Phase 1) or spec-in-progress (Phase 2), and the relevant chat history from `chat_history.json`. There is no persistent agent session — each turn is a stateless call with full context. This keeps the agent communication model uniform across all phases and avoids session management complexity.

---

### Change 8 — Design Spec: Add `chat_history.json` Error Handling (Major)

**Location:** Under Project State Files or Phase 1 Error Handling

**Action:** Insert the following:

> **`chat_history.json` Error Handling:** If `chat_history.json` is unreadable or missing, the pipeline halts and notifies the human — same behavior as `status.json` corruption. The human must fix or recreate the file. Chat history size is bounded by the phase-clearing behavior (cleared on Phase 1→2 and Phase 2→3 transitions). If a single phase's chat history grows large enough to exceed the agent's context window, the agent invocation layer truncates older messages from the beginning of the history, retaining the most recent messages and always retaining the original brain dump. A warning is logged when truncation occurs.

---

### Change 9 — Design Spec: Add Phase 2 Conversation Sequencing (Major)

**Location:** Phase 2, after ~line 141 or as a new subsection "Phase 2 Conversation Mechanics"

**Action:** Insert the following:

> **Phase 2 Conversation Sequencing:** The AI presents all proposed elements in a single structured message: deliverable structure, key decisions, resolved unknowns, and acceptance criteria. The human responds with corrections to any element. The AI revises only the affected elements and re-presents the complete updated proposal. This repeats until the human is satisfied and clicks Confirm. There is no enforced ordering between elements — the human may address them in any sequence. The validation gate (all Unknowns and Open Questions resolved) is checked when Confirm is clicked, not during the correction cycle.

---

### Change 10 — Execution Plan: Add test task for Plan Mode Safety Guardrails (Minor)

**Location:** Build Stage 8 table

**Action:** Add a new row:

> | 58j | Unit tests: plan mode safety guardrails (`safety-rules.js` blocks `shell_exec`, `file_create_source`, `package_install`, `test_exec` operations; allows `file_create_doc`, `file_create_state`, `agent_invoke`, `git_commit`) | — | Task 18 | — | Not Started |

---

### Change 11 — Design Spec: Add prompt file write failure handling (Minor)

**Location:** Prompt Management section, after ~line 525

**Action:** Insert the following:

> **Prompt file write failure:** If the prompt editor cannot write to a file, the Settings UI displays an error message identifying the file and the error. The failed edit is not applied — the human must resolve the file system issue and retry. No partial writes — the prompt editor uses the same atomic write strategy as state files.

---

### Change 12 — Execution Plan: Add test task for VK adapter failure handling (Minor)

**Location:** Build Stage 8 table

**Action:** Add a new row:

> | 58k | Unit tests: Vibe Kanban adapter failure handling (visualization-only call failures logged and pipeline continues, agent execution call failures trigger retry-once-then-halt, VK disabled skips all calls) | — | Tasks 26–29a | — | Not Started |

---

### Change 13 — Design Spec: Extract Stagnation Guard Levenshtein details to Build Spec (Minor)

**Location:** Stagnation Guard in Design Spec (~line 303)

**Find:**
> "for each current issue, check if any prior issue has Levenshtein similarity ≥ 0.8 on the `description` field — if fewer than 70% of current issues find a match, rotation is detected"

**Replace with:**
> "issue replacement detected (rotation threshold and similarity measure defined in build spec). This indicates the reviewer is finding new issues to replace resolved ones, producing a plateau rather than genuine progress."

The build spec already contains these algorithmic details at lines 302-305 — no additions needed there.

---

### Change 14 — Design Spec: Extract concurrency implementation reasoning to Build Spec (Minor)

**Part A — Design Spec** (Concurrency section, ~line 494)

**Find:**
> "Within a single project, the pipeline is single-threaded — only one operation (phase transition, polish iteration, button action) executes at a time. This is enforced by the sequential nature of the pipeline: each phase awaits completion before the next begins, and button presses are ignored while an operation is in progress. No explicit locking is required."

**Replace with:**
> "Within a single project, the pipeline is single-threaded — only one operation (phase transition, polish iteration, button action) executes at a time."

**Part B — Build Spec** (Project State or Concurrency section)

**Add:**
> **Single-project concurrency model:** The sequential nature of the pipeline enforces single-threaded operation per project: each phase awaits completion before the next begins, and button presses are ignored while an operation is in progress. No explicit locking or mutex is required. Concurrent access to a single project's state files is not supported and does not need locking.

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
