# Criterion 4 — recording rules and proposed implementation plan

Updated 2026-10-30 (Asia/Manila).

**Slice 1 completed; slice 2 (paper reference/place) closed on 2026-10-30 with explicit user approval and recorded verification limits.** Criterion 4 remains open; historical snapshots and photo roles require separate gates. Earlier planning/checkpoint text is retained as history; the closure section below is authoritative.

## Resume here in a new session

This plan is the single Criterion 4 planning, status and handoff record. The former separate continuation document was consolidated here after slice 2 was implemented, resumed and closed.

1. Read workspace AGENTS.md, feature-workflow.md, roadmap.md, this plan and each affected application's AGENTS.md. Read the latest closure section before historical checkpoints.
2. Inspect Git status and preserve all changes. Last assistant-created checkpoint commit was c11c5f3 (criteria 1–3); later work is uncommitted unless current Git state proves otherwise. No assistant push was performed.
3. Slices 1 and 2 are closed. Criterion 4 remains open. Next requested work is slice 3 planning for historical business/owner values; its reduced implementation gate has not been approved. Vendor-facing mobile removal is confirmed product direction but requires its own bounded plan/approval.
4. Raw evidence is ignored and machine-local. Never infer a pass from missing artifacts. Slice 2's three-person/two-citation/six-upload caps are exhausted; do not rerun its live writes/uploads without a new gate. Previous wireless V2529 availability must be checked again.
5. Update this document with each approved scope, evidence, remaining limit and next gate. Keep implementation, automated results and real E2E separate. Do not start the next implementation automatically.

Suggested new-session prompt:

> Resume Criterion 4 from docs/criterion-4-plan.md. Read the latest closure/status and current Git state, then prepare the reduced slice 3 plan for approval. Preserve existing work and do not code before its implementation gate is approved.

## Outcome and confirmed rules

An enforcer records a citation with the reviewed printed reference and paper place, confirmed person/business, server-generated issue date/time, ordinance/penalty, issuing enforcer, one photo of the paper and at least one supporting photo. Saved business/owner values remain historically accurate after registry edits. Criterion-3 identity/counting/Verify behavior is retained.

| Decision | User-confirmed rule | Implementation consequence |
| --- | --- | --- |
| D01 paper reference | Printed reference is globally unique by itself. | Global paper-reference uniqueness for citations; no booklet/year component invented. Preserve it as text rather than parsing away leading zeros. |
| D02 issue date/time | Date/time are in the server; place is written on the paper. | Keep server-generated UTC issuance time and current Manila date semantics. No manual issue-date/time input, backdated issuance, late-entry reordering or historical recalculation in this proposal. |
| D03 required reviewed fields | Require both reference and issue place before submission. | Blank/missing/unreadable values cannot be submitted until the enforcer supplies the reviewed value. A selected stall/section must not silently replace the written place. |
| D04 historical field set | Preserve account number, trade name, registered owner name, business type, stall number, market section name and business address as submitted. No invented historical values for legacy rows. | Capture those seven values server-side from the selected business when saving; retain stable business/person IDs separately. Registry edits do not rewrite the saved values. |
| D05 image roles | One paper-ticket photo per citation. At least one supporting photo also required. | Exactly one paper photo and one-or-more supporting photos; reject a submission missing either category. This minimum of two images applies to new citations after the image-role slice, not retroactively to legacy citations. |
| D06 image encoding | Retain current JPEG compression behavior. | “Original image” means the photograph of the paper citation, not an unchanged camera byte stream. Preserve current compression and JPEG validation; do not introduce an archival-original-file pipeline. |

These are the resolved questions for this plan. Proposed technical choices below (wire names, bounds, schema shape and legacy labels) still require the coding gate. They are not additional business rules already approved by the user.

## Existing execution paths and gaps

Paths below are relative to the application named. They were inspected during planning; this is source evidence, not a new runtime test.

| Requirement | Existing path | Gap/action |
| --- | --- | --- |
| Stable ticket identity | API `Domain/Entities/Ticket.cs`: Id, generated ControlNumber; `TicketConfiguration.cs` has a unique control-number index. `TicketRepository.GetNewControlNumber()` parses the last citation control as an integer and increments it. | Preserve IDs and current generated number. Do not put arbitrary paper text into the incrementing ControlNumber path. Propose a separate PaperReference with its own uniqueness constraint. |
| Paper reference/place capture | API `CreateTicketRequest.cs` and `VerifyInspectionRequest.cs` have person/paper-name/business/ordinance/penalty fields, but no printed reference/place. Flutter InspectionFormData/SaveInspectionParams/VerifyInspectionInput and active preview submit chain likewise lack them. | Thread both values through actual form → review → Verify → submit → saved response/read models. Legacy NewTicketSubmitted and warning event/widget declarations contain placeOfApprehension, but no call sites establish those as the active citation save path; do not mistake declarations for persistence. |
| Date/time and duplicate day | `TicketService.CreateTicketAsync` assigns DateTime.UtcNow. `GetPersonFineSummaryAsync`, Verify and save use current time for `GetPersonDuplicatesAsync`; repository converts current day to Asia/Manila boundaries. | Preserve these rules under D02. Do not repurpose IssuedAt or broaden this task into due-date/report/date-filter changes. |
| Person/offense history | `OrdinanceRepository.GetByPersonIdsAsync` counts distinct submitted citation IDs for the person/ordinance across statuses. `TicketRepository.GetPersonHistoryAsync` pages by IssuedAt then Id. | Retain person-keyed counting, independent same-name identities and existing history ordering. Add paper reference to retrieval without confusing paper-reference duplicate detection with same-day person/ordinance duplicate detection. |
| Actor and penalty | EnforcerTicketController overwrites request.EnforcerId from JWT; server computes fine/offense data and compares reviewed calculation. TicketViolation preserves assessed offense/amount; Ticket stores selected penalty/hours. | Keep JWT attribution and noneditable calculated values. No arbitrary officer selection, new roles, paper-penalty discrepancy workflow or settlement change. |
| Historical business/owner values | `TicketRepository.cs` detail/list/history projections read Business/owner through t.Vendor and MarketSection. Create response also uses current selected business values. | Store approved values once on the citation. Current registry data must not be represented as a historical snapshot when no snapshot exists. Preserve PaperViolatorName independently. |
| Upload roles and validation | TicketEvidence has Id/TicketId/FileKey only. `TicketService` validates nonempty JPEGs up to 5 MiB per file and uploads a general list. Detail GET returns presigned URLs as a flat list. | Add persistent paper/supporting roles and stable ordering. Validate actual uploaded categories at save; Verify's declared evidence count alone is not proof of valid uploads. |
| Mobile image processing | `inspection_remote_data_source.dart` compresses every selected file through `core/utils/file_compressor_util.dart` to JPEG quality 80, then sends ticket_evidence_files. Preview/detail/gallery treat photos as one group. | Retain compressor behavior under D06. Form state, delete/replacement, preview, multipart mapping and saved display must preserve each category and count. |
| Web response mapping | API Program uses snake_case JSON. React `src/api/client.ts` converts responses to camelCase; tickets API/types feed actual views. | Add snake_case contract fields and matching camelCase client types; no shared naming-policy rewrite. |

