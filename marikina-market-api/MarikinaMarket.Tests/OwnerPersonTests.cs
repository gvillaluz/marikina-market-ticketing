using MarikinaMarket.API.Application;
using MarikinaMarket.API.Application.DTOs.Person.Response;
using MarikinaMarket.API.Application.Interfaces.Repositories;
using MarikinaMarket.API.Application.Services;
using MarikinaMarket.API.Domain.Entities;
using MarikinaMarket.API.Domain.Enums;
using MarikinaMarket.API.Infrastructure.Persistence;
using MarikinaMarket.API.Infrastructure.Repositories;
using MarikinaMarket.API.Presentation.Controllers;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Routing;
using Microsoft.EntityFrameworkCore;
using Xunit;

namespace MarikinaMarket.Tests;

// Violator selection: the registered owner's person record, found or added from the business record.
// Expected values are worked out by hand from the synthetic records below.
public class OwnerPersonTests
{
    private static readonly MarketSection Section = new() { Id = 1, Name = "Dry Goods", Description = "Synthetic" };

    // Store X (10): owner Maria Santos, address "12, Shoe Ave, Sto. Niño, Marikina City".
    private static Business Store(int id, string first, string last, VendorStatus status = VendorStatus.Active) => new()
    {
        Id = id, BusinessName = $"Store {id}", BusinessAccountNumber = $"ACC-{id}", QrCodeValue = $"qr-{id}",
        OwnerFirstName = first, OwnerLastName = last, HouseNumber = "12", Street = "Shoe Ave",
        Barangay = "Sto. Niño", City = "Marikina City", Status = status, MarketSectionId = Section.Id, MarketSection = Section
    };

    private const string OwnerAddress = "12, Shoe Ave, Sto. Niño, Marikina City";

    private static List<Business> Stores() =>
    [
        Store(10, "Maria", "Santos"),
        Store(20, "Roberto", "Cruz"),
        Store(30, "Ana", "Reyes", VendorStatus.Inactive),
    ];

    private static AppDbContext Context(List<Business> businesses, List<Person> persons, List<Ticket>? tickets = null)
    {
        var context = new AppDbContext(new DbContextOptionsBuilder<AppDbContext>().Options);
        context.Businesses = new AccountDatabaseSet<Business>(businesses);
        context.Persons = new AccountDatabaseSet<Person>(persons);
        context.Tickets = new AccountDatabaseSet<Ticket>(tickets ?? []);
        return context;
    }

    // Keeps people in a list so adds can be counted; every lookup runs the real repository query over the list.
    private sealed class ListPersonRepository(List<Business> businesses, List<Person> persons) : IPersonRepository
    {
        public int Saves { get; private set; }
        private PersonRepository Real() => new(Context(businesses, persons));
        public Task<Person?> GetAsync(int id) => Real().GetAsync(id);
        public Task<List<Person>> GetManyAsync(List<int> ids) => Real().GetManyAsync(ids);
        public Task<(List<Person> Items, int Total)> MatchAsync(string[] n, string? a, string? p, int o, int l) => Real().MatchAsync(n, a, p, o, l);
        public Task<(List<Person> Items, int Total)> SearchAsync(string? s, int o, int l) => Real().SearchAsync(s, o, l);
        public Task<Person?> FindExactAsync(string fullName, string address) => Real().FindExactAsync(fullName, address);
        public Task AddAsync(Person person)
        {
            person.Id = persons.Count == 0 ? 1 : persons.Max(p => p.Id) + 1;
            persons.Add(person);
            return Task.CompletedTask;
        }
        public Task SaveChangesAsync() { Saves++; return Task.CompletedTask; }
    }

    private static (TicketService Service, ListPersonRepository People) Service(List<Person> persons, List<Ticket>? tickets = null)
    {
        var businesses = Stores();
        var context = Context(businesses, persons, tickets);
        var people = new ListPersonRepository(businesses, persons);
        return (new TicketService(new TicketRepository(context), null!, new VendorRepository(context),
            null!, null!, null!, null!, personRepository: people), people);
    }

