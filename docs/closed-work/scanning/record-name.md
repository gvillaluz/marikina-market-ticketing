# Scanning, calculation and verification — criterion 7, calculated counts and the violator's name (closed 2026-11-10)

Closed by the user on 2026-11-10, after they decided how the violator's name works, confirmed that earlier evidence already proved the rest, and approved tests only (no live check).

The criterion: counts and fines are calculated, not editable. A business is corrected through selection; registry editing is separate. Keep the editable paper violator name next to the confirmed person.

## Decision

**The violator's name always comes from the chosen person's record** (user decision, 2026-11-10). The "editable paper name" part of the criterion is dropped. It was not built and is not counted as passed. The reason: the enforcer fills in the app and then copies to the paper, so the app is the source for what is written. This is the same reasoning as the dropped paper-fine comparison in criterion 4.

What follows from it:
- Choosing a person fills the name box with the name on that person's record.
- Editing the name afterwards un-chooses the person and clears the chosen ordinances, because the offense history belongs to the person. Choosing the person again puts the record name back.
- A misspelling on a record is corrected by the office, not on the ticket. A ticket already saved keeps the name it was saved with (the server stores the ticket's name separately; proven 2026-10-29).
- A person who is not in the system yet is added with "New person" after the search finds nobody; they are then on their first offense. A person with history at another business is found by the same search, and offenses are counted per person across businesses. Both already worked (faster entry A1, live 2026-11-06).

## Finding

The phone and server already did everything in the criterion. This slice changed **no application code**. It added tests for the one behaviour that had none: editing the name after a person is chosen.

## Earlier evidence used

| Part of the criterion | Evidence |
| --- | --- |
| Counts and fines are calculated, not editable | The phone shows them as text; the one typed amount is an "up to" fine, which the server keeps inside the legal range. The server recalculates at Verify and at Submit and refuses a changed fine or offense number: tests in `marikina-market-api/MarikinaMarket.Tests/InspectionNotificationTests.cs` (the reviewed calculation altered to a different severity or offense number is refused) and `ReviewVerifyTests.cs`; live on the phone for the fine changing between copy and Verify (`evidence/fine-position-live/results.md`). |
| A business is corrected by selection; registry editing is separate | Back to the entry page and pick again (`evidence/review-verify-live/results.md`, check 3). An enforcer is refused (403) when editing a business or a person: `evidence/business-person-live/results.md` check 5 (2026-11-07) and `evidence/revision-person-registry-2026-10-28/`. |
| Choosing a person fills the name | Live 2026-11-06, `evidence/ticket-flow-a1-live/results.md` check 3; phone tests in `test/business_people_test.dart`. |
| Editing the name clears the person and the ordinances | Live 2026-10-31, `evidence/ordinance-slice2-2026-10-31/report.md` ("Each name edit correctly cleared person confirmation and ordinance selection"). The code for this was not changed after that date. |
| The ticket keeps its own name when the record changes later | Server test `Verify_does_not_save_and_submission_preserves_paper_and_confirmed_identity`; live 2026-10-29, `evidence/revision-ticket-person-identity-2026-10-29/continuation-verification.md`. |
| New person; history at another business | Live 2026-11-06, `evidence/ticket-flow-a1-live/results.md` checks 2, 3 and 5; server code counts offenses by person. |

## What was added

- **Phone tests** (`marikina-market-mobile/test/record_name_test.dart`, 2 cases):
  1. Name box: after typing "pedro" and choosing Pedro Reyes (person 3), the box reads "Pedro Reyes" and the person is reported as chosen with that name. Changing the box to "P. Reyes" reports no person, with "Confirmed person" and "Selected" gone. Choosing him again puts "Pedro Reyes" back.
  2. Entry page: choosing Juan Dela Cruz (person 31) after typing "Juan Cruz" fills "Juan Dela Cruz"; Section 69 is chosen. Changing the name to "J. Cruz" removes the person and the ordinance, and "Select Ordinance" refuses with "Confirm the violator’s person record first." Choosing him again restores the record name. On Review, "Recorded violator" and "Confirmed person" both show Juan Dela Cruz (Person 31), and Verify sends the name "Juan Dela Cruz" with person 31.
- **Server, website, database schema, API contract:** no change.

## Evidence

- The two tests passed on their first run, because they cover behaviour that already existed. The deliberate breaks below are what show they notice a failure.
- Deliberate breaks: 4 of 4 caught. (1) Editing the name keeps the person. (2) Choosing a person does not refill the name box. (3) The box shows the record name but the ticket keeps the typed text. (4) Editing the name keeps the ordinances: at first **not caught** (the break hit the Warning/Ticket switch, not the name change, and the test looked only at text on screen); the test now also reads the list the ordinance card holds, and the break, aimed at the name-change handler, is caught. All app files were put back with `git checkout`; `git status` showed only the new test file.
- `dart format` on the new file: no change; `flutter analyze --no-pub`: no issues. Full phone suite: 516 passed, 1 failed. The failure is `ordinance_shortcuts_test` ("shows the three shortcut groups…"), already known to fail in some full runs and not touched here; it passed 3 of 3 when run alone.

## Limits

- Not checked live (tests only, by user decision): a misspelled name being replaced by the record name when a person is tapped. Earlier live checks showed the tap filling the name, but with a name that already matched. iPhone not tested.
- Observation, not fixed: the entry page's "Paper violator name" box keeps that label, and the "Paper-assessed fine" label on the "up to" field still reads as if the paper were the source.
- Worktree `C:\Users\Admin\Documents\Projects\mmt-record-name` (branch `record-name`, from `main` 5639221). Its only change is the new test file, not yet committed. Only `flutter pub get --offline` was run there (user approved); no key file was copied and no app was built. The test was committed as `127f73d`, pushed, and pull request #15 was merged by the user (merge commit `cf2843b`). On 2026-11-11 (user approved) the worktree was removed; the branch is kept, locally and on GitHub.
