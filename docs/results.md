Now I have all four documents. Let me produce the review.

---

# Project Plan Review ΓÇö ThoughtForge

Review scope: `thoughtforge-design-specification.md` (design spec), `thoughtforge-build-spec.md` (build spec), `thoughtforge-execution-plan.md` (execution plan). Requirements brief (`thoughtforge-requirements-brief.md`) read for context only.

---

## 1. Writing That's Unclear

**[Minor]** Design spec, Phase 4 Convergence Guards ΓÇö Stagnation guard description:

> "Same total error count for 3+ consecutive iterations AND issue rotation detected ΓÇö fewer than 70% of current issues match prior iteration issues by description similarity."

The phrase "prior iteration issues" is ambiguous ΓÇö it could mean only the immediately prior iteration or the full prior window. The build spec clarifies this as comparing against the single prior iteration, but the design spec should match.

**Replacement:**
> "Same total error count for 3+ consecutive iterations AND issue rotation detected ΓÇö fewer than 70% of current issues match issues from the immediately prior iteration by description similarity."

---

**[Minor]** Design spec, Phase 1 step 9 ΓÇö "realign from here":

> "The AI resets to the most recent substantive correction, discarding subsequent conversation, and re-distills from the original brain dump plus all corrections up to that point."

"Discarding subsequent conversation" is misleading ΓÇö the build spec's Realign Algorithm says these messages are retained in `chat_history.json` for audit trail but excluded from the working context. The design spec implies deletion.

**Replacement:**
> "The AI resets to the most recent substantive correction, excluding subsequent conversation from the working context (retained in `chat_history.json` for audit trail), and re-distills from the original brain dump plus all corrections up to that point."

---

**[Minor]** Design spec, Phase 4 Convergence Guards ΓÇö Hallucination guard:

> "Error count spikes sharply after a sustained downward trend"

The build spec defines "sharply" as >20% and "sustained" as 2 consecutive decreasing iterations. The design spec should use language consistent with the specificity of the other guards' descriptions, or at minimum acknowledge the build spec defines the parameters.

**Replacement:**
> "Error count increases significantly (threshold defined in build spec) after a consecutive downward trend (minimum trend length defined in build spec)"

---

**[Minor]** Design spec, Phase 3 Code Mode:

> "Implements structured logging throughout the codebase (mandatory) ΓÇö sufficient for production debugging."

"Throughout the codebase" and "sufficient for production debugging" are subjective. This is a plan-level statement about what the AI agent should produce in the user's code deliverable, not about ThoughtForge's own logging. The phrase "production debugging" may mislead a builder into thinking this refers to ThoughtForge observability.

**Replacement:**
> "Instructs the coding agent to implement structured logging in the deliverable codebase (mandatory requirement in the build prompt). Logging approach and framework are determined by the Phase 2 spec."

---

**[Minor]** Design spec, Locked File Behavior ΓÇö `constraints.md`:

> "If the file is readable but has modified structure (missing sections, unexpected content), the AI reviewer processes it as-is ΓÇö the reviewer prompt is responsible for handling structural variations. ThoughtForge does not validate `constraints.md` structure at reload time."

"The reviewer prompt is responsible for handling structural variations" implies the prompt has logic for this, but the build spec's `constraints.md` structure section and the prompt (marked "to be drafted") say nothing about this. A builder would not know what "handling structural variations" means.

**Replacement:**
> "If the file is readable but has modified structure, ThoughtForge passes it to the AI reviewer without structural validation. The reviewer processes whatever content it receives ΓÇö no special handling is required for structural variations."

---

**[Minor]** Execution plan, Build Stage 1 cross-stage dependency note:

> "Tasks 41ΓÇô42 must be complete before any agent-invoking task begins (Tasks 8, 12, 15, 19, 21, and 30)."

Task 19 does not exist in the task breakdown. This is a stale reference.

**Replacement:**
> "Tasks 41ΓÇô42 must be complete before any agent-invoking task begins (Tasks 8, 12, 15, 21, and 30)."

---

**[Minor]** Design spec, Phase 2 Conversation Mechanics:

> "There is no 'realign from here' in Phase 2 ΓÇö the scope of each element is small enough that targeted corrections suffice."

This states a design decision but frames it as an observation ("small enough"). A builder might wonder if this is a soft guideline or a hard rule.

**Replacement:**
> "The 'realign from here' command is not supported in Phase 2. If issued, it is ignored. Targeted corrections via chat handle all Phase 2 revisions."

---

## 2. Genuinely Missing Plan-Level Content

**[Major]** Design spec ΓÇö No error handling for Phase 1 connector URL parsing.

