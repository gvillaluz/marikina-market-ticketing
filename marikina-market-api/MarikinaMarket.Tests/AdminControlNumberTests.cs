using System.Data.Common;
using MarikinaMarket.API.Application.DTOs.Tickets.Request;
using MarikinaMarket.API.Application.DTOs.Vendor.Request;
using MarikinaMarket.API.Application.Services;
using MarikinaMarket.API.Domain.Entities;
using MarikinaMarket.API.Domain.Enums;
using MarikinaMarket.API.Infrastructure.Persistence;
using MarikinaMarket.API.Infrastructure.Repositories;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Diagnostics;
using Xunit;

namespace MarikinaMarket.Tests;

// Control number Part 2: the website's admin routes send the shown control number (the printed paper number
// for a ticket, the WRN number for a warning, nothing for an old ticket without a printed number), never the
// app's hidden running number. Expected values are worked out by hand from the records below.
//   Ticket A  (id 1): printed "000456", hidden "7"
//   Warning W (id 2): "WRN-0011"
//   Old ticket L (id 3): no printed number, hidden "8"
// No other searched field contains 7 or 8, so searching them can only hit the hidden numbers.
public class AdminControlNumberTests
{
    private const int EnforcerId = 50;
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
            Id = EnforcerId, FirstName = "Test", LastName = "Officer", DateOfBirth = new(1990, 1, 1),
            HouseNumber = "1", Street = "Market Lane", Barangay = "Synthetic", City = "Marikina"
        };
        Ticket NewTicket(int id, ViolationType type, string? hidden, string? printed, int day) => new()
        {
            Id = id, Type = type, ControlNumber = hidden, PaperReference = printed,
            VendorId = BusinessId, Vendor = business, EnforcerId = EnforcerId, Enforcer = officer,
            MarketSectionId = section.Id, MarketSection = section, Description = "Synthetic",
            Status = type == ViolationType.Ticket ? TicketStatus.Pending : null,
            PenaltyType = type == ViolationType.Ticket ? PenaltyType.CommunityService : null,
            CommunityServiceHours = type == ViolationType.Ticket ? 8 : null,
            IssuedAt = DateTime.UtcNow.Date.AddDays(-day), UpdatedAt = DateTime.UtcNow.Date.AddDays(-day)
        };

        var context = new AppDbContext(new DbContextOptionsBuilder<AppDbContext>().Options);
        context.Businesses = new AccountDatabaseSet<Business>([business]);
        context.Tickets = new AccountDatabaseSet<Ticket>(
        [
            NewTicket(1, ViolationType.Ticket, "7", "000456", 1),
            NewTicket(2, ViolationType.Warning, "WRN-0011", null, 2),
            NewTicket(3, ViolationType.Ticket, "8", null, 3),
        ]);
        return context;
    }

    private static TicketService TicketService(AppDbContext context) =>
        new(new TicketRepository(context), null!, new VendorRepository(context), null!, null!, null!, null!);

    private static VendorService VendorService(AppDbContext context) =>
        new(null!, new VendorRepository(context), null!, null!, null!, null!, null!, null!, null!);

    private static readonly (int Id, string? Number)[] AllThree = [(1, "000456"), (2, "WRN-0011"), (3, null)];
    private static readonly (int Id, string? Number)[] TicketsOnly = [(1, "000456"), (3, null)];

    [Fact]
    public async Task Tickets_list_sends_the_printed_number()
    {
        using var context = Context();
        var page = await TicketService(context).GetAdminTicketAsync(0, new TicketSummaryFilters());
        Assert.Equal(TicketsOnly, page.Items.Select(i => (i.Id, i.ControlNumber)));
    }

    [Fact]
    public async Task Ticket_detail_sends_the_shown_number()
    {
        using var context = Context();
        var repository = new TicketRepository(context);
        foreach (var (id, number) in AllThree)
            Assert.Equal(number, (await repository.GetAdminTicketDetailAsync(id))!.ControlNumber);
    }

    [Fact]
    public async Task Inspections_list_sends_the_shown_number()
    {
        using var context = Context();
        var page = await TicketService(context).GetAdminInspectionAsync(0, new InspectionSummaryFilters());
        Assert.Equal(AllThree, page.Items.Select(i => (i.TicketId, i.ControlNumber)));
    }

    [Fact]
    public async Task Business_inspection_history_sends_the_shown_number()
    {
        using var context = Context();
        var page = await TicketService(context).GetVendorInspectionHistoryAsync(BusinessId, 0, new VendorInspectionHistoryFilters());
        Assert.Equal(AllThree, page.Items.Select(i => (i.TicketId, i.ControlNumber)));
    }

    [Fact]
    public async Task Community_service_log_sends_the_printed_number()
    {
        using var context = Context();
        var page = await TicketService(context).GetCommunityServiceLogsAsync(0, null);
        Assert.Equal(TicketsOnly, page.Items.Select(i => (i.TicketId, i.ControlNumber)));
    }

    [Fact]
    public async Task Compliance_activity_sends_the_shown_number()
    {
        using var context = Context();
        var overview = await VendorService(context).GetAdminVendorComplianceOverviewAsync();
        Assert.Equal(AllThree, overview.Activities.Select(i => (i.TicketId, i.ControlNumber)));
    }

    [Fact]
    public async Task Pending_settlements_send_the_printed_number()
    {
        using var context = Context();
        var page = await VendorService(context).GetPendingTicketSettlementsAsync(0);
        Assert.Equal(TicketsOnly, page.Items.Select(i => (i.TicketId, i.ControlNumber)));
    }

    [Fact]
    public async Task Enforcer_inspection_history_sends_the_shown_number()
    {
        using var context = Context();
        var page = await new EnforcerService(null!, new TicketRepository(context), null!).GetInspectionHistoryAsync(EnforcerId, 0);
        Assert.Equal(AllThree, page.Items.Select(i => (i.TicketId, i.ControlNumber)));
    }

    [Theory]
    [InlineData("000456", new[] { 1 })]
    [InlineData("WRN-0011", new int[0])]   // the tickets list holds no warnings
    [InlineData("7", new int[0])]          // hidden numbers are not searched
    [InlineData("8", new int[0])]
    public async Task Tickets_search_matches_the_shown_number_only(string search, int[] expectedIds)
    {
        using var context = Context();
        var page = await TicketService(context).GetAdminTicketAsync(0, new TicketSummaryFilters { Search = search });
        Assert.Equal(expectedIds, page.Items.Select(i => i.Id));
    }

    [Theory]
    [InlineData("000456", new[] { 1 })]
    [InlineData("wrn-0011", new[] { 2 })]  // any capitalisation
    [InlineData("WRN-0011", new[] { 2 })]
    [InlineData("7", new int[0])]
    [InlineData("8", new int[0])]
    public async Task Inspections_search_matches_the_shown_number_only(string search, int[] expectedIds)
    {
        using var context = Context();
        var page = await TicketService(context).GetAdminInspectionAsync(0, new InspectionSummaryFilters { Search = search });
        Assert.Equal(expectedIds, page.Items.Select(i => i.TicketId));
        Assert.Equal(expectedIds.Length, page.Total);
    }

    [Theory]
    [InlineData("000456", new[] { 1 })]    // printed numbers were not searched here before
    [InlineData("wrn-0011", new[] { 2 })]
    [InlineData("7", new int[0])]
    [InlineData("8", new int[0])]
    public async Task Business_history_search_matches_the_shown_number_only(string search, int[] expectedIds)
    {
        using var context = Context();
        var page = await TicketService(context).GetVendorInspectionHistoryAsync(BusinessId, 0,
            new VendorInspectionHistoryFilters { Search = search });
        Assert.Equal(expectedIds, page.Items.Select(i => i.TicketId));
        Assert.Equal(expectedIds.Length, page.Total);
    }

    // The checks above run in memory. This one makes sure every changed query still turns into a real
    // PostgreSQL query (no part left that the database cannot run).
    [Fact]
    public async Task Changed_queries_translate_to_sql()
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseNpgsql("Host=unused;Database=model_only;Username=model_only")
            .UseSnakeCaseNamingConvention()
            .AddInterceptors(new SuppressConnection(), new StopAtCommand()).Options;
        await using var context = new AppDbContext(options);
        var tickets = new TicketRepository(context);
        var vendors = new VendorRepository(context);

        Func<Task>[] queries =
        [
            () => tickets.GetAdminTicketAsync(0, 10, new TicketSummaryFilters { Search = "000456" }),
            () => tickets.GetAdminTicketDetailAsync(1),
            () => tickets.GetAdminInspectionAsync(0, 10, new InspectionSummaryFilters { Search = "wrn" }),
            () => tickets.GetAdminInspectionCountAsync(new InspectionSummaryFilters { Search = "wrn" }),
            () => tickets.GetVendorInspectionHistoryAsync(BusinessId, 0, 10, new VendorInspectionHistoryFilters { Search = "wrn" }),
            () => tickets.GetVendorInspectionHistoryCountAsync(BusinessId, new VendorInspectionHistoryFilters { Search = "wrn" }),
            () => tickets.GetCommunityServiceLogsAsync(0, 10, null),
            () => tickets.GetEnforcerInspectionHistory(EnforcerId, 0, 10),
            () => vendors.GetRecentVendorActivitiesAsync(5),
            () => vendors.GetPendingTicketSettlementsAsync(0, 5),
        ];
        foreach (var query in queries)
            await Assert.ThrowsAsync<CommandReachedException>(query);
    }

    private sealed class SuppressConnection : DbConnectionInterceptor
    {
        public override ValueTask<InterceptionResult> ConnectionOpeningAsync(DbConnection connection,
            ConnectionEventData eventData, InterceptionResult result, CancellationToken cancellationToken = default)
            => ValueTask.FromResult(InterceptionResult.Suppress());
    }

    private sealed class CommandReachedException : Exception { }

    private sealed class StopAtCommand : DbCommandInterceptor
    {
        public override ValueTask<InterceptionResult<DbDataReader>> ReaderExecutingAsync(DbCommand command,
            CommandEventData eventData, InterceptionResult<DbDataReader> result, CancellationToken cancellationToken = default)
            => throw new CommandReachedException();

        public override ValueTask<InterceptionResult<object>> ScalarExecutingAsync(DbCommand command,
            CommandEventData eventData, InterceptionResult<object> result, CancellationToken cancellationToken = default)
            => throw new CommandReachedException();
    }
}
