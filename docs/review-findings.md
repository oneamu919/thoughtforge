# ThoughtForge Documentation Review — Findings

> **Scope:** All 10 documentation files (requirements brief, design specification, build spec, execution plan, review prompt, session handoff, OPA framework template, and 3 blank templates).
>
> **Review approach:** Read as a senior dev who will build from these docs. Findings organized by severity. Design philosophy and architecture decisions are not questioned — this review evaluates completeness, clarity, and internal consistency.

---

## 1. Writing That's Unclear — With Replacement Text

### [Critical] OPA acronym defined inconsistently across documents

The requirements brief header and the OPA Framework Template both define OPA as **"Outcome - Purpose - Action"** (the Tony Robbins definition). The design specification (line 17) redefines it as **"Objective -> Plan -> Assessment"** with a completely different table structure (Objective | Plan | Assessment columns).

These are two different frameworks sharing an acronym. A builder reading the design spec will use Objective/Plan/Assessment columns in Handlebars templates. A builder reading the requirements brief or OPA template will use Outcome/Purpose/Action. The deliverable structure is ambiguous.

**In `thoughtforge-design-specification.md`, replace:**

```
OPA (Objective → Plan → Assessment) is the structural framework used for all Plan mode deliverables. Every major section of a plan document is expressed as an OPA table:

| Column | Purpose |
|---|---|
| Objective | What this section aims to achieve |
| Plan | The specific actions, decisions, or content that accomplish the objective |
| Assessment | How success will be measured or validated for this section |
```

**With:**

```
OPA (Outcome • Purpose • Action) is the structural framework used for all Plan mode deliverables, adapted from Tony Robbins' OPA system. Every major section of a plan document is expressed as an OPA table:

| Column | Purpose |
|---|---|
| Outcome | What this section aims to achieve — the measurable end state |
| Purpose | Why this section matters — the strategic driver and context |
| Action | The specific operations, decisions, or content that accomplish the outcome |
```

This aligns with the requirements brief, the OPA Framework Template, and the Tony Robbins source material referenced throughout.

---

### [Critical] `halted_reason` vs `halt_reason` naming inconsistency across state files

`status.json` schema (build spec line 393) uses `halted_reason`. `polish_state.json` schema (build spec line 424) uses `halt_reason`. A builder implementing crash recovery and halt handling will encounter mismatched field names between the two files that both track halt state.

**In `thoughtforge-build-spec.md`, in the `polish_state.json` Schema section, replace:**

```
  halt_reason: string | null;
```

**With:**

```
  halted_reason: string | null;
```

Use `halted_reason` consistently in both schemas to match the established convention in `status.json`.

---

### [Major] Top-level count fields required by Zod schema but explicitly ignored by orchestrator

The build spec's Count Derivation section (line 246-248) states: "The orchestrator ignores top-level count fields (`critical`, `medium`, `minor`) in the review JSON. It derives all counts from the `issues` array." Yet both Zod schemas define these fields as `z.number().int().min(0)` — required, not optional.

This means the AI must produce accurate count fields the system discards. A builder will either: (a) wonder why required fields are ignored, (b) accidentally use them instead of deriving counts, or (c) be confused about what to validate.

**In `thoughtforge-build-spec.md`, in the Count Derivation section, replace:**

```
The orchestrator ignores top-level count fields (`critical`, `medium`, `minor`) in the review JSON. It derives all counts from the `issues` array by counting per severity. Top-level counts remain in the schema for human readability in logs only and must not be used for convergence guard evaluation.
```

**With:**

```
The orchestrator derives all error counts from the `issues` array by counting occurrences per severity. Top-level count fields (`critical`, `medium`, `minor`) remain in the schema as a convenience for human readability in `polish_log.md` entries. The orchestrator MUST NOT use top-level counts for convergence guard evaluation — always derive from `issues`. The Zod schema validates that top-level counts are present (for log formatting), but the orchestrator treats them as informational only.
```

---

### [Major] Execution plan Task 19 description contradicts design spec

Task 19 in the execution plan says: "Implement Plan Completeness Gate (assessment prompt for Code mode entry, **auto-redirect to Plan mode on fail**)". The design spec (lines 258-260) says something different: "The human can either **override** (proceed with Code mode despite the incomplete plan) or **create a new Plan mode project manually** to refine the plan first. ThoughtForge does not automatically create projects on the human's behalf."

There is no auto-redirect. The pipeline halts and the human decides.

**In `thoughtforge-execution-plan.md`, replace:**

