# Criterion 3, slice 2 — final proposed plan

**Closure update 2026-10-29:** this approved slice and criterion 3 are closed against their scoped acceptance evidence, with user-accepted unrelated verification limits. See [closure record](criterion-3-closure.md). The gate text below is historical; it does not authorize later criteria or additional migrations.

Updated 2026-10-29. **The user approved this final reduced scope; implementation and verification are in progress. The slice is not complete.** This gate incorporates enforcer person creation, manual review, Verify/re-verification and the corrected rules below. The user also requested live verification on connected V2529. The previous draft is preserved in evidence/revision-criterion-3-slice-2-planning/plan-before-final.md. Current implementation and evidence: [progress checkpoint](revision-criterion-3-slice-2-progress.md).

## Subsequent user-approved clarifications and path additions

- Live storage: the user first authorized using the real evidence bucket with cleanup. Source inspection then showed citation uploads apply a 365-day compliance retention lock. After that limitation was explained, the user explicitly approved leaving **synthetic test photos** locked in the real bucket for 365 days. This supersedes the cleanup instruction for those photos. Record exact known object keys; do not promise immediate deletion or change operational retention policies. All test application data still uses local disposable `marikina_market_e2e`.
- Additional Flutter files approved: `presentation/inspections/widgets/inspection_card.dart` and `presentation/inspections/widgets/form/vendor_summary_banner.dart`, to distinguish the saved recorded violator from the selected business's registered owner.
- Additional React file approved: `src/features/inspections/components/InspectionTable.tsx`, to show the recorded violator for citations and explicitly label the owner for warnings.
- These additions preserve the confirmed rules below. They do not add OCR, change offense counting, expand enforcer registry-edit permission, authorize operational database access, or close any roadmap criterion.

## Outcome and scope

An enforcer records a citation against a confirmed independent individual vendor/person and the correct business, preserving the reviewed paper name separately. Web/mobile show business, registered owner, recorded violator and confirmed person distinctly. A person's citation history follows their internal person ID across businesses and issuing officers; identical names do not combine people.

Affected apps: marikina-market-api, marikina-market-mobile and marikina-market-web. Backend first, then both consuming clients. Use the existing architecture, dependencies, themes and controls. Preserve all existing uncommitted work.

Paper scanning/OCR is explicitly outside this slice. Use manually entered/reviewed paper details to exercise system candidate checks → enforcer review/correction → Verify → Submit. The later scan-first roadmap remains intact. Do not add a mandatory person-picker starting screen or claim OCR is implemented.

## Confirmed business rules

In these rules, individual vendor means the confirmed person, not the business or registered owner.

| Concern | Rule |
| --- | --- |
| Offense number | Number of previously submitted citation tickets for this person and ordinance + 1. Count all statuses and all penalty types, across businesses/officers. No reset. Count a ticket once per ordinance. Warnings and unsubmitted/Verify state do not add citation offenses. |
| Duplicate ticket | Earlier citation for the same person + same ordinance + same Asia/Manila calendar day, with status Pending or InProgress. Business, officer and penalty type do not change this key. |
| Nonblocking statuses | Paid/settled, Waived, Contested, Overdue, Cleared and every other status do not block a new citation under this duplicate rule. They still contribute to the offense number. |
| Cash fine | Use the offense number to choose the existing ordinance tier. Only CashFine tickets in Pending/InProgress contribute to an outstanding monetary amount. Settled/inactive fines and noncash penalties are not outstanding cash debt. Do not erase historical assessed amounts or add a new balance/reporting feature. |
| Name matching | Suggestions are possible matches, never proof of identity. The enforcer confirms with the available details. No automatic merge, automatic person creation, permanent alias system or invented confidence percentage. |
| New person | After reviewing possible matches, the enforcer can explicitly create a person using required name/address and optional phone, without waiting for an admin. No login account is created. |
| Registry edits | Admins retain edit permission. Enforcers do not gain edit/delete/merge authority over existing person records. Correcting the paper name does not rename a person or owner. |
| Verification | Successful Verify enables Submit. Any edit to verified ticket information clears verification and disables Submit with “Information changed. Verify again before submitting.” Viewing images/history alone does not invalidate verification. Verify saves no final ticket and adds no offense. |

The latest user clarification supersedes the earlier active-only offense-count interpretation. Example: two earlier citations for ordinance X, both settled, still mean offense position 3 for the next citation, although neither blocks it as an active same-day duplicate.

