# ThoughtForge Plan Review — Round 4

**Reviewer posture:** Senior dev who will eventually build from this plan.
**Documents reviewed:** Design Specification, Build Spec, Execution Plan (with Requirements Brief as context).
**Prior reviews:** Round 1 (13 changes, commit `ca2b448`), Round 2 (9 findings, commit `039ce06`, applied in `b03eb60`), Round 3 (14 findings, applied in `1600369`).

---

## 1. Writing That's Unclear

### Finding 1 — [Major] VK CLI table implies `vibekanban task run` applies to both Plan and Code modes

The build spec's Vibe Kanban CLI Interface table (line 587) says:

```
| Execute agent work | vibekanban task run {task_id} --prompt-file {path} | Phase 3 build, Phase 4 fix steps |
```

This reads as applying to all Phase 3/4 work regardless of mode. But the design spec (lines 350–351) explicitly states that Plan mode invokes agents directly via the agent layer even when VK is enabled — VK is visualization-only for Plan mode. A builder implementing from the build spec alone would wire Plan mode through VK execution, contradicting the design spec.

**File:** `thoughtforge-build-spec.md`, Vibe Kanban CLI Interface table, "Execute agent work" row.

**Replace:**
```
| Execute agent work | `vibekanban task run {task_id} --prompt-file {path}` | Phase 3 build, Phase 4 fix steps |
```

**With:**
```
| Execute agent work | `vibekanban task run {task_id} --prompt-file {path}` | Code mode only: Phase 3 build, Phase 4 fix steps. Plan mode invokes agents directly via agent layer — VK is visualization only. |
```

**Also** in the same table, "Read task result" row:

**Replace:**
```
| Read task result | `vibekanban task result {task_id}` | After each agent execution |
```

**With:**
```
| Read task result | `vibekanban task result {task_id}` | After each Code mode agent execution via VK |
```

---

### Finding 2 — [Major] `deliverable_type` transition from `null` is never explicitly documented as a state change event

The build spec's `ProjectStatus` schema defines `deliverable_type: "plan" | "code" | null` with the comment "null until Phase 1 distillation determines type." But neither the design spec nor the build spec specifies the exact moment this field transitions. The `project_name` transition is explicitly documented ("extracted from its H1 heading and written to status.json" after `intent.md` is locked at the end of Phase 1). `deliverable_type` has no equivalent statement.

This matters because the human can correct the deliverable type during the Phase 1 correction loop. If `deliverable_type` is written to `status.json` at distillation time, a correction could leave `status.json` stale. If written at confirmation time, it's always correct but must be explicitly stated.

**File:** `thoughtforge-design-specification.md`, Phase 1, step 11 (line 73).

**Replace:**
```
11. Output: `intent.md` written to `/docs/` and locked — no further modification by AI in subsequent phases. Human may still edit manually outside the pipeline.
```

**With:**
```
11. Output: `intent.md` written to `/docs/` and locked — no further modification by AI in subsequent phases. Human may still edit manually outside the pipeline. The `deliverable_type` field in `status.json` is set to `"plan"` or `"code"` at this point, derived from the Deliverable Type section of the confirmed `intent.md`.
```

---

### Finding 3 — [Minor] `ChatMessage.phase` intentionally excludes `done` but this design decision is undocumented

The `ProjectStatus.phase` enum includes `done`. The `ChatMessage.phase` enum does not. This is correct — no chat messages occur after project completion. But a builder seeing two nearly-identical enums with one value missing may assume it's a typo and add `done` for "completeness."

**File:** `thoughtforge-build-spec.md`, `chat_history.json` Schema section, `ChatMessage` interface.

**Replace:**
```
  phase: "brain_dump" | "distilling" | "human_review" | "spec_building" | "building" | "polishing" | "halted";
```

**With:**
```
  phase: "brain_dump" | "distilling" | "human_review" | "spec_building" | "building" | "polishing" | "halted";  // "done" excluded — no chat occurs after completion
```

---

## 2. Genuinely Missing Plan-Level Content

### Finding 4 — [Major] No convergence guard evaluation order specified — ambiguous outcomes when multiple guards fire simultaneously

The build spec lists five convergence guards as independent sections with no ordering or precedence rule. At least one concrete scenario creates ambiguity: an iteration where both the termination guard (success — counts within thresholds) and a halt guard could evaluate as true simultaneously. For example, if counts spike from 0/1/2 to 0/3/5 — this is within termination thresholds but could also trigger the hallucination guard (>20% spike after a downward trend). The outcome depends entirely on which guard is checked first.

**File:** `thoughtforge-build-spec.md`, Convergence Guard Parameters section, after the "Used by" line and before the Hallucination Guard heading.

