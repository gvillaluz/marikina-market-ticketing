# Paused — Vendor ticket-detail styling

Recorded: 2026-10-22.

Status updated: **2026-10-24 — partially implemented, verification incomplete,
paused at the user's explicit request.** Preserve the current edits for resumption.

## Current approval and scope

The user approved the inspected plan to copy the existing enforcer ticket-detail
design to vendor ticket detail, within `marikina-market-mobile` only. Design only;
preserve vendor functionality, values, field visibility, navigation, image viewing,
receipt upload, community-service behavior, loading/errors/retry and read-only states.
No API, model, BLoC, dependency, schema, enforcer implementation or roadmap changes.
Phase 3 is closed; this is a separately approved mobile follow-up, not phase advancement.

The user subsequently requested: "stop it and put it in a md file to continue later".
Do not continue implementation or launch checks until the user resumes the work.
Unchanged slice approval need not be requested again when resumed; material scope
changes still require approval.

## Work preserved at pause

Paths below are relative to `marikina-market-mobile/`.

Modified:

- `lib/features/records/presentation/pages/vendor_ticket_detail_page.dart`:
  enforcer-style background, app bar, bounded width and scroll padding; existing
  navigation, listeners, loading, not-found and retry paths retained.
- `lib/features/records/presentation/widgets/vendor_record_detail_content.dart`:
  paper layout, title/subtitle/status badge, section headings and field alignment,
  ordinance cards, penalty display and issued-by/to footer. Uses existing vendor
  values and optional-field conditions; issued time remains the record's actual
  value rather than copying the enforcer widget's current-time expression.
- `lib/features/records/presentation/widgets/record_evidence_grid.dart`:
  responsive enforcer-style thumbnail grid/radii; existing vendor dialog callback,
  network image loading and failure handling retained. Photo numbering is now an
  accessibility label instead of a visible caption.
- `lib/features/records/presentation/widgets/vendor_settlement_section.dart`:
  presentation spacing, heading and card changes only; existing branch conditions,
  loading/retry callbacks and receipt/service widgets retained.
- `test/records_feature_test.dart`: initial design regression, four header pixel
  comparisons, eight narrow/enlarged-text cases and optional preview capture.

Added vendor-local widgets in `lib/features/records/presentation/widgets/`:

- `vendor_ticket_paper_header.dart`
- `vendor_ticket_paper_field.dart`
- `vendor_ticket_paper_section_title.dart`
- `vendor_record_violation_card.dart`
- `vendor_record_evidence_section.dart`

The header/field/section-title layouts were copied from the enforcer reference
without importing that feature's internals. Header control-number visibility
preserves the vendor's non-null condition: no invented PENDING value. The vendor
entity still has no ordinance-series field. Existing vendor amount visibility
for non-cash records and warning offense counts is retained deliberately.

## Verification actually observed

- Before implementation, the new issued-paper layout test failed as expected:
  `VIOLATION TICKET` was absent. Command:
  `flutter test --no-pub test/records_feature_test.dart --plain-name "vendor detail uses the issued paper header and ordinance layout"`.
- Formatting passed for changed Dart files. The final test additions were formatted.
- A focused run of `test/records_feature_test.dart` and
  `test/vendor_settlement_test.dart` reached seven passes with no reported failure,
  then stopped producing output. It was interrupted when the user requested a stop.
  This is not a completed passing run and predates the final test additions and
  some final styling edits.
- `flutter analyze --no-pub` completed with five info diagnostics and exit 1:
  `in_app_notification_banner.dart:87` deprecated withOpacity;
  `usecase.dart:3` Type parameter naming; `lookup_bloc.dart:6` empty constructor;
  `main.dart:16` flutter_native_splash dependency declaration;
  `inspection_photo_controls_test.dart:52` missing braces.
  All are outside changed files; no diagnostic was reported in this slice's files.
  Analysis began before the final test additions and is not final-source validation.
- `git diff --check -- marikina-market-mobile` passed at pause (line-ending warning only).
- Full Flutter suite, final focused run, generated previews and visual inspection
  have NOT completed. No native app run, API/database E2E or native photo-picker
  verification occurred. Do not claim exact visual parity or completed delivery yet.
- Sandbox Flutter invocation produced no output; the SDK checks required an
  escalated tool invocation. SDK path:
  `C:/Users/berna/Documents/develop/flutter`.
- Running tool sessions for this task were interrupted. A targeted cleanup checked
  the previously observed task process IDs; none was reported stopped afterward.
  Do not terminate unrelated VS Code Dart/language-server/Flutter daemon processes.

## Resume checklist

1. Re-read workspace/mobile instructions and inspect current diffs; preserve all
   other uncommitted work. Do not edit the roadmap or the old evidence records.
2. Review the new header pixel-comparison test: `toImage()` / `toByteData()` await
   calls are currently outside `tester.runAsync`. They may need to run inside it
   to avoid hanging under Flutter's fake async environment. This is a suspected
   issue, not an observed failure: these new comparisons have not been executed.
