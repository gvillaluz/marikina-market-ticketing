using System.Text.Json;
using MarikinaMarket.API.Application.Services;
using MarikinaMarket.API.Domain.Entities;
using MarikinaMarket.API.Domain.Enums;
using MarikinaMarket.API.Infrastructure.Persistence;
using MarikinaMarket.API.Infrastructure.Repositories;
using Microsoft.EntityFrameworkCore;
using Xunit;

namespace MarikinaMarket.Tests;

public class EnforcerSummaryTests
{
    [Theory]
    [InlineData(ViolationType.Warning)]
    [InlineData(ViolationType.Ticket)]
    public async Task Inspection_list_formats_ordinance_number_and_series(ViolationType type)
    {
        using var context = Context();
        var service = new TicketService(new TicketRepository(context), null!, null!, null!, null!, null!, null!);

        var response = await service.GetInspectionsByEnforcerIdAsync(8, 0, type, "");

        Assert.NotEmpty(response.Items);
        Assert.All(response.Items, item =>
        {
            Assert.Equal(8, item.EnforcerId);
            Assert.Equal(new[] { "Ord No. 011, Series of 2014", "Ord No. 145, Series of 2006" }, item.OrdinanceNames);
        });
    }

    [Fact]
    public async Task Ticket_list_includes_formatted_ordinances_and_preserves_null_private_stall()
    {
        using var context = Context();
        var service = new TicketService(new TicketRepository(context), null!, null!, null!, null!, null!, null!);

        var response = await service.GetTicketsByEnforcerIdAsync(8, 0, TicketStatus.Pending, "");

        Assert.Equal(2, response.Items.Count);
        Assert.All(response.Items, item => Assert.Equal(8, item.EnforcerId));
        var privateVendor = Assert.Single(response.Items, item => item.BusinessType == BusinessType.Private);
        Assert.Null(privateVendor.StallNumber);
        using var json = JsonDocument.Parse(JsonSerializer.Serialize(response.Items,
            new JsonSerializerOptions { PropertyNamingPolicy = JsonNamingPolicy.SnakeCaseLower }));
        foreach (var item in json.RootElement.EnumerateArray())
            Assert.Equal(new[] { "Ord No. 011, Series of 2014", "Ord No. 145, Series of 2006" },
                item.GetProperty("ordinance_names").EnumerateArray().Select(value => value.GetString()));
    }

    [Fact]
    public async Task Ordinance_lookup_preserves_series_for_new_inspection_summaries()
    {
        using var context = Context();
        var ordinances = await new OrdinanceRepository(context).GetByIdsAsync([11], 17);
        var json = JsonSerializer.SerializeToElement(Assert.Single(ordinances));
        Assert.Equal("2014", json.GetProperty("Series").GetString());
    }

