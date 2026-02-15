# Apply Review Findings

Apply every change listed below to the source files. Each change includes the target file, the location, and the exact replacement or addition. Do not interpret or improvise — apply as written.

---

## Source files

- **Design spec:** `docs/thoughtforge-design-specification.md`
- **Build spec:** `docs/thoughtforge-build-spec.md`
- **Execution plan:** `docs/thoughtforge-execution-plan.md`

Read ALL three files before making any edits.

---

## Changes to Apply

### 1. [Minor] Design spec — Phase 1, step 11a: add "locked" definition

After step 11a, insert:

> "Locked" means the AI pipeline will not modify the file after its creation phase. See Locked File Behavior (Phase 2 section) for the full definition, including human edit consequences.

---

### 2. [Minor] Design spec — Phase 4 Stagnation Guard: replace "converged plateau" text

In the stagnation guard table, replace the Action column text for the stagnation-detected row with:

> Done (success). The deliverable has reached a stable quality level where the reviewer is cycling cosmetic issues rather than finding genuine regressions. Treated as converged — no further iterations will yield net improvement.

---

### 3. [Minor] Design spec — Phase 1, after step 3: add button summary callout

Immediately after step 3 (before step 4), insert:

> **Phase 1 has two action buttons:**
> - **Distill** — "I'm done providing inputs. Process them." (Pressed once after brain dump + resources are provided.)
> - **Confirm** — "The distillation looks correct. Move on." (Pressed after reviewing and correcting the AI's output.)

---

### 4. [Minor] Design spec — Phase 2, step 2: remove "Challenge:" label

Replace Phase 2 step 2 with:

> 2. AI evaluates `intent.md` for structural issues: missing dependencies, unrealistic constraints, scope gaps, internal contradictions, and ambiguous priorities. Each flagged issue is presented to the human with specific reasoning. The AI does not rubber-stamp — it must surface concerns even if the human's intent seems clear. This step does not resolve Unknowns — it identifies new problems.

If the "Challenge" and "Resolve" labels are desired for reference, add a brief introductory line before the Phase 2 numbered list: "Phase 2 has two AI-driven steps: Challenge (step 2) and Resolve (step 3)."

---

### 5. [Minor] Design spec — Phase 3 Plan Mode, after step 1: add VK bypass note

After Phase 3 Plan Mode step 1, insert:

> Plan mode always invokes agents directly via the agent communication layer, regardless of whether Vibe Kanban is enabled. VK provides visualization only (card status updates) for Plan mode projects. VK agent execution is used exclusively in Code mode.

---

### 6. [Critical] Design spec — After "Phase 3 → Phase 4 Transition" section: add human chat during autonomous phases

Insert a new section:

> **Human Chat During Autonomous Phases (3-4):**
>
> During Phase 3 and Phase 4 autonomous execution, the chat input field is disabled. The human can view the project's chat history and current status but cannot send messages. Chat input is re-enabled only when the pipeline enters a stuck or halt state that requires human interaction (Phase 3 stuck recovery, Phase 4 halt recovery). The human can always edit the deliverable files directly outside the pipeline — see "Deliverable Edits During Phase 4."

---

### 7. [Major] Design spec — Fix agent context assembly: add Code mode context specification

In the fix agent context section (where Code mode fix agent context is described), add:

> For Code mode: the fix agent receives the issue list and the content of each file referenced in the issues' `location` fields (parsed as relative paths from project root; line numbers are stripped before file lookup). If a referenced file does not exist, the issue is included in the context with a note: "Referenced file not found." If the total referenced file content exceeds the agent's context window, files are truncated starting from the largest, with a warning logged. `constraints.md` is always included for scope awareness. Unreferenced files are not passed to the fix agent — it operates only on files identified by the reviewer.

---

### 8. [Major] Design spec — Acceptance Criteria Validation Gate: add error handling

In the Acceptance Criteria Validation Gate paragraph, add:

> If the proposed `constraints.md` content does not contain a recognizable Acceptance Criteria section (section heading missing entirely), the AI is re-invoked with an instruction to include acceptance criteria based on the confirmed intent and spec decisions. This follows the standard retry-once-then-halt behavior. The human is notified: "AI did not generate acceptance criteria. Retrying." If the second attempt also lacks the section, the pipeline halts and the human must provide criteria manually in chat.

---

### 9. [Minor] Design spec — After Phase 4 Convergence Guards section: add human final review

Insert:

> **Phase 4 Completion — Human Final Review:**
>
> When Phase 4 completes (termination or stagnation success), the chat displays a completion message with the final error counts, iteration count, and the file path to the polished deliverable. The project status shows as `done`. The human reviews the deliverable by opening the file directly — ThoughtForge does not render the deliverable inline. The chat thread remains available for reference (including all Phase 3-4 chat history) but no further pipeline actions are available.

---

### 10. [Minor] Design spec — WebSocket Reconnection: extract implementation details to build spec

Remove the "Server-side session," "Project Status on Return," and reconnection detail paragraphs from the design spec's WebSocket Disconnection section. Keep only the behavioral requirement ("client auto-reconnects and syncs state") and defer details to the build spec.

Replace in the design spec with:

> The client auto-reconnects and syncs state from the server on reconnect. Detailed reconnection behavior is in the build spec.

Ensure the removed content exists in the build spec's WebSocket Reconnection Parameters section. If already present, no build spec change needed.

---

### 11. [Minor] Design spec — Phase 1 Error Handling table: extract chunking/truncation detail

Replace the "Brain dump text exceeds agent context window" row's action text with:

> | Brain dump text exceeds agent context window | Handled by the agent invocation layer's context window management (see build spec). A warning is displayed in chat if truncation occurs. |

Move the original implementation detail (AI processes in chunks / truncates to max input size) to the build spec's Agent Communication section if not already present there.

---

### 12. [Minor] Design spec — `constraints.md` truncation strategy: remove redundant detail

Remove the sentence "with priority given to Context/Deliverable Type and Acceptance Criteria sections" from the design spec. Replace with:

> If `constraints.md` exceeds the agent's context window when combined with other review context, it is truncated per the strategy defined in the build spec.

---

### 13. [Minor] Design spec — Stagnation Guard Detail: extract Levenshtein formula

Remove the similarity formula sentence (`1 - (levenshtein_distance(a, b) / max(a.length, b.length))`) from the design spec's Stagnation Guard Detail. Keep only: "Issue rotation is detected when fewer than 70% of current issues match any issue in the prior iteration. Match is defined as Levenshtein similarity >= 0.8 on the `description` field." The formula is already in the build spec.

---

### 14. [Minor] Execution plan — Cross-stage dependency note after Stage 1: remove duplicate

Remove the cross-stage dependency callout note after Build Stage 1. The same guidance is already captured in the Parallelism Opportunities section at the bottom.

---

### 15. [Major] Execution plan — Task 8: add mid-processing input queuing

Add to Task 8's description:

> Include mid-processing human input queuing: if the human sends a chat message while the AI is processing, queue the message in `chat_history.json` and include it in the next AI invocation's context (per design spec Phase 1 Mid-Processing Human Input).

---

### 16. [Major] Execution plan — Task 30: add plan fix output validation

Add to Task 30's description:

> Include plan mode fix output validation per design spec: after each plan mode fix, validate the returned content is non-empty and not less than 50% of the pre-fix document size. Reject invalid fix output, preserve pre-fix document, log warning. Halt after 2 consecutive rejected fix outputs.

---

### 17. [Minor] Execution plan — Task 6c: add config-driven validation detail

Add to Task 6c's description:

> Implement `phase3_completeness` config-driven validation: Plan mode checks deliverable character count against `config.yaml` `phase3_completeness.plan_min_chars`. Code mode checks for at least one test file when `phase3_completeness.code_require_tests` is true. Both checks run before Phase 4 entry.

---

## After All Changes Are Applied

1. Re-read each modified file to verify no formatting was broken and all changes landed correctly.
2. Git commit and sync:

```bash
git status -u
git diff --stat
git add docs/thoughtforge-design-specification.md docs/thoughtforge-build-spec.md docs/thoughtforge-execution-plan.md
git commit -m "Apply review findings"
git push
git pull
```
