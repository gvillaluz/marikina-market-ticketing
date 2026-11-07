# New ticket flow — Slice A plan (registered businesses)

Status (2026-11-06): **A1 complete** (closed by the user on 2026-11-06 after automated checks and all six live phone checks on V2529 passed). A2 not started and not approved. Nothing is committed.

## A1 final report (2026-11-06)

### Live check on V2529 (throwaway database `marikina_market_e2e`, made-up data)

Expected results were written first (`evidence/ticket-flow-a1-live/expected.md`). Full results and screenshots: `evidence/ticket-flow-a1-live/results.md`.

| # | Check | Result |
| --- | --- | --- |
| 1 | Search by name, stall, account number | Pass. "nena" → Aling Nena's Store only; "12" → Aling Nena's Store, then Bert's Fish; "ACC-200" → Bert's Fish. The inactive Nena Bakery never appears. |
| 2 | People list vs person history | Pass. Maria Santos 0 offenses · 1 warning · ₱0; Juan Dela Cruz 1 offense · ₱500 unpaid; both match their history screens. |
| 3 | Helper from another business | Pass. Juan found from Bert's Fish, selected with one tap, name kept. "Not any of these – new person" shown below the match. Issue place filled from the business. |
| 4 | Submit one ticket | Pass. Saved as system control #2 (₱100, Ord. 011-2014 §12), photos uploaded. |
| 5 | Close and reopen | Pass. Juan now on Aling Nena's list: 2 offenses · ₱600 unpaid · last ticket at Aling Nena's Store. |
| 6 | Network off, then Retry | Pass with real airplane mode (user on the phone; the server received the retry). A first attempt using Android's per-app network test switch failed; that switch leaves the app unable to reconnect and is not a valid way to test this. |

### Automated checks (re-run 2026-11-06, after the live check)

- Server: build 0 errors; tests 768 passed, 2 skipped (both already skipped before A1), 0 failed. The backup tests need `BACKUP_TEST_TEMP_ROOT` (plus TEMP and TMP) set to a throwaway folder.
- Phone app: formatting clean (27 changed files, 0 reformatted); `flutter analyze` no issues; 426 tests passed.
- Earlier: new tests failed before the code existed; all 9 deliberate breaks were caught (5 server, 4 phone). Nothing still uses the old `/vendor/stall/` route.

### API contract (as built)

- `GET /api/vendor/lookup?search=` (MarketEnforcer). Replaces `GET /api/vendor/stall/{businessAccountNumber}` (removed). Matches business name, stall number or account number; active businesses only; at most 20; exact stall first, then by name. Response: the business list plus `has_more` and `total`. Errors: 400 empty or over 200 characters; 401/403.
- `GET /api/vendor/{businessId}/people` (MarketEnforcer). New. People with submitted tickets or warnings at this business: `id`, `full_name`, `address`, `phone_number`, `created_at`, `ticket_totals` (`offense_count`, `warning_count`, `outstanding_fine`, `last_ticket_at`, `last_business_name`, `business_names`). Errors: 404 missing or inactive business; 400 bad ID; 401/403.
- `POST /api/persons/matches`: request unchanged; each match gains `ticket_totals` (same fields).
- Consumers: phone app only. No web change, no database change, no migration.

### Changes per file

- Server (`MarikinaMarket.API`): `VendorController.cs` (lookup and people routes; old stall route removed); `VendorService.cs`, `IVendorService.cs`, `VendorRepository.cs`, `IVendorRepository.cs` (business search); `TicketService.cs`, `ITicketService.cs`, `TicketRepository.cs`, `ITicketRepository.cs` (people list and per-person totals); `PersonService.cs`, `PersonRepository.cs`, `IPersonRepository.cs`, `PersonCandidateResponse.cs` (totals on matches); new `PersonSummaryResponse.cs`, `PersonTicketTotalsResponse.cs`.
- Server tests: new `BusinessLookupAndPeopleTests.cs`; updated `BusinessLookupTests.cs`, `PersonManagementTests.cs`.
- Phone app (`lib/features/tickets/`): remote data source, repository and interface; `vendor_summary.dart`, `person_candidate.dart` (+ model); new `person_ticket_totals.dart` (+ model), `search_businesses_use_case.dart`, `get_business_people_use_case.dart`; bloc, events, state and new `business_people_*` event/state files; new `search_business_bottom_sheet.dart` (replaces the deleted `search_by_stall_bottom_sheet.dart` and `search_vendor_by_stall_use_case.dart`); new `business_people_section.dart`, `person_record_tile.dart`; `violator_info_card.dart`, `person_identity_review.dart`, `add_new_inspection_page.dart`; `core/di/dependency_injection.dart`.
- Phone tests: new `business_people_test.dart`; updated `inspection_list_ui_test.dart`, `inspection_preview_navigation_test.dart`, `inspection_selection_sheets_test.dart`.

