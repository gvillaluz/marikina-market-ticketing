# Business records revision — implementation and user-operated transition

Scope approved in this chat on 2026-10-27: Revision Phase, first business-record criterion, including the Business/Businesses rename, owner details without login accounts, and removal of existing vendor accounts/profiles and their linked tickets/history. Migration source and snapshot preparation were separately approved. On 2026-10-28, the user explicitly authorized agent execution against the disposable local database only.

Status: business-record criterion 1 closed on 2026-10-28 after real web/API and V2529 acceptance. Criterion 2's business rename is also closed on 2026-10-28 after the user approved reconciling its wording with the existing implementation and evidence. Separate individual/person records remain unfinished under criterion 3; other criteria and the phase remain open. The recorded full Flutter suite failures/timeouts and analyzer findings remain explicitly documented; the user deferred them for criterion 1 closure, and this documentation review does not turn them into passes. The migration and approved cleanup were applied to the disposable local marikina_market_e2e database on 2026-10-28. No operational database was accessed. See evidence/revision-business-records-2026-10-27/live-verification.md and criterion-2-review.md for the separate acceptance and reconciliation evidence.

## Confirmed rules

- The official business account number comes from the business license and is unique. It is text, preserving leading zeros. Outer whitespace is trimmed; uniqueness is case-insensitive, including concurrent saves.
- Only HeadAdmin and AdminOfficer create/edit business records. Business owners and businesses do not have login accounts.
- Required: business account number, business name, owner's first/last names, house number, street, barangay, city, business type and active market section.
- Phone and email are optional contact details, without passwords, credentials or account creation.
- BusinessType is Public or Private. Stall number is required for Public and optional for Private. Changing type does not discard an optionally entered stall number.
- Person identity, offense counting, OCR, revised citation capture and settlement redesign are separate slices and are not completed here.

## Criterion 2 reconciliation

The user approved a documentation-only review of the existing Business/Businesses rename. The original criterion combined that implemented rename with unfinished individual/person identity work and an earlier preservation policy. Its revised scope closes the rename, relationship/client updates, retained business metadata and documented schema transition. The separate individual/person record requirement is retained, unchecked, alongside paper violator identity and offense ownership under criterion 3. Independent owner fields on Business do not constitute a person registry.

The former requirement to preserve old vendor IDs, account links and ticket history was superseded by the user's explicit approval to delete old vendor accounts/profiles and their linked tickets/history. New business IDs were generated after the reset; no transfer of old row values is claimed. The migration execution was separately authorized for the disposable local database. No additional migration, database access or application change was needed for this reconciliation.

Source mappings, transition evidence, updated contracts and existing live web/API/V2529 results support the rename closure. Legacy `VendorId`/`vendor_id` relationship names and some Vendor-prefixed DTO/service names remain compatibility names targeting Business; closing criterion 2 does not claim a system-wide removal of the word vendor or completion of person-based citation/history work. See [criterion 2 assessment](../evidence/revision-business-records-2026-10-27/criterion-2-review.md).

## Field-by-field transition

The user explicitly chose to delete old records instead of transferring old profile/user data. The schema keeps applicable business fields; this reset does not preserve old row values or ticket history.

| Old VendorProfile field | Business field / treatment |
| --- | --- |
| Id | Id; internal integer key, generated for new records |
| UserId / User | Removed; no business-to-user relationship |
| BusinessId | BusinessAccountNumber; required text, maximum 20 characters |
| BusinessName | BusinessName; maximum 100 characters |
| MarketSectionId / MarketSection | Retained relationship |
| Type (VendorType) | Type (BusinessType); Public/Private values retained |
| StallNumber | Retained, maximum 20 characters; server enforces Public requirement |
| Status | Retained Active/Inactive business status; not login permission |
| RegisteredAt | CreatedAt; server-owned UTC creation timestamp |
| QrCodeValue | Retained business metadata; generated for new records, preserved on edit |
| ComplianceScore / ScoreUpdatedAt | Retained for existing reporting compatibility; preserved by record edits. Existing score refresh remains; no new person/offense policy is implied |
| Tickets | Relationship now targets Business; old rows are deleted by the approved user-operated reset |
| Owner fields formerly read from User | Independent OwnerFirstName, OwnerLastName, HouseNumber, Street, Barangay, City, optional PhoneNumber and Email |

The C# entity/DbSet names are Business/Businesses. The PostgreSQL table is `businesses`, following existing database naming. Existing ticket/notification `vendor_id` references remain legacy contract names for the business record until the separately approved person/citation work; they no longer reference a login profile.

## API contract

All new business routes require HeadAdmin or AdminOfficer.

| Route | Result |
| --- | --- |
| GET /api/admin/businesses?offset=0&search=...&market_section_id=... | 200: items, total, has_more; 10 records per page |
| GET /api/admin/businesses/{id} | 200: complete business record |
| POST /api/admin/businesses | 201: saved record and Location header |
| PUT /api/admin/businesses/{id} | 200: updated record; internal ID and metadata remain server-owned |

Synthetic create/edit request (snake_case is the established wire format):

