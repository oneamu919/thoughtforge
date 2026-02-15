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

## Changes to Design Spec (`docs/thoughtforge-design-specification.md`)

### Change 1 — [Major] Hallucination guard parameter naming mismatch with build spec

**Action:** Find the Hallucination guard row/section that references `hallucination_spike_threshold` and `hallucination_min_trend` as configurable parameters. Replace the description text with:

> Total error count increases by more than 20% from the prior iteration (hardcoded threshold, defined in build spec) after at least 2 consecutive iterations with decreasing total error count (hardcoded minimum trend length, defined in build spec)

---

### Change 2 — [Major] Concurrency limit — contradictory definition of "active"

**Action:** Find the Concurrency limit enforcement section. Its first sentence says something like "When the number of active projects (status not `done` or `halted`) reaches max_parallel_runs..." Replace that first sentence with:

> When the number of active projects (status not `done`) reaches `config.yaml` `concurrency.max_parallel_runs`, new project creation is blocked.

This makes it consistent with the "halted counts toward active" interpretation elsewhere in the document.

---

### Change 3 — [Major] `halted` described as "non-terminal" but Terminate also produces `halted`

**Action:** Find the `status.json` schema table rows that describe terminal/non-terminal states. Replace the rows for terminal and non-terminal halt with:

> | Terminal | `done` | Convergence or stagnation success. Does not count toward concurrency limit. |
> | Halt | `halted` | Guard trigger, human terminate, or unrecoverable error. Counts toward concurrency limit until human resumes (returning to active state) or the operator manually deletes the project directory. Terminated projects (`halt_reason: "human_terminated"`) are functionally finished but use the same `halted` state. |

---

### Change 4 — [Minor] "No CLI agent execution" in Plan mode safety guardrails

**Action:** Find the Plan Mode Safety Guardrails table row about "No coding agents" or "No CLI agent execution." Replace that row with:

> | No coding agent shell access | No shell commands, package installs, or file system writes to source files during Plan mode Phases 3-4. AI agents are invoked for text generation only — not with coding-agent capabilities. |

---

### Change 5 — [Minor] "Realign from here" — unclear matching semantics

**Action:** Find the section about "realign from here" (Step 9 or similar). After the text describing it as a chat-parsed command, add:

> The command is matched as an exact case-insensitive string: the entire chat message must be "realign from here" with no additional text. Messages containing the phrase alongside other text are treated as regular corrections.

---

### Change 6 — [Minor] Fabrication guard "2x" phrasing clarity

**Action:** Find the fabrication guard section, specifically the condition about "2x its convergence threshold." Replace that condition text with:

> In at least one prior iteration, every severity category was at or below twice its convergence threshold — specifically: critical ≤ 0 (2 × 0), medium ≤ 6 (2 × 3), minor ≤ 10 (2 × 5) using default config values. This ensures fabrication is only flagged after the deliverable was near-converged.

---

### Change 7 — [Minor] "Agent layer" never formally defined

**Action:** Find the Agent Communication section. Before the first paragraph of that section, add:

> **Agent layer** refers to ThoughtForge's built-in agent invocation module — the subprocess-based mechanism for calling AI agent CLIs, capturing output, normalizing responses, and handling failures. This is distinct from Vibe Kanban's agent execution, which wraps agent invocation in task management and worktree isolation.

---

### Change 8 — [Major] Missing: When the Plan Completeness Gate fires relative to Phase 3

**Action:** Find the Phase 3 Code Mode section. After step 1 ("Orchestrator loads code plugin" or similar), add a new step:

> 1a. **Plan Completeness Gate:** Before the code builder begins work, the orchestrator runs the Plan Completeness Gate (see dedicated section below). If the gate halts the pipeline, Phase 3 does not proceed. If the gate passes or is skipped (no plan document in `/resources/`), the code builder begins.

---

### Change 9 — [Major] Missing: No `projects/` base directory specified

**Action:** Find the Application Entry Point paragraph. Add:

