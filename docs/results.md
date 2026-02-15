I've now read all four documents in full. Let me produce the review.

---

# ThoughtForge Plan Review — Findings

## 1. Writing That's Unclear

**[Minor] Design Spec, Phase 1 Error Handling — "Connector failure during distillation" redundancy**

The standalone paragraph "Connector failure during distillation" (design spec line 124) restates behavior already covered by the error handling table entries for connector authentication failure and connector target not found. The standalone paragraph adds one detail (no need to re-click Distill), but its relationship to the table entries is confusing — a reader could think it's a different scenario.

**Replacement:** Delete the standalone paragraph. Add a parenthetical to both connector error table entries:

| Connector authentication failure (expired token, missing credentials) | Log the failure, notify the human in chat specifying which connector failed and why, and proceed with distillation using available inputs (if distillation is already in progress, no re-click of Distill is required). Do not halt the pipeline. |
| Connector target not found (deleted page, revoked access, invalid URL) | Log the failure, notify the human in chat specifying which resource could not be retrieved, and proceed with distillation using available inputs (if distillation is already in progress, no re-click of Distill is required). |

---

**[Minor] Design Spec, Phase 4 Convergence Guards — Hallucination guard wording**

The hallucination guard description says "Total error count increases by more than the configured spike threshold after at least the configured minimum number of consecutive iterations with decreasing total error count." The design spec says "configured spike threshold" and "configured minimum number" but doesn't name the config keys or link to where they're defined. The reader has to discover in the build spec that the spike threshold is >20% and the minimum trend length is 2. The design spec should at least name the parameters.

**Replacement:**
> Total error count increases by more than the configured spike threshold (`hallucination_spike_threshold`, defined in build spec) after at least the configured minimum number of consecutive iterations with decreasing total error count (`hallucination_min_trend`, defined in build spec).

---

**[Minor] Design Spec, Phase 2 — "AI evaluates intent.md for..." list ambiguity**

Step 2 lists six categories the AI evaluates for ("missing dependencies, unrealistic constraints, scope gaps, internal contradictions, unvalidated assumptions, and ambiguous priorities") but doesn't clarify whether this is exhaustive or representative. A builder could wonder if the AI should also check for other issues.

**Replacement:**
> AI evaluates `intent.md` for issues including but not limited to: missing dependencies, unrealistic constraints, scope gaps, internal contradictions, unvalidated assumptions, and ambiguous priorities. Each flagged issue is presented to the human with specific reasoning. The AI does not rubber-stamp — it must surface concerns even if the human's intent seems clear.

---

**[Minor] Design Spec, Technical Design — "VS Code integration" vs "VS Code extension"**

Line 401 says "VS Code integration" while line 441 says "VS Code extension." These refer to the same Vibe Kanban capability but use different terms.

**Replacement:** Use "VS Code extension" consistently. Change line 401 to:
> **Vibe Kanban** is the execution and visualization layer — kanban board, parallel task execution, agent spawning, git worktree isolation, dashboard, VS Code extension. It runs and displays the work.

---

**[Minor] Design Spec, Locked File Behavior — "static after creation" asymmetry not immediately obvious**

The locked file section explains that `constraints.md` is hot-reloaded while `spec.md` and `intent.md` are read once and cached in memory. But the consequence — that manual edits to `spec.md`/`intent.md` are invisible during active pipeline execution but ARE picked up on restart/resume — is buried in a long paragraph. This is an important operational behavior.

**Replacement:** Add a concise summary after the detailed explanation:
> **In short:** Editing `constraints.md` during Phase 4 works. Editing `spec.md` or `intent.md` during active pipeline execution has no effect. Editing them while the project is halted works if the project is subsequently resumed.

---

**[Minor] Execution Plan, Task 12 — Dense dependency description**

Task 12's description packs too many behaviors into one sentence: "Implement Phase 2: spec building with mode-specific behavior (Plan mode: propose OPA-structured plan sections; Code mode: propose architecture/language/framework/tools with OSS discovery integration from Task 25), AI challenge of weak or risky decisions in `intent.md` (does not rubber-stamp), constraint discovery, acceptance criteria extraction (5–10 per design spec), human review/override of proposed decisions, human review of acceptance criteria, Unknown/Open Question resolution validation gate (block Confirm if unresolved items remain), Confirm to advance."

A builder reading this task will struggle to verify completeness against the design spec. This is a communication problem, not a content gap.

