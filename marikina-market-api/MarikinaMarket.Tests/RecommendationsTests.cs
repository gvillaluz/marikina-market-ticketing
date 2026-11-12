using System.Reflection;
using MarikinaMarket.API.Application.Interfaces.Repositories;
using MarikinaMarket.API.Application.Services;
using MarikinaMarket.API.Domain.Entities;
using MarikinaMarket.API.Infrastructure.Persistence;
using MarikinaMarket.API.Infrastructure.Repositories;
using MarikinaMarket.API.Presentation.Controllers;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Xunit;

namespace MarikinaMarket.Tests;

public class RecommendationsTests
{
    private static readonly DateTime RunFinishedAt = new(2026, 11, 11, 5, 12, 40, DateTimeKind.Utc);

    // S1, worked out by hand. Cards in stored order: B 3.0, C 14.5, A 3.0.
    // Highest risk first gives C 14.5; the two 3.0 cards tie and go by name A to Z, so A then B.
    // Active sections without a card, stored as Zeta then Meat, come back A to Z: Meat, Zeta.
    [Fact]
    public async Task S1_cards_come_highest_risk_first_with_ties_by_section_name()
    {
        var sections = new List<MarketSection>
        {
            Section(1, "A"), Section(2, "B"), Section(3, "C"), Section(4, "Zeta"), Section(5, "Meat")
        };
        var run = Run(Card(2, 3.0m), Card(3, 14.5m), Card(1, 3.0m));
        var service = new RecommendationService(Recommendations(run), Sections(sections));

        var result = await service.GetLatestAsync();

        Assert.Equal(["C", "A", "B"], result.Recommendations.Select(card => card.MarketSectionName));
        Assert.Equal([14.5m, 3.0m, 3.0m], result.Recommendations.Select(card => card.RiskScore));
        Assert.Equal(["Meat", "Zeta"], result.SectionsWithoutRecommendation);

        Assert.NotNull(result.Run);
        Assert.Equal(RunFinishedAt, result.Run.FinishedAt);
        Assert.Equal(new DateTime(2026, 10, 12, 5, 11, 17, DateTimeKind.Utc), result.Run.WindowStart);
        Assert.Equal(new DateTime(2026, 11, 11, 5, 11, 17, DateTimeKind.Utc), result.Run.WindowEnd);
        Assert.Equal(21, result.Run.RecordCount);

        var top = result.Recommendations[0];
        Assert.Equal(3, top.MarketSectionId);
        Assert.Equal("weights_and_measures", top.CategoryCode);
        Assert.Equal("Weights and Measures", top.CategoryNameEnglish);
        Assert.Equal("Timbang at Sukat", top.CategoryNameFilipino);
        Assert.Equal("Check the scales in section 3.", top.RecommendedAction);
        Assert.Equal(4, top.CategoryRecordCount);
        Assert.Equal(6, top.SectionRecordCount);
        Assert.Equal("Moderate", top.RiskLevel);
        Assert.Equal("Moderate", top.PatternConfidence);
        Assert.Equal(8, top.PeakStartHour);
        Assert.Equal([0, 0, 0, 0, 0, 0, 0, 0, 3, 2, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], top.HourlyCounts);
        Assert.Equal(new DateTime(2026, 11, 10, 0, 15, 0, DateTimeKind.Utc), top.LastFlaggedAt);
    }

    // S2, worked out by hand. A: active with a card. B: active, no card. C: inactive, no card. D: inactive with a card.
    // "No recommendation" lists active sections without a card: only B. D still shows as a card under its current name.
    [Fact]
    public async Task S2_without_list_names_only_active_sections_and_inactive_cards_keep_their_name()
    {
        var sections = new List<MarketSection>
        {
            Section(1, "A"), Section(2, "B"), Section(3, "C", isActive: false), Section(4, "D", isActive: false)
        };
        var run = Run(Card(1, 5.0m), Card(4, 2.0m));
        var service = new RecommendationService(Recommendations(run), Sections(sections));

        var result = await service.GetLatestAsync();

        Assert.Equal(["B"], result.SectionsWithoutRecommendation);
        Assert.Equal(["A", "D"], result.Recommendations.Select(card => card.MarketSectionName));
        Assert.Equal([1, 4], result.Recommendations.Select(card => card.MarketSectionId));
    }

    [Fact]
    public async Task S3_no_run_gives_null_run_and_empty_lists()
    {
        var sections = new List<MarketSection> { Section(1, "A") };
        var service = new RecommendationService(Recommendations(null), Sections(sections));

        var result = await service.GetLatestAsync();

        Assert.Null(result.Run);
        Assert.Empty(result.Recommendations);
        Assert.Empty(result.SectionsWithoutRecommendation);
    }

