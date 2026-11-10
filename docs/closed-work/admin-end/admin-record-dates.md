# Admin end — record dates: warning due date and last-updated time (closed 2026-11-11)

Reported by the user on 2026-11-11: a warning's page showed "DUE DATE — (Invalid date)" in red, and "Last updated —" was blank on every record page. The user approved the plan on 2026-11-11, with the recommended choice for the warning page (hide the due-date line when there is no due date).

Pull request: #23 (merged 2026-11-10 21:39 UTC, which is 2026-11-11 in Manila; merge commit `152e9fe`). Branch `admin-detail-fixes`, commit `d57937c`, first cut from `main` 84ce29a, then rebased onto `main` a26ce13 (which includes PRs #20 to #22) before the PR was opened.

Cause, checked in code: warnings never get a due date, and the page printed the empty date as a dash and "(Invalid date)". The admin ticket detail response never included the record's last-updated time, so the page showed a dash.

## What changed

- **Server:** the admin ticket detail response now includes `updatedAt` (the record's last-updated time). Nothing was removed or renamed. Only the website admin record page uses this route; the mobile app does not call it.
- **Website:** a record with no due date (every warning) shows no DUE DATE line. Fines and tickets with a due date are unchanged.

Route (request and error cases unchanged): `GET /api/admin/tickets/{ticketId}`. Response gains `updatedAt` (date and time). No database or package change.

Files: server `MarikinaMarket.API/Application/DTOs/Tickets/Response/AdminTicketDetailResponse.cs` and `MarikinaMarket.API/Infrastructure/Repositories/TicketRepository.cs`; test `MarikinaMarket.Tests/AdminTicketDetailTests.cs`. Website, under `marikina-market-web/src/features/tickets/`: `pages/TicketDetailPage.tsx` and `admin-record-dates.test.mjs` (new).

## Evidence

- **Server test:** the new test `Repository_includes_last_updated_time_in_admin_warning_detail` failed to compile before the change (the response had no last-updated field) and passes after. The 19 tests in `AdminTicketDetailTests` pass.
- **Website test:** `admin-record-dates.test.mjs`, 2 checks. The warning check failed before the change ("Invalid date" shown) and passes after. The last-updated check passes, but its fixture supplies the time itself, so it proves the page shows the value, not that the server sends it. The server test covers that.
- **Server suite (after rebase on `main`):** build 0 errors. 828 passed, 22 failed, 2 skipped. All 22 failures are backup tests (`BackupCoordinationTests`, `BackupRetentionTests`, `AutomaticBackupServiceTests`). They also fail on `main` without this change, checked by stashing the change and re-running the backup tests (22 failed both ways).
- **Website suite (after rebase):** build passes (existing large-file warning only). All 165 Node tests pass.
- **Live check, 7 of 7 passed** (`evidence/admin-record-dates-live/`, in the main folder and not committed; `expected.md` written by hand first; `live-result.json`; screenshots). Real website and server from the worktree, database `marikina_market_e2e`, headless Chrome, Head Admin.
  - Warning WRN-0013: "Last updated Nov 9, 2026, 6:42 PM" shown; no DUE DATE; no "Invalid date".
  - Ticket 6 (control number 5): "Last updated Nov 9, 2026, 2:23 AM"; DUE DATE "Nov 14, 2026, 2:23 AM (3 days left)".
  - 390 px, warning 13: no sideways scrolling; last-updated shown; no DUE DATE.
  - Database after: records 13 and 6 unchanged (status, version, updated time).
  - Changes to the test database: sign-in code rows only, as in the earlier checks.

## Limits

- The live check ran on the branch before the rebase onto `main`. That branch did not include PRs #20 to #22. After the rebase, only the automated checks ran; the live check was not repeated.
- The live check used Head Admin only. Admin Officer was not checked live.
- The live check ran before the change, so the old behavior was only shown by the automated tests, not live.
- The vendor-facing ticket page may also lack the last-updated time. This was not checked and is not in this change.
- The PR description says the "Paid" fallback is still on `main`. That was wrong: PR #20 removed it, as recorded in `warnings-no-status.md`.
