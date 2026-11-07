using System.Net;
using System.Reflection;
using System.Text.Json;
using MarikinaMarket.API.Application.DTOs.Audits.Internal;
using MarikinaMarket.API.Application.DTOs.Vendor.Response;
using MarikinaMarket.API.Application.Interfaces.Repositories;
using MarikinaMarket.API.Application.Interfaces.Services;
using MarikinaMarket.API.Application.Services;
using MarikinaMarket.API.Domain.Entities;
using MarikinaMarket.API.Domain.Enums;
using MarikinaMarket.API.Infrastructure.Persistence;
using MarikinaMarket.API.Infrastructure.Repositories;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Xunit;
using Module = MarikinaMarket.API.Domain.Enums.Module;

namespace MarikinaMarket.Tests;

public class TicketChangeHistoryTests
{
    private static readonly DateTime Issued = new(2026, 11, 2, 1, 0, 0, DateTimeKind.Utc);

    // Ticket 5's own successful actions, plus look-alikes that must stay out.
    private static List<AuditLog> SeededLogs() =>
    [
        Log(1, "SaveNewInspection", Module.Tickets, "5", LogResult.Success, 8, Role.MarketEnforcer, Issued,
            "Inspection creation completed successfully."),
        Log(2, "UpdateTicketStatus", Module.Tickets, "5", LogResult.Success, 7, Role.HeadAdmin, Issued.AddHours(1),
            "Ticket status update completed successfully."),
        Log(3, "UpdateTicketStatus", Module.Tickets, "5", LogResult.Failed, 7, Role.HeadAdmin, Issued.AddHours(2),
            "Ticket status update failed (HTTP 409)."),
        Log(4, "Update", Module.Vendors, "5", LogResult.Success, 7, Role.HeadAdmin, Issued.AddHours(3),
            "Business record update completed successfully."),
        Log(5, "UpdateTicketStatus", Module.Tickets, "6", LogResult.Success, 7, Role.HeadAdmin, Issued.AddHours(4),
            "Ticket status update completed successfully."),
        Log(6, "SubmitTicketReceiptProof", Module.Tickets, "5", LogResult.Success, 8, Role.MarketEnforcer,
            Issued.AddHours(5), "Ticket receipt submission completed successfully."),
        Log(7, "LogCommunityServiceHours", Module.Tickets, "5", LogResult.Success, 8, Role.MarketEnforcer,
            Issued.AddHours(6), "Community-service hours recording completed successfully."),
        Log(8, "MarkTicketOverdue", Module.Tickets, "5", LogResult.Success, null, null, Issued.AddHours(7),
            "System marked a ticket overdue and created its notification."),
        Log(9, "RequestFailedAfterCommit", Module.Tickets, "5", LogResult.Failed, 7, Role.HeadAdmin,
            Issued.AddHours(8), "Ticket status update committed, but request completion failed (HTTP 500)."),
        Log(10, "AuthorizationFailed", Module.Security, "5", LogResult.Failed, 8, Role.MarketEnforcer,
            Issued.AddHours(9), "Request was denied (HTTP 403)."),
        Log(11, "SaveNewInspection", Module.Tickets, "55", LogResult.Success, 8, Role.MarketEnforcer,
            Issued.AddHours(10), "Inspection creation completed successfully."),
        Log(12, "UnlistedTicketAction", Module.Tickets, "5", LogResult.Success, 7, Role.HeadAdmin,
            Issued.AddHours(11), "An action that is not part of a ticket's change history."),
        // A target number belongs to its module: record 5 elsewhere is not ticket 5.
        Log(13, "UpdateTicketStatus", Module.Reports, "5", LogResult.Success, 7, Role.HeadAdmin,
            Issued.AddHours(12), "Ticket status update completed successfully.")
    ];

    [Fact]
    public async Task Repository_returns_only_this_tickets_successful_actions_newest_first()
    {
        using var context = new AppDbContext(new DbContextOptionsBuilder<AppDbContext>().Options);
        context.AuditLogs = new AccountDatabaseSet<AuditLog>(SeededLogs());

        var logs = await new AuditLogRepository(context).GetTicketHistoryAsync(5);

        Assert.Equal([8, 7, 6, 2, 1], logs.Select(log => log.Id));
    }

    [Theory]
    [InlineData("HeadAdmin")]
    [InlineData("AdminOfficer")]
    public async Task History_lists_plain_labels_names_and_times_newest_first(string role)
    {
        var fixture = new Fixture();
        await using var host = await fixture.CreateHostAsync();
        host.Repository.Logs.AddRange(SeededLogs());

        using var response = await host.SendAsync(HttpMethod.Get, "/api/admin/tickets/5/history", role);

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        using var json = JsonDocument.Parse(await response.Content.ReadAsStringAsync());
        var entries = json.RootElement.EnumerateArray().ToList();
        Assert.Equal(["Marked overdue", "Community service hours recorded", "Receipt proof submitted",
            "Status changed", "Issued"], entries.Select(entry => entry.GetProperty("action").GetString()));
        Assert.Equal(["System", "Maria Santos", "Maria Santos", "Juan Dela Cruz", "Maria Santos"],
            entries.Select(entry => entry.GetProperty("performed_by").GetString()));
        Assert.Equal([null, "MarketEnforcer", "MarketEnforcer", "HeadAdmin", "MarketEnforcer"],
            entries.Select(entry => entry.GetProperty("role").ValueKind == JsonValueKind.Null
                ? null : entry.GetProperty("role").GetString()));
        Assert.All(entries, entry => Assert.Equal(JsonValueKind.Null, entry.GetProperty("details").ValueKind));
        Assert.Equal(Issued, entries[^1].GetProperty("occurred_at").GetDateTime().ToUniversalTime());
    }

