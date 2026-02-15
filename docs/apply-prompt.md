# Apply Review Findings from results.md

You are an AI coder. Apply every change listed below to the source files. Each change is taken directly from the review findings in `docs/results.md`. Do not interpret or improvise — apply the replacements, additions, and extractions exactly as specified.

Read all target files before editing. After all changes are applied, git commit and sync to remote.

---

## Target Files

- `docs/thoughtforge-design-specification.md` (referred to as "Design Spec")
- `docs/thoughtforge-build-spec.md` (referred to as "Build Spec")

Read both files before making any edits.

---

## SECTION 1: Replacements (Unclear Writing)

### Change 1 — Design Spec, Phase 1 Step 9: "Realign from here" rollback point [Minor]

**Find** in Phase 1, step 9:
> Human can type "realign from here" in chat. Unlike phase advancement actions (which use buttons to prevent misinterpretation), "realign from here" is a chat-parsed command because it does not advance the pipeline — it re-runs the distillation using the original brain dump plus all corrections up to the identified rollback point. The AI re-distills from the original brain dump plus corrections up to a rollback point. Algorithm details in build spec.

**Replace with:**
> Human can type "realign from here" in chat. Unlike phase advancement actions (which use buttons to prevent misinterpretation), "realign from here" is a chat-parsed command because it does not advance the pipeline — it discards AI messages and corrections after the most recent substantive human correction and re-distills from the original brain dump plus corrections up to that point. Exact matching rules and algorithm in build spec.

---

### Change 2 — Design Spec, Phase 4 Convergence Guards table: Fabrication guard duplicated phrase [Minor]

**Find** in Phase 4 Convergence Guards table, fabrication guard condition 2:
> AND in at least one prior iteration, every severity category was at or below twice its convergence threshold — every severity category was at or below twice its convergence threshold — that is, critical ≤ 2 × `critical_max`, medium ≤ 2 × `medium_max`, minor ≤ 2 × `minor_max`

**Replace with:**
> AND in at least one prior iteration, every severity category was at or below twice its convergence threshold — that is, critical ≤ 2 × `critical_max`, medium ≤ 2 × `medium_max`, minor ≤ 2 × `minor_max`

---

### Change 3 — Design Spec, Phase 3 Stuck Detection table: Overloaded term [Minor]

**Find** the introductory line before the Stuck Detection table:
> **Stuck Detection (Phase 3):**

**Replace with:**
> **Stuck Detection (Phase 3):** Plan mode and Code mode use different stuck detection mechanisms. Plan mode relies on AI self-reporting via a structured response field. Code mode relies on orchestrator-observed failure patterns.

---

### Change 4 — Design Spec, Design Decision #3: "git repo" ambiguity [Minor]

**Find** in Design Decision #3:
> Each project gets its own git repo

**Replace with:**
> Each project gets its own local git repository (git init, no remote)

---

### Change 5 — Design Spec, Phase 3→4 Transition Error Handling: Undefined completeness thresholds [Minor]

**Find:**
> Phase 3 output exists but is empty or trivially small (below minimum completeness thresholds)

**Replace with:**
> Phase 3 output exists but is empty or trivially small (below `config.yaml` `phase3_completeness` thresholds)

---

## SECTION 2: Additions (Missing Plan-Level Content)

### Change 6 — Design Spec, Phase 3 Plan Mode: Template context window overflow [Major]

**Add** the following paragraph after the "Builder interaction model" paragraph in Phase 3 Plan Mode:
> **Template Context Window Overflow:** If the partially-filled template exceeds the agent's context window during multi-invocation plan building, the builder passes only the current section's OPA table slot, the `spec.md` context for that section, and the immediately preceding section (for continuity) — not the full partially-filled template. A warning is logged when truncation occurs. The full template is reassembled from the individually-filled sections after all invocations complete.

---

### Change 7 — Design Spec, Phase 4: Zero-issue iteration behavior [Major]

**Add** the following paragraph after the "Fix agent context assembly" paragraph in Phase 4:
> **Zero-Issue Iteration:** If the review step produces zero issues (empty issues array), the fix step is skipped for that iteration. The orchestrator proceeds directly to convergence guard evaluation. Only the review commit is written — no fix commit.

