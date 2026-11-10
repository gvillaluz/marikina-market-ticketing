# Step 7, slice 3a — dashboard (closed 2026-11-11)

Closed by the user on 2026-11-11. Part of "dashboard, reports and exports against hand-worked totals", which was split on 2026-11-07 into 3a dashboard, 3b reports page and downloads, 3c analytics charts, 3d the enforcer's phone summary. This note covers 3a only. Pull request: #17 (opened 2026-11-11, merged by the user; local `main` fast-forwarded to `3ec7c79`).

## What changed

Website dashboard counters are now **Warnings today**, **Tickets today**, **Open tickets** and **Active businesses**. Removed: "Inspections today" (it mixed warnings and tickets), "Pending applications", the registration panel ("Registration pipeline"), the "Vendor registrations" shortcut and the "registrations awaiting review" alert. The "Vendor directory" shortcut is now "Businesses (Manage business records)". Tickets and warnings of unregistered vendors (no business record) count like any other.

API: `GET /api/dashboard/summary` (Head Admin, Admin Officer). Metrics `warnings_today`, `tickets_today`, `open_tickets`, `active_businesses`; removed `inspections_today`, `active_vendors`, `pending_registrations`. Attention items: only `OpenTickets`. Errors unchanged: 401 not signed in, 403 other roles. Only the website uses this route. No database change.

Files (server): `TicketRepository.cs`, `VendorRepository.cs`, `IVendorRepository.cs`, `DashboardService.cs`, `DashboardSummaryResponse.cs`, `DashboardTicketCounts.cs`, deleted `DashboardVendorCounts.cs`; tests `DashboardSummaryTests.cs`, `AnalyticsCalculationTests.cs`. Website: `DashboardPage.tsx`, `DashboardPage.module.css`, `dashboard.types.ts`, `dashboard.validation.ts`, `DashboardAttentionItem.tsx`, `features/vendors/index.ts`, deleted `DashboardRegistrationPipeline.tsx` and `.module.css` and `useDashboardRegistrationStatus.ts`; test `navigation.test.mjs`.

## Evidence

Built 2026-11-07 on an older copy of the project; on 2026-11-11 the copy was moved forward to `main` 6e552f5 (no clashes, no package changes) and everything was run again.

- **Server tests:** build 0 errors, 8 warnings, all in existing code or packages. 875 passed, 2 skipped (the usual two), 0 failed. The backup tests need `BACKUP_TEST_TEMP_ROOT`, `TEMP` and `TMP` set to a throwaway folder (`TMPDIR` alone is not enough on Windows).
- **New test added 2026-11-11:** `Dashboard_counts_tickets_and_warnings_for_unregistered_vendors`. Today: a warning and a waiting ticket for a registered business; a warning, a waiting ticket and a paid ticket for unregistered vendors. Worked out by hand: 2 warnings, 3 tickets, 2 open. Deliberate break (count only tickets that have a business) failed it: it expected 2 and got 1. The file was put back and checked identical before the final run.
- **Earlier breaks (2026-11-07):** 3 of 3 website and 4 of 5 server caught. Not caught: using the UTC date instead of the Manila date for "today", which only shows between 00:00 and 08:00 Manila because the dashboard reads the real clock.
- **Website:** build passes (existing large-file warning only); 180 of 180 Node tests.
- **Live check, 30 of 30 passed** (`evidence/dashboard-3a-live/`, `expected.md` written by hand first, `results.md`, `live-result.json`, screenshots; the folder is git-ignored). Real server and website from the worktree, database `marikina_market_e2e`, headless Chrome. Head Admin dashboard showed 0 / 0 / 11 / 2 as worked out from the database; 7 shortcuts including Businesses; old wording gone; "Needs attention" "11 Open tickets". Waiving ticket 12 (an unregistered vendor's) took Open tickets to 10 and putting it back to Pending returned 11 (Paid was not used: it needs a receipt photo, which would upload to storage that locks for a year). Reload asks to sign in again. With the dashboard request blocked: "Try again" shown, no numbers; after lifting the block it recovered. Server: 401 not signed in, 403 enforcer, 200 Head Admin with exactly the four metrics. 390px phone width: no sideways scrolling, also in the error state.
- Nothing was uploaded to evidence storage. Ticket 12 ended as it started (Pending); its status change left two audit rows and its version number moved on.
- The main folder's own server and website (running the old dashboard, started by someone else) were stopped with the user's permission to free the ports; the servers started for the check were stopped afterwards.

## Limits

- Admin Officer not checked live (no test account).
- Non-zero "Warnings today" and "Tickets today" are covered by server tests only; a live record needs photos that cannot be deleted for a year. The 3d phone session could check them if wanted.
- The Manila-versus-UTC "today" gap above is not closed (an adjustable clock like the analytics `AnalyticsClock` would fix it; outside this slice).
- Website only; iPhone does not apply.

## Noticed, not fixed

- Dashboard "Recent activity" labels old entries from the business module "VendorRegistration".
- Reports count a ticket with no fine amount as ₱0 (look at this in 3b).
- Existing security warning on server package `System.Security.Cryptography.Pkcs` 10.0.0.
- The website has no formatter installed; 3a was formatted by hand to match the existing style.