### Open items (not A1 failures)

- No automated test for "Try again" on the business search (the people list has one). Optional, test-only.
- Switching Warning → Ticket clears the selected person and typed name.
- If the server sends business data the app cannot read, the search stays on "Searching…" instead of showing an error.
- On its first start against an empty database, the API creates an enabled daily 00:00 backup schedule. In `marikina_market_e2e` it is now turned off (as in earlier test runs); keep it off before any future live run.

Differences from the written plan, already agreed in practice:
- The person totals arrive grouped together as `ticket_totals`, not as separate fields.
- The people list doesn't include the owner's name; the phone takes it from the business record.

Change agreed 2026-11-06: point 6 was revised. "New person" stays available when matches are found (shown below them as "Not any of these – new person"), so a different person with the same name can still be recorded. When nobody matches, it shows as "New person".

Roadmap fit: Revision Phase, "Faster entry (replaces OCR)" criterion. OCR stays dropped (confirmed again 2026-11-06).

## Decisions already confirmed by the user (2026-11-06)

- Keep everything on **one page**, filled top to bottom. Not several screens: more screens look like more steps, and the users are not tech-savvy.
- **Normal button sizes.** No oversized buttons.
- Choices are shown as **options**, the same style as the existing Ticket / Warning choice.
- Steps must stay easy. The enforcer must not have to type the same information twice.
- No OCR for ordinance selection.
- "Most violated" means the whole market, last 30 days.
- The paper ticket is captured with an **auto-crop document scanner**, which captures only the paper.
- Unregistered vendors pick their location from an office-managed list. That's **Slice B**, not this slice.

## Split recommendation

Slice A is too large to build and verify in one go, so it is split into two parts. Each part gets its own approval and verification.

- **A1 — Find the business and the violator** (parts 1–2 below)
- **A2 — Ordinance shortcuts, copy to paper, document scanner** (parts 3–6 below)

This document asks for approval of **A1 only**. A2 is described so you can see the whole picture; it is approved separately later.

## The page after Slice A (top to bottom)

The existing Ticket / Warning choice stays as it is. The Registered / Unregistered choice only arrives in Slice B: showing it now would be an option that does nothing.

| Part | What the enforcer sees | Part of |
| --- | --- | --- |
| 1. Business | One search box: "Business name, stall number or account number". Results show name, stall, section and owner. Tap one. The QR scan button stays. The issue place is filled in from the business (section and stall) and can still be edited. | A1 |
| 2. Violator | The registered owner, plus the helpers already ticketed at this business. Each shows offenses, warnings, unpaid fine and last ticket. Tap one, or **Add helper**. | A1 |
| 3. Ordinance | Top of the list: this person's past violations, then "my recent", then most violated (30 days). Below that, search by number, series **or title**. | A2 |
| 4. Penalty | Unchanged: only the options the ordinance rules allow. | — |
| 5. Evidence photos | Unchanged: at least one is required for tickets. | — |
| 6. Copy to paper | A summary card: name, business, stall, ordinance sections with titles, penalty and fine, with the words "Copy these onto the paper ticket." | A2 |
| 7. Paper ticket | The **Scan paper ticket** button opens the document scanner (one page, auto-cropped). | A2 |
| 8. Next | Unchanged review page with Verify, then Submit. Any edit still means verifying again. | — |

A finished part shrinks to one line with **Change**, so the page stays short.

## A1 in detail

### What changes for the enforcer

