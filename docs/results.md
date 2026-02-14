The review is complete. Here's the full output:

---

# ThoughtForge Project Plan Review

> **Review Date:** 2026-02-14
> **Reviewer Posture:** Senior dev who will build from this plan
> **Documents Reviewed:** Requirements Brief, Design Specification, Build Spec, Execution Plan

---

## 1. Writing That's Unclear

### Finding 1.1 G현 [Minor] "Realign from here" baseline definition is convoluted

**Location:** Design Specification, Phase 1, step 9

**Current text:**
> Human can type "realign from here" as a chat message. The AI treats the human's most recent substantive correction (the last non-command human message before "realign from here") as the new baseline. All AI revisions produced after that correction are discarded. The AI re-distills from the original brain dump plus all human corrections up to and including that baseline message. Does not restart from the original brain dump alone.

**Problem:** "Most recent substantive correction" and "last non-command human message" create ambiguity about what counts as the baseline. A builder would have to guess at classification rules for "substantive" vs. "non-substantive" messages.

**Replacement text:**
> Human can type "realign from here" as a chat message. ThoughtForge identifies the last human message before "realign from here" that is not itself "realign from here" G현 this becomes the baseline. All AI revisions produced after that baseline message are discarded. The AI re-distills from the original brain dump plus all human messages up to and including the baseline. Does not restart from the original brain dump alone.

---

### Finding 1.2 G현 [Minor] Stagnation guard description conflates two behaviors under one term

**Location:** Design Specification, Convergence Guards table, "Stagnation" row

**Current text:**
> Total count plateaus across consecutive iterations AND issue rotation detected (specific issues change between iterations even though the total stays flat G현 the loop has reached the best quality achievable autonomously)

**Problem:** "Issue rotation detected" is stated as a trigger condition but the parenthetical explains the *interpretation* rather than the *detection rule*. The build spec fills in the algorithmic details (Levenshtein similarity), but the design spec's own description reads as if rotation alone is the signal, when what it actually means is: the counts are flat AND the specific issues are churning (replacing each other), indicating the AI is finding different things of similar severity each pass G현 a plateau.

**Replacement text:**
> Total error count remains the same across consecutive iterations AND the specific issues are rotating G현 fewer than a threshold percentage of issues from one iteration match the prior iteration. This indicates the loop has reached the best quality achievable autonomously: it keeps finding different things, but the overall quality level is stable.

---

### Finding 1.3 G현 [Minor] Fabrication guard description is dense and hard to parse in a single pass

**Location:** Design Specification, Convergence Guards table, "Fabrication" row

**Current text:**
> A severity category spikes well above its recent average, AND the system had previously approached convergence thresholds G현 suggesting the reviewer is manufacturing issues because nothing real remains

**Problem:** "Well above its recent average" is vague at the plan level. The build spec defines "50% above trailing 3-iteration average with minimum absolute increase of 2" G현 but the design spec should at least convey the two-condition structure clearly without requiring the reader to consult the build spec for basic understanding.

**Replacement text:**
> Two conditions: (1) any single severity category count spikes sharply above its recent trailing average, AND (2) the system had previously approached convergence thresholds. Together these suggest the reviewer is manufacturing issues because nothing real remains.

---

### Finding 1.4 G현 [Minor] Phase 1 step 0 is a dense paragraph covering 6 distinct operations

**Location:** Design Specification, Phase 1, step 0 ("Project Initialization")

**Problem:** Mixing initialization-time actions with post-Phase-1 actions in one paragraph makes it easy to miss the temporal split.

**Replacement text:**
> Human initiates a new project via the ThoughtForge chat interface (e.g., a "New Project" command or button). At initialization, ThoughtForge: generates a unique project ID, creates the `/projects/{id}/` directory structure (including `/docs/` and `/resources/` subdirectories), initializes a git repo, writes an initial `status.json` with phase `brain_dump` and `project_name` as empty string, opens a new chat thread, and G현 if Vibe Kanban integration is enabled G현 creates a corresponding Kanban card.
>
> After Phase 1 distillation locks `intent.md`, the project name is extracted from the `intent.md` title and written to `status.json`. If Vibe Kanban is enabled, the card name is updated at the same time.

