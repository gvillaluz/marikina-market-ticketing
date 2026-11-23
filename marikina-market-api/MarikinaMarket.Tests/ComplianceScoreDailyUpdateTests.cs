using MarikinaMarket.API.Application;
using MarikinaMarket.API.Application.DTOs.Vendor.Internal;
using MarikinaMarket.API.Application.DTOs.Vendor.Request;
using MarikinaMarket.API.Application.Interfaces.Repositories;
using MarikinaMarket.API.Application.Interfaces.Services;
using MarikinaMarket.API.Application.Services;
using MarikinaMarket.API.Domain.Entities;
using MarikinaMarket.API.Domain.Enums;
using MarikinaMarket.API.Infrastructure.BackgroundServices;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging.Abstractions;
using Xunit;

namespace MarikinaMarket.Tests;

public class ComplianceScoreDailyUpdateTests
{
    // 10:00 AM on 23 November in Manila, whose day began at 16:00 UTC on 22 November.
    private static readonly DateTime Now = new(2026, 11, 23, 2, 0, 0, DateTimeKind.Utc);
    private static readonly DateTime StartOfManilaToday = new(2026, 11, 22, 16, 0, 0, DateTimeKind.Utc);
    private static readonly DateTime Yesterday = new(2026, 11, 22, 3, 0, 0, DateTimeKind.Utc);

    // Hand-derived: 1 ticket gives frequency 80 (24 points), Moderate gives severity 66.67 (20 points),
    // 30 days gives recency 50 (10 points), and an unpaid fine past 15 days gives payment 0 (0 points).
    private const int OneModerateUnpaidFineThirtyDaysOld = 54;

    [Fact]
    public async Task Registry_view_only_reads_saved_scores()
    {
        var vendors = ReviewBoundaryProxy.Create<IVendorRepository>((method, _) => method.Name switch
        {
            "GetAdminVendorSummariesAsync" => Task.FromResult(new List<AdminVendorSummary>
            {
                new() { VendorId = 1, BusinessAccountNumber = "0001", VendorName = "Reyes, Nena",
                    MarketSectionName = "Fish Street", ComplianceScore = 73 }
            }),
            "GetAdminVendorSummaryCountAsync" => Task.FromResult(1),
            _ => throw new InvalidOperationException($"Unexpected write: {method.Name}")
        });
        var service = new VendorService(vendors, Reject<IUnitOfWork>(), null!, Reject<IVendorComplianceScoreService>());

        var page = await service.GetAdminVendorSummariesAsync(0, new AdminVendorSummaryFilter());

        Assert.Equal(73, Assert.Single(page.Items).ComplianceScore);
        Assert.Equal(1, page.Total);
    }

    [Fact]
    public async Task Business_score_view_saves_nothing_and_shows_the_last_update()
    {
        var savedAt = new DateTime(2026, 6, 1, 4, 0, 0, DateTimeKind.Utc);
        var boundary = new Boundary { SavedAt = savedAt, Tickets = [Fine(1, savedAt.AddDays(-30))] };
        var service = new VendorService(boundary.Vendors, boundary.Unit, null!, boundary.Scores);

        var score = await service.GetVendorComplianceScoreAsync(1);

        Assert.Equal(OneModerateUnpaidFineThirtyDaysOld, score.ComplianceScore);
        Assert.Equal(30, score.DaysSinceLastTicket);
        Assert.Equal(savedAt, score.CalculatedAt);
        Assert.Empty(boundary.Saves);
    }

    [Fact]
    public async Task Business_score_view_reports_a_missing_business()
    {
        var boundary = new Boundary();
        await Assert.ThrowsAsync<RecordNotFoundException>(() => boundary.Scores.GetSavedAsync(99));
    }

    [Fact]
    public async Task Daily_update_saves_each_due_business_only_if_it_has_not_changed()
    {
        var boundary = new Boundary
        {
            Due = [(1, Yesterday), (2, Yesterday.AddHours(-1))],
            Tickets = [Fine(1, Now.AddDays(-30))]
        };

        await boundary.Scores.RefreshDueAsync(Now);

        Assert.Equal(StartOfManilaToday, boundary.DueBefore);
        Assert.Equal(
            [(1, Yesterday, OneModerateUnpaidFineThirtyDaysOld, Now), (2, Yesterday.AddHours(-1), 100, Now)],
            boundary.Saves);
    }

    [Fact]
    public async Task Daily_update_changes_nothing_when_no_business_is_due()
    {
        var boundary = new Boundary();
        await boundary.Scores.RefreshDueAsync(Now);
        Assert.Empty(boundary.Saves);
        Assert.Equal(0, boundary.TicketReads);
    }

