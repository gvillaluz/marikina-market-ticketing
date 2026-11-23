using MarikinaMarket.API.Application.DTOs.Tickets.Request;
using MarikinaMarket.API.Application.DTOs.Vendor.Request;
using MarikinaMarket.API.Application.Services;
using MarikinaMarket.API.Domain.Entities;
using MarikinaMarket.API.Domain.Enums;
using MarikinaMarket.API.Infrastructure.Persistence;
using MarikinaMarket.API.Infrastructure.Repositories;
using Microsoft.EntityFrameworkCore;
using Xunit;

namespace MarikinaMarket.Tests;

// When a table is searched, rows where the typed text is a whole word come first, then the rest, each group in the
// order the table already uses. A whole word has no letter or digit right before or after it, so `cruz` is a whole
// word in "Juan Cruz" and "Ana Dela-Cruz" but not in "Cruzado". Expected ids are worked out by hand from the
// records in each test (synthetic names). The data is in memory, so these tests cannot prove that the database runs
// the whole-word rule the same way; the live check does.
public class ExactSearchFirstTests
{
    private static readonly MarketSection Section = new() { Id = 1, Name = "Dry Goods" };
    private static readonly User Enforcer = new()
    {
        Id = 50, FirstName = "Pedro", LastName = "Santos", DateOfBirth = new(1990, 1, 1),
        HouseNumber = "1", Street = "Market Lane", Barangay = "Synthetic", City = "Marikina"
    };

    private static Business NewBusiness(int id, string name, string account) => new()
    {
        Id = id, BusinessName = name, StallNumber = $"S{id}", BusinessAccountNumber = account,
        OwnerFirstName = "Nena", OwnerLastName = "Dizon", HouseNumber = "1", Street = "Market Lane",
        Barangay = "Sta. Elena", City = "Marikina City", QrCodeValue = $"qr-{id}", Status = VendorStatus.Active,
        MarketSectionId = Section.Id, MarketSection = Section
    };

    private static Ticket NewTicket(int id, ViolationType type, int daysAgo, string? violator = null,
        Person? person = null, Business? business = null) => new()
    {
        Id = id, Type = type, PaperReference = type == ViolationType.Ticket ? $"{id:D6}" : null,
        ControlNumber = $"{id:D6}", PaperViolatorName = violator, PersonId = person?.Id, Person = person,
        VendorId = business?.Id, Vendor = business, EnforcerId = Enforcer.Id, Enforcer = Enforcer,
        MarketSectionId = Section.Id, MarketSection = Section, Description = "Synthetic", Status = TicketStatus.Pending,
        IssuedAt = DateTime.UtcNow.Date.AddDays(-daysAgo), UpdatedAt = DateTime.UtcNow.Date.AddDays(-daysAgo)
    };

    private static AppDbContext ContextWith(params Ticket[] tickets)
    {
        var context = new AppDbContext(new DbContextOptionsBuilder<AppDbContext>().Options);
        context.Tickets = new AccountDatabaseSet<Ticket>(tickets);
        context.Businesses = new AccountDatabaseSet<Business>(
            tickets.Where(t => t.Vendor != null).Select(t => t.Vendor!).DistinctBy(b => b.Id));
        return context;
    }

    private static TicketService Service(AppDbContext context) =>
        new(new TicketRepository(context), null!, new VendorRepository(context), null!, null!, null!, null!);

    // ---- The whole-word rule itself ----

    [Theory]
    [InlineData("cruz", "Juan Cruz", true)]
    [InlineData("CRUZ", "Ana Dela-Cruz", true)]
    [InlineData("cruz", "Cruzado", false)]
    [InlineData("cruz", "Decruz", false)]
    [InlineData("a-12", "Stall A-12", true)]
    [InlineData("a-12", "A-120", false)]
    [InlineData("12", "A_12_B", true)]          // an underscore does not count as a letter
    [InlineData("ni", "Niño", false)]           // an accented letter is a letter
    [InlineData("oz", "Muñoz", false)]
    [InlineData("pe", "Peña", false)]
    [InlineData("cruz", "Peña Cruz", true)]
    [InlineData("(jr)", "Ben (Jr) Reyes", true)] // symbols are plain text, not search commands
    [InlineData("a.c", "abc", false)]
    public void The_whole_word_rule_follows_the_website(string search, string text, bool expected) =>
        Assert.Equal(expected, System.Text.RegularExpressions.Regex.IsMatch(text, WholeWordSearch.Pattern(search),
            System.Text.RegularExpressions.RegexOptions.IgnoreCase));

