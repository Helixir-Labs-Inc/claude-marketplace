---
description: Set up Helixir ralph workflow — installs flow-next, gstack, and patches ralph templates with lead coordinator pattern, parallel subagent workers, full quality pipeline, and integration testing. Use when starting a new project, setting up a new machine, or after flow-next updates.
---

# Helixir Ralph Script Setup

This is a single command that handles everything:
1. Verifies flow-next plugin is installed (tells you how to install if not)
2. Installs gstack skills if missing (as real copies, not symlinks)
3. Ensures all skills are real copies (converts any symlinks)
4. Scaffolds ralph via flow-next if the project doesn't have it yet
5. Patches the default ralph templates with the Helixir coordinator workflow
6. Ensures config.env has APP_TYPE and FEATURE_BRANCH_PREFIX fields

Run it:

```bash
${CLAUDE_PLUGIN_ROOT}/scripts/setup.sh
```

After setup, configure your epic in `scripts/ralph/config.env`:
```bash
EPICS=fn-1-your-epic-slug
APP_TYPE=native   # or "web"
```

Then start the ralph loop:
```bash
scripts/ralph/ralph.sh
```

## What this patches

The default flow-next ralph templates are replaced with a lead coordinator architecture:

### Per-task workflow (prompt_work.md)

The lead coordinator pattern:
- **Parallel task detection**: Reads all ready tasks, spawns Agent workers in worktrees for parallelizable work
- **Full quality pipeline per task**: /review -> /investigate (if bugs) -> /design-review -> /ui-verify-xcode (native) -> /qa
- **Always pushes**: Every commit gets pushed to origin (fixes the unpushed worktree commit bug)
- **Worker merge**: Parallel worker branches merged back into the feature branch
- **Receipt after quality gates**: Impl receipt written AFTER all quality gates pass

### Epic completion (prompt_completion.md)

The integration testing + shipping pipeline:
- **Two-pass task validation**: Cheap triage then deep-check suspects
- **Integration testing**: /browse (web) or /ui-verify-xcode (native) tests ALL features from the epic
- **Fix loop**: Finds issues -> spawns fix agents -> retests until clean
- **Security**: /cso full security audit
- **Documentation**: /document-release updates all docs
- **Codex review**: /codex second opinion on complete PR diff
- **Full PR review**: Dedicated agent reviews entire feature branch diff
- **Ship**: /ship creates PR against main

### Quality gate skills used

| Skill | When | Purpose |
|-------|------|---------|
| `/review` | Per task | Staff engineer code review |
| `/investigate` | When bugs suspected | Root cause analysis |
| `/design-review` | Per task | Visual design audit |
| `/ui-verify-xcode` | Per task (native) | iOS + macOS screenshot verification |
| `/qa` | Per task (web) | Systematic QA testing |
| `/browse` | Epic completion (web) | Integration testing |
| `/cso` | Epic completion | Security audit |
| `/document-release` | Epic completion | Documentation update |
| `/codex` | Epic completion | Final diff review |
| `/ship` | Epic completion | Create PR against main |

## Prerequisites

- **flow-next**: Claude Code plugin (marketplace: gmickel/flow-next)
- **gstack**: Quality gate skills (https://github.com/garrytan/gstack)
- Both must be installed as real file copies in `~/.claude/skills/`, NOT symlinks
