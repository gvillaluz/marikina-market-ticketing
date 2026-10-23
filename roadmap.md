# Roadmap

Current phase: **Phase 3 — closed within documented limits; phase advancement pending approval**.
Current task: **Approved Phase 3 closure recorded; next slice awaiting approval**.
In-place adoption and candidate removal are approved. Publishing is not yet approved.

This roadmap organizes existing work; it does not authorize implementation. Each slice and phase advancement requires user approval. No Phase 0 implementation was performed when creating these workflow files.

## Approved Phase 3 closure — 2026-10-24

The user approved closing Phase 3 following the final evidence reconciliation.
Administration/reporting verification is complete for the approved stories within
the recorded isolated-host and coverage limits: accounts, vendor administration
and compliance, ordinances, market sections, dashboard, yearly analytics with a
year filter, reports/exports and audit read paths.

- Implementation: approved paths were reconciled with the retained live results;
  analytics remains yearly, with past-year selection and current-year-to-date behavior.
- Automated evidence: latest recorded API and web builds passed; API tests had
  576 passes, two explicit opt-in skips and zero failures; web tests had 113 passes
  and zero failures. Skipped live checks are not counted as successful E2E checks.
- Live evidence: independently derived SQL totals, persistence, role restrictions,
  Manila date boundaries, report snapshots/exports and relevant recovery cases
  passed in the approved stories against the disposable local database.
- Current-source reconciliation: seven integrated slices, 223 artifact hash
  comparisons and 1,953 source/workspace files were checked, plus ten matching
  selected account source files. The account story was reused with matching
  source evidence rather than rerun in the final dashboard task.

The criterion matrix, individual runs, source linkage and retained limitations are
in [the closure review](evidence/phase-3-dashboard-current/phase-3-closure-review.md)
and [the reconciliation receipt](evidence/phase-3-dashboard-current/phase-3-reconciliation.json).
These are historical verification records; their statements that the roadmap was
unchanged describe the verification task before this separately approved closure.

Closure retains these limits:

- Isolated local API/web execution does not establish normal deployment startup,
  real email/push/storage delivery, native-device behavior or infrastructure outage resilience.
- Current empty recent-activity coverage remains historical; first-record empty
  ordinance/section registries were not manufactured. Current empty-search and
  empty dashboard-attention cases passed.
- Analytics ranking truncation beyond ten and nonzero historical risk bands were
  not exercised live. Historical offense/severity data follows the selected year;
  risk rankings intentionally use current compliance. The preserved analytics
  summary counts one severity case while the raw evidence records four passes.
- Hardcoded configuration notes about active/draft counts and backup completion
  remain an unrelated UI issue; they establish no backup-readiness evidence.
  Existing package/build warnings remain documented in the linked review.

Phase 0 remains closed with its documented limitations. Phases 1 and 2 retain
their lifecycle, live delivery and device verification gaps. Phase 4 operational
readiness remains open and has not started as a verification phase. This closure
does not authorize the next slice or advance to another phase.

## Progress update — 2026-10-21

Historical status below; the approved 2026-10-24 closure supersedes Phase 3 status.

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

### Enforcer checks included in roadmap verification

The separate deferred-enforcer-slices.md tracker was removed at the user's
request on 2026-10-22. All five slices have implementation evidence; remaining
checks are tracked here with the corresponding roadmap stories. A single run can
satisfy both when it explicitly covers the same acceptance criteria. None of these
mobile slices is marked fully verified by this consolidation.

| Existing slice | Roadmap verification | Remaining acceptance coverage |
| --- | --- | --- |
| 1 — Card summaries and ticket loading | Phase 1: enforcer inspection/ticket lists | Full `Ord No. {number}, Series of {series}` labels; private vendor without a stall; recoverable initial/refresh/paging errors; retry and ownership. Evidence: `evidence/enforcer-summary-slice-1/README.md`. |
| 2 — Inspection and ticket filters | Phase 1: enforcer inspection/ticket lists | Inspections default All; tickets default Pending; All omits the filter; search survives selection; paging resets; stale responses cannot replace current results; narrow layout and role isolation. Evidence: `evidence/enforcer-filters-slice-2/README.md`. |
| 3A — Ticket detail and preview paper | Phase 1: issuance, detail and settlement | Matching responsive paper; actual issued control number at 16px, PENDING in preview, none on warnings; full ordinance labels and code spacing; bottom-right prices only for cash fines; receipt selection/save/reopen and invalid-image recovery. Evidence: `evidence/enforcer-ticket-paper-slice-3a/redesign-report.md`. |
| 3B — New-inspection form controls | Phase 1: new inspection | Full ordinance labels in rows/chips; selection/search/restrictions; compact photo action; native capture/cancel/permission/error/retry; small removal icons with accessible targets; gallery and draft preservation on preview Back. Evidence: `evidence/enforcer-form-controls-slice-3b/README.md`. |
| 4 — Enforcer notification parity | Phase 2: cross-role notification integration | Vendor-style enforcer header/cards/filter; All/Unread counts and pagination; snapshot-before-write mark-all; partial failure and retry; correct role-specific detail navigation, ownership and persistence after relogin. Evidence: `evidence/enforcer-notification-slice-4/README.md`. |
| 5 — Profile camera overlap | Phase 2: vendor/enforcer profile checks | Camera partly outside centered portrait; unclipped accessible outer-edge tap target; narrow/enlarged-text layouts; selection/cancel/removal/error/loading states and persisted photo changes. Evidence: `evidence/profile-camera-slice-5/README.md`. |

