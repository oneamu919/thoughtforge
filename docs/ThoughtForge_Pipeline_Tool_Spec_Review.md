# ThoughtForge Pipeline Tool Spec — Build Readiness Review

---

## List 1: Unclear Writing (with replacement text)

### 1.1 — Phase 4 trigger references only Code mode

The Phase 4 trigger line says:

> Code is working (Phase 3 complete).

Phase 4 serves both Plan and Code mode. The trigger text only mentions code.

**Replace the trigger line with:**

> **Plan mode:** Plan document is fully drafted (Phase 3 complete).
> **Code mode:** Code is working, all tests pass (Phase 3 complete).

---

### 1.2 — Stagnation guard: which counts are compared is ambiguous

The current text:

> Same error count for 3+ consecutive iterations, no meaningful change

"Same error count" could mean same total, same per-severity breakdown, or same issues. "No meaningful change" adds a subjective qualifier on top. A developer implementing this guard needs an exact comparison.

**Replace with:**

> Same `critical`, `medium`, AND `minor` counts (all three individually unchanged) for 3+ consecutive iterations.

---

### 1.3 — Config `templates.directory` conflicts with plugin folder structure

The config block declares:

```yaml
templates:
  directory: "./templates"             # /templates/plan/, /templates/code/, etc.
```

But the plugin folder structure, the Phase 3 description, and Design Decision #19 all say templates live inside each plugin at `/plugins/{type}/templates/`. These are two different locations. A developer won't know which one is authoritative.

**Replace the config block entry with:**

```yaml
# Templates are located inside each plugin: /plugins/{type}/templates/
# No separate top-level templates directory. See Plugin Folder Structure.
```

**Or, if a global override directory is intended, make that explicit by replacing with:**

```yaml
# Templates — optional override directory (falls back to plugin's built-in templates)
templates:
  override_directory: "./templates"    # If a template exists here, it takes precedence over /plugins/{type}/templates/
```

---

## List 2: Missing Specs (with proposed content)

### 2.1 — Fabrication guard has no programmatic detection mechanism

Every other guard in the convergence table has a concrete, automatable condition:

| Guard | Detection |
|---|---|
| Hallucination | Count spike after downward trend |
| Scope drift | Issues reference out-of-scope locations |
| Stagnation | Same counts for 3+ iterations |
| **Fabrication** | **???** |

The fabrication guard says: "Model starts inventing issues outside the target code or flagging non-issues just to report something." That's a human judgment, not a computable check. A developer cannot implement this without a detection algorithm.

**Add below the Fabrication row in the Convergence Guards table:**

> **Detection mechanism:** After each review, the orchestrator cross-validates each issue's `location` field against the actual deliverable. For Code mode: verify that every file path and line number in the issues array exists in the project. For Plan mode: verify that every section reference in the issues array exists in the document. Any issue whose location does not resolve to a real artifact is flagged as a fabrication candidate. If fabrication candidates exceed 30% of total issues in a single review, the guard triggers. Threshold is configurable in `config.yaml` as `polish.fabrication_threshold` (default: `0.3`).

**Add to the config block:**

```yaml
polish:
  fabrication_threshold: 0.3   # Halt if >30% of reported issues reference non-existent locations
```

---

### 2.2 — Hallucination guard has no concrete threshold definition

The condition is "error count spikes after a downward trend." Neither "downward trend" nor "spike" is defined. A developer needs exact rules.

**Add a subsection under Convergence Guards or replace the hallucination row's Condition cell with:**

> **Downward trend:** total error count (`critical + medium + minor`) decreased for at least 2 consecutive iterations. **Spike:** total error count increases by more than 20% relative to the previous iteration's total, OR any increase in `critical` count after `critical` has been 0 for 2+ iterations. Either spike condition following a downward trend triggers the halt. The 20% spike threshold is configurable in `config.yaml` as `polish.hallucination_spike_pct` (default: `0.2`).

**Add to the config block:**

```yaml
polish:
  hallucination_spike_pct: 0.2   # Halt if total errors increase by >20% after a downward trend
```

---

### 2.3 — Vibe Kanban integration interface is unspecified

