Now I have all four documents fully read. Let me produce the review.

---

# Plan Review — ThoughtForge Pipeline Tool

Reviewing: `thoughtforge-design-specification.md`, `thoughtforge-build-spec.md`, `thoughtforge-execution-plan.md`
(Requirements brief read for context.)

---

## 1. Writing That's Unclear

**[Minor]** Design spec, Phase 1, step 11b — "derived from the Deliverable Type section of the confirmed `intent.md`" is ambiguous about *how* derivation works.

> **Current:** "The `deliverable_type` field in `status.json` is set to `"plan"` or `"code"`, derived from the Deliverable Type section of the confirmed `intent.md`."
>
> **Replacement:** "The `deliverable_type` field in `status.json` is set to `"plan"` or `"code"` by parsing the Deliverable Type section of the confirmed `intent.md`. The AI's distillation always states exactly one of 'Plan' or 'Code' as the first word of this section. The orchestrator string-matches that word to set the field."

---

**[Minor]** Design spec, Phase 4, Stagnation guard description — the relationship between "same total error count" and "issue replacement" is confusing because the stagnation guard is described as a *success* outcome but the conditions read like a problem.

> **Current:** "Same total error count persisting for a number of consecutive iterations equal to or greater than the configured stagnation limit AND issue replacement detected (rotation threshold and similarity measure defined in build spec). This indicates the reviewer is finding new issues to replace resolved ones, producing a plateau rather than genuine progress."
>
> **Replacement:** "Same total error count for a configured number of consecutive iterations (stagnation limit) AND issue rotation detected (old issues resolved, new issues introduced at the same rate — rotation threshold and similarity measure defined in build spec). This combination indicates the deliverable has reached a quality plateau where the reviewer is cycling through cosmetic or subjective issues rather than finding genuine regressions. Treated as converged."

---

**[Minor]** Design spec, Fabrication guard — "the system had previously reached counts no greater than a configured multiplier of the convergence thresholds" is hard to parse.

> **Current:** "the system had previously reached counts no greater than a configured multiplier of the convergence thresholds in at least one prior iteration"
>
> **Replacement:** "in at least one prior iteration, every severity category was at or below 2x its convergence threshold (e.g., critical ≤0, medium ≤6, minor ≤10) — indicating the deliverable was near-converged"

---

**[Minor]** Design spec, Locked File Behavior — the sentence about `constraints.md` being "hot-reloaded" and then the long clause about what happens if the human restructures it runs on for too long. Break it into two behaviors.

> **Current (single paragraph starting with):** "`constraints.md` (hot-reloaded): The pipeline re-reads `constraints.md` at the start of each Phase 4 iteration..."
>
> **Replacement — split into two sub-bullets:**
>
> - **`constraints.md` — hot-reloaded:** The pipeline re-reads `constraints.md` at the start of each Phase 4 iteration. Manual human edits to acceptance criteria or review rules are picked up automatically. If `constraints.md` is unreadable or missing at the start of a Phase 4 iteration, the iteration halts and the human is notified.
> - **`constraints.md` — unvalidated after creation:** If the human restructures the file (missing sections, reordered content, added sections), ThoughtForge passes it to the AI reviewer as-is without schema validation. If the human empties the Acceptance Criteria section, the reviewer proceeds with whatever criteria remain (which may be none). This is treated as an intentional human override — the pipeline does not validate criteria presence after the initial Phase 2 write.

---

**[Minor]** Execution plan, Dependencies & Blockers table, last row — "Language: TypeScript" with resolution "Implied by Zod schemas and interface definitions in build spec. Confirm or document as JavaScript-only with JSDoc types" is an unresolved question sitting in a dependency table.

> **Current:** "Language: TypeScript | Dependency | — | — | Implied by Zod schemas and interface definitions in build spec. Confirm or document as JavaScript-only with JSDoc types."
>
> **Replacement:** Remove from Dependencies table. Add to the build spec Technical Design section or the execution plan as a design decision: "**Implementation language:** The codebase uses TypeScript. Zod schemas and interface definitions in the build spec use TypeScript syntax. The build toolchain includes `tsc` compilation. (If JavaScript-only is preferred, replace TypeScript interfaces with JSDoc type annotations and use Zod's runtime-only validation.)"

---

**[Minor]** Design spec, Phase 2 — "AI derives 5–10 acceptance criteria from the objective, assumptions, and constraints in `intent.md`" does not clarify whether these are specific to Plan vs. Code mode or universal.

> **Current:** "AI derives 5–10 acceptance criteria from the objective, assumptions, and constraints in `intent.md`"
>
> **Replacement:** "AI derives 5–10 acceptance criteria from the objective, assumptions, and constraints in `intent.md`. For Plan mode, criteria assess document completeness, logical coherence, and actionability. For Code mode, criteria assess functional requirements that map to testable acceptance tests in Phase 3."

