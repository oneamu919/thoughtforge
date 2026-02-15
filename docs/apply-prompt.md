# Apply Review Findings from results.md

You are an AI coder. Apply every change listed below to the source files. Each change is taken directly from the review findings in `docs/results.md`. Do not interpret or improvise — apply the replacements, additions, and extractions exactly as specified.

Read all target files before editing. After all changes are applied, git commit and sync to remote.

---

## Target Files

- `docs/thoughtforge-design-specification.md` (referred to as "Design Spec")
- `docs/thoughtforge-build-spec.md` (referred to as "Build Spec")
- `docs/thoughtforge-execution-plan.md` (referred to as "Execution Plan")

Read all three files before making any edits.

---

## Changes to Design Spec (`docs/thoughtforge-design-specification.md`)

### Change 1 — Replace "realign from here" scope text (near line 92) [Minor]

**Find:**
> Human can type 'realign from here' in chat. Unlike phase advancement actions (which use buttons to prevent misinterpretation), 'realign from here' is a chat-parsed command because it does not advance the pipeline — it re-processes within the current phase.

**Replace with:**
> Human can type 'realign from here' in chat. Unlike phase advancement actions (which use buttons to prevent misinterpretation), 'realign from here' is a chat-parsed command because it does not advance the pipeline — it re-runs the distillation using the original brain dump plus all corrections up to the identified rollback point.

---

### Change 2 — Replace stagnation guard run-on sentence (near line 318) [Minor]

**Find:**
> **Stagnation:** Same total error count (sum of critical + medium + minor) for a configured number of consecutive iterations (stagnation limit) AND issue rotation detected (old issues resolved, new issues introduced at the same rate — rotation threshold and similarity measure defined in build spec). The comparison uses total count only, not per-severity breakdown — a shift in severity composition at the same total is still treated as stagnation if the rotation threshold is also met. This combination indicates the deliverable has reached a quality plateau where the reviewer is cycling through cosmetic or subjective issues rather than finding genuine regressions. Treated as converged.

**Replace with:**
> **Stagnation:** Two conditions must both be true: (1) Same total error count (sum of critical + medium + minor) for a configured number of consecutive iterations (stagnation limit). (2) Issue rotation detected — old issues resolved, new issues introduced at the same rate (rotation threshold and similarity measure defined in build spec). The comparison uses total count only — a shift in severity composition at the same total still qualifies as stagnation if the rotation threshold is also met. When both conditions are true, the deliverable has reached a quality plateau where the reviewer is cycling through cosmetic issues rather than finding genuine regressions. Treated as converged.

---

### Change 3 — Replace parallel execution ambiguity text (near line 454) [Minor]

