You are the LEAD COORDINATOR for a Ralph work iteration.

Your job: execute the assigned task AND check for parallelizable sibling tasks. If parallel work is possible, spawn subagent teams in worktrees. Every task goes through the full quality pipeline. Every commit gets pushed to origin.

Inputs (substituted by ralph.sh):
- TASK_ID={{TASK_ID}}
- BRANCH_MODE={{BRANCH_MODE_EFFECTIVE}}
- WORK_REVIEW={{WORK_REVIEW}}
- REVIEW_RECEIPT_PATH={{REVIEW_RECEIPT_PATH}}
- RALPH_ITERATION={{RALPH_ITERATION}}

---

## Step 0: Read project configuration

```bash
APP_TYPE=$(grep '^APP_TYPE=' scripts/ralph/config.env 2>/dev/null | cut -d= -f2 || echo "web")
FEATURE_BRANCH_PREFIX=$(grep '^FEATURE_BRANCH_PREFIX=' scripts/ralph/config.env 2>/dev/null | cut -d= -f2 || echo "feature/")
echo "APP_TYPE=$APP_TYPE FEATURE_BRANCH_PREFIX=$FEATURE_BRANCH_PREFIX"
```

Store these values — they control which quality gates run.

## Step 1: Assess parallelizable work

Derive the epic ID and find all ready tasks:
```bash
EPIC_ID=$(echo "{{TASK_ID}}" | sed 's/\.[0-9]*$//')
scripts/ralph/flowctl tasks --epic $EPIC_ID --json
```

A task is **ready** if:
- status = `todo`
- ALL dependency tasks have status = `done`

The assigned {{TASK_ID}} is always in the batch. Add any other ready tasks to form the parallel batch.

## Step 2: Ensure feature branch exists and is pushed

```bash
EPIC_SLUG=$(scripts/ralph/flowctl show $EPIC_ID --json | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('slug', d.get('id','')))")
FEATURE_BRANCH="${FEATURE_BRANCH_PREFIX}${EPIC_SLUG}"
```

If the current branch is not the feature branch:
```bash
git fetch origin
git checkout "$FEATURE_BRANCH" 2>/dev/null || git checkout -b "$FEATURE_BRANCH" origin/main
git pull origin "$FEATURE_BRANCH" --rebase 2>/dev/null || true
git push -u origin "$FEATURE_BRANCH"
```

## Step 3: Execute tasks

### If only ONE task is ready (the assigned task):

Execute it directly in the current worktree — no subagent needed. Follow the **Worker Pipeline** (W1–W6) below.

### If MULTIPLE tasks are ready:

1. Execute the assigned {{TASK_ID}} yourself directly using the Worker Pipeline.
2. For EACH additional ready task, spawn a parallel Agent using the Agent tool with `isolation: "worktree"`.

Each Agent prompt MUST include:
- The full Worker Pipeline instructions (W1–W6) below, adapted for the specific TASK_ID
- The APP_TYPE value
- The feature branch name (for reference, workers push their worktree branch)
- The flowctl path (`scripts/ralph/flowctl` relative to repo root)

Wait for ALL agents to complete before proceeding to Step 4.

---

## Worker Pipeline (W1–W6)

Every task — executed by you or a subagent — MUST follow ALL steps in order. No skipping.

### W1: Implement the task

```
/flow-next:work <TASK_ID> --branch=current --review={{WORK_REVIEW}}
```

Verify task is done:
```bash
scripts/ralph/flowctl show <TASK_ID> --json
```
If status != `done`, retry implementation. Do NOT proceed until the task is marked done.

### W2: Staff Engineer Code Review

```
/review
```

This finds bugs that pass CI but blow up in production. Fix any issues found — commit fixes as **separate commits** referencing the task ID.

**If the review surfaces unexpected bugs or behavior that you don't fully understand:**
```
/investigate
```
Use `/investigate` to perform systematic root cause analysis. Do NOT guess at fixes. Find the actual root cause, then fix it.

### W3: Design Review

```
/design-review
```

This audits visual quality against the design system. Fix issues and commit as separate commits. Save any before/after screenshots produced.

### W4: Visual Preview Verification (native apps only)

**Skip this step if APP_TYPE = `web`.**

If APP_TYPE = `native`:
```
/ui-preview
```

Quick preview check of all changed SwiftUI views via Xcode MCP `RenderPreview`.
No build needed — seconds per view. Batch-preview all changed views, fix layout/
spacing/color/typography issues, re-preview until all views pass. Verify:
- Layout correctness — no clipping, misalignment, or overflow
- Design system tokens (colors, typography, spacing) match DESIGN.md
- Both light and dark appearance (if preview supports it)

