Now I have all four documents thoroughly read. Let me produce the review.

---

# ThoughtForge Plan Review ΓÇö Findings

Documents reviewed: `thoughtforge-design-specification.md`, `thoughtforge-build-spec.md`, `thoughtforge-execution-plan.md` (against `thoughtforge-requirements-brief.md` as source of truth).

---

## 1. Writing That's Unclear

**[Minor] Design Spec ΓÇö "Stagnation" guard described as both "halt" and "success" in close proximity (Phase 4 Convergence Guards table vs. guard detail)**

The Convergence Guards table says Stagnation action is: `Done. Notify human.` But two sentences later in the same section: `"Done (success). Notify human ΓÇö same notification path as Termination success: status set to done..."` The table's terse "Done. Notify human." doesn't communicate that stagnation is treated as *success*, not as a halt. A reader scanning the table sees "Hallucination ΓåÆ Halt" and "Stagnation ΓåÆ Done" and could read "Done" as "loop stopped" rather than "loop succeeded."

**Replacement text for the Stagnation row in the Convergence Guards table:**

> | Stagnation | Same total error count for 3+ consecutive iterations AND issue rotation detected ΓÇö fewer than 70% of current issues match prior iteration issues by description similarity. Algorithmic parameters (similarity threshold, window sizes) defined in build spec. | Done (success ΓÇö treated as converged plateau). Notify human with final error counts and iteration summary. |

---

**[Minor] Design Spec ΓÇö "Manual Edit Behavior" placement and scope is confusing**

The sentence `"Locked" means the AI pipeline will not modify these files after their creation phase.` appears under a standalone bold heading "Manual Edit Behavior" wedged between Phase 2 step 9 outputs and the `constraints.md` hot-reload explanation. The heading suggests it covers manual editing behavior, but it actually defines what "locked" means. The manual edit *consequences* (hot-reload for constraints, static for spec/intent) are in the paragraphs below but are not grouped under the heading.

**Replacement text:** Replace the standalone heading and sentence with:

> **Locked File Behavior:** "Locked" means the AI pipeline will not modify these files after their creation phase. The human may still edit them manually outside the pipeline, with the following consequences:

Then keep the existing `constraints.md` and `spec.md`/`intent.md` paragraphs as sub-bullets under this heading.

---

**[Minor] Design Spec ΓÇö Phase 1 step 11 conflates two distinct actions in one sentence**

> `Output: intent.md written to /docs/ and locked ΓÇö no further modification by AI in subsequent phases. Human may still edit manually outside the pipeline. The deliverable_type field in status.json is set to "plan" or "code" at this point, derived from the Deliverable Type section of the confirmed intent.md.`

This single sentence covers file output, locking semantics, manual edit policy, *and* a separate state update. A builder could miss the `deliverable_type` derivation buried at the end.

**Replacement text:**

> 11a. Output: `intent.md` written to `/docs/` and locked ΓÇö no further modification by AI in subsequent phases. Human may still edit manually outside the pipeline.
>
> 11b. The `deliverable_type` field in `status.json` is set to `"plan"` or `"code"`, derived from the Deliverable Type section of the confirmed `intent.md`.

---

**[Minor] Design Spec ΓÇö "Distilling" column missing from Kanban column mapping**

The Kanban column list says: `Brain Dump ΓåÆ Distilling ΓåÆ Human Review ΓåÆ Spec Building ΓåÆ Building ΓåÆ Polishing ΓåÆ Done.` But the surrounding prose says `"Confirmed" is not a separate column` ΓÇö which makes sense ΓÇö while never explicitly stating that `Distilling` *is* a separate column even though it's a transient sub-state within Phase 1. A builder implementing the VK adapter will ask: is "Distilling" a visible column on the board, or a card state within the "Brain Dump" column?

**Replacement text:** Add a clarifying sentence after the column list:

> `Distilling` and `Human Review` are separate Kanban columns representing Phase 1 sub-states ΓÇö the card moves from Brain Dump ΓåÆ Distilling ΓåÆ Human Review as the phase progresses.

---

**[Minor] Execution Plan ΓÇö Task 40 description is ambiguous about scope**

> `40 | Implement git auto-commit after each review and fix step`

Task 2a already says it handles `Phase 3 build completion (including the Phase 3ΓåÆ4 transition commit)` and explicitly defers Phase 4 per-iteration commits to Task 40. But Task 40's description says only "review and fix step" ΓÇö it doesn't say "Phase 4" anywhere. A builder could misread this as applying to all phases.

**Replacement text:**

> `40 | Implement Phase 4 per-iteration git auto-commits: commit after each review step and after each fix step (two commits per iteration)`

---

**[Minor] Design Spec ΓÇö "Per-project agent override is deferred" is stated but never connected to the config**

The Agent Assignment paragraph says: `Per-project agent override is deferred ΓÇö not a current build dependency.` But `config.yaml` defines an `agents.default` key with no per-project override key even as a placeholder. The build spec's `status.json` schema stores `agent: string` per project. A builder may wonder: does Phase 1 initialization just copy `config.yaml agents.default` into `status.json.agent`, and that's it?

