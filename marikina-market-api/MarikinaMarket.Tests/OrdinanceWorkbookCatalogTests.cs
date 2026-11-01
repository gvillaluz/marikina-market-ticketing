using MarikinaMarket.API.Domain.Enums;
using MarikinaMarket.API.Infrastructure.Migrations;
using Xunit;

namespace MarikinaMarket.Tests;

// Expected values are hand-derived from the approved workbook and Slice 3 decisions,
// not copied from the catalog data.
public class OrdinanceWorkbookCatalogTests
{
    private static readonly WorkbookOrdinance[] Catalog = OrdinanceWorkbookCatalogData.Entries;

    private static WorkbookOrdinance Section(string section) => Assert.Single(Catalog, e => e.Section == section);

    private static void AssertTiers(WorkbookOrdinance entry, params (FineKind Kind, decimal? Amount)[] expected)
    {
        Assert.Equal(expected.Length, entry.Tiers.Length);
        for (var i = 0; i < expected.Length; i++)
        {
            var tier = entry.Tiers[i];
            Assert.Equal(i + 1, tier.OffenseNumber);
            Assert.Equal(expected[i].Kind, tier.Kind);
            if (expected[i].Kind == FineKind.Fixed) Assert.Equal(expected[i].Amount, tier.Amount);
            if (expected[i].Kind == FineKind.UpTo) Assert.Equal(expected[i].Amount, tier.Maximum);
        }
    }

    [Fact]
    public void Catalog_has_54_entries_covering_53_sections_with_79_split()
    {
        Assert.Equal(54, Catalog.Length);
        Assert.Equal(53, Catalog.Select(e => e.Section).Distinct().Count());
        Assert.Equal(54, Catalog.Select(e => (e.Section, e.Title)).Distinct().Count());
        Assert.Equal(2, Catalog.Count(e => e.Section == "79"));
        var expectedSections = new[] { 12, 13, 14, 15, 16, 17, 30, 31, 32, 33, 35, 37, 38 }
            .Concat(Enumerable.Range(40, 40)).Select(n => n.ToString()).ToHashSet();
        Assert.True(expectedSections.SetEquals(Catalog.Select(e => e.Section)));
    }

    [Fact]
    public void Legacy_rows_2_to_21_each_map_once_and_34_rows_are_new()
    {
        var legacy = Catalog.Where(e => e.LegacyId.HasValue).Select(e => e.LegacyId!.Value).OrderBy(id => id).ToArray();
        Assert.Equal(Enumerable.Range(2, 20), legacy);
        Assert.Equal(34, Catalog.Count(e => e.LegacyId is null));
        Assert.Equal(1, OrdinanceWorkbookCatalogData.RetiredLegacyId);
        var mapping = new Dictionary<int, string>
        {
            [2] = "12", [3] = "15", [4] = "16", [5] = "30", [6] = "40", [7] = "48", [8] = "49", [9] = "54",
            [10] = "56", [11] = "57", [12] = "58", [13] = "59", [14] = "60", [15] = "62", [16] = "63",
            [17] = "64", [18] = "65", [19] = "79", [20] = "79", [21] = "78"
        };
        foreach (var (id, section) in mapping)
            Assert.Equal(section, Assert.Single(Catalog, e => e.LegacyId == id).Section);
        Assert.Contains("Public", Assert.Single(Catalog, e => e.LegacyId == 19).Title);
        Assert.Contains("Private", Assert.Single(Catalog, e => e.LegacyId == 20).Title);
    }

    [Fact]
    public void Categories_follow_the_workbook_with_others_using_its_label()
    {
        Assert.Equal(25, Catalog.Count(e => e.Category == ViolationCategory.Others));
        Assert.All(Catalog, e =>
        {
            Assert.NotEqual(ViolationCategory.Licensing, e.Category);
            Assert.NotEqual(ViolationCategory.Noise, e.Category);
            if (e.Category == ViolationCategory.Others)
                Assert.InRange(e.SpecificCategory?.Trim().Length ?? 0, 1, 100);
            else
                Assert.Null(e.SpecificCategory);
        });
        Assert.Equal("Vendor Identification", Section("12").SpecificCategory);
        Assert.Equal("Permit & Licensing", Section("13").SpecificCategory);
        Assert.Equal("Permit & Licensing", Section("15").SpecificCategory);
        Assert.Equal("Utilities", Section("40").SpecificCategory);
        Assert.Equal("Resisting Authority", Section("78").SpecificCategory);
        Assert.All(Catalog.Where(e => e.Section == "79"), e => Assert.Equal("General Penalties", e.SpecificCategory));
        Assert.Equal(ViolationCategory.Sanitation, Section("14").Category);
        Assert.Equal(ViolationCategory.WeightMeasures, Section("16").Category);
        Assert.Equal(ViolationCategory.IllegalVendor, Section("42").Category);
        Assert.Equal(ViolationCategory.DressCode, Section("49").Category);
        Assert.Equal(ViolationCategory.IllegalVendor, Section("57").Category);
        Assert.Equal(ViolationCategory.Obstruction, Section("58").Category);
        Assert.Equal(ViolationCategory.Traffic, Section("59").Category);
        Assert.Equal(ViolationCategory.IllegalVendor, Section("61").Category);
    }