---

## 2. Genuinely Missing Plan-Level Content

### Finding 2.1 G현 [Major] No project ID generation strategy specified

**Location:** Design Specification, Phase 1 step 0; Build Spec, `status.json` schema

**Problem:** The plan says "generates a unique project ID" but neither the design spec nor the build spec specifies the ID format or generation strategy. UUID? Incremental? Timestamp-based? This affects directory naming, Vibe Kanban task IDs, URL routing in the chat interface, and human readability.

**Proposed content to add to Design Specification, Phase 1 step 0, after "generates a unique project ID":**
> Project IDs are generated as `{timestamp}-{short-random}` (e.g., `20260214-a3f2`). The timestamp prefix provides natural chronological ordering in the filesystem. The random suffix prevents collisions when projects are created in rapid succession. IDs are used as directory names, Vibe Kanban task IDs, and URL path segments.

---

### Finding 2.2 G현 [Major] No definition of what "locking" a document means in implementation terms

**Location:** Design Specification, Phase 1 step 11, Phase 2 step 9

**Problem:** The plan repeatedly says documents are "locked G현 no further modification by AI in subsequent phases." But there is no specification of how locking is enforced. Without this, a builder might implement locking inconsistently or not at all, and the plan's safety guarantees around `intent.md` immutability become unenforceable.

**Proposed content to add to Design Specification, after the Phase-to-State Mapping table (as a new subsection "Document Locking"):**
> **Document Locking:** When a document is "locked," the orchestrator records the lock in `status.json` (e.g., `locked_docs: ["intent.md"]`). Before any AI write operation in subsequent phases, the orchestrator checks this list and blocks writes to locked files. This is an orchestrator-level enforcement G현 not file system permissions. The human can still edit locked files manually outside the pipeline.

---

### Finding 2.3 G현 [Major] Chat history clearing rules create a gap for Phase 4 agent context

**Location:** Design Specification, Project State Files, `chat_history.json`

**Problem:** Phase 3 stuck recovery messages persist into Phase 4 by design, but the design spec doesn't address whether Phase 4 review prompts should receive this chat context or only the deliverable files and `constraints.md`. A builder won't know whether to pass the full `chat_history.json` to Phase 4 agents or filter by phase.

**Proposed content to add to Design Specification, Phase 4 section, before "Each Iteration G현 Two Steps":**
> **Phase 4 Context:** Phase 4 review and fix prompts receive only the deliverable files and `constraints.md` as input. Chat history from prior phases (including Phase 3 stuck recovery) is not passed to Phase 4 agents. `chat_history.json` retains these messages for human reference and crash recovery, but they are not agent input during polish iterations.

---

### Finding 2.4 G현 [Major] No specification for how the Phase 2 "Confirm button blocked" mechanism works

**Location:** Design Specification, Phase 2 step 7

**Problem:** "Blocked" is a UI behavior that has no corresponding technical spec. What triggers the validation G현 is it a pre-check when the human clicks Confirm, or is the button state continuously updated? This affects whether the builder implements a synchronous gate or a reactive UI state.

**Proposed content to add to Design Specification, Phase 2, after step 7:**
> **Confirm Gate Mechanism:** When the human clicks Confirm during Phase 2, the orchestrator runs a pre-advancement validation: it checks whether the AI has marked all Unknowns and Open Questions from `intent.md` as resolved in the current spec draft. If unresolved items remain, the advancement is rejected G현 the Confirm action fails with a message listing the remaining items, and the phase does not advance. The button is always visible and clickable; the gate is a server-side validation, not a UI state toggle.

---

### Finding 2.5 G현 [Major] No specification for how review prompts handle acceptance criteria

**Location:** Design Specification, Phase 4; Build Spec, prompt placeholders

**Problem:** The design spec says Phase 4 reviews evaluate the deliverable against `constraints.md` including acceptance criteria. But it never specifies how G현 are criteria checked one-by-one? Reported as a separate section in the review JSON? Part of general judgment? This matters because acceptance criteria are the primary quality gate and a reviewer prompt that doesn't explicitly enumerate them will likely miss some.