---

### Change 8 — Design Spec, Notification Content section: Active session awareness [Minor]

**Add** the following to the Notification Content section:
> **Active Session Awareness:** Notifications are sent regardless of whether the human has the project open in the chat interface. The notification layer does not track client connection state. Suppressing notifications for active sessions is deferred — not a current build dependency.

---

### Change 9 — Design Spec, Phase 4 Halt Recovery section: State continuity on resume [Minor]

**Add** the following to the Phase 4 Halt Recovery section:
> **State Continuity on Resume:** The convergence trajectory in `polish_state.json` is continuous across the halt boundary — the resumed iteration is numbered sequentially after the last completed iteration. `polish_log.md` receives a log entry for the resume event before the next iteration's entry: `## Resumed at {ISO8601} — Halted by {guard_type} at iteration {N}, resumed by human`.

---

### Change 10 — Design Spec, after Phase 4 Convergence Guards table: Halt vs. Terminate clarity [Minor]

**Add** the following paragraph immediately after the Phase 4 Convergence Guards table:
> **Halt vs. Terminate:** When a convergence guard triggers a halt, the project is recoverable — the human can Resume or Override. When the human explicitly Terminates (via button), the project is permanently stopped (`halt_reason: "human_terminated"`). Both use the `halted` phase value in `status.json`; the `halt_reason` field distinguishes them.

---

## SECTION 3: Extractions (Move Implementation Details from Design Spec to Build Spec)

### Change 11 — Design Spec, Phase 1 Step 3: Extract connector URL matching details [Minor]

**Find** in Design Spec, Phase 1 step 3:
> The AI matches each URL against the known patterns for enabled connectors:
> - **Match + enabled:** URL is pulled automatically via the connector.
> - **Match + disabled:** URL is silently ignored (not pulled, not treated as text).
> - **No match:** URL is treated as regular brain dump text and included in distillation context.

**Replace with:**
> The AI matches each URL against the known patterns for enabled connectors and pulls content automatically. URL matching rules (enabled/disabled/unmatched behavior) are in the build spec.

Ensure the extracted matching matrix is present in the Build Spec's connector section. If it is already there, no Build Spec change is needed for this item.

---

### Change 12 — Design Spec: Condense Phase 2 Chat History Truncation [Minor]

**Find:**
> **Phase 2 Chat History Truncation:** If Phase 2 chat history exceeds the agent context window, the agent invocation layer truncates older messages from the beginning of the history, retaining the most recent messages and always retaining the initial AI spec proposal message (the first AI message in Phase 2). Messages between the initial proposal and the retained recent messages are dropped. A warning is logged when truncation occurs. This mirrors the Phase 1 truncation behavior — the initial proposal serves the same anchoring role as the original brain dump.

**Replace with:**
> **Phase 2 Chat History Truncation:** If Phase 2 chat history exceeds the agent context window, older messages are truncated while always retaining the initial AI spec proposal (same anchoring pattern as Phase 1's brain dump retention). Algorithm in build spec.

---

### Change 13 — Design Spec: Condense Phase 3–4 Chat History Truncation [Minor]

**Find:**
> **Phase 3–4 Chat History Truncation:** If Phase 3 or Phase 4 recovery chat history exceeds the agent context window, the agent invocation layer truncates older messages from the beginning, retaining the most recent messages. There is no anchoring message for these phases — unlike Phases 1–2, recovery conversations do not have a structural anchor that must be preserved. A warning is logged when truncation occurs.

**Replace with:**
> **Phase 3–4 Chat History Truncation:** If Phase 3 or Phase 4 recovery chat history exceeds the agent context window, older messages are truncated from the beginning with no anchoring message. Algorithm in build spec.

---

## After All Changes Are Applied

1. Re-read each modified file to confirm no formatting is broken (unclosed tables, orphaned headers, broken markdown).
2. `git status -u` — verify all modified files.
3. `git diff --stat` — confirm changes.
4. Git add only the files you modified.
5. Commit with message: `Apply review findings`
6. Push to remote: `git push`
7. `git pull` — confirm sync with remote. Do not leave commits unpushed.
