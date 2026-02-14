# Apply Prompt — Rounds 4 + 5 Combined

**Instructions:** Apply ALL changes below to the source files. Round 4 was never applied — both rounds must be applied together. Changes are organized by target file. Apply each change in order within each file. After all changes are applied, git commit and push.

---

## File 1: `docs/thoughtforge-design-specification.md`

### Change 1 (R4 Finding 2) — Add `deliverable_type` transition to Phase 1 step 11

**Find:**
```
11. Output: `intent.md` written to `/docs/` and locked — no further modification by AI in subsequent phases. Human may still edit manually outside the pipeline.
```

**Replace with:**
```
11. Output: `intent.md` written to `/docs/` and locked — no further modification by AI in subsequent phases. Human may still edit manually outside the pipeline. The `deliverable_type` field in `status.json` is set to `"plan"` or `"code"` at this point, derived from the Deliverable Type section of the confirmed `intent.md`.
```

### Change 2 (R5 Finding 10) — Add `status.json` corruption handling to Phase 1 Error Handling table

**Find the Phase 1 Error Handling table** (starts with "| Condition | Action |" after "**Phase 1 Error Handling:**"). **Add this row at the end of the table:**

```
| `status.json` unreadable, missing, or invalid (applies to all phases, not just Phase 1) | Halt the project and notify the operator with the file path and the specific error (parse failure, missing file, invalid phase value). Do not attempt recovery or partial loading — the operator must fix or recreate the file. |
```

### Change 3 (R5 Finding 9) — Add atomic write requirement for state files

**Find:**
```
### Project State Files
```

**Replace with:**
```
### Project State Files

**Write Atomicity:** All state file writes (`status.json`, `polish_state.json`, `chat_history.json`) use atomic write — write to a temporary file in the same directory, then rename to the target path. This prevents partial writes from corrupting state on crash. The project state module (Task 3) implements this as the default write behavior for all state files.
```

### Change 4 (R5 Finding 1) — Clarify Phase 4 git commit granularity

**Find:**
```
Commits occur at: `intent.md` lock (end of Phase 1), `spec.md` and `constraints.md` lock (end of Phase 2), Phase 3 build completion, and after every Phase 4 review and fix step.
```

**Replace with:**
```
Commits occur at: `intent.md` lock (end of Phase 1), `spec.md` and `constraints.md` lock (end of Phase 2), Phase 3 build completion, and twice per Phase 4 iteration — once after the review step (captures the review JSON) and once after the fix step (captures applied fixes). Two commits per iteration enables rollback of a bad fix while preserving the review that identified the issues.
```

### Change 5 (R5 Finding 14) — Add server host to config table

**Find:**
```
| Server | Web chat interface port | 3000 |
```

**Replace with:**
```
| Server | Web chat interface host and port | 127.0.0.1:3000 |
```

### Change 6 (R5 Finding 3) — Fix prompts path prefix

**Find:**
```
| Prompts | Prompt directory path, individual prompt files | `/prompts/`, one `.md` file per prompt |
```

**Replace with:**
```
| Prompts | Prompt directory path, individual prompt files | `./prompts/`, one `.md` file per prompt |
```

---

## File 2: `docs/thoughtforge-build-spec.md`

### Change 7 (R4 Finding 1a) — Clarify VK CLI "Execute agent work" row

**Find:**
```
| Execute agent work | `vibekanban task run {task_id} --prompt-file {path}` | Phase 3 build, Phase 4 fix steps |
```

**Replace with:**
```
| Execute agent work | `vibekanban task run {task_id} --prompt-file {path}` | Code mode only: Phase 3 build, Phase 4 fix steps. Plan mode invokes agents directly via agent layer — VK is visualization only. |
```

### Change 8 (R4 Finding 1b) — Clarify VK CLI "Read task result" row

**Find:**
```
| Read task result | `vibekanban task result {task_id}` | After each agent execution |
```

**Replace with:**
```
| Read task result | `vibekanban task result {task_id}` | After each Code mode agent execution via VK |
```

### Change 9 (R4 Finding 3) — Add comment explaining `done` exclusion from ChatMessage.phase

**Find:**
```
  phase: "brain_dump" | "distilling" | "human_review" | "spec_building" | "building" | "polishing" | "halted";
```

**Replace with:**
```
  phase: "brain_dump" | "distilling" | "human_review" | "spec_building" | "building" | "polishing" | "halted";  // "done" excluded — no chat occurs after completion
```

### Change 10 (R4 Finding 4) — Add guard evaluation order

**Find the Convergence Guard Parameters heading:**
```
## Convergence Guard Parameters

**Used by:** Tasks 33–37 (convergence guards)
```

