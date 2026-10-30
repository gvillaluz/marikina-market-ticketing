# Roadmap

Precedence: roadmap rules win on scope and what may be worked on. feature-workflow.md wins on procedure. The product AGENTS.md wins on safety boundaries.

**Mode:** revision implementation/verification; application changes require approval per slice.
**Current phase:** Revision Phase — FIRST PRIORITY; business/person/citation criteria 1–4 closed with recorded limits.
**Current task:** criterion 4 and all four implementation slices closed 2026-10-30 by explicit user approval. Its [closure record](#criterion-4-closure--2026-10-30) is consolidated below; the completed planning file was removed at the user's request. Criterion 5 warning implementation has been reviewed; revised policy/live-verification closure remains unconfirmed. No new implementation has started.
**Approved:** completed named slices and criterion-4 closure with recorded verification limits and pre-existing observations. Final slice: API 675 passed/two existing skips, web 135 passed, Flutter 29 focused checks and real API/browser/V2529 acceptance passed. Full Flutter suite stalled after 459 passes in unchanged vendor paging; user accepted this limit because vendor-facing Flutter removal is planned. It is incomplete, not passed. Vendor-facing mobile removal and the next revision criterion require their own bounded plans/approval. This status does not authorize publishing.

This roadmap organizes work; it does not authorize implementation. Preserve existing code, data and uncommitted work until each affected change is explicitly approved.

## Working rules (read before every task)

1. Work only on the slice the user approved. Do not create or add slices on your own. If a slice is too big, propose a split at the gate and wait for approval.
2. Each slice is judged only against its exit criteria below. When all of them pass, the slice is closed.
3. After a verification, report pass or fail per criterion. Propose a roadmap update or follow-up only when the workflow’s Report step asks for it, and never start it.
4. Anything extra you notice goes under **Observations** at the end of your report, or in the Backlog section. Do not act on it.
5. A real failure in a listed criterion is logged as a defect against that slice. Fix it only if the user approves.
6. Time-box each slice. If it is not closed by the limit the user sets, stop and ask whether the slice is too big or something is truly failing.
7. Skipped live checks are never counted as passed.
8. Never run migrations, touch a real database, or print credentials.
9. Existing unrelated issues are reported, not fixed.

## Status

| Phase | Status |
| --- | --- |
| **Revision Phase** | **First priority.** Rules → OCR trial → registry → ticket/verification → OCR/warnings → settlement → web/reporting; separate slice approvals |
| ✓ 0 Baseline | Closed with documented limits (2026-10-15); retained evidence below |
| 1 Core enforcement and settlement lifecycle | Waiting for Revision Phase; verify revised complete stories |
| 2 Enforcer mobile experience | Waiting for Revision Phase; verify revised device workflow |
| 3 Administration and reporting | Historical closure retained; affected checks resume after Revision Phase |
| 4 Operational readiness | Open; final revised-system readiness follows revision and lifecycle verification |

Previous Phase 1/2 verification was incomplete. Superseded requirements are removed, not marked passed. Historical evidence remains valid only for the original behavior and stated limits.

## Revision Phase — System revisions (FIRST PRIORITY; planning)

Complete and verify approved revision slices before resuming Phases 1–4. Phase 0 remains a historical baseline. This priority does not authorize coding; each slice retains its approval gate.

Order (separate gates): 1 confirm workflow, identity/counting rules and affected files → 2 local OCR feasibility → 3 business/person registry → 4 reviewed citation capture, calculation and verification → 5 OCR integration and warnings → 6 staff settlement → 7 affected web tables, reports and recommended actions. Split any oversized slice before approval.

Web/reporting revision scope: business/person administration without mandatory vendor registration; distinct business, registered owner and violator columns; scan/evidence/history retrieval; confirmed submitted records in summaries/exports; visible recommendation basis with administrator review. Phase 3 checks the resulting behavior after revision, preserving historical closure limits.

Exit: each approved slice passes its automated and live acceptance checks, unresolved prerequisites are resolved or explicitly deferred, and the user approves returning to the numbered verification phases. Record implementation, automated checks and E2E separately; incomplete work is not passed.

### Business records, paper tickets and settlement

Goal: record paper-issued tickets and settlement without mandatory vendor accounts.

Exit criteria:
- ✓ Staff maintain business records: official business account number, business name, registered owner, market section and stall where applicable. License account-number meaning/uniqueness confirmed. Closed 2026-10-28 after real web/API and V2529 checks; user explicitly deferred the recorded full Flutter suite/analyzer limitations for this criterion only. Evidence: [live verification](evidence/revision-business-records-2026-10-27/live-verification.md).
- ✓ Rename VendorProfile/VendorProfiles to Business/Businesses after checking actual mappings; update affected relationships, contracts and both clients, retain applicable business metadata, and document the schema transition. Closed 2026-10-28 by approved reconciliation of the existing implementation and web/API/V2529 evidence. The approved deletion of old vendor accounts/profiles and linked tickets/history supersedes the former ID/account-link/history preservation requirement; the disposable migration was applied under separate explicit authorization. Individual/person records remain open under criterion 3. Evidence and retained verification limits: [criterion 2 assessment](evidence/revision-business-records-2026-10-27/criterion-2-review.md).
- ✓ Separate individual vendor/person records without login accounts from business records. Paper NAME/Pangalan is the violator; offense history belongs to the confirmed individual vendor, not the business/owner. Preserve the paper name separately from registry identity; same names must not automatically merge people. No new owner/employee permission roles. Closed 2026-10-29 under the user's conditional approval after confirming the remaining legacy vendor-records paging stall and five analyzer infos are unrelated to this criterion. Full Flutter suite remains incomplete, not passed; no broad readiness waiver. Evidence and exact limits: [criterion 3 closure](docs/criterion-3-closure.md).
- ✓ Save citations with reviewed paper reference, issue date/place, business/vendor links, violator, ordinance, penalty, issuing enforcer, original image and separate supporting evidence. Retain internal IDs and historical business/owner details when registry values change. Criterion 4 and slices 1–4 closed 2026-10-30 by explicit user approval after real API/browser/V2529 verification, with the incomplete vendor-paging suite and existing observations retained. See [closure and evidence](#criterion-4-closure--2026-10-30); mobile saved-time rendering remains an observation, not a claimed fix.
- ☐ Warnings use their own fields and agreed reference/duplicate procedure; the supplied warning has no printed control number. Existing warning implementation confirmed by read-only review on 2026-10-30; full revised criterion closure is not yet established. See [criterion 5 assessment](#criterion-5-existing-implementation-assessment--2026-10-30). Citation printed-reference uniqueness was already resolved under criterion 4; do not reopen it as warning numbering.
- ☐ Authorized staff process existing cash-fine, blood-donation and community-service settlement without vendor app use. Confirm treasury/market-office responsibilities, proof and permissions; a selected penalty does not mean settled.
- ☐ Persistence, authorization, duplicate/retry protection and failure recovery pass against the real disposable API and affected clients.

Implementation is split into the ordered slices above. Backend first for changed contracts; update all affected consumers in the same slice.

Open rules: how to identify an individual reliably; counting across all offenses or per violation; warnings, resets, cancelled/contested/settled records and late scans; paper/calculated penalty discrepancies; business ownership changes. Resolve before dependent implementation; do not invent identifiers or policy.

### Criterion 4 closure — 2026-10-30

Closed by explicit user approval: “let's close the slice 4 and the criterion 4”. All four slices are closed: recording rules, reviewed paper reference/place, historical business snapshots and separate paper/supporting photo roles. The completed planning document was removed on request after consolidating this record. Its historical text is retained only in ignored local evidence at `evidence/revision-photo-roles-2026-10-30/criterion-4-plan-closed-archive.md`.

Confirmed rules: printed citation reference is globally unique as literal text, without a booklet/year component; reviewed reference and paper issue place are required. Server supplies UTC issuance time. Capture seven server-owned historical business values (account, name, registered owner, type, stall, section and composed address) without rewriting history or guessing legacy values. Exactly one paper photo plus at least one supporting photo applies only to violation citations; warnings keep their existing behavior. Existing JPEG compression remains; “original image” means the photograph of the paper, not untouched camera bytes. Old photo roles remain unclassified.

Evidence: final slice API build/675 passes/two existing opt-in skips, web build/135 passes, Flutter 29 focused passes and successful APK install; real disposable API, HeadAdmin/AdminOfficer browser and V2529 capture/Verify/save, invalid-category rejection, failure/history-check/intentional-retry, saved galleries, cold relaunch, fresh sign-in and enlarged-text checks passed. Independent final counts: 24 tickets, 15 persons, five businesses; slice 4 added two persons/two citations/five evidence uploads, with correct role/order/actor/fine values. Prior slice 2 reference-concurrency and slice 3 A/B historical-snapshot evidence remain valid for their stated scope.

Accepted limits: full Flutter suite reached 459 passes with zero assertion failures then stalled in unchanged vendor paging; incomplete, not passed. User accepted it because vendor-facing Flutter removal is planned. Five existing analyzer infos, tooling/package warnings and API skips remain. Mobile saved violation time still uses widget-render time; vendor-settlement wording and nonediting gallery delete-icon visibility remain observations, not fixes. One later supporting capture includes nearby objects with no readable sensitive record observed, disclosed during verification. Retention-locked uploads remain; no deletion promised. Generated QR test artifacts remain untracked following the previously blocked cleanup.

Migrations were explicitly authorized and applied only to guarded disposable local `marikina_market_e2e` after readable recovery backups; operational database untouched. The four original score timestamps were left as directed. Source remains uncommitted, app data preserved, settings restored and own test services stopped. No further writes/uploads, next criterion, vendor-mobile removal or publishing is authorized by closure.

Detailed machine-local reports: [paper reference/place](evidence/revision-paper-metadata-2026-10-29/verification-report.md), [historical snapshots](evidence/revision-business-snapshots-2026-10-30/verification-report.md), [photo roles and reconciliation](evidence/revision-photo-roles-2026-10-30/verification-report.md), [final API contract](evidence/revision-photo-roles-2026-10-30/api-contract.md), [per-file changes](evidence/revision-photo-roles-2026-10-30/changed-files.md). These ignored artifacts may be absent in another checkout; never infer passes from missing files.

### Criterion 5 existing implementation assessment — 2026-10-30

Read-only confirmation: warning creation and a distinct Written Warning Preview already exist. Warning saves have no citation paper-reference/photo requirements and no monetary penalty/status. The server generates an internal `WRN-{id:D4}` reference; this is not a printed warning number. Duplicate detection currently checks existing warnings for the selected business/ordinance across history, and the shared path also excludes active citation ordinances for that business/day. Warnings remain business-keyed rather than using the citation's confirmed person identity. These are observed existing rules, not newly approved warning policy.

Evidence supports existing behavior, not full criterion completion: `InspectionNotificationTests` covers warning save/null fields/JWT attribution and failure handling and passed in the final 675-test API run; recent focused Flutter runs include warning navigation regressions. [Historical warning issuance report](evidence/warning-issuance/README.md) explicitly says live E2E unverified. [Warning-detail verification](evidence/phase-1-warning-detail/README.md) is automated-only; historical vendor-device display evidence does not establish revised enforcer create/duplicate/relogin behavior.

Remaining confirmation: whether the current business/ordinance lifetime warning duplicate rule, active-citation exclusion and generated internal reference are the agreed criterion-5 procedure; then verify that procedure with revised real API/enforcer/staff flows and persistence/duplicate denial. No new warning has been created or code changed for this assessment. Criterion 5 stays open pending reconciliation/verification, rather than rebuilding the already existing flow or assuming completion from preserved citation-slice regressions.

### Scanning, calculation and verification

Goal: Scan → Automatic check → Review/edit → Verify → Submit.

Exit criteria:
- ☐ Test pretrained local recognition separately on sanitized completed tickets, varied handwriting and target hardware; agree per-field/checkbox accuracy and timing targets before evaluation. Compare capture-plus-correction time with current/manual recording. Start with citations, then warnings. Packages/model downloads require approval; custom training is deferred.
- ☐ Business name is handwritten in an agreed empty space on existing forms; confirm placement without adding labels or covering other fields/signatures. Scan extracts available text and marked boxes; recognition failures allow manual correction.
- ☐ Automatic checks flag missing fields/duplicates and suggest business and individual vendor matches for confirmation. Retrieve account number/owner from the selected business, not from guessed ticket text. Unresolved identity requires manual confirmation/search, not automatic record creation.
- ☐ Show provisional offense position and calculated fine after vendor/violation identification. Preserve paper-recorded penalty separately, flag discrepancies and show unavailable calculations rather than zero.
- ☐ Review shows image and editable extracted fields. Verify validates corrected details, rechecks duplicates and recalculates from current history; it does not save a final record or increase offense history.
- ☐ Submit starts disabled. Successful verification enables it; any edit to verified ticket information clears verification and disables Submit until verified again. Display: "Information changed. Verify again before submitting." Viewing images/history does not invalidate verification.
- ☐ Counts/fines are calculated, not editable. Correct a business association through selection; registry editing is separate. Preserve the editable paper violator name alongside confirmed person identity.
- ☐ Server repeats authorization, validation, duplicate and calculation checks at submission. Save image/record consistently; retries/concurrency cannot add duplicate offenses. A changed tier/fine requires renewed review and verification. Only successful submission contributes to history.

Recognition feasibility comes before dependent implementation. Integration uses the established identity, reviewed-record and verification contracts.

Unsubmitted drafts are review state, not settlement status. Durable drafts/offline sync are deferred. Initially the issuing enforcer captures their own ticket; scanning on another officer's behalf requires a separate attribution decision.

## ✓ Phase 0 — Baseline (closed)

Closed with documented limits. Later API checks passed 388 tests; web build and 79 Node tests passed. Mobile full-suite/device gaps remain recorded; historical passes are not revised-feature verification.

Evidence: `evidence/phase-0-task-2-api-command-investigation-2026-10-15/`, `evidence/phase-0-task-3-web-checks-2026-10-15/`, `evidence/phase-0-task-3-mobile-checks-2026-10-15/README.md`, `evidence/known-failures.md`.

## Phase 1 — Core enforcement and settlement lifecycle (WAITING FOR REVISION PHASE)

Goal: verify revised registration-independent enforcement-to-settlement stories.

Exit criteria:
- ☐ Enforcer login, confirmed business/person lookup, citation/warning recording and evidence retrieval pass against the real disposable API and affected clients.
- ☐ Offense/fine rules, duplicate protection, authorization, persistence and retry behavior pass with independent expected results.
- ☐ Authorized staff complete cash-fine, blood-donation and community-service settlement without mandatory vendor app use; status/history agree across clients.
Historical evidence: registration decisions `evidence/phase-1-registration-decisions-current/README.md`; first login/OTP `evidence/phase-1-vendor-first-login-current/validation.json`; enforcer summaries `evidence/phase-1-enforcer-summary-current/live-verification.md`; issuance `evidence/ticket-issuance/README.md`; cash settlement `evidence/cash-fine-lifecycle/run-2/README.md`; other settlement `evidence/blood-donation-settlement/README.md`, `evidence/community-service-settlement/README.md`. These do not close revised criteria.

## Phase 2 — Enforcer mobile experience (WAITING FOR REVISION PHASE)

Goal: verify the revised mobile workflow on the target device.

Exit criteria:
- ☐ Scan, automatic checks, identity selection, editable review, Verify and Submit work on-device; edits disable submission until re-verified.
- ☐ Provisional/final calculations, checkbox recognition, unreadable images, cancellation, permissions, duplicate/concurrent attempts and failed submission/retry behave as specified in the Revision Phase.
- ☐ Retained enforcer navigation/profile/notifications and narrow/enlarged-text layouts pass affected checks; verify real delivery separately when retained behavior requires it.
## Phase 3 — Administration and reporting (HISTORICAL CLOSURE; affected revision checks planned)

Previously closed with documented limits (2026-10-24): API build/576 tests passed, 2 skips; web build/113 tests passed; local administration, analytics, exports and audit stories passed within recorded scope.

Exit criteria for revised areas:
- ☐ Staff business/person management and access match approved permissions without mandatory vendor registration.
- ☐ Ticket tables show business name, registered owner and violator distinctly, plus reference, section, enforcer, date and status. Detail shows scan, evidence and change history; search supports agreed identifiers.
- ☐ Dashboard, reports/exports and mobile summaries use confirmed submitted records once, distinguish warnings/citations and reconcile with independent expected totals. Unsubmitted drafts do not contribute.
- ☐ Recommended actions show period, section, category and supporting counts, use confirmed data and require administrator review; recorded-ticket counts do not establish inspection-adjusted rates.

Revalidate only affected functionality; original closure does not prove changed behavior. Evidence: `evidence/phase-3-dashboard-current/phase-3-closure-review.md`, `evidence/phase-3-dashboard-current/phase-3-reconciliation.json`. Retained limits include external delivery/device coverage, ranking beyond ten, historical risk bands and unresolved severity-count mismatch.

## Phase 4 — Operational readiness (OPEN)

Goal: prove operation and recovery of the revised system.

Exit criteria:
- ✓ Backup scheduling/retry/encrypted download/retention and local multi-instance coordination passed within recorded limits. Evidence: `evidence/phase-4-full-e2e/result.json`, `evidence/backup-retention-verification/README.md`, `evidence/backup-instance-coordination/summary.json`. Recheck compatibility after schema/storage changes.
- ☐ User-operated restore drill and required external-service outage/restart stories pass in a disposable environment; automated restore alone is insufficient.
- ☐ API build/tests, web build/Node tests and mobile format/analyze/tests pass for affected work; target-device/browser E2E verifies identity, offense rules, edits/re-verification, duplicates/concurrency, persistence, permissions, retry and settlement.
- ☐ Setup/recovery instructions and beneficiary evaluation establish recognition accuracy, recording/retrieval time and practical usefulness. Separate implementation, automated checks, live E2E and acceptance evidence; record pre-existing failures separately.

Use commands in `feature-workflow.md`. Each gate names exact files/styles, contracts/errors, schema prerequisites, test expectations and time limit. Documentation-only edits require content/diff validation, not application builds.

## Live E2E environment

Use only the explicitly confirmed user-provisioned disposable `marikina_market_e2e` database; never run migrations or touch operational data. Prior 35-migration/four-role setup is historical, not a current schema guarantee. Recheck prerequisites per slice and reuse valid evidence without repeating unrelated checks. Details: `evidence/local-e2e-database/`.

## Migration exception (approved)

Local monorepo adoption preserved original repositories, history and uncommitted work. Intended remote: `https://github.com/gvillaluz/marikina-market-ticketing.git`; nothing pushed under the recorded exception. See `docs/environment-setup.md`, `docs/environment-verification.md`, `docs/cutover-verification.md`. No product-phase advancement implied.

## Backlog (parked, not approved)

- Analytics severity-count mismatch (summary 1 vs raw evidence 4).
- Hardcoded configuration notes UI issue.
- Phase 4 backup README status text; existing package/build warnings.
- Criterion-3 closure observations: legacy vendor-records paging test stall (full Flutter run incomplete after 451 passes), five retained analyzer infos and Android tooling warnings. Unrelated to the accepted criterion-3 requirements; retained for a separate approved maintenance/retirement decision. See [closure record](docs/criterion-3-closure.md). No automatic repair or vendor-app restoration.

## Deferred work

Mandatory vendor registration/mobile/profile/push/proof-submission completion and old digital-first issuance are removed from active requirements. Existing code, accounts, tests and evidence are preserved; exact retirement/removal actions need their own approved slice. Retained exposed paths still require appropriate checks. Historical vendor evidence: `evidence/phase-2-vendor-notifications/README.md`, `evidence/mobile-device-registration/README.md`, `evidence/mobile-notification-opening/README.md`, `evidence/vendor-profile-v2529-readonly/README.md`. Retained enforcer UI evidence: `evidence/enforcer-notification-slice-4/README.md`, `evidence/profile-camera-slice-5/README.md`; neither is implied complete.

Public vendor lookup, vendor mobile expansion, printing, SMS, bulk imports, custom training, full offline sync/durable drafts, new roles and scanning for another officer remain deferred. Document deletion after approval remains deferred. Infrastructure/architecture expansion and capabilities outside this roadmap require separate approval. No slice is implemented or complete merely because this roadmap changed.
