# ThoughtForge Pipeline Tool — Design Specification

> **Companion to:** [ThoughtForge Requirements Brief](./thoughtforge-requirements-brief.md) | [ThoughtForge Build Spec](./thoughtforge-build-spec.md) | [ThoughtForge Execution Plan](./thoughtforge-execution-plan.md)

---

## Overview

**What is being designed:** An autonomous pipeline tool that takes a human brain dump and produces a polished deliverable (plan document or working code) through structured phases with convergence-based polish loops.

**Terminology convention (applies throughout all ThoughtForge documents):** "Human" and "operator" refer to the same person — the solo user. "Human" is used in pipeline flow descriptions. "Operator" is used in system administration contexts.

---

## Functional Design

### OPA Framework

Plan mode deliverables use an **OPA Table** structure — **Objective → Plan → Assessment** — for every major section. This is distinct from the requirements brief's use of "OPA" (Outcome • Purpose • Action, Tony Robbins' RPM System), which is a document organization framework, not a deliverable content structure. To avoid ambiguity: "OPA Table" always refers to the deliverable structure; "OPA Framework" in the requirements brief refers to the brief's own organization.

| Column | Purpose |
|---|---|
| Objective | What this section aims to achieve |
| Plan | The specific actions, decisions, or content that accomplish the objective |
| Assessment | How success will be measured or validated for this section |

Handlebars templates define the OPA skeleton — fixed section headings with OPA table placeholders. The AI fills the table content but cannot alter the structure. The Phase 4 review loop evaluates both content quality and OPA structural compliance.

### Inputs

| Input | Source | Format | Required |
|-------|--------|--------|----------|
| Brain dump | Human via chat | Freeform text | Yes |
| Resources | Human drops into `/projects/{id}/resources/` | Text, PDF, images, code files | No |
| Notion pages | Human provides page URL(s) via chat or config | Pulled as Markdown | No |
| Google Drive documents | Human provides document URL(s) or folder ID via chat or config | Pulled as Markdown/text | No |
| Corrections | Human via chat | Natural language | Yes (Phase 1-2) |
| Confirmation | Human via Confirm button | Button press | Yes (phase advancement) |
| Plan document (chained) | Previous pipeline output in `/projects/{id}/resources/` | `.md` file | Code mode only (optional) |

### Outputs

| Output | Destination | Format |
|--------|-------------|--------|
| `intent.md` | `/projects/{id}/docs/` | Markdown — 6-section distillation |
| `spec.md` | `/projects/{id}/docs/` | Markdown — locked spec with all decisions |
| `constraints.md` | `/projects/{id}/docs/` | Markdown — review rules + acceptance criteria |
| Plan deliverable | `/projects/{id}/docs/` | Markdown — OPA-structured document |
| Code deliverable | `/projects/{id}/` | Working codebase with tests and logging |
| `polish_log.md` | `/projects/{id}/` | Markdown — iteration-by-iteration log |
| `polish_state.json` | `/projects/{id}/` | JSON — loop state for crash recovery |
| `status.json` | `/projects/{id}/` | JSON — current phase and metadata |
| `chat_history.json` | `/projects/{id}/` | JSON — per-phase chat messages for crash recovery |

Pipeline document outputs (`intent.md`, `spec.md`, `constraints.md`, plan deliverable) are written to `/docs/`. Operational state files (`polish_state.json`, `status.json`, `chat_history.json`) and logs (`polish_log.md`) are written to the project root. Code deliverables are written to the project root.

### Behavior

#### Phase 1 — Brain Dump & Discovery

**Primary Flow:**

0. **Project Initialization:**

   Project initialization creates the project directory structure, initializes version control, writes the initial project state, optionally registers on the Kanban board, and opens the chat interface. The full initialization sequence — including collision retry, field assignments, and error handling — is in the build spec.

   The project ID is used as the directory name and as `project_id` in notifications — not stored in `status.json` since it is always derivable from the project directory path.

   Project name is derived later during Phase 1 — see step 11.

**Interaction model:** Phase 1 uses two explicit actions: a **Distill** button (signals that all inputs are provided and the AI should begin processing) and a **Confirm** button (advances to Phase 2). Both use button presses, not chat commands — see Confirmation Model below.

1. Human brain dumps into chat — one or more messages of freeform text
2. Human drops files/resources into `/resources/` directory (optional, can happen before or after the brain dump messages)
3. If external resource connectors are configured (Notion, Google Drive), the human provides page URLs or document links via chat, or the URLs are pre-configured in `config.yaml` (e.g., default Notion pages that should be pulled for every project). ThoughtForge pulls the content and saves it to `/resources/` as local files. Connectors are optional — if none are configured, this step is skipped.
   **Step 3 Detail — Connector URL Identification:** The AI matches URLs in chat messages against known URL patterns for each enabled connector and pulls content automatically. URL matching rules (enabled/disabled/unmatched behavior) are in the build spec.

