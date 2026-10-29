# Criterion 3 — proposed mobile repair scope

**Closure update 2026-10-29:** criterion 3 is closed with user-accepted unrelated verification limits; see [closure decision](criterion-3-closure.md). The repair outcome below retains the actual incomplete full-suite result and does not claim a full-suite pass.

2026-10-29. **Approved repairs implemented; targeted/build/device checks passed; full-suite completion remains unmet.** Results and per-file changes: [repair verification](../evidence/revision-ticket-person-identity-2026-10-29/repair-verification.md). This is the reduced repair scope following the [closure checklist](criterion-3-closure-failures.md) and [isolated checks](../evidence/revision-ticket-person-identity-2026-10-29/closure-checks.md). No criterion or phase closes automatically.

## Outcome

Retained enforcer/shared behavior passes meaningful regression tests, obsolete vendor-app expectations are reconciled without restoring vendor functionality, and the full Flutter runner finishes with explicit results. Preserve all existing uncommitted work.

Only `marikina-market-mobile` application/tests plus the named closure docs/evidence may change. No API contract, database schema, web application, CSS/theme, dependency or deployment change. The five unrelated analyzer infos stay recorded; they are not silently waived or cleaned up under this repair.

## Allowed files and changes

Paths below are relative to `marikina-market-mobile`.

| File | Approved objective if this plan is accepted |
| --- | --- |
| `lib/core/shared/presentation/widgets/app_outlined_btn.dart` | F06: correct loading accessibility semantics, keeping loading, reduced-motion, disabled and duplicate-tap behavior. Numeric progress must not expose the nonnumeric value `In progress`. No layout/color changes. |
| `lib/core/shared/presentation/widgets/skeleton_pulse.dart` | F07/F09 only if behavioral probes prove an actual retained animation lifecycle fault. Preserve animation while enabled, stop when inactive/reduced-motion and dispose correctly. Do not change it solely because one unrelated framework frame remains scheduled. |
| `test/inspection_creation_ui_test.dart` | F01: make image/file teardown wait for actual release before deleting the synthetic fixture. Preserve decoding/preview assertions. If evidence points to product code outside the two named production files, stop for expanded scope. |
| `test/mobile_role_access_test.dart` | F02: reconcile superseded positive vendor navigation assertions. Preserve retained enforcer navigation, invalid-ID checks, unauthenticated access and account-isolation coverage. No new vendor destinations. |
| `test/mobile_role_navigation_test.dart` | F04 and stall investigation: move relevant logout/password-update coverage to retained enforcer fixtures, provide complete realistic HTTP-boundary responses, bound asynchronous waits, and dispose auth/router resources before widget-test invariant checks. Remove only demonstrably superseded vendor-positive expectations with rationale. Do not delete security or password-update behavior coverage. |
| `test/navigation_transition_test.dart` | F03: verify selected branch, retained state and actual reduced-motion behavior with bounded settling; distinguish framework housekeeping frames from ongoing transitions. If navigation production code needs changing, stop for expanded scope. |
| `test/notification_typography_layout_test.dart` | F05: reconcile the hard-coded sign-in size with the retained shared title token and preserve relevant account/sign-in assertions. Do not restore a historical size or redesign typography merely for a test. |
| `test/shared_ui_test.dart` | F06–F09: exercise valid loading semantics, actual pulse activity/inactivity, reduced-motion behavior, five current loading cards and a single pulse. Replace obsolete internal type assumptions while preserving observable behavior checks. |
| `test/ticket_ui_test.dart` | F10: use the retained status dropdown, then prove a Paid selection cancels pending search and sends the expected single correctly filtered request. |

User-approved expansion (2026-10-29): also repair the asynchronous HTTP-boundary setup and bounded cleanup in `test/ticket_ui_test.dart` for “detail load failure stays on screen with retry” and “duplicate ticket refreshes use one request and keep empty results on failure.” Preserve retry, duplicate-request suppression and retained-empty-results assertions. Production ticket code remains outside this expansion.

Further explicit user approvals (2026-10-29): replace the obsolete counter template in `test/widget_test.dart` with real signed-out MyApp startup/login/no-staff-navigation coverage using existing auth/router fixtures; repair only the async HTTP setup, bounded waits and cleanup of “profile passwords are obscured and cannot be edited while changing” in `test/profile_ui_test.dart`, preserving masking, disabled-field and failure/re-enable assertions. No production startup/profile change. User subsequently reiterated “just avoid drifting”; report any further unrelated failure without changing it.

Documentation/evidence: `docs/criterion-3-closure-failures.md`, `docs/criterion-3-repair-plan.md`, `docs/revision-criterion-3-slice-2-progress.md` and task evidence under `evidence/revision-ticket-person-identity-2026-10-29/`. Retain historical failures; record dispositions and new results separately.

The client route helper still contains legacy vendor branches. This plan does not authorize deleting vendor modules or changing route/authentication policy. Retained server denial evidence must not be described as proof that every client branch is retired. Any required route-policy change needs its own exact expansion before coding.

## Build and verification order

1. Preserve a task starting-state manifest. Reuse the observed red failures; add meaningful failing accessibility/lifecycle checks before changing production code.
2. Fix the confirmed button defect, then reconcile test fixtures/selectors and cleanup. Do not replace failed assertions with the current output without establishing the intended requirement.
3. Run the affected cases and retained auth/role/password-update tests. Investigate unfinished cases individually rather than repeatedly starting a hanging full run.
4. Run Dart formatting on changed files, `flutter analyze --no-pub`, the 23 existing person/Verify/preview regressions, and `flutter test --no-pub`. Read the final output. Record remaining analyzer findings and every failure; no blanket waiver or exclusion by filename.
5. Build the existing debug APK with existing ignored local defines and explicit local API URL. Install on wireless V2529 preserving app data. Verify retained shared loading/disabled behavior and enforcer navigation/issuing review against the disposable local API, using existing synthetic records. No new retained photo uploads are planned.
6. Stop task runtime processes and remove only task-created forwarding; restore any temporary device setting. Update the acceptance report and propose criterion-3 closure only if the required evidence supports it. Wait for user approval before roadmap closure or the next slice.

## Acceptance criteria in plain language

- Loading controls remain usable by accessibility services and cannot submit twice while busy; reduced motion produces no invalid progress value.
- Hidden/reduced-motion skeletons stop animating and enabled skeletons resume, without equating every pending framework frame with an animation defect.
- Real image-preview assertions pass and synthetic files are released cleanly after the test.
- Retained account changes/logout/password-update behavior is protected. Historical vendor-screen success is not a product requirement.
- Current notification loading UI and the current ticket filter are exercised; filter/search cancellation is actually reached and checked.
- Relevant targeted checks pass, the full suite terminates with accounted-for results, no new analyzer warnings/errors are introduced, and the corrected build passes the affected real-device smoke checks.

If an additional failure, package, production path, contract or prerequisite falls outside this table, stop and present the evidence and smallest scope expansion. Unrelated bugs and the five existing analyzer infos are reported separately. No migrations, operational database access, application-data clearing, commit or push.
