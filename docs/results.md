Now I have a thorough understanding of all four documents. Let me produce the review.

---

# Project Plan Review ΓÇö ThoughtForge

Reviewing: `thoughtforge-design-specification.md`, `thoughtforge-build-spec.md`, `thoughtforge-execution-plan.md`

---

## 1. Writing That's Unclear

**[Major]** ΓÇö Design Spec, Phase 4, "Code Mode Iteration Cycle" (lines 270): The sentence describes a three-step cycle but labels the steps inconsistently with the two-step cycle described just above it, creating ambiguity about whether "Step 1" in code mode is the test execution or the review.

**Current text:**
> Code mode adds a test execution step to each iteration. The full cycle is: (1) Orchestrator runs tests via the code plugin's `test-runner.js` and captures results. (2) Review ΓÇö orchestrator passes the test results as additional context to the reviewer AI alongside the codebase and `constraints.md`. Reviewer outputs JSON error report including test results. (3) Fix ΓÇö orchestrator passes issue list to fixer agent. Git commit after fix.

**Replacement:**
> Code mode extends the two-step cycle with a test execution step at the beginning. The full Code mode cycle per iteration is: (1) **Test** ΓÇö orchestrator runs tests via the code plugin's `test-runner.js` and captures results. (2) **Review** ΓÇö orchestrator passes test results as additional context to the reviewer AI alongside the codebase and `constraints.md`. Reviewer outputs JSON error report. (3) **Fix** ΓÇö orchestrator passes the issue list to the fixer agent. Git commit after fix. Plan mode uses the two-step cycle (Review ΓåÆ Fix) with no test execution. Both modes commit after the review step and after the fix step.

---

**[Major]** ΓÇö Design Spec, Phase 4, git commit timing for Code mode (line 266ΓÇô270): The two-step description says "Git commit after review" and "Git commit after fix," but the Code mode iteration cycle description only mentions "Git commit after fix." It's unclear whether Code mode also commits after the review step or only after the fix step.

**Replacement** (add to end of the Code mode iteration cycle paragraph):
> Code mode follows the same two-commits-per-iteration pattern: git commit after the review step (captures review JSON and test results) and git commit after the fix step (captures applied fixes).

---

**[Major]** ΓÇö Design Spec, Stagnation Guard (line 278): "Total count plateaus across consecutive iterations AND issue rotation detected" ΓÇö the phrasing "issue rotation detected" reads as though rotation is the _normal_ state. What is actually meant is that the issues are _churning_ (different issues each time) while the total stays flat, indicating the loop has reached its ceiling.

**Current text:**
> Same total error count for 3+ consecutive iterations... AND issue rotation detected (specific issues change between iterations even though the total stays flat ΓÇö the loop has reached the best quality achievable autonomously)

**Replacement:**
> Same total error count for 3+ consecutive iterations... AND issue churn detected (the specific issues change between iterations even though the total count stays flat ΓÇö indicating the loop is replacing old issues with new ones at the same rate and has reached the best quality achievable autonomously)

---

**[Minor]** ΓÇö Design Spec, Phase 1, step 3 (line 80): "If external resource connectors are configured (Notion, Google Drive), the human provides page URLs or document links via chat." This implies the human must always provide URLs via chat, but the Inputs table (line 35ΓÇô36) also lists "config" as a source for URLs. The two descriptions are inconsistent.

**Current text:**
> the human provides page URLs or document links via chat.

**Replacement:**
> the human provides page URLs or document links via chat, or the URLs are pre-configured in `config.yaml` (e.g., default Notion pages that should be pulled for every project).

If config-based URLs are not actually supported, remove "or config" from the Inputs table instead.

---

**[Minor]** ΓÇö Design Spec, Fabrication Guard (line 279): "A severity category spikes well above its recent average, AND the system had previously approached convergence thresholds" ΓÇö "well above" is vague for a design doc. The build spec quantifies this (50% + minimum absolute increase of 2), but the design spec should give the reader a qualitative sense without forcing them to the build spec.

**Current text:**
> A severity category spikes well above its recent average

**Replacement:**
> A severity category spikes significantly above its trailing 3-iteration average (e.g., >50% increase)

---

