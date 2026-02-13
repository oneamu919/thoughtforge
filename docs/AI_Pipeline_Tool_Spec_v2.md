# ThoughtForge Pipeline Tool
## Design Specification — v2.0

---

## OPA Framework

| | |
|---|---|
| **Outcome** | A personal web-based tool that takes a human brain dump and autonomously produces polished, working code — reducing human touchpoints to 3-4 per project. Multiple projects run in parallel across a visual kanban board with race stats. The polish loop that currently takes ~12 hours of manual work runs unattended to convergence: 0 critical errors, <3 medium, <5 minor. |
| **Purpose** | Eliminates the repetitive manual labor of iterative AI code review. The human focuses only on intent, direction, and final review. Everything between is autonomous. Designed for a solo operator using a Claude flat-rate subscription (Max plan) via Claude Code CLI. If it works well, redesign to ship as a product for others. |
| **Action Scope** | Accept brain dump and resources, distill intent with human correction, discover build constraints through AI self-negotiation, autonomously code and test, run automated polish loop with convergence detection and hallucination guards, notify human when done or stuck. Visualize all projects racing across a kanban board with timing stats. |

> **OPA Framework** adapted from Tony Robbins' RPM system. Every section answers: What result? Why does it matter? What specific steps?

---

## Stack

| Component | Technology | Why |
|---|---|---|
| Runtime | Node.js | Already installed, single runtime for everything |
| Framework | Next.js | Frontend + API routes in one. Future-proofed for product shipping. AI writes it, complexity cost is zero. |
| Kanban UI | React with dnd-kit | Maintained, lightweight. react-beautiful-dnd is abandoned. |
| Real-time updates | Socket.io over Next.js API routes | Live kanban card movement, polish loop progress, phase transitions without page refresh. |
| AI Engine | Claude Code CLI via `child_process.spawn` | Flat-rate Max subscription. No API costs. Use `spawn` not `exec` — handles long stdout streams from 50-iteration polish runs. |
| Project State | File-based: `/projects/{id}/` containing `intent.md`, `spec.md`, `constraints.md`, `polish_log.md`, `polish_state.json`, `status.json` | Simple, human-readable, git-trackable. No database for v1. Wrap all state reads/writes in one module so a DB can be swapped in later if shipped as product. |
| Version Control | Git — each project gets its own repo. Auto-commit after every polish iteration. | Rollback is built in. History is free. Separate repos per project for clean parallel isolation. |
| Notifications | Telegram bot (bot token, direct messages) | Push notification to phone when AI needs human or is done. |
| Config | `config.yaml` at project root | Thresholds, max iterations, concurrency limit. Human-editable. |

**What's NOT in the stack and why:**

- **No Python** — one runtime is cleaner than two. Node handles subprocess spawning, file I/O, and JSON parsing fine.
- **No SQLite or any database** — state is files. Git is the history layer. A database adds complexity with no gain for a solo operator. State access is wrapped in a single module so a DB can be added later.
- **No OpenClaw** — separate tool, separate purpose. Not coupled.
- **No LangGraph, AutoGen, CrewAI, or any agent framework** — the loop is straightforward: spawn CLI, parse JSON, check thresholds, loop or stop. ~100-200 lines of orchestration code. A framework adds abstraction for no benefit.

---

## Phase 1 — Brain Dump & Discovery

| | |
|---|---|
| **Outcome** | A locked `intent.md` document that accurately captures what the human wants — objectives, assumptions, scope, unknowns — validated by human confirmation. |
| **Purpose** | Without confirmed intent, everything downstream is garbage. This phase gets the messy, incomplete idea in the human's head into a structured form that AI can execute against. The human is also learning and refining during this phase. |
| **Action Scope** | Accept brain dump via chat. Read all files in project resource directory. Distill into structured objectives, assumptions, constraints, unknowns. Present to human. Accept corrections. Re-distill. Support "realign from here" resets without going back to zero. Exit when human explicitly confirms intent. |

### Trigger

Human creates a new project card and brain dumps into chat panel. Drops files and resources into the project's `/resources/` directory.

### System Prompt — Brain Dump Intake

