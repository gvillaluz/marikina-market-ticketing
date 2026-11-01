using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using System.Reflection;
using MarikinaMarket.API.Application;
using MarikinaMarket.API.Application.DTOs.Ordinance.Request;
using MarikinaMarket.API.Application.Interfaces.Repositories;
using MarikinaMarket.API.Application.Services;
using MarikinaMarket.API.Domain.Enums;
using Xunit;

namespace MarikinaMarket.Tests;

public class OrdinancePenaltyConfigurationTests
{
    [Fact]
    public async Task Scoring_severity_and_warning_permission_belong_to_ordinance_not_tiers()
    {
        await using var host = await OrdinanceManagementAccessHost.Create();
        using var create = await host.Send(HttpMethod.Post, "/api/ordinance", "AdminOfficer", new
        {
            ordinance_number = "11", series = "2014", section = "53", title = "Public places",
            category = "Obstruction", severity = "High", warning_eligible = true,
            penalty_tiers = new[] { new { offense_number = 1, fine_kind = "UpTo", maximum_fine = 1000,
                penalty_terms = "Up to PHP 1,000", allow_blood_donation = true, allow_community_service = false } }
        });
        Assert.Equal(HttpStatusCode.Created, create.StatusCode);
        var saved = await create.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal("High", saved.GetProperty("severity").GetString());
        Assert.True(saved.GetProperty("warning_eligible").GetBoolean());
        using var detail = await host.Send(HttpMethod.Get, $"/api/ordinance/{saved.GetProperty("id").GetInt32()}", "AdminOfficer");
        var loaded = await detail.Content.ReadFromJsonAsync<JsonElement>();
        var tier = loaded.GetProperty("penalty_tiers")[0];
        Assert.Equal("UpTo", tier.GetProperty("fine_kind").GetString());
        Assert.Equal(100m, tier.GetProperty("minimum_fine").GetDecimal());
        Assert.Equal(1000m, tier.GetProperty("maximum_fine").GetDecimal());
        Assert.Equal(JsonValueKind.Null, tier.GetProperty("penalty_amount").ValueKind);
        Assert.True(tier.GetProperty("allow_blood_donation").GetBoolean());
        Assert.False(tier.TryGetProperty("severity", out _));
        using var catalog = await host.Send(HttpMethod.Get, "/api/ordinance", "MarketEnforcer");
        var item = (await catalog.Content.ReadFromJsonAsync<JsonElement>()).EnumerateArray()
            .Single(value => value.GetProperty("id").GetInt32() == saved.GetProperty("id").GetInt32());
        Assert.Single(item.GetProperty("penalty_tiers").EnumerateArray());
    }

    [Theory]
    [InlineData("missing-severity")]
    [InlineData("unknown-severity")]
    [InlineData("small-cap")]
    [InlineData("imprecise-cap")]
    [InlineData("later-blood")]
    [InlineData("later-service")]
    [InlineData("fixed-with-cap")]
    [InlineData("up-to-with-fixed")]
    [InlineData("unconfirmed-with-money")]
    [InlineData("unconfirmed-without-terms")]
    [InlineData("long-terms")]
    public async Task Invalid_penalty_settings_fail_before_any_write(string invalid)
    {
        var repository = DispatchProxy.Create<IOrdinanceRepository, OrdinanceNumberBoundary>();
        var boundary = (OrdinanceNumberBoundary)(object)repository;
        var service = new OrdinanceService(repository, DispatchProxy.Create<IUnitOfWork, OrdinanceNumberBoundary>());
        var tier = new SavePenaltyTierRequest { OffenseNumber = 1, FineKind = FineKind.UpTo, MaximumFine = 1000m };
        var request = new SaveOrdinanceRequest { OrdinanceNumber = "11", Series = "2014", Section = "53", Title = "Public places",
            Category = ViolationCategory.Obstruction, Severity = Severity.High, PenaltyTiers = [tier] };
        switch (invalid)
        {
            case "missing-severity": request.Severity = null; break;
            case "unknown-severity": request.Severity = (Severity)999; break;
            case "small-cap": tier.MaximumFine = 99.99m; break;
            case "imprecise-cap": tier.MaximumFine = 1000.001m; break;
            case "later-blood": tier.OffenseNumber = 2; tier.AllowBloodDonation = true; break;
            case "later-service": tier.OffenseNumber = 2; tier.AllowCommunityService = true; break;
            case "fixed-with-cap": tier.FineKind = FineKind.Fixed; tier.PenaltyAmount = 500m; break;
            case "up-to-with-fixed": tier.PenaltyAmount = 500m; break;
            case "unconfirmed-with-money": tier.FineKind = FineKind.Unconfirmed; tier.PenaltyTerms = "Not stated"; break;
            case "unconfirmed-without-terms": tier.FineKind = FineKind.Unconfirmed; tier.MaximumFine = null; break;
            case "long-terms": tier.PenaltyTerms = new string('x', 1001); break;
        }
        await Assert.ThrowsAsync<InvalidRequestException>(() => service.CreateAsync(request));
        Assert.Null(boundary.Ordinance);
    }
}
