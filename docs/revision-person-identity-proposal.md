# Criterion 3 — updated person-record foundation proposal

**Closure update 2026-10-29:** criterion 3, including this foundation slice, is closed with recorded unrelated limits. The later isolated API suite completed with 632 passes/2 skips; the earlier unfinished API run below is historical. See [criterion-3 closure](criterion-3-closure.md) for the reviewed live evidence and user-approved disposition. Historical “resume here” instructions below do not start additional work.

Updated 2026-10-28. **The reduced API/admin-web registry foundation is implemented and real API/web live checks passed. The user subsequently authorized applying PersonRegistry only to local disposable marikina_market_e2e; that migration passed with existing data preserved. The full API suite still has an unresolved stalled run, so slice closure and criterion 3 remain open.** No package or mobile product code changed. See the [live verification report](../evidence/revision-person-registry-2026-10-28/live-verification.md).

## Resume here

The registry's migration/live verification is finished within its explicit E2E-only exception. Next resolve or explicitly defer the recorded incomplete full API/backup tests before closing the slice. Do not start ticket/person-history integration or another migration without its own approval. The historical proposal below records the original foundation and later boundaries; its “proposed” wording and earlier provisioning restrictions are retained as history, superseded only by the user's specific PersonRegistry execution exception.

The proposed next slice is the API/admin-web person registry only: required name/address, optional phone, admin maintenance, no login accounts or automatic merging. Ticket identity/history integration and the roadmap's scan/system-check/review/edit/re-verify/submit flow remain later scope. Current verification needs the computer/browser and disposable local API/database; V2529 is optional for retained-feature regression now and required for later mobile scanning acceptance. No scheduled follow-up or background work is created by saving this proposal.

## Confirmed ticket workflow

The intended flow is already in the [roadmap](../roadmap.md):

**Scan → system extracts and cross-checks information → enforcer reviews and may edit → Verify → Submit.**

The system identifies candidate business/person matches from the scanned information and returns checked information for enforcer review. A mandatory manual person-picker is not the starting workflow. Enforcers can type or correct names and other editable ticket details. Ambiguous matches remain unresolved; a matching name alone cannot merge people or establish verified history. Exact matching/confidence rules belong to the later scanning gate.

Any edit to verified ticket information clears verification and disables Submit. Show: **“Information changed. Verify again before submitting.”** Verify reruns checks against the changed information; only successful verification enables Submit. Viewing images/history alone does not invalidate verification. Calculated counts/fines remain system-calculated. The server repeats required checks on submission, and Verify alone does not add a final offense to history.

Ticket corrections and registry edits are separate. Editing a paper name does not rename a person, change a business owner, auto-create a person or merge history. The later system check must reassess identity-dependent results when relevant ticket information changes. Registry maintenance remains admin-only.

The original proposal's default manual-selection workflow is superseded. Its [saved copy](../evidence/revision-business-records-2026-10-27/criterion-3-original-proposal.md) is planning history, not the active implementation proposal.

## Confirmed person rules

| Topic | Confirmed rule |
| --- | --- |
| Required information | Name and address; phone is optional |
| Maintenance | HeadAdmin/AdminOfficer create/edit person records |
| Enforcer | Reviews system-returned information and edits ticket details; cannot create/edit registry records |
| Businesses | One individual may appear on tickets at multiple businesses; each earlier ticket retains its original business association |
| Identity | Business, registered owner and violator are distinct; equal names, addresses or phones never automatically merge people |
| Accounts | No person login, UserId, username/password or new owner/employee permission role |
| Paper name | Preserve reviewed NAME/Pangalan separately from confirmed person identity in the later ticket integration |

## Proposed first implementation slice: person registry foundation

User story: an admin can create, find, read and edit independent person records for the later scanning workflow. This foundation supplies records and validated read endpoints; it does not verify scanned tickets yet.

Proposed technical fields, for implementation approval:

| Field | Proposed rule |
| --- | --- |
| id | Server-generated integer internal key, not a new beneficiary document number |
| full_name | Required plain text, maximum 200 characters; not unique |
| address | Required plain address text, maximum 500 characters; no unique name/address constraint |
| phone_number | Optional; blank/whitespace becomes null. Reuse existing business-record PH mobile validation, 09 followed by nine digits; not unique. |
| created_at | Server-owned UTC creation timestamp, preserved on edit |

No date of birth, email, government ID, document image, employment role or permanent person-to-business assignment table is proposed. No automatic person creation from business owners. Same-name records, including identical entered details, may exist separately; the registry cannot assert their identity is equivalent.

Included in the proposed slice:

1. Person entity/table mapping, repository/service/controllers and server validation using existing layering.
2. Admin web registry with search, create, read and edit; loading/empty/error states and failed-save draft retention.
3. Staff read/search endpoints returning candidates for future matching, without auto-confirmation or automatic creation/merging.
4. Builds/tests and real API/browser persistence, authorization and recovery checks against the disposable local database after its reviewed schema is provisioned under approved scope.
5. Schema transition description; migration/designer/snapshot source preparation only if explicitly included in implementation approval. No migration execution is authorized by this proposal. The earlier BusinessRecords execution exception does not extend to this schema.

Existing ticket fields, submission contracts, business-key history/count queries and mobile inspection screens remain unchanged in this reduced first slice. A separate person link and paper-name ticket field are designed below, but actual ticket columns/contracts are deferred until their complete consuming workflow is approved. Do not introduce a mobile person selection that ticket submission silently discards.

## Proposed foundation API contract — not deployed

| Route | Roles | Request / response |
| --- | --- | --- |
| GET /api/persons?search=...&offset=0 | HeadAdmin, AdminOfficer, MarketEnforcer | Existing-style 10-item paging; 200 items, total, has_more; name/address/phone candidate search, without an identity-verification guarantee |
| GET /api/persons/{id} | Same authorized staff | 200 id, full_name, address, optional phone_number, created_at |
| POST /api/admin/persons | HeadAdmin/AdminOfficer | Name/address/optional phone; 201 saved record and Location |
| PUT /api/admin/persons/{id} | HeadAdmin/AdminOfficer | Editable fields; 200 saved record, original ID/CreatedAt retained |

Errors: 400 invalid/missing fields or invalid offset/key; 401 absent/invalid session; 403 disallowed role; 404 missing record; existing generic 500 on unexpected persistence failure. Duplicate names are legitimate, not uniqueness conflicts. No speculative conflict/versioning or general idempotency framework is proposed.

Disable duplicate submissions while a write is pending. A failed write retains the draft. After an uncertain create timeout, check whether it saved before another create; do not silently deduplicate by name or promise exactly-once creation without an approved server retry contract. This recovery limit must be explicit in verification.

The web registry consumes the new API in the same implementation task. No existing endpoint consumed by mobile changes in this foundation. Later shared ticket changes must update every actual web/mobile consumer together.

## Proposed affected files

These are proposed implementation paths, not files edited by this documentation update. Preserve all current uncommitted work.

| Application | Files / areas |
| --- | --- |
| API domain/persistence | New MarikinaMarket.API/Domain/Entities/Person.cs and Infrastructure/Persistence/Configurations/PersonConfiguration.cs; existing Infrastructure/Persistence/AppDbContext.cs |
| API DTOs | New Application/DTOs/Person/Request/SavePersonRequest.cs, PersonSearchRequest.cs, and Person/Response/PersonRecordResponse.cs; reuse existing PageResponse |
| API layers | New Application/Interfaces/Repositories/IPersonRepository.cs, Interfaces/Services/IPersonService.cs, Application/Services/PersonService.cs, Infrastructure/Repositories/PersonRepository.cs, Presentation/Controllers/PersonController.cs and AdminPersonController.cs; existing Program.cs DI |
| API schema/tests | Migration/designer/snapshot source only under approved scope; new MarikinaMarket.Tests/PersonRecordTests.cs and PersonManagementTests.cs |
| React API | New src/api/endpoints/persons.api.ts, persons.api.test.mjs and src/api/types/person.types.ts |
| React feature | New src/features/persons/index.ts; hooks/usePersonsPage.ts and usePersonForm.ts; pages/AdminPersonsPage.tsx; components/PersonRegistry.tsx and PersonFormModal.tsx; validation/hook/UI tests using the existing Node runner |
| React routing | Existing src/routes/AppRoutes.tsx, routePaths.ts and src/components/layout/Sidebar/Sidebar.tsx for an admin-only registry entry |
| React styles | New AdminPersonsPage.module.css, PersonRegistry.module.css and PersonFormModal.module.css alongside their components; existing shared controls/tokens; no dashboard redesign |
| Flutter | No product-code or style changes in this reduced foundation; optional current-build regression check on V2529 only |
| Documentation/evidence | Person proposal, schema instructions and actual test/live evidence under the approved evidence area |

Sequence after implementation approval: API red/green tests and layers → web registry and request/state tests → builds/full relevant checks → real API/browser verification. A required additional shared area/package must be surfaced before edits. No new dependencies are proposed.

## Foundation acceptance