### Actual consumers to keep in sync

- **Flutter capture:** `features/tickets/presentation/inspections/pages/add_new_inspection_page.dart` → InspectionFormData → `new_inspection_preview_page.dart` → inspection event/BLoC → save use case/repository/remote source. Verify uses VerifyInspectionInput/use case and the same remote source. Preserve all new values when any layer reconstructs a request; criterion 3 previously found exactly such a forwarding defect.
- **Flutter saved reads:** `data/data_sources/ticket_remote_data_source.dart` GET `/enforcer/tickets/{id}`; TicketDetailModel/entity → `presentation/pages/ticket_detail_page.dart` → ticket_detail_content, paper header/violator/violation/evidence sections. Inspection/ticket cards and person_history_sheet also expose references/business data.
- **React ticket detail/modal:** `features/tickets/pages/TicketDetailPage.tsx` and `components/ui/TicketModal/TicketModal.tsx` both use useTicketDetails → ticketsApi.getTicketDetailById → `/admin/tickets/{id}`. useTicketModal also exports the rendered paper; changed displayed labels must be exercised there.
- **React entry points:** InspectionsPage, TicketsPage, AdminVendorInspectionPage and EnforcerPerformancePage use the real TicketModal. Their list types/renderers include InspectionTable, TicketList, AdminVendorInspectionHistory and EnforcerInspectionList.
- **React person history:** PersonTicketHistory → usePersonTicketHistory → ticketsApi.getPersonHistory → `/persons/{id}/tickets`.
- **Secondary staff lists:** business inspection history uses `/admin/vendors/{id}/inspections` via adminVendors.api/types; enforcer history uses EnforcerService.GetInspectionHistoryAsync and TicketRepository.GetEnforcerInspectionHistory. Include their mappings if the approved new reference/historical labels are displayed there. They are not vendor-app restoration.
- **Not a new create flow:** React CreateTicketModal has only its own declaration/export in the inspected references; do not build a web citation-creation feature around it. Likewise the inspected TicketRecordModal is not the active InspectionsPage citation modal. useInspectionDetail is also used by WrittenWarningModal; warning behavior is excluded and must remain compatible.

## Proposed schema and compatibility

**Description only. No migration generated or executed in slice 1.** The user must provision approved disposable schema changes separately before later E2E. Existing migration exceptions do not authorize a new migration execution.

| Slice | Proposed persistence |
| --- | --- |
| 2: paper metadata | Nullable legacy-compatible `tickets.paper_reference` (proposed maximum 200 chars) and `tickets.issue_place` (proposed maximum 500). Require reviewed nonblank values for new citations. Unique index over non-null citation paper references, with controlled conflict handling. Trim outer whitespace; preserve leading zeros and literal spelling. These bounds/normalization are proposed technical limits for approval. |
| 3: historical details | Nullable ticket-owned snapshot columns for account number, business name, owner name, business type, stall, section name and composed business address, reusing relevant existing limits. A proposed nullable `business_snapshot` response groups them for consumers; no new person/account/business row is created. Keep stall/address absence explicit rather than inventing content. |
| 4: photo roles | Nullable legacy-compatible evidence role with two values (PaperTicket/Supporting), plus explicit within-role ordering if needed by the existing gallery. Exactly one PaperTicket and at least one Supporting for new citations, enforced transactionally in server validation/save. Existing rows remain unclassified; do not assume the first old image is a paper photo. |

Maintain current IDs, foreign keys and generated ControlNumber values. No reset, guessed paper-reference backfill, owner/person merge, automatic historical snapshot backfill or historical image relabelling. User-facing proposal: show Paper reference separately from System control number; for old records label the missing paper reference/snapshot/image category as unavailable or unclassified. Existing flat response fields remain compatible; new clients use the explicit historical snapshot when available and distinguish current registry values from missing historical values.

Paper-reference uniqueness is separate from the person/ordinance/Manila-day rule. Same reference on any new citation should conflict, even for another business/person; different references do not bypass an active same-day person/ordinance conflict. The database, not only a preflight query, must protect concurrent duplicate reference submissions.

## Proposed API contract

