Now I have the complete content of all four documents. Let me perform the review.

---

# Project Plan Review — ThoughtForge Pipeline Tool

I reviewed all four documents: Requirements Brief, Design Specification, Build Spec, and Execution Plan. Below are my findings, organized per the requested output format.

---

## 1. Writing That's Unclear

**[Major] Design spec: Hallucination guard parameter naming mismatch with build spec.** The design spec references `hallucination_spike_threshold` and `hallucination_min_trend` as build-spec-defined parameters, but the build spec defines the spike threshold as ">20% from the prior iteration" and the minimum trend length as "at least 2 consecutive iterations." These are hardcoded values in the build spec, not named config parameters. The design spec implies they are configurable; the build spec does not include them in `config.yaml`. Either add them to `config.yaml` or clarify they are hardcoded.

**Replacement text for design spec Hallucination guard row:**
> Total error count increases by more than 20% from the prior iteration (hardcoded threshold, defined in build spec) after at least 2 consecutive iterations with decreasing total error count (hardcoded minimum trend length, defined in build spec)

---

**[Major] Design spec: Concurrency limit — contradictory definition of what counts as "active."** The Concurrency limit enforcement section says: "When the number of active projects (status not `done` or `halted`) reaches max_parallel_runs…" But the Halted projects and concurrency section says: "Projects with `halted` status count toward the active project limit." These directly contradict each other. The execution plan Task 2b matches the "halted counts" interpretation.

**Replacement text for the concurrency limit enforcement paragraph (first sentence):**
> When the number of active projects (status not `done`) reaches `config.yaml` `concurrency.max_parallel_runs`, new project creation is blocked.

---

**[Major] Design spec: `halted` described as both "not terminal" and using language suggesting terminal behavior.** In the `status.json` schema table, `halted` is listed under "Non-terminal halt" and described as requiring the human to "resume or terminate to free the slot." But throughout the document, Terminate buttons set status to `halted` with `halt_reason: "human_terminated"` — and this is described as permanent ("Status set to `halted` permanently"). If `halted` is non-terminal but Terminate sets it to `halted`, there is no actual terminal halt state distinct from `halted`. The `done` state is the only true terminal state. This is functional but the phrasing "Non-terminal halt" is misleading when Terminate also produces `halted`.

**Replacement text for the `status.json` schema table terminal/non-terminal rows:**
> | Terminal | `done` | Convergence or stagnation success. Does not count toward concurrency limit. |
> | Halt | `halted` | Guard trigger, human terminate, or unrecoverable error. Counts toward concurrency limit until human resumes (returning to active state) or the operator manually deletes the project directory. Terminated projects (`halt_reason: "human_terminated"`) are functionally finished but use the same `halted` state. |

---

**[Minor] Design spec: "No CLI agent execution" in Plan mode safety guardrails is confusing.** The rule says "No coding agents" but Plan mode *does* invoke AI agents (for document drafting in Phase 3 and reviewing in Phase 4). The rule means no agents are invoked *as coding agents with shell/file access* — they are invoked for text generation only. The current wording could be misread as "no agent invocations at all."

**Replacement text:**
> | No coding agent shell access | No shell commands, package installs, or file system writes to source files during Plan mode Phases 3-4. AI agents are invoked for text generation only — not with coding-agent capabilities. |

---

**[Minor] Design spec: "Realign from here" — unclear whether the command is exact-match or fuzzy.** Step 9 says the human "can type 'realign from here' in chat" but doesn't specify whether this must be an exact string match, case-insensitive, or whether surrounding text is allowed (e.g., "let's realign from here please").

**Replacement text (add after "realign from here" is a chat-parsed command):**
> The command is matched as an exact case-insensitive string: the entire chat message must be "realign from here" with no additional text. Messages containing the phrase alongside other text are treated as regular corrections.

---

