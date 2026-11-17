# Phase 2 — revised verification (all three criteria closed 2026-11-17 on a review of the existing evidence)

Closed at the user's request after a read-only review of the evidence on file. Nothing was re-run. Criteria 1 and 2 were closed first; criterion 3 was closed later the same day by the user's decision to accept its limits (below).

## 1. Entry, automatic checks, identity selection, Review, Verify and Submit on the phone

Android V2529, real disposable API, `marikina_market_e2e`:
- Submitted tickets: [A1](../../../evidence/ticket-flow-a1-live/results.md), [phone fixes](../../../evidence/phone-fixes-live/results.md), [scanner](../../../evidence/ticket-flow-a2c-live/results.md).
- Automatic checks and a used control number refused: [automatic checks live](../../../evidence/automatic-checks-live/results.md). Review shows the paper photo, Back keeps what was typed, Verify turns Submit on: [review and Verify live](../../../evidence/review-verify-live/results.md).
- An edit after Verify turns Submit off until Verify again, with the message "Information changed. Verify again before submitting.": live 2026-10-29 to 2026-10-31, rechecked 2026-11-10; list of checks in [submit and Verify again](../scanning/submit-reverify.md).
- Copy-to-paper card and unregistered entry: [A2b live](../../../evidence/ticket-flow-a2b-live/results.md), [B2 live](../../../evidence/slice-b2-live/results.md).
- The Review page has no edit boxes by the user's decision; a mistake is fixed by going Back.

## 2. Calculations, cancellation, duplicates, failed submission and retry

- Calculated fine and offense position on the phone: [fine position live](../../../evidence/fine-position-live/results.md).
- Cancelling the scanner changes nothing: check 4 in the [scanner live results](../../../evidence/ticket-flow-a2c-live/results.md).
- Duplicate and concurrent attempts, and a lost connection followed by one retry: [submit server checks](../scanning/submit-server-checks.md). Lost response on the phone for settlement: [criterion 7 repair report](../../../evidence/criterion-7/repair-report.md).
- "Unreadable images" belonged to the OCR plan, which was dropped (see [OCR dropped](../scanning/ocr-dropped.md)).

## Limits

- Not checked on the phone: Verify and Submit for an unregistered vendor (needs photos; tests only), a 3rd offense, an "up to" fine, iPhone.
- No evidence found for a camera-permission-denied check. The scanner-unavailable fallback ("Take a normal photo instead") is covered by tests only.
- The live checks for duplicates, concurrency and retry date from 2026-10-29 and 2026-10-30, before the faster-entry rebuild of the entry page.
- The phone test `ordinance_shortcuts_test` fails in some full runs and passes alone (see [B2](../faster-entry/b2-unregistered-entry.md)).

## 3. Retained enforcer navigation, profile, notifications and narrow/enlarged-text layouts (closed by user decision with accepted limits)

The user chose on 2026-11-17 to tick this criterion and accept the unverified parts below as limits. They are accepted, not passed; no device check was run for them. What exists: sign-in, profile, lists, logout and re-login live on 2026-10-26 ([live verification](../../../evidence/phase-1-enforcer-summary-current/live-verification.md)); the Notifications tab seen live ([control number part 1](../../../evidence/control-number-part1-live/results.md), [phone fixes](../../../evidence/phone-fixes-live/results.md)); 130% text on the forced-password screen and the largest text on the warning card live ([forced password look](../../../evidence/forced-password-look-phone-live/results.md), [A2b live](../../../evidence/ticket-flow-a2b-live/results.md)). Not verified: the enforcer notification slice, opening from a push notification, device-token registration and real push delivery (all marked implemented/unverified or pending in their evidence folders), the profile camera button on a device, and large text on the entry page and the violator picker.
