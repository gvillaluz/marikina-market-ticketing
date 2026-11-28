-- One-time correction: give tickets issued before the Severity Level their level (issue #166, ADR 0001).
-- Run by the user only, on the disposable marikina_market_e2e database, after apply-severity-level.sql.
-- A ticket's level is the highest level among its violations, each worked out from its offence rule the same way
-- the server does (OrdinancePenaltyTier.SeverityLevelOf). If any violation's rule has no level, the ticket stays
-- empty, as a new ticket would. Only tickets with an empty level change; warnings are never touched.
-- Business scores change on the next daily update. All or nothing: one transaction.
BEGIN;

-- Before: tickets by level (empty = no level yet).
SELECT 'before' AS step, severity_level, COUNT(*) AS tickets
FROM tickets WHERE type = 'Ticket' GROUP BY severity_level ORDER BY severity_level NULLS FIRST;

WITH violation_level AS (
    SELECT violation.ticket_id,
        CASE tier.additional_penalty
            WHEN 'Imprisonment' THEN 5
            WHEN 'ClosureRevocation' THEN 4
            WHEN 'ConfiscationSuspensionImpounding' THEN 3
            ELSE CASE
                WHEN tier.fine_kind = 'Fixed' AND tier.penalty_amount IS NOT NULL
                    THEN CASE WHEN tier.penalty_amount > 1000 THEN 2 ELSE 1 END
                WHEN tier.fine_kind = 'UpTo' AND tier.maximum_fine IS NOT NULL
                    THEN CASE WHEN tier.maximum_fine > 1000 THEN 2 ELSE 1 END
            END
        END AS level
    FROM ticket_violations violation
    LEFT JOIN ordinance_penalty_tiers tier
        ON tier.ordinance_id = violation.ordinance_id AND tier.offense_number = violation.offense_count
),
ticket_level AS (
    SELECT ticket_id, MAX(level) AS level
    FROM violation_level
    GROUP BY ticket_id
    HAVING COUNT(level) = COUNT(*) -- every violation has a level
)
UPDATE tickets SET severity_level = ticket_level.level
FROM ticket_level
WHERE tickets.id = ticket_level.ticket_id AND tickets.type = 'Ticket' AND tickets.severity_level IS NULL;

-- After: tickets by level. Any still empty have a violation whose rule has no level; they count as Level 1 in the score.
SELECT 'after' AS step, severity_level, COUNT(*) AS tickets
FROM tickets WHERE type = 'Ticket' GROUP BY severity_level ORDER BY severity_level NULLS FIRST;

COMMIT;
