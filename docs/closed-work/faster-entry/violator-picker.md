# Faster entry: choosing the violator (closed 2026-11-12)

Built and auto-checked on 2026-11-11 and 2026-11-12. The user checked it on their own phone ("its working", 2026-11-12); no results were recorded, so the live check is not counted as recorded evidence. Slice 2 (entry-page layout and buttons) is a separate slice with its own plan.

## What it does for the enforcer

- Under "Violator", the business owner shows first as one card. If the owner already has a person record, one tap chooses them. If not, the card shows "Add owner as person"; one tap creates the record from the business details (nothing typed). The match ignores capital letters and outer spaces.
- "Someone else" opens a find-person sheet: one name box, results as you type from 2 letters, people already ticketed at this business first ("Ticketed here"), and "Not listed? Add new person" with the name already filled in.
- Unregistered vendors get only "Find violator" (no owner card).
- After choosing, only the chosen person's card shows, with "Change" and "History". The long instruction sentences are gone.
- "Change Vendor" and "Change section" now clear the earlier violator, ordinances and fine details.
- The old address and phone search boxes are removed; matching is by name.

## API contract (as built)

- Routes: `GET /api/vendor/{businessId}/owner-person` and `POST /api/vendor/{businessId}/owner-person` (MarketEnforcer only).
- Request: the business number in the path, no body.
- Response: GET returns 200 with the person (id, full_name, address, phone_number, created_at, ticket_totals) or 204 with no body when the owner has no record. POST returns 200 with the existing record, or creates one from the business record and returns it (a retry never makes a second record).
- Errors: 400 when the business number is 0 or less; 404 "Business not found." when the business is missing or inactive; 401/403 for the wrong role.
- Consumers: phone app only. No website change, no database change, no migration.
- Owner record rule: a person whose full name equals the owner's "First Last" and whose address equals "House, Street, Barangay, City", ignoring case and outer spaces; the lowest id wins if several match.

## Changes per file

- Server: `Presentation/Controllers/VendorController.cs` (two routes), `Application/Services/TicketService.cs` and `Application/Interfaces/Services/ITicketService.cs` (look up or add the owner person), `Application/Interfaces/Repositories/IPersonRepository.cs` and `Infrastructure/Repositories/PersonRepository.cs` (exact name and address lookup).
- Server tests: new `MarikinaMarket.Tests/OwnerPersonTests.cs` (7 tests); `PersonManagementTests.cs` (stand-in repository knows the new lookup); `VendorSignUpRemovalTests.cs` (route list includes the two new routes).
- Phone (new): two use cases (get and add owner person), owner events and states in the bloc, `person_matches_loaded.dart`, widgets `owner_person_card.dart`, `person_result_card.dart`, `find_person_sheet.dart`.
- Phone (changed): `person_identity_review.dart` (rewritten, much shorter), `create_person_sheet.dart` (short text, name-only prefill), `add_new_inspection_page.dart` (violator name comes from the chosen person; Change Vendor/section clear it), `selection_card.dart`, the data source, repository, match use case, bloc, events and states, and `dependency_injection.dart`.
- Phone (removed): `business_people_section.dart`, `person_record_tile.dart`, `person_matches_loading.dart` (nothing uses them any more).
- Phone tests: new `violator_picker_test.dart` and `change_business_clears_violator_test.dart`; eight existing test files updated to the new screens.

## Evidence

- Server: one full run, 860 passed, 2 skipped, 1 failed. The failure is `MobileLoginEmailFailureTests.Actual_email_service_cancels_a_stalled_local_SMTP_connection_and_closes_the_socket` (email timing); it passed alone twice (15/15) and the change does not touch it. Not proven to fail on unchanged main.
- Phone: `flutter analyze` no issues; full run 556 of 556 passed; format clean on changed files. The older timing test `ordinance_shortcuts_test.dart` also fails on unchanged main when run alone (not affected by this change).
- Review: read-only reviewer on the server and phone parts, then re-check after the fixes; nothing blocking.

## Limits

- Two enforcers adding the same owner in the same second could still create two records (no unique index; a schema change was out of scope). The phone blocks double taps and the bloc guards per business.
- The match on the real database for names with "Ñ" was not run by the tests (the in-memory stand-in is used); the database itself lowercases Ñ correctly.
- 403 and 500 errors on the owner card show a general "Something went wrong"; only 400 and 404 show the server message.
- Not tested: iPhone, TalkBack, narrow screens, large text.

## Unrelated, not fixed

- A very slow reply for one business could briefly show its "Ticketed here" people under another business (already so before).
- `business_people_loading.dart` holds two classes in one file (already so).
- After the violator is cleared, the chosen payment type and community-service hours stay (already so when changing the person).
