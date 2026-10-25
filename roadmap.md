# Roadmap

Precedence: roadmap rules win on scope and what may be worked on. feature-workflow.md wins on procedure. The product AGENTS.md wins on safety boundaries.

**Current phase:** Phase 1 (active). Phase 3 stays closed (approved 2026-10-24, within documented limits).
**Current task:** None active. Registration submission and decisions verified; next Phase 1 slice awaiting approval.
**Approved:** in-place adoption and candidate removal. **Not approved:** publishing.

This roadmap organizes existing work. It does not authorize implementation. Each slice and each phase advancement requires user approval.

## Working rules (read before every task)

1. Work only on the slice the user approved. Do not create or add slices on your own. If a slice is too big, propose a split at the gate and wait for approval.
2. Each slice is judged only against its exit criteria below. When all of them pass, the slice is closed.
3. Report pass or fail per criterion. After a verification, report pass or fail per criterion. Propose a roadmap update or follow-up only when the workflow’s Report step asks for it, and never start it.
4. Anything extra you notice goes under **Observations** at the end of your report, or in the Backlog section. Do not act on it.
5. A real failure in a listed criterion is logged as a defect against that slice. Fix it only if the user approves.
6. Time-box each slice. If it is not closed by the limit the user sets, stop and ask whether the slice is too big or something is truly failing.
7. Skipped live checks are never counted as passed.
8. Never run migrations, touch a real database, or print credentials.
9. Existing unrelated issues are reported, not fixed.

## Status

| Phase | Status |
| --- | --- |
| ✓ 0 Baseline | Closed with documented limits (2026-10-15); evidence: `evidence/phase-0-task-2-api-2026-10-15/README.md`, `evidence/phase-0-task-3-mobile-checks-2026-10-15/README.md`, `evidence/known-failures.md` |
| 1 Core enforcement and settlement lifecycle | **Active (current phase).** Implemented, live verification incomplete |
| 2 Vendor mobile experience | Implementation present with passing focused checks and some profile device evidence; remaining live/device checks are explicitly deferred in retained reports |
| ✓ 3 Administration and reporting | **Closed with documented limits (2026-10-24)**; evidence: `evidence/phase-3-dashboard-current/phase-3-closure-review.md`, `evidence/phase-3-dashboard-current/phase-3-reconciliation.json` |
| 4 Operational readiness | Core live backup/retry/restart/decrypt/restore drill passed; full operational-readiness closure not established |

Phase order note: on 2026-10-17 the user deferred Phase 1 and 2 verification and moved focus to Phase 3. That did not complete Phases 1 or 2.

## ✓ Phase 0 — Baseline (closed) — evidence: `evidence/phase-0-task-2-api-2026-10-15/README.md`, `evidence/phase-0-task-3-mobile-checks-2026-10-15/README.md`, `evidence/known-failures.md`

Closed as narrowed. Unmet items moved to Phase 1: schema/config reconciliation, live API startup with one client connection, one role/story check.

- API: build passes; tests 387 pass, 1 fail (`AuditServiceTests.cs:501`).
- Mobile: auth test harness and loading-button semantics corrected. Known failures: duplicate-recovery test, dashboard test stalls the full suite, 4 analyzer info diagnostics.
- Web: build passes outside the sandbox. Node tests: **unconfirmed**. Inside the Codex sandbox both fail with `spawn EPERM`, so run web builds and tests outside it.
- Details: `evidence/known-failures.md`.

## Phase 1 — Core enforcement and settlement lifecycle (ACTIVE)

Goal: prove registration-to-resolution across the API and each relevant client.

Carried over from Phase 0: schema/config reconciliation, live API startup with one client connection, one role/story check. Phase 3 already used the isolated local API/web host and disposable database, so reuse that setup and do not redo it unless it is broken.

Phase 1 closes when every exit criterion below passes, or when the user approves closing it with documented limits, as was done for Phases 0 and 3.

