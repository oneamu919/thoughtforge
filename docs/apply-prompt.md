# Apply Review Findings

Apply every change listed below to the source files. Each change includes the target file, the location, and the exact replacement or addition. Do not interpret or improvise — apply as written.

---

## Source files

- **Design spec:** `docs/thoughtforge-design-specification.md`
- **Build spec:** `docs/thoughtforge-build-spec.md`
- **Execution plan:** `docs/thoughtforge-execution-plan.md`

Read ALL three files before making any edits.

---

## Changes to Apply

### 1. [Minor] Design spec — Phase 2 Step 4 acceptance criteria ambiguity

Find the Phase 2, Step 4 passage where "at least 1, target 5–10" acceptance criteria are described.

Replace with:

> 4. AI derives acceptance criteria from the objective, assumptions, and constraints in `intent.md`. The validation gate enforces a minimum of 1 criterion; the target range of 5–10 is guidance for the AI prompt, not an enforced threshold. For Plan mode, criteria assess document completeness, logical coherence, and actionability. For Code mode, criteria assess functional requirements that map to testable acceptance tests in Phase 3.

---

### 2. [Minor] Design spec — Phase 3 Code mode stuck detection inconsistency

Find the test-fix cycle section in Phase 3 Code Mode (the passage describing stuck detection).

Replace with:

> **Stuck detection within the test-fix cycle:** Two conditions trigger stuck detection: (1) the build agent returns non-zero exit on the same build task after 2 consecutive retries, OR (2) the test suite fails on the identical set of test names for 3 consecutive fix-and-retest cycles (compared by exact string match). If each cycle produces different failing tests (rotating failures), condition (2) does not trigger.

Also update the Phase 3 Stuck Detection table, Code row, to read:

> | Code | See test-fix cycle stuck detection above. | Notify and wait |

---

### 3. [Minor] Design spec — Phase 4 Fix Regression guard

Find the Fix Regression guard row in the convergence guards table.

Replace with:

> | Fix Regression (per-iteration) | Evaluated immediately after each fix step, before other guards. Compares the post-fix total error count against the pre-fix review count for the same iteration. **Single occurrence:** If the fix increased the total error count, log a warning but continue. **Consecutive occurrences:** If the two most recent fix steps both increased their respective error counts, halt and notify: "Fix step is introducing more issues than it resolves. Review needed." | Warn (single) or Halt (2 consecutive). Notify human. |

---

### 4. [Minor] Design spec — Stagnation Guard missing intent

Find the Stagnation guard row in the convergence guards table.

Replace with:

> | Stagnation | **Intent:** Detect when the deliverable has reached a quality plateau — the reviewer resolves old issues but introduces equally many new cosmetic issues each iteration, producing no net improvement. Two conditions must both be true: (1) **Plateau:** Total error count is identical for `stagnation_limit` consecutive iterations. (2) **Issue rotation:** Fewer than 70% of current-iteration issues match any issue in the immediately prior iteration (match = Levenshtein similarity ≥ 0.8 on `description`). When both are true, the deliverable is converged. | Done (success — treated as converged plateau). Notify human with final error counts and iteration summary. |

---

### 5. [Minor] Design spec — Fabrication Guard compound conditions

Find the Fabrication guard row in the convergence guards table.

Replace with:

> | Fabrication | Two conditions must both be true: (1) **Category spike:** A single severity category count exceeds its trailing average by more than 50% (with a minimum absolute increase of 2). Trailing window size defined in build spec. (2) **Prior near-convergence:** The system previously reached within 2× of the termination thresholds in at least one prior iteration (i.e., critical ≤ 0, medium ≤ 6, minor ≤ 10 with default config). This ensures fabrication is only flagged after the deliverable was demonstrably close to convergence — not during early volatile iterations. The `2×` multiplier is hardcoded; the base thresholds are read from `config.yaml` at runtime. Parameters in build spec. | Halt. Notify human. |

---

### 6. [Minor] Design spec — Halt vs. Terminate distinction buried

Find the paragraph describing the halt vs. terminate distinction (currently between convergence guard descriptions and halt recovery).

Move it to immediately before the "Halt Recovery" section and add a subheading:

> **Halt vs. Terminate Distinction:**
>
> When a convergence guard triggers a halt, the project is recoverable — the human can Resume or Override. When the human explicitly Terminates (via button), the project is permanently stopped (`halt_reason: "human_terminated"`). Both use the `halted` phase value in `status.json`; the `halt_reason` field distinguishes them. (Authoritative field values are in the build spec Action Button Behavior table.)

---

### 7. [Minor] Design spec — Chat Interface distracting parenthetical

Find: "Lightweight web chat interface (terminal-based alternative deferred)."

Replace with:

> **ThoughtForge Chat (Built):** Lightweight web chat interface. (A terminal-based alternative is deferred — not a current build dependency.)

---

### 8. [Major] Design spec — Add deliverable edits during Phase 4

After the "Locked File Behavior" section, before Phase 4, add:

