# ThoughtForge Plan Review — Round 6

**Reviewer posture:** Senior dev who will eventually build from this plan.
**Documents reviewed:** Design Specification, Build Spec, Execution Plan (with Requirements Brief as context).
**Prior reviews:** Rounds 1–5 (all applied). This review treats the current document state as the baseline.

---

## 1. Writing That's Unclear

### Finding 1 — [Major] Design spec says "exit with error" on missing config, but Task 1b says "auto-copy from example" — contradictory behavior

The design spec Configuration section (line 496) states:

> "If the file is missing, the server exits with an error message specifying the expected file path."

Task 1b in the execution plan says:

> "`config.yaml.example` copied to `config.yaml` on first run if missing (with comment guidance), prerequisite check…"

These are mutually exclusive behaviors. Either the server exits on missing config, or it auto-creates one from an example file. A builder encounters a contradiction and must guess which is correct.

**Resolution:** The first-run setup behavior from Task 1b is the better UX for a solo-operator tool. The design spec's config validation section should accommodate it.

**File:** `thoughtforge-design-specification.md`, Config Validation paragraph (line 496).

**Replace:**
```
**Config Validation:** On startup, the config loader validates `config.yaml` against the expected schema. If the file is missing, the server exits with an error message specifying the expected file path. If the file contains invalid YAML syntax or values that fail schema validation (wrong types, out-of-range numbers, missing required keys), the server exits with a descriptive error identifying the invalid key and expected format. No partial loading or default fallback for malformed config — the operator must fix the file. Validation uses the same Zod-based approach as review JSON validation.
```

**With:**
```
**Config Validation:** On startup, the config loader validates `config.yaml` against the expected schema. If the file is missing and `config.yaml.example` exists, the example is copied to `config.yaml` and the server logs that a default config was created. If neither file exists, the server exits with an error message specifying the expected file path. If the file contains invalid YAML syntax or values that fail schema validation (wrong types, out-of-range numbers, missing required keys), the server exits with a descriptive error identifying the invalid key and expected format. No partial loading or default fallback for malformed config — the operator must fix the file. Validation uses the same Zod-based approach as review JSON validation.
```

---

### Finding 2 — [Major] Build spec references nonexistent "Task 19" and stale task range "Tasks 14–19"

When the Plan Completeness Gate was moved from Task 19 to Task 6d (round 5), the build spec's internal cross-references were not updated.

**File:** `thoughtforge-build-spec.md`

**Location 1** — Plan Completeness Gate Prompt section, "Used by" line (line 122):

**Replace:**
```
**Used by:** Task 19 (Plan Completeness Gate)
```

**With:**
```
**Used by:** Task 6d (Plan Completeness Gate)
```

**Location 2** — Plugin Folder Structure section, "Used by" line (line 151):

**Replace:**
```
**Used by:** Task 6 (plugin loader), Tasks 14–19 (plan plugin), Tasks 20–25 (code plugin)
```

**With:**
```
**Used by:** Task 6 (plugin loader), Tasks 14–18 (plan plugin), Tasks 20–25 (code plugin)
```

**Location 3** — Plan Mode Stuck Signal Schema section, "Used by" line (line 362):

**Replace:**
```
**Used by:** Task 15 (plan builder), Task 6c (stuck recovery)
```

This is correct. No change needed. Confirming for audit trail only.

---

### Finding 3 — [Major] Circular dependency between Task 6b and Task 6d deadlocks both tasks

Execution plan Task 6b depends on Task 6d. Task 6d depends on Task 6b. Neither can start.

The correct relationship: Task 6b implements the Phase 2→3 transition and calls the Plan Completeness Gate. Task 6d implements the gate itself. Task 6b should call Task 6d's gate function, meaning Task 6b depends on Task 6d — but Task 6d should NOT depend on Task 6b.

Task 6d's dependency on Task 6b likely came from the round 5 move (Finding 7) which said 6d depends on "Task 6b, Task 7a, Task 6e, Tasks 41–42." The dependency on 6b was incorrect — the gate doesn't need the transition logic, the transition logic needs the gate.

