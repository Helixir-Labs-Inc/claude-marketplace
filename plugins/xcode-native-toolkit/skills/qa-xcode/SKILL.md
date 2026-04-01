---
name: qa-xcode
description: |
  Systematically QA test a native iOS/macOS app and fix bugs found. The native
  equivalent of /qa — builds, launches in simulator, records video of user flows,
  extracts frames to verify, and fixes issues with atomic commits. Three tiers:
  Quick (critical only), Standard (+ medium), Exhaustive (+ cosmetic/accessibility).
  Produces structured QA reports with video evidence and health scores.
  Use when asked to "qa the app", "test the iOS build", "QA native", "test on
  simulator", "does this work on iPhone", "test the app", or after implementing
  a native feature. For visual-only verification without QA methodology, use
  /ui-verify-xcode instead.
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - AskUserQuestion
  - WebSearch
---

# /qa-xcode: Native App QA — Test → Fix → Verify

You are a QA engineer AND a bug-fix engineer for native iOS/macOS apps. Test the
app like a real user — navigate every flow, interact with every control, check
every state. When you find bugs, fix them in source code with atomic commits,
then re-verify via simulator. Produce a structured report with video/screenshot
evidence.

## Prerequisites

- macOS with Xcode installed
- Simulator booted (or will boot one)
- CLI tools: `xcsift`, `imagemagick`, `axe`, `ffmpeg`
- Xcode MCP bridge configured (optional but preferred): `claude mcp add --transport stdio xcode -- xcrun mcpbridge`

## Setup

**Parse the user's request for these parameters:**

| Parameter | Default | Override example |
|-----------|---------|-----------------|
| Platform | iPhone simulator | `--ipad`, `--macos`, `--both` |
| Tier | Standard | `--quick`, `--exhaustive` |
| Scope | Full app (or diff-scoped) | `Focus on the task creation flow` |
| Output dir | `.gstack/qa-reports/` | `Output to /tmp/qa` |

**Tiers determine which issues get fixed:**
- **Quick:** Critical + high severity only (crashes, data loss, broken navigation)
- **Standard:** + medium severity (layout breaks, wrong data, missing states)
- **Exhaustive:** + low/cosmetic + accessibility (spacing, contrast, VoiceOver, Dynamic Type)

**Read project CLAUDE.md** to get:
- Simulator UDID, scheme, bundle ID, project directory
- Deep link URL schemes
- Design system reference (DESIGN.md)
- Build commands (prefer MCP tools if noted)

**If no scope given and on a feature branch:** Automatically enter **diff-aware mode**:
```bash
git diff main...HEAD --name-only
git log main..HEAD --oneline
```
Identify affected views, services, and user flows from the changed files.

**Check for clean working tree:**
```bash
git status --porcelain
```
If dirty, ask user to commit or stash before proceeding.

## Phase 1: Build and Launch

### With Xcode MCP (preferred)
- `BuildProject` — check for errors
- If errors: `XcodeListNavigatorIssues` → fix → rebuild
- `DocumentationSearch` if unsure about an API

### Shell fallback
```bash
cd <PROJECT_DIR> && xcodebuild -project <Project>.xcodeproj -scheme <Scheme> \
  -destination "platform=iphonesimulator,id=<UDID>" \
  -derivedDataPath DerivedData -configuration Debug build 2>&1 | xcsift -w
```

### Install and launch
```bash
xcrun simctl install <UDID> <APP_PATH>
xcrun simctl launch --console-pty --terminate-running-process <UDID> <BUNDLE_ID>
```

If build fails, fix the build error first. Do NOT proceed to testing with a broken build.

## Phase 2: Generate Test Plan

Based on scope (diff-aware or full app), generate a test plan:

### For each user flow, define:
1. **Flow name** (e.g., "Create a new task")
2. **Steps** (navigate, tap, type, scroll, verify)
3. **Expected result** at each step
4. **Edge cases** to test:
   - Empty state (no data)
   - Error state (invalid input, network failure)
   - Boundary values (very long text, special characters)
   - Keyboard handling (dismiss, next field)
   - Rotation (if applicable)

### Severity classification:
| Severity | Definition | Examples |
|----------|-----------|----------|
| Critical | App crashes, data loss, security issue | Crash on tap, data not saved |
| High | Feature broken, blocks user flow | Button does nothing, wrong screen |
| Medium | Feature works but incorrectly | Wrong color, misaligned layout, truncated text |
| Low | Cosmetic or minor UX issue | Extra spacing, animation glitch |
| Accessibility | VoiceOver, Dynamic Type, contrast | Missing labels, text overflow at AX5 |

## Phase 3: Execute Test Plan (Video-First)

For each user flow in the test plan:

### 3a. Start video recording
```bash
axe record-video --udid <UDID> --fps 10 --scale 0.333 \
  --output <OUTPUT_DIR>/screenshots/flow-<N>.mp4
```
Run in background. `--scale 0.333` = 1x resolution.

### 3b. Perform the flow
Navigate using deep links where possible, then interact:
```bash
xcrun simctl openurl <UDID> "<deep-link>"
sleep 2
axe tap --label "<element>" --udid <UDID> --post-delay 1
axe type "<text>" --udid <UDID>
axe gesture scroll-down --udid <UDID> --post-delay 0.5
```

Take screenshots at key checkpoints:
```bash
xcrun simctl io <UDID> screenshot <OUTPUT_DIR>/screenshots/flow-<N>-step-<M>.png
magick <OUTPUT_DIR>/screenshots/flow-<N>-step-<M>.png -resize 33.333% \
  <OUTPUT_DIR>/screenshots/flow-<N>-step-<M>_1x.png
```

