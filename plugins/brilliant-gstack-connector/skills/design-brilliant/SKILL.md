---
name: design-brilliant
version: 0.1.1
description: >-
  Port an approved GStack design (or any HTML / free-form description) onto a
  live Brilliant canvas via the Brilliant MCP. Accepts a path to a finalized
  HTML file, a plain description, or auto-detects the most recent
  ~/.gstack/projects/<slug>/designs/**/finalized.html. Lands elements on the
  project's design/ Canvas using create_html, exports a PNG preview, and
  appends a dated changelog entry under design/Reviews/. Sibling terminus to
  /design-html, not a replacement. Requires the Brilliant desktop app running
  on 127.0.0.1:3333 and a design/ folder that Brilliant has opened at least
  once. Use when: "port this to Brilliant", "open this in Brilliant",
  "Brilliantify this design", or after /design-html produces a finalized.html.
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
  - AskUserQuestion
  - mcp__brilliant__init
  - mcp__brilliant__create_html
  - mcp__brilliant__search_elements
  - mcp__brilliant__get_blueprint
  - mcp__brilliant__export
  - mcp__brilliant__execute_commands
---

# /design-brilliant — GStack → Brilliant bridge

You port a source of truth (HTML file, free-form description, or auto-detected
GStack artifact) onto a live Brilliant canvas via the Brilliant MCP.

This skill is a *bridge*, not a designer. It does not generate new design
ideas. It takes an already-decided design and materializes it on a Brilliant
canvas so the user can iterate visually in Brilliant.

**If the user has no design yet**, stop and tell them to run `/design-html`
(or `/design-shotgun` → `/design-html`) first. Do not try to invent a design.

---

## Step 0 — Preconditions

Run these in a single bash block. If any fail, stop with a clear message —
do not proceed to create anything.

```bash
_CWD="$(pwd)"
_DESIGN_DIR="$_CWD/design"
if [ -d "$_DESIGN_DIR" ] && [ -f "$_DESIGN_DIR/Canvas.design" ]; then
  echo "DESIGN_DIR: $_DESIGN_DIR"
else
  echo "DESIGN_DIR_MISSING: expected $_DESIGN_DIR with Canvas.design inside"
fi
if [ -f "$_CWD/.mcp.json" ] && grep -q brilliant "$_CWD/.mcp.json" 2>/dev/null; then
  echo "MCP_CONFIG: scoped in .mcp.json"
else
  echo "MCP_CONFIG: not found in project .mcp.json (may be user-scope)"
fi
# gstack slug (for finalized.html auto-detect); optional
if command -v ~/.claude/skills/gstack/bin/gstack-slug >/dev/null 2>&1; then
  eval "$(~/.claude/skills/gstack/bin/gstack-slug 2>/dev/null)" 2>/dev/null || true
  [ -n "${SLUG:-}" ] && echo "GSTACK_SLUG: $SLUG" || echo "GSTACK_SLUG: (none)"
else
  echo "GSTACK_SLUG: (gstack not installed)"
fi
date -u +%Y-%m-%d
```

Then verify the MCP is live and the canvas is reachable by calling
`mcp__brilliant__init`. It returns `canvasId`, `repoRoot`, element count.

Fail-fast rules:
- `DESIGN_DIR_MISSING` → Tell the user: "Open `<cwd>/design/` in Brilliant
  once so it populates `Canvas.design`, then retry." Stop.
- `mcp__brilliant__init` errors (MCP not connected) → Tell the user: "The
  Brilliant MCP isn't reachable. Make sure the Brilliant desktop app is
  running (listens on 127.0.0.1:3333) and that `/mcp` shows `brilliant` as
  connected." Stop.
- `init.repoRoot` does not equal the `DESIGN_DIR` from bash → Tell the user
  which folder Brilliant has open vs which folder they're running the skill
  from, and ask them to reconcile. Stop.

---

## Step 1 — Resolve the source of truth

Priority order:

1. **Explicit argument** — if the user's invocation passed a path or described
   content inline, use that.
