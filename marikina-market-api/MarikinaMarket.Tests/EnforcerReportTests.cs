using System.ComponentModel.DataAnnotations;
using System.Text.Json;
using MarikinaMarket.API.Application.Interfaces.Repositories;
using MarikinaMarket.API.Application.Services;
using MarikinaMarket.API.Domain.Entities;
using MarikinaMarket.API.Domain.Enums;
using MarikinaMarket.API.Infrastructure.Persistence;
using MarikinaMarket.API.Infrastructure.Repositories;
using Microsoft.EntityFrameworkCore;
using Xunit;

namespace MarikinaMarket.Tests;

// The website's all-enforcers report. Every expected value is worked out by hand from the synthetic records below.
// Period: Mon 2 Nov 2026 to Wed 4 Nov 2026, Philippine time (UTC+8),
// so it runs from 1 Nov 16:00 UTC up to (not including) 4 Nov 16:00 UTC.
public class EnforcerReportTests
{
    private static DateTime Utc(int month, int day, int hour, int minute = 0) =>
        new(2026, month, day, hour, minute, 0, DateTimeKind.Utc);

    private static Ticket Record(int id, int enforcerId, ViolationType type, TicketStatus? status, decimal? fine, DateTime issuedAt) => new()
    {
        Id = id, EnforcerId = enforcerId, Type = type, Status = status, TotalPaymentAmount = fine,
        IssuedAt = issuedAt, UpdatedAt = issuedAt, Description = "Synthetic report record"
    };

    private static User Enforcer(int id, string lastName, string firstName, AccountStatus status) => new()
    {
        Id = id, UserName = $"ENF-{id:0000}", FirstName = firstName, LastName = lastName, Status = status,
        DateOfBirth = new DateOnly(1990, 1, 1), HouseNumber = "1", Street = "Test Street", Barangay = "Test Barangay",
        City = "Marikina", Email = $"enforcer{id}@example.invalid", PhoneNumber = "09170000000"
    };

    private static EnforcerService Service(IEnumerable<Ticket> tickets, IEnumerable<User> enforcers)
    {
        var context = new AppDbContext(new DbContextOptionsBuilder<AppDbContext>().Options)
        {
            Tickets = new AccountDatabaseSet<Ticket>(tickets)
        };
        var users = ReviewBoundaryProxy.Create<IUserRepository>((method, _) => method.Name switch
        {
            nameof(IUserRepository.GetAllEnforcersAsync) => Task.FromResult(enforcers.ToList()),
            _ => throw new InvalidOperationException($"Unexpected call {method.Name}")
        });
        return new EnforcerService(users, new TicketRepository(context), null!);
    }

    private static readonly User[] Enforcers =
    [
        Enforcer(8, "Dela Cruz", "Juan", AccountStatus.Active),
        Enforcer(9, "Reyes", "Ana", AccountStatus.Active),
        Enforcer(10, "Bautista", "Leo", AccountStatus.Active),   // no records at all
        Enforcer(11, "Santos", "Mia", AccountStatus.Inactive),   // inactive, one record in the period
        Enforcer(12, "Garcia", "Ben", AccountStatus.Inactive),   // inactive, records only before the period
        Enforcer(13, "Aquino", "Rosa", AccountStatus.Active),    // no records at all
    ];

    private static readonly Ticket[] Records =
    [
        // Enforcer 8
        Record(1, 8, ViolationType.Ticket, TicketStatus.Paid, 1500m, Utc(11, 1, 23)),        // Mon 2 Nov 07:00 -> in, settled
        Record(2, 8, ViolationType.Ticket, TicketStatus.Pending, 1000m, Utc(11, 2, 1)),      // Mon 2 Nov 09:00 -> in, open
        Record(3, 8, ViolationType.Warning, null, null, Utc(11, 3, 2)),                      // Tue 3 Nov 10:00 -> in
        Record(4, 8, ViolationType.Ticket, TicketStatus.Cleared, 500m, Utc(11, 4, 15, 30)),  // Wed 4 Nov 23:30 -> in, settled
        Record(5, 8, ViolationType.Ticket, TicketStatus.Overdue, 2000m, Utc(11, 4, 16, 10)), // Thu 5 Nov 00:10 -> out
        Record(6, 8, ViolationType.Warning, null, null, Utc(11, 1, 15, 50)),                 // Sun 1 Nov 23:50 -> out
        Record(7, 8, ViolationType.Ticket, TicketStatus.Contested, null, Utc(11, 1, 16, 5)), // Mon 2 Nov 00:05 -> in, open, no fine
        // Enforcer 9
        Record(8, 9, ViolationType.Ticket, TicketStatus.Waived, 800m, Utc(11, 3, 4)),        // Tue 3 Nov 12:00 -> settled
        Record(9, 9, ViolationType.Ticket, TicketStatus.InProgress, 1200m, Utc(11, 3, 7)),   // Tue 3 Nov 15:00 -> open
        Record(10, 9, ViolationType.Ticket, null, 300m, Utc(11, 4, 0)),                      // Wed 4 Nov 08:00 -> open
        Record(11, 9, ViolationType.Warning, null, null, Utc(11, 4, 1)),                     // Wed 4 Nov 09:00
        // Enforcer 11 (inactive)
        Record(12, 11, ViolationType.Warning, null, null, Utc(11, 2, 4)),                    // Mon 2 Nov 12:00
        // Enforcer 12 (inactive), before the period
        Record(13, 12, ViolationType.Ticket, TicketStatus.Paid, 500m, Utc(10, 20, 4)),
        // An account that is not an enforcer
        Record(14, 99, ViolationType.Ticket, TicketStatus.Paid, 999m, Utc(11, 3, 4)),
    ];