```
You are receiving a raw brain dump from a human. It will be messy, incomplete,
and possibly contradictory. That's expected.

Your job is to eat everything they gave you — text, files, resources — and
produce a single structured document with these sections:

1. OBJECTIVE — What does the human want to exist when this is done? State it plainly.
2. ASSUMPTIONS — What does the human seem to believe is true that hasn't been
   verified? Flag anything you're inferring, not just what they stated.
3. CONSTRAINTS — Any limitations they mentioned: OS, language, tools, budget,
   timeline, "only this," "not that."
4. UNKNOWNS — What hasn't been addressed but needs to be decided before building?
   These are the gaps.
5. OPEN QUESTIONS — Things you genuinely don't understand from the brain dump.
   Ask them here. Maximum 5 questions. If you have more than 5, pick the 5
   that block the most progress.

Rules:
- Do not add your own ideas, suggestions, or improvements. Only organize what
  the human gave you.
- If something is ambiguous, put it in UNKNOWNS with a note about what's unclear.
- Keep each section short. Bullet points are fine.
- Do not say "great idea" or "interesting concept." Just organize.
```

### AI Behavior

- Reads all resources in the project directory (text, PDF, images via vision, code files)
- Reads the brain dump
- Distills into the 5-section structured document
- Presents it back to human in chat

### Human Behavior

- Reads the distilled version
- Responds in chat: "approved" / "move forward" / "looks good" → advances to Phase 2
- Or: "item 3 is wrong, it should be XYZ" → AI revises and presents again
- If intent is fundamentally off: says "realign from here" — AI resets to that point, not to zero
- If incorrect assumptions keep reappearing: asks AI why, discovers unclear writing or wrong assumptions, adjusts

### Confirmation

Chat-based. The tool classifies the human's message as either a **correction** (loop back, revise) or a **confirmation** (advance to Phase 2). If the human says "approved," "move forward," "looks good, let's build," or equivalent — it advances. If they say "item X is wrong" or give corrections — it revises and presents again.

### Output

`intent.md` — locked intent document carried through all later phases.

---

## Phase 2 — Spec Building & Constraint Discovery

| | |
|---|---|
| **Outcome** | A locked `spec.md` with all technical decisions finalized, a `constraints.md` defining what the polish loop checks against, and a set of **functional acceptance criteria** that validate the code does what was asked. |
| **Purpose** | Constraints prevent the polish loop from chasing its own tail. Without explicit rules for what counts as critical vs. minor, what's in scope vs. out, and what not to touch, the model invents stylistic preferences and never converges. Functional acceptance criteria prevent the polish loop from producing clean code that's missing features. |
| **Action Scope** | Propose language, OS, framework, tools, dependencies, architecture. Push back like a real engineer with reasoning. Accept human overrides. Generate `constraints.md` and acceptance criteria from the accumulated decisions. |

### Trigger

Human confirms intent (Phase 1 complete).

### AI Behavior (Autonomous)

- Proposes build spec: language, OS, framework, tools, dependencies, architecture
- Pushes back like a real engineer: "Node.js makes more sense here because X" or "Docker isn't needed for this, here's why"
- Discovers constraints through internal proposer/challenger reasoning
- **Extracts 5-10 functional acceptance criteria from `intent.md`** — plain statements like:
  - "User can create a project from the kanban board"
  - "Telegram notification fires when polish loop finishes"
  - "Cards move automatically when phase changes"
  - "Git commits after every polish iteration"
- Presents the build spec, constraints, and acceptance criteria to human

### Human Behavior

- Confirms or overrides specific decisions ("No, Python only." / "Yes, Docker is fine." / "I forgot to mention, Windows only.")
- Reviews acceptance criteria — adds missing ones, removes wrong ones
- One round is usually enough

### Exit Condition

Human confirms build spec.

### Outputs

- `spec.md` — build spec with all technical decisions locked
- `constraints.md` — review constraints with severity definitions, scope boundaries, exclusion rules, AND functional acceptance criteria

### What Goes Into `constraints.md`

