# Scanning, calculation and verification — criterion 5, Review and Verify (closed 2026-11-10)

Closed by the user on 2026-11-10 after the automated checks, the deliberate breaks and the live check on the phone passed. Full results: `evidence/review-verify-live/results.md`; expected results (written first): `evidence/review-verify-live/expected-phone.md`.

The criterion: the Review page shows the paper photo and editable fields; Verify validates the corrected details, rechecks duplicates and recalculates from the person's current history; it does not save a final record or increase offense history.

## Decision

"Editable fields" means **go Back to the entry page** (user decision, 2026-11-10). The Review page itself does not get edit boxes (only the "up to" fine amount can be typed there, as before). The scanner that the Review edit boxes were meant for was dropped on 2026-11-04, and the entry page keeps everything typed, so a mistake is fixed there and Verified again. The history-changed case (a ticket saved between two Verifies) is tests only, by user decision.

## Finding

Everything in the criterion already existed (person slice, faster entry, fine position). This slice therefore changed **no application code**. It added tests where a behaviour had none and proved the behaviour on the phone. The new tests pass on their first run because they cover behaviour that already existed; the deliberate breaks below are what show they notice a failure.

## What was added

- **Server tests** (`marikina-market-api/MarikinaMarket.Tests/ReviewVerifyTests.cs`, 4 cases; they run the real ticket and ordinance queries over an in-memory list of tickets): Verify reads the history as it is now (one earlier ticket gives 2nd offense ₱1,000.00; after another ticket is saved, the next Verify gives 3rd offense ₱1,500.00); Verify twice saves nothing, uploads nothing, sends nothing and adds no offense; a corrected control number is checked again (a used number is refused, the fixed one passes); corrected ordinances are checked again for a same-day duplicate.
- **Phone tests** (`marikina-market-mobile/test/review_verify_test.dart`, 3 cases): the Review page shows the paper ticket photo apart from the supporting photo; Verify only sends a check (never a save), even pressed twice; Back keeps the typed control number, place, name and description, and the next Verify carries the fixed control number with everything else unchanged.
- **Website, database schema, API contract:** no change.

## Evidence

- Server: build 0 errors, 4 warnings (the same count as `main`); 870 passed, 2 skipped (the same 2 as before), 0 failed. The backup tests need `BACKUP_TEST_TEMP_ROOT`, `TEMP` and `TMP` set to a throwaway folder.
- Phone: format clean, `flutter analyze` no issues; full suite 513 passed, 1 failed. The failure is `ordinance_shortcuts_test`, already known to fail in some full runs; it passed 5 of 5 when run alone. The new test file passed 3 of 3 on two reruns.
- Deliberate breaks: 8 of 8 caught (server: Verify ignores history; Verify saves; the control number is not rechecked; the duplicate is not rechecked. Phone: the paper photo hidden on Review; Verify also submits; Back loses the typed details; the next Verify gets the old control number). One break first did not take effect (the file has Windows line endings) and one test needed its fake save to return a number; both were fixed and re-run before counting. All files were restored and `git status` confirmed only the two new test files remained.
- Live check on V2529 (worktree app and main-folder server build against `marikina_market_e2e`): 7 of 7 passed. The Review page shows both photos; a used control number is refused at Verify with Submit off; Back keeps everything typed; the fixed number passes ("Verified.", Sec. 30 2nd offense ₱3,000.00, owner and account number from the business record, Submit on); a second Verify gives the same result; nothing was saved (13 tickets, 3 people). Submit was never tapped; the two photos stayed on the phone and nothing was uploaded. No change was made to the test database.

## Limits

- Not checked live: a ticket saved between two Verifies (tests only, by user decision); Submit and the saved record; iPhone. A same-day duplicate fixed by going Back cannot be reached live, because the ordinance list refuses it before Verify (criterion 3); a server test covers it.
- Observations, not fixed: choosing a person ("Same person – select") replaces the paper violator name with the name on the person's record, and editing the name clears the chosen person, so the paper spelling cannot yet be kept next to the confirmed person (criterion 7). The entry page fills the place from the business record ("Groceries Section, Stall 12") instead of leaving it empty.
- Worktree `C:\Users\Admin\Documents\Projects\mmt-review-verify` (branch `review-verify`, from `main` 908eb5e). Its only changes were the two new test files, committed as `baa597b` (pushed, pull request #13 https://github.com/gvillaluz/marikina-market-ticketing/pull/13, merged into `main` by the user as merge commit `d066b4c`). It held the copied git-ignored `android/app/google-services.json` and `GeneratedPluginRegistrant.java` (scanner line fixed by hand). The test app stays installed on the phone. On 2026-11-10 (user approved) local `main` was fast-forwarded to `d066b4c` and the worktree was removed (git needed `--force` for seven auto-generated Flutter plugin files and then stopped with "Filename too long"; the folder was finished with `rd /s /q`), which also removed the copied key file. The branch `review-verify` is kept, locally and on GitHub.
