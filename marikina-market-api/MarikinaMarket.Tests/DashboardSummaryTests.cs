using System.Reflection;
using System.Net;
using System.Text.Json;
using MarikinaMarket.API.Application.DTOs.Analytics.Internal;
using MarikinaMarket.API.Application.DTOs.Analytics.Response;
using MarikinaMarket.API.Application.DTOs.Audits.Internal;
using MarikinaMarket.API.Application.DTOs.User.Response;
using MarikinaMarket.API.Application.Interfaces.Repositories;
using MarikinaMarket.API.Application.Interfaces.Services;
using MarikinaMarket.API.Application.Services;
using MarikinaMarket.API.Domain.Entities;
using MarikinaMarket.API.Domain.Enums;
using MarikinaMarket.API.Infrastructure.Persistence;
using MarikinaMarket.API.Infrastructure.Repositories;
using MarikinaMarket.API.Presentation.Controllers;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Xunit;
using Module = MarikinaMarket.API.Domain.Enums.Module;

namespace MarikinaMarket.Tests;

public class DashboardSummaryTests
{
    [Fact]
    public async Task GetSummaryAsync_CombinesOwnerRepositoryDataAndMapsRecentActivity()
    {
        var tickets = DashboardTicketRepositoryStub.Create();
        ((DashboardTicketRepositoryStub)(object)tickets).Counts = new DashboardTicketCounts
        {
            WarningsToday = 5,
            TicketsToday = 7,
            OpenTickets = 8
        };
        // Issued exactly 8 days ago, so due 3 days ago: 3 days overdue whatever the time of day.
        ((DashboardTicketRepositoryStub)(object)tickets).Overdue = new DashboardOverdueTickets
        {
            Total = 6,
            Items =
            [
                new DashboardOverdueTicket
                {
                    Id = 41, ControlNumber = "2026-000418", VendorId = 3,
                    BusinessName = "Synthetic Meat Shop", IssuedAt = DateTime.UtcNow.AddDays(-8)
                }
            ]
        };
        var vendors = DashboardVendorRepositoryStub.Create();
        ((DashboardVendorRepositoryStub)(object)vendors).ActiveBusinesses = 247;
        var auditLogs = DashboardAuditRepositoryStub.Create();
        ((DashboardAuditRepositoryStub)(object)auditLogs).Activities =
        [
            new AuditLog
            {
                Id = 1101,
                Timestamp = DateTime.UtcNow,
                UserId = 8,
                Action = "SaveNewInspection",
                Module = Module.Tickets,
                Result = LogResult.Success,
                Details = "Inspection recorded for Market Section A."
            }
        ];
        var users = AuditUserRepositoryStub.Create();
        var service = new DashboardService(tickets, vendors, auditLogs, users);

        var result = await service.GetSummaryAsync();

        Assert.Equal(5, result.Metrics.WarningsToday);
        Assert.Equal(7, result.Metrics.TicketsToday);
        Assert.Equal(8, result.Metrics.OpenTickets);
        Assert.Equal(247, result.Metrics.ActiveBusinesses);
        Assert.Equal(DateTimeKind.Utc, result.AsOf.Kind);
        Assert.Equal(6, result.OverdueTickets.Total);
        var overdue = Assert.Single(result.OverdueTickets.Items);
        Assert.Equal(41, overdue.Id);
        Assert.Equal("2026-000418", overdue.ControlNumber);
        Assert.Equal(3, overdue.VendorId);
        Assert.Equal("Synthetic Meat Shop", overdue.BusinessName);
        Assert.Equal(3, overdue.DaysOverdue);
        Assert.Equal(5, ((DashboardTicketRepositoryStub)(object)tickets).OverdueLimit);
        var activity = Assert.Single(result.RecentActivity);
        Assert.Equal("Inspection", activity.Category);
        Assert.Equal("Inspection completed", activity.Title);
        Assert.Equal("Maria Santos", activity.ActorName);
        Assert.Equal(5, ((DashboardAuditRepositoryStub)(object)auditLogs).Limit);

        var ticketStub = (DashboardTicketRepositoryStub)(object)tickets;
        Assert.Equal(TimeSpan.FromDays(1), ticketStub.EndUtc - ticketStub.StartUtc);
        Assert.Equal(DateTimeKind.Utc, ticketStub.StartUtc.Kind);
        Assert.Equal(DateTimeKind.Utc, ticketStub.EndUtc.Kind);
        var manila = TimeZoneInfo.FindSystemTimeZoneById("Asia/Manila");
        Assert.Equal(TimeSpan.Zero, TimeZoneInfo.ConvertTimeFromUtc(ticketStub.StartUtc, manila).TimeOfDay);
        Assert.InRange(result.AsOf, ticketStub.StartUtc, ticketStub.EndUtc.AddTicks(-1));
    }

