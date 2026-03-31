---
description: Explains how to set up and use the helixir-ralph-workflow plugin. Run this on first install or when you need a refresher on the workflow, configuration, or available skills.
---

# How to Use helixir-ralph-workflow

## Response instructions

If this skill is invoked without a specific question, respond with the summary below verbatim (the "Default response" section). If the user asks a specific question about the workflow, answer it directly using the detailed reference that follows.

---

## Default response

The helixir-ralph-workflow is an autonomous build pipeline that executes flow-next epics end-to-end with minimal human intervention. Here's how it works:

### The Big Picture

You define an epic (a feature broken into tasks via `/flow-next:plan`), then ralph runs a loop that picks up tasks, builds them, reviews them, and ships a PR — all autonomously.

### The Flow

1. You plan an epic using `/flow-next:plan` — this creates structured tasks in `.flow/`
2. You create a ralph script for that epic (`/helixir:setup-ralph-script`) — this generates an isolated directory with config and templates
3. You start the ralph loop (`scripts/ralph-<epic>/ralph.sh`) — then walk away

### What Ralph Does Per Task

For each ready task, the coordinator:

1. Spawns worker agents (in parallel if tasks have no conflicts)
2. Each worker runs a quality pipeline:
   - Implement — builds the feature
   - Code review — finds bugs
   - Debug — root cause analysis if bugs found
   - Design review — visual quality audit
   - Visual verify — screenshots (iOS/macOS for native apps)
   - QA — systematic testing
3. Workers commit and push
4. Coordinator merges worker branches into the feature branch

### After All Tasks Complete

Ralph runs an epic-level quality pass: integration testing, security audit, documentation updates, final review, then creates a PR.

### Key Details

- Parallel execution — multiple tasks with no dependency conflicts run simultaneously in git worktrees
- Self-correcting — if review finds bugs, it spawns fix agents and retests
- Configurable — `APP_TYPE=native|web` controls which quality gates run (e.g., Xcode screenshots vs browser QA)
- Controllable — pause/resume/stop with touch files while it's running
- Isolated — each epic gets its own directory, so you can run multiple epics in parallel across terminals

### Setup Steps

1. `/helixir:init-agent-skills` — one-time prerequisite install
2. `/flow-next:plan` — plan your epic
3. `/helixir:setup-ralph-script` — create the ralph script for that epic
4. Run `scripts/ralph-<epic>/ralph.sh` — start the autonomous loop

Want to plan an epic and set this up?

---

## Detailed reference

The sections below provide full details for answering specific questions.

### First-time setup

#### 1. Install prerequisites

```
/helixir:init-agent-skills
```

This installs flow-next and gstack, converts symlinks to real copies. Idempotent — skips anything already installed.

#### 2. Create a ralph script for your epic

```
/helixir:setup-ralph-script
```

Pass the epic slug as an argument. This creates `scripts/ralph-<epic-slug>/` with:
- Patched prompt templates (coordinator workflow)
- Pre-filled config.env
- Isolated run state

Example:
```bash
${CLAUDE_PLUGIN_ROOT}/scripts/setup-ralph-script.sh fn-10-note-editor-redesign . native
```

#### 3. Configure (optional)

Edit `scripts/ralph-<epic-slug>/config.env` to adjust:

```bash
APP_TYPE=native        # "web" for React/Next.js, "native" for Swift iOS/macOS
WORK_REVIEW=codex      # codex, rp, or none
COMPLETION_REVIEW=codex
```

#### 4. Start the ralph loop

```bash
scripts/ralph-<epic-slug>/ralph.sh
```

---

### Running multiple epics in parallel

Each epic gets its own ralph directory with isolated state:

```bash
# Terminal 1
scripts/ralph-fn-10-note-editor/ralph.sh

# Terminal 2
scripts/ralph-fn-11-calendar-sync/ralph.sh
```

No conflicts — each has its own config, templates, runs/, and state.

---

