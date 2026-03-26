---
name: triage-inbox
description: "Process files in inbox folders — rename, tag, and move to proper file storage. Also handles Downloads folder. Use when: 'triage inbox', 'organize inbox', 'process files', 'clean inbox', 'file these', 'organize downloads'. Can run on-demand or as a loop."
---

# Inbox Triage — File Organization

Read the CLAUDE.md in the PKA root for:
- Domain → file storage path mapping
- Naming convention rules
- Finder tag rules

## Step 1: Scan All Inboxes

Check these locations for files:
- `<pka-root>/inbox/personal/`
- `<pka-root>/inbox/helixir/` (or whatever domains exist)
- `<pka-root>/inbox/webvar/` (or whatever domains exist)
- `~/Downloads/` — only files modified in the last 24 hours

List what's found. If nothing: "All inboxes clear." and stop.

## Step 2: Classify Each File

For each file, determine:
1. **Domain** — which domain does it belong to? (from inbox subfolder, or infer from filename/content for Downloads)
2. **Category** — receipt, invoice, contract, tax, statement, legal, medical, note (use naming convention from CLAUDE.md)
3. **Target folder** — look up in `meta/file-locations.md`
4. **New filename** — apply naming convention: `YYYY-MM-DD_category_source_description[_amount].ext`
5. **Finder tags** — Medical, Tax Claimable, Corporate Expense, Childcare, Home Office, Reimbursable (as applicable)

For PDFs: read the file to extract date, vendor, amount if possible.
For screenshots: read the image to determine what it shows and which project it might relate to.
For unknown files: ask the user.

## Step 3: Present Plan

Show the triage plan BEFORE executing:

```
### Inbox Triage

| File | → New Name | → Destination | Tags |
|------|-----------|---------------|------|
| receipt.pdf | 2026-03-26_receipt_pharmacy_rx_45.50.pdf | ~/Documents/Personal/finance/ | Medical, Tax Claimable |
| screenshot.png | 2026-03-26_screenshot_webvar_dashboard.png | ~/Documents/Webvar/projects/ | |
| invoice.pdf | 2026-03-26_invoice_client_march.pdf | Google Drive: Helixir Labs/finance/ | Corporate Expense |

Proceed? (yes/no/edit)
```

## Step 4: Execute

On confirmation:
1. Rename the file
2. Move to target folder (create folder if needed — but ASK first if it's a new folder)
3. Apply Finder tags: `tag -a "Tag Name" "file path"`
4. If the file warrants a PKM note (contract, important receipt), offer to create one in the appropriate domain

## Step 5: Report

```
Triaged X files:
- X → personal/finance/
- X → helixir/finance/
- X → webvar/projects/
- X skipped (need clarification)
```

## Special: Downloads Folder

For `~/Downloads/`:
- Only look at files from the last 24 hours (don't reorganize old downloads)
- Ignore: `.dmg`, `.pkg`, `.app`, `.zip` (software installs — leave them)
- Process: `.pdf`, `.csv`, `.xlsx`, `.docx`, `.png`, `.jpg` (documents and screenshots)
- Ask before moving anything from Downloads — it's a shared space

## Special: Screenshots

macOS screenshots can be read visually. When triaging a screenshot:
1. Read the image to understand what it shows
2. If it's clearly related to a project (shows a specific UI, error, or page): suggest filing it in that project's file storage
3. If it's ambiguous: ask the user
4. Apply descriptive naming: `2026-03-26_screenshot_[project]_[description].png`

## Loop Mode

When running as a loop (via `/loop 5m /triage-inbox`):
- Run silently unless files are found
- For obvious files (receipts, invoices with clear metadata): triage automatically, report summary
- For ambiguous files: queue them and ask during the next user interaction
- Never interrupt the user mid-task for triage — batch questions