| Section | Description |
|---|---|
| Context | What this code does (from `intent.md`) |
| Priorities | What the human cares about (from Phase 1 corrections) |
| Exclusions | What not to touch, what not to flag |
| Severity Definitions | What counts as critical / medium / minor — specific to this project |
| Scope | Which files and functions are targets |
| **Functional Acceptance Criteria** | **5-10 statements of what the code must do — features that must exist and work. The polish loop reviewer validates these alongside code quality.** |

---

## Phase 3 — Build

| | |
|---|---|
| **Outcome** | Working code that runs end-to-end. Rough, unpolished, but functional. |
| **Purpose** | You can't polish what doesn't work. This phase gets the code to a state where automated review is meaningful — not perfect, just operational. |
| **Action Scope** | Code the project using Claude Code CLI. Run and test. Fix errors. Iterate until functional. Ping human only when stuck on ambiguity not covered by spec. |

### Trigger

Build spec confirmed (Phase 2 complete).

### AI Behavior (Autonomous)

- Codes the project using Claude Code CLI
- Runs it, tests it, fixes errors
- Iterates until the code works end-to-end
- If stuck or hitting an ambiguity not covered by spec: pings human via Telegram and waits

### Human Behavior

- Only intervenes if pinged
- Answers specific questions, unblocks

### Exit Condition

Code runs and passes basic functional checks.

### Output

Working but unpolished codebase.

---

## Phase 4 — Polish Loop (Fully Automated)

| | |
|---|---|
| **Outcome** | Polished codebase with 0 critical errors, <3 medium errors, <5 minor errors. Convergence log showing the full error trajectory. |
| **Purpose** | This is the 12-hour manual grind being automated. The intent is locked, the spec is locked, the constraints are defined, the code works. Now it's purely mechanical: find flaws, fix flaws, check counts, repeat until clean. No human judgment needed. |
| **Action Scope** | Run review call (output JSON error report only). Run fix call (apply all fixes). Check termination thresholds. Detect hallucination, scope drift, and stagnation. Enforce max iteration ceiling. Log every iteration. Ping human when done or when guards trigger. |

### Trigger

Code is working (Phase 3 complete).

### Each Iteration — Two Steps

**Step 1 — Review (do not fix):**

"Here is the scoped code and `constraints.md` (including functional acceptance criteria). Output ONLY a JSON report. Do not fix anything."

```json
{
  "critical": 2,
  "medium": 5,
  "minor": 8,
  "issues": [
    {
      "severity": "critical",
      "description": "SQL injection in user input handler",
      "location": "src/api/users.py:42",
      "recommendation": "Use parameterized queries"
    },
    {
      "severity": "critical",
      "description": "Missing feature: Telegram notification not wired up",
      "location": "N/A",
      "recommendation": "Implement Telegram bot integration per acceptance criteria #4"
    }
  ]
}
```

**Step 2 — Fix (apply recommendations):**

The orchestrator passes the JSON issue list and recommendations to the fixer agent, which applies them to the scoped code.

### Convergence Guards

| Guard | Condition | Action |
|---|---|---|
| **Termination (success)** | `critical == 0` AND `medium < 3` AND `minor < 5` | Done. Ping human via Telegram. |
| **Hallucination** | Error count spikes after a downward trend | Stop. Flag it. Ping human. |
| **Scope drift** | Issues reference code outside target files/scope in `constraints.md` | Stop. Flag it. Ping human. |
| **Stagnation** | Same error count for 3+ consecutive iterations, no meaningful change | Stop. Flag it. Ping human. |
| **Fabrication** | Model starts inventing issues outside the target code or flagging non-issues just to report something | Stop. Flag it. Ping human. |
| **Max iterations** | Hard ceiling reached (configurable, default 50) | Stop. Ping human with current state. |

### Loop State Persistence

After each iteration, write to `polish_state.json`:

- Current iteration number
- Error counts (critical, medium, minor)
- Convergence trajectory (array of past counts)
- Timestamp

If the Node process crashes mid-loop, it reads `polish_state.json` on restart and resumes from the last completed iteration instead of starting over. Git history preserves the codebase state at each iteration.

### Orchestrator Logic

