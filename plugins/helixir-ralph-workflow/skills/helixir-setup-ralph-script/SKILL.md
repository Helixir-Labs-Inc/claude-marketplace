---
description: Create a ralph script for a specific flow-next epic. Each epic gets its own isolated directory (scripts/ralph-<epic-slug>/) with its own config, templates, and run state — multiple can run in parallel. Use when starting work on a new epic.
---

# Setup Ralph Script

Creates an epic-specific ralph directory at `scripts/ralph-<epic-slug>/` with:
- Patched prompt templates (lead coordinator + parallel workers)
- Pre-filled config.env with the epic slug and app type
- Its own runs/ directory for isolated state

Multiple ralph scripts can run in parallel since each has its own directory.

## Usage

The skill needs the epic slug. Pass it as an argument:

```bash
${CLAUDE_PLUGIN_ROOT}/scripts/setup-ralph-script.sh <epic-slug> [project-dir] [app-type]
```

Examples:

```bash
# Web app epic (default)
${CLAUDE_PLUGIN_ROOT}/scripts/setup-ralph-script.sh fn-10-note-editor-redesign

# Native iOS/macOS app
${CLAUDE_PLUGIN_ROOT}/scripts/setup-ralph-script.sh fn-10-note-editor-redesign . native

# Different project directory
${CLAUDE_PLUGIN_ROOT}/scripts/setup-ralph-script.sh fn-5-auth-flow /path/to/project web
```

After setup:
```bash
scripts/ralph-fn-10-note-editor-redesign/ralph.sh
```

## Prerequisites

Run `/helixir:init-agent-skills` first if you haven't installed flow-next and gstack yet.

## Re-running

Safe to re-run on an existing directory — it re-patches templates and updates config without losing run state.
