#!/usr/bin/env bash
set -euo pipefail

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
echo -e "${BOLD}Helixir Agent Skills Setup${NC}"
echo ""
echo "Installs and verifies flow-next + gstack prerequisites."
echo "Idempotent — skips anything already installed."
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
  cd gstack
  if [[ -x ./setup ]]; then
    ./setup
  fi
  cd "$HOME/.claude/skills"
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

# 4. Check xcode-native-toolkit plugin (for native app projects)
info "Checking xcode-native-toolkit skills..."
XCODE_TOOLKIT_DIR="$HOME/.claude/plugins/marketplaces/helixir-labs-inc/plugins/xcode-native-toolkit/skills"
if [[ -d "$XCODE_TOOLKIT_DIR" && -f "$XCODE_TOOLKIT_DIR/ui-preview/SKILL.md" ]]; then
  cd "$HOME/.claude/skills"
  copied=0
  for skill_dir in "$XCODE_TOOLKIT_DIR"/*/; do
    skill_name=$(basename "$skill_dir")
    if [[ ! -d "$HOME/.claude/skills/$skill_name" ]]; then
      cp -R "$skill_dir" "$HOME/.claude/skills/$skill_name"
      copied=$((copied + 1))
    else
      # Update existing copies if plugin version is newer
      if ! diff -rq "$skill_dir/SKILL.md" "$HOME/.claude/skills/$skill_name/SKILL.md" >/dev/null 2>&1; then
        cp -R "$skill_dir"/* "$HOME/.claude/skills/$skill_name/"
        copied=$((copied + 1))
      fi
    fi
  done
  if [[ $copied -gt 0 ]]; then
    ok "Installed/updated $copied xcode-native-toolkit skills (ui-preview, ui-verify-xcode, qa-xcode)"
  else
    ok "xcode-native-toolkit skills up to date"
  fi
else
  warn "xcode-native-toolkit plugin not found in marketplace"
  echo "  Expected at: $XCODE_TOOLKIT_DIR"
  echo "  Skills /ui-preview, /ui-verify-xcode, /qa-xcode will not be available."
  echo "  For native app projects (APP_TYPE=native), install the xcode-native-toolkit plugin."
fi

# 5. Check Xcode MCP bridge (optional, for native projects)
info "Checking Xcode MCP bridge..."
if command -v xcrun >/dev/null 2>&1 && xcrun --find mcpbridge >/dev/null 2>&1; then
  ok "xcrun mcpbridge available"
  if claude mcp list 2>/dev/null | grep -q "xcode"; then
    ok "Xcode MCP bridge configured in Claude Code"
  else
    warn "Xcode MCP bridge not configured. For native projects, run:"
    echo "  claude mcp add --transport stdio xcode -- xcrun mcpbridge"
  fi
else
  info "xcrun mcpbridge not found (Xcode 26.3+ required). Skipping — not needed for web projects."
fi

# 6. Check native CLI tools (optional, for native projects)
info "Checking native development CLI tools..."
missing_tools=()
command -v xcsift >/dev/null 2>&1 || missing_tools+=("xcsift")
command -v axe >/dev/null 2>&1 || missing_tools+=("axe")
command -v magick >/dev/null 2>&1 || missing_tools+=("imagemagick")
command -v ffmpeg >/dev/null 2>&1 || missing_tools+=("ffmpeg")
if [[ ${#missing_tools[@]} -eq 0 ]]; then
  ok "All native CLI tools installed (xcsift, axe, imagemagick, ffmpeg)"
else
  warn "Missing native tools: ${missing_tools[*]}"
  echo "  For native app projects, install with:"
  echo "  brew install ${missing_tools[*]}"
  echo "  (axe may need: brew tap cameroncooke/axe && brew install axe)"
fi

echo ""
echo -e "${BOLD}${GREEN}Agent skills ready.${NC}"
echo ""
echo "Next: run /helixir:setup-ralph-script to create a ralph script for a specific epic."
echo ""
