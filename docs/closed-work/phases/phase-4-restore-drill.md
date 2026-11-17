# Phase 4 — restore drill (slice 1 done; the roadmap criterion is still open)

The roadmap line: "User-operated restore drill and required external-service outage/restart stories pass in a disposable environment; automated restore alone is insufficient."

**Slice 1 was marked finished by the user on 2026-11-17.** **This note closes only the restore-drill half, run on 2026-11-17.** The outage and restart stories (internet off, a real kill during a backup, the local database stopped) have not been run. The roadmap line stays open until they are, or until the user decides to split the line. This note does not tick it.

Plan: `spec-restore-drill-outage.md` in the project root (slices 1 to 3). Evidence, step by step with the limits for each row: [results](../../../evidence/phase-4-restore-drill/results.md); expected results written beforehand: [expected-results](../../../evidence/phase-4-restore-drill/expected-results.md); how to repeat it: [runbook](../../../evidence/phase-4-restore-drill/README.md).

## Why the earlier restore did not count

The restore on 2026-10-17 was run by a test program, on a database with 35 migrations (the source now has 50 that EF Core runs). The website's Restore button is switched off on purpose ("Restores are currently unavailable"), and nothing outside a test could open a downloaded backup file. No application code was changed for this drill; the missing piece was a small helper.

## What was built (evidence folder only, no app, API or database change)

- `decrypt-mmbak.mjs`: opens a downloaded `.mmbak` backup using Node's built-in tools (no new package). It refuses a wrong key, a changed file, a wrong version and a short file, and writes nothing in those cases.
- `decrypt-mmbak.test.mjs`: 9 tests. They failed first, and when the helper's final authentication check was removed on purpose two of them failed again, so they catch tampering.
- Scripts the user ran: `Run-Decrypt.ps1`, `Run-RestoredApi.ps1`, `Copy-E2ELogin.ps1`. Scripts the agent ran: `Start-DisposableSystem.ps1`, `Stop-DisposableSystem.ps1`, `Swap-HeadAdminEmail.ps1`. `compare-counts.sql` counts rows per table.

## What was checked, and the result (all on the disposable `marikina_market_e2e`)

| Step | Result |
| --- | --- |
| Back Up Now, then download | Completed, 128608 bytes. The file starts with the 5-byte header and its length equals the size in history. |
| Decrypt (user) | `restore.dump` of 128575 bytes, starts with `PGDMP`; `pg_restore --list` reads its 233 entries. |
| Restore into a new empty database (user) | `pg_restore --exit-on-error` exit code 0, no error text. |
| Migrations | Same count as the source (49 applied; see limits). |
| Row counts, 30 tables | Equal except `backups`, 0 in the source and 1 in the restored copy, exactly as predicted from the code (the dump holds that backup as an unfinished attempt). |
| Wrong key, and a file changed by one byte | Both refused with a plain message; no output file. |
| Restored copy opened in the app (user) | Backups page shows the interrupted backup; counts correct; a ticket photo loads. |

## Finding F1: starting the API on a restored copy deletes the backup it was restored from

Every dump holds its own in-progress backup row, marked cleanup pending and pointing at the very file being made. When the API starts on a restored copy it marks that row failed and then deletes its storage file (`AutomaticBackupService`, `BackupService`, `BackupRepository`). Observed live: six seconds after the restored API started, the row got a deletion time and the audit log recorded `CleanupBackup Success`, "Expired backup was removed from storage." This is existing behavior and was not changed. It means that in a real recovery, the backup you restored from would be removed from storage within seconds of starting the system, unless storage is pointed elsewhere first. Whether to change it is a separate decision for the user.

## Limits

- Several results are the user's own report in chat, without screenshots (Backups page text, "counts correct", the photo).
- F1's deletion rests on the audit entry and the row's deletion time. The bucket itself was not checked to confirm the object is gone.
- `marikina_market_e2e` had 49 of the 50 migrations EF Core runs. The missing one (`20261115053624_Recommendations`) is an untracked migration with an empty body, so it adds no schema. The migration `20261004000000_AddVendorRegistrationUsername` has no Designer file, so EF Core ignores it.
- One disposable database on the same PostgreSQL server as the user's other databases, not a separate server. Real email, real backup storage and the real Evidence bucket were used.
- The Head Admin test account's email was undeliverable, so it was temporarily pointed at the user's inbox and put back afterwards.
- Windows/PostgreSQL 18.6 only. The tool paths in October's drill (`D:\PostgreSQL`) no longer exist; the current ones are in the runbook.

## Cleanup done

Servers stopped; the Head Admin's original email restored; the drill's own backup row removed from the test database (backups back to 0); the downloaded backup and the plaintext dump deleted; the restore database dropped by the user (confirmed by a read-only list of databases). The user's own dev servers were stopped at the user's request and were not restarted by the agent.

## Still open

- The outage and restart stories (slices 2 and 3 in the plan).
- Whether to split the roadmap line so the restore drill can close first.
- Whether to change the behavior in F1.
