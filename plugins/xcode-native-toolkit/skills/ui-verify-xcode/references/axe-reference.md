# AXe — Simulator Interaction Reference

CLI tool for interacting with iOS Simulators using Apple's Accessibility APIs and HID.
Install: `brew tap cameroncooke/axe && brew install axe`

## Accessibility Tree

```bash
# Full UI hierarchy as JSON (frames, labels, types, IDs)
axe describe-ui --udid <UDID>
```

Output includes `AXLabel`, `AXUniqueId`, `frame` (x, y, width, height), `type`, `role`, and `children`.

**Note:** `describe-ui` may not show tab bars or toolbars on iOS 26+.

## Tap

```bash
# Tap by coordinates (1x logical points)
axe tap -x 200 -y 400 --udid <UDID> --post-delay 0.5

# Tap by accessibility label
axe tap --label "Sign in with Apple" --udid <UDID> --post-delay 0.5

# Tap by accessibility identifier
axe tap --id "settingsButton" --udid <UDID> --post-delay 0.5
```

**Verified tap workflow (recommended):**
1. Screenshot at 1x: `xcrun simctl io <UDID> screenshot /tmp/s.png && magick /tmp/s.png -resize 33.333% /tmp/s1x.png`
2. Draw verification box: `magick /tmp/s1x.png -fill none -stroke red -strokewidth 2 -draw "rectangle $((X-30)),$((Y-30)) $((X+30)),$((Y+30))" /tmp/verify.png`
3. Read `/tmp/verify.png` to confirm red box is on target
4. Execute tap

## Type Text

```bash
axe type "Hello world" --udid <UDID>
```

## Swipe and Scroll

**IMPORTANT: Commands use FINGER direction, NOT content direction.**

```bash
# Scroll content UP (finger moves down the screen)
axe gesture scroll-down --udid <UDID> --post-delay 0.5

# Scroll content DOWN (finger moves up the screen)
axe gesture scroll-up --udid <UDID> --post-delay 0.5

# Navigate back (swipe from left edge)
axe gesture swipe-from-left-edge --udid <UDID> --post-delay 0.5

# Swipe left/right
axe gesture swipe-left --udid <UDID> --post-delay 0.5
axe gesture swipe-right --udid <UDID> --post-delay 0.5
```

## Hardware Buttons

```bash
axe button home --udid <UDID>
```

## Touch (Low-Level)

```bash
# Touch down at coordinates
axe touch down -x 200 -y 400 --udid <UDID>

# Touch up at coordinates
axe touch up -x 200 -y 400 --udid <UDID>
```

## Video Recording

```bash
# Record video
axe record-video --udid <UDID> --fps 30 --output /tmp/recording.mp4

# Stream video frames (advanced)
axe stream-video --udid <UDID> --fps 10 --format mjpeg
```

## Key Events

```bash
# Single key press
axe key <keycode> --udid <UDID>

# Key sequence
axe key-sequence <keycode1> <keycode2> --udid <UDID>

# Key combo (modifier + key)
axe key-combo --modifier command --key v --udid <UDID>
```