```
| 19 | Implement Plan Completeness Gate (assessment prompt for Code mode entry, auto-redirect to Plan mode on fail) | — | Task 14, Task 7a, Task 19a, Tasks 41–42 | — | Not Started |
```

**With:**

```
| 19 | Implement Plan Completeness Gate (assessment prompt for Code mode entry, halt and notify on fail with override option) | — | Task 14, Task 7a, Task 19a, Tasks 41–42 | — | Not Started |
```

---

### [Major] Agent adapter normalized output format not specified

The build spec's Agent Communication section (lines 323-329) says "Agent-specific adapters handle output format differences and normalize to ThoughtForge's internal format" but never defines what that internal format looks like. A builder implementing adapters for Claude, Gemini, and Codex needs to know the target format they're normalizing to.

**In `thoughtforge-build-spec.md`, after the Output Normalization subsection (after line 329), add:**

```
### Normalized Agent Response Format

All adapters normalize agent output to this structure:

```typescript
interface AgentResponse {
  success: boolean;          // true if agent returned usable output
  output: string;            // The extracted payload (JSON, markdown, or diff)
  raw: string;               // Original unmodified stdout for debugging
  exit_code: number;         // Agent process exit code
  duration_ms: number;       // Wall-clock execution time
}
```

The orchestrator consumes only `success` and `output`. Phase 4 review steps parse `output` as JSON and validate via Zod. Phase 4 fix steps treat `output` as the applied diff/content. `raw` and `duration_ms` are written to `thoughtforge.log` for debugging.
```

---

### [Minor] "OpenClaw" referenced without explanation

The requirements brief (line 87) and constraints section mention "Node.js only (already installed via OpenClaw, single runtime)." OpenClaw is not explained anywhere in the documentation. A builder unfamiliar with the operator's environment won't know what this refers to.

**In `thoughtforge-requirements-brief.md`, replace:**

```
- **Runtime:** Node.js only (already installed via OpenClaw, single runtime)
```

**With:**

```
- **Runtime:** Node.js only (already installed, single runtime)
```

The reference to how Node.js was installed is irrelevant to the requirements. Similarly update the design spec's Technical Design table (line 295):

**In `thoughtforge-design-specification.md`, replace:**

```
| Runtime | Node.js | Already installed (via OpenClaw), single runtime |
```

**With:**

```
| Runtime | Node.js | Already installed, single runtime |
```

---

### [Minor] Design spec Configuration table template directory default is commented out in config.yaml

The design spec Configuration section (line 468) lists "Template directory path" as configurable with default `./plugins/plan/templates`. But the `config.yaml` template in the build spec (lines 546-549) comments out the templates section with the note "reserved for future cross-plugin shared templates. Not used in current scope."

A builder will see a configurable item in the design spec with no corresponding config key.

**In `thoughtforge-design-specification.md`, replace:**

```
| Templates | Template directory path | `./plugins/plan/templates` (plan mode templates live inside the plan plugin) |
```

**With:**

```
| Templates | Plan mode templates live inside their plugin directory (`/plugins/plan/templates/`). Not exposed as a top-level config key — template paths are managed within the plugin. | N/A |
```

---

### [Minor] `chat_history.json` clearing rules ambiguous for Phase 3-4 boundary

The build spec (line 446) says chat history is "Cleared after phase advancement confirmation." Phase 3→4 transition is automatic (no confirmation). This means Phase 3 stuck recovery conversations (if any) persist into Phase 4 halt recovery conversations. The behavior is likely intentional but not stated.

**In `thoughtforge-build-spec.md`, in the `chat_history.json` Schema section, replace:**

```
On crash, chat resumes from last recorded message. Cleared after phase advancement confirmation.
```

**With:**

```
On crash, chat resumes from last recorded message. Cleared after human-confirmed phase advancement (Phase 1→2 and Phase 2→3). The Phase 3→4 transition is automatic and does NOT clear chat history — any Phase 3 stuck recovery conversation persists and is visible during Phase 4 halt recovery.
```

---

## 2. Genuinely Missing Plan-Level Content

### [Major] No mechanism described for tracking Unknown resolution in Phase 2

The design spec (lines 107-112) states that all Unknowns and Open Questions from `intent.md` must be resolved before Phase 2 advancement, and the Confirm button is blocked if unresolved items remain. But neither the design spec nor the build spec describes the mechanism for how the system knows which unknowns have been resolved.

Does the AI maintain a structured tracker? Does the orchestrator parse `intent.md` unknowns and match them against `spec.md` resolved unknowns? Is it purely prompt-based (the AI is asked "are all unknowns resolved?" before allowing confirm)?