**Add:**
```
### Guard Evaluation Order

Guards are evaluated in the following order after each iteration. The first guard that triggers ends evaluation — subsequent guards are not checked.

1. **Termination** (success) — checked first so that a successful outcome is never overridden by a halt
2. **Hallucination** — checked before stagnation/fabrication because a spike after a downward trend is the strongest anomaly signal
3. **Fabrication** — checked before stagnation because fabricated issues would produce false plateau signals
4. **Stagnation** (success) — checked after halt guards to ensure the plateau is genuine
5. **Max iterations** — checked last as the backstop

If no guard triggers, the loop proceeds to the next iteration.
```

---

### Finding 5 — [Major] Task 6a (pipeline orchestrator) omits safety-rules enforcement responsibility

The design spec (line 292) says: "Orchestrator loads plugin's `safety-rules.js` which declares blocked operations. Enforced at orchestrator level, not by prompting." The build spec's plugin interface contract (line 196) defines `validate(operation)` as "called by orchestrator before every Phase 3/4 action."

But Task 6a says only "phase sequencing based on `status.json`, plugin selection by `deliverable_type`." No task in the entire execution plan is assigned the responsibility of calling `validate()` before Phase 3/4 actions. A builder would implement the safety-rules modules (Tasks 18, 23) and the orchestrator (Task 6a) independently, with neither wiring them together.

**File:** `thoughtforge-execution-plan.md`, Build Stage 1, Task 6a row.

**Replace:**
```
| 6a | Implement pipeline orchestrator: phase sequencing based on `status.json`, plugin selection by `deliverable_type` | — | Task 2, Task 3, Task 6 | — | Not Started |
```

**With:**
```
| 6a | Implement pipeline orchestrator: phase sequencing based on `status.json`, plugin selection by `deliverable_type`, safety-rules enforcement (call plugin `validate(operation)` before every Phase 3/4 action) | — | Task 2, Task 3, Task 6 | — | Not Started |
```

---

### Finding 6 — [Major] Task 21 (code builder) has no dependency on VK-disabled fallback path (Task 29a)

The design spec's VK toggle table (line 353) states: "VK disabled, Code mode: Code builder invokes agents directly via agent layer." Task 21 depends on Task 27 (VK task operations) but not Task 29a (VK-disabled fallback). The code builder must work in both VK-enabled and VK-disabled modes. Without this dependency, the VK-disabled code path has no implementation guarantee before the code builder is built.

Additionally, Task 29a depends only on Task 26 (the adapter wrapper). But the fallback's purpose is to invoke agents directly via the agent layer — so Task 29a should also depend on Tasks 41–42 (agent invocation layer).

**File:** `thoughtforge-execution-plan.md`, Build Stage 4, Task 21 row.

**Replace:**
```
| 21 | Implement `builder.js` — agent-driven coding via Vibe Kanban | — | Task 6a, Task 20, Task 21a, Task 27, Tasks 41–42 | — | Not Started |
```

**With:**
```
| 21 | Implement `builder.js` — agent-driven coding (via Vibe Kanban when enabled, direct agent invocation when disabled) | — | Task 6a, Task 20, Task 21a, Task 27, Task 29a, Tasks 41–42 | — | Not Started |
```

**Also**, Task 29a in Build Stage 5:

**Replace:**
```
| 29a | Implement VK-disabled fallback: direct agent invocation path when `vibekanban.enabled` is false | — | Task 26 | — | Not Started |
```

**With:**
```
| 29a | Implement VK-disabled fallback: direct agent invocation path when `vibekanban.enabled` is false | — | Task 26, Tasks 41–42 | — | Not Started |
```

---

### Finding 7 — [Major] Task 8 (Phase 1 intake) does not mention input validation or error handling described in design spec

The design spec's Phase 1 error handling table includes two conditions specific to Task 8's scope: (1) "Brain dump is empty or trivially short — block distillation and prompt human for more detail" and (2) "Resource file unreadable — log, notify human, proceed with available inputs." Task 8 says only "brain dump intake, resource reading, distillation prompt." A builder could implement the Distill button to always trigger distillation regardless of input quality, and could throw on unreadable resources instead of gracefully degrading.

**File:** `thoughtforge-execution-plan.md`, Build Stage 2, Task 8 row.

**Replace:**
```
| 8 | Implement Phase 1: brain dump intake, resource reading, distillation prompt (loaded from `/prompts/brain-dump-intake.md`) | — | Task 6a, Task 7, Task 7a, Task 7c, Tasks 41–42 | — | Not Started |
```

