using MarikinaMarket.API.Domain.Entities;
using MarikinaMarket.API.Domain.Enums;
using MarikinaMarket.API.Infrastructure.Persistence;
using MarikinaMarket.API.Infrastructure.Repositories;
using Microsoft.EntityFrameworkCore;
using Xunit;

namespace MarikinaMarket.Tests;

public class TicketPersonRulesTests
{
    [Fact]
    public async Task Every_citation_status_and_penalty_counts_once_per_person_and_ordinance()
    {
        var ordinance = new Ordinance { Id = 5, OrdinanceNo = "011", Series = "2014", MarketCode = "FISH", Title = "Sanitation" };
        var id = 0;
        foreach (var status in Enum.GetValues<TicketStatus>())
            foreach (var penalty in Enum.GetValues<PenaltyType>())
            {
                var ticket = Citation(++id, 1, status, DateTime.UtcNow); ticket.PenaltyType = penalty;
                ordinance.TicketViolations.Add(new() { TicketId = id, Ticket = ticket, OrdinanceId = 5 });
            }
        var expected = Enum.GetValues<TicketStatus>().Length * Enum.GetValues<PenaltyType>().Length;
        // Duplicate database association does not make a second offense for one ticket/ordinance.
        ordinance.TicketViolations.Add(ordinance.TicketViolations.First());
        ordinance.TicketViolations.Add(new() { TicketId = ++id, Ticket = Citation(id, 2, TicketStatus.Pending, DateTime.UtcNow), OrdinanceId = 5 });
        var warning = Citation(++id, 1, TicketStatus.Pending, DateTime.UtcNow); warning.Type = ViolationType.Warning;
        ordinance.TicketViolations.Add(new() { TicketId = id, Ticket = warning, OrdinanceId = 5 });
        using var context = Context(); context.Ordinances = new AccountDatabaseSet<Ordinance>([ordinance]);
        var result = Assert.Single(await new OrdinanceRepository(context).GetByPersonIdsAsync([5], 1));
        Assert.Equal(expected, result.OffenseCount);
    }

    [Theory]
    [InlineData(TicketStatus.Pending, true)]
    [InlineData(TicketStatus.InProgress, true)]
    [InlineData(TicketStatus.Paid, false)]
    [InlineData(TicketStatus.Cleared, false)]
    [InlineData(TicketStatus.Waived, false)]
    [InlineData(TicketStatus.Contested, false)]
    [InlineData(TicketStatus.Overdue, false)]
    public async Task Duplicate_uses_person_ordinance_Manila_day_and_only_active_status(TicketStatus status, bool duplicate)
    {
        var now = new DateTime(2026, 10, 28, 16, 5, 0, DateTimeKind.Utc); // Oct 29, 00:05 Manila.
        var ordinance = new Ordinance { Id = 5, OrdinanceNo = "011", Series = "2014", MarketCode = "FISH", Title = "Sanitation" };
        var ticket = Citation(1, 1, status, now.AddMinutes(-4)); ticket.VendorId = 99; ticket.EnforcerId = 88;
        ticket.TicketViolations = [new() { OrdinanceId = 5, Ordinance = ordinance }];
        var yesterday = Citation(2, 1, TicketStatus.Pending, now.AddMinutes(-6));
        yesterday.TicketViolations = [new() { OrdinanceId = 5, Ordinance = ordinance }];
        var anotherPerson = Citation(3, 2, TicketStatus.Pending, now);
        anotherPerson.TicketViolations = [new() { OrdinanceId = 5, Ordinance = ordinance }];
        using var context = Context(); context.Tickets = new AccountDatabaseSet<Ticket>([ticket, yesterday, anotherPerson]);
        var repository = new TicketRepository(context);
        Assert.Equal(duplicate ? 1 : 0, (await repository.GetPersonDuplicatesAsync(1, [5], now)).Count);
        Assert.Empty(await repository.GetPersonDuplicatesAsync(1, [6], now));
        Assert.Empty(await repository.GetPersonDuplicatesAsync(1, [5], now.AddDays(1)));
    }

    [Fact]
    public async Task Incomplete_name_returns_distinct_candidates_without_merging()
    {
        using var context = Context();
        context.Persons = new AccountDatabaseSet<Person>([
            new() { Id = 1, FullName = "Juan Dela Cruz", Address = "12 Market Lane" },
            new() { Id = 2, FullName = "Juan Cruz", Address = "25 River Lane" },
            new() { Id = 3, FullName = "Maria Santos", Address = "31 Market Lane" }
        ]);
        var (items, total) = await new PersonRepository(context).MatchAsync(["juan", "cruz"], null, null, 0, 10);
        Assert.Equal(2, total); Assert.Equal(new[] { 1, 2 }, items.Select(p => p.Id).Order());
    }

    private static AppDbContext Context() => new(new DbContextOptionsBuilder<AppDbContext>().Options);
    private static Ticket Citation(int id, int person, TicketStatus status, DateTime date) => new()
    { Id = id, PersonId = person, PaperViolatorName = "Juan Cruz", VendorId = 10, Description = "Synthetic sanitation citation", Type = ViolationType.Ticket, Status = status, IssuedAt = date };
}
