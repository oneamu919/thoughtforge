I've read all four files. Now let me do a thorough review of the three scrutiny documents against the requirements brief and standard engineering practices.

---

# Project Plan Review ΓÇö ThoughtForge Pipeline Tool

Reviewing: `thoughtforge-design-specification.md`, `thoughtforge-build-spec.md`, `thoughtforge-execution-plan.md`

---

## 1. Writing That's Unclear ΓÇö With Exact Replacement Text

**[Minor]** Design Spec, Phase 4, Stagnation Guard (line 270):

> Same total error count for 3+ consecutive iterations... AND issue churn detected (the specific issues change between iterations even though the total count stays flat ΓÇö indicating the loop is replacing old issues with new ones at the same rate and has reached the best quality achievable autonomously)

The ellipsis and parenthetical embedding makes this read like a draft note, not a spec definition. Replace with:

> Same total error count for 3+ consecutive iterations AND issue rotation detected ΓÇö the specific issues change between iterations while the total count stays flat. This indicates the loop is replacing old issues with new ones at the same rate and has reached the best quality achievable autonomously.

---

**[Minor]** Design Spec, Phase 1 step 9, "realign from here" (line 96):

> Human can type "realign from here" as a chat message. The AI identifies the human's most recent substantive correction ΓÇö defined as the last human message that is not a "realign from here" command. All messages after that correction (both AI and human) are excluded from the working context but remain in chat_history.json for audit purposes. The AI re-distills from the original brain dump plus all human corrections up to and including that baseline message. Does not restart from the original brain dump alone. If no human corrections exist yet (i.e., "realign from here" is sent before any corrections), the command is ignored and the AI responds asking the human to provide a correction first.

This is a single run-on paragraph covering five distinct behaviors. Replace with:

> Human can type "realign from here" as a chat message. The behavior is:
>
> 1. **Baseline identification:** The AI identifies the human's most recent substantive correction ΓÇö defined as the last human message that is not a "realign from here" command.
> 2. **Context truncation:** All messages after that correction (both AI and human) are excluded from the working context but remain in `chat_history.json` for audit purposes.
> 3. **Re-distillation:** The AI re-distills from the original brain dump plus all human corrections up to and including that baseline message. It does not restart from the original brain dump alone.
> 4. **No-correction guard:** If no human corrections exist yet (i.e., "realign from here" is sent before any corrections), the command is ignored and the AI responds asking the human to provide a correction first.

---

**[Minor]** Design Spec, Manual Edit Behavior (line 142):

> "Locked" means the AI pipeline will not modify these files after their creation phase. However, the pipeline re-reads `constraints.md` at the start of each Phase 4 iteration, so manual human edits to acceptance criteria or review rules are picked up automatically. `spec.md` and `intent.md` are read once at Phase 3 start and not re-read during later phases. If the human manually edits these files after their creation phase, the only way to pick up those changes is to create a new project ΓÇö there is no "restart from Phase N" capability in v1. The pipeline does not detect or warn about manual edits.

This conflates two different behaviors (constraints.md is hot-reloaded, spec.md/intent.md are not) in one paragraph without clear delineation. Replace with:

> "Locked" means the AI pipeline will not modify these files after their creation phase.
>
> **`constraints.md` (hot-reloaded):** The pipeline re-reads `constraints.md` at the start of each Phase 4 iteration, so manual human edits to acceptance criteria or review rules are picked up automatically.
>
> **`spec.md` and `intent.md` (static after creation):** These are read once at Phase 3 start and not re-read during later phases. If the human manually edits these files after their creation phase, the only way to pick up those changes is to create a new project ΓÇö there is no "restart from Phase N" capability in v1. The pipeline does not detect or warn about manual edits to any locked file.

---

**[Minor]** Design Spec, WebSocket Disconnection (line 465):

> In-flight AI responses that were streaming when the connection dropped are not replayed ΓÇö the human sees the last fully-received message and can re-trigger the action (e.g., click Distill again) if the operation did not complete.

"If the operation did not complete" is ambiguous ΓÇö complete server-side or complete client-side? Replace with:

> In-flight AI responses that were streaming when the connection dropped are not replayed ΓÇö the human sees the last fully-received message. If the server-side operation completed during the disconnect, the reconnect state sync picks up the updated `status.json` and chat history. If the operation did not complete server-side, the human can re-trigger the action (e.g., click Distill again).

---

**[Major]** Design Spec, Phase 4, Code Mode Iteration Cycle (line 262):

> Code mode follows the same two-commits-per-iteration pattern: git commit after the review step (captures review JSON and test results) and git commit after the fix step (captures applied fixes).

