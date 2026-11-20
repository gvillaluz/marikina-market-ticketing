using MarikinaMarket.API.Application.Services;
using MarikinaMarket.API.Domain.Entities;
using MarikinaMarket.API.Domain.Enums;
using MarikinaMarket.API.Infrastructure.Persistence;
using MarikinaMarket.API.Infrastructure.Repositories;
using Microsoft.EntityFrameworkCore;
using Xunit;

namespace MarikinaMarket.Tests;

// The enforcer performance page's inspection history: each record carries the names the table shows
// (violator, business, registered owner), for a registered ticket, an unregistered ticket and a warning.
public class EnforcerInspectionHistoryNamesTests
{
    private static readonly DateTime Issued = new(2026, 11, 10, 2, 0, 0, DateTimeKind.Utc);
    private static readonly MarketSection Street = new() { Id = 3, Name = "Shoe Avenue" };

    // The business as it is now; a ticket also keeps a copy of how it was when issued.
    private static Business Store() => new()
    {
        Id = 17, BusinessAccountNumber = "ACC-100", BusinessName = "Aling Nena's Store", QrCodeValue = "QR-17",
        OwnerFirstName = "Nena", OwnerLastName = "Reyes"
    };

    private static Ticket Record(int id, ViolationType type, Business? business, string person, string? paperName, int minutes) => new()
    {
        Id = id, Type = type, EnforcerId = 8, VendorId = business?.Id, Vendor = business,
        PersonId = id + 30, Person = new Person { Id = id + 30, FullName = person, Address = "Marikina" },
        PaperViolatorName = paperName, ControlNumber = $"{id}", MarketSectionId = Street.Id, MarketSection = Street,
        Status = type == ViolationType.Ticket ? TicketStatus.Pending : null,
        IssuedAt = Issued.AddMinutes(minutes), UpdatedAt = Issued, Description = "Synthetic history record"
    };

    [Fact]
    public async Task Each_record_carries_the_violator_business_and_owner_names()
    {
        var registeredTicket = Record(1, ViolationType.Ticket, Store(), "Juan Dela Cruz", "JUAN D. CRUZ", 3);
        registeredTicket.SnapshotBusinessAccountNumber = "ACC-100";
        registeredTicket.SnapshotBusinessName = "Aling Nena's Store (2025)";
        registeredTicket.SnapshotRegisteredOwnerName = "Nena Reyes";
        var unregisteredTicket = Record(2, ViolationType.Ticket, null, "Pedro Santos", "PEDRO SANTOS", 2);
        var registeredWarning = Record(3, ViolationType.Warning, Store(), "Maria Lopez", null, 1);
        using var context = new AppDbContext(new DbContextOptionsBuilder<AppDbContext>().Options)
        {
            Tickets = new AccountDatabaseSet<Ticket>([registeredTicket, unregisteredTicket, registeredWarning])
        };

        var page = await new EnforcerService(null!, new TicketRepository(context), null!).GetInspectionHistoryAsync(8, 0);

        // Newest first: 1, 2, 3.
        Assert.Equal(new (int, string?, string?, string?, string?)[]
        {
            (1, "JUAN D. CRUZ", "Juan Dela Cruz", "Aling Nena's Store", "Nena Reyes"),
            (2, "PEDRO SANTOS", "Pedro Santos", null, null),
            (3, null, "Maria Lopez", "Aling Nena's Store", "Nena Reyes"),
        }, page.Items.Select(i => (i.TicketId, i.PaperViolatorName, i.PersonFullName, i.BusinessName, i.RegisteredOwnerName)));
        // The ticket still carries the business as it was when issued.
        Assert.Equal("Aling Nena's Store (2025)", page.Items[0].BusinessSnapshot?.BusinessName);
    }
}
