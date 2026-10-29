# Criterion 3, slice 2 — progress checkpoint

Updated 2026-10-29 (Asia/Manila). **Criterion 3, including slices 1 and 2, is closed with explicitly accepted unrelated verification limits.** The user authorized closure if remaining checks were unrelated; source/evidence review confirmed the legacy vendor-app paging stall and five analyzer infos do not block the accepted person/identity requirements. [Closure record](criterion-3-closure.md) contains the acceptance decision and deferred limits. Only the criterion-3 roadmap item was closed; no next slice starts.

The checkpoints below are historical. Their open/not-complete wording records the status before the later closure approval; raw incomplete-suite outcomes remain incomplete.

## Latest continuation — 2026-10-29

Latest approved repair: **60 tests across all approved repair files pass**, plus **23 person/Verify/preview regressions**. The outlined-button accessibility defect is corrected; the ten original failures are repaired/reconciled with retained behavior. Explicitly approved additional ticket retry/refresh, startup and profile test repairs are included. Final analyzer reports the same five infos and no new warnings/errors. Debug APK built/installed and scoped real V2529 smoke passed: retained enforcer navigation, control-18 identities, matching/explicit person confirmation/history and incomplete-draft validation. No new submission/upload; all ticket/person/evidence hashes unchanged. Device settings restored, app/API stopped and task reverse mapping removed. Full-suite run reached **451 passes, no reported assertion failures**, then stalled with the legacy records paging case active; it was stopped and is **not a full-suite pass**. No change to that unapproved file. See [repair verification](../evidence/revision-ticket-person-identity-2026-10-29/repair-verification.md). Criterion 3 stays open; no waiver or closure is inferred.

Earlier closure checks: **legacy-null display passed live on web and wireless V2529**, with exact ticket/person hash restoration. The ten-failure red run in the [closure-check report](../evidence/revision-ticket-person-identity-2026-10-29/closure-checks.md) is historical evidence preceding the approved repairs. This supersedes the older missing legacy-client-check status.

See [continuation verification](../evidence/revision-ticket-person-identity-2026-10-29/continuation-verification.md) and its [file-by-file summary](../evidence/revision-ticket-person-identity-2026-10-29/continuation-changed-files.md). The earlier sections below remain a historical checkpoint; their pending results are superseded only by the recorded continuation evidence.

- Read the completed API logs: **632 passed, 2 skipped**, and final focused **42 passed**. API application source unchanged in this continuation.
- Fresh web build and **129 tests passed**. Real HeadAdmin/AdminOfficer browser checks passed detail/modal/list/inspection consumers, persisted history, 1440/768/390 layouts and real synthetic-photo retrieval.
- Found and fixed a real Flutter Submit defect: the save use case dropped person ID, paper name and reviewed calculation. A real-chain multipart regression failed before the fix; **23 focused tests passed** after it. Final analyzer has the same **five informational findings**, no warnings/errors. Debug APK rebuilt and installed with app data preserved.
- V2529 passed explicit same-name confirmation, enforcer person creation, Verify/Submit gating, history viewing, edit/re-verification message, pre-request connection failure with retained review/history-before-retry, successful corrected submission, final-APK relaunch and enlarged-text saved display. Person **8**, ticket **266**, control **18**, **PHP500**, authenticated enforcer **3**; one new retained synthetic dark photo. Final database has 18 tickets: original five real submissions, twelve controlled fixtures, and one device submission. Synthetic fixture numbering was repaired without changing original submitted records or product numbering behavior.
- API live additions passed seven-status/three-penalty coverage, Manila date boundary fixtures, stale calculation rejection, paged/fresh-session history, cross-officer fixture history and legacy-null identity. Controlled fixtures are distinguished from actual issuance/settlement.
- **Full Flutter suite remains unresolved:** continuation run reached 374 passes/10 failures and stalled; post-fix run reached 375 passes/10 failures and was stopped after over 120 seconds without progress. Neither is a pass or an approved waiver. Keep this slice and criterion 3 open until required verification passes or the user explicitly approves a scoped deferral.
- Task API/web/diagnostic services stopped, app stopped, task ADB mappings removed, font scale restored to 1.0, and zero dedicated database sessions (`continuation-cleanup.json`). No migration, package install, commit/push, operational database access or roadmap checkbox change.

