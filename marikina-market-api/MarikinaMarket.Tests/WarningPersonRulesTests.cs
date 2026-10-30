using MarikinaMarket.API.Domain.Entities;
using MarikinaMarket.API.Domain.Enums;
using MarikinaMarket.API.Infrastructure.Persistence;
using MarikinaMarket.API.Infrastructure.Repositories;
using Microsoft.EntityFrameworkCore;
using Xunit;

namespace MarikinaMarket.Tests;

public class WarningPersonRulesTests
{
    [Fact]
    public async Task Warning_history_uses_person_and_ordinance_across_businesses_and_dates()
    {
        using var context = Context();
        var own = Record(1, 31, 17, ViolationType.Warning, null, new DateTime(2020, 1, 1, 0, 0, 0, DateTimeKind.Utc));
        var other = Record(2, 32, 17, ViolationType.Warning, null, DateTime.UtcNow);
        var unidentified = Record(3, null, 17, ViolationType.Warning, null, DateTime.UtcNow);
        var citation = Record(4, 33, 17, ViolationType.Ticket, TicketStatus.Pending, DateTime.UtcNow);
        context.Tickets = new AccountDatabaseSet<Ticket>([own, other, unidentified, citation]);
        var repository = new TicketRepository(context);
        Assert.Equal(5, Assert.Single(await repository.GetWarningOrdinancesForPerson(31, [5])).OrdinanceId);
        own.VendorId = 99;
        own.EnforcerId = 77;
        Assert.Single(await repository.GetWarningOrdinancesForPerson(31, [5]));
        Assert.Empty(await repository.GetWarningOrdinancesForPerson(31, [6]));
        Assert.Empty(await repository.GetWarningOrdinancesForPerson(33, [5]));
        Assert.Empty(await repository.GetWarningOrdinancesForPerson(34, [5]));
    }

    [Theory]
    [InlineData(TicketStatus.Pending, true)]
    [InlineData(TicketStatus.InProgress, false)]
    [InlineData(TicketStatus.Paid, false)]
    [InlineData(TicketStatus.Cleared, false)]
    [InlineData(TicketStatus.Waived, false)]
    [InlineData(TicketStatus.Contested, false)]
    [InlineData(TicketStatus.Overdue, false)]
    public async Task Citation_blocks_warning_only_when_pending_in_same_Manila_day(TicketStatus status, bool blocks)
    {
        using var context = Context();
        var now = new DateTime(2026, 10, 30, 4, 0, 0, DateTimeKind.Utc);
        var start = new DateTime(2026, 10, 29, 16, 0, 0, DateTimeKind.Utc);
        context.Tickets = new AccountDatabaseSet<Ticket>([
            Record(1, 31, 99, ViolationType.Ticket, status, start),
            Record(2, 31, 17, ViolationType.Ticket, TicketStatus.Pending, start.AddTicks(-1)),
            Record(3, 31, 17, ViolationType.Ticket, TicketStatus.Pending, start.AddDays(1)),
            Record(4, 32, 17, ViolationType.Ticket, TicketStatus.Pending, now),
            Record(5, null, 17, ViolationType.Ticket, TicketStatus.Pending, now),
            Record(6, 31, 17, ViolationType.Warning, TicketStatus.Pending, now)
        ]);
        var repository = new TicketRepository(context);
        Assert.Equal(blocks ? 1 : 0, (await repository.GetPersonPendingWarningConflictsAsync(31, [5], now)).Count);
        Assert.Empty(await repository.GetPersonPendingWarningConflictsAsync(31, [6], now));
    }

    private static AppDbContext Context() => new(new DbContextOptionsBuilder<AppDbContext>().Options);
    private static Ticket Record(int id, int? person, int business, ViolationType type, TicketStatus? status, DateTime time)
    {
        var ordinance = new Ordinance { Id = 5, OrdinanceNo = "011", Series = "2014", MarketCode = "FISH", Title = "Sanitation" };
        return new Ticket
        {
            Id = id, PersonId = person, VendorId = business, Type = type, Status = status,
            Description = "Synthetic sanitation inspection", IssuedAt = time,
            TicketViolations = [new() { OrdinanceId = 5, Ordinance = ordinance }]
        };
    }
}
