# Phase 4 — outage and restart stories (slices 2 and 3), closed 2026-11-17

The roadmap line: "User-operated restore drill and required external-service outage/restart stories pass in a disposable environment; automated restore alone is insufficient."

**The user ticked this line on 2026-11-17 with the limits below.** The restore-drill half is in [phase-4-restore-drill.md](phase-4-restore-drill.md) (slice 1). This note holds the outage half (slice 2) and the restart half (slice 3). No application code, schema or package changed.

Plan: `spec-restore-drill-outage.md` in the project root. Evidence (local, not committed): `evidence/phase-4-restore-drill/outage-expected-results.md` (expectations written before each run, with what was observed), `outage-results.md` (slice 2 summary) and `slice-3-results.md`.

## Method

The agent cannot work with the internet off, so each outage was made for one service at a time by pointing one setting at a non-routable address through an environment variable on the disposable API only (`BackBlazeB2__Endpoint` for storage, `Email__SmtpHost` for mail; `Backups__TimeoutMinutes=1` to shorten the wait). No User Secrets or appsettings file was edited. The database was the disposable `marikina_market_e2e`.

## Slice 2 — outage stories

| Story | Result | Evidence |
| --- | --- | --- |
| 2a Back Up Now, storage down | The backup waits, then ends **Failed** at its time limit (1 minute set for the test; default 15), message "Backup was cancelled or exceeded its time limit." No temp files left. After storage returned, the pending cleanup finished by itself and the next backup completed. A first run with the real internet off for under the limit showed the backup simply waiting and then completing. | Live, database rows |
| 2b Web login and password reset, mail down | Fail safely: no sign-in, nothing sent, no crash. The message is generic ("login failed" / an error), because the API log shows an unhandled connection timeout, not the clear message the mobile login is built to give. After mail returned, login and reset emails arrived. | Live, user-confirmed |
| 2c Push down | Closed by the user as **not live-tested**: a real Firebase outage cannot be made here. Code reading: a failed push cannot stop a ticket status change or overdue marking. Real delivery works in dev and deployed: user-reported. | Code reading and user report |
| 2d Ticket submit with photos, storage down | The phone showed "Submission could not be confirmed. Check this person's history before trying again." The server saved nothing: 48 tickets and 16 evidence rows before and after. Recovery half not run, because a successful photo upload is locked 365 days. | Live (failure half) |

## Slice 3 — restart stories

| Story | Result | Evidence |
| --- | --- | --- |
| 3a Real kill during a backup | With storage unreachable, a backup was running (unfinished row, one temp file); the API process was hard-killed. On restart the row became Failed and finalized ("Backup was interrupted before completion."), the temp file was removed, and the next backup completed. | Live |
| 3b Local PostgreSQL stopped about 30 seconds (user-operated) | The backup stopped ("Backup 8 stopped after losing database ownership."), the row was finalized by itself, the API kept running with no restart, the history page loaded afterwards, and the next backup completed. | Live |
| 3c Restart with a retry pending | Not rerun. The 2026-10-17 result stays as background (older schema, 35 migrations). | Background only |

## Limits accepted by the user

- A real whole-internet-off run was not done; outages were made one service at a time.
- The phone's mobile-login message (503 "Unable to send your sign-in code") was not tested.
- Push outage not live-tested (2c); photo-upload recovery not run (2d); restart with a pending retry not rerun on the current schema (3c).
- In 3a, removal of a leftover storage object could not be shown, because nothing was uploaded while storage was unreachable.
- The API's temp folder in this test setup is `evidence/local-e2e-database/runtime/api-startup/process-temp/MarikinaMarket-backups`, because the startup wrapper redirects TEMP.
- Real email was used; the Head Admin test account's email was pointed at the user's inbox during runs and restored each time.

## Findings, not fixed

1. Web login and password reset give a generic message when email is down.
2. A push call has no timeout in our code; the effect was not established.
3. From slice 1 (F1): starting the API on a restored copy deletes the restored backup's own storage object.

## Cleanup done

Test API and website stopped; Head Admin email restored to the original; PostgreSQL left running; the user's own dev servers were stopped at the user's request and not restarted by the agent.