---

**[Major]** Design spec, Agent Communication section — "Agent-specific adapters normalize output format differences" doesn't clarify what "internal format" the adapters normalize *to*. The build spec's "Output Normalization" section also says adapters "normalize to ThoughtForge's internal format" without defining it.

> **Current (build spec):** "Agent-specific adapters handle output format differences and normalize to ThoughtForge's internal format."
>
> **Replacement (add to build spec, Agent Communication section, after the Output Normalization subsection):**
>
> **Normalized Agent Response:**
> ```typescript
> interface AgentResponse {
>   success: boolean;      // true if agent exited 0 and produced non-empty output
>   output: string;        // Cleaned agent stdout — wrapper text and metadata stripped
>   exitCode: number;      // Raw process exit code
>   timedOut: boolean;     // true if killed by timeout
> }
> ```
> All agent adapters return this structure. The orchestrator and plugins consume only `AgentResponse`, never raw subprocess output.

---

**[Minor]** Design spec, Chat UI Frontend — "Server-rendered HTML + vanilla JavaScript" — it's unclear whether this means SSR with page refreshes or an SPA with initial HTML that the JS takes over.

> **Current:** "Server-rendered HTML + vanilla JavaScript"
>
> **Replacement:** "Server-rendered initial HTML page with vanilla JavaScript for dynamic UI updates. The chat interface is a single page — navigation between projects and settings is handled client-side via JavaScript DOM manipulation. No full-page reloads after initial load."

---

## 2. Genuinely Missing Plan-Level Content

**[Critical]** No error handling or behavior defined for what happens when the **AI returns content that cannot be parsed as JSON** during non-review steps (Phase 1 distillation, Phase 2 spec proposals, Phase 3 plan builder responses). The review JSON has Zod validation with retry. But the `PlanBuilderResponse` schema, distillation output, and spec-building responses have no specified validation or retry behavior.

> **Proposed addition (Design spec, Agent Communication section, after Failure handling):**
>
> **Structured Response Validation (Non-Review):**
> Phase 3 plan builder responses must conform to the `PlanBuilderResponse` schema. The orchestrator validates the response after each builder invocation. On parse failure: retry once. On second failure: halt and notify human. Phase 1 distillation and Phase 2 spec-building responses are natural language (not structured JSON) and do not require schema validation — the AI's output is presented directly in chat for human review and correction.

---

**[Major]** No specification of **what test framework or test runner** is used for ThoughtForge's own unit and e2e tests (Build Stage 8). The build spec describes the *deliverable's* test runner (`test-runner.js` in the code plugin) but not the tool's own testing infrastructure.

> **Proposed addition (Execution plan, before Task Breakdown, or as a new section "Build Toolchain"):**
>
> **ThoughtForge Build Toolchain:**
> - Test framework: Vitest (or Jest — decide before build starts)
> - Test execution: `npm test` runs all unit tests; `npm run test:e2e` runs end-to-end tests
> - E2E tests require at least one configured agent CLI on PATH
> - All unit tests use mocked dependencies (no real agent calls, no real file I/O for state tests)

---

**[Major]** The design spec describes the **Vibe Kanban CLI commands** in the build spec as "assumed from Vibe Kanban documentation. Verify actual CLI matches before build." But there is no task in the execution plan to actually verify the VK CLI interface before building against it. This is listed as a risk but has no corresponding pre-build verification task.

> **Proposed addition (Execution plan, Build Stage 5, insert as first task):**
>
> | # | Task | Owner | Depends On | Estimate | Status |
> |---|------|-------|------------|----------|--------|
> | 25a | Verify Vibe Kanban CLI interface: confirm actual commands, flags, and output format match assumed interface in build spec. Update build spec if discrepancies found. | — | — | — | Not Started |

---

**[Major]** No defined behavior for **what happens when a project's git operations fail** during project initialization (Task 2 — `git init`). The design spec covers git commit failures during Phase 3→4 transition and Phase 4 iterations, but initialization-time git failure is unaddressed.

> **Proposed addition (Design spec, Phase 1, step 0, after "Project Initialization"):**
>
> **Git Initialization Failure:** If `git init` fails during project creation (permissions error, disk space, git not installed), project creation is aborted. The partially created directory is deleted. The human is notified: "Project creation failed: git initialization error. Verify git is installed and the projects directory is writable." No project state files are written.

---

**[Minor]** No guidance on **how the AI identifies the "Deliverable Type" when brain dump content is ambiguous** — e.g., the human describes both a plan and implementation work in the same dump. The distillation prompt says to "State which one and why you think so" but doesn't say what to do when it's genuinely ambiguous.

> **Proposed addition (Design spec, Phase 1, after step 6, or in the brain dump intake prompt):**
>
> **Ambiguous Deliverable Type:** If the brain dump contains signals for both Plan and Code, the AI defaults to Plan and flags the ambiguity in the Open Questions section: "Brain dump describes both planning and implementation. Classified as Plan — confirm or change to Code." The human resolves during the correction cycle.

