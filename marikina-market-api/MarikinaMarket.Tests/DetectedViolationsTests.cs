using System.ComponentModel.DataAnnotations;
using System.Reflection;
using MarikinaMarket.API.Application.DTOs.Tickets.Internal;
using MarikinaMarket.API.Application.DTOs.Tickets.Request;
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

// The Detected violations page, read from the latest run's saved findings.
public class DetectedViolationsTests
{
    private static readonly DateTime Issued = new(2026, 11, 14, 6, 30, 0, DateTimeKind.Utc);
    private static readonly DetectedViolationFilters NoFilters = new();

    // Ticket 30 has two findings, saved Sanitation then Obstruction, so its one row lists them A to Z.
    // A ticket shows its paper number and a warning shows its own number.
    [Fact]
    public async Task One_row_per_record_with_all_its_violations_and_the_number_people_see()
    {
        List<int>? askedIds = null;
        var service = ServiceWith(
            LatestRun(),
            [Finding(5, 30, "Sanitation"), Finding(5, 30, "Obstruction"), Finding(5, 10, "Traffic")],
            (ids, filters, offset, limit) =>
            {
                askedIds = ids;
                Assert.Same(NoFilters, filters);
                Assert.Equal(0, offset);
                Assert.Equal(10, limit);
                return ([Summary(30, ViolationType.Ticket, "000030", "P-30"), Summary(10, ViolationType.Warning, "W-10", null)], 2);
            });

        var page = await service.GetDetectedViolationsAsync(0, NoFilters);

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

    // 11 records: the first page shows 10 and says there are more; the second shows the last one.
    [Fact]
    public async Task A_full_page_says_there_are_more()
    {
        var findings = Enumerable.Range(1, 11).Select(id => Finding(5, id, "Sanitation")).ToList();
        var service = ServiceWith(LatestRun(), findings, (ids, _, offset, limit) =>
            (ids.Order().Skip(offset).Take(limit).Select(id => Summary(id, ViolationType.Warning, $"W-{id}", null)).ToList(), ids.Count));

        var first = await service.GetDetectedViolationsAsync(0, NoFilters);
        var second = await service.GetDetectedViolationsAsync(10, NoFilters);

        Assert.Equal(10, first.Items.Count);
        Assert.True(first.HasMore);
        Assert.Equal(11, first.Total);
        Assert.Equal([11], second.Items.Select(item => item.TicketId));
        Assert.False(second.HasMore);
        Assert.Equal(11, second.Total);
    }

    // Tickets 30 and 20 have Sanitation; 10 does not. Ticket 30's row still lists its other violation.
    [Fact]
    public async Task The_violation_filter_keeps_matching_records_and_all_their_violations()
    {
        List<int>? askedIds = null;
        var filters = new DetectedViolationFilters { CategoryCode = "Sanitation" };
        var service = ServiceWith(
            LatestRun(),
            [Finding(5, 30, "Sanitation"), Finding(5, 30, "Obstruction"), Finding(5, 20, "Sanitation"), Finding(5, 10, "Traffic")],
            (ids, passed, _, _) =>
            {
                askedIds = ids;
                Assert.Same(filters, passed);
                return ([Summary(30, ViolationType.Ticket, "000030", "P-30"), Summary(20, ViolationType.Ticket, "000020", "P-20")], 2);
            });

        var page = await service.GetDetectedViolationsAsync(0, filters);

        Assert.Equal([20, 30], askedIds!.Order());
        Assert.Equal(["Obstruction", "Sanitation"], page.Items[0].CategoryCodes);
        Assert.Equal(2, page.Total);
    }

    [Fact]
    public async Task No_run_gives_an_empty_page_without_reading_tickets()
    {
        var service = ServiceWith(null, [], (_, _, _, _) => throw new InvalidOperationException("tickets read"));

        var page = await service.GetDetectedViolationsAsync(0, NoFilters);

        Assert.Empty(page.Items);
        Assert.False(page.HasMore);
        Assert.Equal(0, page.Total);
    }

    [Fact]
    public async Task A_run_with_no_findings_gives_an_empty_page()
    {
        var service = ServiceWith(LatestRun(), [], (ids, _, _, _) =>
        {
            Assert.Empty(ids);
            return ([], 0);
        });

        var page = await service.GetDetectedViolationsAsync(0, NoFilters);

        Assert.Empty(page.Items);
        Assert.Equal(0, page.Total);
    }

    [Fact]
    public async Task A_negative_offset_is_refused()
    {
        var service = ServiceWith(null, [], (_, _, _, _) => ([], 0));

        await Assert.ThrowsAsync<ValidationException>(() => service.GetDetectedViolationsAsync(-1, NoFilters));
    }

    // Stored 2, 1, 3, 4. Ticket 4 is not in the list. Tickets 3 and 1 share the newest time, so the higher id comes first.
    // Newest first is 3, 1, 2; skipping one and taking one leaves ticket 1, and the total stays 3.
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

        var all = await repository.GetDetectedTicketsAsync([1, 2, 3], NoFilters, 0, 10);
        var paged = await repository.GetDetectedTicketsAsync([1, 2, 3], NoFilters, 1, 1);

        Assert.Equal([3, 1, 2], all.Items.Select(ticket => ticket.Id));
        Assert.Equal(3, all.Total);
        Assert.Equal("Sample Street", all.Items[0].MarketSectionName);
        Assert.Equal("P-3", all.Items[0].PaperReference);
        Assert.Equal("00003", all.Items[0].ControlNumber);
        Assert.Equal("Description 3", all.Items[0].Description);
        Assert.Equal([1], paged.Items.Select(ticket => ticket.Id));
        Assert.Equal(3, paged.Total);
    }