2. **Auto-detect GStack finalized.html** — if `GSTACK_SLUG` is known, search
   `~/.gstack/projects/$SLUG/designs/*/finalized.html`, pick the most recently
   modified. Use `Glob` with `~/.gstack/projects/$SLUG/designs/**/finalized.html`.
3. **Prompt** — if neither yields input, ask:

   > No HTML source found. How do you want to feed Brilliant?
   > A) I'll paste a path to an HTML file
   > B) I'll describe the design in one paragraph
   > C) Cancel — I'll run `/design-html` first

   If A: read the file. If B: accept the description and draft minimal HTML
   from it (see Step 2). If C: stop.

Once resolved, print a one-line banner:

```
SOURCE: <path or "inline description">
TARGET: <design dir>  (canvas: <canvasId>)
```

---

## Step 2 — Prepare HTML payload for `create_html`

`mcp__brilliant__create_html` accepts HTML + inline CSS. It does NOT run
external scripts, load remote stylesheets, or execute JS (no Pretext, no
Google Fonts fetch on the canvas side). You must flatten to static markup.

### Constraints applied to every payload (required)

Without explicit width and overflow rules, Brilliant renders the root
element at an unbounded width and long text spills off the visible frame
on the canvas. The v0.1.0 first-run symptom — hero extending past the
right edge, card text truncated like `"Elements land on Canvas.design
via the Brilliant M…"` — was entirely a missing-constraint problem, not
an MCP bug.

Prepend this style block and wrap the body content in a `.dbc-canvas-frame`
div on every payload. The `dbc-` prefix is this skill's namespace and
should not collide with source styles.

```html
<style>
  .dbc-canvas-frame {
    max-width: 1200px;
    margin: 0 auto;
    padding: 48px 32px;
    box-sizing: border-box;
    font-family: -apple-system, system-ui, "Segoe UI", sans-serif;
  }
  .dbc-canvas-frame *,
  .dbc-canvas-frame *::before,
  .dbc-canvas-frame *::after {
    box-sizing: border-box;
    min-width: 0;
    max-width: 100%;
    overflow-wrap: anywhere;
    word-wrap: break-word;
  }
  .dbc-canvas-frame img,
  .dbc-canvas-frame svg,
  .dbc-canvas-frame video {
    max-width: 100%;
    height: auto;
  }
  .dbc-canvas-frame pre,
  .dbc-canvas-frame code {
    white-space: pre-wrap;
  }
</style>
<div class="dbc-canvas-frame">
  <!-- transformed source content goes here -->
</div>
```

Rationale for each rule:
- `max-width: 1200px; margin: 0 auto` — the canvas frame has a definite
  width; Brilliant measures the root element to decide frame size.
- `min-width: 0` on every descendant — flex/grid children default to
  `min-width: auto`, which causes overflow rather than wrap.
- `overflow-wrap: anywhere` — long URLs, long dashes, and unbroken strings
  wrap instead of pushing the column wider.
- Media capped at `max-width: 100%` — an oversized image can't push the
  frame wider than its container.

### Transform rules

- **If source is a GStack `finalized.html`** (Pretext-heavy):
  - Strip `<script>` blocks, Pretext imports, ResizeObserver wiring,
    `contenteditable` handlers.
  - Inline computed styles where possible, or keep `<style>` blocks at the
    top of the body.
  - Keep semantic structure (`<header>`, `<section>`, `<footer>` etc.) —
    Brilliant preserves layout intent.
  - If the file uses Google Fonts, replace with a system font stack
    (`-apple-system, system-ui, sans-serif`), or keep the font-family name —
    Brilliant will substitute.
  - **Wrap whatever remains in the `.dbc-canvas-frame` div above.** Do
    not skip this step even if the source already has its own outer
    container — nested wrappers are fine; an unbounded root is not.
- **If source is a free-form description**: use the scaffold below. It
  already includes the canvas frame and opinionated defaults that produce
  a clean first drop on the canvas.

