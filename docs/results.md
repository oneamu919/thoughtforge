Now I have all four documents. Let me thoroughly analyze the design specification against the requirements brief, build spec, and execution plan to produce the review findings.

---

# Project Plan Review — ThoughtForge Design Specification

Review performed against the requirements brief, build spec, and execution plan as companion documents.

---

## 1. Writing That's Unclear

**[Minor] — "Realign from here" rollback point is undefined in the design spec**

The design spec (Phase 1, step 9) says the AI "re-distills from the original brain dump plus corrections up to a rollback point" but never explains what determines the rollback point. The build spec's Realign Algorithm clarifies it (scan backwards past sequential realign commands to the most recent substantive correction), but the design spec reads as if the human specifies a rollback point, which is misleading.

Replace (design spec, Phase 1 step 9):
> Human can type "realign from here" in chat. Unlike phase advancement actions (which use buttons to prevent misinterpretation), "realign from here" is a chat-parsed command because it does not advance the pipeline — it re-runs the distillation using the original brain dump plus all corrections up to the identified rollback point. The AI re-distills from the original brain dump plus corrections up to a rollback point. Algorithm details in build spec.

With:
> Human can type "realign from here" in chat. Unlike phase advancement actions (which use buttons to prevent misinterpretation), "realign from here" is a chat-parsed command because it does not advance the pipeline — it discards AI messages and corrections after the most recent substantive human correction and re-distills from the original brain dump plus corrections up to that point. Exact matching rules and algorithm in build spec.

This also eliminates the duplicative second sentence in the current text ("The AI re-distills from the original brain dump plus corrections up to a rollback point").

---

**[Minor] — Fabrication guard description contains a duplicated phrase**

The fabrication guard condition 2 in the design spec (Phase 4 Convergence Guards table) contains a duplicated clause: "every severity category was at or below twice its convergence threshold — every severity category was at or below twice its convergence threshold".

Replace:
> AND in at least one prior iteration, every severity category was at or below twice its convergence threshold — every severity category was at or below twice its convergence threshold — that is, critical ≤ 2 × `critical_max`, medium ≤ 2 × `medium_max`, minor ≤ 2 × `minor_max`

With:
> AND in at least one prior iteration, every severity category was at or below twice its convergence threshold — that is, critical ≤ 2 × `critical_max`, medium ≤ 2 × `medium_max`, minor ≤ 2 × `minor_max`

---

**[Minor] — "Stuck detection" overloads the term across two different mechanisms**

Phase 3 uses "stuck detection" for both Plan mode (AI self-reports `stuck: true`) and Code mode (consecutive identical test failures or non-zero exits). The design spec presents these in the same table but they are fundamentally different mechanisms — one is AI self-reporting, the other is orchestrator-observed patterns. A reader building from this could confuse the two.

Replace the introductory sentence before the Stuck Detection table:
> **Stuck Detection (Phase 3):**

With:
> **Stuck Detection (Phase 3):** Plan mode and Code mode use different stuck detection mechanisms. Plan mode relies on AI self-reporting via a structured response field. Code mode relies on orchestrator-observed failure patterns.

---

**[Minor] — "Each project gets its own repo" vs. "its own git repo" vs. "git init" used inconsistently**

The design spec uses "git repo" (Technical Design), "its own repo" (Design Decisions table), and "git init" (Phase 1 step 0) to describe the same thing. This is fine for a human reader but could confuse an AI coder about whether "repo" means a separate remote repository or just a local git-initialized directory.

In Design Decision #3, replace:
> Each project gets its own git repo

With:
> Each project gets its own local git repository (git init, no remote)

---

**[Minor] — "Halted" vs. "Terminated" distinction could be clearer at first encounter**

The design spec first introduces `halted` as a convergence guard outcome, then later (Phase 4 Halt Recovery) introduces Terminate as setting `halted` permanently. The distinction between a recoverable halt and a permanent termination isn't clear until the reader reaches the halt recovery section and the `halt_reason` values in the build spec.

After the Phase 4 Convergence Guards table, add:
> **Halt vs. Terminate:** When a convergence guard triggers a halt, the project is recoverable — the human can Resume or Override. When the human explicitly Terminates (via button), the project is permanently stopped (`halt_reason: "human_terminated"`). Both use the `halted` phase value in `status.json`; the `halt_reason` field distinguishes them.

---

**[Minor] — "Minimum completeness thresholds" in Phase 3→4 transition are not defined in the design spec**

The design spec (Phase 3→4 Transition Error Handling) says "below minimum completeness thresholds" but doesn't state what they are. The build spec's `config.yaml` template defines them (`phase3_completeness.plan_min_chars: 100`, `phase3_completeness.code_require_tests: true`), but the design spec should at minimum reference the config key.

Replace:
> Phase 3 output exists but is empty or trivially small (below minimum completeness thresholds)

With:
> Phase 3 output exists but is empty or trivially small (below `config.yaml` `phase3_completeness` thresholds)

---

## 2. Genuinely Missing Plan-Level Content

**[Major] — No error handling for Handlebars template content exceeding agent context window**

The design spec specifies that the plan builder "may invoke the AI agent multiple times to fill the complete template — for example, one invocation per major section." It also specifies that `constraints.md` is truncated if it exceeds context, and that chat history is truncated if it exceeds context. But there is no specification for what happens when the partially-filled template passed as context to the AI grows larger than the agent's context window during multi-invocation plan building. For large plans (e.g., a comprehensive wedding plan), the accumulated filled sections could exceed the window.

