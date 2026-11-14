using MarikinaMarket.API.Application.DTOs.Vendor.Request;
using MarikinaMarket.API.Application.Services;
using MarikinaMarket.API.Domain.Entities;
using MarikinaMarket.API.Domain.Enums;
using MarikinaMarket.API.Infrastructure.Persistence;
using MarikinaMarket.API.Infrastructure.Repositories;
using Microsoft.EntityFrameworkCore;
using Xunit;

namespace MarikinaMarket.Tests;

// The business inspection history sends who the violator was. Expected values are worked out by hand
// from the records below (synthetic names):
//   Ticket  (id 1): written on paper as "Jose Ramos", confirmed person "Jose P. Ramos"
//   Warning (id 2): no paper name, confirmed person "Maria Santos"
//   Old ticket (id 3): no paper name and no confirmed person
public class BusinessHistoryViolatorTests
{
    private const int BusinessId = 10;

    private static AppDbContext Context()
    {
        var section = new MarketSection { Id = 1, Name = "Dry Goods", Description = "Synthetic" };
        var business = new Business
        {
            Id = BusinessId, BusinessName = "Aling Nena's Store", StallNumber = "12", BusinessAccountNumber = "ACC-100",
            OwnerFirstName = "Nena", OwnerLastName = "Cruz", HouseNumber = "1", Street = "Market Lane",
            Barangay = "Sta. Elena", City = "Marikina City", QrCodeValue = "qr-10", Status = VendorStatus.Active,
            MarketSectionId = section.Id, MarketSection = section
        };
        var officer = new User
        {
            Id = 50, FirstName = "Test", LastName = "Officer", DateOfBirth = new(1990, 1, 1),
            HouseNumber = "1", Street = "Market Lane", Barangay = "Synthetic", City = "Marikina"
        };
        var jose = new Person { Id = 7, FullName = "Jose P. Ramos", Address = "Synthetic" };
        var maria = new Person { Id = 8, FullName = "Maria Santos", Address = "Synthetic" };
        Ticket NewTicket(int id, ViolationType type, Person? person, string? paperName, int day) => new()
        {
            Id = id, Type = type, ControlNumber = $"{id}", PersonId = person?.Id, Person = person,
            PaperViolatorName = paperName, VendorId = BusinessId, Vendor = business, EnforcerId = officer.Id,
            Enforcer = officer, MarketSectionId = section.Id, MarketSection = section, Description = "Synthetic",
            IssuedAt = DateTime.UtcNow.Date.AddDays(-day), UpdatedAt = DateTime.UtcNow.Date.AddDays(-day)
        };

        var context = new AppDbContext(new DbContextOptionsBuilder<AppDbContext>().Options);
        context.Businesses = new AccountDatabaseSet<Business>([business]);
        context.Tickets = new AccountDatabaseSet<Ticket>(
        [
            NewTicket(1, ViolationType.Ticket, jose, "Jose Ramos", 1),
            NewTicket(2, ViolationType.Warning, maria, null, 2),
            NewTicket(3, ViolationType.Ticket, null, null, 3),
        ]);
        return context;
    }

    [Fact]
    public async Task Business_history_sends_the_recorded_violator_and_confirmed_person()
    {
        using var context = Context();
        var service = new TicketService(new TicketRepository(context), null!, new VendorRepository(context),
            null!, null!, null!, null!);

        var page = await service.GetVendorInspectionHistoryAsync(BusinessId, 0, new VendorInspectionHistoryFilters());

        (int, string?, string?)[] expected =
        [
            (1, "Jose Ramos", "Jose P. Ramos"),
            (2, null, "Maria Santos"),
            (3, null, null),
        ];
        Assert.Equal(expected, page.Items.Select(i => (i.TicketId, i.PaperViolatorName, i.PersonFullName)));
    }
}
