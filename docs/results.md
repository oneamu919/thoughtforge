Now let me read the remaining two files being scrutinized more carefully for the review. I've read all four files. Let me now produce the review.

---

# Plan Review Findings

## 1. Writing That's Unclear

**[Minor] Design Spec — "Realign from here" scope ambiguity (line 92)**

Current text:
> "Human can type 'realign from here' in chat. Unlike phase advancement actions (which use buttons to prevent misinterpretation), 'realign from here' is a chat-parsed command because it does not advance the pipeline — it re-processes within the current phase."

The phrase "re-processes within the current phase" is vague about what exactly is re-processed.

Replacement text:
> "Human can type 'realign from here' in chat. Unlike phase advancement actions (which use buttons to prevent misinterpretation), 'realign from here' is a chat-parsed command because it does not advance the pipeline — it re-runs the distillation using the original brain dump plus all corrections up to the identified rollback point."

---

**[Minor] Design Spec — Stagnation guard run-on sentence (line 318)**

Current text:
> "**Stagnation:** Same total error count (sum of critical + medium + minor) for a configured number of consecutive iterations (stagnation limit) AND issue rotation detected (old issues resolved, new issues introduced at the same rate — rotation threshold and similarity measure defined in build spec). The comparison uses total count only, not per-severity breakdown — a shift in severity composition at the same total is still treated as stagnation if the rotation threshold is also met. This combination indicates the deliverable has reached a quality plateau where the reviewer is cycling through cosmetic or subjective issues rather than finding genuine regressions. Treated as converged."

This is a single table cell containing four distinct ideas in one block. A builder reading the guard table will miss the severity composition nuance.

Replacement text:
> "**Stagnation:** Two conditions must both be true: (1) Same total error count (sum of critical + medium + minor) for a configured number of consecutive iterations (stagnation limit). (2) Issue rotation detected — old issues resolved, new issues introduced at the same rate (rotation threshold and similarity measure defined in build spec). The comparison uses total count only — a shift in severity composition at the same total still qualifies as stagnation if the rotation threshold is also met. When both conditions are true, the deliverable has reached a quality plateau where the reviewer is cycling through cosmetic issues rather than finding genuine regressions. Treated as converged."

---

**[Minor] Design Spec — "Both modes function fully with the toggle off" (line 454)**

Current text:
> "Both modes function fully with the toggle off. The only losses are the Kanban board view and automated parallel execution (parallel execution management becomes the human's responsibility)."

"Automated parallel execution" is ambiguous — it could mean VK runs multiple agents within a single project, or it manages multiple concurrent projects. The design spec doesn't clarify which aspect VK automates.

Replacement text:
> "Both modes function fully with the toggle off. The only losses are the Kanban board view and VK-managed multi-project parallel execution (the human must manually manage concurrent project execution without VK)."

---

**[Minor] Design Spec — Phase 1-2 Chat Agent Model unclear on chat history scope (line 484)**

Current text:
> "Each invocation passes the full working context: the brain dump, resources, current distillation (Phase 1) or spec-in-progress (Phase 2), and the relevant chat history from `chat_history.json`."

"Relevant chat history" is ambiguous — does this mean the full file or a filtered subset?

Replacement text:
> "Each invocation passes the full working context: the brain dump, resources, current distillation (Phase 1) or spec-in-progress (Phase 2), and all messages from `chat_history.json` for the current phase (subject to the context window truncation behavior described in the `chat_history.json` Error Handling section)."

---

**[Minor] Execution Plan — Critical path notation incomplete (line 188)**

Current text:
> "**Task 1 → Task 41 → Task 42 → Task 8 → Task 9 → Task 11 → Task 12 → Task 13 → Task 15 → Task 16 → Task 30 → Tasks 33–37 → Task 51**"

Task 6a (pipeline orchestrator) is a dependency of Tasks 8, 15, 21, and 30 but does not appear in the critical path chain. If Task 6a takes longer than Task 42, it becomes the actual bottleneck.

