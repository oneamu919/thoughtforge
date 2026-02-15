Now I have the full picture. Let me produce the review.

---

# Project Plan Review — ThoughtForge

**Scope reviewed:** Design Specification, Build Spec, and Execution Plan. Requirements Brief read for context only.

---

## 1. Writing That's Unclear

**[Minor]** Design Spec, Phase 4 — Stagnation Guard description (line 303):

> "Same total error count for consecutive iterations exceeding the configured stagnation limit AND issue replacement detected"

The phrase "consecutive iterations exceeding the configured stagnation limit" is ambiguous — it could mean the count exceeds a numeric limit, or the number of consecutive iterations exceeds a count threshold. The build spec (line 302) clarifies this as "3+ consecutive iterations," but the design spec should stand on its own.

**Replacement:**
> "Same total error count persisting for a number of consecutive iterations equal to or greater than the configured stagnation limit AND issue replacement detected"

---

**[Minor]** Design Spec, Phase 1 Step 9 — "Realign from here" (line 90):

> "The AI resets to the most recent substantive correction, excluding subsequent conversation from the working context (retained in `chat_history.json` for audit trail), and re-distills from the original brain dump plus all corrections up to that point."

"Up to that point" is ambiguous — does it mean up to the realign command, or up to the most recent substantive correction? The build spec algorithm makes clear it means "up to the identified baseline correction," but the design spec sentence reads as if "that point" refers to the realign command itself.

**Replacement:**
> "The AI resets to the most recent substantive correction, excluding all subsequent conversation from the working context (retained in `chat_history.json` for audit trail), and re-distills from the original brain dump plus all corrections up to and including that baseline correction."

---

**[Minor]** Design Spec, Hallucination Guard (line 302):

> "Error count increases significantly (threshold defined in build spec) after a consecutive downward trend (minimum trend length defined in build spec)"

"Consecutive downward trend" is imprecise — "consecutive" modifies "trend" but doesn't convey the intended meaning. The build spec says "at least 2 consecutive iterations of decreasing total error count."

**Replacement:**
> "Total error count increases by more than the configured spike threshold after at least the configured minimum number of consecutive iterations with decreasing total error count"

---

**[Minor]** Design Spec, Fabrication Guard (line 304):

> "the system had previously reached counts within a multiplier of convergence thresholds (multiplier defined in build spec) in at least one prior iteration — suggesting the reviewer is manufacturing issues because nothing real remains"

"Within a multiplier of convergence thresholds" is confusing. "Within 2x" means the counts were at most 2x the thresholds — so up to double the termination thresholds. Readers may misparse this as "within a small multiplier" (i.e., close to thresholds).

**Replacement:**
> "the system had previously reached counts no greater than a configured multiplier of the convergence thresholds in at least one prior iteration — indicating the deliverable was near-converged, and subsequent spikes likely represent manufactured issues"

---

**[Minor]** Design Spec, Code Builder Interaction Model (line 216):

> "a single invocation or multi-turn session (depending on VK task execution behavior)"

This parenthetical delegates a core behavioral question — whether the code builder uses one agent call or multiple — to an external tool's behavior without clarifying what ThoughtForge controls vs. what VK controls.

**Replacement:**
> "a single invocation or multi-turn session, depending on how Vibe Kanban executes the task (if VK is enabled) or as a single invocation (if VK is disabled)"

---

**[Minor]** Execution Plan, Task 2b (line 51):

> "Note: `halted` is not terminal — halted projects count toward the limit."

This is correct per the design spec, but it contradicts the `status.json` schema (build spec line 524) which groups `halted` with `done` as "Terminal." The design spec itself says projects in `halted` status remain until the human acts, and the concurrency section explicitly states halted projects count toward the limit. The build spec's phase-to-state mapping labels `halted` as "Terminal" alongside `done`.

**Replacement in build spec line 524 (Phase-to-State Mapping table):**
Change `Terminal` row to:
> "| Terminal | `done` | `done`: convergence or stagnation success. |"

