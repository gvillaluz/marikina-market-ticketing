# Roadmap

Precedence: roadmap rules win on scope and what may be worked on. feature-workflow.md wins on procedure. The product AGENTS.md wins on safety boundaries.

**Mode:** revision implementation/verification; application changes require approval per slice.
**Current phase:** Revision Phase — FIRST PRIORITY.
**Current task:** None in progress. Nothing new starts without the user's approval.

Legend: ✅ closed (date) · ☐ open · ⏸ waiting or decision for later

All notes, evidence and limits for closed work are in [docs/closed-work/README.md](docs/closed-work/README.md). Closed items below link to it.

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
| **Revision Phase** | **First priority.** Rules → registry → ticket/verification (✅ closed 2026-11-11) → faster entry/warnings (✅ faster entry closed 2026-11-10) → settlement → web/reporting; separate slice approvals |
| ✅ 0 Baseline | Closed with documented limits (2026-10-15) |
| 1 Core enforcement and settlement lifecycle | ⏸ Waiting for Revision Phase; verify revised complete stories |
| 2 Enforcer mobile experience | ⏸ Waiting for Revision Phase; verify revised device workflow |
| 3 Administration and reporting | Historical closure retained; affected checks resume after Revision Phase |
| 4 Operational readiness | Open; final revised-system readiness follows revision and lifecycle verification |

Previous Phase 1/2 verification was incomplete. Superseded requirements are removed, not marked passed. Historical evidence remains valid only for the original behavior and stated limits.

## Revision Phase — System revisions (FIRST PRIORITY)

Complete and verify approved revision slices before resuming Phases 1–4. Phase 0 remains a historical baseline. This priority does not authorize coding; each slice retains its approval gate.

Order (separate gates): 1 confirm workflow, identity/counting rules and affected files → 2 local OCR feasibility (dropped 2026-11-04) → 3 business/person registry → 4 reviewed citation capture, calculation and verification → 5 faster entry and warnings → 6 staff settlement → 7 affected web tables, reports and recommended actions. Split any oversized slice before approval.

Web/reporting revision scope: business/person administration without mandatory vendor registration; distinct business, registered owner and violator columns; scan/evidence/history retrieval; confirmed submitted records in summaries/exports; visible recommendation basis with administrator review. Phase 3 checks the resulting behavior after revision, preserving historical closure limits.

Exit: each approved slice passes its automated and live acceptance checks, unresolved prerequisites are resolved or explicitly deferred, and the user approves returning to the numbered verification phases. Record implementation, automated checks and E2E separately; incomplete work is not passed.

### Closed so far

