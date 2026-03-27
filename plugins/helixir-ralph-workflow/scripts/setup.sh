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

echo ""
echo -e "${BOLD}Helixir Ralph Workflow Setup${NC}"
echo ""

# 1. Check flow-next plugin
info "Checking flow-next plugin..."
if ls ~/.claude/plugins/cache/gmickel-claude-marketplace/flow-next/ >/dev/null 2>&1; then
  FLOW_NEXT_VER=$(ls ~/.claude/plugins/cache/gmickel-claude-marketplace/flow-next/ | sort -V | tail -1)
  ok "flow-next plugin found (v$FLOW_NEXT_VER)"
else
  warn "flow-next plugin not found"
  echo "  Install it in Claude Code: search marketplace for 'flow-next' by gmickel"
  echo "  Or visit: https://github.com/gmickel/flow-next"
  fail "flow-next is required. Install it and re-run this setup."
fi

# 2. Check gstack skills (must be real copies, not symlinks)
info "Checking gstack skills..."
GSTACK_DIR="$HOME/.claude/skills/gstack"
if [[ -d "$GSTACK_DIR" && -f "$GSTACK_DIR/review/SKILL.md" ]]; then
  # Check if the skill entries are real copies
  if [[ -L "$HOME/.claude/skills/review" ]]; then
    warn "gstack skills are symlinked — agents can't read symlinks. Converting to copies..."
    cd "$HOME/.claude/skills"
    for link in $(find . -maxdepth 1 -type l); do
      target=$(readlink "$link")
      name=$(basename "$link")
      if [[ -e "$target" ]]; then
        rm "$link"
        cp -R "$target" "$name"
      fi
    done
    ok "Converted all symlinks to copies"
  else
    ok "gstack skills installed (real copies)"
  fi
else
  warn "gstack not found. Installing..."
  cd "$HOME/.claude/skills"
  if [[ -d gstack ]]; then
    cd gstack && git pull && cd ..
  else
    git clone https://github.com/garrytan/gstack.git
  fi
  # Run setup
  cd gstack
  if [[ -x ./setup ]]; then
    ./setup
  fi
  cd "$HOME/.claude/skills"
  # Convert symlinks to copies
  for link in $(find . -maxdepth 1 -type l); do
    target=$(readlink "$link")
    name=$(basename "$link")
    if [[ -e "$target" ]]; then
      rm "$link"
      cp -R "$target" "$name"
    fi
  done
  ok "gstack installed and skills copied"
fi