Add a new row:
> "| Non-terminal halt | `halted` | `halted`: guard trigger, human terminate, or unrecoverable error. Counts toward concurrency limit. Human must resume or terminate to free the slot. |"

---

## 2. Genuinely Missing Plan-Level Content

**[Major]** Design Spec — No definition of what "agent" means in the context of Phase 1-2 chat interactions.

The design spec describes the AI conversing with the human during Phases 1 and 2 (distillation, correction loops, spec building), but never specifies how the chat AI agent is invoked for conversational turns. The agent communication section describes CLI subprocess invocations for build and review tasks (prompt in, response out), but Phase 1-2 require multi-turn chat — the human sends a message, the AI responds, the human corrects, the AI revises. The design spec doesn't address whether Phase 1-2 chat uses the same agent subprocess model (one invocation per turn, with chat history passed as context) or a persistent session.

**Proposed content to add (Design Spec, under Agent Communication or as a new subsection "Phase 1-2 Chat Agent Model"):**

> **Phase 1-2 Chat Agent Model:** Phases 1 and 2 use the same agent invocation pattern as all other phases — prompt via stdin, response via stdout, one subprocess call per turn. Each invocation passes the full working context: the brain dump, resources, current distillation (Phase 1) or spec-in-progress (Phase 2), and the relevant chat history from `chat_history.json`. There is no persistent agent session — each turn is a stateless call with full context. This keeps the agent communication model uniform across all phases and avoids session management complexity.

---

**[Major]** Design Spec — No error handling for `chat_history.json` corruption or excessive size.

The plan specifies that `chat_history.json` is written after every chat message and is used for crash recovery, realign, and reconnection. But there's no plan-level handling for: (a) what happens if `chat_history.json` grows too large to fit in the agent's context window alongside the brain dump and resources, or (b) what happens if the file becomes corrupted or unreadable.

**Proposed content to add (Design Spec, under Project State Files or Phase 1 Error Handling):**

> **`chat_history.json` Error Handling:** If `chat_history.json` is unreadable or missing, the pipeline halts and notifies the human — same behavior as `status.json` corruption. The human must fix or recreate the file. Chat history size is bounded by the phase-clearing behavior (cleared on Phase 1→2 and Phase 2→3 transitions). If a single phase's chat history grows large enough to exceed the agent's context window, the agent invocation layer truncates older messages from the beginning of the history, retaining the most recent messages and always retaining the original brain dump. A warning is logged when truncation occurs.

---

**[Major]** Design Spec — No specification for how Phase 2 spec-building conversation structures its multi-turn flow.

Phase 1 has a clear interaction model: brain dump → Distill → AI presents distillation → human corrects → AI revises → Confirm. Phase 2 says "AI presents each proposed element as a structured message" and "human responds with corrections" but doesn't define the sequencing. Does the AI present all elements at once or one at a time? If the human corrects element 3, does the AI re-present only element 3 or all elements? What triggers the transition from "proposing structure" to "presenting acceptance criteria"?

**Proposed content to add (Design Spec, Phase 2 Conversation Mechanics, after line 141):**

> **Phase 2 Conversation Sequencing:** The AI presents all proposed elements in a single structured message: deliverable structure, key decisions, resolved unknowns, and acceptance criteria. The human responds with corrections to any element. The AI revises only the affected elements and re-presents the complete updated proposal. This repeats until the human is satisfied and clicks Confirm. There is no enforced ordering between elements — the human may address them in any sequence. The validation gate (all Unknowns and Open Questions resolved) is checked when Confirm is clicked, not during the correction cycle.

---

**[Minor]** Execution Plan — No testing task for Plan mode safety guardrails.

The design spec dedicates a full section to Plan Mode Safety Guardrails (line 356-371) and the build spec defines the operation taxonomy. The execution plan has unit tests for most modules but no explicit test task for verifying that plan mode `safety-rules.js` correctly blocks all prohibited operations.

**Proposed content to add (Execution Plan, Build Stage 8):**

