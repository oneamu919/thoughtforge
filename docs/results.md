Now I have all four documents. Let me produce the review.

---

# Plan Review — ThoughtForge Design Specification, Build Spec, and Execution Plan

---

## 1. Writing That's Unclear

**[Minor]** Design Specification, Phase 4, Stagnation Guard (line 299):

> "Same total error count for 3+ consecutive iterations AND issue rotation detected — fewer than 70% of current issues match issues from the immediately prior iteration by description similarity."

The phrase "issue rotation detected" is defined inline but the term "rotation" is non-standard and counterintuitive — "rotation" sounds like issues are cycling, but the guard is really detecting that issues are being *replaced* while the total count stays flat. A builder reading this will have to re-read it to understand the intent.

**Replacement:**
> "Same total error count for 3+ consecutive iterations AND issue replacement detected — fewer than 70% of current issues have a matching issue in the immediately prior iteration by description similarity. This indicates the reviewer is finding new issues to replace resolved ones, producing a plateau rather than genuine progress."

---

**[Minor]** Design Specification, Phase 4, Fabrication Guard (line 300):

> "A severity category spikes significantly above its trailing 3-iteration average, AND the system had previously reached within 2× of convergence thresholds in at least one prior iteration — suggesting the reviewer is manufacturing issues because nothing real remains"

The phrase "within 2× of convergence thresholds" is ambiguous. Does it mean the counts were at most 2× the threshold values? The build spec (line 312) clarifies this as "≤0 critical, ≤6 medium, ≤10 minor" but the design spec should be self-consistent.

**Replacement:**
> "A severity category spikes significantly above its trailing 3-iteration average, AND the system had previously reached counts within 2× of the termination thresholds (i.e., critical ≤ 0, medium ≤ 6, minor ≤ 10) in at least one prior iteration — suggesting the reviewer is manufacturing issues because nothing real remains"

---

**[Minor]** Design Specification, Phase 1 step 3 (lines 79-80):

> "ThoughtForge pulls the content and saves it to `/resources/` as local files. Connectors are optional — if none are configured, this step is skipped."

Immediately followed by a "Connector URL identification" paragraph that is dense and reads as a continuation of step 3 but is formatted as a separate block. It's unclear whether this is still part of step 3 or a standalone specification element.

**Replacement:** Indent the "Connector URL identification" paragraph under step 3, or prefix it explicitly:

> **Step 3 Detail — Connector URL Identification:** The AI identifies connector URLs in chat messages by matching against known URL patterns...

---

**[Minor]** Design Specification, Locked File Behavior (line 147):

> "If the file is readable but has modified structure, ThoughtForge passes it to the AI reviewer without structural validation. The reviewer processes whatever content it receives — no special handling is required for structural variations."

The term "modified structure" is vague. Does this mean missing sections, reordered sections, or completely different content? A builder might wonder whether to validate headings.

**Replacement:**
> "If the file is readable but has been restructured by the human (missing sections, reordered content, added sections), ThoughtForge passes it to the AI reviewer as-is without validating that it matches the original `constraints.md` schema. The reviewer processes whatever content it receives."

---

**[Minor]** Execution Plan, Build Stage 1, cross-stage dependency note (line 42):

> "Agent Layer (Build Stage 7, Tasks 41–44) provides the core agent invocation mechanism used by Stages 2–6. Task 41 depends on Task 1 (foundation), so Build Stage 7 should begin as soon as Task 1 completes, overlapping with the remainder of Build Stage 1."

The phrase "overlapping with the remainder of Build Stage 1" is imprecise. It should state which Stage 1 tasks can proceed in parallel and which must wait.

**Replacement:**
> "Agent Layer (Build Stage 7, Tasks 41–44) provides the core agent invocation mechanism used by Stages 2–6. Task 41 depends only on Task 1 (foundation), so Build Stage 7 should begin as soon as Task 1 completes. Stage 1 Tasks 2–6e and Stage 7 Tasks 41–44 can proceed in parallel. Any task that invokes an AI agent (Tasks 8, 12, 15, 21, 30) must wait for Tasks 41–42 to complete."

