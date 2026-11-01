using System.Globalization;
using System.Text;
using MarikinaMarket.API.Domain.Enums;

namespace MarikinaMarket.API.Infrastructure.Migrations
{
    public sealed record WorkbookTier(int OffenseNumber, FineKind Kind, decimal? Amount, decimal? Maximum, string? Terms, bool CommunityService);

    public sealed record WorkbookOrdinance(int? LegacyId, string Section, string Title, ViolationCategory Category, string? SpecificCategory, WorkbookTier[] Tiers);

    // Ordinance 011, Series 2014 catalog from the user-approved workbook (docs/ordinance-slice3-plan.md).
    // Blood donation is never enabled ("Not stated"); community service only on monetary first offenses.
    public static class OrdinanceWorkbookCatalogData
    {
        public const string OrdinanceNo = "011";
        public const string Series = "2014";
        public const int RetiredLegacyId = 1;

        private const string UpToTerms = "Up to ₱1,000 and/or up to 6 months imprisonment";
        private const string NotStated = "Not stated";
        private const string LicenseCancellation = "Plus license cancellation";

        private static WorkbookTier F(int offense, decimal amount, string? terms = null) =>
            new(offense, FineKind.Fixed, amount, null, terms, offense == 1);

        private static WorkbookTier UC(int offense, string terms) =>
            new(offense, FineKind.Unconfirmed, null, null, terms, false);

        private static WorkbookTier[] UpTo3() =>
            Enumerable.Range(1, 3).Select(n => new WorkbookTier(n, FineKind.UpTo, null, 1000m, UpToTerms, n == 1)).ToArray();

        private static WorkbookTier[] Fixed3(decimal amount, string? terms = null) =>
            [F(1, amount, terms), F(2, amount, terms), F(3, amount, terms)];

        private static WorkbookTier[] Unconfirmed3(string terms) => [UC(1, terms), UC(2, terms), UC(3, terms)];

        private static WorkbookTier[] License3(decimal amount, string thirdTerms = LicenseCancellation) =>
            [F(1, amount), F(2, amount), F(3, amount, thirdTerms)];

        private static WorkbookOrdinance E(int? legacyId, string section, string title, ViolationCategory category, WorkbookTier[] tiers) =>
            new(legacyId, section, title, category, null, tiers);

        private static WorkbookOrdinance O(int? legacyId, string section, string title, string specific, WorkbookTier[] tiers) =>
            new(legacyId, section, title, ViolationCategory.Others, specific, tiers);

