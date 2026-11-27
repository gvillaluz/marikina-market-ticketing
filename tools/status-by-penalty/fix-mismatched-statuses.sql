-- One-time correction of tickets whose status does not fit their Penalty Type (issue #161).
-- Run by the user only, after the count query (count-mismatched-statuses.sql) found rows.
-- Changes only the status (and, for tickets sent back to Pending, the settled-on date) of the wrong tickets.
-- Never touches warnings or any other ticket, and sends no alerts. All or nothing: one transaction.
BEGIN;

-- Before: the wrong tickets, by penalty and status.
SELECT 'before' AS step, penalty_type, status, COUNT(*) AS tickets
FROM tickets
WHERE type = 'Ticket'
  AND ((penalty_type = 'CashFine' AND status IN ('Cleared', 'InProgress'))
    OR (penalty_type = 'BloodDonation' AND status IN ('Paid', 'InProgress'))
    OR (penalty_type = 'CommunityService' AND status = 'Paid'))
GROUP BY penalty_type, status
ORDER BY penalty_type, status;

-- Cash Fine marked Cleared becomes Paid; settled-on date kept.
UPDATE tickets SET status = 'Paid'
WHERE type = 'Ticket' AND penalty_type = 'CashFine' AND status = 'Cleared';

-- Blood Donation or Community Service marked Paid becomes Cleared; settled-on date kept.
UPDATE tickets SET status = 'Cleared'
WHERE type = 'Ticket' AND penalty_type IN ('BloodDonation', 'CommunityService') AND status = 'Paid';

-- Cash Fine or Blood Donation marked In Progress goes back to Pending; settled-on date cleared.
UPDATE tickets SET status = 'Pending', resolved_at = NULL
WHERE type = 'Ticket' AND penalty_type IN ('CashFine', 'BloodDonation') AND status = 'InProgress';

-- After: should be no rows.
SELECT 'after' AS step, penalty_type, status, COUNT(*) AS tickets
FROM tickets
WHERE type = 'Ticket'
  AND ((penalty_type = 'CashFine' AND status IN ('Cleared', 'InProgress'))
    OR (penalty_type = 'BloodDonation' AND status IN ('Paid', 'InProgress'))
    OR (penalty_type = 'CommunityService' AND status = 'Paid'))
GROUP BY penalty_type, status
ORDER BY penalty_type, status;

COMMIT;
