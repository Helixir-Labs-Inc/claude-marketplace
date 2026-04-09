# helixir-ralph-workflow

Autonomous lead coordinator workflow for [flow-next](https://github.com/gmickel/flow-next) + [gstack](https://github.com/garrytan/gstack). Spawns parallel subagent teams in worktrees, runs a full quality pipeline per task, and ships PRs with integration testing.

## Two ways to get oriented

- **`/helixir:whats-next`** — Dynamic advisor. Reads your live project state (epics, tasks, reviews run, scale) and recommends the best next skills to run. Use when you're mid-project, coming back after a break, or unsure what stage you're at.
- **`/helixir:how-to-use`** — Static reference guide. Setup steps, configuration options, architecture diagram, and troubleshooting. Use on first install or when you need to look something up.

## Quick start

```
/helixir:init-agent-skills          # Install prerequisites (once per machine)
/helixir:setup-ralph-script         # Create ralph script for an epic
scripts/ralph-<epic-slug>/ralph.sh  # Run it
```

## Architecture

```
ralph.sh (loop) -> Lead Coordinator (Claude session)
                    |-- Reads all ready tasks for epic
                    |-- Spawns parallel Agent workers in worktrees
                    |     |-- Worker A: implement -> review -> investigate -> design-review -> ui-verify -> qa -> push
                    |     |-- Worker B: implement -> review -> investigate -> design-review -> ui-verify -> qa -> push
                    |     +-- Worker C: ...
                    |-- Merges worker branches -> feature branch -> push
                    +-- Writes receipts for completed tasks

                  Epic Completion (after all tasks done)
                    |-- Per-task validation sweep (two-pass)
                    |-- Integration test ALL features: /browse (web) or /ui-verify-xcode (native)
                    |-- Fix loop: find issues -> spawn fix agents -> retest
                    |-- /cso (security audit)
                    |-- /document-release (docs update)
                    |-- /codex (final diff review)
                    |-- Full PR review agent
                    +-- /ship (create PR against main)
```

## Parallel epics

Each epic gets its own isolated ralph directory:

```
scripts/
  ralph-fn-10-note-editor/     # Terminal 1
  ralph-fn-11-calendar-sync/   # Terminal 2
  ralph-fn-12-auth-flow/       # Terminal 3
```

No conflicts — each has its own config, templates, runs/, and state.

## Skills

| Skill | Purpose |
|-------|---------|
| `/helixir:whats-next` | Dynamic advisor — reads live project state and recommends what to do next. |
| `/helixir:init-agent-skills` | Install prerequisites (flow-next, gstack). Once per machine. |
| `/helixir:setup-ralph-script` | Create a ralph script for a specific epic. Per epic. |
| `/helixir:how-to-use` | Static reference — setup guide, config options, architecture, troubleshooting. |

## Prerequisites

- **flow-next**: Claude Code plugin (marketplace: gmickel/flow-next)
- **gstack**: Quality gate skills (https://github.com/garrytan/gstack)
- Both must be installed as real file copies in `~/.claude/skills/`, NOT symlinks
