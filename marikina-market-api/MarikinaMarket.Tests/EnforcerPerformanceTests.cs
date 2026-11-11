using MarikinaMarket.API.Application;
using MarikinaMarket.API.Application.Interfaces.Repositories;
using MarikinaMarket.API.Application.Services;
using MarikinaMarket.API.Domain.Entities;
using MarikinaMarket.API.Domain.Enums;
using MarikinaMarket.API.Infrastructure.Persistence;
using MarikinaMarket.API.Infrastructure.Repositories;
using Microsoft.EntityFrameworkCore;
using Xunit;

namespace MarikinaMarket.Tests;

// The website's enforcer performance page. Every expected value is worked out by hand from the synthetic records below.
public class EnforcerPerformanceTests
{
    private const int EnforcerId = 8;
    private const int OtherEnforcerId = 9;
    private const int HeadAdminId = 1;
    private const int NewEnforcerId = 20;

    private static DateTime Utc(int year, int month, int day, int hour, int minute = 0) =>
        new(year, month, day, hour, minute, 0, DateTimeKind.Utc);

    private static Ticket Record(int id, ViolationType type, TicketStatus? status, DateTime issuedAt, int enforcerId = EnforcerId) => new()
    {
        Id = id, EnforcerId = enforcerId, Type = type, Status = status, IssuedAt = issuedAt, UpdatedAt = issuedAt,
        Description = "Synthetic performance record"
    };

    private static EnforcerService Service(IEnumerable<Ticket> tickets, DateTime utcNow, IUserRepository? users = null)
    {
        var context = new AppDbContext(new DbContextOptionsBuilder<AppDbContext>().Options)
        {
            Tickets = new AccountDatabaseSet<Ticket>(tickets)
        };
        return new EnforcerService(users!, new TicketRepository(context), null!, clock: new AnalyticsClock(utcNow));
    }

    [Fact]
    public async Task Enforcer_with_no_inspections_gets_zeros_and_twelve_empty_months()
    {
        var service = Service([Record(1, ViolationType.Ticket, TicketStatus.Paid, Utc(2026, 3, 1, 2), OtherEnforcerId)],
            Utc(2026, 11, 11, 2));

        var summary = await service.GetPerformanceSummaryAsync(EnforcerId);

        Assert.Equal(EnforcerId, summary.EnforcerId);
        Assert.Equal(0, summary.TotalInspections);
        Assert.Equal(0, summary.ResolutionRate);
        Assert.Equal(0, summary.WarningRatio);
        Assert.Equal(0, summary.TicketRatio);
        Assert.Equal(Enumerable.Range(1, 12), summary.MonthlyInspections.Select(m => m.Month));
        Assert.All(summary.MonthlyInspections, m => Assert.Equal(0, m.TotalIssuedTickets));
    }

    [Fact]
    public async Task Resolution_rate_counts_paid_cleared_and_waived_tickets_out_of_tickets_only()
    {
        // Enforcer 8: 4 tickets (Paid, Cleared, Waived, Pending) and 2 warnings (no status). 6 inspections.
        //   Resolution rate = 3 finished tickets / 4 tickets = 75.0 %  (warnings are left out)
        //   Warnings = 2 / 6 = 33.3 %, tickets = 4 / 6 = 66.7 %
        // Enforcer 9's paid ticket is not counted.
        var issued = Utc(2026, 5, 4, 2);
        var service = Service([
            Record(1, ViolationType.Ticket, TicketStatus.Paid, issued),
            Record(2, ViolationType.Ticket, TicketStatus.Cleared, issued),
            Record(3, ViolationType.Ticket, TicketStatus.Waived, issued),
            Record(4, ViolationType.Ticket, TicketStatus.Pending, issued),
            Record(5, ViolationType.Warning, null, issued),
            Record(6, ViolationType.Warning, null, issued),
            Record(7, ViolationType.Ticket, TicketStatus.Paid, issued, OtherEnforcerId)
        ], Utc(2026, 11, 11, 2));

        var summary = await service.GetPerformanceSummaryAsync(EnforcerId);

        Assert.Equal(6, summary.TotalInspections);
        Assert.Equal(75.0, summary.ResolutionRate);
        Assert.Equal(33.3, summary.WarningRatio);
        Assert.Equal(66.7, summary.TicketRatio);
    }

