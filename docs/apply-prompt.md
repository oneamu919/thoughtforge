Read `results.md` in this directory, then apply every change listed below to the source files. Each change is a direct replacement, addition, or extraction. Do not interpret or improvise — apply exactly what is specified.

Source files (all in `docs/`):
- `docs/thoughtforge-design-specification.md` (referred to as "Design Spec")
- `docs/thoughtforge-build-spec.md` (referred to as "Build Spec")
- `docs/thoughtforge-execution-plan.md` (referred to as "Execution Plan")

Read all three source files before making changes so you have full context.

---

## Section 1: Unclear Writing — Replacements

### 1.1 [Minor] Design Spec — Phase 4 Stagnation Guard

**Find this text:**
> Same total error count for 3+ consecutive iterations... AND issue churn detected (the specific issues change between iterations even though the total count stays flat — indicating the loop is replacing old issues with new ones at the same rate and has reached the best quality achievable autonomously)

**Replace with:**
> Same total error count for 3+ consecutive iterations AND issue rotation detected — the specific issues change between iterations while the total count stays flat. This indicates the loop is replacing old issues with new ones at the same rate and has reached the best quality achievable autonomously.

### 1.2 [Minor] Design Spec — Phase 1 step 9, "realign from here"

**Find the paragraph that begins:**
> Human can type "realign from here" as a chat message. The AI identifies the human's most recent substantive correction

**Replace the entire paragraph with:**
> Human can type "realign from here" as a chat message. The behavior is:
>
> 1. **Baseline identification:** The AI identifies the human's most recent substantive correction — defined as the last human message that is not a "realign from here" command.
> 2. **Context truncation:** All messages after that correction (both AI and human) are excluded from the working context but remain in `chat_history.json` for audit purposes.
> 3. **Re-distillation:** The AI re-distills from the original brain dump plus all human corrections up to and including that baseline message. It does not restart from the original brain dump alone.
> 4. **No-correction guard:** If no human corrections exist yet (i.e., "realign from here" is sent before any corrections), the command is ignored and the AI responds asking the human to provide a correction first.

### 1.3 [Minor] Design Spec — Manual Edit Behavior (locked files)

**Find the paragraph that begins:**
> "Locked" means the AI pipeline will not modify these files after their creation phase. However, the pipeline re-reads

**Replace the entire paragraph with:**
> "Locked" means the AI pipeline will not modify these files after their creation phase.
>
> **`constraints.md` (hot-reloaded):** The pipeline re-reads `constraints.md` at the start of each Phase 4 iteration, so manual human edits to acceptance criteria or review rules are picked up automatically.
>
> **`spec.md` and `intent.md` (static after creation):** These are read once at Phase 3 start and not re-read during later phases. If the human manually edits these files after their creation phase, the only way to pick up those changes is to create a new project — there is no "restart from Phase N" capability in v1. The pipeline does not detect or warn about manual edits to any locked file.

### 1.4 [Minor] Design Spec — WebSocket Disconnection

**Find this text:**
> In-flight AI responses that were streaming when the connection dropped are not replayed — the human sees the last fully-received message and can re-trigger the action (e.g., click Distill again) if the operation did not complete.

**Replace with:**
> In-flight AI responses that were streaming when the connection dropped are not replayed — the human sees the last fully-received message. If the server-side operation completed during the disconnect, the reconnect state sync picks up the updated `status.json` and chat history. If the operation did not complete server-side, the human can re-trigger the action (e.g., click Distill again).

### 1.5 [Major] Design Spec — Phase 4 Code Mode Iteration Cycle

**Find this text:**
> Code mode follows the same two-commits-per-iteration pattern: git commit after the review step (captures review JSON and test results) and git commit after the fix step (captures applied fixes).

**Replace with:**
> Code mode follows the same two-commits-per-iteration pattern: git commit after the review step (captures any review artifacts and test results) and git commit after the fix step (captures applied fixes). The review JSON output is persisted as part of the `polish_state.json` update and the `polish_log.md` append that occur at each iteration boundary — it is not written as a separate file.

### 1.6 [Minor] Design Spec — Stuck Detection table, Plan mode column

**Find the Plan mode stuck detection text:**
> AI returns a JSON response. The orchestrator parses this JSON to detect stuck status. Response schema (`PlanBuilderResponse`) defined in build spec.

**Replace with:**
> AI includes a `stuck: boolean` flag in every response (per `PlanBuilderResponse` schema in build spec). When `stuck` is `true`, the `reason` field describes what decision is needed. The orchestrator checks this flag after every builder response.

### 1.7 [Minor] Execution Plan — Task 30 description

**Find this text in Task 30's description area:**
> Count derivation (Task 32), polish state persistence + crash recovery (Task 38), and polish log append (Task 39) are implemented as part of the polish loop orchestrator module — they are listed as separate tasks for tracking but are coded within the orchestrator, not as separate modules.