| Scenario | Expected result |
| --- | --- |
| Admin creates name/address without phone | Persists with null phone and no new login account |
| Another person has the same name or identical entered details | Distinct records permitted; no automatic merge or unique-name rejection |
| Admin edits a person | Values persist; ID and CreatedAt unchanged |
| Refresh and fresh sign-in | Same saved records are retrieved |
| Enforcer or anonymous write attempt | 403/401 with no write; authorized read tested separately |
| Invalid required fields or entered phone | Clear errors; no partially saved record |
| Save failure | Draft retained, controls recover, intentional retry and uncertain-create recovery checked |

Passing this foundation does not close all of criterion 3. It provides the registry for later identity/history integration.

## Later ticket/scanning integration — separate gate

Reuse the existing roadmap flow; do not add a duplicate requirement or implement OCR now. Later tickets need a distinct person foreign key and paper_violator_name alongside their original business link. Business owner and person remain independent. Ticket.VendorId currently points to Business and must not silently become a person key. Preserve ticket IDs/evidence/settlement links; do not repeat the prior business reset or infer historical violators from owners.

Current later-integration consumers include [Ticket.cs](../marikina-market-api/MarikinaMarket.API/Domain/Entities/Ticket.cs), [CreateTicketRequest.cs](../marikina-market-api/MarikinaMarket.API/Application/DTOs/Tickets/Request/CreateTicketRequest.cs), TicketService/TicketRepository, [OrdinanceRepository.cs](../marikina-market-api/MarikinaMarket.API/Infrastructure/Repositories/OrdinanceRepository.cs), fine-summary/warning-check and ticket list/detail routes; React ticket types/violator display; and Flutter [save_inspection_params.dart](../marikina-market-mobile/lib/features/tickets/data/models/params/save_inspection_params.dart), inspection state/preview/detail/remote sources. Their exact file/style and contract scope will be gated together.

Resolve before dependent integration: ambiguous/absent identity handling and office handoff, matching/confidence rules, history visibility across enforcers, per-ordinance versus combined offense eligibility, treatment of warnings/contested/cancelled/settled/late records, legacy ticket identity transition and submitted-record identity correction. These do not block standalone registry maintenance, but block claiming verified identity, person-based fines or completed criterion 3.

Future hand-derived example: Person A has one citation at Business X and one at Y; Person B has one at X. Raw person history returns A's two and B's one. This tests association, not which records count toward an offense tier or fine.

## Verification equipment and boundaries

| Verification | What is needed | What it proves |
| --- | --- | --- |
| API/database foundation | Local computer, current API, disposable local marikina_market_e2e with reviewed person schema provisioned under approved scope | Validation, roles, independent records, persistence and no login creation |
| Web foundation | Chrome or Edge on the computer, real web app/API and synthetic admin/enforcer sessions | Admin creation/edit/search, same-name handling, fresh-login persistence and failed-save recovery |
| Optional retained-mobile regression now | V2529, USB connection, unlocked phone and authorized USB debugging; current APK pointed to the local disposable API | Retained enforcer sign-in/business lookup; not person matching or scanning acceptance |
| Later mobile ticket/scanning acceptance | V2529 with working camera, USB debugging, current local-build APK, real disposable API and sanitized completed ticket samples | Scan, system checks/matching, editable review, re-verification and correct saved person/business/paper links |

No additional physical device is required for API/web checks. V2529 is the chosen later mobile target. Obtain separate permission if installation requires uninstalling/clearing app data. Stop task servers/app and remove task-created forwarding afterward. Earlier full Flutter suite/analyzer findings remain recorded; their criterion-1 deferral does not waive later checks.

Later V2529 checks must show:

1. Scan sanitized paper; review system-returned business/owner/person information without a mandatory manual person-picker starting step.
2. Correct a name or editable ticket field without changing registry data. After prior verification, Submit disables and the exact roadmap message appears.
3. Verify again; checks rerun on the edited values and Submit enables only on success. Verify alone adds no final offense. Viewing images/history alone does not invalidate verification.
4. Ambiguous identical names stay flagged, never silently merged or accepted as a new first offense; business owner and violator remain distinct.
5. Submit with server rechecks, then confirm persisted links and web/mobile agreement after refresh/relogin/relaunch. Changed fine/tier requires renewed review.
6. Test unreadable text, correction, failed checks/submission, retry and narrow/keyboard-open/enlarged-text layouts. Mocked responses and screenshots alone are not live acceptance.

## Validation and scope status

The original planning update checked the corrected workflow and kept criterion 3 open. The subsequent approved foundation implementation and actual build/test/browser results are recorded in the linked implementation report. Live API/database verification and full API-suite completion remain outstanding; no migration or device run is claimed.

Future implementation uses existing API solution build/test, web build/all Node tests and mobile format/analyze/test/current APK commands when the corresponding app changes. Record implementation, automated checks and live evidence separately. Registry CRUD alone cannot close scanning verification or all of criterion 3.
