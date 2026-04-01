# Build Troubleshooting

Common xcodebuild errors and how to fix them.

## Table of Contents
- Scheme Not Found
- No Matching Destination
- Signing Errors
- Missing Config Files
- Package Resolution Failures
- Module Not Found
- Build Timeout
- Derived Data Issues
- Workspace vs Project
- App Crashes on Launch

## Scheme Not Found

**Error:** `xcodebuild: error: The scheme "X" is not in the project`

**Fix:**
```bash
xcodebuild -list -project *.xcodeproj 2>/dev/null | grep -A 20 "Schemes:"
```
Use the exact scheme name from the output.

## No Matching Destination

**Error:** `unable to find a destination matching the provided destination specifier`

**Fix:**
```bash
# List available destinations
xcodebuild -scheme "<Scheme>" -showdestinations 2>/dev/null

# Common destinations:
-destination "platform=iOS Simulator,name=iPhone 16 Pro"
-destination "platform=macOS"
-destination "platform=macOS,variant=Mac Catalyst"
```

Ensure device name matches `xcrun simctl list devices available` exactly.

## Signing Errors

**Error:** `Signing requires a development team` or `No signing certificate`

**Fix for simulator builds** (signing not required):
```bash
xcodebuild ... \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY="" \
  build
```

Note: Some entitlements (CloudKit, push) may require signing even for simulator.

## Missing Config Files

**Error:** `unable to open configuration settings file` (e.g., `Config.xcconfig`)

**Fix:**
```bash
grep -r "xcconfig" *.xcodeproj/project.pbxproj 2>/dev/null
find . -name "*.xcconfig.example" -maxdepth 3
```

If `.xcconfig.example` exists, the project needs a config file. Copy and fill
it in, or create a minimal placeholder. **Never read existing .xcconfig files**
— they may contain secrets.

## Package Resolution Failures

**Error:** `Package resolution failed`

**Fix:**
```bash
xcodebuild -resolvePackageDependencies \
  -project *.xcodeproj \
  -scheme "<Scheme>" 2>&1 | tail -10

# Or clean package caches:
rm -rf ~/Library/Developer/Xcode/DerivedData/*/SourcePackages
```

May take several minutes for projects with many Swift packages.

## Module Not Found

**Error:** `No such module 'SomeFramework'`

**Fix:** Clean and rebuild:
```bash
xcodebuild clean -scheme "<Scheme>" -derivedDataPath /tmp/xc-derived
xcodebuild -scheme "<Scheme>" -configuration Debug \
  -destination "platform=iOS Simulator,name=iPhone 16 Pro" \
  -derivedDataPath /tmp/xc-derived build 2>&1 | tail -20
```

## Build Timeout

Large Swift projects with many SPM dependencies can take 5-10 minutes for a
clean build.

- Set Bash timeout to **600000** (10 minutes) for clean builds
- Incremental builds after small changes: 10-60 seconds
- If timeout occurs, check if build partially succeeded:
```bash
find /tmp/xc-derived/Build/Products/ -name "*.app" -maxdepth 2
```

## Derived Data Issues

**WARNING: Do NOT delete DerivedData as a first resort.** Deleting DerivedData:
1. Usually doesn't fix the underlying problem
2. Breaks Xcode's Swift Package Manager resolution temporarily
3. Forces a full clean rebuild (5-10 minutes)

**Only if truly necessary:**
```bash
# Project-relative DerivedData (preferred path):
rm -rf DerivedData
# Or if using /tmp:
rm -rf /tmp/xc-derived
# Or if using default location:
rm -rf ~/Library/Developer/Xcode/DerivedData/<ProjectName>-*
```

**Prefer project-relative DerivedData** (`-derivedDataPath DerivedData`) over `/tmp/xc-derived`
for better cache persistence across sessions and worktree support.

## Workspace vs Project

- If `.xcworkspace` exists alongside `.xcodeproj`, **use the workspace**
- CocoaPods projects always require `-workspace`
- SPM-only projects typically work with `-project`

```bash
xcodebuild -workspace MyApp.xcworkspace -scheme MyApp ...
xcodebuild -project MyApp.xcodeproj -scheme MyApp ...
```

## App Crashes on Launch

Common causes:
1. **Missing config/secrets** — App needs runtime config (API keys, URLs)
2. **Missing entitlements** — CloudKit, push, etc.
3. **Wrong architecture** — Apple Silicon runs arm64 simulators by default

Check console output for crash reason:
```bash
xcrun simctl launch --console booted <bundle-id> 2>&1 | head -50
```