- ✅ Ordinance revision, slice 1 — closed 2026-10-31
- ✅ Ordinance revision, slice 2 — closed 2026-11-01
- ✅ Ordinance revision, slice 3 — closed 2026-11-01
- ✅ Part 1, business records, paper tickets and settlement (criteria 1–7) — closed 2026-10-30
- ✅ Vendor-end removal, mobile only — closed 2026-11-02
- ✅ Step 7, slice 1: web ticket tables — complete 2026-11-06 (merged as PR #1)
- ✅ Step 7, slice 2: ticket change history (server + website) — complete 2026-11-07
- ✅ Web and reporting slice 2: business and person management (website) — complete 2026-11-07 (PR #5)
- ✅ Step 7, slice 3a: dashboard (server + website; Admin Officer and non-zero "today" counts not checked live) — closed 2026-11-11 (merged as PR #17). Notes: [docs/closed-work/website-step-7/slice-3a-dashboard.md](docs/closed-work/website-step-7/slice-3a-dashboard.md)
- ✅ Step 7, slice 3b: reports page and downloads (website; no app change, one new server test and a live check; Admin Officer and the empty-history message not checked live) — closed 2026-11-11. Notes: [docs/closed-work/website-step-7/slice-3b-reports.md](docs/closed-work/website-step-7/slice-3b-reports.md)
- ✅ Step 7, slice 3c: analytics charts (website; one new server test and a live check; warnings and tickets shown apart in the section chart and hotspot table; Admin Officer not checked live) — closed 2026-11-11 (PR #19). Notes: [docs/closed-work/website-step-7/slice-3c-analytics.md](docs/closed-work/website-step-7/slice-3c-analytics.md)
- ✅ Step 7, slice 3d: the enforcer's weekly phone summary (server; "This week's overview" now counts Monday to Sunday in Manila time instead of a UTC rolling 7 days; one new server test and a live check; not checked on a real phone) — closed 2026-11-11 (PR #21). Notes: [docs/closed-work/website-step-7/slice-3d-enforcer-week.md](docs/closed-work/website-step-7/slice-3d-enforcer-week.md)
- ✅ Admin end: warnings have no status (server refuses a status change on a warning; the website shows no status and no Change Status for one; Admin Officer not checked live) — closed 2026-11-11 (PR #20). Notes: [docs/closed-work/admin-end/warnings-no-status.md](docs/closed-work/admin-end/warnings-no-status.md)
- ✅ Admin end: warning pages show no due date and every record page shows its last-updated time (website and admin ticket detail; one additive response field; Head Admin checked live; Admin Officer not checked live) — closed 2026-11-11 (PR #23). Notes: [docs/closed-work/admin-end/admin-record-dates.md](docs/closed-work/admin-end/admin-record-dates.md)
- ✅ Faster entry A1 (find the business and the violator) — complete 2026-11-06
- ✅ Faster entry A2a (ordinance shortcuts and title search) — complete 2026-11-06
- ✅ Faster entry A2b (copy-to-paper card) — complete 2026-11-07
- ✅ Faster entry A3 (business search by owner or address) — complete 2026-11-09 (PR #7)
- ✅ Faster entry A2c (paper ticket scanner; Android checked, iPhone not tested) — complete 2026-11-09 (PR #8)
- ✅ Faster entry B1 (the system holds and shows tickets and warnings for unregistered vendors: server, phone, website) — complete 2026-11-09 (PR #9)
- ✅ Faster entry B2 (Registered / Unregistered choice and section entry on the phone; QR scanning removed; checked live on Android, iPhone not tested) — complete 2026-11-10 (PR #10)
- ✅ Faster entry: choosing the violator (owner shown first with one tap, "Add owner as person" in one tap, "Someone else" name search; server routes for the owner person; Change Vendor/section clear the violator; checked by the user on their own phone, no recorded results; iPhone not tested) — closed 2026-11-12 (PR #28). Notes: [docs/closed-work/faster-entry/violator-picker.md](docs/closed-work/faster-entry/violator-picker.md)
- ✅ Control number Part 1 (server messages and phone) — complete 2026-11-07
- ✅ Control number Part 2 (website) — complete 2026-11-07
- ✅ Phone-only fixes (review-page addresses, Warning ↔ Ticket keeps the person, notification wording) — complete 2026-11-08 (PR #6)
- ✅ Local OCR feasibility — dropped 2026-11-04 by user decision (not passed); replaced by faster in-app entry
- ✅ Faster entry — closed 2026-11-10 (A1, A2a, A2b, A2c, A3, B1 and B2 done); the timing test was dropped by user decision, so the speed-up was not measured
- ✅ Automatic checks (Scanning, calculation and verification, criterion 3; tests and live check only) — closed 2026-11-10
- ✅ Review and Verify (Scanning, calculation and verification, criterion 5; tests and live check only) — closed 2026-11-10
- ✅ Submit and Verify again (Scanning, calculation and verification, criterion 6; earlier evidence plus one new test) — closed 2026-11-10
- ✅ Calculated counts and the violator's name (Scanning, calculation and verification, criterion 7; tests only; the name comes from the chosen person's record) — closed 2026-11-10
- ✅ The server's checks at Submit (Scanning, calculation and verification, criterion 8; earlier evidence plus three new server tests) — closed 2026-11-11
- ✅ Scanning, calculation and verification (Revision step 4; all 8 criteria; remaining phone, live and iPhone checks belong to Phases 1, 2 and 4) — closed 2026-11-11
- ✅ Website vendor sign-up leftovers removed (website plus the server's 9 old sign-up routes; no schema change; Admin Officer not checked live) — closed 2026-11-11 (PR #22). Notes: [docs/closed-work/website-step-7/vendor-signup-leftovers.md](docs/closed-work/website-step-7/vendor-signup-leftovers.md)

### Open

- ☐ Step 7, next web and reporting slices (agreed order 2026-11-07, each needs its own approval): recommended actions (3c analytics charts and 3d enforcer's phone summary closed 2026-11-11)
- Control number Parts 1 and 2 (server, phone and website) are merged into `main` (pull request #2). The worktree is gone; the local branch `control-number-part2-web` is left over and can be deleted when you approve.

## Scanning, calculation and verification (✅ closed 2026-11-11)

Goal: Enter → Automatic check → Review/edit → Verify → Submit. The enforcer fills in the app, then copies to the paper ticket.

Exit criteria:
- ✅ OCR and handwritten business-name scanning dropped 2026-11-04 (not passed). Notes: [docs/closed-work/README.md](docs/closed-work/README.md).
- ✅ Faster entry (replaces OCR), closed 2026-11-10: find a business by name, stall, owner, address or account number; place filled from the business record; a "copy to paper" summary card on the entry page, before the review page with Verify (A2b). The suggested next control number was dropped by user decision on 2026-11-06, and the timing test on 2026-11-10. Every business comes from office records; enforcers do not create them. Detailed criteria are in the [slice A plan](docs/closed-work/faster-entry/ticket-flow-slice-a-plan.md).
- ✅ Automatic checks flag missing fields/duplicates and suggest business and individual vendor matches for confirmation. Retrieve account number/owner from the selected business, not from guessed ticket text. Unresolved identity requires manual confirmation/search, not automatic record creation. Closed 2026-11-10 (no app change; tests and live check on Android; iPhone not tested). Notes: [docs/closed-work/scanning/automatic-checks.md](docs/closed-work/scanning/automatic-checks.md).
- ✅ Offense position and calculated fine shown after person and ordinance are chosen; unavailable calculations shown instead of zero; the Review page warns when Verify's fine differs from what the enforcer copied onto the paper. The paper-penalty comparison was dropped by user decision (the system is the source for what is written on paper). Closed 2026-11-10 (phone only; tests and live check on Android; 3rd offense, "up to" fines and iPhone not checked live; PR #12). Notes: [docs/closed-work/scanning/fine-position.md](docs/closed-work/scanning/fine-position.md).
- ✅ Review shows the paper photo; a mistake is fixed by going Back to the entry page, which keeps what was typed (user decision: no edit boxes on Review, since scanning was dropped). Verify validates corrected details, rechecks duplicates and recalculates from current history; it does not save a final record or increase offense history. Closed 2026-11-10 (no app change; tests and live check on Android; a ticket saved between two Verifies is tests only; Submit and iPhone not checked live). Notes: [docs/closed-work/scanning/review-verify.md](docs/closed-work/scanning/review-verify.md).
- ✅ Submit starts disabled. Successful verification enables it; any edit to verified ticket information clears verification and disables Submit until verified again. Display: "Information changed. Verify again before submitting." Viewing images/history does not invalidate verification. Closed 2026-11-10 (no app change; tickets only; earlier live checks and tests plus one new photo test; photo viewing not checked live; iPhone not tested). Notes: [docs/closed-work/scanning/submit-reverify.md](docs/closed-work/scanning/submit-reverify.md).
- ✅ Counts/fines are calculated, not editable. Correct a business association through selection; registry editing is separate. The violator's name always comes from the chosen person's record (user decision: the editable paper name was dropped, so it is not counted as passed). Closed 2026-11-10 (no app change; earlier evidence plus two new tests; a misspelled name replaced by the record name on tap not checked live; iPhone not tested). Notes: [docs/closed-work/scanning/record-name.md](docs/closed-work/scanning/record-name.md).
- ✅ Server repeats authorization, validation, duplicate and calculation checks at submission. Save image/record consistently; retries/concurrency cannot add duplicate offenses. A changed tier/fine requires renewed review and verification. Only successful submission contributes to history. Closed 2026-11-11 (no app change; earlier live evidence plus three new server tests; no new live check; a losing submit can leave its photos in locked storage; iPhone not tested; PR #16). Notes: [docs/closed-work/scanning/submit-server-checks.md](docs/closed-work/scanning/submit-server-checks.md).

Faster entry uses the established identity, reviewed-record and verification contracts.

Unsubmitted drafts are review state, not settlement status. Durable drafts/offline sync are deferred. Initially the issuing enforcer captures their own ticket; scanning on another officer's behalf requires a separate attribution decision.

## Phase 1 — Core enforcement and settlement lifecycle (WAITING FOR REVISION PHASE)

Goal: verify revised registration-independent enforcement-to-settlement stories.

Exit criteria:
- ☐ Enforcer login, confirmed business/person lookup, citation/warning recording and evidence retrieval pass against the real disposable API and affected clients.
- ☐ Offense/fine rules, duplicate protection, authorization, persistence and retry behavior pass with independent expected results.
- ☐ Authorized staff complete cash-fine, blood-donation and community-service settlement without mandatory vendor app use; status/history agree across clients.

Historical evidence is listed in [docs/closed-work/README.md](docs/closed-work/README.md). It does not close revised criteria.

## Phase 2 — Enforcer mobile experience (WAITING FOR REVISION PHASE)

Goal: verify the revised mobile workflow on the target device.

Exit criteria:
- ☐ Entry, automatic checks, identity selection, editable review, Verify and Submit work on-device; edits disable submission until re-verified. Progress: faster entry A1–B2 entry steps (search, identity selection, copy card, scanner, unregistered entry) checked live on Android V2529; Verify and Submit for an unregistered vendor not checked live; iPhone not tested.
- ☐ Provisional/final calculations, unreadable images, cancellation, permissions, duplicate/concurrent attempts and failed submission/retry behave as specified in the Revision Phase.
- ☐ Retained enforcer navigation/profile/notifications and narrow/enlarged-text layouts pass affected checks; verify real delivery separately when retained behavior requires it.

## Phase 3 — Administration and reporting (HISTORICAL CLOSURE; affected revision checks planned)

Previously closed with documented limits (2026-10-24). Details: [docs/closed-work/README.md](docs/closed-work/README.md).

Exit criteria for revised areas:
- ☐ Staff business/person management and access match approved permissions without mandatory vendor registration. Progress: web and reporting slice 2 done (2026-11-07); Admin Officer not checked live; the website's vendor sign-up leftovers were removed (2026-11-11, PR #22).
- ☐ Ticket tables show business name, registered owner and violator distinctly, plus reference, section, enforcer, date and status. Detail shows scan, evidence and change history; search supports agreed identifiers. Progress: tables done (step 7 slice 1); detail scan, evidence and change history done (step 7 slice 2, 2026-11-07); control number search done (Control number Part 2); unregistered-vendor label shown in the tables, ticket page and person history (faster entry B1, 2026-11-09, checked live on the website); any further agreed search identifiers still to be confirmed.
- ✅ Dashboard, reports/exports and mobile summaries use confirmed submitted records once, distinguish warnings/citations and reconcile with independent expected totals. Unsubmitted drafts do not contribute. Closed 2026-11-11 by user decision (step 7 slices 3a to 3d; Admin Officer and the real phone not checked live). Progress: dashboard counters done (step 7 slice 3a, 2026-11-11, live check on the website; Admin Officer not checked live); reports page and downloads checked against hand-worked totals (step 7 slice 3b, 2026-11-11, live check on the website; Admin Officer not checked live); analytics charts checked against hand-worked totals and now show warnings and tickets apart (step 7 slice 3c, 2026-11-11, live check on the website; Admin Officer not checked live); the enforcer's weekly phone summary checked against hand-worked totals and now uses the Manila calendar week (step 7 slice 3d, 2026-11-11, server test and live check against the server; not checked on a real phone).
- ☐ Recommended actions show period, section, category and supporting counts, use confirmed data and require administrator review; recorded-ticket counts do not establish inspection-adjusted rates.


Revalidate only affected functionality; original closure does not prove changed behavior.

## Phase 4 — Operational readiness (OPEN)

Goal: prove operation and recovery of the revised system.

Exit criteria:
- ✅ Backup scheduling/retry/encrypted download/retention and local multi-instance coordination passed within recorded limits. Recheck compatibility after schema/storage changes.
- ☐ User-operated restore drill and required external-service outage/restart stories pass in a disposable environment; automated restore alone is insufficient.
- ☐ API build/tests, web build/Node tests and mobile format/analyze/tests pass for affected work; target-device/browser E2E verifies identity, offense rules, edits/re-verification, duplicates/concurrency, persistence, permissions, retry and settlement.
- ☐ Setup/recovery instructions and beneficiary evaluation establish recording/retrieval time and practical usefulness. The faster-entry timing test was dropped 2026-11-10, so no time measurement exists yet. Separate implementation, automated checks, live E2E and acceptance evidence; record pre-existing failures separately.

Use commands in `feature-workflow.md`. Each gate names exact files/styles, contracts/errors, schema prerequisites, test expectations and time limit. Documentation-only edits require content/diff validation, not application builds.

## Live E2E environment

Use only the explicitly confirmed user-provisioned disposable `marikina_market_e2e` database; never run migrations or touch operational data. Prior 35-migration/four-role setup is historical, not a current schema guarantee. Recheck prerequisites per slice and reuse valid evidence without repeating unrelated checks. Details: `evidence/local-e2e-database/`.

## Migration exception (approved)

Local monorepo adoption preserved original repositories, history and uncommitted work. Intended remote: `https://github.com/gvillaluz/marikina-market-ticketing.git`; nothing pushed under the recorded exception. See `docs/environment-setup.md`, `docs/environment-verification.md`, `docs/cutover-verification.md`. No product-phase advancement implied.

## Backlog (parked, not approved)

- Noted 2026-11-08 (phone-only fixes closure), not fixed: the saved ticket page on the phone still labels the business address just "ADDRESS"; the server still saves status-change notification text with no control number and a blank business name.
- Existing package/build warnings.
- Criterion-3 closure observations: five retained analyzer infos and Android tooling warnings (AGP 8.11.1 and Kotlin 2.2.20 nearing end of Flutter support). Unrelated to the accepted criterion-3 requirements; retained for a separate approved maintenance decision. See [closure record](docs/criterion-3-closure.md). The vendor-records paging stall was resolved by the mobile vendor-end removal (2026-11-02).

## Deferred work

Mandatory vendor registration/mobile/profile/push/proof-submission completion and old digital-first issuance are removed from active requirements. Existing code, accounts, tests and evidence are preserved; exact retirement/removal actions need their own approved slice. Retained exposed paths still require appropriate checks. Historical vendor evidence: `evidence/phase-2-vendor-notifications/README.md`, `evidence/mobile-device-registration/README.md`, `evidence/mobile-notification-opening/README.md`, `evidence/vendor-profile-v2529-readonly/README.md`. Retained enforcer UI evidence: `evidence/enforcer-notification-slice-4/README.md`, `evidence/profile-camera-slice-5/README.md`; neither is implied complete.

Public vendor lookup, vendor mobile expansion, printing, SMS, bulk imports, custom training, full offline sync/durable drafts, new roles and scanning for another officer remain deferred. Document deletion after approval remains deferred. Infrastructure/architecture expansion and capabilities outside this roadmap require separate approval. No slice is implemented or complete merely because this roadmap changed.
