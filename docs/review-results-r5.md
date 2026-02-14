# ThoughtForge Plan Review — Round 5

**Reviewer posture:** Senior dev who will eventually build from this plan.
**Documents reviewed:** Design Specification, Build Spec, Execution Plan (with Requirements Brief as context).
**Prior reviews:** Rounds 1–3 (applied). Round 4 (11 findings, NOT yet applied — this round treats those findings as still outstanding and does not re-list them).

**NOTE:** Round 4 findings remain valid and must be applied alongside this round. This review covers only NEW findings.

---

## 1. Writing That's Unclear

### Finding 1 — [Major] Phase 4 git commit granularity is ambiguous — one commit or two per iteration?

The design spec states two things about Phase 4 commits:

- Line 226–227: "Git commit snapshot after each step." (Context: referring to Step 1 Review and Step 2 Fix as separate steps)
- Line 329: "after every Phase 4 review and fix step"

Task 40 in the execution plan says: "Implement git auto-commit after each review and fix step."

These can be read as either: (a) two commits per iteration — one after review, one after fix — or (b) one commit per combined review-and-fix iteration. The Phase 4 error handling table supports reading (a): "File system error during git commit after fix" specifically calls out the fix commit, implying the fix step has its own commit. But the review step's commit is never mentioned in error handling.

This matters for rollback granularity. With two commits per iteration, you can revert a bad fix while preserving the review JSON that identified the issues. With one commit, you lose both.

**File:** `thoughtforge-design-specification.md`, Git Commit Strategy paragraph (line 329).

**Replace:**
```
Commits occur at: `intent.md` lock (end of Phase 1), `spec.md` and `constraints.md` lock (end of Phase 2), Phase 3 build completion, and after every Phase 4 review and fix step.
```

**With:**
```
Commits occur at: `intent.md` lock (end of Phase 1), `spec.md` and `constraints.md` lock (end of Phase 2), Phase 3 build completion, and twice per Phase 4 iteration — once after the review step (captures the review JSON) and once after the fix step (captures applied fixes). Two commits per iteration enables rollback of a bad fix while preserving the review that identified the issues.
```

---

### Finding 2 — [Major] Task 12 (Phase 2) does not mention mode-branching behavior described in the design spec

The design spec describes two distinct Phase 2 behaviors by mode:

- **Plan Mode** (line 130): "Proposes plan structure following OPA Framework — every major section gets its own OPA table."
- **Code Mode** (line 132): "Proposes build spec (language, OS, framework, tools, dependencies, architecture). Runs Open Source Discovery before proposing custom-built components."

Task 12 says: "spec building, constraint discovery, acceptance criteria extraction, human review/override of proposed decisions, human review of acceptance criteria, Unknown/Open Question resolution validation gate…" It makes no mention of mode-specific behavior. A builder implementing Task 12 would not know that Plan mode Phase 2 must propose OPA-structured sections specifically, nor that Code mode Phase 2 integrates OSS discovery.

**File:** `thoughtforge-execution-plan.md`, Build Stage 2, Task 12 row.

**Replace:**
```
| 12 | Implement Phase 2: spec building, constraint discovery, acceptance criteria extraction, human review/override of proposed decisions, human review of acceptance criteria, Unknown/Open Question resolution validation gate (block Confirm if unresolved items remain), Confirm to advance | — | Task 6a, Task 10, Task 11, Task 7a, Task 7f, Task 25, Tasks 41–42 | — | Not Started |
```

**With:**
```
| 12 | Implement Phase 2: spec building with mode-specific behavior (Plan mode: propose OPA-structured plan sections; Code mode: propose architecture/language/framework/tools with OSS discovery integration from Task 25), AI challenge of weak or risky decisions in `intent.md` (does not rubber-stamp), constraint discovery, acceptance criteria extraction (5–10 per design spec), human review/override of proposed decisions, human review of acceptance criteria, Unknown/Open Question resolution validation gate (block Confirm if unresolved items remain), Confirm to advance | — | Task 6a, Task 10, Task 11, Task 7a, Task 7f, Task 25, Tasks 41–42 | — | Not Started |
```

