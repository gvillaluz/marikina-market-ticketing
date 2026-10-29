# Criterion 3 — failure triage and closure checklist

Updated: 2026-10-29 (Asia/Manila).

**Status: criterion 3 closed 2026-10-29 with accepted unrelated limits.** The user's conditional closure approval applies after review confirmed the remaining vendor-app paging stall and five analyzer infos are unrelated to criterion 3. See [closure decision and acceptance matrix](criterion-3-closure.md). Open historical checklist items below remain deferred observations or are superseded by that decision; they are not silently marked passed. This file authorizes no further repairs or next slice.

Repair checkpoint before closure: [approved repair verification](../evidence/revision-ticket-person-identity-2026-10-29/repair-verification.md). All 60 tests across the approved repair files pass, and the 23 identity/Verify/preview regressions pass. The ten original failures have been repaired or reconciled with retained behavior. APK build/install and the scoped real V2529 smoke passed; all ticket/person/evidence hashes remained unchanged and task runtime/device settings were restored. The full run reached 451 passes with no reported assertion failures but stalled with the legacy records paging case active; it was stopped and is **not** a passing full suite. Five unchanged analyzer infos remain recorded. These unrelated limits were subsequently accepted for criterion-3 closure as documented above.

Earlier checks: [wireless V2529 legacy verification and isolated triage](../evidence/revision-ticket-person-identity-2026-10-29/closure-checks.md). Live legacy display passed in both clients; fixture restoration hashes matched. The original ten-failure red run remains historical evidence.

## Current product scope

There is **no vendor-facing application**. An individual vendor/person is a registry identity without a login account. Staff and enforcers use the retained applications. Business, registered owner, confirmed person and paper violator name are separate concepts.

Do not restore vendor login, vendor screens or vendor notification navigation to satisfy historical tests. Positive vendor-app expectations may be obsolete. Security checks that prevent retired vendor accounts from accessing the system still matter. Inspect mixed tests assertion by assertion before changing them.

Judge criterion 3 against its approved person/identity/history requirements and [slice-2 plan](revision-criterion-3-slice-2-plan.md), not against every historical vendor feature. Unrelated failures remain observations unless evidence connects them to an approved acceptance criterion. Required repository checks must still be run and their outcomes accounted for; obsolete assertions are not passing tests or silently waived failures.

## Evidence already obtained

- API recorded full suite: **632 passed, 2 skipped**; focused final suite: **42 passed**. Skips are not live passes.
- Fresh web build and **129 Node tests passed**.
- Flutter focused regression/contract/review/navigation checks: **23 passed**. Corrected debug APK built and installed preserving V2529 app data.
- Real API, browser and V2529 issuing flow passed within the [recorded acceptance matrix](../evidence/revision-ticket-person-identity-2026-10-29/continuation-verification.md). Device-issued ticket 266/control 18 belongs to person 8, business 1 and authenticated enforcer 3, with PHP500 assessed.
- The mobile save-use-case defect that dropped person ID, paper name and reviewed calculation was fixed, with a regression that failed before the correction and passed afterward.
- Post-fix full Flutter run: **375 passed, 10 failed, then stalled**. Stopped after over 120 seconds without progress. The same ten failing cases were observed before the forwarding fix; this does not prove they predate the entire slice.
- Final analyzer: **five informational findings**, zero warnings/errors. Its nonzero exit remains recorded.

Sources: [full Flutter log](../evidence/revision-ticket-person-identity-2026-10-29/continuation-full-after-fix.log), [stall record](../evidence/revision-ticket-person-identity-2026-10-29/continuation-full-after-fix-stop.txt), [analyzer log](../evidence/revision-ticket-person-identity-2026-10-29/continuation-analyze-clean.log), [progress checkpoint](revision-criterion-3-slice-2-progress.md).

## 1. Classify the ten failures before proposing fixes

These are observed assertions, not confirmed root causes. For each item record: current requirement, isolated reproduction, test-versus-product diagnosis, relation to criterion 3, proposed allowed files, and evidence needed to resolve it.

