# Roadmap

Current phase: **Phase 3 — Verify administration and reporting**.
Current task: **Approved local monorepo migration candidate — preparation in progress**.
Workspace replacement and publishing are not yet approved.

This roadmap organizes existing work; it does not authorize implementation. Each slice and phase advancement requires user approval. No Phase 0 implementation was performed when creating these workflow files.

## Progress update — 2026-10-21

- Phase 0: closed with documented limitations.
- Phase 1: implemented/unverified; remaining live lifecycle checks are outstanding.
- Phase 2: implementation present; notification delivery and device verification remain incomplete.
- Phase 3: current focus; administration/reporting exit criteria are not yet established.
- Phase 4: not started as a verification phase; backup configuration was corrected,
  but successful automatic backup and restore verification remain outstanding.

### Recent approved slices

1. Enforcer card summaries and ticket loading:
   implemented with focused automated evidence; live/device verification pending.
   Evidence: evidence/enforcer-summary-slice-1/README.md

2. Enforcer inspection and ticket filters:
   implemented; API build passed, 531 tests passed and 2 skipped.
   Focused mobile tests: 22 passed.
   Full Flutter suite stalled after 119 passes and 2 known failures;
   four existing analyzer diagnostics remain.
   Live/device verification pending.
   Evidence: evidence/enforcer-filters-slice-2/README.md

### Deferred product work

Slices 3–5 are saved in deferred-enforcer-slices.md:
- Ticket paper and new-inspection form.
- Enforcer notification parity.
- Profile camera button overlap.

### Approved migration exception

Prepare and verify a local monorepo candidate while preserving the original
repositories, Git history, and uncommitted work.

Intended remote:
https://github.com/gvillaluz/marikina-market-ticketing.git

Inventory has started; the candidate has not yet been created.
Remote verification remains pending.
This migration does not establish completion or advancement of a product phase.

## Evidence and initial state

Baseline: read-only inspection of the three working trees on 2026-10-15. All three contain uncommitted changes. Current builds/tests and live E2E were not run during that inspection.

- **Complete**: approved acceptance criteria and required automated and E2E checks passed, with recorded evidence.
- **Implemented/unverified**: execution paths exist, but required evidence is missing.
- **Partial**: required behavior or integration is absent.
- **Missing**: required user-facing behavior is absent.
- **Blocked**: a named prerequisite prevents a required check or implementation.

| Area                            | Initial status and evidence                                                                                                                                                                                 |
| ------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Authentication and access       | Implemented/unverified: API auth services and client flows; logout/audit and Flutter login/refresh/role tests exist.                                                                                        |
| Registration and administration | Implemented/unverified: API vendor services and web submission/review/action screens; registration/version tests exist.                                                                                     |
| Inspections and tickets         | Implemented/unverified: API services/repositories, mobile enforcement flows, web inspection/ticket screens and targeted tests exist.                                                                        |
| Vendor records and settlement   | Implemented/unverified: vendor routes, mobile list/detail/proof submission, staff/web settlement views and targeted tests exist.                                                                            |
| Vendor notifications            | Partial: API ownership/read-state/paging logic and tests exist; mobile notification data source uses enforcer routes and the vendor tab is blank. `vendor-notifications.md` records an unapplied migration. |
| Vendor mobile profile           | Missing: vendor profile route renders a blank `VendorPlaceholderPage`.                                                                                                                                      |
| Reports, audit and analytics    | Implemented/unverified: API and web paths exist; reports/audit tests do not establish live totals or browser behavior.                                                                                      |
| Backups                         | Implemented/unverified: API scheduler/service/repository and web screens exist. Documentation records historical fake-service checks, not real dump/storage/restore evidence.                               |
| Verification                    | API CI exists; Node web tests and Flutter tests exist. Historical Flutter logs contain failures/timeouts. No checked-in browser/device E2E suite was found.                                                 |

No product capability is initially marked complete. File or endpoint existence and historical results are insufficient.

## Current progression decision (2026-10-17)

The user explicitly deferred further verification and approved moving to Phase 3. This advances the work focus; it does not establish completion of Phase 1 or Phase 2 exit criteria. The initial-state table above remains a historical baseline, not the current implementation inventory.

- **Phase 1: implemented/unverified.** Recorded slices cover registration submission/decisions, vendor first login, warning/ticket issuance, vendor Records/proof handling, and cash-fine, blood-donation and community-service settlement. Focused automated and limited device evidence exists; full live stories, role/failure coverage and some automated checks remain incomplete. See the corresponding folders under `evidence/`, especially `vendor-first-login/README.md` for the latest first-login limits.
- **Phase 2: implementation present; verification incomplete.** Source/evidence review found vendor-owned notification list/read integration, device registration, push opening, post-commit inspection delivery handling, vendor profile/account/QR actions and active vendor routes replacing placeholders. See `evidence/phase-2-vendor-notifications/`, `evidence/mobile-device-registration/`, `evidence/mobile-notification-opening/`, `evidence/inspection-notification-boundary/`, `evidence/vendor-profile-v2529-readonly/` and `marikina-market-mobile/evidence/vendor-profile-cached-ui/`. Live delivery, schema/deployment readiness and remaining role/native-device cases are not established.
- **Phase 3: current focus.** Existing administration/reporting paths remain implemented/unverified until individually reviewed. No Phase 3 implementation slice is approved by this progression decision. Further application changes still require a bounded plan and approval. The user's instruction to skip further verification remains in effect unless changed.