Fix any issues found. Commit fixes.

### W4b: Simulator Integration Test (native apps only)

**Skip this step if APP_TYPE = `web`.**
**Skip this step if the task has NO navigation, animation, or multi-view changes.**

If APP_TYPE = `native` AND the task touches navigation/animations/multi-view flows:
```
/ui-verify-xcode
```

Build, install, launch in simulator. Record video of affected user flows.
Extract frames to verify navigation and transitions work correctly.
Test both iPhone and iPad layouts where applicable.

Fix any issues found. Commit fixes.

### W5: QA Verification

**If APP_TYPE = `web`:**
```
/qa
```
Runs systematic QA, finds bugs, fixes them, re-verifies.

**If APP_TYPE = `native`:**
```
/qa-xcode
```
Systematic native QA: builds, launches in simulator, records video of user flows
affected by this task, tests edge cases (empty states, error states, keyboard,
accessibility), fixes issues with atomic commits, and produces a structured report.
Tests both iOS Simulator and macOS builds.

### W6: Commit and push

Ensure ALL changes are committed:
```bash
git add -A
git status
```

If there are uncommitted changes, commit them with a descriptive message referencing the task ID.

**CRITICAL — Push to origin. Unpushed work is invisible to other agents and will be lost.**
```bash
git push origin HEAD
```

---

## Step 4: Merge parallel worker branches into feature branch

**Skip if no parallel subagents were spawned.**

If you spawned parallel subagents, each completed in its own worktree with its own branch. Merge them into the feature branch:

```bash
git checkout "$FEATURE_BRANCH"
git pull origin "$FEATURE_BRANCH"
```

For each completed worker branch:
```bash
git merge <worker-branch> --no-ff -m "merge: <task-id> — <one-line summary>"
```

Resolve any merge conflicts. Then push:
```bash
git push origin "$FEATURE_BRANCH"
```

If no parallel workers were spawned, ensure the feature branch is pushed:
```bash
git push origin "$FEATURE_BRANCH"
```

## Step 5: Write impl receipts

Write receipt for the primary assigned task:
```bash
mkdir -p "$(dirname '{{REVIEW_RECEIPT_PATH}}')"
ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
cat > '{{REVIEW_RECEIPT_PATH}}' <<EOF
{"type":"impl_review","id":"{{TASK_ID}}","mode":"{{WORK_REVIEW}}","timestamp":"$ts","iteration":{{RALPH_ITERATION}}}
EOF
echo "Receipt written: {{REVIEW_RECEIPT_PATH}}"
```

For each parallel task that completed the FULL Worker Pipeline (W1–W6), also write its receipt:
```bash
RECEIPT_DIR="$(dirname '{{REVIEW_RECEIPT_PATH}}')"
cat > "$RECEIPT_DIR/impl-<PARALLEL_TASK_ID>.json" <<EOF
{"type":"impl_review","id":"<PARALLEL_TASK_ID>","mode":"{{WORK_REVIEW}}","timestamp":"$ts","iteration":{{RALPH_ITERATION}}}
EOF
```

**CRITICAL:** Only write receipts for tasks that completed ALL quality gates (W1–W6). Never write a receipt for a task that failed or was skipped.

## Step 6: Validate epic

```bash
scripts/ralph/flowctl validate --epic $(echo {{TASK_ID}} | sed 's/\.[0-9]*$//') --json
```

## Step 7: On hard failure

Output `<promise>FAIL</promise>` and stop.

---

## Rules

- Must run `flowctl done` and verify status = `done` before proceeding to quality gates.
- Must `git add -A` (never list files individually).
- Do NOT use TodoWrite.
- ALL quality gates (W2–W5) are MANDATORY. Do not skip any.
- If `/review` or `/design-review` find critical issues, fix them before proceeding.
- If a quality gate finds unfixable critical issues, reset the task:
  ```bash
  scripts/ralph/flowctl task reset <TASK_ID> --json
  ```
  Then output `<promise>RETRY</promise>` and stop.
- Commit quality gate fixes as SEPARATE commits (not amended into the task commit).
- **Always push to origin after committing.** Every. Single. Time.
- When spawning parallel agents, include the FULL Worker Pipeline (W1–W6) in the agent prompt. Do not abbreviate.
- When something doesn't work as expected, use `/investigate` before trying random fixes.

## FORBIDDEN OUTPUT

**NEVER output `<promise>COMPLETE</promise>`** — this prompt handles tasks for ONE iteration only.
Ralph detects all-work-complete automatically via the selector. Outputting COMPLETE here is INVALID and will be ignored.