The final acceptance matrix and remaining full-suite limitations are in the continuation report. Do not restart historical ticket-creation, migration or reset scripts. Do not start slice 3.

Approved source of scope: [final plan](revision-criterion-3-slice-2-plan.md). Task evidence: `evidence/revision-ticket-person-identity-2026-10-29/`. Preserve all existing uncommitted work; this workspace already contained substantial edits before this slice. `status-before.txt` and `source-before.json` identify the starting state, not a restorable source backup.

## Finalized rules to retain

- “Individual vendor” means the confirmed **person**, not the business or registered owner. Store `PersonId`, existing business `VendorId`, and reviewed `PaperViolatorName` separately. Never merge same-name people or backfill old tickets from an owner.
- Next offense number = earlier submitted citation tickets for **person + ordinance**, counted once per ticket, plus one. Count every status and penalty type across businesses/officers, with no reset. Warnings and Verify do not add citation offenses.
- Duplicate = same person + ordinance + **Asia/Manila calendar day**, where an earlier citation is **Pending or InProgress**. Other statuses do not block, but still count toward the offense number. This is not a rolling 24-hour rule.
- Only active Pending/InProgress **CashFine** tickets contribute outstanding cash. Keep historical assessed amounts. Noncash citations still count as offenses.
- Reviewed name/address/optional phone produce suggestions; the enforcer manually confirms a person. Enforcers can explicitly create a new independent person after reviewing matches, without an admin. Existing record edits remain admin-only.
- Verify writes no final ticket, returns authoritative calculations, and enables Submit. Any ticket-information edit requires another Verify with the message **“Information changed. Verify again before submitting.”** Viewing photos/history alone must not invalidate. Submission rechecks history/calculations/duplicates and uses JWT actor identity.
- Authenticated HeadAdmin/AdminOfficer/MarketEnforcer read paged person citation history across businesses/officers. Legacy unlinked tickets remain explicitly unconfirmed.
- Paper scanning/OCR, backdating/reference rules, warning-policy redesign, settlement/reporting redesign, backup repairs, aliases/merging and new packages/roles remain excluded.

## Approved changes after the final plan

1. V2529 live verification is included. ADB last detected authorized device **V2529**, serial `10AF8U1X9100241`. Preserve installed app data; no uninstall or data clear is authorized.
2. Only additive `TicketPersonIdentity` migration execution was approved for local disposable **marikina_market_e2e**, after target validation and readable recovery backup. It has been applied. This does not authorize another migration or operational database access.
3. User authorized the real evidence bucket. After the existing **365-day compliance lock** was explained, the user approved leaving synthetic test photos there for 365 days. Immediate cleanup is not possible and is no longer promised. Do not alter retention behavior.
4. Additional Flutter display paths approved: `inspection_card.dart` and `form/vendor_summary_banner.dart` within the inspection widgets area.
5. Additional React display path approved: `src/features/inspections/components/InspectionTable.tsx`.

## Implementation so far

| Area | Changes |
| --- | --- |
| API schema | Nullable ticket person ID and paper name, restrictive person FK, history index; migration/designer/snapshot. Existing ticket identity is not guessed or reset. |
| API candidates and permission | Person match request/response, normalized token matching, explicit enforcer create, staff history read. Existing admin edit permission retained. |
| API ticket rules | Person-based citation counting and Manila-day active duplicate checks; Verify and reviewed-calculation comparison; paged person history with historical assessment/outstanding cash distinction; explicit identity fields in ticket/inspection projections. |
| API failure checks | Malformed and stale calculation tests; concurrent collision translated into controlled conflict. Most recent correction rejects high-severity noncash submission before uploading evidence; its red failure was recorded and final build passed, but its final test result must still be read. |
| Flutter data/domain | Typed candidate, verification and history entities/models; repository methods and thin use cases; person/paper/review fields through multipart save and response mappings; distinct person ID in fine calculations. |
| Flutter review | Manual match/confirm/create sheets and person history; Verify/Submit gating; cancelled Verify responses ignored; failure retains review and requires checking history before an uncertain retry; explicit paper/person/owner preview and saved displays. New event/state classes have separate files. |
| Flutter verification fixes | Narrow/enlarged-text preview tests caught an unsafe ancestor lookup during dispose; preview now retains the BLoC reference before disposal. Updated navigation tests exercise manual person confirmation and Verify before Submit. |
| React | Typed identity/history response fields; paged history API/hook/component; explicit identity in ticket modal/detail/list and approved inspection list; raw ticket/warning response logging removed. Scoped ticket detail responsive CSS is being verified. |

