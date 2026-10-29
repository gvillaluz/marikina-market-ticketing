using System.Net;
using System.Text.Json;
using MarikinaMarket.API.Application.Interfaces.Services;
using MarikinaMarket.API.Application.Services;
using MarikinaMarket.API.Domain.Entities;
using MarikinaMarket.API.Domain.Enums;
using MarikinaMarket.API.Infrastructure.Persistence;
using MarikinaMarket.API.Infrastructure.Repositories;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Xunit;

namespace MarikinaMarket.Tests;

public class AnalyticsCalculationTests
{
    [Fact]
    public async Task Past_year_query_returns_the_selected_year_instead_of_current_year()
    {
        await using var context = Context(Records());
        var service = new AdminAnalyticsService(new TicketRepository(context), new AnalyticsClock(Utc(2026, 2, 20)));
        await using var host = await AuditHost.CreateAsync(services => services.AddSingleton<IAdminAnalyticsService>(service));
        using var response = await host.SendAsync(HttpMethod.Get, "/api/admin/analytics/violation-trend?year=2025", "HeadAdmin");
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        using var json = JsonDocument.Parse(await response.Content.ReadAsStringAsync());
        Assert.All(json.RootElement.EnumerateArray(), point => Assert.Equal(2025, point.GetProperty("year").GetInt32()));
        Assert.Equal(1, json.RootElement[11].GetProperty("low_severity_count").GetInt32());
    }

    [Theory]
    [InlineData("0")]
    [InlineData("1")]
    [InlineData("2")]
    [InlineData("2027")]
    [InlineData("not-a-year")]
    [InlineData("2025.5")]
    public async Task Every_analytics_endpoint_rejects_invalid_or_future_years(string year)
    {
        await using var context = Context([]);
        var service = new AdminAnalyticsService(new TicketRepository(context), new AnalyticsClock(Utc(2026, 2, 20)));
        await using var host = await AuditHost.CreateAsync(services => services.AddSingleton<IAdminAnalyticsService>(service));
        foreach (var route in new[] { "violation-trend", "peak-violation-times", "violation-type-distribution", "inspection-ratio", "resolution-rate", "market-section-aggregation", "hotspot-ranking", "vendor-risk-ranking" })
        {
            using var response = await host.SendAsync(HttpMethod.Get, $"/api/admin/analytics/{route}?year={year}", "HeadAdmin");
            Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
        }
    }

    [Fact]
    public async Task Past_year_includes_exact_Manila_start_and_last_microsecond_but_excludes_adjacent_years()
    {
        var start = Utc(2024, 12, 31, 16);
        var end = Utc(2025, 12, 31, 16);
        await using var context = Context([
            Record(1, start.AddTicks(-10)), Record(2, start),
            Record(3, Utc(2025, 10, 24), severity: Severity.Moderate),
            Record(4, end.AddTicks(-10), severity: Severity.High), Record(5, end)]);
        var service = new AdminAnalyticsService(new TicketRepository(context), new AnalyticsClock(Utc(2026, 2, 20)));
        Assert.Equal(3, (await service.GetInspectionRatioAsync(2025)).TicketCount);
        var trend = await service.GetViolationTrendAsync(2025);
        Assert.All(trend, row => Assert.Equal(2025, row.Year));
        Assert.Equal(1, trend[0].LowSeverityCount);
        Assert.Equal(1, trend[9].MediumSeverityCount);
        Assert.Equal(1, trend[11].HighSeverityCount);
        Assert.Equal(3, (await service.GetViolationResolutionRateAsync(2025)).TicketCount);
        Assert.Equal(3, (await service.GetPeakViolationTimesAsync(2025)).Sum(row => row.TicketCount));
        Assert.Equal(3, Assert.Single(await service.GetMarketSectionAggregationAsync(2025)).TicketCount);
        var hotspot = Assert.Single(await service.GetHotspotRankingAsync(2025));
        Assert.Equal(3, hotspot.TotalInspectionCount);
        Assert.Equal(1, hotspot.PreviousPeriodCount);
        Assert.Equal(1, (await service.GetInspectionRatioAsync()).TicketCount);
        Assert.Equal(1, (await service.GetInspectionRatioAsync(2026)).TicketCount);
    }

    private static DateTime Utc(int year, int month, int day, int hour = 0, int minute = 0) => new(year, month, day, hour, minute, 0, DateTimeKind.Utc);
    private static Ticket Record(int id, DateTime date, ViolationType type = ViolationType.Ticket, Severity severity = Severity.Minor) => new()
    { Id = id, IssuedAt = date, UpdatedAt = date, Type = type, HighestSeverity = severity, Status = type == ViolationType.Warning ? null : TicketStatus.Pending, Description = "Synthetic analytics record", MarketSectionId = 2 };

