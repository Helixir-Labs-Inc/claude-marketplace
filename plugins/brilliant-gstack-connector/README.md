# brilliant-gstack-connector

> **Status: WIP scaffold (v0.0.1).** The `/design-brilliant` skill is a
> stub — it will not produce working output yet. This plugin is registered
> in the marketplace early so the author can iterate against the live
> Brilliant MCP from the dev sandbox. Do not install this plugin expecting
> functionality.

Bridges the GStack design pipeline into [Brilliant](https://brilliant.app).

## What it does (intended)

The GStack design skills (`/design-consultation`, `/design-shotgun`, `/design-html`) produce approved mockups as Pretext-native HTML. This plugin adds a parallel terminus: instead of (or in addition to) emitting HTML, the approved design is written into a project's Brilliant design folder so you can open it in Brilliant and iterate visually.

- `/design-brilliant` — runs after a GStack planning/shotgun pass; materializes the approved mockup into `Canvas.design` + `Features/*.design` in the project's `design/` folder via the Brilliant MCP.

## Dev loop

1. `cd ~/_git/_helixirlabs-projects/brilliant-gstack-connector-dev/`
2. Open `design/` in Brilliant so the app populates `.brilliant/` and a base `Canvas.design`.
3. Start Claude Code — the project-local `.mcp.json` loads the Brilliant MCP at `http://127.0.0.1:3333/mcp`.
4. Iterate on `skills/design-brilliant/SKILL.md` in this repo with the MCP tools live.
5. Commit + push to the canonical repo at `Helixir-Labs-Inc/claude-marketplace`. The installed marketplace on your machine reads from GitHub, so every push needs to be landed for `/plugin update` to reflect it.

## Requirements

- GStack installed (skills read from `~/.claude/skills/design-*`).
- Brilliant desktop app running locally (MCP server on `127.0.0.1:3333`).
- The target project has (or will have) a `design/` folder opened as a Brilliant project.