    // Ticket 1: street 1. Warning 2: street 2. Ticket 3: street 2.
    [Fact]
    public async Task Ticket_repository_filters_by_type_and_street()
    {
        using var context = EmptyContext();
        context.Tickets = new AccountDatabaseSet<Ticket>(
        [
            StoredTicket(1, Issued, marketSectionId: 1),
            StoredTicket(2, Issued, ViolationType.Warning, marketSectionId: 2),
            StoredTicket(3, Issued, marketSectionId: 2)
        ]);
        var repository = new TicketRepository(context);

        var warnings = await repository.GetDetectedTicketsAsync([1, 2, 3], new() { Type = ViolationType.Warning }, 0, 10);
        var street = await repository.GetDetectedTicketsAsync([1, 2, 3], new() { MarketSectionId = 2 }, 0, 10);
        var both = await repository.GetDetectedTicketsAsync([1, 2, 3], new() { MarketSectionId = 2, Type = ViolationType.Ticket }, 0, 10);

        Assert.Equal([2], warnings.Items.Select(ticket => ticket.Id));
        Assert.Equal([3, 2], street.Items.Select(ticket => ticket.Id));
        Assert.Equal([3], both.Items.Select(ticket => ticket.Id));
        Assert.Equal(1, both.Total);
    }

    // Search covers the number people see and the description, ignoring case.
    // Ticket 1's hidden running number is 00001, so searching it must not find the ticket.
    [Fact]
    public async Task Search_finds_the_shown_number_or_description_but_not_a_tickets_hidden_number()
    {
        using var context = EmptyContext();
        var warning = StoredTicket(2, Issued, ViolationType.Warning);
        warning.ControlNumber = "W-0884";
        var described = StoredTicket(3, Issued);
        described.Description = "Maruming sahig sa puwesto";
        context.Tickets = new AccountDatabaseSet<Ticket>([StoredTicket(1, Issued), warning, described]);
        var repository = new TicketRepository(context);

        Assert.Equal([1], (await repository.GetDetectedTicketsAsync([1, 2, 3], new() { Search = "p-1" }, 0, 10)).Items.Select(t => t.Id));
        Assert.Equal([2], (await repository.GetDetectedTicketsAsync([1, 2, 3], new() { Search = "w-0884" }, 0, 10)).Items.Select(t => t.Id));
        Assert.Equal([3], (await repository.GetDetectedTicketsAsync([1, 2, 3], new() { Search = "  SAHIG " }, 0, 10)).Items.Select(t => t.Id));
        Assert.Empty((await repository.GetDetectedTicketsAsync([1, 2, 3], new() { Search = "00001" }, 0, 10)).Items);
    }

    // Ticket 1 is newer but only contains "basura" inside "basurahan". Ticket 2 has the whole word, so it comes first.
    [Fact]
    public async Task A_whole_word_search_match_comes_before_a_newer_partial_match()
    {
        using var context = EmptyContext();
        var partial = StoredTicket(1, Issued);
        partial.Description = "Walang takip ang basurahan";
        var whole = StoredTicket(2, Issued.AddDays(-3));
        whole.Description = "May basura sa sahig";
        context.Tickets = new AccountDatabaseSet<Ticket>([partial, whole]);

        var result = await new TicketRepository(context).GetDetectedTicketsAsync([1, 2], new() { Search = "basura" }, 0, 10);

        Assert.Equal([2, 1], result.Items.Select(ticket => ticket.Id));
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

    // Run 5 has three findings on two records; run 4's record does not count.
    [Fact]
    public async Task The_detected_count_counts_each_record_once()
    {
        using var context = EmptyContext();
        context.RecommendationFindings = new AccountDatabaseSet<RecommendationFinding>(
        [
            Finding(4, 9, "Traffic"),
            Finding(5, 2, "Sanitation"),
            Finding(5, 2, "Obstruction"),
            Finding(5, 3, "Obstruction")
        ]);

        Assert.Equal(2, await new RecommendationRepository(context).CountDetectedRecordsAsync(5));
    }

    [Theory]
    [InlineData(201, 1, 10, false)]
    [InlineData(200, 0, 10, false)]
    [InlineData(200, 1, 65, false)]
    [InlineData(200, 1, 64, true)]
    public void Filters_are_validated(int searchLength, int street, int violationLength, bool valid)
    {
        var filters = new DetectedViolationFilters
        {
            Search = new string('a', searchLength),
            MarketSectionId = street,
            CategoryCode = new string('b', violationLength)
        };

        Assert.Equal(valid, Validator.TryValidateObject(filters, new ValidationContext(filters), null, validateAllProperties: true));
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

    private static RecommendationRun LatestRun() => new() { Id = 5, ModelVersion = "test" };

    private static RecommendationService ServiceWith(
        RecommendationRun? run,
        List<RecommendationFinding> findings,
        Func<List<int>, DetectedViolationFilters, int, int, (List<DetectedTicketSummary> Items, int Total)> tickets)
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
                Task.FromResult(tickets((List<int>)args[0]!, (DetectedViolationFilters)args[1]!, (int)args[2]!, (int)args[3]!)),
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

    private static Ticket StoredTicket(int id, DateTime issuedAt, ViolationType type = ViolationType.Ticket, int marketSectionId = 1) => new()
    {
        Id = id,
        ControlNumber = $"0000{id}",
        PaperReference = $"P-{id}",
        Type = type,
        MarketSectionId = marketSectionId,
        MarketSection = new MarketSection { Id = marketSectionId, Name = "Sample Street" },
        Description = $"Description {id}",
        IssuedAt = issuedAt
    };
}
