Done. Here's my evaluation:

- **result: true** — still needs updates
- **Critical: 1** (no error handling for unparseable AI responses in non-review steps)
- **Major: 4** (undefined internal format for agent adapters, no test framework specified, no VK CLI verification task, no git init failure handling)
- **Minor: 11** (several are "no change needed" after inspection, but the actionable ones still exceed the threshold)
- The review fails convergence on two criteria: critical findings must be 0 (found 1), and major findings must be fewer than 3 (found 4).

`apply-prompt.md` has been written with 18 explicit changes across all three target files (design spec, build spec, execution plan), with exact find/replace text, addition locations, and a git commit+push instruction at the end.