    [Theory]
    [InlineData("2026-11-22T15:59:59Z", "2026-11-21T16:00:00Z")] // 11:59:59 PM Manila, still the 22nd
    [InlineData("2026-11-22T16:00:00Z", "2026-11-22T16:00:00Z")] // midnight Manila, now the 23rd
    public async Task Daily_update_follows_the_Manila_calendar_day(string now, string expectedDueBefore)
    {
        var boundary = new Boundary();
        await boundary.Scores.RefreshDueAsync(Utc(now));
        Assert.Equal(Utc(expectedDueBefore), boundary.DueBefore);
    }

    [Fact]
    public async Task Failed_update_is_recorded_without_details_and_the_next_run_can_succeed()
    {
        var runs = 0;
        var logs = new List<AuditLog>();
        var scores = ReviewBoundaryProxy.Create<IVendorComplianceScoreService>((method, _) =>
        {
            Assert.Equal("RefreshDueAsync", method.Name);
            return ++runs == 1
                ? Task.FromException(new InvalidOperationException("private database detail"))
                : Task.CompletedTask;
        });
        var audit = ReviewBoundaryProxy.Create<IAuditLogService>((method, args) =>
        {
            Assert.Equal("RecordAsync", method.Name);
            logs.Add((AuditLog)args[0]!);
            return Task.CompletedTask;
        });
        using var services = new ServiceCollection().AddScoped(_ => scores).AddScoped(_ => audit).BuildServiceProvider();
        var job = new ComplianceScoreUpdateService(services, NullLogger<ComplianceScoreUpdateService>.Instance);

        await job.RunOnceAsync();
        var log = Assert.Single(logs);
        Assert.Equal("UpdateComplianceScores", log.Action);
        Assert.Equal(Module.Vendors, log.Module);
        Assert.Equal(LogResult.Failed, log.Result);
        Assert.Equal("System compliance score update failed and will be retried.", log.Details);

        await job.RunOnceAsync();
        Assert.Equal(2, runs);
        Assert.Single(logs);
    }

    private static DateTime Utc(string value)
        => DateTime.Parse(value, null, System.Globalization.DateTimeStyles.AdjustToUniversal);

    private static VendorComplianceTicket Fine(int vendorId, DateTime issuedAt) => new()
    {
        VendorId = vendorId, IssuedAt = issuedAt, HighestSeverity = Severity.Moderate,
        PenaltyType = PenaltyType.CashFine, TotalPaymentAmount = 500m, Status = TicketStatus.Pending
    };

    private static T Reject<T>() where T : class => ReviewBoundaryProxy.Create<T>((method, _) =>
        throw new InvalidOperationException($"Unexpected operation: {method.Name}"));

    private sealed class Boundary
    {
        public List<(int Id, DateTime ScoreUpdatedAt)> Due = [];
        public List<VendorComplianceTicket> Tickets = [];
        public List<(int, DateTime, int, DateTime)> Saves = [];
        public DateTime? SavedAt, DueBefore;
        public int TicketReads;
        public IVendorRepository Vendors { get; }
        public IUnitOfWork Unit { get; } = Reject<IUnitOfWork>();
        public VendorComplianceScoreService Scores { get; }

        public Boundary()
        {
            Vendors = ReviewBoundaryProxy.Create<IVendorRepository>((method, args) =>
            {
                switch (method.Name)
                {
                    case "GetBusinessesDueForScoreUpdateAsync":
                        DueBefore = (DateTime)args[0]!;
                        return Task.FromResult(Due);
                    case "GetScoreUpdatedAtAsync":
                        return Task.FromResult(SavedAt);
                    case "SaveScoreIfNotChangedAsync":
                        Saves.Add(((int)args[0]!, (DateTime)args[1]!, (int)args[2]!, (DateTime)args[3]!));
                        return Task.CompletedTask;
                    default:
                        throw new InvalidOperationException($"Unexpected operation: {method.Name}");
                }
            });
            var tickets = ReviewBoundaryProxy.Create<ITicketRepository>((method, args) =>
            {
                Assert.Equal("GetVendorComplianceTicketsAsync", method.Name);
                TicketReads++;
                var ids = (IReadOnlyCollection<int>)args[0]!;
                var start = (DateTime)args[1]!;
                var end = (DateTime)args[2]!;
                return Task.FromResult(Tickets
                    .Where(t => ids.Contains(t.VendorId) && t.IssuedAt >= start && t.IssuedAt <= end).ToList());
            });
            Scores = new VendorComplianceScoreService(Vendors, tickets, Unit);
        }
    }
}