    [Fact]
    public async Task Phone_summary_counts_this_Manila_calendar_week_for_the_signed_in_enforcer()
    {
        // Worked out by hand. The week runs from Monday 00:00 to the next Monday 00:00, Manila time (UTC+8).
        //  1 ticket, enforcer 8, registered business, Mon 9 Nov 00:30 Manila (Sun 8 Nov 16:30 UTC)  -> counted
        //  2 ticket, enforcer 8, unregistered vendor, two violations, Wed 11 Nov 09:00 Manila       -> counted once
        //  3 warning, enforcer 8, unregistered vendor, Tue 10 Nov 12:00 Manila                     -> counted
        //  4 warning, enforcer 8, Sun 8 Nov 23:30 Manila (last week)                               -> not counted
        //  5 ticket, enforcer 8, Thu 5 Nov 12:00 Manila (last week, inside a rolling 7 days)       -> not counted
        //  6 ticket, enforcer 9, Tue 10 Nov 10:00 Manila (another enforcer)                        -> not counted
        static DateTime Utc(int day, int hour, int minute = 0) => new(2026, 11, day, hour, minute, 0, DateTimeKind.Utc);
        static Ticket Record(int id, ViolationType type, DateTime issuedAt, int enforcerId = 8) => new()
        {
            Id = id, EnforcerId = enforcerId, Type = type, IssuedAt = issuedAt, UpdatedAt = issuedAt,
            Status = type == ViolationType.Ticket ? TicketStatus.Pending : null, Description = "Synthetic weekly record"
        };
        var registeredMonday = Record(1, ViolationType.Ticket, Utc(8, 16, 30)); registeredMonday.VendorId = 17;
        var unregisteredTicket = Record(2, ViolationType.Ticket, Utc(11, 1)); unregisteredTicket.PersonId = 1;
        unregisteredTicket.TicketViolations = [new() { Id = 1, OrdinanceId = 11 }, new() { Id = 2, OrdinanceId = 145 }];
        var unregisteredWarning = Record(3, ViolationType.Warning, Utc(10, 4)); unregisteredWarning.PersonId = 1;
        var lastSundayWarning = Record(4, ViolationType.Warning, Utc(8, 15, 30)); lastSundayWarning.VendorId = 17;
        var lastThursdayTicket = Record(5, ViolationType.Ticket, Utc(5, 4)); lastThursdayTicket.VendorId = 17;
        var otherEnforcer = Record(6, ViolationType.Ticket, Utc(10, 2), enforcerId: 9); otherEnforcer.VendorId = 17;
        using var context = new AppDbContext(new DbContextOptionsBuilder<AppDbContext>().Options)
        {
            Tickets = new AccountDatabaseSet<Ticket>(
                [registeredMonday, unregisteredTicket, unregisteredWarning, lastSundayWarning, lastThursdayTicket, otherEnforcer])
        };
        async Task<(int Tickets, int Warnings, int Total)> CountAt(DateTime utcNow)
        {
            var service = new TicketService(new TicketRepository(context), null!, null!, null!, null!, null!, null!,
                clock: new AnalyticsClock(utcNow));
            var summary = await service.GetMobileTicketCountAsync(8);
            return (summary.TicketRecorded, summary.WarningRecorded, summary.TotalRecorded);
        }

        Assert.Equal((2, 1, 3), await CountAt(Utc(11, 2)));       // Wed 11 Nov 10:00 Manila
        Assert.Equal((2, 1, 3), await CountAt(Utc(15, 15, 59)));  // Sun 15 Nov 23:59 Manila, same week
        Assert.Equal((0, 0, 0), await CountAt(Utc(15, 16)));      // Mon 16 Nov 00:00 Manila, a new week
    }

    private static AppDbContext Context()
    {
        var user = new User { FirstName = "Juan", LastName = "Santos", DateOfBirth = new DateOnly(1990, 1, 1),
            HouseNumber = "1", Street = "Test Street", Barangay = "Test Barangay", City = "Marikina" };
        var ordinances = new[] {
            new Ordinance { Id = 11, OrdinanceNo = "011", Series = "2014", Section = "SEC-8", Title = "Market walkway", Category = ViolationCategory.Obstruction },
            new Ordinance { Id = 145, OrdinanceNo = "145", Series = "2006", Section = "SEC-9", Title = "Market access", Category = ViolationCategory.Obstruction }
        };
        Ticket Record(int id, ViolationType type, BusinessType businessType, int enforcerId = 8) => new()
        {
            Id = id, ControlNumber = id.ToString(), EnforcerId = enforcerId, VendorId = 17,
            Type = type, Status = type == ViolationType.Ticket ? TicketStatus.Pending : null,
            Description = "Blocked market walkway", IssuedAt = new DateTime(2026, 10, 21, 2, 0, 0, DateTimeKind.Utc),
            Vendor = new Business { Id = 17, BusinessAccountNumber = "BUS-17", BusinessName = "Market Goods",
                Type = businessType, StallNumber = businessType == BusinessType.Public ? "A-12" : null, QrCodeValue = "synthetic-17", OwnerFirstName = user.FirstName, OwnerLastName = user.LastName, Email = user.Email },
            MarketSection = new MarketSection { Name = "Dry Goods", Description = "Dry goods section" },
            TicketViolations = ordinances.Select((ordinance, index) => new TicketViolation { Id = index + 1, OrdinanceId = ordinance.Id, Ordinance = ordinance }).ToList()
        };
        var context = new AppDbContext(new DbContextOptionsBuilder<AppDbContext>().Options);
        context.Tickets = new AccountDatabaseSet<Ticket>([
            Record(42, ViolationType.Ticket, BusinessType.Public), Record(43, ViolationType.Ticket, BusinessType.Private),
            Record(44, ViolationType.Warning, BusinessType.Public), Record(45, ViolationType.Ticket, BusinessType.Public, 9)]);
        context.Ordinances = new AccountDatabaseSet<Ordinance>(ordinances);
        return context;
    }
}