    [Fact]
    public async Task Owner_person_is_the_record_with_the_owners_exact_name_and_address_ignoring_case_and_spaces()
    {
        var officer = new User { FirstName = "Test", LastName = "Officer", DateOfBirth = new(1990, 1, 1),
            HouseNumber = "1", Street = "Market Lane", Barangay = "Synthetic", City = "Marikina" };
        var persons = new List<Person>
        {
            new() { Id = 1, FullName = "Maria Santos", Address = "99 Other St" },              // same name, other address
            new() { Id = 2, FullName = "Maria Santos Jr", Address = OwnerAddress },          // same address, other name
            new() { Id = 3, FullName = " maria SANTOS ", Address = "12, shoe ave, sto. niño, marikina city " },
        };
        var tickets = new List<Ticket>
        {
            new() { Id = 1, VendorId = 10, PersonId = 3, Enforcer = officer, Description = "Synthetic",
                Type = ViolationType.Ticket, Status = TicketStatus.Pending, PenaltyType = PenaltyType.CashFine,
                TotalPaymentAmount = 500, IssuedAt = new DateTime(2026, 10, 4, 2, 0, 0, DateTimeKind.Utc), MarketSection = Section },
        };
        var (service, _) = Service(persons, tickets);

        var owner = await service.GetOwnerPersonAsync(10);

        Assert.NotNull(owner);
        Assert.Equal(3, owner!.Id);
        Assert.Equal(1, owner.TicketTotals.OffenseCount);         // the one pending ticket
        Assert.Equal(500m, owner.TicketTotals.OutstandingFine);
    }

    [Fact]
    public async Task Owner_person_is_none_when_no_record_matches_and_the_oldest_when_two_do()
    {
        var persons = new List<Person>
        {
            new() { Id = 7, FullName = "Roberto Cruz", Address = OwnerAddress },
            new() { Id = 4, FullName = "Roberto Cruz", Address = OwnerAddress },
        };
        var (service, _) = Service(persons);

        Assert.Null(await service.GetOwnerPersonAsync(10));         // nobody is Maria Santos
        Assert.Equal(4, (await service.GetOwnerPersonAsync(20))!.Id); // two Roberto Cruz records: lower ID wins
    }

    [Fact]
    public async Task Adding_the_owner_copies_the_business_record_and_never_makes_a_second_one()
    {
        var persons = new List<Person>();
        var (service, people) = Service(persons);

        var first = await service.AddOwnerPersonAsync(10);
        var second = await service.AddOwnerPersonAsync(10);

        var saved = Assert.Single(persons);
        Assert.Equal("Maria Santos", saved.FullName);
        Assert.Equal(OwnerAddress, saved.Address);
        Assert.Null(saved.PhoneNumber);
        Assert.Equal(saved.Id, first.Id);
        Assert.Equal(saved.Id, second.Id);
        Assert.Equal(0, first.TicketTotals.OffenseCount);
        Assert.Equal(1, people.Saves);
    }

    [Fact]
    public async Task Adding_the_owner_returns_the_existing_record()
    {
        var persons = new List<Person> { new() { Id = 5, FullName = "MARIA SANTOS", Address = OwnerAddress } };
        var (service, people) = Service(persons);

        var owner = await service.AddOwnerPersonAsync(10);

        Assert.Equal(5, owner.Id);
        Assert.Single(persons);
        Assert.Equal(0, people.Saves);
    }

    [Fact]
    public async Task Missing_inactive_and_invalid_businesses_are_refused()
    {
        var (service, people) = Service([]);
        await Assert.ThrowsAsync<RecordNotFoundException>(() => service.GetOwnerPersonAsync(99));
        await Assert.ThrowsAsync<RecordNotFoundException>(() => service.GetOwnerPersonAsync(30));
        await Assert.ThrowsAsync<InvalidRequestException>(() => service.GetOwnerPersonAsync(0));
        await Assert.ThrowsAsync<RecordNotFoundException>(() => service.AddOwnerPersonAsync(99));
        await Assert.ThrowsAsync<RecordNotFoundException>(() => service.AddOwnerPersonAsync(30));
        await Assert.ThrowsAsync<InvalidRequestException>(() => service.AddOwnerPersonAsync(0));
        Assert.Equal(0, people.Saves);
    }

    [Fact]
    public async Task Route_answers_no_content_when_the_owner_has_no_record_and_the_person_when_one_exists()
    {
        var (service, _) = Service([new() { Id = 4, FullName = "Roberto Cruz", Address = OwnerAddress }]);
        var controller = new VendorController(null!);

        Assert.IsType<NoContentResult>((await controller.GetOwnerPerson(10, service)).Result);
        var ok = Assert.IsType<OkObjectResult>((await controller.GetOwnerPerson(20, service)).Result);
        Assert.Equal(4, Assert.IsType<PersonSummaryResponse>(ok.Value).Id);
    }

    [Fact]
    public void Owner_person_routes_are_enforcer_only()
    {
        foreach (var verb in new[] { typeof(HttpGetAttribute), typeof(HttpPostAttribute) })
        {
            var method = Assert.Single(typeof(VendorController).GetMethods(), m => m.GetCustomAttributes(verb, false)
                .Cast<HttpMethodAttribute>().Any(a => a.Template == "{businessId:int}/owner-person"));
            var roles = method.GetCustomAttributes(typeof(AuthorizeAttribute), false).Cast<AuthorizeAttribute>().Single().Roles;
            Assert.Equal("MarketEnforcer", roles);
        }
    }
}
