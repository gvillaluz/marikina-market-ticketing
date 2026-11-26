# Backlog

Parked and deferred work. Nothing here is approved; each item needs its own approval before work starts. Moved word for word from the retired roadmap on 2026-11-26 (full text: [final roadmap](docs/closed-work/phases/final-roadmap.md)).

## Backlog (parked, not approved)

- Noted 2026-11-08 (phone-only fixes closure), not fixed: the saved ticket page on the phone still labels the business address just "ADDRESS"; the server still saves status-change notification text with no control number and a blank business name.
- Existing package/build warnings.
- Criterion-3 closure observations: five retained analyzer infos and Android tooling warnings (AGP 8.11.1 and Kotlin 2.2.20 nearing end of Flutter support). Unrelated to the accepted criterion-3 requirements; retained for a separate approved maintenance decision. See [closure record](docs/criterion-3-closure.md). The vendor-records paging stall was resolved by the mobile vendor-end removal (2026-11-02).

## Deferred work

Mandatory vendor registration/mobile/profile/push/proof-submission completion and old digital-first issuance are removed from active requirements. Existing code, accounts, tests and evidence are preserved; exact retirement/removal actions need their own approved slice. Retained exposed paths still require appropriate checks. Historical vendor evidence: `evidence/phase-2-vendor-notifications/README.md`, `evidence/mobile-device-registration/README.md`, `evidence/mobile-notification-opening/README.md`, `evidence/vendor-profile-v2529-readonly/README.md`. Retained enforcer UI evidence: `evidence/enforcer-notification-slice-4/README.md`, `evidence/profile-camera-slice-5/README.md`; neither is implied complete.

Public vendor lookup, vendor mobile expansion, printing, SMS, bulk imports, custom training, full offline sync/durable drafts, new roles and scanning for another officer remain deferred. Document deletion after approval remains deferred. Infrastructure/architecture expansion and capabilities outside this roadmap require separate approval. No slice is implemented or complete merely because this roadmap changed.

## Open follow-ups (added 2026-11-26)

- Restore from the website: put the restore changes and the backup download fix (#156) on the demo (server first, then website, then the phone app). Before that, check that the demo database login owns the tables (query in `marikina-market-api/MarikinaMarket.API/BACKUPS.md`).
- `recovery-guide.md` still says the website's Restore button is switched off; update it for restore from the website.