1. **Business search accepts names and stall numbers.** Today it only matches the account number. Only active businesses appear, at most 20, sorted by name. If more match: "Keep typing to narrow the results."
2. **People list for the business.**
   - **Owner:** the registered owner from the business record. The owner is not stored as a person yet. Tapping the owner opens the person search with the owner's name filled in, so the enforcer selects the existing person or creates one.
   - **Helpers:** everyone who already has a submitted ticket or warning at this business. No new database table is needed: the list comes from past tickets.
   - Each person shows their totals **across all businesses**: offenses, warnings, unpaid fine, and last ticket (date and business).
3. **Add helper searches the whole system first.** This is the existing "Check possible matches" search, now showing the same totals plus the businesses where the person was ticketed. Tapping **Same person – select** reuses the record without retyping. **New person** (name and address) is the main choice when nobody matches; when matches are found it sits below them as "Not any of these – new person" (revised 2026-11-06). Same names are never merged automatically (existing rule).
4. **The issue place is filled from the business** (market section and stall). The enforcer can still edit it.

### Repeat helper at a new business (your question)

Juan was ticketed at Store X. Now he is caught at Store Y. He isn't on Store Y's list yet, so the enforcer taps **Add helper** and types "Juan". The search covers everyone, so Juan from Store X appears with "2 offenses · last ticket at Store X". The enforcer taps **Same person – select**. This new ticket counts as his 3rd offense, and after it is submitted Juan also appears on Store Y's list.

### API contract changes (backend first)

| Route | Change |
| --- | --- |
| `GET /api/vendor/lookup?search=` (MarketEnforcer) | **Replaces** `GET /api/vendor/stall/{businessAccountNumber}`, which is removed (its only user is mobile). It matches business name, stall number or account number, case-insensitive. Only active businesses, at most 20, sorted by business name. The response is the same list shape as today (`GetVendorResponse`), plus a `has_more` flag. Errors: 400 when the search is empty or over 200 characters; 401/403 as today. |
| `GET /api/vendor/{businessId}/people` (MarketEnforcer) | **New.** Returns the registered owner name, plus the people with submitted tickets or warnings at this business. Each person has `id`, `full_name`, `address`, `offense_count`, `warning_count`, `outstanding_fine`, `last_ticket_at` and `last_business_name`, ordered by most recent ticket. Errors: 404 for a missing or inactive business, 400 for a bad ID, 401/403. |
| `POST /api/persons/matches` | **Response gains fields**: `offense_count`, `warning_count`, `outstanding_fine`, `last_ticket_at`, `last_business_name` and `business_names`. Request unchanged. |

Counting rules reuse the existing ones: offenses = submitted citations (the existing total-citation counting); warnings = submitted warnings; unpaid = the existing outstanding cash fine. Nothing new is invented.

Consumers: **mobile only**. The web app does not call these routes; I checked `marikina-market-web/src` for them. No web change. No database change, no migration.

### Files

- **API:** `Presentation/Controllers/VendorController.cs`; `Application/Services/VendorService.cs` and its interface; `Infrastructure/Repositories/VendorRepository.cs` and its interface; `Application/Services/PersonService.cs` and the person repository match query; `Application/DTOs/Person/Response/PersonCandidateResponse.cs`; a new response DTO for the business people list; tests in `MarikinaMarket.Tests` (new `BusinessLookupAndPeopleTests.cs`, plus additions to the existing person match tests).
- **Mobile:** `inspection_remote_data_source.dart`, `inspection_repository(_impl).dart`, the vendor-summary and person-candidate models/entities, a new business-person model/entity and use case, the `inspection_bloc` events and state, `violator_info_card.dart`, `search_by_stall_bottom_sheet.dart` (becomes the business search), `person_identity_review.dart`, and `add_new_inspection_page.dart` (issue-place fill and the new people list). Tests: `inspection_creation_ui_test.dart`, `inspection_selection_sheets_test.dart`, plus a new people-list test.
- **Mobile style:** existing `core/theme` values only. If a value is missing, it is added to `core/theme` and reported.
- **Web:** none.

### What "done" means for A1, and how it is checked

