# Migration and environment verification — 2026-10-21

Status: the local monorepo candidate is prepared for review. Automated migration integrity and credential-removal checks pass. Full application and live environment verification remains incomplete because of the mobile failures and prerequisites below. Nothing has been published or substituted for the original workspace.

## What was preserved

The original API, web and mobile repositories remain separate and untouched. Their currently available branches and remote-tracking refs were imported into the candidate under `archive/api`, `archive/web` and `archive/mobile`. Each imported application HEAD is reachable from monorepo `main`; there are no nested Git repositories or Git submodules. Remote-only branches absent from the local originals were not fetched or inventoried.

The originals each gained one commit between initial preparation and this resumed task. Those three commits were also imported after sanitization, without changing application contents. Current original heads:

| Application | Original HEAD | Commits mapped |
| --- | --- | --- |
| API | `7994ed7b9bc708fe2ed3cd67625913f5b9aadae8` | 23 |
| Web | `06c7c1c1582c4ada8904f1611b2c3d9220ac30ee` | 48 |
| Mobile | `5e58e7d279d2e64443786bde223ed91ea306b89f` | 4 |

All 75 commit mappings were checked for author, committer, timestamps, commit messages and parent relationships. The three symbolic `origin/HEAD` aliases are verified through their target `origin/main` refs; fast-export does not create separate archived symbolic aliases. Sanitized IDs differ as recorded in [history-migration.json](history-migration.json). Both initial and resumed local recovery bundles passed `git bundle verify`.

All 1,902 source-file manifest entries still match the initial working-file snapshot (including preserved staged, unstaged and untracked content). Original HEADs, refs and status stayed unchanged during this resumed task. Candidate differences are limited to credential sanitization, safe configuration examples, web/mobile environment configuration and migration infrastructure. The nested API CI workflow moved to root with its API working directory set. No API contract, schema, dependency declaration or application styling change was made.

Original local recovery material can contain old credentials and is outside the candidate. Historical product evidence folders referenced by the roadmap remain in the original workspace; they were not blindly copied into the publishable candidate because they include local build/configuration artifacts. The migration does not establish any product-phase completion.

## Credential-removal evidence

The [redacted inventory](sanitization-inventory.json) identifies 10 historical file/key locations. Seven distinct non-placeholder literal values were checked in memory without printing or persisting those values. Historical and working files were checked for those removed values and common Firebase-key, private-key and GitHub-token patterns. All imported refs passed, as did six local-secret ignore checks and tracked-local-configuration checks. `git fsck --full --no-reflogs` passed.

The scan is pattern-based and covers locally imported refs. It does not prove the absence of unknown credential formats, inspect provider accounts, revoke credentials, or remove old values from existing original clones/bundles. Rotate any still-valid historical database password and JWT signing default. Firebase public-client keys require owner review of restrictions and usage; they are distinct from a server service-account private key. See the [setup guide](environment-setup.md) for every replacement location and provisioning step.

Machine-readable preservation and credential-check results are in [migration-verification](migration-verification/). Raw local logs and recovery bundles remain under the original workspace's `.monorepo-migration/`; recovery bundles must stay local. Selected command output is preserved in [command-output.txt](migration-verification/command-output.txt).

## Application checks from the fresh local clone

The initial `fresh-clone` was cloned locally with `--no-local --no-hardlinks`, at `70888a3c6e469dabddf718553bffc0fc3fb9a535`. Existing dependency caches were used; no dependency declarations or lockfiles were upgraded. Later candidate changes add source-history ancestry, documentation and preserved public example configuration. Final clone file comparisons separately establish application-content parity with the tested clone; no application check is claimed to have run on an untested revision solely because its Git history exists.