**[Minor] Design spec: Fabrication guard description says "2× its convergence threshold" with examples that don't match `config.yaml` defaults for `critical_max`.** The example says "≤0 critical" which is 2× 0 = 0, fine. But the prose says "2× its convergence threshold" which for critical_max=0 is 0, for medium_max=3 is 6, for minor_max=5 is 10. The math checks out but the "2×" phrasing applied to a threshold of 0 reads oddly. Since the build spec already has the concrete formula, this is just a clarity issue.

**Replacement text (design spec fabrication guard, condition 2):**
> In at least one prior iteration, every severity category was at or below twice its convergence threshold — specifically: critical ≤ 0 (2 × 0), medium ≤ 6 (2 × 3), minor ≤ 10 (2 × 5) using default config values. This ensures fabrication is only flagged after the deliverable was near-converged.

---

**[Minor] Execution plan: Task 6a description says "cross-cutting file system error handling (halt and notify on write failures — no retry)" but this is only part of the cross-cutting error behavior.** Read failures on `status.json` and `chat_history.json` also halt — and those are read failures, not write failures. The parenthetical is incomplete.

**Replacement text for the parenthetical:**
> (halt and notify on file system failures — both read failures on critical state files and write failures — no retry)

---

**[Minor] Build spec: `config.yaml` template includes a `templates:` key that is commented out with a note "reserved for future."** But the design spec says cross-plugin template directory config is deferred. Having a commented-out key with a value (`./plugins/plan/templates`) in the example config could confuse an AI coder into thinking it's active.

**Replacement text (remove the commented block entirely or change to):**
```yaml
# templates: (reserved for future cross-plugin shared template configuration)
```

---

**[Minor] Build spec: `PlanBuilderResponse` interface shows `content: string` described as "required when stuck is false, empty string when stuck is true" — but the TypeScript interface doesn't express this constraint.** A builder could return `{ stuck: false, content: "" }` and pass type checking. Since this is a build spec, the constraint should be explicit.

**Replacement text (add a comment in the interface):**
```typescript
interface PlanBuilderResponse {
  stuck: boolean;
  reason?: string;       // Required when stuck is true
  content: string;       // Non-empty when stuck is false; empty string when stuck is true.
                         // Orchestrator must validate: if stuck is false and content is empty, treat as malformed response.
}
```

---

**[Minor] Execution plan: Task 12 description lists 7 numbered sub-steps inline, making it the longest task description in the plan.** It functions as a mini-spec rather than a task description. The detail is useful but should be a brief summary pointing to the design spec.

**Replacement text:**
> Implement Phase 2: spec building per design spec Phase 2 behavior. Includes mode-specific proposal (Plan: OPA structure; Code: architecture with OSS discovery from Task 25), AI challenge of intent decisions, constraint discovery, acceptance criteria extraction, human review/override, Unknown resolution validation gate, and Confirm advancement. Prompt loaded from `/prompts/spec-building.md`.

---

**[Minor] Design spec: The term "agent layer" is used frequently but never formally defined.** It appears to mean the agent invocation module (Tasks 41-44) but is sometimes used in contrast with "Vibe Kanban." Adding a one-line definition would prevent ambiguity.

**Proposed addition (in the Agent Communication section, before the first paragraph):**
> **Agent layer** refers to ThoughtForge's built-in agent invocation module — the subprocess-based mechanism for calling AI agent CLIs, capturing output, normalizing responses, and handling failures. This is distinct from Vibe Kanban's agent execution, which wraps agent invocation in task management and worktree isolation.

---

## 2. Genuinely Missing Plan-Level Content

**[Major] No definition of when the Plan Completeness Gate fires relative to Phase 3.** The design spec says "When a Code mode pipeline starts and a plan document is detected in `/resources/`" — but doesn't specify whether this happens before Phase 3 begins (between Phase 2 Confirm and Phase 3 builder invocation) or at the start of Phase 3 execution. The execution plan has Task 6b ("Phase 2→3 transition: Plan Completeness Gate trigger for Code mode") which implies it fires during the transition, but the design spec Phase 3 Code Mode section doesn't mention the gate at all. The gate is documented in its own section but its sequencing within the pipeline flow is ambiguous.