| # | Done when | Test that proves it |
| --- | --- | --- |
| 1 | Typing "nena" finds "Aling Nena's Store". Typing "12" finds stall 12. Typing an account number still works. Inactive businesses never appear. | API tests with 3 hand-made businesses, one of them inactive. Each search result is worked out by hand before running. |
| 2 | With 21 matches, the app shows 20 and "Keep typing…". | API test with 21 businesses; app test for the message. |
| 3 | Store Y's list shows the owner, plus only the people ticketed at Store Y. | API test: person A ticketed at X and Y, person B only at X. Store Y's list = owner + A. |
| 4 | The totals are correct across businesses. | Same data: A shows 2 offenses; A's last business = the most recent one. Warnings and unpaid fine are checked with a known warning and a known unpaid ₱500. |
| 5 | "Add helper" finds a person from another business and selects them without retyping. | App test: the search returns Juan from Store X, one tap selects him, and the name is filled in. |
| 6 | "New person" is the main choice only when there is no match; with matches it shows below them as "Not any of these – new person". Same names are not merged. | Existing tests are kept; a new test checks both cases and that the button sits below the matches. |
| 7 | The issue place is filled from the business and stays editable. | App test. |
| 8 | Empty, loading and error states show plain messages, and retry works. | App tests for each state. |
| 9 | The old account-number route is gone and nothing still uses it. | Search of the code, plus an API test that the old route returns 404. |

Each test is first run against the unchanged code to confirm it **fails**, then it is made to pass. I will also break the new code on purpose to check that the tests notice.

### Live check on the phone (V2529, disposable database `marikina_market_e2e` only)

Expected results are written down before running. Then:

1. Search a business by name, then by stall, then by account number.
2. Open the people list and confirm the counts against the person history screen.
3. Add a helper who was ticketed at another business, and confirm their past offenses count.
4. Submit one ticket.
5. Close and reopen the app: the helper is now on this business's list.
6. Turn the network off during a search: an error appears, and retry works.

### Full checks

- API: `dotnet build` and `dotnet test` (full suite).
- Mobile: `dart format`, `flutter analyze --no-pub` (the five existing infos are expected), and `flutter test --no-pub` (full suite).
- A debug APK installed on V2529.
- Web: not touched, so no web run.

### Not in A1

- Ordinance shortcuts, the copy-to-paper card and the document scanner (A2).
- Unregistered vendors and the Registered / Unregistered option (Slice B).
- Suggested next control number.
- OCR.
- Enforcers creating businesses.
- Any web change.
- Any database change.

## A2a — Ordinance shortcuts and title search (approved 2026-11-06)

Status (2026-11-06): **A2a complete** (closed by the user on 2026-11-06). Server 775 passed / 2 existing skips; phone 431 passed, analyze and format clean; all four live checks on V2529 passed (`evidence/ticket-flow-a2a-live/results.md`). Nothing is committed.

As built: the route is `GET /api/ordinance/shortcuts` in `OrdinanceController`, but the counting lives in `TicketService` / `TicketRepository` (the server rules keep ticket queries in the ticket module). New: `OrdinanceShortcutsResponse.cs`, `OrdinanceShortcutsTests.cs`; phone `ordinance_shortcuts.dart` (+ model), `get_ordinance_shortcuts_use_case.dart`, `ordinance_shortcuts_test.dart`. Changed: ticket service/repository and their interfaces, `OrdinanceController.cs`; phone data source, repository and interface, bloc and `LoadOrdinanceSelection` event, `select_ordinance_bottom_sheet.dart`, `dependency_injection.dart`; four existing phone tests now answer the new shortcuts request in their fake servers.

A2 is split into three parts, each with its own approval and live check: **A2a** ordinance shortcuts and title search (this part), **A2b** the copy-to-paper card, **A2c** the paper ticket scanner (needs package approval). The suggested next control number is dropped (user, 2026-11-06); a control number field is a separate question to the user.

**For the enforcer:** the ordinance picker also searches titles and section numbers, and shows three shortcut groups at the top: this person's past violations, my recent ordinances, and the market's most violated in the last 30 days. If the shortcuts cannot load, the normal list still works.

**Rules (agreed):** "violation" counts both tickets and warnings. Only active ordinances. Up to 5 per group; an ordinance appears only in the first group it qualifies for. Person and my recent: most recent use first. Most violated: most uses in the last 30 days first, ties by ordinance ID.

**API (backend first):** `GET /api/ordinance/shortcuts?person_id=` (MarketEnforcer; the enforcer comes from the sign-in). `person_id` is optional. Response: `person_ordinance_ids`, `my_recent_ordinance_ids`, `most_violated_ordinance_ids` (ordinance IDs, in order). Errors: 400 when `person_id` is zero or negative; 401/403. Consumers: mobile only; no web change, no database change.

