I see there's a previous review result. Now let me proceed with my own full review following the prompt's instructions. Let me read through all four documents carefully ΓÇö I've already loaded them ΓÇö and produce my review.

---

# Project Plan Review ΓÇö ThoughtForge Pipeline Tool

## 1. Writing That's Unclear

**[Major] DS-1: Phase 2 conversation mechanics are unspecified.**
The design spec describes Phase 1's correction flow in detail (chat corrections, "realign from here," Distill/Confirm buttons) but Phase 2 says only "Human confirms or overrides specific decisions" and "Human reviews acceptance criteria" with no specification of how the back-and-forth works. Phase 1's confirmation model statement says "This model applies to all human action points in the pipeline" but Phase 2 has no equivalent detail for multi-turn conversation, how the AI presents decisions for override, or how acceptance criteria editing works in the chat.

**Replacement text** (add after Phase 2 step 6, before step 7, in the design spec):

> **Phase 2 Conversation Mechanics:** The AI presents each proposed element (deliverable structure, key decisions, resolved unknowns, acceptance criteria) as a structured message in chat. The human responds with natural language corrections or overrides ΓÇö same chat-based correction model as Phase 1. The AI revises and re-presents the updated element. There is no "realign from here" in Phase 2 ΓÇö the scope of each element is small enough that targeted corrections suffice. The Confirm button advances to Phase 3 only after the validation gate in step 7 passes.

---

**[Major] DS-2: "Stuck status via a structured flag in its JSON output" is ambiguous in the design spec.**
Phase 3 Plan mode stuck detection says the AI signals via "a structured flag in its JSON output" with "Exact JSON schema in build spec." The build spec provides a TypeScript interface (`PlanBuilderResponse`) but the design spec wording implies the AI's natural response contains JSON, which conflicts with the Handlebars template-driven drafting described in the same section. It's unclear whether the builder prompt instructs the AI to return JSON wrapping the drafted content, or whether the orchestrator parses a separate signal.

**Replacement text** (design spec, Phase 3 Stuck Detection, Plan mode row):

> Plan | AI returns a JSON response containing a `stuck` boolean, an optional `reason` string (required when stuck), and a `content` string (the drafted document content when not stuck). The orchestrator parses this JSON to detect stuck status. Schema in build spec (`PlanBuilderResponse`). | Notify and wait

---

**[Minor] DS-3: "Extended period" is vague in Phase 2 error handling.**
The Phase 2 error handling table says "Human has not responded to a Phase 2 question for an extended period" ΓÇö no definition of what "extended" means.

**Replacement text:**

> Human has not responded to a Phase 2 question | No automatic action. Project remains in `spec_building` state. No timeout ΓÇö the project stays open indefinitely until the human acts. Reminder notification is deferred (not a current build dependency).

---

**[Minor] DS-4: "Trailing 3-iteration average" in the fabrication guard needs a cold-start clause.**
The build spec says "Any single severity category count exceeds its trailing 3-iteration average by more than 50%." What happens in iterations 1-2 when there aren't 3 prior iterations?

**Replacement text** (build spec, Fabrication Guard, condition 1):

> **Category spike:** Any single severity category count exceeds its trailing 3-iteration average by more than 50%, with a minimum absolute increase of 2. If fewer than 3 prior iterations exist, use the available iterations for the average. The fabrication guard cannot trigger before iteration 4 (need at least 3 data points for a meaningful trailing average).

---

**[Minor] DS-5: "Fewer than 70% of issues match" in the stagnation guard ΓÇö direction is ambiguous.**
The build spec says "Fewer than 70% of issues in the current iteration match an issue from the prior iteration." This could mean 70% of current issues match prior, or 70% of prior issues match current. These produce different results when issue counts differ between iterations.

**Replacement text:**

> **Issue rotation detection:** Fewer than 70% of issues in the current iteration have a matching issue in the prior iteration (i.e., for each current issue, check if any prior issue has Levenshtein similarity ΓëÑ 0.8 on the `description` field ΓÇö if fewer than 70% of current issues find a match, rotation is detected).