These are proposed additions to existing routes, not a new approved wire contract. No general verification token, workflow flag or speculative versioning layer is proposed. Coordinate required-input rollout with the updated Flutter app; older clients will not satisfy new citation requirements. Nullable read fields preserve legacy records, not old-client creation compatibility.

| Route | Current behavior | Proposed extension |
| --- | --- | --- |
| POST `/api/enforcer/tickets/verify` | Enforcer JSON: vendor_id, person_id, paper_violator_name, ordinance_ids, description, penalty_type, optional community_service_hours, evidence_count. Returns calculation/reviewed_calculation; no final write. | Slice 2 adds paper_reference/issue_place, validates required values and checks printed-reference conflicts. Slice 3 adds a server-read reviewed business snapshot for display/comparison. Slice 4 validates exactly one declared paper photo and at least one declared supporting photo; actual files are revalidated at submit. |
| POST `/api/enforcer/tickets/new-inspection` | Enforcer multipart fields plus generic ticket_evidence_files, person/paper name and reviewed calculation. JWT sets actor. Returns 201 and saved summary/Location. | Slice 2 accepts required paper_reference/issue_place. Slice 3 captures authoritative snapshot from selected business; client snapshot, if used for review comparison, is never accepted as authoritative registry data. Slice 4 proposes one `paper_ticket_photo` file and `supporting_evidence_files` list. Exact file wire names are for gate approval. Keep warning branch unchanged. |
| POST `/api/enforcer/tickets/fine-summary` | Person/ordinance-based provisional counts/fines. | Retain contract and current server-time calculation rules; do not add editable counts or date override. |
| GET `/api/enforcer/tickets/{id}`, `/api/admin/tickets/{id}` | Saved detail, distinct person/paper/owner fields and flat evidence URLs. | Add nullable paper_reference/issue_place; later business_snapshot and typed evidence items containing role/order/presigned URL. Preserve compatible legacy fields; do not expose storage credentials. |
| Existing enforcer/admin ticket and inspection lists | Paged summaries with existing system control/date/business/person fields. | Add paper reference and relevant snapshot display values only where consumed. Preserve paging/filters; add paper-reference search through existing ticket search when implemented. No analytics/report redesign. |
| GET `/api/persons/{id}/tickets?offset=0` | Staff paged citation history across businesses/officers. | Add paper reference and explicit historical business data where shown, preserving person identity/count/order and current limits. |

Use existing structured error mechanisms: **400** missing/invalid metadata or image roles/files; **401/403** authentication/role denial; **404** missing person/business/ticket; **409** existing person/day duplicate, paper-reference collision, stale reviewed calculation or approved snapshot concurrency conflict; retain existing **422** ResourceCreationFailedException handling and generic **500** for unexpected failures. Confirm unique-constraint conversion matches only the intended constraint; do not convert every database error into “duplicate reference.”

For snapshot review, propose that a registry change between Verify and Submit requires renewed review rather than silently saving different displayed business details. Finalize the smallest comparison payload in slice 3's gate, using the existing recheck pattern. It is review consistency, not client authorization proof. Do not change criterion-3 counting or introduce a general signing/token mechanism.

## Proposed implementation sequence — separate gates

### Slice 2: reviewed paper reference and issue place

User story: enter the printed unique reference/place, review them, Verify and submit; retrieve the same values in mobile and staff web. Server date/time remains automatic. Keep existing generic photo handling until slice 4, without claiming criterion 4 complete.

Order: approved schema definition and failing API tests → service/query/contract changes → Flutter real-chain fields/validation/Verify invalidation → affected React read displays/types → automated and disposable API/browser/V2529 verification. Backend first; update actual clients together.

Proposed file inventory for its gate (not current write permission):

- API: `Domain/Entities/Ticket.cs`; `Infrastructure/Persistence/Configurations/TicketConfiguration.cs`; reviewed new PaperCitationMetadata migration/designer and existing snapshot (exact timestamped names at the gate); `Application/DTOs/Tickets/Request/CreateTicketRequest.cs`, `VerifyInspectionRequest.cs`; `Application/DTOs/Tickets/Response/InspectionVerificationResponse.cs`, `TicketDetailResponse.cs`, `PersonTicketHistoryResponse.cs`, `InspectionSummaryResponse.cs`, `TickeSummaryResponse.cs` (existing filename spelling), `AdminInspectionSummaryResponse.cs`, `AdminTicketSummaryResponse.cs`; corresponding internal `InspectionSummary.cs`, `TicketSummary.cs`, `AdminInspectionSummary.cs`, `AdminTicketSummary.cs`; `Application/Interfaces/Repositories/ITicketRepository.cs`; TicketService and TicketRepository. Secondary staff history DTO/mapping additions must be explicitly listed before approval if included; do not silently expand into VendorService/EnforcerService.
- API tests: new `MarikinaMarket.Tests/PaperCitationMetadataTests.cs` (proposed) plus existing `TicketPersonRulesTests.cs` and `AdminTicketDetailTests.cs` only where contract regression changes require them.
- Flutter, under `features/tickets/`: `domain/entities/inspection_form_data.dart`, `verify_inspection_input.dart`, `ticket_detail.dart`, `ticket_summary.dart`, `inspection_ticket_summary.dart`, `person_ticket_history.dart`; `data/models/params/save_inspection_params.dart`, `ticket_detail_model.dart`, `ticket_summary_model.dart`, `inspection_summary_model.dart`, `person_ticket_history_model.dart`; `domain/use_cases/save_inspection_ticket_use_case.dart`; `data/data_sources/inspection_remote_data_source.dart`; `presentation/inspections/bloc/inspection_bloc.dart`, `inspection_event.dart`; `presentation/inspections/pages/add_new_inspection_page.dart`, `new_inspection_preview_page.dart`; new `presentation/inspections/widgets/form/paper_citation_fields.dart` (proposed); `presentation/inspections/widgets/preview/violation_details_section.dart`, `person_history_sheet.dart`, `inspection_card.dart`; `presentation/tickets/widgets/ticket_violation_section.dart`, `ticket_card.dart`; `presentation/widgets/ticket_paper_header.dart`. Existing repository/use-case signatures change only if the agreed params objects do not carry additions without a signature change.
- Flutter tests: existing `test/features/tickets/data/person_identity_contract_test.dart`, `test/features/tickets/presentation/person_verification_flow_test.dart`, `ticket_preview_paper_test.dart`; `test/inspection_preview_navigation_test.dart`; new `test/features/tickets/presentation/paper_citation_fields_test.dart` (proposed).
- React: `src/api/types/ticket.types.ts`, `src/api/endpoints/tickets.api.ts`; `src/features/tickets/pages/TicketDetailPage.tsx`, `components/TicketList.tsx`, `components/PersonTicketHistory.tsx`; `src/components/ui/TicketModal/modal/TicketViolatorInfoSection.tsx`, `TicketViolationDetailsSection.tsx`, `TicketAttachmentHeader.tsx`; `src/features/inspections/components/InspectionTable.tsx`; tests `src/features/tickets/person-history.test.mjs` and proposed `paper-metadata.test.mjs`. Hooks consume the additive typed results; no hook/client refactor unless required and named at the gate.
- Proposed style allowance: Flutter existing AppTheme tokens, no theme changes. React only `TicketDetailPage.module.css`, `PersonTicketHistory.module.css`, `TicketViolatorInfoSection.module.css`, `TicketViolationDetailsSection.module.css`, `TicketAttachmentHeader.module.css` if labels need wrapping/spacing. No global CSS or redesign.

