# Apply Review Findings from results.md

You are an AI coder. Apply every change listed below to the source files. Each change is taken directly from the review findings in `results.md`. Do not interpret or improvise — apply the replacements, additions, and extractions exactly as specified.

Read all target files before editing. After all changes are applied, git commit and sync to remote.

---

## Target Files

- `docs/thoughtforge-design-specification.md` (referred to as "Design Spec")
- `docs/thoughtforge-build-spec.md` (referred to as "Build Spec")
- `docs/thoughtforge-execution-plan.md` (referred to as "Execution Plan")

Read all three files before making any edits.

---

## Changes to Apply

### Change 1 — Design Spec: Stagnation row in Convergence Guards table (Minor)

**Location:** Phase 4 Convergence Guards table, the Stagnation row.

**Action:** Replace the existing Stagnation row with:

> | Stagnation | Same total error count for 3+ consecutive iterations AND issue rotation detected — fewer than 70% of current issues match prior iteration issues by description similarity. Algorithmic parameters (similarity threshold, window sizes) defined in build spec. | Done (success — treated as converged plateau). Notify human with final error counts and iteration summary. |

---

### Change 2 — Design Spec: "Manual Edit Behavior" heading and sentence (Minor)

**Location:** The standalone bold heading "Manual Edit Behavior" and the sentence `"Locked" means the AI pipeline will not modify these files after their creation phase.` which appears between Phase 2 step 9 outputs and the `constraints.md` hot-reload explanation.

**Action:** Replace the heading and that sentence with:

> **Locked File Behavior:** "Locked" means the AI pipeline will not modify these files after their creation phase. The human may still edit them manually outside the pipeline, with the following consequences:

Then restructure the existing `constraints.md` and `spec.md`/`intent.md` paragraphs that follow as sub-bullets under this heading.

---

### Change 3 — Design Spec: Phase 1 step 11 split (Minor)

**Location:** Phase 1, step 11 output text.

**Action:** Replace the single step 11 with two sub-steps:

> 11a. Output: `intent.md` written to `/docs/` and locked — no further modification by AI in subsequent phases. Human may still edit manually outside the pipeline.
>
> 11b. The `deliverable_type` field in `status.json` is set to `"plan"` or `"code"`, derived from the Deliverable Type section of the confirmed `intent.md`.

---

### Change 4 — Design Spec: Distilling column clarification (Minor)

**Location:** The Kanban column list (Brain Dump → Distilling → Human Review → Spec Building → Building → Polishing → Done).

**Action:** Add the following sentence immediately after the column list:

> `Distilling` and `Human Review` are separate Kanban columns representing Phase 1 sub-states — the card moves from Brain Dump → Distilling → Human Review as the phase progresses.

---

### Change 5 — Execution Plan: Task 40 description (Minor)

**Location:** Task 40 row in the execution plan table.

**Action:** Replace the Task 40 description with:

> 40 | Implement Phase 4 per-iteration git auto-commits: commit after each review step and after each fix step (two commits per iteration)

Keep all other columns of the row unchanged.

---

### Change 6 — Design Spec: Agent Assignment paragraph addition (Minor)

**Location:** The Agent Assignment paragraph that contains `Per-project agent override is deferred — not a current build dependency.`

**Action:** Add the following text at the end of that paragraph:

> At project initialization, `config.yaml` `agents.default` is copied to the project's `status.json` `agent` field. This value is used for all pipeline phases of that project. There is no mechanism to change the agent mid-project or override it per-project in v1.

---

### Change 7 — Design Spec: Phase 2 error handling table addition (Major)

**Location:** Phase 2 Error Handling table.

**Action:** Add two new rows to the table:

> | File system error during `spec.md` or `constraints.md` write | Halt and notify human immediately with file path and error. No retry — same behavior as cross-cutting file system error handling. |
> | AI returns empty or structurally invalid content for `spec.md` or `constraints.md` | Retry once. On second failure, halt and notify human. |

---

### Change 8 — Build Spec: Code Builder Task Queue definition (Major)

**Location:** Build Spec, under the Code Plugin section or the Plugin Interface Contract (whichever exists — add near existing code builder content).

**Action:** Add the following new subsection:

> **Code Builder Task Queue:** The code builder maintains an ordered list of build tasks derived from `spec.md` (e.g., implement feature X, write tests for Y). Each task has a string identifier used for stuck detection — consecutive agent invocations against the same task identifier increment the retry counter. The task list format and derivation logic are internal to the code builder and are not persisted to state files. On crash recovery, the code builder re-derives the task list from `spec.md` and the current project file state.

---

### Change 9 — Design Spec: Code builder interaction model (Major)

