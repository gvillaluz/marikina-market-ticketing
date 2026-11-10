# Step 7, slice 3d — the enforcer's weekly phone summary (closed 2026-11-11)

Part of "dashboard, reports and exports against hand-worked totals", split on 2026-11-07 into 3a dashboard, 3b reports page and downloads, 3c analytics charts, 3d the enforcer's phone summary. This note covers 3d only. Pull request: #21 (commit `c04b903`, branch `enforcer-week-3d`, from `main` 84ce29a).

Before the slice, the earlier evidence was checked first (user asked to close 3d only if it already proved the criterion). It did not: no server test covered the phone's count, the old phone-dashboard evidence was for the removed vendor dashboard, the enforcer-summary evidence covered the ticket and inspection lists only, and the phone's own dashboard tests feed in made-up numbers. The count also used UTC days.

Approved by the user on 2026-11-11 with "calendar week" (Monday to Sunday, Manila time). Real-phone check skipped by user decision.

## What changed (server only)

The phone's "This week's overview" (`GET /api/enforcer/tickets/dashboard`) counted from midnight UTC seven days ago, so the window moved forward at 8 AM Manila time and included last week's records. It now counts the signed-in enforcer's warnings and tickets from **Monday 00:00 to the next Monday 00:00, Manila time**. Each saved record counts once; unregistered vendors count; another enforcer's records never count.

- `TicketService.cs`: optional clock (same pattern as `AdminAnalyticsService`); works out the Manila week and passes its UTC range to the repository.
- `TicketRepository.cs` and `ITicketRepository.cs`: `GetTicketCountAsync(enforcerId, startUtc, endUtc)` counts between the given start and end.
- Test: `MarikinaMarket.Tests/EnforcerSummaryTests.cs`.

API contract (form unchanged): `GET /api/enforcer/tickets/dashboard`, MarketEnforcer only; no request body; response `{ ticket_recorded, warning_recorded, total_recorded }` for this calendar week in Manila time; 401 not signed in, 403 other roles. Only the phone uses this route; its wording already says "this week", so it needed no change. No website, database or package change.

## Evidence

- **New server test** `Phone_summary_counts_this_Manila_calendar_week_for_the_signed_in_enforcer`. Hand-worked records: a ticket Mon 9 Nov 00:30 Manila (Sunday in UTC), an unregistered vendor's ticket with two violations Wed 11 Nov, an unregistered vendor's warning Tue 10 Nov (all counted); a warning Sun 8 Nov 23:30 Manila, a ticket Thu 5 Nov and another enforcer's ticket (not counted). Expected by hand: Wed 11 Nov 10:00 Manila gives 2 tickets, 1 warning, total 3; Sun 15 Nov 23:59 the same; Mon 16 Nov 00:00 gives 0, 0, 0. Written first; it failed against the old code (no clock to set "now"). **5 deliberate breaks, 5 caught**: week in UTC (got 1, 1, 2), week starting Sunday (2, 2, 4), back to the old rolling 7 days (3, 2, 5), enforcer check dropped (3, 1, 4), unregistered vendors skipped (1, 0, 1). The files were restored byte for byte after each break.
- **Server:** build 0 errors, 8 warnings (all existing code or packages); 878 passed, 2 skipped (the usual two), 0 failed. The backup tests need `BACKUP_TEST_TEMP_ROOT`, `TEMP`, `TMP` and `TMPDIR` set to a throwaway folder.
- **Live check, 8 of 8 passed** (`evidence/enforcer-week-3d-live/`, git-ignored; `expected.md` written by hand first; `live-result.json`). Real server from worktree `mmt-enforcer-week-3d`, database `marikina_market_e2e`, at Wed 11 Nov 04:51 Manila time. All 13 records belong to the test enforcer. The test enforcer got **7 tickets, 1 warning, total 8** (tickets #6 to #9, #11, #12, #14 and warning #13; #1 to #5 are last week, including #5 at 00:44 Sunday Manila time), matching the hand-worked numbers and a raw database count using the database's own Monday-start week. The old code would have answered 11, 1, 12 at that hour. The response keeps exactly its three fields. No sign-in 401; Head Admin 403.
- Changes made to the test database: 2 sign-in code rows only. The server started for the check was stopped afterwards.

## Limits

- Not checked on a real phone (user decision): the phone code is unchanged, and its existing tests cover how it shows the three numbers it receives. iPhone not tested.
- On Monday mornings the phone shows zeros and "No activity this week" until the first record of the week. This is correct for a calendar week but differs from the old behaviour.

## Noticed, not fixed

- The website dashboard's "today" cards still use the real clock with the same kind of UTC gap (noted in 3a).
- Existing security warning on server package `System.Security.Cryptography.Pkcs` 10.0.0.