    private static List<Ticket> Records()
    {
        var records = new List<Ticket> {
            Record(1, Utc(2025, 12, 31, 15, 59)), // Prior Manila year.
            Record(2, Utc(2025, 12, 31, 16)), // Jan 1, Thu 00:00 Manila.
            Record(3, Utc(2026, 1, 31, 15, 59), severity: Severity.Moderate), // Jan 31, Sat 23:59.
            Record(4, Utc(2026, 1, 31, 16), severity: Severity.High), // Feb 1, Sun 00:00.
            Record(5, Utc(2026, 2, 1), ViolationType.Warning)
        };
        records[0].Status = TicketStatus.Overdue;
        records[1].Status = TicketStatus.Paid; records[1].ResolvedAt = records[1].IssuedAt.AddDays(7);
        records[2].Status = TicketStatus.Cleared; records[2].ResolvedAt = records[2].IssuedAt.AddDays(8);
        return records;
    }

    private static AppDbContext Context(List<Ticket> records)
    {
        var sanitation = new Ordinance { Id = 1, OrdinanceNo = "011", Series = "2026", MarketCode = "MKT", Title = "Sanitation", Category = ViolationCategory.Sanitation };
        var sanitationSecond = new Ordinance { Id = 2, OrdinanceNo = "012", Series = "2026", MarketCode = "MKT", Title = "Sanitation second", Category = ViolationCategory.Sanitation };
        var licensing = new Ordinance { Id = 3, OrdinanceNo = "013", Series = "2026", MarketCode = "MKT", Title = "Licensing", Category = ViolationCategory.Licensing };
        var links = new List<TicketViolation>();
        void Link(int ticketId, Ordinance ordinance)
        {
            var ticket = records.SingleOrDefault(item => item.Id == ticketId);
            if (ticket is not null) links.Add(new() { TicketId = ticketId, Ticket = ticket, OrdinanceId = ordinance.Id, Ordinance = ordinance });
        }
        Link(2, sanitation); Link(2, sanitationSecond); Link(2, licensing); Link(3, sanitation); Link(4, licensing);
        return new AppDbContext(new DbContextOptionsBuilder<AppDbContext>().Options) {
            Tickets = new AccountDatabaseSet<Ticket>(records),
            TicketViolations = new AccountDatabaseSet<TicketViolation>(links),
            MarketSections = new AccountDatabaseSet<MarketSection>(records.Count == 0 ? [] : [new() { Id = 2, Name = "Produce", Description = "Synthetic section", Tickets = records }]),
            Businesses = new AccountDatabaseSet<Business>([])
        };
    }

    [Fact]
    public async Task Analytics_uses_Manila_year_and_returns_the_correct_year_label_at_new_year()
    {
        await using var context = Context(Records());
        var service = new AdminAnalyticsService(new TicketRepository(context), new AnalyticsClock(Utc(2025, 12, 31, 16, 30)));
        var ratio = await service.GetInspectionRatioAsync();
        Assert.Equal(1, ratio.TicketCount);
        Assert.Equal(100, ratio.TicketPercentage);
        var trend = await service.GetViolationTrendAsync();
        Assert.Equal(12, trend.Count);
        Assert.All(trend, point => Assert.Equal(2026, point.Year));
        Assert.Equal(1, trend[0].LowSeverityCount);
    }

    [Fact]
    public async Task Monthly_and_peak_buckets_use_Manila_calendar_and_clock()
    {
        await using var context = Context(Records());
        var repository = new TicketRepository(context);
        var trend = await repository.GetViolationTrendAsync(Utc(2025, 12, 31, 16), Utc(2026, 2, 20));
        Assert.Equal(1, trend.Single(bucket => bucket.Month == 1 && bucket.Severity == Severity.Minor).Count);
        Assert.Equal(1, trend.Single(bucket => bucket.Month == 1 && bucket.Severity == Severity.Moderate).Count);
        Assert.Equal(1, trend.Single(bucket => bucket.Month == 2 && bucket.Severity == Severity.High).Count);
        Assert.All(trend, bucket => Assert.Equal(2026, bucket.Year));
        var peak = await repository.GetPeakViolationTimesAsync(Utc(2025, 12, 31, 16), Utc(2026, 2, 20));
        Assert.Equal(1, peak.Single(bucket => bucket.DayOfWeek == (int)DayOfWeek.Thursday && bucket.TimeBlock == 0).Count);
        Assert.Equal(1, peak.Single(bucket => bucket.DayOfWeek == (int)DayOfWeek.Saturday && bucket.TimeBlock == 5).Count);
        Assert.Equal(1, peak.Single(bucket => bucket.DayOfWeek == (int)DayOfWeek.Sunday && bucket.TimeBlock == 0).Count);
    }

