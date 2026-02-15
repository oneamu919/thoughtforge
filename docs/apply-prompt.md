# Apply Review Findings — ThoughtForge

You are an AI coder. Apply every change listed below to the source files. Each change is a direct replacement, addition, or extraction. Do not interpret or improvise — apply exactly what is specified.

The review findings come from `docs/results.md`. The source files are:
- `docs/thoughtforge-design-specification.md` (referred to as "Design Spec")
- `docs/thoughtforge-build-spec.md` (referred to as "Build Spec")
- `docs/thoughtforge-execution-plan.md` (referred to as "Execution Plan")

Read all three source files before making changes so you have full context.

---

## Section 1: Unclear Writing — Replacements

### 1.1 [Major] Design Spec — Phase 4, Code Mode Iteration Cycle (~line 270)

**Find this text:**
> Code mode adds a test execution step to each iteration. The full cycle is: (1) Orchestrator runs tests via the code plugin's `test-runner.js` and captures results. (2) Review — orchestrator passes the test results as additional context to the reviewer AI alongside the codebase and `constraints.md`. Reviewer outputs JSON error report including test results. (3) Fix — orchestrator passes issue list to fixer agent. Git commit after fix.

**Replace with:**
> Code mode extends the two-step cycle with a test execution step at the beginning. The full Code mode cycle per iteration is: (1) **Test** — orchestrator runs tests via the code plugin's `test-runner.js` and captures results. (2) **Review** — orchestrator passes test results as additional context to the reviewer AI alongside the codebase and `constraints.md`. Reviewer outputs JSON error report. (3) **Fix** — orchestrator passes the issue list to the fixer agent. Git commit after fix. Plan mode uses the two-step cycle (Review → Fix) with no test execution. Both modes commit after the review step and after the fix step.

### 1.2 [Major] Design Spec — Phase 4, Code mode git commit timing (~line 266–270)

**Add this sentence at the end of the Code mode iteration cycle paragraph** (the paragraph you just replaced in 1.1):
> Code mode follows the same two-commits-per-iteration pattern: git commit after the review step (captures review JSON and test results) and git commit after the fix step (captures applied fixes).

### 1.3 [Major] Design Spec — Stagnation Guard (~line 278)

**Find this text:**
> Same total error count for 3+ consecutive iterations... AND issue rotation detected (specific issues change between iterations even though the total stays flat — the loop has reached the best quality achievable autonomously)

**Replace with:**
> Same total error count for 3+ consecutive iterations... AND issue churn detected (the specific issues change between iterations even though the total count stays flat — indicating the loop is replacing old issues with new ones at the same rate and has reached the best quality achievable autonomously)

### 1.4 [Minor] Design Spec — Phase 1, step 3 (~line 80)

**Find this text:**
> the human provides page URLs or document links via chat.

**Replace with:**
> the human provides page URLs or document links via chat, or the URLs are pre-configured in `config.yaml` (e.g., default Notion pages that should be pulled for every project).

If config-based URLs are NOT actually a supported feature, then instead go to the Inputs table (~line 35–36) and remove "or config" from the connector URL source. Pick whichever option is consistent with the design intent.

### 1.5 [Minor] Design Spec — Fabrication Guard (~line 279)

**Find this text:**
> A severity category spikes well above its recent average

**Replace with:**
> A severity category spikes significantly above its trailing 3-iteration average (e.g., >50% increase)

### 1.6 [Minor] Design Spec — Manual Edit Behavior (~line 153)

**Find this text:**
> `spec.md` and `intent.md` are read at Phase 3 start and not re-read — manual edits to these files after their respective phases require restarting from that phase (not currently supported; project must be recreated).

**Replace with:**
> `spec.md` and `intent.md` are read once at Phase 3 start and not re-read during later phases. If the human manually edits these files after their creation phase, the only way to pick up those changes is to create a new project — there is no "restart from Phase N" capability in v1.

### 1.7 [Minor] Execution Plan — Build Stage 6, Task 30 (~line 106)

**Find this text:**
> Includes count derivation from issues array (Task 32), polish state persistence + crash recovery (Task 38), and polish log append (Task 39) as integral orchestrator responsibilities — these tasks extend Task 30, not replace it

**Replace with:**
> Count derivation (Task 32), polish state persistence + crash recovery (Task 38), and polish log append (Task 39) are implemented as part of the polish loop orchestrator module — they are listed as separate tasks for tracking but are coded within the orchestrator, not as separate modules.

### 1.8 [Minor] Design Spec — Confirmation model paragraph (~line 92)

**Find this text:**
> Both use explicit button presses to eliminate misclassification.

**Replace with:**
> Both use explicit button presses to eliminate the risk of the AI misinterpreting a chat message as a phase advancement command.

---

## Section 2: Missing Content — Additions

### 2.1 [Major] Design Spec — WebSocket Disconnection Behavior

