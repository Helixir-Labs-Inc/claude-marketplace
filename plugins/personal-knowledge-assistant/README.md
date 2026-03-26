# PKA — Personal Knowledge Assistant

Agent-native personal knowledge management for Claude Code. Designed for people who want an AI agent to manage their notes, files, calendar, and daily workflows.

## What it does

- **Interactive setup** — interviews you about your life domains, emails, calendars, and file storage to scaffold a personalized PKA folder
- **Morning planning** — ADHD-friendly daily kickoff with calendar, emails, goals, and a top-3 focus picker
- **Daily review** — end-of-day progress check across all domains
- **Weekly review** — Friday retrospective with goals progress
- **Inbox triage** — drop files in inbox folders, the agent renames, tags, and files them
- **Top-3 system** — never shows a full task list; always batches into 3 focus items

## Install

```bash
claude /install-plugin github:ariccb/pka-plugin
```

## Setup

After installing, run the setup interview:

```
/pka-setup
```

This creates your personal PKA folder with:
- Domain folders for each area of your life (personal, work, company, etc.)
- A CLAUDE.md with agent instructions tailored to your setup
- Mirrored file storage structure
- Inbox folders for file triage

## Daily Usage

Start Claude Code from your PKA folder:

```bash
cd ~/pka && claude
```

Available commands:
- `/morning-planning` — start your day (8:30am Mon-Fri)
- `/daily-review` — end of day check-in (4pm Mon-Thu)
- `/weekly-review` — Friday retrospective (4pm Fri)
- `/next-3` — done with current focus items, get next batch
- `/triage-inbox` — process files in inbox folders

## Architecture

**Plugin** (this repo) = shareable tooling — skills, agents, setup interview.
**PKA folder** (created by setup) = your personal data — notes, journals, projects. Never shared.

The PKA folder is a git repo for portability. Clone it on a new device, install the plugin, and you're productive immediately.