The spec says "ThoughtForge creates tasks, pushes them to Vibe Kanban" and "Vibe Kanban handles agent spawning and execution." But it never defines the integration surface. Without this, a developer doesn't know how ThoughtForge talks to Vibe Kanban or where the boundary is for Phase 3 vs. Phase 4 agent calls.

**Add a new subsection under the Stack section, after the Vibe Kanban table:**

> ### ThoughtForge / Vibe Kanban Integration Interface
>
> ThoughtForge communicates with Vibe Kanban via its CLI. The integration has two modes:
>
> | Operation | How | When |
> |---|---|---|
> | **Create task** | `vibekanban task create --name "{name}" --agent {agent} --worktree {path}` | Phase 3 start: ThoughtForge creates a Vibe Kanban task for the build. |
> | **Check task status** | `vibekanban task status --id {id}` | Phase 3: ThoughtForge polls until the build task completes. |
> | **Read task output** | `vibekanban task output --id {id}` | Phase 3: ThoughtForge reads build results when task completes. |
> | **Direct agent invocation** | ThoughtForge invokes the coding agent CLI directly (not via Vibe Kanban) using the `agents` config. | Phase 4: Review and fix calls are ThoughtForge-managed. Vibe Kanban is not in the Phase 4 loop. |
>
> **Boundary rule:** Phase 3 build execution goes through Vibe Kanban (for worktree isolation, agent management, and dashboard visibility). Phase 4 polish loop runs agents directly — ThoughtForge owns the review/fix cycle and cannot depend on Vibe Kanban's task queue for tight iteration control.
>
> If Vibe Kanban's CLI interface changes or if Vibe Kanban is not installed, ThoughtForge falls back to direct agent invocation for Phase 3 as well, losing dashboard visibility but not functionality. This is detected at startup and logged.

Adapt the above to match Vibe Kanban's actual CLI/API surface once confirmed. The key point is that the spec must declare the boundary and the mechanism, even if the specific commands change.

---

### 2.4 — Plugin interface contracts for `builder.js` and `safety-rules.js` are undefined

The spec shows the Zod schema for `reviewer.js` but never defines what `builder.js` or `safety-rules.js` export. A developer implementing the orchestrator's plugin loader needs the interface contract.

**Add a new subsection under Plugin Folder Structure:**

> ### Plugin Interface Contracts
>
> Every plugin must export the following from each file. The orchestrator loads the plugin folder matching the deliverable type in `intent.md` and calls these exports.
>
> **`builder.js`**
> ```javascript
> module.exports = {
>   /**
>    * Run Phase 3 build for this deliverable type.
>    * @param {object} context - { projectDir, intent, spec, constraints, agent, config }
>    * @returns {Promise<{ success: boolean, outputPath: string, error?: string }>}
>    */
>   build: async (context) => { /* ... */ },
> };
> ```
>
> **`reviewer.js`**
> ```javascript
> module.exports = {
>   /** Zod schema for validating review JSON */
>   schema: z.object({ /* ... as already defined in spec ... */ }),
>
>   /**
>    * Build the review prompt for this deliverable type.
>    * @param {object} context - { projectDir, constraints, deliverablePath }
>    * @returns {string} The full review prompt to send to the agent.
>    */
>   buildReviewPrompt: (context) => { /* ... */ },
> };
> ```
>
> **`safety-rules.js`**
> ```javascript
> module.exports = {
>   /**
>    * List of blocked operation patterns for this deliverable type.
>    * The orchestrator checks every agent command and file write against these
>    * before execution. If a match is found, the operation is blocked and logged.
>    */
>   blocked: {
>     fileExtensions: ['.js', '.py', '.ts', '.sh', ...],  // Plan mode blocks these
>     commands: ['npm', 'pip', 'node', 'python', ...],     // Plan mode blocks these
>     operations: ['shell_exec', 'file_create', 'package_install', ...],
>   },
>
>   /**
>    * Returns true if the given operation is allowed for this deliverable type.
>    * @param {object} operation - { type: string, target: string, command?: string }
>    * @returns {boolean}
>    */
>   isAllowed: (operation) => { /* ... */ },
> };
> ```