No subagents, package installation, commits or pushes were performed for this slice.

## Automated evidence

| Check | Observed result / limit |
| --- | --- |
| API person counting/duplicates/candidates | Initial red recorded; 9 focused tests passed. |
| API identity, verification and model consistency | 40 tests passed, then 42 passed after stale/concurrency cases. Latest high-severity rejection test failed as expected before the correction. |
| API build after latest correction | Passed, 0 errors, 7 existing warnings (`api-build-final.log`). |
| First full API run | 609 passed, 22 failed, 2 skipped (633 total). Backup tests require TEMP/TMP to equal BACKUP_TEST_TEMP_ROOT; this first invocation set only BACKUP_TEST_TEMP_ROOT. Do not describe these as product regressions. |
| Corrected full API run | Started with TEMP/TMP/BACKUP_TEST_TEMP_ROOT pointing to the same isolated task folder. Read `api-full-isolated-tests.log` for final outcome; do not infer a pass. Hang timeout is 120 seconds. |
| Web tests and build | 129 Node tests passed and build passed before the latest approved inspection-list/CSS changes. Repeat affected checks/build after those changes. Existing bundle-size warning remains. |
| Mobile contract/review tests | New contract tests first failed, then passed. Cancelled-review test first failed, then passed. Latest focused set: **22 passed**, including actual preview/navigation at 800/390px, paper preview at 280/400px with enlarged text and all penalty types (`mobile-review-tests.log`). |
| Full mobile run | Reached 362 passes and 22 failures; then stopped after over two minutes without progress. The run was incomplete. Some failures came from the now-fixed preview dispose bug; earlier baseline also had failures/timeouts. Compare actual logs; do not claim all remaining failures are equivalent to baseline. |
| Analyzer/format | Earlier analyzer runs exposed introduced unused imports and test nullability issues, which were corrected. A fresh final analyzer and formatting pass on slice-changed files is still required. Five earlier baseline infos were recorded; do not silently waive new issues. |
| APK/device | First APK build attempt stopped to reduce memory pressure while tests were running. No current APK installation or V2529 acceptance pass is established yet. Run heavy checks sequentially on this 8GB machine. |

## Live evidence actually obtained

The real API ran only against local `marikina_market_e2e`. Before startup: disabled schedules, no expired token cleanup, zero tickets and zero business email addresses. Synthetic staff credentials/OTP fixtures produced real authenticated sessions; email delivery was not tested.

- Enforcer created same-name **person IDs 4 and 5** separately, plus concurrency person **6**. Candidate search for Juan Cruz returned the two distinct Juan Dela Cruz IDs. Enforcer editing an existing registry record was denied; anonymous history read was denied.
- Real citation submissions created **ticket IDs 248–252**, using businesses **1 and 2**. JWT actor overrode submitted enforcer ID 999.
- Verify saved no ticket. An active same-day citation blocked the same person/ordinance at the other business.
- Controlled status fixtures changed only this task's first/second tickets to Paid/Cleared. These are fixture changes, not proof of settlement workflow. Observed offense amounts were independently expected **PHP500 → PHP1000 → PHP1500**, including the noncash second citation in the count.
- Person 4 history returned three records across two businesses; person 5 returned one. Outstanding cash was PHP1500; the old assessed PHP500 remained recorded. Renaming person 4 in the registry retained saved paper name **Juan Cruz**.
- Two concurrent real submissions for person 6 returned **201 and 409**, with one persisted active citation.
- Five saved evidence keys and the synthetic photo hash are recorded in `live-ticket-result.json`; photos remain subject to the user-approved 365-day lock. Check for any upload from a losing/failed submission before calling the storage inventory exhaustive.