```json
{
  "business_account_number": "0001842",
  "business_name": "Reyes Fish Store",
  "owner_first_name": "Juan",
  "owner_last_name": "Reyes",
  "house_number": "12",
  "street": "J. P. Rizal",
  "barangay": "Sta. Elena",
  "city": "Marikina City",
  "phone_number": null,
  "email": null,
  "market_section_id": 1,
  "business_type": "Public",
  "stall_number": "F-12"
}
```

Response: request fields plus id, market_section_name, created_at and status. No user ID, password, username or login role is created/returned by these routes.

Errors: 400 invalid/missing fields, invalid/inactive section, missing Public stall or duplicate account number; 401 missing/invalid authentication; 403 non-admin role; 404 missing business; 409 concurrent transaction conflict; 500 unexpected persistence failure with the existing generic response. Both raw and normalized account-number unique constraints must map a race to the duplicate message. No new package or idempotency framework is introduced.

Affected existing contracts rename business_id to business_account_number and vendor_type to business_type where that property exists. The admin business-owner profile now exposes business_account_number, business_name and created_at instead of pretending the owner has a username, account creation date or role. Web and mobile consumers are updated together. Legacy vendor account registration/approval is rejected, mobile vendor sign-in and refresh cannot issue tokens, and the API rejects existing MarketVendor bearer sessions. Registration pages explain that records are managed by the market office.

## Migration applied to the disposable local database

Source: `marikina-market-api/MarikinaMarket.API/Infrastructure/Migrations/20261027142714_BusinessRecords.cs`, its designer and the updated AppDbContextModelSnapshot.

The generated source was reviewed and amended to implement the approved reset:

1. Refuse any database name except `marikina_market_e2e`.
2. Select user IDs linked to old profiles or assigned MarketVendor. Refuse the reset if any selected user also has a staff role.
3. Delete notifications, service logs, evidence metadata and violation rows for vendor-linked tickets before deleting those tickets.
4. Delete old profile rows and selected vendor refresh/device/OTP/Identity records, then selected users. Do not delete staff roles/accounts, ordinances or sections.
5. Replace vendor_profiles with the empty businesses table, add independent owner fields and normalized unique protection, and reconnect the ticket/notification foreign keys.
6. Rename the retained legacy registration-request business identifier column to business_account_number.

The operation is irreversible through Down; rollback requires a user-managed backup. No data is inserted into businesses. Existing registration-request archives and external stored files are not purged by this migration: the named reset removes database profile/account/ticket data and evidence references. Any further archive/object-storage deletion requires its own decision. Unexpected foreign-key dependencies should stop the user-operated transition; do not add a broad cascade or delete unrelated data to bypass them.

Source generation used installed EF tooling with a temporary offline design factory; that factory was removed afterward. After explicit execution authorization on 2026-10-28, the current build generated a single-migration transactional SQL script. A local custom-format recovery backup was created and its archive listing checked before applying the script. Post-checks confirmed migration history, an empty businesses table, removal of two vendor users/profiles, and unchanged fingerprints for staff accounts, sections and ordinances. There were zero tickets before and after. See evidence/revision-business-records-2026-10-27/migration-result.json for target, backup location and checks. The schema check alone does not establish live completion; the subsequent real client verification is recorded separately in live-verification.md.

## Verification and manual acceptance

See `evidence/revision-business-records-2026-10-27/` for actual outputs. Implementation, automated results, browser fixture checks and live evidence are reported separately there. Old success tests for vendor account workflows were updated to assert account-independent boundaries or account-creation rejection; passing staff behaviors remain covered. They are not evidence that the retired vendor workflow is still supported.

The disposable local transition and scoped live acceptance have passed. The sequence below remains a manual review checklist; detailed actual results and approved Flutter limitations are in live-verification.md:

1. Record the staff-account/ordinance/section baseline and verify it remains unchanged by cleanup. Confirm old vendor accounts/profiles and vendor-linked ticket history are removed and businesses starts empty.
2. Log in as each admin role. Create a Public business with a leading-zero license number; omitting Stall Number must fail without saving. Add the stall and save.
3. Create a Private business without stall, phone or email. Confirm no user, login role or credentials are created for either business.
4. Refresh/relogin and retrieve both records. Edit owner/address/name fields; the business ID, CreatedAt and QR metadata must remain unchanged by that edit.
5. Submit exact, whitespace and case variants of an existing account number. They must be rejected. Submit two simultaneous creates of the same number: at most one business may persist; the other request must return a handled duplicate/conflict response.
6. Search by business name, account number, owner and stall. Verify distinct business/owner columns. Confirm affected mobile lookup/detail fields read the renamed contracts.
7. Attempt create/edit through a MarketEnforcer token and without authentication: expect 403/401 and no write. Former vendor credentials or bearer/refresh tokens must not grant access.
8. Stop or disconnect the API during a save attempt. The form must retain inputs and show an error. Restore it, inspect whether the record exists, then retry without creating a duplicate.

The recorded acceptance checks passed on web/API and V2529 for criterion 1, with the explicitly approved full Flutter suite/analyzer deferral. Criterion 2's business rename is separately closed through the approved documentation/evidence reconciliation above. Criterion 3's individual/person records and identity rules remain open. No phase advancement is claimed.


