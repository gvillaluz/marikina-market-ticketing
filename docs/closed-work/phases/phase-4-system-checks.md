# Phase 4 — system checks and live run (line 3), 2026-11-18

The roadmap line: "API build/tests, web build/Node tests and mobile format/analyze/tests pass for affected work; target-device/browser E2E verifies identity, offense rules, edits/re-verification, duplicates/concurrency, persistence, permissions, retry and settlement."

**Status: closed 2026-11-18; the user ticked the roadmap line with the limits below.** The live run changed no application code. Two problems it found were then fixed with the user's approval (see Findings); no schema, package or API contract change. Evidence (local, not committed): `evidence/phase-4-criterion-3-live/` (`expected.md` written before running, `results.md`, screenshots, scripts).

## Automated checks

Latest main (server and website at f9895be, phone at 82c50a7), in a fresh worktree:

| Check | Result |
| --- | --- |
| Server build | 0 errors, 8 existing warnings |
| Server tests | 1000 passed, 0 failed, 2 skipped (opt-in browser tests) |
| Website build | built |
| Website tests | 375 / 375 |
| Phone analyze | no issues |
| Phone tests | 700 / 700 |
| Phone format check | 24 files unformatted, all unchanged since the 2026-10-21 import (pre-existing) |

## Live run

Real disposable server and `marikina_market_e2e`, website in Chrome as Head Admin, phone V2529 as the test enforcer, plus scripted requests to the same server for things a person cannot do by hand (two submits at the same moment, a resend after a lost reply).

| Area | Result |
| --- | --- |
| Identity | Pass. Business found by name with account, owner and stall from the record; violator chosen from the record; unregistered vendor placed on a market street |
| Offense rules | Pass. 1st offense ₱300.00, 2nd offense ₱3,000.00, 3rd offense ₱2,000.00 with permit revocation, "up to ₱1,000" shown as "Unavailable until assessed" until an amount is entered; community service only on a 1st offense, blood donation only when the rule allows it |
| Edits and re-checking | Pass. Back from Review keeps what was typed; a changed place shows on Review; the server re-checks at Submit (Verify was removed on 2026-11-13) |
| Duplicates / concurrency | Pass. Two identical submits at once: one saved, one refused (409) |
| Retry | Pass. A resent ticket is refused (control number used); a resent receipt with the same submission ID still gives one proof |
| Permissions | Pass. Signed out 401; office staff submitting 403; enforcer using the staff status change 403 |
| Settlement | Pass. Receipt and community service hours from the phone, receipts by script; on the website: cash (registered and unregistered) Paid, blood donation Cleared; full community service hours set Cleared automatically (by design); Paid/Cleared not offered before proof |
| Persistence | Pass. Same tickets after a server restart; same statuses on the website and the phone after fresh sign-ins |

## Findings

1. **Fixed 2026-11-18 (user-approved).** A ticket with an empty hidden running number (`control_number`) as the newest ticket made every ticket submit fail (server 500). Seen because demo records added by script on 2026-11-16 left it empty; on the open list since 2026-11-13. During the run it was worked around (ticket 47 given a number temporarily, set back afterwards). Fix: the server now issues the highest whole number already used by a ticket + 1, skipping empty or non-number values (`TicketRepository.GetNewControlNumber`); "highest" rather than "newest" because the number is unique. Test `NextControlNumberTests` (failed before the fix; two deliberate breaks caught).
2. **Fixed 2026-11-18 (user-approved).** The phone's ticket list failed ("Unable to read the ticket list") if any listed ticket had that number empty. The list never shows it, so it is now optional (`ticket_summary_model.dart`, `ticket_summary.dart`). Tests `ticket_missing_hidden_number_test.dart` (3, failed before the fix; deliberate break caught).
   Live check of both fixes (2026-11-18): with a temporary newest ticket that had no hidden number, a scripted submit to the fixed server was saved (201) with number 17 (highest in use + 1); the phone's Pending list loaded with two demo tickets that have no hidden number ("All tickets loaded"). Automated after the fixes: server 1001 passed / 2 skipped / 0 failed, website 375/375, phone analyze clean and 703/703.
3. Not fixed: the website shows code names (`BloodDonation`, `CashFine`) for the penalty type in the ticket parameters.

For the hosted demo database: a read-only check and a guarded repair script, run by the user, are in `evidence/phase-4-criterion-3-live/hosted-demo/` (local, not committed).

## Limits

- Admin Officer not checked (no test account); iPhone not checked.
- Two-at-once, resend and the blood-donation ticket were sent by script to the real server, not from the phone.
- The 3rd-offense check used two temporary earlier tickets in the database (removed afterwards).
- Ticket photos were black (phone face down); receipts and service proof were made-up images.
- About 16 objects went to the locked evidence storage (365 days), including probably 2 from the losing submit with no ticket (known limit) and 2 from the fix check.
- During the fix check, one attempt ran against another session's server that held the same ports; nothing was saved, and the check scripts now refuse to run against a server they did not start.