    // S4: the repository's real query runs over an in-memory table (no database, no new package).
    // Runs stored as: older (finished 10 Nov), newer (finished 11 Nov), oldest (finished 9 Nov).
    // Only the newer run, with its own single card for section 7, may come back.
    [Fact]
    public async Task S4_repository_returns_only_the_latest_finished_run()
    {
        var older = Run(Card(1, 9.0m), Card(2, 8.0m));
        older.Id = 1;
        older.FinishedAt = RunFinishedAt.AddDays(-1);
        var newer = Run(Card(7, 1.0m));
        newer.Id = 2;
        var oldest = Run(Card(3, 20.0m));
        oldest.Id = 3;
        oldest.FinishedAt = RunFinishedAt.AddDays(-2);
        using var context = new AppDbContext(new DbContextOptionsBuilder<AppDbContext>().Options);
        context.RecommendationRuns = new AccountDatabaseSet<RecommendationRun>([older, newer, oldest]);
        var repository = new RecommendationRepository(context);

        var latest = await repository.GetLatestRunAsync();

        Assert.NotNull(latest);
        Assert.Equal(2, latest.Id);
        Assert.Equal([7], latest.SectionRecommendations.Select(card => card.MarketSectionId));
    }

    [Fact]
    public async Task S4_repository_returns_null_when_no_run_exists()
    {
        using var context = new AppDbContext(new DbContextOptionsBuilder<AppDbContext>().Options);
        context.RecommendationRuns = new AccountDatabaseSet<RecommendationRun>([]);

        Assert.Null(await new RecommendationRepository(context).GetLatestRunAsync());
    }

    [Fact]
    public void S5_route_is_restricted_to_head_admin_and_admin_officer()
    {
        var controller = typeof(AdminRecommendationsController);
        var authorize = controller.GetCustomAttribute<AuthorizeAttribute>();
        var route = controller.GetCustomAttribute<RouteAttribute>();
        var get = controller.GetMethod(nameof(AdminRecommendationsController.GetLatest))!
            .GetCustomAttribute<HttpGetAttribute>();

        Assert.Equal("HeadAdmin,AdminOfficer", authorize?.Roles);
        Assert.Equal("api/admin/recommendations", route?.Template);
        Assert.NotNull(get);
        Assert.Null(get.Template);
    }

    private static IRecommendationRepository Recommendations(RecommendationRun? run)
        => ReviewBoundaryProxy.Create<IRecommendationRepository>((method, _) => method.Name switch
        {
            nameof(IRecommendationRepository.GetLatestRunAsync) => Task.FromResult(run),
            _ => throw new InvalidOperationException(method.Name)
        });

    private static IMarketSectionRepository Sections(List<MarketSection> sections)
        => ReviewBoundaryProxy.Create<IMarketSectionRepository>((method, _) => method.Name switch
        {
            nameof(IMarketSectionRepository.GetAllAsync) => Task.FromResult(sections),
            _ => throw new InvalidOperationException(method.Name)
        });

    private static MarketSection Section(int id, string name, bool isActive = true)
        => new() { Id = id, Name = name, Description = $"{name} stalls", IsActive = isActive };

    private static RecommendationRun Run(params SectionRecommendation[] cards) => new()
    {
        StartedAt = RunFinishedAt.AddMinutes(-1),
        FinishedAt = RunFinishedAt,
        WindowStart = new DateTime(2026, 10, 12, 5, 11, 17, DateTimeKind.Utc),
        WindowEnd = new DateTime(2026, 11, 11, 5, 11, 17, DateTimeKind.Utc),
        ModelVersion = "test-model",
        RecordCount = 21,
        SectionRecommendations = cards.ToList()
    };

    private static SectionRecommendation Card(int marketSectionId, decimal riskScore) => new()
    {
        MarketSectionId = marketSectionId,
        CategoryCode = "weights_and_measures",
        CategoryNameEnglish = "Weights and Measures",
        CategoryNameFilipino = "Timbang at Sukat",
        RecommendedAction = $"Check the scales in section {marketSectionId}.",
        CategoryRecordCount = 4,
        SectionRecordCount = 6,
        RiskScore = riskScore,
        RiskLevel = "Moderate",
        PatternConfidence = "Moderate",
        PeakStartHour = 8,
        HourlyCounts = [0, 0, 0, 0, 0, 0, 0, 0, 3, 2, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        LastFlaggedAt = new DateTime(2026, 11, 10, 0, 15, 0, DateTimeKind.Utc)
    };
}