```
for each iteration (max from config):
    run Review call → parse JSON
    log iteration number, error counts, timestamp to polish_state.json

    if critical == 0 AND medium < 3 AND minor < 5 → DONE
    if error count spiked after downward trend → HALT (hallucination)
    if same counts for 3+ iterations → HALT (stagnation)
    if issues reference out-of-scope code → HALT (scope drift)

    git commit snapshot
    run Fix call → write updated files
    git commit snapshot
```

### Structured Output Validation

The review call must return valid JSON. The orchestrator:

- Validates the JSON parses correctly
- Validates the schema has the required fields (`critical`, `medium`, `minor`, `issues`)
- On malformed output: retries the review call (max 2 retries)
- On repeated failure: halts and pings human

### Output

- Polished codebase
- `polish_log.md` — iteration-by-iteration error counts, convergence trajectory, total iterations, duration

---

## UI

### Two Panels

**Left: Chat Panel**

- Per-project chat thread
- Used for brain dump, corrections, confirmations, and AI pings
- Supports file/resource dropping (or references a project resource directory)
- AI messages labeled by phase (distilling, reviewing, building, polishing)
- Chat-based confirmation: human says "approved" to advance, or gives corrections to loop

**Right: Kanban Board**

- Columns: **Brain Dump → Distilling → Human Review → Confirmed → Spec Building → Coding → Polishing → Done**
- Each card = one project or objective
- Cards move automatically as pipeline progresses
- Cards pause and visually indicate when human input is needed
- Clicking a card opens its chat thread in the left panel

### Per-Card Stats

- Created timestamp
- Time spent in each phase
- Total duration
- Polish loop: iteration count, error counts per iteration, convergence chart (critical/medium/minor over time)
- Status: running / waiting on human / done / stuck
- Model used (for comparing performance across different AI models on same task)

### Dashboard View

- All active cards with progress indicators
- Historical stats across completed projects
- Model performance comparison: same task run with different models shows iteration count, time, and convergence speed differences
- Helps decide if a project was worthwhile and which model performs best for which type of work

---

## Configuration

```yaml
# Polish loop thresholds
polish:
  critical_max: 0
  medium_max: 3
  minor_max: 5
  max_iterations: 50
  stagnation_limit: 3
  retry_malformed_output: 2

# Parallel execution
concurrency:
  max_parallel_runs: 3

# Notifications
notifications:
  telegram_bot_token: ""
  telegram_chat_id: ""

# Claude Code CLI
claude:
  command: "claude"
  flags: "--print"
```

---

## Human Touchpoints Summary

| Touchpoint | Phase | What Human Does |
|---|---|---|
| 1 | Brain Dump | Dumps idea + drops resources |
| 2 | Review | Corrects AI's distilled understanding (1-3 rounds via chat) |
| 3 | Confirm | Confirms intent is right, optionally overrides spec decisions and acceptance criteria |
| 4 | Final Review | Reviews finished polished output |

Everything between touchpoints 3 and 4 is fully autonomous.

---

## Key Design Decisions Log

These decisions were made across three design conversations and one audit review:

1. **File-based state over database** — for v1 solo operator. State access wrapped in a single module for future DB swap.
2. **Each parallel project gets its own git repo** — clean isolation, no shared mutable state.
3. **Chat-based confirmation over button UI** — "approved" or "item 3 is wrong" parsed by AI. Natural, no extra UI components.
4. **Functional acceptance criteria added to `constraints.md`** — prevents polish loop from producing clean code that's missing features. Reviewer checks both code quality AND "does this feature exist."
5. **Structured output validation with retry** — JSON from review call is validated and retried on failure, not blindly trusted.
6. **Polish state persistence** — `polish_state.json` written after each iteration so the loop can resume after a crash.
7. **No agent frameworks** — the orchestration logic is ~100-200 lines. Frameworks add abstraction with no benefit.
8. **Phase 1 distillation prompt specified** — structured intake (objectives, assumptions, constraints, unknowns, open questions) reduces human correction rounds from 5 to 1-2.

---

*Document Version: 2.0 | February 2026 | OPA Framework (Tony Robbins' RPM System)*