**Proposed addition to `thoughtforge-design-specification.md`, after the Phase 2 Primary Flow (after line 114):**

```
**Unknown Resolution Tracking:** Before the Confirm button is enabled for Phase 2 advancement, the orchestrator invokes the AI with both `intent.md` and the current draft `spec.md`, asking it to enumerate any unresolved Unknowns or Open Questions from `intent.md` that do not have a corresponding resolution in `spec.md`. If the AI returns any unresolved items, the Confirm button remains blocked and the items are presented to the human in chat. This is a prompt-based check, not a mechanical parser — the AI performs the semantic matching. The check runs every time the human requests advancement.
```

---

### [Major] Seven of nine pipeline prompts are unwritten

The build spec lists 9 prompt files. Only `brain-dump-intake.md` has actual prompt text. The remaining 7 are marked "Status: Prompt text to be drafted before Task [X] begins." While the execution plan accounts for drafting these (Tasks 7f, 15a, 19a, 21a, 30a, 30b), the build spec is currently incomplete as a builder reference.

This is not a structural gap — the plan correctly defers drafting to the appropriate execution stage. However, the build spec should make this status more visible.

**Proposed addition to `thoughtforge-build-spec.md`, at the top of the Prompt File Directory section (after line 13):**

```
> **Prompt Completion Status:** 1 of 9 prompts drafted. Remaining prompts will be drafted as prerequisite sub-tasks before their consuming tasks begin (see execution plan Tasks 7f, 15a, 19a, 21a, 30a, 30b). The build spec will be updated with prompt text as each is drafted.

| Prompt File | Status | Drafted By |
|---|---|---|
| `brain-dump-intake.md` | Complete | — |
| `spec-building.md` | Not drafted | Task 7f |
| `plan-build.md` | Not drafted | Task 15a |
| `plan-review.md` | Not drafted | Task 30a |
| `plan-fix.md` | Not drafted | Task 30a |
| `code-build.md` | Not drafted | Task 21a |
| `code-review.md` | Not drafted | Task 30b |
| `code-fix.md` | Not drafted | Task 30b |
| `completeness-gate.md` | Not drafted | Task 19a |
```

---

### [Minor] No description of nested git repo handling