    [Fact]
    public async Task Each_enforcer_row_and_the_total_row_add_up_from_the_records_in_the_period()
    {
        var report = await Service(Records, Enforcers).GetReportAsync("2026-11-02", "2026-11-04");

        Assert.Equal(new DateOnly(2026, 11, 2), report.DateRange.From);
        Assert.Equal(new DateOnly(2026, 11, 4), report.DateRange.To);

        // Enforcer 8: records 1, 2, 3, 4, 7.
        //   warnings 1 (3); tickets 4 (1, 2, 4, 7); total 5
        //   settled 2 (1 Paid, 4 Cleared); open 2 (2 Pending, 7 Contested)
        //   fines charged 1500 + 1000 + 500 + 0 = 3000; fines settled 1500 + 500 = 2000
        //   days: 2 Nov (1, 2, 7), 3 Nov (3), 4 Nov (4) = 3; last record = record 4
        var juan = report.Enforcers.Single(r => r.EnforcerId == 8);
        Assert.Equal(("ENF-0008", "Juan", "Dela Cruz", AccountStatus.Active),
            (juan.Username, juan.FirstName, juan.LastName, juan.Status));
        Assert.Equal((1, 4, 5, 2, 2), (juan.Warnings, juan.Tickets, juan.TotalRecords, juan.SettledTickets, juan.OpenTickets));
        Assert.Equal((3000m, 2000m), (juan.FinesCharged, juan.FinesSettled));
        Assert.Equal(3, juan.DaysWithRecords);
        Assert.Equal(Utc(11, 4, 15, 30), juan.LastRecordAt);

        // Enforcer 9: records 8, 9, 10, 11.
        //   warnings 1; tickets 3; total 4; settled 1 (Waived); open 2 (InProgress, no status)
        //   fines charged 800 + 1200 + 300 = 2300; fines settled 800
        //   days: 3 Nov, 4 Nov = 2; last record = record 11
        var ana = report.Enforcers.Single(r => r.EnforcerId == 9);
        Assert.Equal((1, 3, 4, 1, 2), (ana.Warnings, ana.Tickets, ana.TotalRecords, ana.SettledTickets, ana.OpenTickets));
        Assert.Equal((2300m, 800m), (ana.FinesCharged, ana.FinesSettled));
        Assert.Equal(2, ana.DaysWithRecords);
        Assert.Equal(Utc(11, 4, 1), ana.LastRecordAt);

        // Enforcer 11 (inactive): record 12 only.
        var mia = report.Enforcers.Single(r => r.EnforcerId == 11);
        Assert.Equal((1, 0, 1, 0, 0), (mia.Warnings, mia.Tickets, mia.TotalRecords, mia.SettledTickets, mia.OpenTickets));
        Assert.Equal((0m, 0m), (mia.FinesCharged, mia.FinesSettled));
        Assert.Equal(1, mia.DaysWithRecords);
        Assert.Equal(Utc(11, 2, 4), mia.LastRecordAt);

        // Totals: enforcers 8 + 9 + 11 (records 13 and 14 are not counted).
        //   warnings 1 + 1 + 1 = 3; tickets 4 + 3 = 7; total 10; settled 2 + 1 = 3; open 2 + 2 = 4
        //   fines charged 3000 + 2300 = 5300; fines settled 2000 + 800 = 2800
        var totals = report.Totals;
        Assert.Equal((3, 7, 10, 3, 4), (totals.Warnings, totals.Tickets, totals.TotalRecords, totals.SettledTickets, totals.OpenTickets));
        Assert.Equal((5300m, 2800m), (totals.FinesCharged, totals.FinesSettled));
    }