Exit criteria:
- ✓ Registration submission and administrator decisions persist — verified for the approved isolated local stories; real email/push delivery remains separate; evidence: `evidence/phase-1-registration-submission-current/registration-submission-verification.md`, `evidence/phase-1-registration-decisions-current/README.md`.
- Enforcer login, vendor lookup, warning/ticket issuance and evidence work — unchecked: full live issuance/photo story remains unverified; evidence: `evidence/warning-issuance/README.md`, `evidence/ticket-issuance/README.md`.
- Vendors see only their own records and can submit eligible settlement proof — unchecked: cash-fine proof/ownership passed, but Records and other settlement live coverage remain incomplete; evidence: `evidence/vendor-receipt-error-recovery/README.md`, `evidence/blood-donation-settlement/README.md`, `evidence/community-service-settlement/README.md`.
- Staff settlement/status actions show correctly in mobile and web — unchecked: JPEG cash-fine-to-Paid passed; blood-donation/community-service live status paths remain; evidence: `evidence/cash-fine-lifecycle/run-2/README.md`, `evidence/blood-donation-settlement/README.md`, `evidence/community-service-settlement/README.md`.
- Invalid input, unauthorized access and paging behave correctly — unchecked: registration and focused Records paging pass, but full lifecycle/live paging coverage remains incomplete; evidence: `evidence/phase-1-registration-decisions-current/README.md`, `evidence/phase-1-records-pagination/README.md`.
- Complete stories pass against the real local API and each relevant client — unchecked: registration/cash-fine stories pass within scope; remaining first-login/issuance/settlement stories prevent whole-criterion completion; evidence: `evidence/vendor-first-login/README.md`, `evidence/ticket-issuance/README.md`, `evidence/community-service-settlement/README.md`.

Finished approved slices/checks (checkmarks apply only to the stated coverage):
- ✓ Registration submission → Pending admin review — live Public-vendor wizard, persistence, document reads, validation/role checks and cleanup; `evidence/phase-1-registration-submission-current/registration-submission-verification.md`.
- ✓ Registration approval/rejection — both admin roles, Pending/NeedsInformation, exact account creation, rejection reasons, stale/repeated decisions, fresh-login persistence and cleanup; `evidence/phase-1-registration-decisions-current/README.md`.
- ✓ Inspection-filter fixture reconciliation — focused automated checks; live/device coverage remains separate; `evidence/phase-1-inspection-filter-fixture/README.md`.
- ✓ OTP navigation timer cleanup — automated fixture correction; `evidence/phase-1-otp-navigation-cleanup/README.md`.
- ✓ Role-access/account-switch fixture reconciliation — focused automated checks; `evidence/phase-1-role-access-account-switch/README.md`.
- ✓ Vendor Records pagination — focused automated checks; live/device coverage remains separate; `evidence/phase-1-records-pagination/README.md`.
- ✓ Warning-detail layout — automated 280px/400px checks at 2× text; `evidence/phase-1-warning-detail/README.md`.
- ✓ Ticket-card narrow-layout fix — automated 280px/400px checks at 2× text; `evidence/phase-1-ticket-card-layout/README.md`.

Remaining work: first vendor login/OTP; enforcer login/vendor lookup and warning/ticket issuance; remaining vendor Records/proof and cash-fine, blood-donation and community-service settlement verification; cross-client persistence and role checks. Reuse passed receipt/settlement stories rather than repeating them. Document deletion after approval remains deferred by user instruction.

### Enforcer slices (all implemented; none marked verified)

Verify each against its core criteria only. A single run may satisfy both the slice and the matching Phase 1 story.

| Slice | Core criteria | Evidence |
| --- | --- | --- |
| 1 Card summaries and ticket loading | Full `Ord No. {number}, Series of {series}` labels; private vendor without a stall; initial/refresh/paging errors recoverable | `evidence/enforcer-summary-slice-1/README.md` |
| 2 Inspection and ticket filters | Inspections default All, tickets default Pending; All omits the filter; search survives selection; paging resets; stale responses do not replace current results | `evidence/enforcer-filters-slice-2/README.md` |
| 3A Ticket detail and preview paper | Correct control number (issued, PENDING in preview, none on warnings); full ordinance labels; prices only for cash fines; receipt select/save/reopen | `evidence/enforcer-ticket-paper-slice-3a/redesign-report.md` |
| 3B New-inspection form controls | Full ordinance labels; selection/search/restrictions; photo capture and removal; draft preserved on preview Back | `evidence/enforcer-form-controls-slice-3b/README.md` |

## Phase 2 — Vendor mobile experience (not active; do not start while Phase 1 is open unless the user approves)

Goal: replace known vendor gaps and complete notification integration.

