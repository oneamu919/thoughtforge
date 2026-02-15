# Apply Review Findings

Read `docs/results.md` for context. Apply every change listed below to the source files. Each change is taken directly from the review findings. Do not interpret or improvise — apply exactly what is specified.

Read all three source files before making any changes:
- `docs/thoughtforge-design-specification.md`
- `docs/thoughtforge-build-spec.md`
- `docs/thoughtforge-execution-plan.md`

---

## Section 1: Writing That's Unclear (6 Minor changes)

### 1A. Build spec — Guard Evaluation Order

**File:** `docs/thoughtforge-build-spec.md`
**Location:** Guard Evaluation Order section, after the introductory paragraph
**Action:** Replace the existing ordered guard list with the following (inserting Fix Regression as guard 0):

> Guards are evaluated in the following order after each iteration. The first guard that triggers ends evaluation — subsequent guards are not checked.
>
> 0. **Fix Regression** (per-iteration) — checked first, immediately after each fix step. If total error count increased compared to the review that prompted the fix, log a warning. If 2 consecutive iterations show fix-step regression, halt and notify. This guard runs before the convergence guards below.
> 1. **Termination** (success) — checked first among convergence guards so that a successful outcome is never overridden by a halt
> 2. **Hallucination** — [keep existing text unchanged]
> 3. **Fabrication** — [keep existing text unchanged]
> 4. **Stagnation** — [keep existing text unchanged]
> 5. **Max Iterations** — [keep existing text unchanged]

Also find the completion checklist entry that says "All 5 convergence guards" and change it to "All 6 convergence guards (including Fix Regression per-iteration check)".

---

### 1B. Design spec — Phase 2 steps 2–3 clarity

**File:** `docs/thoughtforge-design-specification.md`
**Location:** Phase 2, steps 2 and 3 (where AI evaluates intent.md)
**Action:** Replace steps 2 and 3 with:

> 2. **Challenge:** AI evaluates `intent.md` for structural issues: missing dependencies, unrealistic constraints, scope gaps, internal contradictions, and ambiguous priorities. Each flagged issue is presented to the human with specific reasoning. The AI does not rubber-stamp — it must surface concerns even if the human's intent seems clear. This step does not resolve Unknowns — it identifies new problems.
> 3. **Resolve:** AI resolves Unknowns and Open Questions from `intent.md` — either by making a reasoned decision (stated in `spec.md`) or by asking the human during the Phase 2 chat.

Keep the rest of step 3 unchanged after the replaced opening sentence.

---

### 1C. Design spec — Stagnation guard precision

**File:** `docs/thoughtforge-design-specification.md`
**Location:** Convergence Guards table, Stagnation guard row
**Action:** Replace the stagnation guard description with:

> Same total error count for a configured number of consecutive iterations (stagnation limit), AND issue rotation detected (fewer than 70% of current issues match prior iteration issues by Levenshtein similarity ≥ 0.8 on description). When both conditions are true, the deliverable has reached a quality plateau. Parameters in build spec.

---

### 1D. Build spec — Code Builder Task Queue persistence contradiction

**File:** `docs/thoughtforge-build-spec.md`
**Location:** Code Builder Task Queue section — the two contradictory paragraphs about persistence
**Action:** Replace both paragraphs with this single merged paragraph:

> The code builder maintains an ordered list of build tasks derived from `spec.md`. Each task has a string identifier used for stuck detection. On crash recovery, the code builder attempts to re-derive the task list from `spec.md` and the current state of files in the project directory. If the re-derived task list differs from the pre-crash list (non-deterministic ordering), the code builder persists the initial task list to `task_queue.json` in the project directory at derivation time, and uses the persisted list for crash recovery. Whether to persist is a Task 21 implementation decision — but crash recovery must produce a compatible task ordering.

---

### 1E. Design spec — Phase 3 completeness wording

**File:** `docs/thoughtforge-design-specification.md`
**Location:** Phase 3→4 Transition Error Handling
**Action:** Find text that says outputs "meet `config.yaml` `phase3_completeness` thresholds" and change "thresholds" to "criteria":

