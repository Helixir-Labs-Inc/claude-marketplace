---
name: triage-inbox
description: "Process files in the ~/Documents inbox folders — rename, tag, and file into the correct workspace or notes vault. Also handles Downloads. Use when: 'triage inbox', 'organize inbox', 'process files', 'clean inbox', 'file these', 'organize downloads'. Can run on-demand or as a loop."
---

# Inbox Triage — File & Note Organization

Read `~/pka/CLAUDE.md` first — it is the contract (locations, routing rules, naming, tags). `~/pka/meta/file-locations.md` has the full path map. Core rule: **`~/Documents` = files, `~/Notes` = markdown vaults.**

---

## Step 1: Scan the capture points

- `~/Documents/Inbox - Personal/`
- `~/Documents/Inbox - Helixir/`
- `~/Documents/Inbox - Webvar/`
- `~/Downloads/` — only files modified in the last 24 hours

These are the ONLY inboxes. List what's found. If nothing: "All inboxes clear." and stop.

## Step 2: Classify each item

1. **Domain** — the inbox folder says it (`Inbox - Personal` → Personal). For Downloads, infer from content (read PDFs/images). Employment paperwork (TD1/T4/pay stub/ROE/offer letter, any employer) is ALWAYS Personal → `Areas/Career/Employment/<Employer>/`.

2. **Note or file?**
   - Markdown knowledge (ideas, meeting notes, journal fragments) → the domain **vault**: `~/Notes/<Domain>/` (Inbox if unsorted, Daily for dated journal, Meetings, People, Reference…). Apply YAML frontmatter per the contract.
   - Everything else (and `.md` that is really a *document*, e.g. exported contract) → the domain **file workspace**.

3. **Category** (files):
   | If the document is... | Category | Example |
   |----------------------|----------|---------|
   | Proof of purchase | `receipt` | pharmacy receipt, Amazon order |
   | Bill to/from someone | `invoice` | freelance invoice, utility bill |
   | Signed agreement, SOW, terms | `contract` | NDA, engagement letter |
   | Government tax form/filing | `tax` | T4, notice of assessment |
   | Bank/card periodic summary | `statement` | BMO chequing January statement |
   | Employment verification/offer/termination | `legal` | employment letter |
   | Doctor/hospital/pharmacy record | `medical` | lab results, prescription |
   | Meeting record, memo | `note` | meeting minutes (→ usually vault) |
   | UI capture, error, visual reference | `screenshot` | dashboard state |

4. **Target folder** (files — plain PARA, no numbered folders ever):
   - `receipt`/`invoice` → `<workspace>/Areas/Finance/Receipts/YYYY/` (or `Invoices/`)
   - `statement` → `<workspace>/Areas/Finance/Statements/`
   - `tax` → `<workspace>/Areas/Finance/Taxes/YYYY/` (never re-sort a year that has Return + NOA)
   - `medical` → `Personal Documents/Areas/Health/YYYY/`
   - `contract`/`legal` → `<workspace>/Areas/Legal/` (employment docs → Personal `Areas/Career/Employment/<Employer>/`)
   - `screenshot` → relevant project folder under `<workspace>/Projects/`
   - Employer-paid receipts (Wispr Flow, ChatGPT Pro, Anthropic Claude Max) → `Webvar Documents/Areas/Finance/Receipts/YYYY/`
   - Use the **document date** for YYYY. Year folders auto-create; any other new folder needs user confirmation — scan 2 levels first, the right folder almost certainly exists.

5. **New filename**: `YYYY-MM-DD_category_source_description[_amount].ext` — date from content; source lowercase-hyphenated (`shoppers-drug-mart`, `td-bank`); description 2–4 words; amount on receipts/invoices only.

6. **Finder tags** (all that match): `Medical`, `Childcare`, `Home Office`, `Tax Claimable` (personally deductible), `Corporate Expense` (Helixir), `Reimbursable` (client-billable).

## Step 3: Dedup check

Before filing, check the target for an existing file with the same date + source + category. If found: compare content (hash); identical → skip and report; different → ask (replace / keep both with `_v2` / skip).

## Step 4: Present plan

Show the triage plan BEFORE executing, grouped by domain — table of: current name → new name → destination → tags. Proceed on confirmation. (Loop mode: auto-execute obvious receipts/invoices, queue ambiguous ones.)

## Step 5: Execute

1. Move + rename in one operation (never delete the original — it moves).
2. `tag -a "Tag Name" "<filepath>"` for each tag.
3. Spotlight comment: `xattr -w com.apple.metadata:kMDItemComment "original: <original-filename> | <keywords>" "<filepath>"` (vendor, type, purpose, amount) so `mdfind` finds it.
4. Verify the file exists at the destination.
5. If it warrants a note (contract, key receipt), offer to create one in the domain vault with a `File:` absolute-path reference.

## Step 6: Report

```
Triaged X items:
- N → Personal Documents/Areas/Finance/Receipts/2026/
- N → ~/Notes/Webvar/Meetings/
- N skipped (need clarification)
```

## Finding filed documents later

1. Spotlight: `mdfind "kMDItemComment == '*<keyword>*'" -onlyin ~/Documents/`, `mdfind "kMDItemUserTags == 'Tax Claimable'" -onlyin ~/Documents/`
2. Filename pattern: `find ~/Documents -name "*_receipt_*<vendor>*"`
3. Notes: search the domain vault (`grep -ri <term> ~/Notes/<Domain>/`)
Never search or file into `~/Library/Mobile Documents/com~apple~CloudDocs/Backups/` — that's the read-only archive (check its `_MANIFEST.md` only when explicitly hunting something old).

## Special: Downloads

Only files from the last 24h. Ignore `.dmg`/`.pkg`/`.app`/`.zip` installers. Ask before moving anything — it's a shared space.

## Special: Screenshots

Read the image; if clearly project-related, file under that project with `YYYY-MM-DD_screenshot_<project>_<description>.png`; if ambiguous, ask.

## Loop mode (`/loop 5m /triage-inbox`)

Run silently unless files are found. Auto-file obvious items (clear receipts/invoices), report a summary; batch questions for ambiguous items — never interrupt mid-task.

## Mercury receipts (email)

Check Gmail for Mercury "requires a receipt" emails; find the matching vendor receipt email and forward to receipts@mercury.com.