**Replacement text:** Add to the Agent Assignment paragraph:

> At project initialization, `config.yaml` `agents.default` is copied to the project's `status.json` `agent` field. This value is used for all pipeline phases of that project. There is no mechanism to change the agent mid-project or override it per-project in v1.

---

## 2. Genuinely Missing Plan-Level Content

**[Major] No error handling for Phase 2 `spec.md` / `constraints.md` generation failure**

Phase 1 and Phase 3 both have error handling tables. Phase 2 has an error handling table that covers agent failure and unresolved unknowns ΓÇö but does not address the case where the actual *generation* of `spec.md` or `constraints.md` fails (file system write error, AI returns empty or unparseable content for the spec/constraints documents). Phase 3 explicitly handles "expected output files are missing" at the transition boundary, but Phase 2 has no equivalent.

**Proposed content:** Add to the Phase 2 Error Handling table:

> | File system error during `spec.md` or `constraints.md` write | Halt and notify human immediately with file path and error. No retry ΓÇö same behavior as cross-cutting file system error handling. |
> | AI returns empty or structurally invalid content for `spec.md` or `constraints.md` | Retry once. On second failure, halt and notify human. |

---

**[Major] No definition of what "same task" means for Code mode stuck detection in the design spec**

The design spec says: `"Same task" means consecutive agent invocations with the same prompt intent (e.g., "implement feature X" or "fix test Y") ΓÇö tracked by the code builder's internal task queue.` This tells a builder *what the phrase means* but not *how the code builder's task queue works*. There's no mention of how tasks are created, queued, or identified. The build spec's `builder.js` interface doesn't reference a task queue. The design spec introduces "task queue" as a concept but the build spec never specifies it.

**Proposed content:** Add to the Build Spec under the Code Plugin section or the Plugin Interface Contract:

> **Code Builder Task Queue:** The code builder maintains an ordered list of build tasks derived from `spec.md` (e.g., implement feature X, write tests for Y). Each task has a string identifier used for stuck detection ΓÇö consecutive agent invocations against the same task identifier increment the retry counter. The task list format and derivation logic are internal to the code builder and are not persisted to state files. On crash recovery, the code builder re-derives the task list from `spec.md` and the current project file state.

---

**[Major] No specification of how the Phase 3 code builder drives the build process**

The Plan builder has a clear interaction model: template-driven, section-by-section, `PlanBuilderResponse` schema with stuck signal. The Code builder has: "Codes the project using configured agent via Vibe Kanban (when enabled) or direct agent invocation (when disabled)." This tells a builder *what tools are used* but not *how the build is orchestrated*. Specifically:

- How does the code builder decide what to build in what order?
- Does it make one large agent call ("build this whole project") or multiple targeted calls?
- How does it track progress through the build?
- What is the equivalent of the plan builder's "section-by-section" interaction model?

The plan builder gets 5 paragraphs of interaction model detail. The code builder gets one sentence.

**Proposed content:** Add to Design Spec Phase 3 Code Mode, after step 1:

> **Code builder interaction model:** The code builder passes the full `spec.md` (architecture, dependencies, acceptance criteria) to the coding agent as a single build prompt. The agent is responsible for scaffolding, implementation, and initial test writing in a single invocation or multi-turn session (depending on VK task execution behavior). The code builder then enters a test-fix cycle: run tests, pass failures back to the agent, agent fixes, re-run tests ΓÇö repeating until all tests pass or stuck detection triggers. This is a coarser-grained interaction model than the plan builder's section-by-section approach, reflecting that coding agents (Claude Code, Codex) operate best with full project context rather than isolated function-level prompts.

---

**[Minor] No test coverage for WebSocket reconnection behavior**

The testing strategy in Build Stage 8 includes unit tests for the chat interface (Task 58a) covering "WebSocket message delivery, AI response streaming, phase-labeled messages, project thread switching." But the design spec specifies reconnection behavior (auto-reconnect, state sync from `status.json` and `chat_history.json`, in-flight response handling, connection status indicator) that is architecturally significant and not covered by Task 58a's description.

**Proposed content:** Add a test task:

> | 58f | Unit tests: WebSocket reconnection (auto-reconnect on disconnect, state sync from `status.json` and `chat_history.json` on reconnect, connection status indicator shown during disconnect, in-flight responses not replayed, server handles invalid project ID on reconnect) | ΓÇö | Task 7i | ΓÇö | Not Started |

---

**[Minor] No test coverage for concurrency limit enforcement**

Task 2b implements concurrency limits but no unit test task covers it.

**Proposed content:** Add:

> | 58g | Unit tests: concurrency limit enforcement (block new project at max, count halted as active, re-enable on terminal state, sidebar message displayed) | ΓÇö | Task 2b | ΓÇö | Not Started |

---

**[Minor] No test coverage for server restart recovery**