---

**[Minor]** No defined behavior for **what happens when the human manually deletes a project directory** while the server is running and the project is active.

> **Proposed addition (Design spec, Project Lifecycle After Completion section):**
>
> **Manual Project Deletion (Active Project):** If a project directory is deleted while the server is running and the project is in a non-terminal state, the server will encounter file system errors on the next operation for that project. These are handled by the existing cross-cutting file system error handling: halt and notify. The project list sidebar will show the project until the server is restarted (server restart scans `/projects/` and removes stale entries). Graceful handling of mid-run directory deletion is deferred — not a current build dependency.

---

**[Minor]** The execution plan's **Critical Path** section lists the longest chain but doesn't note that the secondary critical chain (Code mode) shares the same foundation bottleneck (Task 1) and that Tasks 41-42 gate almost everything.

> **Proposed addition (Execution plan, Critical Path section, after secondary critical chain):**
>
> **Parallelism note:** Tasks 41-42 (agent invocation layer) gate every task that calls an AI agent. These should be prioritized immediately after Task 1 completes, as they are the single biggest bottleneck across both critical paths. All Build Stage 1 foundation tasks (2-6a) and Stage 7 tasks (41-44) can run in parallel once Task 1 is done.

(Note: this is partially stated in the cross-stage dependency note under Build Stage 1, but it deserves explicit emphasis in the Critical Path section where a builder would look for scheduling guidance.)

---

## 3. Build Spec Material That Should Be Extracted

**[Minor]** Design spec, Phase 1, step 9 — the "realign from here" algorithm description includes implementation-level detail (scan backwards, exclude messages, re-distill scope). This is already properly extracted to the build spec's "Realign Algorithm" section, but the design spec *also* contains the full algorithm. The design spec version should be reduced to behavior-level description only.

> **Current (design spec):** "Human can type 'realign from here' in chat. The AI resets to the most recent substantive correction, excluding all subsequent conversation from the working context (retained in `chat_history.json` for audit trail), and re-distills from the original brain dump plus all corrections up to and including that baseline correction. If no corrections exist yet, the command is ignored with a prompt to provide a correction first. Implementation algorithm in build spec."
>
> **This is acceptable** — it already references the build spec. However, the sentence "excluding all subsequent conversation from the working context (retained in `chat_history.json` for audit trail)" is implementation detail that belongs only in the build spec. Shorten to:
>
> **Replacement:** "Human can type 'realign from here' in chat. The AI rolls back to the most recent substantive correction and re-distills from the original brain dump plus all corrections up to that point. If no corrections exist yet, the command is ignored with a prompt to provide a correction first. Implementation algorithm in build spec."

---

**[Minor]** Design spec, Phase 4, Convergence Guards table — includes specific algorithmic parameters like "spike threshold" and "similarity measure" alongside references to "defined in build spec." The design spec should state the *behavior* (what the guard detects), and all parameter values should live exclusively in the build spec.

> The design spec already says "Algorithmic parameters for each guard... are defined in the build spec." But individual guard descriptions in the design spec still mention "spike threshold," "trailing average," "window size" as if they're defined there. These terms are acceptable as behavioral descriptions since the actual *values* are correctly in the build spec. **No extraction needed** — this is borderline but acceptable as written.

---

**[Minor]** Design spec, `status.json` and `polish_state.json` field descriptions are duplicated between the design spec's "Project State Files" section and the build spec schemas. The design spec should describe what each file tracks conceptually; the full schemas with TypeScript interfaces should live only in the build spec.

> **Current (design spec, `polish_state.json` description):** "Iteration number, error counts, convergence trajectory, tests passed (null for plan mode), completed flag, halt reason, timestamp. Full schema in build spec."
>
> This is **already handled correctly** — the design spec gives a summary and references the build spec for the full schema. No change needed.

---

**[Minor]** Build spec, `config.yaml` Template — the inline comments explaining `supports_vision` behavior are implementation guidance embedded in a config template. This is acceptable for a build spec but the comment block after the `agents.available` section reads more like design rationale than config documentation.

> **Current:** "# The `supports_vision` field determines whether image resources are passed to this agent. If `false` or absent, image files are logged as skipped."
>
> This is fine as a config file comment. **No extraction needed.**

---

**[Minor]** Design spec, Notification Content section — the full JSON example object at the bottom (`{ project_id: "{id}", project_name: "Wedding Plan"... }`) is implementation-level detail that belongs in the build spec alongside the `NotificationPayload` TypeScript interface.

> **Recommendation:** Move the JSON example to the build spec's "Notification Payload Schema" section. Keep only the summary-string examples in the design spec.

---

End of review. Total findings: 16 (1 Critical, 4 Major, 11 Minor).
