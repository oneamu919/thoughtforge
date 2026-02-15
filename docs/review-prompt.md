read these files to understand the Project
thoughtforge-requirements-brief.md

scrutinize  these files and follow this prompt
thoughtforge-design-specification.md
thoughtforge-build-spec.md
thoughtforge-execution-plan.md

# Project Plan Review Prompt

Review this plan as a senior dev who will eventually build from it.

## Rules:
- Read the entire document before flagging anything. If a concern is addressed elsewhere in the plan, it's not a concern.
- If something is addressed but the writing is unclear, say so and give me replacement text. Don't flag it as a gap.
- Design philosophy and architecture decisions are locked. Don't question them, don't suggest alternatives. You're reviewing for completeness and clarity as a plan, not redesigning.
- Evaluate completeness and clarity against standard software engineering best practices. If the plan deviates from or omits something that industry convention would expect at the plan level, flag it.
- If the plan explicitly marks something as future or "not a build dependency," don't flag it.
- Don't speculate about edge cases the architecture already handles through its core loop mechanics.
- This is a plan, not a build spec. Do NOT review for implementation details like function signatures, module wiring, file manifests, or code-level data flow. If you find implementation detail that doesn't belong in a plan, flag it for extraction.
- For every issue you raise: specific replacement text or proposed content to add. No vague observations.
- If you're below 80% sure something is actually a problem, don't include it.

## Severity Ratings:
Every finding must be tagged with exactly one severity:
- **Critical** -- The build cannot proceed without resolving this. Missing requirements, contradictions, or ambiguities that would block implementation or guarantee rework.
- **Major** -- The build can start but this will cause significant rework, misalignment, or quality issues if not resolved before or during implementation.
- **Minor** -- Clarity or quality improvement. Won't block the build or cause rework, but raises the bar on the plan as a communication document.

## Output Format:
Three output lists only. Each finding within each list must be prefixed with its severity tag -- [Critical], [Major], or [Minor]. Sort findings within each list by severity (Critical first, then Major, then Minor).

1. **Writing that's unclear** -- with exact replacement text.
2. **Genuinely missing plan-level content** -- with proposed content to add.
3. **Build spec material that should be extracted** -- identify each section and why it belongs in a build spec, not the plan.