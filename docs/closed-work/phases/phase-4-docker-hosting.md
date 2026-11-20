# Phase 4 — Docker hosting (server package with `pg_dump`, daily recommendations job), 2026-11-20

The roadmap line: "Docker hosting: the server package with `pg_dump` and the daily recommended-actions job on Azure."

**Status: closed 2026-11-20.** All three build slices passed their acceptance checks, including the job's first run by its own schedule. Plan: `spec-docker-hosting.md` (decisions D1–D7, Azure facts, results per slice). How to update the demo now: [deployment guide](../../../deployment-guide.md). Evidence (local, not in Git): `evidence/docker-server-package-live/`, `evidence/docker-d2-demo/`, `evidence/docker-d3-model/`.

## Why

The demo's Backups page could not work on Azure (no `pg_dump` there), the recommendations model only ran when started by hand on a computer with an exact Python setup, and Azure hosting differences were only found after deploying.

## What was built

| Slice | What | Pull request |
| --- | --- | --- |
| D1 | **Server package**: `marikina-market-api/Dockerfile` (.NET 10 server plus PostgreSQL 18's `pg_dump`, runs as a non-administrator user, no secret inside). The Firebase key is read from one setting (`Firebase:ServiceAccountJson`) instead of a key file (`Presentation/FirebaseKey.cs`, with tests) | #95 |
| D2 | **The demo runs the package**: new App Service `marikina-market-server` on the existing B1 plan, fetching the package from the registry `marikinamarketregistry` with its own identity (no password). The existing App Service could not be switched to a package; the old `marikina-market-api` is kept as the way back until the owner deletes it. Website rebuilt with the new address | #97 |
| D3 | **Model package and daily job**: `description-model/Dockerfile` (Python 3.12.10, 59 pinned add-ons, the frozen model taken from the git-ignored folder at build time, never in Git); Azure Container Apps job `marikina-market-recommendations`, every day at 4:00 AM Manila, 1 CPU, 2 GB, retried once; run logs kept 30 days. Fix: the model's file-fingerprint record uses Windows `\`; the connector reads it as `/` so the model runs on Linux | #98, #99 |

## Checks

| Check | Result |
| --- | --- |
| D1 automated | Server 1004 passed, 2 skipped, 0 failed; Firebase key tests failed first, deliberate breaks caught; package 560 MB, `pg_dump` 18.7, no key or password inside |
| D1 live (package against the disposable `marikina_market_e2e`) | All checks passed: sign-in, records, **Back Up Now and the downloaded backup opening with the recovery tool** |
| D2 on Azure | Server checks passed (not-found page, Swagger off, website allowed, sign-in refresh refused without cookie, http to https); website check list W1–W8 passed; **demo Back Up Now completed and the downloaded backup opened: 30 tables, database 18.6, dumped by `pg_dump` 18.7** |
| D3 automated | Connector's 7 tests inside the package; the model's self-check passes in the package after the fix; six sample notes give the same answers in the package and on Windows; no secret inside |
| D3 comparison on `marikina_market_e2e` | A run by hand and a run from the package (with Azure's 1 CPU / 2 GB) gave the same result: 52 records, 26 findings, 3 cards, no difference; tickets and warnings unchanged |
| D3 on Azure | Started by hand 2026-11-19: "Run 1: 15 records, 0 with findings, 0 section recommendations."; the Recommended Actions page shows "Last updated". **First scheduled run 2026-11-20 4:00 AM Manila: Succeeded, "Run 2: 18 records, 1 with findings, 0 section recommendations."** |

No cards on the demo yet: a card needs at least 2 records with the same problem in the same street within 30 days, and the demo's records have only one finding. On the test database the same package made 3 cards.

## Limits and open items

1. **Two update steps not yet done as written:** pointing the server, and the daily job, at a new package label (marked "(not yet tried)" in the deployment guide).
2. **Always On is off** on the server (App Service default, as before): automatic backups and the overdue-ticket check only run while the server is awake.
3. **Phone apps built before 2026-11-19 still use the old server.** They must be rebuilt with the new address (deployment guide, step 5) before the old server `marikina-market-api` is deleted.
4. **The Azure account is a free trial:** it must be upgraded to pay-as-you-go before about 11 December 2026, or the whole demo is switched off.
5. The model prints a known warning about an "incorrect regex pattern" (seen since model plan step 1); results are unaffected so far.
6. Recovery of the database still needs commands (see line 4's note, limit 4).