    [Fact]
    public async Task Dashboard_counts_match_the_hand_worked_example()
    {
        // Manila "today" is 7 Nov 2026: 6 Nov 16:00 UTC up to 7 Nov 16:00 UTC.
        var startUtc = Utc(2026, 11, 6, 16);
        var endUtc = Utc(2026, 11, 7, 16);
        using var context = new AppDbContext(new DbContextOptionsBuilder<AppDbContext>().Options)
        {
            Tickets = new AccountDatabaseSet<Ticket>(
            [
                Record(1, Utc(2026, 11, 7, 1), ViolationType.Warning, null),          // today 9:00 am
                Record(2, Utc(2026, 11, 7, 15, 59), ViolationType.Warning, null),     // today 11:59 pm
                Record(3, Utc(2026, 11, 6, 16), ViolationType.Ticket, TicketStatus.Paid),        // today 12:00 am
                Record(4, Utc(2026, 11, 7, 3), ViolationType.Ticket, TicketStatus.Pending),
                Record(5, Utc(2026, 11, 7, 5), ViolationType.Ticket, TicketStatus.Contested),
                Record(6, Utc(2026, 11, 6, 15, 59), ViolationType.Ticket, TicketStatus.Pending), // yesterday 11:59 pm
                Record(7, Utc(2026, 10, 31, 2), ViolationType.Ticket, TicketStatus.Overdue),
                Record(8, Utc(2026, 11, 1, 2), ViolationType.Ticket, TicketStatus.Cleared)
            ]),
            Businesses = new AccountDatabaseSet<Business>(
            [
                Shop(1, VendorStatus.Active), Shop(2, VendorStatus.Active),
                Shop(3, VendorStatus.Active), Shop(4, VendorStatus.Inactive)
            ])
        };

        var counts = await new TicketRepository(context).GetDashboardTicketCountsAsync(startUtc, endUtc);
        var activeBusinesses = await new VendorRepository(context).GetActiveBusinessCountAsync();

        Assert.Equal(2, counts.WarningsToday);
        Assert.Equal(3, counts.TicketsToday);
        Assert.Equal(4, counts.OpenTickets); // 4 waiting, 5 contested, 6 waiting, 7 overdue.
        Assert.Equal(3, activeBusinesses);
    }

    [Fact]
    public async Task Dashboard_counts_tickets_and_warnings_for_unregistered_vendors()
    {
        // Manila "today" is 7 Nov 2026. Today: a warning and a waiting ticket for a registered business,
        // a warning, a waiting ticket and a paid ticket for unregistered vendors (a person, no business).
        var registeredWarning = Record(1, Utc(2026, 11, 7, 1), ViolationType.Warning, null);
        var registeredTicket = Record(2, Utc(2026, 11, 7, 2), ViolationType.Ticket, TicketStatus.Pending);
        registeredWarning.VendorId = 1;
        registeredTicket.VendorId = 1;
        var unregisteredWarning = Record(3, Utc(2026, 11, 7, 3), ViolationType.Warning, null);
        var unregisteredWaiting = Record(4, Utc(2026, 11, 7, 4), ViolationType.Ticket, TicketStatus.Pending);
        var unregisteredPaid = Record(5, Utc(2026, 11, 7, 5), ViolationType.Ticket, TicketStatus.Paid);
        foreach (var record in new[] { unregisteredWarning, unregisteredWaiting, unregisteredPaid })
        {
            record.PersonId = 1;
            record.PaperViolatorName = "Synthetic Vendor";
        }
        using var context = new AppDbContext(new DbContextOptionsBuilder<AppDbContext>().Options)
        {
            Tickets = new AccountDatabaseSet<Ticket>(
                [registeredWarning, registeredTicket, unregisteredWarning, unregisteredWaiting, unregisteredPaid])
        };

        var counts = await new TicketRepository(context)
            .GetDashboardTicketCountsAsync(Utc(2026, 11, 6, 16), Utc(2026, 11, 7, 16));

        Assert.Equal(2, counts.WarningsToday);
        Assert.Equal(3, counts.TicketsToday);
        Assert.Equal(2, counts.OpenTickets); // the two waiting tickets, one of each kind.
    }

