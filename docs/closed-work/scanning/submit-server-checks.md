# Scanning, calculation and verification — criterion 8, the server's checks at Submit (closed 2026-11-11)

Closed by the user on 2026-11-11. Earlier evidence already proved most of the criterion; the user approved three new server tests for the parts that had no record. There was no live check (user decision, option A).

The criterion: the server repeats authorization, validation, duplicate and calculation checks at submission. Image and record are saved consistently; retries and concurrency cannot add duplicate offenses. A changed tier or fine requires renewed review and verification. Only a successful submission contributes to history.

## Finding

The server already did everything in the criterion. This slice changed **no application code**. The code that protects against two submits at once (one transaction that refuses conflicting saves, and a control number that must be unique) has not changed since the live checks of 2026-10-29 and 2026-10-30, apart from message wording ("paper reference" became "control number" on 2026-11-07). Unregistered vendors (faster entry B1, 2026-11-09) go through the same Submit path.

## Earlier evidence used

| Part of the criterion | Evidence |
| --- | --- |
| Sign-in and role checked again | Only an enforcer can submit; the enforcer comes from the sign-in. Live 2026-10-29: refused when not signed in (401) and for office staff (403) (`evidence/revision-paper-metadata-2026-10-29/verification-report.md`). Live 2026-10-30: a faked enforcer number was ignored (`evidence/revision-warning-person-2026-10-30/verification-report.md`). Test `Inspection_uses_the_authenticated_enforcer_instead_of_the_submitted_id`. |
| Details checked again | Control number, place, confirmed person, one paper photo plus at least one supporting photo, real JPEGs under the size limit: tests in `InspectionNotificationTests.cs`, `AutomaticChecksTests.cs`, `UnregisteredTicketTests.cs`; live 2026-10-29 (`revision-paper-metadata-2026-10-29`). |
| Duplicates checked again | A used control number and a same-day duplicate are refused at Submit: `AutomaticChecksTests.cs` (2026-11-10), `Existing_paper_reference_blocks_verify_and_save_without_upload`; live 2026-10-29. |
| Fine worked out again | A changed offense number, severity or "up to" setting is refused at Submit: `Stale_review_requires_verification_before_upload_or_save`, `Changed_configuration_after_verify_requires_review_before_upload`. Live 2026-10-29: a ticket saved in between gave 409, nothing saved, and a new Verify said 2nd offense (`evidence/revision-ticket-person-identity-2026-10-29/continuation-verification.md`). |
| Photos and record saved together | All checks run before any upload; the ticket and its photo rows are saved in one transaction; a failed upload saves nothing (`Upload_failure_rolls_back_citation_without_creating_evidence_rows`). Live 2026-10-30 (`evidence/revision-photo-roles-2026-10-30/verification-report.md`). |
| Two submits at once | One saved, the other refused (201/409): live 2026-10-29 for the same person, ordinance and day, and for the same control number (`continuation-verification.md`, `revision-paper-metadata-2026-10-29/verification-report.md`); live 2026-10-30 for warnings (`revision-warning-person-2026-10-30/verification-report.md`). Test `Concurrent_citation_collision_is_a_controlled_conflict`. |
| Connection lost before sending | Nothing saved; one later retry saved exactly one ticket: live 2026-10-29 and 2026-10-30. |
| Only a successful submit counts | Verify saves nothing (`ReviewVerifyTests.cs`, 2026-11-10); a failed submit is undone (`Notification_save_failure_rolls_back_inspection_without_push`, the upload and collision tests). |

## What was added

- **Server tests** (`marikina-market-api/MarikinaMarket.Tests/SubmitChecksTests.cs`, 3 cases). The ticket, ordinance and person queries are the real ones, run over an in-memory list of tickets; photo storage is faked, so nothing is uploaded. Juan Dela Cruz (person 31) has one earlier paid ticket on Sec. 12 (fines ₱500, ₱1,000, ₱1,500), so his next one is the 2nd offense, ₱1,000.00 (worked out by hand).
  1. The office changes the Sec. 12 2nd-offense fine to ₱1,200 after Verify. Submit is refused with "Offense history or the calculated fine changed. Review and verify again before submitting.", with no upload and nothing saved. Verify again still says 2nd offense, now ₱1,200.00, so the refused Submit added nothing. Submitting after that saves the ticket with ₱1,200.00.
  2. The first Submit saves (two Sec. 12 tickets, both photos uploaded once). The same ticket sent again, as after a lost answer, is refused because the control number is already used. With a new control number it is refused as a same-day duplicate. Still one new offense and one upload.
  3. An unregistered vendor (no business, section 3): another officer saves a Sec. 13 ticket for Juan between Verify and Submit. Submit refuses it as a same-day duplicate before any upload.
- **Website, phone, database schema, API contract:** no change.

## Evidence

- The three tests passed on their first run, because they cover behaviour that already existed. The deliberate breaks below are what show they notice a failure.
- Deliberate breaks: 4 of 4 caught. (1) Submit ignores a changed fine amount: test 1. (2) Submit skips the used-control-number check: test 2. (3) Submit finds no same-day duplicates: tests 2 and 3. (4) Submit finds no same-day duplicates only for an unregistered vendor: test 3. The first versions of (3) and (4) only blanked the refusal on one line and were **not caught**: a second, older refusal a few lines further down throws the same error when every chosen ordinance is a duplicate, so the check was still on. Both were redone at the duplicate lookup and were caught. After each break the file was put back with `git checkout`; `git status` showed only the new test file.
- Server build: 0 errors, 8 warnings, all in existing code or packages (none from the new file). Full server suite: 873 passed, 2 skipped (the usual two opt-in tests), 0 failed. The backup tests need `BACKUP_TEST_TEMP_ROOT`, `TEMP` and `TMP` set to a throwaway folder.

## Limits

- Not checked live (user decision, option A): two submits at once were last checked on the real server on 2026-10-29 and 2026-10-30; a retry after a lost answer and Submit for an unregistered vendor are tests only. iPhone not tested.
- Known storage limit (accepted 2026-10-29 and 2026-10-30): a submit that loses a race after its photos were uploaded leaves them in the locked evidence storage with no ticket. A ticket never points to missing photos.
- Observation, not fixed: the same-day duplicate check exists twice in the Submit code (the current refusal and an older one below it). It works, but it is redundant.
- Worktree `C:\Users\Admin\Documents\Projects\mmt-submit-checks` (branch `submit-checks`, from `main` cf2843b). Only `dotnet restore` was run there (user approved); no key file was copied. Its only change is the new test file, committed as `f47b9f4`, pushed, pull request #16 https://github.com/gvillaluz/marikina-market-ticketing/pull/16 (not merged). Merged by the user on 2026-11-11 as merge commit `6e552f5`; local `main` was fast-forwarded to it. On 2026-11-11 (user approved) the worktree was removed; the branch is kept, locally and on GitHub.

## Earlier roadmap note (moved word for word on 2026-11-11, when the whole section closed)

Note for the next ticket-verification slice: focused Review/Verify/Submit and device evidence exists, but full-suite, live-environment and some device checks remain incomplete; do not mark the slice passed yet.

All eight criteria of "Scanning, calculation and verification" are now closed. What the note still describes as incomplete (the full phone test run, live and device checks, iPhone) is tracked by Phase 1, Phase 2 and Phase 4 in the roadmap.
