# Original-workspace monorepo cutover — 2026-10-21

The user approved applying the verified monorepo to the original workspace and deleting the temporary candidate copies. The permanent Git root is now `C:\Users\berna\Documents\MarikinaMarketTicketing`. The application directories and installed dependency caches remain in their existing locations. No GitHub push was performed.

## Implementation and recovery

The candidate base is `b4ee26c49cae05958610e18265b295ef4a33a78b`. Its Git objects were copied independently, without an alternates file or dependency on a candidate directory. Its sanitized history and archived application refs are preserved. Every application resolves `git rev-parse --show-toplevel` to the permanent workspace root; no active application contains nested `.git` metadata or a Git submodule.

Before application files changed, all 1,902 original source-file manifest entries and the existing root documents were backed up and checked against SHA-256 hashes. Original Git metadata was retained with the original tracked trees under:

```text
.workspace-backups/monorepo-cutover-20261021/
├── originals/marikina-market-api/
├── originals/marikina-market-web/
├── originals/marikina-market-mobile/
├── workspace-files/
└── cutover-plan.json
```

These are local recovery repositories, not active application repositories or monorepo contents. Original backup HEADs, refs, clean working-tree status, file hashes and `git fsck` were verified. Recovery files can contain original credentials and are ignored by Git. The candidate copies (`candidate`, `candidate-v2`, `candidate-pre-validation`, `fresh-clone`, `review-clone`) are removed only after in-place integrity and credential checks pass. Import tooling, old recovery bundles and raw check logs remain locally under ignored `.monorepo-migration/`.

All 1,921 candidate tracked files were checked in place. The 1,902 application files match the tested candidate exactly; the six existing root documentation/ignore files differ only for the approved adoption status, local artifact exclusions and corrected setup instructions. No application behavior was added or unrelated bug fixed. No dependencies, API contracts or schemas changed.

Existing API User Secrets were preserved. The original tracked database connection was imported into that same development secret store using stdin without printing its value or contacting the database. The original tracked launch-profile JWT defaults are removed; the already-configured User Secrets JWT setting remains. The web `.env` and native Firebase configuration remain local and ignored. The previous mobile API URL and public client keys are also preserved in ignored `marikina-market-mobile/firebase.local.json` for use with `--dart-define-from-file=firebase.local.json`.

The first PowerShell stdin import failed because of a UTF-8 BOM, before updating the store. A BOM-free Node stdin import then passed, and existing secret keys were compared in memory to confirm preservation. The setup guide now uses a BOM-safe import command. Actual credentials are excluded from this report.

## Automated checks at the original paths

| Check | Result |
| --- | --- |
| Original backup file/history verification | Passed: 1,902 source entries; original refs and HEADs preserved |
| Candidate-to-original application file comparison | Passed: application contents match exactly |
| Root Git, archived refs, ancestry and `git fsck` | Passed; no object alternates or active nested Git repositories |
| Credential-removal check across imported refs and publishable files | Passed for the seven known removed literal values and common token/private-key/client-key patterns; nine local-path ignore checks passed |
| API `dotnet build MarikinaMarket.slnx --no-restore` | Passed: 0 errors, 7 warnings |
| API `dotnet test MarikinaMarket.slnx --no-restore --no-build` | Passed: 531 passed, 2 skipped, 0 failed |
| Web `npm run build` | Passed; existing large-bundle warning |
| Web existing `node --test` suite | Passed: 109 tests, 0 failures |
| Flutter `flutter analyze --no-pub` | Exit 1: the same four pre-existing info diagnostics |
| Flutter placeholder API/Firebase configuration probe | Passed: 1 test, exit 0 |
| Flutter filter/summary focused tests | 21 passed, 1 pre-existing ticket-card overflow failure |

API tests used a task-specific disposable backup temp directory, with live-test variables removed. Two live report/backup verification tests were skipped. No migrations, database access, dev servers, email/push deliveries, storage operations or restores were run. Existing dependencies were used without restore/install or upgrades during cutover.

