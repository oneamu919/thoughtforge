**OPA Framework Template**

*Outcome • Purpose • Action*

Based on Tony Robbins’ OPA System (formerly RPM — Rapid Planning Method)

# **What is OPA?**

OPA is a results-focused, purpose-driven planning and documentation framework originally developed by Tony Robbins. In its original context, OPA is a system of thinking — not a time-management technique — that trains you to start with the end in mind by asking three questions in sequence: *What do I want? Why do I want it? What do I need to do?*

This template adapts Robbins’ OPA for technical documentation, ensuring every procedure or tool document answers those three fundamental questions clearly at the outset. This structure enables both human operators and AI agents to quickly understand what a document covers and whether it applies to their current situation.

| Component | Robbins’ Original | Applied to Documentation |
| :---- | :---- | :---- |
| **Outcome** | What do I actually want? The specific, measurable result I can envision and verify. | What end state will exist after successful execution? The measurable result. |
| **Purpose** | Why does this matter? The emotional and strategic driver that sustains momentum. | Why does this document matter? Who benefits and in what context? |
| **Action** | What specific steps will I take? Prioritized against the outcome, not just a to-do list. | What specific operations or steps does this document cover? |

**Source:** *Tony Robbins’ OPA System / RPM (Rapid Planning Method). For the full system, see tonyrobbins.com/rpm-system.*

# **When to Use OPA**

Apply OPA framing to documents that will be consumed by AI agents or used as reference material for repeatable processes.

## **Good Candidates**

* DevOps runbooks and toolkits

* Automation script documentation

* Standard operating procedures (SOPs)

* Troubleshooting guides

* API or integration documentation

## **Not Necessary For**

* Meeting notes or informal logs

* Creative or exploratory documents

* One-time communications

# **Blank Template**

Copy the structure below as your starting point. Fill in each section before writing procedural content.

| \[Document Title\] OPA Framework Outcome *\[State the measurable end state. What result will exist after successful execution? Be specific enough that success can be verified. Example: “All production servers running v2.0 with zero data loss.”\]* Purpose *\[Explain the why. Who uses this and under what circumstances? What’s the driving reason this outcome matters? Example: “Enables AI agents to autonomously perform upgrades. Human operators use for manual intervention during critical incidents.”\]* Action Scope *\[List the specific operations covered. Start each with a verb. These are the prioritized actions that serve the outcome — not just a task list. Example: “Backup data, swap containers, restore data, verify integrity.”\]* ——— *\[Procedural content follows: Prerequisites, Steps, Scripts, Reference Tables, etc.\]* |
| :---- |

# **Guidance Notes**

## **Writing the Outcome**

In Robbins’ system, the outcome is the answer to “What do I actually want?” — not a vague goal, but a clear, envisioned result. Apply the same standard to documentation:

* Be specific and measurable — an agent or operator should be able to verify success against this statement

* Focus on the end state, not the process of getting there

* Write it so clearly that someone can read it and immediately know whether the outcome has been achieved

* If you can’t measure it, refine it until you can

## **Writing the Purpose**

Robbins emphasizes that purpose is the fuel — the emotional and strategic “why” that sustains momentum when execution gets difficult. In documentation, purpose serves a similar role: it helps operators and agents decide if this document is relevant to them right now.

* Identify the audience (AI agent, human operator, or both)

* Describe triggering conditions — when should this document be used?

* Explain the value delivered — why does achieving this outcome matter to the organization or workflow?

## **Writing the Action Scope**

In Robbins’ framework, action items are prioritized against the outcome — they’re not a random to-do list, but a deliberate set of steps that serve the result. Apply this discipline to your action scope:

* Use bullet points for clarity

* Start each item with a verb

* Prioritize actions by impact on the outcome

* Include edge cases if applicable

* Explicitly state what is NOT covered if boundaries matter

# **Example: Filled Template**

Below is a condensed example showing OPA applied to a database migration toolkit.

| Database Migration Toolkit Outcome Migrate PostgreSQL databases from v12 to v15 with zero downtime and verified data integrity. Purpose Enables DevOps teams and automation pipelines to execute controlled database upgrades. Used during scheduled maintenance windows or triggered by version deprecation alerts. Action Scope Pre-migration health checks, logical backup with pg\_dump, parallel restore to new cluster, streaming replication cutover, post-migration validation, rollback procedures. |
| :---- |

# **Reference**

This framework is adapted from Tony Robbins’ OPA system, which evolved from his Rapid Planning Method (RPM). The core principle: start with the result you want, anchor it to a compelling reason, then build prioritized actions to get there.

For the complete OPA / RPM system, visit:

* tonyrobbins.com/rpm-system — Official RPM system page

* O.P.A. Life Planner: Life Management System — Tony Robbins (book/product)

*Template Version: 2.0  |  Last Updated: February 2026  |  Based on Tony Robbins’ OPA System*