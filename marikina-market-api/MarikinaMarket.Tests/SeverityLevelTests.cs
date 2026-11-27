using System.ComponentModel.DataAnnotations;
using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using MarikinaMarket.API.Domain.Enums;
using MarikinaMarket.API.Infrastructure.Migrations;
using Xunit;

namespace MarikinaMarket.Tests;

// Severity Level from the Market Code (ADR 0001, #164). Expected levels are worked out by hand from the level table.
public class SeverityLevelTests
{
    [Theory]
    [InlineData(FineKind.UpTo, 0, AdditionalPenalty.None, 1)]          // up to ₱1,000 and/or imprisonment → 1
    [InlineData(FineKind.Fixed, 1000, AdditionalPenalty.None, 1)]      // ₱1,000 is still "up to ₱1,000"
    [InlineData(FineKind.Fixed, 2000, AdditionalPenalty.None, 2)]      // over ₱1,000
    [InlineData(FineKind.Fixed, 200, AdditionalPenalty.ConfiscationSuspensionImpounding, 3)]
    [InlineData(FineKind.Fixed, 1000, AdditionalPenalty.ClosureRevocation, 4)]
    [InlineData(FineKind.Unconfirmed, 0, AdditionalPenalty.Imprisonment, 5)]
    public async Task Fine_summary_shows_the_level_of_the_offence_rule(FineKind kind, decimal amount, AdditionalPenalty penalty, int level)
    {
        using var fixture = new InspectionNotificationTests.Fixture
        {
            FineKind = kind, FixedAmount = amount, MaximumFine = kind == FineKind.UpTo ? 1000m : null, AdditionalPenalty = penalty
        };
        var summary = await fixture.Service.GetPersonFineSummaryAsync([1], 31);
        Assert.Equal(level, Assert.Single(summary.Breakdown).SeverityLevel);
        Assert.Equal(level, summary.SeverityLevel);
        Assert.Equal(Severity.Minor, summary.HighestSeverity);
    }

    [Fact]
    public async Task Ticket_saves_the_highest_level_among_its_violations()
    {
        // Ordinance 1: ₱1,000 + closure → 4; ordinance 2: ₱200 → 1.
        using var fixture = new InspectionNotificationTests.Fixture
        {
            AdditionalOrdinance = true, FixedAmount = 1000m, AdditionalPenalty = AdditionalPenalty.ClosureRevocation
        };
        var summary = await fixture.Service.GetPersonFineSummaryAsync([1, 2], 31);
        Assert.Equal([4, 1], summary.Breakdown.Select(item => item.SeverityLevel));
        var submit = fixture.Request(ViolationType.Ticket); submit.Ordinances = [1, 2];
        var created = await fixture.Service.CreateTicketAsync(submit);
        Assert.Equal(4, fixture.CreatedTicket!.SeverityLevel);
        Assert.Equal(4, created.SeverityLevel);
        Assert.Equal(Severity.Minor, fixture.CreatedTicket.HighestSeverity);
    }

    [Theory]
    [InlineData(0, 1)] // 1st offence: ₱300 → 1
    [InlineData(2, 4)] // 3rd offence: ₱2,000 + permit revocation → 4
    public async Task Same_rule_rises_only_when_the_code_adds_a_penalty(int previousOffences, int level)
    {
        using var fixture = new InspectionNotificationTests.Fixture
        {
            OffenseCount = previousOffences,
            Tiers =
            [
                new() { OffenseNumber = 1, FineKind = FineKind.Fixed, PenaltyAmount = 300m },
                new() { OffenseNumber = 2, FineKind = FineKind.Fixed, PenaltyAmount = 600m },
                new() { OffenseNumber = 3, FineKind = FineKind.Fixed, PenaltyAmount = 2000m, AdditionalPenalty = AdditionalPenalty.ClosureRevocation }
            ]
        };
        await fixture.Service.CreateTicketAsync(fixture.Request(ViolationType.Ticket));
        Assert.Equal(level, fixture.CreatedTicket!.SeverityLevel);
    }

    [Theory]
    [InlineData(PenaltyType.CashFine)]
    [InlineData(PenaltyType.CommunityService)]
    [InlineData(PenaltyType.BloodDonation)]
    public async Task Penalty_type_does_not_change_the_level(PenaltyType penalty)
    {
        // ₱500 + confiscation → 3, however the vendor settles.
        using var fixture = new InspectionNotificationTests.Fixture { AdditionalPenalty = AdditionalPenalty.ConfiscationSuspensionImpounding };
        var submit = fixture.Request(ViolationType.Ticket); submit.PenaltyType = penalty; submit.CommunityServiceHours = 3;
        await fixture.Service.CreateTicketAsync(submit);
        Assert.Equal(3, fixture.CreatedTicket!.SeverityLevel);
    }

    [Fact]
    public async Task Rule_without_a_confirmed_fine_is_still_refused_even_with_a_level()
    {
        using var fixture = new InspectionNotificationTests.Fixture
        {
            FineKind = FineKind.Unconfirmed, PenaltyTerms = "Closure", AdditionalPenalty = AdditionalPenalty.ClosureRevocation
        };
        var error = await Assert.ThrowsAsync<ValidationException>(() => fixture.Service.CreateTicketAsync(fixture.Request(ViolationType.Ticket)));
        Assert.Equal("A confirmed penalty rule is required before assessment. Review the displayed penalty terms.", error.Message);
        Assert.Null(fixture.CreatedTicket);
    }

    [Fact]
    public async Task Rule_with_no_fine_and_no_additional_penalty_has_no_level()
    {
        using var fixture = new InspectionNotificationTests.Fixture { FineKind = FineKind.Unconfirmed, PenaltyTerms = "Not stated" };
        var summary = await fixture.Service.GetPersonFineSummaryAsync([1], 31);
        Assert.Null(Assert.Single(summary.Breakdown).SeverityLevel);
        Assert.Null(summary.SeverityLevel);
    }