This citation slice uses the existing current-issuance IssuedAt path with Manila calendar boundaries. Backdated/late paper issue-date capture and its historical ordering are deferred to the paper-recording gate. No rolling-24-hour rule will be retained for the new citation duplicate check.

## Implementation

1. Add a separate nullable PersonId and PaperViolatorName to tickets for legacy compatibility; require both for new citations. Retain the existing business key and ticket IDs. Use a restrictive person foreign key and history index, with no data reset, cascade history deletion or guessed owner-to-person backfill. Legacy unlinked identity remains explicitly unconfirmed.
2. Add authorized candidate matching from reviewed name and optional address/phone. Use straightforward normalized name-token matching so Juan Cruz can suggest Juan Dela Cruz, with supporting match information and existing-style pagination. A candidate is not automatically accepted. Keep the current admin registry search compatible.
3. Add explicit enforcer person creation inside review using existing validation/service/persistence. Show candidate matches before intentional creation, disable concurrent clicks and retain fields on failure. Check actual persistence before retrying an uncertain create result. Use existing audit mechanisms for the authenticated action without logging person/contact payloads.
4. Thread person ID and paper name through the actual Flutter form/review state, request parameters, use cases, repository, API submission and saved response. Show business/owner separately. Include candidate, no-match, ambiguous, loading/empty/error states and scoped person-history display.
5. Implement a server Verify endpoint for reviewed identity/business/ordinance and editable citation details. Return authoritative offense positions, calculated amounts and duplicate conflicts, without creating a ticket. Counts/fines remain read-only. Edits invalidate verification; server changes to reviewed counts/amounts at submission require review and verification again.
6. At submission, derive enforcer identity from JWT claims and repeat authorization, person/business validation, required-field/evidence checks, counts and duplicates. Reuse existing serializable transactions for recheck/save consistency. Concurrent same-person/ordinance/day attempts must create at most one new active citation, with a controlled conflict for the loser and no extra offense. Do not silently remove duplicate ordinances or alter the reviewed ticket; report conflicts for correction/re-verification.
7. Return explicit person/paper-name/business/owner fields to all affected actual web/mobile consumers. Keep legacy response fields compatible. Preserve paper spelling independently of later registry-name edits. Existing ticket/inspection list/detail displays must not silently label the owner as a confirmed violator.
8. Proposed history-read permission within this final approval: HeadAdmin/AdminOfficer/MarketEnforcer may read a confirmed person's paged citation history across businesses and issuing officers. No public/vendor-account access to the new route. Ticket-owned service/repository code performs history queries.

Uncertain ticket saves require checking actual persistence before intentional retry. This slice does not introduce a general exactly-once transport/idempotency framework or infer paper-reference uniqueness. Its live retry evidence must state the actual failure scenario tested.

## API contract for approval

| Route | Request and result |
| --- | --- |
| POST /api/persons | Enforcer explicitly creates with full_name/address/optional phone_number. Reuse existing limits: 200/500 characters, optional 11-digit 09 phone. Return 201 saved ID/details/created_at and Location. Admin create/edit routes retain their current restrictions. |
| POST /api/persons/matches | Authenticated staff provide reviewed name and optional address/phone; return paged candidate IDs/details and matched-field information. No save or identity confirmation. |
| GET /api/persons/{id}/tickets?offset=0 | Authenticated staff citation history across businesses/officers. Existing-style items/total/has_more, ten-item pages, stable ordering. Include ticket ID/reference, paper name, business, officer, ordinances, date and status. |
| POST /api/enforcer/tickets/verify | Enforcer-only reviewed person/business/ordinance and citation information. Return validated details, offense positions/calculated amounts and conflicts. No ticket/history write. |
| POST /api/enforcer/tickets/fine-summary | Citation calculations use a distinct person_id. Never repurpose vendor_id, whose meaning remains business. Calculations use total citation count, not active count. |
| POST /api/enforcer/tickets/new-inspection | Extend the citation request with person_id, paper_violator_name and reviewed calculation values for comparison. Keep multipart evidence and existing business key. Return saved explicit identity/details; server recomputes authoritative values. |
| Existing admin/enforcer ticket and inspection list/detail GETs | Add explicit identity/paper-name/owner fields; nullable legacy identity. Update both actual consuming clients in this task and preserve compatible legacy fields. |