This is an inspected candidate inventory, not a complete permission gate. Validate field propagation in inherited DTOs and the exact secondary-consumer set, finalize migration names, remove unnecessary paths and present the reduced allowlist before coding. No “necessary files anywhere” permission is implied.

### Slice 3: historical business/owner values

User story: a saved citation retains D04's seven values after registry edits; current registry and old citation remain distinct.

Dependencies: slice-2 contract stable; server snapshot and stale-review policy in its own gate. Extend Ticket/configuration/schema, current TicketRepository detail/list/person-history projections and TicketService save/Verify. Carry snapshot through the existing ticket DTOs/read models above. Add the concrete snapshot DTO/model files and exact secondary business/enforcer-history DTO/service/renderer paths before approval; those are an explicit gate dependency, not open write scope. React detail/modal/history and Flutter detail/cards/history need snapshot-first, provenance-aware display. Registry management remains current-state and is not rewritten.

Acceptance: submit synthetic business values A; edit only that disposable business to B through authorized registry APIs; A remains visible on the saved citation while the registry shows B. A newly submitted citation uses B. Legacy records report absent historical data without manufacturing A or relabelling current B as old. Keep the original person's link/paper name and assessed penalties unchanged. Server rejects unauthorized changes and handles a changed reviewed business according to the separately approved stale-review rule.

### Slice 4: one paper photo plus required supporting evidence

User story: the form/review distinctly captures one PaperTicket photo and one-or-more Supporting photos; saved retrieval preserves both roles. JPEG compression stays unchanged.

Dependencies: role wire names/schema and storage prerequisite gate. Extend TicketEvidence/configuration/migration, CreateTicketRequest/VerifyInspectionRequest and save/Verify/detail URL mapping. Proposed mobile paths include the existing form/photo controls, InspectionFormData/SaveInspectionParams/VerifyInspectionInput, inspection events/BLoC, preview/grid/gallery, remote multipart mapping and TicketDetail model/entity/evidence section. New role-specific typed files and exact tests must be enumerated at that gate. Proposed React paths are TicketDetailPage, TicketModal/TicketPhotoEvidenceSection and EvidenceSection plus their CSS Modules and API types; preserve settlement proofs as a separate existing concept. Do not alter the shared compressor just to distinguish roles.

Acceptance: exactly one paper plus one/two supporting photos persists/reloads in correct groups; missing category, second paper upload, empty/invalid/oversized JPEGs are rejected; replace/delete clears verification as appropriate; failed upload retains user review and is checked for persistence before intentional retry. Old unclassified images remain viewable with explicit unknown classification. Use actual presigned retrieval in browser/device evidence. Retention-locked failed uploads cannot be promised immediate deletion.

### Final criterion-4 reconciliation

Reconcile the approved slices, all criterion fields, actual API/browser/V2529 saved record agreement, refresh/relogin/relaunch, role denial, required-image/reference/place validation, history/legacy display, concurrency and failure/retry. Record implementation, automated checks and live results separately. Present closure for user approval; do not automatically start warnings, settlement or OCR.

## Independent acceptance examples for slice 2

These values are synthetic expectations for later tests, not records created during planning:

| Case | Independently expected outcome |
| --- | --- |
| Printed reference `000456` with reviewed place `Fish aisle near stall F-014` | Save and retrieval preserve the reference including zeros and the reviewed place. Internal ID/system control stay separate. |
| Same exact paper reference for another business/person or another day/year | 409; no additional citation/offense. No booklet/year exception under D01. |
| Different paper reference, same person/ordinance/current Manila day with Pending/InProgress citation | Existing person/day duplicate still blocks submission; changing paper reference does not bypass it. |
| Missing reference or whitespace place | Client explains required input; server independently rejects even if UI validation is bypassed. No save/upload side effect from known-invalid metadata. |
| Edit reference/place after Verify | Submit disabled with the existing re-verification message; renewed Verify required. |
| Submit while another request uses the same paper reference | At most one committed citation with that reference; controlled conflict for loser. Storage inventory limitations remain explicit. |
| Existing legacy ticket without paper metadata | It remains retrievable; no guessed reference/place or rewrite of its stored date. |
| Server date/time | Within the independently recorded request interval, UTC stored and existing Manila presentation/day rules retained; no client-supplied issue date accepted. |

