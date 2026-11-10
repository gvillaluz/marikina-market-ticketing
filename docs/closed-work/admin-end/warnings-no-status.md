# Admin end — warnings have no status (closed 2026-11-11)

Noted by the user on 2026-11-08: warnings have no status, so the server should refuse a status change on a warning and the website should not offer one. Plan approved by the user on 2026-11-11, including removing the "Paid" fallback in the ticket page header and the refusal wording. Pull request: #20 (commit `f1784cc`, branch `warning-status`, from `main` 644c3ff). Built in parallel with the vendor sign-up leftovers slice (another session, worktree `mmt-vendor-signup-cleanup`); the two touch different website files.

A warning is a non-monetary notice. It has no fine, no payment status and no settlement, and it does not count as an offense. Before this change the website offered "Change Status" on a warning and the server accepted Pending, Contested, Waived, Overdue and In Progress (only Paid and Cleared were refused, with the settlement message).

## What changed

- **Server:** any status change on a warning is refused with 400 "Warnings have no status and cannot be changed." and nothing is saved. The check runs after "not found" (404) and the stale-version check (409). The old warning line inside the Paid/Cleared settlement check ("Only violation tickets with completed settlement can be marked Paid or Cleared.") could no longer run, so it was removed.
- **Website:** a warning's ticket page shows no status in the header (the `?? "Paid"` fallback is gone) and no "Change Status" button, decided by record type, so a warning that still holds an old status shows none either. "View Full Ticket Record" stays. Tickets are unchanged.
- **Phone:** no change; it does not use this route.

Route (request and success response unchanged): `PATCH /api/admin/tickets/{id}/update-status` with `{ "new_status", "version" }`; Head Admin and Admin Officer only. New error: 400 for a warning. No database or package change.

Files: server `MarikinaMarket.API/Application/Services/TicketService.cs`, test `MarikinaMarket.Tests/TicketStatusSettlementTests.cs`. Website, under `marikina-market-web/src/features/tickets/`: `pages/TicketDetailPage.tsx`, `components/detail/TicketDetailHeader.tsx`, `components/detail/TicketDetailFooter.tsx`, `warning-status.test.mjs` (new). The plan named `hooks/useTicketStatusSelection.ts`; hiding the button in the footer was simpler and made that change unnecessary.

## Evidence

- **Server tests:** the narrow old warning test was replaced by `Warning_status_cannot_be_changed` (all 7 statuses, a warning stored with no status, checks the message and that nothing changed) and `Status_endpoint_returns_400_for_a_warning` (through the real route). All 8 failed before the change (5 statuses accepted, the endpoint returned 200; Paid and Cleared gave the old message) and pass after.
- **Website tests:** 3 new; the two warning tests failed before the change (the header showed "Paid" and "Pending") and pass after; the ticket test guards that tickets are unchanged.
- **Server:** build 0 errors, 4 warnings (the existing `System.Security.Cryptography.Pkcs` package notice); 883 passed, 2 skipped (the usual two), 0 failed.
- **Website:** build passes (existing large-file warning only); 183 of 183 Node tests.
- **Live check, 9 of 9 passed** (`evidence/warning-status-live/`, git-ignored; `expected.md` written by hand first; `live-result.json`; screenshots). Real server and website from worktree `mmt-warning-status`, database `marikina_market_e2e`, headless Chrome, Head Admin.
  - Warning 13 (WRN-0013, no business) and warning 1 (WRN-0001, still "Contested" from the old bug): no status in the header, no "Change Status", "View Full Ticket Record" shown. Ticket 12: "Pending" and "Change Status" shown.
  - Server, Head Admin: warning 13 to Waived and to Pending both refused with 400 and the message.
  - Database after: warnings 13 and 1 and ticket 12 unchanged (status, version, updated time); warning 13's change history unchanged. 390px: no sideways scrolling.
- Changes made to the test database: 1 sign-in code row. The servers started for the check were stopped afterwards.

## Limits

- Admin Officer not checked live (no test account). The route tests use the Head Admin role; the role rules are unchanged.
- Website and server only; iPhone and Android do not apply.

## Noticed, not fixed

- A warning's page shows "DUE DATE — (Invalid date)" in red.
- "Last updated —" is blank on every ticket page.
- Warning 1 in the test database keeps "Contested" and a "Status changed" history row from before the fix (correct history; no data change was made).
- Existing security warning on server package `System.Security.Cryptography.Pkcs` 10.0.0.