Errors: 400 invalid/missing/unconfirmed identity or reviewed inputs; 401/403 authentication/role denial; 404 absent person/business/ticket; 409 duplicate, stale reviewed calculation or transaction conflict; existing generic 500 unexpected failure. A conflict never silently submits a different set of ordinances. No new packages, roles or general verification-token framework.

## Allowed files and areas

Paths below are relative to each application. Only the named feature areas and their necessary tests are included; stop if another shared area is required.

| App | Allowed areas |
| --- | --- |
| API model/schema | Domain/Entities/Ticket.cs; Infrastructure/Persistence/Configurations/TicketConfiguration.cs; new TicketPersonIdentity migration/designer and existing snapshot. Person remains independent. |
| API contracts | Application/DTOs/Person request/response DTOs for candidate matching; Application/DTOs/Tickets/Request/CreateTicketRequest.cs, FineSummaryRequest.cs and new VerifyInspectionRequest.cs; affected ticket/inspection internal and response DTOs, including inherited admin detail. New verification/person-history DTOs within existing structure. |
| API behavior | IPersonService/IPersonRepository and PersonService/PersonRepository for candidates/creation; ITicketService/ITicketRepository and TicketService/TicketRepository for verify/save/history; IOrdinanceRepository/OrdinanceRepository for person counts. PersonController, EnforcerTicketController and AdminTicketController for the agreed actions. Reuse UnitOfWork serializable behavior; no unrelated transaction refactor. |
| API tests | New focused person-candidate, enforcer-create, ticket-person identity/verification/history and access tests; affected issuance, fine/duplicate and detail regression tests. No backup-test edits. |
| Flutter data/domain | features/tickets/data/models/params/save_inspection_params.dart; inspection_remote_data_source.dart; inspection_repository_impl.dart and domain/repositories/inspection_repository.dart; existing save/fine-summary use cases; inspection_form_data.dart; ticket_detail_model.dart, ticket_summary_model.dart, inspection_ticket_summary_model.dart and corresponding entities. New typed candidate/history/verification models/entities/params and single-method use cases within this feature. |
| Flutter presentation | presentation/inspections/bloc/inspection_{bloc,event,state}.dart; add_new_inspection_page.dart; new_inspection_preview_page.dart; form/violator_info_card.dart; preview/violator_info_section.dart; tickets/widgets/violator_detail_section.dart; new person_identity_review.dart, create_person_sheet.dart and person_history_sheet.dart in the existing ticket widgets area. Ticket detail state only where consuming new fields. |
| Flutter wiring/style | lib/core/di/dependency_injection.dart for use-case wiring. Scoped widget styling uses existing theme tokens. Use existing pages/sheets; no new app routes or global theme/router redesign. |
| React | src/api/types/ticket.types.ts and affected admin-vendor inspection types; src/api/endpoints/tickets.api.ts; features/tickets/hooks/useTicketDetails.ts and features/inspections/hooks/useInspectionDetail.ts; TicketList.tsx, TicketDetailPage.tsx and components/ui/TicketModal/modal/TicketViolatorInfoSection.tsx. New ticket-feature PersonTicketHistory.tsx and usePersonTicketHistory.ts. Affected mapping/display/API tests. Remove raw response logging in the changed tickets.api.ts consumer before adding person data. |
| React styles | TicketViolatorInfoSection.module.css, TicketList.module.css, TicketDetailPage.module.css and new PersonTicketHistory.module.css only. Existing components/tokens; no dashboard/reporting redesign. |
| Docs/evidence | This plan, exact schema/contract notes and evidence for the approved slice. Do not change roadmap completion checkboxes without approval. |

All existing uncommitted work must be preserved. No delegation is assumed.

## Schema and runtime prerequisites

Prepare the TicketPersonIdentity migration with only person linkage, paper-name column, restrictive foreign key and history index. Existing rows remain unlinked and preserved. The prior PersonRegistry execution exception is not silently extended. Requested as part of this final plan approval: an explicit exception to apply only this reviewed TicketPersonIdentity migration to local disposable marikina_market_e2e after confirming the target and taking a readable recovery backup. Otherwise the user provisions the schema separately before live E2E. Never use an operational database or rerun the historical business reset.

