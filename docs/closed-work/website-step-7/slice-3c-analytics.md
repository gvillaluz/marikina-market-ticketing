# Step 7, slice 3c — analytics charts (closed 2026-11-11)

Part of "dashboard, reports and exports against hand-worked totals", split on 2026-11-07 into 3a dashboard, 3b reports page and downloads, 3c analytics charts, 3d the enforcer's phone summary. This note covers 3c only. Approved by the user on 2026-11-11 with option B (check and prove, plus a small website-only change). Pull request: #19 (commit `4695de5`, branch `analytics-3c`, from `main` 644c3ff).

3c was a **check-and-prove slice with one small display change**. The eight charts on the Violation Analytics page were built in the original Phase 3, before the revision changed how records are kept. 3c proved they still give the right totals with today's records (unregistered vendors, tickets with several violations, warnings kept apart from tickets, blood-donation and community-service tickets, Manila-time days and years).

## What the charts count (rules now confirmed by a test and a live check)

- **Tickets only:** the violation trend (by Manila month and the ticket's highest severity), the peak violation times (by Manila weekday and 4-hour block), the violation type distribution and the resolution rate. Each saved ticket counts once; a ticket with two violations in one category counts once in that category and once in each other category it touches.
- **Warnings and tickets:** the warning and ticket ratio, the market section chart and the hotspot ranking. Warnings and tickets are separate numbers.
- **Resolution rate:** tickets that are Paid, Cleared or Waived within 7 days of being issued, out of all tickets of the year.
- **Vendor risk ranking:** registered businesses only (an unregistered vendor has no business record); offenses are the business's tickets for the year; the risk score is 100 minus the business's current compliance score.
- The year is the Manila calendar year (year to date for the current year). Years below 3 or after the current year are refused (400).

## What changed (website only)

- Market Section Aggregation and Hotspot Ranking show warnings and tickets apart ("1 warning · 9 tickets"; separate Warnings and Tickets columns). Ranking, bar length and trend still use warnings plus tickets, and the subtitles say so.
- The word "inspection" is gone from the ratio card (now "Warning and Ticket Ratio"), the section chart and the hotspot table.
- The trend and peak-time charts say "Tickets only; warnings are not included."
- The hotspot table has a narrow-screen rule (tighter cell padding, long section names may wrap) so its five columns fit at 390px.

No server code, API contract, database or package changed. Routes (unchanged): `GET /api/admin/analytics/{violation-trend, peak-violation-times, violation-type-distribution, inspection-ratio, resolution-rate, market-section-aggregation, hotspot-ranking, vendor-risk-ranking}?year=`; Head Admin and Admin Officer only (401 not signed in, 403 other roles, 400 for a year below 3 or after the current year).

Files: server test `MarikinaMarket.Tests/AnalyticsCalculationTests.cs`. Website, all under `marikina-market-web/src/features/analytics/`: `components/MarketSectionAggregationChart.tsx` and `.module.css`, `components/HotspotRankingTable.tsx` and `.module.css`, `components/InspectionRatioCard.tsx`, `components/ViolationTrendChart.tsx`, `components/PeakViolationHeatmap.tsx`, `calculations.test.mjs`.

## Evidence

- **New server test** `Every_chart_counts_each_saved_record_once_with_unregistered_vendors_and_several_violations`. It runs the real analytics service over the real repository queries with hand-worked records: 4 tickets (one with two Sanitation violations and a Licensing one, two for unregistered vendors, a blood-donation and a community-service ticket, one paid after 3 days, one waived after 8 days, one waived after 1 day) and 2 warnings in 2026, plus last year's records. Worked out by hand: 2 warnings and 4 tickets (66.7% and 33.3%); 2 of 4 resolved within 7 days (50%); Sanitation 1, Licensing 2, Noise 2 of 4 tickets; Produce 2 warnings and 3 tickets, Meat 0 and 1; hotspots Produce 5 Rising from 0 and Meat 1 Falling from 2; the one registered business 2 offenses, High, risk 30. It passed on the first run (the behaviour already existed), so it was checked with **6 deliberate breaks, 6 caught** (skip unregistered vendors in the warning and ticket counts: expected 2, got 1; peak times include warnings: expected 4, got 6; peak times use UTC instead of Manila: expected 1, got 0; Waived not counted as resolved: expected 2, got 1; business ranking counts warnings: expected 2 offenses, got 3; categories counted per violation: expected 1, got 2). The repository file was put back from git after each break.
- **Website tests:** 3 new, written first and seen failing for the old wording; 4 deliberate breaks, 4 caught (hotspot warnings column shows the total; plural always adds "s"; the tickets-only note dropped; the old section subtitle put back).
- **Server:** build 0 errors, 8 warnings (all existing code or packages); 877 passed, 2 skipped (the usual two), 0 failed. The backup tests need `BACKUP_TEST_TEMP_ROOT`, `TEMP`, `TMP` and `TMPDIR` set to a throwaway folder.
- **Website:** build passes (existing large-file warning only); 183 of 183 Node tests (180 before plus 3). Re-run after the last style change.
- **Live check, 49 of 49 passed** (`evidence/analytics-3c-live/`, git-ignored; `expected.md` written by hand first from a read-only look at the database; `live-result.json`; screenshots). Real server and website from worktree `mmt-analytics-3c`, database `marikina_market_e2e` (13 records, all November 2026), headless Chrome, Head Admin.
  - Database cross-checks (raw SQL): 2 warnings and 11 tickets; categories Others 6, Traffic 2, WeightMeasures 2, DressCode 1; the Manila weekday and block cells; warnings and tickets per section; tickets per registered business.
  - Page, year 2026, before and after signing in again: ratio 15% with 2 warnings, 11 tickets and "13 warnings and tickets in total"; resolution 0% and "0 of 11 tickets"; trend flat except November at 11 on the Low line; the 8 non-zero heat-map cells (Mon 12AM-4AM = 4 for the tickets issued 02:23 to 02:24 Manila time, which are Sunday in UTC; Sun 12AM-4AM = 1 for the 00:44 ticket, which is Saturday in UTC); distribution 55%, 18%, 18%, 9%; section chart Groceries "1 warning · 9 tickets", Fish and Seafood and Meat "0 warnings · 1 ticket", Vegetable "1 warning · 0 tickets"; hotspot ranking in two columns with all trends Rising or Stable; vendor risk Aling Nena's Store 9 / Bert's Fish 1 / Nena Bakery 0 (unregistered ticket 12 not counted). The server's answers for ratio, resolution and sections matched.
  - Waiving ticket 12 (unregistered vendor, community service): the server showed 1 of 11 resolved (9.1%) straight away; a fresh page view after the one-minute cache showed 1 of 11 and 9%; setting it back to Pending returned 0 of 11.
  - Year 2025: all zeros, every section "0 warnings · 0 tickets", all hotspots Stable, the three businesses still listed with 0 offenses.
  - With the trend request blocked: only that panel showed its failure message and Retry, the other panels kept their numbers, and Retry brought the chart back after the block was lifted.
  - Not signed in 401, enforcer 403, Head Admin 200, years 2027 and 0 give 400, on all 8 routes. Reload asks to sign in again. 390px: no sideways scrolling and every section row fits.
- **Phone follow-up (hotspot table), 4 of 4 passed.** The first follow-up run failed one check because of a typo in the script (a pattern written `/\s+/` inside a template string became `/s+/`); the script was fixed and run again, and the first run's failure was not counted as a pass. At 390px all five headers are visible, the table does not scroll sideways, the rows show warnings and tickets apart, and the desktop table is unchanged.
- Nothing was uploaded to evidence storage. Changes made to the test database: 5 sign-in code rows, and ticket 12 waived and restored (so its history has extra rows and its version number moved on). Database at the end: 13 records, ticket 12 Pending. The servers started for the checks were stopped afterwards.

## Limits

- Admin Officer not checked live (no test account). The server tests use both roles.
- Website only; iPhone and Android do not apply.
- The trend chart's drawn lines were checked from the page's own markup, not read from a picture; the screenshots were looked at by eye.

## Noticed, not fixed

- The six-column vendor risk table also scrolls sideways inside its box at 390px.
- The enforcer performance page still calls its figure "Inspection Ratio".
- The analytics pages keep each chart's data in the browser for 60 seconds (`staleTime: 60_000` in `main.tsx`), the same cache noted in 3b; a change made in the last minute shows after that.
- The vendor risk score uses each business's current compliance score, not the selected year's tickets. The page says so; any change belongs with the recommended-actions slice.
- Existing security warning on server package `System.Security.Cryptography.Pkcs` 10.0.0.
