#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TEMPLATES_DIR="$PLUGIN_DIR/templates"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

info()  { printf "${CYAN}▸${NC} %s\n" "$*"; }
ok()    { printf "${GREEN}✓${NC} %s\n" "$*"; }
warn()  { printf "${YELLOW}⚠${NC} %s\n" "$*"; }
fail()  { printf "${RED}✗${NC} %s\n" "$*"; exit 1; }

# --- Args ---
EPIC_SLUG="${1:-}"
PROJECT_DIR="${2:-$(pwd)}"
APP_TYPE="${3:-web}"

if [[ -z "$EPIC_SLUG" ]]; then
  echo ""
  echo -e "${BOLD}Usage:${NC} setup-ralph-script.sh <epic-slug> [project-dir] [app-type]"
  echo ""
  echo "  epic-slug    The flow-next epic ID (e.g., fn-10-note-editor-redesign)"
  echo "  project-dir  Project root directory (default: current directory)"
  echo "  app-type     'web' or 'native' (default: web)"
  echo ""
  echo "Creates: scripts/ralph-<epic-slug>/"
  echo ""
  fail "epic-slug is required."
fi

RALPH_DIR="$PROJECT_DIR/scripts/ralph-${EPIC_SLUG}"

echo ""
echo -e "${BOLD}Setup Ralph Script: ${EPIC_SLUG}${NC}"
echo -e "Directory: ${CYAN}${RALPH_DIR}${NC}"
echo ""

# --- Quick dep check ---
info "Checking prerequisites..."
if ! ls ~/.claude/plugins/cache/gmickel-claude-marketplace/flow-next/ >/dev/null 2>&1; then
  fail "flow-next not installed. Run /helixir:init-agent-skills first."
fi
FLOW_NEXT_VER=$(ls ~/.claude/plugins/cache/gmickel-claude-marketplace/flow-next/ | sort -V | tail -1)

if [[ ! -d "$HOME/.claude/skills/gstack" ]]; then
  fail "gstack not installed. Run /helixir:init-agent-skills first."
fi
ok "Prerequisites installed (flow-next v$FLOW_NEXT_VER, gstack)"

# --- Check if already exists ---
if [[ -d "$RALPH_DIR" ]]; then
  warn "Ralph script already exists at $RALPH_DIR"
  echo "  Re-patching templates and config..."
fi

# --- Scaffold from flow-next ---
info "Scaffolding ralph for ${EPIC_SLUG}..."
mkdir -p "$RALPH_DIR"