Proposed content to add after the "Builder interaction model" paragraph in Phase 3 Plan Mode:
> **Template Context Window Overflow:** If the partially-filled template exceeds the agent's context window during multi-invocation plan building, the builder passes only the current section's OPA table slot, the `spec.md` context for that section, and the immediately preceding section (for continuity) — not the full partially-filled template. A warning is logged when truncation occurs. The full template is reassembled from the individually-filled sections after all invocations complete.

---

**[Major] — No specification for what the Phase 4 fix agent does when a review finds zero issues**

The design spec's convergence check happens after the full iteration (review + fix). If the review finds zero issues (all counts at 0), the termination guard would trigger at the end of the iteration. But the spec doesn't say whether the fix step is skipped when there are no issues. Running a fix agent with an empty issue list is wasteful and could produce unexpected behavior.

Proposed content to add after the "Fix agent context assembly" paragraph in Phase 4:
> **Zero-Issue Iteration:** If the review step produces zero issues (empty issues array), the fix step is skipped for that iteration. The orchestrator proceeds directly to convergence guard evaluation. Only the review commit is written — no fix commit.

---

**[Minor] — No specification for notification behavior when the human is actively viewing the project**

The design spec says every phase transition pings the human with a notification (ntfy.sh). But if the human is already looking at the project in the chat interface, duplicate external notifications are noise. The plan doesn't address whether notifications are suppressed when the human has the project open.

Proposed content to add to the Notification Content section:
> **Active Session Awareness:** Notifications are sent regardless of whether the human has the project open in the chat interface. The notification layer does not track client connection state. Suppressing notifications for active sessions is deferred — not a current build dependency.

---

**[Minor] — No mention of how `polish_log.md` or `polish_state.json` behave on Resume after halt**

The design spec says Resume "resumes the polish loop from the next iteration" and that `polish_state.json` is preserved. But it doesn't specify whether `polish_log.md` gets a resume entry, or whether the convergence trajectory in `polish_state.json` is continuous across the halt boundary.

Proposed content to add to the Phase 4 Halt Recovery section:
> **State Continuity on Resume:** The convergence trajectory in `polish_state.json` is continuous across the halt boundary — the resumed iteration is numbered sequentially after the last completed iteration. `polish_log.md` receives a log entry for the resume event before the next iteration's entry: `## Resumed at {ISO8601} — Halted by {guard_type} at iteration {N}, resumed by human`.

---

## 3. Build Spec Material That Should Be Extracted

**[Minor] — Phase 1 step 3 connector URL pattern matching details**

The design spec (Phase 1, step 3 detail) specifies the three-way URL matching logic (match+enabled, match+disabled, no match). This is implementation-level routing logic — the design-level content is "ThoughtForge identifies connector URLs in chat messages and pulls content via enabled connectors." The matching matrix belongs in the build spec alongside the connector URL patterns that are already there.

Specific text to extract from design spec Phase 1, step 3:
> The AI matches each URL against the known patterns for enabled connectors:
> - **Match + enabled:** URL is pulled automatically via the connector.
> - **Match + disabled:** URL is silently ignored (not pulled, not treated as text).
> - **No match:** URL is treated as regular brain dump text and included in distillation context.

Replace with in the design spec:
> The AI matches each URL against the known patterns for enabled connectors and pulls content automatically. URL matching rules (enabled/disabled/unmatched behavior) are in the build spec.

---

**[Minor] — Operation Type Taxonomy table in design spec**

The design spec (Plan Mode Safety Guardrails section) references the Operation Taxonomy and says "The complete operation type list and the mapping from orchestrator actions to operation types are defined in the build spec." This is correct — the build spec contains the full taxonomy table. No extraction needed here; the design spec correctly delegates. (Noting this for completeness — no action required.)

---

**[Minor] — `chat_history.json` truncation algorithm specifics**

The design spec describes truncation behavior for all four phases in detail (Phase 1 retains brain dump, Phase 2 retains initial proposal, Phase 3-4 have no anchor). These are algorithm-level details that the build spec's "Chat History Truncation Algorithm" section already covers. The design spec should state the *policy* (what is retained and why) but not the algorithm.

Specific text that could be condensed in the design spec:
> **Phase 2 Chat History Truncation:** If Phase 2 chat history exceeds the agent context window, the agent invocation layer truncates older messages from the beginning of the history, retaining the most recent messages and always retaining the initial AI spec proposal message (the first AI message in Phase 2). Messages between the initial proposal and the retained recent messages are dropped. A warning is logged when truncation occurs. This mirrors the Phase 1 truncation behavior — the initial proposal serves the same anchoring role as the original brain dump.

Replace with:
> **Phase 2 Chat History Truncation:** If Phase 2 chat history exceeds the agent context window, older messages are truncated while always retaining the initial AI spec proposal (same anchoring pattern as Phase 1's brain dump retention). Algorithm in build spec.

And similarly for the Phase 3-4 truncation paragraph — replace:
> **Phase 3–4 Chat History Truncation:** If Phase 3 or Phase 4 recovery chat history exceeds the agent context window, the agent invocation layer truncates older messages from the beginning, retaining the most recent messages. There is no anchoring message for these phases — unlike Phases 1–2, recovery conversations do not have a structural anchor that must be preserved. A warning is logged when truncation occurs.

With:
> **Phase 3–4 Chat History Truncation:** If Phase 3 or Phase 4 recovery chat history exceeds the agent context window, older messages are truncated from the beginning with no anchoring message. Algorithm in build spec.
