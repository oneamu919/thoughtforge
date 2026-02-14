# Consolidated Apply Prompt — Round 4 Review

Apply all 11 changes below to the ThoughtForge plan documents. Each change specifies the exact file, location, old text, and new text. No interpretation required. Apply them in order.

---

## Change 1 — Build Spec: VK CLI table "Execute agent work" row (Major)

**File:** `docs/thoughtforge-build-spec.md`
**Section:** Vibe Kanban CLI Interface table, "Execute agent work" row

**Find:**
```
| Execute agent work | `vibekanban task run {task_id} --prompt-file {path}` | Phase 3 build, Phase 4 fix steps |
```

**Replace with:**
```
| Execute agent work | `vibekanban task run {task_id} --prompt-file {path}` | Code mode only: Phase 3 build, Phase 4 fix steps. Plan mode invokes agents directly via agent layer — VK is visualization only. |
```

---

## Change 2 — Build Spec: VK CLI table "Read task result" row (Major)

**File:** `docs/thoughtforge-build-spec.md`
**Section:** Vibe Kanban CLI Interface table, "Read task result" row

**Find:**
```
| Read task result | `vibekanban task result {task_id}` | After each agent execution |
```

**Replace with:**
```
| Read task result | `vibekanban task result {task_id}` | After each Code mode agent execution via VK |
```

---

## Change 3 — Design Spec: deliverable_type transition timing (Major)

**File:** `docs/thoughtforge-design-specification.md`
**Section:** Phase 1, step 11

**Find:**
```
11. Output: `intent.md` written to `/docs/` and locked — no further modification by AI in subsequent phases. Human may still edit manually outside the pipeline.
```

**Replace with:**
```
11. Output: `intent.md` written to `/docs/` and locked — no further modification by AI in subsequent phases. Human may still edit manually outside the pipeline. The `deliverable_type` field in `status.json` is set to `"plan"` or `"code"` at this point, derived from the Deliverable Type section of the confirmed `intent.md`.
```

---

## Change 4 — Build Spec: ChatMessage.phase comment (Minor)

**File:** `docs/thoughtforge-build-spec.md`
**Section:** `chat_history.json` Schema, `ChatMessage` interface

**Find:**
```
  phase: "brain_dump" | "distilling" | "human_review" | "spec_building" | "building" | "polishing" | "halted";
```

**Replace with:**
```
  phase: "brain_dump" | "distilling" | "human_review" | "spec_building" | "building" | "polishing" | "halted";  // "done" excluded — no chat occurs after completion
```

---

## Change 5 — Build Spec: Guard evaluation order (Major)

**File:** `docs/thoughtforge-build-spec.md`
**Section:** Convergence Guard Parameters, after the "Used by" line (`**Used by:** Tasks 33–37 (convergence guards)`) and before the `### Hallucination Guard` heading

**Insert the following block:**

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

## Change 6 — Execution Plan: Task 6a add safety-rules and filesystem error handling (Major × 2)

**File:** `docs/thoughtforge-execution-plan.md`
**Section:** Build Stage 1, Task 6a row

**Find:**
```
| 6a | Implement pipeline orchestrator: phase sequencing based on `status.json`, plugin selection by `deliverable_type` | — | Task 2, Task 3, Task 6 | — | Not Started |
```

**Replace with:**
```
| 6a | Implement pipeline orchestrator: phase sequencing based on `status.json`, plugin selection by `deliverable_type`, safety-rules enforcement (call plugin `validate(operation)` before every Phase 3/4 action), cross-cutting file system error handling (halt and notify on write failures — no retry) | — | Task 2, Task 3, Task 6 | — | Not Started |
```

---

## Change 7 — Execution Plan: Task 21 add VK-disabled dependency and description (Major)

**File:** `docs/thoughtforge-execution-plan.md`
**Section:** Build Stage 4, Task 21 row

**Find:**
```
| 21 | Implement `builder.js` — agent-driven coding via Vibe Kanban | — | Task 6a, Task 20, Task 21a, Task 27, Tasks 41–42 | — | Not Started |
```

