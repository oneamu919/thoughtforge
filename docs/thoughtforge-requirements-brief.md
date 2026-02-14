# ThoughtForge Pipeline Tool — Requirements Brief

> **Framework:** OPA (Outcome • Purpose • Action)

---

## Outcome

A personal tool that takes a human brain dump and autonomously produces a polished deliverable — either a **plan** (wedding, event, engineering design, business strategy, etc.) or **working code**. Reduces human touchpoints to 3-4 per project. Multiple projects run in parallel via Vibe Kanban with per-project timing and agent performance stats. The polish loop that currently takes ~12 hours of manual work runs unattended to convergence: 0 critical errors, ≤3 medium, ≤5 minor.

---

## Purpose

Eliminates the repetitive manual labor of iterative AI review — for any type of project, not just code. The human focuses only on intent, direction, and final review. Everything between is autonomous. Designed for a solo operator using flat-rate AI subscriptions via multiple coding agents (Claude Code CLI, Gemini CLI, Codex CLI). If it works well, redesign to ship as a product for others.

**Audience:** Solo operator (the builder) — human-in-the-loop at intent and final review only.

**Trigger:** Any time the operator has an idea (plan or code) that needs to go from messy brain dump to polished deliverable.

**Value:** Reclaims ~12 hours of manual polish grind per project. Enables parallel execution of multiple projects with minimal human attention.

---

## Action Scope

- Accept brain dump and resources
- Pull resources from configured external sources (Notion pages, Google Drive documents) into the project's `/resources/` directory
- Distill intent with human correction
- Discover constraints through AI self-negotiation
- Autonomously build the deliverable (plan or code)
- Run automated polish loop with convergence detection and hallucination guards
- Notify human when done or stuck
- Vibe Kanban handles task visualization, parallel execution, and agent orchestration
- ThoughtForge handles the intelligence: brain dump intake, plan mode, constraint discovery, polish loop logic, and convergence guards

**Out of Scope:**
- Custom kanban UI (Vibe Kanban provides this)
- Database layer (file-based state, DB swappable later)
- Agent frameworks (no LangGraph/AutoGen/CrewAI)
- MCP implementation (architecture-ready only, not a current build dependency)

---

## Project Types

| Type | Deliverable | Polish Loop Reviews For | Examples |
|---|---|---|---|
| **Plan** | A polished document — complete, detailed, actionable. | Completeness, logical gaps, missing details, contradictions, feasibility issues, unclear responsibilities, missing timelines/budgets. | Wedding plan, event logistics, engineering design, business strategy, product roadmap, marketing campaign. |
| **Code** | A working, polished codebase. | Code quality (best practices, security, error handling) + functional acceptance criteria (features exist and work). | Web apps, CLI tools, APIs, scripts, automation. |

### Pipeline Chaining: Plan → Code

A plan and its code implementation are **two separate pipeline runs**, not one. The plan must be fully complete, polished, and human-approved before it becomes input for a code pipeline. The tool does NOT auto-chain them — the human decides when a plan is ready and manually kicks off the code pipeline with the finished plan as input.

A plan can spawn multiple code pipelines (e.g., a product roadmap spawns separate pipelines for frontend, backend, and infrastructure). Or a plan can stay a plan forever (e.g., a wedding plan).

---

## Human Touchpoints

| Touchpoint | Phase | What Human Does |
|---|---|---|
| 1 | Brain Dump | Dumps idea + drops resources |
| 2 | Review | Corrects AI's distilled understanding (1-3 rounds via chat) |
| 3 | Confirm | Confirms intent is right, optionally overrides spec decisions and acceptance criteria |
| 4 | Final Review | Reviews finished polished output |

Everything between touchpoints 3 and 4 is fully autonomous.

---

## Success Criteria

| Criteria | Metric | Target |
|----------|--------|--------|
| Human touchpoints per project | Count of required human interactions | 3-4 max |
| Polish loop convergence | Error counts after autonomous run | 0 critical, ≤3 medium, ≤5 minor (thresholds inclusive — matches config.yaml convergence settings) |
| Manual labor replaced | Hours of iterative review saved | ~12 hours per project |
| Parallel execution | Concurrent projects running | Up to 3 (configurable via `config.yaml` `concurrency.max_parallel_runs`) |
| Plan mode safety | Code execution during plan mode | Zero — hard blocked |

---

## Constraints

- **Runtime:** Node.js only (already installed via OpenClaw, single runtime)
- **AI Agents:** Claude Code CLI, Gemini CLI, Codex CLI — flat-rate subscriptions
- **Execution layer:** Vibe Kanban (free, open source, YC-backed) — not custom-built
- **State management:** File-based (`.md`, `.json`), git-trackable, DB-swappable later
- **Notifications:** ntfy.sh default with abstraction layer for future channels
- **Plan deliverables:** Must follow OPA Framework structure
- **No agent frameworks** — orchestration logic is straightforward, no LangGraph/AutoGen/CrewAI
- **MCP-ready architecture** — design-time decision, not v1 build dependency

---

## Stakeholders

| Role | Name / Team | Responsibility |
|------|-------------|----------------|
| Owner | Solo operator | All decisions, final review authority |
| Builder | AI agents (Claude Code, Gemini, Codex) | Execute build and polish under ThoughtForge orchestration |
| Execution Layer | Vibe Kanban | Task visualization, parallel execution, agent spawning |

---

*Based on Tony Robbins' OPA System (Outcome • Purpose • Action). See [tonyrobbins.com/rpm-system](https://tonyrobbins.com/rpm-system)*

*Template Version: 1.0 | Last Updated: February 2026*