    [Fact]
    public async Task Dashboard_overdue_list_matches_the_hand_worked_example()
    {
        // Seven overdue tickets (one for an unregistered vendor) and records that must stay out:
        // a waiting, a paid and a contested ticket, and a warning (warnings have no status).
        var unregistered = Overdue(2, Utc(2026, 11, 9, 1), "2026-000402", null, null);
        unregistered.PersonId = 1;
        unregistered.PaperViolatorName = "Synthetic Vendor";
        using var context = new AppDbContext(new DbContextOptionsBuilder<AppDbContext>().Options)
        {
            Tickets = new AccountDatabaseSet<Ticket>(
            [
                Overdue(6, Utc(2026, 11, 18, 1), "2026-000431", 6, "Synthetic Carinderia"),
                Overdue(1, Utc(2026, 11, 5, 1), "2026-000391", 1, "Synthetic Fruit Stand"),
                Overdue(3, Utc(2026, 11, 12, 1), "2026-000410", 3, "Synthetic Dry Goods"),
                Overdue(7, Utc(2026, 11, 18, 23), "2026-000436", 7, "Synthetic Vegetables"),
                Overdue(5, Utc(2026, 11, 16, 1), "2026-000425", 5, "Synthetic Rice Center"),
                unregistered,
                Overdue(4, Utc(2026, 11, 14, 1), "2026-000418", 4, "Synthetic Meat Shop"),
                Record(8, Utc(2026, 11, 1, 1), ViolationType.Ticket, TicketStatus.Pending),
                Record(9, Utc(2026, 11, 1, 1), ViolationType.Ticket, TicketStatus.Paid),
                Record(10, Utc(2026, 11, 2, 1), ViolationType.Ticket, TicketStatus.Contested),
                Record(11, Utc(2026, 11, 1, 1), ViolationType.Warning, null)
            ])
        };

        var overdue = await new TicketRepository(context).GetDashboardOverdueTicketsAsync(5);

        Assert.Equal(7, overdue.Total);
        Assert.Equal([1, 2, 3, 4, 5], overdue.Items.Select(ticket => ticket.Id).ToArray());
        Assert.Equal(
            ["2026-000391", "2026-000402", "2026-000410", "2026-000418", "2026-000425"],
            overdue.Items.Select(ticket => ticket.ControlNumber!).ToArray());
        Assert.Null(overdue.Items[1].VendorId);
        Assert.Null(overdue.Items[1].BusinessName);
        Assert.Equal(1, overdue.Items[0].VendorId);
        Assert.Equal("Synthetic Fruit Stand", overdue.Items[0].BusinessName);
        Assert.Equal(Utc(2026, 11, 5, 1), overdue.Items[0].IssuedAt);
    }

    [Fact]
    public async Task Dashboard_overdue_list_breaks_equal_issue_times_by_ticket_number()
    {
        var sameTime = Utc(2026, 11, 10, 2);
        using var context = new AppDbContext(new DbContextOptionsBuilder<AppDbContext>().Options)
        {
            Tickets = new AccountDatabaseSet<Ticket>(
            [
                Overdue(12, sameTime, "2026-000512", 1, "Synthetic shop 1"),
                Overdue(11, sameTime, "2026-000511", 1, "Synthetic shop 1")
            ])
        };

        var overdue = await new TicketRepository(context).GetDashboardOverdueTicketsAsync(5);

        Assert.Equal([11, 12], overdue.Items.Select(ticket => ticket.Id).ToArray());
    }

