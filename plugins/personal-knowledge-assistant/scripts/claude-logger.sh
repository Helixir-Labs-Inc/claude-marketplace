#!/bin/bash
set -euo pipefail

# Claude Code session logger (PKA plugin)
# Logs per-session to ~/.claude/logs/YYYY-MM-DD/session-{id}.jsonl
# On Stop events, generates a readable summary .md file

LOG_BASE="$HOME/.claude/logs"
LOCK_DIR="${TMPDIR:-/tmp}/claude-logger.lock"

logTimestamp=$(date +%s)
logDate=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
dateDir=$(date +"%Y-%m-%d")
stdin=$(cat)

# Atomic lock
while ! mkdir "$LOCK_DIR" 2>/dev/null; do
    sleep 0.1
done
trap 'rmdir "$LOCK_DIR" 2>/dev/null' EXIT

# Extract session info
session_id=$(echo "$stdin" | jq -r '.session_id // empty')
hook_event=$(echo "$stdin" | jq -r '.hook_event_name // empty')

[[ -z "$session_id" ]] && exit 0

# Create organized directory
session_dir="$LOG_BASE/$dateDir"
mkdir -p "$session_dir"

session_log="$session_dir/session-${session_id}.jsonl"
state_dir="$LOG_BASE/.state"
mkdir -p "$state_dir"

# Track transcript diffs
transcript_path=$(echo "$stdin" | jq -r '.transcript_path // empty')
if [[ -n "$transcript_path" && -f "$transcript_path" ]]; then
    state_file="$state_dir/${session_id}.transcript.jsonl"
    path_file="$state_dir/${session_id}.transcript_path.txt"

    # Detect new session
    if [[ ! -f "$path_file" ]] || [[ $(< "$path_file") != "$transcript_path" ]]; then
        jq -nc --arg ts "$logTimestamp" --arg date "$logDate" --arg sid "$session_id" \
            '{logEvent:"SESSION_START", timestamp:$ts, date:$date, session_id:$sid}' >> "$session_log"
        > "$state_file"
    fi

    echo "$transcript_path" > "$path_file"
    [[ -f "$state_file" ]] || touch "$state_file"

    diff_output=$(diff "$state_file" "$transcript_path" 2>/dev/null || true)
    cp "$transcript_path" "$state_file"

    # Log new transcript items
    logAdditions=$(echo "$diff_output" | grep '^> ' | sed 's/^> //' || true)
    if [[ -n "$logAdditions" ]]; then
        echo "$logAdditions" | jq -c --arg ts "$logTimestamp" --arg date "$logDate" \
            '{logEvent:"TRANSCRIPT_ITEM", timestamp:$ts, date:$date} + .' >> "$session_log"
    fi
fi

# Log the hook event itself
echo "$stdin" | jq -c --arg ts "$logTimestamp" --arg date "$logDate" \
    '{logEvent:"HOOK", timestamp:$ts, date:$date} + .' >> "$session_log"

# On Stop: generate session summary
if [[ "$hook_event" == "Stop" ]]; then
    summary_file="$session_dir/session-${session_id}.md"
    SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
    PARSE_SCRIPT="$SCRIPT_DIR/summarize-session.py"

    # Try plugin venv first, fall back to system python
    VENV_PYTHON="$SCRIPT_DIR/venv/bin/python3"
    if [[ -f "$VENV_PYTHON" ]]; then
        "$VENV_PYTHON" "$PARSE_SCRIPT" "$session_log" > "$summary_file" 2>/dev/null || true
    elif command -v python3 &>/dev/null; then
        python3 "$PARSE_SCRIPT" "$session_log" > "$summary_file" 2>/dev/null || true
    fi

    # Update latest symlinks
    ln -sf "$session_log" "$LOG_BASE/latest.jsonl"
    [[ -f "$summary_file" && -s "$summary_file" ]] && ln -sf "$summary_file" "$LOG_BASE/latest.md"

    # Clean up state files for this session
    rm -f "$state_dir/${session_id}.transcript.jsonl" "$state_dir/${session_id}.transcript_path.txt"
fi

exit 0
