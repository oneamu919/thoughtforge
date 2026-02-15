I've read all four documents thoroughly. Now I'll produce the review.

---

# Project Plan Review — ThoughtForge Pipeline Tool

**Documents reviewed:** Requirements Brief, Design Specification, Build Spec, Execution Plan

**Summary:** Critical 0, Major 2, Minor 8

---

## 1. Writing That's Unclear

**[Minor] Design Spec — Phase 2 Acceptance Criteria count (lines 149 vs 210)**

Phase 2 behavior says "5–10 acceptance criteria" (line 149), but the `constraints.md` structure also says "5–10 statements" (line 210). Phase 2 also includes a validation gate that only checks for "at least 1 criterion" (line 157). The floor of 1 contradicts the stated range of 5–10.

**Replacement text** for the validation gate (Design Spec, line 157):

> Before Phase 2 Confirm advances to Phase 3, the orchestrator validates that the Acceptance Criteria section of the proposed `constraints.md` contains at least 5 criteria (the minimum of the 5–10 target range). If the section contains fewer than 5, the Confirm button is blocked and the AI prompts the human: "At least 5 acceptance criteria are required before proceeding (current: {N}). Add criteria or confirm the AI's proposed set."

Or, if the intent is truly a floor of 1, change the "5–10" language in both locations to "at least 1, target 5–10" so they're consistent.

---

**[Minor] Design Spec — "Stuck" flag on Code plugin builder return (line 256 vs Build Spec line 185)**

Design Spec says Code mode stuck detection is "orchestrator-observed failure patterns" (line 251), and the stuck table says it relies on "2 consecutive non-zero exits" or "3 consecutive identical test failures" — both observed by the orchestrator. But the Build Spec's Plugin Interface Contract (line 185) says the Code plugin builder returns `{ stuck: boolean, reason?: string }`, implying the code builder self-reports stuck status just like the Plan builder.

This creates ambiguity: does the Code builder set `stuck: true` itself, or does the orchestrator observe failure patterns and determine stuck externally? Pick one.

**Replacement text** for Build Spec line 185:

> **Code plugin** returns `Promise<{ success: boolean, reason?: string }>` — `success` is `false` when the current task invocation failed. The orchestrator tracks consecutive failures per task identifier and determines stuck status externally (2 consecutive non-zero exits on the same task, or 3 consecutive identical test failures). The `stuck` flag pattern is Plan-mode-only.

---

**[Minor] Design Spec — "Distilling" and "Human Review" sub-states vs. Phase 1 flow description**

The Kanban column mapping (line 594) lists `distilling` and `human_review` as Phase 1 sub-states, and the Build Spec's `status.json` schema (line 565) shows `brain_dump → distilling → human_review`. But the Phase 1 flow description (lines 59–97) never explicitly names the transition from `distilling` to `human_review`. The reader must piece together that `human_review` is entered when the AI finishes distillation and presents results to the human.

**Add after Design Spec line 89** (after step 6, "AI distills into structured document"):

> When the AI completes distillation and presents the result in chat, `status.json` transitions from `distilling` to `human_review`. This signals that the AI has finished processing and is awaiting human corrections.

---

**[Minor] Design Spec — "Each project gets its own local git repository" vs. Vibe Kanban's git worktree isolation**

Decision #3 says "Each project gets its own local git repository (git init, no remote)" (line 613). But the Vibe Kanban description says VK provides "Git worktree isolation — each task in its own worktree — clean parallel isolation" (line 468). A worktree is a branch of an existing repo, not a separate repo. These are different isolation models.

**Replacement text** for Design Spec line 468:

> | Git worktree isolation | VK manages worktree-based isolation for its internal task execution. ThoughtForge's per-project git repos (created at project initialization) are independent of VK's worktree model. VK operates within the project's existing repo when executing agent work. |

---

## 2. Genuinely Missing Plan-Level Content

**[Major] No error handling for Handlebars template selection failure in Phase 3 Plan mode**

Design Spec line 218 says: "If no type-specific template matches, the `generic.hbs` template is used as the default." The Phase 3 error handling table (line 280) covers "Template directory empty or `generic.hbs` missing." But there's no handling for the case where the deliverable type from `intent.md` maps to a template name that doesn't exist (e.g., deliverable type is "marketing" but no `marketing.hbs` exists) — the spec jumps straight to `generic.hbs` without logging or notifying the human that a type-specific template was expected but not found.