Replacement text:
> "**Task 1 → Task 41 → Task 42 → Task 6a → Task 8 → Task 9 → Task 11 → Task 12 → Task 13 → Task 15 → Task 16 → Task 30 → Tasks 33–37 → Task 51**
>
> Note: Task 6a (pipeline orchestrator) depends on Tasks 2, 3, and 6, which run in parallel with the agent layer (41–42). Task 6a appears on the critical path only if its dependency chain (Task 1 → Tasks 2+3+6 → Task 6a) takes longer than the agent layer chain (Task 1 → Task 41 → Task 42). The builder should track both branches."

---

**[Minor] Design Spec — "Per-project agent override is deferred" stated twice (line 75)**

Current text:
> "Per-project agent override is deferred — not a current build dependency. At project initialization, `config.yaml` `agents.default` is copied to the project's `status.json` `agent` field. This value is used for all pipeline phases of that project. There is no mechanism to change the agent mid-project or override it per-project in v1."

The last two sentences repeat what the first sentence and the paragraph opening already said.

Replacement text:
> "Per-project agent override is deferred — not a current build dependency. At project initialization, `config.yaml` `agents.default` is copied to the project's `status.json` `agent` field and used for all pipeline phases of that project."

---

## 2. Genuinely Missing Plan-Level Content

**[Major] Design Spec — No chat history truncation behavior for Phase 2**

The design spec (line 126) specifies detailed truncation behavior for Phase 1 when chat history exceeds the agent context window — brain dump messages are always retained, older messages are dropped from the middle, a warning is logged. But Phase 2 has no equivalent specification. Phase 2 conversations can also grow long (spec negotiation, decision debates, acceptance criteria iteration), and the same context window constraint applies.

Proposed content to add after the `chat_history.json` Error Handling paragraph (after line 126):

> **Phase 2 Chat History Truncation:** If Phase 2 chat history exceeds the agent context window, the agent invocation layer truncates older messages from the beginning of the history, retaining the most recent messages and always retaining the initial AI spec proposal message (the first AI message in Phase 2). Messages between the initial proposal and the retained recent messages are dropped. A warning is logged when truncation occurs. This mirrors the Phase 1 truncation behavior — the initial proposal serves the same anchoring role as the original brain dump.

---

**[Major] Execution Plan — No testing task for chat_history.json truncation behavior**

The design spec specifies detailed truncation logic (retain brain dump, drop middle messages, log warning) and the build spec's realign algorithm depends on chat history integrity. But Build Stage 8 has no unit test task covering chat history truncation.

Proposed task to add to Build Stage 8:

> | 58l | Unit tests: chat history truncation (Phase 1 truncation retains brain dump messages, drops middle messages, retains recent; Phase 2 truncation retains initial proposal; warning logged on truncation; empty history handled; history below window size passed through unchanged) | — | Task 9a | — | Not Started |

---

**[Major] Design Spec — No specification for what happens when the human edits `constraints.md` to be syntactically invalid Markdown**

The design spec (lines 156-159) specifies that `constraints.md` is hot-reloaded at each Phase 4 iteration and that ThoughtForge passes it to the AI reviewer "as-is without schema validation" if the human restructures it. It also specifies that if `constraints.md` is "unreadable or missing," the iteration halts. But "unreadable" isn't defined — if the human saves a file with binary content, encoding errors, or a file so large it exceeds the agent context window, the behavior is undefined.

Proposed content to add after the `constraints.md` — unvalidated after creation paragraph:

> **`constraints.md` — readability definition:** "Unreadable" means the file cannot be read from disk (permission error, I/O error) or is not valid UTF-8 text. A file that is readable but contains unexpected content (empty, restructured, nonsensical) is passed to the reviewer as-is per the unvalidated-after-creation policy. If the file exceeds the agent's context window when combined with other review context, it is truncated with a warning logged.

---

**[Minor] Execution Plan — No task for implementing the ambiguous deliverable type handling**

The design spec (line 98) specifies that when a brain dump contains signals for both Plan and Code, the AI defaults to Plan and flags the ambiguity. This is prompt-level behavior and is covered by the brain-dump-intake prompt text. However, the deliverable type parsing logic (build spec line 515) string-matches "Plan" or "Code" from the first word. There's no specification for what happens if the AI writes something other than "Plan" or "Code" as the first word (e.g., "Both" or "Hybrid").

Proposed content to add to the build spec's Deliverable Type Parsing section:

> If the first word of the Deliverable Type section is neither "Plan" nor "Code" (case-insensitive), the orchestrator sets `deliverable_type` to `null` and does not advance to Phase 2. The human is notified in chat: "Could not determine deliverable type from intent. Please correct the Deliverable Type section to start with 'Plan' or 'Code'."

And add to Execution Plan Task 11 description:

> Include deliverable type parse failure handling: reject values other than "Plan" or "Code", notify human in chat, do not advance.

---

**[Minor] Design Spec — No specification for how the Settings UI handles prompt files that are added or deleted outside the editor**

The design spec (line 542) says "New prompts added to this directory are automatically picked up by the Settings UI." The build spec (line 29) confirms this. But there is no specification for what the Settings UI does if a prompt file is deleted from the filesystem while the editor is open, or if the user opens a file that no longer exists. This is a basic file-system-backed editor scenario that the builder will need to decide.

Proposed content to add to the Prompt Management section of the design spec:

> **Prompt file list refresh:** The Settings UI reads the `/prompts/` directory listing each time it is opened. If a prompt file is deleted externally while the editor is open, saving to the deleted file creates it anew (same atomic write behavior). No file locking — the single-operator model makes this acceptable.

---

**[Minor] Execution Plan — Task 25 (OSS discovery) has no corresponding unit test task**

Build Stage 8 has no test task for the OSS qualification scorecard (`discovery.js`). The scorecard has 8 signals, a minimum qualification threshold, and red flag logic — this warrants unit testing.

Proposed task to add to Build Stage 8:

> | 58m | Unit tests: OSS discovery scorecard (8-signal evaluation, red flag detection on Age/Last Updated/License, minimum 6-of-8 qualification threshold, handles missing signal data gracefully) | — | Task 25 | — | Not Started |

---

## 3. Build Spec Material That Should Be Extracted

**[Minor] Design Spec — Levenshtein similarity threshold and rotation percentage (line 318)**

The stagnation guard description in the design spec table includes:
> "rotation threshold and similarity measure defined in build spec"

But the build spec (lines 302-305) is where the actual values live — 70% rotation threshold, Levenshtein similarity ≥ 0.8. The design spec should reference the build spec without restating algorithmic parameters. Currently the design spec doesn't restate the values, so this is correct. **No action needed** — this entry is noted and dismissed.

---

**[Minor] Design Spec — WebSocket reconnection parameters reference (line 536)**

Current text:
> "Reconnection parameters (backoff strategy, timing) are in the build spec."

This is correct delegation — the design spec properly defers the parameters. The build spec (lines 523-528) contains the values. **No action needed.**

---

**[Major] Design Spec — Operation Type Taxonomy detail level (line 387)**

Current text:
> "**Operation Taxonomy:** The orchestrator classifies every Phase 3/4 action into an operation type before invoking the plugin's `validate()`. The complete operation type list and the mapping from orchestrator actions to operation types are defined in the build spec."

This is correctly delegated to the build spec. However, the build spec (lines 212-224) contains the full taxonomy table with operation types, descriptions, and example actions. This is properly placed. **No action needed.**

---

**[Minor] Design Spec — Agent invocation shell safety detail (Design Spec line 474 cross-referencing Build Spec line 361)**

The design spec says:
> "ThoughtForge invokes agents via CLI subprocess calls, passing prompts via file or stdin. Agent-specific adapters normalize output format differences. Invocation details in build spec."

The build spec (lines 361-362) adds:
> "**Shell safety:** Prompt content is passed to agent subprocesses via file descriptor or stdin pipe — never through shell argument expansion or interpolation. The agent invocation layer must not use shell string concatenation for prompt content."

The shell safety constraint is a design-level security decision (preventing command injection from user brain dumps), not just an implementation detail. It should be stated in the design spec's Agent Communication section, not only in the build spec.

Proposed addition to Design Spec Agent Communication section (after line 474):

> **Shell safety:** Prompt content is passed via stdin pipe or file — never through shell argument expansion. This prevents shell metacharacters in brain dump text or resource files from causing accidental command execution.

And in the build spec, the existing shell safety text can remain as the implementation-level reinforcement.

---

That concludes the review. Three lists, findings sorted by severity within each list.
