-- Read-only count of tickets whose status does not fit their Penalty Type (issue #161).
-- Changes no data: the transaction is READ ONLY, so PostgreSQL refuses any write inside it.
-- Expected output: one row per wrong case that exists. No rows means nothing needs correcting.
BEGIN TRANSACTION READ ONLY;

SELECT penalty_type, status, COUNT(*) AS tickets
FROM tickets
WHERE type = 'Ticket'
  AND (
        (penalty_type = 'CashFine' AND status IN ('Cleared', 'InProgress'))
     OR (penalty_type = 'BloodDonation' AND status IN ('Paid', 'InProgress'))
     OR (penalty_type = 'CommunityService' AND status = 'Paid')
  )
GROUP BY penalty_type, status
ORDER BY penalty_type, status;

ROLLBACK;
