# Phase 4 — setup/recovery instructions and beneficiary evaluation (line 4), 2026-11-20

The roadmap line: "Setup/recovery instructions and beneficiary evaluation establish recording/retrieval time and practical usefulness. The faster-entry timing test was dropped 2026-11-10, so no time measurement exists yet. Separate implementation, automated checks, live E2E and acceptance evidence; record pre-existing failures separately."

**Status: closed 2026-11-20 with accepted limits (owner decision: option B, "close with an accepted limit").** The instructions exist and were followed to update the demo; the intended users' evaluation gives practical usefulness; **recording and retrieval times were not measured.** Plan: `spec-phase-4-criterion-4.md` (deleted 2026-11-20 after closing, last version in commit 1aa71ac). Evidence (local, not in Git): `evidence/phase-4-criterion-4-demo-update/`, `evidence/phase-4-criterion-4-slice-w-live/`, `evidence/phase-4-evaluation/`.

## What was written (implementation)

| Piece | Where | When |
| --- | --- | --- |
| Setup guide (new computer: prerequisites, database, secrets, storage, website, phone app, Docker) | [`environment-setup.md`](../../../environment-setup.md) | Slice 1, PR #86, 2026-11-18; moved to the project root 2026-11-19 (PR #99) |
| Recovery guide (before trouble; restore from a backup in 9 steps; what to do when email, storage, database, server or push is down) | [`recovery-guide.md`](../../../recovery-guide.md) | Slice 1, PR #86; moved to the root (PR #99) |
| Backup-opening tool and its tests | `tools/recovery/decrypt-mmbak.mjs`, `decrypt-mmbak.test.mjs` | Slice 1, PR #86 |
| Secret settings list (names only) | `user-secrets-list.md` | Slice 1, PR #86 |
| Website on its own address with "stay signed in" (needed to host the website separately) | server CORS and cookie, website server address | Slice W, PR #89 and #90, 2026-11-18 |
| Deployment guide, in plain language, including the phone app | [`deployment-guide.md`](../../../deployment-guide.md) | PR #115, 2026-11-20 (replaces the setup guide's former Azure section) |
| Deploy website button on GitHub | `.github/workflows/deploy-website.yml` | PR #103, 2026-11-19 |

The Docker hosting work (server package with `pg_dump`, daily recommendations job; see [Docker hosting](phase-4-docker-hosting.md)) was done between the demo update and this closure; the deployment guide describes the demo as it runs now.

## Automated checks

| Check | Result |
| --- | --- |
| Backup-opening tool's tests | 9 / 9 passed; with the integrity check removed on purpose, 2 failed as they should, then 9 / 9 again |
| Slice W, all checks on `main` 88c3c35 (with line 3's fixes) | Server 997 passed, 2 skipped, 0 failed, no new warnings; website build OK, 379 / 379; new tests failed first for the right reason; deliberate breaks caught |
| Secret search on the guides | No token, key, password or connection string |

## Live evidence

| Run | Result |
| --- | --- |
| Slice W on this computer (website and server on different addresses, real Chrome) | 14 / 14 passed; line 3's website checks re-run 6 / 6 |
| **Demo update by following the guide (slice 2, 2026-11-18/19)** | The owner backed up the demo, ran the two database change files written for it, deployed the server and the website. Two problems found and fixed on the way: the server stopped on Azure (fixed ports; PR #92) and the demo's Backups page could not work (no `pg_dump` on Azure; fixed by the Docker server package, 2026-11-19). Notes for the guide: `evidence/phase-4-criterion-4-demo-update/README.md` |
| **Demo check list** (`5-check-list.md`) | Website W1–W8 Pass (log in with the emailed code, refresh keeps you signed in, every page reloads, log out); S1 private window Pass (stayed signed in); phone P1–P3 Pass (log in, record a warning with its photo, find it on the website). Reported by the owner 2026-11-19 |

## Beneficiary evaluation (practical usefulness)

The project's **System Evaluation** Google Form (ISO/IEC 25010:2023; 9 quality groups, 40 statements rated 1 to 5, three open questions). Respondents used the demo website, the phone app and a video of the phone app; which of these each person used is not recorded. Summary without names: `evidence/phase-4-evaluation/results.md`.

- **29 answers**, 15–20 November 2026: **20 market enforcers, 4 administrators / Head Administrators, 5 IT experts**.
- **Overall 4.79 out of 5.** Of 1,160 ratings: 928 Strongly Agree, 227 Agree, 2 Moderately Agree, 3 Disagree, none lower.
- Groups: Functional Suitability 4.85, Maintainability 4.84, Flexibility 4.84, Safety 4.83, Security 4.80, Performance Efficiency 4.79, Interaction Capability 4.78, Compatibility 4.72, **Reliability 4.63** (lowest).
- Usefulness statements: helps decide inspections (analytics, recommendations) 4.86; helps recognise inspection errors 4.86; helps avoid mistakes 4.83; can replace the paper process 4.83; easy to learn 4.72.
- **Lowest statement: works when a part fails or the internet is down, 4.28** (all three Disagree ratings).
- Enforcers rated highest (most statements 4.90–5.00); IT experts were the most critical (4.20–4.80).
- Open answers. Liked: organised, traceable records (violator, stall, ordinance, officer and photos linked), accuracy, easy navigation, dashboard summaries, enforcer ranking. Problems: needs internet; the app on low-end phones; a new violator can be saved with only a name. Suggestions: **offline use** (most common, 4 answers), a lighter app for low-end phones, more readable text for older users, required-field labels, ordinance search or favourites, a review screen before submitting, documentation.

## Acceptance

The owner approved closing this line on 2026-11-20 with the limits below. The owner's read-through of the guides was asked for and not given.

## Accepted limits

1. **Recording and retrieval times were not measured.** The faster-entry timing test was dropped on 2026-11-10, and the planned stopwatch session (slice 3, step B: record a ticket, record a warning, find a saved record) was not run; the owner chose to close without it on 2026-11-20. The form's statement on speed (2.1, 4.83) is an opinion, not a measurement.
2. **Correctness with and without the app was not counted** (slice 3, step B's violation cards). Statements 4.4 and 9.2 are opinions.
3. **Which way each respondent tried the system** (demo website, phone app or video) is not recorded.
4. **Recovery needs commands.** The website's Restore button is switched off on purpose; restoring the system's own backups follows the recovery guide's commands (proven in the restore drill, 2026-11-17). Azure's own click-based database restore (7 days kept) is not in the guide and was not tested.
5. **Two deployment steps not yet done as written:** pointing the server, and the daily job, at a new package label (marked "(not yet tried)" in the deployment guide).

## Observations (not acted on)

- The users' main requests, **offline use** and **low-end phones**, match the lowest-rated statement (5.3) and are outside this line.
- Pre-existing, unchanged (from line 3): 22 server backup tests fail only when `BACKUP_TEST_TEMP_ROOT`, `TEMP` and `TMP` are not set to the same folder (test setup); 8 existing server build warnings; 24 phone files unformatted since the 2026-10-21 import.
