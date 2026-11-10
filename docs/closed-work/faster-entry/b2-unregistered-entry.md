# Faster entry B2: unregistered vendor entry (closed 2026-11-10)

Closed by the user on 2026-11-10 after all automated checks, deliberate breaks and the live check on the phone passed. Full results, expected results (written first) and screenshots: `evidence/slice-b2-live/results.md` and `expected-phone.md`.

B2 is the second half of Slice B. B1 let the system hold and show a ticket or warning with **no business**. B2 lets the enforcer enter one on the phone and removes QR scanning. Server and website are unchanged by B2 except the removed QR route.

## What it does

- **Choice:** the new inspection page starts with a Registered / Unregistered choice (Registered selected). Registered works as before with only **Search business**.
- **Unregistered:** the enforcer taps one of the office's active market sections (the list comes from the existing section list; switched-off sections are never offered). The page then shows a banner `Unregistered vendor` with the section and **Change section**. The issue place starts empty and is required. There is no owner and no people list; the person search, ordinance choice, penalty, photos and copy-to-paper card work as before.
- **Review page:** says `Unregistered vendor` with the section instead of business details. Submit for a ticket needs a verified calculation but no business snapshot (an unregistered ticket has none).
- **Change section** counts as an edit, so a ticket must be verified again.
- **Registered to Unregistered:** the place that came from a business record is cleared when the business is changed, so it does not carry over.
- **QR scanning removed:** the phone's scan button, scanner screen and helpers, the QR lookup chain, and the `mobile_scanner` package are gone. The camera permission stays (the paper scanner uses the camera).

## Contract (as built)

- **Removed:** `GET /api/vendor/code/{code}` (enforcer QR lookup). Only the phone used it; the website does not.
- **Used, unchanged:** `GET /api/marketsection` (any signed-in user; the phone keeps only sections with `is_active` true), `POST /api/enforcer/tickets/verify` and `POST /api/enforcer/tickets/new-inspection` (from B1: without `vendor_id`, `market_section_id` is required and must be an active section), `POST /api/enforcer/tickets/fine-summary` and `warning-check` (`vendor_id` optional).
- **Phone sends:** with a business, `vendor_id` (and no `market_section_id` on Verify); without one, no `vendor_id` and the chosen `market_section_id`.
- **Schema:** none. The B1 change (`tickets.vendor_id` optional) must already be applied to the database in use.

## Changes per file

- **Server (`marikina-market-api`):** `Presentation/Controllers/VendorController.cs`, `Application/Services/VendorService.cs`, `Application/Interfaces/Services/IVendorService.cs`, `Application/Interfaces/Repositories/IVendorRepository.cs`, `Infrastructure/Repositories/VendorRepository.cs` (QR lookup removed). Tests: new `QrLookupRemovedTests.cs` (2), `BusinessLookupTests.cs` (QR lines removed).
- **Phone, new** (`marikina-market-mobile/lib/features/tickets`): `domain/entities/market_section.dart`, `data/models/market_section_model.dart`, `domain/use_cases/get_market_sections_use_case.dart`, bloc `market_sections_requested.dart`, `market_sections_loading.dart`, `market_sections_error.dart`, widgets `vendor_kind_toggle.dart`, `unregistered_section_picker.dart`, `unregistered_section_banner.dart`.
- **Phone, changed:** `add_new_inspection_page.dart`, `new_inspection_preview_page.dart`, `violator_info_card.dart`, `person_identity_review.dart`, `violator_info_section.dart`, `select_ordinance_bottom_sheet.dart`, `inspection_bloc.dart`, `inspection_event.dart`, `inspection_state.dart`, `inspection_form_data.dart`, `vendor_summary.dart`, `verify_inspection_input.dart`, `save_inspection_params.dart`, the repository interface and implementation, the remote data source, the fine-summary, warning-check and save use cases, `core/di/dependency_injection.dart`, `pubspec.yaml`, `pubspec.lock`.
- **Phone, deleted:** `qr_scanner_screen.dart`, `qr_scanner_camera_controls.dart`, `qr_scanner_camera_error.dart`, `qr_scanner_overlay.dart`, `qr_scanner_status.dart`, `scanner_corner_pointer.dart`, `search_vendor_by_code_use_case.dart`, `test/qr_scanner_ui_test.dart`.
- **Phone tests:** new `test/unregistered_entry_test.dart` and `test/unregistered_entry_flow_test.dart`; updated `inspection_list_ui_test.dart`, `inspection_preview_navigation_test.dart`, `business_people_test.dart`.
- **Website:** no change.

## Evidence

- **Server:** build 0 errors, 4 warnings (the same count as `main`); 860 passed, 2 skipped (the same 2 as before), 0 failed. The backup tests need `BACKUP_TEST_TEMP_ROOT`, `TEMP` and `TMP` set to a throwaway folder.
- **Phone:** format clean on changed files, analyze no issues. One of two final full runs passed all 490 tests; the other had only `ordinance_shortcuts_test` failing (see Limits).
- **First-fail:** the new tests were written first and failed (they did not compile, because the code did not exist yet).
- **Bug found by the full-page test:** Submit for an unregistered ticket stayed off because the review page waited for a business snapshot. Fixed.
- **Deliberate breaks:** 12 of 12 caught (11 phone, 1 server). Phone: inactive sections offered; Verify drops the section; save sends business 0; a section pre-fills the place; a section change not seen as an edit; Submit always wants a snapshot; save accepts no business and no section; people list requested without a business; an old business place kept after Change Vendor; Submit sends section 0; the review page drops the section on Verify. Server: a QR route put back. All files were restored and compared by fingerprint afterwards.
- **Live check on V2529** (debug app from the worktree, API from the worktree against `marikina_market_e2e`): 11 of 11 passed. All 8 active sections shown; no QR button; a Ticket's fine and a Warning's check ran with no business; changing the section kept the typed place; a registered business's place did not carry over to an unregistered entry; nothing saved (database still 12 tickets, highest id 13).

## Limits

- Not checked live: Verify and Submit for an unregistered vendor on the phone (photos are needed, and Submit would upload to the locked evidence storage); the server side of Verify with no business was live-checked in B1. Not checked live: a switched-off section being hidden (the test database has none); the paper scanner (not included in the plugin list copied for the build); iPhone.
- The phone test `ordinance_shortcuts_test` fails in some runs ("No element": a request not yet made; it failed 2 of 3 solo runs and some full runs) and passes in others. It is not part of B2.
- Existing, not fixed: after Change Vendor or Change section, the person box shows nothing selected but the page still holds the earlier person (also true for registered businesses).
- Existing, not fixed: the tracked generated file `marikina-market-mobile/macos/Flutter/GeneratedPluginRegistrant.swift` still mentions `mobile_scanner`; Flutter regenerates it on the next `pub get` on a machine with Developer Mode on. It was left alone because the main folder holds uncommitted edits to it.
- Place suggestions (a list of places from earlier unregistered tickets) were not built; B2 says the enforcer types the place.
- Committed on 2026-11-10 as `3f54dcf` on the branch `b2-unregistered-entry` (50 files, from `main` 33d750b). Pushed and merged into `main` as pull request #10 (https://github.com/gvillaluz/marikina-market-ticketing/pull/10), merge commit `bf87f4c`. The worktree `C:\Users\Admin\Documents\Projects\mmt-b2-unregistered-entry` holds the copied `google-services.json` and `GeneratedPluginRegistrant.java` (scanner line removed), both git-ignored; delete the key file when the worktree is removed. The test app stays installed on the phone.