    // ---- Tickets (newest first) ----

    // Ticket 1 (newest) "Cruzado Lim" is only part of a word; 2 "Juan Cruz" and 3 "Maria Dela-Cruz" are whole words.
    private static Ticket[] CruzTickets() =>
    [
        NewTicket(1, ViolationType.Ticket, 1, "Cruzado Lim"),
        NewTicket(2, ViolationType.Ticket, 2, "Juan Cruz"),
        NewTicket(3, ViolationType.Ticket, 3, "Maria Dela-Cruz"),
    ];

    [Fact]
    public async Task Tickets_with_the_search_as_a_whole_word_come_first()
    {
        using var context = ContextWith(CruzTickets());
        var page = await Service(context).GetAdminTicketAsync(0, new TicketSummaryFilters { Search = "CRUZ" });
        Assert.Equal([2, 3, 1], page.Items.Select(i => i.Id));
        Assert.Equal(3, page.Total);
    }

    [Fact]
    public async Task Tickets_without_a_search_keep_newest_first()
    {
        using var context = ContextWith(CruzTickets());
        var page = await Service(context).GetAdminTicketAsync(0, new TicketSummaryFilters());
        Assert.Equal([1, 2, 3], page.Items.Select(i => i.Id));
    }

    [Fact]
    public async Task A_whole_word_match_on_a_later_page_moves_to_the_first_page()
    {
        // Tickets 1-11 (newest) are only part of a word; ticket 12 (oldest) is the whole word, so it is on page 2 today.
        var tickets = Enumerable.Range(1, 11).Select(id => NewTicket(id, ViolationType.Ticket, id, $"Cruzado {id}"))
            .Append(NewTicket(12, ViolationType.Ticket, 12, "Juan Cruz")).ToArray();
        using var context = ContextWith(tickets);
        var page = await Service(context).GetAdminTicketAsync(0, new TicketSummaryFilters { Search = "cruz" });
        Assert.Equal(12, page.Items.First().Id);
        Assert.Equal(10, page.Items.Count());
        Assert.Equal(12, page.Total);
        Assert.True(page.HasMore);
    }

    [Fact]
    public async Task Symbols_in_the_search_are_plain_text()
    {
        // Account A-12 is the whole text; A-120 only starts with it.
        var tickets = new[]
        {
            NewTicket(1, ViolationType.Ticket, 1, business: NewBusiness(10, "Sari Shop", "A-120")),
            NewTicket(2, ViolationType.Ticket, 2, business: NewBusiness(11, "Fish Stall", "A-12")),
        };
        using var context = ContextWith(tickets);
        var page = await Service(context).GetAdminTicketAsync(0, new TicketSummaryFilters { Search = "a-12" });
        Assert.Equal([2, 1], page.Items.Select(i => i.Id));
        var withBracket = await Service(context).GetAdminTicketAsync(0, new TicketSummaryFilters { Search = "(a-12" });
        Assert.Empty(withBracket.Items);
    }

    // ---- Inspections (newest first) ----

    [Fact]
    public async Task Inspections_with_the_search_as_a_whole_word_come_first()
    {
        // Warning 1 (newest) person "Cruzado Ana" is part of a word; ticket 2 "Juan Cruz" and warning 3 person "Ana Cruz" are whole.
        var tickets = new[]
        {
            NewTicket(1, ViolationType.Warning, 1, person: new Person { Id = 21, FullName = "Cruzado Ana", Address = "Synthetic" }),
            NewTicket(2, ViolationType.Ticket, 2, "Juan Cruz"),
            NewTicket(3, ViolationType.Warning, 3, person: new Person { Id = 22, FullName = "Ana Cruz", Address = "Synthetic" }),
        };
        using var context = ContextWith(tickets);
        var page = await Service(context).GetAdminInspectionAsync(0, new InspectionSummaryFilters { Search = "cruz" });
        Assert.Equal([2, 3, 1], page.Items.Select(i => i.TicketId));
        Assert.Equal(3, page.Total);
    }