    // "Now" is 24 Nov 2026, 2:00 pm in Manila (06:00 UTC). A ticket is due 5 days after it was issued.
    [Theory]
    [InlineData(2026, 11, 5, 1, 14)]   // issued 5 Nov 9:00 am, due 10 Nov
    [InlineData(2026, 11, 9, 1, 10)]   // due 14 Nov
    [InlineData(2026, 11, 12, 1, 7)]   // due 17 Nov
    [InlineData(2026, 11, 14, 1, 5)]   // due 19 Nov
    [InlineData(2026, 11, 16, 1, 3)]   // due 21 Nov
    [InlineData(2026, 11, 18, 1, 1)]   // due 23 Nov
    [InlineData(2026, 11, 18, 23, 0)]  // issued 19 Nov 7:00 am Manila, due today; counted in UTC it would be 1
    [InlineData(2026, 11, 22, 1, 0)]   // set to Overdue by hand before its due date (27 Nov): never below 0
    public void Days_overdue_are_counted_on_Manila_dates(int year, int month, int day, int hour, int expected)
        => Assert.Equal(expected, DashboardService.CountDaysOverdue(Utc(year, month, day, hour), Utc(2026, 11, 24, 6)));

    private static Ticket Overdue(int id, DateTime issuedAt, string controlNumber, int? vendorId, string? businessName)
    {
        var ticket = Record(id, issuedAt, ViolationType.Ticket, TicketStatus.Overdue);
        ticket.PaperReference = controlNumber;
        ticket.ControlNumber = $"hidden-{id}";
        ticket.VendorId = vendorId;
        ticket.SnapshotBusinessAccountNumber = businessName is null ? null : $"BA-{vendorId:0000}";
        ticket.SnapshotBusinessName = businessName;
        return ticket;
    }

    private static DateTime Utc(int year, int month, int day, int hour, int minute = 0)
        => new(year, month, day, hour, minute, 0, DateTimeKind.Utc);

    private static Ticket Record(int id, DateTime issuedAt, ViolationType type, TicketStatus? status) => new()
    {
        Id = id, IssuedAt = issuedAt, UpdatedAt = issuedAt, Type = type, Status = status,
        Description = "Synthetic dashboard record", MarketSectionId = 1
    };

    private static Business Shop(int id, VendorStatus status) => new()
    {
        Id = id, BusinessAccountNumber = $"BA-{id:0000}", BusinessName = $"Synthetic shop {id}",
        QrCodeValue = $"synthetic-{id}", Status = status, MarketSectionId = 1
    };

    [Fact]
    public async Task GetSummaryAsync_ReturnsNoOverdueTicketsAndNoActivityForZeroCounts()
    {
        var tickets = DashboardTicketRepositoryStub.Create();
        var vendors = DashboardVendorRepositoryStub.Create();
        var auditLogs = DashboardAuditRepositoryStub.Create();
        var users = AuditUserRepositoryStub.Create();
        var service = new DashboardService(tickets, vendors, auditLogs, users);

        var result = await service.GetSummaryAsync();

        Assert.Equal(0, result.OverdueTickets.Total);
        Assert.Empty(result.OverdueTickets.Items);
        Assert.Empty(result.RecentActivity);
        Assert.Equal(0, result.Metrics.WarningsToday);
        Assert.Equal(0, result.Metrics.TicketsToday);
        Assert.Equal(0, result.Metrics.OpenTickets);
        Assert.Equal(0, result.Metrics.ActiveBusinesses);
        Assert.Empty(((AuditUserRepositoryStub)(object)users).NameRequests);
    }

    [Fact]
    public void DashboardSummaryEndpoint_RestrictsRouteToAdministratorRoles()
    {
        var controller = typeof(DashboardController);
        var authorize = controller.GetCustomAttribute<AuthorizeAttribute>();
        var route = controller.GetCustomAttribute<RouteAttribute>();
        var get = controller.GetMethod(nameof(DashboardController.GetSummary))!
            .GetCustomAttribute<HttpGetAttribute>();

        Assert.Equal("HeadAdmin,AdminOfficer", authorize?.Roles);
        Assert.Equal("api/dashboard", route?.Template);
        Assert.Equal("summary", get?.Template);
    }