**Location:** Add to the UI section, after the "Per-project chat thread" paragraph.

**Add this content:**
> **WebSocket Disconnection:** If the WebSocket connection drops, the chat client automatically attempts to reconnect. On reconnect, the client fetches the current project state from `status.json` and the latest chat messages from `chat_history.json` to restore the UI to the correct state. In-flight AI responses that were streaming when the connection dropped are not replayed — the human sees the last fully-received message and can re-trigger the action (e.g., click Distill again) if the operation did not complete. Pipeline processing continues server-side regardless of client connection state.

### 2.2 [Major] Design Spec — Resource File Processing

**Location:** Add to Phase 1, after step 5 (or alternatively add to Build Spec as implementation reference — choose one location).

**Add this content:**
> **Resource File Processing:**
> | Format | Processing Method |
> |---|---|
> | `.md`, `.txt`, code files | Read as plain text, passed to AI as context |
> | `.pdf` | Text extracted via PDF parsing library (e.g., `pdf-parse`). If extraction yields no text (scanned PDF), log a warning and skip the file. OCR is deferred. |
> | Images (`.png`, `.jpg`, `.gif`) | Passed to the AI agent's vision capability if the configured agent supports it. If not, log a warning and skip. |
> | Unsupported formats | Logged as unreadable per Phase 1 error handling |

### 2.3 [Major] Design Spec — Concurrency Model

**Location:** Add to the Project State Files section.

**Add this content:**
> **Concurrency Model:** Each project operates on its own isolated directory and state files. No cross-project state sharing exists. Within a single project, the pipeline is single-threaded — only one operation (phase transition, polish iteration, button action) executes at a time. The orchestrator serializes operations per project. Concurrent access to a single project's state files is not supported and does not need locking.

### 2.4 [Minor] Design Spec — Template Content Escaping

**Location:** Add to Phase 3 Plan Mode section (or Build Spec).

**Add this content:**
> **Template Content Escaping:** AI-generated content inserted into Handlebars template slots is escaped to prevent Handlebars syntax characters in plan text (e.g., literal `{{` or `}}`) from causing render failures. The plan builder escapes content before template rendering.

### 2.5 [Minor] Design Spec — Project Status on Return

**Location:** Add to the UI section.

**Add this content:**
> **Project Status on Return:** The project list sidebar shows each project's current phase and status (including halted indicator). When the human opens a project's chat thread, the most recent messages and any pending action buttons (e.g., halt recovery options) are displayed. No separate "catch-up" summary is generated — the chat history and project status serve this purpose.

### 2.6 [Minor] Execution Plan — Testing Strategy Statement

**Location:** Add before the Build Stage 8 task table.

**Add this content:**
> **Testing Strategy:** Unit tests (Tasks 45–50b) use mocked dependencies — no real agent CLI calls, no real file system for state tests, no real API calls for connectors. E2e tests (Tasks 51–57) run the full pipeline with real agent invocations against a test project. Synthetic convergence guard tests (Task 54) use fabricated `polish_state.json` data, not real polish loop runs.

---

## Section 3: Extractions — Move from Design Spec to Build Spec

For each extraction: remove the detailed content from the Design Spec and add a one-line reference pointing to the Build Spec. Then add the removed content to the appropriate section of the Build Spec.

### 3.1 [Minor] Action Button Behavior Table (~lines 96–109 in Design Spec)

**In Design Spec:** Remove the full Action Button Behavior table (the one specifying exact `status.json` field updates, button disabled states, spinner behaviors, and confirmation dialog text). Replace with:
> Complete button inventory with `status.json` effects and UI behavior is specified in the build spec.

**In Build Spec:** Add the removed table to the UI / button behavior section. If no such section exists, create a subsection titled "Action Button Behavior" and paste the table there.

### 3.2 [Minor] Phase-to-State Mapping Table (~lines 122–131 in Design Spec)

**In Design Spec:** Remove the Phase-to-State Mapping table (the one mapping pipeline phases to exact `status.json` string enum values and transitions). Replace with:
> Phase-to-state enum mapping and transition triggers are defined in the build spec's `status.json` schema.

**In Build Spec:** Merge the removed table into the existing `status.json` schema section. If the build spec already has equivalent content, ensure no information is lost and remove any duplicates.

### 3.3 [Minor] Connector and Notification URL Validation Table (~lines 543–551 in Design Spec)

**In Design Spec:** Remove the detailed validation table (exact error message strings, startup-vs-runtime timing, Zod validation approach). Replace with:
> URL validation policy: validate connector and notification URLs at startup for configuration errors; handle failures gracefully at runtime. Implementation details are in the build spec.

**In Build Spec:** Confirm the existing "Connector and Notification URL Validation" section (~lines 609–621) covers all information from the removed Design Spec table. If any details were in the Design Spec table but not in the Build Spec section, add them.

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