    [Fact]
    public async Task Ordinance_responses_carry_additional_penalty_and_level_beside_old_severity()
    {
        await using var host = await OrdinanceManagementAccessHost.Create();
        using var create = await host.Send(HttpMethod.Post, "/api/ordinance", "AdminOfficer", new
        {
            ordinance_number = "11", series = "2014", section = "53", title = "Public places",
            category = "Obstruction", severity = "High", warning_eligible = false,
            penalty_tiers = new[] { new { offense_number = 1, fine_kind = "UpTo", maximum_fine = 1000,
                penalty_terms = "Up to PHP 1,000", allow_blood_donation = false, allow_community_service = false } }
        });
        Assert.Equal(HttpStatusCode.Created, create.StatusCode);
        var id = (await create.Content.ReadFromJsonAsync<JsonElement>()).GetProperty("id").GetInt32();
        using var detail = await host.Send(HttpMethod.Get, $"/api/ordinance/{id}", "AdminOfficer");
        using var catalog = await host.Send(HttpMethod.Get, "/api/ordinance", "MarketEnforcer");
        var loaded = await detail.Content.ReadFromJsonAsync<JsonElement>();
        var listed = (await catalog.Content.ReadFromJsonAsync<JsonElement>()).EnumerateArray().Single(o => o.GetProperty("id").GetInt32() == id);
        foreach (var ordinance in new[] { loaded, listed })
        {
            Assert.Equal("High", ordinance.GetProperty("severity").GetString());
            var tier = ordinance.GetProperty("penalty_tiers")[0];
            Assert.Equal("None", tier.GetProperty("additional_penalty").GetString());
            Assert.Equal(1, tier.GetProperty("severity_level").GetInt32()); // up to ₱1,000 → 1
        }
    }

    // Hand-typed from the label list the user approved on 2026-11-28: levels for the 1st, 2nd and 3rd offence, "-" = no level.
    private static readonly Dictionary<string, string> ApprovedLevels = new()
    {
        ["12"] = "1 1 1", ["13"] = "1 1 1", ["14"] = "1 1 1", ["15"] = "2 4 -", ["16"] = "1 - 2", ["17"] = "1 1 1",
        ["30"] = "2 2 4", ["31"] = "- - 4", ["32"] = "- - -", ["33"] = "- - -", ["35"] = "1 1 1", ["37"] = "3 - -",
        ["38"] = "- - -", ["40"] = "3 3 3", ["41"] = "4 - -", ["42"] = "1 1 1", ["43"] = "1 1 1", ["44"] = "4 4 4",
        ["45"] = "3 3 3", ["46"] = "- - -", ["47"] = "1 1 1", ["48"] = "1 4 -", ["49"] = "1 1 1", ["50"] = "1 1 1",
        ["51"] = "1 1 1", ["52"] = "3 3 3", ["53"] = "1 1 1", ["54"] = "1 3 5", ["55"] = "1 1 1", ["56"] = "2 2 2",
        ["57"] = "1 1 4", ["58"] = "1 1 1", ["59"] = "1 1 1", ["60"] = "3 3 3", ["61"] = "1 1 4", ["62"] = "1 1 1",
        ["63"] = "1 1 1", ["64"] = "1 1 1", ["65"] = "1 1 1", ["66"] = "1 1 4", ["67"] = "1 1 4", ["68"] = "2 2 4",
        ["69"] = "1 1 4", ["70"] = "1 1 4", ["71"] = "1 1 4", ["72"] = "1 1 4", ["73"] = "1 1 4", ["74"] = "1 1 4",
        ["75"] = "1 1 4", ["76"] = "1 1 4", ["77"] = "- - -", ["78"] = "2 2 2",
        ["79 Fines / Penalties — Public"] = "1 1 1", ["79 Fines / Penalties — Private"] = "1 2 -",
    };

    [Fact]
    public void Catalog_labels_give_every_offence_rule_its_approved_level()
    {
        var actual = OrdinanceWorkbookCatalogData.Entries.ToDictionary(
            entry => entry.Section == "79" ? $"79 {entry.Title}" : entry.Section,
            entry => string.Join(" ", entry.Tiers.Select(tier =>
            {
                var label = SeverityLevelLabelData.Labels.SingleOrDefault(l => l.Section == entry.Section && l.OffenseNumber == tier.OffenseNumber);
                var level = API.Domain.Entities.OrdinancePenaltyTier.SeverityLevelOf(
                    tier.Kind, tier.Amount, tier.Maximum, label?.AdditionalPenalty ?? AdditionalPenalty.None);
                return level?.ToString() ?? "-";
            })));
        Assert.Equal(ApprovedLevels.OrderBy(p => p.Key), actual.OrderBy(p => p.Key));
    }

    [Fact]
    public void Label_script_names_only_catalog_rules_and_stops_when_any_is_missing()
    {
        foreach (var label in SeverityLevelLabelData.Labels)
            Assert.Contains(OrdinanceWorkbookCatalogData.Entries, e => e.Section == label.Section && e.Tiers.Any(t => t.OffenseNumber == label.OffenseNumber));
        Assert.DoesNotContain(SeverityLevelLabelData.Labels, l => l.Section == "79"); // two rules share section 79
        var sql = SeverityLevelLabelData.BuildLabelSql();
        Assert.Contains($"IF labelled <> {SeverityLevelLabelData.Labels.Length} THEN", sql);
        Assert.Contains("('54', 3, 'Imprisonment')", sql);
        Assert.Equal(36, SeverityLevelLabelData.Labels.Length); // counted by hand from the approved list
    }
}