Task 1c implements restart recovery (scan projects, halt autonomous states, resume interactive states) but no test task covers it.

**Proposed content:** Add:

> | 58h | Unit tests: server restart recovery (interactive states resume, autonomous states halted with `server_restart` reason, notifications sent for halted projects, terminal states ignored) | ΓÇö | Task 1c | ΓÇö | Not Started |

---

**[Minor] No test coverage for button debounce and duplicate request detection**

Task 10 explicitly implements "button debounce: disable on press until operation completes, server-side duplicate request detection." Task 58b covers button state but its description says "button state disabled during processing" ΓÇö which is the client side only. Server-side duplicate detection is not mentioned.

**Proposed content:** Amend Task 58b description:

> | 58b | Unit tests: action buttons (Distill triggers distillation, Confirm advances phase, button state disabled during processing, server-side duplicate request ignored and returns current state, Phase 4 halt recovery buttons, Phase 3 stuck recovery buttons) | ΓÇö | Task 10, Task 40a, Task 6c | ΓÇö | Not Started |

---

**[Minor] Execution Plan Risk Register is thin compared to the Design Spec's Risks & Mitigations table**

The Design Spec lists 5 risks. The Execution Plan's Risk Register lists 4, and they're mostly the same. But the Execution Plan should carry *execution-specific* risks that the design spec doesn't cover: dependency availability (what if Vibe Kanban isn't ready, what if an agent CLI changes mid-build), integration complexity, and schedule risk from the cross-stage dependency chain.

**Proposed content:** Add to Risk Register:

> | Agent CLI changes mid-build (flag deprecation, output format change) | Low | High | Agent adapters isolate changes. Pin agent CLI versions during build. Run adapter unit tests on each agent update. |
> | Cross-stage dependency chain delays (Stage 7 ΓåÆ Stage 2 ΓåÆ Stage 4) | Medium | Medium | Begin Build Stage 7 (agent layer) immediately after Task 1. Track critical path separately from stage numbering. |

---

## 3. Build Spec Material That Should Be Extracted

**[Minor] Design Spec ΓÇö Realign Algorithm (Phase 1, step 9) contains implementation-level algorithmic detail**

Phase 1 step 9 describes: "The AI scans backwards through chat history past any sequential 'realign from here' commands to find the most recent human correction message. It discards all AI and human messages after that point from the working context (retaining them in `chat_history.json` for audit), and re-distills from the original brain dump plus all corrections up to that baseline."

This is the algorithm implementation, not the *behavior*. The build spec already has a "Realign Algorithm" section (lines 386ΓÇô393) that duplicates this content. The design spec should describe the *what*: "Human can reset the conversation to a previous correction point. The AI re-distills from the brain dump plus corrections up to that point." The *how* (scan backwards, sequential command skipping, context truncation) belongs in the build spec only.

**Replacement text for Design Spec Phase 1 step 9:**

> 9. Human can type "realign from here" in chat. The AI resets to the most recent substantive correction, discarding subsequent conversation, and re-distills from the original brain dump plus all corrections up to that point. If no corrections exist yet, the command is ignored with a prompt to provide a correction first. Implementation algorithm in build spec.

---

**[Minor] Design Spec ΓÇö Operation Taxonomy paragraph contains build-spec-level enumeration**

The paragraph under Plan Mode Safety Guardrails: "The orchestrator classifies every Phase 3/4 action into an operation type before invoking the plugin's `validate()`. Operation types include: `shell_exec` (any subprocess or CLI command), `file_create` (creating a new file ΓÇö subdivided by extension/location), `file_modify` (modifying an existing file), `package_install` (dependency installation), and `agent_invoke` (invoking a coding agent)."

The operation type enumeration with parenthetical definitions is implementation detail. The design spec already says "The complete operation type list and the mapping from orchestrator actions to operation types are defined in the build spec" ΓÇö so the list in the design spec is redundant and risks going out of sync.

**Replacement text:**

> **Operation Taxonomy:** The orchestrator classifies every Phase 3/4 action into an operation type before invoking the plugin's `validate()`. The complete operation type list and the mapping from orchestrator actions to operation types are defined in the build spec.

---

**[Minor] Design Spec ΓÇö Stagnation guard's issue matching algorithm is implementation detail**

The Stagnation guard description says: "fewer than 70% of current issues match prior iteration issues by description similarity." This is plan-level behavior. But the inline detail in the build spec's convergence guard parameters includes: "Levenshtein similarity ΓëÑ 0.8 on the `description` field." That's the right place for it. The design spec should not repeat the algorithm ΓÇö and currently it doesn't inline the Levenshtein detail, but it does say "Algorithmic parameters (similarity threshold, window sizes) defined in build spec" which correctly defers. No change needed here ΓÇö this is already handled correctly. *(Self-correction: withdrawing this finding.)*

---

That's the full review. Three lists, each finding tagged with severity and sorted Critical ΓåÆ Major ΓåÆ Minor within each list. Replacement text or proposed content provided for every finding.
