# Apply Review Findings from results.md

You are an AI coder. Apply every change listed below to the source files. Each change is taken directly from the review findings in `results.md`. Do not interpret or improvise — apply the replacements, additions, and extractions exactly as specified.

Read all target files before editing. After all changes are applied, git commit and sync to remote.

---

## Target Files

- `docs/thoughtforge-design-specification.md` (referred to as "Design Spec")
- `docs/thoughtforge-build-spec.md` (referred to as "Build Spec")
- `docs/thoughtforge-execution-plan.md` (referred to as "Execution Plan")

Read all three files before making any edits.

---

## Changes to Apply

### Change 1 — Design Spec: Stagnation guard description (Minor)

**Location:** Phase 4 Convergence Guards, Stagnation guard.

**Find:**
> Same total error count for 3+ consecutive iterations AND issue rotation detected — fewer than 70% of current issues match prior iteration issues by description similarity.

**Replace with:**
> Same total error count for 3+ consecutive iterations AND issue rotation detected — fewer than 70% of current issues match issues from the immediately prior iteration by description similarity.

---

### Change 2 — Design Spec: Phase 1 step 9 "realign from here" (Minor)

**Location:** Phase 1 step 9.

**Find:**
> The AI resets to the most recent substantive correction, discarding subsequent conversation, and re-distills from the original brain dump plus all corrections up to that point.

**Replace with:**
> The AI resets to the most recent substantive correction, excluding subsequent conversation from the working context (retained in `chat_history.json` for audit trail), and re-distills from the original brain dump plus all corrections up to that point.

---

### Change 3 — Design Spec: Phase 4 Hallucination guard (Minor)

**Location:** Phase 4 Convergence Guards, Hallucination guard.

**Find:**
> Error count spikes sharply after a sustained downward trend

**Replace with:**
> Error count increases significantly (threshold defined in build spec) after a consecutive downward trend (minimum trend length defined in build spec)

---

### Change 4 — Design Spec: Phase 3 Code Mode structured logging (Minor)

**Location:** Phase 3 Code Mode.

**Find:**
> Implements structured logging throughout the codebase (mandatory) — sufficient for production debugging.

**Replace with:**
> Instructs the coding agent to implement structured logging in the deliverable codebase (mandatory requirement in the build prompt). Logging approach and framework are determined by the Phase 2 spec.

---

### Change 5 — Design Spec: Locked File Behavior, `constraints.md` (Minor)

**Location:** Locked File Behavior section, `constraints.md` paragraph.

**Find:**
> If the file is readable but has modified structure (missing sections, unexpected content), the AI reviewer processes it as-is — the reviewer prompt is responsible for handling structural variations. ThoughtForge does not validate `constraints.md` structure at reload time.

**Replace with:**
> If the file is readable but has modified structure, ThoughtForge passes it to the AI reviewer without structural validation. The reviewer processes whatever content it receives — no special handling is required for structural variations.

---

### Change 6 — Execution Plan: Build Stage 1 cross-stage dependency note (Minor)

**Location:** Build Stage 1 cross-stage dependency note.

**Find:**
> Tasks 41–42 must be complete before any agent-invoking task begins (Tasks 8, 12, 15, 19, 21, and 30).

**Replace with:**
> Tasks 41–42 must be complete before any agent-invoking task begins (Tasks 8, 12, 15, 21, and 30).

Note: Task 19 does not exist. This removes the stale reference.

---

### Change 7 — Design Spec: Phase 2 "realign from here" absence (Minor)

**Location:** Phase 2 Conversation Mechanics.

**Find:**
> There is no 'realign from here' in Phase 2 — the scope of each element is small enough that targeted corrections suffice.

**Replace with:**
> The 'realign from here' command is not supported in Phase 2. If issued, it is ignored. Targeted corrections via chat handle all Phase 2 revisions.

---

### Change 8 — Design Spec: Phase 1 Error Handling table — add malformed URL row (Major)

**Location:** Phase 1 Error Handling table (the table listing conditions like auth failure, target not found, etc.).

**Action:** Add this row to the existing table:

| Human provides malformed or unparseable connector URL in chat | AI responds in chat: "Could not parse URL: '{url}'. Please provide a valid Notion page URL or Google Drive document link." Does not halt. Does not attempt to pull. |

---

### Change 9 — Design Spec: Connector URL identification (Major)

**Location:** Immediately after Phase 1 step 3 (where the human provides page URLs or document links via chat).

**Action:** Add this content after step 3:

> **Connector URL identification:** The AI identifies connector URLs in chat messages by matching against known URL patterns for each enabled connector (e.g., `notion.so/` or `notion.site/` for Notion, `docs.google.com/` or `drive.google.com/` for Google Drive). URLs matching an enabled connector pattern are pulled automatically. URLs matching a disabled connector pattern are ignored. Unrecognized URLs are treated as regular brain dump text. Pattern definitions are in the build spec.

---

### Change 10 — Execution Plan: Add resource file processing test task (Major)

**Location:** Execution Plan, Build Stage 8 task table.

**Action:** Add this row:

| 58i | Unit tests: resource file processing (text read, PDF extraction, image vision routing, unsupported format skip, file size limit enforcement) | — | Task 8 | — | Not Started |

---

### Change 11 — Design Spec/Build Spec: Add `supports_vision` agent config field (Minor)

**Location A:** In the `config.yaml` template under `agents.available`, for each agent entry. Add the `supports_vision` field. Example for Claude:

```yaml
    claude:
      command: "claude"
      flags: "--print"
      supports_vision: true
```

**Location B:** In the Build Spec's agent config section, add this sentence:

> The `supports_vision` field determines whether image resources are passed to this agent. If `false` or absent, image files are logged as skipped.

---

### Change 12 — Build Spec: Add Operation Type Taxonomy (Minor)

**Location:** Build Spec, after the Plugin Interface Contract section.

**Action:** Add this new subsection:

> **Operation Type Taxonomy**
>
> Every orchestrator action in Phase 3/4 is classified into one of these operation types before calling `safety-rules.js` `validate()`:
>
> | Operation Type | Description | Example Actions |
> |---|---|---|
> | `shell_exec` | Execute a shell command or subprocess (excluding agent invocations) | Run build script, install package |
> | `file_create_source` | Create a source code file (`.js`, `.py`, `.ts`, `.sh`, etc.) | Scaffold project, write boilerplate |
> | `file_create_doc` | Create a documentation file (`.md`) | Write plan section, draft document |
> | `file_create_state` | Create or update a state file (`.json`) | Write `status.json`, `polish_state.json` |
> | `agent_invoke` | Invoke an AI agent for content generation | Call Claude for plan section, call Codex for code |
> | `package_install` | Install a dependency via package manager | `npm install`, `pip install` |
> | `test_exec` | Execute a test suite | Run `npm test`, `pytest` |
> | `git_commit` | Create a git commit | Milestone commit, iteration commit |

---

### Change 13 — Execution Plan: Completion Checklist — add connector testing (Minor)

**Location:** Execution Plan, Completion Checklist section.

**Action:** Add this checklist item:

> - [ ] Resource connectors: Notion and Google Drive pull, auth failure handling, disabled connector behavior

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