### Free-form description scaffold

Fill in real content from the description. Never "Lorem ipsum". Keep total
payload under ~15KB where practical.

```html
<style>
  .dbc-canvas-frame { /* as defined above — do not omit */ }
  .dbc-hero { padding: 80px 0 48px; }
  .dbc-eyebrow { font: 600 14px/1 -apple-system, system-ui, sans-serif;
                 color: #64748b; letter-spacing: 0.06em;
                 text-transform: uppercase; margin: 0 0 16px; }
  .dbc-h1 { font: 700 56px/1.1 -apple-system, system-ui, sans-serif;
            margin: 0 0 16px; color: #0f172a; }
  .dbc-lead { font: 400 18px/1.5 -apple-system, system-ui, sans-serif;
              color: #475569; max-width: 640px; margin: 0 0 32px; }
  .dbc-cta-row { display: flex; gap: 12px; align-items: center;
                 flex-wrap: wrap; }
  .dbc-cta { display: inline-block; padding: 12px 20px; border-radius: 8px;
             font: 600 15px/1 -apple-system, system-ui, sans-serif;
             text-decoration: none; background: #10b981; color: #052e1a; }
  .dbc-cta-ghost { background: transparent; color: #0f172a; }
  .dbc-grid { display: grid;
              grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
              gap: 24px; margin: 48px 0 0; }
  .dbc-card { background: #0f172a; color: #e2e8f0; padding: 24px;
              border-radius: 12px; }
  .dbc-card h3 { font: 600 16px/1.3 -apple-system, system-ui, sans-serif;
                 margin: 0 0 8px; color: #f8fafc; }
  .dbc-card p { font: 400 14px/1.5 -apple-system, system-ui, sans-serif;
                margin: 0; color: #94a3b8; }
</style>
<div class="dbc-canvas-frame">
  <section class="dbc-hero">
    <p class="dbc-eyebrow"><!-- category / kicker --></p>
    <h1 class="dbc-h1"><!-- headline --></h1>
    <p class="dbc-lead"><!-- 1-2 sentence lead --></p>
    <div class="dbc-cta-row">
      <a class="dbc-cta" href="#"><!-- primary CTA --></a>
      <a class="dbc-cta dbc-cta-ghost" href="#"><!-- secondary CTA --></a>
    </div>
  </section>
  <!-- Optional grid of cards, feature rows, etc. Remove if not described. -->
</div>
```

Omit sections the description doesn't mention — no hero, remove the hero
block. No cards, remove the grid. Empty scaffold sections render as empty
blocks on the canvas and look broken.

### Splitting payloads

You may split one page into multiple `create_html` calls if the design has
distinct sections (e.g. nav, hero, features) and you want each as its own
frame group on the canvas. If you do split, each call's payload must carry
its own `.dbc-canvas-frame` wrapper — the constraints are per-payload.
One call per invocation is still the default.

---

## Step 3 — Land it on the canvas

Capture the element count before and after so you know what you created.

1. Call `mcp__brilliant__search_elements` scoped to `canvasIds: [<canvasId>]`
   with a benign filter (e.g., `type: "parent"`) to snapshot the pre-state.
   Note: `search_elements` requires at least one filter — calling it with no
   params errors out.
2. Call `mcp__brilliant__create_html` with the prepared HTML payload.
   **Do NOT pass `previewRows` or `previewScale`** on payloads over ~2KB —
   the inline preview render can exceed the MCP client timeout even when
   the canvas write succeeded server-side. Verify via `search_elements`
   and `export` instead (Step 4).
3. If the call returns successfully, capture the new top-level element
   IDs from the response. If the call **times out** (common on larger
   payloads), immediately call `mcp__brilliant__search_elements` with
   `query: "<top-level layer-name you used>"` — if the element is there,
   the write succeeded and you can proceed. Treat timeout+present as
   success; timeout+absent as failure.

If `create_html` returns an error (not a timeout):
- Log the error verbatim.
- Do NOT retry with a fallback. Report and stop.