---

**[Minor] DS-6: Requirements brief says "Up to 3 (configurable)" for parallel execution but doesn't clarify what configures it.**

**Replacement text** (requirements brief, Success Criteria table, Parallel execution row):

> Up to 3 (configurable via `config.yaml` `concurrency.max_parallel_runs`)

---

**[Minor] DS-7: Build spec prompt sections that say "Status: Prompt text to be drafted before Task N begins" are ambiguous about ownership.**
Seven prompt sections in the build spec have placeholder status lines. This is fine for a build spec, but it's unclear whether the AI coder drafts these or the human provides them.

**Replacement text** for each placeholder prompt section (spec-building, plan-review, code-review, plan-fix, code-fix, completeness-gate, plan-build, code-build):

> **Status:** To be drafted by the AI coder as the first step of the task that depends on this prompt (see "Used by" reference above). The human reviews and edits via the Settings UI after initial draft.

---

## 2. Genuinely Missing Plan-Level Content

**[Critical] EP-M1: The execution plan has no testing strategy for the chat interface and UI components.**
Build Stage 8 has unit tests for state module, plugin loader, convergence guards, agent adapters, resource connectors, notifications, and prompt editor ΓÇö but no tests for the core chat interface (Task 7), WebSocket streaming, action buttons (Task 10), project list sidebar (Task 7g), or file dropping (Task 7h). The chat interface is the primary human interaction surface and has zero test coverage specified.

**Proposed content** (add to Build Stage 8 in the execution plan):

> | 58a | Unit tests: chat interface (WebSocket message delivery, AI response streaming, phase-labeled messages, project thread switching) | ΓÇö | Task 7, Task 7g | ΓÇö | Not Started |
> | 58b | Unit tests: action buttons (Distill triggers distillation, Confirm advances phase, button state disabled during processing, Phase 4 halt recovery buttons) | ΓÇö | Task 10, Task 40a | ΓÇö | Not Started |
> | 58c | Unit tests: file/resource dropping (upload to `/resources/`, unsupported file handling, concurrent uploads) | ΓÇö | Task 7h | ΓÇö | Not Started |

Also add to the Completion Checklist:

> - [ ] Chat interface tests pass (WebSocket, streaming, buttons, file drop, project switching)

---

**[Major] EP-M2: No task for drafting the Phase 2 spec-building prompt, but the task is actually present as 7f ΓÇö it's just easy to miss because it's embedded in Build Stage 2 without a clear connection to Task 12.**
Actually, Task 7f exists ("Draft `/prompts/spec-building.md` prompt text"). This is addressed. No action needed ΓÇö withdrawing this finding.

---

**[Major] EP-M3: The execution plan has no task for config schema validation.**
The design spec describes config validation on startup (Zod-based, exit on invalid/missing, descriptive errors). No task in the execution plan covers implementing this. Task 1 says "config.yaml loader" but doesn't mention validation.

**Proposed content** (update Task 1 in the execution plan):

> | 1 | Initialize Node.js project, folder structure, `config.yaml` loader with Zod schema validation (exit with descriptive error on missing file, invalid YAML, or schema violations) | ΓÇö | ΓÇö | ΓÇö | Not Started |

---

**[Major] EP-M4: No task for implementing the "realign from here" behavior.**
The design spec describes specific "realign from here" mechanics (Phase 1, step 9) ΓÇö treating the last substantive correction as baseline, discarding AI revisions after that point, re-distilling from original brain dump plus corrections. Task 9 says "correction loop (chat-based revisions, 'realign from here')" which covers it in name, but the realign mechanic is non-trivial and worth calling out explicitly.

**Proposed content** (clarify Task 9 in the execution plan):

> | 9 | Implement correction loop: chat-based revisions with AI re-presentation, and "realign from here" command (discard post-correction AI revisions, re-distill from brain dump + corrections up to baseline message) | ΓÇö | Task 8 | ΓÇö | Not Started |