    [Fact]
    public void Tiers_encode_workbook_penalties()
    {
        AssertTiers(Section("12"), (FineKind.Fixed, 100m), (FineKind.Fixed, 100m), (FineKind.Fixed, 100m));
        AssertTiers(Section("13"), (FineKind.UpTo, 1000m), (FineKind.UpTo, 1000m), (FineKind.UpTo, 1000m));
        Assert.All(Section("13").Tiers, t => Assert.Contains("imprisonment", t.Terms));
        AssertTiers(Section("15"), (FineKind.Fixed, 2000m), (FineKind.Unconfirmed, null), (FineKind.Unconfirmed, null));
        Assert.Contains("Closure", Section("15").Tiers[1].Terms);
        AssertTiers(Section("16"), (FineKind.Fixed, 1000m), (FineKind.Unconfirmed, null), (FineKind.Fixed, 2000m));
        AssertTiers(Section("30"), (FineKind.Fixed, 1500m), (FineKind.Fixed, 3000m), (FineKind.Fixed, 5000m));
        Assert.Contains("closure", Section("30").Tiers[2].Terms);
        AssertTiers(Section("31"), (FineKind.Unconfirmed, null), (FineKind.Unconfirmed, null), (FineKind.Fixed, 5000m));
        AssertTiers(Section("40"), (FineKind.Fixed, 200m), (FineKind.Fixed, 200m), (FineKind.Fixed, 200m));
        Assert.All(Section("40").Tiers, t => Assert.Contains("Disconnection", t.Terms));
        AssertTiers(Section("54"), (FineKind.Fixed, 1000m), (FineKind.Fixed, 1000m), (FineKind.Unconfirmed, null));
        AssertTiers(Section("56"), (FineKind.Fixed, 2000m), (FineKind.Fixed, 2000m), (FineKind.Fixed, 2000m));
        AssertTiers(Section("57"), (FineKind.Fixed, 300m), (FineKind.Fixed, 600m), (FineKind.Fixed, 2000m));
        AssertTiers(Section("60"), (FineKind.Unconfirmed, null), (FineKind.Unconfirmed, null), (FineKind.Unconfirmed, null));
        AssertTiers(Section("68"), (FineKind.Fixed, 2000m), (FineKind.Fixed, 2000m), (FineKind.Fixed, 2000m));
        AssertTiers(Section("77"), (FineKind.Unconfirmed, null), (FineKind.Unconfirmed, null), (FineKind.Unconfirmed, null));
        var publicPenalty = Assert.Single(Catalog, e => e.LegacyId == 19);
        AssertTiers(publicPenalty, (FineKind.UpTo, 1000m), (FineKind.UpTo, 1000m), (FineKind.UpTo, 1000m));
        var privatePenalty = Assert.Single(Catalog, e => e.LegacyId == 20);
        AssertTiers(privatePenalty, (FineKind.Fixed, 1000m), (FineKind.Fixed, 1500m), (FineKind.Unconfirmed, null));
    }

    [Fact]
    public void Community_service_is_first_offense_monetary_only()
    {
        Assert.True(Section("12").Tiers[0].CommunityService);
        Assert.True(Section("13").Tiers[0].CommunityService);
        Assert.True(Section("40").Tiers[0].CommunityService);
        Assert.False(Section("31").Tiers[0].CommunityService);
        Assert.False(Section("60").Tiers[0].CommunityService);
        Assert.False(Section("77").Tiers[0].CommunityService);
        Assert.All(Catalog.SelectMany(e => e.Tiers), t =>
        {
            if (t.OffenseNumber != 1) Assert.False(t.CommunityService);
            if (t.Kind == FineKind.Unconfirmed) Assert.False(t.CommunityService);
        });
    }

    [Fact]
    public void Every_entry_satisfies_admin_tier_rules()
    {
        Assert.All(Catalog, e =>
        {
            Assert.InRange(e.Title.Length, 1, 250);
            Assert.InRange(e.Section.Length, 1, 100);
            Assert.Equal(Enumerable.Range(1, e.Tiers.Length), e.Tiers.Select(t => t.OffenseNumber));
            Assert.All(e.Tiers, t =>
            {
                Assert.True((t.Terms?.Length ?? 0) <= 1000);
                switch (t.Kind)
                {
                    case FineKind.Fixed:
                        Assert.True(t.Amount > 0); Assert.Null(t.Maximum); break;
                    case FineKind.UpTo:
                        Assert.Null(t.Amount); Assert.True(t.Maximum >= 100); break;
                    default:
                        Assert.False(string.IsNullOrWhiteSpace(t.Terms)); Assert.Null(t.Amount); Assert.Null(t.Maximum); break;
                }
            });
        });
    }

    [Fact]
    public void Migration_sql_guards_retires_legacy_and_leaves_new_rows_unconfigured()
    {
        var sql = OrdinanceWorkbookCatalogData.BuildUpSql();
        Assert.Contains("RAISE EXCEPTION", sql);
        Assert.Contains("SAMPLE-021", sql);
        Assert.Contains("is_active = false", sql);
        Assert.Equal(34, CountOccurrences(sql, "INSERT INTO ordinances "));
        Assert.Equal(20, CountOccurrences(sql, "DELETE FROM ordinance_penalty_tiers WHERE ordinance_id = "));
        Assert.DoesNotContain("ticket", sql, StringComparison.OrdinalIgnoreCase);
        // Tier tuples end with (allow_blood_donation, allow_community_service): blood is never true.
        Assert.DoesNotContain("true, true)", sql);
        Assert.DoesNotContain("true, false)", sql);
        // New ordinance tuples end with (severity, warning_eligible, is_active).
        Assert.Equal(34, CountOccurrences(sql, "NULL, false, true) RETURNING id"));
        Assert.DoesNotContain("severity =", sql);
        Assert.DoesNotContain("warning_eligible =", sql);
    }

    private static int CountOccurrences(string text, string value)
    {
        var count = 0;
        for (var i = text.IndexOf(value, StringComparison.Ordinal); i >= 0; i = text.IndexOf(value, i + value.Length, StringComparison.Ordinal))
            count++;
        return count;
    }
}
