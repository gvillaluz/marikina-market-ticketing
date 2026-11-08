using System.ComponentModel.DataAnnotations;
using MarikinaMarket.API.Application;
using MarikinaMarket.API.Application.DTOs.Person.Request;
using MarikinaMarket.API.Application.Services;
using MarikinaMarket.API.Domain.Entities;
using MarikinaMarket.API.Domain.Enums;
using MarikinaMarket.API.Infrastructure.Persistence;
using MarikinaMarket.API.Infrastructure.Repositories;
using Microsoft.EntityFrameworkCore;
using Xunit;

namespace MarikinaMarket.Tests;

// Slice A1: enforcer business search by name/stall/account number and the business people list.
// Expected values below are worked out by hand from the synthetic records, not copied from output.
public class BusinessLookupAndPeopleTests
{
    private static readonly MarketSection Section = new() { Id = 1, Name = "Dry Goods", Description = "Synthetic" };

    private static Business NewBusiness(int id, string name, string? stall, string account,
        VendorStatus status = VendorStatus.Active) => new()
    {
        Id = id, BusinessName = name, StallNumber = stall, BusinessAccountNumber = account,
        OwnerFirstName = "Owner", OwnerLastName = $"No{id}", HouseNumber = "1", Street = "Market Lane",
        Barangay = "Sta. Elena", City = "Marikina City", QrCodeValue = $"qr-{id}", Status = status,
        MarketSectionId = Section.Id, MarketSection = Section
    };

    private static AppDbContext Context(IEnumerable<Business>? businesses = null, IEnumerable<Ticket>? tickets = null,
        IEnumerable<Person>? persons = null)
    {
        var context = new AppDbContext(new DbContextOptionsBuilder<AppDbContext>().Options);
        context.Businesses = new AccountDatabaseSet<Business>(businesses ?? []);
        context.Tickets = new AccountDatabaseSet<Ticket>(tickets ?? []);
        context.Persons = new AccountDatabaseSet<Person>(persons ?? []);
        return context;
    }

    private static List<Business> SearchFixture() =>
    [
        NewBusiness(1, "Aling Nena's Store", "12", "ACC-100"),
        NewBusiness(2, "Bert's Fish", "112", "ACC-200"),
        NewBusiness(3, "Nena Bakery", "12", "ACC-300", VendorStatus.Inactive),
        NewBusiness(4, "Carlo Hardware", null, "ACC-12X"),
        NewBusiness(5, "Zeny Dry Goods", "12", "ACC-500"),
    ];

    [Theory]
    [InlineData("nena", new[] { 1 })]          // name, any case; inactive Nena Bakery hidden
    [InlineData("NENA", new[] { 1 })]
    [InlineData("acc-200", new[] { 2 })]       // account number still works
    [InlineData("12", new[] { 1, 5, 2, 4 })]   // exact stall 12 first (Aling, Zeny), then 112 and ACC-12X by name
    [InlineData("zzz", new int[0])]
    public async Task Search_matches_name_stall_or_account_number_for_active_businesses_only(string search, int[] expectedIds)
    {
        using var context = Context(SearchFixture());
        var (items, total) = await new VendorRepository(context).SearchActiveBusinessesAsync(search, 20);
        Assert.Equal(expectedIds, items.Select(i => i.VendorId));
        Assert.Equal(expectedIds.Length, total);
    }

    // Slice A3: owner name (either order) and address. All addresses are in "Marikina City".
    private static Business Owned(Business business, string first, string last, string house, string street, string barangay)
    {
        business.OwnerFirstName = first;
        business.OwnerLastName = last;
        business.HouseNumber = house;
        business.Street = street;
        business.Barangay = barangay;
        return business;
    }

    private static List<Business> OwnerAddressFixture() =>
    [
        Owned(NewBusiness(1, "Aling Nena's Store", "12", "ACC-100"), "Maria", "Santos", "12", "Shoe Ave", "Sto. Niño"),
        Owned(NewBusiness(2, "Bert's Fish", "112", "ACC-200"), "Roberto", "Cruz", "5", "Gil Fernando Ave", "San Roque"),
        Owned(NewBusiness(3, "Nena Bakery", "12", "ACC-300", VendorStatus.Inactive), "Maria", "Santos", "3", "Shoe Ave", "Sto. Niño"),
        Owned(NewBusiness(4, "Carlo Hardware", null, "ACC-12X"), "Carlo", "Santos", "8", "J.P. Rizal St", "San Roque"),
    ];

