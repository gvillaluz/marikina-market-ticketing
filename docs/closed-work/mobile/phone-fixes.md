# Phone-only fixes (COMPLETE 2026-11-08, closed by the user)

Approved scope: `marikina-market-mobile` only; no server, website, database or API contract change. Branch `phone-fixes` (worktree `mmt-phone-fixes`), committed `a118b53`, **PR #6**.

**For the enforcer:**
- **Addresses on the review page.** The business's address is labelled "BUSINESS ADDRESS" (before and after Verify); tickets also show "VIOLATOR ADDRESS" from the confirmed person's record, the same address the copy-to-paper card shows. Warnings show neither.
- **Warning ↔ Ticket.** Switching keeps the chosen person and the typed name; ordinances, fine and penalty are still cleared. The person box also lost its selection whenever the ticket fields appeared above it; it now keeps its state through a key.
- **Notification wording.** Status-change notifications are rebuilt on the phone as "Ticket <number> for <business> is now <status>." (old tickets without a number: "A ticket for ..."). A control number starting `WRN-` marks a warning: "Warning <number> ..." with the title "Warning status updated". Issued tickets and warnings (saved as Pending) keep the server's text. Decision (user, 2026-11-08): show "Warning" rather than "Ticket"; phone-only (the server's notification list does not send the record type).

**Files:** `violator_info_section.dart`, `inspection_form_data.dart`, `add_new_inspection_page.dart`, `new_inspection_preview_page.dart`, `vendor_notification_tile.dart`; tests: new `enforcer_status_notification_text_test.dart` and `violator_info_section_test.dart`, `inspection_preview_navigation_test.dart` changed.

Evidence ([live results](../../../evidence/phone-fixes-live/results.md)): phone 457 passed, analyze no issues, format clean; new tests failed first; deliberate breaks caught (person cleared again, key removed, old address label, server text always, always "Ticket", title unchanged). Live on V2529 against `marikina_market_e2e`: both switch directions keep the person, address labels on the review page before and after Verify and on the copy card, ticket submitted (E2E-PF-0001), old and new status notifications, warning wording; nothing skipped in the final run.

Limits and notes: warning detection relies on the `WRN-` prefix of the control number; the server's notification list does not send the record type. The ordinances-cleared-on-switch rule was not exercised live. Observed, not fixed: the saved ticket page still labels the business address just "ADDRESS"; the server saves status-change notification text with no control number and a blank business name; the server accepts a status change on a warning. Follow-up noted, not approved: the admin end should not offer or accept a status change for warnings (server and website). Completion does not authorize the next slice.