## Phase 0 — Establish a reproducible baseline incrementally

Goal: Report prerequisites first, then establish evidence through small separately approved tasks.

Known missing or unconfirmed prerequisites to report before implementation:

- Current API build/test, web build/Node test, and Flutter analyze/test results are unconfirmed. Historical Flutter failures need fresh evidence.
- SDK versions and existing dependency availability for application verification have not been established by this documentation task.
- A disposable local database, safe seed data, and user-provisioned schema readiness are unconfirmed. Vendor notification schema application is documented as pending; backup setup documentation must be reconciled with current migrations.
- Local API/client configuration and device/emulator connectivity are unconfirmed. API startup references a Firebase credential file; usable local credentials are unconfirmed and must never be printed.
- Safe email/push/storage test configuration and real delivery evidence are unconfirmed.
- Repeatable role/story checks and browser/device E2E evidence are missing from this baseline.
- Custom agents live in `.codex/agents`. api_developer spawn is verified; the other three are unverified. code_reviewer's read-only rule is instructional only.

Suggested task order, each requiring its own small plan and approval:

1. Inventory one repository's SDK/dependency/command prerequisites without installing anything.
2. Run that repository's available checks, record results and propose one bounded fix only if needed.
3. Repeat independently for the other repositories; do not bundle unrelated fixes.
4. Reconcile one schema or configuration prerequisite and provide user-operated setup steps; never run migrations or touch the real database.
5. Verify one local API startup and one relevant client connection once prerequisites are supplied.
6. Write and execute one core role/story check, then propose the next small check.

Exit criteria:

- Prerequisites are recorded as available, missing or unconfirmed, with owner and next action.
- Required commands and current results are reproducible for all three repositories, tied to revision and working-tree state.
- Historical failures are reproduced or shown resolved; outstanding failures are explicit.
- Schema, safe data and local configuration prerequisites for the first core story are confirmed.
- One minimal local API/client story is verified; a full E2E environment is not required in a single task.
- Remaining story coverage is explicit and the first Phase 1 slice is approved.

### Phase 0 closure note (2026-10-15)

Phase 0 closed as narrowed. Not every exit criterion was met; the unmet ones moved to Phase 1.

- API: build passes; tests 387 pass / 1 fail (AuditServiceTests.cs:501). Run happened outside the approved gate, so treated as baseline with that caveat.
- Mobile: inventory recorded. Auth test harness and loading-button semantics corrected (evidence/phase-0-task-3-\*). Known failures: duplicate-recovery test, dashboard test stalls the full suite, 4 analyzer info diagnostics.
- Web: build [exit 0 outside sandbox, per build-outside-sandbox-result.json]. Node tests [fill from tests-outside-sandbox-result.json, or write "unconfirmed"]. Inside the Codex sandbox both fail with spawn EPERM, so run web builds and tests outside it.
- Known failures: evidence/known-failures.md
- Moved to Phase 1: schema/config reconciliation (task 4), live API startup plus one client connection (task 5), one role/story check (task 6).

## Phase 1 — Verify the core enforcement and settlement lifecycle

Goal: Prove the existing registration-to-resolution workflow across relevant clients.

Exit criteria:

- Registration submission and administrator decisions persist correctly.
- Enforcer login, vendor lookup, warning/ticket issuance and evidence work.
- Vendors see only their records and submit eligible settlement proof.
- Staff settlement/status actions appear correctly in mobile and web.
- Invalid input, unauthorized access, pagination and failure recovery pass.
- Complete stories are verified with the real local API and each relevant client.

## Phase 2 — Finish the vendor mobile experience

Goal: Replace known vendor gaps and complete notification integration.

Exit criteria:

- Vendor notifications consume the vendor-owned list/read contract; read states remain independent.
- Device registration and notification delivery/opening are verified.
- Delivery failure does not undo committed inspection data.
- Vendor profile supports the approved account actions.
- Vendor role restrictions and loading/empty/error states pass on a device.
- No blank placeholder remains in the approved vendor flows.

## Phase 3 — Verify administration and reporting

Goal: Make existing management and reporting functions dependable.

Exit criteria:

- Accounts, vendor administration, ordinances and market sections enforce the agreed role matrix.
- Dashboard/analytics totals reconcile with independently derived local results.
- Reports preserve snapshots and handle Manila date boundaries correctly.
- Report export and audit filtering/detail pass through the web UI.
- Relevant denial, stale-action, empty and failure cases pass.

## Phase 4 — Verify operational readiness

Goal: Demonstrate operation and recovery of the existing system.

Exit criteria:

- Backup scheduling, retries, encrypted download and retention are verified.
- A user-operated restore drill succeeds in a disposable environment.
- External-service outages and restarts preserve agreed behavior.
- Required regression checks and E2E stories pass.
- Setup, deployment prerequisites, recovery steps and limitations are reproducible and documented.

## Deferred work

New capabilities, architecture changes, infrastructure expansion and additional agents require a separately approved roadmap change. Existing unrelated issues are reported without fixes.
