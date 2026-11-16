using MarikinaMarket.API.Application.DTOs.Tickets.Request;
using MarikinaMarket.API.Application.Services;
using MarikinaMarket.API.Domain.Entities;
using MarikinaMarket.API.Domain.Enums;
using MarikinaMarket.API.Infrastructure.Persistence;
using MarikinaMarket.API.Infrastructure.Repositories;
using Microsoft.EntityFrameworkCore;
using Xunit;

namespace MarikinaMarket.Tests;

// The Tickets list total counts only the tickets that match the street, status and search filters.
// The records are synthetic and held in memory.
public class AdminTicketTotalTests
{
    private static readonly MarketSection Dry = new() { Id = 1, Name = "Dry Goods" };
    private static readonly MarketSection Wet = new() { Id = 2, Name = "Wet Market" };
    private static readonly User Enforcer = new()
    {
        Id = 50, FirstName = "Pedro", LastName = "Santos", DateOfBirth = new(1990, 1, 1),
        HouseNumber = "1", Street = "Market Lane", Barangay = "Synthetic", City = "Marikina"
    };

    private static Ticket NewTicket(int id, ViolationType type, MarketSection section, TicketStatus status, string violator) => new()
    {
        Id = id, Type = type, PaperReference = $"{id:D6}", ControlNumber = $"{id:D6}", PaperViolatorName = violator,
        EnforcerId = Enforcer.Id, Enforcer = Enforcer, MarketSectionId = section.Id, MarketSection = section,
        Description = "Synthetic", Status = status, IssuedAt = DateTime.UtcNow.Date.AddDays(-id),
        UpdatedAt = DateTime.UtcNow.Date.AddDays(-id)
    };

    // Tickets 1-4 are tickets; 5 is a warning, which the Tickets list never counts.
    private static Ticket[] Records() =>
    [
        NewTicket(1, ViolationType.Ticket, Dry, TicketStatus.Pending, "Juan Cruz"),
        NewTicket(2, ViolationType.Ticket, Dry, TicketStatus.Paid, "Ana Reyes"),
        NewTicket(3, ViolationType.Ticket, Wet, TicketStatus.Pending, "Ben Cruz"),
        NewTicket(4, ViolationType.Ticket, Wet, TicketStatus.Pending, "Carl Lim"),
        NewTicket(5, ViolationType.Warning, Wet, TicketStatus.Pending, "Dina Cruz"),
    ];

    private static async Task<(int Rows, int? Total)> Load(TicketSummaryFilters filters)
    {
        var context = new AppDbContext(new DbContextOptionsBuilder<AppDbContext>().Options);
        context.Tickets = new AccountDatabaseSet<Ticket>(Records());
        var service = new TicketService(new TicketRepository(context), null!, new VendorRepository(context), null!, null!, null!, null!);
        var page = await service.GetAdminTicketAsync(0, filters);
        return (page.Items.Count(), page.Total);
    }

    [Fact]
    public async Task With_no_filter_the_total_counts_every_ticket_but_not_warnings() =>
        Assert.Equal((4, 4), await Load(new TicketSummaryFilters()));

    [Fact]
    public async Task The_street_filter_limits_the_total() =>
        Assert.Equal((2, 2), await Load(new TicketSummaryFilters { MarketSectionId = Dry.Id }));

    [Fact]
    public async Task The_status_filter_limits_the_total() =>
        Assert.Equal((3, 3), await Load(new TicketSummaryFilters { Status = TicketStatus.Pending }));

    [Fact]
    public async Task The_search_limits_the_total() =>
        Assert.Equal((2, 2), await Load(new TicketSummaryFilters { Search = "cruz" }));

    [Fact]
    public async Task Filters_together_limit_the_total() =>
        Assert.Equal((1, 1), await Load(new TicketSummaryFilters { MarketSectionId = Wet.Id, Status = TicketStatus.Pending, Search = "cruz" }));
}
