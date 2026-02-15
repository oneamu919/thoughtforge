# Apply Review Findings from results.md

You are an AI coder. Apply every change listed below to the source files. Each change is taken directly from the review findings in `docs/results.md`. Do not interpret or improvise — apply the replacements, additions, and extractions exactly as specified.

Read all three target files before editing. After all changes are applied, git commit and sync to remote.

---

## Target Files

- `docs/thoughtforge-design-specification.md` (referred to as "Design Spec")
- `docs/thoughtforge-build-spec.md` (referred to as "Build Spec")
- `docs/thoughtforge-execution-plan.md` (referred to as "Execution Plan")

Read all three files before making any edits.

---

## Changes to Design Spec (`docs/thoughtforge-design-specification.md`)

### Change 1 — Phase 1 step 11b, deliverable_type derivation (Minor)

**Find:**
> The `deliverable_type` field in `status.json` is set to `"plan"` or `"code"`, derived from the Deliverable Type section of the confirmed `intent.md`.

**Replace with:**
> The `deliverable_type` field in `status.json` is set to `"plan"` or `"code"` by parsing the Deliverable Type section of the confirmed `intent.md`. The AI's distillation always states exactly one of 'Plan' or 'Code' as the first word of this section. The orchestrator string-matches that word to set the field.

---

### Change 2 — Phase 4 Stagnation guard description (Minor)

**Find:**
> Same total error count persisting for a number of consecutive iterations equal to or greater than the configured stagnation limit AND issue replacement detected (rotation threshold and similarity measure defined in build spec). This indicates the reviewer is finding new issues to replace resolved ones, producing a plateau rather than genuine progress.

**Replace with:**
> Same total error count for a configured number of consecutive iterations (stagnation limit) AND issue rotation detected (old issues resolved, new issues introduced at the same rate — rotation threshold and similarity measure defined in build spec). This combination indicates the deliverable has reached a quality plateau where the reviewer is cycling through cosmetic or subjective issues rather than finding genuine regressions. Treated as converged.

---

### Change 3 — Fabrication guard wording (Minor)

**Find:**
> the system had previously reached counts no greater than a configured multiplier of the convergence thresholds in at least one prior iteration

**Replace with:**
> in at least one prior iteration, every severity category was at or below 2x its convergence threshold (e.g., critical ≤0, medium ≤6, minor ≤10) — indicating the deliverable was near-converged

---

### Change 4 — Locked File Behavior for constraints.md (Minor)

**Find the single paragraph that starts with:**
> `constraints.md` (hot-reloaded): The pipeline re-reads `constraints.md` at the start of each Phase 4 iteration...

**Replace that entire paragraph with these two sub-bullets:**

- **`constraints.md` — hot-reloaded:** The pipeline re-reads `constraints.md` at the start of each Phase 4 iteration. Manual human edits to acceptance criteria or review rules are picked up automatically. If `constraints.md` is unreadable or missing at the start of a Phase 4 iteration, the iteration halts and the human is notified.
- **`constraints.md` — unvalidated after creation:** If the human restructures the file (missing sections, reordered content, added sections), ThoughtForge passes it to the AI reviewer as-is without schema validation. If the human empties the Acceptance Criteria section, the reviewer proceeds with whatever criteria remain (which may be none). This is treated as an intentional human override — the pipeline does not validate criteria presence after the initial Phase 2 write.

---

### Change 5 — Phase 2 acceptance criteria clarification (Minor)

**Find:**
> AI derives 5–10 acceptance criteria from the objective, assumptions, and constraints in `intent.md`

**Replace with:**
> AI derives 5–10 acceptance criteria from the objective, assumptions, and constraints in `intent.md`. For Plan mode, criteria assess document completeness, logical coherence, and actionability. For Code mode, criteria assess functional requirements that map to testable acceptance tests in Phase 3.

---

### Change 6 — Chat UI Frontend clarification (Minor)

**Find:**
> Server-rendered HTML + vanilla JavaScript

**Replace with:**
> Server-rendered initial HTML page with vanilla JavaScript for dynamic UI updates. The chat interface is a single page — navigation between projects and settings is handled client-side via JavaScript DOM manipulation. No full-page reloads after initial load.

---

### Change 7 — Add Structured Response Validation section (CRITICAL)

**Location:** In the Agent Communication section, after the existing "Failure handling" subsection.

**Add this new subsection:**

**Structured Response Validation (Non-Review):**
Phase 3 plan builder responses must conform to the `PlanBuilderResponse` schema. The orchestrator validates the response after each builder invocation. On parse failure: retry once. On second failure: halt and notify human. Phase 1 distillation and Phase 2 spec-building responses are natural language (not structured JSON) and do not require schema validation — the AI's output is presented directly in chat for human review and correction.

---

### Change 8 — Add Git Initialization Failure behavior (Major)

**Location:** In Phase 1, after the "Project Initialization" step (step 0).

**Add:**

**Git Initialization Failure:** If `git init` fails during project creation (permissions error, disk space, git not installed), project creation is aborted. The partially created directory is deleted. The human is notified: "Project creation failed: git initialization error. Verify git is installed and the projects directory is writable." No project state files are written.

---

### Change 9 — Add Ambiguous Deliverable Type behavior (Minor)

**Location:** In Phase 1, after step 6 (or in the brain dump intake prompt section).

**Add:**