    [Theory]
    [InlineData("HeadAdmin", HttpStatusCode.OK)]
    [InlineData("AdminOfficer", HttpStatusCode.OK)]
    [InlineData("MarketEnforcer", HttpStatusCode.Forbidden)]
    [InlineData("MarketVendor", HttpStatusCode.Forbidden)]
    public async Task DashboardSummaryEndpoint_EnforcesAdministratorRoles(string role, HttpStatusCode expected)
    {
        await using var host = await AuditHost.CreateAsync(services =>
            services.AddSingleton<IDashboardService, DashboardServiceStub>());

        var response = await host.SendAsync(HttpMethod.Get, "/api/dashboard/summary", role);

        Assert.Equal(expected, response.StatusCode);
        if (expected == HttpStatusCode.OK)
        {
            using var json = JsonDocument.Parse(await response.Content.ReadAsStringAsync());
            var metrics = json.RootElement.GetProperty("metrics");
            Assert.Equal(
                ["warnings_today", "tickets_today", "open_tickets", "active_businesses"],
                metrics.EnumerateObject().Select(property => property.Name).ToArray());
            Assert.True(json.RootElement.TryGetProperty("recent_activity", out _));
            var overdue = json.RootElement.GetProperty("overdue_tickets");
            Assert.Equal(
                ["total", "items"],
                overdue.EnumerateObject().Select(property => property.Name).ToArray());
            Assert.False(json.RootElement.TryGetProperty("attention_items", out _));
        }
    }

    [Fact]
    public async Task DashboardSummaryEndpoint_RequiresAuthentication()
    {
        await using var host = await AuditHost.CreateAsync(services =>
            services.AddSingleton<IDashboardService, DashboardServiceStub>());

        var response = await host.SendAsync(HttpMethod.Get, "/api/dashboard/summary", role: null);

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }
}

public sealed class DashboardServiceStub : IDashboardService
{
    public Task<DashboardSummaryResponse> GetSummaryAsync()
        => Task.FromResult(new DashboardSummaryResponse
        {
            AsOf = DateTime.UtcNow,
            Metrics = new DashboardMetricsResponse()
        });
}

public class DashboardTicketRepositoryStub : DispatchProxy
{
    public DashboardTicketCounts Counts { get; set; } = new();
    public DashboardOverdueTickets Overdue { get; set; } = new();
    public int OverdueLimit { get; private set; }
    public DateTime StartUtc { get; private set; }
    public DateTime EndUtc { get; private set; }

    public static ITicketRepository Create()
        => DispatchProxy.Create<ITicketRepository, DashboardTicketRepositoryStub>();

    protected override object? Invoke(MethodInfo? targetMethod, object?[]? args)
    {
        if (targetMethod?.Name == nameof(ITicketRepository.GetDashboardTicketCountsAsync))
        {
            StartUtc = (DateTime)args![0]!;
            EndUtc = (DateTime)args[1]!;
            return Task.FromResult(Counts);
        }
        if (targetMethod?.Name == nameof(ITicketRepository.GetDashboardOverdueTicketsAsync))
        {
            OverdueLimit = (int)args![0]!;
            return Task.FromResult(Overdue);
        }
        throw new InvalidOperationException($"Unexpected ticket repository call: {targetMethod?.Name}");
    }
}

public class DashboardVendorRepositoryStub : DispatchProxy
{
    public int ActiveBusinesses { get; set; }

    public static IVendorRepository Create()
        => DispatchProxy.Create<IVendorRepository, DashboardVendorRepositoryStub>();

    protected override object? Invoke(MethodInfo? targetMethod, object?[]? args)
    {
        if (targetMethod?.Name == nameof(IVendorRepository.GetActiveBusinessCountAsync))
            return Task.FromResult(ActiveBusinesses);
        throw new InvalidOperationException($"Unexpected vendor repository call: {targetMethod?.Name}");
    }
}

public class DashboardAuditRepositoryStub : DispatchProxy
{
    public List<AuditLog> Activities { get; set; } = [];
    public int Limit { get; private set; }

    public static IAuditLogRepository Create()
        => DispatchProxy.Create<IAuditLogRepository, DashboardAuditRepositoryStub>();

    protected override object? Invoke(MethodInfo? targetMethod, object?[]? args)
    {
        if (targetMethod?.Name == nameof(IAuditLogRepository.GetRecentDashboardActivitiesAsync))
        {
            Limit = (int)args![0]!;
            return Task.FromResult(Activities);
        }
        throw new InvalidOperationException($"Unexpected audit repository call: {targetMethod?.Name}");
    }
}