**Proposed content** — add to Phase 3 error handling table in Design Spec:

> | Type-specific template not found but `generic.hbs` exists | Log a warning: "No template found for plan type '{type}'. Using generic template." Notify the human in chat. Proceed with `generic.hbs`. |

---

**[Major] No specification for how Phase 2 chat history is handled on crash during Phase 2**

Design Spec specifies chat history clearing on Phase 1→2 and Phase 2→3 transitions. It specifies crash recovery behavior for Phase 4 (`polish_state.json`) and Phase 1 (resume from last message in `chat_history.json`). But it doesn't explicitly state crash recovery for Phase 2. The reader must infer it follows the same pattern as Phase 1. While probably obvious, Phase 2 has a distinct behavior — the AI presents all proposed elements in a single structured message and iterates on them — so crash recovery during spec building should be stated.

**Proposed content** — add to Phase 2 Error Handling table in Design Spec:

> | Server crash during Phase 2 conversation | On restart, `status.json` phase is `spec_building` (an interactive state — not auto-halted per Server Restart Behavior). Chat resumes from the last recorded message in `chat_history.json`. The AI re-reads `intent.md` and the chat history to reconstruct the spec-in-progress, then re-presents the current proposal for human review. |

---

## 3. Build Spec Material That Should Be Extracted

**[Minor] Design Spec — `PlanBuilderResponse` interface mentioned inline (line 255)**

The Design Spec references `PlanBuilderResponse` by schema name and describes its fields (`stuck: boolean`, `reason` field). This is implementation-level schema detail. The Build Spec already contains the full `PlanBuilderResponse` interface (Build Spec line 406–413). The Design Spec should reference the behavior ("AI signals when stuck") and point to the Build Spec for the schema, not duplicate it.

**Recommendation:** Replace Design Spec line 255–256 with:

> | Plan | AI includes a stuck signal in every builder response. When the AI reports stuck, the orchestrator halts and notifies with the AI's stated reason. Response schema in build spec (`PlanBuilderResponse`). | Notify and wait |

---

**[Minor] Design Spec — WebSocket reconnection parameters (line 580)**

The Design Spec says "Reconnection parameters (backoff strategy, timing) are in the build spec." This is correct delegation. However, the sentence immediately before it (line 579) says "On successful reconnect, state is synced from the server" — this level of sync protocol detail (client sends project ID, server responds with `status.json` and `chat_history.json`) is already fully specified in the Build Spec's WebSocket Reconnection Parameters and the Design Spec's "Server-side session" section. The Design Spec's "Reconnection behavior" bullet list (lines 579–580) partially duplicates what's in both places. No action needed since it's brief, but flagging as borderline.

---

**[Minor] Design Spec — Action Button Behavior inventory (lines 108-110)**

The Design Spec says "Complete button inventory with `status.json` effects and UI behavior is specified in the build spec." The Build Spec has this full inventory (Build Spec lines 489–508). This is correctly delegated. But the Design Spec then proceeds to describe individual button behaviors inline in Phase 1, Phase 3, Phase 4, and Plan Completeness Gate sections — including `status.json` effects and confirmation requirements. This creates two sources of truth for button behavior.

**Recommendation:** Remove the per-section inline button behavior descriptions from the Design Spec (they exist in Phase 3 Stuck Recovery, Phase 4 Halt Recovery, and Plan Completeness Gate sections) and replace each with a reference: "Button behavior and `status.json` effects are specified in the build spec Action Button Behavior inventory."

---

**[Minor] Design Spec — Levenshtein similarity threshold for stagnation (line 343)**

The Design Spec mentions "rotation threshold and similarity measure defined in build spec" but then also states the concept of issue rotation detection inline. The Build Spec (line 305–306) contains the actual parameters: "Levenshtein similarity ≥ 0.8" and "fewer than 70% of current issues find a match." The Design Spec's inline description of the concept is appropriate for a design document, but the 70% and 0.8 thresholds should only live in the Build Spec. Currently the Design Spec correctly does NOT state the numbers — this is fine as-is. No extraction needed.

---

**End of review.**
