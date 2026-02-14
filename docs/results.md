I've read all four documents in full. Now let me produce the review.

---

# Plan Review GÇö ThoughtForge Pipeline Tool

## 1. Writing That's Unclear

**[Major] Design Spec, Phase 2, Step 3 GÇö "resolves" is ambiguous about what happens when the AI can't reason its way to a decision**

The current text at line 108:
> "AI resolves Unknowns and Open Questions from `intent.md` GÇö either by making a reasoned decision (stated in `spec.md`) or by asking the human during the Phase 2 chat. No unresolved unknowns may carry into `spec.md`."

The error handling table below covers "AI cannot resolve an Unknown through reasoning," but the primary flow text makes it sound like the AI will always succeed at one of two paths. The reader has to cross-reference the error table to understand the fallback.

**Replacement:**
> "AI attempts to resolve each Unknown and Open Question from `intent.md`. For each item, the AI either makes a reasoned decision (stated in `spec.md` with rationale) or, if it cannot reach a confident resolution through reasoning alone, presents the item to the human in the Phase 2 chat for decision. No unresolved unknowns may carry into `spec.md`."

---

**[Major] Design Spec, Stagnation Guard GÇö "issue rotation detected" needs the threshold stated inline, not just in the build spec**

Line 230:
> "Total count plateaus across consecutive iterations AND issue rotation detected (specific issues change between iterations even though the total stays flat GÇö the loop has reached the best quality achievable autonomously)"

The design spec defines every other guard's trigger condition with enough specificity to understand the mechanism (e.g., hallucination says "spikes sharply after a sustained downward trend"). Stagnation says "issue rotation detected" but the actual definition (70% match threshold, Levenshtein GëÑ0.8) only appears in the build spec. A reader of the design spec alone can't understand what "rotation" means concretely.

**Replacement:**
> "Total count plateaus across consecutive iterations AND issue rotation detected GÇö fewer than 70% of issues in the current iteration match issues from the prior iteration (matched by description similarity). The loop has reached the best quality achievable autonomously."

---

**[Major] Design Spec, Fabrication Guard GÇö same problem as stagnation: mechanism unclear without build spec**

Line 231:
> "A severity category spikes well above its recent average, AND the system had previously approached convergence thresholds GÇö suggesting the reviewer is manufacturing issues because nothing real remains"

"Spikes well above" and "approached convergence thresholds" are vague at the plan level. The build spec defines these precisely (>50% above trailing 3-iteration average, within 2+ù of termination thresholds), but the design spec reader has no sense of scale.

**Replacement:**
> "A severity category spikes significantly above its trailing average (e.g., >50% increase), AND the system had previously reached near-convergence (within roughly 2+ù of termination thresholds) GÇö suggesting the reviewer is manufacturing issues because nothing real remains."

---

**[Minor] Requirements Brief, line 9 GÇö "~12 hours" appears as both the problem and the target without distinguishing them**

The Outcome says the polish loop "currently takes ~12 hours of manual work" and the Value section says "Reclaims ~12 hours of manual polish grind per project." These are the same number used two different ways (current cost vs. expected savings), which implies 100% automation of that time. If that's the intent, say so. If not, clarify.

**Replacement for Value (line 79):**
> "Reclaims the majority of ~12 hours currently spent on manual polish per project. Human time reduces to brain dump, correction, and final review only."

---

**[Minor] Design Spec, Phase 1, Step 0 GÇö dense paragraph covering 6+ distinct operations**

Line 58 is a single paragraph that covers: ID generation, directory creation, git init, status.json write, project name extraction timing, Vibe Kanban card creation. It's hard to parse as a sequence.

**Replacement:**
> 0. **Project Initialization:**
>    1. Human initiates a new project via the ThoughtForge chat interface (e.g., a "New Project" command or button).
>    2. ThoughtForge generates a unique project ID and creates the `/projects/{id}/` directory structure (including `/docs/` and `/resources/` subdirectories).
>    3. Initializes a git repo in the project directory.
>    4. Writes an initial `status.json` with phase `brain_dump` and `project_name` as empty string.
>    5. Opens a new chat thread.
>    6. After Phase 1 distillation locks `intent.md`, the project name is extracted from the `intent.md` title and written to `status.json`. If Vibe Kanban is enabled, the card name is updated at the same time.
>    7. If Vibe Kanban integration is enabled, a corresponding card is created at this point.

