# Marikina Market Ticketing

One product repository containing independently built applications:

| Directory | Application |
| --- | --- |
| marikina-market-api | ASP.NET API and .NET tests |
| marikina-market-web | React and TypeScript web application |
| marikina-market-mobile | Flutter mobile application |

Read AGENTS.md, feature-workflow.md, roadmap.md and the affected application's AGENTS.md before changing code. Deferred mobile work is in deferred-enforcer-slices.md.

Start with the [environment setup guide](docs/environment-setup.md) for prerequisites, PostgreSQL, ASP.NET Core User Secrets, Firebase, SMTP, B2 storage, backups, and web/mobile local configuration. The [verification report](docs/environment-verification.md) distinguishes automated checks from services that still need manual setup.

## Build and test

Use each application's existing installed toolchain and lockfiles. No root package manager or monorepo framework is required. Run these commands from the indicated application directory:

- API: dotnet build MarikinaMarket.slnx --no-restore; dotnet test MarikinaMarket.slnx --no-restore. Backup tests require a disposable BACKUP_TEST_TEMP_ROOT. Live-test environment variables must remain unset unless a disposable environment has been approved.
- Web: npm run build. In PowerShell, enumerate tests with $tests = @(rg --files src -g '*.test.mjs'), then node --test @tests.
- Mobile: flutter analyze --no-pub; flutter test --no-pub. Format changed Dart files with dart format.

Keep credentials in the existing user-secrets/environment mechanisms. Do not commit database dumps, local credential files, migration safeguards or build outputs. Never run migrations or use operational data for verification.

## Migration status

This is a local migration candidate, not the replacement workspace. Sanitized application histories and current working changes are imported. Original repositories remain intact. No push or workspace replacement has been performed. See MIGRATION_STATUS.md and docs/environment-verification.md for verification status.
