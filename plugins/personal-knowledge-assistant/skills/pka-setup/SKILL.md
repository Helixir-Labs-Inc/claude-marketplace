---
name: pka-setup
description: "Interactive setup interview for the Personal Knowledge Assistant. Creates your personalized PKA folder with domains, file storage mappings, and agent configuration. Use when: 'set up pka', 'pka setup', 'create my knowledge base', 'set up my PKM'."
---

# PKA Setup Interview

You are setting up a Personal Knowledge Assistant for a new user. This is an interactive interview — ask questions, wait for answers, then scaffold everything based on their responses.

## Important Rules
- Ask ONE question group at a time. Do not dump all questions at once.
- Use the AskUserQuestion tool for each question group.
- Be conversational, not robotic. Explain WHY you're asking.
- Provide sensible defaults so the user can just hit enter for most things.
- After gathering all info, scaffold everything in ONE pass.
- **PKA is completely independent from flow-next, .flow/, Linear tasks, or any other task system.** PKA tracks focus items in journal entries only. Never reference or integrate with flow-next unless the user explicitly asks.

---

## Interview Flow

### Step 1: Welcome & Name

Say:
```
Welcome to PKA setup! I'll ask a few questions to understand how your life is organized, then build your personal knowledge system.

This takes about 5 minutes. Everything stays on your machine — nothing is shared.
```

Ask: **What's your first name?** (Used in your CLAUDE.md and journal templates.)

### Step 2: Life Domains

Explain:
```
PKA organizes everything into "domains" — the main areas of your life.
Most people have 2-4: personal life, their employer, maybe a side business or freelance work.
```

Ask: **What are the main domains in your life?** Give examples:
- "Personal, and my employer Acme Corp"
- "Personal, my company FooBar LLC, and my day job at BigCo"
- "Personal, freelance clients, and a side project"

### Step 3: Domain Details (loop for each domain)

For each domain the user named, ask:

**For personal domain** (always exists):
```
For your personal life — where do you keep important files like tax docs, medical records, etc.?

Common options:
1. ~/Documents/ (default — syncs via iCloud on Mac)
2. Google Drive
3. OneDrive
4. Dropbox
5. A specific folder (tell me the path)
```

Also ask:
- **What's your personal email?** (for calendar/email integration)
- **What are the key areas you want to track?** Suggest defaults: health, finance, family, learning, career, legal. They can add/remove.

**For work/company domains:**
```
For [domain name] — a few quick questions:

1. Where are the files stored? (Google Drive folder, SharePoint, local, etc.)
2. What email is associated with it?
3. Any sub-areas? (e.g., for a company: clients, finance, operations)
```

### Step 4: Work Schedule

Ask:
```
What are your typical work hours? (default: 8am-5pm, Mon-Fri)

During work hours, I'll prioritize work tasks and keep personal stuff as brief reminders.
After hours, I'll flip to personal goals and only show urgent work items.
```

### Step 5: Features & Integrations

Ask:
```
Which features do you want enabled? You can change these later.

**Planning & Reviews** (uses your PKA notes and journal only):
- [x] Morning planning (daily kickoff with top-3 focus items)
- [x] Daily review (end of day check-in)
- [x] Weekly review (Friday retrospective)
- [x] Inbox triage (file organization from inbox folders)

**Integrations** (requires MCP connections — I'll check what's available):
- [ ] Google Calendar — surface today's events in planning
- [ ] Gmail — surface emails needing response
- [ ] Linear — track work issues
- [ ] Slack — check for unread DMs/mentions
- [ ] Actual Budget — financial awareness

Just tell me which integrations you want, or say "all" / "none".
```

After the user answers, check which MCP tools are actually available (try calling them). Report which ones are connected and which need setup. Only enable what's both wanted AND connected.

### Step 6: Task Management Style

Ask:
```
How do you prefer to see your tasks?

1. **Top-3 batching** — I show you 3 things at a time. Finish those, get 3 more. Good if you have ADHD or get overwhelmed by long lists. (recommended)
2. **Priority list** — I show a ranked list, you pick what to work on.
3. **Time-blocked** — I assign tasks to time slots based on your calendar.

Note: PKA has its own lightweight task tracking in your journal. It does NOT
use flow-next or any other task system — those are completely separate tools.
```

### Step 7: PKA Folder Location

Ask:
```
Where should your PKA folder live? (default: ~/pka/)

This is where all your notes, journals, and project docs go. It's a git repo — you can clone it to other devices.
```

### Step 8: Confirm & Scaffold

Present a summary:
```
Here's what I'll set up:

📁 PKA Location: ~/pka/

Domains:
  - personal/ → files at ~/Documents/Personal/ (iCloud)
  - [company]/ → files at [Google Drive path]
  - [employer]/ → files at [path]

Email accounts:
  - personal@gmail.com → personal domain
  - work@company.com → employer domain

Enabled integrations: Calendar, Gmail, Linear (or whichever were selected)
Disabled: Slack, Actual Budget (or whichever were opted out)

Schedule: 8am-5pm Mon-Fri
Task style: Top-3 batching

Ready to scaffold? (yes/no)
```

### Step 9: Build Everything

On confirmation, create the full structure:

1. **Create PKA directory** at chosen location
2. **Initialize git repo** with `.gitignore`
3. **Create domain folders** with area docs for each domain:
   - For personal: health.md, finance.md, family.md, learning/, career/, journal/, notes/, projects/, meetings/
   - For work domains: notes/, projects/, meetings/, plus any sub-areas they specified
   - Area docs (`.md` at domain root) include a `Files:` reference to the storage mirror path
4. **Create inbox folders** (gitignored): inbox/inbox-personal/, inbox/inbox-[domain]/, etc.
5. **Create shared folders**: templates/, meta/
6. **Write CLAUDE.md** with (include ONLY enabled integrations):
   - Domain structure and routing rules
   - File storage mapping (domain → path)
   - Schedule awareness (work hours, personal hours)
   - Task management style preference
   - Email/calendar account mapping
   - Inbox triage workflow
   - Note conventions (frontmatter, linking)
   - MCP integration references
7. **Write meta files**:
   - `meta/file-locations.md` — domain → file storage path map
   - `meta/device-setup.md` — machine-specific paths and tool checklist
   - `meta/workspaces.md` — workspace definitions for apps
8. **Write templates**: meeting-note.md, journal-entry.md, project-kickoff.md, learning-topic.md
9. **Write setup.sh** — bootstrap script for new devices
10. **Write README.md** — quick reference
11. **Initial git commit**

### Step 9: Post-Setup

After scaffolding, tell the user:

```
PKA is ready at [path].

To start using it:
  cd [path] && claude

Available commands:
  /morning-planning — start your day
  /daily-review — end of day check-in
  /weekly-review — Friday retrospective
  /next-3 — get your next 3 focus items
  /triage-inbox — process inbox files

Pro tip: Keep a terminal window with Claude running from your PKA folder
at all times — your personal knowledge assistant is always a message away.
```

Check which MCP integrations are available (Gmail, Calendar, Linear, Slack) and tell the user which accounts are connected and which need setup.
