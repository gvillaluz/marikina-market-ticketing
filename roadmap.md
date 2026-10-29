# Roadmap

Precedence: roadmap rules win on scope and what may be worked on. feature-workflow.md wins on procedure. The product AGENTS.md wins on safety boundaries.

**Mode:** revision implementation/verification; application changes require approval per slice.
**Current phase:** Revision Phase — FIRST PRIORITY; business/person criteria 1–3 closed with recorded limits.
**Current task:** criterion 4 slice 2 (paper reference/place) closed 2026-10-30 with explicit user-approved verification limits; criterion 4 remains open. See [slice 2 closure](docs/criterion-4-plan.md#slice-2-closure--2026-10-30-asiamanila).
**Approved:** completed named slices, criterion-3 closure and criterion-4 slice-2 closure with recorded limits. Vendor-facing mobile removal is confirmed product direction; its bounded removal plan and later criterion-4 slices need separate approval before implementation. This status does not authorize publishing.

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
- ☐ Save citations with reviewed paper reference, issue date/place, business/vendor links, violator, ordinance, penalty, issuing enforcer, original image and separate supporting evidence. Retain internal IDs and historical business/owner details when registry values change.
- ☐ Warnings use their own fields and agreed reference/duplicate procedure; the supplied warning has no printed control number. Paper citation numbering across booklets/years must be confirmed.
- ☐ Authorized staff process existing cash-fine, blood-donation and community-service settlement without vendor app use. Confirm treasury/market-office responsibilities, proof and permissions; a selected penalty does not mean settled.
- ☐ Persistence, authorization, duplicate/retry protection and failure recovery pass against the real disposable API and affected clients.

Implementation is split into the ordered slices above. Backend first for changed contracts; update all affected consumers in the same slice.

Open rules: how to identify an individual reliably; counting across all offenses or per violation; warnings, resets, cancelled/contested/settled records and late scans; paper/calculated penalty discrepancies; business ownership changes. Resolve before dependent implementation; do not invent identifiers or policy.

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