    [Fact]
    public async Task Active_enforcers_always_appear_inactive_ones_only_with_records_sorted_by_most_records_then_name()
    {
        var report = await Service(Records, Enforcers).GetReportAsync("2026-11-02", "2026-11-04");

        // Juan 5, Ana 4, Mia 1, then the zero rows by last name: Aquino before Bautista.
        // Ben (inactive, nothing in the period) and account 99 (not an enforcer) are left out.
        Assert.Equal(new[] { 8, 9, 11, 13, 10 }, report.Enforcers.Select(r => r.EnforcerId));

        var leo = report.Enforcers.Single(r => r.EnforcerId == 10);
        Assert.Equal((0, 0, 0, 0, 0, 0), (leo.Warnings, leo.Tickets, leo.TotalRecords, leo.SettledTickets, leo.OpenTickets, leo.DaysWithRecords));
        Assert.Equal((0m, 0m), (leo.FinesCharged, leo.FinesSettled));
        Assert.Null(leo.LastRecordAt);
    }

    [Fact]
    public async Task Days_are_Philippine_calendar_days_not_UTC_days()
    {
        // Two records on Mon 2 Nov, Philippine time: 07:00 (1 Nov in UTC) and 09:00 (2 Nov in UTC). One day, not two.
        var tickets = new[]
        {
            Record(1, 8, ViolationType.Warning, null, null, Utc(11, 1, 23)),
            Record(2, 8, ViolationType.Warning, null, null, Utc(11, 2, 1)),
        };

        var report = await Service(tickets, [Enforcers[0]]).GetReportAsync("2026-11-02", "2026-11-02");

        var juan = Assert.Single(report.Enforcers);
        Assert.Equal(2, juan.TotalRecords);
        Assert.Equal(1, juan.DaysWithRecords);
    }

    [Fact]
    public async Task Report_with_no_records_returns_zero_rows_for_active_enforcers_and_zero_totals()
    {
        var report = await Service([], Enforcers).GetReportAsync("2026-11-02", "2026-11-04");

        Assert.Equal(new[] { 13, 10, 8, 9 }, report.Enforcers.Select(r => r.EnforcerId));
        Assert.All(report.Enforcers, r => Assert.Equal(0, r.TotalRecords));
        Assert.Equal((0, 0, 0, 0, 0), (report.Totals.Warnings, report.Totals.Tickets, report.Totals.TotalRecords,
            report.Totals.SettledTickets, report.Totals.OpenTickets));
        Assert.Equal((0m, 0m), (report.Totals.FinesCharged, report.Totals.FinesSettled));
    }

    [Theory]
    [InlineData(null, "2026-11-04", "Dates are required and must use YYYY-MM-DD.")]
    [InlineData("2026-11-02", "", "Dates are required and must use YYYY-MM-DD.")]
    [InlineData("11/02/2026", "2026-11-04", "Dates are required and must use YYYY-MM-DD.")]
    [InlineData("2026-13-01", "2026-11-04", "Dates are required and must use YYYY-MM-DD.")]
    [InlineData("2026-11-05", "2026-11-04", "From must be on or before to.")]
    [InlineData("2026-11-02", "9999-12-31", "Dates are outside the supported report range.")]
    public async Task Bad_dates_are_refused_with_a_clear_message(string? from, string? to, string message)
    {
        var error = await Assert.ThrowsAsync<ValidationException>(() => Service(Records, Enforcers).GetReportAsync(from, to));
        Assert.Equal(message, error.Message);
    }

    [Fact]
    public async Task Response_uses_the_field_names_the_website_reads()
    {
        var report = await Service(Records, Enforcers).GetReportAsync("2026-11-02", "2026-11-04");

        using var json = JsonDocument.Parse(JsonSerializer.Serialize(report,
            new JsonSerializerOptions { PropertyNamingPolicy = JsonNamingPolicy.SnakeCaseLower }));
        var root = json.RootElement;
        Assert.Equal("2026-11-02", root.GetProperty("date_range").GetProperty("from").GetString());
        var row = root.GetProperty("enforcers")[0];
        foreach (var name in new[] { "enforcer_id", "username", "first_name", "last_name", "status", "warnings", "tickets",
                     "total_records", "settled_tickets", "open_tickets", "fines_charged", "fines_settled",
                     "days_with_records", "last_record_at" })
            Assert.True(row.TryGetProperty(name, out _), $"Row is missing {name}");
        var totals = root.GetProperty("totals");
        Assert.Equal(5300m, totals.GetProperty("fines_charged").GetDecimal());
        Assert.False(totals.TryGetProperty("days_with_records", out _));
    }
}