`live-ticket-result.json` has `passed:false` because its browser step timed out; its four recorded API checks passed. **Do not rerun `-Mode checks`: it is a creation sequence that requires zero starting tickets.** Use the browser continuation or a new narrowly scoped fixture check.

Browser attempts are preserved. An initial cold-load timeout was followed by a harness navigation error: full page navigation discarded memory-only web authentication. The continuation now navigates through actual Tickets links and Change actions. It rendered explicit identity and person history, but its 390px overflow assertion failed. A scoped responsive CSS correction has been made; final browser rerun, fresh AdminOfficer sign-in and screenshots remain pending. Existing screenshots are evidence of the attempted state, not a completed pass.

Migration evidence: `ticket-person-migration-result.json`. Backup is outside source under LOCALAPPDATA; archive listing succeeded and all existing table checksums were preserved. Never rerun the migration script or the historical business reset.

## Required continuation

1. Read the corrected API full-test outcome and latest mobile review log. Finish final analyzer/format/build and affected regression checks; keep unrelated backup/mobile failures separate.
2. Restart only the isolated current API build after confirming its startup guards. The harness now permits the five manifest-accounted test tickets; do not bypass guards for unknown rows.
3. Finish real browser verification using `Invoke-TicketLive.ps1 -Mode browser`, not `checks`. Verify scoped responsive correction at 1440/768/390px, identity fields, modal/list consumers, history, refresh/fresh sign-in, and inspect screenshots.
4. Complete missing approved API live cases: stale server history after Verify, paged history, same-name separation after reload, active/inactive status/penalty coverage, Manila boundary fixtures and explicit failure/retry evidence. The nine repository tests alone are not live proof.
5. Build debug APK with existing local defines and explicit local API URL; install with data preserved on V2529. No current-device result is implied by ADB detection. Verify manual candidate confirmation/new person, Verify/Submit gating, edits/re-verification, retained failed review, saved person/paper/business/owner meanings, history, relaunch and narrow/keyboard/enlarged-text behavior. Do not photograph sensitive real records.
6. Record known uploaded object keys and retention/cleanup limits. Stop task API/web/app processes and remove task-created ADB forwarding when finished; preserve device data and the synthetic database evidence.
7. Produce a file-by-file change summary, final API contract and an acceptance matrix. Leave the slice **implemented/unverified** if any required evidence remains; request approval before advancing a slice or roadmap phase.

## API contract at this checkpoint

- `POST /api/persons`: enforcer creates `full_name`, `address`, optional `phone_number`; 201 saved record and Location. Existing admin creation/edit endpoints remain.
- `POST /api/persons/matches`: staff send `name`, optional address/phone, offset; response `items/total/has_more` with independent IDs/details/matched fields.
- `GET /api/persons/{id}/tickets?offset=0`: staff read ten-item stable citation history across businesses/officers; includes paper name, business/owner/officer, ordinances, status/date, assessed and outstanding cash.
- `POST /api/enforcer/tickets/fine-summary`: citation body includes existing business `vendor_id` and distinct `person_id`, plus `ordinance_ids`. Counts use person identity.
- `POST /api/enforcer/tickets/verify`: reviewed business/person/paper name, ordinances, description, penalty/hours, evidence count; response `calculation` and `reviewed_calculation`, without final ticket write.
- `POST /api/enforcer/tickets/new-inspection`: multipart existing fields/evidence plus `person_id`, `paper_violator_name`, `reviewed_calculation` for citations. Actor comes from JWT; server rechecks; warning path remains compatible.
- Existing ticket/inspection list/detail responses add nullable `person_id`, `person_full_name`, `paper_violator_name`, `registered_owner_name`.
- Errors: 400 invalid/missing reviewed data; 401/403 auth/role; 404 missing person/business; 409 duplicate, changed calculation or concurrent collision; existing generic 500 for unexpected failures. No new roles or verification-token framework.