---

**[Minor]** Design Specification, Server Restart Behavior (line 404):

> "Projects in autonomous states (`distilling`, `building`, `polishing`) — where the AI was actively processing without human interaction — are set to `halted` with `halt_reason: "server_restart"` and the human is notified."

The `halt_reason` value `"server_restart"` is documented in the `status.json` schema in the build spec but not listed in the design spec's narrative. This is consistent but the design spec doesn't explain *why* these projects are halted rather than auto-resumed. A builder might question this decision.

**Replacement:**
> "Projects in autonomous states (`distilling`, `building`, `polishing`) are set to `halted` with `halt_reason: "server_restart"`. These are not auto-resumed because the server cannot safely re-enter a mid-execution agent invocation or polish iteration — the prior subprocess is dead and its partial output is unknown. The human must explicitly resume."

---

## 2. Genuinely Missing Plan-Level Content

**[Major]** No security model for the web chat interface.

The design spec specifies `server.host: "127.0.0.1"` as the default bind address (localhost only), which implies a single-operator local tool with no authentication. However, the config allows changing this to `"0.0.0.0"` for network access (build spec line 722). If the operator binds to a network interface, the chat interface is fully open — anyone on the network can create projects, trigger agent invocations, drop files, and terminate projects. The plan has no mention of authentication, CORS, or access control even at the plan level.

**Proposed content to add** (Design Specification, under Technical Design → ThoughtForge Stack, after the Server entry):

> **Access Control:** When bound to localhost (`127.0.0.1`), no authentication is required — only the local operator can access the interface. If the operator changes the bind address to allow network access (`0.0.0.0` or a specific network interface), a warning is logged at startup: "Server bound to network interface. No authentication is configured — any network client can access ThoughtForge." Authentication and access control are deferred — not a current build dependency. The operator assumes responsibility for network security when binding to non-localhost addresses.

---

**[Major]** No error handling for connector URL identification in chat (Phase 1 step 3).

The design spec describes URL pattern matching (line 80) but doesn't address what happens when a URL matches a connector pattern but the connector is *enabled* and authentication fails mid-conversation (as opposed to at startup). The Phase 1 error handling table covers "Connector authentication failure" and "Connector target not found" but doesn't specify what happens to the *chat flow* — does the Distill button remain available? Does the human need to re-click Distill after a connector failure?

This is already partially addressed: "proceed with distillation using available inputs" in the error handling table. But the interaction with the Distill button is ambiguous. If the human clicks Distill and a connector fails, does the distillation still proceed automatically, or does it wait for human re-confirmation?

**Proposed content to add** (Design Specification, Phase 1 Error Handling table, as a clarifying note below the table):

> **Connector failure during distillation:** If a connector fails after the human clicks Distill, the distillation proceeds automatically using all successfully retrieved inputs. The human is notified of the connector failure in chat but does not need to re-click Distill. The failed connector resources are simply absent from the distillation context.

---

**[Minor]** No plan-level statement about browser compatibility requirements for the chat UI.

The design specifies "Server-rendered HTML + vanilla JavaScript" (line 388) but doesn't state minimum browser requirements. A builder will need to decide whether to use modern JS features (ES modules, `fetch`, WebSocket) or polyfill for older browsers.

**Proposed content to add** (Design Specification, under UI → ThoughtForge Chat):

> **Browser Compatibility:** The chat interface targets modern evergreen browsers (Chrome, Firefox, Edge, Safari — current and previous major version). No IE11 or legacy browser support. ES6+ JavaScript features and native WebSocket API are assumed available.

---

**[Minor]** No specification for how the Settings/prompt editor handles concurrent edits.

If the operator has two browser tabs open and edits the same prompt file in both, the last save wins with no warning. For a single-operator tool this is acceptable, but it should be stated explicitly.

**Proposed content to add** (Design Specification, under UI → Prompt Management):

> **Concurrent edit handling:** The prompt editor uses a last-write-wins model with no conflict detection. Since this is a single-operator tool, concurrent tab edits are the operator's responsibility.

---

**[Minor]** No mention of log rotation or size management for `thoughtforge.log`.