**Done when:** (1) title and section search finds the right ordinance; (2) the three groups are correct, ordered and without repeats; (3) inactive ordinances and uses older than 30 days are left out where required; (4) if the shortcuts fail, the full list still works; (5) the live check on V2529 shows the expected shortcuts. Each new test must fail first; deliberate breaks must be caught.

## A2b — Copy-to-paper card (approved 2026-11-07)

Status (2026-11-07): **A2b complete** (closed by the user on 2026-11-07). Phone 446 passed (10 new), analyze no issues, format clean; all six live checks on V2529 passed (`evidence/ticket-flow-a2b-live/results.md`). Committed on branch `a2b-copy-to-paper` (worktree `C:\Users\Admin\Documents\Projects\mmt-a2b-copy-to-paper`).

Noted for later (user, 2026-11-07), not approved: on the review page, ADDRESS shows the business's address, while the card's ADDRESS shows the violator's own address from their person record (what the paper asks for under NAME). Not caused by A2b.

**For the enforcer:** on the New Inspection page, between the description and the paper photo, a card "Copy these onto the paper ticket" (or "…paper warning") lists what to write, using the paper's own labels and order. It appears only when everything it lists is ready and follows every change on the page. It saves nothing and does not affect Verify or Submit.

**User decisions (2026-11-07):** the card matches the real paper fields (not business/stall); warnings get their own card with the BABALA labels; Control No. (pre-printed), "Iba pang uri ng paglabag" and "Tinanggap" are left off.