### How it works

#### Per-task (the coordinator handles this)

Each ralph iteration, the lead coordinator:

1. Reads all ready tasks for the epic
2. If multiple tasks have no dependency conflicts, spawns **parallel Agent workers in worktrees**
3. Each worker runs the full quality pipeline:

| Step | Skill | Purpose |
|------|-------|---------|
| Implement | `/flow-next:work` | Build the feature |
| Code review | `/review` | Find production bugs |
| Debug | `/investigate` | Root cause analysis (if bugs found) |
| Design review | `/design-review` | Visual quality audit |
| Visual verify | `/ui-verify-xcode` | iOS + macOS screenshots (native only) |
| QA | `/qa` | Systematic testing |

4. Workers commit and **push** to origin
5. Coordinator merges worker branches into the feature branch

#### Epic completion (after all tasks done)

| Step | Skill | Purpose |
|------|-------|---------|
| Validate tasks | flowctl | Two-pass: cheap triage, then deep-check suspects |
| Integration test | `/browse` or `/ui-verify-xcode` | Test ALL features together (catches merge breakage) |
| Fix loop | Agent spawning | Find issues -> fix agents -> retest until clean |
| Security audit | `/cso` | Secrets, dependencies, OWASP, STRIDE |
| Documentation | `/document-release` | Update README, CHANGELOG, CLAUDE.md |
| Final review | `/codex` | Second opinion on complete diff |
| PR review | Agent | Comprehensive review of full feature branch |
| Ship | `/ship` | Create PR against main |

---

### Skills reference

| Skill | Purpose |
|-------|---------|
| `/helixir:init-agent-skills` | Install prerequisites (flow-next, gstack). Run once per machine. |
| `/helixir:setup-ralph-script` | Create a ralph script for a specific epic. Run per epic. |
| `/how-to-use` | This guide. |

---

### Configuration reference

| Variable | Values | Default | Purpose |
|----------|--------|---------|---------|
| `EPICS` | epic slug | required | Target epic |
| `APP_TYPE` | `native`, `web` | `web` | Controls quality gates |
| `FEATURE_BRANCH_PREFIX` | string | `feature/` | Branch naming |
| `BRANCH_MODE` | `current`, `new` | `current` | How ralph manages branches |
| `WORK_REVIEW` | `codex`, `rp`, `none` | `codex` | Per-task review backend |
| `COMPLETION_REVIEW` | `codex`, `rp`, `none` | `codex` | Epic completion review backend |
| `MAX_ITERATIONS` | number | `25` | Max ralph loop iterations |
| `MAX_ATTEMPTS_PER_TASK` | number | `5` | Retry limit per task |
| `YOLO` | `0`, `1` | `1` | Skip permission prompts |
| `RALPH_RATE_LIMIT_WAIT` | seconds | `300` | Pause on rate limit |

---

### Controlling ralph

While ralph is running:

- **Pause**: `touch scripts/ralph-<epic-slug>/PAUSE`
- **Resume**: `rm scripts/ralph-<epic-slug>/PAUSE`
- **Stop**: `touch scripts/ralph-<epic-slug>/STOP`
- **Logs**: `scripts/ralph-<epic-slug>/runs/<RUN_ID>/`

---

### Troubleshooting

**Commits not being pushed?** Re-run `/helixir:setup-ralph-script` to re-patch the templates. The v2.0 templates explicitly push after every commit.

**Skills not loading in subagents?** Skills must be real file copies in `~/.claude/skills/`, not symlinks. Run `/helixir:init-agent-skills` to auto-convert.

**Tasks stuck in retry loop?** Check `scripts/ralph-<epic-slug>/runs/<RUN_ID>/attempts.json`. After `MAX_ATTEMPTS_PER_TASK` failures, the task gets blocked. Review the block file for context.

**Rate limited?** Ralph automatically waits `RALPH_RATE_LIMIT_WAIT` seconds (default 300) and retries.
