---
name: morning-planning
description: "Morning planning session with goals overview, calendar, emails, and top 3 focus picker. Use when: 'morning planning', 'start my day', 'what should I focus on', 'plan my day', 'morning brief', 'good morning'. Scheduled 8:30am Mon-Fri."
---

# Morning Planning — Daily Kickoff

Read the CLAUDE.md in the PKA root to understand the user's domains, schedule, email accounts, and task management preferences before proceeding.

## Critical Boundary
**PKA tasks are NOT flow-next tasks.** Do not read `.flow/` directories, do not use flowctl, do not reference flow-next skills. PKA tracks focus items in journal entries only. The "Top 3" system lives in `personal/journal/` — it is PKA's own lightweight tracker, not an external task system.

If the user says "add a task" or "what are my tasks" without mentioning "flow" or "flow-next", they mean PKA tasks — items tracked in their journal's Focus section.

## Step 1: Gather Context (silently, in parallel)

Do NOT narrate what you're gathering. Run all of these in parallel:

**PKM State:**
- Read the PKA root CLAUDE.md for domain structure and schedule config
- Read project folders across ALL domains (check each `<domain>/projects/`)
- Read area docs at each domain root (the `.md` files)
- Read learning/career areas if they exist
- Check most recent journal entry for continuity
- Check inbox folders for pending files: `ls <pka-root>/inbox/*/`

**Calendar & Email (MCP — use whatever accounts are configured):**
- Google Calendar: list today's events across all calendars
- Gmail: search for unread important messages from today and yesterday
- Linear: list assigned issues in progress or high priority (if available)
- Slack: check for unread DMs or mentions (if available)

**Code Activity:**
- Recent git commits in active repos (check domains for repo references)

## Step 2: Present the Brief

Read the user's task management style from CLAUDE.md. If "Top-3 batching" (the default), use this format.

**Keep the entire output under 40 lines.** Skip any section with nothing to show.

```
## [Day, Month DD] — Morning Planning

### Schedule
[Time] — [Event title]
[Time] — [Event title]
(if empty: "Clear calendar today")

### Needs Response
- [Email/Slack from X about Y — 1 line max]
(if none: skip entirely)

### Active Work
**[Work Domain Name]**
- [project/issue — status in ≤5 words]
- [project/issue — status in ≤5 words]

**[Company Domain Name]** (if applicable)
- [project/client — status in ≤5 words]

### Keep in Mind
- [Personal items relevant today only — appointments, errands, reminders]
(During work hours: keep this to 1-2 lines max)
(After work hours: expand personal items, compress work)

### Goals Pulse
Work: [current milestone — 1 sentence]
Personal: [current goal — 1 sentence]

### Inbox
[counts per domain — or "all clear"]

---

### Top 3 for Today
1. **[Task]** — [why now, ≤5 words]
2. **[Task]** — [why now, ≤5 words]
3. **[Task]** — [why now, ≤5 words]

Swap any? Or "go" to lock in.
```

## Step 3: Lock In

When user confirms ("go", "good", "yeah", "ok", "looks good", or accepts without changes):

1. Create/update today's journal entry at `<pka>/personal/journal/YYYY/MM/YYYY-MM-DD.md`
   - Use the journal-entry template if creating new
   - Add a `## Focus` section with the locked-in top 3
   - Add a `## Schedule` section with today's events
2. Output: **"Locked in. `/next-3` when you've crushed these."**

## Top 3 Selection Rules
- Overdue or blocking someone → always include
- Meeting today about it → include for prep
- User worked on it yesterday → momentum pick
- Mix work and personal items based on time of day (check CLAUDE.md schedule config)
- Never include more than 1 admin task (emails, triage, filing)
- If user has ADHD/batching preference: keep items concrete and actionable, not vague