**Proposed content to add to Design Specification, Phase 4, after "Step 1 G현 Review":**
> The review prompt passes the full text of `constraints.md` (including all acceptance criteria) to the reviewer AI. The reviewer must evaluate every acceptance criterion individually and report unmet criteria as issues in the JSON error report. Acceptance criteria violations are always severity `critical`. This ensures the polish loop cannot converge while acceptance criteria remain unmet.

---

### Finding 2.6 G현 [Minor] Execution Plan has no task for config.yaml schema validation

**Location:** Design Specification, "Config Validation" paragraph; Execution Plan, Build Stage 1

**Problem:** The design spec describes Zod-based config validation, but the Execution Plan Task 1 only says "config.yaml loader" G현 the validation is non-trivial and deserves its own task.

**Proposed: add Task 1b to Build Stage 1:**

| # | Task | Owner | Depends On | Estimate | Status |
|---|------|-------|------------|----------|--------|
| 1b | Implement `config.yaml` Zod schema validation: validate all keys on startup, exit with descriptive per-key error on failure, no partial loading | G현 | Task 1 | G현 | Not Started |

---

### Finding 2.7 G현 [Minor] No error handling specified for project initialization failures

**Location:** Design Specification, Phase 1 step 0

**Problem:** The Phase 1 error handling table covers agent failures, empty brain dumps, unreadable resources, and connector failures G현 but not initialization failures (filesystem errors, git init failures, VK card creation failures).

**Proposed content to add to Phase 1 Error Handling table:**

| Condition | Action |
|---|---|
| Project directory creation failure (permissions, disk space) | Halt immediately with error message. No project created, no state files written. |
| Git repo initialization failure | Halt immediately with error message. Clean up any partially created project directory. |
| Vibe Kanban card creation failure (VK enabled) | Log the failure, notify the human, proceed without Kanban visualization. Project runs in VK-disabled mode for this project. |

---

### Finding 2.8 G현 [Minor] No input size limits for brain dump or resource files

**Location:** Design Specification, Phase 1 Inputs table

**Problem:** AI context windows have hard token limits. A large resource would silently fail or produce garbage distillation.

**Proposed content to add after Phase 1 Inputs table:**
> **Input Size Limits:** Resource files exceeding the configured agent's context window will be truncated with a notification to the human specifying which file was truncated and how much was lost. ThoughtForge does not chunk or summarize oversized inputs G현 truncation is the only strategy in v1. The human can split large files manually. Maximum individual file sizes and total input budget are deferred to build spec configuration.

---

### Finding 2.9 G현 [Minor] Execution Plan Build Stage 8 has no chat interface integration test task

**Location:** Execution Plan, Build Stage 8

**Problem:** No integration test for the chat interface G현 WebSocket connectivity, message streaming, button interactions, project switching, file dropping.

**Proposed: add Task 59 to Build Stage 8:**

| # | Task | Owner | Depends On | Estimate | Status |
|---|------|-------|------------|----------|--------|
| 59 | Integration tests: chat interface (WebSocket connection, message streaming, button actions, project switching, file upload to `/resources/`) | G현 | Task 7, Task 7g, Task 7h, Task 10 | G현 | Not Started |

Also add to Completion Checklist:
> - [ ] Chat interface integration tests pass (WebSocket, streaming, buttons, file upload)

---

## 3. Build Spec Material That Should Be Extracted

**No findings.** The design specification stays at the plan level throughout. Implementation details (schemas, function signatures, prompt text, CLI commands, algorithmic parameters) are already correctly placed in the build spec. This split is clean.

---

## Summary

| Severity | Count |
|----------|-------|
| Critical | 0 |
| Major | 5 |
| Minor | 8 |
| **Total** | **13** |

No critical blockers. The five major findings (project ID format, document locking mechanism, Phase 4 agent context, Phase 2 confirm gate, acceptance criteria review behavior) would each force a builder to make undocumented architectural decisions. All are resolvable with the proposed additions above.

---

## Consolidated Coder Prompt

