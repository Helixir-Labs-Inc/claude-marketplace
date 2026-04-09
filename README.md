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

Review the plan — pick the review that matches what you're building:

```
/flow-next:plan-review       # Carmack-level architectural review (flow-next built-in)
/autoplan                    # Full auto-review: runs CEO → design → eng → DX sequentially
/plan-ceo-review             # Rethink the problem — find the 10-star product hiding in the request
/plan-eng-review             # Lock in architecture, data flow, edge cases, and test plan
/plan-design-review          # Rate each design dimension 0-10, then fix the plan to hit 10s
/plan-devex-review           # Developer experience audit — personas, TTHW benchmarks, friction points
/flow-next                   # Quick list of all tasks and statuses
```

**Which review should you use?**

| Building for... | Plan review (before code) | Live audit (after shipping) |
|----------------|--------------------------|----------------------------|
| End users (UI, web app, mobile) | `/plan-design-review` | `/design-review` |
| Developers (API, CLI, SDK, docs) | `/plan-devex-review` | `/devex-review` |
| Architecture (data flow, perf, tests) | `/plan-eng-review` | `/review` |
| All of the above | `/autoplan` | — |

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
| `/helixir:whats-next` | Intelligent next-step advisor — reads epic state, scale, and review history, then suggests the best skills to run next. Start here if you're unsure. |
| `/helixir:init-agent-skills` | Install flow-next + gstack prerequisites. Run once per machine. |
| `/helixir:setup-ralph-script` | Create a ralph script for a specific epic. Safe to re-run. |
| `/helixir:how-to-use` | Show usage instructions and workflow overview. |

### gstack skills — the full development lifecycle

gstack ([github.com/garrytan/gstack](https://github.com/garrytan/gstack)) provides specialist skills for every stage of development. Each skill feeds into the next — outputs from one become inputs to the next. Ralph automates this pipeline, but you can also run any skill manually.

**Think → Plan → Build → Review → Test → Ship → Reflect**

#### Think — Frame the problem before writing code

| Skill | Specialist | What it does |
|-------|-----------|-------------|
| `/office-hours` | YC Office Hours | Six forcing questions that reframe your product. Challenges premises, generates alternatives. Outputs a design doc that feeds into every downstream review. |
| `/design-consultation` | Design Partner | Build a complete design system from scratch. Researches the landscape, proposes creative risks, generates realistic product mockups. |
| `/design-shotgun` | Design Explorer | Generates 4-6 AI mockup variants, opens a comparison board in your browser, collects feedback, and iterates until you love something. |

#### Plan — Review and lock in the approach

| Skill | Specialist | What it does |
|-------|-----------|-------------|
| `/plan-ceo-review` | CEO / Founder | Rethink the problem. Find the 10-star product. Four modes: Expansion, Selective Expansion, Hold Scope, Reduction. |
| `/plan-eng-review` | Eng Manager | Lock in architecture, data flow, edge cases, and test plan. Forces hidden assumptions into the open. |
| `/plan-design-review` | Senior Designer | Rates each design dimension 0-10, explains what a 10 looks like, then edits the plan to get there. AI Slop detection. |
| `/plan-devex-review` | DX Lead | Explores developer personas, benchmarks against competitors, designs your magical moment, traces friction points. 20-45 forcing questions. |
| `/autoplan` | Review Pipeline | One command — runs CEO → design → eng → DX review sequentially with encoded decision principles. Surfaces only taste decisions for your approval. |

#### Build — Implement with quality gates

| Skill | Specialist | What it does |
|-------|-----------|-------------|
| `/design-html` | Design Engineer | Turn a mockup into production HTML. Pretext computed layout, 30KB, zero deps. Detects React/Svelte/Vue. Output is shippable, not a demo. |
| `/browse` | QA Engineer | Real Chromium browser — real clicks, real screenshots, ~100ms per command. |
| `/pair-agent` | Multi-Agent Coordinator | Share your browser with any AI agent. One command, one paste, connected. Works with OpenClaw, Hermes, Codex, Cursor. |

#### Review — Catch bugs before they ship

| Skill | Specialist | What it does |
|-------|-----------|-------------|
| `/review` | Staff Engineer | Find bugs that pass CI but blow up in production. Auto-fixes the obvious ones. Flags completeness gaps. |
| `/investigate` | Debugger | Systematic root-cause debugging. Iron Law: no fixes without investigation. Stops after 3 failed fixes. |
| `/design-review` | Designer Who Codes | Visual quality audit — finds inconsistency, spacing issues, hierarchy problems, AI slop patterns. Fixes with atomic commits and before/after screenshots. |
| `/devex-review` | DX Tester | Live developer experience audit. Actually tests your onboarding: navigates docs, tries getting started, times TTHW. Compares against `/plan-devex-review` scores. |
| `/cso` | Chief Security Officer | OWASP Top 10 + STRIDE threat model. 17 false positive exclusions, 8/10+ confidence gate. Each finding includes a concrete exploit scenario. |

#### Test — Verify everything works

| Skill | Specialist | What it does |
|-------|-----------|-------------|
| `/qa` | QA Lead | Test your app, find bugs, fix them with atomic commits, re-verify. Auto-generates regression tests for every fix. |
| `/qa-only` | QA Reporter | Same methodology as `/qa` but report only — pure bug report without code changes. |
| `/benchmark` | Performance Engineer | Baseline page load times, Core Web Vitals, and resource sizes. Compare before/after on every PR. |

#### Ship — Get it to production

| Skill | Specialist | What it does |
|-------|-----------|-------------|
| `/ship` | Release Engineer | Sync main, run tests, audit coverage, push, open PR. Bootstraps test frameworks if needed. |
| `/land-and-deploy` | Release Engineer | Merge the PR, wait for CI and deploy, verify production health. One command from "approved" to "verified in production." |
| `/canary` | SRE | Post-deploy monitoring loop. Watches for console errors, performance regressions, and page failures. |
| `/document-release` | Technical Writer | Update all project docs to match what shipped. Catches stale READMEs automatically. |

#### Reflect — Learn and improve

| Skill | Specialist | What it does |
|-------|-----------|-------------|
| `/retro` | Eng Manager | Team-aware weekly retro. Per-person breakdowns, shipping streaks, test health trends. `/retro global` runs across all projects and AI tools. |
| `/learn` | Memory | Manage what gstack learned across sessions. Learnings compound so the agent gets smarter on your codebase over time. |

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

# 4. Review the plan (pick one or more)
/flow-next:plan-review        # Quick architectural review
/autoplan                     # Full auto-review (CEO → design → eng → DX)
/plan-eng-review              # Deep engineering review

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