**Ticket card:** NAME (paper name), ADDRESS (the confirmed person's address), ORDINANCE ("tick OTHERS, write:" then "011 series of 2014, Sec. 12 – title" per ordinance; every ordinance in the app is 011/2014, so none of the three printed boxes applies), FINE/PENALTIES ("tick Php 1,500.00" / "tick Php 1,000.00" for those totals, otherwise "tick OTHERS, write Php …"; "tick Blood Donation"; "tick Community Service, write N hrs"), PLACE (issue place field), DATE / TIME (now), NAME & SIGNATURE OF APPREHENDING OFFICER (signed-in enforcer). Shown only with a name, address, place, at least one ordinance, and a complete cash total or community service of at least 3 hours.

**Warning card:** Petsa, Pangalan, Lugar, one "Ordinansa Blg." per ordinance ("011, Serye: 2014" then "Sec. 49 – title"), Market Enforcer. Shown with a name, place and at least one ordinance.

**Files:** new `copy_to_paper_card.dart` (ticket form widgets); `add_new_inspection_page.dart` (places the card); new `test/copy_to_paper_card_test.dart`; `test/inspection_preview_navigation_test.dart` gains card checks on the real page (approved by the user). No server, website or database change; no API contract change.

**Checks:** new tests failed first (10 of 10 against an empty card). Deliberate breaks caught: fine box never matched, card shown before the fine was complete, later ordinances dropped, card missing from the page, place sent as the address. In the whole-page test, a failed check makes the remaining tests in that file stall until the time limit (existing test setup behaviour).

## Control number, Part 1 — server messages and phone (approved 2026-11-06)

Status: **complete** (closed by the user 2026-11-07). Server 784 passed / 2 existing skips; phone 436 passed, analyze and format clean. Live V2529 checks 1, 2, 3, 4 and 6 passed. Check 5 rested on a wrong expectation and was accepted as-is by the user. Details: `evidence/control-number-part1-live/results.md`. Nothing committed.

Noted for later (user, 2026-11-07), not approved:
- **Notification wording.** The phone's Notifications page shows the message the server saved. Saved status updates read " — status changed from Pending to Contested.": they carry no control number, and the business name in front is blank. That wording predates this task. The "Ticket X for … is now …" line changed in Part 1 belongs to a display the page never uses.
- The server accepts a status change on a warning.

**Decision (user, 2026-11-06):** the control number is the number printed on the paper ticket (stored as `paper_reference`). A warning, which has no printed number, uses its WRN number. The app's own running number (`control_number`, e.g. "2") stays stored and used internally but is no longer shown. Old tickets without a printed number show "Unavailable (legacy record)" on screens and leave the number out of messages. Part 2 (web admin screens and the two web-only searches) is planned separately.

**Phone:** form field and messages say "Control number"; the paper-style preview shows one "CONTROL NUMBER:" box; Tickets card, Inspections card and person history show "Control number" only; warning details "CONTROL NUMBER: WRN-…"; notifications "Ticket <number> for <business> is now <status>." **Server:** ticket issued / status update / overdue notifications, push titles and email subjects and bodies use the shown number; duplicate and missing-number errors say "control number". **API:** in the enforcer notification list, `control_number` now holds the shown number (null for old tickets without a printed number); only the phone reads it. The vendor notification list is left unchanged: it is unreachable since vendor logins were removed (`GetVendorIdByUserIdAsync` always returns null). No other contract change, no database change.

**Done when:** each phone screen shows "Control number" with the right number for a ticket, a warning and an old ticket; vendor messages carry the shown number and old tickets leave it out; the notification lists send the shown number. Tests fail first; deliberate breaks are caught; live check on V2529 (issue a ticket, check screens, read the saved vendor notification, change status as Head Admin, check the phone notification, open the warning).

## Control number, Part 2 — website (approved 2026-11-07)

Status (2026-11-07): **complete** (closed by the user 2026-11-07). Server 806 passed / 2 existing skips (22 new); website build passed, 163 Node tests passed (9 new); all 41 live checks passed (`evidence/control-number-part2-live/results.md`). Nothing committed: server changes are in the main folder; website changes are on branch `control-number-part2-web` in the worktree `C:\Users\Admin\Documents\Projects\mmt-control-number-part2-web` (branched from `62036e5`, after this computer's `main` was brought up to date with GitHub). The community service log could not be checked live (no community-service tickets in the throwaway database); it is covered by automated tests only.

**For office staff:** every website screen shows one "Control number" (printed number for tickets, WRN number for warnings, "Unavailable (legacy record)" for old tickets). Covered: Tickets list, ticket detail page (title, breadcrumb, status confirmation), ticket record popup (one "CONTROL NO." box for both kinds) and its download file name, Inspections list, business inspection history and its export, compliance activity, pending settlements, community service log, enforcer inspection list, person history. The hidden app number is no longer shown or searched on the website.

**Searches:** the admin tickets, admin inspections and business inspection history searches match the shown number, any capitalisation, and no longer the hidden number. Other search fields unchanged.

**API (backend first, consumers: website only):** on `GET /api/admin/tickets`, `/api/admin/tickets/{id}`, `/api/admin/vendors/{id}/inspections`, `/api/admin/vendors/compliance-overview`, `/api/admin/vendors/pending-settlements`, `/api/admin/vendors/community-service-logs` and `/api/admin/enforcers/{id}/inspections/history`, `control_number` holds the shown number (null for old tickets without a printed number). `GET /api/admin/tickets/inspections` rows gain `control_number`. Requests and errors unchanged; no database change. Person history route (shared with the phone) unchanged.

**User decisions (2026-11-07):** delete the unused `TicketCard.tsx` and `TicketRecordModal.tsx`; one number box in the record popup; leave the print/export button (calls a missing server route) untouched.

**Done when:** (1) server sends the shown number on every route above and never the hidden one; (2) the three searches find printed and WRN numbers in any case and not hidden numbers; (3) every listed screen shows the right number and no old labels; (4) no old labels left in the website code. Tests fail first; deliberate breaks are caught; live check as Head Admin in the browser (desktop and 390px) on `marikina_market_e2e`.

## A2 preview (approved separately later)

- **New:** `GET /api/ordinances/shortcuts?person_id=` returns up to 5 ordinance IDs each for: this person's past violations, this enforcer's recent ordinances, and the most violated across the market in the last 30 days. The phone maps them onto its saved ordinance list. If the call fails, the normal list still works.
- **Mobile:** ordinance search also matches titles; the copy-to-paper card; the paper photo uses the document scanner (one page). Warnings use the same scanner.
- **Package:** `google_mlkit_document_scanner`. It works on Android only, needs Google Play services, downloads its scanner once on first use, and scans on the phone. It needs your package approval at the A2 gate.

## Open questions

None for A1. The A2 package approval is asked at the A2 gate.