    [Fact]
    public async Task Monthly_chart_uses_the_Manila_calendar_year_and_months()
    {
        // Manila is UTC+8.
        //   1  Thu 31 Dec 2025 23:30 Manila (15:30 UTC)  -> last year, not shown
        //   2  Fri  1 Jan 2026 01:00 Manila (Thu 31 Dec 2025 17:00 UTC) -> January
        //   3  Thu 15 Oct 2026 12:00 Manila                -> October
        //   4  Sun  1 Nov 2026 00:30 Manila (Sat 31 Oct 16:30 UTC) -> November, not October
        //   5  Fri  1 Jan 2027 00:30 Manila (Thu 31 Dec 2026 16:30 UTC) -> next year, not shown
        var tickets = new[]
        {
            Record(1, ViolationType.Ticket, TicketStatus.Pending, Utc(2025, 12, 31, 15, 30)),
            Record(2, ViolationType.Warning, null, Utc(2025, 12, 31, 17)),
            Record(3, ViolationType.Ticket, TicketStatus.Pending, Utc(2026, 10, 15, 4)),
            Record(4, ViolationType.Ticket, TicketStatus.Pending, Utc(2026, 10, 31, 16, 30)),
            Record(5, ViolationType.Ticket, TicketStatus.Pending, Utc(2026, 12, 31, 16, 30))
        };
        int[] Expected(params (int Month, int Count)[] counts) =>
            Enumerable.Range(1, 12).Select(month => counts.Where(c => c.Month == month).Sum(c => c.Count)).ToArray();

        // Wed 11 Nov 2026 10:00 Manila.
        var november = await Service(tickets, Utc(2026, 11, 11, 2)).GetPerformanceSummaryAsync(EnforcerId);
        Assert.Equal(Expected((1, 1), (10, 1), (11, 1)), november.MonthlyInspections.Select(m => m.TotalIssuedTickets));

        // Fri 1 Jan 2026 02:00 Manila (still 31 Dec 2025 in UTC): the chart already shows 2026.
        var newYear = await Service(tickets, Utc(2025, 12, 31, 18)).GetPerformanceSummaryAsync(EnforcerId);
        Assert.Equal(Expected((1, 1), (10, 1), (11, 1)), newYear.MonthlyInspections.Select(m => m.TotalIssuedTickets));
    }

    [Fact]
    public async Task Profile_opens_only_for_enforcers_and_shows_no_last_inspection_when_there_is_none()
    {
        var users = new Dictionary<int, (User User, Role Role)>
        {
            [HeadAdminId] = (Person(HeadAdminId, "head.admin"), Role.HeadAdmin),
            [NewEnforcerId] = (Person(NewEnforcerId, "new.enforcer"), Role.MarketEnforcer)
        };
        var repository = ReviewBoundaryProxy.Create<IUserRepository>((method, args) => method.Name switch
        {
            nameof(IUserRepository.GetUserAsync) => Task.FromResult(users.TryGetValue((int)args[0]!, out var found) ? found.User : null),
            nameof(IUserRepository.GetRoleAsync) => Task.FromResult<Role?>(users[((User)args[0]!).Id].Role),
            _ => throw new InvalidOperationException($"Unexpected call {method.Name}")
        });
        var service = Service([Record(1, ViolationType.Ticket, TicketStatus.Paid, Utc(2026, 3, 1, 2))], Utc(2026, 11, 11, 2), repository);

        var headAdmin = await Assert.ThrowsAsync<RecordNotFoundException>(() => service.GetProfileAsync(HeadAdminId));
        Assert.Equal("Enforcer not found.", headAdmin.Message);
        var missing = await Assert.ThrowsAsync<RecordNotFoundException>(() => service.GetProfileAsync(999));
        Assert.Equal("Enforcer not found.", missing.Message);

        var profile = await service.GetProfileAsync(NewEnforcerId);
        Assert.Equal(Role.MarketEnforcer, profile.Role);
        Assert.Null(profile.LastInspectionDate);
    }

    private static User Person(int id, string username) => new()
    {
        Id = id, UserName = username, FirstName = "Synthetic", LastName = "Staff", DateOfBirth = new DateOnly(1990, 1, 1),
        HouseNumber = "1", Street = "Test Street", Barangay = "Test Barangay", City = "Marikina",
        Email = $"{username}@example.invalid", PhoneNumber = "09170000000"
    };
}
