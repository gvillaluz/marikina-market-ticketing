using System.ComponentModel.DataAnnotations;
using System.Reflection;
using MarikinaMarket.API.Application.DTOs.Tickets.Internal;
using MarikinaMarket.API.Application.Interfaces.Repositories;
using MarikinaMarket.API.Application.Services;
using MarikinaMarket.API.Domain.Entities;
using MarikinaMarket.API.Domain.Enums;
using MarikinaMarket.API.Infrastructure.Persistence;
using MarikinaMarket.API.Infrastructure.Repositories;
using MarikinaMarket.API.Presentation.Controllers;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Xunit;

namespace MarikinaMarket.Tests;

// The Detected violations list on the Recommended Actions page, read from the latest run's saved findings.
public class DetectedViolationsTests
{
    private static readonly DateTime Issued = new(2026, 11, 14, 6, 30, 0, DateTimeKind.Utc);

    // Ticket 30 has two findings, saved Sanitation then Obstruction, so its one row lists them A to Z.
    // A ticket shows its paper number and a warning shows its own number.
    [Fact]
    public async Task One_row_per_record_with_all_its_violations_and_the_number_people_see()
    {
        List<int>? askedIds = null;
        var service = ServiceWith(
            new RecommendationRun { Id = 5, ModelVersion = "test" },
            [Finding(5, 30, "Sanitation"), Finding(5, 30, "Obstruction"), Finding(5, 10, "Traffic")],
            (ids, offset, limit) =>
            {
                askedIds = ids;
                Assert.Equal(0, offset);
                Assert.Equal(11, limit);
                return
                [
                    Summary(30, ViolationType.Ticket, "000030", "P-30"),
                    Summary(10, ViolationType.Warning, "W-10", null)
                ];
            });

        var page = await service.GetDetectedViolationsAsync(0);

        Assert.Equal([10, 30], askedIds!.Order());
        Assert.Equal(2, page.Total);
        Assert.False(page.HasMore);
        Assert.Equal([30, 10], page.Items.Select(item => item.TicketId));
        Assert.Equal(["P-30", "W-10"], page.Items.Select(item => item.ControlNumber));
        Assert.Equal(["Obstruction", "Sanitation"], page.Items[0].CategoryCodes);
        Assert.Equal(["Traffic"], page.Items[1].CategoryCodes);
        Assert.Equal(ViolationType.Ticket, page.Items[0].Type);
        Assert.Equal("Sample Street", page.Items[0].MarketSectionName);
        Assert.Equal("Description 30", page.Items[0].Description);
        Assert.Equal(Issued, page.Items[0].IssuedAt);
    }

    // 11 records: the first page shows 10 and says there are more.
    [Fact]
    public async Task A_full_page_says_there_are_more()
    {
        var findings = Enumerable.Range(1, 11).Select(id => Finding(5, id, "Sanitation")).ToList();
        var service = ServiceWith(
            new RecommendationRun { Id = 5, ModelVersion = "test" },
            findings,
            (ids, offset, limit) => ids.OrderBy(id => id).Skip(offset).Take(limit)
                .Select(id => Summary(id, ViolationType.Warning, $"W-{id}", null)).ToList());

        var first = await service.GetDetectedViolationsAsync(0);
        var second = await service.GetDetectedViolationsAsync(10);

        Assert.Equal(10, first.Items.Count);
        Assert.True(first.HasMore);
        Assert.Equal(11, first.Total);
        Assert.Equal([11], second.Items.Select(item => item.TicketId));
        Assert.False(second.HasMore);
        Assert.Equal(11, second.Total);
    }

    [Fact]
    public async Task No_run_gives_an_empty_page_without_reading_tickets()
    {
        var service = ServiceWith(null, [], (_, _, _) => throw new InvalidOperationException("tickets read"));

        var page = await service.GetDetectedViolationsAsync(0);

        Assert.Empty(page.Items);
        Assert.False(page.HasMore);
        Assert.Equal(0, page.Total);
    }

    [Fact]
    public async Task A_run_with_no_findings_gives_an_empty_page()
    {
        var service = ServiceWith(
            new RecommendationRun { Id = 5, ModelVersion = "test" },
            [],
            (ids, _, _) =>
            {
                Assert.Empty(ids);
                return [];
            });

        var page = await service.GetDetectedViolationsAsync(0);

        Assert.Empty(page.Items);
        Assert.Equal(0, page.Total);
    }

    [Fact]
    public async Task A_negative_offset_is_refused()
    {
        var service = ServiceWith(null, [], (_, _, _) => []);

        await Assert.ThrowsAsync<ValidationException>(() => service.GetDetectedViolationsAsync(-1));
    }

