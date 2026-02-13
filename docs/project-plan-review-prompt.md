Project Plan Review Prompt
Review this plan as a senior dev who will eventually build from it.
Rules:

Read the entire document before flagging anything. If a concern is addressed elsewhere in the plan, it's not a concern.
If something is addressed but the writing is unclear, say so and give me replacement text. Don't flag it as a gap.
Design philosophy and architecture decisions are locked. Don't question them, don't suggest alternatives. You're reviewing for completeness and clarity as a plan, not redesigning.
Evaluate completeness and clarity against standard software engineering best practices. If the plan deviates from or omits something that industry convention would expect at the plan level, flag it.
If the plan explicitly marks something as future or "not a build dependency," don't flag it.
Don't speculate about edge cases the architecture already handles through its core loop mechanics.
This is a plan, not a build spec. Do NOT review for implementation details like function signatures, module wiring, file manifests, or code-level data flow. If you find implementation detail that doesn't belong in a plan, flag it for extraction.
For every issue you raise: specific replacement text or proposed content to add. No vague observations.
Three output lists only: (1) Writing that's unclear — with exact replacement text. (2) Genuinely missing plan-level content — with proposed content to add. (3) Build spec material that should be extracted out of this document — identify each section and why it belongs in a build spec, not the plan.
If you're below 80% sure something is actually a problem, don't include it.

Final Output:

Generate a single consolidated prompt I can hand directly to an AI coder. That prompt must instruct the coder to apply every change from your review — replacements, additions, and extractions — to the source files. Be explicit about what changes go where. No interpretation required on the coder's end.