The operational log (design spec line 399) writes structured JSON lines continuously. Over many projects and iterations, this file will grow unbounded. For a v1 single-operator tool this is acceptable, but it should be explicitly acknowledged alongside the existing disk management statement.

**Proposed content to add** (Design Specification, under Functional Design → Phase 1 → Disk management paragraph, append):

> Operational logs (`thoughtforge.log`) also accumulate without rotation or size limits in v1. The operator is responsible for manual log management. Automated log rotation is deferred — not a current build dependency.

---

## 3. Build Spec Material That Should Be Extracted

**[Minor]** Design Specification, Phase 1 step 9 (line 90):

> "Implementation algorithm in build spec."

This is fine — it correctly points to the build spec. However, the design spec also contains this paragraph in Phase 1:

> "Human can type 'realign from here' in chat. The AI resets to the most recent substantive correction, excluding subsequent conversation from the working context (retained in `chat_history.json` for audit trail), and re-distills from the original brain dump plus all corrections up to that point."

This is plan-level behavior description and belongs here. **No extraction needed.** The build spec's Realign Algorithm section correctly contains the step-by-step implementation algorithm. This pairing is appropriate.

---

**[Minor]** Design Specification, Phase 4, Stagnation Guard (line 299):

> "Levenshtein similarity ≥ 0.8 on the `description` field"

This algorithmic parameter (Levenshtein threshold) appears in the design spec. The design spec says "Algorithmic parameters... are defined in the build spec" and the build spec does repeat these. However, the Levenshtein threshold value appears in *both* documents. This creates a dual-source-of-truth risk — if one is updated and the other isn't, a builder will be confused about which is authoritative.

**Recommendation:** Remove the specific threshold value from the design spec and leave only the behavioral description. Replace the design spec text with:

> "fewer than 70% of current issues match issues from the immediately prior iteration by description similarity (match threshold defined in build spec)"

The build spec (line 303-304) already has the full specification: "Levenshtein similarity ≥ 0.8 on the `description` field."

---

**[Minor]** Design Specification, Convergence Guards table (lines 295-301):

The design spec includes specific numeric thresholds inline: ">20% spike", "70% match", "50% category spike", "2× convergence thresholds", "3 consecutive iterations". These are all repeated in the build spec's Convergence Guard Parameters section with more precise definitions. The design spec acknowledges this: "Algorithmic parameters... defined in the build spec."

However, having the same numbers in both documents creates maintenance risk. Since the design spec explicitly states that algorithmic parameters belong in the build spec, the design spec should describe *behavior* and the build spec should own *values*.

**Recommendation:** In the design spec's Convergence Guards table, replace specific threshold numbers with behavioral descriptions and reference the build spec for exact values. For example, the Hallucination guard:

Current: "Error count increases significantly (threshold defined in build spec) after a consecutive downward trend (minimum trend length defined in build spec)"

This is already correctly written — it doesn't include the 20% number. The Stagnation and Fabrication guards should follow the same pattern. Replace:

- "Same total error count for 3+ consecutive iterations" → "Same total error count for consecutive iterations exceeding the configured stagnation limit"
- "fewer than 70% of current issues match" → "issue replacement detected (rotation threshold and similarity measure defined in build spec)"
- "trailing 3-iteration average" and "within 2× of convergence thresholds" → "trailing average (window size defined in build spec)" and "within a multiplier of convergence thresholds (multiplier defined in build spec)"

---

**[Minor]** Build Spec, `config.yaml` template (lines 633-724):

The `config.yaml` template is correctly in the build spec. However, the Design Specification's Configuration table (lines 573-584) duplicates several default values (e.g., "Max parallel runs: 3", "ntfy enabled, topic 'thoughtforge'", "claude, 300s"). These default values are implementation details and should be owned by the build spec's `config.yaml` template alone.

**Recommendation:** In the design spec's Configuration table, remove specific default values and replace with "See `config.yaml` template in build spec" for each row's Defaults column. Keep the "What's Configurable" column as-is — that's plan-level content describing *what* is tunable.

---

That concludes the review. Three lists, findings sorted by severity within each.
