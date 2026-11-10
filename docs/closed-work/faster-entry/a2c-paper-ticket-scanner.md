# Faster entry A2c: paper ticket scanner (closed 2026-11-09)

Closed by the user on 2026-11-09 after all automated checks, deliberate breaks and the Android phone check passed. Full results and screenshots: `evidence/ticket-flow-a2c-live/results.md`. Not checked: the iPhone scanner (built, not tested, by the user's decision) and phones without Google Play services.

## What it does for the enforcer

The paper ticket or paper warning photo is taken with a document scanner instead of the plain camera. The button says "Scan paper ticket" (or "Scan paper warning"), then "Rescan paper ticket" once a page is saved. The scanner takes one page, camera only, with no filters, and crops it to the paper. Android uses Google's scanner; an iPhone uses Apple's document scanner (built, not tested). If the scanner fails or is missing, the enforcer sees "The scanner is unavailable on this phone." and a "Take a normal photo instead" button, so the paper photo is never blocked. Cancelling changes nothing; a second tap while the scanner is open does nothing. Supporting photos still use the normal camera.

## Package (approved by the user 2026-11-09)

`cunning_document_scanner` 3.0.4 (pinned), instead of `google_mlkit_document_scanner` named in the earlier plan, because it also covers iPhone and has its own backup scanner for phones without Google Play services (the enforcer drags the crop corners there). Version 3.1.0 was 12 hours old, so 3.0.4 was chosen.

## API contract

None. No server, website or database change. The photo is sent as before (compressed to JPEG when saving).

## Changes per file (phone only)

- `pubspec.yaml`, `pubspec.lock`: added the package.
- `lib/features/tickets/presentation/inspections/widgets/form/scan_paper_btn.dart` (new): the scan button, with the unavailable message and the normal-photo fallback.
- `lib/features/tickets/presentation/inspections/pages/add_new_inspection_page.dart`: the paper photo section uses the scan button.
- `test/features/tickets/presentation/scan_paper_btn_test.dart` (new): 12 widget tests with only the scanner and camera plugin channels faked.
- `test/inspection_preview_navigation_test.dart`: feeds the paper photo through the scan button; checks the labels and that supporting photos still use the normal camera.

## Evidence

- Phone: format clean, analyze no issues, 469 passed, 1 failed. The failure is `ordinance_shortcuts_test.dart`, which fails the same way in a full run without A2c's code (baseline 457 passed, 1 failed) and passes alone.
- Deliberate breaks: 7 of 7 caught (two pages allowed, scanned page dropped, double-tap guard removed, scanner failure not handled, gallery allowed, filters on, cancel clearing the message). The double-tap break was first missed and a test was added.
- Code review (read-only agent): no serious findings; three low findings fixed (cancel now changes nothing, state set through `setState`, unused option removed).
- Phone checks on V2529 against `marikina_market_e2e`: all ten steps passed. One real ticket was submitted (LIVE-A2C-0001, test ticket id 11): tickets 9 → 10, evidence rows 14 → 16, one `PaperTicket` and one `Supporting` row, server error log empty.

## Limits

- Submitting uploaded 2 photos to the real evidence storage; they stay locked for 365 days (until about November 2027).
- The app never removes the scan files it leaves on the phone (they contain ticket details).
- Merged into `main` as pull request #8 (2026-11-09, merge commit `a7f5f84`), code only (these notes are not part of that pull request). Before the merge the code was uncommitted: the code is in the worktree `mmt-a2c-paper-scanner` (branch `a2c-paper-scanner`, based on `6c1e3a1`). The worktree also holds two git-ignored build copies (`google-services.json` and a hand-edited `GeneratedPluginRegistrant.java`).
