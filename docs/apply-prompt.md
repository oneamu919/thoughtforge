# Apply Review Findings from results.md

You are an AI coder. Apply every change listed below to the source files. Each change is taken directly from the review findings in `docs/results.md`. Do not interpret or improvise — apply the replacements, additions, and extractions exactly as specified.

Read all target files before editing. After all changes are applied, git commit and sync to remote.

---

## Target Files

- `docs/thoughtforge-design-specification.md` (referred to as "Design Spec")
- `docs/thoughtforge-build-spec.md` (referred to as "Build Spec")
- `docs/thoughtforge-execution-plan.md` (referred to as "Execution Plan")

Read all three files before making any edits.

---

## SECTION 1: Replacements (Unclear Writing)

### Change 1 — Design Spec, Phase 1 Step 3, Connector URL Identification (around line 82) [Minor]

**Find this text:**
> "URLs matching an enabled connector pattern are pulled automatically. URLs matching a disabled connector pattern are ignored. Unrecognized URLs are treated as regular brain dump text."

**Replace with:**
> "The AI matches each URL against the known patterns for enabled connectors:
> - **Match + enabled:** URL is pulled automatically via the connector.
> - **Match + disabled:** URL is silently ignored (not pulled, not treated as text).
> - **No match:** URL is treated as regular brain dump text and included in distillation context."

---

### Change 2 — Design Spec, Stagnation Guard description (around line 334) [Minor]

**Find this text:**
> "The comparison uses total count only — a shift in severity composition at the same total still qualifies as stagnation if the rotation threshold is also met."

**Replace with:**
> "Stagnation compares total error count only, not per-severity breakdowns. A shift in severity composition (e.g., fewer criticals but more minors) at the same total still qualifies as stagnation, provided the rotation threshold is also met."

---

### Change 3 — Design Spec, Fabrication Guard (around line 335) [Minor]

**Find this text (the inline hardcoded math):**
> "specifically: critical ≤ 0 (2 × 0), medium ≤ 6 (2 × 3), minor ≤ 10 (2 × 5) using default config values"

**Replace with:**
> "every severity category was at or below twice its convergence threshold — that is, critical ≤ 2 × `critical_max`, medium ≤ 2 × `medium_max`, minor ≤ 2 × `minor_max` (using default config: ≤0 critical, ≤6 medium, ≤10 minor). These values are derived from `config.yaml` at runtime, not hardcoded."

---

### Change 4 — Design Spec, Phase 3 Code Builder Interaction Model (around line 237) [Minor]

**Find this text:**
> "Since each cycle produces different failing tests, the stuck detector will not trigger on rotating failures."

**Replace with:**
> "If each test-fix cycle produces *different* failing tests (rotating failures rather than the same tests failing repeatedly), the stuck detector does not trigger — it only fires on 3 consecutive cycles with the *identical* set of failing test names."

---

### Change 5 — Design Spec, Locked File Behavior section (around line 166) [Minor]

**Find this text:**
> "On server restart, the in-memory copies are lost."

**Replace with:**
> "On server restart, the orchestrator's in-memory working copies of `spec.md` and `intent.md` (loaded at Phase 3 start) are discarded."

---

### Change 6 — Execution Plan, Critical Path (around line 192) [Minor]

**Find this text:**
> "Task 1 → Task 41 → Task 42 → Task 6a → Task 8 → Task 9 → Task 11 → Task 12 → Task 13 → Task 15 → Task 16 → Task 30 → Tasks 33–37 → Task 51"

**Replace with:**
> "Task 1 → Task 41 → Task 42 → Task 6a → Task 8 → Task 9 → Task 11 → Task 12 → Task 13 → Task 15 → Task 30 → Tasks 33–37 → Task 51
>
> Note: Task 30 depends on Task 17 (plan reviewer) and Task 6c (Phase 3→4 transition), not Task 16 (templates). Task 16 (templates) feeds Task 15 at runtime but is not on the critical path — templates can be created after the builder module. Task 17 runs in parallel with Task 15 and must complete before Task 30."

---

### Change 7 — Build Spec, Code Builder Task Queue section (around line 208) [Minor]

**Find this text:**
> "The exact parsing and ordering logic is an implementation detail of Task 21, but must produce a deterministic task list from the same `spec.md` input"

**Replace with:**
> "The exact parsing and ordering logic is an implementation detail of Task 21, but must produce a deterministic task list from the same `spec.md` input — this ensures crash recovery (re-deriving the task list after restart) produces the same task ordering and can correctly identify which tasks were already completed."

---

### Change 8 — Design Spec, Hallucination Guard notification template (around line 333) [Minor]

**Find the notification message template that says:**
> "Errors trending down then spiked"

**Replace the notification template with:**
> `"Project '{name}' — fix-regress cycle detected. Errors decreased for {N} iterations ({trajectory}) then spiked to {X} at iteration {current}. Review needed."`

---

## SECTION 2: Additions (Missing Plan-Level Content)

### Change 9 — Design Spec, Phase 2, after the Unknowns validation gate (step 7 area) [Critical]

**Add the following new subsection:**

