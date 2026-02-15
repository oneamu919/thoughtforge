Now I have all four documents. Let me perform a thorough review.

---

# Plan Review Findings

## 1. Writing That's Unclear

**[Minor] Design Spec — Phase 1, step 11a: "locked" introduced without definition**

The term "locked" first appears at Phase 1 step 11a but isn't defined until the "Locked File Behavior" section under Phase 2. A reader encounters the concept before understanding what it means.

**Replacement text** — add after step 11a:

> "Locked" means the AI pipeline will not modify the file after its creation phase. See Locked File Behavior (Phase 2 section) for the full definition, including human edit consequences.

---

**[Minor] Design Spec — Phase 4 Stagnation Guard: "converged plateau" is used without prior introduction**

The sentence "This is treated as a successful convergence outcome" introduces the concept that stagnation = success, but then the guard table says "Done (success — treated as converged plateau)." The phrase "converged plateau" hasn't been defined.

**Replacement text** for the stagnation guard table's Action column:

> Done (success). The deliverable has reached a stable quality level where the reviewer is cycling cosmetic issues rather than finding genuine regressions. Treated as converged — no further iterations will yield net improvement.

---

**[Minor] Design Spec — "Distill" button purpose vs. "Confirm" button purpose: potential confusion**

Phase 1 introduces two buttons (Distill and Confirm) but the distinction is explained across several paragraphs with the confirmation model explanation at the bottom of Phase 1. A reader parsing the numbered steps could confuse when each is used.

**Replacement text** — add a summary callout box immediately after step 3 (before step 4):