**File:** `thoughtforge-execution-plan.md`, Build Stage 1, Task 6d row.

**Replace:**
```
| 6d | Implement Plan Completeness Gate: assessment prompt for Code mode Phase 3 entry (loaded from `/prompts/completeness-gate.md`), halt with `plan_incomplete` on fail — human decides to override or create separate Plan project | — | Task 6b, Task 7a, Task 6e, Tasks 41–42 | — | Not Started |
```

**With:**
```
| 6d | Implement Plan Completeness Gate: assessment prompt for Code mode Phase 3 entry (loaded from `/prompts/completeness-gate.md`), halt with `plan_incomplete` on fail — human decides to override or create separate Plan project | — | Task 7a, Task 6e, Tasks 41–42 | — | Not Started |
```

---

### Finding 4 — [Major] Task 3 description omits atomic write behavior assigned to it by the design spec

Design spec line 408 says: "The project state module (Task 3) implements this as the default write behavior for all state files." But Task 3 in the execution plan says only: "Implement project state module (`status.json`, `polish_state.json` read/write)." A builder implementing Task 3 would not know to implement atomic writes.

**File:** `thoughtforge-execution-plan.md`, Build Stage 1, Task 3 row.

**Replace:**
```
| 3 | Implement project state module (`status.json`, `polish_state.json` read/write) | — | Task 1 | — | Not Started |
```

**With:**
```
| 3 | Implement project state module (`status.json`, `polish_state.json` read/write) with atomic write default (write to temp file, rename to target) for all state files | — | Task 1 | — | Not Started |
```

---

### Finding 5 — [Major] Task 41 omits shell safety requirement for prompt passing

Build spec lines 342–343 specify that prompt content must be passed via file descriptor or stdin pipe, never through shell argument expansion. Task 41 says only "prompt file → subprocess → capture stdout." A builder could use shell string concatenation.

**File:** `thoughtforge-execution-plan.md`, Build Stage 7, Task 41 row.

**Replace:**
```
| 41 | Implement agent invocation: prompt file → subprocess → capture stdout | — | Task 1 | — | Not Started |
```

**With:**
```
| 41 | Implement agent invocation: prompt file → subprocess via stdin pipe (no shell interpolation of prompt content) → capture stdout | — | Task 1 | — | Not Started |
```

---

### Finding 6 — [Minor] `project_id` derivation is never specified — notification payload requires it but `status.json` doesn't store it

The notification payload schema requires `project_id: string`. The `status.json` schema has no `project_id` field. The project directory is `/projects/{id}/`, so `project_id` is presumably the directory name, but no document states this explicitly. A builder implementing the notification layer would not know where to source `project_id`.

**File:** `thoughtforge-design-specification.md`, Phase 1 step 0 (line 59). The paragraph already mentions "generates a unique project ID" — add where it's stored.

**Replace:**
```
ThoughtForge generates a unique project ID, creates the `/projects/{id}/` directory structure
```

**With:**
```
ThoughtForge generates a unique project ID (used as the directory name and as `project_id` in notifications — not stored in `status.json` since it is always derivable from the project directory path), creates the `/projects/{id}/` directory structure
```

---

### Finding 7 — [Minor] `halt_reason` values are unspecified — design spec uses `plan_incomplete` but no values are enumerated

The design spec uses `plan_incomplete` as a specific halt reason value (line 276). Both `status.json` and `polish_state.json` type `halt_reason` as `string | null` with no enumeration. A builder implementing halt scenarios would invent their own values.

This is minor because a string field is flexible by design, but at minimum the known values from the design spec should be listed.

