---
name: triage-inbox
description: "Process files in inbox folders — rename, tag, and move to proper file storage. Also handles Downloads folder. Use when: 'triage inbox', 'organize inbox', 'process files', 'clean inbox', 'file these', 'organize downloads'. Can run on-demand or as a loop."
---

# Inbox Triage — File Organization

Read the CLAUDE.md in the PKA root for:
- Domain → file storage path mapping (and `meta/file-locations.md` for full path map)
- Naming convention rules (from global CLAUDE.md / AGENTS.md)
- Finder tag rules

---

## Step 1: Scan All Inboxes

Check these locations for files:
- `<pka-root>/inbox/inbox-<domain>/` for each domain listed in CLAUDE.md
- `~/Downloads/` — only files modified in the last 24 hours

List what's found. If nothing: "All inboxes clear." and stop.

---

## Step 2: Classify Each File

For each file, determine all five fields:

1. **Domain** — which domain does it belong to?
   - Inbox subfolder determines domain directly (`inbox-personal/` → personal)
   - For Downloads, infer from content (read PDFs/images to determine)

2. **Category** — use this decision tree:
   | If the document is... | Category | Example |
   |----------------------|----------|---------|
   | Proof of purchase | `receipt` | pharmacy receipt, Amazon order |
   | Bill sent to or from someone | `invoice` | freelance invoice, utility bill |
   | Signed agreement, SOW, terms | `contract` | employment contract, NDA |
   | Government tax form or filing | `tax` | T4, notice of assessment |
   | Bank/credit card periodic summary | `statement` | TD chequing January statement |
   | Employment verification, offer, termination | `legal` | employment letter, offer letter |
   | Doctor/hospital/pharmacy record | `medical` | lab results, prescription record |
   | Meeting record, memo, note | `note` | meeting minutes, brain dump |
   | UI capture, error, visual reference | `screenshot` | Slack thread, dashboard state |

3. **Target folder** — route using category + year:

   Categories that use **year subfolders** (these accumulate over time):
   - `receipt` → `<storage-root>/finance/YYYY/`
   - `invoice` → `<storage-root>/finance/YYYY/`
   - `statement` → `<storage-root>/finance/YYYY/`
   - `tax` → `<storage-root>/finance/tax/YYYY/`
   - `medical` → `<storage-root>/health/YYYY/`

   Categories that use **flat folders** (few files, high importance):
   - `contract` → `<storage-root>/legal/`
   - `legal` → `<storage-root>/legal/` or `<storage-root>/career/` (employment docs)
   - `note` → `<storage-root>/notes/` or relevant project folder
   - `screenshot` → relevant project folder, or `<storage-root>/projects/`

   Use the document date for YYYY, not today's date. Create year folders on demand.

4. **New filename** — apply naming convention:
   ```
   YYYY-MM-DD_category_source_description[_amount].ext
   ```
   - **Date**: from document content, not file modification time
   - **Source**: lowercase, hyphens for spaces (e.g., `shoppers-drug-mart`, `td-bank`, `max-technologies`)
   - **Description**: 2-4 words, lowercase, hyphens. Specific enough to distinguish from similar docs
   - **Amount**: include on receipts/invoices, omit on everything else

5. **Finder tags** — apply all that match:
   | Tag | When |
   |-----|------|
   | `Medical` | Any health-related document |
   | `Childcare` | Childcare expenses |
   | `Home Office` | Home office deductions (T2125) |
   | `Tax Claimable` | Any personally tax-deductible item |
   | `Corporate Expense` | Helixir Labs business expense |
   | `Reimbursable` | Client-billable expense |

**Content extraction:**
- For PDFs: read the file to extract date, vendor/source, amount, and purpose
- For screenshots: read the image to determine what it shows and which project it relates to
- For unknown files: ask the user

---

## Step 3: Dedup Check

Before presenting the plan, check the target folder for existing files with the same date + source + category pattern. If a potential duplicate exists:
- Show both filenames and ask: "This looks similar to an existing file — replace, keep both, or skip?"
- To keep both, append a sequence suffix: `..._v2.pdf`

---

## Step 4: Present Plan

Show the triage plan BEFORE executing, grouped by domain:

```
### Inbox Triage

**Personal**
| File | → New Name | → Destination | Tags |
|------|-----------|---------------|------|
| receipt.pdf | 2026-03-26_receipt_pharmacy_rx_45.50.pdf | ~/Documents/Personal/finance/2026/ | Medical, Tax Claimable |

**Helixir**
| File | → New Name | → Destination | Tags |
|------|-----------|---------------|------|
| invoice.pdf | 2026-03-26_invoice_collegium_march.pdf | .../Helixir Labs/finance/2026/ | Corporate Expense |

Proceed? (yes/no/edit)
```

---

## Step 5: Execute

On confirmation, for each file:

1. **Create target folder** if needed (year folders are fine to auto-create; ask first for any new top-level category folder)
2. **Move + rename** the file in one operation
3. **Apply Finder tags**: `tag -a "Tag Name" "file path"`
4. **Set Spotlight comment** with searchable keywords:
   ```bash
   xattr -w com.apple.metadata:kMDItemComment "original: <original-filename> | <extracted-keywords>" "<new-filepath>"
   ```
   Keywords should include: vendor name, document type, purpose, amount — whatever was extracted from the content. This makes `mdfind` searches work across all filed documents.
5. **Verify** the file exists at the destination (quick `ls` check)
6. If the file warrants a PKM note (contract, important receipt, employment letter), offer to create one in the appropriate domain

---

## Step 6: Report

```
Triaged X files:
- X → personal/finance/2026/
- X → helixir/finance/2026/
- X skipped (need clarification)
```

---

## Finding Filed Documents Later

When the user asks to find a previously filed document, use these strategies in order:

1. **Spotlight search** (fastest, searches tags + comments + filenames):
   ```bash
   mdfind "kMDItemComment == '*employment*'" -onlyin ~/Documents/Personal/
   mdfind "kMDItemUserTags == 'Medical'" -onlyin ~/Documents/Personal/
   mdfind "kind:pdf name:receipt 2026" -onlyin ~/Documents/Personal/
   ```

2. **Filename pattern search** (when you know the category/source):
   ```bash
   find ~/Documents/Personal/ -name "*_receipt_*pharmacy*" -type f
   find ~/Documents/Personal/ -name "2026-03*" -type f
   ```

3. **Tag search** (for browsing by classification):
   ```bash
   tag -f "Tax Claimable" ~/Documents/Personal/
   mdfind "kMDItemUserTags == 'Corporate Expense'" -onlyin ~/path/
   ```

---

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
4. Apply descriptive naming: `YYYY-MM-DD_screenshot_[project]_[description].png`

---

## Loop Mode

When running as a loop (via `/loop 5m /triage-inbox`):
- Run silently unless files are found
- For obvious files (receipts, invoices with clear metadata): triage automatically, report summary
- For ambiguous files: queue them and ask during the next user interaction
- Never interrupt the user mid-task for triage — batch questions