| Check | Actual result | Limits |
| --- | --- | --- |
| API restore/build | Passed; build has 0 errors and 3 existing warnings | Two migration-type naming warnings and obsolete Firebase `Message.Token`; no startup/database check |
| API tests | 531 passed, 2 skipped, 0 failed | `ReportsLiveVerificationTests` and `FullBackupE2ETests` were skipped; disposable backup temp path used and live-test variables cleared |
| Web offline restore/build | Passed | Existing large-bundle warning; no browser/live API story |
| All existing web Node tests | 109 passed, 0 failed | Automated tests, not external service delivery |
| Isolated User Secrets setup probe | Passed | 15 placeholder keys imported into a task-specific isolated store; tracked defaults and environment override checked; real developer store untouched |
| Vite environment probe | 2 checks passed | Default local proxy and explicit proxy override; no real API connection |
| Flutter offline dependency setup | Dependency resolution succeeded; command exit 1 at native plugin symlink setup | Windows Developer Mode/symlink privilege absent; not a complete native setup |
| Flutter analysis | 4 existing info diagnostics | Deprecated `withOpacity`, type parameter `Type`, empty constructor body, and undeclared direct `flutter_native_splash` import |
| Focused Flutter filters/summary tests | 21 passed, 1 failed | Ticket-card layout overflows at 280px |
| Resumed Flutter environment probe | 1 passed, exit 0 | Actual API/Firebase Dart defines loaded from placeholder-only JSON; no network/service access |
| Resumed full Flutter suite | 119 passed, 2 failures observed, then stalled | Stopped the task's own test process at the known dashboard stall; suite did not finish and later tests may not have run |
| Original-source ticket-card regression | Failed with the same overflow | Confirms the focused failure exists before migration; left unchanged |

The two full-suite failures were `auth_ui_test.dart` duplicate recovery (connection error/timeout) and `features/profile/profile_form_test.dart` empty optional middle name/duplicate saves (`EditProfileError` instead of `EditProfileLoading`). Both and the dashboard stall were recorded before this migration in the original workspace evidence. The separate focused run and original-source reproduction identify the ticket-card overflow; the stalled full run did not reach every remaining test. No tests were removed or weakened and no unrelated product bugs were fixed.

The first placeholder setup-probe command failed in Windows batch argument handling. Repeating it with `--dart-define-from-file` passed. The setup guide already uses this file-based approach. Flutter checks required access to the existing SDK cache outside the sandbox.

## Reproducible commands

Run API checks from `marikina-market-api`: `dotnet build MarikinaMarket.slnx --no-restore`, then `dotnet test MarikinaMarket.slnx --no-restore`. Set `BACKUP_TEST_TEMP_ROOT` to a disposable test directory, with live-test variables unset.

Run web checks from `marikina-market-web`: `npm run build`, then in PowerShell `$tests = @(rg --files src -g '*.test.mjs')` and `node --test @tests`.

Run mobile checks from `marikina-market-mobile`: `flutter analyze --no-pub`, `flutter test --no-pub --timeout 30s`, and focused `flutter test --no-pub test/enforcer_filters_test.dart test/ticket_summary_loading_test.dart --timeout 30s`. The complete suite currently needs the existing failures/stall addressed in a separately approved task.

The local migration tooling is deliberately outside the publishable candidate. From the original workspace, `node .monorepo-migration/verify-resumed-candidate.cjs` verifies preservation/history, and `node .monorepo-migration/verify-secrets.cjs .monorepo-migration/candidate-v2` verifies imported refs and ignore rules without printing removed values.

## Manual setup and remaining verification

1. Review [environment-setup.md](environment-setup.md), the safe examples, commit mappings and redacted inventory.
2. On a new machine, install the documented SDKs and enable authorized native symlink support, then restore dependencies without upgrading lockfiles. Native Android/iOS builds remain unverified.
3. Configure your own authorized development User Secrets, Firebase Admin/native/client configuration, SMTP and B2 access. Verify effective provider permissions and any required credential rotation with the owner.
4. Have the user provision a disposable local database and its schema, plus synthetic role accounts. No migrations or database operations were executed by this migration task.
5. Start the API and relevant client against that disposable environment. Check login, persistence, role ownership, refresh, and an important failure path. Verify SMTP, push opening/delivery, storage, scheduled backups and user-operated restore separately. These live stories have not been run.
6. Review the concrete candidate before separately approving workspace replacement or publication. The previously successful remote check advertised no HEAD; no push has been performed.

API contract and schema: unchanged. Application implementation was carried over; automated evidence and live E2E evidence remain separate. This report does not mark a product feature or phase complete.
