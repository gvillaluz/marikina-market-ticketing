using MarikinaMarket.API.Application.Services;
using MarikinaMarket.API.Domain.Entities;
using MarikinaMarket.API.Domain.Enums;
using MarikinaMarket.API.Infrastructure.Persistence;
using MarikinaMarket.API.Infrastructure.Repositories;
using Microsoft.EntityFrameworkCore;
using Xunit;

namespace MarikinaMarket.Tests;

// The Tickets page "Level 4–5 tickets" box (#167). The records are synthetic and held in memory.
public class LevelFourToFiveTicketsTests
{
    private static readonly DateTime StartOfThisMonth = new(DateTime.UtcNow.Year, DateTime.UtcNow.Month, 1, 0, 0, 0, DateTimeKind.Utc);

    private static Ticket NewTicket(int id, ViolationType type, int? level, DateTime issuedAt, TicketStatus status = TicketStatus.Pending) => new()
    {
        Id = id, Type = type, SeverityLevel = level, Description = "Synthetic", Status = status,
        IssuedAt = issuedAt, UpdatedAt = issuedAt
    };

    private static TicketService Service(params Ticket[] tickets)
    {
        var context = new AppDbContext(new DbContextOptionsBuilder<AppDbContext>().Options);
        context.Tickets = new AccountDatabaseSet<Ticket>(tickets);
        return new TicketService(new TicketRepository(context), null!, null!, null!, null!, null!, null!);
    }

    [Fact]
    public async Task Resolved_box_counts_only_paid_or_waived_tickets_issued_this_month()
    {
        var thisMonth = StartOfThisMonth.AddMinutes(1);
        var lastMonth = StartOfThisMonth.AddDays(-3);
        var summary = await Service(
            NewTicket(1, ViolationType.Ticket, 1, thisMonth, TicketStatus.Paid),
            NewTicket(2, ViolationType.Ticket, 1, thisMonth, TicketStatus.Waived),
            NewTicket(3, ViolationType.Ticket, 1, thisMonth, TicketStatus.Pending),
            NewTicket(4, ViolationType.Ticket, 1, lastMonth, TicketStatus.Paid),
            NewTicket(5, ViolationType.Ticket, 1, lastMonth, TicketStatus.Waived)
        ).GetTicketAnalyticsAsync();

        // Tickets 1 and 2 only; 2 resolved of 3 issued this month = 66.7%.
        Assert.Equal(2, summary.ResolvedViolationsThisMonth);
        Assert.Equal(66.7, summary.ResolutionRate);
    }

    [Fact]
    public async Task Box_counts_only_tickets_at_level_4_or_5_by_month()
    {
        var thisMonth = StartOfThisMonth.AddMinutes(1);
        var lastMonth = StartOfThisMonth.AddDays(-3);
        var context = new AppDbContext(new DbContextOptionsBuilder<AppDbContext>().Options);
        context.Tickets = new AccountDatabaseSet<Ticket>(
        [
            NewTicket(1, ViolationType.Ticket, 5, thisMonth),
            NewTicket(2, ViolationType.Ticket, 4, thisMonth),
            NewTicket(3, ViolationType.Ticket, 3, thisMonth),
            NewTicket(4, ViolationType.Ticket, null, thisMonth),   // issued before levels existed
            NewTicket(5, ViolationType.Warning, 4, thisMonth),    // warnings are never counted
            NewTicket(6, ViolationType.Ticket, 4, lastMonth),
        ]);
        var service = new TicketService(new TicketRepository(context), null!, null!, null!, null!, null!, null!);

        var summary = await service.GetTicketAnalyticsAsync();

        // Tickets 1 and 2 this month; ticket 6 last month; 1 → 2 is +100%.
        Assert.Equal(2, summary.LevelFourToFiveThisMonth);
        Assert.Equal(100, summary.LevelFourToFiveChangePercentage);
    }
}