        public static readonly WorkbookOrdinance[] Entries =
        [
            O(2, "12", "Market Identification Card", "Vendor Identification", Fixed3(100m)),
            O(null, "13", "Market Clearance", "Permit & Licensing", UpTo3()),
            E(null, "14", "Food Safety and Personal Hygiene Training", ViolationCategory.Sanitation, UpTo3()),
            O(3, "15", "Posting of \"Pahintulot sa Paghahanapbuhay\"", "Permit & Licensing",
                [F(1, 2000m), UC(2, "Closure"), UC(3, NotStated)]),
            E(4, "16", "\"Timbangan Bayan\" Requirement", ViolationCategory.WeightMeasures,
                [F(1, 1000m), UC(2, NotStated), F(3, 2000m, "3rd/Final offense")]),
            O(null, "17", "Energy Efficient Lighting System (EELS)", "Lighting & Energy", UpTo3()),
            E(5, "30", "Weights and Measures", ViolationCategory.WeightMeasures,
                [F(1, 1500m, "Workbook marks this amount as uncertain (*)"), F(2, 3000m), F(3, 5000m, "Plus permit revocation/cancellation and closure")]),
            E(null, "31", "Attached Wire on Weighing Scale", ViolationCategory.WeightMeasures,
                [UC(1, "N/A"), UC(2, "N/A"), F(3, 5000m, "Plus permit revocation/cancellation and closure")]),
            E(null, "32", "Reporting Removed/Detached/Destroyed Scale Wire", ViolationCategory.WeightMeasures, Unconfirmed3("Not specified")),
            E(null, "33", "Redemption of Confiscated Weighing Scale", ViolationCategory.WeightMeasures,
                [UC(1, "N/A"), UC(2, "Additional ₱3,000 after 5-day grace period"), UC(3, "N/A")]),
            O(null, "35", "Limitations on Occupancy of Stall or Space", "Stall Occupancy", UpTo3()),
            O(null, "37", "Abandoned Stall / Articles", "Stall Management",
                [UC(1, "Forfeiture/disposal"), UC(2, NotStated), UC(3, NotStated)]),
            O(null, "38", "Construction/Alteration/Removal of Improvements", "Stall Construction",
                [UC(1, "Unauthorized improvement may be removed"), UC(2, NotStated), UC(3, NotStated)]),
            O(6, "40", "Unsettled Water and Electric Bill", "Utilities", Fixed3(200m, "Disconnection; ₱200 reconnection fee")),
            O(null, "41", "Unsettled Monthly Fixed Stall Rental", "Stall Rental",
                [UC(1, "Temporary closure + possible lease cancellation/revocation after 3 months"), UC(2, NotStated), UC(3, NotStated)]),
            E(null, "42", "Peddling and Hawking", ViolationCategory.IllegalVendor, UpTo3()),
            O(null, "43", "Loafing, Loitering, Begging and the Like", "Public Order", UpTo3()),
            O(null, "44", "Intoxicating, Dispensing and Serving of Liquor", "Liquor", Unconfirmed3("General penalty and/or award revocation")),
            E(null, "45", "Loose Animals", ViolationCategory.Sanitation, Unconfirmed3("Animal impounded")),
            O(null, "46", "Prohibitions", "Market Conduct", Unconfirmed3("General penalty + possible summary ejection")),
            E(null, "47", "Use of Alleys, Corridors and Walkways", ViolationCategory.Obstruction, UpTo3()),
            E(7, "48", "Prohibition to Buy Goods from Sidewalk Vendors", ViolationCategory.IllegalVendor,
                [F(1, 500m), UC(2, "Permit cancellation + closure"), UC(3, NotStated)]),
            E(8, "49", "Prohibition of Certain Inadequate Attire", ViolationCategory.DressCode, Fixed3(500m)),
            E(null, "50", "Use of \"P-Traps\" and \"Grease Trap\"", ViolationCategory.Sanitation, UpTo3()),
            E(null, "51", "Installation of Septic Tank", ViolationCategory.Sanitation, UpTo3()),
            E(null, "52", "Transport and Sale of All Types of Shellfish", ViolationCategory.Sanitation,
                Unconfirmed3("Confiscation/destruction + general penalty may apply")),
            E(null, "53", "Restriction for Use of Streets/Sidewalks/Public Places", ViolationCategory.Obstruction, UpTo3()),
            E(9, "54", "Harboring or Accepting Illegal Vendors", ViolationCategory.IllegalVendor,
                [F(1, 1000m), F(2, 1000m, "Plus 6-month suspension"), UC(3, "3rd and subsequent offenses: 20 days imprisonment + license/permit cancellation")]),
            O(null, "55", "Bladed Instruments", "Bladed Instruments", UpTo3()),
            E(10, "56", "Livestock and Poultry Products", ViolationCategory.Sanitation, Fixed3(2000m)),
            E(11, "57", "Mobile Vending Business", ViolationCategory.IllegalVendor,
                [F(1, 300m), F(2, 600m), F(3, 2000m, "Plus permit revocation")]),
            E(12, "58", "Wooden Furniture", ViolationCategory.Obstruction, Fixed3(1000m)),
            E(13, "59", "Tricycle Ban", ViolationCategory.Traffic, Fixed3(500m)),
            O(14, "60", "Regulation of Porter", "Porter Regulation",
                Unconfirmed3("₱100 + confiscation (registered) / ₱1,000 + confiscation (colorum)")),
            E(null, "61", "Regulation of Mobile Vending Activities", ViolationCategory.IllegalVendor,
                [F(1, 300m), F(2, 600m), F(3, 2000m, "Plus permit revocation")]),
            O(15, "62", "Promotional Sampling and Leafleting", "Promotions", Fixed3(1000m)),
            O(16, "63", "Promotional Activities and Advertising", "Advertising", Fixed3(1000m)),
            O(17, "64", "Streamers within Market/Zone Premises", "Signage & Streamers", Fixed3(1000m)),
            O(18, "65", "Shooting/Taping/Music/Entertainment Activities", "Entertainment Activities", UpTo3()),
            E(null, "66", "Cleaning of Market Premises", ViolationCategory.Sanitation, License3(1000m)),
            E(null, "67", "Public Toilets and Washing Facilities", ViolationCategory.Sanitation, License3(1000m)),
            O(null, "68", "General Lighting Facilities", "Lighting Facilities", License3(2000m)),
            E(null, "69", "Garbage Receptacles", ViolationCategory.Sanitation, License3(1000m)),
            E(null, "70", "Cooked/Raw Foods Protection from Contamination", ViolationCategory.Sanitation, License3(1000m)),
            E(null, "71", "Construction/Care of Stalls/Booths/Tables/Fixtures", ViolationCategory.Sanitation, License3(1000m)),
            E(null, "72", "Use of Impervious Materials", ViolationCategory.Sanitation, License3(1000m)),
            E(null, "73", "Cleaning Stalls/Booths/Spaces at End of Day", ViolationCategory.Sanitation, License3(1000m)),
            E(null, "74", "Abandonment of Perishable Goods", ViolationCategory.Sanitation,
                License3(1000m, "Plus license cancellation; lease revocation may apply")),
            O(null, "75", "Posting of Rules and Regulations", "Market Rules", License3(1000m)),
            O(null, "76", "Posting of Price Monitoring Board", "Price Monitoring", License3(1000m)),
            O(null, "77", "Surcharges", "Market Fees & Surcharges",
                Unconfirmed3("Surcharge: 3x rate / 2x excess-space rate / +25% late rate")),
            O(21, "78", "Opposing/Resisting/Interfering with Market Officers", "Resisting Authority",
                Fixed3(2000m, "And/or license-revocation recommendation")),
            O(19, "79", "Fines / Penalties — Public", "General Penalties", UpTo3()),
            O(20, "79", "Fines / Penalties — Private", "General Penalties",
                [F(1, 1000m), F(2, 1500m), UC(3, "Closure/revocation recommendation")]),
        ];