---

### Finding 3 — [Minor] `/prompts/` path prefix inconsistency between design spec and build spec config

The design spec Configuration table (line 487) lists prompt directory as `/prompts/` with a leading slash. The build spec config.yaml template (line 565) uses `directory: "./prompts"` — a relative path. The build spec's Prompt File Directory section (line 15) also uses `/prompts/`. A builder could question whether prompts are at an absolute path or relative to the project root.

**File:** `thoughtforge-design-specification.md`, Configuration table, Prompts row (line 487).

**Replace:**
```
| Prompts | Prompt directory path, individual prompt files | `/prompts/`, one `.md` file per prompt |
```

**With:**
```
| Prompts | Prompt directory path, individual prompt files | `./prompts/`, one `.md` file per prompt |
```

**Also** in `thoughtforge-build-spec.md`, Prompt File Directory section (line 15):

**Replace:**
```
All pipeline prompts are stored as external `.md` files in `/prompts/`.
```

**With:**
```
All pipeline prompts are stored as external `.md` files in `./prompts/` (relative to project root).
```

---

## 2. Genuinely Missing Plan-Level Content

### Finding 4 — [Major] No execution plan task covers Phase 1 sub-state transitions (`brain_dump` → `distilling` → `human_review`)

The design spec Phase-to-State Mapping table (lines 89–93) defines three `status.json` phase values within Phase 1:
- `brain_dump`: human providing inputs
- `distilling`: triggered by Distill button, AI processing
- `human_review`: human correcting distillation

These values are not cosmetic — Vibe Kanban columns map directly to them (line 422: "Brain Dump → Distilling → Human Review → Spec Building → Building → Polishing → Done"). No task in the execution plan mentions implementing these sub-phase state transitions. Task 8 covers intake and distillation. Task 9 covers corrections. Task 10 covers buttons. None mention writing `distilling` or `human_review` to `status.json`.

**File:** `thoughtforge-execution-plan.md`, Build Stage 2, Task 8 row.

Current Task 8 (after R4 Finding 7 is applied):
```
| 8 | Implement Phase 1: brain dump intake (including empty/trivially-short input guard — block distillation and prompt for more detail), resource reading (log and skip unreadable files, notify human, proceed with available inputs), distillation prompt (loaded from `/prompts/brain-dump-intake.md`) | — | Task 6a, Task 7, Task 7a, Task 7c, Tasks 41–42 | — | Not Started |
```