| ID | Test file / failed case | Observed failure | Required investigation / correct disposition |
| --- | --- | --- | --- |
| F01 | `test/inspection_creation_ui_test.dart` — photo preview uses valid parent data and bounds thumbnail decoding | Windows could not delete the temporary photo directory because a file was still open. | Inspect image/file disposal and test teardown. Determine whether the leak belongs to application code or the test harness. Do not label this a failed camera capture solely from the cleanup exception. Relevant to retained inspection photo handling. |
| F02 | `test/mobile_role_access_test.dart` — notification taps respect role and validate ticket IDs | Expected `/vendor/notifications`; actual `/vendor/records/42`. | Separate obsolete positive vendor navigation expectations from retained role/ID validation. Do not implement either vendor destination. Preserve or replace genuine denial/security assertions against the current retired-vendor policy, after scope approval. |
| F03 | `test/navigation_transition_test.dart` — rapid tab changes and reduced motion settle on the selected branch | A frame remained scheduled when the test expected none. | Reproduce retained enforcer navigation. Determine whether actual motion continues, cleanup is incomplete, or a framework/timing assumption is too strict. Do not infer a visible animation defect from the frame flag alone. |
| F04 | `test/mobile_role_navigation_test.dart` — logout and restored vendor sessions cannot expose prior navigation | A periodic authentication timer remained after widget disposal. | Classify vendor-screen expectations separately. Retain logout/account isolation and denial of retired-role access. Trace ownership of the timer and test teardown; do not assume the pending test timer proves a production session leak. |
| F05 | `test/notification_typography_layout_test.dart` — account edit keeps its original size and sign-in is unchanged | Expected sign-in heading size 24; actual 22. | Compare the test with the intended retained sign-in design. Change product typography only if the expectation is still required; otherwise reconcile an outdated assertion with documented rationale. Not automatically a criterion-3 identity defect. |
| F06 | `test/shared_ui_test.dart` — outlined button blocks duplicate taps while loading and supports disabled state | Flutter rejected progress accessibility semantics: value `In progress` with numeric range 0–100. | Inspect shared loading-control semantics and actual accessibility behavior. Preserve duplicate-tap prevention and disabled states. Shared controls may affect the enforcer issuing flow; root cause and affected consumers need confirmation. |
| F07 | `test/shared_ui_test.dart` — inactive skeleton pauses and resumes when its tab becomes active | A frame remained scheduled after the tab became inactive. | Check ticker/animation lifecycle and whether the test correctly isolates it. Verify retained enforcer loading screens if a shared component changes. |
| F08 | `test/shared_ui_test.dart` — notification placeholders use one pulse for the group | Expected five `SkeletonBox` widgets; found zero. | Inspect the current loading component structure. Determine whether this is an obsolete widget-structure assertion or a missing loading state. Verify observable behavior; do not recreate an old widget tree merely to satisfy its type count. |
| F09 | `test/shared_ui_test.dart` — skeleton stops scheduling frames when reduced motion is enabled | A frame remained scheduled with reduced motion enabled. | Distinguish ongoing animation from one pending framework frame. Verify intended reduced-motion behavior before changing code or expectations. |
| F10 | `test/ticket_ui_test.dart` — changing ticket status cancels pending search debounce | The test could not find a `ChoiceChip` labelled `Paid` to tap. | Check the actual retained ticket filter control. Exercise that control and prove pending search cancellation and expected request count. The current failure occurs before the debounce behavior is tested. |

All test paths in this table are relative to `marikina-market-mobile`.

- [x] Give each original failure a confirmed disposition; see the repair report for F01–F10.
- [x] Reconcile only confirmed superseded expectations; retain the historical failure evidence and explain the replacement/removal.
- [x] Preserve relevant authentication, authorization, logout and account-isolation protections in the passing retained-role tests.
- [x] Repair only approved current defects, with recorded red evidence before the production fix.
- [x] Record unrelated failures separately; the additional legacy records runner stall is outside the repair scope and remains unresolved.

## 2. Resolve or explain the full-suite stall

The last printed test concerned a mandatory password update, but interleaved parallel output does **not** establish that it caused the stall.

Repair update: retained enforcer password-update/logout cases now terminate and pass. User-approved ticket refresh/retry, startup and profile test additions also pass. The fresh full run (`repair-full-suite-final.log`) reached 451 passes and no reported failed assertions, then made no progress with `records_feature_test.dart` / “scrolling fetches only at the bottom and stops after the last page” active. The owned process tree was stopped, with timestamp and counts in `repair-full-suite-final-stop.json`. That legacy vendor-records test file is unchanged and outside the approved repair scope. Its active-test status identifies the remaining investigation target, not a confirmed production defect. Do not mark the full suite passed or infer approval to repair/retire that file.

- [ ] Identify unfinished test files/cases and reproduce them individually.
- [ ] Inspect pending futures, timers, streams, BLoC/router disposal and test teardown based on evidence.
- [ ] Distinguish a product lifecycle defect from test isolation or runner/environment behavior.
- [ ] Obtain a terminating full-suite run with explicit final counts after approved corrections/reconciliation.
- [ ] Do not count a stopped run as passed or repeatedly rerun it without diagnosing the lack of progress.