3. Finish visual parity review against current enforcer sources. In particular,
   review paper section spacing, severity colors, settlement card treatment and
   the receipt/service content. The current vendor severity uses existing theme
   helpers, whose High/Moderate colors differ from the enforcer penalty badges.
   The current vendor settlement card is not yet identical to the enforcer's
   `buildSettlementCard` decoration. Do not change vendor action behavior to match.
4. The ordinance-card palette/dimensions were copied literally from the enforcer
   reference; review compliance with mobile theme rules. Theme edits were not in
   the approved files. If new theme tokens are required, surface that scope need
   before changing the theme; do not silently expand scope.
5. Run focused tests with bounded timeouts and inspect any hang instead of leaving
   checks running. Final required checks are format, `flutter analyze --no-pub`
   and `flutter test --no-pub`. Record pre-existing failures separately; the full
   suite has historical failures/stalls, so use a bounded run and report limits.
6. Optional fixture preview command:
   `flutter test --no-pub --dart-define=VENDOR_DETAIL_PREVIEWS=true test/records_feature_test.dart test/vendor_settlement_test.dart`.
   Captures go to ignored `build/vendor-detail-previews/`. The capture setup loads
   cached Roboto/MaterialIcons fonts through FLUTTER_ROOT. Inspect the vendor and
   enforcer 400px captures and 280/400px enlarged-text cases. Reference and vendor
   preview data differ; header comparisons use identical inputs.
7. Visually verify cash, blood-donation, community-service and warning records;
   actual/long/missing control numbers; empty/populated evidence; loading/retry;
   existing read-only and upload behavior. Device/API prerequisites must be
   explicitly confirmed before any live check; never use the operational database.
8. Report implementation, automated checks and visual/device evidence separately.
   Update this note only with observed results. The slice is currently incomplete.

## Original saved proposal — historical

The remaining sections preserve the 2026-10-22 proposal. They are historical:
its pending-approval, environment and verification assumptions are superseded by
the current approved scope/status above. In particular, do not hide existing
non-cash vendor amounts merely to copy the enforcer's cash-only visibility rule.

## Objective

Give the vendor ticket-detail page the same visual style as the redesigned
enforcer ticket-detail page, while preserving vendor-specific information and
actions.

Scope: **`marikina-market-mobile` only**. Preserve existing uncommitted work.

## Proposed changes

1. Match the page background, bounded content width, padding, white paper surface,
   subtle borders/shadow, and section headings.
2. Match the compact logo/title paper header and bold, right-aligned **16px control
   number**, using the actual number when available. Keep written-warning
   presentation consistent and show the existing ticket status above the paper.
3. Match responsive label/value alignment and ordinance-card styling. Preserve
   complete values on narrow screens and with enlarged text.
4. Show ordinance prices only for cash-fine tickets, at the bottom-right of each
   ordinance card. Preserve ordinance and offense information for other penalties.
5. Coordinate penalty, evidence, and settlement section spacing with the enforcer
   design. Preserve vendor information, receipt actions, navigation, loading,
   read-only states, errors, and retry behavior.
6. Reuse existing theme values. Keep rendering within the records feature; do not
   import enforcer feature internals. Extract vendor paper widgets only where
   needed for readability, following existing architecture.

## Proposed files and areas

Paths below are relative to `marikina-market-mobile/`:

- `lib/features/records/presentation/pages/vendor_ticket_detail_page.dart`
- `lib/features/records/presentation/widgets/vendor_record_detail_content.dart`
- `lib/features/records/presentation/widgets/record_detail_row.dart`
- `lib/features/records/presentation/widgets/record_evidence_grid.dart`
- `lib/features/records/presentation/widgets/vendor_settlement_section.dart`
  (styling only)
- Vendor-local paper header/ordinance-card widgets, if extraction is needed,
  within the same records presentation widgets directory.
- Relevant vendor layout/detail/settlement cases in `test/records_feature_test.dart`
  and `test/vendor_settlement_test.dart`.

Style reference: existing enforcer paper/detail widgets and scoped paper values
in `lib/core/theme/app_theme.dart`. No theme-file edits are currently proposed.

## Data boundary and exclusions

The vendor `RecordViolation` entity currently supplies ordinance number, code,
offense count, and optional penalty amount, but no ordinance-series field.
Preserve the available information; do not invent a series or expand the API.

No API, schema, dependency, authentication, upload-contract, or business-rule
changes are proposed. No enforcer redesign or unrelated maintenance fixes are
included. This is separate from the deferred enforcer slices.

## Focused verification

The user explicitly requested avoiding unnecessary checks and tests:

- Format and analyze changed Dart files.
- Run the relevant vendor detail/settlement tests once; repeat affected checks
  only if a change or failure warrants it.
- Cover ticket/warning presentation, cash/non-cash price visibility, actual
  control-number display, narrow layouts, and enlarged text.
- Preserve existing vendor receipt and read-only behavior through focused
  regression checks.
- Record implementation and automated evidence separately from live/device
  evidence. Broad full-suite runs and Android builds are not part of this
  proposed styling verification.

Live verification remains pending: the user confirmed that no disposable local
database is available. Do not access the operational database, run migrations,
or establish an environment as part of this styling task. Report remaining manual
checks without claiming live feature completion.
