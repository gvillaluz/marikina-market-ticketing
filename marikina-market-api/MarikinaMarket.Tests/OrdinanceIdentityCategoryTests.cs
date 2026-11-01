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

public class OrdinanceIdentityCategoryTests
{
    [Theory]
    [InlineData("DressCode", null)]
    [InlineData("IllegalVendor", null)]
    [InlineData("NonSmoking", null)]
    [InlineData("Others", "  Market clearance  ")]
    public async Task Administrator_can_save_and_reload_section_and_specific_category(string category, string? specific)
    {
        await using var host = await OrdinanceManagementAccessHost.Create();
        var request = new
        {
            ordinance_number = "11", series = "2014", section = " 53 ", title = "Use of public places",
            category, specific_category = specific, severity = "Minor",
            penalty_tiers = new[] { new { offense_number = 1, fine_kind = "Fixed", penalty_amount = 500 } }
        };
        using var create = await host.Send(HttpMethod.Post, "/api/ordinance", "AdminOfficer", request);
        Assert.Equal(HttpStatusCode.Created, create.StatusCode);
        var created = await create.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal("53", created.GetProperty("section").GetString());
        Assert.Equal(specific?.Trim(), created.GetProperty("specific_category").GetString());
        Assert.False(created.TryGetProperty("market_code", out _));
        var id = created.GetProperty("id").GetInt32();
        using var details = await host.Send(HttpMethod.Get, $"/api/ordinance/{id}", "AdminOfficer");
        var loaded = await details.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal("53", loaded.GetProperty("section").GetString());
        Assert.Equal(specific?.Trim(), loaded.GetProperty("specific_category").GetString());
        Assert.Equal(500m, loaded.GetProperty("penalty_tiers")[0].GetProperty("penalty_amount").GetDecimal());
    }

    [Fact]
    public void Historical_category_numbers_are_not_reassigned()
    {
        Assert.Equal(3, (int)ViolationCategory.Licensing);
        Assert.Equal(4, (int)ViolationCategory.Noise);
        Assert.Equal(5, (int)ViolationCategory.WeightMeasures);
    }

    [Theory]
    [InlineData(null)]
    [InlineData("")]
    [InlineData("   ")]
    public async Task Others_requires_specific_text_before_any_write(string? specific)
    {
        var service = Service(out var boundary);
        var request = Request();
        request.Category = ViolationCategory.Others;
        request.SpecificCategory = specific;
        await Assert.ThrowsAsync<InvalidRequestException>(() => service.CreateAsync(request));
        Assert.Null(boundary.Ordinance);
    }

    [Theory]
    [InlineData(ViolationCategory.Licensing)]
    [InlineData(ViolationCategory.Noise)]
    [InlineData((ViolationCategory)999)]
    public async Task Historical_or_unknown_categories_cannot_be_saved(ViolationCategory category)
    {
        var service = Service(out var boundary);
        var request = Request(); request.Category = category;
        await Assert.ThrowsAsync<InvalidRequestException>(() => service.CreateAsync(request));
        Assert.Null(boundary.Ordinance);
    }

    [Fact]
    public async Task Text_limits_and_blank_section_are_enforced()
    {
        var service = Service(out var boundary);
        foreach (var section in new[] { "", "   ", new string('5', 101) })
        {
            var request = Request(); request.Section = section;
            await Assert.ThrowsAsync<InvalidRequestException>(() => service.CreateAsync(request));
        }
        var other = Request(); other.Category = ViolationCategory.Others; other.SpecificCategory = new string('a', 101);
        await Assert.ThrowsAsync<InvalidRequestException>(() => service.CreateAsync(other));
        Assert.Null(boundary.Ordinance);
    }

    [Fact]
    public async Task Changing_from_others_clears_specific_category_and_preserves_ordinance_and_tier_ids()
    {
        var service = Service(out var boundary);
        var request = Request(); request.Category = ViolationCategory.Others; request.SpecificCategory = " Market clearance ";
        await service.CreateAsync(request);
        var ordinance = boundary.Ordinance!; var tier = Assert.Single(ordinance.PenaltyTiers); tier.Id = 77;
        request.Category = ViolationCategory.DressCode; request.Section = "49";
        var updated = await service.UpdateAsync(ordinance.Id, request);
        Assert.Null(updated.SpecificCategory);
        Assert.Null(ordinance.SpecificCategory);
        Assert.Equal(1, ordinance.Id);
        Assert.Equal("49", ordinance.Section);
        Assert.Equal(77, Assert.Single(ordinance.PenaltyTiers).Id);
        Assert.Equal(500m, tier.PenaltyAmount);
    }

    [Fact]
    public async Task Legacy_ordinance_without_confirmed_section_remains_readable()
    {
        await using var host = await OrdinanceManagementAccessHost.Create();
        host.Items[0].Section = null;
        host.Items[0].Category = ViolationCategory.Noise;
        using var response = await host.Send(HttpMethod.Get, "/api/ordinance/7", "AdminOfficer");
        var data = await response.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal(JsonValueKind.Null, data.GetProperty("section").ValueKind);
        Assert.Equal("Noise", data.GetProperty("category").GetString());
        Assert.False(data.TryGetProperty("market_code", out _));
    }

    private static SaveOrdinanceRequest Request() => new()
    {
        OrdinanceNumber = "11", Series = "2014", Section = "53", Title = "Public places",
        Category = ViolationCategory.Obstruction, Severity = Severity.Minor,
        PenaltyTiers = [new() { OffenseNumber = 1, FineKind = FineKind.Fixed, PenaltyAmount = 500m }]
    };

    private static OrdinanceService Service(out OrdinanceNumberBoundary boundary)
    {
        var repository = DispatchProxy.Create<IOrdinanceRepository, OrdinanceNumberBoundary>();
        boundary = (OrdinanceNumberBoundary)(object)repository;
        return new OrdinanceService(repository, DispatchProxy.Create<IUnitOfWork, OrdinanceNumberBoundary>());
    }
}
