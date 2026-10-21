# Deferred enforcer mobile slices

Saved on 2026-10-21 at the user's request. These slices are deferred while monorepo migration is considered. Resume with a bounded plan and explicit approval; this document does not authorize implementation.

## Scope and current state

- Product scope: `marikina-market-api` and `marikina-market-mobile`. Web is excluded from these product changes.
- Preserve existing uncommitted edits, architecture and theme patterns. No packages or database migrations are authorized.
- Use ordinance text consistently: `Ord No. {ordinance.ordinanceNo}, Series of {ordinance.series}`.
- Slice 1 (card summaries and ticket loading recovery) and slice 2 (enforcer list filters) are implemented with focused automated evidence; required live/device verification remains outstanding. They are not fully verified feature completions.
- Evidence: `evidence/enforcer-summary-slice-1/README.md` and `evidence/enforcer-filters-slice-2/README.md`.
- Slice 2 final checks: API build passed, 531 tests passed / 2 skipped; focused Flutter tests 22 passed. Full Flutter suite stopped after stalling at 119 passed / 2 known failures. Four existing analyzer info diagnostics remain.

Paths below reflect the current separate-repository layout; reconcile them if migration changes that layout.

## Slice 3 — Ticket paper and new-inspection form

Resumed on 2026-10-22 with approval to redesign the paper, ticket-detail page,
and corresponding inspection-preview paper. This expands the original
spacing-only styling restriction below. The final design keeps the control number
at 16px, shows ordinance prices only for cash-fine tickets, and aligns those prices
at the bottom right of each ordinance card. The user also requested the settlement
receipt FileImage crash fix; it is included in this resumed mobile slice.

Status: implementation present; automated and visual evidence is recorded in
`evidence/enforcer-ticket-paper-slice-3a/README.md` (2026-10-22 redesign section).
Native/live completion remains unverified. An Android device is available, but
the user confirmed that no disposable local database is available. No database
was accessed or provisioned. Keep this slice open for the remaining live checks;
this resume does not complete or advance a product phase.

Requested behavior:

1. Match the ticket-detail paper header layout to the new-inspection preview paper header, retaining the actual ticket control number.
2. Add a small gap between the ordinance number/series and ordinance code in violation details, following the preview layout. Keep this adjustment about spacing; preserve existing colors and typography.
3. Use the full ordinance number/series format in the new-inspection ordinance selection bottom sheet, including selected chips and list rows.
4. Remove the unnecessary outer container around the Take a photo button; retain camera, loading and error behavior.
5. Make evidence X icons visually smaller while preserving an accessible tap target.

Likely mobile files, under `lib/features/tickets/presentation/`:

- `tickets/widgets/ticket_detail_content.dart`
- `tickets/widgets/ticket_violation_section.dart`
- `inspections/pages/new_inspection_preview_page.dart` (layout reference)
- `inspections/widgets/preview/violation_details_section.dart` (spacing reference; adjust only if needed for consistency)
- `inspections/widgets/form/bottom_sheets/select_ordinance_bottom_sheet.dart`
- `inspections/widgets/form/add_photo_evidence_btn.dart`
- `inspections/widgets/form/inspection_evidence_tile.dart` (confirm exact location before resuming)

Verify header alignment, actual control number, complete ordinance labels, narrow layouts, ordinance selection, camera handling and evidence removal. Prefer existing theme spacing; identify any required theme file change in the resumed plan. No API change is expected unless inspection finds missing data.

## Slice 4 — Enforcer notification parity

Requested behavior:

1. Give enforcer notifications the same design as vendor notifications.
2. Reuse the vendor filter design and provide mark all as read.
3. Preserve pagination, unread counts, loading/error/retry behavior and role ownership.

Investigation notes to reconfirm:

- Shared `NotificationPage` currently branches on vendor/enforcer presentation.
- Vendor header and tile widgets provide the intended reference design.
- Existing `NotificationBloc` mark-all handling snapshots unread IDs across pages before marking them, avoiding skipped items when the unread list shrinks. Preserve partial-failure handling.
- Vendor notification DI supplies the unread-count use case; the enforcer instance needs the equivalent wiring.
- Enforcer notification list responses may need the filtered current-user total already supplied by the vendor service. Check all consumers before approving a contract change.
- Prefer the existing role-owned list/read endpoints; a new bulk endpoint is not assumed necessary.

Likely areas: mobile notification presentation/BLoC/data wiring and `lib/core/di/dependency_injection.dart`; API notification service/repository and relevant tests if unread totals require changes.

Verify all/unread filtering, count changes, empty results, multiple pages, mark-all success and partial failure, retry and cross-user denial. Agree on the API contract before dependent mobile work. If a required web consumer is discovered, reopen the scope gate before changing that contract.

## Slice 5 — Profile camera button overlap

Requested behavior:

- Position the profile camera button partly outside the portrait, similar to Discord's avatar-edit placement.
- Preserve tap behavior, loading/disabled states, clipping and accessibility.

Likely area: shared profile avatar widget (`profile_avatar.dart`; confirm exact location). The existing Stack reportedly allows overflow; adjust positioning using theme values and check whether parent clipping or hit testing needs attention. Identify any theme-file change in the resumed plan.

Verify both vendor/enforcer profiles using this widget, narrow screens, button hit testing outside the portrait and photo update states. No API change is expected.

## Verification still outstanding from earlier slices

- Live API/database/device checks require a user-confirmed disposable local database and user-provisioned schema. Do not use operational data or execute migrations.
- Existing Flutter failures: duplicate recovery request timeout, optional-middle-name profile form state mismatch, dashboard/refresh test stalls; existing analyzer info diagnostics are documented in slice evidence.
- Do not fix unrelated failures as part of a resumed UI slice without separately approved scope.
