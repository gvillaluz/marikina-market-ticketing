# Monorepo adoption status

- Permanent workspace: `C:\Users\berna\Documents\MarikinaMarketTicketing`.
- User approved applying the verified candidate in place and removing the candidate copies after verification.
- One root Git repository on `main`; the three application folders use this root. Existing application architectures and dependencies are preserved.
- Candidate base: `b4ee26c49cae05958610e18265b295ef4a33a78b`. Sanitized application histories, namespaced archived refs and all 75 source commit mappings are retained.
- Intended origin: https://github.com/gvillaluz/marikina-market-ticketing.git. Nothing has been pushed; publishing is a separate approval.
- Original source files, original Git repositories and prior workspace documents are preserved under ignored `.workspace-backups/monorepo-cutover-20261021`. Recovery files can contain old credentials and must remain local.
- Existing API secret settings were preserved, and the previous tracked database connection was imported securely into the existing User Secrets store. The database was not accessed.
- Existing web `.env` and native Firebase files remain local and ignored. Mobile client keys and the previous API URL are preserved in ignored `marikina-market-mobile/firebase.local.json`; run Flutter with `--dart-define-from-file=firebase.local.json`.
- Root workflow, ignore rules, instructions and setup documentation apply to the monorepo. Historical local evidence and root Codex settings remain ignored.
- API routes, requests, responses, errors and schemas are unchanged. No package was added and no migration ran.
- Prior mobile failures/native prerequisites and live verification limits remain documented; this migration does not complete a product phase.

See [docs/cutover-verification.md](docs/cutover-verification.md) for checks at the original location and [docs/environment-setup.md](docs/environment-setup.md) for setup on other computers.
