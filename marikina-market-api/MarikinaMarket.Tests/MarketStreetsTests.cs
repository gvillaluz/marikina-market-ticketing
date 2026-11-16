using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using MarikinaMarket.API.Application.DTOs.MarketSection.Request;
using MarikinaMarket.API.Application.DTOs.MarketSection.Response;
using MarikinaMarket.API.Domain.Entities;
using MarikinaMarket.API.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Metadata;
using Microsoft.EntityFrameworkCore.Migrations;
using Xunit;

namespace MarikinaMarket.Tests;

// Market streets slice 3: the list holds the market streets, and a street has no description.
public class MarketStreetsTests
{
    // The user's list (2026-11-16), in the user's order.
    private static readonly string[] Streets =
    [
        "Shoe Avenue", "E. Jacinto Street", "E. Dela Paz Street", "P. Burgos Street", "M. Cruz Street",
        "J. P. Rizal Street", "Sumulong Avenue", "Villalon Street", "P. Paz Street", "Kapitan Venciong Street",
        "W. Paz Street"
    ];

    private static readonly string[] OldSections =
    [
        "Fish and Seafood Section", "Meat Section", "Dry Goods Section", "Vegetable Section",
        "Groceries Section", "Eatery Section", "Special Stalls", "Miscellaneous Section"
    ];

    [Fact]
    public void A_new_database_starts_with_exactly_the_streets_all_turned_on()
    {
        using var context = Context();
        var seeds = context.GetService<IDesignTimeModel>().Model.FindEntityType(typeof(MarketSection))!.GetSeedData().ToList();

        Assert.Equal(Enumerable.Range(1, 11), seeds.Select(seed => (int)seed["Id"]!));
        Assert.Equal(Streets, seeds.Select(seed => (string)seed["Name"]!));
        Assert.All(seeds, seed => Assert.True((bool)seed["IsActive"]!));
    }

    [Fact]
    public void A_street_has_no_description_anywhere()
    {
        using var context = Context();
        Assert.Null(context.Model.FindEntityType(typeof(MarketSection))!.FindProperty("Description"));
        Assert.Null(typeof(SaveMarketSectionRequest).GetProperty("Description"));
        Assert.Null(typeof(MarketSectionResponse).GetProperty("Description"));
    }

    [Fact]
    public void The_update_moves_records_to_streets_and_matches_the_model()
    {
        using var context = Context();
        Assert.False(context.Database.HasPendingModelChanges());
        var migrations = context.GetService<IMigrationsAssembly>().Migrations.Keys.ToList();
        var migration = Assert.Single(migrations, id => id.EndsWith("_MarketStreets"));
        var previous = migrations[migrations.IndexOf(migration) - 1];
        var sql = context.GetService<IMigrator>().GenerateScript(previous, migration);

        foreach (var table in new[] { "recommendation_reviews", "section_recommendations", "recommendation_findings", "recommendation_runs" })
            Assert.Contains($"DELETE FROM {table};", sql);
        Assert.Contains("ALTER TABLE market_sections DROP COLUMN description;", sql);
        foreach (var street in Streets)
            Assert.Contains($"'{street}'", sql);
        foreach (var section in OldSections)
            Assert.DoesNotContain(section, sql);
        Assert.Contains("UPDATE businesses", sql);
        Assert.Contains("UPDATE tickets", sql);
        Assert.Contains("snapshot_market_section_name", sql);
        Assert.Contains("UPDATE vendor_registration_requests", sql);
        Assert.Contains("DELETE FROM market_sections WHERE id > 11;", sql);
        Assert.Contains("setval", sql);
        // Nothing else is deleted: tickets, warnings and businesses are kept.
        Assert.Equal(5, sql.Split("DELETE FROM").Length - 1);
        Assert.Contains("START TRANSACTION", sql);
        Assert.Contains("COMMIT", sql);
    }

    [Fact]
    public async Task A_street_is_added_and_renamed_with_a_name_only()
    {
        await using var host = await MarketSectionManagementHost.Create();
        using var create = await host.Send(HttpMethod.Post, "/api/marketsection", "AdminOfficer", new { name = "Shoe Avenue" });
        Assert.Equal(HttpStatusCode.Created, create.StatusCode);
        var created = await create.Content.ReadFromJsonAsync<JsonElement>();
        Assert.False(created.TryGetProperty("description", out _));

        var id = created.GetProperty("id").GetInt32();
        using var edit = await host.Send(HttpMethod.Put, $"/api/marketsection/{id}", "AdminOfficer", new { name = "W. Paz Street" });
        Assert.Equal(HttpStatusCode.OK, edit.StatusCode);

        using var list = await host.Send(HttpMethod.Get, "/api/marketsection", "AdminOfficer");
        var records = (await list.Content.ReadFromJsonAsync<JsonElement>()).EnumerateArray().ToList();
        Assert.Contains(records, record => record.GetProperty("name").GetString() == "W. Paz Street");
        Assert.All(records, record => Assert.False(record.TryGetProperty("description", out _)));
    }

    private static AppDbContext Context() => new(new DbContextOptionsBuilder<AppDbContext>()
        .UseNpgsql("Host=localhost;Database=unused;Username=unused").UseSnakeCaseNamingConvention().Options);
}
