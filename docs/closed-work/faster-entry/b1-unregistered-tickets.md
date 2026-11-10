# Faster entry B1: unregistered vendor tickets shown (closed 2026-11-09)

Closed by the user on 2026-11-09 after all automated checks, deliberate breaks and live checks on the website, the server and the phone passed. Full results, expected results (written first) and screenshots: `evidence/slice-b1-live/results.md`, `expected.md`, `expected-phone.md`.

B1 is the first half of Slice B. It lets the system hold and show a ticket or warning that has **no business** (an unregistered vendor). Entering one from the phone (the Registered / Unregistered choice, picking the market section, typing the place) and removing QR scanning are **B2**, planned and not approved.

## What it does

- **Server:** a ticket or warning can be saved with no business if it has an active market section. Nothing is sent to a business owner for it (no notification, push or email, and no business score change). Registered tickets work exactly as before. All lists, searches, settlements, counts and the overdue job handle a ticket with no business.
- **Phone:** wherever a ticket or warning would name its business (inspections list, tickets list, ticket and warning page, person citation history) it says "Unregistered vendor" with the market section and the place. Old records whose business details were never saved still say "Historical business details unavailable."
- **Website:** the same label in the Tickets list, Inspections list, ticket page, record popup, person history, community service log and enforcer inspection list, with the right market section and no owner or stall. A record counts as unregistered only when the server explicitly sends an empty business ID.

## Schema (applied by the user, never by an agent)

`tickets.vendor_id` becomes optional. Hand-written EF migration `20261109090000_OptionalTicketBusiness` (with its Designer file and the model snapshot updated). On 2026-11-09 the user applied the same change to the test database `marikina_market_e2e` (`ALTER TABLE public.tickets ALTER COLUMN vendor_id DROP NOT NULL;` plus a row in the migration history table). The change must be applied to any other database before the new code runs there. The rollback fails by design while any ticket has no business.

## API contract (as built, no new routes)

- `POST /api/enforcer/tickets/new-inspection` and `POST /api/enforcer/tickets/verify`: `vendor_id` is now optional. Without it, `market_section_id` is required and must be an active section (400 when missing or switched off, 404 when it does not exist). With a `vendor_id`, the business's own section is used and `market_section_id` is ignored.
- `POST /api/enforcer/tickets/warning-check`: `vendor_id` optional. `fine-summary` is person-based and ignores it.
- Responses for an unregistered record: `vendor_id`, `business_name`, `first_name`, `last_name`, `registered_owner_name`, `business_type`, `business_account_number`, `stall_number` and `business_snapshot` are `null`; `market_section_id`, `market_section_name` and `issue_place` are filled.
- Pending settlements and the community service log send `business_account_number` and `vendor_name` as `null`; person history sends `business_name` and `registered_owner_name` as `null`; the enforcer inspection history now also sends `vendor_id`.
- Consumers: phone and website, both updated.

## Changes per file

- Server (`marikina-market-api/MarikinaMarket.API`): `Domain/Entities/Ticket.cs`; `Application/Services/TicketService.cs`, `EnforcerService.cs`; `Application/Interfaces/Services/ITicketService.cs`, `Repositories/ITicketRepository.cs`; `Infrastructure/Repositories/TicketRepository.cs`, `VendorRepository.cs`; ticket and settlement DTOs (internal, request, response: 16 files) and `Application/DTOs/Enforcers/Response/InspectionResponse.cs`; `Infrastructure/Migrations/20261109090000_OptionalTicketBusiness.cs`, its Designer file and `AppDbContextModelSnapshot.cs`.
- Server tests (`MarikinaMarket.Tests`): new `UnregisteredTicketTests.cs` (31 cases) and `OptionalTicketBusinessMigrationTests.cs` (2); updated `InspectionNotificationTests.cs`, `TicketStatusSettlementTests.cs` (its test ticket now carries a business ID, as a saved ticket always does).
- Phone (`marikina-market-mobile/lib/features/tickets`): four data models and four entities (business fields optional; `isUnregistered`), new `domain/entities/unregistered_vendor.dart`, `inspection_card.dart`, `ticket_card.dart`, `ticket_detail_content.dart`, `violator_detail_section.dart`, `person_history_sheet.dart`. New test `test/unregistered_ticket_ui_test.dart` (9 cases).
- Website (`marikina-market-web/src`): `utils/formatters.ts` (the label), four type files, `TicketList.tsx`, `InspectionTable.tsx`, `TicketDetailPage.tsx`, `PersonTicketHistory.tsx`, `TicketViolatorInfoSection.tsx`, `TicketViolationDetailsSection.tsx`, `EnforcerInspectionList.tsx`, `SettlementCard.tsx`, `AdminCommunityServiceLogs.tsx`. New test `features/tickets/unregistered-vendor.test.mjs` (8 cases).

## Evidence

- Server: build 0 errors (4 warnings, all already on `main`); 858 passed, 0 failed, 2 skipped (the same 2 as before). The backup tests need `BACKUP_TEST_TEMP_ROOT`, `TEMP` and `TMP` set to a throwaway folder.
- Phone: format clean, analyze no issues, 479 passed.
- Website: type check clean, build passes, 177 passed.
- Deliberate breaks: 14 of 14 caught (6 server, 4 phone, 5 website; my first server run of these was invalid because of a script mistake and was redone).
- Website and server live check against `marikina_market_e2e`: 35 of 35 passed, including the server "verify" step as the enforcer (200 without a business, 400 with neither business nor section, 404 for an unknown section, 200 with a business).
- Phone check on V2529: lists, tickets, ticket page, warning page, registered ticket unchanged, people at the business and Juan Dela Cruz's citation history all as expected. Nothing was submitted and no photo was taken.
- Two synthetic records stay in the test database: ticket 12 (B1-LIVE-0001, community service, Meat Section) and warning 13 (WRN-0013, Vegetable Section), neither with a business. No photos were uploaded.

## Limits

- Not checked live: the settlement card for an unregistered vendor with a cash fine (the website lists community-service tickets in the community service log, not as settlement cards), and saving an unregistered ticket through `new-inspection` (it needs photos, which would go to the locked evidence storage). Both are covered by automated tests only.
- The phone test `ordinance_shortcuts_test` fails in some full runs (2 of 4 runs on identical code) and passes alone. It is not part of B1.
- The place-suggestions code (a list of places from earlier unregistered tickets) was taken out of B1 as unused and is left for B2.
- Committed on 2026-11-09 as `21e6153` on the branch `b-unregistered-vendors` (60 files). Pushed and merged into `main` as pull request #9 (https://github.com/gvillaluz/marikina-market-ticketing/pull/9) on 2026-11-09, merge commit `33d750b`. The migration must be applied to every other database before the new server code runs there. When closed it was uncommitted: the code is in the worktree `C:\Users\Admin\Documents\Projects\mmt-b-unregistered-vendors` (branch `b-unregistered-vendors`, from `main` a7f5f84). The older folder `mmt-b1-unregistered-tickets`, where the first server work was started, is untouched. The copied `google-services.json` and `GeneratedPluginRegistrant.java` are in that worktree only (git-ignored); delete the key file when the worktree is removed.
- Existing, not caused by B1: a ticket page on the phone shows the current time under "DATE & TIME" instead of the issue time.
