# Apply Prompt — results.md Findings (Iteration 3)

The latest review (`results.md`) found **3 Major** and **10 Minor** findings with **0 Critical**. This does not meet convergence (need <3 Major, <5 Minor). The summary identifies the findings by topic but does not provide itemized replacement text. You must locate each issue, determine the fix, and apply it.

**Source files:**
- `docs/thoughtforge-design-specification.md` (referred to as "design spec")
- `docs/thoughtforge-build-spec.md` (referred to as "build spec")
- `docs/thoughtforge-execution-plan.md` (referred to as "exec plan")
- `docs/thoughtforge-requirements-brief.md` (referred to as "requirements brief")

**Context files (read for understanding, do not modify):**
- `docs/review-results.md` — Round 2 detailed findings (already applied, but useful for understanding what was previously addressed)
- `docs/results.md` — Round 3 summary (the review you are fixing)

---

## Step 1: Read all source files and review files

Read `results.md`, `review-results.md`, and all four source files end-to-end before making any changes. You need the full context.

---

## Step 2: Fix the 3 Major Findings

The `results.md` summary identifies these three majors by topic:

### Major 1: Phase 3→4 transition error handling

**Topic:** The Phase 3 to Phase 4 transition lacks explicit error handling. This will generate questions from whoever implements Task 6c.

**What to find and fix:** In the design spec, locate the Phase 3→4 transition (where Phase 3 build completes and Phase 4 polish begins). Determine what happens if the transition fails — e.g., if Phase 3 output is missing, malformed, or incomplete when Phase 4 tries to start. Add explicit error handling text: what the orchestrator does on failure (halt, retry, notify), what state is written to `status.json`, and what the human sees.

### Major 2: Action button UI behavior

**Topic:** Action button behavior in the chat UI is underspecified. This will generate questions from whoever implements Task 10.

**What to find and fix:** In the design spec, locate all places where action buttons are presented to the user in the chat interface (Phase 2 Confirm, Phase 3 stuck recovery, Phase 4 halt recovery, Plan Completeness Gate Override/Terminate). For each set of buttons, ensure the following is specified: (a) what each button does to `status.json`, (b) what the chat UI shows after the button is pressed, (c) whether the button is a one-click action or requires confirmation. If any button interaction is missing these details, add them.

### Major 3: Connector URL handling

**Topic:** Connector URL handling is underspecified. This will generate questions during Task 8 implementation.

**What to find and fix:** In the design spec and/or build spec, locate the connector/notification sections (ntfy.sh, Vibe Kanban webhook). Determine what happens when the configured URL is invalid, missing, has no scheme, or points to an unreachable endpoint. Add explicit handling: validation on startup vs. runtime, what error is shown, whether the pipeline halts or continues.

---

## Step 3: Fix the 10 Minor Findings

The `results.md` summary does not enumerate the 10 minor findings individually. You must identify them yourself by re-reviewing the source files using the review prompt criteria in `docs/review-prompt.md`. Minor findings are clarity or quality improvements — unclear writing, inconsistent terminology, formatting issues, redundant text, or style inconsistencies.

To find them:
1. Read `docs/review-prompt.md` for the review criteria and severity definitions.
2. Re-read all three source files looking for minor-level issues: unclear phrasing, inconsistent terminology between documents, formatting problems in tables, redundant or contradictory statements, missing cross-references.
3. Fix each one in place with clear, minimal edits. Do not restructure or redesign — only improve clarity and consistency.

---

## Step 4: Verify

After applying all changes:
1. Re-read every modified section to ensure no formatting was broken (markdown tables, indentation, list numbering, link references).
2. Confirm all three major topics have been addressed with explicit, unambiguous text.
3. Count your fixes to confirm you addressed all 3 majors and at least 10 minors.

---

## Step 5: Commit and sync

```bash
git add docs/thoughtforge-design-specification.md docs/thoughtforge-build-spec.md docs/thoughtforge-execution-plan.md docs/thoughtforge-requirements-brief.md
git commit -m "Apply review findings: fix Phase 3→4 transition error handling, clarify action button UI behavior, specify connector URL handling, fix 10 minor clarity issues"
git push
```

Only include files you actually modified in the `git add` command. Do not add files you did not change.