**Find:**
> Both modes function fully with the toggle off. The only losses are the Kanban board view and automated parallel execution (parallel execution management becomes the human's responsibility).

**Replace with:**
> Both modes function fully with the toggle off. The only losses are the Kanban board view and VK-managed multi-project parallel execution (the human must manually manage concurrent project execution without VK).

---

### Change 4 — Replace chat history scope text (near line 484) [Minor]

**Find:**
> Each invocation passes the full working context: the brain dump, resources, current distillation (Phase 1) or spec-in-progress (Phase 2), and the relevant chat history from `chat_history.json`.

**Replace with:**
> Each invocation passes the full working context: the brain dump, resources, current distillation (Phase 1) or spec-in-progress (Phase 2), and all messages from `chat_history.json` for the current phase (subject to the context window truncation behavior described in the `chat_history.json` Error Handling section).

---

### Change 5 — Replace per-project agent override text (near line 75) [Minor]

**Find:**
> Per-project agent override is deferred — not a current build dependency. At project initialization, `config.yaml` `agents.default` is copied to the project's `status.json` `agent` field. This value is used for all pipeline phases of that project. There is no mechanism to change the agent mid-project or override it per-project in v1.

**Replace with:**
> Per-project agent override is deferred — not a current build dependency. At project initialization, `config.yaml` `agents.default` is copied to the project's `status.json` `agent` field and used for all pipeline phases of that project.

---

### Change 6 — Add Phase 2 chat history truncation specification [Major]

**Location:** After the `chat_history.json` Error Handling paragraph (after line 126), where the Phase 1 truncation behavior is specified.

**Add this new paragraph:**

> **Phase 2 Chat History Truncation:** If Phase 2 chat history exceeds the agent context window, the agent invocation layer truncates older messages from the beginning of the history, retaining the most recent messages and always retaining the initial AI spec proposal message (the first AI message in Phase 2). Messages between the initial proposal and the retained recent messages are dropped. A warning is logged when truncation occurs. This mirrors the Phase 1 truncation behavior — the initial proposal serves the same anchoring role as the original brain dump.

---

### Change 7 — Add constraints.md readability definition [Major]

**Location:** After the `constraints.md` — unvalidated after creation paragraph (near lines 156-159).

**Add this new paragraph:**

> **`constraints.md` — readability definition:** "Unreadable" means the file cannot be read from disk (permission error, I/O error) or is not valid UTF-8 text. A file that is readable but contains unexpected content (empty, restructured, nonsensical) is passed to the reviewer as-is per the unvalidated-after-creation policy. If the file exceeds the agent's context window when combined with other review context, it is truncated with a warning logged.

---

### Change 8 — Add prompt file list refresh specification [Minor]

**Location:** In the Prompt Management section, after the existing text about new prompts being auto-picked up (near line 542).

**Add this new paragraph:**

> **Prompt file list refresh:** The Settings UI reads the `/prompts/` directory listing each time it is opened. If a prompt file is deleted externally while the editor is open, saving to the deleted file creates it anew (same atomic write behavior). No file locking — the single-operator model makes this acceptable.

---

### Change 9 — Add shell safety to Agent Communication section [Major]

**Location:** After the agent invocation text (after line 474).

**Add this new paragraph:**

> **Shell safety:** Prompt content is passed via stdin pipe or file — never through shell argument expansion. This prevents shell metacharacters in brain dump text or resource files from causing accidental command execution.

---

## Changes to Execution Plan (`docs/thoughtforge-execution-plan.md`)

### Change 10 — Replace critical path notation (near line 188) [Minor]

**Find:**
> **Task 1 → Task 41 → Task 42 → Task 8 → Task 9 → Task 11 → Task 12 → Task 13 → Task 15 → Task 16 → Task 30 → Tasks 33–37 → Task 51**

**Replace with:**
> **Task 1 → Task 41 → Task 42 → Task 6a → Task 8 → Task 9 → Task 11 → Task 12 → Task 13 → Task 15 → Task 16 → Task 30 → Tasks 33–37 → Task 51**
>
> Note: Task 6a (pipeline orchestrator) depends on Tasks 2, 3, and 6, which run in parallel with the agent layer (41–42). Task 6a appears on the critical path only if its dependency chain (Task 1 → Tasks 2+3+6 → Task 6a) takes longer than the agent layer chain (Task 1 → Task 41 → Task 42). The builder should track both branches.

---

### Change 11 — Add unit test task for chat history truncation to Build Stage 8 [Major]

**Add this row to the Build Stage 8 task table:**

> | 58l | Unit tests: chat history truncation (Phase 1 truncation retains brain dump messages, drops middle messages, retains recent; Phase 2 truncation retains initial proposal; warning logged on truncation; empty history handled; history below window size passed through unchanged) | — | Task 9a | — | Not Started |

---

### Change 12 — Add unit test task for OSS discovery scorecard to Build Stage 8 [Minor]

**Add this row to the Build Stage 8 task table:**

> | 58m | Unit tests: OSS discovery scorecard (8-signal evaluation, red flag detection on Age/Last Updated/License, minimum 6-of-8 qualification threshold, handles missing signal data gracefully) | — | Task 25 | — | Not Started |

---

## Changes to Build Spec (`docs/thoughtforge-build-spec.md`)

### Change 13 — Add deliverable type parse failure handling [Minor]

**Location:** In the Deliverable Type Parsing section (near line 515).

**Add this text:**

> If the first word of the Deliverable Type section is neither "Plan" nor "Code" (case-insensitive), the orchestrator sets `deliverable_type` to `null` and does not advance to Phase 2. The human is notified in chat: "Could not determine deliverable type from intent. Please correct the Deliverable Type section to start with 'Plan' or 'Code'."

---

### Change 14 — Update Task 11 description in Execution Plan [Minor]

**Location:** In `docs/thoughtforge-execution-plan.md`, find the Task 11 row.

**Append to the Task 11 description:**

> Include deliverable type parse failure handling: reject values other than "Plan" or "Code", notify human in chat, do not advance.

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