**Replace with:**
```
| 21 | Implement `builder.js` — agent-driven coding (via Vibe Kanban when enabled, direct agent invocation when disabled) | — | Task 6a, Task 20, Task 21a, Task 27, Task 29a, Tasks 41–42 | — | Not Started |
```

---

## Change 8 — Execution Plan: Task 29a add agent layer dependency (Major)

**File:** `docs/thoughtforge-execution-plan.md`
**Section:** Build Stage 5, Task 29a row

**Find:**
```
| 29a | Implement VK-disabled fallback: direct agent invocation path when `vibekanban.enabled` is false | — | Task 26 | — | Not Started |
```

**Replace with:**
```
| 29a | Implement VK-disabled fallback: direct agent invocation path when `vibekanban.enabled` is false | — | Task 26, Tasks 41–42 | — | Not Started |
```

---

## Change 9 — Execution Plan: Task 8 add input validation and error handling (Major)

**File:** `docs/thoughtforge-execution-plan.md`
**Section:** Build Stage 2, Task 8 row

**Find:**
```
| 8 | Implement Phase 1: brain dump intake, resource reading, distillation prompt (loaded from `/prompts/brain-dump-intake.md`) | — | Task 6a, Task 7, Task 7a, Task 7c, Tasks 41–42 | — | Not Started |
```

**Replace with:**
```
| 8 | Implement Phase 1: brain dump intake (including empty/trivially-short input guard — block distillation and prompt for more detail), resource reading (log and skip unreadable files, notify human, proceed with available inputs), distillation prompt (loaded from `/prompts/brain-dump-intake.md`) | — | Task 6a, Task 7, Task 7a, Task 7c, Tasks 41–42 | — | Not Started |
```

---

## Change 10 — Execution Plan: Task 15 add template failure handling (Major)

**File:** `docs/thoughtforge-execution-plan.md`
**Section:** Build Stage 3, Task 15 row

**Find:**
```
| 15 | Implement `builder.js` — Handlebars template-driven document drafting | — | Task 6a, Task 14, Task 15a, Tasks 41–42 | — | Not Started |
```

**Replace with:**
```
| 15 | Implement `builder.js` — Handlebars template-driven document drafting, including template rendering failure handling (halt immediately, no retry) | — | Task 6a, Task 14, Task 15a, Tasks 41–42 | — | Not Started |
```

---

## Change 11 — Execution Plan: Task 9a clarify which transitions clear chat history (Minor)

**File:** `docs/thoughtforge-execution-plan.md`
**Section:** Build Stage 2, Task 9a row

**Find:**
```
| 9a | Implement `chat_history.json` persistence: append after each chat message, clear on phase advancement confirmation, resume from last recorded message on crash | — | Task 3, Task 7 | — | Not Started |
```

**Replace with:**
```
| 9a | Implement `chat_history.json` persistence: append after each chat message, clear on Phase 1→2 and Phase 2→3 confirmation only (NOT on Phase 3→4 automatic transition), resume from last recorded message on crash | — | Task 3, Task 7 | — | Not Started |
```

---

## Change 12 — Execution Plan: Task 30c distinguish runner crashes from assertion failures (Minor)

**File:** `docs/thoughtforge-execution-plan.md`
**Section:** Build Stage 6, Task 30c row

**Find:**
```
| 30c | Implement Code mode iteration cycle: test execution via `test-runner.js` before review, test results passed as reviewer context | — | Task 24, Task 30 | — | Not Started |
```

**Replace with:**
```
| 30c | Implement Code mode iteration cycle: test execution via `test-runner.js` before review, test results passed as reviewer context. Distinguish test runner crashes (process error — retry once, halt on second) from test assertion failures (pass to reviewer as context). | — | Task 24, Task 30 | — | Not Started |
```

---

## After All Changes

1. Verify each change was applied correctly by reading the modified sections.
2. Git commit all three modified files with message: `Apply review findings round 4: 0 critical, 8 major, 3 minor across design spec, build spec, and execution plan`
3. Git push to remote.
