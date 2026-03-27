You are running one Ralph epic completion review iteration.

Inputs:
- EPIC_ID={{EPIC_ID}}
- COMPLETION_REVIEW={{COMPLETION_REVIEW}}

## Steps (execute ALL in order)

**Step 1: Re-anchor**
```bash
scripts/ralph/flowctl show {{EPIC_ID}} --json
scripts/ralph/flowctl cat {{EPIC_ID}}
git status
git log -10 --oneline
```

**Step 2: Save checkpoint** (recovery point if context compacts during review cycles)
```bash
scripts/ralph/flowctl checkpoint save --epic {{EPIC_ID}} --json
```

**Step 3: Per-task validation sweep**

Before the holistic epic review, triage every "done" task with a cheap pass, then deep-check only suspects.

```bash
scripts/ralph/flowctl tasks --epic {{EPIC_ID}} --json
```

**Pass 1: Quick triage (ALL tasks, ~1 command each)**

For each task with status `done`, run ONE command to read the spec:
```bash
scripts/ralph/flowctl cat <task-id>
```

Flag a task as SUSPECT if ANY of:
- No `## Done summary` or `## Evidence` section
- No commit SHAs in evidence
- Done summary is generic/vague (e.g., "Implemented as described" with no specifics)
- Evidence commits don't exist on HEAD: `git cat-file -t <sha> 2>/dev/null || echo MISSING`

Tasks that have a specific done summary, valid commit SHAs, and evidence of tests/builds → mark PASS, move on. Do NOT read source files for passing tasks.

**Pass 2: Deep check (SUSPECT tasks only)**

For each suspect task:
1. Verify evidence commits touch the files listed in the spec: `git show --stat <sha> | head -20`
2. Check the diff for stubs: `git diff <first-sha>^..<last-sha> | grep -i "TODO\|FIXME\|HACK\|placeholder\|not implemented\|stub"`
3. For each acceptance criterion, grep for the specific implementation (function name, view name, property) — ONE grep per criterion, not a full file read.

**Handling failures:**
- Attempt to fix the issue directly (implement missing pieces, fix broken code).
- If fixable: commit the fix as a separate commit referencing the task ID.
- If NOT fixable within reasonable effort: reset the task:
  ```bash
  scripts/ralph/flowctl task reset <task-id> --json
  ```

**If ANY tasks were reset**, output `<promise>RETRY</promise>` and end this iteration. Ralph will re-run the reset tasks in subsequent iterations, then return to completion review once all tasks are done again.

Only proceed to Step 4 if all tasks pass.

**Step 4: Build verification (iOS Simulator)**

Build, install, and visually verify the full epic's changes:
```bash
cd DeftTask && xcodebuild -project DeftTask.xcodeproj -scheme DeftTask \
  -destination "platform=iphonesimulator,id=07056B03-F4DE-488B-B0A4-5BA389605F4B" \
  -derivedDataPath DerivedData -configuration Debug build 2>&1 | xcsift -w
```
If the build fails, fix the errors and rebuild. If the build succeeds:
```bash
UDID=07056B03-F4DE-488B-B0A4-5BA389605F4B
xcrun simctl install $UDID DeftTask/DerivedData/Build/Products/Debug-iphonesimulator/DeftTask.app
xcrun simctl launch --console-pty --terminate-running-process $UDID com.defttask.app -UITestBypassAuth
xcrun simctl io $UDID screenshot /tmp/screen.png && magick /tmp/screen.png -resize 33.333% /tmp/screen_1x.png
```
Navigate to screens affected by the epic and take screenshots. Verify:
- No layout issues, clipping, or misalignment
- Dark mode works where applicable
- Design tokens are applied correctly (colors, typography, spacing)

Use deep links (`xcrun simctl openurl $UDID "defttask://home"`) and accessibility tools (`axe describe-ui --udid $UDID`, `axe tap -x <X> -y <Y> --udid $UDID --post-delay 0.5`) to navigate.

If issues are found: fix, rebuild, re-screenshot, commit fixes as separate commits. If an issue traces back to a specific task that needs rework, reset that task and output `<promise>RETRY</promise>`.

**Step 5: Completion review gate**

Ralph mode rules (must follow):
- If COMPLETION_REVIEW=rp: use `flowctl rp` wrappers (setup-review, select-add, prompt-get, chat-send).
- If COMPLETION_REVIEW=codex: use `flowctl codex` wrappers (completion-review with --receipt).
- Write receipt via bash heredoc (no Write tool) if `REVIEW_RECEIPT_PATH` set.
- If any rule is violated, output `<promise>RETRY</promise>` and stop.

Run the review:
- If COMPLETION_REVIEW=rp: run `/flow-next:epic-review {{EPIC_ID}} --review=rp`
- If COMPLETION_REVIEW=codex: run `/flow-next:epic-review {{EPIC_ID}} --review=codex`
- If COMPLETION_REVIEW=none: set ship and stop:
  `scripts/ralph/flowctl epic set-completion-review-status {{EPIC_ID}} --status ship --json`

**Step 6:** The skill will loop internally until `<verdict>SHIP</verdict>`:
- First review uses `--new-chat`
- If NEEDS_WORK: skill fixes gaps (creates tasks or implements inline), re-reviews in SAME chat
- Repeats until SHIP
- Only returns to Ralph after SHIP or MAJOR_RETHINK
- If context compacts mid-review: `scripts/ralph/flowctl checkpoint restore --epic {{EPIC_ID}} --json`

**Step 7:** IMMEDIATELY after SHIP verdict, write receipt (for rp mode):
```bash
mkdir -p "$(dirname '{{REVIEW_RECEIPT_PATH}}')"
ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
cat > '{{REVIEW_RECEIPT_PATH}}' <<EOF
{"type":"completion_review","id":"{{EPIC_ID}}","mode":"rp","timestamp":"$ts","iteration":{{RALPH_ITERATION}}}
EOF
```
For codex mode, receipt is written automatically by `flowctl codex completion-review --receipt`.
**CRITICAL: Copy EXACTLY. The `"id":"{{EPIC_ID}}"` field is REQUIRED.**
Missing id = verification fails = forced retry.

**Step 8: Finalize**
- `scripts/ralph/flowctl epic set-completion-review-status {{EPIC_ID}} --status ship --json`
- stop (do NOT output promise tag)

**Step 9:** If MAJOR_RETHINK (rare):
- `scripts/ralph/flowctl epic set-completion-review-status {{EPIC_ID}} --status needs_work --json`
- output `<promise>FAIL</promise>` and stop

**Step 10:** On hard failure, output `<promise>FAIL</promise>` and stop.

## FORBIDDEN OUTPUT
**NEVER output `<promise>COMPLETE</promise>`** - this prompt handles ONE epic only.
Ralph detects all-work-complete automatically via the selector. Outputting COMPLETE here is INVALID and will be ignored.
