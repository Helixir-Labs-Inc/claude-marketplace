# Xcode Native Toolkit

Native iOS/macOS development skills for Claude Code. Three skills covering the full UI verification pipeline for Swift/SwiftUI apps.

## Skills

| Skill | Purpose | Speed |
|-------|---------|-------|
| `/ui-preview` | Quick SwiftUI preview via Xcode MCP `RenderPreview` | Seconds |
| `/ui-verify-xcode` | Simulator integration testing with video recording | Minutes |
| `/qa-xcode` | Systematic native QA with structured reports | Minutes |

## Prerequisites

- macOS with Xcode 26.3+
- Xcode MCP bridge: `claude mcp add --transport stdio xcode -- xcrun mcpbridge`
- Xcode Settings > Intelligence > "Xcode Tools" enabled
- CLI tools: `brew install xcsift imagemagick axe`
- `ffmpeg` for video frame extraction: `brew install ffmpeg`

## How the skills relate

```
Code change
    │
    ▼
/ui-preview          ← Quick visual check (no build needed)
    │                   RenderPreview for each changed SwiftUI view
    │                   Batch, fix, re-preview until all views pass
    ▼
/ui-verify-xcode     ← Simulator integration (build required)
    │                   Video record user flows, extract frames
    │                   Verify navigation, animations, transitions
    ▼
/qa-xcode            ← Systematic QA (build required)
                        Test all acceptance criteria and edge cases
                        Atomic fix commits, health score, structured report
```

## Ralph Integration

When used with the `helixir-ralph-workflow` plugin (`APP_TYPE=native`):

| Ralph Step | Skill | Condition |
|------------|-------|-----------|
| W4 | `/ui-preview` | Every native task |
| W4b | `/ui-verify-xcode` | Only if navigation/animation changed |
| W5 | `/qa-xcode` | Every native task |
| Completion Step 4 | `/qa-xcode --exhaustive` | Epic integration test |

## Standalone Usage

Each skill works independently:

```
# Quick check after editing a view
/ui-preview

# Test navigation flow in simulator
/ui-verify-xcode

# Full QA pass before shipping
/qa-xcode
```
