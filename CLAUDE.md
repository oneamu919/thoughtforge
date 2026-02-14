Read this first. It tells you what exists, what's done, and what's not.

## MANDATORY: Session Handoff

**Before your session ends, you MUST update this file.** This is how the next AI coder knows where you left off. If you don't update it, the next coder wastes time re-auditing the entire project.

Update these sections before closing out:
1. **Current Status** — mark what you completed, what's still not done
2. **Last Session** — replace the entry below with what you did
3. If you created new files or modules, add them to the **Module Map** or **Key Paths**
4. If you learned a gotcha, add it to `docs/lessons-learned.md` (next lesson number in sequence)
5. Commit this file with your other changes. Do not leave it uncommitted.
6. **Push after each commit.** It's OK to push frequently — the human can always roll back with `git revert` or `git reset`. If you made a mistake, fix it and push the fix. Never leave commits unpushed without the human knowing. Before closing out, confirm everything is pushed.

### Last Session
- **Date:**
- **What was done:**
- **What's next:**

## What This Is

## Current Status

## Key Paths

## Ports

## Git Sync Protocol

"git sync" means ALL of these steps, in order. Do NOT skip any.

1. `git status -u` — check for ALL local changes including untracked files in all subdirectories
2. `git diff --stat` — confirm what files are modified across the entire repo
3. If there are local changes: `git add` → `git commit` → `git push`
4. `git pull` — pull remote changes AFTER pushing local ones

### Rules

- NEVER report "in sync" after only running `git pull`. That checks ONE direction. Sync is TWO directions.
- NEVER skip the status/diff check. Local agents modify files constantly. Assume local changes exist until proven otherwise.
- NEVER use bare `git status` without `-u`. You WILL miss untracked files in subdirectories.
- If you only run `git pull` and say "all synced", you are WRONG. You checked nothing.

### Why This Matters

This project uses automated agents that modify local files. The human does not always know what changed locally. If you don't check status and push, those changes are lost or out of sync with remote. This has caused repeated problems. Do not be the next one to cause it again.

## Rules

2. Never modify files in -working dir- without asking first.
5. Read `docs/lessons-learned.md` before writing PowerShell or doing SSH operations.

## Module Map