> **Deliverable Edits During Phase 4:**
>
> If the human manually edits the deliverable (plan document or source code) between Phase 4 iterations, the edits are picked up by the next iteration's review step — the reviewer reads the current state of the deliverable from disk. The next fix step's git commit captures both the human's edits and the AI's fixes. The pipeline does not detect, warn about, or distinguish human edits from AI fixes. This is by design — the human has full authority to modify the deliverable at any time. The convergence trajectory may shift as a result (human edits could increase or decrease error counts). No special handling is needed.

---

### 9. [Major] Design spec — Add Template Slot Validation

In Phase 3 Plan Mode, after the "Template Content Escaping" section, add:

> **Template Slot Validation:** After each plan builder invocation, the orchestrator validates that the returned content corresponds to a valid template slot. If the AI returns content for a non-existent slot, the content is discarded with a warning logged. If a required template slot receives empty or placeholder content (containing "TBD", "TODO", or "placeholder" — case-insensitive), the builder re-invokes the AI for that slot (subject to the standard retry-once-then-halt behavior). After all invocations complete and the template is assembled, a final validation confirms all slots are filled. Any remaining empty slots halt the builder with a notification identifying the unfilled sections.

---

### 10. [Major] Execution plan — Add TypeScript to Task 1

Find Task 1 in the Task Breakdown of the execution plan.

Replace Task 1's description with:

> Initialize Node.js project with TypeScript: `tsconfig.json` (`"module": "nodenext"`, `"moduleResolution": "nodenext"`), `package.json` with ESM (`"type": "module"`), `start` script targeting compiled output, `dev` script using `tsx` for development, `build` script running `tsc`, and folder structure. Install initial dependencies (per build spec Initial Dependencies). Implement `config.yaml` loader with Zod schema validation.

---

### 11. [Minor] Design spec — Add Phase 2 Challenge step persistence

After Phase 2 step 2, add:

> Challenge findings that result in design changes are captured in the `spec.md` "Key Decisions" section with the original concern and resolution. Challenge findings that the human dismisses are not persisted beyond the chat history. Since chat history is cleared on Phase 2→3 transition, dismissed challenges are not available for later reference. This is acceptable — the human's decisions are captured in `spec.md`; the reasoning for rejected alternatives is not.

---

### 12. [Minor] Execution plan — Add static assets to Task 7

Find Task 7 ("Build ThoughtForge web chat interface") in the execution plan.

Add to Task 7's description:

> Create `/public/` directory with static assets: `index.html` (single-page chat interface), `style.css`, and `app.js` (vanilla JavaScript for WebSocket client, DOM manipulation, project switching, and action buttons). These are served by Express directly — no build tooling or bundler required.

---

### 13. [Minor] Design spec — Add config reload behavior

In the Configuration section of the design spec, add:

> **Config reload behavior:** `config.yaml` is read once at server startup and cached in memory for the duration of the server process. Changes to `config.yaml` require a server restart to take effect. The one exception is `vibekanban.enabled`, which is read at each VK operation (already specified in VK toggle behavior). Hot-reloading of config is deferred — not a current build dependency.

---

### 14. [Minor] Design spec — Extract Project Initialization detail to build spec

Find Phase 1 step 0 in the design spec. It contains collision retry behavior, agent field assignment, and git init failure handling.

Trim the design spec to the behavioral description and cross-reference: "Project initialization creates the project directory structure, initializes version control, writes the initial project state, optionally registers on the Kanban board, and opens the chat interface. The full initialization sequence — including collision retry, field assignments, and error handling — is in the build spec."

Remove the collision retry algorithm, agent field assignment details (`status.json` `agent` field), and git init failure handling from the design spec. These already exist in the build spec's "Project Initialization Sequence" section.

---

### 15. [Minor] Design spec — Extract VK toggle truth table to build spec

Find the 4-row truth table (VK enabled/disabled × Plan/Code) and toggle-change-during-active-projects paragraph in the design spec.

Replace in the design spec with: "Both modes function fully with VK disabled. VK provides visualization and Code mode agent execution. Plan mode always invokes agents directly. Implementation details including the toggle truth table are in the build spec."

Move the removed truth table and toggle-change handling to the build spec's VK CLI Interface section.

---

### 16. [Minor] Design spec — Extract Phase 1-2 Chat Agent Model to build spec

Find the subprocess invocation pattern ("prompt via stdin, response via stdout, one subprocess call per turn") and context assembly details in the design spec.

Replace in the design spec with: "Each chat turn is a stateless AI invocation with full context. There is no persistent agent session. Implementation details are in the build spec."

Move the removed subprocess pattern and context assembly list to the build spec's Agent Communication section.

---

### 17. [Minor] Design spec — Extract WebSocket reconnection detail to build spec

Find the in-flight response handling and operation-completion scenarios in the design spec's WebSocket reconnection content.

Replace in the design spec with: "The client auto-reconnects and syncs state from the server on reconnect. Detailed reconnection behavior is in the build spec."

Move the removed in-flight response handling, operation-completion scenarios, and re-trigger behavior to the build spec's WebSocket Reconnection Parameters section.

---

## After All Changes Are Applied

1. Re-read each modified file to verify no formatting was broken and all changes landed correctly.
2. Git commit and sync:

```bash
git status -u
git diff --stat
git add docs/thoughtforge-design-specification.md docs/thoughtforge-build-spec.md docs/thoughtforge-execution-plan.md
git commit -m "Apply review findings"
git push
git pull
```
