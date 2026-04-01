---
name: ui-verify-xcode
description: >-
  Full simulator integration testing for iOS/macOS apps. Build, install, launch
  in simulator, record video of user flows, extract frames to verify navigation,
  animations, and multi-step interactions. Use after visual appearance is already
  verified with /ui-preview. Triggers on: "test in simulator", "verify on device",
  "integration test", "test navigation", "test animations", "record the flow",
  "full verify", "simulator test", "ui-verify-xcode", "test on iPhone",
  "test on iPad". For quick visual checks of individual views, use /ui-preview
  instead (much faster).
---

# UI Verify — Xcode Simulator Integration Testing

Build, install, launch in simulator. Record video of user flows. Extract frames
to verify navigation, animations, and state transitions.

**For quick visual checks of individual views → use `/ui-preview` instead.**
This skill is for testing things that require the app to actually run.

## When to Use

- Navigation between screens
- Animations and transitions
- Multi-step user flows (create, edit, delete, etc.)
- Dark mode / Dynamic Type appearance in running app
- Accessibility (touch targets, VoiceOver labels)
- Final integration check before marking work done

## Prerequisites

- macOS with Xcode installed
- CLI tools: `xcsift`, `imagemagick`, `axe`, `ffmpeg`
- Xcode MCP bridge (optional but preferred for builds)

## Step 1: Build

**MCP (preferred):** `BuildProject` → structured JSON errors.
On failure: `XcodeListNavigatorIssues` for details.

**Shell fallback:**
```bash
xcodebuild -project <Project>.xcodeproj -scheme "<Scheme>" \
  -configuration Debug \
  -destination "platform=iphonesimulator,id=<UDID>" \
  -derivedDataPath DerivedData build 2>&1 | xcsift -w
```

Set Bash `timeout` to **600000** for clean builds.

**CRITICAL: Never delete DerivedData.**

## Step 2: Install and Launch

```bash
xcrun simctl install <UDID> DerivedData/Build/Products/Debug-iphonesimulator/<App>.app
xcrun simctl launch --console-pty --terminate-running-process <UDID> <bundle-id>
```

Always use `--terminate-running-process`.

## Step 3: Record Video + Perform User Flow

**Start recording (background):**
```bash
axe record-video --udid <UDID> --fps 10 --scale 0.333 --output /tmp/flow-test.mp4
```

`--scale 0.333` = 1x resolution. `--fps 10` for review, `--fps 30` for animation checks.

**Perform the flow** while recording:
```bash
xcrun simctl openurl <UDID> "<deep-link>"      # Navigate via deep link (preferred)
sleep 2
axe tap --label "<element>" --udid <UDID> --post-delay 1
axe type "<text>" --udid <UDID>
axe gesture scroll-down --udid <UDID> --post-delay 0.5
axe tap -x <X> -y <Y> --udid <UDID> --post-delay 0.5
```

Take screenshots at key checkpoints for static analysis:
```bash
xcrun simctl io <UDID> screenshot /tmp/step-N.png
magick /tmp/step-N.png -resize 33.333% /tmp/step-N_1x.png
```

**Stop recording** — kill the background process.

## Step 4: Extract Frames and Review

```bash
mkdir -p /tmp/flow-frames
ffmpeg -i /tmp/flow-test.mp4 -vf "fps=2" /tmp/flow-frames/frame_%03d.png 2>/dev/null
```

`fps=2` = 2 frames/second. Use `fps=5` for animation-critical review.

Read key frames with **Read** tool. Verify:
- Screen transitions are smooth (no flicker/jump between frames)
- Navigation state correct at each step
- Animations completed properly
- Data appears correctly after actions
- No layout glitches during transitions

## Step 5: Fix and Re-Record

If issues found:
1. Fix the code
2. `BuildProject` (incremental, 10-30s)
3. Re-install + re-launch
4. Re-record same flow
5. Re-extract frames → verify
6. Repeat until pass

## Simpler Alternative: Screenshot-Per-Action

When video feels heavy, screenshot after each action:
```bash
axe tap --label "Tasks" --udid <UDID> --post-delay 1
xcrun simctl io <UDID> screenshot /tmp/step1.png && magick /tmp/step1.png -resize 33.333% /tmp/step1_1x.png
axe tap --label "New Task" --udid <UDID> --post-delay 1
xcrun simctl io <UDID> screenshot /tmp/step2.png && magick /tmp/step2.png -resize 33.333% /tmp/step2_1x.png
```

Misses animations but catches navigation and state issues.

## Appearance Testing

```bash
# Dark mode
xcrun simctl ui booted appearance dark
sleep 1
xcrun simctl io <UDID> screenshot /tmp/dark.png
xcrun simctl ui booted appearance light

# Dynamic Type largest
xcrun simctl ui booted content_size extra-extra-extra-large
sleep 1
xcrun simctl io <UDID> screenshot /tmp/ax-large.png
xcrun simctl ui booted content_size large  # Reset

# Clean status bar
xcrun simctl status_bar booted override \
  --time "9:41" --batteryState charged --batteryLevel 100 \
  --wifiBars 3 --cellularBars 4
```

## Accessibility

```bash
axe describe-ui --udid <UDID>
```

Verify: touch targets >= 44x44pt, VoiceOver labels set, proper roles,
>= 8pt between adjacent tap targets.

## Tap Accuracy Verification

Before tapping uncertain coordinates:
```bash
X=200; Y=400
magick /tmp/screen_1x.png -fill none -stroke red -strokewidth 2 \
  -draw "rectangle $((X-30)),$((Y-30)) $((X+30)),$((Y+30))" /tmp/verify.png
```

Read `/tmp/verify.png` to confirm, then tap.

## Interaction Commands Reference

```bash
# Tap by label (preferred)
axe tap --label "Save" --udid <UDID> --post-delay 0.5

# Tap by coordinates (1x)
axe tap -x 200 -y 400 --udid <UDID> --post-delay 0.5

# Type text
axe type "Hello world" --udid <UDID>

# Scroll (FINGER direction, not content)
axe gesture scroll-down --udid <UDID> --post-delay 0.5   # Content UP
axe gesture scroll-up --udid <UDID> --post-delay 0.5     # Content DOWN

# Back navigation
axe gesture swipe-from-left-edge --udid <UDID> --post-delay 0.5

# Hardware button
axe button home --udid <UDID>
```

## Multi-Device Testing

```bash
xcrun simctl boot "iPhone 16 Pro"
xcrun simctl boot "iPad Pro 13-inch (M4)"

IPHONE_UDID=$(xcrun simctl list devices booted | grep "iPhone 16 Pro" | grep -oE '[A-F0-9-]{36}')
IPAD_UDID=$(xcrun simctl list devices booted | grep "iPad Pro" | grep -oE '[A-F0-9-]{36}')
```

## References

| Topic | File |
|-------|------|
| Simulator commands | [simctl-reference.md](references/simctl-reference.md) |
| AXe interaction | [axe-reference.md](references/axe-reference.md) |
| Build errors | [build-troubleshooting.md](references/build-troubleshooting.md) |
| Assessment criteria | [ui-assessment-checklist.md](references/ui-assessment-checklist.md) |