    [Fact]
    public async Task Annual_counts_preserve_ticket_category_semantics_and_dashboard_remains_a_current_snapshot()
    {
        var records = Records();
        await using var context = Context(records);
        var repository = new TicketRepository(context);
        var service = new AdminAnalyticsService(repository, new AnalyticsClock(Utc(2026, 2, 20, 12)));
        var ratio = await service.GetInspectionRatioAsync();
        Assert.Equal(3, ratio.TicketCount); Assert.Equal(1, ratio.WarningCount); Assert.Equal(4, ratio.TotalInspectionCount);
        Assert.Equal(75, ratio.TicketPercentage); Assert.Equal(25, ratio.WarningPercentage);
        var resolution = await service.GetViolationResolutionRateAsync();
        Assert.Equal(3, resolution.TicketCount); Assert.Equal(1, resolution.ResolvedWithinSevenDays); Assert.Equal(33.3, resolution.ResolutionRate);
        var categories = await service.GetViolationCategoryDistributionAsync();
        Assert.Equal(2, categories.Single(item => item.Category == "Sanitation").TicketCount);
        Assert.Equal(2, categories.Single(item => item.Category == "Licensing").TicketCount);
        Assert.Equal(66.7, categories.Single(item => item.Category == "Sanitation").Percentage);
        var section = Assert.Single(await service.GetMarketSectionAggregationAsync());
        Assert.Equal(4, section.TotalInspectionCount);
        records.Add(Record(6, Utc(2026, 2, 20, 10), ViolationType.Warning));
        var current = await repository.GetDashboardTicketCountsAsync(Utc(2026, 2, 19, 16), Utc(2026, 2, 20, 16));
        Assert.Equal(1, current.InspectionsToday);
        Assert.Equal(2, current.OpenTickets); // Includes the unresolved ticket from the prior year.
        var annual = await service.GetInspectionRatioAsync();
        Assert.Equal(5, annual.TotalInspectionCount);
    }

    [Fact]
    public async Task Prior_year_hotspot_comparison_uses_matching_Manila_calendar_date_across_leap_year()
    {
        await using var context = Context([Record(90, Utc(2024, 2, 29, 16, 15))]);
        var service = new AdminAnalyticsService(new TicketRepository(context), new AnalyticsClock(Utc(2025, 2, 28, 16, 30)));
        var hotspot = Assert.Single(await service.GetHotspotRankingAsync());
        Assert.Equal(0, hotspot.TotalInspectionCount);
        Assert.Equal(1, hotspot.PreviousPeriodCount); // Through Mar 1 00:30 Manila in both years.
    }

    [Fact]
    public async Task Empty_annual_data_returns_zero_totals_and_complete_empty_chart_buckets()
    {
        await using var context = Context([]);
        var service = new AdminAnalyticsService(new TicketRepository(context), new AnalyticsClock(Utc(2026, 2, 20)));
        Assert.Equal(0, (await service.GetInspectionRatioAsync()).TotalInspectionCount);
        Assert.Equal(0, (await service.GetViolationResolutionRateAsync()).ResolutionRate);
        Assert.All(await service.GetViolationCategoryDistributionAsync(), item => Assert.Equal(0, item.Percentage));
        Assert.Equal(12, (await service.GetViolationTrendAsync()).Count);
        Assert.Equal(42, (await service.GetPeakViolationTimesAsync()).Count);
    }

    [Theory]
    [InlineData("HeadAdmin", HttpStatusCode.OK)]
    [InlineData("AdminOfficer", HttpStatusCode.OK)]
    [InlineData("MarketEnforcer", HttpStatusCode.Forbidden)]
    [InlineData("MarketVendor", HttpStatusCode.Forbidden)]
    [InlineData(null, HttpStatusCode.Unauthorized)]
    public async Task All_analytics_routes_enforce_administrator_access(string? role, HttpStatusCode expected)
    {
        await using var context = Context([]);
        await using var host = await AuditHost.CreateAsync(services => services.AddSingleton<IAdminAnalyticsService>(new AdminAnalyticsService(new TicketRepository(context))));
        foreach (var route in new[] { "violation-trend", "peak-violation-times", "violation-type-distribution", "inspection-ratio", "resolution-rate", "market-section-aggregation", "hotspot-ranking", "vendor-risk-ranking" })
        {
            using var response = await host.SendAsync(HttpMethod.Get, $"/api/admin/analytics/{route}", role);
            Assert.Equal(expected, response.StatusCode);
        }
    }
}

internal sealed class AnalyticsClock(DateTime utcNow) : TimeProvider
{
    public override DateTimeOffset GetUtcNow() => new(utcNow);
}
