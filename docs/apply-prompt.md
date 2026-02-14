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