---

**[Minor] Design Spec, Hallucination Guard GÇö "spikes sharply" is subjective**

Line 229:
> "Error count spikes sharply after a sustained downward trend"

The build spec defines this as ">20% increase after 2+ declining iterations." The plan-level text should give directional specificity.

**Replacement:**
> "Error count increases meaningfully (e.g., >20%) after a sustained downward trend of 2+ iterations"

---

## 2. Genuinely Missing Plan-Level Content

**[Critical] No error handling for concurrent access to shared resources**

The plan supports up to 3 parallel projects. The design spec says each project gets its own git repo and directory, which handles file isolation. But the shared resources are: the config file (`config.yaml`), the notification channel (ntfy.sh topic), and the web chat server (single Express instance on port 3000). There is no mention of:
- What happens if two projects try to send notifications simultaneously (likely fine with ntfy.sh, but the abstraction layer isn't specified as concurrent-safe)
- How the single web server handles multiple concurrent project chat sessions (does WebSocket multiplex? Is there a project-scoped session model?)

**Proposed addition to Design Spec, Technical Design section, after the Chat Interface stack entry:**

> **Concurrency Model:** The single Express/WebSocket server handles all active projects. Each WebSocket connection is scoped to a project ID GÇö the client sends the project ID on connection, and all subsequent messages are routed to that project's pipeline instance. Multiple browser tabs can connect to different projects simultaneously. Notification sends are stateless HTTP POSTs and require no concurrency coordination. The orchestrator runs one pipeline instance per active project; each instance operates on its own project directory and state files with no shared mutable state.

---

**[Major] No specification of how the chat interface connects brain dump text to the pipeline**

Phase 1 describes: "Human brain dumps into chat GÇö one or more messages of freeform text" and then "Human clicks Distill button." But the design never specifies how the chat messages become the input to the distillation prompt. Are all messages concatenated? Is there a message boundary? Is the raw chat text passed to the agent, or is it pre-processed?

**Proposed addition to Design Spec, Phase 1, between current steps 4 and 5:**

> When the human clicks **Distill**, the orchestrator concatenates all human chat messages from the current `brain_dump` phase (from `chat_history.json`) in chronological order, separated by newlines. This concatenated text, along with any files in `/resources/`, is passed to the distillation prompt as the brain dump input. No pre-processing or summarization is applied GÇö the AI receives the raw human text.

---

**[Major] Execution Plan has no definition of "done" for prompt-drafting tasks**

Tasks 7f, 15a, 19a, 21a, 30a, 30b are all "Draft `/prompts/{name}.md` prompt text." The execution plan doesn't specify what "done" means for a prompt. Is it written and committed? Written, tested against a real agent call, and revised? Just a first draft?

**Proposed addition to Execution Plan, before Build Stage 2 (as a note or convention):**

> **Prompt drafting convention:** A prompt task is complete when the prompt file is written to `/prompts/`, committed, and the drafting developer has verified it produces the expected structured output format when tested against at least one agent with representative input. Prompts are iterable GÇö refinement happens during integration testing (Build Stage 8) GÇö but the initial draft must produce valid output.

---

**[Major] No specification of unique project ID generation strategy**

Design spec line 58 says "ThoughtForge generates a unique project ID" but never specifies the format or generation method. This matters because the ID is used in directory paths, git repo names, Vibe Kanban card IDs, and `status.json`. Is it a UUID? A timestamp? A slug? A sequential number?

**Proposed addition to Design Spec, Phase 1, Step 0 (or as a footnote to the project initialization):**

> **Project ID format:** UUID v4 (e.g., `a1b2c3d4-e5f6-7890-abcd-ef1234567890`). Generated via Node.js `crypto.randomUUID()`. Used as directory name, Vibe Kanban card ID, and internal reference. Human-readable project name is stored separately in `status.json` after Phase 1 distillation.

---

**[Minor] No mention of browser/client requirements for the chat UI**

The design specifies "server-rendered HTML + vanilla JavaScript" and "WebSocket client in plain JS" but doesn't state whether this needs to work in any specific browser or just the operator's local browser. For a solo-operator tool this is low-stakes, but it's a standard plan-level item.

**Proposed addition to Design Spec, Technical Design, Chat UI entry:**

> Targets modern evergreen browsers (Chrome, Firefox, Edge). No mobile support required. Operator accesses via `localhost:{port}` on the same machine running ThoughtForge.

---

**[Minor] Execution Plan has no rollback or recovery strategy for failed builds**

The plan has crash recovery for the polish loop (`polish_state.json`) but no mention of what happens if the build itself fails partway through a stage. If Task 15 (plan builder) partially completes and the operator needs to restart, what state is preserved? The git commits provide rollback points, but the plan doesn't explicitly state "roll back to last git commit and re-run the phase."

**Proposed addition to Execution Plan, after the Dependencies & Blockers section:**

> **Recovery Strategy:** Each pipeline phase commits to git at completion (per Design Spec git commit strategy). If a phase fails or produces unacceptable results, the operator can `git reset` the project repo to the last phase-completion commit and re-trigger the phase. Phase 4 crash recovery uses `polish_state.json` to resume mid-loop. No automated rollback GÇö the operator decides when to reset.

---

## 3. Build Spec Material That Should Be Extracted

**[Minor] Design Spec, line 157GÇô163 GÇö Plugin folder structure with specific filenames**

The Design Spec section "Plugin Folder Structure" says "Full folder structure and filenames in build spec" but then the paragraphs above it (lines 342-344) already describe the exact contents: "a builder (Phase 3 drafting/coding), a reviewer (Phase 4 schema and severity definitions), safety rules (blocked operations), and any type-specific assets." This is fine at plan level. However, noting this for completeness: the design spec correctly defers the full file tree to the build spec. No action needed.

**[Minor] Design Spec, line 348 GÇö Plugin interface contract function signatures**

Line 348 says: "Plugin interface contract (function signatures, parameters, return types) defined in build spec." This is correctly deferred. The design spec describes what each component does without listing signatures. No action needed.

**No items requiring extraction.** The design spec consistently defers implementation detail to the build spec using explicit forward references. The separation is clean.

---

# Consolidated Coder Prompt

```
You are applying the results of a plan review to the ThoughtForge project documentation.
Apply every change below exactly as specified. Do not interpret, summarize, or skip any item.

## File: docs/thoughtforge-requirements-brief.md

### Change 1 GÇö Clarify Value metric (line 79)
Replace:
"Reclaims ~12 hours of manual polish grind per project. Enables parallel execution of multiple projects with minimal human attention."

With:
"Reclaims the majority of ~12 hours currently spent on manual polish per project. Human time reduces to brain dump, correction, and final review only. Enables parallel execution of multiple projects with minimal human attention."

---

## File: docs/thoughtforge-design-specification.md

### Change 2 GÇö Clarify Phase 2 Unknown resolution (line 108)
Replace:
"AI resolves Unknowns and Open Questions from `intent.md` GÇö either by making a reasoned decision (stated in `spec.md`) or by asking the human during the Phase 2 chat. No unresolved unknowns may carry into `spec.md`."

With:
"AI attempts to resolve each Unknown and Open Question from `intent.md`. For each item, the AI either makes a reasoned decision (stated in `spec.md` with rationale) or, if it cannot reach a confident resolution through reasoning alone, presents the item to the human in the Phase 2 chat for decision. No unresolved unknowns may carry into `spec.md`."

### Change 3 GÇö Break up Phase 1 Step 0 into numbered sub-steps (line 58)
Replace the entire sentence starting "**Project Initialization:** Human initiates..." through "...a corresponding card is created at this point." with:

"**Project Initialization:**
   1. Human initiates a new project via the ThoughtForge chat interface (e.g., a "New Project" command or button).
   2. ThoughtForge generates a unique project ID (UUID v4 via `crypto.randomUUID()`) and creates the `/projects/{id}/` directory structure (including `/docs/` and `/resources/` subdirectories).
   3. Initializes a git repo in the project directory.
   4. Writes an initial `status.json` with phase `brain_dump` and `project_name` as empty string.
   5. Opens a new chat thread.
   6. If Vibe Kanban integration is enabled, a corresponding card is created at this point.
   7. After Phase 1 distillation locks `intent.md`, the project name is extracted from the `intent.md` title and written to `status.json`. If Vibe Kanban is enabled, the card name is updated at the same time."

### Change 4 GÇö Add brain dump concatenation specification
After the current step 4 ("Human clicks **Distill** button...") and before step 5 ("AI reads all resources..."), insert:

"4a. When the human clicks **Distill**, the orchestrator concatenates all human chat messages from the current `brain_dump` phase (from `chat_history.json`) in chronological order, separated by newlines. This concatenated text, along with any files in `/resources/`, is passed to the distillation prompt as the brain dump input. No pre-processing or summarization is applied GÇö the AI receives the raw human text."

### Change 5 GÇö Clarify Hallucination guard (line 229)
Replace:
"Error count spikes sharply after a sustained downward trend"

With:
"Error count increases meaningfully (e.g., >20%) after a sustained downward trend of 2+ iterations"

### Change 6 GÇö Clarify Stagnation guard (line 230)
Replace:
"Total count plateaus across consecutive iterations AND issue rotation detected (specific issues change between iterations even though the total stays flat GÇö the loop has reached the best quality achievable autonomously)"

With:
"Total count plateaus across consecutive iterations AND issue rotation detected GÇö fewer than 70% of issues in the current iteration match issues from the prior iteration (matched by description similarity). The loop has reached the best quality achievable autonomously."

### Change 7 GÇö Clarify Fabrication guard (line 231)
Replace:
"A severity category spikes well above its recent average, AND the system had previously approached convergence thresholds GÇö suggesting the reviewer is manufacturing issues because nothing real remains"

With:
"A severity category spikes significantly above its trailing average (e.g., >50% increase), AND the system had previously reached near-convergence (within roughly 2+ù of termination thresholds) GÇö suggesting the reviewer is manufacturing issues because nothing real remains"

### Change 8 GÇö Add concurrency model
In the Technical Design section, after the "Chat UI (Frontend)" row in the ThoughtForge Stack table, add a new paragraph:

"**Concurrency Model:** The single Express/WebSocket server handles all active projects. Each WebSocket connection is scoped to a project ID GÇö the client sends the project ID on connection, and all subsequent messages are routed to that project's pipeline instance. Multiple browser tabs can connect to different projects simultaneously. Notification sends are stateless HTTP POSTs and require no concurrency coordination. The orchestrator runs one pipeline instance per active project; each instance operates on its own project directory and state files with no shared mutable state."

### Change 9 GÇö Add browser target
In the ThoughtForge Stack table, in the "Chat UI (Frontend)" row's "Why" column, append:

" Targets modern evergreen browsers (Chrome, Firefox, Edge). No mobile support required. Operator accesses via `localhost:{port}`."

---

## File: docs/thoughtforge-execution-plan.md

### Change 10 GÇö Add prompt drafting convention
Before the "### Build Stage 2" heading, add:

"> **Prompt drafting convention:** A prompt task is complete when the prompt file is written to `/prompts/`, committed, and the drafting developer has verified it produces the expected structured output format when tested against at least one agent with representative input. Prompts are iterable GÇö refinement continues during integration testing (Build Stage 8) GÇö but the initial draft must produce valid output."

### Change 11 GÇö Add recovery strategy
After the "## Dependencies & Blockers" section and before the "## Risk Register" section, add:

"## Recovery Strategy

Each pipeline phase commits to git at completion (per Design Spec git commit strategy). If a phase fails or produces unacceptable results, the operator can `git reset` the project repo to the last phase-completion commit and re-trigger the phase. Phase 4 crash recovery uses `polish_state.json` to resume mid-loop. No automated rollback GÇö the operator decides when to reset."

---

After all changes are applied:
1. Review each file to confirm no formatting was broken by the insertions.
2. git add the three modified files.
3. git commit with message: "Apply plan review findings: clarity, completeness, and concurrency model"
4. git push to sync with remote.
```
