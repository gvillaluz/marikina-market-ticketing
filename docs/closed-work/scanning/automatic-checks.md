# Scanning, calculation and verification — criterion 3, automatic checks (closed 2026-11-10)

Closed by the user on 2026-11-10 after the automated checks, the deliberate breaks and the live check on the phone passed. Full results: `evidence/automatic-checks-live/results.md`; expected results (written first): `evidence/automatic-checks-live/expected-phone.md`.

The criterion: automatic checks flag missing fields and duplicates and suggest business and person matches for confirmation; the account number and owner come from the selected business record; an unresolved identity needs manual confirmation or search, never automatic creation.

## Finding

Every check already existed in the app (from the person slice in October and faster entry A1 to B2). This slice therefore changed **no application code**. It added tests where a check had none, and proved the checks on the current entry page. The new tests pass on their first run because they cover behaviour that already existed; the deliberate breaks below are what show they notice a failure.

## What was added

- **Server tests** (`marikina-market-api/MarikinaMarket.Tests/AutomaticChecksTests.cs`, 6 cases): Submit repeats the same-day duplicate check; a citation without a confirmed person or paper name is refused (4 cases); an unknown person is refused and nobody is created.
- **Phone tests** (`marikina-market-mobile/test/automatic_checks_test.dart`, 10 cases): Verify shows the server's words for a repeated control number and for a same-day duplicate (2); the ordinance list refuses a same-day duplicate citation and a repeat warning, and accepts a clean ordinance (3); Next names every missing item for a ticket and for a warning (2); no ordinance can be picked before the person is confirmed; a suggested person must be tapped before ordinances open; with no match nobody is created.
- **Website:** no change. **Database schema:** no change. **API contract:** no change.

## Evidence

- Server: build 0 errors, 4 warnings (the same count as `main`); 866 passed, 2 skipped (the same 2 as before), 0 failed. The backup tests need `BACKUP_TEST_TEMP_ROOT`, `TEMP` and `TMP` set to a throwaway folder.
- Phone: format clean, `flutter analyze` no issues; 499 passed, 1 failed. The failure is `ordinance_shortcuts_test`, already known to fail in some runs; it failed 1 of 3 solo runs on this code too.
- Deliberate breaks: 10 of 10 caught (3 server: submit ignores duplicates, submit accepts no person or paper name, an unknown person is quietly created; 7 phone: no ordinance never flagged, missing photos never flagged, same-day duplicate not refused, repeat warning not refused, ordinances open without a confirmed person, a single match picked for the enforcer, Verify hides the server message). All files were restored and `git status` confirmed only the two new test files remained.
- Live check on V2529 (worktree app and API against `marikina_market_e2e`): 11 of 11 passed. Missing items for a ticket and a warning; the confirmation steps before ordinances open; "no possible matches" with nobody created (people table still 3); the repeat warning for Maria Santos; the same-day duplicate for Juan Dela Cruz (a made-up pending ticket dated today was added at the user's choice); a repeated control number refused at Verify with Submit off; account number `ACC-100` and owner read from the business record; an unregistered vendor verified with no account number or owner. Submit was never tapped; the two photos stayed on the phone and nothing was uploaded.

## Limits

- Not checked live: the same-day duplicate and repeated control number at **Submit** (Submit would upload photos to the locked evidence storage); they are covered by the new server tests. iPhone not tested. A switched-off market section being hidden from the unregistered list (the test database has none).
- One made-up ticket stays in the test database `marikina_market_e2e`: id 14, pending, Juan Dela Cruz, Sec. 12, control number `AC-LIVE-SAMEDAY`, dated 2026-11-10, no photos.
- Observation, not fixed: the red message under "Select Ordinance" (`ticket_violation_card.dart`) is a row without wrapping, so a long message (for example the "paper-assessed fines" one) may run off a phone screen. Not confirmed on a device.
- Worktree `C:\Users\Admin\Documents\Projects\mmt-automatic-checks` (branch `automatic-checks`, from `main` bf87f4c). Its only changes were the two new test files, committed as `9254f39` (pushed, pull request #11 https://github.com/gvillaluz/marikina-market-ticketing/pull/11, merged into `main` by the user as merge commit `e5eb9ad`). It holds the copied git-ignored `android/app/google-services.json` and `GeneratedPluginRegistrant.java`; delete the key file when the worktree is removed. The test app stays installed on the phone. On 2026-11-10 (user approved) local `main` was fast-forwarded to `e5eb9ad` and the worktree was removed (git stopped with "Filename too long"; the folder was finished with `rd /s /q`), which also removed the copied key file. The branch `automatic-checks` is kept, locally and on GitHub.