**[Minor]** ΓÇö Design Spec, "Manual Edit Behavior" (line 153): The sentence "manual edits to these files after their respective phases require restarting from that phase (not currently supported; project must be recreated)" is confusing ΓÇö it says restart is required, then says it's not supported, then says recreate. A builder reading this wouldn't know what to actually do.

**Current text:**
> `spec.md` and `intent.md` are read at Phase 3 start and not re-read ΓÇö manual edits to these files after their respective phases require restarting from that phase (not currently supported; project must be recreated).

**Replacement:**
> `spec.md` and `intent.md` are read once at Phase 3 start and not re-read during later phases. If the human manually edits these files after their creation phase, the only way to pick up those changes is to create a new project ΓÇö there is no "restart from Phase N" capability in v1.

---

**[Minor]** ΓÇö Execution Plan, Build Stage 6, Task 30 (line 106): The parenthetical "these tasks extend Task 30, not replace it" is ambiguous about what "extend" means in practice ΓÇö is this subtasking, or are Tasks 32, 38, and 39 literally implemented inside Task 30's codebase?

**Current text:**
> Includes count derivation from issues array (Task 32), polish state persistence + crash recovery (Task 38), and polish log append (Task 39) as integral orchestrator responsibilities ΓÇö these tasks extend Task 30, not replace it

**Replacement:**
> Count derivation (Task 32), polish state persistence + crash recovery (Task 38), and polish log append (Task 39) are implemented as part of the polish loop orchestrator module ΓÇö they are listed as separate tasks for tracking but are coded within the orchestrator, not as separate modules.

---

**[Minor]** ΓÇö Design Spec, "Confirmation model" paragraph (line 92): "Both use explicit button presses to eliminate misclassification" ΓÇö misclassification of what? This is clear in context if you've read the design philosophy, but the sentence doesn't stand alone.

**Current text:**
> Both use explicit button presses to eliminate misclassification.

**Replacement:**
> Both use explicit button presses to eliminate the risk of the AI misinterpreting a chat message as a phase advancement command.

---

## 2. Genuinely Missing Plan-Level Content

**[Major]** ΓÇö **No WebSocket reconnection or connection loss behavior defined.** The chat interface uses WebSocket for real-time streaming. The plan does not specify what happens when the WebSocket connection drops mid-conversation or mid-streaming (Phase 1 distillation streaming, Phase 4 status updates). For a single-operator local tool, this is still a real scenario (browser tab closed, laptop sleep).

**Proposed content** (add to Design Spec, UI section, after "Per-project chat thread" paragraph):
> **WebSocket Disconnection:** If the WebSocket connection drops, the chat client automatically attempts to reconnect. On reconnect, the client fetches the current project state from `status.json` and the latest chat messages from `chat_history.json` to restore the UI to the correct state. In-flight AI responses that were streaming when the connection dropped are not replayed ΓÇö the human sees the last fully-received message and can re-trigger the action (e.g., click Distill again) if the operation did not complete. Pipeline processing continues server-side regardless of client connection state.

---

**[Major]** ΓÇö **No definition of what "resource reading" means for each supported file type.** Phase 1 says "AI reads all resources (text, PDF, images via vision, code files)" but the plan never specifies how each format is handled ΓÇö particularly PDFs (full text extraction? OCR?) and images (passed to vision model? which model?). A builder would have to make these decisions during implementation.

**Proposed content** (add to Design Spec, Phase 1, after step 5 or to Build Spec as an implementation reference):
> **Resource File Processing:**
> | Format | Processing Method |
> |---|---|
> | `.md`, `.txt`, code files | Read as plain text, passed to AI as context |
> | `.pdf` | Text extracted via PDF parsing library (e.g., `pdf-parse`). If extraction yields no text (scanned PDF), log a warning and skip the file. OCR is deferred. |
> | Images (`.png`, `.jpg`, `.gif`) | Passed to the AI agent's vision capability if the configured agent supports it. If not, log a warning and skip. |
> | Unsupported formats | Logged as unreadable per Phase 1 error handling |

---

**[Major]** ΓÇö **No concurrency control for the project state module.** The plan specifies up to 3 parallel projects and atomic writes for state files, but does not address what happens if two pipeline operations attempt to write to state files simultaneously (e.g., two projects sharing a notification queue, or the orchestrator and a user-initiated action racing on `status.json`). For file-based state this matters.

