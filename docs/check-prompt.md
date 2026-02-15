Read these files:
results.md

Based on what you read, do these project files still need updates or not?

The convergence criteria is: 0 critical findings, fewer than 3 major findings, fewer than 5 minor findings. If the review meets that criteria, updates are not necessary. If it does not, updates are still needed.

Write your answer in this format:
- result: true or false (true = still needs updates, false = no updates needed)
- Your counts of critical, major, and minor findings
- One sentence explaining your reasoning

If result is true, create or overwrite the file apply-prompt.md with a prompt that instructs an AI coder to apply every change from the findings in results.md — replacements, additions, and extractions — to the source files. Be explicit about what changes go where. No interpretation required on the coder's end. The prompt must conclude by instructing the AI coder to git commit and sync to remote once all changes have been applied. The apply-prompt.md file MUST exist on disk before you finish.

If result is false, do not modify apply-prompt.md.