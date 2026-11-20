using System.ComponentModel.DataAnnotations;
using System.Text.Json;
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

// The website's report for one enforcer. Every expected value is worked out by hand from the synthetic records below.
// Period: Mon 2 Nov 2026 to Wed 4 Nov 2026, Philippine time (UTC+8): 1 Nov 16:00 UTC up to 4 Nov 16:00 UTC.
public class EnforcerActivityReportTests
{
    private const int EnforcerId = 8;
    private const int OtherEnforcerId = 9;
    private const int HeadAdminId = 1;

    private static DateTime Utc(int month, int day, int hour, int minute = 0) =>
        new(2026, month, day, hour, minute, 0, DateTimeKind.Utc);

    private static readonly MarketSection DryGoods = new() { Id = 1, Name = "Dry Goods Lane" };
    private static readonly MarketSection WetMarket = new() { Id = 2, Name = "Wet Market Row" };

    private static Ordinance Ordinance(int id, ViolationCategory category) => new()
    {
        Id = id, OrdinanceNo = $"0{id}", Series = "2026", Title = $"Synthetic {category}", Category = category
    };
    private static readonly Ordinance SanitationA = Ordinance(1, ViolationCategory.Sanitation);
    private static readonly Ordinance SanitationB = Ordinance(2, ViolationCategory.Sanitation);
    private static readonly Ordinance Licensing = Ordinance(3, ViolationCategory.Licensing);
    private static readonly Ordinance Obstruction = Ordinance(4, ViolationCategory.Obstruction);

    private static Ticket Record(int id, ViolationType type, TicketStatus? status, PenaltyType? penalty, decimal? fine,
        MarketSection street, DateTime issuedAt, int enforcerId = EnforcerId, params Ordinance[] ordinances) => new()
    {
        Id = id, EnforcerId = enforcerId, Type = type, Status = status, PenaltyType = penalty, TotalPaymentAmount = fine,
        MarketSectionId = street.Id, MarketSection = street, IssuedAt = issuedAt, UpdatedAt = issuedAt,
        Description = "Synthetic report record",
        TicketViolations = ordinances.Select((o, i) => new TicketViolation
            { Id = id * 10 + i, TicketId = id, OrdinanceId = o.Id, Ordinance = o }).ToList()
    };

    private static readonly Ticket[] Records =
    [
        // Mon 2 Nov 07:00 and 09:00: two Sanitation ordinances count once; Sanitation + Licensing count under both.
        Record(1, ViolationType.Ticket, TicketStatus.Paid, PenaltyType.CashFine, 1500m, DryGoods, Utc(11, 1, 23), EnforcerId, SanitationA, SanitationB),
        Record(2, ViolationType.Ticket, TicketStatus.Pending, PenaltyType.CashFine, 1000m, DryGoods, Utc(11, 2, 1), EnforcerId, SanitationA, Licensing),
        // Tue 3 Nov 10:00, 15:00, 12:00
        Record(3, ViolationType.Warning, null, null, null, WetMarket, Utc(11, 3, 2), EnforcerId, Obstruction),
        Record(5, ViolationType.Ticket, TicketStatus.InProgress, PenaltyType.CommunityService, null, DryGoods, Utc(11, 3, 7), EnforcerId, Obstruction),
        Record(6, ViolationType.Ticket, TicketStatus.Waived, PenaltyType.BloodDonation, null, WetMarket, Utc(11, 3, 4), EnforcerId, SanitationA),
        // Wed 4 Nov 23:30, 08:00, 09:00 (7 and 8 have no penalty kind / no ordinance recorded)
        Record(4, ViolationType.Ticket, TicketStatus.Cleared, PenaltyType.CommunityService, null, WetMarket, Utc(11, 4, 15, 30), EnforcerId, Licensing),
        Record(7, ViolationType.Ticket, TicketStatus.Overdue, null, null, DryGoods, Utc(11, 4, 0)),
        Record(8, ViolationType.Warning, null, null, null, DryGoods, Utc(11, 4, 1)),
        // Left out: Thu 5 Nov 00:10 (after the period), and another enforcer's ticket inside the period.
        Record(9, ViolationType.Ticket, TicketStatus.Paid, PenaltyType.CashFine, 2000m, DryGoods, Utc(11, 4, 16, 10), EnforcerId, Licensing),
        Record(10, ViolationType.Ticket, TicketStatus.Paid, PenaltyType.CashFine, 999m, WetMarket, Utc(11, 3, 4), OtherEnforcerId, Licensing),
    ];