This sentence says the review step commit "captures review JSON and test results" but the review JSON is an AI output ΓÇö it's unclear where the review JSON file is written or what its filename is. The design spec mentions `polish_log.md` (human-readable) and `polish_state.json` (machine state), but neither of those is the review JSON itself. Replace with:

> Code mode follows the same two-commits-per-iteration pattern: git commit after the review step (captures any review artifacts and test results) and git commit after the fix step (captures applied fixes). The review JSON output is persisted as part of the `polish_state.json` update and the `polish_log.md` append that occur at each iteration boundary ΓÇö it is not written as a separate file.

If the intention is for the review JSON to be written as a separate file, add it to the Outputs table and specify the filename and path.

---

**[Minor]** Execution Plan, Task 30 description (line 106):

> Count derivation (Task 32), polish state persistence + crash recovery (Task 38), and polish log append (Task 39) are implemented as part of the polish loop orchestrator module ΓÇö they are listed as separate tasks for tracking but are coded within the orchestrator, not as separate modules.

This is a parenthetical about project management methodology embedded in a task description. Replace with a note row after the task table:

> **Note:** Tasks 32, 38, and 39 are implemented within the Task 30 orchestrator module, not as separate files. They are listed separately for progress tracking.

---

**[Minor]** Design Spec, Stuck Detection table (line 211):

> AI returns a JSON response. The orchestrator parses this JSON to detect stuck status. Response schema (`PlanBuilderResponse`) defined in build spec.

This describes Plan mode stuck detection as "AI returns a JSON response" but doesn't state what triggers the AI to signal stuck versus not-stuck. The Code mode column is clear (non-zero exit after 2 retries, or 3 identical test failures). Replace Plan mode column with:

> AI includes a `stuck: boolean` flag in every response (per `PlanBuilderResponse` schema in build spec). When `stuck` is `true`, the `reason` field describes what decision is needed. The orchestrator checks this flag after every builder response.

---

## 2. Genuinely Missing Plan-Level Content ΓÇö With Proposed Content to Add

**[Critical]** Missing: `intent.md` template/structure definition.

The design spec specifies exact structures for `spec.md` and `constraints.md`, and the build spec provides their Markdown templates. But `intent.md` ΓÇö the first and most foundational document in the pipeline ΓÇö has no defined structure. The design spec says it contains "Deliverable Type, Objective, Assumptions, Constraints, Unknowns, Open Questions" (line 93) and that the project name comes from its H1 heading (line 74), but there is no structural definition matching the level of detail given to the other documents.

**Proposed addition to the build spec** (after the `constraints.md` structure section):

```
## `intent.md` Structure

**Used by:** Task 11 (intent.md generation and locking)
**Written:** End of Phase 1, locked after write

### Template

    # {Project Name}

    ## Deliverable Type
    {Plan or Code, with reasoning}

    ## Objective
    {What the human wants to exist when this is done}

    ## Assumptions
    {What the human seems to believe is true, both stated and inferred}

    ## Constraints
    {Limitations: OS, language, tools, budget, timeline, etc.}

    ## Unknowns
    {Gaps that need to be decided before building}

    ## Open Questions
    {Up to 5 questions the AI couldn't resolve from the brain dump, prioritized by blocking impact}
```

---

**[Major]** Missing: How the Plan Completeness Gate accesses the plan document in Code mode.

The design spec says (line 305): "When a Code mode pipeline starts and a plan document is detected in `/resources/`..." But it doesn't specify how the system identifies which file in `/resources/` is the plan document versus other resource files. If the human drops a plan plus three reference PDFs into `/resources/`, how does the system know which one to evaluate?

**Proposed addition to Design Spec, Plan Completeness Gate section:**

> **Plan document identification:** The gate scans `/resources/` for `.md` files. If exactly one `.md` file is present, it is treated as the plan document. If multiple `.md` files are present, the gate evaluates each and uses the first that appears to be a structured plan (contains OPA table structure or section headings matching the plan template pattern). If no `.md` files are present, the gate is skipped ΓÇö Code mode proceeds without plan evaluation.

---

**[Major]** Missing: WebSocket reconnection strategy specifics.

The design spec says "the chat client automatically attempts to reconnect" (line 465) but doesn't specify the reconnection behavior at a plan level ΓÇö immediate retry, backoff, max attempts, or how the user is informed of disconnection state.

**Proposed addition to Design Spec, WebSocket Disconnection section:**

> **Reconnection behavior:** The client uses exponential backoff starting at 1 second, capped at 30 seconds, with no maximum retry limit. During disconnection, the chat UI displays a visible "Reconnecting..." indicator. On successful reconnect, the indicator is removed and state is synced from the server.

---

**[Major]** Missing: Concurrency enforcement mechanism.