The full Flutter suite was not repeated after cutover: the unchanged application source had already stalled in the candidate run after 119 passes and two failures. Its known duplicate-recovery and profile-save failures, dashboard stall and native symlink prerequisite remain documented in the [historical verification report](environment-verification.md). The four analyzer diagnostics are deprecated `withOpacity`, type parameter `Type`, an empty constructor body and a direct `flutter_native_splash` import without a direct dependency declaration. The focused 280px ticket-card overflow reproduced in the original source before cutover and remains unchanged.

The API build warnings include the existing migration-type naming and obsolete Firebase `Message.Token` warnings, plus NU1902/NU1903 advisories for the existing `System.Security.Cryptography.Pkcs` 10.0.0 dependency in both projects. The historical candidate restore had disabled NuGet audit; this in-place build used existing original restore assets and surfaced those advisory warnings. No package version or lockfile changed and no unrelated dependency fix was attempted.

Raw inspectable command output, test results and machine-readable cutover checks are retained locally under `.monorepo-migration/cutover-checks/` and `.monorepo-migration/cutover-verification.json`. The credential check is pattern-based; provider revocation and unknown credential formats are not established by a passing scan. Original histories remain in private recovery copies.

## Files and areas applied

- Root `.git`: combined sanitized history, `main`, archived refs and the intended GitHub origin.
- Root `AGENTS.md` and `feature-workflow.md`: monorepo instructions and the actual hyphenated mobile directory name, preserving the product workflow.
- Root `.github/workflows/dotnet.yml`: API workflow relocated with its working directory set; the inactive nested workflow was retained in recovery.
- Root `.gitignore`: local credentials, recovery directories, root historical `evidence/` and machine-local `.codex/` stay private. These local directories are retained in place.
- Root `README.md`, `MIGRATION_STATUS.md`, `roadmap.md`: original-location adoption status and documentation links; product Phase 3 remains the focus with existing verification limits.
- `docs/environment-setup.md`, `docs/environment-verification.md`, `docs/history-migration.json`, `docs/sanitization-inventory.json`, `docs/migration-verification/`: setup, historical evidence and redacted provenance carried over. The User Secrets import instructions now avoid Windows BOM failures.
- API `appsettings.json` and launch settings: sanitized tracked connection/JWT configuration, with existing development configuration retained through User Secrets. `user-secrets.example.json` remains a safe template.
- Web `.env.example`, `.gitignore` and `vite.config.ts`: safe public configuration example, local env exclusions and configurable development proxy. The original `.env` remains ignored and local.
- Mobile network client, Firebase options and safe native examples: the verified API/Firebase Dart defines and placeholder-only examples. Original native configuration remains ignored and local; `firebase.local.json` preserves this computer's existing client configuration.
- All other application source, tests and dependency declarations: identical to the verified candidate.

## Manual follow-up

1. Reopen the original workspace in the editor and confirm it shows one root Git repository. Run `git status` from the root or any application directory.
2. Read [environment-setup.md](environment-setup.md) before starting services. Existing local credentials are retained; rotate previously exposed database/JWT values where still applicable with the service owner. No rotation or live operation was performed here.
3. Start the API and relevant client only against an explicitly approved disposable database. User-provisioned schema/accounts and external-service permissions are still needed for live E2E checks.
4. For mobile, run `flutter run --dart-define-from-file=firebase.local.json` from `marikina-market-mobile` when a device session is authorized. Native symlink/device prerequisites and the pre-existing failures remain unresolved.
5. Keep the local recovery backup. Publishing the monorepo requires separate approval; no commit or test result here establishes live product readiness or phase completion.

API contract: routes, requests, responses and error cases unchanged. Schema: unchanged; no migrations executed. Implementation adoption, automated checks and live E2E evidence remain separate.