Before live execution, confirm API/client versions, schema, real evidence-storage target and outbound-notification isolation for ticket creation. Slice-1 person CRUD did not exercise ticket-image storage. Missing prerequisites are reported as small separate tasks, not assumed ready.

V2529 must be connected/unlocked with authorized USB debugging and a current local API build. Installation must preserve app data; ask separately if signing would require uninstall/clearing data. Stop task servers/app and remove task-created forwarding afterward.

## Acceptance and independent expected outcomes

| Scenario | Expected result |
| --- | --- |
| A at Business X and later Y; B at X, even with the same name | A's linked citation history contains two records and B's one. Separate people never merge by name/business. Use different days or a nonblocking earlier status to avoid intentionally violating the same-day rule. |
| Paper name Juan Cruz, confirmed person Juan Dela Cruz | Candidate is suggested without auto-confirmation. Confirmed ticket stores that person ID and preserves Juan Cruz separately. |
| New person during enforcer review | Required name/address, optional phone; explicit create and continued recording without admin wait. No login account; enforcer cannot edit an existing registry person. |
| Two prior ordinance-X citations, both settled | Next offense position is 3. They do not block a new same-day citation as active duplicates. Their recorded amounts/history remain unchanged. |
| Same person/ordinance/day and Pending/InProgress | New citation is a duplicate, even at a different business or from another officer. Other statuses do not block it. A different person or ordinance is independent. |
| Cash versus noncash | All citation penalty types count for offense position. Only active CashFine amounts are outstanding cash debt; noncash or settled tickets do not contribute cash due. Reuse current fine fields; no new reporting feature. |
| Manila midnight | 23:59 and 00:01 are different calendar days despite being two minutes apart. Prior-day active ticket still contributes to offense number but not same-day duplicate blocking. |
| Verify and edit | Verify persists no ticket. Submit stays disabled until success; an edit clears it with the exact message. Viewing images/history does not clear it. Changed server count/fine at submit requires renewed review/verification. |
| Duplicate/concurrent submissions | At most one new active same-day citation per person/ordinance, controlled conflict for the loser, no partial extra history. No silent ordinance removal. |
| Permissions/failure/retry | Server denies unauthorized writes and invalid keys. Failed save retains review state. Check persistence before intentional retry of uncertain results; record the exact tested failure window. |
| Save and refresh/relaunch | Correct person/business/paper links persist and agree across real API, browser and V2529. Admin registry-name edits do not rewrite paper name. |
| Legacy record without person | Explicitly unconfirmed; no owner-to-person guess, data reset or history reassignment. |

Derive exact fine-tier amounts by hand from existing ordinance configuration using total citation count + 1. Record expected history, duplicate outcomes, assessed amounts and cash due separately; do not copy application output into expectations.

## Build, verification and exclusions

Order: API red/green tests and contract/model behavior → Flutter and React against that contract → automated checks → real disposable API/browser/V2529 story. No next slice/phase starts automatically. Stop at a new scope/package/environment blocker; no time limit has been specified by the user.

Commands: dotnet build MarikinaMarket.slnx --no-restore and dotnet test MarikinaMarket.slnx --no-restore; web npm run build and all existing src/**/*.test.mjs through node --test; mobile dart format on changed files, flutter analyze --no-pub, flutter test --no-pub and the existing debug APK build/device run. Read outputs and report pass/fail per acceptance criterion. Retain unrelated backup/full-Flutter limitations separately without silently waiving affected failures or expanding into repairs.

Live checks cover real persistence, refresh/relogin/relaunch, both relevant staff roles, no-match/ambiguous input, person creation, edits/re-verification, status/penalty matrix, same-day and midnight boundaries, concurrent attempts, failure/retry and narrow/keyboard/enlarged-text layouts. Mocked responses and screenshots alone do not establish completion.

Excluded: paper scanning/OCR, automatic aliases or merging, submitted-identity correction, backdated paper-capture rules, new paper-reference/numbering procedures, warning-policy redesign, historical business/owner snapshots, settlement/report/dashboard redesign, durable drafts/full offline sync, new packages/roles, backup repairs and unrelated UI cleanup. Existing warning paths remain compatible; this slice does not claim completed warning integration or the later scanning criteria.

Record implementation, automated checks and live acceptance separately. Close this slice only against its approved criteria/evidence. Report what remains in criterion 3 and later roadmap criteria without starting it.