The design spec states `max_parallel_runs: 3` is configurable (line 80) and the execution plan tests parallel execution (Task 56), but neither document specifies how the concurrency limit is enforced. When a fourth project is started while three are running, what happens? Is it queued? Rejected? Does Vibe Kanban enforce this, or does ThoughtForge?

**Proposed addition to Design Spec, Concurrency Model subsection:**

> **Concurrency limit enforcement:** When the number of active projects (status not `done` or `halted`) reaches `config.yaml` `concurrency.max_parallel_runs`, new project creation is blocked. The chat interface disables the "New Project" action and displays a message: "Maximum parallel projects reached ({N}/{N}). Complete or halt an existing project to start a new one." Enforcement is at the ThoughtForge orchestrator level, not delegated to Vibe Kanban.

---

**[Minor]** Missing: Execution Plan has no task for Handlebars template content escaping.

The design spec says (line 191): "The plan builder escapes content before template rendering." This is a specific implementation requirement but has no corresponding task in the execution plan. It could be subsumed under Task 15, but given that it's a distinct defensive behavior that prevents rendering failures, it warrants explicit mention.

**Proposed addition:** Add to Task 15 description in the Execution Plan:

> Implement `builder.js` ΓÇö Handlebars template-driven document drafting, **including content escaping for Handlebars syntax characters in AI-generated content,** including template rendering failure handling (halt immediately, no retry)

---

**[Minor]** Missing: Execution Plan has no task for WebSocket reconnection and state recovery.

The design spec defines reconnection behavior (line 465) but no execution plan task covers implementing it. The closest is Task 7 (web chat interface) but its description says "core chat panel with per-project thread, AI message streaming via WebSocket" ΓÇö no mention of disconnect handling or state recovery.

**Proposed addition:** Add to Task 7 description:

> Build ThoughtForge web chat interface: core chat panel with per-project thread, AI message streaming via WebSocket, messages labeled by phase, **WebSocket disconnection handling with auto-reconnect and state recovery from `status.json` and `chat_history.json`**

---

**[Minor]** Missing: What happens when git operations fail during Phase 4.

The Phase 4 error handling table covers "File system error during git commit after fix" (halt and notify), but doesn't address git commit failure after the review step. Since the design calls for two commits per iteration, the review-step commit failure case is unaddressed.

**Proposed addition to Design Spec, Phase 4 Error Handling table:**

| Condition | Action |
|---|---|
| Git commit failure after review step | Halt and notify human immediately. The review JSON is preserved in memory for the current iteration. `polish_state.json` for the current iteration is not written. On resume, the review step is re-attempted from the beginning. |

---

## 3. Build Spec Material That Should Be Extracted ΓÇö Identify Each Section and Why

**[Minor]** Design Spec, Phase 1, Resource File Processing table (lines 86ΓÇô91).

This table specifies implementation-level file format handling (`pdf-parse` library, OCR deferred, vision capability detection). The plan-level content is: "Resources are processed by format ΓÇö text read directly, PDFs extracted, images via AI vision if supported, unsupported formats logged and skipped." The library recommendations and capability-detection logic belong in the build spec.

---

**[Minor]** Design Spec, Stagnation Guard, Issue Rotation Detection details (lines 284ΓÇô285 of the build spec).

The build spec already has the full algorithmic parameters. However, the design spec (line 270) also embeds the parenthetical "(i.e., for each current issue, check if any prior issue has Levenshtein similarity ΓëÑ 0.8 on the `description` field ΓÇö if fewer than 70% of current issues find a match, rotation is detected)" ΓÇö wait, that's in the build spec, not the design spec. On re-check, the design spec only says "issue churn detected." The build spec has the detail. This is correctly placed. **Retracted ΓÇö no extraction needed.**

---

**[Minor]** Design Spec, Template Content Escaping (line 191):

> AI-generated content inserted into Handlebars template slots is escaped to prevent Handlebars syntax characters in plan text (e.g., literal `{{` or `}}`) from causing render failures. The plan builder escapes content before template rendering.

This is implementation detail about string escaping during template rendering. The plan-level content is the requirement: "AI-generated content must not break template rendering." The how (escape before rendering, which characters) belongs in the build spec. Move to build spec under the Plan builder section.

---

**[Minor]** Design Spec, Operational Logging component in Stack table (line 365):

> Structured JSON logger (custom, using Node.js `fs` for file append)

The technology choice ("custom, using Node.js `fs` for file append") is build-level detail. The plan-level entry should be: "Structured JSON logger ΓÇö per-project operational log for debugging." The implementation approach belongs in the build spec.

---

That concludes the review. Three lists, findings sorted by severity within each.
