Now I have the full context. Let me produce the review.

---

# ThoughtForge Plan Review ΓÇö Iteration 6

## 1. Writing That's Unclear

**[Minor] Design Spec, Phase 1, Step 9 ΓÇö "realign from here" scope is confusing on first read**

Current text:
> Human can type "realign from here" in chat. The AI identifies the most recent substantive correction, discards all AI and human messages after that point from the working context (retaining them in `chat_history.json` for audit), and re-distills from the original brain dump plus all corrections up to that baseline.

The phrase "most recent substantive correction" is ambiguous ΓÇö it reads as though the AI must judge what counts as "substantive" vs. not. The build spec's Realign Algorithm clarifies that it scans backwards past any sequential "realign from here" commands to find the most recent human correction. The design spec should match.

Replacement:
> Human can type "realign from here" in chat. The AI scans backwards through chat history past any sequential "realign from here" commands to find the most recent human correction message. It discards all AI and human messages after that point from the working context (retaining them in `chat_history.json` for audit), and re-distills from the original brain dump plus all corrections up to that baseline.

---

**[Minor] Design Spec, Phase 4 ΓÇö Stagnation guard description overloads one sentence**

Current text:
> Stagnation | Same total error count for 3+ consecutive iterations AND issue rotation detected ΓÇö fewer than 70% of current issues match prior iteration issues (match = issues with substantially similar descriptions, as determined by string similarity). Algorithmic parameters (similarity threshold, window sizes) defined in build spec. | Done (success). Notify human ΓÇö same notification path as Termination success: status set to `done`, human notified with final error counts and iteration summary.

The parenthetical "(match = issues with substantially similar descriptions, as determined by string similarity)" says "string similarity" while the build spec specifies Levenshtein ΓëÑ 0.8. The design spec should either say "Levenshtein similarity" or omit the detail entirely and let the build spec own it.

Replacement:
> Stagnation | Same total error count for 3+ consecutive iterations AND issue rotation detected ΓÇö fewer than 70% of current issues match prior iteration issues by description similarity. Algorithmic parameters (similarity threshold, window sizes) defined in build spec. | Done (success). Notify human ΓÇö same notification path as Termination success: status set to `done`, human notified with final error counts and iteration summary.

---

**[Minor] Design Spec, Notification Content ΓÇö "project_name" derivation described twice**

The `project_name` field in the Notification Content table includes a full description of how the name is derived (extracted from intent.md, stored in status.json). This same derivation is already described in Phase 1 step 0 ("Project Name Derivation") and in the build spec's "Project Name Derivation" section. The Notification Content table should reference the derivation, not restate it.

Replacement for the `project_name` row's Description cell:
> Human-readable project name. Derived during Phase 1 ΓÇö see Project Name Derivation (Phase 1, step 0).

---

**[Minor] Design Spec, Phase 2 ΓÇö "AI resolves Unknowns and Open Questions" in step 3 is ambiguous about _how_ the AI decides whether to resolve autonomously vs. ask the human**

Current text:
> AI resolves Unknowns and Open Questions from `intent.md` ΓÇö either by making a reasoned decision (stated in `spec.md`) or by asking the human during the Phase 2 chat. No unresolved unknowns may carry into `spec.md`.

There is no guidance on what determines the AI's choice between autonomous resolution and human escalation. The prompt should govern this, but the design spec doesn't say so.

Replacement:
> AI resolves Unknowns and Open Questions from `intent.md` ΓÇö either by making a reasoned decision (stated in `spec.md`) or by asking the human during the Phase 2 chat. The Phase 2 prompt (`spec-building.md`) governs when the AI should decide autonomously vs. escalate to the human. No unresolved unknowns may carry into `spec.md`.

---

**[Minor] Design Spec, Phase 3 Code Mode ΓÇö step 3 "Implements logging throughout the codebase (mandatory)" is vague**

"Logging" is not scoped. A builder implementing this could produce anything from `console.log` sprinkled everywhere to a structured logging framework. The design spec should state the intent clearly.

Replacement:
> Implements structured logging throughout the codebase (mandatory) ΓÇö sufficient for production debugging. Logging framework and approach are determined by the Phase 2 spec.

---

**[Minor] Execution Plan, Task 19 ΓÇö Description is confusing about relationship to Task 23**

Current text:
> Implement orchestrator-level safety-rules enforcement for Code mode: before each Phase 3/4 agent invocation, call the code plugin's `safety-rules.js` `validate(operation)` and block disallowed operations. This is the enforcement mechanism; the rules themselves are defined in Task 23.

Task 19 depends on Task 6a and Task 20, but not Task 23 ΓÇö yet it calls Task 23's output. This is a dependency that should exist. If the intent is that Task 19 implements the generic enforcement mechanism (which already exists in Task 6a's description) and Task 23 populates the code-specific rules, then Task 19 is redundant with Task 6a's safety-rules enforcement line.

Replacement ΓÇö either:
(a) Remove Task 19 entirely (Task 6a already specifies "safety-rules enforcement: call plugin `validate(operation)` before every Phase 3/4 action"), or
(b) If Task 19 is meant to be Code-mode-specific enforcement that differs from the generic enforcement in 6a, state what the difference is and add Task 23 as a dependency.

---

## 2. Genuinely Missing Plan-Level Content

**[Major] Design Spec ΓÇö No specification of what operations the plan-mode safety-rules `validate()` function receives as input**

