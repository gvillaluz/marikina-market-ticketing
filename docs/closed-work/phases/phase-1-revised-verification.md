# Phase 1 — revised verification (closed 2026-11-17 on a review of the existing evidence)

Closed at the user's request after a read-only review of the evidence on file. Nothing was re-run for this closure; no application, test, database or schema change. The review used the revision-phase evidence (Part 1, faster entry, scanning), not the older `phase-1-*` folders, which stay historical (see [Phase 1 historical evidence](phase-1-historical-evidence.md)).

## 1. Enforcer login, business/person lookup, citation/warning recording, evidence retrieval

Live on the real disposable API, the website and the Android phone V2529:
- Business records and person records: [business records live verification](../../../evidence/revision-business-records-2026-10-27/live-verification.md) (2026-10-28), [criterion 3 closure](../../criterion-3-closure.md) (2026-10-29).
- Citation capture with paper reference, photos and issuing enforcer: [paper metadata](../../../evidence/revision-paper-metadata-2026-10-29/verification-report.md), [photo roles](../../../evidence/revision-photo-roles-2026-10-30/verification-report.md); warnings: [warning person](../../../evidence/revision-warning-person-2026-10-30/verification-report.md).
- Find the business and the violator, then submit: [A1 live](../../../evidence/ticket-flow-a1-live/results.md) (2026-11-06), [phone fixes live](../../../evidence/phone-fixes-live/results.md) (ticket E2E-PF-0001), [scanner live](../../../evidence/ticket-flow-a2c-live/results.md) (ticket LIVE-A2C-0001).
- Saved evidence (scan, supporting photos, change history) retrieved on the website: [ticket change history live](../../../evidence/ticket-change-history-live/results.md).

## 2. Offense/fine rules, duplicates, authorization, persistence, retry

- Rules and server checks at Submit: [submit server checks](../scanning/submit-server-checks.md) (earlier live checks 2026-10-29 and 2026-10-30, three new server tests 2026-11-11).
- Two submits at once (one saved, one refused), a lost connection followed by one retry, a faked enforcer number ignored, office staff refused (403), signed out refused (401): same note.
- Duplicate control number refused at Verify on the phone, 2026-11-10: [automatic checks live](../../../evidence/automatic-checks-live/results.md), [review and Verify live](../../../evidence/review-verify-live/results.md).
- Fine position and calculated fine on the phone: [fine position live](../../../evidence/fine-position-live/results.md).

## 3. Settlement without the vendor app

- Cash fine and blood donation: [settlement report](../../../evidence/settlement-slice-report.md) (2026-10-30): the assigned enforcer uploads proof, Head Admin settles cash and Admin Officer settles blood; website, API and phone; status persisted after a fresh sign-in.
- Community service: [community verification report](../../../evidence/community-verification-report.md).
- Retries with durable submission IDs, including a lost response on the phone: [criterion 7 repair report](../../../evidence/criterion-7/repair-report.md).

## Limits

- Admin Officer not checked live on most website checks (no test account).
- iPhone not tested.
- Tests only, no live check: Verify and Submit for an unregistered vendor on the phone, a retry after a lost answer for tickets since the faster-entry rebuild, a 3rd offense and an "up to" fine on the phone.
- The live checks for two submits at once and a lost connection date from 2026-10-29 and 2026-10-30, before unregistered tickets, market streets and the new search.
- Cash settlement for an unregistered vendor's ticket was not checked live (see [B1](../faster-entry/b1-unregistered-tickets.md)).
- Retention-locked photos from a losing submit can stay in evidence storage with no ticket.
- Part 1's full Flutter run stalled in the vendor records paging test after about 450 passes, with no failures; accepted then, and the stall was resolved by the vendor-end removal (2026-11-02).