    [Fact]
    public async Task Inspections_without_a_search_keep_newest_first()
    {
        using var context = ContextWith(CruzTickets());
        var page = await Service(context).GetAdminInspectionAsync(0, new InspectionSummaryFilters());
        Assert.Equal([1, 2, 3], page.Items.Select(i => i.TicketId));
    }

    // ---- Owner full names, on both tables ----

    // Ticket 1 (newest) has owner "Nena Reyesa", where the search is only part of a word; ticket 2 has "Nena Reyes".
    private static Ticket[] OwnerNameTickets()
    {
        var partial = NewBusiness(10, "Sari Shop", "A-10");
        partial.OwnerLastName = "Reyesa";
        var whole = NewBusiness(11, "Fish Stall", "A-11");
        whole.OwnerLastName = "Reyes";
        return [NewTicket(1, ViolationType.Ticket, 1, business: partial), NewTicket(2, ViolationType.Ticket, 2, business: whole)];
    }

    // The same names, this time as the owner saved on each ticket.
    private static Ticket[] SavedOwnerNameTickets()
    {
        var tickets = new[]
        {
            NewTicket(1, ViolationType.Ticket, 1, business: NewBusiness(10, "Sari Shop", "A-10")),
            NewTicket(2, ViolationType.Ticket, 2, business: NewBusiness(11, "Fish Stall", "A-11")),
        };
        tickets[0].SnapshotRegisteredOwnerName = "Lito Ramosa";
        tickets[1].SnapshotRegisteredOwnerName = "Lito Ramos";
        return tickets;
    }

    [Fact]
    public async Task A_whole_owner_name_comes_first_on_Tickets()
    {
        using var context = ContextWith(OwnerNameTickets());
        var page = await Service(context).GetAdminTicketAsync(0, new TicketSummaryFilters { Search = "nena reyes" });
        Assert.Equal([2, 1], page.Items.Select(i => i.Id));
    }

    [Fact]
    public async Task A_whole_owner_name_comes_first_on_Inspections()
    {
        using var context = ContextWith(OwnerNameTickets());
        var page = await Service(context).GetAdminInspectionAsync(0, new InspectionSummaryFilters { Search = "nena reyes" });
        Assert.Equal([2, 1], page.Items.Select(i => i.TicketId));
    }

    [Fact]
    public async Task A_whole_saved_owner_name_comes_first_on_Tickets()
    {
        using var context = ContextWith(SavedOwnerNameTickets());
        var page = await Service(context).GetAdminTicketAsync(0, new TicketSummaryFilters { Search = "lito ramos" });
        Assert.Equal([2, 1], page.Items.Select(i => i.Id));
    }

    [Fact]
    public async Task A_whole_saved_owner_name_comes_first_on_Inspections()
    {
        using var context = ContextWith(SavedOwnerNameTickets());
        var page = await Service(context).GetAdminInspectionAsync(0, new InspectionSummaryFilters { Search = "lito ramos" });
        Assert.Equal([2, 1], page.Items.Select(i => i.TicketId));
    }

    // ---- Persons (A to Z by full name) ----

    private static PersonRepository PersonsWith(params Person[] people)
    {
        var context = new AppDbContext(new DbContextOptionsBuilder<AppDbContext>().Options);
        context.Persons = new AccountDatabaseSet<Person>(people);
        return new PersonRepository(context);
    }

    private static Person NewPerson(int id, string name) => new() { Id = id, FullName = name, Address = "Synthetic" };

    [Fact]
    public async Task Persons_with_the_search_as_a_whole_word_come_first_then_A_to_Z()
    {
        // A to Z today: Ana Dela-Cruz (3), Cruzado Ana (1), Juan Cruz (2).
        var repository = PersonsWith(NewPerson(1, "Cruzado Ana"), NewPerson(2, "Juan Cruz"), NewPerson(3, "Ana Dela-Cruz"));
        var (items, total) = await repository.SearchAsync("Cruz", 0, 10);
        Assert.Equal([3, 2, 1], items.Select(p => p.Id));
        Assert.Equal(3, total);
    }

    [Fact]
    public async Task Persons_without_a_search_keep_A_to_Z()
    {
        var repository = PersonsWith(NewPerson(1, "Cruzado Ana"), NewPerson(2, "Juan Cruz"), NewPerson(3, "Ana Dela-Cruz"));
        var (items, _) = await repository.SearchAsync(null, 0, 10);
        Assert.Equal([3, 1, 2], items.Select(p => p.Id));
    }

