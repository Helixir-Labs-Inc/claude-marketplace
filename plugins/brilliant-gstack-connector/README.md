# brilliant-gstack-connector

> **Status: v0.1.0 — first working version.** The `/design-brilliant` skill
> now ports an HTML source of truth onto a live Brilliant canvas via the
> Brilliant MCP. Still narrow in scope: one source → one canvas drop, with a
> PNG preview and a dated changelog. Not a full design authoring skill.

Bridges the GStack design pipeline (and arbitrary HTML/descriptions) into
[Brilliant](https://brilliant.app).

## What it does

The GStack design skills (`/design-consultation`, `/design-shotgun`,
`/design-html`) produce approved mockups as Pretext-native HTML. This plugin
adds a parallel terminus: instead of only emitting HTML, the approved design
is also landed on a live Brilliant canvas so you can iterate visually with
the full Brilliant toolset (auto layout, components, effects, export).

- `/design-brilliant` — takes a finalized HTML file path, a free-form
  description, or auto-detects the most recent
  `~/.gstack/projects/<slug>/designs/**/finalized.html`, and:
  1. Verifies the Brilliant MCP is connected and `design/Canvas.design` exists.
  2. Calls `mcp__brilliant__create_html` to materialize the design on the canvas.
  3. Exports a PNG preview to `design/Reviews/<YYYY-MM-DD>-<slug>.png`.
  4. Appends a dated changelog entry to `design/Reviews/<YYYY-MM-DD>.md`.
  5. Reports the canvas ID, new element IDs, preview path, and next steps.

Out of scope (for now): new design generation (use `/design-html`),
Blueprint DSL authoring, direct `Canvas.design` text writing.

## Requirements

- **Brilliant desktop app** running locally. MCP server listens on
  `http://127.0.0.1:3333/mcp`.
- **MCP registration.** Either project-scoped via `.mcp.json` or user-scoped
  in your Claude config. Verify with `/mcp` — `brilliant` must show as
  connected.
- **A `design/` folder** at the project root that Brilliant has opened at
  least once, so `Canvas.design` (and `.brilliant/`, `Assets/`, `Features/`,
  `Sketches/`) exist.
- **Optional: GStack** — enables `finalized.html` auto-detection. Without
  GStack, pass a path or description explicitly.

## Dev loop

1. `cd ~/_git/_helixirlabs-projects/brilliant-gstack-connector-dev/`
2. Open `design/` in Brilliant so the app populates `.brilliant/` and a
   base `Canvas.design`.
3. Start Claude Code — the project-local `.mcp.json` loads the Brilliant
   MCP at `http://127.0.0.1:3333/mcp`.
4. Iterate on
   `~/_git/_ai-tools/helixir-labs-inc-marketplace/claude-marketplace/plugins/brilliant-gstack-connector/skills/design-brilliant/SKILL.md`
   with the MCP tools live.
5. Commit + push. The installed marketplace on your machine reads from
   GitHub, so every push needs to be landed for `/plugin update` to
   reflect it.

## Example invocations

```
/design-brilliant
/design-brilliant ~/.gstack/projects/foo/designs/landing-20260417/finalized.html
/design-brilliant "dark-mode pricing page, three tier cards, hero with headline and CTA"
```