    [Fact]
    public async Task Status_change_records_old_and_new_status_and_shows_it_in_the_history()
    {
        var fixture = new Fixture();
        await using var host = await fixture.CreateHostAsync();
        host.Repository.Logs.Add(Log(1, "SaveNewInspection", Module.Tickets, "5", LogResult.Success, 8,
            Role.MarketEnforcer, Issued, "Inspection creation completed successfully."));

        using var update = await host.SendAsync(HttpMethod.Patch, "/api/admin/tickets/5/update-status",
            "HeadAdmin", "{\"new_status\":\"Contested\",\"version\":7}");
        Assert.Equal(HttpStatusCode.OK, update.StatusCode);
        using var history = await host.SendAsync(HttpMethod.Get, "/api/admin/tickets/5/history");

        var saved = Assert.Single(host.Repository.Logs, log => log.Action == "UpdateTicketStatus");
        Assert.Equal("Status changed from Pending to Contested.", saved.Details);
        using var json = JsonDocument.Parse(await history.Content.ReadAsStringAsync());
        var newest = json.RootElement[0];
        Assert.Equal(2, json.RootElement.GetArrayLength());
        Assert.Equal("Status changed", newest.GetProperty("action").GetString());
        Assert.Equal("Status changed from Pending to Contested.", newest.GetProperty("details").GetString());
        Assert.Equal("Juan Dela Cruz", newest.GetProperty("performed_by").GetString());
    }

    [Theory]
    [InlineData(null, "5", HttpStatusCode.Unauthorized)]
    [InlineData("MarketEnforcer", "5", HttpStatusCode.Forbidden)]
    [InlineData("HeadAdmin", "99", HttpStatusCode.NotFound)]
    [InlineData("HeadAdmin", "0", HttpStatusCode.BadRequest)]
    public async Task History_reports_sign_in_role_missing_and_invalid_ticket_errors(
        string? role, string id, HttpStatusCode expected)
    {
        var fixture = new Fixture();
        await using var host = await fixture.CreateHostAsync();
        host.Repository.Logs.AddRange(SeededLogs());

        using var response = await host.SendAsync(HttpMethod.Get, $"/api/admin/tickets/{id}/history", role);

        Assert.Equal(expected, response.StatusCode);
    }

    [Fact]
    public async Task Ticket_without_recorded_actions_returns_an_empty_list()
    {
        var fixture = new Fixture();
        await using var host = await fixture.CreateHostAsync();

        using var response = await host.SendAsync(HttpMethod.Get, "/api/admin/tickets/5/history");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.Equal("[]", await response.Content.ReadAsStringAsync());
    }

    private static AuditLog Log(int id, string action, Module module, string? target, LogResult result,
        int? userId, Role? role, DateTime timestamp, string details) => new()
    {
        Id = id, Action = action, Module = module, TargetId = target, Result = result,
        UserId = userId, Role = role, Timestamp = timestamp, Details = details
    };

    private sealed class Fixture
    {
        private readonly Ticket _ticket = new()
        {
            Id = 5, ControlNumber = "VIO-0005", Description = "Violation", Type = ViolationType.Ticket,
            Status = TicketStatus.Pending, PenaltyType = PenaltyType.CashFine, Version = 7,
            UpdatedAt = DateTime.UnixEpoch
        };

        public Task<AuditHost> CreateHostAsync() => AuditHost.CreateAsync(services =>
            services.AddScoped<ITicketService>(provider =>
            {
                var audit = provider.GetRequiredService<AuditLogContext>();
                return new TicketService(TicketRepository(), null!, null!, UnitOfWork(audit), null!,
                    Proxy<INotificationService>((method, _) => method.Name is
                        nameof(INotificationService.SendPushNotificationAsync) or
                        nameof(INotificationService.SendPushNotificationToVendorAsync)
                        ? Task.FromResult(true) : Task.CompletedTask),
                    Proxy<IVendorComplianceScoreService>((_, _) => Task.FromResult(new VendorComplianceScoreResponse
                    {
                        Standing = "Good", ViolationFrequencyLevel = "Low", CategorySeverityLevel = "Low"
                    })),
                    audit, provider.GetRequiredService<IAuditLogService>());
            }));

        private ITicketRepository TicketRepository() => Proxy<ITicketRepository>((method, args) => method.Name switch
        {
            nameof(ITicketRepository.GetTicketByIdAsync) => Task.FromResult((int)args![0]! == 5 ? _ticket : null),
            nameof(ITicketRepository.SetOriginalVersion) => null,
            nameof(ITicketRepository.SaveChangesAsync) => Task.CompletedTask,
            _ => throw new InvalidOperationException("Unexpected repository method: " + method.Name)
        });

        // Like the real unit of work, a commit marks the staged audit entry as stored.
        private static IUnitOfWork UnitOfWork(AuditLogContext audit) => Proxy<IUnitOfWork>((method, _) =>
        {
            if (method.Name == nameof(IUnitOfWork.CommitAsync) && audit.Staged) audit.Stored = true;
            return Task.CompletedTask;
        });
    }

    private static T Proxy<T>(Func<MethodInfo, object?[]?, object?> handler) where T : class
    {
        var proxy = DispatchProxy.Create<T, HistoryProxy>();
        ((HistoryProxy)(object)proxy).Handler = handler;
        return proxy;
    }

    public class HistoryProxy : DispatchProxy
    {
        public Func<MethodInfo, object?[]?, object?> Handler { get; set; } = null!;
        protected override object? Invoke(MethodInfo? method, object?[]? args) => Handler(method!, args);
    }
}