> verify expected output files exist and meet `config.yaml` `phase3_completeness` criteria before entering Phase 4

---

### 1F. Execution plan — Critical Path correction

**File:** `docs/thoughtforge-execution-plan.md`
**Location:** Critical Path section
**Action:** Replace the critical path chain with:

> **Task 1 → Task 41 → Task 42 → Task 6a → Task 8 → Task 9 → Task 11 → Task 12 → Task 13 → Task 6c → Task 30 → Tasks 33–37 → Task 51**
>
> Note: Task 15 (plan builder) is not on the critical path — it runs in parallel with the Phase 1–2 human interaction chain and must complete before Task 51 (e2e test), but it does not gate Task 30. Task 30 depends on Task 6c (Phase 3→4 transition), which depends on Tasks 5, 6a, and 7. Task 6c is the critical dependency entering the polish loop.

---

## Section 2: Genuinely Missing Plan-Level Content (3 Major + 4 Minor)

### 2A. [MAJOR] Build spec — Add Initial Dependencies section

**File:** `docs/thoughtforge-build-spec.md`
**Location:** After the "Build Toolchain" section
**Action:** Add this new section:

> ## Initial Dependencies
>
> **Used by:** Task 1 (project initialization)
>
> ```json
> {
>   "dependencies": {
>     "express": "^4.x",
>     "ws": "^8.x",
>     "zod": "^3.x",
>     "handlebars": "^4.x",
>     "yaml": "^2.x",
>     "pdf-parse": "^1.x"
>   },
>   "devDependencies": {
>     "typescript": "^5.x",
>     "vitest": "^1.x"
>   }
> }
> ```
>
> Use `package-lock.json` for deterministic installs. Pin major versions. Run `npm audit` before v1 release.

---

### 2B. [MAJOR] Config.yaml + Design spec — Context window awareness

**File 1:** `docs/thoughtforge-build-spec.md` (or whichever file contains the `config.yaml` template), under `agents.available`
**Action:** Update each agent entry to include `context_window_tokens`:

```yaml
    claude:
      command: "claude"
      flags: "--print"
      supports_vision: true
      context_window_tokens: 200000
    gemini:
      command: "gemini"
      flags: ""
      supports_vision: true
      context_window_tokens: 1000000
    codex:
      command: "codex"
      flags: ""
      supports_vision: false
      context_window_tokens: 200000
```

**File 2:** `docs/thoughtforge-design-specification.md`, in the Agent Communication section
**Action:** Add this paragraph:

> **Context window awareness:** Each agent's context window size is configured in `config.yaml` `agents.available.{agent}.context_window_tokens`. ThoughtForge uses this value to determine when to truncate chat history, plan builder context, and code review context. The token count is an approximation — ThoughtForge estimates tokens as `character_count / 4` (a standard rough heuristic). Exact tokenization is agent-specific and not worth the complexity for truncation decisions.

---

### 2C. [MAJOR] Design spec — Graceful Shutdown for concurrent projects

**File:** `docs/thoughtforge-design-specification.md`
**Location:** Graceful Shutdown paragraph
**Action:** Replace the existing Graceful Shutdown paragraph with:

> **Graceful Shutdown:** On `SIGTERM` or `SIGINT`, the server stops accepting new operations and waits for all in-progress agent subprocesses to complete (up to the configured `agents.call_timeout_seconds`). Each project's subprocess is handled independently: if a subprocess completes within the timeout, its iteration state is written normally. If the timeout expires for any subprocess, that subprocess is killed and its current iteration is abandoned (no state written). After all subprocesses have either completed or been killed, the server exits. On next startup, the standard Server Restart Behavior applies to each project independently.

---

### 2D. [Minor] Build spec — Add HTTP API Surface table

**File:** `docs/thoughtforge-build-spec.md`
**Location:** After the "WebSocket Reconnection Parameters" section
**Action:** Add this new section:

> ## HTTP API Surface
>
> **Used by:** Tasks 1a, 7, 7b, 7g, 7h (server, chat interface, settings, sidebar, file upload)
>
> | Method | Path | Purpose |
> |---|---|---|
> | GET | `/` | Serve chat interface HTML |
> | GET | `/api/projects` | List all projects with current status |
> | POST | `/api/projects` | Create new project |
> | GET | `/api/projects/:id/status` | Get project `status.json` |
> | GET | `/api/projects/:id/chat` | Get project `chat_history.json` |
> | POST | `/api/projects/:id/action` | Trigger button action (distill, confirm, resume, override, terminate, provide-input) |
> | POST | `/api/projects/:id/upload` | Upload resource file to `/resources/` |
> | GET | `/api/prompts` | List prompt files |
> | GET | `/api/prompts/:filename` | Read prompt file content |
> | PUT | `/api/prompts/:filename` | Save prompt file content |
> | WS | `/ws` | WebSocket for real-time chat streaming |
>
> Route structure is a build-time implementation detail — the above is guidance, not a rigid contract. The key requirement is that all project mutations go through the orchestrator (never direct file writes from HTTP handlers).

---

### 2E. [Minor] Design spec — CORS / static serving note

**File:** `docs/thoughtforge-design-specification.md`
**Location:** Under the "Chat UI (Frontend)" section
**Action:** Add this line:

> Static assets (HTML, CSS, JS) are served directly by Express from a `/public/` directory. No CORS configuration is needed — the browser loads assets from the same origin as the WebSocket connection.

---

### 2F. [Minor] Build spec — Remove discovery.js from plan plugin folder structure

**File:** `docs/thoughtforge-build-spec.md`
**Location:** Plan plugin folder structure listing
**Action:** Remove `discovery.js` from the listing. Updated listing:

> ```
> /plugins/
>   plan/
>     builder.js
>     reviewer.js
>     safety-rules.js
>     templates/
>       generic.hbs
>       wedding.hbs
>       strategy.hbs
>       engineering.hbs
> ```

---

### 2G. [Minor] Build spec — Add fix_regression to halt_reason values

**File:** `docs/thoughtforge-build-spec.md`
**Location:** `status.json` schema, `halt_reason` field known values list
**Action:** Add `"fix_regression"` to the known values list (triggered by the Fix Regression per-iteration guard when 2 consecutive fix steps increase error count).

---

## Section 3: Build Spec Material That Should Be Extracted (2 Minor)

### 3A. Design spec — Extract brain dump intake prompt text

**File:** `docs/thoughtforge-design-specification.md`
**Location:** Phase 1 section, where the full brain dump intake system prompt is embedded
**Action:** Replace the embedded prompt block with:

> Full prompt text is specified in the build spec under "Phase 1 System Prompt — Brain Dump Intake."

Keep the behavioral requirements paragraph ("Brain Dump Intake Prompt Behavior") that describes the 6-section structure, no AI suggestions, max 5 questions — that stays in the design spec.

---

### 3B. Design spec — Action Button Behavior source-of-truth note

**File:** `docs/thoughtforge-design-specification.md`
**Location:** Wherever inline button descriptions specify `status.json` field values (e.g., `halt_reason: "human_terminated"`)
**Action:** No extraction needed — the build spec already has the authoritative table. But where inline design spec descriptions state `status.json` field-level effects, add a note:

> (Authoritative field values are in the build spec Action Button Behavior table.)

This is a light annotation, not a full rewrite. Apply it to any inline description that specifies a `status.json` field value.

---

## After All Changes Are Applied

1. Re-read each modified file to verify no formatting was broken and all changes were applied correctly.
2. `git status -u` — verify all modified files.
3. `git diff --stat` — confirm changes.
4. Git add only the files you modified.
5. Commit with message: `Apply review findings`
6. Push to remote: `git push`
7. `git pull` — confirm sync with remote. Do not leave commits unpushed.
