You are running one Ralph work iteration.

Inputs:
- TASK_ID={{TASK_ID}}
- BRANCH_MODE={{BRANCH_MODE_EFFECTIVE}}
- WORK_REVIEW={{WORK_REVIEW}}

## Steps (execute ALL in order)

**Step 1: Execute task**
```
/flow-next:work {{TASK_ID}} --branch={{BRANCH_MODE_EFFECTIVE}} --review={{WORK_REVIEW}}
```
When `--review=rp`, the worker subagent invokes `/flow-next:impl-review` internally.
When `--review=codex`, the worker uses `flowctl codex impl-review` for review.
The impl-review skill handles review coordination and requires `<verdict>SHIP|NEEDS_WORK|MAJOR_RETHINK</verdict>` from reviewer.
Do NOT improvise review prompts - the skill has the correct format.

**Step 2: Verify task done** (AFTER skill returns)
```bash
scripts/ralph/flowctl show {{TASK_ID}} --json
```
If status != `done`, output `<promise>RETRY</promise>` and stop.

**Step 3: Post-task quality gates** (run both sequentially)

After the task is done and committed, run these quality checks. Fix any issues found before moving on.

**CRITICAL: If a quality gate finds critical issues that you cannot fix, reset the task:**
```bash
scripts/ralph/flowctl task reset {{TASK_ID}} --json
```
Then output `<promise>RETRY</promise>` and stop. Ralph will retry the task on the next iteration.

**3a: Staff Engineer Code Review**
Run the gstack /review skill to find bugs that pass CI but blow up in production:
```
/review
```
This will auto-fix obvious issues and flag completeness gaps. If it produces fixes, commit them as a separate commit referencing the task ID.

**3b: Design Review**
Run the gstack /design-review skill to audit visual quality against the design system spec:
```
/design-review
```
This audits the same dimensions as /plan-design-review but then fixes what it finds with atomic commits. If it produces before/after screenshots, save them.

**NOTE:** UI verification (simulator build + screenshots) is deferred to epic completion review to avoid redundant builds per task.

**Step 4: Write impl receipt** (MANDATORY if WORK_REVIEW=rp or codex — ONLY after quality gates pass)

This receipt signals to Ralph that the task is truly complete including quality gates. Do NOT write it before Step 3 finishes successfully.

For rp mode:
```bash
mkdir -p "$(dirname '{{REVIEW_RECEIPT_PATH}}')"
ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
cat > '{{REVIEW_RECEIPT_PATH}}' <<EOF
{"type":"impl_review","id":"{{TASK_ID}}","mode":"rp","timestamp":"$ts","iteration":{{RALPH_ITERATION}}}
EOF
echo "Receipt written: {{REVIEW_RECEIPT_PATH}}"
```
For codex mode, receipt is written automatically by `flowctl codex impl-review --receipt`.
**CRITICAL: Copy the command EXACTLY. The `"id":"{{TASK_ID}}"` field is REQUIRED.**
Ralph verifies receipts match this exact schema. Missing id = verification fails = forced retry.

**Step 5: Validate epic**
```bash
scripts/ralph/flowctl validate --epic $(echo {{TASK_ID}} | sed 's/\.[0-9]*$//') --json
```

**Step 6: On hard failure** → output `<promise>FAIL</promise>` and stop.

## Rules
- Must run `flowctl done` and verify task status is `done` before commit.
- Must `git add -A` (never list files).
- Do NOT use TodoWrite.
- Post-task quality gates (Step 3) are mandatory. Do not skip them.
- If /review or /design-review find critical issues, fix them before proceeding.
- If a quality gate finds unfixable critical issues, reset the task and output `<promise>RETRY</promise>`.
- Commit quality gate fixes as SEPARATE commits (not amended into the task commit).
- Do NOT write the impl receipt (Step 4) until AFTER quality gates (Step 3) pass. This is how Ralph detects incomplete tasks on restart.

## ⛔ FORBIDDEN OUTPUT
**NEVER output `<promise>COMPLETE</promise>`** — this prompt handles ONE task only.
Ralph detects all-work-complete automatically via the selector. Outputting COMPLETE here is INVALID and will be ignored.