    private static User Person(int id, string lastName, string firstName) => new()
    {
        Id = id, UserName = $"ENF-{id:0000}", FirstName = firstName, LastName = lastName, Status = AccountStatus.Active,
        DateOfBirth = new DateOnly(1990, 1, 1), HouseNumber = "1", Street = "Test Street", Barangay = "Test Barangay",
        City = "Marikina", Email = $"user{id}@example.invalid", PhoneNumber = "09170000000"
    };

    private static EnforcerService Service(IEnumerable<Ticket> tickets)
    {
        var users = new Dictionary<int, (User User, Role Role)>
        {
            [EnforcerId] = (Person(EnforcerId, "Dela Cruz", "Juan"), Role.MarketEnforcer),
            [HeadAdminId] = (Person(HeadAdminId, "Admin", "Head"), Role.HeadAdmin),
        };
        var repository = ReviewBoundaryProxy.Create<IUserRepository>((method, args) => method.Name switch
        {
            nameof(IUserRepository.GetUserAsync) => Task.FromResult(users.TryGetValue((int)args[0]!, out var found) ? found.User : null),
            nameof(IUserRepository.GetRoleAsync) => Task.FromResult<Role?>(users[((User)args[0]!).Id].Role),
            _ => throw new InvalidOperationException($"Unexpected call {method.Name}")
        });
        var context = new AppDbContext(new DbContextOptionsBuilder<AppDbContext>().Options)
        {
            Tickets = new AccountDatabaseSet<Ticket>(tickets)
        };
        return new EnforcerService(repository, new TicketRepository(context), null!);
    }

    [Fact]
    public async Task Summary_counts_only_this_enforcers_records_in_the_period()
    {
        var report = await Service(Records).GetActivityReportAsync(EnforcerId, "2026-11-02", "2026-11-04");

        // Records 1-8. Warnings 3, 8; tickets 1, 2, 4, 5, 6, 7.
        //   settled 1 Paid, 4 Cleared, 6 Waived = 3; open 2 Pending, 5 InProgress, 7 Overdue = 3
        //   fines charged 1500 + 1000 = 2500; fines settled 1500; days 2, 3, 4 Nov = 3; last record 4 (4 Nov 23:30)
        var e = report.Enforcer;
        Assert.Equal((EnforcerId, "ENF-0008", "Juan", "Dela Cruz"), (e.EnforcerId, e.Username, e.FirstName, e.LastName));
        Assert.Equal((2, 6, 8, 3, 3), (e.Warnings, e.Tickets, e.TotalRecords, e.SettledTickets, e.OpenTickets));
        Assert.Equal((2500m, 1500m), (e.FinesCharged, e.FinesSettled));
        Assert.Equal(3, e.DaysWithRecords);
        Assert.Equal(Utc(11, 4, 15, 30), e.LastRecordAt);
        Assert.Equal((new DateOnly(2026, 11, 2), new DateOnly(2026, 11, 4)), (report.DateRange.From, report.DateRange.To));
    }

    [Fact]
    public async Task Penalty_kinds_split_tickets_into_settled_and_open_with_not_recorded_last()
    {
        var report = await Service(Records).GetActivityReportAsync(EnforcerId, "2026-11-02", "2026-11-04");

        // Cash fine 1, 2 (1 settled, 1 open, 2500); community service 4, 5 (1, 1); blood donation 6 (waived = settled);
        // not recorded 7 (open). Most tickets first; a tie keeps the order cash fine, blood donation, community service.
        Assert.Equal(new (PenaltyType?, int, int, int, decimal)[]
        {
            (PenaltyType.CashFine, 2, 1, 1, 2500m),
            (PenaltyType.CommunityService, 2, 1, 1, 0m),
            (PenaltyType.BloodDonation, 1, 1, 0, 0m),
            (null, 1, 0, 1, 0m),
        }, report.PenaltyKinds.Select(p => (p.PenaltyType, p.Tickets, p.SettledTickets, p.OpenTickets, p.FinesCharged)));
        Assert.Equal(report.Enforcer.Tickets, report.PenaltyKinds.Sum(p => p.Tickets));
    }

    [Fact]
    public async Task Violation_types_count_each_record_once_per_type_with_not_recorded_last()
    {
        var report = await Service(Records).GetActivityReportAsync(EnforcerId, "2026-11-02", "2026-11-04");

        // Sanitation: tickets 1, 2, 6 (record 1 has two Sanitation ordinances, counted once).
        // Obstruction: warning 3, ticket 5. Licensing: tickets 2, 4. Not recorded: ticket 7, warning 8.
        // Most records first; a tie keeps the category order (Obstruction before Licensing).
        Assert.Equal(new (ViolationCategory?, int, int, int)[]
        {
            (ViolationCategory.Sanitation, 0, 3, 3),
            (ViolationCategory.Obstruction, 1, 1, 2),
            (ViolationCategory.Licensing, 0, 2, 2),
            (null, 1, 1, 2),
        }, report.ViolationTypes.Select(v => (v.Category, v.Warnings, v.Tickets, v.Total)));
        // Record 2 has two types, so the type totals (9) are one more than the records (8).
        Assert.Equal(9, report.ViolationTypes.Sum(v => v.Total));
    }