**With:**
```
| 8 | Implement Phase 1: brain dump intake (including empty/trivially-short input guard — block distillation and prompt for more detail), resource reading (log and skip unreadable files, notify human, proceed with available inputs), distillation prompt (loaded from `/prompts/brain-dump-intake.md`) | — | Task 6a, Task 7, Task 7a, Task 7c, Tasks 41–42 | — | Not Started |
```

---

### Finding 8 — [Major] Task 15 (plan builder) does not mention template rendering failure handling

The design spec's Phase 3 error handling table specifies: "Template rendering failure (Plan mode) — Halt and notify human with error details. No retry — template errors indicate a structural problem, not a transient failure." This is distinct from agent failure handling (which retries once). Task 15 says only "Handlebars template-driven document drafting." A builder could wrap template rendering in the same retry logic as agent calls.

**File:** `thoughtforge-execution-plan.md`, Build Stage 3, Task 15 row.

**Replace:**
```
| 15 | Implement `builder.js` — Handlebars template-driven document drafting | — | Task 6a, Task 14, Task 15a, Tasks 41–42 | — | Not Started |
```

**With:**
```
| 15 | Implement `builder.js` — Handlebars template-driven document drafting, including template rendering failure handling (halt immediately, no retry) | — | Task 6a, Task 14, Task 15a, Tasks 41–42 | — | Not Started |
```

---

### Finding 9 — [Major] Task 6a (pipeline orchestrator) does not mention file system error handling

The design spec's Phase 3 and Phase 4 error handling tables both include: "File system error — Halt and notify human immediately. No retry." This is a cross-cutting concern that spans Phase 3 (cannot write to project directory) and Phase 4 (git commit after fix). No task in the execution plan mentions this behavior. The orchestrator is the natural home since it sequences all phases.

**File:** `thoughtforge-execution-plan.md`, Build Stage 1, Task 6a row.

This change combines with Finding 5. The full replacement for Task 6a (incorporating both findings) is:

**Replace:**
```
| 6a | Implement pipeline orchestrator: phase sequencing based on `status.json`, plugin selection by `deliverable_type` | — | Task 2, Task 3, Task 6 | — | Not Started |
```

**With:**
```
| 6a | Implement pipeline orchestrator: phase sequencing based on `status.json`, plugin selection by `deliverable_type`, safety-rules enforcement (call plugin `validate(operation)` before every Phase 3/4 action), cross-cutting file system error handling (halt and notify on write failures — no retry) | — | Task 2, Task 3, Task 6 | — | Not Started |
```

---

### Finding 10 — [Minor] Task 9a chat history clearing rule is ambiguous about which phase transitions clear

Task 9a says "clear on phase advancement confirmation." The design spec and build spec specify that only Phase 1→2 and Phase 2→3 confirmations clear chat history — Phase 3→4 (automatic) does NOT clear. A builder reading only the execution plan would reasonably implement clearing on ALL phase advancements.

**File:** `thoughtforge-execution-plan.md`, Build Stage 2, Task 9a row.

**Replace:**
```
| 9a | Implement `chat_history.json` persistence: append after each chat message, clear on phase advancement confirmation, resume from last recorded message on crash | — | Task 3, Task 7 | — | Not Started |
```

**With:**
```
| 9a | Implement `chat_history.json` persistence: append after each chat message, clear on Phase 1→2 and Phase 2→3 confirmation only (NOT on Phase 3→4 automatic transition), resume from last recorded message on crash | — | Task 3, Task 7 | — | Not Started |
```

---

### Finding 11 — [Minor] Task 30c does not distinguish test runner crashes from test assertion failures

The design spec's Phase 4 error handling table explicitly distinguishes: "Test runner crash (process error) — retry once, halt on second failure. Distinct from test assertion failures, which are passed to the reviewer as context." Task 30c says "test execution via `test-runner.js` before review, test results passed as reviewer context" — covering only the assertion-failure path.

**File:** `thoughtforge-execution-plan.md`, Build Stage 6, Task 30c row.

**Replace:**
```
| 30c | Implement Code mode iteration cycle: test execution via `test-runner.js` before review, test results passed as reviewer context | — | Task 24, Task 30 | — | Not Started |
```

**With:**
```
| 30c | Implement Code mode iteration cycle: test execution via `test-runner.js` before review, test results passed as reviewer context. Distinguish test runner crashes (process error — retry once, halt on second) from test assertion failures (pass to reviewer as context). | — | Task 24, Task 30 | — | Not Started |
```

---

## 3. Build Spec Material That Should Be Extracted

No build-spec material found in the plan documents. The current state of the design spec and execution plan is clean of implementation detail that belongs in the build spec. No extraction needed.

---

## Summary

| Severity | Count |
|----------|-------|
| Critical | 0 |
| Major | 8 |
| Minor | 3 |

---
