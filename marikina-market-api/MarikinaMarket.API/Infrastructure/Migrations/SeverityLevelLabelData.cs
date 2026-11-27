using System.Text;
using MarikinaMarket.API.Domain.Enums;

namespace MarikinaMarket.API.Infrastructure.Migrations
{
    public sealed record SeverityLevelLabel(string Section, int OffenseNumber, AdditionalPenalty AdditionalPenalty);

    // Additional Penalty of each Ordinance 011, Series 2014 rule, from the label list the user approved on 2026-11-28 (#164).
    // Every rule not listed keeps None. Recommended penalties ("recommendation", "possible", "may") and surcharges never count.
    public static class SeverityLevelLabelData
    {
        private const AdditionalPenalty Taken = AdditionalPenalty.ConfiscationSuspensionImpounding;
        private const AdditionalPenalty Closure = AdditionalPenalty.ClosureRevocation;

        private static SeverityLevelLabel[] All3(string section, AdditionalPenalty penalty) =>
            [new(section, 1, penalty), new(section, 2, penalty), new(section, 3, penalty)];

        public static readonly SeverityLevelLabel[] Labels =
        [
            new("15", 2, Closure),          // Closure
            new("30", 3, Closure),          // Plus permit revocation/cancellation and closure
            new("31", 3, Closure),          // Plus permit revocation/cancellation and closure
            new("37", 1, Taken),            // Forfeiture/disposal
            .. All3("40", Taken),           // Disconnection; ₱200 reconnection fee
            new("41", 1, Closure),          // Temporary closure (the lease cancellation is only "possible")
            .. All3("44", Closure),         // General penalty and/or award revocation
            .. All3("45", Taken),           // Animal impounded
            new("48", 2, Closure),          // Permit cancellation + closure
            .. All3("52", Taken),           // Confiscation/destruction
            new("54", 2, Taken),            // Plus 6-month suspension
            new("54", 3, AdditionalPenalty.Imprisonment), // 20 days imprisonment + license/permit cancellation
            new("57", 3, Closure),          // Plus permit revocation
            .. All3("60", Taken),           // ₱100 + confiscation / ₱1,000 + confiscation
            new("61", 3, Closure),          // Plus permit revocation
            new("66", 3, Closure), new("67", 3, Closure), new("68", 3, Closure), new("69", 3, Closure),
            new("70", 3, Closure), new("71", 3, Closure), new("72", 3, Closure), new("73", 3, Closure),
            new("74", 3, Closure), new("75", 3, Closure), new("76", 3, Closure), // Plus license cancellation
        ];

        // Stops (and rolls back) when any listed rule is missing, so a changed catalog is never half labelled.
        public static string BuildLabelSql()
        {
            var values = string.Join(",\n        ", Labels.Select(l => $"('{l.Section}', {l.OffenseNumber}, '{l.AdditionalPenalty}')"));
            var sql = new StringBuilder();
            sql.AppendLine("DO $$");
            sql.AppendLine("DECLARE labelled integer;");
            sql.AppendLine("BEGIN");
            sql.AppendLine("    UPDATE ordinance_penalty_tiers tier SET additional_penalty = label.additional_penalty");
            sql.AppendLine("    FROM ordinances ordinance, (VALUES");
            sql.AppendLine($"        {values}");
            sql.AppendLine("    ) AS label(section, offense_number, additional_penalty)");
            sql.AppendLine("    WHERE tier.ordinance_id = ordinance.id AND ordinance.ordinance_no = '011' AND ordinance.series = '2014'");
            sql.AppendLine("        AND ordinance.is_active AND ordinance.section = label.section AND tier.offense_number = label.offense_number;");
            sql.AppendLine("    GET DIAGNOSTICS labelled = ROW_COUNT;");
            sql.AppendLine($"    IF labelled <> {Labels.Length} THEN");
            sql.AppendLine($"        RAISE EXCEPTION 'Severity labels blocked: expected {Labels.Length} offence rules, found %. Manual review required.', labelled;");
            sql.AppendLine("    END IF;");
            sql.AppendLine("END $$;");
            return sql.ToString();
        }
    }
}
