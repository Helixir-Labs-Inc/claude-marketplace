# Helixir Labs — Claude Code Plugin Marketplace

Claude Code plugins built by [Helixir Labs](https://helixirlabs.com) for autonomous software development, personal knowledge management, and native app quality assurance.

## Plugins

| Plugin | Version | Description |
|--------|---------|-------------|
| [helixir-ralph-workflow](plugins/helixir-ralph-workflow/) | 2.1.0 | Autonomous build pipeline — plan epics, execute tasks, and ship PRs with parallel subagents and automated quality gates |
| [personal-knowledge-assistant](plugins/personal-knowledge-assistant/) | 0.2.0 | Agent-native PKM with ADHD-friendly planning, inbox triage, and scheduled reviews |
| [xcode-native-toolkit](plugins/xcode-native-toolkit/) | 1.0.0 | Native iOS/macOS UI verification pipeline — SwiftUI previews, simulator testing, and systematic QA |

---

## helixir-ralph-workflow

The flagship plugin. It connects two open-source Claude Code skill systems — **flow-next** (task planning and tracking) and **gstack** (browser-based QA and code review) — into an autonomous build pipeline called **Ralph**. You plan your work as an epic, generate a ralph script, start it, and walk away. Ralph executes each task, reviews its own code, runs QA, and ships a PR when the epic is complete.

### Prerequisites

Before using this plugin, you need two external plugins installed:

1. **flow-next** by Gordon Mickel — task planning, epic tracking, and the base Ralph loop
   ```bash
   claude /install-marketplace github:gmickel/gmickel-claude-marketplace
   claude /install-plugin gmickel:flow-next
   ```

2. **gstack** by Garry Tan — code review, QA testing, security audits, and browser automation
   ```bash
   # Installed via the init script (see below), not as a Claude plugin
   ```

Run the init script to install and configure everything:
```
/helixir:init-agent-skills
```

This checks that flow-next is installed, clones gstack if missing, converts symlinked skills to real file copies (required for subagents), and installs xcode-native-toolkit skills for native projects.

### How it works

The workflow has three phases: **Plan**, **Setup**, and **Execute**.

#### Phase 1: Plan your epic

Use flow-next to create a structured plan from a feature request:

```
/flow-next:plan Add OAuth login with Google and GitHub providers
```

This researches your codebase, creates an epic (e.g., `fn-1-add-oauth`), and generates individual task files in `.flow/` with specs, acceptance criteria, and dependency ordering.

Review the plan:
```
/flow-next:plan-review    # Carmack-level architectural review
/flow-next                # Quick list of all tasks and statuses
```

Optionally refine requirements interactively:
```
/flow-next:interview fn-1-add-oauth    # 40+ question deep-dive
```

#### Phase 2: Set up the Ralph script

Generate an isolated ralph directory for your epic:

```
/helixir:setup-ralph-script fn-1-add-oauth
```

This creates `scripts/ralph-fn-1-add-oauth/` containing:

```
scripts/ralph-fn-1-add-oauth/
  ralph.sh              # The autonomous loop script
  config.env            # Epic config (app type, review backends, limits)
  prompt_work.md        # Lead coordinator template (per-task pipeline)
  prompt_completion.md  # Epic completion template (integration + ship)
  .gitignore
```

Edit `config.env` to customize behavior:

```bash
EPICS="fn-1-add-oauth"       # Target epic(s)
APP_TYPE="web"                # "web" or "native" — controls which QA tools run
WORK_REVIEW="codex"           # Per-task review: codex, rp, or none
COMPLETION_REVIEW="codex"     # Epic completion review backend
MAX_ITERATIONS=25             # Max ralph loop iterations
MAX_ATTEMPTS_PER_TASK=5       # Retry limit per task
YOLO=1                        # Skip permission prompts (autonomous mode)
```

#### Phase 3: Execute

Start the ralph loop and walk away:

```bash
scripts/ralph-fn-1-add-oauth/ralph.sh
```

Ralph spawns a fresh Claude Code session for each iteration. Each session:

1. **Finds ready tasks** — checks `.flow/` for tasks with all dependencies met
2. **Spawns parallel workers** — if multiple tasks are ready, runs them simultaneously in git worktrees
3. **Executes the Worker Pipeline (W1–W6) per task:**
   - **W1: Implement** — runs `/flow-next:work` to build the feature
   - **W2: Code Review** — runs `/review` (gstack) for staff-engineer-level review, `/investigate` if bugs found
   - **W3: Design Review** — runs `/design-review` (gstack) for visual quality audit
   - **W4: Visual Preview** — (native only) `/ui-preview` + `/ui-verify-xcode` for simulator testing with video
   - **W5: QA Verification** — `/qa` (web) or `/qa-xcode` (native) for systematic testing
   - **W6: Commit and push** — pushes to origin after each task
4. **Writes implementation receipts** — proof-of-work that gates the next task

When all tasks are done, Ralph runs the **Epic Completion Pipeline:**

1. Two-pass task validation (quick triage, then deep check of suspect tasks)
2. Integration testing of all features together
3. Security audit (`/cso` — secrets, dependencies, OWASP, STRIDE)
4. Documentation update (`/document-release`)
5. Cross-model code review (`/codex`)
6. Full PR review of the entire feature branch
7. Ships the PR (`/ship`)
8. Epic completion review gate (`/flow-next:epic-review`)

### Controlling Ralph at runtime

```bash
# Pause (finish current task, then wait)
touch scripts/ralph-fn-1-add-oauth/PAUSE

# Resume
rm scripts/ralph-fn-1-add-oauth/PAUSE

# Stop (finish current task, then exit)
touch scripts/ralph-fn-1-add-oauth/STOP
```

Logs for each run are saved in `scripts/ralph-fn-1-add-oauth/runs/<RUN_ID>/`.

### Running multiple epics in parallel

Each epic gets its own isolated ralph directory. You can run multiple simultaneously in separate terminals:

```bash
# Terminal 1
scripts/ralph-fn-1-add-oauth/ralph.sh

# Terminal 2
scripts/ralph-fn-2-dashboard-redesign/ralph.sh
```

### Available skills

| Skill | Description |
|-------|-------------|
| `/helixir:init-agent-skills` | Install flow-next + gstack prerequisites. Run once per machine. |
| `/helixir:setup-ralph-script` | Create a ralph script for a specific epic. Safe to re-run. |
| `/helixir:how-to-use` | Show usage instructions and workflow overview. |

### Quick start (end to end)

```bash
# 1. Install the marketplace and plugin
claude /install-marketplace github:Helixir-Labs-Inc/claude-marketplace
claude /install-plugin helixir-labs-inc:helixir-ralph-workflow

# 2. Install prerequisites (flow-next + gstack)
#    In Claude Code:
/helixir:init-agent-skills

# 3. Plan your work
/flow-next:plan <describe your feature>

# 4. Review the plan
/flow-next:plan-review

# 5. Generate the ralph script
/helixir:setup-ralph-script fn-1-your-epic-slug

# 6. (Optional) Edit config.env to set APP_TYPE, review backends, etc.

# 7. Start the autonomous loop
#    In your terminal:
scripts/ralph-fn-1-your-epic-slug/ralph.sh

# 8. Come back to a PR
```

---

## personal-knowledge-assistant

An agent-native personal knowledge management system designed for people with ADHD. Runs from a dedicated PKA folder as a persistent Claude Code session and manages notes, files, calendar, email, and daily workflows.

### Skills

| Skill | Schedule | Description |
|-------|----------|-------------|
| `/morning-planning` | 8:30am Mon–Fri | Calendar review, email scan, pick top 3 focus items |
| `/daily-review` | 4:00pm Mon–Thu | What got done, what's in progress, segmented by domain |
| `/weekly-review` | 4:00pm Friday | Week retrospective, goals progress, next week preview |
| `/next-3` | On demand | Clear current batch, get next 3 focus items |
| `/triage-inbox` | On demand | Process inbox files and Downloads — rename, tag, and file |
| `/boss-update` | On demand | Draft a Slack DM progress update (daily or weekly) |
| `/pka-setup` | One-time | Interactive setup interview for new users |

### Agents

- **pkm-assistant** — always-on companion for notes, file search, goal tracking, and proactive nudges
- **inbox-watcher** — lightweight haiku-based monitor that watches inbox folders for new files

### Quick start

```bash
# Install
claude /install-plugin helixir-labs-inc:personal-knowledge-assistant

# Run the setup interview
/pka-setup

# Start a persistent PKA session
cd ~/pka && claude

# Begin your day
/morning-planning
```

---

## xcode-native-toolkit

UI verification pipeline for native iOS/macOS apps built with Swift and SwiftUI. Three skills that form a progressive verification chain: quick preview, simulator testing, and systematic QA.

| Skill | What it does | Speed |
|-------|-------------|-------|
| `/ui-preview` | Renders SwiftUI previews via Xcode MCP without building | Seconds |
| `/ui-verify-xcode` | Builds, installs in simulator, records video of user flows | Minutes |
| `/qa-xcode` | Systematic QA testing with structured bug reports and fix loop | Minutes |

**Verification pipeline:** Code change → `/ui-preview` (no build) → `/ui-verify-xcode` (build + simulator) → `/qa-xcode` (full QA)

**Requirements:** macOS with Xcode 26.3+, Xcode MCP bridge, and CLI tools (xcsift, imagemagick, axe, ffmpeg).

When used with `helixir-ralph-workflow` and `APP_TYPE=native`, these skills are automatically invoked during the W4 and W5 pipeline stages.

---

## Install

Add the marketplace:
```bash
claude /install-marketplace github:Helixir-Labs-Inc/claude-marketplace
```

Install individual plugins:
```bash
claude /install-plugin helixir-labs-inc:helixir-ralph-workflow
claude /install-plugin helixir-labs-inc:personal-knowledge-assistant
claude /install-plugin helixir-labs-inc:xcode-native-toolkit
```

## License

MIT