---

**[Major] DS-M5: No specification of what happens when the human manually edits locked files (`intent.md`, `spec.md`, `constraints.md`) outside the pipeline.**
The design spec says these files are "locked ΓÇö no further modification by AI in subsequent phases. Human may still edit manually outside the pipeline." But there's no specification of the consequences. Does the polish loop re-read `constraints.md` each iteration (picking up manual edits)? Does `spec.md` get re-read at Phase 3 start? If the human edits `intent.md` after Phase 2, does anything notice?

**Proposed content** (add to design spec, after the Phase 2 outputs section):

> **Manual Edit Behavior:** "Locked" means the AI pipeline will not modify these files after their creation phase. However, the pipeline re-reads `constraints.md` at the start of each Phase 4 iteration, so manual human edits to acceptance criteria or review rules are picked up automatically. `spec.md` and `intent.md` are read at Phase 3 start and not re-read ΓÇö manual edits to these files after their respective phases require restarting from that phase (not currently supported; project must be recreated). The pipeline does not detect or warn about manual edits.

---

**[Minor] DS-M6: No specification for how the project name is derived from `intent.md`.**
The design spec says "the project name is extracted from the `intent.md` title" and the notification section says "the AI extracts or generates a short name from the brain dump." These describe slightly different things ΓÇö one says extraction from `intent.md` title, the other says generation from brain dump.

**Proposed content** (add clarification to design spec, Phase 1 step 0):

> After Phase 1 distillation locks `intent.md`, the project name is set to the first heading (H1) of `intent.md`. If `intent.md` has no H1 heading, the AI generates a short descriptive name (2-4 words) from the brain dump content and uses that as both the `intent.md` title and the project name.

---

## 3. Build Spec Material That Should Be Extracted

**[Minor] BS-1: The design spec contains Vibe Kanban CLI command details that belong in the build spec.**
The design spec's "Vibe Kanban Integration Interface" section describes "four operations: task creation, status updates, agent work execution, result reading" and references "Exact CLI commands and flags in build spec." This is fine ΓÇö the design spec describes operations, not commands. However, the sentence "All integration calls centralized in `vibekanban-adapter.js`" includes the filename, which is an implementation detail. This is borderline but acceptable since it serves as an architectural constraint (single adapter pattern), not just a filename. **No extraction needed** ΓÇö withdrawing this finding.

---

**[Minor] BS-2: The design spec Phase 1 step 0 contains implementation-level detail about directory creation.**
"ThoughtForge generates a unique project ID, creates the `/projects/{id}/` directory structure (including `/docs/` and `/resources/` subdirectories), initializes a git repo, writes an initial `status.json`..." ΓÇö this reads more like a build task than a design behavior. However, since it establishes the project structure that all subsequent phases depend on, it's appropriately at the plan level. **No extraction needed** ΓÇö withdrawing this finding.

No items require extraction. The design spec and build spec are cleanly separated ΓÇö the build spec already contains the implementation details (schemas, function signatures, CLI commands, prompt text) while the design spec stays at the behavioral level.

---

## Final Output: Consolidated AI Coder Prompt