## Verification commands and live prerequisites

Slice 1 validation only: local link/source-path existence, decision consistency, Git status/diff and Markdown whitespace. No builds/tests/runtime/device changes are needed to validate a documentation-only task.

For each separately approved coding slice:

- API: failing targeted tests first, then `dotnet build MarikinaMarket.slnx --no-restore` and `dotnet test MarikinaMarket.slnx --no-restore` from `marikina-market-api`. Use the established isolated test setup where required; do not misreport an incomplete run as passed.
- Web: `npm run build`; enumerate `src/**/*.test.mjs` with `rg --files` and pass the files to `node --test` from `marikina-market-web`.
- Mobile: `dart format` on changed files, `flutter analyze --no-pub`, focused real-chain/contract/UI regressions and `flutter test --no-pub`; existing debug APK build with ignored local defines/local API URL. Read counts and report pre-existing warnings/stalls separately. No new test runner/packages.
- **V2529 is required for coding slices**, although not for this planning slice. Verify actual form/review/Verify/Submit, saved detail/history, relaunch, keyboard/narrow/enlarged text and an important real connection/upload failure. Do not replace real device acceptance with mocked tests.
- Use only user-provisioned disposable `marikina_market_e2e`; do not execute migrations, reset its existing evidence or touch operational data. Snapshot existing synthetic records and manifests before writes.
- Existing real storage has a user-approved 365-day retention lock for earlier synthetic uploads. The exact future live gate must identify target, new synthetic image count and retention implications; prior uploads are not a promise of deletability. Stop if prerequisites/permission are missing.
- Start only approved runtime services; preserve installed app data; restore settings/forwarding and stop task runtime after checks. No automatic commit/push.

## Boundaries and remaining gate work

No business-rule question from the three rounds above remains unanswered. Still **proposed technical details** for the next approval: metadata bounds and case-sensitive reference normalization, separate paper-reference/UI labelling versus existing generated control, exact response additions/secondary staff consumers, migration filenames, snapshot comparison format, image-role payload names/ordering and scoped style files. Resolve technical details into an exact reduced allowlist at each coding gate; do not start code from this inventory.

No manual issue-date/backdating feature, OCR/model work, warning policy, vendor app, officer delegation, settlement, global analytics/export redesign, durable drafts/offline sync, generic transport/idempotency framework, package addition, migration execution or unrelated test repair is included. Existing penalty calculation remains authoritative; paper-recorded penalty discrepancy handling remains outside this gate. Existing date/report/settlement dependencies were inspected as risk boundaries, not authorized for refactoring.

Prior criterion-3 deferrals are criterion-specific: the legacy vendor-records Flutter stall, five analyzer infos and Android tooling warnings remain observations and do not silently become criterion-4 passes/waivers. Historical evidence links can be found in [criterion-3 closure](criterion-3-closure.md); ignored raw evidence may be absent in a new checkout.

## Handoff status

- Slice 1 planning approved and mapped; D01–D06 confirmed by user.
- No application/style/schema/runtime/device/package changes in slice 1.
- Next action: review and finalize **slice 2 (paper reference/place)** as the first coding gate. Request approval for its exact contract/files/tests/prerequisites before implementation.
- Slices 3/4 and criterion closure remain proposed and separately gated.

## Slice 2 — reduced approval proposal (2026-10-29)

**Approved by the user; implementation/verification in progress.** This section narrows and supersedes the earlier candidate inventory for slice 2 only. Slices 3/4 remain outside it. The user specifically requested mobile verification; actual V2529 verification below is required, not optional or replaceable by widget tests. The user subsequently authorized execution only against the disposable database; the reviewed metadata migration was applied with a recovery backup and preserved-data checks. No operational database permission was granted.

### Story, contract and schema

Enforcer enters reviewed paper reference and written issue place, sees them in review, verifies, submits and retrieves the same values in mobile and staff web. Editing either field requires Verify again. Server repeats validation/uniqueness checks independently of client gating.

- Add nullable legacy-compatible Ticket.PaperReference (200 characters) and Ticket.IssuePlace (500). Require nonblank trimmed values for new citations, but leave existing rows null; no guessed backfill or reset. Store text literally after trimming outer whitespace, retaining leading zeros/case/punctuation. Proposed uniqueness is exact stored text, case-sensitive, globally across citations/statuses/dates; approval includes this comparison rule. No numeric conversion or booklet/year scope.
- Add a named filtered unique index `ix_tickets_paper_reference` for citation rows with non-null paper_reference. Preflight existence checks give an early 409; only this named unique-index violation is mapped to a controlled paper-reference conflict. Other constraint failures retain their own meaning. Preserve the existing serializable save/recheck pattern.
- Keep ID, generated ControlNumber, current server UTC IssuedAt and Manila duplicate-day/offense/fine rules. UI labels distinguish Paper reference from System control number. A new printed reference cannot bypass a same-person/ordinance/day duplicate.
- POST `/api/enforcer/tickets/verify`: add required citation `paper_reference` and `issue_place`; validate/check duplicate reference without writing. Existing calculation/reviewed_calculation response stays unchanged. No new verification token or server flag.
- Multipart POST `/api/enforcer/tickets/new-inspection`: add those same fields; server revalidates and saves them. Actor remains JWT-derived. Existing 201 summary/Location includes the two nullable metadata values.
- GET `/api/enforcer/tickets/{id}`, `/api/admin/tickets/{id}`, primary enforcer/admin ticket/inspection lists and `/api/persons/{id}/tickets`: add nullable metadata fields, preserving current contracts/paging. Extend existing primary ticket search to paper reference alongside current search fields. Legacy UI says unavailable rather than borrowing the system number/place from registry data.
- Warning input/behavior stays compatible; the new required-field rule applies only to new citations. No new paper-date input, historical snapshots or image-role enforcement in this slice. Existing photo capture/upload/compression stays in place until slice 4; complete criterion-4 photo compliance is not claimed here.
- Errors: 400 invalid/missing/overlong metadata, 401/403 auth/role, 404 absent business/person/ticket, 409 paper-reference/person-day/stale-calculation conflicts; retain existing 422 creation failure and generic 500 handling. No raw database errors or sensitive payload logging.