    [Theory]
    [InlineData("santos", new[] { 1, 4 })]        // last name; inactive Nena Bakery (also Santos) hidden
    [InlineData("MARIA SANTOS", new[] { 1 })]     // first then last, any case
    [InlineData("santos maria", new[] { 1 })]     // last then first
    [InlineData("roberto cruz", new[] { 2 })]
    [InlineData("cruz roberto", new[] { 2 })]
    [InlineData("maria cruz", new int[0])]        // names of two different owners do not combine
    [InlineData("shoe ave", new[] { 1 })]         // street; inactive Nena Bakery on the same street hidden
    [InlineData("san roque", new[] { 2, 4 })]     // barangay, sorted by business name
    [InlineData("sto. niño", new[] { 1 })]
    [InlineData("marikina", new[] { 1, 2, 4 })]   // city: every active business
    public async Task Search_matches_owner_name_in_either_order_or_address(string search, int[] expectedIds)
    {
        using var context = Context(OwnerAddressFixture());
        var (items, total) = await new VendorRepository(context).SearchActiveBusinessesAsync(search, 20);
        Assert.Equal(expectedIds, items.Select(i => i.VendorId));
        Assert.Equal(expectedIds.Length, total);
    }

    [Fact]
    public async Task Search_returns_at_most_20_and_reports_more()
    {
        var shops = Enumerable.Range(1, 21).Select(i => NewBusiness(i, $"Shop {i:00}", null, $"ACC-{i:000}"));
        using var context = Context(shops);
        var page = await Service(context).SearchBusinessesAsync("shop");
        Assert.Equal(20, page.Items.Count);
        Assert.Equal(21, page.Total);
        Assert.True(page.HasMore);
        Assert.Equal("Shop 01", page.Items[0].TradeName);
        Assert.Equal("Dry Goods", page.Items[0].MarketSectionName);
    }

    [Theory]
    [InlineData(null)]
    [InlineData("   ")]
    public async Task Search_rejects_empty_text(string? search)
    {
        using var context = Context(SearchFixture());
        var error = await Assert.ThrowsAsync<ValidationException>(() => Service(context).SearchBusinessesAsync(search));
        Assert.Equal("Enter a business name, stall, owner, address or account number.", error.Message);
    }

    [Fact]
    public async Task Search_rejects_text_over_200_characters()
    {
        using var context = Context(SearchFixture());
        await Assert.ThrowsAsync<ValidationException>(() => Service(context).SearchBusinessesAsync(new string('a', 201)));
    }

    private static VendorService Service(AppDbContext context) =>
        new(null!, new VendorRepository(context), null!, null!, null!, null!, null!, null!, null!);

    // People fixture: Juan (1) ticketed at Store X then Store Y; Maria (2) only warned at Store X;
    // Pedro (3) cited at Store Y for community service; Ana (4) has no tickets; one legacy ticket has no person.
    private static AppDbContext PeopleContext()
    {
        var storeX = NewBusiness(10, "Store X", "5", "ACC-X");
        var storeY = NewBusiness(20, "Store Y", "6", "ACC-Y");
        var storeZ = NewBusiness(30, "Store Z", "7", "ACC-Z", VendorStatus.Inactive);
        var officer = new User { FirstName = "Test", LastName = "Officer", DateOfBirth = new(1990, 1, 1),
            HouseNumber = "1", Street = "Market Lane", Barangay = "Synthetic", City = "Marikina" };
        Ticket NewTicket(int id, Business business, int? personId, ViolationType type, TicketStatus? status,
            PenaltyType? penalty, decimal? amount, int day) => new()
        {
            Id = id, VendorId = business.Id, Vendor = business, PersonId = personId, Enforcer = officer,
            Description = "Synthetic", Type = type, Status = status, PenaltyType = penalty,
            TotalPaymentAmount = amount, IssuedAt = new DateTime(2026, 10, day, 2, 0, 0, DateTimeKind.Utc),
            MarketSection = Section
        };
        return Context([storeX, storeY, storeZ],
        [
            NewTicket(1, storeX, 1, ViolationType.Ticket, TicketStatus.Paid, PenaltyType.CashFine, 500, 1),
            NewTicket(2, storeY, 1, ViolationType.Ticket, TicketStatus.Pending, PenaltyType.CashFine, 500, 5),
            NewTicket(3, storeX, 2, ViolationType.Warning, null, null, null, 3),
            NewTicket(4, storeY, 3, ViolationType.Ticket, TicketStatus.InProgress, PenaltyType.CommunityService, null, 2),
            NewTicket(5, storeY, null, ViolationType.Ticket, TicketStatus.Pending, PenaltyType.CashFine, 800, 6),        ],
        [
            new() { Id = 1, FullName = "Juan Dela Cruz", Address = "1 Shoe Ave" },
            new() { Id = 2, FullName = "Maria Santos", Address = "2 Shoe Ave" },
            new() { Id = 3, FullName = "Pedro Reyes", Address = "3 Shoe Ave" },
            new() { Id = 4, FullName = "Juan Bautista", Address = "4 Shoe Ave" },
        ]);
    }