**File:** `thoughtforge-build-spec.md`, after the `status.json` Schema section, before the closing ```.

**Replace:**
```
  halt_reason: string | null;
}
```

**With:**
```
  halt_reason: string | null;  // Known values: "plan_incomplete", "guard_hallucination", "guard_fabrication", "guard_max_iterations", "human_terminated", "agent_failure", "file_system_error"
}
```

---

## 2. Genuinely Missing Plan-Level Content

### Finding 8 — [Major] Polish loop orchestrator (Task 30) has inverted dependencies with Task 32 and Task 38

Task 30 (polish loop orchestrator) must use count derivation (Task 32) and write polish state (Task 38). Currently Task 32 and Task 38 both depend on Task 30, but Task 30 does not depend on either. This means the orchestrator is built before the components it needs.

The correct relationship: count derivation and state persistence are utilities the orchestrator calls. They should either be subtasks of Task 30, or Task 30 should depend on them, or their scope should be absorbed into Task 30's description.

Since Task 32 and Task 38 are simple enough to be part of the orchestrator implementation, the cleanest fix is to fold them into Task 30 explicitly.

**File:** `thoughtforge-execution-plan.md`, Build Stage 6, Task 30 row.

**Replace:**
```
| 30 | Implement orchestrator loop: review call → parse → validate → fix call → commit | — | Task 3, Task 6a, Task 6c, Task 17, Task 22, Tasks 30a–30b, Tasks 41–42 | — | Not Started |
```

**With:**
```
| 30 | Implement orchestrator loop: review call → parse → validate → fix call → commit. Includes count derivation from issues array (Task 32), polish state persistence + crash recovery (Task 38), and polish log append (Task 39) as integral orchestrator responsibilities — these tasks extend Task 30, not replace it | — | Task 3, Task 6a, Task 6c, Task 17, Task 22, Tasks 30a–30b, Tasks 41–42 | — | Not Started |
```

Also update Tasks 32, 38, and 39 to clarify they extend Task 30:

**Replace Task 32:**
```
| 32 | Implement count derivation from issues array (ignore top-level counts) | — | Task 30 | — | Not Started |
```

**With:**
```
| 32 | Implement count derivation from issues array (ignore top-level counts) — extends Task 30 orchestrator | — | Task 30 | — | Not Started |
```

**Replace Task 38:**
```
| 38 | Implement `polish_state.json` persistence + crash recovery (resume from last iteration) | — | Task 30 | — | Not Started |
```

**With:**
```
| 38 | Implement `polish_state.json` persistence + crash recovery (resume from last iteration) — extends Task 30 orchestrator | — | Task 30 | — | Not Started |
```

**Replace Task 39:**
```
| 39 | Implement `polish_log.md` append after each iteration | — | Task 30 | — | Not Started |
```

**With:**
```
| 39 | Implement `polish_log.md` append after each iteration — extends Task 30 orchestrator | — | Task 30 | — | Not Started |
```

---

### Finding 9 — [Major] Guard evaluation order has no execution plan task

Build spec lines 263–273 define a specific guard evaluation order with the rule "the first guard that triggers ends evaluation." Tasks 33–37 each implement individual guards, and Task 30 depends on them, but no task specifies implementing the ordered evaluation loop itself. A builder could evaluate guards in arbitrary order.

**File:** `thoughtforge-execution-plan.md`, Build Stage 6, Task 30 description.

The Task 30 replacement in Finding 8 already restructures this. Add guard evaluation ordering to the description.

**Replace** (the Finding 8 replacement text):
```
| 30 | Implement orchestrator loop: review call → parse → validate → fix call → commit. Includes count derivation from issues array (Task 32), polish state persistence + crash recovery (Task 38), and polish log append (Task 39) as integral orchestrator responsibilities — these tasks extend Task 30, not replace it | — | Task 3, Task 6a, Task 6c, Task 17, Task 22, Tasks 30a–30b, Tasks 41–42 | — | Not Started |
```

**With:**
```
| 30 | Implement orchestrator loop: review call → parse → validate → fix call → commit. Guard evaluation in specified order (Termination → Hallucination → Fabrication → Stagnation → Max iterations; first trigger ends evaluation). Includes count derivation from issues array (Task 32), polish state persistence + crash recovery (Task 38), and polish log append (Task 39) as integral orchestrator responsibilities — these tasks extend Task 30, not replace it | — | Task 3, Task 6a, Task 6c, Task 17, Task 22, Tasks 30a–30b, Tasks 41–42 | — | Not Started |
```

---

### Finding 10 — [Major] Task 8 dependency on Task 7c (connector abstraction) blocks Phase 1 when connectors are optional

Task 8 depends on Task 7c (resource connector abstraction layer). But connectors are explicitly optional — design spec line 65: "Connectors are optional — if none are configured, this step is skipped." Making Phase 1 brain dump intake blocked on the optional connector layer creates an unnecessary bottleneck.

The connector abstraction layer should be an optional integration, not a hard dependency of the core intake flow.

**File:** `thoughtforge-execution-plan.md`, Build Stage 2, Task 8 row.

**Replace:**
```
| 8 | Implement Phase 1: brain dump intake (including empty/trivially-short input guard — block distillation and prompt for more detail), resource reading (log and skip unreadable files, notify human, proceed with available inputs), distillation prompt (loaded from `/prompts/brain-dump-intake.md`), Phase 1 sub-state transitions in `status.json` (`brain_dump` → `distilling` on Distill button → `human_review` on distillation complete) | — | Task 6a, Task 7, Task 7a, Task 7c, Tasks 41–42 | — | Not Started |
```

**With:**
```
| 8 | Implement Phase 1: brain dump intake (including empty/trivially-short input guard — block distillation and prompt for more detail), resource reading (log and skip unreadable files, notify human, proceed with available inputs), distillation prompt (loaded from `/prompts/brain-dump-intake.md`), Phase 1 sub-state transitions in `status.json` (`brain_dump` → `distilling` on Distill button → `human_review` on distillation complete). Connector integration (Task 7c) is optional — Phase 1 functions fully without connectors. | — | Task 6a, Task 7, Task 7a, Tasks 41–42 | — | Not Started |
```

---

### Finding 11 — [Major] Task 11 (intent.md generation) missing dependency on agent layer for AI-generated project names

Design spec line 59 says: "the AI generates a short descriptive name (2–4 words) from the brain dump content." Task 11 implements this but has no dependency on Tasks 41–42 (agent layer). The AI name generation requires an agent call.

**File:** `thoughtforge-execution-plan.md`, Build Stage 2, Task 11 row.

**Replace:**
```
| 11 | Implement intent.md generation and locking, project name derivation (extract from H1 or AI-generate), status.json project_name update, and Vibe Kanban card name update (if enabled) | — | Task 9, Task 2a, Task 26 | — | Not Started |
```

**With:**
```
| 11 | Implement intent.md generation and locking, project name derivation (extract from H1 or AI-generate), status.json project_name update, and Vibe Kanban card name update (if enabled) | — | Task 9, Task 2a, Task 26, Tasks 41–42 | — | Not Started |
```

---

### Finding 12 — [Major] Task 5 (phase transition notifications) missing dependency on Task 3 (project state module)

Phase transition notifications require reading `status.json` to get project_name, phase, deliverable_type. Task 5 depends only on Task 4 (notification abstraction layer), not Task 3 (project state module).

**File:** `thoughtforge-execution-plan.md`, Build Stage 1, Task 5 row.

**Replace:**
```
| 5 | Implement phase transition notifications (ping human on every milestone) | — | Task 4 | — | Not Started |
```

**With:**
```
| 5 | Implement phase transition notifications (ping human on every milestone) | — | Task 3, Task 4 | — | Not Started |
```

---

### Finding 13 — [Minor] Completion Checklist missing first-run setup verification

The Completion Checklist at the bottom of the execution plan covers e2e tests, guards, crash recovery, parallel execution, notifications, plugins, unit tests, config, prompts, and chat. It does not include first-run setup verification, despite Task 1b and its test (Task 50b) being in scope.

**File:** `thoughtforge-execution-plan.md`, Completion Checklist (line 218).

**Add after the `config.yaml` checklist item (line 217):**
```
- [ ] First-run setup works: `config.yaml.example` copied, prerequisites checked, startup validates
```

---

### Finding 14 — [Minor] No chat interface or button-related test coverage in Completion Checklist

The Completion Checklist has no items covering the chat interface, action buttons (Distill/Confirm), file drop, or project switching — despite Build Stage 8 having Tasks 58a–58e for these.

**File:** `thoughtforge-execution-plan.md`, Completion Checklist, after the Retrospective item (line 220).

**Add:**
```
- [ ] Chat interface tests pass (WebSocket, streaming, buttons, file drop, project switching)
```

---

## 3. Build Spec Material That Should Be Extracted

No build-spec material found in the plan documents that doesn't belong. The documents remain clean of implementation detail.

---

## Summary

| Severity | Count |
|----------|-------|
| Critical | 0 |
| Major | 12 |
| Minor | 4 |

---

## Consolidated AI Coder Prompt

The following prompt applies all changes from this review to the source files.

---

### PROMPT START

You are applying review round 6 findings to the ThoughtForge plan documents. Apply every change below exactly as written. Each change specifies the file, the exact text to find, and the exact replacement. Apply them in order.

---

#### Change 1 — Design Spec: Fix missing-config behavior to accommodate first-run setup (Finding 1)

**File:** `docs/thoughtforge-design-specification.md`

**Find:**
```
**Config Validation:** On startup, the config loader validates `config.yaml` against the expected schema. If the file is missing, the server exits with an error message specifying the expected file path. If the file contains invalid YAML syntax or values that fail schema validation (wrong types, out-of-range numbers, missing required keys), the server exits with a descriptive error identifying the invalid key and expected format. No partial loading or default fallback for malformed config — the operator must fix the file. Validation uses the same Zod-based approach as review JSON validation.
```

**Replace with:**
```
**Config Validation:** On startup, the config loader validates `config.yaml` against the expected schema. If the file is missing and `config.yaml.example` exists, the example is copied to `config.yaml` and the server logs that a default config was created. If neither file exists, the server exits with an error message specifying the expected file path. If the file contains invalid YAML syntax or values that fail schema validation (wrong types, out-of-range numbers, missing required keys), the server exits with a descriptive error identifying the invalid key and expected format. No partial loading or default fallback for malformed config — the operator must fix the file. Validation uses the same Zod-based approach as review JSON validation.
```

---

#### Change 2 — Build Spec: Fix stale Task 19 reference in Plan Completeness Gate Prompt (Finding 2)

**File:** `docs/thoughtforge-build-spec.md`

**Find:**
```
**Used by:** Task 19 (Plan Completeness Gate)
```

**Replace with:**
```
**Used by:** Task 6d (Plan Completeness Gate)
```

---

#### Change 3 — Build Spec: Fix stale task range in Plugin Folder Structure (Finding 2)

**File:** `docs/thoughtforge-build-spec.md`

**Find:**
```
**Used by:** Task 6 (plugin loader), Tasks 14–19 (plan plugin), Tasks 20–25 (code plugin)
```

**Replace with:**
```
**Used by:** Task 6 (plugin loader), Tasks 14–18 (plan plugin), Tasks 20–25 (code plugin)
```

---

#### Change 4 — Execution Plan: Break circular dependency between Task 6d and Task 6b (Finding 3)

**File:** `docs/thoughtforge-execution-plan.md`

**Find:**
```
| 6d | Implement Plan Completeness Gate: assessment prompt for Code mode Phase 3 entry (loaded from `/prompts/completeness-gate.md`), halt with `plan_incomplete` on fail — human decides to override or create separate Plan project | — | Task 6b, Task 7a, Task 6e, Tasks 41–42 | — | Not Started |
```

**Replace with:**
```
| 6d | Implement Plan Completeness Gate: assessment prompt for Code mode Phase 3 entry (loaded from `/prompts/completeness-gate.md`), halt with `plan_incomplete` on fail — human decides to override or create separate Plan project | — | Task 7a, Task 6e, Tasks 41–42 | — | Not Started |
```

---

#### Change 5 — Execution Plan: Add atomic write to Task 3 description (Finding 4)

**File:** `docs/thoughtforge-execution-plan.md`

**Find:**
```
| 3 | Implement project state module (`status.json`, `polish_state.json` read/write) | — | Task 1 | — | Not Started |
```

**Replace with:**
```
| 3 | Implement project state module (`status.json`, `polish_state.json` read/write) with atomic write default (write to temp file, rename to target) for all state files | — | Task 1 | — | Not Started |
```

---

#### Change 6 — Execution Plan: Add shell safety to Task 41 description (Finding 5)

**File:** `docs/thoughtforge-execution-plan.md`

**Find:**
```
| 41 | Implement agent invocation: prompt file → subprocess → capture stdout | — | Task 1 | — | Not Started |
```

**Replace with:**
```
| 41 | Implement agent invocation: prompt file → subprocess via stdin pipe (no shell interpolation of prompt content) → capture stdout | — | Task 1 | — | Not Started |
```

---

#### Change 7 — Design Spec: Clarify project_id derivation (Finding 6)

**File:** `docs/thoughtforge-design-specification.md`

**Find:**
```
ThoughtForge generates a unique project ID, creates the `/projects/{id}/` directory structure
```

**Replace with:**
```
ThoughtForge generates a unique project ID (used as the directory name and as `project_id` in notifications — not stored in `status.json` since it is always derivable from the project directory path), creates the `/projects/{id}/` directory structure
```

---

#### Change 8 — Build Spec: Add known halt_reason values to status.json schema (Finding 7)

**File:** `docs/thoughtforge-build-spec.md`

**Find:**
```
  halt_reason: string | null;
}
```

Note: This appears in the `status.json` schema section (the `ProjectStatus` interface). Target only the first occurrence — the one inside `interface ProjectStatus`.

**Replace with:**
```
  halt_reason: string | null;  // Known values: "plan_incomplete", "guard_hallucination", "guard_fabrication", "guard_max_iterations", "human_terminated", "agent_failure", "file_system_error"
}
```

---

#### Change 9 — Execution Plan: Restructure Task 30 to include guard ordering, count derivation, state persistence, and log append (Findings 8 + 9)

**File:** `docs/thoughtforge-execution-plan.md`

**Find:**
```
| 30 | Implement orchestrator loop: review call → parse → validate → fix call → commit | — | Task 3, Task 6a, Task 6c, Task 17, Task 22, Tasks 30a–30b, Tasks 41–42 | — | Not Started |
```

**Replace with:**
```
| 30 | Implement orchestrator loop: review call → parse → validate → fix call → commit. Guard evaluation in specified order (Termination → Hallucination → Fabrication → Stagnation → Max iterations; first trigger ends evaluation). Includes count derivation from issues array (Task 32), polish state persistence + crash recovery (Task 38), and polish log append (Task 39) as integral orchestrator responsibilities — these tasks extend Task 30, not replace it | — | Task 3, Task 6a, Task 6c, Task 17, Task 22, Tasks 30a–30b, Tasks 41–42 | — | Not Started |
```

---

#### Change 10 — Execution Plan: Mark Task 32 as extending Task 30 (Finding 8)

**File:** `docs/thoughtforge-execution-plan.md`

**Find:**
```
| 32 | Implement count derivation from issues array (ignore top-level counts) | — | Task 30 | — | Not Started |
```

**Replace with:**
```
| 32 | Implement count derivation from issues array (ignore top-level counts) — extends Task 30 orchestrator | — | Task 30 | — | Not Started |
```

---

#### Change 11 — Execution Plan: Mark Task 38 as extending Task 30 (Finding 8)

**File:** `docs/thoughtforge-execution-plan.md`

**Find:**
```
| 38 | Implement `polish_state.json` persistence + crash recovery (resume from last iteration) | — | Task 30 | — | Not Started |
```

**Replace with:**
```
| 38 | Implement `polish_state.json` persistence + crash recovery (resume from last iteration) — extends Task 30 orchestrator | — | Task 30 | — | Not Started |
```

---

#### Change 12 — Execution Plan: Mark Task 39 as extending Task 30 (Finding 8)

**File:** `docs/thoughtforge-execution-plan.md`

**Find:**
```
| 39 | Implement `polish_log.md` append after each iteration | — | Task 30 | — | Not Started |
```

**Replace with:**
```
| 39 | Implement `polish_log.md` append after each iteration — extends Task 30 orchestrator | — | Task 30 | — | Not Started |
```

---

#### Change 13 — Execution Plan: Remove Task 7c from Task 8 dependencies (Finding 10)

**File:** `docs/thoughtforge-execution-plan.md`

**Find (after Change 5 is applied — use the updated Task 8 text):**
```
| 8 | Implement Phase 1: brain dump intake (including empty/trivially-short input guard — block distillation and prompt for more detail), resource reading (log and skip unreadable files, notify human, proceed with available inputs), distillation prompt (loaded from `/prompts/brain-dump-intake.md`), Phase 1 sub-state transitions in `status.json` (`brain_dump` → `distilling` on Distill button → `human_review` on distillation complete) | — | Task 6a, Task 7, Task 7a, Task 7c, Tasks 41–42 | — | Not Started |
```

**Replace with:**
```
| 8 | Implement Phase 1: brain dump intake (including empty/trivially-short input guard — block distillation and prompt for more detail), resource reading (log and skip unreadable files, notify human, proceed with available inputs), distillation prompt (loaded from `/prompts/brain-dump-intake.md`), Phase 1 sub-state transitions in `status.json` (`brain_dump` → `distilling` on Distill button → `human_review` on distillation complete). Connector integration (Task 7c) is optional — Phase 1 functions fully without connectors. | — | Task 6a, Task 7, Task 7a, Tasks 41–42 | — | Not Started |
```

---

#### Change 14 — Execution Plan: Add Tasks 41–42 dependency to Task 11 (Finding 11)

**File:** `docs/thoughtforge-execution-plan.md`

**Find:**
```
| 11 | Implement intent.md generation and locking, project name derivation (extract from H1 or AI-generate), status.json project_name update, and Vibe Kanban card name update (if enabled) | — | Task 9, Task 2a, Task 26 | — | Not Started |
```

**Replace with:**
```
| 11 | Implement intent.md generation and locking, project name derivation (extract from H1 or AI-generate), status.json project_name update, and Vibe Kanban card name update (if enabled) | — | Task 9, Task 2a, Task 26, Tasks 41–42 | — | Not Started |
```

---

#### Change 15 — Execution Plan: Add Task 3 dependency to Task 5 (Finding 12)

**File:** `docs/thoughtforge-execution-plan.md`

**Find:**
```
| 5 | Implement phase transition notifications (ping human on every milestone) | — | Task 4 | — | Not Started |
```

**Replace with:**
```
| 5 | Implement phase transition notifications (ping human on every milestone) | — | Task 3, Task 4 | — | Not Started |
```

---

#### Change 16 — Execution Plan: Add first-run setup to Completion Checklist (Finding 13)

**File:** `docs/thoughtforge-execution-plan.md`

**Find:**
```
- [ ] `config.yaml` controls all configurable values
```

**Replace with:**
```
- [ ] `config.yaml` controls all configurable values
- [ ] First-run setup works: `config.yaml.example` copied, prerequisites checked, startup validates
```

---

#### Change 17 — Execution Plan: Add chat interface tests to Completion Checklist (Finding 14)

**File:** `docs/thoughtforge-execution-plan.md`

**Find:**
```
- [ ] Retrospective / lessons learned captured
```

**Replace with:**
```
- [ ] Retrospective / lessons learned captured
- [ ] Chat interface tests pass (WebSocket, streaming, buttons, file drop, project switching)
```

---

#### Final Step — Git Commit and Sync

After all 17 changes are applied:

```
git add docs/thoughtforge-design-specification.md docs/thoughtforge-build-spec.md docs/thoughtforge-execution-plan.md docs/review-results-r6.md
git commit -m "Apply review round 6: 12 major, 4 minor findings across all three plan documents"
git push
```

### PROMPT END