Prepare/review only the `PaperCitationMetadata` migration, its timestamp-matching designer and `Infrastructure/Migrations/AppDbContextModelSnapshot.cs`. Its generated timestamp is assigned during implementation; its content is limited to the two columns and named index. **Subsequent explicit user exception:** the agent may execute this migration only in disposable `marikina_market_e2e`. Migration `20261029153400_PaperCitationMetadata` was applied under that exception after a readable recovery backup; original ticket values and all other application tables were unchanged. Evidence: `evidence/revision-paper-metadata-2026-10-29/schema-result.json`.

### Allowed files (paths relative to each app)

Permission, if granted, is restricted to the files below and the stated behavior. Listed existing DTOs/model files need edits only where they carry consumed fields; unused files are left alone. Missing additional consumers/files trigger an expanded gate, not automatic scope expansion.

API under `MarikinaMarket.API/`:

- `Domain/Entities/Ticket.cs`.
- `Infrastructure/Persistence/Configurations/TicketConfiguration.cs`; the one PaperCitationMetadata migration/designer and existing model snapshot above.
- `Application/DTOs/Tickets/Request/CreateTicketRequest.cs`, `VerifyInspectionRequest.cs`.
- `Application/DTOs/Tickets/Internal/InspectionSummary.cs`, `TicketSummary.cs`, `AdminInspectionSummary.cs`, `AdminTicketSummary.cs`.
- `Application/DTOs/Tickets/Response/InspectionSummaryResponse.cs`, `TickeSummaryResponse.cs` (existing filename), `AdminInspectionSummaryResponse.cs`, `AdminTicketSummaryResponse.cs`, `TicketDetailResponse.cs`, `PersonTicketHistoryResponse.cs`. AdminTicketDetailResponse inherits the detail additions; no unrelated child/settlement fields change.
- `Application/Interfaces/Repositories/ITicketRepository.cs`, `Application/Services/TicketService.cs`, `Infrastructure/Repositories/TicketRepository.cs`.
- Tests under `MarikinaMarket.Tests/`: proposed new `PaperCitationMetadataTests.cs`; existing `InspectionNotificationTests.cs` for required-field fixtures and real service Verify/save assertions; `TicketPersonRulesTests.cs` and `AdminTicketDetailTests.cs` for affected contract/regression checks. No unrelated backup/auth test repairs.

Flutter under `lib/features/tickets/`:

- `domain/entities/inspection_form_data.dart`, `verify_inspection_input.dart`, `ticket_detail.dart`, `ticket_summary.dart`, `inspection_ticket_summary.dart`, `person_ticket_history.dart`.
- `data/models/params/save_inspection_params.dart`, `ticket_detail_model.dart`, `ticket_summary_model.dart`, `inspection_summary_model.dart`, `person_ticket_history_model.dart`.
- `domain/use_cases/save_inspection_ticket_use_case.dart`; `data/data_sources/inspection_remote_data_source.dart`. Existing parameter objects carry additions; no repository interface/use-case signature redesign.
- `presentation/inspections/bloc/inspection_bloc.dart`, `inspection_event.dart`; `presentation/inspections/pages/add_new_inspection_page.dart`, `new_inspection_preview_page.dart`.
- Proposed new `presentation/inspections/widgets/form/paper_citation_fields.dart`; existing `presentation/inspections/widgets/preview/violation_details_section.dart`, `presentation/inspections/widgets/person_history_sheet.dart`, `inspection_card.dart`.
- `presentation/tickets/widgets/ticket_detail_content.dart`, `ticket_violation_section.dart`, `ticket_card.dart`; `presentation/widgets/ticket_paper_header.dart`.
- Tests: `test/features/tickets/data/person_identity_contract_test.dart`, `inspection_submission_test.dart`; `test/features/tickets/presentation/person_verification_flow_test.dart`, `ticket_preview_paper_test.dart`, `ticket_paper_layout_test.dart`; `test/inspection_preview_navigation_test.dart`, `inspection_creation_ui_test.dart`, `ticket_ui_test.dart`; proposed new `test/features/tickets/presentation/paper_citation_fields_test.dart`. Changes to existing valid-citation fixtures/labels are limited to metadata requirements; no unrelated harness fixes.

React under `src/`:

- `api/types/ticket.types.ts`, `api/endpoints/tickets.api.ts` (only if additive mapping/search contract needs changes).
- `features/tickets/pages/TicketDetailPage.tsx`, `features/tickets/components/TicketList.tsx`, `PersonTicketHistory.tsx`; `features/inspections/components/InspectionTable.tsx`.
- `components/ui/TicketModal/TicketModal.tsx` for its actual system-number header; `components/ui/TicketModal/modal/TicketViolatorInfoSection.tsx`, `TicketViolationDetailsSection.tsx` for metadata rows. The unrelated TicketAttachmentHeader component needs no change for this slice.
- Tests: `features/tickets/person-history.test.mjs`, proposed new `features/tickets/paper-metadata.test.mjs`. Use existing Node test approach; no packages/runner.
- Styles only if wrapping/spacing needs adjustment: `features/tickets/pages/TicketDetailPage.module.css`, `features/tickets/components/PersonTicketHistory.module.css`, `components/ui/TicketModal/TicketModal.module.css`, `components/ui/TicketModal/modal/TicketViolatorInfoSection.module.css`, `TicketViolationDetailsSection.module.css`. Flutter uses existing AppTheme; no global theme/design changes.