        // Data-only migration body. EF runs each migration in one transaction.
        public static string BuildUpSql()
        {
            var sql = new StringBuilder();
            var legacyCodes = string.Join(", ", Enumerable.Range(1, 21).Select(id => $"({id}, 'SAMPLE-{id:D3}')"));
            var sections = string.Join(", ", Entries.Select(e => Q(e.Section)).Distinct());

            sql.AppendLine("DO $$");
            sql.AppendLine("BEGIN");
            sql.AppendLine($"    IF (SELECT count(*) FROM ordinances WHERE (id, market_code) IN ({legacyCodes})) <> 21 THEN");
            sql.AppendLine("        RAISE EXCEPTION 'Workbook catalog blocked: legacy ordinances 1-21 differ from the seeded catalog; manual review required.';");
            sql.AppendLine("    END IF;");
            sql.AppendLine($"    IF EXISTS (SELECT 1 FROM ordinances WHERE id NOT BETWEEN 1 AND 21 AND is_active AND ordinance_no = {Q(OrdinanceNo)} AND series = {Q(Series)} AND section IN ({sections})) THEN");
            sql.AppendLine("        RAISE EXCEPTION 'Workbook catalog blocked: an active ordinance already uses a target section.';");
            sql.AppendLine("    END IF;");
            sql.AppendLine("END $$;");
            sql.AppendLine();
            sql.AppendLine($"UPDATE ordinances SET is_active = false, updated_at = timezone('utc', now()) WHERE id = {RetiredLegacyId};");

            foreach (var entry in Entries.Where(e => e.LegacyId.HasValue))
            {
                var id = entry.LegacyId!.Value;
                sql.AppendLine();
                sql.AppendLine($"UPDATE ordinances SET ordinance_no = {Q(OrdinanceNo)}, series = {Q(Series)}, section = {Q(entry.Section)}, title = {Q(entry.Title)}, category = {Q(entry.Category.ToString())}, specific_category = {Q(entry.SpecificCategory)}, is_active = true, updated_at = timezone('utc', now()) WHERE id = {id};");
                sql.AppendLine($"DELETE FROM ordinance_penalty_tiers WHERE ordinance_id = {id};");
                sql.AppendLine("INSERT INTO ordinance_penalty_tiers (ordinance_id, offense_number, fine_kind, penalty_amount, maximum_fine, penalty_terms, allow_blood_donation, allow_community_service) VALUES");
                sql.AppendLine(string.Join(",\n", entry.Tiers.Select(t => $"    ({id}, {TierValues(t)})")) + ";");
            }

            foreach (var entry in Entries.Where(e => e.LegacyId is null))
            {
                sql.AppendLine();
                sql.AppendLine("WITH inserted AS (");
                sql.AppendLine($"    INSERT INTO ordinances (ordinance_no, series, section, title, category, specific_category, severity, warning_eligible, is_active) VALUES ({Q(OrdinanceNo)}, {Q(Series)}, {Q(entry.Section)}, {Q(entry.Title)}, {Q(entry.Category.ToString())}, {Q(entry.SpecificCategory)}, NULL, false, true) RETURNING id)");
                sql.AppendLine("INSERT INTO ordinance_penalty_tiers (ordinance_id, offense_number, fine_kind, penalty_amount, maximum_fine, penalty_terms, allow_blood_donation, allow_community_service)");
                sql.AppendLine("SELECT inserted.id, tier.* FROM inserted CROSS JOIN (VALUES");
                sql.AppendLine(string.Join(",\n", entry.Tiers.Select(t => $"    ({TierValues(t)})")));
                sql.AppendLine(") AS tier(offense_number, fine_kind, penalty_amount, maximum_fine, penalty_terms, allow_blood_donation, allow_community_service);");
            }

            return sql.ToString();
        }

        private static string TierValues(WorkbookTier t) =>
            $"{t.OffenseNumber}, {Q(t.Kind.ToString())}, {N(t.Amount)}, {N(t.Maximum)}, {Q(t.Terms)}::text, false, {(t.CommunityService ? "true" : "false")}";

        private static string Q(string? value) => value is null ? "NULL" : "'" + value.Replace("'", "''") + "'";

        private static string N(decimal? value) => value.HasValue ? value.Value.ToString(CultureInfo.InvariantCulture) + "::numeric" : "NULL::numeric";
    }
}