    // Stored 2, 1, 3, 4. Ticket 4 is not in the list. Ticket 3 and 1 share the newest time, so the higher id comes first.
    // Newest first is 3, 1, 2; skipping one and taking one leaves ticket 1.
    [Fact]
    public async Task Ticket_repository_returns_only_the_given_records_newest_first()
    {
        using var context = EmptyContext();
        context.Tickets = new AccountDatabaseSet<Ticket>(
        [
            StoredTicket(2, Issued.AddDays(-1)),
            StoredTicket(1, Issued),
            StoredTicket(3, Issued),
            StoredTicket(4, Issued.AddDays(1))
        ]);
        var repository = new TicketRepository(context);

        var all = await repository.GetDetectedTicketsAsync([1, 2, 3], 0, 10);
        var paged = await repository.GetDetectedTicketsAsync([1, 2, 3], 1, 1);

        Assert.Equal([3, 1, 2], all.Select(ticket => ticket.Id));
        Assert.Equal("Sample Street", all[0].MarketSectionName);
        Assert.Equal("P-3", all[0].PaperReference);
        Assert.Equal("00003", all[0].ControlNumber);
        Assert.Equal("Description 3", all[0].Description);
        Assert.Equal([1], paged.Select(ticket => ticket.Id));
    }

    [Fact]
    public async Task Recommendation_repository_returns_only_that_runs_findings()
    {
        using var context = EmptyContext();
        context.RecommendationFindings = new AccountDatabaseSet<RecommendationFinding>(
        [
            Finding(4, 1, "Traffic"),
            Finding(5, 2, "Sanitation"),
            Finding(5, 3, "Obstruction")
        ]);

        var findings = await new RecommendationRepository(context).GetFindingsAsync(5);

        Assert.Equal([2, 3], findings.Select(finding => finding.TicketId).Order());
    }

    [Fact]
    public void The_route_is_restricted_to_head_admin_and_admin_officer()
    {
        var controller = typeof(AdminRecommendationsController);
        var get = controller.GetMethod(nameof(AdminRecommendationsController.GetDetectedViolations))!
            .GetCustomAttribute<HttpGetAttribute>();

        Assert.Equal("HeadAdmin,AdminOfficer", controller.GetCustomAttribute<AuthorizeAttribute>()?.Roles);
        Assert.Equal("findings", get?.Template);
    }

    private static RecommendationService ServiceWith(
        RecommendationRun? run,
        List<RecommendationFinding> findings,
        Func<List<int>, int, int, List<DetectedTicketSummary>> tickets)
    {
        var recommendations = ReviewBoundaryProxy.Create<IRecommendationRepository>((method, args) => method.Name switch
        {
            nameof(IRecommendationRepository.GetLatestRunAsync) => Task.FromResult(run),
            nameof(IRecommendationRepository.GetFindingsAsync) =>
                Task.FromResult(findings.Where(finding => finding.RecommendationRunId == (int)args[0]!).ToList()),
            _ => throw new InvalidOperationException(method.Name)
        });
        var ticketRepository = ReviewBoundaryProxy.Create<ITicketRepository>((method, args) => method.Name switch
        {
            nameof(ITicketRepository.GetDetectedTicketsAsync) =>
                Task.FromResult(tickets((List<int>)args[0]!, (int)args[1]!, (int)args[2]!)),
            _ => throw new InvalidOperationException(method.Name)
        });
        return new RecommendationService(
            recommendations,
            ReviewBoundaryProxy.Create<IMarketSectionRepository>((method, _) => throw new InvalidOperationException(method.Name)),
            ReviewBoundaryProxy.Create<IUserRepository>((method, _) => throw new InvalidOperationException(method.Name)),
            ticketRepository,
            ReviewBoundaryProxy.Create<IUnitOfWork>((method, _) => throw new InvalidOperationException(method.Name)));
    }

    private static AppDbContext EmptyContext() => new(new DbContextOptionsBuilder<AppDbContext>().Options);

    private static RecommendationFinding Finding(int runId, int ticketId, string code)
        => new() { RecommendationRunId = runId, TicketId = ticketId, CategoryCode = code };

    private static DetectedTicketSummary Summary(int id, ViolationType type, string? controlNumber, string? paperReference) => new()
    {
        Id = id,
        ControlNumber = controlNumber,
        PaperReference = paperReference,
        Type = type,
        MarketSectionName = "Sample Street",
        Description = $"Description {id}",
        IssuedAt = Issued
    };

    private static Ticket StoredTicket(int id, DateTime issuedAt) => new()
    {
        Id = id,
        ControlNumber = $"0000{id}",
        PaperReference = $"P-{id}",
        Type = ViolationType.Ticket,
        MarketSection = new MarketSection { Id = 1, Name = "Sample Street" },
        Description = $"Description {id}",
        IssuedAt = issuedAt
    };
}
