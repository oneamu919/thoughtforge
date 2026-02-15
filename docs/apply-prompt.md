# Apply Review Findings from results.md

You are an AI coder. Apply every change listed below to the source files. Each change is taken directly from the review findings in `docs/results.md`. Do not interpret or improvise — apply the replacements, additions, and extractions exactly as specified.

Read all target files before editing. After all changes are applied, git commit and sync to remote.

---

## Target Files

- `docs/thoughtforge-design-specification.md` (referred to as "Design Spec")
- `docs/thoughtforge-build-spec.md` (referred to as "Build Spec")

Read both files before making any edits.

---

## SECTION 1: Replacements (Unclear Writing)

### Change 1 — Design Spec, Phase 2 Acceptance Criteria validation gate (line ~157) [Minor]

Find the validation gate text that checks for "at least 1 criterion" before Phase 2 Confirm advances to Phase 3. Replace it with:

> Before Phase 2 Confirm advances to Phase 3, the orchestrator validates that the Acceptance Criteria section of the proposed `constraints.md` contains at least 5 criteria (the minimum of the 5–10 target range). If the section contains fewer than 5, the Confirm button is blocked and the AI prompts the human: "At least 5 acceptance criteria are required before proceeding (current: {N}). Add criteria or confirm the AI's proposed set."

Alternatively, if the rest of the spec implies a true floor of 1, change the "5–10" language in both the Phase 2 behavior (line ~149) and `constraints.md` structure (line ~210) to "at least 1, target 5–10" so they are consistent. Pick whichever approach aligns with the spec's existing intent.

---

### Change 2 — Build Spec, Code plugin builder return type (line ~185) [Minor]

Find the Code plugin's builder return type in the Plugin Interface Contract. Replace the return type description so it no longer includes a `stuck` field. Use this text:

> **Code plugin** returns `Promise<{ success: boolean, reason?: string }>` — `success` is `false` when the current task invocation failed. The orchestrator tracks consecutive failures per task identifier and determines stuck status externally (2 consecutive non-zero exits on the same task, or 3 consecutive identical test failures). The `stuck` flag pattern is Plan-mode-only.

---

### Change 3 — Design Spec, Phase 1 sub-state transition (after line ~89) [Minor]

After step 6 in the Phase 1 flow description ("AI distills into structured document"), add:

> When the AI completes distillation and presents the result in chat, `status.json` transitions from `distilling` to `human_review`. This signals that the AI has finished processing and is awaiting human corrections.

---

### Change 4 — Design Spec, Vibe Kanban git worktree isolation row (line ~468) [Minor]

Find the Vibe Kanban feature table row about "Git worktree isolation." Replace the row content with:

> | Git worktree isolation | VK manages worktree-based isolation for its internal task execution. ThoughtForge's per-project git repos (created at project initialization) are independent of VK's worktree model. VK operates within the project's existing repo when executing agent work. |

---

## SECTION 2: Additions (Missing Plan-Level Content)

### Change 5 — Design Spec, Phase 3 error handling table: Template selection failure [Major]

Find the Phase 3 error handling table (near line ~280). Add a new row:

> | Type-specific template not found but `generic.hbs` exists | Log a warning: "No template found for plan type '{type}'. Using generic template." Notify the human in chat. Proceed with `generic.hbs`. |

---

### Change 6 — Design Spec, Phase 2 error handling table: Crash recovery [Major]

Find the Phase 2 error handling table. Add a new row:

> | Server crash during Phase 2 conversation | On restart, `status.json` phase is `spec_building` (an interactive state — not auto-halted per Server Restart Behavior). Chat resumes from the last recorded message in `chat_history.json`. The AI re-reads `intent.md` and the chat history to reconstruct the spec-in-progress, then re-presents the current proposal for human review. |

---

## SECTION 3: Extractions (Move Implementation Details from Design Spec to Build Spec)

### Change 7 — Design Spec, `PlanBuilderResponse` inline schema (line ~255–256) [Minor]

Find the stuck detection table row for Plan mode that references `PlanBuilderResponse` and describes its fields (`stuck: boolean`, `reason` field). Replace it with:

> | Plan | AI includes a stuck signal in every builder response. When the AI reports stuck, the orchestrator halts and notifies with the AI's stated reason. Response schema in build spec (`PlanBuilderResponse`). | Notify and wait |

---

### Change 8 — Design Spec, inline button behavior descriptions [Minor]

In these Design Spec sections, remove the inline button behavior descriptions (including `status.json` effects and confirmation requirements) and replace each with a reference line:

- Phase 3 Stuck Recovery section
- Phase 4 Halt Recovery section
- Plan Completeness Gate section

Replace the inline descriptions in each with:

> Button behavior and `status.json` effects are specified in the build spec Action Button Behavior inventory.

---

## After All Changes Are Applied

1. Re-read each modified file to confirm no formatting is broken (unclosed tables, orphaned headers, broken markdown).
2. `git status -u` — verify all modified files.
3. `git diff --stat` — confirm changes.
4. Git add only the files you modified.
5. Commit with message: `Apply review findings`
6. Push to remote: `git push`
7. `git pull` — confirm sync with remote. Do not leave commits unpushed.