# Copy core ralph files from flow-next if ralph.sh doesn't exist yet
if [[ ! -f "$RALPH_DIR/ralph.sh" ]]; then
  FLOW_PLUGIN_ROOT="$HOME/.claude/plugins/cache/gmickel-claude-marketplace/flow-next/$FLOW_NEXT_VER"

  # Try scripts-ralph directory first
  if [[ -d "$FLOW_PLUGIN_ROOT/scripts-ralph" ]]; then
    for f in "$FLOW_PLUGIN_ROOT/scripts-ralph"/*; do
      [[ -f "$f" ]] && cp "$f" "$RALPH_DIR/"
    done
  fi

  # If that didn't work, try flowctl ralph init
  if [[ ! -f "$RALPH_DIR/ralph.sh" ]]; then
    # Check if the default scripts/ralph exists and copy from there
    if [[ -f "$PROJECT_DIR/scripts/ralph/ralph.sh" ]]; then
      cp "$PROJECT_DIR/scripts/ralph/ralph.sh" "$RALPH_DIR/ralph.sh"
      [[ -f "$PROJECT_DIR/scripts/ralph/flowctl" ]] && cp "$PROJECT_DIR/scripts/ralph/flowctl" "$RALPH_DIR/flowctl"
      [[ -f "$PROJECT_DIR/scripts/ralph/flowctl.py" ]] && cp "$PROJECT_DIR/scripts/ralph/flowctl.py" "$RALPH_DIR/flowctl.py"
      [[ -f "$PROJECT_DIR/scripts/ralph/watch-filter.py" ]] && cp "$PROJECT_DIR/scripts/ralph/watch-filter.py" "$RALPH_DIR/watch-filter.py"
      [[ -d "$PROJECT_DIR/scripts/ralph/hooks" ]] && cp -R "$PROJECT_DIR/scripts/ralph/hooks" "$RALPH_DIR/hooks"
    fi
  fi

  # Last resort: try flowctl
  if [[ ! -f "$RALPH_DIR/ralph.sh" && -x "$FLOW_PLUGIN_ROOT/scripts/flowctl" ]]; then
    cd "$PROJECT_DIR"
    "$FLOW_PLUGIN_ROOT/scripts/flowctl" ralph init 2>/dev/null || true
    # If it created scripts/ralph, move to our epic-specific dir
    if [[ -f "$PROJECT_DIR/scripts/ralph/ralph.sh" && ! -f "$RALPH_DIR/ralph.sh" ]]; then
      cp -R "$PROJECT_DIR/scripts/ralph/"* "$RALPH_DIR/"
    fi
  fi

  if [[ -f "$RALPH_DIR/ralph.sh" ]]; then
    chmod +x "$RALPH_DIR/ralph.sh" 2>/dev/null || true
    ok "Ralph scaffold created"
  else
    fail "Could not scaffold ralph. Run /flow-next:ralph-init first, then re-run this setup."
  fi
else
  ok "Ralph scaffold already exists"
fi

# --- Patch prompt templates ---
info "Patching prompt templates with Helixir coordinator workflow..."
cp "$TEMPLATES_DIR/prompt_work.md" "$RALPH_DIR/prompt_work.md"
ok "prompt_work.md (lead coordinator + parallel workers + full quality pipeline)"

cp "$TEMPLATES_DIR/prompt_completion.md" "$RALPH_DIR/prompt_completion.md"
ok "prompt_completion.md (integration testing + CSO + docs + codex + PR review + ship)"

# --- Check ralph.sh rate limit handling ---
if grep -q "codex --approval-mode" "$RALPH_DIR/ralph.sh" 2>/dev/null; then
  warn "Found broken Codex CLI fallback in ralph.sh — replace with wait-and-retry"
fi

# --- Create/update config.env ---
info "Writing config.env..."
if [[ -f "$RALPH_DIR/config.env" ]]; then
  # Update EPICS if it doesn't match
  if ! grep -q "^EPICS=${EPIC_SLUG}" "$RALPH_DIR/config.env" 2>/dev/null; then
    sed -i '' "s/^EPICS=.*/EPICS=${EPIC_SLUG}/" "$RALPH_DIR/config.env" 2>/dev/null || true
  fi
  # Ensure APP_TYPE exists
  if ! grep -q '^APP_TYPE=' "$RALPH_DIR/config.env" 2>/dev/null; then
    echo "" >> "$RALPH_DIR/config.env"
    echo "APP_TYPE=${APP_TYPE}" >> "$RALPH_DIR/config.env"
  fi
  # Ensure FEATURE_BRANCH_PREFIX exists
  if ! grep -q '^FEATURE_BRANCH_PREFIX=' "$RALPH_DIR/config.env" 2>/dev/null; then
    echo "FEATURE_BRANCH_PREFIX=feature/" >> "$RALPH_DIR/config.env"
  fi
  ok "Updated existing config.env (EPICS=${EPIC_SLUG})"
else
  cat > "$RALPH_DIR/config.env" <<ENVEOF
# Ralph config — ${EPIC_SLUG}

# Target epic
EPICS=${EPIC_SLUG}

# App type: "native" (iOS/macOS Swift) or "web" (React, Next.js, etc.)
APP_TYPE=${APP_TYPE}

# Feature branch prefix
FEATURE_BRANCH_PREFIX=feature/

# Review gates (codex, rp, or none)
REQUIRE_PLAN_REVIEW=0
PLAN_REVIEW=codex
WORK_REVIEW=codex
COMPLETION_REVIEW=codex

# Codex settings
CODEX_SANDBOX=auto
FLOW_CODEX_EMBED_MAX_BYTES=500000

# Work settings
BRANCH_MODE=current
MAX_ITERATIONS=25
MAX_ATTEMPTS_PER_TASK=5

# Unattended mode
YOLO=1

# Rate limit handling — pause and retry (seconds)
RALPH_RATE_LIMIT_WAIT=300
ENVEOF
  ok "Created config.env (EPICS=${EPIC_SLUG}, APP_TYPE=${APP_TYPE})"
fi

# --- .gitignore for runs ---
if [[ ! -f "$RALPH_DIR/.gitignore" ]]; then
  cat > "$RALPH_DIR/.gitignore" <<'GIEOF'
runs/
*.log
PAUSE
STOP
GIEOF
fi

echo ""
echo -e "${BOLD}${GREEN}Ralph script ready: ${EPIC_SLUG}${NC}"
echo ""
echo "  Directory:  $RALPH_DIR"
echo "  Epic:       $EPIC_SLUG"
echo "  App type:   $APP_TYPE"
echo ""
echo "  To run:     $RALPH_DIR/ralph.sh"
echo ""
echo "  Multiple ralph scripts can run in parallel — each has its own"
echo "  config, state, and runs directory."
echo ""
