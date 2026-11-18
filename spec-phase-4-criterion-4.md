# Plan: Phase 4, line 4 — setup/recovery instructions and beneficiary evaluation

Written 2026-11-18 (recreated the same day after the project folder was cleaned). **Status: slice 1 built and merged (PR #86); your read-through is still pending. D1 = B (keep the website on Static Web Apps); its code change, slice W, was approved, built, checked automatically and live-checked on this computer 2026-11-18 (branch `feature/phase-4-criterion-4-slice-w`, pull request opened); its final proof is the demo update (slice 2).**

This file is committed with slice 1 (branch `feature/phase-4-criterion-4`), so it reaches every computer once that pull request is merged.

The roadmap line:

> ☐ Setup/recovery instructions and beneficiary evaluation establish recording/retrieval time and practical usefulness. The faster-entry timing test was dropped 2026-11-10, so no time measurement exists yet. Separate implementation, automated checks, live E2E and acceptance evidence; record pre-existing failures separately.

## What this line asks for, in plain words

1. **Instructions someone else could follow**: how to set the system up (on a computer and on Azure) and how to bring it back after something goes wrong.
2. **Proof from the real intended users** (market enforcers and office staff): how long it takes to record a ticket and to find a saved record, and whether the system is actually useful to them.

## Your decisions so far (2026-11-18)

| # | Question | Your answer |
| --- | --- | --- |
| 1 | Cover Azure in the guide? | Yes. |
| 2 | Move the backup-opening tool into the repository? | Yes. |
| 3 | Which usefulness form? | The form already used: the ISO/IEC 25010:2023 Google Form (see slice 3). |
| 4 | Faster than before? | No. The app should make enforcers **more correct** (used as a dictionary of ordinances and fines). |
| 5 | Target time? | None. |
| 6 | Where the evaluation runs | The demo. |
| 7 | Start now or wait for line 3? | Start the guide now; the demo update and evaluation wait for line 3. |
| 8 | D1: how the website reaches the server | **B**: keep the website on Static Web Apps, separate from the server (code change: slice W). |
| 9 | Slice 1 | Approved. |
| 10 | A list of the secret settings | Yes, names only, in a file at the project root (`user-secrets-list.md`, built). |
| 11 | Slice W | Approved: remove the server's website fallback; setting name `VITE_API_BASE_URL`. |
| 12 | Slice W installs | Yes: `dotnet restore` and `npm ci` in this work copy. |
| 13 | Move the CORS rule into its own file so a test can check it | Yes: `Presentation/WebsiteCors.cs`. |

## How you deploy today (as you described it, 2026-11-18)

| Part | How |
| --- | --- |
| Database (Azure Database for PostgreSQL) | I give you a SQL file with the new tables and changes; you run it with the PostgreSQL extension in VS Code. |
| Server (Azure App Service) | You update the `publish-api` folder and deploy it with the Azure App Service extension in VS Code. |
| Website (Azure Static Web Apps) | Build the website, then `npx @azure/static-web-apps-cli deploy ./marikina-market-web/dist --deployment-token <TOKEN> --env production`, after changing the server address the website calls. |

**The deployment token is a secret.** It was pasted into chat on 2026-11-18, so reset it in the Azure portal (your Static Web App → Overview → Manage deployment token → Reset) before the next deploy. The guide only shows `<TOKEN>`; the real token is never written into the project.

## Decision D1: how the website reaches the server (decided: B)

Checked in the code on `main` (2026-11-18): since PR #62 ("stay signed in after a page refresh", merged), the website **has no setting for the server address**. It always calls `/api` on its own address (`marikina-market-web/src/api/client.ts`, `baseURL: "/api"`), and the server also serves the website (`app.MapWebsiteFallback()` in `Program.cs`). PR #62 was built for one address on the App Service, because the "stay signed in" cookie only works reliably there. So the Static Web Apps deploy **does not work with the current code**.

| Option | What it means | Code change? |
| --- | --- | --- |
| A | Stop using Static Web Apps; copy the built website into `publish-api/wwwroot` and deploy once with the App Service extension. One address; "stay signed in" works everywhere. | None. |
| **B (chosen)** | Keep Static Web Apps on its own address, free plan. | Yes: slice W. |
| C | Keep Static Web Apps and link the App Service behind it, so both share one address. | None expected; needs the Static Web Apps paid (Standard) plan. |

Why B has a limit: the two Azure addresses count as different sites to browsers, so the sign-in cookie becomes a "third-party" cookie. Normal Chrome and Edge windows on Windows and Android are expected to keep it; **Safari (iPhone, iPad, Mac) and private/incognito windows are expected to block it**, so those users are signed out on refresh. The website is used by office staff (enforcers use the phone app, which does not use this cookie). Making B work everywhere would need both parts on one bought domain, which costs money and needs a paid App Service plan.

## What already existed (checked 2026-11-18)

| Item | State before slice 1 |
| --- | --- |
| `docs/environment-setup.md` | Developer guide; said the repository was "not published" and "no push has been performed"; section 7 listed website settings the website no longer uses. `README.md` pointed to an old folder (`C:\Users\berna\...`). |
| Restore steps and backup-opening tool | Proven by your restore drill on 2026-11-17, but only in `evidence/phase-4-restore-drill/`, which Git leaves out. |
| Outage results | `docs/closed-work/phases/phase-4-outage-and-restart-stories.md`, written as test results. |
| Finding F1 | Starting the system on a restored copy deletes the stored copy of the backup it came from. The downloaded file is not affected. Not fixed (your decision). |
| Azure steps | None written. No deployment script in the project (`.github/workflows/dotnet.yml` only builds and tests the server). |
| Time measurement / user evaluation | None measured; the Google Form evaluation exists (slice 3). |

A ticket cannot be saved without one paper photo and at least one supporting photo; a warning needs one paper photo (`TicketService.cs`).

## Order

1. **Slice 1** (the guide): **merged (PR #86)**; your read-through pending.
2. **Slice W** (website on its own address): **built and checked 2026-11-18** (results below). It changes sign-in code that line 3 checks, so the affected line 3 checks are re-run after it is merged.
3. **Slice 2** (after line 3 and slice W pass): you update the demo by following the Azure section. This updates the demo and tests the written steps.
4. **Slice 3**: evaluation gaps.
5. **Slice 4**: closing note and roadmap tick proposal.

Line 3's live checks stay on the local test database, as the project rules require. Only the evaluation uses the demo.

## Slice 1 — Setup, recovery and Azure guide (built 2026-11-18, uncommitted)

All in the work copy `C:\Users\Admin\orca\workspaces\marikina-market-ticketing\phase-4-criterion-4`:

| File | Change |
| --- | --- |
| `docs/recovery-guide.md` (new) | Before trouble; restore in 9 steps with the F1 warning; what to do when email, storage, database, server or push is down; a table showing where every part comes from. |
| `docs/environment-setup.md` | Clone lines no longer say "not published / no push"; section 7 matches the website (no server-address setting, no Firebase settings); the restore drill links to the recovery guide; new section 11 "Azure (demo hosting)": database, server (with the setting names and a note that your computer's User Secrets are never sent to Azure), website (marked not usable until slice W), phone app. |
| `README.md` | "Nothing has been pushed" and the old folder path removed; link to the recovery guide. |
| `tools/recovery/decrypt-mmbak.mjs`, `tools/recovery/decrypt-mmbak.test.mjs` (new) | Copied from `evidence/phase-4-restore-drill/` (the originals stay as drill evidence). Only comments changed: the run path, and the usage note now points to the guide's way of entering the key instead of typing it on a command line. |
| `user-secrets-list.md` (new, at your request) | The 15 server settings (name on your computer, name on Azure, what it is, where to get it), the Firebase key file, the 11 test-only settings, and steps for moving to another computer. Names only, no values. |

| Check | Result |
| --- | --- |
| Tool's 9 tests from `tools/recovery/` | 9 passed, 0 failed |
| Integrity check removed on purpose | 2 failed (changed byte in the data, changed byte in the tag), 7 passed; restored, 9 passed |
| Secret search on the changed files | No token, key, password or connection string (only the existing placeholder `Password=<YOUR_DATABASE_PASSWORD>`) |
| Read-through table | In the guide. Marked **not tested**: typing the key with `Read-Host`, restoring into an Azure database, switching an Azure server to a restored database |
| Your read-through | **Pending** (acceptance) |

Azure items marked *(confirm)*, to settle in slice 2: the exact `dotnet publish` command; whether the demo sets `Backups__PgDumpPath`. (The `Cors__AllowedOrigins__0` value and the `SWA_CLI_DEPLOYMENT_TOKEN` question were settled in slice W.)

Not in slice 1: any fix for F1, any app change, any change on Azure, any deploy, installing the EF tool.

## Slice W — Website on its own address with "stay signed in" (approved; built and checked 2026-11-18)

**Why:** you chose B. Today the website can only reach the server when both are at one address (PR #62).

**User story:** office staff open the website on its Static Web Apps address, sign in, refresh any page, and stay signed in (in Chrome and Edge).

| Part | Change | Files |
| --- | --- | --- |
| Server | The sign-in cookie may be sent from another site (`SameSite=None`; it stays `HttpOnly` and `Secure`). The server accepts requests **with the cookie** only from the addresses in `Cors:AllowedOrigins`. | `Presentation/Controllers/AuthController.cs`, `Program.cs`, tests in `MarikinaMarket.Tests` (`WebSessionCookieTests.cs` and a CORS test) |
| Server | The server stops serving the website, so the website fallback is removed, keeping no unused code (learned rule 1). | `Program.cs`, `Presentation/WebsiteFallback.cs` (deleted), `WebsiteFallbackTests.cs` (deleted) |
| Website | A build setting for the server address comes back (proposed name `VITE_API_BASE_URL`, the server's address without `/api`); empty in development, where the existing `/api` forwarding is used. Every request sends the cookie (`withCredentials`). | `src/api/client.ts`, `src/config/env.ts`, `.env.example`, Node tests |
| Website | A Static Web Apps settings file so refreshing a page like `/tickets` loads the website instead of "not found". | `marikina-market-web/staticwebapp.config.json` (new) |
| Docs | Sections 7 and 11.3 of the setup guide get the setting name and the steps. | `docs/environment-setup.md` |

No database change. The phone app is not affected. No new package.

**Acceptance criteria**

1. Built with `VITE_API_BASE_URL` set, every website request goes to that server address, with the cookie.
2. Signing in, then refreshing, keeps you signed in when the website and server are on different addresses (Chrome/Edge).
3. Signing out removes the cookie; refreshing afterwards shows the login page.
4. A request from an address **not** in `Cors:AllowedOrigins` gets no permission to read the server's answer (so another website cannot use someone's cookie to get a sign-in).
5. Refreshing on any website page on Static Web Apps loads that page.
6. Development (`npm run dev`) still works with the setting empty.

**Checks:** server build and all server tests; website build and all Node tests; each new test fails first and catches a deliberate break. A local live check runs the website and the server on different ports, but a computer's own ports do not behave exactly like two Azure addresses, so criterion 2 is only fully proven on the demo in slice 2 (Chrome; Safari expected to sign out on refresh, recorded as a known limit).

**Your answers:** remove the server's website fallback; setting name `VITE_API_BASE_URL`.

### Slice W — what was built (2026-11-18)

Branch `feature/phase-4-criterion-4-slice-w`, from `main` at 82c50a7.

| File | Change |
| --- | --- |
| `Presentation/WebsiteCors.cs` (new, approved) | The CORS rule moved out of `Program.cs` so a test can check it; only `Cors:AllowedOrigins` addresses may read answers and send the cookie (`AllowCredentials`). |
| `Program.cs` | Uses `WebsiteCors`; `MapWebsiteFallback()` removed. |
| `Presentation/Controllers/AuthController.cs` | Cookie `SameSite=None` (still `HttpOnly`, `Secure`, path `/api/auth`, ends when the browser closes). |
| `Presentation/WebsiteFallback.cs`, `WebsiteFallbackTests.cs` | Deleted. |
| `MarikinaMarket.Tests/WebsiteCorsTests.cs` (new), `WebSessionCookieTests.cs` | 6 new address tests; cookie tests expect `samesite=none`. |
| `src/config/env.ts`, `src/vite-env.d.ts` | `apiBaseUrl` = `VITE_API_BASE_URL` + `/api` (just `/api` when empty). The typing file was not in the plan's list; needed to declare the setting. |
| `src/api/client.ts`, `src/api/endpoints/authRefresh.api.ts` | Use `apiBaseUrl`; send the cookie (`withCredentials`). |
| `public/staticwebapp.config.json` (new) | Page refresh on Static Web Apps. In `public/`, not the web folder's root as planned, because Microsoft's `swa deploy` docs say the file goes in the deployed folder; the build copies it into `dist`. |
| `src/api/server-address.test.mjs` (new), `web-session-cookie.test.mjs` | 4 new website tests; the existing renewal test gets the setting. |
| `administration.test.mjs`, `market-street-options.test.mjs` | One stand-in line each for the settings file (their file loader cannot read Vite's build settings); their checks are unchanged. |
| `.env.example`, `docs/environment-setup.md` | The setting; sections 7, 11.2 (the exact `Cors__AllowedOrigins__0` value and a new step 4: the App Service's own CORS page must stay empty, because Microsoft says it overrides the server's rule) and 11.3 (build with the setting; known Safari limit; `SWA_CLI_DEPLOYMENT_TOKEN` confirmed from Microsoft's docs). |

| Check | Result |
| --- | --- |
| Server build | 0 errors, the same 8 old warnings |
| Server tests (test folder settings given) | 996 passed, 2 skipped, 0 failed (before: 1,000; 10 removed with the fallback, 6 added) |
| Website build | OK; `staticwebapp.config.json` is in `dist` |
| Website tests | 379 passed, 0 failed (before: 375) |
| New tests failed first, for the right reason | Yes (cookie still `strict`; no credentials permission; no server address) |
| Deliberate breaks caught | Every address allowed (4 tests failed); cookie not sent (1); setting ignored (1) |
| Live check on this computer (`evidence/phase-4-criterion-4-slice-w-live/`, off Git) | 14 of 14 passed on run 1: built website on `http://127.0.0.1:4173`, server on `http://localhost:5000` (different sites to Chrome), throwaway database, real Chrome. Criteria 1, 2, 3, 4 and 6 shown; throwaway account removed |
| Pre-existing | 22 backup tests fail only when `BACKUP_TEST_TEMP_ROOT`, `TEMP` and `TMP` are not set to the same folder (test setup, same on `main`) |

Not proven yet (slice 2, on the demo): criterion 5 (the Static Web Apps refresh file); HTTPS on both addresses (this computer's HTTPS development certificate is not trusted and was not changed); Safari and private windows (expected to sign out on refresh).

Risk: with `SameSite=None`, another website can make the browser call "log out" on our server, so the user's next refresh shows the login page. It cannot read anything or sign in as them.

## Slice 2 — Update the demo by following the guide (after line 3 and slice W pass)

- **You** deploy the version line 3 and slice W checked, step by step from the Azure section. I write the SQL files for the missing schema changes; I do not touch Azure or the hosted database.
- Every step that is wrong, missing or unclear is noted; I fix the guide afterwards.
- A short quick-check list I write and **you** run on the demo: sign in on the website, refresh and stay signed in (Chrome; and Safari, expected to sign out), sign in on the phone, record one warning, find it on the website. Recording it uploads one photo.
- Proves: the Azure steps work when followed, and the demo runs the checked version.

## Slice 3 — Beneficiary evaluation (after slice 2; only what is still missing)

### Step A: what your existing form covers (read 2026-11-18)

The "System Evaluation" Google Form: ISO/IEC 25010:2023, 9 groups (Functional Suitability, Performance Efficiency, Compatibility, Interaction Capability, Reliability, Security, Maintainability, Flexibility, Safety), 40 statements rated 1 to 5, three open questions, respondents grouped as Market Enforcer, Administrator / Head Administrator, or IT Expert. Respondents were invited to watch a video of the phone app and to use the web system.

| The roadmap line needs | Covered by the form? |
| --- | --- |
| Practical usefulness | **Yes**, as ratings: for example 1.3 (helps decide inspections), 4.2 (easy to learn), 4.4 and 9.2 (helps avoid mistakes), 8.4 (can replace the paper process), plus the three open questions. |
| Time to record a ticket | **No.** 2.1 asks whether speed feels acceptable; nothing is measured. |
| Time to find a saved record | **No.** |
| More correct with the app than on paper | **No.** 1.2 and 4.4 ask for opinions; no mistakes are counted. |
| Hands-on use of the phone app | **Unclear.** The form links a video, so some enforcers may have rated it without using it. |

Still needed: **the answers** (Google Forms: Responses → Download responses (.csv), or the Sheets icon), the date, and which app version people saw. The form asks for names (optional); only answers without names are used, and the file stays in `evidence/`, off Git.

### Step B: a short new session for the gaps only

Planned in detail and approved separately after step A. As now proposed:

- **Correctness:** each enforcer gets the same made-up violation cards (business, what was seen, the vendor's earlier offenses). Some done the old way on paper with their usual reference, some in the app. Before the session I write the correct answer for each card by hand from the ordinance list: right ordinance, right offense number (1st, 2nd, 3rd), right fine. We count mistakes each way.
- **Times** (stopwatch, no app change, no target):

  | Task | Who | Start | Stop |
  | --- | --- | --- | --- |
  | Record a ticket | Enforcer, phone | Taps New inspection | Sees the "submitted" message |
  | Record a warning | Enforcer, phone | Taps New inspection | Sees the "submitted" message |
  | Find a saved record | Office staff, website | On the Tickets page, given a control number or business name | Ticket page with photos open |

  Each task 3 times per person; the first is practice. Reported: middle, fastest and slowest time.
- **Usefulness:** the same Google Form, so new answers add to the old ones.
- Participant codes (P1, P2...) only. Sheets kept in `evidence/phase-4-evaluation/`, off Git.

### Demo conditions

- Practice businesses and vendors (with earlier offenses) go into the demo through a SQL file I write and **you** run. I never read or change the hosted database.
- Times include internet delay; a free Azure plan can be slow on the first visit after sitting idle. That is why there is no target.
- **Photos:** every ticket needs 2 photos and every warning 1. If the demo uses the same photo storage as the test system, they are locked for a year and cannot be deleted before then. You can check which storage the demo uses in its App Service settings.

## Slice 4 — Closing note

A note in `docs/closed-work/phases/phase-4-setup-and-evaluation.md`, listed in `docs/closed-work/README.md`, keeping apart: what was written, automated checks (the tool's tests), live evidence (the demo deploy and the evaluation), and your acceptance. Pre-existing failures are copied from line 3. Then I propose the roadmap tick; you decide.

## Still open

- Your read-through of slice 1 (acceptance).
- Slice W: your acceptance and merging its pull request; then re-run the affected line 3 sign-in checks.
- Before the next demo deploy: the App Service's own CORS page must be empty (setup guide 11.2, step 4).
- Reset the Static Web Apps deployment token before the next deploy.
- The form's answers (CSV), the date, and which version people saw (before slice 3).
- Whether the demo uses the same photo storage (before slice 2).