**Replace with:**
```
## Convergence Guard Parameters

**Used by:** Tasks 33–37 (convergence guards)

### Guard Evaluation Order

Guards are evaluated in the following order after each iteration. The first guard that triggers ends evaluation — subsequent guards are not checked.

1. **Termination** (success) — checked first so that a successful outcome is never overridden by a halt
2. **Hallucination** — checked before stagnation/fabrication because a spike after a downward trend is the strongest anomaly signal
3. **Fabrication** — checked before stagnation because fabricated issues would produce false plateau signals
4. **Stagnation** (success) — checked after halt guards to ensure the plateau is genuine
5. **Max iterations** — checked last as the backstop

If no guard triggers, the loop proceeds to the next iteration.
```

### Change 11 (R5 Finding 5) — Add `spec.md` and `constraints.md` structure templates

**Find the line `*Template Version: 1.0 | Last Updated: February 2026*` at the end of the file.** Insert the following BEFORE that line:

```markdown
---

## `spec.md` Structure

**Used by:** Task 13 (spec and constraints generation)
**Written:** End of Phase 2, locked after write

### Plan Mode

```markdown
# {Project Name} — Specification

## Deliverable Overview
{Restated objective from intent.md}

## Deliverable Structure
{Proposed plan sections following OPA Framework — every major section gets an OPA table}

## Key Decisions
{Each decision the AI made or the human confirmed, with rationale}

## Resolved Unknowns
{Every Unknown and Open Question from intent.md, with resolution and source (AI-reasoned or human-provided)}

## Dependencies
{External tools, services, data, or prerequisites required}

## Scope Boundaries
{What is explicitly included and excluded}
```

### Code Mode

Same structure as Plan mode, except:
- **Deliverable Structure** contains proposed architecture, language, framework, and tools (including OSS qualification results where applicable)

---

## `constraints.md` Structure

**Used by:** Task 13 (spec and constraints generation), Task 30 (polish loop — re-read at each Phase 4 iteration start)
**Written:** End of Phase 2, locked after write (but human may manually edit; changes picked up at next Phase 4 iteration)

```markdown
# {Project Name} — Review Constraints

## Context
{What this deliverable does, from intent.md}

## Deliverable Type
{Plan or Code}

## Priorities
{What the human cares about}

## Exclusions
{What not to touch, what not to flag}

## Severity Definitions
{What counts as critical / medium / minor}

## Scope
{Plan mode: sections/topics in scope. Code mode: files/functions in scope.}

## Acceptance Criteria
{5–10 statements of what the deliverable must contain or do}
```

---

## Notification Payload Schema

**Used by:** Tasks 4–5 (notification layer + phase transition notifications)
**Sent:** Every phase transition, convergence event, error, and stuck/halt condition

```typescript
interface NotificationPayload {
  project_id: string;
  project_name: string;
  phase: string;
  event_type: "convergence_success" | "guard_triggered" | "human_needed" | "milestone_complete" | "error";
  summary: string;  // One-line description with actionable context
}
```
```

### Change 12 (R5 Finding 12) — Add shell safety note to agent communication

**Find:**
```
4. Response parsed/validated (Zod for review JSON, file diff detection for fix steps)
```

**Replace with:**
```
4. Response parsed/validated (Zod for review JSON, file diff detection for fix steps)

**Shell safety:** Prompt content is passed to agent subprocesses via file descriptor or stdin pipe — never through shell argument expansion or interpolation. The agent invocation layer must not use shell string concatenation for prompt content. This prevents accidental command execution from shell metacharacters in brain dump text or resource files.
```

### Change 13 (R5 Finding 3) — Fix prompts path in build spec

**Find:**
```
All pipeline prompts are stored as external `.md` files in `/prompts/`.
```

**Replace with:**
```
All pipeline prompts are stored as external `.md` files in `./prompts/` (relative to project root).
```

### Change 14 (R5 Finding 14) — Add server host to config.yaml template

**Find:**
```yaml
# Web server
server:
  port: 3000
```

**Replace with:**
```yaml
# Web server
server:
  host: "127.0.0.1"  # Bind to localhost only. Change to "0.0.0.0" for network access.
  port: 3000
```

---

## File 3: `docs/thoughtforge-execution-plan.md`

### Change 15 (R4 Finding 5 + R4 Finding 9 combined + R5 Finding 8) — Update Task 6a

**Find:**
```
| 6a | Implement pipeline orchestrator: phase sequencing based on `status.json`, plugin selection by `deliverable_type` | — | Task 2, Task 3, Task 6 | — | Not Started |
```

**Replace with:**
```
| 6a | Implement pipeline orchestrator: phase sequencing based on `status.json`, plugin selection by `deliverable_type`, safety-rules enforcement (call plugin `validate(operation)` before every Phase 3/4 action), cross-cutting file system error handling (halt and notify on write failures — no retry) | — | Task 2, Task 3, Task 6 | — | Not Started |
```