The design spec says each project gets its own git repo (line 425, Decision #3), initialized at project creation inside `/projects/{id}/`. If the ThoughtForge tool itself lives in a git repo (which it does — this repo), creating nested git repos under it could cause issues (git's nested repo behavior, `.gitignore` considerations).

**Proposed addition to `thoughtforge-design-specification.md`, after the Git Commit Strategy paragraph (after line 314):**

```
**Nested Git Repo Isolation:** Since ThoughtForge itself may live in a git repository, project repos created under `/projects/{id}/` are nested repos. The ThoughtForge root `.gitignore` must exclude the `/projects/` directory to prevent the parent repo from tracking project files. Each project repo is fully independent — ThoughtForge never performs git operations on its own root repo during pipeline execution.
```

---

### [Minor] Review prompt severity terminology differs from polish loop severity

The `project-plan-review-prompt.md` (used for reviewing the ThoughtForge docs themselves) uses severity levels: Critical / **Major** / Minor. The polish loop's review schema uses: critical / **medium** / minor. The middle tier uses different labels. This is not a bug — they serve different purposes — but it could confuse a builder who sees both.

**Proposed addition to `project-plan-review-prompt.md`, after the Severity Ratings section (after line 21):**

```
> **Note:** These severity levels (Critical/Major/Minor) are for reviewing plan documents. The ThoughtForge polish loop uses a separate scale (critical/medium/minor) defined in `constraints.md` per project. The two scales are independent.
```

---

### [Minor] CLAUDE.md session handoff template has empty sections and unclear references

The CLAUDE.md file has empty sections (What This Is, Current Status, Key Paths, Ports, Git, Module Map) and Rule 2 references "working dir" without defining it. Rule 5 references `docs/lessons-learned.md` which doesn't exist.

These are not issues for now — the file is a template to be populated during development. No changes needed, but the first builder session should fill in the known sections (What This Is, Key Paths, Git rules).

---

## 3. Build Spec Material That Should Be Extracted

No findings. The build spec extraction has already been done thoroughly — implementation details (schemas, prompts, function signatures, config templates) live in the build spec, while the design spec stays at the functional/behavioral level. The separation is clean.

---

## Summary

| Severity | Count |
|----------|-------|
| Critical | 2 |
| Major | 4 |
| Minor | 5 |
| **Total** | **11** |

**Critical findings** are the OPA acronym inconsistency (which would produce incorrectly structured deliverables) and the field naming mismatch between state files (which would cause bugs in halt/recovery handling).

**Major findings** are the count field confusion in Zod schemas, the execution plan task description contradicting the design spec, the missing agent response format, and the unspecified unknown-resolution mechanism for Phase 2.

All findings have specific replacement text or proposed content.

---

## Appendix: Validation Against Git History

Each finding was verified against the actual git history to confirm it represents a real issue, not fabricated noise.

### Confirmed Valid (7 of 11)

| # | Finding | Verdict | Evidence |
|---|---------|---------|----------|
| 1 | OPA acronym inconsistency | **CONFIRMED — real conflict introduced by prior review** | `1bb3c51` added "Objective → Plan → Assessment" to design spec. Requirements brief has said "Outcome • Purpose • Action" since `a9bd431`. OPA Framework Template also says "Outcome • Purpose • Action." Three documents, two different definitions. A previous review session introduced the wrong one. |
| 2 | `halted_reason` vs `halt_reason` | **CONFIRMED** | Both field names present in `build-spec.md` since its initial extraction in `14948fd`. `status.json` schema line 393 says `halted_reason`, `polish_state.json` schema line 424 says `halt_reason`. |
| 3 | Zod count fields required but ignored | **CONFIRMED** | Count Derivation section (added `1bb3c51`) explicitly says "orchestrator ignores top-level count fields." Both Zod schemas (added `14948fd`) require them as `z.number().int().min(0)`. A builder will see required fields the system discards. |
| 4 | Task 19 "auto-redirect" contradicts design spec | **CONFIRMED — stale from partial update** | `7731e38` added "auto-redirect to Plan mode on fail" to Task 19. Same day, `1bb3c51` rewrote the design spec to say "ThoughtForge does not automatically create projects on the human's behalf." Execution plan was never updated to match. |
| 5 | Agent adapter normalized format undefined | **CONFIRMED** | Build spec line 324 says "normalize to ThoughtForge's internal format" since `14948fd`. That internal format is never defined anywhere in any document. |
| 7 | "OpenClaw" unexplained | **CONFIRMED** | Present in 3 files (requirements brief, design spec, execution plan). No definition anywhere. Truly minor — won't block a build. |
| 8 | Template directory config mismatch | **CONFIRMED** | Design spec line 468 lists it as configurable. Build spec `config.yaml` template comments it out as "reserved for future." Minor inconsistency. |

### Overclaiming / Weak (3 of 11)

| # | Finding | Verdict | Why It's Weak |
|---|---------|---------|---------------|
| 6 | Unknown resolution mechanism missing | **OVERCLAIMING** | Design spec line 112 explicitly says "AI validates that all Unknowns and Open Questions from `intent.md` have been resolved." That IS the mechanism — prompt-based AI validation. The exact prompt is deferred to Task 12 (standard for this project). My proposed addition adds useful precision but the mechanism isn't actually missing. **Downgrade from Major to Minor.** |
| 9 | `chat_history.json` clearing rules ambiguous | **ALREADY ADDRESSED** | I flagged the build spec (line 446) as vague, but the design spec (line 395) already has the full detail: "Cleared after each phase advancement confirmation (Phase 1 → Phase 2 and Phase 2 → Phase 3)... Phase 3 and Phase 4 recovery conversations are also persisted." The build spec is just a shorter summary. A builder reading both docs has the full picture. **Downgrade to informational — not a real gap.** |
| 10 | Review prompt severity differs from pipeline severity | **NOT A REAL ISSUE** | The `project-plan-review-prompt.md` is a meta-document for reviewing the ThoughtForge docs themselves (Critical/Major/Minor). The pipeline's error schema (critical/medium/minor) is for reviewing deliverables. These are completely different contexts. No builder would confuse them. **Remove.** |

### Non-Issue (1 of 11)

| # | Finding | Verdict |
|---|---------|---------|
| 11 | CLAUDE.md empty sections | Already acknowledged as a template to be filled during development. Not a gap. |

### Revised Honest Count

| Severity | Original | After Validation |
|----------|----------|-----------------|
| Critical | 2 | **2** (both confirmed) |
| Major | 4 | **3** (#6 downgraded to Minor) |
| Minor | 5 | **3** (#7, #8 confirmed; #6 downgraded here; #9 and #10 removed) |
| Removed | 0 | **3** (#9 already addressed, #10 not real, #11 non-issue) |
| **Real findings** | **11** | **8** |
