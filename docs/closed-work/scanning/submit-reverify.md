# Scanning, calculation and verification — criterion 6, Submit and Verify again (closed 2026-11-10)

Closed by the user on 2026-11-10, after they confirmed that earlier evidence already proved most of the criterion and approved one new phone test for the part that had no record.

The criterion: Submit starts disabled. Successful verification enables it; any edit to verified ticket information clears verification and disables Submit until verified again. Display: "Information changed. Verify again before submitting." Viewing images/history does not invalidate verification.

## Decision

Closed on existing evidence plus one new test (user decision, 2026-11-10). No new live check. The rule applies to tickets only: a warning has no Verify step (no fine to calculate), and the server checks a warning when it is saved.

## Finding

The phone already did everything in the criterion. This slice changed **no application code**. Most of the criterion was proven by earlier live checks on the phone and by existing tests (below). The only part with no record was viewing a photo on the Review page; a new test covers it.

## Earlier evidence used

| Part of the criterion | Evidence |
| --- | --- |
| Submit starts off; a successful Verify turns it on | Live on V2529: 2026-10-29 (`evidence/revision-ticket-person-identity-2026-10-29/continuation-verification.md`), 2026-10-30 (`evidence/revision-photo-roles-2026-10-30/verification-report.md`), 2026-10-31 (`evidence/ordinance-slice2-2026-10-31/report.md`), 2026-11-09 (`evidence/ticket-flow-a2c-live/results.md`, check 7), 2026-11-10 (`evidence/automatic-checks-live/results.md`, check 8; `evidence/review-verify-live/results.md`, checks 2 and 4). |
| A Verify the server refuses leaves Submit off | Live 2026-11-10: a used control number, Submit stayed off (`evidence/automatic-checks-live/results.md` check 8; `evidence/review-verify-live/results.md` check 2). |
| An edit after Verify turns Submit off until Verify again | Live: description changed (2026-10-29, `continuation-verification.md`); control number, then place changed, and restored values still needed Verify (2026-10-29, `evidence/revision-paper-metadata-2026-10-29/device-gates.json`); a photo deleted (2026-10-30, `verification-report.md`); an "up to" fine changed on Review (2026-10-31, `evidence/ordinance-slice2-2026-10-31/report.md`). Tests: `test/features/tickets/presentation/up_to_assessment_flow_test.dart` (fine changed on Review) and `test/unregistered_entry_flow_test.dart` (section changed after Review, faster entry B2). |
| The message "Information changed. Verify again before submitting." | Live on the entry page (2026-10-29, `continuation-verification.md`) and on the Review page (2026-10-31, `ordinance-slice2-2026-10-31/report.md`); the same two tests. |
| Viewing the person's history keeps verification | Live 2026-10-29: "History viewing left verification enabled" (`continuation-verification.md`). |
| Viewing a photo keeps verification | No earlier record. New test below. |

## What was added

- **Phone test** (`marikina-market-mobile/test/submit_reverify_test.dart`, 1 case): on the Review page Submit starts off; Verify turns it on with "Verified."; the paper ticket photo and then the supporting photo are each opened full screen and closed; after each, Submit is still on, "Verified." is still shown, "Information changed" is not shown, and no new check was started; the only request was the one Verify (nothing saved).
- **Server, website, database schema, API contract:** no change.

## Evidence

- The new test passed on its first run, because it covers behaviour that already existed. The first try did not run: the test was missing one import, and it first checked before the photo screen had finished closing. Both were fixed before counting.
- Deliberate breaks: 3 of 3 caught after one test fix. (1) Touching a photo clears verification: caught (Submit off). (2) Touching a photo starts a new Verify: at first **not caught**, because inside the test the extra check never reached the fake server, so the "only one request" line could not see it; the test now also checks that the phone's Verify state is still "verified", and the break is caught. (3) Submit no longer waits for Verify: the first version of this break did not actually turn Submit on (another condition still kept it off); it was rewritten and is caught. After each break the file was put back with `git checkout`; `git status` showed only the new test file.
- `dart format` on the new file only; `flutter analyze --no-pub`: no issues. Full phone suite: 514 passed, 1 failed. The failure is `ordinance_shortcuts_test` ("shows the three shortcut groups…"), already known to fail in some full runs and not touched here; it passed 3 of 3 when run alone. The new test passed again afterwards.

## Limits

- Not checked live: viewing a photo on Review (test only, by user decision). Most live edit checks above were made before the entry page was rebuilt for faster entry (2026-11-06 to 2026-11-10); since then, the B2 test and the 2026-11-10 live checks show the on/off behaviour still works, and the rebuilt entry page tracks every field for the "changed" message. iPhone not tested.
- Coming back to Review after Back always needs a new Verify, even when nothing changed. This is stricter than the criterion and was left as it is.
- Worktree `C:\Users\Admin\Documents\Projects\mmt-submit-reverify` (branch `submit-reverify`, from `main` d066b4c). Its only change is the new test file, not yet committed. Only `flutter pub get --offline` was run there (user approved); no key file was copied and no app was built. The test was committed as `72a0d58`, pushed, and pull request #14 was merged by the user (merge commit `5639221`). On 2026-11-11 (user approved) the worktree was removed; the branch is kept, locally and on GitHub.
