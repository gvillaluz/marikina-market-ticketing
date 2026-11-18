# Plan: Docker hosting — server with `pg_dump`, daily recommended-actions job

Written 2026-11-19. **Status: planned, not approved.** Nothing is built. Each slice below needs your approval before it
starts, and every install, purchase or Azure change is asked for first.

## Why

| Problem seen | Where |
| --- | --- |
| The demo server stopped on Azure on 2026-11-19 because Azure runs it differently from this computer (fixed ports and a development certificate). Fixed in PR #92, but only found after deploying. | `evidence/server-ports-fix-live/` |
| The demo's Backups page cannot work: the Azure server has no `pg_dump`, the program the backup function runs. | `evidence/phase-4-criterion-4-demo-update/README.md` |
| The recommended-actions model only runs when started by hand, and needs an exact Python 3.12 setup that this computer does not have by default. Its daily Azure job (model plan step 5) was never planned. | `docs/recommended-actions-model-plan.md` |
| Setup on Azure is partly manual and not recorded in the project. | setup guide section 11 |

**What Docker changes, in plain words:** the project gets "recipe" files that describe exactly what each part needs to
run. Docker turns a recipe into a **package**. The same package runs on this computer and on Azure, so differences
show up here first. Nothing is set up by hand on Azure beyond settings.

**What does not change:** the app's code structure (server layers, website, phone app), the website's hosting on Static
Web Apps (slice W), the database on Azure, the backup file format and the restore steps proven in Phase 4.

## Target picture

| Part | Today | After |
| --- | --- | --- |
| Website | Static Web Apps | Unchanged |
| Server | App Service (Linux), files deployed from `publish-api` | Same App Service (if Azure allows the switch; see D4) runs the **server package**: the server plus `pg_dump` of the database's version |
| Recommended-actions model | Started by hand on a computer | **Model package** (Python 3.12, its packages, the connector, the model) run by Azure every day at 4:00 AM Manila as an Azure Container Apps scheduled job |
| Package store | — | One private store for both packages (see D2) |
| Database | Azure Database for PostgreSQL | Unchanged |

Two packages, not one: the server is small and updated often; the model package is large (likely 2–3 GB, mostly the
`torch` package and the 0.46 GB model) and rarely changes. Kept apart, a server update never moves the model, and a
model failure can never stop the server.

## Facts checked (2026-11-19)