**Replacement:** Break into a numbered list within the task description:
> Implement Phase 2: spec building.
> 1. Mode-specific proposal (Plan: OPA-structured plan sections; Code: architecture/language/framework/tools with OSS discovery from Task 25)
> 2. AI challenge of weak or risky decisions in `intent.md` (does not rubber-stamp)
> 3. Constraint discovery
> 4. Acceptance criteria extraction (5–10 per design spec)
> 5. Human review/override of proposed decisions and acceptance criteria
> 6. Unknown/Open Question resolution validation gate (block Confirm if unresolved items remain)
> 7. Confirm to advance

---

## 2. Genuinely Missing Plan-Level Content

**[Major] Design Spec — No specification of how Phase 4 fix agent handles plan mode document modifications**

The design spec describes fix agent context assembly for Code mode in detail (codebase files referenced in issue `location` fields). For Plan mode, it says only "the current plan document." But the plan is a single Markdown file. How does the fix agent apply targeted fixes to a single document? Does it receive the full document and return the full document? Does it return a diff? The code mode fix path is clear (files identified by `location` field), but plan mode fix mechanics are unspecified at the plan level.

**Proposed content to add** (after "Fix agent context assembly" in Phase 4):
> **Plan mode fix interaction:** The fix agent receives the full plan document and the JSON issue list. It returns the complete updated plan document with fixes applied. The orchestrator replaces the existing plan file with the returned content. The fix agent does not return diffs or partial documents — full document replacement ensures structural integrity of the OPA template.

---

**[Major] Design Spec — No specification for how the orchestrator knows which file is "the plan deliverable" in Phase 4**

Phase 3 Plan mode outputs a "complete but unpolished plan document (`.md`) in `/docs/`." Phase 4 needs to pass this document to the reviewer and fixer. But `/docs/` also contains `intent.md`, `spec.md`, and `constraints.md`. How does the orchestrator identify which `.md` file in `/docs/` is the plan deliverable vs. the pipeline artifacts?

**Proposed content to add** (in Phase 3 Plan Mode output):
> The plan deliverable filename is `plan.md`, written to `/projects/{id}/docs/plan.md`. This distinguishes it from pipeline artifacts (`intent.md`, `spec.md`, `constraints.md`) in the same directory. The Phase 4 reviewer and fixer reference this fixed filename.

---

**[Major] Design Spec — No specification of how the code mode fix agent applies fixes**

The design spec says the fix agent receives the issue list and relevant codebase files. But it doesn't specify the interaction model: does the fix agent return modified file contents? Does it execute as a coding agent that directly modifies files in the project directory? For plan mode I've flagged the gap above; for code mode the question is different because coding agents (Claude Code, Codex) can directly modify files on disk rather than returning content.

**Proposed content to add** (in Phase 4, after "Fix agent context assembly"):
> **Code mode fix interaction:** The fix agent operates as a coding agent with write access to the project directory. It reads the issue list, modifies the relevant source files directly, and exits. The orchestrator then runs `git add` and commits the changes. The fix agent does not return modified file content — it applies changes in-place, consistent with how coding agents operate during Phase 3.

---

**[Major] Execution Plan — No testing strategy for prompt quality/effectiveness**

The plan has unit tests (mocked) and e2e tests (real agents), but no plan-level mention of how prompt effectiveness is validated. The prompts are the core of the pipeline's intelligence — brain-dump-intake, review, fix, spec-building — and 7 of 9 prompts are "to be drafted by the AI coder." There's no acceptance criteria for prompt quality beyond "the human reviews and edits via the Settings UI." For a plan that depends this heavily on prompt engineering, there should be a stated strategy for validating prompt effectiveness.

**Proposed content to add** (in Execution Plan, after Task Acceptance Criteria section):
> ### Prompt Validation Strategy
>
> Each pipeline prompt ("To be drafted" prompts in build spec) is validated during the end-to-end tests (Tasks 51–53). The e2e tests serve as the primary prompt quality gate — if the pipeline produces acceptable deliverables end-to-end, the prompts are working. If an e2e test fails due to poor AI output quality (rather than code bugs), the prompt is revised and the test re-run. Prompt iteration is expected during Build Stage 8 and is not a sign of implementation failure.

---

**[Minor] Design Spec — No mention of what happens to resources after Phase 1**

Resources in `/resources/` are consumed during Phase 1 distillation. The design spec doesn't state whether they remain in place, are cleaned up, or are referenced again. The Plan Completeness Gate scans `/resources/` for plan documents, so they clearly persist. But for non-plan resources (images, PDFs, code files), the lifecycle is unstated.

**Proposed content to add** (in Phase 1, after step 11b):
> **Resource lifecycle:** Files in `/resources/` persist for the lifetime of the project. They are not deleted or moved after Phase 1 consumption. The Plan Completeness Gate (Code mode entry) scans `/resources/` for plan documents. Non-plan resources remain for human reference but are not re-consumed by later pipeline phases.

---