### 3c. Stop recording
Kill the background recording process.

### 3d. Extract key frames for review
```bash
mkdir -p <OUTPUT_DIR>/screenshots/flow-<N>-frames
ffmpeg -i <OUTPUT_DIR>/screenshots/flow-<N>.mp4 \
  -vf "fps=2" <OUTPUT_DIR>/screenshots/flow-<N>-frames/frame_%03d.png 2>/dev/null
```

### 3e. Review frames and screenshots
Read each key frame and checkpoint screenshot. For each, check:
- Is the expected UI state shown?
- Are transitions smooth (no flicker between frames)?
- Is data correct?
- Are there layout issues?

### 3f. Log findings
For each issue found, record:
- Flow name and step number
- Severity (critical/high/medium/low/accessibility)
- Description of what's wrong
- Expected vs actual behavior
- Screenshot/frame reference

## Phase 4: Appearance and Accessibility Testing

### Dark mode
```bash
xcrun simctl ui booted appearance dark
```
Re-run critical flows. Screenshot key screens. Check for:
- Light-theme colors leaking through
- Unreadable text (contrast)
- Missing dark variants for custom colors

```bash
xcrun simctl ui booted appearance light  # Reset
```

### Dynamic Type (Exhaustive tier only)
```bash
xcrun simctl ui booted content_size extra-extra-extra-large
```
Screenshot key screens. Check for:
- Text overflow or clipping
- Layout reflow
- Overlapping elements

```bash
xcrun simctl ui booted content_size large  # Reset
```

### Accessibility inspection (Exhaustive tier only)
```bash
axe describe-ui --udid <UDID>
```
Check:
- Touch targets >= 44x44pt (check frame sizes in JSON output)
- VoiceOver labels on all interactive elements
- Proper roles (button, link, etc.)
- >= 8pt spacing between adjacent tap targets

## Phase 5: Fix Loop

For each issue found, ordered by severity (critical first):

### 5a. Fix the code
Read the relevant source files, identify the bug, fix it.

### 5b. Rebuild and re-verify
- `BuildProject` (or shell fallback)
- Re-install and re-launch
- Navigate to the affected screen
- Screenshot or record to confirm the fix

### 5c. Atomic commit
Each fix gets its own commit:
```bash
git add <changed-files>
git commit -m "fix(<scope>): <description>

Severity: <critical|high|medium|low>
Found by: /qa-xcode
Flow: <flow-name>, Step <N>"
```

### 5d. Before/after evidence
Save both the "before" screenshot (from Phase 3) and "after" screenshot showing the fix.

## Phase 6: Re-run Affected Flows

After all fixes are committed, re-run the flows that had issues:
1. Rebuild
2. Record video of each previously-failing flow
3. Extract frames and verify all issues are resolved
4. If new issues found, return to Phase 5

## Phase 7: QA Report

Write the report to `<OUTPUT_DIR>/qa-report-<platform>-<date>.md`:

```markdown
# QA Report — <Platform> — <Date>

| Metric | Value |
|--------|-------|
| **Platform** | <iPhone/iPad/macOS> |
| **Tier** | <Quick/Standard/Exhaustive> |
| **Scope** | <Full app / diff-scoped: description> |
| **Flows tested** | <N> |
| **Issues found** | <N> |
| **Issues fixed** | <N> |
| **Health score** | <0-100> |

## Flows Tested

### Flow 1: <name>
**Status:** PASS / FAIL (N issues)
**Video:** screenshots/flow-1.mp4
**Steps:**
1. <step> — PASS
2. <step> — FAIL: <description> — FIXED in <commit>

### Flow 2: <name>
...

## Issues Summary

| # | Severity | Flow | Description | Status |
|---|----------|------|-------------|--------|
| 1 | Critical | Create task | Crash on empty title | FIXED <sha> |
| 2 | Medium | Task list | Title truncated at 20 chars | FIXED <sha> |

## Appearance Testing
- Light mode: PASS / FAIL
- Dark mode: PASS / FAIL
- Dynamic Type: PASS / FAIL / SKIPPED (tier)
- Accessibility: PASS / FAIL / SKIPPED (tier)

## Evidence
Screenshots and video recordings in `screenshots/` subdirectory.
```

### Health score calculation:
- Start at 100
- Critical issue: -25 each
- High issue: -15 each
- Medium issue: -5 each
- Low/accessibility: -2 each
- Fixed issues add back half their deduction
- Floor at 0

## Phase 8: Ship Readiness

At the end, report:
- **SHIP IT** — Health score >= 80, no unfixed critical/high issues
- **NEEDS WORK** — Health score 50-79, or unfixed medium issues remain
- **BLOCKED** — Health score < 50, or unfixed critical/high issues remain

## Integration with Ralph

When invoked as W5 in the Ralph Worker Pipeline:
- Use diff-aware mode (scope to the task's changes)
- Standard tier unless the task spec says otherwise
- All fixes committed as separate commits referencing the task ID
- Report written to `.gstack/qa-reports/`
- Return SHIP IT / NEEDS WORK / BLOCKED as the gate result

## Tips

- Use deep links aggressively — skip tapping through menus
- Record video for every flow, not just failing ones (evidence)
- `axe tap --label` is more reliable than coordinates
- `--terminate-running-process` on every launch
- Never delete DerivedData
- Read DESIGN.md before assessing visual issues
