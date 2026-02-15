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

### Change 1 — Design Spec: Stagnation Guard wording (Minor)

**Location:** Phase 4 Convergence Guards, Stagnation Guard description.

**Find:**
> Same total error count for 3+ consecutive iterations AND issue rotation detected — fewer than 70% of current issues match issues from the immediately prior iteration by description similarity.

**Replace with:**
> Same total error count for 3+ consecutive iterations AND issue replacement detected — fewer than 70% of current issues have a matching issue in the immediately prior iteration by description similarity. This indicates the reviewer is finding new issues to replace resolved ones, producing a plateau rather than genuine progress.

---

### Change 2 — Design Spec: Fabrication Guard wording (Minor)

**Location:** Phase 4 Convergence Guards, Fabrication Guard description.

**Find the text containing:**
> A severity category spikes significantly above its trailing 3-iteration average, AND the system had previously reached within 2× of convergence thresholds in at least one prior iteration — suggesting the reviewer is manufacturing issues because nothing real remains

**Replace with:**
> A severity category spikes significantly above its trailing 3-iteration average, AND the system had previously reached counts within 2× of the termination thresholds (i.e., critical ≤ 0, medium ≤ 6, minor ≤ 10) in at least one prior iteration — suggesting the reviewer is manufacturing issues because nothing real remains

---

### Change 3 — Design Spec: Connector URL identification formatting (Minor)

**Location:** Phase 1 step 3, the "Connector URL identification" paragraph that follows step 3.

**Action:** Prefix the paragraph explicitly to clarify it belongs to step 3. Change the opening to:

> **Step 3 Detail — Connector URL Identification:** The AI identifies connector URLs in chat messages by matching against known URL patterns...

Keep the rest of the paragraph text intact. Only add the bold prefix and indent it under step 3.

---

### Change 4 — Design Spec: Locked File Behavior wording (Minor)

**Location:** Locked File Behavior section.

**Find:**
> If the file is readable but has modified structure, ThoughtForge passes it to the AI reviewer without structural validation. The reviewer processes whatever content it receives — no special handling is required for structural variations.

**Replace with:**
> If the file is readable but has been restructured by the human (missing sections, reordered content, added sections), ThoughtForge passes it to the AI reviewer as-is without validating that it matches the original `constraints.md` schema. The reviewer processes whatever content it receives.

---

### Change 5 — Execution Plan: Cross-stage dependency note (Minor)

**Location:** Build Stage 1 cross-stage dependency note.

**Find:**
> Agent Layer (Build Stage 7, Tasks 41–44) provides the core agent invocation mechanism used by Stages 2–6. Task 41 depends on Task 1 (foundation), so Build Stage 7 should begin as soon as Task 1 completes, overlapping with the remainder of Build Stage 1.

**Replace with:**
> Agent Layer (Build Stage 7, Tasks 41–44) provides the core agent invocation mechanism used by Stages 2–6. Task 41 depends only on Task 1 (foundation), so Build Stage 7 should begin as soon as Task 1 completes. Stage 1 Tasks 2–6e and Stage 7 Tasks 41–44 can proceed in parallel. Any task that invokes an AI agent (Tasks 8, 12, 15, 21, 30) must wait for Tasks 41–42 to complete.

---

### Change 6 — Design Spec: Server Restart Behavior explanation (Minor)

**Location:** Server Restart Behavior section.

**Find:**
> Projects in autonomous states (`distilling`, `building`, `polishing`) — where the AI was actively processing without human interaction — are set to `halted` with `halt_reason: "server_restart"` and the human is notified.

**Replace with:**
> Projects in autonomous states (`distilling`, `building`, `polishing`) are set to `halted` with `halt_reason: "server_restart"`. These are not auto-resumed because the server cannot safely re-enter a mid-execution agent invocation or polish iteration — the prior subprocess is dead and its partial output is unknown. The human must explicitly resume.

---

### Change 7 — Design Spec: Add Access Control statement (Major)

**Location:** Under Technical Design → ThoughtForge Stack, after the Server entry.

**Action:** Insert this new subsection:

> **Access Control:** When bound to localhost (`127.0.0.1`), no authentication is required — only the local operator can access the interface. If the operator changes the bind address to allow network access (`0.0.0.0` or a specific network interface), a warning is logged at startup: "Server bound to network interface. No authentication is configured — any network client can access ThoughtForge." Authentication and access control are deferred — not a current build dependency. The operator assumes responsibility for network security when binding to non-localhost addresses.

---

### Change 8 — Design Spec: Add Connector failure during distillation note (Major)

**Location:** Phase 1 Error Handling table, as a clarifying note below the table.

**Action:** Insert below the Phase 1 Error Handling table:

> **Connector failure during distillation:** If a connector fails after the human clicks Distill, the distillation proceeds automatically using all successfully retrieved inputs. The human is notified of the connector failure in chat but does not need to re-click Distill. The failed connector resources are simply absent from the distillation context.

---

### Change 9 — Design Spec: Add Browser Compatibility statement (Minor)

**Location:** Under UI → ThoughtForge Chat section.

**Action:** Insert this new entry:

> **Browser Compatibility:** The chat interface targets modern evergreen browsers (Chrome, Firefox, Edge, Safari — current and previous major version). No IE11 or legacy browser support. ES6+ JavaScript features and native WebSocket API are assumed available.

---

### Change 10 — Design Spec: Add Concurrent edit handling statement (Minor)

**Location:** Under UI → Prompt Management section.

**Action:** Insert:

> **Concurrent edit handling:** The prompt editor uses a last-write-wins model with no conflict detection. Since this is a single-operator tool, concurrent tab edits are the operator's responsibility.

---

### Change 11 — Design Spec: Add log rotation note (Minor)

**Location:** Under Functional Design → Phase 1 → Disk management paragraph. Append to end of existing paragraph.

**Action:** Append:

> Operational logs (`thoughtforge.log`) also accumulate without rotation or size limits in v1. The operator is responsible for manual log management. Automated log rotation is deferred — not a current build dependency.

---

### Change 12 — Design Spec: Remove Levenshtein threshold (extraction) (Minor)

**Location:** Phase 4, Stagnation Guard description (same area as Change 1).

**Find** (after Change 1 has been applied) the text:
> Levenshtein similarity ≥ 0.8 on the `description` field

**Replace the surrounding clause so it reads:**
> fewer than 70% of current issues match issues from the immediately prior iteration by description similarity (match threshold defined in build spec)

Do NOT modify the build spec — it already contains "Levenshtein similarity ≥ 0.8 on the `description` field" at ~lines 303-304.

---

### Change 13 — Design Spec: Replace threshold numbers in Convergence Guards table (extraction) (Minor)

**Location:** Convergence Guards table (~lines 295-301).

In the **Stagnation guard** row, replace:
- "Same total error count for 3+ consecutive iterations" → "Same total error count for consecutive iterations exceeding the configured stagnation limit"
- "fewer than 70% of current issues match" → "issue replacement detected (rotation threshold and similarity measure defined in build spec)"

In the **Fabrication guard** row, replace:
- "trailing 3-iteration average" → "trailing average (window size defined in build spec)"
- "within 2× of convergence thresholds" → "within a multiplier of convergence thresholds (multiplier defined in build spec)"

Do NOT change the Hallucination guard row — it is already correctly written without inline numbers.

---

### Change 14 — Design Spec: Remove default values from Configuration table (extraction) (Minor)

**Location:** Configuration table (~lines 573-584).

In the "Defaults" column of every row, replace each specific default value with:
> See `config.yaml` template in build spec

Keep the "What's Configurable" column unchanged — that is plan-level content.

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
