---
name: daily-review
description: "End of day review — what got done, what's in progress, segmented by domain. Use when: 'daily review', 'end of day', 'what did I do today', 'wrap up', 'eod review'. Scheduled 4pm Mon-Thu."
---

# Daily Review — End of Day Check-in

Read the CLAUDE.md in the PKA root to understand domains and schedule config.

## Step 1: Gather Context (silently, in parallel)

**Today's Activity:**
- Read today's journal entry for the morning's locked-in top 3
- Check git log across active repos for today's commits
- Check Linear for issues updated today (if available)
- Check today's calendar events (what meetings happened)
- Check Gmail for sent messages today (what was communicated)
- Check inbox folders — anything still pending?

**PKM Changes:**
- Check `git -C <pka-root> diff --stat` for notes modified today
- Check for any new files in domain folders

## Step 2: Present the Review

**Keep it scannable. Under 35 lines.**

```
## [Day, Month DD] — Daily Review

### Completed
**[Work Domain]**
- ✅ [thing done — 1 line]
- ✅ [thing done — 1 line]

**[Company Domain]** (if applicable)
- ✅ [thing done — 1 line]

**Personal**
- ✅ [thing done — 1 line]

### In Progress (carrying forward)
- ⏳ [task — status/next step]
- ⏳ [task — status/next step]

### Blocked / Needs Attention
- 🚫 [blocker — what's needed]
(skip if nothing blocked)

### Tomorrow Preview
- [First calendar event]
- [Any deadlines approaching]

---

Morning top 3 score: [X/3 completed]
Overall: [one-sentence assessment — encouraging, not judgmental]
```

## Step 3: Update Journal

Append to today's journal entry:
- `## End of Day` section with the completed/in-progress items
- Update the `## Focus` section marking completed items with ✅

## Tone Rules
- Celebrate wins. Even small ones. "Shipped the PR and cleared inbox — solid day."
- Never guilt-trip for incomplete items. "Carrying 2 forward — normal, not a failure."
- If everything got done: "Clean sweep. Nice. 🎯"
- Keep it warm but brief. One sentence of encouragement, not a paragraph.
