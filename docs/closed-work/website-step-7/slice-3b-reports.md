# Step 7, slice 3b — reports page and downloads (closed 2026-11-11)

Part of "dashboard, reports and exports against hand-worked totals", split on 2026-11-07 into 3a dashboard, 3b reports page and downloads, 3c analytics charts, 3d the enforcer's phone summary. This note covers 3b only. Pull request: #18 (merged by the user on 2026-11-11, merge commit `644c3ff`; local `main` fast-forwarded to it and the worktree `mmt-reports-3b` removed; branch `reports-3b` kept).

3b was a **check-and-prove slice**: the Reports page, the saved reports and the CSV and PDF downloads were built in the original Phase 3, before the revision changed how records are kept. 3b proved they still give the right totals with today's records (unregistered vendors, tickets with several violations, warnings kept apart from tickets, blood-donation and community-service tickets). **No app code changed.** One server test was added.

Approved by the user on 2026-11-11 with option A: a ticket with no cash fine adds ₱0 to the money column and still counts as a ticket (no change to the column name or the page).

## What the report does (rules now confirmed by tests and a live check)

- Each saved warning and ticket issued on a Manila-time day in the chosen dates is counted once. A ticket with two violations is one ticket. Verified-but-not-submitted tickets are not records, so they are never counted.
- "Warnings issued" and "Tickets issued" are separate lines. A "Warning" report has no tickets line; a "Ticket" report has no warnings line.
- "Assessed Penalties" is the cash fines written on tickets, whether paid, unpaid or waived. Warnings and tickets with no cash fine (blood donation, community service) add ₱0.
- "Resolved records" are tickets that are Paid, Cleared or Waived; "Pending records" are every other ticket (Pending, Contested, Overdue, In Progress). Warnings are not in either line, only in "Warnings issued" and the Total.
- A saved report keeps its original numbers when tickets change later. A new preview reflects the change.
- The day follows Manila time: records issued at 02:23 Manila time on 9 Nov (8 Nov in UTC) are in the 9 Nov report.

No server contract changed. Routes (unchanged): `GET /api/admin/reports/preview?date=&type=`, `POST /api/admin/reports`, `GET /api/admin/reports?offset=`, `GET /api/admin/reports/{id}`; Head Admin and Admin Officer only (401 not signed in, 403 other roles, 400 bad dates or type, 404 unknown report). No database change.

## Evidence

- **New server test** `ReportCountsEachRecordOnceAndAddsOnlyCashFines` in `MarikinaMarket.Tests/ReportRepositoryTests.cs`. It runs the real report service over the real report query with hand-worked records: 2 warnings (one registered, one unregistered), a Paid 1,000 ticket with two violations, a Waived 300, a Pending 500 for an unregistered vendor, a Pending blood-donation ticket and a Pending community-service ticket (no amount), plus a Paid 999 ticket one tick before the day and a warning exactly at its end. Worked out by hand: warnings 2 / 0; tickets 5 / 1,800; resolved 2 / 1,300; pending 3 / 500; total 7 / 1,800; the "Ticket" and "Warning" types show only their own line. It passed on the first run (the behaviour already existed), so it was checked with deliberate breaks: skipping unregistered vendors failed it (expected 2 warnings, got 1); counting a waived ticket as unpaid failed it (expected 2 resolved, got 1). The file was put back, checked identical to `main` and touched before the final run.
- **Server:** build 0 errors, 8 warnings (all existing code or packages); 876 passed, 2 skipped (the usual two), 0 failed. The backup tests need `BACKUP_TEST_TEMP_ROOT`, `TEMP`, `TMP` and `TMPDIR` set to a throwaway folder.
- **Website:** build passes (existing large-file warning only); 180 of 180 Node tests.
- **Live check** (`evidence/reports-3b-live/`, git-ignored; `expected.md` written by hand first; real server and website from worktree `mmt-reports-3b`, database `marikina_market_e2e`, headless Chrome, Head Admin): **41 of 43 passed in the main run, then a follow-up run passed 9 of 9** (the two failures are explained below).
  - Report 1 (1 to 10 Nov): warnings 2 / ₱0, tickets 11 / ₱6,400, resolved 0 / ₱0, pending 11 / ₱6,400, total 13 / ₱6,400 on screen, in the saved database row, in the CSV and in the PDF (the PDF was rendered to an image and read).
  - Report 2 (9 Nov, includes the four tickets issued 02:23 to 02:24 Manila time): 1 / ₱0, 6 / ₱4,700, 0, 6 / ₱4,700, total 7 / ₱4,700, on screen, database, CSV and PDF. A one-day preview showed the same numbers and saved nothing.
  - "Ticket" only for 8 Nov (a ticket issued 00:44 Manila time): one ticket, ₱500, no warnings line. "Warning" only for 9 Nov: one warning, ₱0, no tickets line.
  - Waiving ticket 12 (unregistered vendor, community service): the server's preview showed resolved 1 / ₱0, pending 5 / ₱4,700 straight away; the saved Reports 1 and 2 and their database rows kept their original numbers; after setting it back to Pending the numbers returned.
  - Bad dates: "To before From" and "after today" each showed their message and saved nothing; the server returns 400 for reversed dates sent directly.
  - Reload asks to sign in again; both saved reports are still listed afterwards. 401 not signed in, 403 for the enforcer (history and preview), 200 for the Head Admin, 404 for a report that does not exist. 390px phone width: no sideways scrolling.
  - Database at the end: 13 records, ticket 12 Pending, exactly 2 saved reports.
- The two main-run failures: (1) the check for the "No reports yet" message read the page before the history finished loading; it is a script timing slip and **was not re-run**, because two reports are now saved and the app cannot delete them. The empty-history message is therefore not counted as checked live. (2) The check for new numbers after the waive failed because the page showed the earlier numbers (see "Noticed" below); the follow-up proved the server was right and that the page updates after a minute. A first follow-up run failed one step because the script never left the Reports page; it was fixed and rerun (first run kept as `live-result-followup-run1.json`).
- Nothing was uploaded to evidence storage. Changes made to the test database: sign-in code rows, 2 saved reports (permanent), ticket 12 waived and restored twice (so its audit history has extra rows, and its version number moved on).
- The main folder's own server (process 18284, started 01:41, with a connection to the default database) was stopped with the user's permission to free the ports; the servers started for the check were stopped afterwards.

## Limits

- Admin Officer not checked live (no test account). The server tests use both roles.
- The empty-history message ("No reports yet") not checked live (see above); the website's own browser check for it uses simulated responses.
- Website only; iPhone does not apply. The PDF is a picture of the report page, so its text cannot be selected or searched (existing behaviour).

## Noticed, not fixed

- **A preview can show numbers up to one minute old.** The website keeps each one-day preview in memory for 60 seconds (`staleTime: 60_000` in `main.tsx`; the history list asks every time). If someone previews a day, changes a ticket, and previews the same day again within a minute, the page shows the earlier numbers; the server is correct and after a minute (or after leaving and returning) the page is right. A saved report is not affected. Not fixed; needs its own approval (for example asking the server every time for previews).
- The money column is "assessed", not "collected": it includes unpaid and waived cash fines. The column is named "Assessed Penalties", so it matches; say so if a "collected" figure is wanted later.
- Existing security warning on server package `System.Security.Cryptography.Pkcs` 10.0.0.