> **Phase 1 has two action buttons:**
> - **Distill** — "I'm done providing inputs. Process them." (Pressed once after brain dump + resources are provided.)
> - **Confirm** — "The distillation looks correct. Move on." (Pressed after reviewing and correcting the AI's output.)

---

**[Minor] Design Spec — "Challenge" step in Phase 2 uses a colon-delimited label that breaks the numbered flow**

Step 2 begins with "**Challenge:** AI evaluates…" This reads as a substep label rather than a continuation of the numbered flow. Steps 1, 3, 4, etc. do not use this label pattern.

**Replacement text** for step 2:

> 2. AI evaluates `intent.md` for structural issues: missing dependencies, unrealistic constraints, scope gaps, internal contradictions, and ambiguous priorities. Each flagged issue is presented to the human with specific reasoning. The AI does not rubber-stamp — it must surface concerns even if the human's intent seems clear. This step does not resolve Unknowns — it identifies new problems.

(Move the "Challenge" and "Resolve" labels to a brief introductory line before the numbered list if the labels are desired for reference, e.g., "Phase 2 has two AI-driven steps: Challenge (step 2) and Resolve (step 3).")

---

**[Minor] Design Spec — "Plan mode always invokes agents directly" appears in VK integration but isn't mentioned in Phase 3 Plan Mode section**

The Phase 3 Plan Mode section (steps 1-8) never mentions that Plan mode bypasses Vibe Kanban for agent execution. This is stated only in the VK Toggle Behavior table (build spec) and the VK Integration Interface paragraph. A reader of Phase 3 alone would assume VK applies to both modes.

**Replacement text** — add to Phase 3 Plan Mode after step 1:

> Plan mode always invokes agents directly via the agent communication layer, regardless of whether Vibe Kanban is enabled. VK provides visualization only (card status updates) for Plan mode projects. VK agent execution is used exclusively in Code mode.

---

**[Minor] Execution Plan — Cross-stage dependency note after Stage 1 says "Stage 7 should begin as soon as Task 1 completes" but this is restated in the Parallelism note at the bottom.**

The same guidance appears in two places with slightly different emphasis. Consolidate.

**Replacement text** — remove the cross-stage dependency callout note after Build Stage 1 and keep only the Parallelism Opportunities section at the bottom, which already captures this with the note: "Tasks 41-42 (agent invocation layer) gate every task that calls an AI agent. These should be prioritized immediately after Task 1 completes."

---

## 2. Genuinely Missing Plan-Level Content

**[Critical] Design Spec — No specification of what happens when the human sends a chat message during Phase 3 or Phase 4 autonomous execution (outside of stuck/halt recovery)**

Phase 1-2 describe interactive chat behavior. Phase 3 and Phase 4 describe stuck/halt recovery button interactions. But there is no specification for what happens if the human opens a project's chat thread during autonomous execution and types a message. Can they? Is the chat input disabled? Is the message queued? This will cause builder confusion.

**Proposed content** — add after "Phase 3 → Phase 4 Transition" section:

> **Human Chat During Autonomous Phases (3-4):**
>
> During Phase 3 and Phase 4 autonomous execution, the chat input field is disabled. The human can view the project's chat history and current status but cannot send messages. Chat input is re-enabled only when the pipeline enters a stuck or halt state that requires human interaction (Phase 3 stuck recovery, Phase 4 halt recovery). The human can always edit the deliverable files directly outside the pipeline — see "Deliverable Edits During Phase 4."

---

**[Major] Design Spec — No specification for how the fix agent receives codebase context in Code mode Phase 4**

The design spec says: "The fix agent receives the JSON issue list and the relevant deliverable context. For Code mode: the current codebase files referenced in the issue `location` fields, plus `constraints.md` for scope awareness." But there's no specification for how this context is assembled — unlike the review step which has a full context assembly paragraph (diff-based for large codebases, full source for small). Does the fix agent get the full source? Only the referenced files? What if `location` references don't parse?

**Proposed content** — add to "Fix agent context assembly" paragraph:

> For Code mode: the fix agent receives the issue list and the content of each file referenced in the issues' `location` fields (parsed as relative paths from project root; line numbers are stripped before file lookup). If a referenced file does not exist, the issue is included in the context with a note: "Referenced file not found." If the total referenced file content exceeds the agent's context window, files are truncated starting from the largest, with a warning logged. `constraints.md` is always included for scope awareness. Unreferenced files are not passed to the fix agent — it operates only on files identified by the reviewer.

---

**[Major] Design Spec — No error handling for the Acceptance Criteria validation gate in Phase 2**

The design spec describes the Acceptance Criteria validation gate (before Phase 2 Confirm advances to Phase 3) but doesn't specify error handling for the case where the AI-proposed criteria cannot be parsed or the section is missing from the proposed `constraints.md`. The Unknowns validation gate has explicit handling (blocked Confirm, AI presents remaining items), but the AC gate only says "the Confirm button is blocked." What if the AI never generated an Acceptance Criteria section at all?

**Proposed content** — add to the Acceptance Criteria Validation Gate paragraph:

> If the proposed `constraints.md` content does not contain a recognizable Acceptance Criteria section (section heading missing entirely), the AI is re-invoked with an instruction to include acceptance criteria based on the confirmed intent and spec decisions. This follows the standard retry-once-then-halt behavior. The human is notified: "AI did not generate acceptance criteria. Retrying." If the second attempt also lacks the section, the pipeline halts and the human must provide criteria manually in chat.

---

**[Major] Execution Plan — No task for implementing mid-processing human input queuing (Phase 1)**

The design spec describes (Phase 1, "Mid-Processing Human Input"): "If the human sends a chat message while the AI is processing a prior turn, the message is queued in `chat_history.json` and included in the next AI invocation's context." There is no task in the execution plan that covers implementing this queuing behavior. Task 8 covers brain dump intake and Task 9 covers the correction loop, but neither explicitly includes message queuing during AI processing.

**Proposed content** — add to Task 8 description:

> Include mid-processing human input queuing: if the human sends a chat message while the AI is processing, queue the message in `chat_history.json` and include it in the next AI invocation's context (per design spec Phase 1 Mid-Processing Human Input).

---

**[Major] Design Spec / Execution Plan — No specification or task for the plan fix output validation (2 consecutive rejected fix outputs halts)**

The design spec describes plan mode fix output validation: "If 2 consecutive iterations produce rejected fix output, the pipeline halts and notifies the human." This is specified in the design, but there is no execution plan task that explicitly covers implementing this validation logic. Task 30 covers the orchestrator loop broadly, but this is a distinct validation step with specific consecutive-failure tracking that should be called out.

**Proposed content** — add to Task 30 description:

> Include plan mode fix output validation per design spec: after each plan mode fix, validate the returned content is non-empty and not less than 50% of the pre-fix document size. Reject invalid fix output, preserve pre-fix document, log warning. Halt after 2 consecutive rejected fix outputs.

---

**[Minor] Design Spec — No specification for what the human sees after Phase 4 terminates successfully**

The design spec describes notification content for convergence success, but doesn't specify what happens in the chat UI. Is there a "Final Review" view? Does the chat show the deliverable? Does the human get a link to the file? Touchpoint 4 in the requirements brief is "Reviews finished polished output" but there's no design for how this review happens.

**Proposed content** — add after Phase 4 Convergence Guards section:

> **Phase 4 Completion — Human Final Review:**
>
> When Phase 4 completes (termination or stagnation success), the chat displays a completion message with the final error counts, iteration count, and the file path to the polished deliverable. The project status shows as `done`. The human reviews the deliverable by opening the file directly — ThoughtForge does not render the deliverable inline. The chat thread remains available for reference (including all Phase 3-4 chat history) but no further pipeline actions are available.

---

**[Minor] Execution Plan — No task for implementing the `phase3_completeness` validation criteria from `config.yaml`**

`config.yaml` defines `phase3_completeness.plan_min_chars` and `phase3_completeness.code_require_tests`. Task 6c references "per design spec Phase 3→4 Transition Error Handling" and mentions `config.yaml` `phase3_completeness` criteria, but the actual logic for reading and applying these config values (checking character count, checking for test file existence) is not specified in any task description beyond a parenthetical reference. This is borderline covered by Task 6c's description, but the config-driven logic deserves explicit mention.

**Proposed content** — add to Task 6c description:

> Implement `phase3_completeness` config-driven validation: Plan mode checks deliverable character count against `config.yaml` `phase3_completeness.plan_min_chars`. Code mode checks for at least one test file when `phase3_completeness.code_require_tests` is true. Both checks run before Phase 4 entry.

---

## 3. Build Spec Material That Should Be Extracted

**[Minor] Design Spec — WebSocket Reconnection Parameters**

The design spec's "WebSocket Disconnection" paragraph says: "Detailed reconnection behavior is in the build spec." But the design spec then also describes in-flight response handling, operation completion during disconnect, and connection status indicator behavior (which are implementation details). These are already duplicated in the build spec. The design spec should state the behavioral requirement only ("client auto-reconnects and syncs state") and defer all parameters and edge cases to the build spec.

**Sections to extract:** The "Server-side session," "Project Status on Return," and reconnection detail paragraphs under the UI section. These describe implementation-level reconnection mechanics, not design-level behavior.

---

**[Minor] Design Spec — HTTP API Surface**

The build spec contains the HTTP API route table. The design spec does not contain it directly, but the design spec's Technical Design section references Express.js and discusses routing architecture. This is fine as-is — no extraction needed. Noting for completeness that the boundary is clean here.

---

**[Minor] Design Spec — Phase 1 Error Handling table entry "Brain dump text exceeds agent context window"**

The entry specifies: "AI processes in chunks if the configured agent supports it, otherwise truncates to the agent's maximum input size." This is implementation-level behavior for the agent communication layer, not a design-level error handling policy. The design-level concern is "what happens if the input is too large" — the answer is "it's handled." The chunking/truncation strategy belongs in the build spec alongside the token estimation formula and context window management.

**Section to extract:** Move the "Brain dump text exceeds agent context window" row's implementation detail to the build spec's Agent Communication section. Replace the design spec row with:

> | Brain dump text exceeds agent context window | Handled by the agent invocation layer's context window management (see build spec). A warning is displayed in chat if truncation occurs. |

---

**[Minor] Design Spec — `constraints.md` truncation strategy**

The design spec says: "Truncation order is specified in the build spec." But it also specifies the priority sections (Context/Deliverable Type and Acceptance Criteria). The build spec then re-specifies the full truncation strategy including removal order. This is redundant — the design spec should state only that truncation preserves the most critical sections and defer the algorithm to the build spec.

**Section to extract:** Remove the sentence "with priority given to Context/Deliverable Type and Acceptance Criteria sections" from the design spec. The build spec already contains the authoritative truncation strategy. Replace with:

> If `constraints.md` exceeds the agent's context window when combined with other review context, it is truncated per the strategy defined in the build spec.

---

**[Minor] Design Spec — Levenshtein similarity formula in Stagnation Guard Detail**

The design spec's Stagnation Guard Detail paragraph includes: "Similarity is computed as `1 - (levenshtein_distance(a, b) / max(a.length, b.length))`." This is an implementation formula. The design-level concern is "issues are compared for similarity using Levenshtein distance with a 0.8 threshold." The formula belongs in the build spec (which already has its own Stagnation Guard section with the same detail).

**Section to extract:** Remove the similarity formula sentence from the design spec's Stagnation Guard Detail. Keep only: "Issue rotation is detected when fewer than 70% of current issues match any issue in the prior iteration. Match is defined as Levenshtein similarity ≥ 0.8 on the `description` field." The formula is already in the build spec's Convergence Guard Parameters section.