> **Acceptance Criteria Validation Gate:** Before Phase 2 Confirm advances to Phase 3, the orchestrator validates that the Acceptance Criteria section of the proposed `constraints.md` contains at least 1 criterion. If the section is empty, the Confirm button is blocked and the AI prompts the human: "At least one acceptance criterion is required before proceeding. Add acceptance criteria or confirm the AI's proposed set." This gate enforces the minimum at creation time only — after `constraints.md` is written, the human may freely edit it (including emptying the section) per the unvalidated-after-creation policy.

---

### Change 10 — Design Spec, Vibe Kanban Integration Interface section, after the toggle behavior table [Major]

**Add the following paragraph:**

> **Toggle Change During Active Projects:** The `vibekanban.enabled` toggle is read at each operation, not cached at project creation. If VK is disabled after a project was created with VK enabled, subsequent VK status update calls will succeed (updating an existing card) but new project creation will skip card creation. If VK is enabled after a project was created without it, VK status calls will fail (no card exists) and will be logged and ignored per standard VK failure handling. Toggling VK mid-project does not halt or disrupt the pipeline — VK calls are never on the critical path.

---

### Change 11 — Design Spec, Phase 4 Error Handling table [Major]

**Add a new row to the error handling table:**

> | `polish_state.json` unreadable, missing, or invalid at Phase 4 resume | Halt and notify the operator with the file path and the specific error (parse failure, missing file, invalid schema). Do not attempt recovery or partial loading — the operator must fix or recreate the file. Same behavior as `status.json` and `chat_history.json` corruption handling. |

---

### Change 12 — Design Spec, Phase 3 Code Mode, after the test framework selection paragraph [Major]

**Add the following paragraph:**

> **Test Command Discovery:** The code builder's `test-runner.js` does not parse `spec.md` to discover the test command. Instead, the coding agent is instructed (via the `/prompts/code-build.md` prompt) to create a standard `npm test` script in the project's `package.json` (or the language-equivalent test entry point). `test-runner.js` always invokes the project's standard test entry point (`npm test` for Node.js projects). The specific test framework is an implementation detail of the deliverable codebase, not of ThoughtForge's `test-runner.js`. If the test command exits non-zero, `test-runner.js` treats it as test failures and captures stdout/stderr as the `details` field.

---

### Change 13 — Execution Plan, Build Stage 2, after Task 8 [Major]

**Add a new task row to the task table:**

> | 8a | Implement chat-message URL scanning for resource connectors: match URLs in brain dump chat messages against enabled connector URL patterns (from build spec), auto-pull matched URLs via connector layer, ignore matches for disabled connectors, pass unmatched URLs through as brain dump text | — | Task 8, Task 7c | — | Not Started |

---

### Change 14 — Execution Plan, Task 8 description [Minor]

**Append to the existing Task 8 description:**

> "Include ambiguous deliverable type handling per design spec: when brain dump signals both Plan and Code, AI defaults to Plan and flags in Open Questions."

---

### Change 15 — Design Spec, UI section, after the project list sidebar description [Minor]

**Add the following paragraph:**

> **Mid-Stream Project Switch:** If the human switches projects while an AI response is streaming, the client stops rendering the stream for the previous project's chat. Server-side processing continues uninterrupted — the AI response completes and is persisted to `chat_history.json` regardless of client-side display state. When the human returns to the project, the completed response is visible in the chat history.

---

### Change 16 — Execution Plan, Task 6c dependencies [Minor]

**Find Task 6c's "Depends On" value:**
> `Task 6a, Task 7`

**Replace with:**
> `Task 5, Task 6a, Task 7`

---

## SECTION 3: Extractions (Move Implementation Details from Design Spec to Build Spec)

### Change 17 — Design Spec → Build Spec: "realign from here" matching rule (around line 92) [Minor]

**In the Design Spec, find this text:**
> "The command is matched as an exact case-insensitive string: the entire chat message must be 'realign from here' with no additional text."

**Replace that sentence in the Design Spec with:**
> "The human types 'realign from here' in chat to trigger a re-distillation from the original brain dump plus corrections up to a rollback point. Exact matching rules and algorithm in build spec."

**Then add the removed matching rule to the Build Spec's Realign Algorithm section:**
> "The command is matched as an exact case-insensitive string: the entire chat message must be 'realign from here' with no additional text."

---

### Change 18 — Design Spec: Stagnation Guard inline parameter values (around line 334) [Minor]

**If the design spec stagnation guard description contains inline parameter values like "70% of issues" or "Levenshtein similarity ≥ 0.8"**, remove those inline values from the design spec. The design spec should say only:

> "Issue rotation detected — old issues resolved, new issues introduced at the same rate (rotation threshold and similarity measure defined in build spec)."

The build spec's Convergence Guard Parameters section already contains these values. Confirm they are present there and do not duplicate them.

---

## After All Changes Are Applied

1. Re-read each modified file to confirm no formatting is broken (unclosed tables, orphaned headers, broken markdown).
2. `git status -u` — verify all modified files
3. `git diff --stat` — confirm changes
4. Git add only the files you modified:
   ```bash
   git add docs/thoughtforge-design-specification.md docs/thoughtforge-build-spec.md docs/thoughtforge-execution-plan.md
   ```
5. Commit with message: `Apply review findings`
6. Push to remote: `git push`
7. `git pull` — confirm sync with remote. Do not leave commits unpushed.
