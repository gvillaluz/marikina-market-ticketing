-- Severity Level from the Market Code, server step (issue #164, ADR 0001).
-- Run by the user only, on the disposable marikina_market_e2e database. Same changes as the EF migration
-- 20261128090000_SeverityLevel; the label block is produced by SeverityLevelLabelData.BuildLabelSql().
-- Adds the Additional Penalty to every offence rule (None unless listed) and an empty Severity Level to tickets,
-- then labels the 36 offence rules of Ordinance 011, Series 2014 that the user approved on 2026-11-28.
-- Old tickets keep an empty level until the later correction script. All or nothing: one transaction.
BEGIN;

ALTER TABLE ordinance_penalty_tiers ADD COLUMN additional_penalty text NOT NULL DEFAULT 'None';
ALTER TABLE tickets ADD COLUMN severity_level integer NULL;

DO $$
DECLARE labelled integer;
BEGIN
    UPDATE ordinance_penalty_tiers tier SET additional_penalty = label.additional_penalty
    FROM ordinances ordinance, (VALUES
        ('15', 2, 'ClosureRevocation'),
        ('30', 3, 'ClosureRevocation'),
        ('31', 3, 'ClosureRevocation'),
        ('37', 1, 'ConfiscationSuspensionImpounding'),
        ('40', 1, 'ConfiscationSuspensionImpounding'),
        ('40', 2, 'ConfiscationSuspensionImpounding'),
        ('40', 3, 'ConfiscationSuspensionImpounding'),
        ('41', 1, 'ClosureRevocation'),
        ('44', 1, 'ClosureRevocation'),
        ('44', 2, 'ClosureRevocation'),
        ('44', 3, 'ClosureRevocation'),
        ('45', 1, 'ConfiscationSuspensionImpounding'),
        ('45', 2, 'ConfiscationSuspensionImpounding'),
        ('45', 3, 'ConfiscationSuspensionImpounding'),
        ('48', 2, 'ClosureRevocation'),
        ('52', 1, 'ConfiscationSuspensionImpounding'),
        ('52', 2, 'ConfiscationSuspensionImpounding'),
        ('52', 3, 'ConfiscationSuspensionImpounding'),
        ('54', 2, 'ConfiscationSuspensionImpounding'),
        ('54', 3, 'Imprisonment'),
        ('57', 3, 'ClosureRevocation'),
        ('60', 1, 'ConfiscationSuspensionImpounding'),
        ('60', 2, 'ConfiscationSuspensionImpounding'),
        ('60', 3, 'ConfiscationSuspensionImpounding'),
        ('61', 3, 'ClosureRevocation'),
        ('66', 3, 'ClosureRevocation'),
        ('67', 3, 'ClosureRevocation'),
        ('68', 3, 'ClosureRevocation'),
        ('69', 3, 'ClosureRevocation'),
        ('70', 3, 'ClosureRevocation'),
        ('71', 3, 'ClosureRevocation'),
        ('72', 3, 'ClosureRevocation'),
        ('73', 3, 'ClosureRevocation'),
        ('74', 3, 'ClosureRevocation'),
        ('75', 3, 'ClosureRevocation'),
        ('76', 3, 'ClosureRevocation')
    ) AS label(section, offense_number, additional_penalty)
    WHERE tier.ordinance_id = ordinance.id AND ordinance.ordinance_no = '011' AND ordinance.series = '2014'
        AND ordinance.is_active AND ordinance.section = label.section AND tier.offense_number = label.offense_number;
    GET DIAGNOSTICS labelled = ROW_COUNT;
    IF labelled <> 36 THEN
        RAISE EXCEPTION 'Severity labels blocked: expected 36 offence rules, found %. Manual review required.', labelled;
    END IF;
END $$;

-- Record the migration only where EF keeps its history, so a later `dotnet ef` run does not repeat it.
DO $$
BEGIN
    IF to_regclass('"__EFMigrationsHistory"') IS NOT NULL THEN
        INSERT INTO "__EFMigrationsHistory" ("MigrationId", "ProductVersion") VALUES ('20261128090000_SeverityLevel', '10.0.9');
    END IF;
END $$;

-- After: offence rules by level ingredient, for a quick look (expect 36 labelled rules).
SELECT additional_penalty, COUNT(*) AS rules FROM ordinance_penalty_tiers GROUP BY additional_penalty ORDER BY additional_penalty;

COMMIT;
