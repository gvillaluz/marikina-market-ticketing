# Faster entry: entry page layout and buttons (closed 2026-11-12)

Phone only. Built and auto-checked on 2026-11-12. The user checked it on their own phone and said it is good; no results were recorded, so the live check is not counted as recorded evidence. No server, website or database change.

## What it does for the enforcer

- The start screen has less text.
- The chosen business or section shows as a short banner with a "Change" link.
- The form is grouped under four headings: Paper details, Violator, Violation, Paper copy.
- Ticket and warning use the same "Issue place" field.
- Scan, photo and ordinance buttons share one outlined style; Cancel is quiet.

## API contract

Unchanged. No route, request, response or error change.

## Changes per file

- Phone (new): `form_section.dart` (section heading and spacing).
- Phone (changed): `add_new_inspection_page.dart`, `vendor_summary_banner.dart`, `unregistered_section_banner.dart`, `paper_citation_fields.dart`, `ticket_violation_card.dart`, `scan_paper_btn.dart`, `add_photo_evidence_btn.dart`.
- Phone tests: new `entry_page_layout_test.dart` (19 tests); ten existing test files reworded to the new labels ("Select ordinance", "Change vendor", "Change section"); one wait added in `inspection_preview_navigation_test.dart` (the page grows after the owner lookup, so the old scroll missed the "Someone else" button at 390 px; no check weakened).

## Evidence

- `flutter analyze`: no issues; format clean on changed files.
- Full phone run: 570 passed, 3 failed. `ordinance_shortcuts_test` ("shows the three shortcut groups...") fails every time it is the file's first test, also on unchanged main (pre-existing). The other two (ordinance "a warning leaves out...", violator picker "owner card F") failed once in a slow run and passed on rerun; not rerun on unchanged main.
- Review: a read-only reviewer checked the first build; later fixes were self-reviewed only (user chose main agent only).

## Limits

- Not tested: iPhone, TalkBack, large text.
- When the owner has no person record, "Add owner as person" is also a filled button.

## Unrelated, not fixed

Unused leftovers: `ViolatorInfoCard.errorMessage` and `_vendorError`, `TicketViolationCard.capturedPhotos`, `warning_violation_card`, `violator_info_fields`, `error_banner`, `status_placeholder`.