Exit criteria:
- Vendor notifications use the vendor-owned list/read contract; read states stay independent — unchecked: automated contract/isolation checks pass, live persistence/independent read-state story remains; evidence: `evidence/phase-2-vendor-notifications/README.md`.
- Device registration and notification delivery/opening are verified — unchecked: real registration/push delivery/opening remain unverified; evidence: `evidence/mobile-device-registration/README.md`, `evidence/mobile-notification-opening/README.md`.
- Delivery failure does not undo committed inspection data — unchecked: six service-ordering/rollback tests pass, but real transaction durability under delivery failure remains unverified; evidence: `evidence/inspection-notification-boundary/README.md`.
- Vendor profile supports the approved account actions — unchecked: read/edit/save/restore device checks passed, but complete password/QR/native-action coverage remains; evidence: `evidence/vendor-profile-v2529-readonly/README.md`, `evidence/mobile-pending-tests-recovery/phase-reconciliation.md`.
- Vendor role restrictions pass on a device — unchecked: automated role/account-switch checks pass, full real-device role/ownership story remains; evidence: `evidence/phase-1-role-access-account-switch/README.md`.
- ✓ No blank placeholder remains in approved vendor flows — Dashboard, Records, Notifications and Profile use their real feature pages; this source/UI criterion does not establish delivery or full device verification; evidence: `marikina-market-mobile/lib/core/router/app_routes.dart`, `evidence/phase-2-vendor-notifications/README.md`, `evidence/phase-1-role-access-account-switch/README.md`, `evidence/vendor-profile-v2529-readonly/README.md`.

Already finished coverage (implementation/automated results are not described as missing features):
- ✓ Vendor inbox contract/UI and account-isolation automated checks — 21 notification cases plus one isolation case passed; live read-state durability/ownership remains separate; evidence: `evidence/phase-2-vendor-notifications/25-notification-regressions.log`, `evidence/phase-2-vendor-notifications/27-account-isolation.log`.
- ✓ Device-registration/session/logout focused contract checks — 10 registration, 12 session and 16 logout cases passed across runs; real Firebase/server binding remains separate; evidence: `evidence/mobile-device-registration/README.md`.
- ✓ Notification-opening automated checks — eight cases passed; actual push/OS lifecycle remains separate; evidence: `evidence/mobile-notification-opening/06-focused.log`.
- ✓ Inspection delivery-failure service-boundary checks — six cases passed; real transaction/delivery-failure durability remains separate; evidence: `evidence/inspection-notification-boundary/focused-tests.log`.
- ✓ Vendor profile edit/save/restore on V2529 — temporary City save/reopen and restoration of all ten fields passed; remaining native photo/password/QR actions are not covered by this result; evidence: `evidence/vendor-profile-v2529-readonly/edit-restore-results.json`.

### Enforcer slices (implemented; none marked verified)

| Slice | Core criteria | Evidence |
| --- | --- | --- |
| 4 Enforcer notification parity | Vendor-style header/cards/filter; All/Unread counts and paging; mark-all with partial failure and retry; correct role-specific navigation and ownership; persistence after relogin | `evidence/enforcer-notification-slice-4/README.md` |
| 5 Profile camera overlap | Camera button overlaps portrait with an unclipped tap target; select/cancel/remove/error states; photo change persists | `evidence/profile-camera-slice-5/README.md` |

### Batched device pass (proposed, needs user approval)

Native-device edge cases (camera permission/cancel/error, narrow and enlarged-text layouts, push delivery and opening) are checked once on a device for all Phase 1 and 2 slices, not repeated per slice.

Remaining work: inbox persistence, ownership and mark-all; real device registration and push delivery; profile, account and QR actions with loading/empty/error/role coverage.

## ✓ Phase 3 — Administration and reporting (closed 2026-10-24) — evidence: `evidence/phase-3-dashboard-current/phase-3-closure-review.md`, `evidence/phase-3-dashboard-current/phase-3-reconciliation.json`

Closed by user approval for the approved stories: ✓ accounts, ✓ vendor administration and compliance, ✓ ordinances, ✓ market sections, ✓ dashboard, ✓ yearly analytics with year filter, ✓ reports/exports and ✓ audit read paths — criterion evidence and individual run references: `evidence/phase-3-dashboard-current/phase-3-closure-review.md`, `evidence/phase-3-dashboard-current/phase-3-reconciliation.json`.

