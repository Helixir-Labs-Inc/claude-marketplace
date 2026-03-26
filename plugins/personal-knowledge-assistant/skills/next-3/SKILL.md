---
name: next-3
description: "Clear current focus batch and get the next 3 items. Use when: 'next 3', 'done', 'finished my 3', 'what's next', 'crushed it', 'next batch', 'more tasks'. Part of the ADHD-friendly top-3 batching system."
---

# Next 3 — Batch Focus Rotation

The user has completed (or wants to swap) their current top 3 focus items. Present the next batch.

## Step 1: Check Current State

- Read today's journal entry for the current `## Focus` section
- Mark completed items with ✅
- Check time of day to determine work vs personal priority weighting (read CLAUDE.md for schedule)

## Step 2: Gather Fresh Context

Quickly check (in parallel):
- Any new urgent emails or Slack messages since morning planning
- Any calendar events in the next 2 hours that need prep
- Inbox folders — anything new?
- Linear issues updated since last check (if available)

## Step 3: Present Next Batch

```
### ✅ Cleared
1. ~~[completed item]~~
2. ~~[completed item]~~
3. ~~[completed item]~~

Nice work. Here's your next 3:

### Next 3
1. **[Task]** — [why now]
2. **[Task]** — [why now]
3. **[Task]** — [why now]

Swap any? Or "go".
```

If the user hasn't finished all 3, show what's remaining:
```
### Progress
1. ✅ ~~[done]~~
2. ⏳ [still in progress]
3. ❌ [swapping out]

### Next 3
1. ⏳ [carry forward from above]
2. **[New task]** — [why now]
3. **[New task]** — [why now]
```

## Step 4: Update Journal

Update today's `## Focus` section:
- Mark completed items ✅
- Add the new batch under a `## Focus (Batch N)` heading
- Keep all batches visible so end-of-day review can count them

## Selection Rules
- Same rules as morning planning (see morning-planning skill)
- Avoid repeating the same TYPE of work back-to-back (if last 3 were all code, mix in a communication or planning task)
- If it's after 3pm: bias toward quick wins that can close before EOD
- If it's close to a meeting: include meeting prep if needed
- Always celebrate the cleared batch: "Nice work", "Crushed it", "Three down" — short and genuine