```
You are applying the results of a plan review to the ThoughtForge project documents.
Apply every change below to the specified files. Do not interpret, reorder, or skip any
change. After all changes are applied, git add the modified files, commit with the message
"Apply plan review findings G현 clarity fixes, missing content, new tasks", and push to remote.

=============================================================================
FILE: docs/thoughtforge-design-specification.md
=============================================================================

CHANGE 1 G현 Replace "realign from here" description (Phase 1, step 9)

Find:
> Human can type "realign from here" as a chat message. The AI treats the human's most
> recent substantive correction (the last non-command human message before "realign from
> here") as the new baseline. All AI revisions produced after that correction are discarded.
> The AI re-distills from the original brain dump plus all human corrections up to and
> including that baseline message. Does not restart from the original brain dump alone.

Replace with:
> Human can type "realign from here" as a chat message. ThoughtForge identifies the last
> human message before "realign from here" that is not itself "realign from here" G현 this
> becomes the baseline. All AI revisions produced after that baseline message are discarded.
> The AI re-distills from the original brain dump plus all human messages up to and
> including the baseline. Does not restart from the original brain dump alone.

---

CHANGE 2 G현 Replace Stagnation guard description in Convergence Guards table

Find the Stagnation row's "Condition" cell:
> Total count plateaus across consecutive iterations AND issue rotation detected (specific
> issues change between iterations even though the total stays flat G현 the loop has reached
> the best quality achievable autonomously)

Replace with:
> Total error count remains the same across consecutive iterations AND the specific issues
> are rotating G현 fewer than a threshold percentage of issues from one iteration match the
> prior iteration. This indicates the loop has reached the best quality achievable
> autonomously: it keeps finding different things, but the overall quality level is stable.

---

CHANGE 3 G현 Replace Fabrication guard description in Convergence Guards table

Find the Fabrication row's "Condition" cell:
> A severity category spikes well above its recent average, AND the system had previously
> approached convergence thresholds G현 suggesting the reviewer is manufacturing issues
> because nothing real remains

Replace with:
> Two conditions: (1) any single severity category count spikes sharply above its recent
> trailing average, AND (2) the system had previously approached convergence thresholds.
> Together these suggest the reviewer is manufacturing issues because nothing real remains.

---

CHANGE 4 G현 Replace Phase 1 step 0 paragraph (Project Initialization)

Find the paragraph starting with:
> Human initiates a new project via the ThoughtForge chat interface

Replace the entire paragraph (from "Human initiates" through "a corresponding card is
created at this point.") with:

> Human initiates a new project via the ThoughtForge chat interface (e.g., a "New Project"
> command or button). At initialization, ThoughtForge: generates a unique project ID
> (format: `{timestamp}-{short-random}`, e.g., `20260214-a3f2` G현 timestamp prefix for
> chronological ordering, random suffix to prevent collisions; used as directory names,
> Vibe Kanban task IDs, and URL path segments), creates the `/projects/{id}/` directory
> structure (including `/docs/` and `/resources/` subdirectories), initializes a git repo,
> writes an initial `status.json` with phase `brain_dump` and `project_name` as empty
> string, opens a new chat thread, and G현 if Vibe Kanban integration is enabled G현 creates
> a corresponding Kanban card.
>
> After Phase 1 distillation locks `intent.md`, the project name is extracted from the
> `intent.md` title and written to `status.json`. If Vibe Kanban is enabled, the card
> name is updated at the same time.

---

CHANGE 5 G현 Add "Document Locking" subsection after the Phase-to-State Mapping table

Insert the following new subsection immediately after the "Vibe Kanban columns mirror
these `status.json` values directly." line and BEFORE "Project Lifecycle After Completion":

**Document Locking:** When a document is "locked," the orchestrator records the lock in
`status.json` (e.g., `locked_docs: ["intent.md"]`). Before any AI write operation in
subsequent phases, the orchestrator checks this list and blocks writes to locked files.
This is an orchestrator-level enforcement G현 not file system permissions. The human can
still edit locked files manually outside the pipeline.

---

CHANGE 6 G현 Add Phase 4 Context note before "Each Iteration G현 Two Steps"

Insert the following immediately before the "**Each Iteration G현 Two Steps:**" line in
Phase 4:

**Phase 4 Context:** Phase 4 review and fix prompts receive only the deliverable files
and `constraints.md` as input. Chat history from prior phases (including Phase 3 stuck
recovery) is not passed to Phase 4 agents. `chat_history.json` retains these messages
for human reference and crash recovery, but they are not agent input during polish
iterations.

---

CHANGE 7 G현 Add acceptance criteria review behavior after Phase 4 "Step 1 G현 Review"

Insert the following immediately after the "Step 1 G현 Review" description ("Outputs ONLY
a JSON error report. Does not fix anything."):

The review prompt passes the full text of `constraints.md` (including all acceptance
criteria) to the reviewer AI. The reviewer must evaluate every acceptance criterion
individually and report unmet criteria as issues in the JSON error report. Acceptance
criteria violations are always severity `critical`. This ensures the polish loop cannot
converge while acceptance criteria remain unmet.

---

CHANGE 8 G현 Add Confirm Gate Mechanism after Phase 2 step 7

Insert the following after step 7 in Phase 2 (after "the AI presents the remaining items
to the human.") and before step 8:

**Confirm Gate Mechanism:** When the human clicks Confirm during Phase 2, the orchestrator
runs a pre-advancement validation: it checks whether the AI has marked all Unknowns and
Open Questions from `intent.md` as resolved in the current spec draft. If unresolved items
remain, the advancement is rejected G현 the Confirm action fails with a message listing the
remaining items, and the phase does not advance. The button is always visible and clickable;
the gate is a server-side validation, not a UI state toggle.

---

CHANGE 9 G현 Add Input Size Limits after Phase 1 Inputs table

Insert the following after the Phase 1 Inputs table and before "### Outputs":

**Input Size Limits:** Resource files exceeding the configured agent's context window will
be truncated with a notification to the human specifying which file was truncated and how
much was lost. ThoughtForge does not chunk or summarize oversized inputs G현 truncation is
the only strategy in v1. The human can split large files manually. Maximum individual file
sizes and total input budget are deferred to build spec configuration.

---

CHANGE 10 G현 Add initialization error handling rows to Phase 1 Error Handling table

Add the following three rows to the end of the Phase 1 Error Handling table:

| Project directory creation failure (permissions, disk space) | Halt immediately with error message. No project created, no state files written. |
| Git repo initialization failure | Halt immediately with error message. Clean up any partially created project directory. |
| Vibe Kanban card creation failure (VK enabled) | Log the failure, notify the human, proceed without Kanban visualization. Project runs in VK-disabled mode for this project. |

=============================================================================
FILE: docs/thoughtforge-execution-plan.md
=============================================================================

CHANGE 11 G현 Add Task 1b to Build Stage 1 table

Add the following row to the Build Stage 1 table, immediately after the Task 1a row:

| 1b | Implement `config.yaml` Zod schema validation: validate all keys on startup, exit with descriptive per-key error on failure, no partial loading | G현 | Task 1 | G현 | Not Started |

---

CHANGE 12 G현 Add Task 59 to Build Stage 8 table

Add the following row to the Build Stage 8 table, after Task 58:

| 59 | Integration tests: chat interface (WebSocket connection, message streaming, button actions, project switching, file upload to `/resources/`) | G현 | Task 7, Task 7g, Task 7h, Task 10 | G현 | Not Started |

---

CHANGE 13 G현 Add chat interface integration test to Completion Checklist

Add the following line to the Completion Checklist, after the "Unit tests pass for all
core modules" line:

- [ ] Chat interface integration tests pass (WebSocket, streaming, buttons, file upload)

=============================================================================
FILE: docs/thoughtforge-build-spec.md
=============================================================================

CHANGE 14 G현 Update `status.json` schema to include `locked_docs` field

In the `status.json` schema TypeScript interface, add the following field after
`halted_reason`:

  locked_docs: string[];       // Documents locked after phase completion (e.g., ["intent.md", "spec.md", "constraints.md"])

=============================================================================
AFTER ALL CHANGES
=============================================================================

Run:
  git add docs/thoughtforge-design-specification.md docs/thoughtforge-execution-plan.md docs/thoughtforge-build-spec.md
  git commit -m "Apply plan review findings G현 clarity fixes, missing content, new tasks"
  git push
```

---

I also attempted to write this to `results.md` but file write permissions were denied. Let me know if you'd like me to try again or save it elsewhere.
