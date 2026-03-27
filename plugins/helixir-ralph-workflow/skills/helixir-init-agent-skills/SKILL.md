---
description: Install flow-next and gstack agent skill prerequisites. Idempotent — skips anything already installed, converts symlinks to copies. Run once per machine, or after updates.
---

# Helixir Agent Skills Setup

Installs and verifies the prerequisites needed by the ralph workflow:
1. Verifies flow-next plugin is installed
2. Installs gstack skills if missing
3. Converts any symlinked skills to real copies (agents can't read symlinks)

Run it:

```bash
${CLAUDE_PLUGIN_ROOT}/scripts/init-agent-skills.sh
```

This is idempotent. If everything is already installed, it just confirms and exits.

After this, use `/helixir:setup-ralph-script` to create a ralph script for a specific epic.