    // ---- Businesses (by account number) ----

    private static VendorRepository BusinessesWith(params Business[] businesses)
    {
        var context = new AppDbContext(new DbContextOptionsBuilder<AppDbContext>().Options);
        context.Businesses = new AccountDatabaseSet<Business>(businesses);
        return new VendorRepository(context);
    }

    [Fact]
    public async Task Businesses_with_the_search_as_a_whole_word_come_first_then_by_account_number()
    {
        // By account number today: A-001 "Cruzado Store" (10), A-002 "Cruz Store" (11).
        var repository = BusinessesWith(NewBusiness(10, "Cruzado Store", "A-001"), NewBusiness(11, "Cruz Store", "A-002"));
        var items = await repository.GetAdminVendorSummariesAsync(0, 10, new AdminVendorSummaryFilter { Search = "cruz" });
        Assert.Equal([11, 10], items.Select(i => i.VendorId));
    }

    [Fact]
    public async Task Businesses_without_a_search_keep_account_number_order()
    {
        var repository = BusinessesWith(NewBusiness(10, "Cruzado Store", "A-001"), NewBusiness(11, "Cruz Store", "A-002"));
        var items = await repository.GetAdminVendorSummariesAsync(0, 10, new AdminVendorSummaryFilter());
        Assert.Equal([10, 11], items.Select(i => i.VendorId));
    }

    // ---- A business's inspection history (newest or oldest first, the user picks) ----

    private static Ticket WithOrdinance(Ticket ticket, Business business, string ordinanceNo)
    {
        ticket.VendorId = business.Id;
        ticket.Vendor = business;
        ticket.TicketViolations =
        [
            new TicketViolation
            {
                Id = ticket.Id, TicketId = ticket.Id, OrdinanceId = ticket.Id,
                Ordinance = new Ordinance { Id = ticket.Id, OrdinanceNo = ordinanceNo, Series = "2020", Title = "Synthetic" }
            }
        ];
        return ticket;
    }

    // The whole-word ordinance "12" goes first under either sort, and the picked sort still applies inside each group.
    // Ticket 1 holds ordinance "123" (part of a number); ticket 2 holds "12"; the other ticket is far older or newer.
    [Theory]
    [InlineData("asc", 1, 5)]   // exact is the newest, so plain oldest-first would put it last
    [InlineData("desc", 5, 1)]  // exact is the oldest, so plain newest-first would put it last
    public async Task History_with_the_search_as_a_whole_word_comes_first_under_every_sort(
        string sort, int exactDaysAgo, int partialDaysAgo)
    {
        var business = NewBusiness(10, "Sari Shop", "A-1");
        var exact = WithOrdinance(NewTicket(1, ViolationType.Ticket, exactDaysAgo), business, "12");
        var partial = WithOrdinance(NewTicket(2, ViolationType.Ticket, partialDaysAgo), business, "123");
        using var context = ContextWith(partial, exact);
        var page = await Service(context).GetVendorInspectionHistoryAsync(10, 0,
            new VendorInspectionHistoryFilters { Search = "12", SortDirection = sort });
        Assert.Equal([1, 2], page.Items.Select(i => i.TicketId));
    }

    [Fact]
    public async Task History_without_a_search_keeps_the_picked_sort()
    {
        var business = NewBusiness(10, "Sari Shop", "A-1");
        var newest = WithOrdinance(NewTicket(1, ViolationType.Ticket, 1), business, "12");
        var oldest = WithOrdinance(NewTicket(2, ViolationType.Ticket, 5), business, "123");
        using var context = ContextWith(newest, oldest);
        var service = Service(context);
        var desc = await service.GetVendorInspectionHistoryAsync(10, 0, new VendorInspectionHistoryFilters { SortDirection = "desc" });
        var asc = await service.GetVendorInspectionHistoryAsync(10, 0, new VendorInspectionHistoryFilters { SortDirection = "asc" });
        Assert.Equal([1, 2], desc.Items.Select(i => i.TicketId));
        Assert.Equal([2, 1], asc.Items.Select(i => i.TicketId));
    }
}
