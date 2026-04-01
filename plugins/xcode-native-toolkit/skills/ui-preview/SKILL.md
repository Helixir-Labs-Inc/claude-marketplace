---
name: ui-preview
description: >-
  Quick SwiftUI preview check using Xcode MCP RenderPreview. Lightweight,
  ad-hoc skill for verifying visual appearance of SwiftUI views without
  building or launching the app. Seconds per cycle. Use during coding to
  check if a view looks right, after tweaking layout/colors/spacing, or
  to batch-check all changed views before committing. Triggers on: "preview
  this view", "does this look right", "check the preview", "render preview",
  "quick visual check", "how does it look", "show me the view", "preview
  check", "ui-preview". Does NOT test navigation, animations, or runtime
  behavior — use /ui-verify-xcode for that.
---

# UI Preview — Quick SwiftUI Visual Check

Render SwiftUI `#Preview` blocks via Xcode MCP to verify appearance without
building or launching. Seconds per cycle. Use ad-hoc during coding.

**Not for:** navigation testing, animations, runtime behavior, multi-step flows.
Use `/ui-verify-xcode` for those.

## Requirements

- Xcode open with the project loaded
- Xcode MCP bridge connected
- Views must have `#Preview` blocks

## The Loop

```
1. Identify changed SwiftUI view files
2. For each view with a #Preview block:
   a. RenderPreview → read the rendered image
   b. Assess against checklist below
   c. If issues found → fix code → RenderPreview again
   d. Repeat until view passes
3. Next view
4. Done when all views pass
```

**Batch aggressively.** Changed 4 views? Preview all 4, collect all issues,
fix them all at once, then re-preview — don't fix one at a time.

## Assessment Checklist

For each preview, check:

1. **Layout** — Elements positioned correctly? No overlap or clipping?
2. **Spacing** — Consistent with design system (4pt grid)? Edge padding correct?
3. **Typography** — Hierarchy clear? No truncation? Correct weights/sizes?
4. **Colors** — Match design tokens? Sufficient contrast? No pure black/white?
5. **Icons** — SF Symbols? Proportional to text? Semantic colors?
6. **Safe areas** — Respects notch, home indicator, status bar?
7. **Empty/loading states** — If the preview shows these, do they look right?

If the project has a DESIGN.md, check against it.

## MCP Tools

| Tool | Purpose |
|------|---------|
| `RenderPreview` | Render a view's `#Preview` block |
| `DocumentationSearch` | Verify an Apple API name before using it |
| `ExecuteSnippet` | Test a Swift expression in REPL |
| `XcodeListNavigatorIssues` | Check for compiler errors without full build |
| `XcodeRefreshCodeIssuesInFile` | Get live diagnostics for a specific file |

## When Xcode MCP Is Unavailable

If `RenderPreview` fails (Xcode not open, MCP not connected), fall back to:
1. `BuildProject` or shell build
2. Install → launch → screenshot → assess
3. This is much slower — suggest the user open Xcode

## Tips

- All new SwiftUI views MUST include a `#Preview` block
- Multiple `#Preview` blocks per file are fine (light/dark, different data states)
- If a view needs runtime data, create a preview with mock data
- Don't skip previews for "simple" views — they catch spacing/color issues fast