**Ambiguous Deliverable Type:** If the brain dump contains signals for both Plan and Code, the AI defaults to Plan and flags the ambiguity in the Open Questions section: "Brain dump describes both planning and implementation. Classified as Plan — confirm or change to Code." The human resolves during the correction cycle.

---

### Change 10 — Add Manual Project Deletion behavior (Minor)

**Location:** In the "Project Lifecycle After Completion" section.

**Add:**

**Manual Project Deletion (Active Project):** If a project directory is deleted while the server is running and the project is in a non-terminal state, the server will encounter file system errors on the next operation for that project. These are handled by the existing cross-cutting file system error handling: halt and notify. The project list sidebar will show the project until the server is restarted (server restart scans `/projects/` and removes stale entries). Graceful handling of mid-run directory deletion is deferred — not a current build dependency.

---

### Change 11 — Shorten "realign from here" to behavior-level only (Minor)

**Find:**
> Human can type 'realign from here' in chat. The AI resets to the most recent substantive correction, excluding all subsequent conversation from the working context (retained in `chat_history.json` for audit trail), and re-distills from the original brain dump plus all corrections up to and including that baseline correction. If no corrections exist yet, the command is ignored with a prompt to provide a correction first. Implementation algorithm in build spec.

**Replace with:**
> Human can type 'realign from here' in chat. The AI rolls back to the most recent substantive correction and re-distills from the original brain dump plus all corrections up to that point. If no corrections exist yet, the command is ignored with a prompt to provide a correction first. Implementation algorithm in build spec.

---

### Change 12 — Move Notification JSON example to build spec (Minor)

**Find the JSON example object in the Notification Content section** (the one containing `project_id: "{id}", project_name: "Wedding Plan"` etc.)

**Remove it from the design spec.** Keep only the summary-string examples in the design spec. The JSON example will be added to the build spec in Change 15 below.

---

## Changes to Build Spec (`docs/thoughtforge-build-spec.md`)

### Change 13 — Add AgentResponse interface (Major)

**Location:** In the Agent Communication section, after the "Output Normalization" subsection.

**Add:**

**Normalized Agent Response:**
```typescript
interface AgentResponse {
  success: boolean;      // true if agent exited 0 and produced non-empty output
  output: string;        // Cleaned agent stdout — wrapper text and metadata stripped
  exitCode: number;      // Raw process exit code
  timedOut: boolean;     // true if killed by timeout
}
```
All agent adapters return this structure. The orchestrator and plugins consume only `AgentResponse`, never raw subprocess output.

---

### Change 14 — Add ThoughtForge Build Toolchain section (Major)

**Location:** Before the Task Breakdown section, or as a new section titled "Build Toolchain."

**Add:**

**ThoughtForge Build Toolchain:**
- Test framework: Vitest (or Jest — decide before build starts)
- Test execution: `npm test` runs all unit tests; `npm run test:e2e` runs end-to-end tests
- E2E tests require at least one configured agent CLI on PATH
- All unit tests use mocked dependencies (no real agent calls, no real file I/O for state tests)

---

### Change 15 — Add Notification JSON example (moved from design spec)

**Location:** In the "Notification Payload Schema" section, near the `NotificationPayload` TypeScript interface.

**Add the JSON example object that was removed from the design spec in Change 12.** Paste it as-is alongside the interface definition.

---

## Changes to Execution Plan (`docs/thoughtforge-execution-plan.md`)

### Change 16 — Replace language dependency row with design decision (Minor)

**Find in the Dependencies & Blockers table the row:**
> Language: TypeScript | Dependency | ... | Implied by Zod schemas and interface definitions in build spec. Confirm or document as JavaScript-only with JSDoc types.

**Remove that row from the table.** Add the following as a design decision (in the Technical Design section, or at the top of the execution plan if no such section exists):

**Implementation language:** The codebase uses TypeScript. Zod schemas and interface definitions in the build spec use TypeScript syntax. The build toolchain includes `tsc` compilation. (If JavaScript-only is preferred, replace TypeScript interfaces with JSDoc type annotations and use Zod's runtime-only validation.)

---

### Change 17 — Add VK CLI verification task to Build Stage 5 (Major)

**Location:** Build Stage 5's task table, insert as the first task.

**Add this row:**

| # | Task | Owner | Depends On | Estimate | Status |
|---|------|-------|------------|----------|--------|
| 25a | Verify Vibe Kanban CLI interface: confirm actual commands, flags, and output format match assumed interface in build spec. Update build spec if discrepancies found. | — | — | — | Not Started |

---

### Change 18 — Add parallelism note to Critical Path section (Minor)

**Location:** In the Critical Path section, after the secondary critical chain description.

**Add:**

**Parallelism note:** Tasks 41-42 (agent invocation layer) gate every task that calls an AI agent. These should be prioritized immediately after Task 1 completes, as they are the single biggest bottleneck across both critical paths. All Build Stage 1 foundation tasks (2-6a) and Stage 7 tasks (41-44) can run in parallel once Task 1 is done.

---

## After All Changes Are Applied

1. Re-read each modified file to confirm no formatting is broken (unclosed tables, orphaned headers, broken markdown).
2. Git add only files you actually modified:
   ```bash
   git add docs/thoughtforge-design-specification.md docs/thoughtforge-build-spec.md docs/thoughtforge-execution-plan.md
   ```
3. Commit with message: `Apply review findings`
4. Push to remote: `git push`
5. Confirm the push succeeded. Do not leave commits unpushed.
