# Roadmap

Precedence: roadmap rules win on scope and what may be worked on. feature-workflow.md wins on procedure. The product AGENTS.md wins on safety boundaries.

**Mode:** revision implementation/verification; application changes require approval per slice.
**Current phase:** Revision Phase — FIRST PRIORITY; the ordinance revision (slices 1–3) and Part 1 (business records, paper tickets and settlement) are closed with recorded limits. OCR items (local OCR feasibility, OCR integration) are not started.
**Current task:** none in progress. The next Revision Phase slice needs a separate plan and approval; nothing is authorized by these closures.
**Approved:** Part 1 criteria 1–7 and ordinance revision slices 1–3 closure within their recorded limits. Slice 3 closed 2026-11-01 by explicit user approval ("let's close the slice 3"), including its follow-up fixes and accepting the vendor-only paging stall (see [slice 3 closure](#ordinance-revision--slice-3-closed-2026-11-01)). Slice 2 closed 2026-11-01 by explicit user approval accepting the vendor-only paging stall because the vendor end of marikina-market-mobile is being removed (see [slice 2 closure](#ordinance-revision--slice-2-closed-2026-11-01)). Slice 1 evidence: API build/707 passes/two existing skips, web build/143 passes, 73 focused mobile passes after the approved cache repair, APK build/install, real API/admin-browser/V2529 catalog/selection/cache/cold-relaunch checks. Full Flutter reached 462 passes with zero assertion failures, then stalled in the vendor records paging test; accepted as incomplete, not passed, for slice 1 because vendor-user retirement is planned. Five existing analyzer infos and the isolated-storage verification limit remain documented. The user approved the final slice 2 implementation/verification scope on 2026-10-31. This does not authorize publishing, new migration execution or vendor-user/code/data removal.

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

### Vendor-end removal — mobile only (CLOSED 2026-11-02)

Approved scope: remove the vendor login end of `marikina-market-mobile` (vendor routes, dashboard, records, QR export, vendor profile model) with no API or web change; vendor-as-violator lookups, `Role.marketVendor` and the enforcer inbox's vendor-style tiles kept. Also approved: vendor-only test deletions, unused QR/vendor theme values, the skeleton `isVendor` flag, and removal of `share_plus` and `file_saver`.

Closed by explicit user approval: "okay close it". Evidence ([report](evidence/vendor-mobile-removal-2026-11-02/report.md)): full Flutter suite **417 passed** (first complete run; the vendor-paging stall is gone with the removed records feature); analyzer five inherited infos only; V2529 against guarded disposable `marikina_market_e2e` passed enforcer tabs/bell, notifications open, profile/edit, sign-out, fresh code sign-in and cold relaunches. Vendor no-access screen not shown on device: the API already refuses vendors at mobile sign-in, and the `vendorPublic`/`vendorPrivate` test accounts no longer exist in the disposable database (removed by the criterion-2 vendor account deletion); redirect covered by automated tests. Observations (not fixed): the old grouped notification list (`NotificationList`, `NotificationTile`, `useVendorStyle=false`) is reachable only from tests. Resolved 2026-11-02: unused `qr_flutter` removed (analyzer five inherited infos, 417 tests passed, debug APK built). Closure does not authorize API/web vendor retirement, further removals or publishing.

### Ordinance revision — slice 3 (CLOSED 2026-11-01)

Approved scope ([plan](docs/ordinance-slice3-plan.md)): data-only migration `20261101090000_OrdinanceWorkbookCatalog` replacing the catalog with the 53-section Ordinance 011 (2014) workbook (`Untitled spreadsheet.xlsx` categories): 20 legacy rows updated in place, legacy ID 1 retired, 34 new rows left unconfigured (no severity, not warning-eligible), Section 79 split Public/Private, blood donation off, community service first-offense monetary only. Follow-up fixes approved before closure: API enforcement lookups refuse inactive ordinances; mobile hides inactive ordinances, shows titles in selection/form, and explains unavailable totals.

Closed by explicit user approval: "let's close the slice 3". Evidence ([report](evidence/ordinance-slice3-2026-11-01/report.md)): catalog tests red→green with mutations; API final 755 passes/two skips; migration applied only to guarded disposable `marikina_market_e2e` under separate authorization after readable backup; live API, admin browser (S17 severity set) and V2529 checks passed (catalog/categories, warning list, unconfigured S13 blocked, inactive ID 1 hidden and refused, citations 294 ₱600 and 295 ₱1,500 persisted through relaunch); original ticket/violation/evidence/person rows unchanged. Mobile analyzer five inherited infos only.

Accepted limit for this slice only: full Flutter suite **incomplete, not passed** — 487 passes, then the unchanged vendor-only `records_feature_test.dart` paging test timed out and stalled. No test deleted or weakened. Observations (not fixed): mobile ordinance search matches only number/series; preview and saved-ticket screens omit the ordinance title (needs an API change). Closure does not authorize OCR work, vendor-end removal, publishing or further migrations.

### Ordinance revision — slice 2 (CLOSED 2026-11-01)

Approved scope ([plan](docs/ordinance-slice2-plan.md)): ordinance-only scoring severity; independent warning eligibility; Fixed/UpTo/Unconfirmed tiers with visible terms; UpTo minimum ₱100 to configured cap with enforcer-entered paper amount; first-offense-only blood/community flags intersected across selected tiers; no highest-tier fallback or invented zero; Verify/Submit recheck and edit invalidation; API first, web and mobile together.

Closed by explicit user approval: "yes, i accept the vendor-paging stall failure because im removing the vendor's end in the marikina-market-mobile. we can close the slice 2". Evidence ([report](evidence/ordinance-slice2-2026-10-31/report.md), [contract](evidence/ordinance-slice2-2026-10-31/api-contract.md)): API 745 passes/two existing skips, final affected 141 passes and Release build; web build/152 passes; mobile format clean, analyzer five inherited infos only, 93 focused passes, APK built/installed preserving data. Real API/storage/admin-browser checks and V2529 native story passed: warning eligibility, tier display, alternative intersection, ₱100/₱1000 bounds, edit-after-Verify, one native citation (ticket 293, ₱850.50, High, two JPEG evidence rows), cold relaunch, fresh credential/OTP sign-in, 1.3× text, cache decode and original-data preservation (43/33/5/25).

Accepted limit for this slice only: full Flutter suite **incomplete, not passed** — 481 passes, then unchanged vendor-only `records_feature_test.dart` paging timed out and stalled. No test deleted or weakened. Migration 20261031112520_OrdinancePenaltyRules was separately authorized and applied only to guarded disposable `marikina_market_e2e`. Observations (not fixed): Warning→Ticket switch clears violator name; saved-detail time uses render time; saved detail shows "Others" without specific category. Closure does not authorize vendor-end removal, publishing or slice 3 implementation.

### Ordinance revision — slice 1 (CLOSED 2026-10-31)

Approved scope: ordinance section replaces market/ordinance code in entities and contracts; revised selectable categories with required specific text for Others; Fine amount wording; API/web/mobile consumers updated together. User separately approved the narrow mobile cache repair discovered during live verification: refresh the catalog from the API, save successful responses in the existing Hive cache, and use cache fallback only for network failure.

Implementation, automated and live evidence are recorded separately in [slice 1 report and contract](evidence/ordinance-slice1-2026-10-31/report.md). API: 707 passes/two existing skips and Release build. Web: 143 passes/build. Mobile: 73 focused passes, no issues in cache-repair analysis, five retained full-analyzer infos, APK built and installed preserving app data. Real admin/browser save, invalid-input/role rejection, failed-save/retry, refresh/fresh sign-in and V2529 catalog/selection/fine/cache/cold-relaunch checks passed. Independent fingerprints confirm existing ticket, evidence, settlement, business and person rows unchanged.

The user explicitly accepted closure after confirming the paging test is vendor-user facing: `records_feature_test.dart`, “scrolling fetches only at the bottom and stops after the last page,” renders `RecordsPage`, routed under `/vendor/records`, and its data source uses `/vendor/tickets/inspections`. The 462-pass full Flutter run stalled here and remains **incomplete, not passed**. No test was deleted or weakened. Closure does not authorize removing vendor accounts, screens or data. Existing analyzer infos and isolated-host photograph-backed ticket retrieval limits remain as reported; no broad readiness waiver.

The new schema migration was separately authorized and applied only to guarded local `marikina_market_e2e` after a readable recovery backup. Original catalog identities and legacy codes were preserved. The single synthetic ordinance ID 24 remains a disposable verification fixture. Operational data was not accessed. Owned verification services are stopped and the task's ADB reverse rule removed. Source and existing uncommitted work are preserved; nothing published.

Next requested slice: penalty-tier behavior, backend first and all affected clients together. Confirmed rules: enforcer enters the paper-assessed amount for monetary “up to” tiers, with minimum 100 and maximum the stated cap; unresolved/conditional or missing later-offense rules display terms and require confirmation; each ordinance has independent warning eligibility; blood donation/community service are independently configurable on first offense only. Severity stays on the ordinance for scoring only, with no severity on tiers or effect on fine/eligibility decisions. See [final slice 2 scope and verification plan](docs/ordinance-slice2-plan.md). The workbook catalog migration remains slice 3; no slice 2 migration execution or vendor-user removal is authorized by this plan.

### Part 1 — Business records, paper tickets and settlement (CLOSED 2026-10-30)

Goal: record paper-issued tickets and settlement without mandatory vendor accounts.

Exit criteria:
- ✓ Staff maintain business records: official business account number, business name, registered owner, market section and stall where applicable. License account-number meaning/uniqueness confirmed. Closed 2026-10-28 after real web/API and V2529 checks; user explicitly deferred the recorded full Flutter suite/analyzer limitations for this criterion only. Evidence: [live verification](evidence/revision-business-records-2026-10-27/live-verification.md).
- ✓ Rename VendorProfile/VendorProfiles to Business/Businesses after checking actual mappings; update affected relationships, contracts and both clients, retain applicable business metadata, and document the schema transition. Closed 2026-10-28 by approved reconciliation of the existing implementation and web/API/V2529 evidence. The approved deletion of old vendor accounts/profiles and linked tickets/history supersedes the former ID/account-link/history preservation requirement; the disposable migration was applied under separate explicit authorization. Individual/person records remain open under criterion 3. Evidence and retained verification limits: [criterion 2 assessment](evidence/revision-business-records-2026-10-27/criterion-2-review.md).
- ✓ Separate individual vendor/person records without login accounts from business records. Paper NAME/Pangalan is the violator; offense history belongs to the confirmed individual vendor, not the business/owner. Preserve the paper name separately from registry identity; same names must not automatically merge people. No new owner/employee permission roles. Closed 2026-10-29 under the user's conditional approval after confirming the remaining legacy vendor-records paging stall and five analyzer infos are unrelated to this criterion. Full Flutter suite remains incomplete, not passed; no broad readiness waiver. Evidence and exact limits: [criterion 3 closure](docs/criterion-3-closure.md).
- ✓ Save citations with reviewed paper reference, issue date/place, business/vendor links, violator, ordinance, penalty, issuing enforcer, original image and separate supporting evidence. Retain internal IDs and historical business/owner details when registry values change. Criterion 4 and slices 1–4 closed 2026-10-30 by explicit user approval after real API/browser/V2529 verification, with the incomplete vendor-paging suite and existing observations retained. See [closure and evidence](#criterion-4-closure--2026-10-30); mobile saved-time rendering remains an observation, not a claimed fix.
- ✓ Warnings use their own fields and agreed reference/duplicate procedure; the supplied warning has no printed control number. Person/ordinance lifetime warning rule, same-Manila-day pending citation exclusion, one paper warning photo and server-owned reference/time implemented and verified across the real API, staff browser and V2529. Criterion 5 and both slices closed 2026-10-30 by explicit user approval, accepting the unrelated vendor-paging full-suite stall. See [closure and exact limits](#criterion-5-closure--2026-10-30). Citation printed-reference uniqueness remains separate from internal warning numbering.
- ✓ Authorized staff process cash-fine, blood-donation and community-service settlement without vendor app use. Criterion 6 closed 2026-10-30 by explicit user approval: assigned enforcer submits proof; HeadAdmin/AdminOfficer settle cash/blood; service hours automatically progress InProgress → Cleared at completion. Real API/browser/V2529 checks passed, including failure/reload and fresh-sign-in persistence. Full Flutter suite stalled after 451 passes with zero assertion failures; accepted limit, incomplete rather than passed. Evidence: [cash/blood](evidence/settlement-slice-report.md), [community service](evidence/community-verification-report.md).
- ✓ Persistence, authorization, duplicate/retry protection and failure recovery verified within the recorded scope. Criterion 7 and Part 1 closed 2026-10-30 by explicit user approval after fixing settlement retries with durable submission IDs. Real disposable API, API restart, browser and V2529 lost-response/reload checks passed. Full Flutter suite stalled after 453 passes with zero assertion failures; explicitly accepted limit, incomplete rather than passed. Existing observations and prior closure limits remain. Evidence: [criterion 7 repair and contract](evidence/criterion-7/repair-report.md).

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

Historical read-only assessment before the two criterion-5 slices: warning creation and a distinct Written Warning Preview already existed. Warning saves then had no citation paper-reference/photo requirements and no monetary penalty/status. The server generated an internal `WRN-{id:D4}` reference, not a printed warning number. Duplicate detection then checked business/ordinance warning history and excluded pending citation ordinances for that business within a rolling 24 hours. Those observed rules were superseded by the approved person-based procedure recorded below.

Evidence supports existing behavior, not full criterion completion: `InspectionNotificationTests` covers warning save/null fields/JWT attribution and failure handling and passed in the final 675-test API run; recent focused Flutter runs include warning navigation regressions. [Historical warning issuance report](evidence/warning-issuance/README.md) explicitly says live E2E unverified. [Warning-detail verification](evidence/phase-1-warning-detail/README.md) is automated-only; historical vendor-device display evidence does not establish revised enforcer create/duplicate/relogin behavior.

At that assessment, policy reconciliation and revised live verification were still outstanding; no warning was created or code changed by the assessment itself. The later approved slices resolved the rules and supplied the closure evidence below. Historical automated-only reports alone did not establish revised completion.

### Criterion 5 closure — 2026-10-30

Closed by explicit user instruction: disregard the vendor-paging failure because the vendor-facing mobile end is being removed, and close criterion 5 if there are no other failures. Review of final checks found no other unresolved introduced failure. Slice 1 (rules/contract planning) and slice 2 (implementation/verification) are closed. This accepts the vendor-paging limit for criterion 5 only; it does not execute or approve vendor-mobile removal or broaden readiness claims.

Confirmed warning rules: required confirmed person, business, exactly one minor ordinance, description, actual issue place and one paper warning photo; no supporting photos, monetary penalty or settlement status. Server supplies UTC saved issue time and internal `WRN-{recordId:D4}` reference; no printed/manual warning number is invented. A confirmed person's warning for an ordinance blocks another forever across businesses/dates/officers. A pending citation for that person/ordinance on the same Manila calendar day blocks the warning. No silent ordinance removal. Warnings do not increase citation offense tiers. Business-only history cannot establish a person's previous warning; no automatic identity backfill or reset workflow is added.

Evidence: API build and 697 tests passed/two existing opt-in skips; web build and 137 Node tests passed; changed Dart format and 53 focused Flutter checks passed; APK built/installed. Final analyzer retained five existing infos, with no new warnings/errors. Real disposable API, HeadAdmin/AdminOfficer browser and V2529 checks passed for required fields/photos, person-based duplicate denial across businesses, same-day pending citation exclusion, concurrent 201/409 with exactly one saved warning, actual stored JPEG retrieval, real outage/retained draft/checked history/one intentional retry, cold relaunch, fresh sign-in, native lifetime-conflict message and enlarged-text saved detail. Independent final totals: 29 records (24 citations/five warnings), 19 persons, five businesses and 24 evidence rows. All pre-existing ticket/person/business/evidence hashes match baseline.

Accepted full-suite limit: Flutter reached 462 passes with zero assertion failures, then stalled in unchanged vendor paging; stopped after 314 seconds without progress. **Incomplete, not passed**, explicitly accepted by the user for this closure. Existing skips, analyzer infos and tooling/package warnings remain. Lifetime-date/Manila-midnight/status boundary tests are repository evidence; live time travel and storage/notification-save outage were not induced. External email/push delivery is not claimed. Six storage uploads for five committed paper rows retain the existing possibility of one unreferenced upload after a losing concurrent transaction; no deletion promise. Existing enforcer detail ownership, shared web signature-date, legacy modal route and citation widget-time observations remain unchanged.

Only guarded local `marikina_market_e2e` was used; no migrations, schema/dependency changes or operational data access. Native photo is a dark covered-lens capture; nearby-object preview was not captured/uploaded. Test services stopped, font restored, ADB reverse removed, app data/source preserved and changes uncommitted. Generated test artifacts remain. No next criterion, vendor-mobile removal, additional fixture writes/uploads or publishing is authorized by closure.

The completed criterion-5 plan was deleted at the user's request after closure; this roadmap retains the consolidated rules, evidence and accepted limits. Detailed machine-local evidence: [verification/manual retest](evidence/revision-warning-person-2026-10-30/verification-report.md), [API contract](evidence/revision-warning-person-2026-10-30/api-contract.md), [changes per file](evidence/revision-warning-person-2026-10-30/changed-files.md), [live API results](evidence/revision-warning-person-2026-10-30/live-api-result.json), [device results](evidence/revision-warning-person-2026-10-30/live-device-result.json). Ignored evidence may be absent in another checkout; never infer a pass from a missing artifact.

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

Revalidate only affected functionality; original closure does not prove changed behavior. Evidence: `evidence/phase-3-dashboard-current/phase-3-closure-review.md`, `evidence/phase-3-dashboard-current/phase-3-reconciliation.json`. Retained limits include external delivery/device coverage, ranking beyond ten, historical risk bands. The severity-count mismatch (summary 1 vs raw 4) is explained: an evidence-script counting error, with all four raw cases passed. See `evidence/phase-3-analytics-year-filter/count-correction-2026-11-03.md`.

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

- Resolved 2026-11-03: analytics severity-count mismatch (summary 1 vs raw evidence 4). The evidence script miscounted the results list under Windows PowerShell 5.1. All four raw cases passed, and the app is not affected. Historical files are unchanged; see the correction note above.
- Resolved 2026-11-03: hardcoded configuration page stat cards and notes (market sections, active ordinances, last backup). The page now shows live counts and the real last successful backup (HeadAdmin only), with loading skeletons and per-card retry. Evidence: web build passed; the configuration browser check passed 3/3 against a temporary dev server with mocked API responses (real values, none-yet, error/fallback, retry, AdminOfficer hides the backup card, 390px layout). Not verified against the real API; changes remain uncommitted.
- Resolved 2026-11-04: Phase 4 backup README status text. `evidence/phase-4-full-e2e/README.md` said "running"; it now says completed 2026-10-17, matching `full-e2e.trx` (1 executed, 1 passed) and `result.json`. Documentation only; the evidence folder is git-ignored, so the edit is local.
- Existing package/build warnings.
- Criterion-3 closure observations: five retained analyzer infos and Android tooling warnings (AGP 8.11.1 and Kotlin 2.2.20 nearing end of Flutter support). Unrelated to the accepted criterion-3 requirements; retained for a separate approved maintenance decision. See [closure record](docs/criterion-3-closure.md). The vendor-records paging stall was resolved by the mobile vendor-end removal (2026-11-02).
- The `vendorPublic`/`vendorPrivate` E2E accounts were removed by the approved criterion-2 vendor account deletion (database holds only the four staff accounts, checked read-only 2026-11-02); their credentials and aliases remain in local user-secrets and evidence helper scripts. Resolved 2026-11-04: the four `vendorPublic`/`vendorPrivate` user-secret entries (username and password each) were removed from the API project's local user-secrets after the user approved; the four staff accounts' entries remain. The evidence helper scripts were left unchanged: they hold only the account names, no credentials, and are records of closed slices.

## Deferred work

Mandatory vendor registration/mobile/profile/push/proof-submission completion and old digital-first issuance are removed from active requirements. Existing code, accounts, tests and evidence are preserved; exact retirement/removal actions need their own approved slice. Retained exposed paths still require appropriate checks. Historical vendor evidence: `evidence/phase-2-vendor-notifications/README.md`, `evidence/mobile-device-registration/README.md`, `evidence/mobile-notification-opening/README.md`, `evidence/vendor-profile-v2529-readonly/README.md`. Retained enforcer UI evidence: `evidence/enforcer-notification-slice-4/README.md`, `evidence/profile-camera-slice-5/README.md`; neither is implied complete.

Public vendor lookup, vendor mobile expansion, printing, SMS, bulk imports, custom training, full offline sync/durable drafts, new roles and scanning for another officer remain deferred. Document deletion after approval remains deferred. Infrastructure/architecture expansion and capabilities outside this roadmap require separate approval. No slice is implemented or complete merely because this roadmap changed.