---

### 2.5 — Review JSON count integrity: no validation that AI-reported counts match the issues array

The Zod schemas define top-level `critical`, `medium`, `minor` counts AND an `issues` array where each issue has a `severity` field. The orchestrator uses the top-level counts for convergence checks. But there's nothing preventing the AI from reporting `critical: 0` while the issues array contains a critical-severity item. Zod validates structure, not cross-field consistency. If the AI under-reports counts, the loop terminates early with unfixed critical issues.

**Add a subsection under Structured Output Validation (Zod), or add to the existing validation flow:**

> **Count integrity check:** After Zod validation passes, the orchestrator derives `critical`, `medium`, and `minor` counts by filtering the `issues` array by severity. The derived counts are used for all convergence logic — the AI's self-reported top-level counts are logged but never trusted for termination decisions.
>
> ```javascript
> const derived = {
>   critical: parsed.issues.filter(i => i.severity === 'critical').length,
>   medium: parsed.issues.filter(i => i.severity === 'medium').length,
>   minor: parsed.issues.filter(i => i.severity === 'minor').length,
> };
> // Use `derived` for all guard checks, not `parsed.critical` / `parsed.medium` / `parsed.minor`
> ```
>
> If derived counts diverge from AI-reported counts, log the discrepancy as a warning. Repeated divergence (3+ consecutive iterations) is logged as a pattern but does not halt the loop — the derived counts are still authoritative.

---

### 2.6 — Agent invocation pattern for Phase 4 review/fix calls is unspecified

The config defines agent commands (`claude --print`, `gemini`, `codex`) and the pseudocode shows "run Review call" and "run Fix call." But the spec never describes how a prompt is sent to an agent and how structured JSON is received back. A developer needs to know: is the prompt sent via stdin, as a CLI argument, as a file path? How is the JSON response captured — stdout, a file, a stream?

**Add a subsection under Phase 4 or under the Stack section:**

> ### Agent Invocation Pattern
>
> ThoughtForge invokes coding agents as CLI subprocesses. The pattern for all Phase 4 calls:
>
> 1. **Prompt assembly:** The plugin's `reviewer.js` builds the full review prompt (including `constraints.md` content and deliverable content). For fix calls, the orchestrator assembles the prompt from the review JSON issues and recommendations.
> 2. **Invocation:** The orchestrator spawns the agent as a child process using the `command` and `flags` from `config.yaml`. The prompt is passed via stdin pipe.
>    ```
>    echo "{prompt}" | {agent.command} {agent.flags}
>    ```
> 3. **Response capture:** Agent stdout is captured as a string. For review calls, the orchestrator extracts the JSON block from the response (scanning for the first `{` to last `}` at the top level), then validates against the plugin's Zod schema. For fix calls, the agent writes files directly to the project directory (agents like Claude Code and Codex do this natively).
> 4. **Timeout:** Each agent call has a configurable timeout (default: 5 minutes for review, 10 minutes for fix). On timeout, the orchestrator retries once, then halts and notifies the human.
>
> Agent-specific invocation quirks (e.g., Claude Code's `--print` flag for non-interactive mode, Codex's `--quiet` flag) are handled by the `flags` field in `config.yaml`, not by orchestrator branching.

---

### 2.7 — Plan document detection for the completeness gate is undefined

The spec says the Plan Completeness Gate "runs automatically at the start of Phase 1 in Code mode when a plan document is detected in `/resources/`." But it doesn't define how a plan document is distinguished from other resource files (reference PDFs, images, data files, code samples).

**Add to the Plan Completeness Gate section, before the Assessment Prompt:**

> **Detection:** The orchestrator scans `/resources/` for `.md` files. Any `.md` file whose first 500 characters contain an OPA Framework table (the string `Outcome` AND `Purpose` AND `Action Scope` within a markdown table) OR whose filename contains `plan` (case-insensitive) is treated as a candidate plan document and passed to the assessment prompt. Non-markdown files and markdown files that don't match either condition are treated as supplementary resources and skipped. If multiple plan documents are detected, all are assessed individually — each must pass or the entire set is flagged.