### Change 16 (R5 Finding 7) — Move Plan Completeness Gate from Stage 3 to Stage 1

**Find in Build Stage 1, after the Task 6c row:**
(Add new rows after Task 6c)

```
| 6d | Implement Plan Completeness Gate: assessment prompt for Code mode Phase 3 entry (loaded from `/prompts/completeness-gate.md`), halt with `plan_incomplete` on fail — human decides to override or create separate Plan project | — | Task 6b, Task 7a, Task 6e, Tasks 41–42 | — | Not Started |
| 6e | Draft `/prompts/completeness-gate.md` prompt text | — | Task 7a | — | Not Started |
```

**Find and update Task 6b:**
```
| 6b | Implement Phase 2→3 transition: Plan Completeness Gate trigger for Code mode, advancement logic | — | Task 6a, Task 19 | — | Not Started |
```

**Replace with:**
```
| 6b | Implement Phase 2→3 transition: Plan Completeness Gate trigger for Code mode, advancement logic | — | Task 6a, Task 6d | — | Not Started |
```

**Find in Build Stage 3 and remove Tasks 19 and 19a:**

Remove:
```
| 19 | Implement Plan Completeness Gate (assessment prompt for Code mode entry, halt with `plan_incomplete` on fail — human decides to override or create separate Plan project) | — | Task 14, Task 7a, Task 19a, Tasks 41–42 | — | Not Started |
| 19a | Draft `/prompts/completeness-gate.md` prompt text | — | Task 7a | — | Not Started |
```

### Change 17 (R5 Finding 13) — Add first-run setup task

**Find Task 1a row.** Add after it:
```
| 1b | Implement first-run setup: `config.yaml.example` copied to `config.yaml` on first run if missing (with comment guidance), prerequisite check (Node.js version, agent CLIs on PATH), startup validation summary | — | Task 1 | — | Not Started |
```

### Change 18 (R5 Finding 8) — Update Task 3a (logging integration)

**Find:**
```
| 3a | Implement operational logging module (per-project `thoughtforge.log`, structured entries for agent calls, phase transitions, errors) | — | Task 1 | — | Not Started |
```

**Replace with:**
```
| 3a | Implement operational logging module (per-project `thoughtforge.log`, structured entries for agent calls, phase transitions, guard evaluations, halts, errors, config/plugin loading). All tasks that produce loggable events (Tasks 1, 6, 6a, 33–37, 41) must call this module — logging integration is the responsibility of each event-producing task, not a separate wiring task. | — | Task 1 | — | Not Started |
```

### Change 19 (R5 Finding 11) — Add path traversal protection to Task 7h

**Find:**
```
| 7h | Implement file/resource dropping in chat interface (upload to `/resources/`) | — | Task 7 | — | Not Started |
```

**Replace with:**
```
| 7h | Implement file/resource dropping in chat interface (upload to `/resources/`). Validate that resolved file paths stay within the project's `/resources/` directory — reject uploads with path traversal components (`..`, absolute paths). | — | Task 7 | — | Not Started |
```

### Change 20 (R4 Finding 7 + R5 Finding 4 combined) — Update Task 8

**Find:**
```
| 8 | Implement Phase 1: brain dump intake, resource reading, distillation prompt (loaded from `/prompts/brain-dump-intake.md`) | — | Task 6a, Task 7, Task 7a, Task 7c, Tasks 41–42 | — | Not Started |
```

**Replace with:**
```
| 8 | Implement Phase 1: brain dump intake (including empty/trivially-short input guard — block distillation and prompt for more detail), resource reading (log and skip unreadable files, notify human, proceed with available inputs), distillation prompt (loaded from `/prompts/brain-dump-intake.md`), Phase 1 sub-state transitions in `status.json` (`brain_dump` → `distilling` on Distill button → `human_review` on distillation complete) | — | Task 6a, Task 7, Task 7a, Task 7c, Tasks 41–42 | — | Not Started |
```

### Change 21 (R4 Finding 10) — Update Task 9a

**Find:**
```
| 9a | Implement `chat_history.json` persistence: append after each chat message, clear on phase advancement confirmation, resume from last recorded message on crash | — | Task 3, Task 7 | — | Not Started |
```

**Replace with:**
```
| 9a | Implement `chat_history.json` persistence: append after each chat message, clear on Phase 1→2 and Phase 2→3 confirmation only (NOT on Phase 3→4 automatic transition), resume from last recorded message on crash | — | Task 3, Task 7 | — | Not Started |
```

### Change 22 (R5 Finding 2 + R5 Finding 17) — Update Task 12 and add mode note

