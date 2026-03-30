---
name: boss-update
description: "Draft a progress update Slack DM for your boss. Two modes: daily (last 24h) and weekly (full week summary). Copies to clipboard for pasting. Use when: 'boss update', 'update for Max', 'update Max', 'weekly update', 'progress update', 'keep Max informed', 'boss-update weekly'. Scheduled 2pm Mon-Fri (daily), Friday (weekly)."
---

# Boss Update — Keep the Boss Informed

Draft a progress update for your boss as a Slack DM. Inspired by the "keep the boss informed" discipline — consistent format, regular cadence, no surprises.

Read the CLAUDE.md in the PKA root for domain config, repo locations, and connected accounts.

## Mode Detection

- Default (no argument, or `daily`): **Daily update** — last 24 hours
- Argument `weekly` or invoked on Friday after 2pm: **Weekly update** — last 7 days
- The user can always override: "do a weekly one" or "just today"

## Configuration

On first run, check the PKA root CLAUDE.md for a `## Boss Update Config` section. If missing, write one with these defaults (ask the user to confirm):

```markdown
## Boss Update Config

- **Boss:** Max (Maxim Tarasiouk)
- **Channel:** Slack DM with Max
- **Repos:** `~/_git/_helixir-clients/_webvar/` (all subdirectories)
- **Tone:** Professional but casual — first-name basis, no corporate speak
- **Schedule:** Daily at 2pm (Mon-Fri), weekly summary on Friday
```

If the config already exists, read it silently and proceed.

---

## Step 1: Gather Context (silently, in parallel)

Gather ALL of the following in parallel. Do not narrate what you're gathering.

**Git Activity:**
- Scan all repos under `~/_git/_helixir-clients/_webvar/` for commits in the time window
- For each repo with commits: `git -C <repo> log --oneline --since="<cutoff>" --author="Aric\|aric\|acbouwers"`
- Note: some repos may have worktree directories (skip `*-worktrees`, `*.worktrees`)
- Categorize commits: feature work, bug fixes, refactors, reviews, config/infra

**Linear Issues** (if MCP available):
- Issues assigned to Aric, updated in the time window
- Status changes (In Progress → Done, etc.)

**PKA Notes:**
- Recently modified files in `<pka-root>/webvar/`: `find <pka-root>/webvar/ -name "*.md" -mtime -1` (daily) or `-mtime -7` (weekly)
- Check journal entries for the time window — look for Focus items and completions

**Calendar** (if MCP available):
- Meetings from the time window — note any that involved planning, design reviews, or decisions

**Email** (if MCP available):
- Sent emails in the time window — may reveal communication, decisions, or coordination work

---

## Step 2: Classify Work into Sections

Take everything gathered and sort into these sections. **Only include sections that have content — omit empty sections entirely.**

| Section | What goes here |
|---------|---------------|
| **Released** | PRs merged to main/production, features shipped, deployments completed |
| **Development** | Active coding work — features in progress, bugs being fixed, code reviews done |
| **Design** | UI/UX work, design decisions, mockups, design reviews attended |
| **Planning** | Specs written, architecture decisions, technical planning, roadmap discussions |
| **WIP** | Started but not complete — carry-forward items with brief status |
| **Sales, Marketing, & Operations** | Non-dev work: client calls, demos, documentation, process improvements, hiring |
| **Blockers** | Anything preventing progress — waiting on someone, access issues, unclear requirements |

**Weekly only:**
| **Next Week** | Planned focus areas for the coming week |

### Classification Rules

- A PR that's merged → **Released** (not Development)
- A PR that's open/in review → **Development**
- A Linear ticket moved to Done → **Released**
- A Linear ticket In Progress → **Development** or **WIP** depending on how much is done
- Meeting notes about planning → **Planning**
- Meeting notes about design → **Design**
- If unsure, default to **Development**

---

## Step 3: Draft the Message

### Daily Format

```
Hey Max, quick update for [Day, Month DD]:

**Released**
- Merged [feature/fix] in [repo] — [one-line description]

**Development**
- Working on [feature] — [status in ≤10 words]
- Code review for [PR/feature] — [approved/requested changes]

**Planning**
- [Spec/decision/meeting outcome — one line]

**Blockers**
- [What's blocked — who/what is needed]
```

### Weekly Format

```
Hey Max, weekly update for week of [Month DD]:

**Released**
- [Shipped item — one line] ([repo])
- [Shipped item — one line] ([repo])

**Development**
- [Major dev work this week — status]

**Design**
- [Design work this week]

**Planning**
- [Specs, plans, architecture decisions this week]

**WIP (carrying into next week)**
- [In-progress item — what's left]

**Sales, Marketing, & Operations**
- [Non-dev work this week]

**Blockers**
- [Open blockers]

**Next Week**
- [Planned focus area 1]
- [Planned focus area 2]
```

### Drafting Rules

- **Conversational but professional.** First-name basis, no corporate jargon.
- **One line per item.** Max should be able to scan this in 30 seconds.
- **Repo names in parentheses** when relevant: `(wv-connect)`, `(wv-fe-monorepo)`
- **Omit empty sections entirely.** If there's no design work, don't show a Design heading.
- **Blockers last** (unless urgent — then mention at the top with a note).
- **Never fabricate work.** If git shows nothing, say "light commit day — focused on [X]" or ask the user what they worked on.
- **Don't over-detail.** "Implemented user search API" not "Added GET /api/users endpoint with pagination, filtering by name and email, and Drizzle query builder integration"

---

## Step 4: Present Draft

Show the draft to the user:

```
### Boss Update Draft (Daily/Weekly)

[the formatted message]

---
Send it? (yes / edit / skip)
```

---

## Step 5: Deliver

**On confirmation** ("yes", "send", "good", "yeah", "ok", "looks good"):
1. Copy the message to clipboard:
   ```bash
   printf '%s' "<message>" | pbcopy
   ```
2. Output: **"Copied to clipboard — paste in your DM with Max."**

**On edit request:**
- Ask what to change, revise, re-present

**On skip:**
- Output: "Skipped. Run `/boss-update` when you're ready."

---

## Step 6: Log to Journal

After sending (or skipping), append a one-line entry to today's journal:

```markdown
## Boss Update
- [Daily/Weekly] update sent to Max at [time]
- Key items: [2-3 word summary of main items]
```

This creates a record the weekly review can reference.

---

## Edge Cases

**No git commits in the window:**
- Don't show an empty Released/Development section
- Ask the user: "I don't see recent commits in Webvar repos. What were you working on today?"
- They may have been in meetings, planning, or working in a repo you didn't scan

**Friday afternoon:**
- If invoked after 2pm on Friday, default to weekly mode
- If invoked before 2pm on Friday, default to daily but mention: "Want the weekly summary instead? It's Friday."

**Monday morning:**
- Daily mode covers "since Friday" (last business day), not literally 24h
- Adjust the git log window: `--since="last Friday"`

**User adds context:**
- If the user says "also mention X" or "I was in meetings all day about Y", incorporate it into the draft and re-present

---

## Scheduling Reminders

This skill is invoked on-demand. To make it automatic:

- **In a persistent PKA session:** The `pkm-assistant` agent should remind at 2pm: "Time for your boss update — run `/boss-update`"
- **Via `/loop`:** Not ideal for this skill since it needs user review before sending
- **Via `/schedule`:** Can be set up as a cron trigger that runs and waits for user input

The morning-planning skill should include "Boss update at 2pm" in the Schedule section on weekdays.