Secondary business/enforcer-history rows continue to carry their existing generated system reference and open the same updated detail/modal. Their endpoint contracts/registry labels are unchanged in this reduced slice; no new secondary DTO/service updates or vendor-app work are authorized. The new nullable metadata additions do not repurpose any fields they already consume.

Documentation/evidence: this plan, plus new task artifacts under `evidence/revision-paper-metadata-2026-10-29/`. Preserve historical scripts/results rather than rewriting them. No roadmap completion, commit/push, package change, app-data clearing, data reset or operational database access.

### Build and verification order

1. Record starting Git/source state and prerequisites. Use one agent; preserve all work. Run heavy checks sequentially on this host.
2. API failing tests for required metadata, exact uniqueness/leading zeros, no-write Verify, save/read mapping, no upload for known-invalid metadata and named-constraint conflict. Implement backend contract and reviewed schema definition first.
3. Flutter failing real-chain test proves both values survive form/event/BLoC/use-case/multipart reconstruction; implement fields, required validation, review display, edit/re-Verify behavior and saved read labels. Then update actual React primary list/detail/modal/person-history consumers against the same contract.
4. Run relevant targeted tests, all API build/tests, web build/all existing Node tests, mobile formatting/analyzer/full suite and focused identity/Verify/paper regressions. Build the debug APK with existing ignored local defines/local API URL. Read actual output; record the legacy full-suite stall/five infos/tooling warnings separately. No automatic criterion-4 waiver or unrelated repair.
5. After the user provisions schema, verify with real disposable API, browser and wireless V2529. Expected results are written before running. Check one successful device submission with reference `000456` (or a fresh synthetic prefixed reference if already used), reviewed place, same saved values after relaunch and fresh staff sign-in; compare database persistence and JWT actor independently.
6. On V2529, prove required-field errors, keyboard/narrow/enlarged text, Submit disabled before Verify, enabled after success, and edits to reference/place disabling Submit again. Exercise a real pre-request connection failure with review retained; check persistence/history before intentional retry. This does not claim arbitrary lost-after-commit exactly-once behavior.
7. Verify duplicate reference rejection across distinct synthetic persons/businesses and a real concurrent pair against the unique constraint; also retain the existing different-reference same-person/day denial. Legacy records stay readable with explicit missing metadata. Test rejected unauthorized writes and unchanged original fixture contents.
8. Reconcile results, restore device settings/forwarding, stop task services/app and report per-file changes/API contract/remaining limits. Required affected failures or blocked schema/device evidence mean implemented/unverified; do not mark complete automatically.

Live data/storage scope proposed for this gate: at most three explicitly named synthetic person fixtures, at most two committed new citations (one device save plus one concurrency winner), and at most six synthetic JPEG uploads including any retained concurrent-loser upload. Use existing disposable businesses/ordinances after guarded preflight; never mutate old citations to evade duplicate rules. Each planned successful citation can carry a paper-like synthetic image and supporting image in the current unclassified list, without implementing role handling early. The known real bucket has **365-day retention**; approval of this live scope includes leaving these synthetic images locked for that period. If actual target/schema/state cannot be verified, stop before writes/uploads and request the smallest missing prerequisite. Do not promise bucket-wide cleanup or deletion of retention-locked artifacts.

Acceptance is the slice-2 example matrix above plus actual V2529/API/browser persistence, important failure recovery, permission checks and legacy compatibility. No time limit has been specified. Approval of this section applies to slice 2 only; historical snapshots, required image-role implementation and overall criterion-4 closure remain later gates.

## Slice 2 continuation approval

The user approved finishing the existing slice-2 implementation, affected mobile test corrections, API/web/mobile checks, required V2529/browser/API E2E, and evidence/handoff updates. Existing allowlists, acceptance criteria and live data/upload caps above still apply. No new slice, unrelated repair, package, reset, commit or push is included. V2529 availability was confirmed by the user. Implementation, automated checks and live results remain separately tracked; completion is not yet established.

User-approved scope extension: update only the two citation-header cases (280px/400px) in `marikina-market-mobile/test/records_feature_test.dart` to assert the enforcer paper reference, separate system control and fitting layout. Preserve warning pixel comparisons, all unrelated cases and vendor production code. The obsolete citation pixel-parity failures were introduced by the intended header change; the separate historical paging stall is not covered by this approval.

### Automated verification checkpoint

- API build passed; full suite: 650 passed, 2 existing opt-in live skips, zero failures.
- Web production build passed; all 131 Node tests passed. Existing large-chunk warning remains.
- Flutter focused slice checks: 67 passed. Analysis completed with the same five unchanged informational findings (no new warnings/errors).
- Full Flutter run reached 451 passes and two obsolete citation-header pixel comparisons, then remained active in the previously recorded vendor-record paging test; owned runner stopped at the 300-second limit. Full suite is incomplete, not passed.
- After separately approved header-test updates, all five selected header tests passed (including both citation widths, preserved warning comparisons and existing vendor detail header check). No paging repair or vendor production changes.
- Actual disposable API validation/no-write Verify/401/403/legacy detail checks passed. Synthetic persons 9,10,11 created within the approved cap; ticket count remains 18. Current slice device/browser persistence and concurrency checks remain pending.
- APK build is in progress. Evidence directory: `evidence/revision-paper-metadata-2026-10-29/`. Do not interpret this checkpoint as slice closure or as accepting the full-suite/analyzer limits for criterion 4.