**Phase 1 has two action buttons:**
- **Distill** — "I'm done providing inputs. Process them." (Pressed once after brain dump + resources are provided.)
- **Confirm** — "The distillation looks correct. Move on." (Pressed after reviewing and correcting the AI's output.)

4. Human clicks **Distill** button — signals that all inputs (brain dump text, files, connector URLs) have been provided and the AI should begin processing. This follows the same confirmation model as phase advancement: explicit button press, not chat-parsed.
5. AI reads all resources (text, PDF, images via vision, code files) and the brain dump

**Resource File Processing:** Resources are processed by format — text read directly, PDFs extracted, images via AI vision if supported, unsupported formats logged and skipped.

6. AI distills into structured document: Deliverable Type, Objective, Assumptions, Constraints, Unknowns, Open Questions (max 5)

   When the AI completes distillation and presents the result in chat, `status.json` transitions from `distilling` to `human_review`. This signals that the AI has finished processing and is awaiting human corrections.

7. AI presents distillation to human in chat
8. Human corrects via chat → AI revises and re-presents
9. Human can type "realign from here" in chat. Unlike phase advancement actions (which use buttons), this is a chat-parsed command that excludes messages after the most recent substantive human correction from the working context and re-distills. Excluded messages are retained in `chat_history.json` for audit trail but not passed to the AI. Matching rules and algorithm in build spec.

10. Human clicks **Confirm** button → advances to Phase 2
11a. Output: `intent.md` written to `/docs/` and locked — no further modification by AI in subsequent phases. Human may still edit manually outside the pipeline.

"Locked" means the AI pipeline will not modify the file after its creation phase. See Locked File Behavior (Phase 2 section) for the full definition, including human edit consequences.

11b. The deliverable type is derived from the confirmed intent and set in `status.json`.

**Project Name Derivation (during Phase 1 distillation):** The project name is derived from the distilled intent document. When `intent.md` is written and locked, the project name is extracted and written to `status.json`. If Vibe Kanban is enabled, the card name is updated at the same time.

**Resource lifecycle:** Files in `/resources/` persist for the lifetime of the project. They are not deleted or moved after Phase 1 consumption. The Plan Completeness Gate (Code mode entry) scans `/resources/` for plan documents. Non-plan resources remain for human reference but are not re-consumed by later pipeline phases.

**Ambiguous Deliverable Type:** If the brain dump contains signals for both Plan and Code, the AI defaults to Plan and flags the ambiguity in the Open Questions section: "Brain dump describes both planning and implementation. Classified as Plan — confirm or change to Code." The human resolves during the correction cycle.

**Brain Dump Intake Prompt Behavior:** The prompt enforces: organize only (no AI suggestions or improvements), structured output (6 sections as listed above), maximum 5 open questions (prioritized by blocking impact), ambiguities routed to Unknowns. Full prompt text is specified in the build spec under "Phase 1 System Prompt — Brain Dump Intake."

**Mid-Processing Human Input:** If the human sends a chat message while the AI is processing a prior turn (e.g., typing a correction while distillation is streaming), the message is queued in `chat_history.json` and included in the next AI invocation's context. It does not interrupt the current processing. The chat input field remains active during AI processing to allow the human to queue messages.

**Confirmation model:** Chat-based corrections, button-based actions. Corrections are natural language in chat. The **Distill** button signals that all brain dump inputs are provided and the AI should begin processing. The **Confirm** button advances the pipeline to the next phase. Both use explicit button presses to eliminate the risk of the AI misinterpreting a chat message as a phase advancement command. This model applies to all human action points in the pipeline.

**Action Button Behavior (All Buttons):**

Every action button follows the behavior contract defined in the build spec's Action Button Behavior inventory, which specifies `status.json` effects, UI feedback, and confirmation requirements for each button.

**Phase 1 Error Handling:**

| Condition | Action |
|---|---|
| Agent failure during distillation (timeout, crash, empty response) | Same retry behavior as agent communication layer: retry once, halt and notify on second failure. Chat resumes from last recorded message. |
| Brain dump is empty or trivially short (below configurable minimum length) | AI responds in chat asking the human to provide more detail. Does not advance to distillation. |
| Resource file unreadable (corrupted, unsupported format) | AI logs the unreadable file, notifies the human in chat specifying which file(s) could not be read, and proceeds with distillation using available inputs. |
| Connector authentication failure (expired token, missing credentials) | Log the failure, notify the human in chat specifying which connector failed and why, and proceed with distillation using available inputs (if distillation is already in progress, no re-click of Distill is required). Do not halt the pipeline. |
| Connector target not found (deleted page, revoked access, invalid URL) | Log the failure, notify the human in chat specifying which resource could not be retrieved, and proceed with distillation using available inputs (if distillation is already in progress, no re-click of Distill is required). |
| `status.json` unreadable, missing, or invalid (applies to all phases, not just Phase 1) | Halt the project and notify the operator with the file path and the specific error (parse failure, missing file, invalid phase value). Do not attempt recovery or partial loading — the operator must fix or recreate the file. |
| Brain dump text exceeds agent context window | Handled by the agent invocation layer's context window management (see build spec). A warning is displayed in chat if truncation occurs. |
| Resource file exceeds configurable size limit | Log a warning, skip the file, and notify the human in chat: "File '{filename}' exceeds size limit and was skipped." |
| Human provides malformed or unparseable connector URL in chat | AI responds in chat: "Could not parse URL: '{url}'. Please provide a valid Notion page URL or Google Drive document link." Does not halt. Does not attempt to pull. |

**`chat_history.json` Error Handling:** If `chat_history.json` is unreadable or missing, the pipeline halts and notifies the human — same behavior as `status.json` corruption. The human must fix or recreate the file. Chat history size is bounded by the phase-clearing behavior (cleared on Phase 1→2 and Phase 2→3 transitions). If a phase's chat history exceeds the agent's context window, the agent invocation layer truncates older messages using phase-specific anchoring rules. Truncation algorithms per phase are defined in the build spec. A warning is logged when truncation occurs.

**Phase-to-State Mapping:** Phase-to-state enum mapping and transition triggers are defined in the build spec's `status.json` schema.

Vibe Kanban columns correspond to these `status.json` phase values, except `halted` — which is a card state indicator, not a separate column. See the UI section for full column mapping.

**Project Lifecycle After Completion:** Once a project reaches `done` or `halted`, no further pipeline actions are taken. The project directory, git repo, and all state files remain in place for human reference. Project archival, deletion, and re-opening are deferred. Not a current build dependency.

**Manual Project Deletion (Active Project):** If a project directory is deleted while the server is running and the project is in a non-terminal state, the server will encounter file system errors on the next operation for that project. These are handled by the existing cross-cutting file system error handling: halt and notify. The project list sidebar will show the project until the server is restarted (server restart scans `/projects/` and removes stale entries). Graceful handling of mid-run directory deletion is deferred — not a current build dependency.

**Disk management:** Project directories accumulate indefinitely in v1. The operator is responsible for manually deleting completed or halted project directories when no longer needed. ThoughtForge does not track or limit total disk usage. Automated project archival and cleanup are deferred — not a current build dependency. Operational logs (`thoughtforge.log`) also accumulate without rotation or size limits in v1. The operator is responsible for manual log management. Automated log rotation is deferred — not a current build dependency.

#### Phase 2 — Spec Building & Constraint Discovery

**Primary Flow:**

Phase 2 has two AI-driven steps: Challenge (step 2) and Resolve (step 3).

1. AI proposes deliverable structure and key decisions based on `intent.md`
2. AI evaluates `intent.md` for structural issues: missing dependencies, unrealistic constraints, scope gaps, internal contradictions, and ambiguous priorities. Each flagged issue is presented to the human with specific reasoning. The AI does not rubber-stamp — it must surface concerns even if the human's intent seems clear. This step does not resolve Unknowns — it identifies new problems.

Challenge findings that result in design changes are captured in the `spec.md` "Key Decisions" section with the original concern and resolution. Challenge findings that the human dismisses are not persisted beyond the chat history. Since chat history is cleared on Phase 2→3 transition, dismissed challenges are not available for later reference. This is acceptable — the human's decisions are captured in `spec.md`; the reasoning for rejected alternatives is not.

3. **Resolve:** AI resolves Unknowns and Open Questions from `intent.md` — either by making a reasoned decision (stated in `spec.md`) or by asking the human during the Phase 2 chat. The governing principle: the AI decides autonomously when the decision is low-risk, reversible, or has a clearly dominant option based on the constraints — and escalates to the human when the decision is high-impact, preference-dependent, or has multiple viable options with material trade-offs. The Phase 2 prompt (`spec-building.md`) operationalizes this principle. No unresolved unknowns may carry into `spec.md`.
4. AI derives acceptance criteria from the objective, assumptions, and constraints in `intent.md`. The validation gate enforces a minimum of 1 criterion; the target range of 5–10 is guidance for the AI prompt, not an enforced threshold. For Plan mode, criteria assess document completeness, logical coherence, and actionability. For Code mode, criteria assess functional requirements that map to testable acceptance tests in Phase 3.
5. Human confirms or overrides specific decisions
6. Human reviews acceptance criteria — adds/removes as needed

**Phase 2 Conversation Sequencing:** The AI presents all proposed elements in a single structured message: deliverable structure, key decisions, resolved unknowns, and acceptance criteria. The human responds with corrections to any element. The AI revises only the affected elements and re-presents the complete updated proposal. This repeats until the human is satisfied and clicks Confirm. There is no enforced ordering between elements — the human may address them in any sequence. The validation gate (all Unknowns and Open Questions resolved) is checked when Confirm is clicked, not during the correction cycle.

7. Before advancement: AI validates that all Unknowns and Open Questions from `intent.md` have been resolved (either by AI decision in `spec.md` or by human input during Phase 2 chat). If unresolved items remain, the Confirm button is blocked and the AI presents the remaining items to the human.

**Acceptance Criteria Validation Gate:** Before Phase 2 Confirm advances to Phase 3, the orchestrator validates that the Acceptance Criteria section of the proposed `constraints.md` contains at least 1 criterion. If the section is empty, the Confirm button is blocked and the AI prompts the human: "At least one acceptance criterion is required before proceeding. Add acceptance criteria or confirm the AI's proposed set." This gate enforces the minimum at creation time only — after `constraints.md` is written, the human may freely edit it (including emptying the section) per the unvalidated-after-creation policy.

If the proposed `constraints.md` content does not contain a recognizable Acceptance Criteria section (section heading missing entirely), the AI is re-invoked with an instruction to include acceptance criteria based on the confirmed intent and spec decisions. This follows the standard retry-once-then-halt behavior. The human is notified: "AI did not generate acceptance criteria. Retrying." If the second attempt also lacks the section, the pipeline halts and the human must provide criteria manually in chat.

8. Human clicks **Confirm** → advances to Phase 3
9. Outputs: `spec.md` and `constraints.md` written to `/docs/` and locked — no further modification by AI in subsequent phases. Human may still edit manually outside the pipeline.

**Locked File Behavior:**

"Locked" means the AI pipeline will not modify these files after their creation phase. The human may still edit them manually outside the pipeline, with the following consequences:

#### `constraints.md` — Hot-Reloaded

The pipeline re-reads `constraints.md` at the start of each Phase 4 iteration. Manual human edits to acceptance criteria or review rules are picked up automatically. If `constraints.md` is unreadable or missing at the start of a Phase 4 iteration, the iteration halts and the human is notified.

**`constraints.md` — unvalidated after creation:** If the human restructures the file (missing sections, reordered content, added sections), ThoughtForge passes it to the AI reviewer as-is without schema validation. If the human empties the Acceptance Criteria section, the reviewer proceeds with whatever criteria remain (which may be none). This is treated as an intentional human override — the pipeline does not validate criteria presence after the initial Phase 2 write.

**`constraints.md` — readability definition:** "Unreadable" means the file cannot be read from disk (permission error, I/O error) or is not valid UTF-8 text. A file that is readable but contains unexpected content (empty, restructured, nonsensical) is passed to the reviewer as-is per the unvalidated-after-creation policy. If the file exceeds the agent's context window when combined with other review context, it is truncated with a warning logged.

**`constraints.md` truncation strategy:** If `constraints.md` exceeds the agent's context window when combined with other review context, it is truncated per the strategy defined in the build spec.

#### `spec.md` and `intent.md` — Static After Creation

Read at Phase 3 start and used by the Phase 3 builder. Not re-read during Phase 4 iterations — Phase 4 uses `constraints.md` and the deliverable itself.

- Manual human edits during active pipeline execution have no effect — the pipeline works from its Phase 3 context.
- On server restart, any in-memory Phase 3 context is discarded. When a halted project is resumed during Phase 3, the orchestrator re-reads both files from disk. When a halted project is resumed during Phase 4, neither file is re-read — Phase 4 operates from `constraints.md` and the current deliverable state.
- There is no "restart from Phase N" capability in v1. The pipeline does not detect or warn about manual edits to any locked file.

**In short:** Editing `constraints.md` during Phase 4 works. Editing `spec.md` or `intent.md` during active pipeline execution has no effect. Editing them while the project is halted works if the project is subsequently resumed.

**Phase 2 Error Handling:**

| Condition | Action |
|---|---|
| AI cannot resolve an Unknown from `intent.md` through reasoning | AI presents the Unknown to the human in the Phase 2 chat for decision. No unresolved Unknowns may carry into `spec.md`. |
| Agent failure during Phase 2 conversation (timeout, crash, empty response) | Same retry behavior as agent communication layer: retry once, halt and notify on second failure. Chat resumes from last recorded message in `chat_history.json`. |
| Human has not responded to a Phase 2 question | No automatic action. Project remains in `spec_building` state. No timeout — the project stays open indefinitely until the human acts. Reminder notification is deferred (not a current build dependency). |
| File system error during `spec.md` or `constraints.md` write | Halt and notify human immediately with file path and error. No retry — same behavior as cross-cutting file system error handling. |
| AI returns empty or structurally invalid content for `spec.md` or `constraints.md` | Retry once. On second failure, halt and notify human. |
| Server crash during Phase 2 conversation | On restart, `status.json` phase is `spec_building` (an interactive state — not auto-halted per Server Restart Behavior). Chat resumes from the last recorded message in `chat_history.json`. The AI re-reads `intent.md` and the chat history to reconstruct the spec-in-progress, then re-presents the current proposal for human review. |

**Plan Mode behavior:** Proposes plan structure following OPA Framework — every major section gets its own OPA table. Challenges decisions per Phase 2 step 2 behavior.

**Code Mode behavior:** Proposes build spec (language, OS, framework, tools, dependencies, architecture). Runs Open Source Discovery before proposing custom-built components. Every OSS recommendation includes the 8-signal qualification scorecard (signals, red flags, and minimum qualification threshold defined in build spec).

**`spec.md` structure:** See build spec `spec.md` Structure section for the full template. Contains: Deliverable Overview, Deliverable Structure, Key Decisions, Resolved Unknowns, Dependencies, and Scope Boundaries.

Plan mode: Deliverable Structure contains proposed plan sections following OPA Framework. Code mode: Deliverable Structure contains proposed architecture, language, framework, and tools (including OSS qualification results where applicable).

**`constraints.md` structure:**

| Section | Description |
|---|---|
| Context | What this deliverable does (from `intent.md`) |
| Deliverable Type | Plan or Code |
| Priorities | What the human cares about |
| Exclusions | What not to touch, what not to flag |
| Severity Definitions | What counts as critical / medium / minor |
| Scope | Plan mode: sections/topics in scope. Code mode: files/functions in scope. |
| Acceptance Criteria | At least 1, target 5–10 statements of what the deliverable must contain or do |

#### Phase 3 — Build (Autonomous)

**Plan Mode:**

1. Orchestrator loads plan plugin (`/plugins/plan/builder.js`)

Plan mode always invokes agents directly via the agent communication layer, regardless of whether Vibe Kanban is enabled. VK provides visualization only (card status updates) for Plan mode projects. VK agent execution is used exclusively in Code mode.

2. Selects appropriate Handlebars template from `/plugins/plan/templates/`
3. Template selection is driven by the Deliverable Type classification from `intent.md`. The template directory uses a naming convention (e.g., `wedding.hbs`, `engineering.hbs`, `strategy.hbs`). If no type-specific template matches, the `generic.hbs` template is used as the default. Template selection logic lives in the plan plugin's `builder.js`.
4. Template defines OPA skeleton as fixed structure — AI fills content slots but cannot break structure
5. Fills every section — no placeholders, no "TBD"

**Builder interaction model:** The plan builder may invoke the AI agent multiple times to fill the complete template — for example, one invocation per major section or group of sections. The builder tracks which sections are complete and passes the partially-filled template as context for subsequent invocations. Each invocation returns a `PlanBuilderResponse`. The builder is complete when all template sections are filled with non-placeholder content.

**Partial Plan Build Recovery:** If the plan builder halts mid-template (agent failure on section N of M), the orchestrator commits the partially-filled template before halting. On resume, the builder re-reads the partially-filled template from disk, identifies which sections are complete (non-empty, non-placeholder content), and resumes from the first incomplete section. Already-filled sections are not re-generated.

**Template Context Window Overflow:** If the partially-filled template exceeds the agent's context window during multi-invocation plan building, the builder passes only the current section's OPA table slot, the `spec.md` context for that section, and the immediately preceding section (for continuity) — not the full partially-filled template. A warning is logged when truncation occurs. The full template is reassembled from the individually-filled sections after all invocations complete.

**Template Content Escaping:** AI-generated content must not break template rendering.

**Template Slot Validation:** After each plan builder invocation, the orchestrator validates that the returned content corresponds to a valid template slot. If the AI returns content for a non-existent slot, the content is discarded with a warning logged. If a required template slot receives empty or placeholder content (containing "TBD", "TODO", or "placeholder" — case-insensitive), the builder re-invokes the AI for that slot (subject to the standard retry-once-then-halt behavior). After all invocations complete and the template is assembled, a final validation confirms all slots are filled. Any remaining empty slots halt the builder with a notification identifying the unfilled sections.

6. **NEVER creates source files, runs commands, installs packages, scaffolds projects, or executes anything. Document drafting only. Enforced at orchestrator level via plugin safety rules.**
7. If stuck on a decision requiring human input: notifies and waits
8. Output: complete but unpolished plan document (`.md`) in `/docs/`

The plan deliverable filename is `plan.md`, written to `/projects/{id}/docs/plan.md`. This distinguishes it from pipeline artifacts (`intent.md`, `spec.md`, `constraints.md`) in the same directory. The Phase 4 reviewer and fixer reference this fixed filename.

**Code Mode:**

1. Orchestrator loads code plugin (`/plugins/code/builder.js`)

1a. **Plan Completeness Gate:** Before the code builder begins work, the orchestrator runs the Plan Completeness Gate (see dedicated section below). If the gate halts the pipeline, Phase 3 does not proceed. If the gate passes or is skipped (no plan document in `/resources/`), the code builder begins.

**Code builder context assembly:** The code builder passes the following files to the coding agent as build context: `spec.md` (architecture, decisions, dependencies), `constraints.md` (acceptance criteria, scope, priorities), and optionally the plan document from `/resources/` if one was identified by the Plan Completeness Gate. `intent.md` is not passed — its content is already distilled into `spec.md`. Resource files from `/resources/` (other than a chained plan document) are not passed to the code builder — they were consumed during Phase 1 distillation.

**Code builder interaction model:** The code builder passes the full `spec.md` (architecture, dependencies, acceptance criteria) to the coding agent as a single build prompt. The agent is responsible for scaffolding, implementation, and initial test writing in a single invocation or multi-turn session, depending on how Vibe Kanban executes the task (if VK is enabled) or as a single invocation (if VK is disabled). This is a coarser-grained interaction model than the plan builder's section-by-section approach, reflecting that coding agents (Claude Code, Codex) operate best with full project context rather than isolated function-level prompts.

**Code builder test-fix cycle:**

After the initial build invocation, the code builder enters a test-fix cycle: run tests → pass failures to the agent → agent fixes → re-run tests. This repeats until all tests pass or stuck detection triggers.

**Stuck detection within the test-fix cycle:** Two conditions trigger stuck detection: (1) the build agent returns non-zero exit on the same build task after 2 consecutive retries, OR (2) the test suite fails on the identical set of test names for 3 consecutive fix-and-retest cycles (compared by exact string match). If each cycle produces different failing tests (rotating failures), condition (2) does not trigger.

**Cycle termination:** The test-fix cycle terminates via stuck detection or human intervention (Phase 3 stuck recovery buttons). A hard cap on test-fix iterations is deferred — not a current build dependency.

**Commit behavior:** Unlike Phase 4, the Phase 3 test-fix cycle does not commit after each cycle. A single git commit is written when Phase 3 completes successfully.

2. Codes the project using configured agent via Vibe Kanban (when enabled) or direct agent invocation (when disabled — see Vibe Kanban toggle behavior)
3. Instructs the coding agent to implement structured logging in the deliverable codebase (mandatory requirement in the build prompt). Logging approach and framework are determined by the Phase 2 spec.
4. Writes tests: unit, integration, and acceptance (each acceptance criterion from `constraints.md` must have a corresponding test)
5. Runs all tests, fixes failures, iterates until passing
6. If stuck: notifies and waits
7. Output: working but unpolished codebase

**Stuck Detection (Phase 3):** Plan mode and Code mode use different stuck detection mechanisms. Plan mode relies on AI self-reporting via a structured response field. Code mode relies on orchestrator-observed failure patterns.

| Mode | Stuck Condition | Action |
|---|---|---|
| Plan | AI includes a stuck signal in every builder response. When the AI reports stuck, the orchestrator halts and notifies with the AI's stated reason. Response schema in build spec (`PlanBuilderResponse`). | Notify and wait |
| Code | See test-fix cycle stuck detection above. | Notify and wait |

**Code mode stuck tracking:** "Same task" means consecutive agent invocations with the same prompt intent (e.g., "implement feature X" or "fix test Y") — tracked by the code builder's internal task queue. "Identical test failures" means the same set of test names appear in the failed list across consecutive fix-and-retest cycles, compared by exact test name string match.

**Phase 3 Stuck Recovery:**

When Phase 3 stuck detection triggers, the human is notified with context (deliverable type, what the AI is stuck on, current build state). The human has two options, presented as buttons in the ThoughtForge chat interface: Provide Input or Terminate.

Phase 3 does not offer an Override option — unlike Phase 4, there is no partially complete deliverable worth accepting. The builder either needs the input to continue or the project is abandoned.

Button behavior and `status.json` effects are specified in the build spec Action Button Behavior inventory.

**Provide Input Flow:** When the human clicks Provide Input and submits text, the orchestrator appends the human's message to `chat_history.json` and re-invokes the builder's current stuck task with the original prompt context plus the human's input appended as additional guidance. The builder's retry counter for the stuck task is reset — the human's input constitutes a new attempt, not a continuation of the failure sequence. If the builder remains stuck after receiving human input, stuck detection resumes from count 0 for that task.

**Phase 3 Error Handling:**

| Condition | Action |
|---|---|
| Agent failure (timeout, crash, empty response) during build | Same retry behavior as agent communication layer: retry once, halt and notify on second failure. |
| Template rendering failure (Plan mode) | Halt and notify human with error details. No retry — template errors indicate a structural problem, not a transient failure. |
| File system error (cannot write to project directory) | Halt and notify human immediately. No retry. |
| Template directory empty or `generic.hbs` missing | Halt and notify human: "No plan templates found. Ensure at least `generic.hbs` exists in `/plugins/plan/templates/`." No retry. |
| Type-specific template not found but `generic.hbs` exists | Log a warning: "No template found for plan type '{type}'. Using generic template." Notify the human in chat. Proceed with `generic.hbs`. |

**Phase 3 → Phase 4 Transition:** Automatic. When the Phase 3 builder completes successfully (plan document drafted or codebase built and tests passing), the orchestrator writes a git commit, updates `status.json` to `polishing`, sends a milestone notification ("Phase 3 complete. Deliverable built. Polish loop starting."), and immediately begins Phase 4. No human confirmation is required — this is within the autonomous window between Touchpoints 3 and 4.

**Phase 3 → Phase 4 Transition Error Handling:**

| Condition | Action |
|---|---|
| Phase 3 builder reports success but expected output files are missing (Plan mode: no `.md` deliverable in `/docs/`; Code mode: no source files in project directory) | Halt. Set `status.json` to `halted` with `halt_reason: "phase3_output_missing"`. Notify human: "Phase 3 reported success but deliverable files are missing. Review project directory." Do not enter Phase 4. |
| Phase 3 output exists but is empty or trivially small (below `config.yaml` `phase3_completeness` criteria) | Halt. Set `status.json` to `halted` with `halt_reason: "phase3_output_incomplete"`. Notify human: "Phase 3 deliverable appears incomplete. Review before proceeding." Do not enter Phase 4. |
| `status.json` write fails during transition (cannot update phase to `polishing`) | Halt. Notify human with file path and error. The Phase 3 git commit has already been written — the deliverable is preserved. The operator must fix the file system issue and manually update `status.json` to resume. |
| Milestone notification fails during transition | Log the notification failure. Proceed with Phase 4 — notification failure is not blocking. The phase transition and deliverable are the critical path, not the notification. |
| `constraints.md` missing or unreadable at Phase 3→4 transition | Halt. Set `status.json` to `halted` with `halt_reason: "file_system_error"`. Notify human: "constraints.md missing or unreadable. Cannot start polish loop. Review project `/docs/` directory." Do not enter Phase 4. |

**Human Chat During Autonomous Phases (3-4):**

During Phase 3 and Phase 4 autonomous execution, the chat input field is disabled. The human can view the project's chat history and current status but cannot send messages. Chat input is re-enabled only when the pipeline enters a stuck or halt state that requires human interaction (Phase 3 stuck recovery, Phase 4 halt recovery). The human can always edit the deliverable files directly outside the pipeline — see "Deliverable Edits During Phase 4."

**Code Mode Testing Requirements:**

| Test Type | What It Covers | When It Runs |
|---|---|---|
| Unit tests | Core functions and logic in isolation | Phase 3 + Phase 4 |
| Integration tests | Components working together | Phase 3 + Phase 4 |
| Acceptance tests | Each acceptance criterion has a corresponding test | Phase 3 + Phase 4 |

**Test framework selection:** The test framework is determined during Phase 2 as part of the proposed architecture (language, tools, dependencies). The `test-runner.js` module executes tests using the framework specified in `spec.md`. It is not prescriptive about which framework — it adapts to whatever was decided during spec building.

**Test Command Discovery:** The code builder's `test-runner.js` does not parse `spec.md` to discover the test command. Instead, the coding agent is instructed (via the `/prompts/code-build.md` prompt) to create a standard `npm test` script in the project's `package.json` (or the language-equivalent test entry point). `test-runner.js` always invokes the project's standard test entry point (`npm test` for Node.js projects). The specific test framework is an implementation detail of the deliverable codebase, not of ThoughtForge's `test-runner.js`. If the test command exits non-zero, `test-runner.js` treats it as test failures and captures stdout/stderr as the `details` field.

**Non-Node.js projects:** For deliverables in languages other than Node.js, the coding agent is instructed (via the `/prompts/code-build.md` prompt) to create a standard test entry point appropriate to the language (e.g., `Makefile` with `make test`, `pyproject.toml` with `pytest`, etc.). `test-runner.js` reads the project's `spec.md` Deliverable Structure section to determine the language and invokes the language-appropriate test command. The mapping from language to test command is a configuration in `test-runner.js`, not hardcoded to `npm test`.

**Deliverable Edits During Phase 4:**

If the human manually edits the deliverable (plan document or source code) between Phase 4 iterations, the edits are picked up by the next iteration's review step — the reviewer reads the current state of the deliverable from disk. The next fix step's git commit captures both the human's edits and the AI's fixes. The pipeline does not detect, warn about, or distinguish human edits from AI fixes. This is by design — the human has full authority to modify the deliverable at any time. The convergence trajectory may shift as a result (human edits could increase or decrease error counts). No special handling is needed.

#### Phase 4 — Polish Loop (Fully Automated)

**Each Iteration — Two Steps:**

**Step 1 — Review (do not fix):** AI reviews scoped deliverable + `constraints.md` (including acceptance criteria). Outputs ONLY a JSON error report. Does not fix anything. Git commit after review (captures the review JSON).

**Step 2 — Fix (apply recommendations):** Orchestrator passes JSON issue list to fixer agent, which applies fixes. Git commit after fix (captures applied fixes).

**Agent assignment for review and fix steps:** Both the review and fix steps use the same agent assigned to the project (from `status.json` `agent` field). The review prompt instructs the agent to produce a JSON error report only — no fixes. The fix prompt instructs the agent to apply fixes from the provided issue list only — no new review. Prompt separation enforces the behavioral boundary. Using separate agents for review vs. fix is deferred — not a current build dependency.

**Fix agent context assembly:** The fix agent receives the JSON issue list and the relevant deliverable context. For Plan mode: the current plan document. For Code mode: the fix agent receives the issue list and the content of each file referenced in the issues' `location` fields (parsed as relative paths from project root; line numbers are stripped before file lookup). If a referenced file does not exist, the issue is included in the context with a note: "Referenced file not found." If the total referenced file content exceeds the agent's context window, files are truncated starting from the largest, with a warning logged. `constraints.md` is always included for scope awareness. Unreferenced files are not passed to the fix agent — it operates only on files identified by the reviewer. The fix agent does not receive the prior review JSON from previous iterations — only the current iteration's issue list. Full context assembly is specified in the fix prompts (`plan-fix.md`, `code-fix.md`).

**Zero-Issue Iteration:** If the review step produces zero issues (empty issues array), the fix step is skipped for that iteration. The orchestrator proceeds directly to convergence guard evaluation. Only the review commit is written — no fix commit.

**Plan mode fix interaction:** The fix agent receives the full plan document and the JSON issue list. It returns the complete updated plan document with fixes applied. The orchestrator replaces the existing plan file with the returned content. The fix agent does not return diffs or partial documents — full document replacement ensures structural integrity of the OPA template.

**Plan mode fix output validation:** After the fix agent returns the updated plan document, the orchestrator validates that the returned content is non-empty and does not have fewer characters than 50% of the pre-fix plan document. If either check fails, the fix is rejected: the pre-fix plan document is preserved (no replacement), a warning is logged, and the iteration proceeds to convergence guard evaluation using the pre-fix state. If 2 consecutive iterations produce rejected fix output, the pipeline halts and notifies the human: "Fix agent returning invalid plan content. Review needed."

**Code mode fix interaction:** The fix agent operates as a coding agent with write access to the project directory. It reads the issue list, modifies the relevant source files directly, and exits. The orchestrator then runs `git add` and commits the changes. The fix agent does not return modified file content — it applies changes in-place, consistent with how coding agents operate during Phase 3.

**Code mode `location` field convention:** For Code mode review JSON, the `location` field must contain the relative file path from the project root, optionally followed by `:line_number` (e.g., `src/server.ts:42`). The fix prompt (`code-fix.md`) instructs the fix agent to use these paths to locate and modify the relevant files. The reviewer prompt (`code-review.md`) instructs the reviewer to produce `location` values in this format. The orchestrator does not parse or validate `location` — it is a convention enforced by prompts, not code.

**Code Mode Iteration Cycle:** Code mode extends the two-step cycle with a test execution step. The full cycle per iteration is:

1. **Test** — Orchestrator runs tests via the code plugin's `test-runner.js` and captures results.
2. **Review** — Orchestrator passes test results as additional context to the reviewer AI alongside the codebase and `constraints.md`. Reviewer outputs a JSON error report.
3. **Fix** — Orchestrator passes the issue list to the fixer agent.

Plan mode uses the two-step cycle (Review → Fix) with no test execution.

**Code mode review context:** The review prompt includes `constraints.md`, test results, and a representation of the codebase. For codebases that fit within the agent's context window, the full source is included. For larger codebases, the reviewer receives a file manifest (list of all source files with sizes) plus the content of files that changed since the last iteration (identified via `git diff`). The review prompt (`code-review.md`) specifies the context assembly strategy. If the codebase exceeds the agent's context window even with diff-only strategy, the orchestrator logs a warning and proceeds with truncated context.

**Commit pattern:** Both modes commit twice per iteration — once after the review step (captures review artifacts and test results) and once after the fix step (captures applied fixes). This enables rollback of a bad fix while preserving the review that identified the issues.

**Review JSON persistence:** The review JSON output is persisted as part of the `polish_state.json` update and the `polish_log.md` append at each iteration boundary — it is not written as a separate file.

**Convergence Guards:**

| Guard | Condition | Action |
|---|---|---|
| Termination (success) | Error counts within configured thresholds (+ all tests pass for code). Thresholds in `config.yaml`. | Done. Notify human. |
| Fix Regression (per-iteration) | Evaluated immediately after each fix step, before other guards. Compares the post-fix total error count against the pre-fix review count for the same iteration. **Single occurrence:** If the fix increased the total error count, log a warning but continue. **Consecutive occurrences:** If the two most recent fix steps both increased their respective error counts, halt and notify: "Fix step is introducing more issues than it resolves. Review needed." | Warn (single) or Halt (2 consecutive). Notify human. |
| Hallucination | Total error count increases by more than 20% from the prior iteration (hardcoded threshold, defined in build spec) after at least 2 consecutive iterations with decreasing total error count (hardcoded minimum trend length, defined in build spec) | Halt. Notify human: "Project '{name}' — fix-regress cycle detected. Errors decreased for {N} iterations ({trajectory}) then spiked to {X} at iteration {current}. Review needed." |
| Stagnation | **Intent:** Detect when the deliverable has reached a quality plateau — the reviewer resolves old issues but introduces equally many new cosmetic issues each iteration, producing no net improvement. Two conditions must both be true: (1) **Plateau:** Total error count is identical for `stagnation_limit` consecutive iterations. (2) **Issue rotation:** Fewer than 70% of current-iteration issues match any issue in the immediately prior iteration (match = Levenshtein similarity ≥ 0.8 on `description`). When both are true, the deliverable is converged. | Done (success). The deliverable has reached a stable quality level where the reviewer is cycling cosmetic issues rather than finding genuine regressions. Treated as converged — no further iterations will yield net improvement. |
| Fabrication | Two conditions must both be true: (1) **Category spike:** A single severity category count exceeds its trailing average by more than 50% (with a minimum absolute increase of 2). Trailing window size defined in build spec. (2) **Prior near-convergence:** The system previously reached within 2× of the termination thresholds in at least one prior iteration (i.e., critical ≤ 0, medium ≤ 6, minor ≤ 10 with default config). This ensures fabrication is only flagged after the deliverable was demonstrably close to convergence — not during early volatile iterations. The `2×` multiplier is hardcoded; the base thresholds are read from `config.yaml` at runtime. Parameters in build spec. | Halt. Notify human. |
| Max iterations | Hard ceiling reached (configurable, default 50) | Halt. Notify human: "Max [N] iterations reached. Avg flaws/iter: [X]. Lowest: [Y] at iter [Z]. Review needed." |

**Evaluation timing note:** Fix Regression is evaluated immediately after each fix step (before other guards). All other guards are evaluated after the full iteration cycle (review + fix) completes. See build spec Guard Evaluation Order for the complete sequence.

Algorithmic parameters for each guard (spike thresholds, similarity measures, window sizes) are defined in the build spec.

**Stagnation Guard Detail:** Stagnation compares total error count only (sum of critical + medium + minor), not per-severity breakdowns. Issue rotation is detected when fewer than 70% of current issues match any issue in the prior iteration. Match is defined as Levenshtein similarity >= 0.8 on the `description` field. The rotation threshold and similarity measure are defined in the build spec. When both conditions are true, the deliverable has reached a quality plateau where the reviewer is cycling through cosmetic issues rather than finding genuine regressions. This is treated as a successful convergence outcome.

**Phase 4 Completion — Human Final Review:**

When Phase 4 completes (termination or stagnation success), the chat displays a completion message with the final error counts, iteration count, and the file path to the polished deliverable. The project status shows as `done`. The human reviews the deliverable by opening the file directly — ThoughtForge does not render the deliverable inline. The chat thread remains available for reference (including all Phase 3-4 chat history) but no further pipeline actions are available.

**Loop State Persistence:** `polish_state.json` written after each iteration. Full field list in the Project State Files section under Technical Design. On crash, resumes from last completed iteration.

**Halt vs. Terminate Distinction:**

When a convergence guard triggers a halt, the project is recoverable — the human can Resume or Override. When the human explicitly Terminates (via button), the project is permanently stopped (`halt_reason: "human_terminated"`). Both use the `halted` phase value in `status.json`; the `halt_reason` field distinguishes them. (Authoritative field values are in the build spec Action Button Behavior table.)

**Halt Recovery:**

When a convergence guard halts the loop, the human is notified with context (guard type, iteration number, error state). The human has three options: Resume, Override, or Terminate.

Recovery is initiated through the ThoughtForge chat interface. The halted card remains in the Polishing column with a visual halted indicator until the human acts.

Button behavior and `status.json` effects are specified in the build spec Action Button Behavior inventory.

**Button display order:** Recovery buttons are displayed left-to-right: Resume, Override, Terminate. Terminate is visually distinguished (e.g., red or separated by a divider) as the destructive option.

**State Continuity on Resume:** The convergence trajectory in `polish_state.json` is continuous across the halt boundary — the resumed iteration is numbered sequentially after the last completed iteration. `polish_log.md` receives a log entry for the resume event before the next iteration's entry: `## Resumed at {ISO8601} — Halted by {guard_type} at iteration {N}, resumed by human`.

**Phase 4 Error Handling:**

| Condition | Action |
|---|---|
| Agent failure during review or fix step (timeout, crash, empty response) | Same retry behavior as agent communication layer: retry once, halt and notify on second failure. `polish_state.json` preserves loop progress — on resume, the failed iteration is re-attempted from the beginning (review step). |
| Zod validation failure on review JSON | Retry up to `config.yaml` `polish.retry_malformed_output` (default 2). On repeated failure: halt and notify human. |
| File system error during git commit after fix | Halt and notify human immediately. `polish_state.json` for the current iteration is not written (last completed iteration preserved for recovery). |
| Test runner crash during Code mode iteration (process error, not test assertion failure) | Same retry behavior as agent communication layer: retry once, halt on second failure. Distinct from test assertion failures, which are passed to the reviewer as context. |
| Git commit failure after review step | Halt and notify human immediately. The review JSON is preserved in memory for the current iteration. `polish_state.json` for the current iteration is not written. On resume, the review step is re-attempted from the beginning. |
| Fix step git commit fails after review step committed successfully | Halt and notify human. The review commit is preserved. Un-committed fix changes remain in the working tree. On resume, the orchestrator does NOT re-run the review step — it re-attempts only the fix commit. If the commit succeeds on retry, the iteration proceeds normally. If the working tree has been manually modified by the human during the halt, the orchestrator commits whatever is present (the human is responsible for the state they left). |
| `polish_state.json` unreadable, missing, or invalid at Phase 4 resume | Halt and notify the operator with the file path and the specific error (parse failure, missing file, invalid schema). Do not attempt recovery or partial loading — the operator must fix or recreate the file. Same behavior as `status.json` and `chat_history.json` corruption handling. |

**Count Derivation:** The orchestrator derives error counts from the issues array, not from top-level count fields. Count derivation logic is specified in the build spec.

#### Plan Completeness Gate (Code Mode Entry)

When a Code mode pipeline starts and a plan document is detected in `/resources/`, the AI assesses whether the plan is complete enough to build from. This is a prompt-based AI judgment — not a mechanical gate.

**Plan document identification:** The gate scans `/resources/` for `.md` files. If exactly one `.md` file is present, it is treated as the plan document. If multiple `.md` files are present, the gate evaluates each and uses the first that appears to be a structured plan (contains OPA table structure or section headings matching the plan template pattern). If no `.md` files are present, the gate is skipped — Code mode proceeds without plan evaluation. The AI is given the completeness signals below as evaluation criteria and returns a pass/fail recommendation with reasoning.

**Completeness signals (prompt guidance, not a scored rubric):** OPA Framework structure present, specific objectives (not vague), decisions made (not options listed), enough detail to build without guessing, acceptance criteria defined, no TBD/placeholders, clear scope boundaries, dependencies listed.

If the AI recommends fail: ThoughtForge halts the Code mode pipeline, sets `status.json` to `halted` with reason `plan_incomplete`, and notifies the human with the AI's reasoning. The chat interface presents two action buttons: Override or Terminate. ThoughtForge does not automatically create projects on the human's behalf. (Authoritative field values are in the build spec Action Button Behavior table.)

Button behavior and `status.json` effects are specified in the build spec Action Button Behavior inventory.

**Plan → Code Chaining Workflow:** To chain a completed plan into a code pipeline, the human creates a new project and places the finished plan document into the new project's `/resources/` directory. The new project proceeds through Phase 1 as normal — the plan document is one of the resources the AI reads during brain dump intake. At Phase 3 entry, the Plan Completeness Gate evaluates the plan and either proceeds or redirects as described above. The two projects are independent — separate project IDs, directories, git repos, and pipeline states.

#### Plan Mode Safety Guardrails

**Plan mode NEVER builds, executes, compiles, installs, or runs code. Ever.**

| Rule | What It Prevents |
|---|---|
| No coding agent shell access | No shell commands, package installs, or file system writes to source files during Plan mode Phases 3-4. AI agents are invoked for text generation only — not with coding-agent capabilities. |
| No source file creation | Only documentation files (`.md`) and operational state files (`.json`) may be created. Source file extensions are defined in `safety-rules.js`. |
| No "quick prototype" | AI cannot build something to validate the plan |
| No test execution | Plan quality assessed by review loop only |
| Phase 3 = document drafting only | No project scaffolding or boilerplate |
| Phase 4 = document review only | Does not evaluate if code snippets would compile |

**Enforcement:** Orchestrator loads plugin's `safety-rules.js` which declares blocked operations. Enforced at orchestrator level, not by prompting.

**Operation Taxonomy:** The orchestrator classifies every Phase 3/4 action into an operation type before invoking the plugin's `validate()`. The complete operation type list and the mapping from orchestrator actions to operation types are defined in the build spec.

---

## Technical Design

### Architecture — Two Layers

**ThoughtForge** is the intelligence layer — brain dump intake, plan mode, constraint discovery, polish loop logic, convergence guards. It creates and manages the work.

**Vibe Kanban** is the execution and visualization layer — kanban board, parallel task execution, agent spawning, git worktree isolation, dashboard, VS Code extension. It runs and displays the work.

ThoughtForge creates tasks → pushes them to Vibe Kanban → Vibe Kanban executes via coding agents → ThoughtForge monitors results and runs convergence logic.

### ThoughtForge Stack

| Component | Technology | Why |
|---|---|---|
| Runtime | Node.js | Already installed (via OpenClaw), single runtime |
| Core | Node.js CLI + orchestration logic | Intelligence layer: Phase 1-2 chat, polish loop, convergence guards, plan mode enforcement |
| Chat Interface | Express.js + WebSocket (ws) | Lightweight HTTP server for chat UI, WebSocket for real-time AI response streaming. Both MIT-licensed, standard Node.js ecosystem. |
| Chat UI (Frontend) | Server-rendered initial HTML page with vanilla JavaScript for dynamic UI updates. The chat interface is a single page — navigation between projects and settings is handled client-side via JavaScript DOM manipulation. No full-page reloads after initial load. | Minimal build tooling, no bundler required. WebSocket client in plain JS. Consistent with lightweight single-operator tool scope. |

Static assets (HTML, CSS, JS) are served directly by Express from a `/public/` directory. No CORS configuration is needed — the browser loads assets from the same origin as the WebSocket connection.
| AI Agents | Claude Code CLI, Gemini CLI, Codex CLI | Multi-agent support, flat-rate subscriptions |
| Project State | File-based: `/projects/{id}/` with `/docs/` subdirectory | Human-readable, git-trackable. State access wrapped in single module for future DB swap |
| Version Control | Git — each project gets its own repo | Rollback built in. Separate repos for clean parallel isolation |
| Notifications | ntfy.sh (Apache 2.0) with abstraction layer | One HTTP POST, no tokens needed. Abstraction supports adding channels via config |
| Resource Connectors | Notion API, Google Drive API — with abstraction layer (`/connectors/` directory) | Optional external resource intake for Phase 1. Abstraction layer follows same pattern as notification channels: config-driven, pluggable. Each connector is a module in `/connectors/` (e.g., `notion.js`, `google_drive.js`). Connector pulls content and writes to local `/resources/` directory. Connector interface defined in build spec. |
| Config | `config.yaml` at project root | Thresholds, max iterations, concurrency, agent prefs, notification channels |
| Prompts | External `.md` files in `/prompts/` | Human-editable pipeline prompts. Not embedded in code. Settings UI reads/writes directly. |
| Schema Validation | Zod (MIT, TypeScript-first) | Single-source review JSON schema. Auto-validation with clear errors |
| Template Engine | Handlebars (MIT) | OPA skeleton as fixed structure. AI fills slots, can't break structure |
| Plugin Architecture | Convention-based: `/plugins/{type}/` | Self-contained per deliverable type. Orchestrator delegates, no if/else branching |
| Operational Logging | Structured JSON logger — per-project operational log for debugging | ThoughtForge logs its own operations — agent invocations, phase transitions, convergence guard evaluations, errors, and halt events — to a per-project `thoughtforge.log` file as structured JSON lines. Separate from `polish_log.md` (which is the human-readable iteration log). Used for debugging, not human review. |
| MCP (Future) | Model Context Protocol | Core actions as clean standalone functions for future MCP wrapping. Deferred. Not a current build dependency. |

**Access Control:** When bound to localhost (`127.0.0.1`), no authentication is required — only the local operator can access the interface. If the operator changes the bind address to allow network access (`0.0.0.0` or a specific network interface), a warning is logged at startup: "Server bound to network interface. No authentication is configured — any network client can access ThoughtForge." Authentication and access control are deferred — not a current build dependency. The operator assumes responsibility for network security when binding to non-localhost addresses.

**Application Entry Point:** The operator starts ThoughtForge by running a Node.js server command (e.g., `thoughtforge start` or `node server.js`). This launches the lightweight web chat interface on a local port. The operator accesses the interface via browser. The entry point initializes the config loader, plugin loader, notification layer, and Vibe Kanban adapter (if enabled).

Project directories are created under the path specified by `config.yaml` `projects.directory` (default: `./projects` relative to ThoughtForge's working directory).

**Server Restart Behavior:** On startup, the server scans `/projects/` for projects with non-terminal `status.json` states (`brain_dump`, `distilling`, `human_review`, `spec_building`, `building`, `polishing`). Projects in human-interactive states (`brain_dump`, `human_review`, `spec_building`) resume normally — they are waiting for human input and no action is needed. Projects in autonomous states (`distilling`, `building`, `polishing`) are set to `halted` with `halt_reason: "server_restart"`. These are not auto-resumed because the server cannot safely re-enter a mid-execution agent invocation or polish iteration — the prior subprocess is dead and its partial output is unknown. The human must explicitly resume. The server does not automatically re-enter autonomous pipeline phases after a restart.

**Graceful Shutdown:** On `SIGTERM` or `SIGINT`, the server stops accepting new operations and waits for all in-progress agent subprocesses to complete (up to the configured `agents.call_timeout_seconds`). Each project's subprocess is handled independently: if a subprocess completes within the timeout, its iteration state is written normally. If the timeout expires for any subprocess, that subprocess is killed and its current iteration is abandoned (no state written). After all subprocesses have either completed or been killed, the server exits. On next startup, the standard Server Restart Behavior applies to each project independently.

**WebSocket Shutdown:** During graceful shutdown, the server sends a WebSocket close frame (code 1001, "Server shutting down") to all connected clients before stopping the HTTP listener. Clients receive the close event and display a "Server stopped" message instead of triggering the auto-reconnect loop. On server restart, clients reconnect normally.

**Interactive state shutdown:** For projects in human-interactive states (`brain_dump`, `human_review`, `spec_building`), no server-side processing is interrupted — the server is waiting for human input. The WebSocket close frame is sent as described above. Any chat message the human was composing but had not yet sent is lost (client-side only). The last persisted message in `chat_history.json` is the recovery point on restart.

**Hard crash (ungraceful termination):** If the server process terminates without sending a WebSocket close frame (kill -9, OOM, power loss), the client detects the dropped TCP connection via WebSocket `onerror` or `onclose` events. The same auto-reconnect behavior applies. The key difference from graceful shutdown: any agent subprocess that was running is killed by the OS (orphaned child process cleanup is OS-dependent). On restart, Server Restart Behavior applies — autonomous-state projects are halted. The client reconnects and syncs state normally.

**Git Commit Strategy:** Each project's git repo is initialized at project creation. Commits occur at: `intent.md` lock (end of Phase 1), `spec.md` and `constraints.md` lock (end of Phase 2), Phase 3 build completion, and twice per Phase 4 iteration — once after the review step (captures the review JSON) and once after the fix step (captures applied fixes). Two commits per iteration enables rollback of a bad fix while preserving the review that identified the issues. This ensures rollback capability at every major pipeline milestone.

### Vibe Kanban (Execution Layer — Integrated, Not Built)

| What It Provides | How ThoughtForge Uses It |
|---|---|
| Kanban board UI | Visualize pipeline phases as cards moving across columns |
| Parallel execution | Run multiple projects simultaneously across agents |
| Git worktree isolation | VK manages worktree-based isolation for its internal task execution. ThoughtForge's per-project git repos (created at project initialization) are independent of VK's worktree model. VK operates within the project's existing repo when executing agent work. |
| Multi-agent support | Claude Code, Gemini CLI, Codex, Amp, Cursor CLI |
| VS Code extension | Task status inside the IDE |
| Dashboard / stats | Timing, agent performance, progress tracking |

### Vibe Kanban Integration Interface

ThoughtForge communicates with Vibe Kanban via its CLI through four operations: task creation (project initialization), status updates (every phase transition), agent work execution (Phase 3 build, Phase 4 fix steps), and result reading (after each agent execution). All integration calls centralized in `vibekanban-adapter.js`. ThoughtForge never calls Vibe Kanban directly from orchestrator logic. Exact CLI commands and flags in build spec.

**Vibe Kanban toggle behavior:** The `vibekanban.enabled` config controls Kanban card creation, status updates, and dashboard visualization. Both modes function fully with VK disabled. VK provides visualization and Code mode agent execution. Plan mode always invokes agents directly. Implementation details including the toggle truth table are in the build spec.

**Vibe Kanban CLI failure handling:** If a VK CLI call fails (non-zero exit, timeout, command not found), the adapter logs the error. For visualization-only calls (card creation, status updates), the failure is logged as a warning and the pipeline continues — VK is not on the critical path. For agent execution calls (`vibekanban task run` in Code mode), the failure is treated as an agent failure and follows the standard agent retry-once-then-halt behavior.

### Plugin Folder Structure

Each plugin folder contains: a builder (Phase 3 drafting/coding), a reviewer (Phase 4 schema and severity definitions), safety rules (blocked operations), and any type-specific assets (e.g., Handlebars templates for Plan, test runner for Code). Full folder structure and filenames in build spec.

### Plugin Interface Contract

Plugin interface contract (function signatures, parameters, return types) defined in build spec. Includes builder.js (Phase 3), reviewer.js (Phase 4), safety-rules.js, discovery.js (optional Phase 2 hook — used by Code plugin for OSS qualification scorecard), and test-runner.js (Code plugin only — test execution for Phase 3 build iteration and Phase 4 review context).

### Zod Review Schemas

**Review JSON structure:** Both modes produce a JSON error report with per-severity issue counts and an issues array. Each issue includes severity, description, location, and recommendation. Code mode additionally includes test results (total, passed, failed). Exact Zod schemas in build spec.

**Validation flow:** Review JSON is validated against the Zod schema for the active deliverable type. Malformed responses are retried up to a configurable limit, then the pipeline halts and notifies the human. Validation flow and retry logic are in the build spec.

### Agent Communication

**Agent layer** refers to ThoughtForge's built-in agent invocation module — the subprocess-based mechanism for calling AI agent CLIs, capturing output, normalizing responses, and handling failures. This is distinct from Vibe Kanban's agent execution, which wraps agent invocation in task management and worktree isolation.

ThoughtForge invokes agents via CLI subprocess calls, passing prompts via file or stdin. Agent-specific adapters normalize output format differences. Invocation details in build spec.

**Context window awareness:** Each agent's context window size is configured in `config.yaml` `agents.available.{agent}.context_window_tokens`. ThoughtForge uses this value to determine when to truncate chat history, plan builder context, and code review context. The token count is an approximation — the exact estimation method is in the build spec.

**Shell safety:** Prompt content is passed via stdin pipe or file — never through shell argument expansion. This prevents shell metacharacters in brain dump text or resource files from causing accidental command execution.

**Failure handling:**
- Non-zero exit, timeout, or empty output → retry once
- Second failure → halt and notify human
- Timeout configurable via `config.yaml` (`agents.call_timeout_seconds`, default 300)

**Agent availability check:** At server startup, the configured default agent CLI is verified to exist on PATH. If not found, the server logs a warning: "Default agent '{agent}' not found on PATH. Projects will fail at first agent invocation." The server does not exit — other agents may be available, and the operator may install the agent before creating a project. At project creation, no agent availability check is performed — the first agent invocation failure triggers the standard retry-once-then-halt behavior.

**Structured Response Validation (Non-Review):**
Agent responses are validated where schemas exist; phases 1–2 use natural language reviewed by the human. Validation details, retry counts, and token estimation formula are specified in the build spec.

**Phase 1-2 Chat Agent Model:** Each chat turn is a stateless AI invocation with full context. There is no persistent agent session. Implementation details are in the build spec.

### Notification Content

Every phase transition pings the human with a status update. Every notification includes structured context:

| Field | Description |
|---|---|
| project_id | Unique project identifier |
| project_name | Human-readable project name. Derived during Phase 1 — see Project Name Derivation (Phase 1, step 0). |
| phase | Current phase |
| event_type | `convergence_success`, `guard_triggered`, `human_needed`, `milestone_complete`, `error` |
| summary | One-line description with actionable context |

**Notification Examples:**
- `"Project 'Wedding Plan' — polish loop converged. 0 critical, 1 medium, 3 minor. Ready for final review."`
- `"Project 'API Backend' — fix-regress cycle detected. Errors trending down (42→28→19) then spiked to 31 at iteration 12. Review needed."`
- `"Project 'CLI Tool' — polish sufficient. Ready for final review."`
- `"Project 'Dashboard' — fabrication suspected at iteration 9. Errors were near-converged (0 critical, 2 medium, 4 minor) then spiked. The reviewer may be manufacturing issues because nothing real remains. Loop halted."`
- `"Project 'Mobile App' — max 50 iterations reached. Avg flaws/iter: 12. Lowest: 6 at iter 38. Review needed."`
- `"Project 'API Backend' — Phase 1 complete. Intent locked."`
- `"Project 'API Backend' — Phase 2 complete. Spec and constraints locked. Build starting."`
- `"Project 'API Backend' — Phase 3 complete. Deliverable built. Polish loop starting."`
- `"Project 'CLI Tool' — Phase 2 spec building. AI stuck on ambiguity: should auth use JWT or session cookies? Decision needed."`

**Active Session Awareness:** Notifications are sent regardless of whether the human has the project open in the chat interface. The notification layer does not track client connection state. Suppressing notifications for active sessions is deferred — not a current build dependency.

### Project State Files

**Concurrency Model:** Each project operates on its own isolated directory and state files. No cross-project state sharing exists.

**Concurrency limit enforcement:** When the number of active projects (status not `done`) reaches `config.yaml` `concurrency.max_parallel_runs`, new project creation is blocked. The chat interface disables the "New Project" action and displays a message: "Maximum parallel projects reached ({N}/{N}). Complete or halt an existing project to start a new one." Enforcement is at the ThoughtForge orchestrator level, not delegated to Vibe Kanban. Within a single project, the pipeline is single-threaded — only one operation (phase transition, polish iteration, button action) executes at a time. Concurrent access to a single project's state files is not supported and does not need locking.

**Halted projects and concurrency:** Projects with `halted` status count toward the active project limit until the human either resumes them (returning to active pipeline state) or terminates them (setting them to terminal state). This prevents the operator from creating unlimited projects while ignoring halted ones.

**Write Atomicity:** All state file writes (`status.json`, `polish_state.json`, `chat_history.json`) use atomic write — write to a temporary file in the same directory, then rename to the target path. This prevents partial writes from corrupting state on crash. The project state module (Task 3) implements this as the default write behavior for all state files.

| File | Written When | Schema |
|---|---|---|
| `status.json` | Every phase transition and state change | Tracks project name, current phase, deliverable type, assigned agent, timestamps, and halt reason. Full schema in build spec. |
| `polish_state.json` | After each Phase 4 iteration | Iteration number, error counts, convergence trajectory, tests passed (null for plan mode), completed flag, halt reason, timestamp. Full schema in build spec. |
| `polish_log.md` | Appended after each Phase 4 iteration | Human-readable iteration log |
| `chat_history.json` | Appended after each chat message (Phases 1–2, Phase 3 stuck recovery, Phase 4 halt recovery) | Array of timestamped messages (role, content, phase). On crash, chat resumes from last message. Cleared after each phase advancement confirmation (Phase 1 → Phase 2 and Phase 2 → Phase 3). Phase 3→4 is automatic and does NOT clear chat history — any Phase 3 stuck recovery messages persist into Phase 4. Phase 3 and Phase 4 recovery conversations are also persisted. Chat history is never cleared on pipeline completion (`done`) or halt. The full Phase 3 and Phase 4 chat history (including any recovery conversations) persists in the completed project for human reference. |

**`polish_log.md` entry format:** Each iteration appends a human-readable summary including error counts, guard evaluations, issues found, and fixes applied. Full entry format in build spec.

### UI

**ThoughtForge Chat (Built):** Lightweight web chat interface. (A terminal-based alternative is deferred — not a current build dependency.) Primary use: Phases 1–2 (brain dump intake, spec building). Also used for Phase 3 stuck recovery (provide input, terminate) and Phase 4 halt recovery (resume, override, terminate). Per-project chat thread, file/resource dropping, AI messages labeled by phase, corrections via chat, advancement via Confirm button. During stuck and halt recovery, the chat presents the current state context and the available recovery options — no free-form AI conversation. The chat interface includes a project list sidebar showing all active projects with their current phase. The human clicks a project to open its chat thread. New projects are created from this list via a "New Project" action. The active project's chat thread occupies the main panel.

**Mid-Stream Project Switch:** If the human switches projects while an AI response is streaming, the client stops rendering the stream for the previous project's chat. Server-side processing continues uninterrupted — the AI response completes and is persisted to `chat_history.json` regardless of client-side display state. When the human returns to the project, the completed response is visible in the chat history.

**Browser Compatibility:** The chat interface targets modern evergreen browsers (Chrome, Firefox, Edge, Safari — current and previous major version). No IE11 or legacy browser support. ES6+ JavaScript features and native WebSocket API are assumed available.

**WebSocket Disconnection:** The client auto-reconnects and syncs state from the server on reconnect. Detailed reconnection behavior is in the build spec.

**Prompt Management:** The chat interface includes a Settings button that opens a prompt editor. All pipeline prompts — brain dump intake, review, fix, and any future prompts — are listed, viewable, and editable by the human. Edits apply globally (all future projects use the updated prompts). Per-project prompt overrides are deferred. Not a current build dependency. Prompts are stored as external files in a `/prompts/` directory, not embedded in code. The prompt editor reads from and writes to these files.

**Concurrent edit handling:** The prompt editor uses a last-write-wins model with no conflict detection. Since this is a single-operator tool, concurrent tab edits are the operator's responsibility.

**Prompt file write failure:** If the prompt editor cannot write to a file, the Settings UI displays an error message identifying the file and the error. The failed edit is not applied — the human must resolve the file system issue and retry. No partial writes — the prompt editor uses the same atomic write strategy as state files.

**Prompt file list refresh:** The Settings UI reads the `/prompts/` directory listing each time it is opened. If a prompt file is deleted externally while the editor is open, saving to the deleted file creates it anew (same atomic write behavior). No file locking — the single-operator model makes this acceptable.

**Vibe Kanban Dashboard (Integrated, Not Built):** Columns map to `status.json` phases: Brain Dump → Distilling → Human Review → Spec Building → Building → Polishing → Done. `Distilling` and `Human Review` are separate Kanban columns representing Phase 1 sub-states — the card moves from Brain Dump → Distilling → Human Review as the phase progresses. "Confirmed" is not a separate column — confirmation advances the card from Human Review to the next phase. Cards with `halted` status remain in their current column with a visual halted indicator; "Halted" is a card state, not a column. Cards with `halt_reason: "human_terminated"` display a distinct visual indicator (e.g., strikethrough or "Terminated" badge) to distinguish permanently stopped projects from recoverable halts that await human action. (Authoritative field values are in the build spec Action Button Behavior table.) The specific visual treatment is a UI implementation detail. Each card = one project. Shows agent, status, parallel execution.

Phase 2 uses a single `spec_building` state for both AI proposal and human correction cycles. On the Kanban board, the card remains in the Spec Building column for the duration of Phase 2. The halted indicator (if the project is halted during Phase 2) provides the only visual distinction. If finer-grained Phase 2 status visualization is needed, it is deferred.

**Per-Card Stats:** Created timestamp, time per phase, total duration, status, and agent used are provided by Vibe Kanban's built-in dashboard. Polish loop metrics (iteration count, convergence trajectory, final error counts) are read from `polish_state.json` in each project directory. ThoughtForge does not push stats to Vibe Kanban — Vibe Kanban reads the project files directly.

**Plan vs. Code Column Display:** Plan mode cards pass through the same Kanban columns. The "Building" column represents Phase 3 (autonomous build) for both deliverable types — document drafting for Plans, coding for Code. Column labels are not mode-specific. The card's `deliverable_type` field in `status.json` distinguishes the two in the dashboard.

**Agent Performance Comparison:** Vibe Kanban's dashboard surfaces timing and agent data natively. ThoughtForge enables comparison by writing iteration count, convergence trajectory, and final error counts to `polish_state.json`, which Vibe Kanban reads per-card.

### Future Extensibility: MCP

Orchestrator core actions (create project, check status, read polish log, trigger phase advance, read convergence state) are clean standalone functions with no CLI-specific coupling. Wrapping as MCP tools later is a thin adapter, not a refactor.

---

## Design Decisions

| # | Decision | Rationale |
|---|----------|-----------|
| 1 | Dual deliverable types: Plan and Code | Tool handles both documents and software via plugin architecture |
| 2 | Pipeline chaining: Plan must be complete before Code | Two separate runs. Plan polished and human-approved before becoming code input |
| 3 | Each project gets its own local git repository (git init, no remote) | Clean isolation, no shared mutable state |
| 4 | Chat-based corrections, button-based confirmation | Natural corrections, unambiguous phase advancement |
| 5 | Acceptance criteria in `constraints.md` | Prevents polish loop from missing what was asked for |
| 6 | Zod for structured output validation | Single-source schema, auto-validation, clear errors |
| 7 | Polish state persistence | `polish_state.json` enables crash recovery |
| 8 | No agent frameworks | Vibe Kanban handles spawning, ThoughtForge handles logic |
| 9 | Structured Phase 1 distillation prompt | Reduces correction rounds from 5 to 1-2 |
| 10 | Plan mode hard-blocks code execution via plugin safety rules | Orchestrator-level enforcement, not prompt-level |
| 11 | Code mode requires logging and tests | Logging mandatory, acceptance criteria must have tests |
| 12 | Plan Completeness Gate on Code mode entry | AI assesses plan readiness, redirects if incomplete |
| 13 | All plans follow OPA Framework | Structural requirement and review criterion |
| 14 | Vibe Kanban as execution layer | Cuts build scope roughly in half |
| 15 | Multi-agent support | Not locked to one provider, agents compared on same task |
| 16 | ntfy.sh with abstraction layer | Open source, self-hostable, extensible via config |
| 17 | Zod over hand-written validation | MIT, TypeScript-first, standard in Node.js ecosystem |
| 18 | MCP-ready architecture (design-time only) | Clean functions now, thin adapter later |
| 19 | Handlebars for Plan mode templates | Fixed OPA skeleton, AI can't break structure |
| 20 | Plugin architecture for deliverable types | New type = new folder, orchestrator unchanged |
| 21 | OSS discovery with qualification scorecard | 8-signal assessment before recommending any tool |

---

## Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Polish loop never converges | Medium | High | Convergence guards (hallucination, fabrication, max iterations) halt and notify. Stagnation treated as successful plateau. |
| AI ignores plan mode safety rules | Low | High | Orchestrator-level enforcement via plugin safety-rules.js, not prompt-level |
| Vibe Kanban CLI changes break integration | Medium | Medium | All calls through `vibekanban-adapter.js` — single update point |
| Agent timeout blocks loop indefinitely | Medium | High | Configurable timeout (default 300s), subprocess killed on exceed |
| Review JSON malformed | Medium | Low | Zod validation + 2 retries, then halt |

---

## Configuration

| Config Area | What's Configurable | Defaults |
|---|---|---|
| Polish loop | Convergence thresholds: `critical_max` (0), `medium_max` (3), `minor_max` (5) — maximum allowed counts, inclusive. Max iterations (50). Stagnation limit (3). Malformed output retries (2). | See `config.yaml` template in build spec |
| Concurrency | Max parallel runs | See `config.yaml` template in build spec |
| Notifications | Channel selection (ntfy, telegram, etc.), channel-specific settings | See `config.yaml` template in build spec |
| Resource Connectors | Connector selection (Notion, Google Drive, etc.), per-connector credentials and settings | See `config.yaml` template in build spec |
| Agents | Default agent, call timeout, per-agent command and flags | See `config.yaml` template in build spec |
| Templates | Plan mode templates located at `./plugins/plan/templates/` by convention (inside the plan plugin directory). Cross-plugin template directory config deferred — not a current build dependency. | See `config.yaml` template in build spec |
| Plugins | Plugin directory path | See `config.yaml` template in build spec |
| Prompts | Prompt directory path, individual prompt files | See `config.yaml` template in build spec |
| Vibe Kanban | Enabled toggle | See `config.yaml` template in build spec |
| Server | Web chat interface host and port | See `config.yaml` template in build spec |

**Config reload behavior:** `config.yaml` is read once at server startup and cached in memory for the duration of the server process. Changes to `config.yaml` require a server restart to take effect. The one exception is `vibekanban.enabled`, which is read at each VK operation (already specified in VK toggle behavior). Hot-reloading of config is deferred — not a current build dependency.

**Connector and Notification URL Validation:**

URL validation policy: validate connector and notification URLs at startup for configuration errors; handle failures gracefully at runtime. Implementation details are in the build spec.

**Credential Handling:** API tokens and credential paths in `config.yaml` are stored in plaintext. This is acceptable for v1 as a single-operator local tool. The operator is responsible for file system permissions on `config.yaml`. Credential encryption, secret vaults, and environment variable injection are deferred — not a current build dependency.

**Config Validation:** On startup, the config loader validates `config.yaml` against the expected schema. If the file is missing and `config.yaml.example` exists, the example is copied to `config.yaml` and the server logs that a default config was created. If neither file exists, the server exits with an error message specifying the expected file path. If the file contains invalid YAML syntax or values that fail schema validation (wrong types, out-of-range numbers, missing required keys), the server exits with a descriptive error identifying the invalid key and expected format. No partial loading or default fallback for malformed config — the operator must fix the file. Validation uses the same Zod-based approach as review JSON validation.

Full `config.yaml` with all keys and structure in build spec.

---

*Template Version: 1.0 | Last Updated: February 2026*
