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

    [Fact]
    public async Task Every_chart_counts_each_saved_record_once_with_unregistered_vendors_and_several_violations()
    {
        // "Today" is 7 Nov 2026 (Manila). Records worked out by hand, all times Manila unless stated:
        //  T1 ticket, Produce, registered Shop A, Mon 2 Feb 10:30, High, Paid after 3 days. Violations: Sanitation, Sanitation, Licensing.
        //  T2 ticket, Produce, unregistered vendor, Tue 10 Feb 02:30 (Mon 9 Feb 18:30 UTC), Moderate, still Pending. Violation: Licensing. Blood donation.
        //  T3 ticket, Meat, unregistered vendor, Sun 15 Mar 12:00, Minor, Waived after 8 days. Violation: Noise. Community service.
        //  T4 ticket, Produce, registered Shop A, Wed 1 Apr 00:30 (Tue 31 Mar 16:30 UTC), Minor, Waived after 1 day. Violation: Noise. Blood donation.
        //  W1 warning, Produce, unregistered vendor, 3 Feb.   W2 warning, Produce, registered Shop A, 4 May.
        //  Last year: a Meat ticket (1 Jun 2025), a Meat warning (1 Sep 2025), and a Produce ticket one minute before 2026 starts (31 Dec 2025 23:59).
        var produce = new MarketSection { Id = 2, Name = "Produce", Description = "Synthetic section" };
        var meat = new MarketSection { Id = 3, Name = "Meat", Description = "Synthetic section" };
        var shop = new Business
        {
            Id = 1, BusinessAccountNumber = "BA-0001", BusinessName = "Synthetic Shop A", QrCodeValue = "synthetic-1",
            ComplianceScore = 70, MarketSectionId = 2
        };
        var t1 = Record(1, Utc(2026, 2, 2, 2, 30), severity: Severity.High);
        t1.Status = TicketStatus.Paid; t1.ResolvedAt = t1.IssuedAt.AddDays(3); t1.VendorId = 1;
        var t2 = Record(2, Utc(2026, 2, 9, 18, 30), severity: Severity.Moderate);
        t2.PersonId = 1; t2.PenaltyType = PenaltyType.BloodDonation;
        var t3 = Record(3, Utc(2026, 3, 15, 4), severity: Severity.Minor);
        t3.PersonId = 1; t3.PenaltyType = PenaltyType.CommunityService;
        t3.Status = TicketStatus.Waived; t3.ResolvedAt = t3.IssuedAt.AddDays(8);
        var t4 = Record(4, Utc(2026, 3, 31, 16, 30), severity: Severity.Minor);
        t4.Status = TicketStatus.Waived; t4.ResolvedAt = t4.IssuedAt.AddDays(1); t4.VendorId = 1;
        t4.PenaltyType = PenaltyType.BloodDonation;
        var w1 = Record(5, Utc(2026, 2, 3, 1), ViolationType.Warning); w1.HighestSeverity = null; w1.PersonId = 1;
        var w2 = Record(6, Utc(2026, 5, 4), ViolationType.Warning); w2.HighestSeverity = null; w2.VendorId = 1;
        var lastYearMeatTicket = Record(7, Utc(2025, 6, 1));
        var lastYearMeatWarning = Record(8, Utc(2025, 9, 1), ViolationType.Warning); lastYearMeatWarning.HighestSeverity = null;
        var lastYearProduceTicket = Record(9, Utc(2025, 12, 31, 15, 59));
        foreach (var record in new[] { t3, lastYearMeatTicket, lastYearMeatWarning }) record.MarketSectionId = 3;
        var records = new List<Ticket> { t1, t2, t3, t4, w1, w2, lastYearMeatTicket, lastYearMeatWarning, lastYearProduceTicket };
        produce.Tickets = records.Where(record => record.MarketSectionId == 2).ToList();
        meat.Tickets = records.Where(record => record.MarketSectionId == 3).ToList();
        shop.Tickets = [t1, t4, w2];
        var sanitationA = new Ordinance { Id = 1, OrdinanceNo = "011", Series = "2026", Section = "MKT", Title = "Sanitation A", Category = ViolationCategory.Sanitation };
        var sanitationB = new Ordinance { Id = 2, OrdinanceNo = "012", Series = "2026", Section = "MKT", Title = "Sanitation B", Category = ViolationCategory.Sanitation };
        var licensing = new Ordinance { Id = 3, OrdinanceNo = "013", Series = "2026", Section = "MKT", Title = "Licensing", Category = ViolationCategory.Licensing };
        var noise = new Ordinance { Id = 4, OrdinanceNo = "014", Series = "2026", Section = "MKT", Title = "Noise", Category = ViolationCategory.Noise };
        var links = new List<TicketViolation>();
        void Link(Ticket ticket, Ordinance ordinance)
            => links.Add(new() { TicketId = ticket.Id, Ticket = ticket, OrdinanceId = ordinance.Id, Ordinance = ordinance });
        Link(t1, sanitationA); Link(t1, sanitationB); Link(t1, licensing); Link(t2, licensing); Link(t3, noise); Link(t4, noise);
        await using var context = new AppDbContext(new DbContextOptionsBuilder<AppDbContext>().Options)
        {
            Tickets = new AccountDatabaseSet<Ticket>(records),
            TicketViolations = new AccountDatabaseSet<TicketViolation>(links),
            MarketSections = new AccountDatabaseSet<MarketSection>([produce, meat]),
            Businesses = new AccountDatabaseSet<Business>([shop])
        };
        var service = new AdminAnalyticsService(new TicketRepository(context), new AnalyticsClock(Utc(2026, 11, 7, 12)));

        // Warnings and tickets: 2 and 4 (last year's three records are left out); 4 of 6 and 2 of 6.
        var ratio = await service.GetInspectionRatioAsync();
        Assert.Equal(2, ratio.WarningCount); Assert.Equal(4, ratio.TicketCount); Assert.Equal(6, ratio.TotalInspectionCount);
        Assert.Equal(66.7, ratio.TicketPercentage); Assert.Equal(33.3, ratio.WarningPercentage);

        // Resolved within 7 days: T1 (3 days) and T4 (1 day). T3 took 8 days and T2 is still pending. 2 of 4 = 50%.
        var resolution = await service.GetViolationResolutionRateAsync();
        Assert.Equal(4, resolution.TicketCount); Assert.Equal(2, resolution.ResolvedWithinSevenDays); Assert.Equal(50, resolution.ResolutionRate);

        // Tickets only, by Manila month and highest severity: Feb High 1 (T1) and Moderate 1 (T2), Mar Minor 1 (T3), Apr Minor 1 (T4). May's warning adds nothing.
        var trend = await service.GetViolationTrendAsync();
        Assert.Equal((1, 1, 0), (trend[1].HighSeverityCount, trend[1].MediumSeverityCount, trend[1].LowSeverityCount));
        Assert.Equal((0, 0, 1), (trend[2].HighSeverityCount, trend[2].MediumSeverityCount, trend[2].LowSeverityCount));
        Assert.Equal((0, 0, 1), (trend[3].HighSeverityCount, trend[3].MediumSeverityCount, trend[3].LowSeverityCount));
        Assert.Equal(0, trend[4].HighSeverityCount + trend[4].MediumSeverityCount + trend[4].LowSeverityCount);
        Assert.Equal(4, trend.Sum(point => point.HighSeverityCount + point.MediumSeverityCount + point.LowSeverityCount));

        // Tickets only, by Manila weekday and 4-hour block: Mon 8AM-12PM (T1), Tue 12AM-4AM (T2), Sun 12PM-4PM (T3), Wed 12AM-4AM (T4).
        var peaks = await service.GetPeakViolationTimesAsync();
        Assert.Equal(4, peaks.Sum(cell => cell.TicketCount));
        Assert.Equal(1, peaks.Single(cell => cell.DayOfWeek == (int)DayOfWeek.Monday && cell.TimeBlock == 2).TicketCount);
        Assert.Equal(1, peaks.Single(cell => cell.DayOfWeek == (int)DayOfWeek.Tuesday && cell.TimeBlock == 0).TicketCount);
        Assert.Equal(1, peaks.Single(cell => cell.DayOfWeek == (int)DayOfWeek.Sunday && cell.TimeBlock == 3).TicketCount);
        Assert.Equal(1, peaks.Single(cell => cell.DayOfWeek == (int)DayOfWeek.Wednesday && cell.TimeBlock == 0).TicketCount);

        // A ticket counts once per category: Sanitation 1 (T1 has two Sanitation violations), Licensing 2 (T1, T2), Noise 2 (T3, T4), out of 4 tickets.
        var categories = await service.GetViolationCategoryDistributionAsync();
        Assert.Equal((1, 25), (categories.Single(item => item.Category == "Sanitation").TicketCount, categories.Single(item => item.Category == "Sanitation").Percentage));
        Assert.Equal((2, 50), (categories.Single(item => item.Category == "Licensing").TicketCount, categories.Single(item => item.Category == "Licensing").Percentage));
        Assert.Equal((2, 50), (categories.Single(item => item.Category == "Noise").TicketCount, categories.Single(item => item.Category == "Noise").Percentage));
        Assert.Equal(5, categories.Sum(item => item.TicketCount));

        // Sections keep warnings and tickets apart: Meat 0 warnings and 1 ticket (T3); Produce 2 warnings (W1, W2) and 3 tickets (T1, T2, T4).
        var sections = await service.GetMarketSectionAggregationAsync();
        var sectionMeat = sections.Single(section => section.MarketSectionName == "Meat");
        var sectionProduce = sections.Single(section => section.MarketSectionName == "Produce");
        Assert.Equal((0, 1, 1), (sectionMeat.WarningCount, sectionMeat.TicketCount, sectionMeat.TotalInspectionCount));
        Assert.Equal((2, 3, 5), (sectionProduce.WarningCount, sectionProduce.TicketCount, sectionProduce.TotalInspectionCount));

        // Hotspots: Produce 2 + 3 = 5, up from 0 before (last year's 31 Dec 23:59 ticket is after 7 Nov 2025). Meat 0 + 1 = 1, down from 2 (a ticket and a warning).
        var hotspots = await service.GetHotspotRankingAsync();
        Assert.Equal(["Produce", "Meat"], hotspots.Select(hotspot => hotspot.MarketSectionName));
        Assert.Equal((1, 2, 3, 5, 0, "Rising"), (hotspots[0].Rank, hotspots[0].WarningCount, hotspots[0].TicketCount, hotspots[0].TotalInspectionCount, hotspots[0].PreviousPeriodCount, hotspots[0].Trend));
        Assert.Equal((2, 0, 1, 1, 2, "Falling"), (hotspots[1].Rank, hotspots[1].WarningCount, hotspots[1].TicketCount, hotspots[1].TotalInspectionCount, hotspots[1].PreviousPeriodCount, hotspots[1].Trend));

        // Only the registered business is ranked: 2 offenses (T1, T4, not W2, not the unregistered tickets), highest severity High, risk 100 - 70 = 30.
        var risk = Assert.Single(await service.GetVendorRiskRankingAsync());
        Assert.Equal(("BA-0001", 2, Severity.High, 30), (risk.BusinessAccountNumber, risk.OffenseCount, risk.HighestSeverity, risk.RiskScore));
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
        var sanitation = new Ordinance { Id = 1, OrdinanceNo = "011", Series = "2026", Section = "MKT", Title = "Sanitation", Category = ViolationCategory.Sanitation };
        var sanitationSecond = new Ordinance { Id = 2, OrdinanceNo = "012", Series = "2026", Section = "MKT", Title = "Sanitation second", Category = ViolationCategory.Sanitation };
        var licensing = new Ordinance { Id = 3, OrdinanceNo = "013", Series = "2026", Section = "MKT", Title = "Licensing", Category = ViolationCategory.Licensing };
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
        Assert.Equal(1, current.WarningsToday);
        Assert.Equal(0, current.TicketsToday);
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