> Project directories are created under the path specified by `config.yaml` `projects.directory` (default: `./projects` relative to ThoughtForge's working directory).

---

### Change 10 — [Minor] Missing: What happens to Vibe Kanban cards when a project is terminated

**Action:** Find the Vibe Kanban Dashboard section, after the sentence about halted cards displaying a halted indicator. Add:

> Cards with `halt_reason: "human_terminated"` display a distinct visual indicator (e.g., strikethrough or "Terminated" badge) to distinguish permanently stopped projects from recoverable halts that await human action. The specific visual treatment is a UI implementation detail.

---

### Change 11 — [Minor] Missing: How ThoughtForge handles missing default agent CLI

**Action:** Find the Agent Communication section, after the Failure handling content. Add:

> **Agent availability check:** At server startup, the configured default agent CLI is verified to exist on PATH. If not found, the server logs a warning: "Default agent '{agent}' not found on PATH. Projects will fail at first agent invocation." The server does not exit — other agents may be available, and the operator may install the agent before creating a project. At project creation, no agent availability check is performed — the first agent invocation failure triggers the standard retry-once-then-halt behavior.

---

### Change 12 — [Minor] Plan Mode Safety Guardrails — source file extension list belongs in build spec

**Action:** Find the Plan Mode Safety Guardrails table row "No file creation outside plan docs" (or similar wording that lists specific file extensions like `.js`, `.py`, `.ts`, `.sh`). Replace that row with:

> | No source file creation | Only documentation files (`.md`) and operational state files (`.json`) may be created. Source file extensions are defined in `safety-rules.js`. |

---

### Change 13 — [Minor] Button debounce duplicate paragraph

**Action:** Find and remove the duplicate "Button Debounce" paragraph from the Phase 1 section. The design spec already covers button behavior in the Action Button Behavior section ("Buttons prevent duplicate actions..."). The build spec's detailed implementation section is the right home for UI-level specifics.

---

## Changes to Build Spec (`docs/thoughtforge-build-spec.md`)

### Change 14 — [Minor] `config.yaml` template — commented-out `templates:` key

**Action:** Find the `config.yaml` template section. It has a commented-out `templates:` key with a value like `./plugins/plan/templates`. Replace that entire commented block with:

```yaml
# templates: (reserved for future cross-plugin shared template configuration)
```

---

### Change 15 — [Minor] `PlanBuilderResponse` interface — missing content validation constraint

**Action:** Find the `PlanBuilderResponse` interface definition. Replace it with:

```typescript
interface PlanBuilderResponse {
  stuck: boolean;
  reason?: string;       // Required when stuck is true
  content: string;       // Non-empty when stuck is false; empty string when stuck is true.
                         // Orchestrator must validate: if stuck is false and content is empty, treat as malformed response.
}
```

---

### Change 16 — [Major] Missing: No `projects/` base directory in config

**Action:** Find the `config.yaml` template. Add the following key:

```yaml
# Projects
projects:
  directory: "./projects"  # Base directory for all project directories
```

---

### Change 17 — [Minor] Missing: No guidance on code builder task derivation from spec.md

**Action:** Find the Code Builder Task Queue section. After the first paragraph, add:

> **Task derivation guidance:** The code builder parses the Deliverable Structure and Acceptance Criteria sections of `spec.md`. Each architectural component or feature maps to a build task. Each acceptance criterion maps to a test-writing task. The builder orders tasks by dependency (foundational components first, then features, then tests). The exact parsing and ordering logic is an implementation detail of Task 21, but must produce a deterministic task list from the same `spec.md` input.

---

### Change 18 — [Minor] Project ID format — extract to its own subsection

**Action:** Find the Project Initialization Sequence section where the project ID format (`{timestamp}-{random}`) is defined inline within a step list. Extract it into its own subsection:

> ### Project ID Format
> `{timestamp}-{random}`, e.g., `20260214-a3f2`. Timestamp is `YYYYMMDD` from project creation date. Random is a 4-character lowercase hexadecimal string. The combined ID is URL-safe, filesystem-safe, and unique within the projects directory.

---

## Changes to Execution Plan (`docs/thoughtforge-execution-plan.md`)

### Change 19 — [Minor] Task 6a — incomplete error handling parenthetical

**Action:** Find Task 6a's description. It contains the parenthetical "(halt and notify on write failures — no retry)." Replace that parenthetical with:

> (halt and notify on file system failures — both read failures on critical state files and write failures — no retry)

---

### Change 20 — [Minor] Task 12 — overly detailed description

**Action:** Find Task 12's description (it has 7 numbered sub-steps inline). Replace the entire task description with:

> Implement Phase 2: spec building per design spec Phase 2 behavior. Includes mode-specific proposal (Plan: OPA structure; Code: architecture with OSS discovery from Task 25), AI challenge of intent decisions, constraint discovery, acceptance criteria extraction, human review/override, Unknown resolution validation gate, and Confirm advancement. Prompt loaded from `/prompts/spec-building.md`.

---

### Change 21 — [Major] Missing: No task for Phase 3→4 transition output validation

**Action:** Find Task 6c. Its current description focuses on stuck recovery. Replace or expand the description to:

> Task 6c (expanded): Implement Phase 3→4 automatic transition including output validation (per design spec Phase 3→4 Transition Error Handling: verify expected output files exist and meet `config.yaml` `phase3_completeness` thresholds before entering Phase 4), Phase 3 stuck recovery interaction (Provide Input / Terminate buttons), and milestone notification.

---

### Change 22 — [Minor] Missing: Test framework decision unresolved

**Action:** Find the Design Decisions section (or add as a pre-build task before Task 1). Add:

> **Pre-build decision: Test framework.** Choose Vitest or Jest before Task 1 begins. Both are compatible. Vitest is recommended for ESM-native support and faster execution with TypeScript projects (no separate compilation step for tests).

---

## After All Changes Are Applied

1. Re-read each modified file to confirm no formatting is broken (unclosed tables, orphaned headers, broken markdown).
2. Git add only the files you modified:
   ```bash
   git add docs/thoughtforge-design-specification.md docs/thoughtforge-build-spec.md docs/thoughtforge-execution-plan.md
   ```
3. Commit with message: `Apply review findings`
4. Push to remote: `git push`
5. Confirm the push succeeded. Do not leave commits unpushed.