# 3. Check flow-next skills are real copies too
info "Checking flow-next skills..."
FLOW_NEXT_SKILLS="$HOME/.claude/plugins/cache/gmickel-claude-marketplace/flow-next/$FLOW_NEXT_VER/skills"
if [[ -d "$FLOW_NEXT_SKILLS" ]]; then
  cd "$HOME/.claude/skills"
  converted=0
  for skill_dir in "$FLOW_NEXT_SKILLS"/*/; do
    skill_name=$(basename "$skill_dir")
    if [[ -L "$HOME/.claude/skills/$skill_name" ]]; then
      rm "$HOME/.claude/skills/$skill_name"
      cp -R "$skill_dir" "$HOME/.claude/skills/$skill_name"
      converted=$((converted + 1))
    elif [[ ! -d "$HOME/.claude/skills/$skill_name" ]]; then
      cp -R "$skill_dir" "$HOME/.claude/skills/$skill_name"
      converted=$((converted + 1))
    fi
  done
  if [[ $converted -gt 0 ]]; then
    ok "Copied $converted flow-next skills"
  else
    ok "flow-next skills already installed as copies"
  fi
fi

# 4. Check project ralph scaffold — init if missing
info "Checking project ralph scaffold..."
PROJECT_DIR="${1:-$(pwd)}"
if [[ -d "$PROJECT_DIR/scripts/ralph" && -f "$PROJECT_DIR/scripts/ralph/ralph.sh" ]]; then
  ok "Ralph scaffold found at $PROJECT_DIR/scripts/ralph/"
else
  warn "No ralph scaffold found. Scaffolding via flow-next..."
  # Find the flow-next ralph-init script and run it
  RALPH_INIT_SKILL="$HOME/.claude/plugins/cache/gmickel-claude-marketplace/flow-next/$FLOW_NEXT_VER/scripts"
  if [[ -d "$RALPH_INIT_SKILL" ]]; then
    # flow-next ralph-init copies scripts from its own scripts/ dir
    mkdir -p "$PROJECT_DIR/scripts/ralph"
    # Copy the core ralph files from flow-next
    for f in "$RALPH_INIT_SKILL"/../scripts-ralph/*; do
      [[ -f "$f" ]] && cp "$f" "$PROJECT_DIR/scripts/ralph/"
    done
  fi
  # If that didn't work, check alternate locations
  if [[ ! -f "$PROJECT_DIR/scripts/ralph/ralph.sh" ]]; then
    # Try the flowctl-bundled approach
    FLOW_PLUGIN_ROOT="$HOME/.claude/plugins/cache/gmickel-claude-marketplace/flow-next/$FLOW_NEXT_VER"
    if [[ -x "$FLOW_PLUGIN_ROOT/scripts/flowctl" ]]; then
      cd "$PROJECT_DIR"
      "$FLOW_PLUGIN_ROOT/scripts/flowctl" ralph init 2>/dev/null || true
    fi
  fi
  if [[ -f "$PROJECT_DIR/scripts/ralph/ralph.sh" ]]; then
    chmod +x "$PROJECT_DIR/scripts/ralph/ralph.sh" 2>/dev/null || true
    ok "Ralph scaffold created at $PROJECT_DIR/scripts/ralph/"
  else
    warn "Could not auto-scaffold ralph. Run /flow-next:ralph-init in Claude Code, then re-run this setup."
    fail "Ralph scaffold required."
  fi
fi

# 5. Patch templates
info "Patching ralph templates with Helixir workflow..."
cp "$TEMPLATES_DIR/prompt_work.md" "$PROJECT_DIR/scripts/ralph/prompt_work.md"
ok "Patched prompt_work.md (receipt-gated quality gates, gstack integration)"

cp "$TEMPLATES_DIR/prompt_completion.md" "$PROJECT_DIR/scripts/ralph/prompt_completion.md"
ok "Patched prompt_completion.md (two-pass validation sweep, deferred UI verification)"

# 6. Patch ralph.sh rate limit handling (remove broken Codex fallback if present)
info "Checking ralph.sh rate limit handling..."
if grep -q "codex --approval-mode" "$PROJECT_DIR/scripts/ralph/ralph.sh" 2>/dev/null; then
  warn "Found broken Codex CLI fallback in ralph.sh"
  echo "  The Codex fallback used outdated CLI syntax and a dumbed-down prompt."
  echo "  It skipped quality gates and could duplicate already-committed work."
  echo "  Manual fix recommended: replace the Codex fallback block with wait-and-retry."
  echo "  See: https://github.com/ariccb/helixir-ralph-workflow#rate-limit-handling"
else
  ok "ralph.sh rate limit handling looks correct"
fi

# 7. Show config reminder
if [[ ! -f "$PROJECT_DIR/scripts/ralph/config.env" ]]; then
  warn "No config.env found. Copy the example:"
  echo "  cp $TEMPLATES_DIR/config.env.example $PROJECT_DIR/scripts/ralph/config.env"
  echo "  Then edit EPICS= to match your target epic."
fi

echo ""
echo -e "${BOLD}${GREEN}Setup complete.${NC}"
echo ""
echo "What was patched:"
echo "  • prompt_work.md — receipt written AFTER quality gates (not before)"
echo "  •                — gstack /review + /design-review as quality gates"
echo "  •                — task reset on unfixable quality gate failures"
echo "  • prompt_completion.md — two-pass task validation (cheap triage, deep-check suspects)"
echo "  •                     — UI verification deferred to epic completion"
echo "  •                     — build + screenshot verification at epic level"
echo ""
echo "To run: cd $PROJECT_DIR && scripts/ralph/ralph.sh"
echo ""