The design spec defines what Plan mode blocks (no CLI, no file creation outside docs, no prototyping, etc.), and the build spec defines `safety-rules.js` `validate(operation)` returning `{ allowed, reason }`. But nowhere is the taxonomy of `operation` values defined or described at the plan level. The orchestrator must pass _something_ to `validate()`, and what that something represents determines whether the safety rules can actually enforce the blocking list.

Proposed addition to the Design Spec, Plan Mode Safety Guardrails section (after the table):
> **Operation Taxonomy:** The orchestrator classifies every Phase 3/4 action into an operation type before invoking the plugin's `validate()`. Operation types include: `shell_exec` (any subprocess or CLI command), `file_create` (creating a new file ΓÇö subdivided by extension/location), `file_modify` (modifying an existing file), `package_install` (dependency installation), and `agent_invoke` (invoking a coding agent). The complete operation type list and the mapping from orchestrator actions to operation types are defined in the build spec.

---

**[Major] Design Spec ΓÇö No error handling for Handlebars template selection when Deliverable Type doesn't match any template name**

Phase 3 Plan Mode says: "If no type-specific template matches, the `generic.hbs` template is used as the default." But there's no handling specified for when `generic.hbs` itself is missing or the templates directory is empty.

Proposed addition to Design Spec, Phase 3 Error Handling table:
> | Template directory empty or `generic.hbs` missing | Halt and notify human: "No plan templates found. Ensure at least `generic.hbs` exists in `/plugins/plan/templates/`." No retry. |

---

**[Minor] Execution Plan ΓÇö No task for implementing `halted` project concurrency counting**

The design spec states: "Projects with `halted` status count toward the active project limit until the human either resumes them or terminates them." Task 2b handles concurrency enforcement, but its description only mentions "active (non-terminal) project count" ΓÇö it doesn't explicitly address the halted-counts-as-active rule, which is non-obvious behavior.

Proposed change to Task 2b description:
> Implement concurrency limit enforcement: block new project creation when active project count (all non-terminal states including `halted`) reaches `config.yaml` `concurrency.max_parallel_runs`, disable "New Project" action in sidebar with message, re-enable when a project reaches terminal state. Note: `halted` is not terminal ΓÇö halted projects count toward the limit.

---

**[Minor] Design Spec ΓÇö No specification of what happens if the human edits `constraints.md` in a way that breaks the expected structure**

`constraints.md` is hot-reloaded at each Phase 4 iteration start. The design spec doesn't say what happens if a human manually edits the file and introduces malformed content (e.g., removes the Acceptance Criteria section entirely, introduces YAML frontmatter, etc.).

Proposed addition to Design Spec, Phase 4 section, after the `constraints.md` hot-reload description:
> If `constraints.md` is unreadable or missing at the start of a Phase 4 iteration (due to manual deletion or file system error), the iteration halts and the human is notified. If the file is readable but has modified structure (missing sections, unexpected content), the AI reviewer processes it as-is ΓÇö the reviewer prompt is responsible for handling structural variations. ThoughtForge does not validate `constraints.md` structure at reload time.

---

**[Minor] Build Spec ΓÇö No schema or structure specified for the `PlanBuilderResponse` when `stuck` is false**

The `PlanBuilderResponse` interface shows `content?: string` as optional. When `stuck` is false, the builder has produced content ΓÇö but the interface doesn't require it. A builder returning `{ stuck: false }` with no content would be a silent failure.

Proposed change to the `PlanBuilderResponse` interface comment in the build spec:
```typescript
interface PlanBuilderResponse {
  stuck: boolean;        // true if the AI cannot proceed without human input
  reason?: string;       // Required when stuck is true ΓÇö what decision is needed
  content: string;       // The drafted content ΓÇö required when stuck is false, empty string when stuck is true
}
```
(Remove the `?` from `content` and note the empty-string convention for stuck state.)

---

## 3. Build Spec Material That Should Be Extracted

**[Minor] Design Spec, Phase 1 ΓÇö Resource file size limit "50MB" is an implementation parameter, not a design decision**

The line: "Resource file exceeds reasonable size (>50MB)" in the Phase 1 error handling table specifies a concrete threshold. This is a tunable implementation detail ΓÇö the design decision is "skip files that exceed a reasonable size limit." The specific number belongs in `config.yaml` and the build spec.

The design spec should say: "Resource file exceeds configurable size limit" and the build spec should define the default (50MB) as a `config.yaml` parameter.

---

**[Minor] Design Spec, Phase 1 ΓÇö Brain dump minimum word count "~10 words" is an implementation threshold**

The line: "Brain dump is empty or trivially short (fewer than ~10 words)" specifies a concrete minimum. This is a tunable implementation parameter.

The design spec should say: "Brain dump is empty or trivially short (below configurable minimum length)" and the build spec should define the default (10 words) as a constant or config key.

---

**[Minor] Design Spec, Phase 3ΓåÆ4 Transition ΓÇö "deliverable under ~100 characters" is an implementation threshold**

The line: "Phase 3 output exists but is empty or trivially small (Plan mode: deliverable under ~100 characters; Code mode: no test files found)" specifies concrete thresholds for the output completeness check.

The design spec should say: "Phase 3 output exists but is empty or trivially small (below minimum completeness thresholds)" and the build spec should define the specific thresholds (100 chars for plan, test file presence for code).

---

End of review. Three lists produced with severity tags, sorted by severity within each list.