Exit criteria (achieved within the approved closure limits):
- ✓ Accounts, vendor administration, ordinances and market sections enforce the agreed role matrix — evidence: `evidence/phase-3-dashboard-current/phase-3-closure-review.md` (criterion matrix and linked account/vendor/ordinance/section live runs).
- ✓ Dashboard/analytics totals reconcile with independently derived local results — evidence: `evidence/phase-3-dashboard-current/phase-3-closure-review.md` (independent SQL stages, dashboard and analytics live runs).
- ✓ Reports preserve snapshots and handle Manila date boundaries correctly — evidence: `evidence/phase-3-dashboard-current/phase-3-closure-review.md` (persisted snapshots and independent period checks).
- ✓ Report export and audit filtering/detail pass through the web UI — evidence: `evidence/phase-3-dashboard-current/phase-3-closure-review.md` (CSV/PDF parity and audit browser/SQL checks).
- ✓ Relevant denial, stale-action, empty and failure cases pass — evidence: `evidence/phase-3-dashboard-current/phase-3-closure-review.md` (criterion-specific conflict, denial and recovery results; documented exclusions retained).

Evidence summary:
- API build passed; 576 tests passed, 2 opt-in skips, 0 failures. Web build passed; 113 tests passed, 0 failures.
- Live checks passed on the disposable local database: independent SQL totals, persistence, role restrictions, Manila date boundaries, report snapshots/exports, recovery cases.
- Source reconciliation: 7 integrated slices, 223 artifact hash comparisons, 1,953 files checked.
- Full detail: `evidence/phase-3-dashboard-current/phase-3-closure-review.md` and `phase-3-reconciliation.json`.

Retained limits:
- Isolated local execution does not prove deployment startup, real email/push/storage delivery, native-device behavior or outage resilience.
- Not exercised live: first-record empty ordinance/section registries, analytics ranking beyond ten, nonzero historical risk bands.
- Analytics summary counts one severity case while raw evidence records four. Unresolved.
- Hardcoded configuration notes (active/draft counts, backup completion) are an unrelated UI issue and are not backup-readiness evidence.

## Phase 4 — Operational readiness (open)

Goal: demonstrate operation and recovery of the existing system.

Exit criteria:
- ✓ Backup scheduling, retries, encrypted download and retention verified — within the recorded single-instance/local drill scope; evidence: `evidence/phase-4-full-e2e/result.json`, `evidence/phase-4-live-database-checks/cloud-result.json`, `evidence/backup-retention-verification/README.md`.
- User-operated restore drill succeeds in a disposable environment — unchecked: automated decrypt/restore passed, user-operated procedure not established; evidence: `evidence/phase-4-full-e2e/result.json`.
- External-service outages and restarts preserve agreed behavior — unchecked: backup failure/retry/restart passed, other required outage/permission cases remain; evidence: `evidence/phase-4-full-e2e/README.md`, `evidence/phase-4-full-e2e/result.json`.
- Required regression checks and E2E stories pass — unchecked: recent API/web checks pass, mobile/live coverage remains incomplete; evidence: `evidence/phase-1-registration-submission-current/registration-submission-verification.md`, `evidence/mobile-pending-tests-recovery/README.md`.
- Setup, deployment prerequisites, recovery steps and limits are documented and reproducible — unchecked: isolated-host evidence does not establish normal deployment/recovery readiness; evidence: `evidence/phase-3-dashboard-current/phase-3-closure-review.md`, `evidence/phase-4-full-e2e/README.md`.

✓ Live backup/browser/retry/restart and automated decrypt/restore drill completed successfully — one executed TRX test passed with zero failures; the downloaded backup restored into a disposable database with 35 migrations, and owned provider/database artifacts were cleaned up; evidence: `evidence/phase-4-full-e2e/result.json`, `evidence/phase-4-full-e2e/full-e2e.trx`. Its README's "running" line is superseded by these final artifacts. This does not establish a user-operated restore or every operational-readiness criterion.

## Live E2E environment

- Use only the identified disposable database `marikina_market_e2e` (35 migrations, four roles, reference data).
- As of 2026-10-23 it holds six users, six role assignments, two vendor profiles, one audit log and one backup schedule. Existing records and credentials were later reused in approved Phase 3 verification.
- Details: `evidence/local-e2e-database/`.

## Migration exception (approved)

A local monorepo candidate was prepared with original repositories, Git history and uncommitted work preserved. Intended remote: `https://github.com/gvillaluz/marikina-market-ticketing.git` (no HEAD advertised; **nothing pushed**). See `docs/environment-setup.md`, `docs/environment-verification.md`, `docs/cutover-verification.md`. This does not advance any product phase.

## Backlog (parked, not approved)

Items here are not work. Review once at the end of each phase and promote only with user approval.

- Analytics severity count mismatch (1 vs 4).
- Hardcoded configuration notes UI issue.
- Phase 4 backup README status text.
- Existing package/build warnings.

## Deferred work

New capabilities, architecture changes, infrastructure expansion and additional agents need a separately approved roadmap change.