```
You are applying review changes to the ThoughtForge project plan documents. Apply every change below exactly as specified. Do not interpret or improvise ΓÇö each change has explicit replacement or addition text.

## FILE: docs/thoughtforge-design-specification.md

### CHANGE 1 (DS-1): Add Phase 2 conversation mechanics
Location: Phase 2, after step 6 ("Human reviews acceptance criteria ΓÇö adds/removes as needed"), before step 7.
Add the following as a new paragraph between steps 6 and 7:

**Phase 2 Conversation Mechanics:** The AI presents each proposed element (deliverable structure, key decisions, resolved unknowns, acceptance criteria) as a structured message in chat. The human responds with natural language corrections or overrides ΓÇö same chat-based correction model as Phase 1. The AI revises and re-presents the updated element. There is no "realign from here" in Phase 2 ΓÇö the scope of each element is small enough that targeted corrections suffice. The Confirm button advances to Phase 3 only after the validation gate in step 7 passes.

### CHANGE 2 (DS-2): Clarify Plan mode stuck detection
Location: Phase 3 Stuck Detection table, Plan mode row.
Replace the current Plan row:
OLD: "Plan | AI signals stuck status via a structured flag in its JSON output ΓÇö not freeform text. The Phase 3 plan builder prompt requires this structured signal. Exact JSON schema in build spec. | Notify and wait"
NEW: "Plan | AI returns a JSON response containing a `stuck` boolean, an optional `reason` string (required when stuck), and a `content` string (the drafted document content when not stuck). The orchestrator parses this JSON to detect stuck status. Schema in build spec (`PlanBuilderResponse`). | Notify and wait"

### CHANGE 3 (DS-3): Fix vague "extended period" in Phase 2 error handling
Location: Phase 2 Error Handling table, third row.
Replace:
OLD: "Human has not responded to a Phase 2 question for an extended period | No automatic action. Project remains in `spec_building` state. Notification sent as a reminder (configurable ΓÇö deferred, not a current build dependency)."
NEW: "Human has not responded to a Phase 2 question | No automatic action. Project remains in `spec_building` state. No timeout ΓÇö the project stays open indefinitely until the human acts. Reminder notification is deferred (not a current build dependency)."

### CHANGE 4 (DS-M5): Add manual edit behavior specification
Location: After the Phase 2 outputs paragraph (after step 9, "Outputs: `spec.md` and `constraints.md` written to `/docs/` and locked..."), add a new paragraph:

**Manual Edit Behavior:** "Locked" means the AI pipeline will not modify these files after their creation phase. However, the pipeline re-reads `constraints.md` at the start of each Phase 4 iteration, so manual human edits to acceptance criteria or review rules are picked up automatically. `spec.md` and `intent.md` are read at Phase 3 start and not re-read ΓÇö manual edits to these files after their respective phases require restarting from that phase (not currently supported; project must be recreated). The pipeline does not detect or warn about manual edits.

### CHANGE 5 (DS-M6): Clarify project name derivation
Location: Phase 1 step 0, replace the sentence "After Phase 1 distillation locks `intent.md`, the project name is extracted from the `intent.md` title and written to `status.json`."
NEW: "After Phase 1 distillation locks `intent.md`, the project name is set to the first heading (H1) of `intent.md`. If `intent.md` has no H1 heading, the AI generates a short descriptive name (2-4 words) from the brain dump content and uses that as both the `intent.md` title and the project name. The project name is written to `status.json`."

---

## FILE: docs/thoughtforge-build-spec.md

### CHANGE 6 (DS-4): Add cold-start clause to fabrication guard
Location: Convergence Guard Parameters ΓåÆ Fabrication Guard ΓåÆ condition 1.
Replace:
OLD: "1. **Category spike:** Any single severity category count exceeds its trailing 3-iteration average by more than 50%, with a minimum absolute increase of 2"
NEW: "1. **Category spike:** Any single severity category count exceeds its trailing 3-iteration average by more than 50%, with a minimum absolute increase of 2. If fewer than 3 prior iterations exist, use the available iterations for the average. The fabrication guard cannot trigger before iteration 4 (need at least 3 data points for a meaningful trailing average)."

### CHANGE 7 (DS-5): Clarify stagnation guard issue rotation direction
Location: Convergence Guard Parameters ΓåÆ Stagnation Guard ΓåÆ Issue rotation detection.
Replace:
OLD: "- **Issue rotation detection:** Fewer than 70% of issues in the current iteration match an issue from the prior iteration"
NEW: "- **Issue rotation detection:** Fewer than 70% of issues in the current iteration have a matching issue in the prior iteration (i.e., for each current issue, check if any prior issue has Levenshtein similarity ΓëÑ 0.8 on the `description` field ΓÇö if fewer than 70% of current issues find a match, rotation is detected)"

### CHANGE 8 (DS-7): Clarify prompt draft ownership
Location: Every prompt section that currently says "**Status:** Prompt text to be drafted before Task N begins."
Replace each instance with:
"**Status:** To be drafted by the AI coder as the first step of the task that depends on this prompt (see "Used by" reference above). The human reviews and edits via the Settings UI after initial draft."

This applies to the following sections:
- Phase 2 System Prompt ΓÇö Spec Building
- Phase 4 System Prompt ΓÇö Plan Review
- Phase 4 System Prompt ΓÇö Code Review
- Phase 4 System Prompt ΓÇö Plan Fix
- Phase 4 System Prompt ΓÇö Code Fix
- Plan Completeness Gate Prompt
- Phase 3 System Prompt ΓÇö Plan Build
- Phase 3 System Prompt ΓÇö Code Build

---

## FILE: docs/thoughtforge-requirements-brief.md

### CHANGE 9 (DS-6): Clarify parallel execution config reference
Location: Success Criteria table, Parallel execution row, Target column.
Replace:
OLD: "Up to 3 (configurable)"
NEW: "Up to 3 (configurable via `config.yaml` `concurrency.max_parallel_runs`)"

---

## FILE: docs/thoughtforge-execution-plan.md

### CHANGE 10 (EP-M1): Add chat interface test tasks
Location: Build Stage 8 table, after Task 58.
Add three new rows:

| 58a | Unit tests: chat interface (WebSocket message delivery, AI response streaming, phase-labeled messages, project thread switching) | ΓÇö | Task 7, Task 7g | ΓÇö | Not Started |
| 58b | Unit tests: action buttons (Distill triggers distillation, Confirm advances phase, button state disabled during processing, Phase 4 halt recovery buttons) | ΓÇö | Task 10, Task 40a | ΓÇö | Not Started |
| 58c | Unit tests: file/resource dropping (upload to `/resources/`, unsupported file handling, concurrent uploads) | ΓÇö | Task 7h | ΓÇö | Not Started |

### CHANGE 11 (EP-M1): Add chat interface to completion checklist
Location: Completion Checklist, after the last checkbox item.
Add:

- [ ] Chat interface tests pass (WebSocket, streaming, buttons, file drop, project switching)

### CHANGE 12 (EP-M3): Add config validation to Task 1
Location: Build Stage 1, Task 1 description.
Replace:
OLD: "Initialize Node.js project, folder structure, `config.yaml` loader"
NEW: "Initialize Node.js project, folder structure, `config.yaml` loader with Zod schema validation (exit with descriptive error on missing file, invalid YAML, or schema violations)"

### CHANGE 13 (EP-M4): Clarify Task 9 description
Location: Build Stage 2, Task 9 description.
Replace:
OLD: "Implement correction loop (chat-based revisions, \"realign from here\")"
NEW: "Implement correction loop: chat-based revisions with AI re-presentation, and \"realign from here\" command (discard post-correction AI revisions, re-distill from brain dump + corrections up to baseline message)"

---

## AFTER ALL CHANGES

Run: git add docs/thoughtforge-requirements-brief.md docs/thoughtforge-design-specification.md docs/thoughtforge-build-spec.md docs/thoughtforge-execution-plan.md
Run: git commit -m "Apply plan review findings: 1 critical, 4 major, 5 minor across all four plan documents"
Run: git push
```

---

**Summary: 10 findings total** ΓÇö 1 Critical, 4 Major, 5 Minor

| Severity | Count | Key Issues |
|----------|-------|------------|
| Critical | 1 | EP-M1: No test coverage specified for the chat interface (primary human interaction surface) |
| Major | 4 | Phase 2 conversation mechanics unspecified; Plan mode stuck signal ambiguous; No config validation task; Manual edit behavior of locked files undefined |
| Minor | 5 | Vague timeout language; Fabrication guard cold-start; Stagnation guard direction; Parallel execution config ref; Prompt draft ownership |