**Location:** Design Spec, Phase 3 Code Mode section, after step 1.

**Action:** Add the following content:

> **Code builder interaction model:** The code builder passes the full `spec.md` (architecture, dependencies, acceptance criteria) to the coding agent as a single build prompt. The agent is responsible for scaffolding, implementation, and initial test writing in a single invocation or multi-turn session (depending on VK task execution behavior). The code builder then enters a test-fix cycle: run tests, pass failures back to the agent, agent fixes, re-run tests — repeating until all tests pass or stuck detection triggers. This is a coarser-grained interaction model than the plan builder's section-by-section approach, reflecting that coding agents (Claude Code, Codex) operate best with full project context rather than isolated function-level prompts.

---

### Change 10 — Execution Plan: Add test task 58f for WebSocket reconnection (Minor)

**Location:** Execution Plan task table, after Task 58e (or the last 58-series task).

**Action:** Add:

> | 58f | Unit tests: WebSocket reconnection (auto-reconnect on disconnect, state sync from `status.json` and `chat_history.json` on reconnect, connection status indicator shown during disconnect, in-flight responses not replayed, server handles invalid project ID on reconnect) | — | Task 7i | — | Not Started |

---

### Change 11 — Execution Plan: Add test task 58g for concurrency limits (Minor)

**Location:** Execution Plan task table, after the new Task 58f.

**Action:** Add:

> | 58g | Unit tests: concurrency limit enforcement (block new project at max, count halted as active, re-enable on terminal state, sidebar message displayed) | — | Task 2b | — | Not Started |

---

### Change 12 — Execution Plan: Add test task 58h for server restart recovery (Minor)

**Location:** Execution Plan task table, after the new Task 58g.

**Action:** Add:

> | 58h | Unit tests: server restart recovery (interactive states resume, autonomous states halted with `server_restart` reason, notifications sent for halted projects, terminal states ignored) | — | Task 1c | — | Not Started |

---

### Change 13 — Execution Plan: Amend Task 58b description (Minor)

**Location:** Execution Plan, Task 58b row.

**Action:** Replace the Task 58b description with:

> 58b | Unit tests: action buttons (Distill triggers distillation, Confirm advances phase, button state disabled during processing, server-side duplicate request ignored and returns current state, Phase 4 halt recovery buttons, Phase 3 stuck recovery buttons)

Keep all other columns unchanged.

---

### Change 14 — Execution Plan: Add execution-specific risks to Risk Register (Minor)

**Location:** Execution Plan, Risk Register table.

**Action:** Add two new rows:

> | Agent CLI changes mid-build (flag deprecation, output format change) | Low | High | Agent adapters isolate changes. Pin agent CLI versions during build. Run adapter unit tests on each agent update. |
> | Cross-stage dependency chain delays (Stage 7 → Stage 2 → Stage 4) | Medium | Medium | Begin Build Stage 7 (agent layer) immediately after Task 1. Track critical path separately from stage numbering. |

---

### Change 15 — Design Spec: Extract Realign Algorithm detail to build spec (Minor)

**Location:** Design Spec, Phase 1 step 9.

**Action:** Replace the current step 9 text with:

> 9. Human can type "realign from here" in chat. The AI resets to the most recent substantive correction, discarding subsequent conversation, and re-distills from the original brain dump plus all corrections up to that point. If no corrections exist yet, the command is ignored with a prompt to provide a correction first. Implementation algorithm in build spec.

Verify that the Build Spec already contains the full Realign Algorithm detail (it should, around lines 386–393). If it does, no build spec change needed for this item.

---

### Change 16 — Design Spec: Extract Operation Taxonomy enumeration (Minor)

**Location:** Design Spec, Plan Mode Safety Guardrails section, the Operation Taxonomy paragraph.

**Action:** Replace the paragraph with:

> **Operation Taxonomy:** The orchestrator classifies every Phase 3/4 action into an operation type before invoking the plugin's `validate()`. The complete operation type list and the mapping from orchestrator actions to operation types are defined in the build spec.

Remove the inline enumeration of operation types (shell_exec, file_create, file_modify, package_install, agent_invoke) from the design spec. Verify the build spec already contains this enumeration.

---

## After All Changes Are Applied

1. Re-read each modified file to confirm no formatting is broken (unclosed tables, orphaned headers, broken markdown).
2. Git add only files you actually modified:
   ```bash
   git add docs/thoughtforge-design-specification.md docs/thoughtforge-build-spec.md docs/thoughtforge-execution-plan.md
   ```
3. Commit with message: `Apply review findings`
4. Push to remote: `git push`
5. Confirm the push succeeded. Do not leave commits unpushed.