**Proposed addition (design spec, Phase 3 Code Mode, after step 1 "Orchestrator loads code plugin"):**
> 1a. **Plan Completeness Gate:** Before the code builder begins work, the orchestrator runs the Plan Completeness Gate (see dedicated section below). If the gate halts the pipeline, Phase 3 does not proceed. If the gate passes or is skipped (no plan document in `/resources/`), the code builder begins.

---

**[Major] No `projects/` base directory specified in config or design.** The design spec references `/projects/{id}/` throughout but never specifies where `projects/` lives relative to the ThoughtForge installation. The `config.yaml` template has no `projects.directory` key. The server restart behavior says "the server scans `/projects/`" but from what root? Without this, AI coders will guess or use a relative path from CWD.

**Proposed addition to `config.yaml` template:**
```yaml
# Projects
projects:
  directory: "./projects"  # Base directory for all project directories
```

**Proposed addition to design spec, Application Entry Point paragraph:**
> Project directories are created under the path specified by `config.yaml` `projects.directory` (default: `./projects` relative to ThoughtForge's working directory).

---

**[Major] Execution plan has no task for the Phase 3→4 transition output validation.** The design spec defines Phase 3→4 Transition Error Handling with specific conditions (output files missing, output trivially small, completeness thresholds). The build spec defines `phase3_completeness` config keys (`plan_min_chars`, `code_require_tests`). But no task in the execution plan implements this validation. Task 6c covers "Phase 3→4 automatic transition" but its description focuses on stuck recovery interaction, not the output validation gate.

**Proposed addition (new task or expanded Task 6c description):**
> Task 6c (expanded): Implement Phase 3→4 automatic transition including output validation (per design spec Phase 3→4 Transition Error Handling: verify expected output files exist and meet `config.yaml` `phase3_completeness` thresholds before entering Phase 4), Phase 3 stuck recovery interaction (Provide Input / Terminate buttons), and milestone notification.

---

**[Minor] No explicit statement of what happens to Vibe Kanban cards when a project is terminated.** The design spec says cards with `halted` status remain in their current column with a halted indicator. But terminated projects also have `halted` status (with `halt_reason: "human_terminated"`). Are terminated cards distinguishable from recoverable halts on the Kanban board? The dashboard should differentiate them since one can be resumed and the other cannot.

**Proposed addition (design spec, Vibe Kanban Dashboard section, after the halted indicator sentence):**
> Cards with `halt_reason: "human_terminated"` display a distinct visual indicator (e.g., strikethrough or "Terminated" badge) to distinguish permanently stopped projects from recoverable halts that await human action. The specific visual treatment is a UI implementation detail.

---

**[Minor] No plan-level statement about how ThoughtForge handles the scenario where the configured default agent CLI is not installed.** The design spec mentions agent CLI commands in `config.yaml` but doesn't specify what happens if `claude` (or whichever agent is default) is not found on PATH at project creation or first agent invocation. Task 1b mentions "prerequisite check (agent CLIs on PATH)" but the design spec has no corresponding behavior.

**Proposed addition (design spec, Agent Communication section, after Failure handling):**
> **Agent availability check:** At server startup, the configured default agent CLI is verified to exist on PATH. If not found, the server logs a warning: "Default agent '{agent}' not found on PATH. Projects will fail at first agent invocation." The server does not exit — other agents may be available, and the operator may install the agent before creating a project. At project creation, no agent availability check is performed — the first agent invocation failure triggers the standard retry-once-then-halt behavior.

---

**[Minor] Build spec test framework decision is unresolved.** The Build Toolchain section says "Test framework: Vitest (or Jest — decide before build starts)." This is the only undecided technical choice in the entire plan. It should be decided now or flagged as a pre-build decision.

**Proposed addition (execution plan, Design Decisions section or as a pre-build task):**
> **Pre-build decision: Test framework.** Choose Vitest or Jest before Task 1 begins. Both are compatible. Vitest is recommended for ESM-native support and faster execution with TypeScript projects (no separate compilation step for tests).

---

**[Minor] No plan-level guidance on how the code builder derives its internal task queue from `spec.md`.** The build spec says "The task list format and derivation logic are internal to the code builder" but provides no guidance on how `spec.md` sections map to build tasks. This is underspecified for an AI coder implementing Task 21.

**Proposed addition (build spec, Code Builder Task Queue section, after the first paragraph):**
> **Task derivation guidance:** The code builder parses the Deliverable Structure and Acceptance Criteria sections of `spec.md`. Each architectural component or feature maps to a build task. Each acceptance criterion maps to a test-writing task. The builder orders tasks by dependency (foundational components first, then features, then tests). The exact parsing and ordering logic is an implementation detail of Task 21, but must produce a deterministic task list from the same `spec.md` input.

---

## 3. Build Spec Material That Should Be Extracted

**[Minor] Design spec: Operation Type Taxonomy reference.** The design spec says "The complete operation type list and the mapping from orchestrator actions to operation types are defined in the build spec." This is correct — the reference is clean. However, the design spec's Plan Mode Safety Guardrails table contains operation-level specificity (listing specific file extensions like `.js`, `.py`, `.ts`, `.sh`) that belongs in the build spec's `safety-rules.js` implementation, not in the design spec.

**Recommendation:** Replace the Plan Mode Safety Guardrails table row "No file creation outside plan docs" with:
> | No source file creation | Only documentation files (`.md`) and operational state files (`.json`) may be created. Source file extensions are defined in `safety-rules.js`. |

This keeps the design spec at the "what" level and delegates the extension list to the build spec.

---

**[Minor] Design spec: WebSocket Reconnection parameters.** The design spec says "Reconnection parameters (backoff strategy, timing) are in the build spec" — correct delegation. But the build spec section (WebSocket Reconnection Parameters) includes only 4 values. These are implementation constants, not design decisions. The design spec already delegates correctly. No change needed on the design spec side, but note that this build spec section is appropriately placed.

---

**[Minor] Design spec: Button debounce implementation detail.** The design spec says "Server-side deduplication handles race conditions" which is a design-level statement. But the build spec's Button Debounce Implementation section contains UI-level implementation detail ("immediately disabled in the UI and remains disabled until the triggered operation completes or fails") that could live in the build spec alone. The design spec's single sentence is sufficient.

**Recommendation:** Remove the duplicate "Button Debounce" paragraph from the design spec Phase 1 section. The design spec already covers button behavior in the Action Button Behavior section ("Buttons prevent duplicate actions. Once pressed, a button cannot trigger a second action until the first completes or fails. Server-side deduplication handles race conditions.") The build spec's detailed implementation section is the right home for the UI-level specifics.

---

**[Minor] Design spec: Project ID format.** The design spec says "Format defined in build spec" and the build spec defines it as `{timestamp}-{random}` (e.g., `20260214-a3f2`). This is correct delegation. However, the build spec's Project Initialization Sequence includes the format inline within a step list — it would be cleaner as its own labeled section for easy reference by AI coders implementing Task 2.

**Recommendation:** In the build spec, extract the project ID format into its own subsection header:
> ### Project ID Format
> `{timestamp}-{random}`, e.g., `20260214-a3f2`. Timestamp is `YYYYMMDD` from project creation date. Random is a 4-character lowercase hexadecimal string. The combined ID is URL-safe, filesystem-safe, and unique within the projects directory.

---

That completes the review. Summary counts:

| Severity | List 1 (Unclear) | List 2 (Missing) | List 3 (Extract) |
|---|---|---|---|
| Critical | 0 | 0 | 0 |
| Major | 3 | 3 | 0 |
| Minor | 8 | 4 | 4 |
