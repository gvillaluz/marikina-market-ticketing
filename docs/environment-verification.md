# Environment and migration verification

The migration is a local candidate only. No push, workspace replacement, application startup, database access or migration execution is authorized by these checks.

## Expected results

- Each imported source ref is sanitized and retained under a distinct archive namespace; application main histories are ancestors of monorepo main.
- Every removed original configuration literal is absent from reachable imported history, current candidate files and the fresh local clone.
- API launch profiles contain no JWT default. Required non-sensitive appsettings, Firebase project metadata and client environment names remain available.
- Safe examples are tracked; actual local credential/native configuration files are ignored.
- Original HEADs, refs, staged/unstaged work and source file hashes remain unchanged by migration.
- A fresh local clone receives documentation, examples, current application source and sanitized history without nested Git repositories or gitlinks.
- Placeholder configuration can be read and development environment overrides can be applied without reading this computer's real User Secrets or connecting to services.
- Repository build/test outcomes are recorded separately from live integration readiness and pre-existing failures.

## Results

Verification is in progress. Final results and limitations will be recorded here before this candidate is presented for publication review.

## Manual verification required

The new machine/user must supply authorized PostgreSQL credentials and a disposable provisioned schema; rotate the historical database/JWT values if still valid; provision Firebase Admin/native/web configuration and verify IAM/APNs/device/browser push; configure and test SMTP and B2 access; verify firewall/certificate/native toolchain readiness; and test manual/automatic backups and a user-operated restore. No automated source scan can prove provider-side rotation or successful live delivery.

Recovery bundles and original histories remain outside this candidate and must never be published. Locally available refs were imported; remote-only branches of the old repositories are not claimed as inventoried.
