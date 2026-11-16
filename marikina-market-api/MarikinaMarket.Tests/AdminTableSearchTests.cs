using MarikinaMarket.API.Application.DTOs.Tickets.Request;
using MarikinaMarket.API.Application.Services;
using MarikinaMarket.API.Domain.Entities;
using MarikinaMarket.API.Domain.Enums;
using MarikinaMarket.API.Infrastructure.Persistence;
using MarikinaMarket.API.Infrastructure.Repositories;
using Microsoft.EntityFrameworkCore;
using Xunit;

namespace MarikinaMarket.Tests;

// The Tickets and Inspections tables can be searched by the violator, enforcer and business name they show,
// in any capital letters. Expected ids are worked out by hand from the records below (newest first):
//   Ticket 1  (1 day ago):  business "Sari Shop" (saved on the ticket as "Old Bakery"), owner Nena Dizon,
//                           account ACC-100, violator "Jun Reyes", enforcer Pedro Santos
//   Warning 2 (2 days ago): business "Sari Shop", person "Ana Villa", enforcer Maria Lopez
//   Ticket 3  (3 days ago): unregistered, violator "Ben Torres", enforcer Maria Lopez
public class AdminTableSearchTests
{
    private static AppDbContext Context()
    {
        var section = new MarketSection { Id = 1, Name = "Dry Goods" };
        var business = new Business
        {
            Id = 10, BusinessName = "Sari Shop", StallNumber = "12", BusinessAccountNumber = "ACC-100",
            OwnerFirstName = "Nena", OwnerLastName = "Dizon", HouseNumber = "1", Street = "Market Lane",
            Barangay = "Sta. Elena", City = "Marikina City", QrCodeValue = "qr-10", Status = VendorStatus.Active,
            MarketSectionId = section.Id, MarketSection = section
        };
        User Enforcer(int id, string first, string last) => new()
        {
            Id = id, FirstName = first, LastName = last, DateOfBirth = new(1990, 1, 1),
            HouseNumber = "1", Street = "Market Lane", Barangay = "Synthetic", City = "Marikina"
        };
        var pedro = Enforcer(50, "Pedro", "Santos");
        var maria = Enforcer(51, "Maria", "Lopez");
        var ana = new Person { Id = 21, FullName = "Ana Villa", Address = "Synthetic" };

        var context = new AppDbContext(new DbContextOptionsBuilder<AppDbContext>().Options);
        context.Tickets = new AccountDatabaseSet<Ticket>(
        [
            new()
            {
                Id = 1, Type = ViolationType.Ticket, PaperReference = "000111", VendorId = 10, Vendor = business,
                SnapshotBusinessAccountNumber = "ACC-100", SnapshotBusinessName = "Old Bakery",
                PaperViolatorName = "Jun Reyes", EnforcerId = 50, Enforcer = pedro,
                MarketSectionId = 1, MarketSection = section, Description = "Synthetic", Status = TicketStatus.Pending,
                IssuedAt = DateTime.UtcNow.Date.AddDays(-1), UpdatedAt = DateTime.UtcNow.Date.AddDays(-1)
            },
            new()
            {
                Id = 2, Type = ViolationType.Warning, ControlNumber = "WRN-0001", VendorId = 10, Vendor = business,
                PersonId = 21, Person = ana, EnforcerId = 51, Enforcer = maria,
                MarketSectionId = 1, MarketSection = section, Description = "Synthetic",
                IssuedAt = DateTime.UtcNow.Date.AddDays(-2), UpdatedAt = DateTime.UtcNow.Date.AddDays(-2)
            },
            new()
            {
                Id = 3, Type = ViolationType.Ticket, PaperReference = "000222",
                PaperViolatorName = "Ben Torres", EnforcerId = 51, Enforcer = maria,
                MarketSectionId = 1, MarketSection = section, Description = "Synthetic", Status = TicketStatus.Pending,
                IssuedAt = DateTime.UtcNow.Date.AddDays(-3), UpdatedAt = DateTime.UtcNow.Date.AddDays(-3)
            },
        ]);
        return context;
    }

    private static TicketService TicketService(AppDbContext context) =>
        new(new TicketRepository(context), null!, new VendorRepository(context), null!, null!, null!, null!);

    [Theory]
    [InlineData("jun reyes", new[] { 1 })]     // violator
    [InlineData("BEN TORRES", new[] { 3 })]    // unregistered ticket's violator
    [InlineData("pedro santos", new[] { 1 })]  // enforcer full name
    [InlineData("maria", new[] { 3 })]         // enforcer first name; warning 2 is not a ticket
    [InlineData("old bakery", new[] { 1 })]    // business name saved on the ticket
    [InlineData("sari shop", new[] { 1 })]     // current business name still works
    public async Task Tickets_search_finds_violator_enforcer_and_business(string search, int[] expectedIds)
    {
        using var context = Context();
        var page = await TicketService(context).GetAdminTicketAsync(0, new TicketSummaryFilters { Search = search });
        Assert.Equal(expectedIds, page.Items.Select(i => i.Id));
    }

    [Theory]
    [InlineData("jun reyes", new[] { 1 })]      // ticket's violator
    [InlineData("ANA VILLA", new[] { 2 })]      // warning's person
    [InlineData("maria lopez", new[] { 2, 3 })] // enforcer full name
    [InlineData("old bakery", new[] { 1 })]     // business name saved on the ticket
    [InlineData("sari shop", new[] { 1, 2 })]   // current business name, any capital letters
    [InlineData("dizon", new[] { 1, 2 })]       // owner, any capital letters
    [InlineData("acc-100", new[] { 1, 2 })]     // account number, any capital letters
    public async Task Inspections_search_finds_violator_enforcer_and_business(string search, int[] expectedIds)
    {
        using var context = Context();
        var page = await TicketService(context).GetAdminInspectionAsync(0, new InspectionSummaryFilters { Search = search });
        Assert.Equal(expectedIds, page.Items.Select(i => i.TicketId));
        Assert.Equal(expectedIds.Length, page.Total);
    }
}
