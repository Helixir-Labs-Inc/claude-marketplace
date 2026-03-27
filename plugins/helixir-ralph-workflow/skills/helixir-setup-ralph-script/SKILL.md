---
description: Set up Helixir ralph workflow — installs flow-next, gstack, and patches ralph templates with quality-gated execution pipeline. Use when starting a new project, setting up a new machine, or after flow-next updates.
---

# Helixir Ralph Script Setup

This is a single command that handles everything:
1. Verifies flow-next plugin is installed (tells you how to install if not)
2. Installs gstack skills if missing (as real copies, not symlinks)
3. Ensures all skills are real copies (converts any symlinks)
4. Scaffolds ralph via flow-next if the project doesn't have it yet
5. Patches the default ralph templates with the Helixir workflow

Run it:

```bash
${CLAUDE_PLUGIN_ROOT}/scripts/setup.sh
```

After setup, configure your epic in `scripts/ralph/config.env`:
```bash
EPICS=fn-1-your-epic-slug
```

Then start the ralph loop:
```bash
scripts/ralph/ralph.sh
```

## What this patches

The default flow-next ralph templates are patched with:

### Per-task workflow (prompt_work.md)
- **Receipt after quality gates**: The impl receipt is written AFTER `/review` and `/design-review` pass, not before. If Claude gets rate-limited during quality gates, the missing receipt causes ralph to reset and retry the task.
- **gstack quality gates**: `/review` (staff engineer code review) and `/design-review` (visual QA) run after each task implementation.
- **Task reset on failure**: If quality gates find unfixable issues, the task is reset to `todo` via `flowctl task reset`.
- **No per-task UI verification**: Simulator builds are deferred to epic completion to avoid redundant builds.

### Epic completion (prompt_completion.md)
- **Two-pass validation sweep**: Quick triage of all done tasks (1 command each), deep-check only suspects. Catches tasks marked done prematurely without burning tokens on obviously-complete work.
- **Build verification**: Single iOS Simulator build + screenshot pass across all epic screens.
- **Task reset loop**: Suspect tasks that fail validation are reset, ralph re-implements them, then returns to completion review.

### Rate limit handling (ralph.sh guidance)
- Broken Codex CLI fallback removed (used wrong syntax, skipped quality gates)
- Wait-and-retry on rate limit (300s default, configurable)

## Prerequisites

- **flow-next**: Claude Code plugin (marketplace: gmickel/flow-next)
- **gstack**: Quality gate skills (https://github.com/garrytan/gstack)
- Both must be installed as real file copies in `~/.claude/skills/`, NOT symlinks
