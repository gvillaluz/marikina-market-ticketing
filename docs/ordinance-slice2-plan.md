# Ordinance revision — slice 2: penalty-tier behavior

Status: **CLOSED 2026-11-01** by explicit user approval. Implementation approved 2026-10-31. Migration 20261031112520_OrdinancePenaltyRules was separately authorized and applied only to disposable local marikina_market_e2e with a readable recovery backup and preservation/backfill checks. Final results and accepted limits: see the roadmap's slice 2 closure and [the slice 2 report](../evidence/ordinance-slice2-2026-10-31/report.md).

## User story and confirmed rules

Administrators configure each ordinance's actual offense penalties. Enforcers review the applicable penalty during recording; the API selects and validates the applicable tier using confirmed person/ordinance history. Web and mobile consume the same contract.

- Use offense occurrence and ordinance-defined terms for new penalty configuration, instead of deriving penalty behavior from severity.
- Fixed fines keep their stated value.
- Monetary fines expressly described as “up to X” have minimum 100 and maximum X, inclusive. The minimum does not apply to fixed fines, imprisonment duration or unqualified monetary amounts.
- The recording enforcer enters the actual paper-assessed amount for an UpTo fine. Verify and Submit enforce the same bounds without silently choosing an amount. Fixed fines are not editable by the enforcer.
- Each ordinance has an independent warning-eligibility setting. Existing person-based lifetime warning and same-Manila-day pending-citation restrictions remain.
- Each first-offense tier has independent blood-donation and community-service eligibility settings. Neither alternative is available for second or later offenses. For a multi-ordinance citation, every applicable tier must allow the selected alternative and each must be a first offense.
- Keep Minor/Moderate/High severity on the ordinance only, for compliance scoring and existing severity reporting. Remove severity from active tier configuration. Severity cannot determine fines, warnings or alternative penalties.
- Preserve historical assessed amounts and ticket relationships; new catalog settings must not rewrite old assessments.
- Keep the workbook's conditional, additional-sanction and unspecified wording. “Not stated” and N/A must not become an invented zero fine.
- The workbook catalog replacement remains slice 3; this slice builds the behavior and compatible schema/contracts without importing or reclassifying the 53 provisions.

## Confirmed assessment behavior

The user confirmed that N/A, not-stated, unresolved conditional and later offenses without a confirmed applicable rule must display their terms and block automatic citation assessment until configured. Use an exact configured offense tier; remove the current silent highest-tier fallback. Do not invent zero fines. Warning eligibility remains independent of whether citation assessment is configured.

The user approved keeping scoring severity on the ordinance, not on its tiers. For new tickets, capture the highest selected ordinance severity using the existing ticket severity snapshot. Keep the existing compliance-score formula; do not rewrite historical stored ticket severity or assessed amounts.

## Proposed implementation order and allowed areas

1. Implement the contract below, backend first. The parent coordinates backend/contract and integration; after the contract is fixed, React and Flutter specialists may work on disjoint client paths. A reviewer may inspect the integrated diff without edits. No additional roles or child delegation.
2. API: ordinance/tier entities and persistence configurations, ordinance DTOs/service/repository, affected ticket request/internal/response DTOs, TicketService and repository projections, related service/repository interfaces and controller binding where needed. Update fine-summary/Verify/Submit, stale-review comparison, warning/noncash eligibility and necessary severity serialization. Retain historical stored severity; scoring-formula/risk-policy redesign is excluded. Add meaningful tests in the existing MarikinaMarket.Tests project.
3. Generate the matching schema migration/designer/snapshot. Preserve current catalog IDs, ticket assessments and existing fixed fines. Applying the migration is a separate schema prerequisite, subject to the workspace rules and explicit authorization for that migration.
4. Web: existing src/api ordinance/ticket types and request functions, src/features/ordinances types/constants/utils/editor/list hooks/details/tier/registry components and management tests, plus affected ticket details in src/features/tickets and src/components/ui/TicketModal. Put scoring severity/warning eligibility at ordinance level and fixed/up-to/terms/first-offense controls at tier level. Expected style files: OrdinanceDetailsFields.module.css, PenaltyTierRow.module.css and OrdinancePenaltyTiers.module.css. Any necessary extracted component stays in the existing feature and gets its own CSS Module using existing variables. No global style changes.
5. Mobile: existing lib/features/tickets models/data sources/repository, domain entities/enums/use-case inputs, inspection entry/preview/verification BLoC and widgets, affected ticket/records saved-detail models/widgets, and corresponding tests. Preserve Hive type IDs and existing field IDs; append new fields. Legacy cached data must not fabricate eligibility. Successful catalog refresh supplies the current settings. Style changes stay in affected widgets using existing core/theme values; no theme-file changes, navigation or state-management packages.
6. Review the integrated diff and verify the approved story against the explicitly identified disposable database, staff browser and V2529. Stop owned services after verification.

All three application directories are affected. Update each actual consumer of a changed response in this slice. Adding a general sanctions workflow, automatic closure/revocation/imprisonment enforcement, new permission roles, analytics redesign, vendor-user retirement, or catalog import requires its own scope decision.

## Proposed contract boundary

Keep the existing routes and role checks, using the project's existing JSON naming conventions:

| Route | Request/response change |
| --- | --- |
| GET /api/Ordinance; GET /api/Ordinance/{id} | Ordinance Severity (scoring only) and WarningEligible; revised tier data in detail, with eligibility available to the enforcer catalog. |
| POST /api/Ordinance; PUT /api/Ordinance/{id} | Ordinance Severity and WarningEligible; tiers contain OffenseNumber, FineKind (Fixed, UpTo, Unconfirmed), nullable PenaltyAmount for fixed fines, nullable MaximumFine for UpTo, PenaltyTerms, AllowBloodDonation and AllowCommunityService. Remove tier Severity. |
| POST /api/enforcer/tickets/fine-summary | Return applicable offense, kind, terms, assessed PaymentAmount or null, bounds and independent alternative eligibility. Incomplete assessments have no payable total rather than zero. |
| POST /api/enforcer/tickets/warning-check | Use WarningEligible; retain person/business identity and existing duplicate restrictions. |
| POST /api/enforcer/tickets/verify | Add selected UpTo assessments as OrdinanceId/AssessedAmount pairs. Validate exact tier, bounds, alternative eligibility and current history; return reviewed calculation and scoring severity. |
| POST /api/enforcer/tickets/new-inspection | Add the same assessments to existing multipart submission; repeat server checks and reject stale reviewed calculations. |

The UpTo minimum is server-derived as 100 and exposed to clients; do not trust a client-supplied bound. Reject duplicate/unselected assessment IDs, missing required UpTo amounts and attempted fixed-amount overrides. Reject alternative flags enabled on later tiers. Recheck changed tier, amount/bounds, eligibility and scoring severity during Verify and Submit. Changes require renewed review/verification.

Errors to preserve or define: invalid tier/amount/required-field or unavailable confirmed rule 400 with a useful message; authentication/role 401/403; missing records 404; duplicate or stale reviewed assessment 409. Preserve existing duplicate/person-counting and retry behavior.

## Schema and compatibility proposal

- Add ordinance scoring severity and warning eligibility; add tier fine kind, optional cap/terms and alternative flags in the existing Domain/Entities, Domain/Enums and Infrastructure/Persistence/Configurations areas, with migration/designer/snapshot under Infrastructure/Migrations. Existing monetary tiers migrate as Fixed.
- Initialize ordinance severity from the existing first-offense tier. Missing source classification remains visibly unconfigured and requires an administrator decision before new citation assessment; never guess Minor.
- Preserve existing warning availability by initializing WarningEligible from the former first-tier Minor rule. Initialize first-tier alternative flags from the former non-High eligibility; second/later flags are false under the newly approved first-offense-only policy. These are transitional legacy settings, not workbook-derived eligibility. New flags default false unless explicitly enabled.
- Retire active tier severity after copying the first-offense classification. Do not modify stored ticket severity, assessment, identity or settlement rows. Preserve recovery information and guard rollback where new fine shapes cannot be represented by the old schema.
- New catalog eligibility applies to recording new citations. Do not retroactively reject settlement of already-issued tickets solely because the catalog changed. Existing authorization, proof, idempotency and community-service hour behavior remain.
- Coordinate API/web/mobile deployment; old clients cannot be assumed compatible with removed tier fields and new assessment requirements.
- Live target is only the explicitly identified disposable local marikina_market_e2e. Recheck schema/device prerequisites before E2E. The user applies the migration unless separately authorizing this specific migration once reviewable. No operational database access.

## Acceptance and verification

- A fixed 500 fine stays 500; the new 100 minimum does not convert it to a selectable range.
- For an “up to 1,000” tier, 100 and 1,000 pass; 99.99, 1,000.01 and a missing amount fail. The saved amount matches the entered paper assessment.
- Offense occurrence selects the agreed tier. Missing, conditional and later-occurrence cases follow the confirmed rule and do not fabricate an amount.
- A High ordinance can allow warnings and a Minor ordinance can disallow them. Existing lifetime/same-day conflicts still fail. Each first-tier alternative works only when independently enabled; later offenses and forged requests reject both. Mixed-ordinance tickets require permission from every applicable first tier. This proves severity no longer controls eligibility.
- New ticket scoring uses ordinance severity. Existing stored severities/fines remain unchanged and missing classification cannot silently become Minor.
- An assessment changed after verification requires review/verification again. Final ticket history preserves the actual assessed amount after future catalog edits.
- New request/response shapes work across real API, web and mobile; refresh/fresh sign-in, relevant role denial and an important failure/retry path are observed.
- Meaningful red/green tests first. API: dotnet build MarikinaMarket.slnx --no-restore and dotnet test MarikinaMarket.slnx --no-restore with existing isolated backup-test temporary-root setup. Web: npm run build and all src/**/*.test.mjs files enumerated by rg and passed to node --test. Mobile: dart format changed files, flutter analyze --no-pub, focused tests, flutter test --no-pub, APK build/install and narrow/enlarged-text V2529 checks. Use installed dependencies; do not stop the user's API to release build locks.
- Retain the known vendor-only full-suite stall as a reported limit, never a pass or automatic waiver for slice 2. Five analyzer infos, existing API skips and isolated-host photograph-backed retrieval limits remain inherited observations; do not claim new E2E coverage from historical logs.

Exclusions: catalog import (slice 3), vendor-user/account removal, scoring-formula redesign, OCR, a general conditional-rule engine, automatic imprisonment/closure/license enforcement, new roles/packages, publishing and operational database changes. Conditional terms remain visible text and require an explicitly confirmed monetary rule before automatic assessment.

All business-policy questions and this final scope are approved. Authorization covers only the named implementation and verification work. The separately authorized disposable migration is applied; no operational database or additional migration execution is authorized. No slice 2 completion is established merely by this document.
