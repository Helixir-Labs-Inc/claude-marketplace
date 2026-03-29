#!/usr/bin/env python3
"""Generate a readable session summary from a session JSONL log file."""

import json
import sys
from datetime import datetime, timezone
from pathlib import Path


def extract_text_from_content(content) -> str:
    """Extract text from Claude's content block format (string or list)."""
    if isinstance(content, str):
        return content
    if not isinstance(content, list):
        return ""
    parts = []
    for block in content:
        if isinstance(block, dict):
            if block.get("type") == "text":
                parts.append(block.get("text", ""))
            elif block.get("type") == "tool_use":
                parts.append(f"[tool: {block.get('name', '?')}]")
    return " ".join(parts)


def get_user_text(entry: dict) -> str | None:
    """Extract user-typed text from a transcript item."""
    msg = entry.get("message", {})
    if isinstance(msg, dict):
        content = msg.get("content", "")
    else:
        content = entry.get("content", "")

    if isinstance(content, str):
        text = content.strip()
        if text and not text.startswith("<") and not text.startswith("{"):
            return text
    elif isinstance(content, list):
        texts = []
        for block in content:
            if isinstance(block, dict):
                if block.get("type") == "text":
                    t = block.get("text", "").strip()
                    if t and not t.startswith("<"):
                        texts.append(t)
        if texts:
            return " ".join(texts)
    return None


def summarize(logfile: Path) -> str:
    lines = logfile.read_text().strip().split("\n")
    entries = []
    for line in lines:
        try:
            entries.append(json.loads(line))
        except json.JSONDecodeError:
            continue

    user_messages: list[dict] = []
    assistant_texts: list[dict] = []
    tools_used: dict[str, int] = {}
    session_start = None
    session_end = None
    session_id = None
    cwd = None

    for entry in entries:
        event = entry.get("logEvent", "")
        ts = entry.get("timestamp") or entry.get("logTimestamp")

        if event == "SESSION_START":
            session_id = entry.get("session_id")
            session_start = ts

        if ts:
            session_end = ts

        if event == "HOOK":
            hook_name = entry.get("hook_event_name", "")
            if hook_name in ("PreToolUse", "PostToolUse"):
                tool = entry.get("tool_name", "unknown")
                tools_used[tool] = tools_used.get(tool, 0) + 1
            if not cwd:
                cwd = entry.get("cwd")

        if event == "TRANSCRIPT_ITEM":
            item_type = entry.get("type", "")

            if item_type == "user":
                text = get_user_text(entry)
                if text:
                    user_messages.append({"ts": ts, "text": text})

            elif item_type == "assistant":
                msg = entry.get("message", {})
                if isinstance(msg, dict):
                    content = msg.get("content", "")
                else:
                    content = entry.get("content", "")
                text = extract_text_from_content(content)
                if text.strip():
                    assistant_texts.append({"ts": ts, "text": text.strip()})

    # Deduplicate user messages
    seen = set()
    unique_user = []
    for m in user_messages:
        key = m["text"][:200]
        if key not in seen:
            seen.add(key)
            unique_user.append(m)

    out = []

    start_str = format_ts(session_start) if session_start else "unknown"
    end_str = format_ts(session_end) if session_end else "unknown"
    out.append("# Session Summary")
    if session_id:
        out.append(f"**Session:** `{session_id[:12]}...`")
    out.append(f"**Started:** {start_str}")
    out.append(f"**Ended:** {end_str}")
    if cwd:
        out.append(f"**Working Directory:** `{cwd}`")
    out.append("")

    out.append("## User Messages")
    out.append("")
    if unique_user:
        for m in unique_user:
            text = m["text"].strip().replace("\n", " ")
            if len(text) > 500:
                text = text[:500] + "..."
            out.append(f"- {text}")
    else:
        out.append("_No user messages captured._")
    out.append("")

    out.append("## Session Activity")
    out.append("")
    if tools_used:
        sorted_tools = sorted(tools_used.items(), key=lambda x: -x[1])
        out.append("**Tools used:**")
        for tool, count in sorted_tools:
            actual = max(1, count // 2)
            out.append(f"- {tool}: {actual}x")
        out.append("")

    if assistant_texts:
        last = assistant_texts[-1]["text"]
        if len(last) > 1000:
            last = last[:1000] + "..."
        out.append("**Last response:**")
        for line in last.split("\n"):
            out.append(f"> {line}")
        out.append("")

    return "\n".join(out)


def format_ts(ts) -> str:
    try:
        t = int(ts)
        return datetime.fromtimestamp(t, tz=timezone.utc).strftime("%Y-%m-%d %H:%M UTC")
    except (ValueError, TypeError):
        return str(ts)


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: summarize-session.py <session.jsonl>", file=sys.stderr)
        sys.exit(1)
    logfile = Path(sys.argv[1])
    if not logfile.exists():
        print(f"File not found: {logfile}", file=sys.stderr)
        sys.exit(1)
    print(summarize(logfile))
