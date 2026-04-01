---
name: weekly-review
description: "Weekly retrospective + boss recap email. Use when: 'weekly review', 'friday review', 'retro', 'what did I ship this week', 'week recap', 'boss update', 'weekly recap'. Thursday = boss recap email, Friday = personal review."
---

# Weekly Review

Read the CLAUDE.md in the PKA root to understand domains and goals.

This skill has two outputs:
1. **Boss Weekly Recap** (Thursday EOD) — structured email for Max in his required format
2. **Personal Retrospective** (Friday) — personal goals, trajectory, next week preview

When run on Thursday (or when the user says "boss recap", "weekly recap for Max"), prioritize the boss recap. When run on Friday, do both. When ambiguous, do both.

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

**Metrics (for boss recap):**
- Count measurable inputs: contacts enriched, emails sent, meetings booked, PRs merged, issues closed, deploys shipped, etc.
- Note any specific numbers from Linear, git, or session logs

## Step 2: Boss Weekly Recap Email

Draft an email reply to Max using this exact format. Calculate the ISO week number from today's date.

```
Week: [ISO week number]

**What I worked on this week**
- [Key activity, project, or deliverable — 1 line each]
- [Key activity, project, or deliverable — 1 line each]
- [...]

**Numbers / highlights**
- [Measurable inputs: PRs merged, issues closed, meetings, deploys, contacts enriched, emails sent, etc.]
- [Any notable wins or milestones]

**Blockers or challenges**
- [Anything slowing you down or where you need support]
- [Or: "None this week"]

**Plan for next week**
1. [Top priority]
2. [Second priority]
3. [Third priority]
```

**Tone:** Professional but casual — first-name basis, no corporate speak. Keep it concise and scannable. Focus on activity and inputs Max cares about. Don't pad with fluff.

**Present the draft to the user for review before sending.** After approval, draft it as a Gmail reply to Max's weekly recap thread (search Gmail for the original email from Max about weekly recaps).

## Step 3: Personal Retrospective

Skip this step if the user only asked for the boss recap. Include it on Fridays or when explicitly asked.

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

## Step 4: Update Journal

Create a weekly summary entry in the Personal workspace: `~/Documents/Personal Documents/02 Areas/Journal/YYYY/MM/YYYY-MM-DD-weekly.md`

```yaml
---
title: Week of Month DD-DD
created: YYYY-MM-DD
type: weekly-review
---
```

Include the full review content (both boss recap and personal retrospective) so it's searchable later.

## Tone
- Zoom out. This is about trajectory, not daily tasks.
- Celebrate momentum: "Third week in a row hitting learning goals."
- Flag drift: "Work project stalled — blocked on API access since Tuesday."
- End with energy for next week, not exhaustion from this one.
