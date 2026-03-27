# helixir-ralph-workflow

A Claude Code plugin that coordinates [flow-next](https://github.com/gmickel/flow-next) task management with [gstack](https://github.com/garrytan/gstack) quality gates into a single ralph workflow.

This is NOT a fork of either tool. It is a coordination layer that patches the default ralph templates with customized prompt files and quality gate integration.

## What it does

1. **Checks prerequisites** — verifies flow-next plugin and gstack skills are installed, installs them if not
2. **Patches ralph templates** — overwrites the default prompt templates with versions that integrate gstack quality gates
3. **Provides a setup skill** — `/helixir:setup` gets everything working on a new machine or project

## What's customized

### Per-task workflow (prompt_work.md)

The default flow-next work prompt is replaced with one that:

- Runs gstack `/review` (staff engineer code review) and `/design-review` (visual QA) after each task
- Writes the impl receipt AFTER quality gates pass, not before — if Claude gets rate-limited mid-quality-gate, the missing receipt causes ralph to retry the task on restart
- Resets tasks via `flowctl task reset` if quality gates find unfixable critical issues
- Defers UI verification (simulator build + screenshots) to epic completion to avoid redundant builds per task

### Epic completion (prompt_completion.md)

The default completion prompt is replaced with one that:

- Runs a two-pass validation sweep: cheap triage of all done tasks first, deep-check only suspects
- Builds for iOS Simulator and takes screenshots across all screens affected by the epic
- Resets suspect tasks that fail validation, causing ralph to re-implement them before returning to completion review

### Rate limit handling

Guidance for replacing the broken Codex CLI fallback in ralph.sh with a wait-and-retry approach. The original fallback used outdated CLI syntax and skipped quality gates.

## What comes from flow-next / gstack

- **flow-next** provides: ralph loop (`ralph.sh`), flowctl CLI, task/epic management, plan/work/review skills, RepoPrompt and Codex review integration
- **gstack** provides: `/review` (staff engineer code review), `/design-review` (visual QA), `/plan-design-review` (design audit)
- **This plugin** provides: the glue between them — customized prompts, receipt ordering, two-pass validation, deferred UI verification

## Installation

### Option A: ai-agent-skills

```bash
npx ai-agent-skills install ~/helixir-ralph-workflow
```

### Option B: Manual

Clone or copy this directory to `~/helixir-ralph-workflow/`, then register it as a Claude Code plugin.

## Usage

### First-time setup on a project

1. Make sure the project has ralph scaffolded:
   ```
   /flow-next:ralph-init
   ```

2. Run the setup skill:
   ```
   /helixir:setup
   ```
   Or run the script directly:
   ```bash
   ~/helixir-ralph-workflow/scripts/setup.sh /path/to/your/project
   ```

3. Configure your epic:
   ```bash
   cp ~/helixir-ralph-workflow/templates/config.env.example scripts/ralph/config.env
   # Edit EPICS= to match your target epic
   ```

4. Start ralph:
   ```bash
   scripts/ralph/ralph.sh
   ```

### After flow-next or gstack updates

Re-run the setup to re-patch the templates:
```bash
~/helixir-ralph-workflow/scripts/setup.sh /path/to/your/project
```

The setup script is idempotent — it overwrites the prompt files with the latest versions from this plugin.

## Symlinks: always use copies

Both gstack and flow-next skills MUST be installed as real file copies in `~/.claude/skills/`, not symlinks. Claude Code subagents cannot follow symlinks — they silently fail to read the skill files.

The setup script detects symlinks and converts them to copies automatically.

## Directory structure

```
~/helixir-ralph-workflow/
├── plugin.json              # Plugin manifest
├── README.md                # This file
├── skills/
│   └── helixir-setup/
│       └── SKILL.md         # /helixir:setup skill definition
├── templates/
│   ├── prompt_work.md       # Customized per-task prompt
│   ├── prompt_completion.md # Customized epic completion prompt
│   └── config.env.example   # Example ralph config
└── scripts/
    └── setup.sh             # Setup and patching script
```

## Rate limit handling

The default flow-next ralph.sh may include a Codex CLI fallback for rate limits. This fallback has known issues:

- Uses outdated `codex --approval-mode` syntax
- Sends a dumbed-down prompt that skips quality gates
- Can duplicate already-committed work

The recommended approach is wait-and-retry: when rate-limited, sleep for `RALPH_RATE_LIMIT_WAIT` seconds (default 300) and retry with Claude Code. The setup script detects the broken fallback and warns you if it's present.