**[Minor] Execution Plan — No dependency on Node.js ≥18 in Task 1b prerequisite check**

The Dependencies & Blockers table lists "Node.js version ≥18 LTS" as a dependency. Task 1b mentions "prerequisite check (Node.js version, agent CLIs on PATH)" but doesn't specify what Node.js version to check for. The builder needs to know the minimum version to validate.

**Proposed content to add** (in Task 1b description):
> prerequisite check (Node.js ≥18 LTS, agent CLIs on PATH)

---

**[Minor] Design Spec — Chat history truncation for Phase 3 and Phase 4 recovery conversations is unspecified**

The design spec specifies truncation behavior for Phase 1 (retain brain dump) and Phase 2 (retain initial proposal) chat histories when they exceed the agent context window. Phase 3 stuck recovery and Phase 4 halt recovery also use chat, and the spec says Phase 3→4 does NOT clear chat history. If a project has multiple stuck/halt recovery conversations across Phases 3 and 4, this accumulated chat history could grow large. No truncation anchor is specified for these phases.

**Proposed content to add** (after "Phase 2 Chat History Truncation"):
> **Phase 3–4 Chat History Truncation:** If Phase 3 or Phase 4 recovery chat history exceeds the agent context window, the agent invocation layer truncates older messages from the beginning, retaining the most recent messages. There is no anchoring message for these phases — unlike Phases 1–2, recovery conversations do not have a structural anchor that must be preserved. A warning is logged when truncation occurs.

---

## 3. Build Spec Material That Should Be Extracted

**[Minor] Design Spec, Phase 1 — "realign from here" algorithm detail**

The design spec (line 92) describes the realign algorithm: "The AI rolls back to the most recent substantive correction and re-distills from the original brain dump plus all corrections up to that point. If no corrections exist yet, the command is ignored with a prompt to provide a correction first. Implementation algorithm in build spec." This correctly defers to the build spec. However, the design spec also says "Scan backwards through `chat_history.json` past any sequential 'realign from here' commands" — this level of algorithmic detail (scan direction, skip behavior) belongs in the build spec, not the design spec. The design spec already says "Implementation algorithm in build spec."

**Recommendation:** Remove from the design spec: "The AI rolls back to the most recent substantive correction and re-distills from the original brain dump plus all corrections up to that point. If no corrections exist yet, the command is ignored with a prompt to provide a correction first." Replace with: "The AI re-distills from the original brain dump plus corrections up to a rollback point. Algorithm details in build spec."

---

**[Minor] Design Spec, Phase 4 — Stagnation guard Levenshtein similarity threshold**

The design spec (line 322) includes "rotation threshold and similarity measure defined in build spec" — correctly deferring. But then in the same paragraph it describes the mechanism: "old issues resolved, new issues introduced at the same rate." This is sufficient for the design spec. The issue is that the build spec (line 303–304) defines the similarity measure as "Levenshtein similarity ≥ 0.8 on the `description` field" and the rotation threshold as "fewer than 70% of current issues find a match." These are correctly in the build spec. No action needed — flagged for completeness but the current placement is correct.

**No extraction needed.** This is already properly split.

---

**[Minor] Design Spec, Technical Design — Agent adapter output normalization details**

The design spec (line 478) says "Agent-specific adapters normalize output format differences. Invocation details in build spec." The build spec then provides the `AgentResponse` TypeScript interface. This split is correct. However, the design spec's "Agent Communication" section also specifies "prompt content is passed via stdin pipe or file — never through shell argument expansion" — this is a security design constraint that belongs in the design spec. The implementation detail of *how* the adapter strips wrapper text belongs in the build spec. Current split is correct.

**No extraction needed.** The current placement is appropriate.

---

**[Minor] Design Spec, Phase 1 — Chat history truncation algorithm detail**

The design spec (line 126) specifies the full truncation algorithm: "The original brain dump messages are identified as all human messages before the first Distill button press in the chat history. During truncation, these messages are always retained at the beginning of the context, followed by the most recent messages that fit within the remaining window. Messages between the brain dump and the retained recent messages are dropped." This is implementation-level algorithmic detail (message identification logic, windowing strategy, drop behavior) that belongs in the build spec alongside the Realign Algorithm.

**Recommendation:** In the design spec, replace the algorithm detail with: "If a single phase's chat history exceeds the agent's context window, the agent invocation layer truncates older messages while always retaining the original brain dump and the most recent messages. Truncation algorithm in build spec." Move the full algorithm to a new "Chat History Truncation Algorithm" section in the build spec, alongside the existing Realign Algorithm section.

---

**Summary of findings:**

| Severity | Count |
|---|---|
| Critical | 0 |
| Major | 4 |
| Minor | 12 |
