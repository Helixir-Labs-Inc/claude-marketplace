---
name: weekly-review
description: "Friday weekly retrospective — what shipped, goals progress, next week preview. Use when: 'weekly review', 'friday review', 'retro', 'what did I ship this week', 'week recap'. Scheduled 4pm Friday."
---

# Weekly Review — Friday Retrospective

Read the CLAUDE.md in the PKA root to understand domains and goals.

## Step 1: Gather Context (silently, in parallel)

**This Week's Activity:**
- Read all journal entries from this week (Mon-Fri)
- Check git log across active repos for this week's commits
- Read session summaries from `~/.claude/logs/` for Mon-Fri (glob each day's `session-*.md` files)
- Check Linear for issues completed this week (if available)
- Check Linear for issues still in progress
- Read area docs at domain roots for goals context
- Check `personal/learning/` for learning progress
- Check `personal/career/` for career goal progress
- Scan each domain's `projects/` for project status

**Calendar:**
- List this week's events (what happened)
- List next week's events (what's coming)

**Email:**
- Count of threads handled this week (if Gmail available)

## Step 2: Present the Review

```
## Week of [Month DD–DD] — Weekly Review

### Shipped This Week
**[Work Domain]**
- [thing completed with impact — 1 line]

**[Company Domain]**
- [thing completed — 1 line]

**Personal**
- [thing completed — 1 line]

### Goals Progress
**Work Goals**
- [goal] — [progress this week, trajectory]

**Personal Goals**
- [learning goal] — [what you learned/practiced]
- [health/life goal] — [progress]

### AI Collaboration
- [N sessions this week across M projects]
- Most active: [repo — N sessions]
(skip if no session logs available)

### Carrying Into Next Week
- [task/project — next step]
- [task/project — next step]

### Next Week Preview
- [Key meetings or deadlines]
- [Any scheduled launches, reviews, or milestones]

---

Week score: [shipped X items, Y meetings, Z learning sessions]
Highlight: [single best thing that happened this week]
```

## Step 3: Update Journal

Create a weekly summary entry: `<pka>/personal/journal/YYYY/MM/YYYY-MM-DD-weekly.md`

```yaml
---
title: Week of Month DD-DD
created: YYYY-MM-DD
type: weekly-review
---
```

Include the full review content so it's searchable later.

## Tone
- Zoom out. This is about trajectory, not daily tasks.
- Celebrate momentum: "Third week in a row hitting learning goals."
- Flag drift: "Work project stalled — blocked on API access since Tuesday."
- End with energy for next week, not exhaustion from this one.