    private static TicketService PeopleService(AppDbContext context) => new(new TicketRepository(context), null!,
        new VendorRepository(context), null!, null!, null!, null!, personRepository: new PersonRepository(context));

    [Fact]
    public async Task Business_people_are_those_ticketed_there_newest_first_with_totals_across_all_businesses()
    {
        using var context = PeopleContext();
        var service = PeopleService(context);

        var storeY = await service.GetBusinessPeopleAsync(20);
        Assert.Equal(new[] { 1, 3 }, storeY.Select(p => p.Id));   // Juan (Oct 5), Pedro (Oct 2); legacy ticket has no person

        var juan = storeY[0];
        Assert.Equal("Juan Dela Cruz", juan.FullName);
        Assert.Equal(2, juan.TicketTotals.OffenseCount);           // one citation at X, one at Y
        Assert.Equal(0, juan.TicketTotals.WarningCount);
        Assert.Equal(500m, juan.TicketTotals.OutstandingFine);      // X ticket paid, Y ticket pending ₱500
        Assert.Equal(new DateTime(2026, 10, 5, 2, 0, 0, DateTimeKind.Utc), juan.TicketTotals.LastTicketAt);
        Assert.Equal("Store Y", juan.TicketTotals.LastBusinessName);
        Assert.Equal(new[] { "Store X", "Store Y" }, juan.TicketTotals.BusinessNames);

        var pedro = storeY[1];
        Assert.Equal(1, pedro.TicketTotals.OffenseCount);
        Assert.Equal(0m, pedro.TicketTotals.OutstandingFine);       // community service is not a cash fine

        var storeX = await service.GetBusinessPeopleAsync(10);
        Assert.Equal(new[] { 2, 1 }, storeX.Select(p => p.Id));   // Maria warned Oct 3, Juan cited Oct 1
        var maria = storeX[0];
        Assert.Equal(0, maria.TicketTotals.OffenseCount);
        Assert.Equal(1, maria.TicketTotals.WarningCount);
        Assert.Equal("Store X", maria.TicketTotals.LastBusinessName);
    }

    [Fact]
    public async Task Business_people_reject_missing_and_invalid_businesses()
    {
        using var context = PeopleContext();
        var service = PeopleService(context);
        await Assert.ThrowsAsync<RecordNotFoundException>(() => service.GetBusinessPeopleAsync(99));
        await Assert.ThrowsAsync<RecordNotFoundException>(() => service.GetBusinessPeopleAsync(30));   // inactive Store Z
        await Assert.ThrowsAsync<InvalidRequestException>(() => service.GetBusinessPeopleAsync(0));
    }

    [Fact]
    public async Task Person_matches_show_ticket_totals_so_a_helper_from_another_business_is_recognised()
    {
        using var context = PeopleContext();
        var service = new PersonService(new PersonRepository(context), new TicketRepository(context));
        var page = await service.MatchAsync(new PersonMatchRequest { Name = "juan" });

        Assert.Equal(new[] { 4, 1 }, page.Items.Select(p => p.Id));  // sorted by name: Juan Bautista, Juan Dela Cruz
        var bautista = page.Items[0];
        Assert.Equal(0, bautista.TicketTotals.OffenseCount);
        Assert.Null(bautista.TicketTotals.LastTicketAt);
        Assert.Null(bautista.TicketTotals.LastBusinessName);
        Assert.Empty(bautista.TicketTotals.BusinessNames);
        var delaCruz = page.Items[1];
        Assert.Equal(2, delaCruz.TicketTotals.OffenseCount);
        Assert.Equal("Store Y", delaCruz.TicketTotals.LastBusinessName);
        Assert.Equal(new[] { "Store X", "Store Y" }, delaCruz.TicketTotals.BusinessNames);
    }
}

public class BusinessLookupRouteTests
{
    [Fact]
    public void Old_account_number_route_is_gone_and_new_routes_are_enforcer_only()
    {
        var routes = typeof(MarikinaMarket.API.Presentation.Controllers.VendorController).GetMethods()
            .SelectMany(m => m.GetCustomAttributes(typeof(Microsoft.AspNetCore.Mvc.HttpGetAttribute), false)
                .Cast<Microsoft.AspNetCore.Mvc.HttpGetAttribute>().Select(a => (Method: m, a.Template)))
            .ToList();
        Assert.DoesNotContain(routes, r => r.Template!.StartsWith("stall/"));
        foreach (var template in new[] { "lookup", "{businessId:int}/people" })
        {
            var method = Assert.Single(routes, r => r.Template == template).Method;
            var roles = method.GetCustomAttributes(typeof(Microsoft.AspNetCore.Authorization.AuthorizeAttribute), false)
                .Cast<Microsoft.AspNetCore.Authorization.AuthorizeAttribute>().Single().Roles;
            Assert.Equal("MarketEnforcer", roles);
        }
    }
}