## Latest continuation result — 2026-10-30 (Asia/Manila)

This checkpoint supersedes earlier pending/build/device wording above. Slice 2 implementation and feature-specific live checks passed; **formal slice closure remains pending the user's disposition of the full Flutter suite/analyzer limits**. No slice 3 work, whole-criterion closure, commit or push has started.

- API: build passed; 650 tests passed, 2 existing opt-in skips. Web: build and all 131 Node tests passed.
- Mobile: 67 focused checks passed; 5 selected header checks passed after the separately approved two-case update. APK built and installed preserving data. Full analysis retains the same five infos, no new warnings/errors; the added approved test file analyzes cleanly.
- Full Flutter suite remains incomplete: 451 passes and two obsolete citation pixel comparisons before the 300-second limit, with legacy vendor paging active. Those two introduced comparison failures were corrected with approval and passed targeted checks; no full-suite pass or criterion-4 waiver is claimed.
- Actual V2529 passed required metadata, leading zeros, enlarged text/keyboard, separate generated system number, Verify/Submit gating, independent reference/place edit/re-Verify, retained review/photos after real pre-request failure, history check before deliberate retry, save, cold retrieval, primary search and person history.
- Device citation267/control19 stores reference 000456 and place Synthetic fish aisle F-014 for person9/enforcer3, PHP500, two photos. Concurrent distinct persons returned 201/409 with only citation268/control20 for E2E-METADATA-RACE-0001. Fresh API sessions and actual HeadAdmin/AdminOfficer browser views read exact values; legacy266 remains nullable/readable. Browser detail fits 1440/768/390 and both stored synthetic images loaded.
- Final disposable counts: 20 tickets, 11 persons; original ticket/person/evidence hashes unchanged. Approved caps exhausted: three new synthetic persons, two committed citations and six storage uploads including concurrent loser files. **Do not rerun creation/concurrency** or upload more without a new gate. Original task evidence is Git-ignored and machine-local.
- Cleanup complete: task API/web services/app stopped; device font and notification-banner setting restored; forwarding removed. Installed app data and source work preserved.
- Remaining observations: existing saved mobile date display uses widget-render time; existing web vendor-settlement wording remains. Neither was repaired in this slice. Historical snapshots/photo roles remain later slices.

Evidence and full file-by-file summary: [verification report](../evidence/revision-paper-metadata-2026-10-29/verification-report.md), [changed files](../evidence/revision-paper-metadata-2026-10-29/changed-files.md), [API contract](../evidence/revision-paper-metadata-2026-10-29/api-contract.md). Raw passed logs, screenshots, fixture limits and cleanup proof are in that evidence folder.

Closure decision received: the user explicitly approved closing slice 2 with the recorded limits; see the closure section below. Do not advance automatically.

## Slice 2 closure — 2026-10-30 (Asia/Manila)

**Closed by explicit user approval: “go ahead and close it.”** This closure supersedes the earlier in-progress and closure-pending checkpoints. It closes only Criterion 4 slice 2 (paper reference and issue place), with the limits below; Criterion 4 remains open.

Acceptance passed across API, Flutter and primary staff web consumers: required reviewed reference/place, trimmed literal text with leading zeros, global exact case-sensitive citation-reference uniqueness, separate generated system control, edit/re-Verify gating, saved values after cold retrieval/fresh sign-in, legacy null labels, permission checks, same-person/day protection, real concurrent 201/409 and retained review/history-check/intentional retry after a real pre-request connection failure. Actual wireless V2529 and staff browser evidence passed. No general lost-after-commit exactly-once claim is made.

Verification: API build and 650 tests passed (2 existing opt-in skips); web build and 131 tests passed; mobile 67 focused checks plus 5 selected header checks passed; APK built/installed preserving data. Full Flutter suite remains incomplete after 451 passes and two obsolete header parity failures, followed by the legacy vendor-record paging stall. The two introduced header failures were repaired with explicit approval and passed targeted checks. Full-suite success is not claimed.

Accepted limits for this slice only: the remaining paging case belongs to the vendor-facing mobile Records screen, using a vendor session and vendor endpoints, not the enforcer citation/person-history flow. The user confirmed there will be no vendor-facing mobile application and directed its removal. Its dependency mapping, removal plan and implementation require a separate bounded approval gate; no removal was performed to obtain this closure. The same five unchanged analyzer infos (notification withOpacity, generic Type naming, empty LookupBloc constructor, splash dependency declaration and photo-helper braces) remain recorded, with no new warnings/errors. This is not a system-wide readiness waiver.

Disposable-only verification ended with tickets267/268, controls19/20 and persons9–11; original fixture hashes match. Three-person/two-citation/six-upload caps are exhausted, including retention-locked concurrent-loser uploads. Do not rerun live creation/upload scripts without a new gate. Device settings/forwarding were restored, task app/API/web services stopped, and no commit/push made.

Evidence: [verification report](../evidence/revision-paper-metadata-2026-10-29/verification-report.md), [file changes](../evidence/revision-paper-metadata-2026-10-29/changed-files.md), [API contract](../evidence/revision-paper-metadata-2026-10-29/api-contract.md). Raw evidence is Git-ignored and machine-local; these documents preserve the durable decision and limits.

Remaining Criterion 4 work: separately gated historical business/owner snapshots (slice 3), explicit paper/supporting photo roles (slice 4), and final criterion reconciliation. Existing mobile saved-date rendering and vendor-settlement wording remain observations. No next slice or vendor-removal implementation starts automatically.