    [Fact]
    public async Task Market_streets_and_days_add_up_to_the_records()
    {
        var report = await Service(Records).GetActivityReportAsync(EnforcerId, "2026-11-02", "2026-11-04");

        // Dry Goods Lane: tickets 1, 2, 5, 7 and warning 8. Wet Market Row: warning 3, tickets 4, 6.
        Assert.Equal(new (int, string, int, int, int)[]
        {
            (1, "Dry Goods Lane", 1, 4, 5),
            (2, "Wet Market Row", 1, 2, 3),
        }, report.MarketStreets.Select(s => (s.MarketSectionId, s.MarketSectionName, s.Warnings, s.Tickets, s.Total)));

        // Philippine days, oldest first. 2 Nov: 1 (07:00, still 1 Nov in UTC) and 2. 3 Nov: 3, 5, 6. 4 Nov: 4, 7, 8.
        Assert.Equal(new (DateOnly, int, int, int)[]
        {
            (new DateOnly(2026, 11, 2), 0, 2, 2),
            (new DateOnly(2026, 11, 3), 1, 2, 3),
            (new DateOnly(2026, 11, 4), 1, 2, 3),
        }, report.Days.Select(d => (d.Date, d.Warnings, d.Tickets, d.Total)));
        Assert.Equal(report.Enforcer.TotalRecords, report.MarketStreets.Sum(s => s.Total));
        Assert.Equal(report.Enforcer.TotalRecords, report.Days.Sum(d => d.Total));
    }

    [Fact]
    public async Task Enforcer_with_no_records_gets_zeros_and_empty_tables()
    {
        var report = await Service([Records[^1]]).GetActivityReportAsync(EnforcerId, "2026-11-02", "2026-11-04");

        Assert.Equal((0, 0, 0, 0), (report.Enforcer.TotalRecords, report.Enforcer.DaysWithRecords, report.PenaltyKinds.Count, report.ViolationTypes.Count));
        Assert.Empty(report.MarketStreets);
        Assert.Empty(report.Days);
        Assert.Null(report.Enforcer.LastRecordAt);
    }

    [Theory]
    [InlineData(HeadAdminId)]
    [InlineData(999)]
    public async Task Someone_who_is_not_an_enforcer_is_not_found(int userId)
    {
        var error = await Assert.ThrowsAsync<RecordNotFoundException>(() =>
            Service(Records).GetActivityReportAsync(userId, "2026-11-02", "2026-11-04"));
        Assert.Equal("Enforcer not found.", error.Message);
    }

    [Theory]
    [InlineData(null, "2026-11-04", "Dates are required and must use YYYY-MM-DD.")]
    [InlineData("2026-11-05", "2026-11-04", "From must be on or before to.")]
    public async Task Bad_dates_are_refused_with_the_same_messages_as_the_all_enforcers_report(string? from, string? to, string message)
    {
        var error = await Assert.ThrowsAsync<ValidationException>(() => Service(Records).GetActivityReportAsync(EnforcerId, from, to));
        Assert.Equal(message, error.Message);
    }

    [Fact]
    public async Task Response_uses_the_field_names_the_website_reads()
    {
        var report = await Service(Records).GetActivityReportAsync(EnforcerId, "2026-11-02", "2026-11-04");

        using var json = JsonDocument.Parse(JsonSerializer.Serialize(report,
            new JsonSerializerOptions { PropertyNamingPolicy = JsonNamingPolicy.SnakeCaseLower }));
        var root = json.RootElement;
        Assert.Equal("2026-11-02", root.GetProperty("date_range").GetProperty("from").GetString());
        Assert.Equal(8, root.GetProperty("enforcer").GetProperty("total_records").GetInt32());
        Assert.Equal(2500m, root.GetProperty("penalty_kinds")[0].GetProperty("fines_charged").GetDecimal());
        Assert.True(root.GetProperty("violation_types")[0].TryGetProperty("category", out _));
        Assert.Equal("Dry Goods Lane", root.GetProperty("market_streets")[0].GetProperty("market_section_name").GetString());
        Assert.Equal("2026-11-02", root.GetProperty("days")[0].GetProperty("date").GetString());
    }
}