Historical environment prerequisites (2026-10-22/23): later approved isolated-host
verification and reuse are recorded in the closure evidence above. These earlier
checks alone did not establish application or deployment readiness.

Live E2E requires the explicitly identified disposable environment. The then-current
local `marikina_market_e2e` schema was verified on 2026-10-22 with 35 migrations,
four roles and reference data, but zero accounts. Shared synthetic account setup
is proposed, not yet approved or executed. API/client routing and isolated
email/push/storage/background-service configuration remain prerequisites.
See `evidence/local-e2e-database/schema-completion-2026-10-22.md`.

Account-setup preflight on 2026-10-23 supersedes the empty-account baseline:
the database now has six users, six role assignments, two vendor profiles,
one audit log and one backup schedule. The approved helper stopped before
seeding; this task created no accounts or credentials. Existing records and
credentials have not been validated. The user authorized preserving the
LOGIN-enabled database owner; that setting was not changed. Confirm provenance
and approve verification/reuse of the existing records before proceeding.
No API/client startup is established by these checks. See
`evidence/local-e2e-database/accounts-setup-status.md` and `accounts-preflight.json`
in that directory.

### Evidence reconciliation — 2026-10-22

This read-only review of recorded results does not rerun application verification,
advance phases or declare a whole phase complete. The 2026-10-21 overview above
remains historical where later evidence is more specific.

Recorded verified slices, within their approved scope:

- Phase 3 accounts: `evidence/phase-3-accounts-live/README.md` and passing live TRX.
- Phase 3 ordinances/penalties: `evidence/phase-3-ordinances-live/README.md` and passing live TRX.
- Phase 3 vendor concurrency/narrow-layout fixes with final vendor story rerun:
  `evidence/phase-3-vendor-fixes/README.md`, `browser-result.json`, `live-final.trx`.
- Phase 3 market-section management/focus: `evidence/phase-3-market-section-focus-fix/README.md`
  and passing focus-after TRX/browser results supersede the original focus blocker.
- Phase 3 dashboard totals/navigation: `evidence/phase-3-dashboard-shortcut-fix/README.md`
  and passing dashboard live TRX supersede the original shortcut blocker.
- Phase 4 backup browser/manual download, automatic failure/retry/restart and
  automated decrypt/restore drill: `evidence/phase-4-full-e2e/result.json` and
  passing `full-e2e.trx`. Its README still says running; final artifacts establish
  this bounded drill passed, not operational readiness or a user-operated restore.

Remaining verification work as of 2026-10-22, grouped by phase:

- Phase 1: registration submission/decisions and first login/OTP; warning/ticket
  issuance; vendor-owned Records/proofs; cash-fine, blood-donation and
  community-service settlement; cross-client persistence, role and failure paths.
  Include enforcer slices 1–3 above.
- Phase 2: vendor/enforcer inbox persistence/ownership and mark-all; real device
  registration, push delivery/opening and post-commit delivery failure; profile,
  account and QR actions with native-device/loading/empty/error/role coverage.
  Include enforcer slices 4–5 above.
- Phase 3: live analytics reconciliation and date boundaries; live audit filters,
  counts/details/denial/recovery; close report snapshot/export regression gaps.
  `evidence/phase-3-reports-live/README.md` records a passing live report story but
  broad regression failures, so do not treat that whole slice as complete.
  These historical Phase 3 gaps were subsequently reconciled by the current
  analytics, audit and reports/regression evidence linked in the approved closure.
- Phase 4: remaining outage/restart/permission cases, user-operated restore drill,
  complete regression and cross-client E2E coverage, and current reproducible
  setup/deployment/recovery documentation. Historical backup-drill results alone
  do not close these criteria.

At this 2026-10-22 review, Phase 0 remained closed with documented limitations and
Phases 1–4 remained open as whole-phase verification. The approved 2026-10-24
closure supersedes only the Phase 3 status. Previously passed isolated-host stories do not establish
normal deployment startup or external delivery unless their evidence says so.

### Approved migration exception

Prepare and verify a local monorepo candidate while preserving the original
repositories, Git history, and uncommitted work.

Intended remote:
https://github.com/gvillaluz/marikina-market-ticketing.git

The original workspace now contains one root Git repository with sanitized application histories and current working changes.
The supplied remote was checked; no HEAD was advertised. Nothing has been pushed.
Setup documentation and migration verification are tracked in docs/environment-setup.md
and docs/environment-verification.md; in-place results are in docs/cutover-verification.md. Original repositories are backed up locally. Live/device checks remain outstanding.
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

## Historical progression decision (2026-10-17)

Later separately approved verification tasks and the 2026-10-24 closure supersede
the Phase 3 focus and verification deferral below. Phases 1 and 2 remain open.

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

Status: **Closed by user approval on 2026-10-24 for the approved stories within
the limits and evidence recorded in the closure note above.**

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