**Proposed content** (add to Design Spec, Project State Files section):
> **Concurrency Model:** Each project operates on its own isolated directory and state files. No cross-project state sharing exists. Within a single project, the pipeline is single-threaded ΓÇö only one operation (phase transition, polish iteration, button action) executes at a time. The orchestrator serializes operations per project. Concurrent access to a single project's state files is not supported and does not need locking.

---

**[Minor]** ΓÇö **No error handling for Handlebars template rendering failures at the content level.** The plan covers template _file_ errors (halt, no retry) but not what happens if the AI returns content that breaks Handlebars syntax (e.g., unescaped `{{` in plan text). This is a real scenario since the AI fills content slots in a Handlebars template.

**Proposed content** (add to Design Spec, Phase 3 Plan Mode, or Build Spec):
> **Template Content Escaping:** AI-generated content inserted into Handlebars template slots is escaped to prevent Handlebars syntax characters in plan text (e.g., literal `{{` or `}}`) from causing render failures. The plan builder escapes content before template rendering.

---

**[Minor]** ΓÇö **No specification for how the human learns about the tool's current state after returning from an absence.** The plan describes notifications for events, but if the human is away for hours and returns to the browser, there's no description of a dashboard summary or project status overview in the ThoughtForge chat UI itself (separate from the Vibe Kanban dashboard).

**Proposed content** (add to Design Spec, UI section):
> **Project Status on Return:** The project list sidebar shows each project's current phase and status (including halted indicator). When the human opens a project's chat thread, the most recent messages and any pending action buttons (e.g., halt recovery options) are displayed. No separate "catch-up" summary is generated ΓÇö the chat history and project status serve this purpose.

---

**[Minor]** ΓÇö **Execution Plan has no explicit testing strategy statement.** Build Stage 8 lists specific tests, but there's no high-level statement about testing philosophy ΓÇö unit tests use mocks (not real agents), e2e tests use real agents or stubs, etc. A builder starting Task 45 wouldn't know whether to mock the agent layer or spin up real CLIs.

**Proposed content** (add to Execution Plan, before Build Stage 8 task table):
> **Testing Strategy:** Unit tests (Tasks 45ΓÇô50b) use mocked dependencies ΓÇö no real agent CLI calls, no real file system for state tests, no real API calls for connectors. E2e tests (Tasks 51ΓÇô57) run the full pipeline with real agent invocations against a test project. Synthetic convergence guard tests (Task 54) use fabricated `polish_state.json` data, not real polish loop runs.

---

## 3. Build Spec Material That Should Be Extracted

**[Minor]** ΓÇö **Design Spec, Action Button Behavior table (lines 96ΓÇô109).** This table specifies exact `status.json` field updates, button disabled states, spinner behaviors, and confirmation dialog text for every button in the system. This is implementation-level UI specification ΓÇö the design spec should state the _behavior model_ (chat-based corrections, button-based actions, confirmation for destructive operations) and the button inventory, but the exact status.json mutations and UI feedback strings belong in the build spec.

**Why:** A builder needs this table, but it's implementation detail. The design spec already establishes the confirmation model in the paragraph above the table. The table should move to the build spec with a reference from the design spec: "Complete button inventory with `status.json` effects and UI behavior in build spec."

---

**[Minor]** ΓÇö **Design Spec, Phase-to-State Mapping table (lines 122ΓÇô131).** This maps pipeline phases to exact `status.json` string enum values and their transitions. The design spec should describe the phase progression conceptually; the exact enum values and transition triggers are build spec material (and are already partially duplicated in the build spec's `status.json` schema).

**Why:** The `status.json` schema in the build spec already defines the valid phase values. Having the mapping in both documents creates a maintenance burden ΓÇö if a phase value changes, both documents need updating. Move the table to the build spec and reference it from the design spec.

---

**[Minor]** ΓÇö **Design Spec, Connector and Notification URL Validation table (lines 543ΓÇô551).** This specifies exact error message strings, startup-vs-runtime timing, and Zod validation approach for URL checking. The design spec should state the validation _policy_ (validate at startup for config issues, handle gracefully at runtime); the exact error messages and implementation approach belong in the build spec.

**Why:** The build spec already has a "Connector and Notification URL Validation" section (lines 609ΓÇô621) that covers the implementation. The design spec section duplicates this with slightly different wording, creating drift risk.

---

That concludes the review. Three lists, sorted by severity within each.