**Remove it from the task description. Add a standalone note after the task table (or after Task 30's row if inline notes are used):**
> **Note:** Tasks 32, 38, and 39 are implemented within the Task 30 orchestrator module, not as separate files. They are listed separately for progress tracking.

---

## Section 2: Missing Content — Additions

### 2.1 [Critical] Build Spec — Add `intent.md` structure definition

**Location:** After the `constraints.md` structure section in the build spec.

**Add this new section:**

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

### 2.2 [Major] Design Spec — Plan Completeness Gate: add plan document identification

**Location:** In the Plan Completeness Gate section, after the sentence about detecting a plan document in `/resources/`.

**Add this content:**
> **Plan document identification:** The gate scans `/resources/` for `.md` files. If exactly one `.md` file is present, it is treated as the plan document. If multiple `.md` files are present, the gate evaluates each and uses the first that appears to be a structured plan (contains OPA table structure or section headings matching the plan template pattern). If no `.md` files are present, the gate is skipped — Code mode proceeds without plan evaluation.

### 2.3 [Major] Design Spec — WebSocket Disconnection: add reconnection behavior

**Location:** In the WebSocket Disconnection section, after the replacement text from 1.4 above.

**Add this content:**
> **Reconnection behavior:** The client uses exponential backoff starting at 1 second, capped at 30 seconds, with no maximum retry limit. During disconnection, the chat UI displays a visible "Reconnecting..." indicator. On successful reconnect, the indicator is removed and state is synced from the server.

### 2.4 [Major] Design Spec — Concurrency limit enforcement

**Location:** Add near the configuration/concurrency area where `max_parallel_runs` is defined.

**Add this content:**
> **Concurrency limit enforcement:** When the number of active projects (status not `done` or `halted`) reaches `config.yaml` `concurrency.max_parallel_runs`, new project creation is blocked. The chat interface disables the "New Project" action and displays a message: "Maximum parallel projects reached ({N}/{N}). Complete or halt an existing project to start a new one." Enforcement is at the ThoughtForge orchestrator level, not delegated to Vibe Kanban.

### 2.5 [Minor] Execution Plan — Task 15: add Handlebars escaping mention

**Find Task 15's description** (about `builder.js` and Handlebars template-driven document drafting).

**Update the description to include:**
> **including content escaping for Handlebars syntax characters in AI-generated content,** including template rendering failure handling (halt immediately, no retry)

If the description already mentions "template rendering failure handling," integrate the escaping mention before it rather than duplicating.

### 2.6 [Minor] Execution Plan — Task 7: add WebSocket disconnect handling

**Find Task 7's description** (about web chat interface).

**Append to the description:**
> **WebSocket disconnection handling with auto-reconnect and state recovery from `status.json` and `chat_history.json`**

### 2.7 [Minor] Design Spec — Phase 4 Error Handling table: add review-step git commit failure

**Add this row to the Phase 4 error handling table:**

| Condition | Action |
|---|---|
| Git commit failure after review step | Halt and notify human immediately. The review JSON is preserved in memory for the current iteration. `polish_state.json` for the current iteration is not written. On resume, the review step is re-attempted from the beginning. |

---

## Section 3: Extractions — Move from Design Spec to Build Spec

### 3.1 [Minor] Design Spec — Phase 1 Resource File Processing table

**In Design Spec:** Find the table that specifies implementation-level file format handling (mentioning `pdf-parse` library, OCR deferred, vision capability detection). Replace the implementation details with plan-level language:
> Resources are processed by format — text read directly, PDFs extracted, images via AI vision if supported, unsupported formats logged and skipped.

**In Build Spec:** Move the removed implementation details (library names, capability-detection logic) to the resource processing section.

### 3.2 [Minor] Design Spec — Template Content Escaping

**In Design Spec, find this text:**
> AI-generated content inserted into Handlebars template slots is escaped to prevent Handlebars syntax characters in plan text (e.g., literal `{{` or `}}`) from causing render failures. The plan builder escapes content before template rendering.

**Replace with plan-level language:**
> AI-generated content must not break template rendering.

**In Build Spec:** Move the implementation detail (escaping approach, which characters) to the Plan builder section.

### 3.3 [Minor] Design Spec — Operational Logging in Stack table

**In Design Spec, find the entry:**
> Structured JSON logger (custom, using Node.js `fs` for file append)

**Replace with:**
> Structured JSON logger — per-project operational log for debugging

**In Build Spec:** Move the implementation detail ("custom, using Node.js `fs` for file append") to the logging section.

---

## After All Changes Are Applied

1. Re-read each modified file to confirm no formatting is broken (e.g., unclosed tables, orphaned headers).
2. Only `git add` files you actually modified:
   ```bash
   git add docs/thoughtforge-design-specification.md docs/thoughtforge-build-spec.md docs/thoughtforge-execution-plan.md
   ```
3. Commit with message: `Apply review findings`
4. Push to remote: `git push`
5. Confirm the push succeeded.
