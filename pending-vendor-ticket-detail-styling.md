# Pending — Vendor ticket-detail styling

Recorded: 2026-10-22.

Status: **pending approval; implementation has not started**. The user requested
that this proposal be saved for later. Saving it does not authorize application
changes or advance the roadmap. Resume with the workspace workflow and explicit
approval of this bounded mobile follow-up.

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
