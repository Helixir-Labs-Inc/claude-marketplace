# xcrun simctl — Command Reference

Quick reference for iOS Simulator management commands.

## Table of Contents
- Device Management
- App Lifecycle
- IO (Screenshots, Video)
- UI Settings
- Status Bar
- Push Notifications
- Deep Links
- Location
- Privacy & Permissions
- Pasteboard

## Device Management

```bash
# List all available devices
xcrun simctl list devices available

# List booted devices
xcrun simctl list devices booted

# Boot a device by name
xcrun simctl boot "iPhone 16 Pro"

# Boot by UDID
xcrun simctl boot <UDID>

# Shutdown specific device
xcrun simctl shutdown "iPhone 16 Pro"

# Shutdown all
xcrun simctl shutdown all

# Erase (factory reset) a device
xcrun simctl erase "iPhone 16 Pro"

# Clone a device
xcrun simctl clone "iPhone 16 Pro" "iPhone 16 Pro - Test Copy"

# Open Simulator.app
open -a Simulator
```

## App Lifecycle

```bash
# Install app from .app bundle
xcrun simctl install booted /path/to/App.app
# Or by UDID (preferred for reliability):
xcrun simctl install <UDID> /path/to/App.app

# Uninstall by bundle ID
xcrun simctl uninstall booted com.example.app

# Launch app (non-blocking, no console)
xcrun simctl launch booted com.example.app

# Launch with print() output capture (BLOCKS terminal)
# IMPORTANT: Use --console-pty (not --console or --stdout)
xcrun simctl launch --console-pty --terminate-running-process booted com.example.app

# --terminate-running-process ensures app relaunches even if already running
# Without it, launch silently does nothing if app is in foreground

# Launch in background with console to file:
xcrun simctl launch --console-pty --terminate-running-process <UDID> com.example.app \
  > /tmp/console.log 2>&1 &

# Terminate running app
xcrun simctl terminate booted com.example.app

# Get app info
xcrun simctl appinfo booted com.example.app

# List all installed apps
xcrun simctl listapps booted

# Get app container path
xcrun simctl get_app_container booted com.example.app
xcrun simctl get_app_container booted com.example.app data    # Data container
xcrun simctl get_app_container booted com.example.app groups   # App group containers
```

## Logging (OSLog / Logger)

```bash
# Stream logs filtered by subsystem (non-blocking in Claude — use run_in_background)
xcrun simctl spawn <UDID> log stream --level=debug \
  --predicate 'subsystem == "com.example.app"'

# Show recent logs (last N minutes)
xcrun simctl spawn <UDID> log show --last 2m --style compact \
  --predicate 'subsystem == "com.example.app"'

# Filter by category
xcrun simctl spawn <UDID> log stream --level=debug \
  --predicate 'subsystem == "com.example.app" AND category == "networking"'
```

## IO — Screenshots and Video

```bash
# Screenshot (PNG by default)
xcrun simctl io booted screenshot /tmp/screenshot.png

# Screenshot with format
xcrun simctl io booted screenshot --type=jpeg /tmp/screenshot.jpg
xcrun simctl io booted screenshot --type=tiff /tmp/screenshot.tiff

# Screenshot specific device by UDID
xcrun simctl io <UDID> screenshot /tmp/screenshot.png

# Record video (Ctrl+C to stop)
xcrun simctl io booted recordVideo /tmp/recording.mov

# Record with codec
xcrun simctl io booted recordVideo --codec=h264 /tmp/recording.mov
```

## UI Settings

```bash
# Appearance (light/dark mode)
xcrun simctl ui booted appearance              # Get current
xcrun simctl ui booted appearance dark         # Set dark
xcrun simctl ui booted appearance light        # Set light

# Increase Contrast
xcrun simctl ui booted increase_contrast enabled
xcrun simctl ui booted increase_contrast disabled

# Content Size (Dynamic Type)
xcrun simctl ui booted content_size                        # Get current
xcrun simctl ui booted content_size extra-large             # Set specific
xcrun simctl ui booted content_size accessibility-extra-large
xcrun simctl ui booted content_size increment               # One step larger
xcrun simctl ui booted content_size decrement               # One step smaller

# Available sizes (small to large):
#   extra-small, small, medium, large (default),
#   extra-large, extra-extra-large, extra-extra-extra-large
# Accessibility range:
#   accessibility-medium, accessibility-large,
#   accessibility-extra-large, accessibility-extra-extra-large,
#   accessibility-extra-extra-extra-large
```

## Status Bar Overrides

Override status bar for clean screenshots:

```bash
# Set clean status bar
xcrun simctl status_bar booted override \
  --time "9:41" \
  --batteryState charged --batteryLevel 100 \
  --wifiBars 3 --cellularBars 4 \
  --dataNetwork wifi

# Clear overrides
xcrun simctl status_bar booted clear
```

## Push Notifications

```bash
# Send push via stdin
xcrun simctl push booted com.example.app - <<'EOF'
{
  "aps": {
    "alert": { "title": "Hello", "body": "Test notification" },
    "badge": 3,
    "sound": "default"
  }
}
EOF

# Send push from file
xcrun simctl push booted com.example.app payload.json
```

## Deep Links

```bash
# Open URL scheme
xcrun simctl openurl booted myapp://screen/detail?id=123

# Open universal link
xcrun simctl openurl booted https://example.com/deep/path
```

## Location

```bash
# Set location (lat,lon)
xcrun simctl location booted set 37.7749,-122.4194

# Clear location
xcrun simctl location booted clear
```

## Privacy & Permissions

```bash
# Grant permissions
xcrun simctl privacy booted grant photos com.example.app
xcrun simctl privacy booted grant camera com.example.app
xcrun simctl privacy booted grant microphone com.example.app
xcrun simctl privacy booted grant location-always com.example.app
xcrun simctl privacy booted grant contacts com.example.app

# Revoke
xcrun simctl privacy booted revoke photos com.example.app

# Reset all permissions
xcrun simctl privacy booted reset all com.example.app
```

## Pasteboard & Media

```bash
# Copy text to simulator pasteboard
echo "test text" | xcrun simctl pbcopy booted

# Read simulator pasteboard
xcrun simctl pbpaste booted

# Add photos/videos to simulator
xcrun simctl addmedia booted /path/to/photo.jpg
```
