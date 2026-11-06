using MarikinaMarket.API.Application;
using MarikinaMarket.API.Application.Services;
using MarikinaMarket.API.Domain.Entities;
using MarikinaMarket.API.Domain.Enums;
using MarikinaMarket.API.Infrastructure.Persistence;
using MarikinaMarket.API.Infrastructure.Repositories;
using Microsoft.EntityFrameworkCore;
using Xunit;

namespace MarikinaMarket.Tests;

// Slice A2a: ordinance shortcuts (person's past violations, my recent, market's most violated in 30 days).
// Every expected list below is worked out by hand from the synthetic tickets, not copied from output.
public class OrdinanceShortcutsTests
{
    private const int Me = 10;
    private const int OtherEnforcer = 20;

    private static Ordinance NewOrdinance(int id, bool active = true) => new()
    {
        Id = id, OrdinanceNo = "011", Series = "2014", Section = id.ToString(), Title = $"Synthetic rule {id}",
        IsActive = active
    };

    private static AppDbContext Context(List<Ordinance> ordinances,
        params (int Id, int PersonId, int EnforcerId, ViolationType Type, int DaysAgo, int[] OrdinanceIds)[] tickets)
    {
        var now = DateTime.UtcNow;
        var byId = ordinances.ToDictionary(o => o.Id);
        var ticketRows = new List<Ticket>();
        var violationRows = new List<TicketViolation>();
        foreach (var t in tickets)
        {
            var ticket = new Ticket
            {
                Id = t.Id, PersonId = t.PersonId, EnforcerId = t.EnforcerId, Type = t.Type, Description = "Synthetic",
                IssuedAt = now.AddDays(-t.DaysAgo)
            };
            foreach (var ordinanceId in t.OrdinanceIds)
            {
                var violation = new TicketViolation
                {
                    TicketId = ticket.Id, Ticket = ticket, OrdinanceId = ordinanceId, Ordinance = byId[ordinanceId], OffenseCount = 1
                };
                ticket.TicketViolations.Add(violation);
                violationRows.Add(violation);
            }
            ticketRows.Add(ticket);
        }
        var context = new AppDbContext(new DbContextOptionsBuilder<AppDbContext>().Options);
        context.Ordinances = new AccountDatabaseSet<Ordinance>(ordinances);
        context.Tickets = new AccountDatabaseSet<Ticket>(ticketRows);
        context.TicketViolations = new AccountDatabaseSet<TicketViolation>(violationRows);
        return context;
    }

    // Ordinances 1-7 active, 8 inactive. Person 1 and person 2; enforcers 10 (me) and 20.
    private static AppDbContext MarketContext() => Context(
        [.. Enumerable.Range(1, 7).Select(id => NewOrdinance(id)), NewOrdinance(8, active: false)],
        (1, 1, OtherEnforcer, ViolationType.Ticket, 40, [1]),
        (2, 1, Me, ViolationType.Warning, 2, [2]),
        (3, 2, Me, ViolationType.Ticket, 1, [3, 8]),
        (4, 2, OtherEnforcer, ViolationType.Ticket, 3, [4]),
        (5, 2, OtherEnforcer, ViolationType.Ticket, 5, [4]),
        (6, 2, OtherEnforcer, ViolationType.Ticket, 31, [5]),
        (7, 2, Me, ViolationType.Ticket, 10, [6]),
        (8, 2, OtherEnforcer, ViolationType.Ticket, 4, [7]));

    private static TicketService Service(AppDbContext context) =>
        new(new TicketRepository(context), null!, null!, null!, null!, null!, null!);

    [Fact]
    public async Task Groups_are_ordered_and_an_ordinance_appears_only_in_its_first_group()
    {
        using var context = MarketContext();

        var shortcuts = await Service(context).GetOrdinanceShortcutsAsync(Me, 1);

        // Person 1: ordinance 2 two days ago (warning counts), ordinance 1 forty days ago.
        Assert.Equal([2, 1], shortcuts.PersonOrdinanceIds);
        // Me: 3 (1 day), 2 (2 days, already above), 6 (10 days); inactive 8 never shows.
        Assert.Equal([3, 6], shortcuts.MyRecentOrdinanceIds);
        // Last 30 days: 4 used twice; 2, 3, 6, 7 once (ties by ID); 5 is 31 days old, 1 is 40 days old.
        // 2, 3 and 6 are already above, leaving 4 and 7.
        Assert.Equal([4, 7], shortcuts.MostViolatedOrdinanceIds);
    }

    [Fact]
    public async Task Without_a_person_only_my_recent_and_most_violated_are_returned()
    {
        using var context = MarketContext();

        var shortcuts = await Service(context).GetOrdinanceShortcutsAsync(Me, null);

        Assert.Empty(shortcuts.PersonOrdinanceIds);
        Assert.Equal([3, 2, 6], shortcuts.MyRecentOrdinanceIds);
        Assert.Equal([4, 7], shortcuts.MostViolatedOrdinanceIds);
    }

    [Fact]
    public async Task Each_group_holds_at_most_five_most_recent_first()
    {
        using var context = MarketContext();

        var shortcuts = await Service(context).GetOrdinanceShortcutsAsync(OtherEnforcer, 2);

        // Person 2 by last use: 3 (1 day; 8 is inactive), 4 (3), 7 (4), 6 (10), 5 (31).
        Assert.Equal([3, 4, 7, 6, 5], shortcuts.PersonOrdinanceIds);
        // Enforcer 20 by last use: 4, 7, 5, 1; only 1 is not above.
        Assert.Equal([1], shortcuts.MyRecentOrdinanceIds);
        // Market: 4, 2, 3, 6, 7; only 2 is not above.
        Assert.Equal([2], shortcuts.MostViolatedOrdinanceIds);
    }

    [Fact]
    public async Task A_group_is_cut_to_five()
    {
        // Person 3 used ordinances 1-7, ordinance N exactly N days ago.
        using var context = Context([.. Enumerable.Range(1, 7).Select(id => NewOrdinance(id))],
            [.. Enumerable.Range(1, 7).Select(n => (n, 3, OtherEnforcer, ViolationType.Ticket, n, new[] { n }))]);

        var shortcuts = await Service(context).GetOrdinanceShortcutsAsync(Me, 3);

        Assert.Equal([1, 2, 3, 4, 5], shortcuts.PersonOrdinanceIds);
        Assert.Empty(shortcuts.MyRecentOrdinanceIds);
        // All seven are once each in 30 days; 1-5 are above, so 6 and 7 remain.
        Assert.Equal([6, 7], shortcuts.MostViolatedOrdinanceIds);
    }

    [Fact]
    public async Task An_unknown_person_has_no_past_violations()
    {
        using var context = MarketContext();

        var shortcuts = await Service(context).GetOrdinanceShortcutsAsync(Me, 99);

        Assert.Empty(shortcuts.PersonOrdinanceIds);
        Assert.Equal([3, 2, 6], shortcuts.MyRecentOrdinanceIds);
    }

    [Theory]
    [InlineData(0)]
    [InlineData(-1)]
    public async Task A_person_id_of_zero_or_less_is_rejected(int personId)
    {
        using var context = MarketContext();

        await Assert.ThrowsAsync<InvalidRequestException>(() => Service(context).GetOrdinanceShortcutsAsync(Me, personId));
    }
}