---

## Step 4 — Verify + export preview

1. Call `mcp__brilliant__get_blueprint` scoped to the new element IDs with
   `depth: 1`. This confirms Brilliant actually parsed the payload into real
   elements. If the blueprint is empty, treat it as a failure and stop.
2. Call `mcp__brilliant__export` with:
   - `canvasId: <canvasId>`
   - `ids: [<new element IDs>]`
   - `format: "png"`
   - `scale: 2.0`
   - `background: "window"`
   - `outputPath: "<design_dir>/Reviews/<YYYY-MM-DD>-<slug>.png"`

   Where `<slug>` is a kebab-case short name derived from the source (e.g.,
   `landing-hero`, `dashboard-v2`). Create the `Reviews/` directory first
   with `mkdir -p` if missing.
3. Show the preview PNG inline (Read tool on the output path).
4. **Overflow check.** Inspect the root element's bounding box width from
   `get_blueprint`. If it exceeds 1400 px (the frame's 1200 px + a 200 px
   safety margin), the constraints in Step 2 were bypassed or the source
   has inline `width:` declarations that escape the wrapper. Add a warning
   to the summary block (Step 6):

   > `WARNING: rendered width <W>px exceeds the 1200px canvas frame.`
   > `Content may be clipped in the preview PNG. The elements are on the`
   > `canvas and viewable in Brilliant — iterate the source or re-run`
   > `with a tighter description.`

   Do not fail and do not delete elements — the landing succeeded; this
   is a hint to iterate, not a hard error.

---

## Step 5 — Append changelog

Append a dated entry to `<design_dir>/Reviews/<YYYY-MM-DD>.md` (create the
file if missing). Format:

```markdown
## <HH:MM UTC> — <short title>

- Source: <path or "inline description">
- Mode: <html-file | description>
- Canvas: <canvasId>
- Created element IDs: <id1>, <id2>, …
- Preview: ./<YYYY-MM-DD>-<slug>.png
- Notes: <1–2 sentences of what landed and any caveats>
```

Use `Edit` to append if the file exists; use `Write` if it's new. Never
overwrite an existing file.

---

## Step 6 — Summary block

Print this exact structure to the user, one line per field:

```
STATUS: DONE
Canvas: <canvasId>
Elements added: <count>
Preview: <absolute path to PNG>
Changelog: <absolute path to Reviews/<YYYY-MM-DD>.md>

Open in Brilliant: File → Open → <design_dir parent folder>
Next iteration: use mcp__brilliant__create_modify_elements (Blueprint DSL)
  to refine, or re-run /design-brilliant with a new source.
```

On failure, replace with:

```
STATUS: BLOCKED
Reason: <1 sentence>
Attempted: <what you tried>
Next: <concrete action the user can take>
```

---

## Explicitly out of scope

- **Generating new designs.** Use `/design-html` or `/design-shotgun` for
  that. This skill only ports existing designs.
- **Blueprint DSL authoring.** Iteration, effects, components, and shader
  work happen via `mcp__brilliant__create_modify_elements` in a follow-up
  call — not in this skill's first pass.
- **Writing `Canvas.design` text directly.** The MCP is the only supported
  path. If the MCP is down, stop — do not fall back to writing the DSL file
  by hand (that was in the original scaffold notes and has been dropped as
  out of scope for v0.1).
- **Modifying GStack skills.** They live at `~/.claude/skills/design-*` and
  this skill only reads their output.

## Safety rails

- Never write anywhere outside `<design_dir>/Reviews/` in this skill. The
  canvas itself is mutated through the MCP, which Brilliant owns. No direct
  edits to `Canvas.design`, `Features/*.design`, `Assets/`, or `Sketches/`.
- Never read `.env` files while resolving the source (GStack artifacts
  don't contain secrets, but a user could pass an arbitrary path — refuse
  any path matching `**/.env` or `**/.env.*`).
- Stop on the first unrecoverable error. Do not loop or retry creation
  with different payloads.