Phase 1 step 3 says "the human provides page URLs or document links via chat." Error handling covers auth failure and target not found, but there is no specification for what happens when the human provides a malformed or unparseable URL in chat (not in config ΓÇö that's covered by startup validation). A builder would have to guess.

**Proposed content to add** (under Phase 1 Error Handling table):

| Condition | Action |
|---|---|
| Human provides malformed or unparseable connector URL in chat | AI responds in chat: "Could not parse URL: '{url}'. Please provide a valid Notion page URL or Google Drive document link." Does not halt. Does not attempt to pull. |

---

**[Major]** Design spec ΓÇö No specification for how the AI identifies connector URLs in chat messages.

Phase 1 step 3 says the human provides URLs "via chat." There is no indication of how the system distinguishes a Notion/Drive URL from any other URL the human might include in their brain dump text. A builder would have to invent URL pattern matching logic.

**Proposed content to add** (after Phase 1 step 3):

> **Connector URL identification:** The AI identifies connector URLs in chat messages by matching against known URL patterns for each enabled connector (e.g., `notion.so/` or `notion.site/` for Notion, `docs.google.com/` or `drive.google.com/` for Google Drive). URLs matching an enabled connector pattern are pulled automatically. URLs matching a disabled connector pattern are ignored. Unrecognized URLs are treated as regular brain dump text. Pattern definitions are in the build spec.

---

**[Major]** Execution plan ΓÇö No testing task for resource file processing.

Tasks 49 covers connector unit tests, and Task 58c covers file dropping. But there is no unit test task for the resource file processing logic itself (PDF extraction, image vision routing, unsupported format handling, size limit enforcement). This is a distinct module from connectors and from file upload.

**Proposed content to add** (in Build Stage 8):

| # | Task | Owner | Depends On | Estimate | Status |
|---|------|-------|------------|----------|--------|
| 58i | Unit tests: resource file processing (text read, PDF extraction, image vision routing, unsupported format skip, file size limit enforcement) | ΓÇö | Task 8 | ΓÇö | Not Started |

---

**[Minor]** Design spec ΓÇö No specification for what happens when an agent doesn't support vision and images are provided as resources.

The Resource File Processing section in the build spec says "Passed to the AI agent's vision capability if the configured agent supports it. If not, log a warning and skip." But the design spec doesn't define how ThoughtForge knows whether an agent supports vision. There's no `supports_vision` field in the agent config.

**Proposed content to add** (in `config.yaml` template under `agents.available`, per agent):

```yaml
    claude:
      command: "claude"
      flags: "--print"
      supports_vision: true
```

And in the build spec's agent config section: "The `supports_vision` field determines whether image resources are passed to this agent. If `false` or absent, image files are logged as skipped."

---

**[Minor]** Design spec ΓÇö No specification for the operation type taxonomy referenced in Plan Mode Safety Guardrails.

The design spec states: "The orchestrator classifies every Phase 3/4 action into an operation type before invoking the plugin's `validate()`. The complete operation type list and the mapping from orchestrator actions to operation types are defined in the build spec." But the build spec does not contain this list. The Plan mode `safety-rules.js` shows example blocked operations (`"shell_exec"`, `"file_create_source"`, `"package_install"`) but the full operation type taxonomy and the orchestrator-to-type mapping are absent.

**Proposed content to add** (in build spec, after Plugin Interface Contract section):

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

**[Minor]** Execution plan ΓÇö Completion Checklist missing connector testing.

The checklist covers notifications, plugins, guards, agents, crash recovery, and prompt editor. But connector functionality (Notion, Google Drive) is not listed despite being build tasks (7cΓÇô7e) with unit tests (49).

**Proposed content to add** (in Completion Checklist):

> - [ ] Resource connectors: Notion and Google Drive pull, auth failure handling, disabled connector behavior

---

## 3. Build Spec Material That Should Be Extracted

**[Minor]** Design spec, Phase 1 step 0 ΓÇö Project ID format:

> "A URL-safe, filesystem-safe, unique string identifier. Format defined in build spec."

This is correctly deferred to the build spec. No action needed. (Noted for completeness ΓÇö the design spec handles this correctly.)

---

**[Minor]** Design spec, OPA Framework section:

> "Handlebars templates define the OPA skeleton ΓÇö fixed section headings with OPA table placeholders."

This is plan-level (what templates do). The design spec correctly avoids specifying template file contents. No extraction needed.

---

No findings in this category. The design spec has done a good job of deferring implementation details to the build spec via explicit "defined in build spec" references. The build spec correctly contains schemas, prompts, folder structures, CLI commands, and algorithmic parameters. The boundary between the two documents is clean.

---

**Summary:** 7 clarity findings (all Minor), 3 missing content findings (2 Major, 1 Minor with 2 additional Minor items), 0 extraction findings. The plan documents are thorough and well-structured. The two Major findings (connector URL parsing error handling and connector URL identification in chat) are the most likely to cause builder confusion or ad-hoc decision-making during implementation.
