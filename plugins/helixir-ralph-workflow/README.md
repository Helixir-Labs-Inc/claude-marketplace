# helixir-ralph-workflow

A Claude Code plugin that coordinates [flow-next](https://github.com/gmickel/flow-next) task management with [gstack](https://github.com/garrytan/gstack) quality gates into an autonomous lead coordinator workflow.

This is NOT a fork of either tool. It is a coordination layer that patches the default ralph templates with a lead coordinator architecture that spawns parallel subagent teams, runs a full quality pipeline per task, and ships PRs with integration testing.

## Architecture

```
ralph.sh (loop) → Lead Coordinator (Claude session)
                    ├── Reads all ready tasks for epic
                    ├── Spawns parallel Agent workers in worktrees
                    │     ├── Worker A: implement → /review → /investigate → /design-review → /ui-verify-xcode → /qa → push
                    │     ├── Worker B: implement → /review → /investigate → /design-review → /ui-verify-xcode → /qa → push
                    │     └── Worker C: ...
                    ├── Merges worker branches → feature branch → push
                    └── Writes receipts for completed tasks

                  Epic Completion (after all tasks done)
                    ├── Per-task validation sweep (two-pass)
                    ├── Integration test ALL features: /browse (web) or /ui-verify-xcode (native)
                    ├── Fix loop: find issues → spawn fix agents → retest
                    ├── /cso (security audit)
                    ├── /document-release (docs update)
                    ├── /codex (final diff review)
                    ├── Full PR review agent
                    └── /ship (create PR against main)
```

## Per-task quality pipeline

Every task goes through these gates, whether executed by the coordinator directly or by a parallel subagent:

1. **Implement** — `/flow-next:work` executes the task
2. **Code Review** — `/review` finds production bugs
3. **Root Cause** — `/investigate` when bugs are suspected (no guessing at fixes)
4. **Design Review** — `/design-review` audits visual quality
5. **Visual Verify** — `/ui-verify-xcode` screenshots iOS + macOS (native apps only)
6. **QA** — `/qa` (web) or `/qa` methodology via `/ui-verify-xcode` (native)
7. **Push** — every commit pushed to origin

## Epic completion pipeline

After all tasks are done:

1. **Validate** — two-pass sweep of all done tasks (cheap triage, deep-check suspects)
2. **Integration test** — `/browse` (web) or `/ui-verify-xcode` (native) tests ALL epic features
3. **Fix loop** — issues documented → fix agents spawned → retest until clean
4. **Security** — `/cso` full audit (secrets, dependencies, OWASP, STRIDE)
5. **Documentation** — `/document-release` updates all project docs
6. **Codex** — `/codex` second opinion on complete PR diff
7. **PR Review** — dedicated agent reviews entire feature branch
8. **Ship** — `/ship` creates PR against main

## Installation

### Option A: ai-agent-skills

```bash
npx ai-agent-skills install ~/helixir-ralph-workflow
```

### Option B: Manual

Clone or copy this directory, then register it as a Claude Code plugin.

## Usage

### First-time setup on a project

1. Scaffold ralph if the project doesn't have it:
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

3. Configure your epic in `scripts/ralph/config.env`:
   ```bash
   EPICS=fn-1-your-epic-slug
   APP_TYPE=native   # "native" for Swift iOS/macOS, "web" for React/Next.js
   ```

4. Start ralph:
   ```bash
   scripts/ralph/ralph.sh
   ```

### After flow-next or gstack updates

Re-run setup to re-patch the templates:
```bash
~/helixir-ralph-workflow/scripts/setup.sh /path/to/your/project
```

## Configuration

| Variable | Values | Default | Purpose |
|----------|--------|---------|---------|
| `EPICS` | epic slug | — | Target epic(s) |
| `APP_TYPE` | `native`, `web` | `web` | Controls quality gates: native uses /ui-verify-xcode, web uses /browse and /qa |
| `FEATURE_BRANCH_PREFIX` | string | `feature/` | Prefix for feature branches |
| `BRANCH_MODE` | `current`, `new` | `current` | How ralph manages branches |
| `WORK_REVIEW` | `codex`, `rp`, `none` | `codex` | Per-task review backend |
| `COMPLETION_REVIEW` | `codex`, `rp`, `none` | `codex` | Epic completion review backend |
| `MAX_ITERATIONS` | number | `25` | Max ralph loop iterations |
| `MAX_ATTEMPTS_PER_TASK` | number | `5` | Retry limit per task |
| `YOLO` | `0`, `1` | `1` | Skip permission prompts |

## Symlinks: always use copies

Both gstack and flow-next skills MUST be installed as real file copies in `~/.claude/skills/`, not symlinks. Claude Code subagents cannot follow symlinks — they silently fail to read skill files.

The setup script detects symlinks and converts them to copies automatically.

## Directory structure

```
helixir-ralph-workflow/
├── .claude-plugin/
│   └── plugin.json              # Plugin manifest
├── README.md                    # This file
├── skills/
│   └── helixir-setup-ralph-script/
│       └── SKILL.md             # /helixir:setup skill definition
├── templates/
│   ├── prompt_work.md           # Lead coordinator + parallel workers
│   ├── prompt_completion.md     # Integration testing + security + docs + ship
│   └── config.env.example       # Example ralph config
└── scripts/
    └── setup.sh                 # Setup and patching script
```