**Replace with (adds sub-state transitions to R4's updated text):**
```
| 8 | Implement Phase 1: brain dump intake (including empty/trivially-short input guard — block distillation and prompt for more detail), resource reading (log and skip unreadable files, notify human, proceed with available inputs), distillation prompt (loaded from `/prompts/brain-dump-intake.md`), Phase 1 sub-state transitions in `status.json` (`brain_dump` → `distilling` on Distill button → `human_review` on distillation complete) | — | Task 6a, Task 7, Task 7a, Task 7c, Tasks 41–42 | — | Not Started |
```

---

### Finding 5 — [Major] `spec.md` and `constraints.md` structures have no build spec reference

The design spec defines the structure of `spec.md` (6 sections, lines 134–145) and `constraints.md` (7 sections, lines 147–157). The build spec provides TypeScript interface schemas for `status.json`, `polish_state.json`, `chat_history.json`, and review JSON — but has nothing for these two Markdown outputs. A builder implementing Task 13 would need to go back to the design spec to find the section structure, defeating the build spec's purpose as the implementation reference.

**File:** `thoughtforge-build-spec.md`, after the `chat_history.json` Schema section (after line 456).

**Add:**
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
```

---

### Finding 6 — [Major] Notification payload schema missing from build spec

The design spec defines a 5-field notification schema (lines 382–403): `project_id`, `project_name`, `phase`, `event_type`, `summary` with specific `event_type` enum values. Every other structured data format in the system has a build spec schema. Notifications do not. A builder implementing Tasks 4–5 would need to derive the schema from design spec examples.

**File:** `thoughtforge-build-spec.md`, after the `polish_log.md` Entry Format section (after line 497).

**Add:**
```markdown
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

---

### Finding 7 — [Major] Plan Completeness Gate (Task 19) is in the wrong build stage — it's a Code mode concern placed in the Plan Mode Plugin stage

Task 19 lives in Build Stage 3 (Plan Mode Plugin) and depends on Task 14 (plan plugin folder structure). But the Plan Completeness Gate is exclusively a Code mode concern — it evaluates whether a plan is ready for Code mode building. It triggers at Code mode Phase 3 entry (Task 6b). The gate's prompt lives at `/prompts/completeness-gate.md`, not in the plan plugin. The build spec's plugin folder structure does not list it in either plugin directory.

**File:** `thoughtforge-execution-plan.md`, move Task 19 and 19a from Build Stage 3 to a more appropriate location. Since the gate is orchestrator-level logic triggered at Phase 3 entry, it belongs with Task 6b (which already depends on it).

**Replace Build Stage 3 tasks 19 and 19a:**

Remove these rows from Build Stage 3:
```
| 19 | Implement Plan Completeness Gate (assessment prompt for Code mode entry, halt with `plan_incomplete` on fail — human decides to override or create separate Plan project) | — | Task 14, Task 7a, Task 19a, Tasks 41–42 | — | Not Started |
| 19a | Draft `/prompts/completeness-gate.md` prompt text | — | Task 7a | — | Not Started |
```

**Add to Build Stage 1 (after Task 6c):**
```
| 6d | Implement Plan Completeness Gate: assessment prompt for Code mode Phase 3 entry (loaded from `/prompts/completeness-gate.md`), halt with `plan_incomplete` on fail — human decides to override or create separate Plan project | — | Task 6b, Task 7a, Task 6e, Tasks 41–42 | — | Not Started |
| 6e | Draft `/prompts/completeness-gate.md` prompt text | — | Task 7a | — | Not Started |
```

**Also update Task 6b dependency:**

**Replace:**
```
| 6b | Implement Phase 2→3 transition: Plan Completeness Gate trigger for Code mode, advancement logic | — | Task 6a, Task 19 | — | Not Started |
```

**With:**
```
| 6b | Implement Phase 2→3 transition: Plan Completeness Gate trigger for Code mode, advancement logic | — | Task 6a, Task 6d | — | Not Started |
```

---

### Finding 8 — [Major] No task covers operational logging integration — module is created but never wired

Task 3a creates the operational logging module. The build spec defines log events including `phase_transition`, `agent_call`, `agent_response`, `guard_evaluation`, `halt`, `error`, `config_loaded`, `plugin_loaded`. Each event is produced by a different task (Task 41 for agent calls, Task 6a for phase transitions, Tasks 33–37 for guard evaluations, Task 1 for config loading, Task 6 for plugin loading). None of these tasks mention calling the logger.

This is the same systemic pattern as R4 Finding 5 (safety-rules created but never wired into the orchestrator).

**File:** `thoughtforge-execution-plan.md`, Build Stage 1, Task 3a row.

**Replace:**
```
| 3a | Implement operational logging module (per-project `thoughtforge.log`, structured entries for agent calls, phase transitions, errors) | — | Task 1 | — | Not Started |
```

**With:**
```
| 3a | Implement operational logging module (per-project `thoughtforge.log`, structured entries for agent calls, phase transitions, guard evaluations, halts, errors, config/plugin loading). All tasks that produce loggable events (Tasks 1, 6, 6a, 33–37, 41) must call this module — logging integration is the responsibility of each event-producing task, not a separate wiring task. | — | Task 1 | — | Not Started |
```

---

### Finding 9 — [Major] No plan-level requirement for atomic writes on state files

Three JSON files are written repeatedly during pipeline execution: `status.json` (every phase transition), `polish_state.json` (every Phase 4 iteration), and `chat_history.json` (every chat message). None of the plan documents mention atomic writes. If the process crashes mid-write (power failure, OOM kill, disk full), any of these files could be left truncated or empty.

This is a plan-level concern because the design chose file-based state management and crash recovery as explicit features. `polish_state.json` specifically exists for crash recovery, but a partial write to that file defeats the recovery mechanism it supports. Standard mitigation: write-to-temp-then-rename (atomic on most filesystems).

**File:** `thoughtforge-design-specification.md`, Project State Files table section (before line 406).

**Add before the table:**
```
**Write Atomicity:** All state file writes (`status.json`, `polish_state.json`, `chat_history.json`) use atomic write — write to a temporary file in the same directory, then rename to the target path. This prevents partial writes from corrupting state on crash. The project state module (Task 3) implements this as the default write behavior for all state files.
```

---

### Finding 10 — [Major] No recovery path for corrupted or missing `status.json`

Every phase transition, recovery mechanism, and the orchestrator itself depends on reading `status.json`. The plan documents recovery for `polish_state.json` (resume from last iteration), agent failures (retry then halt), and chat history (resume from last message). But there is no behavior for when `status.json` is corrupted (invalid JSON), missing (accidental deletion), or contains an invalid phase value.

**File:** `thoughtforge-design-specification.md`, Phase 1 Error Handling table (after line 87).

**Add a row to the Phase 1 Error Handling table:**
```
| `status.json` unreadable, missing, or invalid (applies to all phases) | Halt the project and notify the operator with the file path and the specific error (parse failure, missing file, invalid phase value). Do not attempt recovery or partial loading — the operator must fix or recreate the file. |
```

---

### Finding 11 — [Major] File upload path traversal protection not specified

The chat interface accepts file drops into `/projects/{id}/resources/` (Task 7h). No validation of uploaded filenames is specified. A file named `../../config.yaml` or `../docs/intent.md` could overwrite critical pipeline files. This is not adversarial attack — it's the most common file upload vulnerability and can happen accidentally from certain OS/browser filename behaviors.

**File:** `thoughtforge-execution-plan.md`, Build Stage 2, Task 7h row.

**Replace:**
```
| 7h | Implement file/resource dropping in chat interface (upload to `/resources/`) | — | Task 7 | — | Not Started |
```

**With:**
```
| 7h | Implement file/resource dropping in chat interface (upload to `/resources/`). Validate that resolved file paths stay within the project's `/resources/` directory — reject uploads with path traversal components (`..`, absolute paths). | — | Task 7 | — | Not Started |
```

---

### Finding 12 — [Major] Agent subprocess prompt content must avoid shell interpolation

The build spec's agent invocation pattern (line 325) is `{command} {flags} < prompt`. The prompt file contains content derived from human brain dumps and resource files — which can contain shell metacharacters (backticks, `$()`, etc.). Neither document notes that prompt content must be passed without shell interpolation.

For a solo-operator tool, this is not a security attack vector — it's an accidental execution risk when resource files contain code snippets with shell-significant characters.

**File:** `thoughtforge-build-spec.md`, Agent Communication section, Invocation Pattern (after line 328).

**Add after step 4:**
```
**Shell safety:** Prompt content is passed to agent subprocesses via file descriptor or stdin pipe — never through shell argument expansion or interpolation. The agent invocation layer must not use shell string concatenation for prompt content. This prevents accidental command execution from shell metacharacters in brain dump text or resource files.
```

---

### Finding 13 — [Major] No first-run setup task in the execution plan

The plan documents describe what to build and how, but no task covers the operator's first-run experience. The operator needs to: install Node.js dependencies, create `config.yaml` from a template, ensure agent CLIs are on PATH, and optionally configure VK and connectors. The config loader exits with a descriptive error on missing config, but the operator would need to reverse-engineer the expected config format from the build spec.

**File:** `thoughtforge-execution-plan.md`, Build Stage 1, after Task 1a row.

**Add:**
```
| 1b | Implement first-run setup: `config.yaml.example` copied to `config.yaml` on first run if missing (with comment guidance), prerequisite check (Node.js version, agent CLIs on PATH), startup validation summary | — | Task 1 | — | Not Started |
```

**Also add to Build Stage 8:**
```
| 50b | Unit tests: first-run setup (missing config creates from example, prerequisite check reports missing CLIs, valid config passes startup) | — | Task 1b | — | Not Started |
```

---

### Finding 14 — [Minor] Web server bind address not specified — Express.js defaults to 0.0.0.0

The config specifies `server.port: 3000` but no bind address. Express.js defaults to all interfaces (`0.0.0.0`), exposing the chat interface to any device on the local network. For a single-operator local tool, localhost binding is the safe default.

**File:** `thoughtforge-build-spec.md`, `config.yaml` Template, server section (line 573).

**Replace:**
```yaml
# Web server
server:
  port: 3000
```

**With:**
```yaml
# Web server
server:
  host: "127.0.0.1"  # Bind to localhost only. Change to "0.0.0.0" for network access.
  port: 3000
```

**Also** in `thoughtforge-design-specification.md`, Configuration table, Server row (line 489):

**Replace:**
```
| Server | Web chat interface port | 3000 |
```

**With:**
```
| Server | Web chat interface host and port | 127.0.0.1:3000 |
```

---

### Finding 15 — [Minor] No test task for "realign from here" command behavior

"Realign from here" (design spec Phase 1 step 9) has specific documented behavior with multiple edge cases: identify baseline message, exclude subsequent messages, re-distill, handle no-prior-corrections edge case. Task 9 implements it, but no test task in Build Stage 8 covers it. Task 58b covers Distill and Confirm buttons. Task 58a covers WebSocket delivery. Neither covers chat command parsing for "realign from here."

**File:** `thoughtforge-execution-plan.md`, Build Stage 8, after Task 58c row.

**Add:**
```
| 58d | Unit tests: "realign from here" command (identifies correct baseline message, excludes post-correction messages, re-distills with corrections, ignores command when no prior corrections exist) | — | Task 9 | — | Not Started |
```

---

### Finding 16 — [Minor] No test task for Phase 3 stuck recovery interaction

Task 6c implements Phase 3 stuck recovery (Provide Input / Terminate buttons). Build Stage 8 has tests for Phase 4 halt recovery buttons (Task 58b) but no explicit test for Phase 3 stuck recovery. The two flows are distinct: Phase 3 has two options and keeps `building` state, Phase 4 has three options and uses `halted` state.

**File:** `thoughtforge-execution-plan.md`, Build Stage 8, after Task 58d (from Finding 15).

**Add:**
```
| 58e | Unit tests: Phase 3 stuck recovery (Provide Input resumes builder with human input while staying in `building` state, Terminate sets `halted`, stuck detection triggers correctly for both Plan and Code modes) | — | Task 6c | — | Not Started |
```

---

### Finding 17 — [Major] Task 12 dependency on Task 25 (OSS discovery) blocks Plan mode Phase 2 unnecessarily

Task 12 depends on Task 25 (OSS qualification scorecard). But Task 25 is Code-mode-only — the build spec's `discovery.js` interface says "Plan plugin may omit this file." A builder implementing Plan mode Phase 2 first is blocked by a Code-mode-only dependency. The dependency should be conditional or the task should note that OSS discovery is Code-mode-only and Plan mode Phase 2 can proceed without it.

**File:** `thoughtforge-execution-plan.md`, Build Stage 2, Task 12 row.

The Task 12 replacement from Finding 2 above already includes mode-specific behavior. Add a note to the cross-stage dependency:

**Add after Build Stage 2 heading (before the table):**
```
> **Note:** Task 12 depends on Task 25 (OSS discovery) for Code mode Phase 2 only. Plan mode Phase 2 does not use OSS discovery and can be implemented and tested before Task 25 is complete.
```

---

## 3. Build Spec Material That Should Be Extracted

No build-spec material found in the plan documents that doesn't belong. The documents remain clean of implementation detail.

---

## Summary

| Severity | Count |
|----------|-------|
| Critical | 0 |
| Major | 13 |
| Minor | 4 |

Combined with round 4 (unapplied): 8 Major + 3 Minor = **total outstanding: 21 Major + 7 Minor across both rounds.**

---