> | 58j | Unit tests: plan mode safety guardrails (`safety-rules.js` blocks `shell_exec`, `file_create_source`, `package_install`, `test_exec` operations; allows `file_create_doc`, `file_create_state`, `agent_invoke`, `git_commit`) | — | Task 18 | — | Not Started |

---

**[Minor]** Design Spec — No specification for how the Settings UI handles prompt file write failures.

The prompt editor reads and writes to `/prompts/`. The plan specifies last-write-wins for concurrent edits, but doesn't specify what happens if the write itself fails (disk full, permission error).

**Proposed content to add (Design Spec, Prompt Management section, after line 525):**

> **Prompt file write failure:** If the prompt editor cannot write to a file, the Settings UI displays an error message identifying the file and the error. The failed edit is not applied — the human must resolve the file system issue and retry. No partial writes — the prompt editor uses the same atomic write strategy as state files.

---

**[Minor]** Execution Plan — No testing task for the Vibe Kanban adapter failure handling.

The design spec specifies that VK visualization-only call failures are logged and ignored, and VK agent execution failures follow agent retry-once-then-halt. There's no test task covering this branching behavior.

**Proposed content to add (Execution Plan, Build Stage 8):**

> | 58k | Unit tests: Vibe Kanban adapter failure handling (visualization-only call failures logged and pipeline continues, agent execution call failures trigger retry-once-then-halt, VK disabled skips all calls) | — | Tasks 26–29a | — | Not Started |

---

## 3. Build Spec Material That Should Be Extracted

**[Minor]** Design Spec, Phase 1 Step 3 — Connector URL Identification (line 80):

> "The AI identifies connector URLs in chat messages by matching against known URL patterns for each enabled connector. Pattern definitions are in the build spec."

The first sentence is design-level (what), but it strays toward implementation when it specifies "matching against known URL patterns." The design spec should state *that* URLs are identified and routed to connectors. The *how* (URL pattern matching) is correctly delegated to the build spec via the second sentence, but the first sentence partially duplicates it. This is borderline — acceptable as-is since the build spec already owns the pattern definitions. No action required unless you want tighter separation.

---

**[Minor]** Design Spec, Stagnation Guard — Levenshtein similarity specification (line 303):

> "for each current issue, check if any prior issue has Levenshtein similarity ≥ 0.8 on the `description` field — if fewer than 70% of current issues find a match, rotation is detected"

The design spec names a specific algorithm (Levenshtein), specific thresholds (0.8 similarity, 70% match rate), and a specific field (`description`). These are algorithmic parameters that belong in the build spec. The design spec already delegates parameters to the build spec for other guards but embeds them inline for stagnation. Consistent treatment would be:

**Replacement in Design Spec:**
> "issue replacement detected (rotation threshold and similarity measure defined in build spec). This indicates the reviewer is finding new issues to replace resolved ones, producing a plateau rather than genuine progress."

The existing build spec section (lines 302-305) already contains these details, so no content needs to be added there.

---

**[Minor]** Design Spec, Concurrency section (line 494):

> "Within a single project, the pipeline is single-threaded — only one operation (phase transition, polish iteration, button action) executes at a time. This is enforced by the sequential nature of the pipeline: each phase awaits completion before the next begins, and button presses are ignored while an operation is in progress. No explicit locking is required."

The statement "no explicit locking is required" and the reasoning about sequential enforcement are implementation justifications. The design-level statement is: "Within a single project, the pipeline is single-threaded." The rest explains *why* no locking mechanism needs to be built — that's a build spec concern.

**Replacement in Design Spec:**
> "Within a single project, the pipeline is single-threaded — only one operation (phase transition, polish iteration, button action) executes at a time."

**Move to build spec (Project State or Concurrency section):**
> **Single-project concurrency model:** The sequential nature of the pipeline enforces single-threaded operation per project: each phase awaits completion before the next begins, and button presses are ignored while an operation is in progress. No explicit locking or mutex is required. Concurrent access to a single project's state files is not supported and does not need locking.

---

End of review.