**Find:**
```
| 12 | Implement Phase 2: spec building, constraint discovery, acceptance criteria extraction, human review/override of proposed decisions, human review of acceptance criteria, Unknown/Open Question resolution validation gate (block Confirm if unresolved items remain), Confirm to advance | — | Task 6a, Task 10, Task 11, Task 7a, Task 7f, Task 25, Tasks 41–42 | — | Not Started |
```

**Replace with:**
```
| 12 | Implement Phase 2: spec building with mode-specific behavior (Plan mode: propose OPA-structured plan sections; Code mode: propose architecture/language/framework/tools with OSS discovery integration from Task 25), AI challenge of weak or risky decisions in `intent.md` (does not rubber-stamp), constraint discovery, acceptance criteria extraction (5–10 per design spec), human review/override of proposed decisions, human review of acceptance criteria, Unknown/Open Question resolution validation gate (block Confirm if unresolved items remain), Confirm to advance | — | Task 6a, Task 10, Task 11, Task 7a, Task 7f, Task 25, Tasks 41–42 | — | Not Started |
```

**Also add a note before the Build Stage 2 table:**
```
> **Note:** Task 12 depends on Task 25 (OSS discovery) for Code mode Phase 2 only. Plan mode Phase 2 does not use OSS discovery and can be implemented and tested before Task 25 is complete.
```

### Change 23 (R4 Finding 8) — Update Task 15

**Find:**
```
| 15 | Implement `builder.js` — Handlebars template-driven document drafting | — | Task 6a, Task 14, Task 15a, Tasks 41–42 | — | Not Started |
```

**Replace with:**
```
| 15 | Implement `builder.js` — Handlebars template-driven document drafting, including template rendering failure handling (halt immediately, no retry) | — | Task 6a, Task 14, Task 15a, Tasks 41–42 | — | Not Started |
```

### Change 24 (R4 Finding 6a) — Update Task 21

**Find:**
```
| 21 | Implement `builder.js` — agent-driven coding via Vibe Kanban | — | Task 6a, Task 20, Task 21a, Task 27, Tasks 41–42 | — | Not Started |
```

**Replace with:**
```
| 21 | Implement `builder.js` — agent-driven coding (via Vibe Kanban when enabled, direct agent invocation when disabled) | — | Task 6a, Task 20, Task 21a, Task 27, Task 29a, Tasks 41–42 | — | Not Started |
```

### Change 25 (R4 Finding 6b) — Update Task 29a

**Find:**
```
| 29a | Implement VK-disabled fallback: direct agent invocation path when `vibekanban.enabled` is false | — | Task 26 | — | Not Started |
```

**Replace with:**
```
| 29a | Implement VK-disabled fallback: direct agent invocation path when `vibekanban.enabled` is false | — | Task 26, Tasks 41–42 | — | Not Started |
```

### Change 26 (R4 Finding 11) — Update Task 30c

**Find:**
```
| 30c | Implement Code mode iteration cycle: test execution via `test-runner.js` before review, test results passed as reviewer context | — | Task 24, Task 30 | — | Not Started |
```

**Replace with:**
```
| 30c | Implement Code mode iteration cycle: test execution via `test-runner.js` before review, test results passed as reviewer context. Distinguish test runner crashes (process error — retry once, halt on second) from test assertion failures (pass to reviewer as context). | — | Task 24, Task 30 | — | Not Started |
```

### Change 27 (R5 Findings 13, 15, 16) — Add test tasks to Build Stage 8

**Find the last row in Build Stage 8 (Task 58c).** Add after it:

```
| 58d | Unit tests: "realign from here" command (identifies correct baseline message, excludes post-correction messages, re-distills with corrections, ignores command when no prior corrections exist) | — | Task 9 | — | Not Started |
| 58e | Unit tests: Phase 3 stuck recovery (Provide Input resumes builder with human input while staying in `building` state, Terminate sets `halted`, stuck detection triggers correctly for both Plan and Code modes) | — | Task 6c | — | Not Started |
| 50b | Unit tests: first-run setup (missing config creates from example, prerequisite check reports missing CLIs, valid config passes startup) | — | Task 1b | — | Not Started |
```

### Change 28 (R5 Finding 13) — Update Completion Checklist

**Find:**
```
- [ ] `config.yaml` controls all configurable values
```

**Add after it:**
```
- [ ] First-run setup works: `config.yaml.example` copied, prerequisites checked, startup validates
```

---

## Final Step

After applying ALL changes above, run:

```bash
git add docs/thoughtforge-design-specification.md docs/thoughtforge-build-spec.md docs/thoughtforge-execution-plan.md docs/review-results-r5.md docs/apply-prompt-r5.md
git commit -m "Apply review rounds 4+5: 24 major, 7 minor findings across all three plan documents"
git push
```