## 3. Account for the five analyzer infos

| ID | Location in `marikina-market-mobile` | Finding | Disposition needed |
| --- | --- | --- | --- |
| A01 | `lib/core/notification/widgets/in_app_notification_banner.dart:87` | Deprecated `withOpacity` usage. | Classify as retained shared-code maintenance; obtain scope approval before changing it. |
| A02 | `lib/core/usecases/usecase.dart:3` | Generic type parameter named `Type` matches a visible type. | Style/naming finding; check callers before any approved rename. |
| A03 | `lib/features/lookup/presentation/bloc/lookup_bloc.dart:6` | Empty constructor body should use a semicolon. | Style finding; not evidence of failed person identification. |
| A04 | `lib/main.dart:16` | Import of `flutter_native_splash` is not declared as a direct dependency. | Investigate existing startup/dependency usage. Do not add a package or alter startup behavior without approval. |
| A05 | `test/features/tickets/presentation/inspection_photo_controls_test.dart:52` | Missing braces around an `if`. | Test style finding; fix only within approved test scope. |

- [ ] Record which findings are required fixes and which are documented unrelated limits.
- [ ] Run the analyzer after approved changes and report the actual exit code and remaining findings.
- [ ] Do not call these infos runtime crashes or assume the earlier criterion-1 Flutter deferral covers criterion 3.

## 4. Complete the legacy-null client verification gap

Completed 2026-10-29 using wireless V2529 and the real browser/API. Evidence: [closure checks](../evidence/revision-ticket-person-identity-2026-10-29/closure-checks.md). This supersedes the earlier missing-client-capture status only.

- [x] Use an explicitly identified synthetic legacy fixture in disposable local `marikina_market_e2e`; record its original values and restore them afterward.
- [x] In the real web consumer, show legacy person identity as unconfirmed, with the registered owner kept separate.
- [x] On V2529, verify the same explicit unconfirmed meaning in the retained record display.
- [x] Confirm there is no owner-to-person backfill, automatic merge or reassignment of history.
- [x] Save sanitized results/screenshots and restoration evidence; an absent screenshot alone is a verification gap, not proof of a product defect.

Do not execute migrations, rerun historical resets/creation sequences, or use operational data. Any test uploads must respect the already recorded 365-day retention restriction. Preserve installed app data and restore task-created device settings/forwarding.

## 5. Verification and closure gate

Suggested order for the next approved task: classify obsolete/current tests → reproduce relevant failures/stall → approve exact repair files → fix and verify → finish legacy-client checks → reconcile closure evidence. This is a proposed work order, not authorization to implement every item above.

Use installed dependencies and existing commands:

```powershell
# From marikina-market-mobile; format only approved changed files.
dart format <approved-changed-files>
flutter analyze --no-pub
flutter test --no-pub

# Build/install the approved debug target when application code changes.
# Use the existing ignored local defines and explicit disposable local API URL.
```

If API/web code changes are approved, also run their required build/test commands from `feature-workflow.md`, update all actual consumers of any contract change, and repeat affected real API/browser/device checks. No contract or schema change is proposed by this document.

- [ ] Keep the passing person/identity/history/Verify/Submit regression and real issuing story intact.
- [ ] Report implementation, automated checks and real E2E acceptance separately.
- [ ] Account for every full-suite failure/stall: corrected, superseded with rationale, or explicitly documented as unrelated. Obtain explicit user deferral for any required verification that remains unmet; do not infer it from vendor retirement.
- [x] Complete the required live legacy-client checks or record an explicitly approved scoped deferral. Both clients passed; no deferral used.
- [ ] Reconcile both criterion-3 slices and older checkpoint wording against the final evidence. Historical pending statements must not be mistaken for current results.
- [ ] Present pass/fail per approved criterion and any remaining limits, then propose closing criterion 3. Wait for user approval before changing roadmap completion or starting another slice.

## Observations outside this closure checklist

- Saved mobile detail showed `Address is unavailable`. Do not substitute the owner/person address or redesign paper-address capture without a separate approved requirement.
- The test-fixture control-number issue was corrected in synthetic fixtures. Do not expand this into a product numbering redesign under criterion 3.
- A possible unlinked synthetic upload from the earlier concurrent loser remains a storage-inventory limitation. The report does not claim exhaustive bucket cleanup or immediate deletion of retention-locked objects.
- OCR/scanning, new paper-reference rules, settlement/reporting changes and restoring a vendor application remain outside this work.