| Fact | Source |
| --- | --- |
| The demo App Service runs on Linux and starts the server on port 8080 | Azure's start-up log, 2026-11-18 |
| App Service can pull a private Azure Container Registry package with a managed identity (CLI, not portal) | [Microsoft: configure a custom container](https://learn.microsoft.com/en-us/azure/app-service/configure-custom-container) |
| Container Apps jobs support a schedule (cron), evaluated in UTC. 4:00 AM Manila = `0 20 * * *` UTC | [Microsoft: Container Apps jobs](https://learn.microsoft.com/en-us/azure/container-apps/jobs) |
| Container Apps free monthly grant: 180,000 vCPU-seconds and 360,000 GiB-seconds per subscription | [Container Apps pricing](https://azure.microsoft.com/en-us/pricing/details/container-apps/) |
| Azure Container Registry Basic includes 10 GB storage | [Container Registry pricing](https://azure.microsoft.com/en-us/pricing/details/container-registry/) |
| Docker Hub free plan: 1 private repository, 100 pulls per hour | [Docker pricing](https://www.docker.com/pricing/) |
| Docker Desktop is free for personal use, education and small businesses (under 250 employees and US$10 million revenue) | [Docker Desktop license](https://docs.docker.com/subscription/desktop-license/) |
| One model run: about 1,275 MB memory at peak; first run 174 s, later 23.6 s | model plan, step 1 result |
| The server reads the Firebase key from the file `Keys/…json` (`Program.cs`) | code |

**Not settled by the documentation (checked in slice D0):** whether the existing App Service can switch from files to a
package without a new address; whether the demo's App Service plan tier runs packages well; the exact monthly price of
the registry (the pricing page did not show it; use Azure's pricing calculator).

**Estimate, to confirm after real runs:** a daily model run of about 3 minutes at 1 vCPU and 2 GiB is about 5,400
vCPU-seconds and 10,800 GiB-seconds a month, inside the free grant.

## Decisions needed

| # | Question | Options | Recommendation |
| --- | --- | --- | --- |
| D1 | When, compared with the evaluation (line 4, slice 3)? | (a) Docker first, evaluation after; (b) evaluation first on today's demo, Docker after | **(b)**: the demo works now; Docker changes how the demo is hosted, so doing it during the evaluation risks downtime. If evaluators must use the Backups page, do D0–D2 first. |
| D2 | Where to store the packages | (a) Azure Container Registry Basic (private, 10 GB, pulls with managed identity, monthly cost); (b) Docker Hub free (1 private repository, so both packages share it as tags; Azure pulls with a stored username and token) | **(a)**: both packages private, no stored password; check the monthly price in the calculator first |
| D3 | The Firebase key (a secret) | (a) the server reads the key's content from one setting everywhere (small code change; on this computer it moves into User Secrets; on Azure into an App Service setting; the key file is no longer used); (b) the key file is copied into the private package (no code change, but the secret travels with every copy of the package); (c) Azure file share mounted into the server (no code change; extra Azure storage to set up) | **(a)**: no secret inside packages, one way of loading it (learned rule 1) |
| D4 | The App Service | (a) switch the existing one to the package, if Azure allows it (same address); (b) create a new one (new address: website rebuilt, CORS setting and phone app changed) | **(a)** if D0 shows it is offered; otherwise decide then |
| D5 | Install Docker Desktop on this computer | Needs Windows' Linux support (WSL2) | Needed for every slice except D0; asked before installing |
| D6 | `pg_dump` version in the server package | Must be the database's major version or newer | Set from D0's answer |
| D7 | Roadmap | (a) a Phase 4 line (added now as ⏸, waiting); (b) outside Phase 4, after it closes | **(a)**, as ⏸ until you approve; you decide whether it must pass before Phase 4 closes |

## Slices

### D0 — Facts from Azure (you, read-only, about 15 minutes)

Nothing changes. You send me:

1. The database's PostgreSQL version: `marikina-market-db` → Overview.
2. The App Service plan's pricing tier: `marikina-market-api` → Overview → App Service plan.
3. Whether `marikina-market-api` → **Deployment Center** offers a container registry as a source (a screenshot is enough).
4. The registry's monthly price for your region, from Azure's pricing calculator (if D2 = a).

### D1 — Server package, on this computer

**User story:** the server and `pg_dump` are described in the project and run on this computer exactly as they will on
Azure, and the Backups page makes a backup that restores.

| Part | Files |
| --- | --- |
| Recipe: build the server, then a small runtime package with the .NET server and PostgreSQL's own `pg_dump` (version from D6); listens on 8080; no secrets inside | `marikina-market-api/Dockerfile` (new), `marikina-market-api/.dockerignore` (new) |
| Firebase key (if D3 = a): read from one setting instead of the file | `Program.cs`, one small new file in `Presentation/` if needed for a test, tests in `MarikinaMarket.Tests` |
| Settings list and guide: new section "Docker" (build, run locally) | `docs/environment-setup.md`, `user-secrets-list.md` |

Installs (each asked first): Docker Desktop; the base packages Docker downloads from Microsoft and PostgreSQL.

**Acceptance criteria**

1. One command builds the server package from the repository.
2. The package starts outside Development mode on port 8080 with no development certificate.
3. On the throwaway database: Back Up Now completes, Download works, and the file opens with `tools/recovery/` and
   lists the database's tables with `pg_restore --list`.
4. No secret is inside the package (checked by listing its files and settings).
5. Running the server the usual way on this computer (`dotnet run`, live-check scripts) is unchanged.

**Checks:** full server tests; new tests fail first; the package built and run locally against `marikina_market_e2e`
(start, `/api/does-not-exist`, CORS preflight, sign-in, backup and restore listing). The backup is uploaded to the test
system's Backups storage (asked first; check whether that storage locks files).

### D2 — Demo server runs the package (you on Azure, me writing the steps)

1. Create the package store (D2), push the server package.
2. Switch `marikina-market-api` to the package (D4), let it pull with its managed identity.
3. Settings stay; add the Firebase setting (D3) and remove `Backups__PgDumpPath` if present.

**Acceptance:** the demo check list W1–W8 passes again; on the demo, Back Up Now completes and the downloaded file opens
and lists the tables. **Way back:** until D2 passes, the old way (`publish-api`, Deploy to Web App) stays in the guide,
so the demo can be restored to files in minutes. Do it when nobody is using the demo.

### D3 — Model package and the daily job

**User story:** recommended actions refresh every morning on the demo without anyone starting the model.

| Part | Files |
| --- | --- |
| Recipe: Python 3.12, the exact package versions recorded in model plan step 1 plus the database package, the connector; the model folder (git-ignored) copied in from this computer at build time | `description-model/Dockerfile` (new), `description-model/.dockerignore` (new) |
| Guide: build, push, create the Container Apps job (schedule `0 20 * * *`, 1 vCPU, 2 GiB, database settings as secrets) | `docs/environment-setup.md` |

**Acceptance:** the connector's 7 tests pass inside the package; one run against `marikina_market_e2e` gives the same
results as a run by hand on the same data; on Azure, a manual start of the job fills the demo's Recommended Actions
page ("Last updated" shows the run); the next scheduled run happens at 4:00 AM Manila; warnings and tickets unchanged.

### D4 — Closing

Closing note in `docs/closed-work/`, guide read-through, roadmap tick proposal.

## Not in this plan

App code structure changes; the website's hosting; automatic builds on GitHub (can be a later step); database changes;
the phone app; restore automation (restore stays the recovery guide's steps).

## Risks

| Risk | Handling |
| --- | --- |
| The demo is down while switching | Do D2 when nobody uses the demo; the old deploy way stays documented until D2 passes |
| Azure does not allow switching the existing App Service | Found in D0; then D4 decides between a new App Service (new address) and staying with files plus `pg_dump` stored once (option A of 2026-11-19) |
| Monthly cost of the registry | Price checked in D0 before anything is created |
| Free App Service plan limits (60 CPU minutes a day; Microsoft does not support it for production) | Tier checked in D0; noted for the evaluation |
| Large model package (2–3 GB) is slow to upload | One-time; only re-uploaded when the model or connector changes |
| Backups from the demo land in the shared Backups storage | Check its file-lock setting before turning on any automatic schedule |

## Meanwhile

- Until D2 is done, the demo's Backups page does not work. Back up from your computer before each update
  (`pg_dump` command in `evidence/phase-4-criterion-4-demo-update/README.md`) and keep the demo's automatic backup schedule off.
- The demo's Recommended Actions page is probably empty since the Market Streets update deleted the old results. If the
  evaluators should see it before D3, the connector can be run by hand once against the demo (asked separately).
