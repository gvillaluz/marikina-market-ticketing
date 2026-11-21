using System.ComponentModel.DataAnnotations;
using System.Net;
using System.Reflection;
using System.Text.Json;
using MarikinaMarket.API.Application;
using MarikinaMarket.API.Application.DTOs.Audits.Internal;
using MarikinaMarket.API.Application.DTOs.Ordinance.Internal;
using MarikinaMarket.API.Application.DTOs.Tickets.Request;
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

// Changing the penalty on an issued ticket (spec-change-penalty.md, slice 1).
// Fixture ticket: Pending cash fine issued by enforcer 7 for business 3, two first offenses:
// ordinance 11 (fixed ₱500) and ordinance 12 (enforcer's "up to" amount ₱1,000). Cash total = 500 + 1000 = 1500.
public class TicketPenaltyChangeTests
{
    private const string MarketCodeMessage = "This penalty is not allowed for this ticket under the market code.";
    private const string StatusMessage = "The penalty can only be changed while the ticket is Pending or Overdue.";
    private const string ProofMessage = "The penalty can't be changed after settlement proof or community service hours are recorded.";
    private const string OwnershipMessage = "You can only change the penalty on tickets you issued.";

    // 1–6: allowed choices follow the market code.

    [Fact]
    public async Task Options_for_two_first_offenses_that_allow_alternatives_offer_all_three()
    {
        var fixture = new Fixture();

        var options = await fixture.Service.GetPenaltyOptionsAsync(1, enforcerId: null);

        Assert.Equal(1, options.TicketId);
        Assert.Equal(PenaltyType.CashFine, options.CurrentPenaltyType);
        Assert.Equal([PenaltyType.CashFine, PenaltyType.CommunityService, PenaltyType.BloodDonation],
            options.AllowedPenaltyTypes);
        Assert.Equal(1500m, options.CashFineAmount);
        Assert.Null(options.CommunityServiceHours);
        Assert.Equal(7u, options.Version);
        Assert.Equal([11, 12], fixture.RequestedOrdinanceIds.Order());
    }

    [Fact]
    public async Task Options_for_a_second_offense_offer_only_cash()
    {
        var fixture = new Fixture();
        fixture.Ticket.TicketViolations.Single(v => v.OrdinanceId == 12).OffenseCount = 2;

        var options = await fixture.Service.GetPenaltyOptionsAsync(1, enforcerId: null);

        Assert.Equal([PenaltyType.CashFine], options.AllowedPenaltyTypes);
    }

    [Fact]
    public async Task Options_drop_community_service_when_one_ordinance_disallows_it()
    {
        var fixture = new Fixture();
        fixture.Tier(12, 1).AllowCommunityService = false;

        var options = await fixture.Service.GetPenaltyOptionsAsync(1, enforcerId: null);

        Assert.Equal([PenaltyType.CashFine, PenaltyType.BloodDonation], options.AllowedPenaltyTypes);
    }

    [Fact]
    public async Task Options_offer_only_cash_when_a_tier_is_unconfirmed()
    {
        var fixture = new Fixture();
        fixture.Tier(12, 1).FineKind = FineKind.Unconfirmed;

        var options = await fixture.Service.GetPenaltyOptionsAsync(1, enforcerId: null);

        Assert.Equal([PenaltyType.CashFine], options.AllowedPenaltyTypes);
    }

    [Fact]
    public async Task Options_offer_only_cash_when_an_ordinance_has_no_first_offense_tier()
    {
        var fixture = new Fixture();
        fixture.Tiers.Remove(fixture.Tier(12, 1));

        var options = await fixture.Service.GetPenaltyOptionsAsync(1, enforcerId: null);

        Assert.Equal([PenaltyType.CashFine], options.AllowedPenaltyTypes);
    }

    [Fact]
    public async Task Options_leave_out_cash_when_a_violation_has_no_saved_amount()
    {
        var fixture = new Fixture();
        fixture.Ticket.TicketViolations.Single(v => v.OrdinanceId == 12).PenaltyAmount = null;

        var options = await fixture.Service.GetPenaltyOptionsAsync(1, enforcerId: null);

        Assert.Equal([PenaltyType.CommunityService, PenaltyType.BloodDonation], options.AllowedPenaltyTypes);
        Assert.Null(options.CashFineAmount);
    }

    [Fact]
    public async Task Options_show_the_current_community_service_hours()
    {
        var fixture = new Fixture();
        fixture.MakeCommunityService(8);

        var options = await fixture.Service.GetPenaltyOptionsAsync(1, enforcerId: null);

        Assert.Equal(PenaltyType.CommunityService, options.CurrentPenaltyType);
        Assert.Equal(8, options.CommunityServiceHours);
        Assert.Equal(1500m, options.CashFineAmount);
    }

    // 7–9: what a successful change saves.

    [Fact]
    public async Task Cash_to_community_service_saves_hours_clears_total_refreshes_score_and_records_reason()
    {
        var fixture = new Fixture();

        var response = await fixture.ChangeAsync(PenaltyType.CommunityService, 10);

        Assert.Equal(1, response.TicketId);
        Assert.Equal(PenaltyType.CommunityService, response.PenaltyType);
        Assert.Equal(10, response.CommunityServiceHours);
        Assert.Null(response.TotalFineAmount);
        Assert.Equal(8u, response.Version);
        Assert.NotEqual(DateTime.UnixEpoch, response.UpdatedAt);
        Assert.Equal(PenaltyType.CommunityService, fixture.Ticket.PenaltyType);
        Assert.Equal(10, fixture.Ticket.CommunityServiceHours);
        Assert.Null(fixture.Ticket.TotalPaymentAmount);
        Assert.Equal(response.UpdatedAt, fixture.Ticket.UpdatedAt);
        Assert.Equal(TicketStatus.Pending, fixture.Ticket.Status);
        Assert.Equal([3], fixture.RefreshedVendorIds);
        Assert.Equal("Penalty changed from Cash fine to Community service (10 hours). Reason: Violator can't pay the cash fine.",
            fixture.Audit.Entry!.Details);
        // The score reads saved tickets, so it is refreshed after saving and before the commit.
        var save = fixture.Calls.IndexOf("SaveChangesAsync");
        var refresh = fixture.Calls.IndexOf("RefreshAsync");
        var commit = fixture.Calls.IndexOf("CommitAsync");
        Assert.True(save >= 0 && save < refresh && refresh < commit);
        Assert.DoesNotContain("RollbackAsync", fixture.Calls);
        Assert.Empty(fixture.NotificationCalls);
    }

    [Theory]
    [InlineData(null)]
    [InlineData((PenaltyChangeReason)99)]
    public async Task Change_without_a_known_reason_is_rejected_before_anything_is_saved(PenaltyChangeReason? reason)
    {
        var fixture = new Fixture();

        var error = await Assert.ThrowsAsync<ValidationException>(() =>
            fixture.ChangeAsync(PenaltyType.CommunityService, 10, reason: reason, useDefaultReason: false));

        Assert.Equal("Select a reason for the change.", error.Message);
        fixture.AssertUnchanged(expectedCalls: []);
    }

    [Theory]
    [InlineData(PenaltyChangeReason.CannotPayCashFine, "Violator can't pay the cash fine")]
    [InlineData(PenaltyChangeReason.RequestedDifferentPenalty, "Violator asked for a different penalty")]
    [InlineData(PenaltyChangeReason.WrongPenaltyAtIssue, "Wrong penalty chosen when issuing")]
    public async Task History_text_ends_with_the_reason_label(PenaltyChangeReason reason, string label)
    {
        var fixture = new Fixture();

        await fixture.ChangeAsync(PenaltyType.BloodDonation, null, reason);

        Assert.EndsWith($" Reason: {label}.", fixture.Audit.Entry!.Details);
    }

    [Fact]
    public async Task Community_service_back_to_cash_restores_the_total_and_clears_hours()
    {
        var fixture = new Fixture();
        fixture.MakeCommunityService(8);

        var response = await fixture.ChangeAsync(PenaltyType.CashFine, null, PenaltyChangeReason.WrongPenaltyAtIssue);

        Assert.Equal(PenaltyType.CashFine, response.PenaltyType);
        Assert.Null(response.CommunityServiceHours);
        Assert.Equal(1500m, response.TotalFineAmount);
        Assert.Equal(1500m, fixture.Ticket.TotalPaymentAmount);
        Assert.Null(fixture.Ticket.CommunityServiceHours);
        Assert.Equal("Penalty changed from Community service to Cash fine. Reason: Wrong penalty chosen when issuing.",
            fixture.Audit.Entry!.Details);
    }

    [Fact]
    public async Task Blood_donation_ignores_sent_hours_and_clears_total()
    {
        var fixture = new Fixture();

        var response = await fixture.ChangeAsync(PenaltyType.BloodDonation, 5, PenaltyChangeReason.RequestedDifferentPenalty);

        Assert.Equal(PenaltyType.BloodDonation, response.PenaltyType);
        Assert.Null(response.CommunityServiceHours);
        Assert.Null(response.TotalFineAmount);
        Assert.Null(fixture.Ticket.CommunityServiceHours);
        Assert.Null(fixture.Ticket.TotalPaymentAmount);
        Assert.Equal("Penalty changed from Cash fine to Blood donation. Reason: Violator asked for a different penalty.",
            fixture.Audit.Entry!.Details);
    }

    // 10–12: choices the market code or the form rules refuse.

    [Fact]
    public async Task Change_to_a_penalty_the_market_code_does_not_allow_is_rejected()
    {
        var fixture = new Fixture();
        fixture.Ticket.TicketViolations.Single(v => v.OrdinanceId == 12).OffenseCount = 2;

        var error = await Assert.ThrowsAsync<InvalidRequestException>(() =>
            fixture.ChangeAsync(PenaltyType.CommunityService, 10));

        Assert.Equal(MarketCodeMessage, error.Message);
        fixture.AssertRejectedInsideTransaction();
    }

    [Theory]
    [InlineData(null)]
    [InlineData(0)]
    [InlineData(2)]
    public async Task Community_service_needs_at_least_three_hours(int? hours)
    {
        var fixture = new Fixture();

        var error = await Assert.ThrowsAsync<InvalidRequestException>(() =>
            fixture.ChangeAsync(PenaltyType.CommunityService, hours));

        Assert.Equal("Community service requires a minimum of 3 hours.", error.Message);
        fixture.AssertRejectedInsideTransaction();
    }

    [Fact]
    public async Task Community_service_of_exactly_three_hours_is_accepted()
    {
        var fixture = new Fixture();

        var response = await fixture.ChangeAsync(PenaltyType.CommunityService, 3);

        Assert.Equal(3, response.CommunityServiceHours);
    }

    [Fact]
    public async Task Change_to_the_current_penalty_is_rejected()
    {
        var fixture = new Fixture();

        var error = await Assert.ThrowsAsync<InvalidRequestException>(() => fixture.ChangeAsync(PenaltyType.CashFine, null));

        Assert.Equal("The ticket already has this penalty.", error.Message);
        fixture.AssertRejectedInsideTransaction();
    }

    // 13–15: tickets whose penalty can no longer change. The options call refuses them the same way.

    [Theory]
    [InlineData(TicketStatus.Paid)]
    [InlineData(TicketStatus.Cleared)]
    [InlineData(TicketStatus.Waived)]
    [InlineData(TicketStatus.Contested)]
    [InlineData(TicketStatus.InProgress)]
    public async Task Only_pending_or_overdue_tickets_can_change(TicketStatus status)
    {
        var fixture = new Fixture();
        fixture.Ticket.Status = status;

        var options = await Assert.ThrowsAsync<InvalidRequestException>(() =>
            fixture.Service.GetPenaltyOptionsAsync(1, enforcerId: null));
        var change = await Assert.ThrowsAsync<InvalidRequestException>(() =>
            fixture.ChangeAsync(PenaltyType.CommunityService, 10));

        Assert.Equal(StatusMessage, options.Message);
        Assert.Equal(StatusMessage, change.Message);
        Assert.Equal(PenaltyType.CashFine, fixture.Ticket.PenaltyType);
        Assert.DoesNotContain("CommitAsync", fixture.Calls);
    }

    [Theory]
    [InlineData(TicketStatus.Pending)]
    [InlineData(TicketStatus.Overdue)]
    public async Task Pending_and_overdue_tickets_can_change(TicketStatus status)
    {
        var fixture = new Fixture();
        fixture.Ticket.Status = status;

        var response = await fixture.ChangeAsync(PenaltyType.CommunityService, 10);

        Assert.Equal(PenaltyType.CommunityService, response.PenaltyType);
        Assert.Equal(status, fixture.Ticket.Status);
    }

    [Theory]
    [InlineData("proof")]
    [InlineData("receipt")]
    [InlineData("service log")]
    public async Task Recorded_settlement_proof_or_service_hours_block_the_change(string recorded)
    {
        var fixture = new Fixture();
        if (recorded == "proof") fixture.Ticket.ProofUrls = ["", "receipt/proof.png"];
        if (recorded == "receipt") fixture.Ticket.ReceiptSubmissionId = Guid.NewGuid();
        if (recorded == "service log")
        {
            fixture.MakeCommunityService(8);
            fixture.Ticket.CommunityServiceLogs = [new CommunityServiceLog { HoursWorked = 2m, ProofUrl = "log.png" }];
        }

        var options = await Assert.ThrowsAsync<InvalidRequestException>(() =>
            fixture.Service.GetPenaltyOptionsAsync(1, enforcerId: null));
        var change = await Assert.ThrowsAsync<InvalidRequestException>(() =>
            fixture.ChangeAsync(PenaltyType.BloodDonation, null));

        Assert.Equal(ProofMessage, options.Message);
        Assert.Equal(ProofMessage, change.Message);
        Assert.DoesNotContain("CommitAsync", fixture.Calls);
    }

    [Fact]
    public async Task Blank_proof_entries_alone_do_not_block_the_change()
    {
        var fixture = new Fixture();
        fixture.Ticket.ProofUrls = ["", " "];

        var response = await fixture.ChangeAsync(PenaltyType.BloodDonation, null);

        Assert.Equal(PenaltyType.BloodDonation, response.PenaltyType);
    }

    [Fact]
    public async Task Warnings_have_no_penalty_to_change()
    {
        var fixture = new Fixture();
        fixture.Ticket.Type = ViolationType.Warning;
        fixture.Ticket.Status = null;

        var options = await Assert.ThrowsAsync<InvalidRequestException>(() =>
            fixture.Service.GetPenaltyOptionsAsync(1, enforcerId: null));
        var change = await Assert.ThrowsAsync<InvalidRequestException>(() =>
            fixture.ChangeAsync(PenaltyType.BloodDonation, null));

        Assert.Equal("Warnings have no penalty to change.", options.Message);
        Assert.Equal("Warnings have no penalty to change.", change.Message);
        Assert.DoesNotContain("CommitAsync", fixture.Calls);
    }

    // 16–18: who may change it, stale copies and bad ids.

    [Fact]
    public async Task Another_enforcer_cannot_see_options_or_change_the_penalty()
    {
        var fixture = new Fixture();

        var options = await Assert.ThrowsAsync<UnauthorizedAccessException>(() =>
            fixture.Service.GetPenaltyOptionsAsync(1, enforcerId: 9));
        var change = await Assert.ThrowsAsync<UnauthorizedAccessException>(() =>
            fixture.ChangeAsync(PenaltyType.CommunityService, 10, enforcerId: 9));

        Assert.Equal(OwnershipMessage, options.Message);
        Assert.Equal(OwnershipMessage, change.Message);
        fixture.AssertRejectedInsideTransaction();
    }

    [Theory]
    [InlineData(7)]
    [InlineData(null)]
    public async Task The_issuing_enforcer_and_admins_can_change_the_penalty(int? enforcerId)
    {
        var fixture = new Fixture();

        var options = await fixture.Service.GetPenaltyOptionsAsync(1, enforcerId);
        var response = await fixture.ChangeAsync(PenaltyType.CommunityService, 10, enforcerId: enforcerId);

        Assert.Equal(3, options.AllowedPenaltyTypes.Count);
        Assert.Equal(PenaltyType.CommunityService, response.PenaltyType);
    }

    [Fact]
    public async Task Stale_version_is_a_conflict_and_changes_nothing()
    {
        var fixture = new Fixture();

        var error = await Assert.ThrowsAsync<ConcurrencyConflictException>(() =>
            fixture.ChangeAsync(PenaltyType.CommunityService, 10, version: 6));

        Assert.Equal("This ticket was updated by another user. Please refresh and try again.", error.Message);
        fixture.AssertRejectedInsideTransaction();
    }

    [Fact]
    public async Task Missing_ticket_is_not_found()
    {
        var fixture = new Fixture();

        var options = await Assert.ThrowsAsync<RecordNotFoundException>(() =>
            fixture.Service.GetPenaltyOptionsAsync(99, enforcerId: null));
        var change = await Assert.ThrowsAsync<RecordNotFoundException>(() =>
            fixture.ChangeAsync(PenaltyType.CommunityService, 10, ticketId: 99));

        Assert.Equal("Ticket not found.", options.Message);
        Assert.Equal("Ticket not found.", change.Message);
    }

    [Fact]
    public async Task Ticket_id_zero_is_invalid()
    {
        var fixture = new Fixture();

        var options = await Assert.ThrowsAsync<InvalidRequestException>(() =>
            fixture.Service.GetPenaltyOptionsAsync(0, enforcerId: null));
        var change = await Assert.ThrowsAsync<InvalidRequestException>(() =>
            fixture.ChangeAsync(PenaltyType.CommunityService, 10, ticketId: 0));

        Assert.Equal("Ticket identification is invalid.", options.Message);
        Assert.Equal("Ticket identification is invalid.", change.Message);
        Assert.Empty(fixture.Calls);
    }

    // 19: the change shows in the ticket's history; failed attempts do not.

    [Fact]
    public async Task Repository_lists_successful_penalty_changes_in_the_ticket_history()
    {
        using var context = new AppDbContext(new DbContextOptionsBuilder<AppDbContext>().Options);
        context.AuditLogs = new AccountDatabaseSet<AuditLog>(
        [
            Log(1, "ChangePenalty", LogResult.Success, "Penalty changed from Cash fine to Blood donation. Reason: Wrong penalty chosen when issuing."),
            Log(2, "ChangePenalty", LogResult.Failed, "Ticket penalty change failed (HTTP 400).")
        ]);

        var logs = await new AuditLogRepository(context).GetTicketHistoryAsync(1);

        Assert.Equal([1], logs.Select(log => log.Id));
    }

    [Fact]
    public async Task Successful_change_appears_as_Penalty_changed_with_who_and_why()
    {
        var fixture = new Fixture();
        await using var host = await fixture.CreateHostAsync();

        // A stale copy is a business failure, so it is logged as Failed; it must stay out of the history.
        using var failed = await host.SendAsync(HttpMethod.Patch, "/api/admin/tickets/1/penalty", "HeadAdmin",
            "{\"penalty_type\":\"BloodDonation\",\"reason\":\"CannotPayCashFine\",\"version\":6}");
        using var changed = await host.SendAsync(HttpMethod.Patch, "/api/admin/tickets/1/penalty", "HeadAdmin",
            "{\"penalty_type\":\"CommunityService\",\"community_service_hours\":10,\"reason\":\"CannotPayCashFine\",\"version\":7}");
        using var history = await host.SendAsync(HttpMethod.Get, "/api/admin/tickets/1/history");

        Assert.Equal(HttpStatusCode.Conflict, failed.StatusCode);
        Assert.Equal(HttpStatusCode.OK, changed.StatusCode);
        Assert.Contains(host.Repository.Logs, log => log.Action == "ChangePenalty" && log.Result == LogResult.Failed);
        using var json = JsonDocument.Parse(await history.Content.ReadAsStringAsync());
        var entry = Assert.Single(json.RootElement.EnumerateArray());
        Assert.Equal("Penalty changed", entry.GetProperty("action").GetString());
        Assert.Equal("Penalty changed from Cash fine to Community service (10 hours). Reason: Violator can't pay the cash fine.",
            entry.GetProperty("details").GetString());
        Assert.Equal("Juan Dela Cruz", entry.GetProperty("performed_by").GetString());
    }

    // 20: the routes, their roles and the wire format.

    [Theory]
    [InlineData("GET", "/api/admin/tickets/1/penalty-options", "MarketEnforcer", HttpStatusCode.Forbidden)]
    [InlineData("PATCH", "/api/admin/tickets/1/penalty", "MarketEnforcer", HttpStatusCode.Forbidden)]
    [InlineData("GET", "/api/enforcer/tickets/1/penalty-options", "HeadAdmin", HttpStatusCode.Forbidden)]
    [InlineData("PATCH", "/api/enforcer/tickets/1/penalty", "AdminOfficer", HttpStatusCode.Forbidden)]
    [InlineData("GET", "/api/admin/tickets/1/penalty-options", null, HttpStatusCode.Unauthorized)]
    [InlineData("PATCH", "/api/admin/tickets/1/penalty", null, HttpStatusCode.Unauthorized)]
    [InlineData("GET", "/api/enforcer/tickets/1/penalty-options", null, HttpStatusCode.Unauthorized)]
    [InlineData("PATCH", "/api/enforcer/tickets/1/penalty", null, HttpStatusCode.Unauthorized)]
    public async Task Routes_refuse_the_wrong_role_and_signed_out_callers(string method, string route, string? role,
        HttpStatusCode expected)
    {
        var fixture = new Fixture();
        await using var host = await fixture.CreateHostAsync();

        using var response = await host.SendAsync(new HttpMethod(method), route, role, method == "PATCH" ? ValidBody : null);

        Assert.Equal(expected, response.StatusCode);
        Assert.Equal(PenaltyType.CashFine, fixture.Ticket.PenaltyType);
        Assert.Empty(fixture.Calls);
    }

    [Theory]
    [InlineData("/api/admin/tickets/1", "HeadAdmin")]
    [InlineData("/api/admin/tickets/1", "AdminOfficer")]
    [InlineData("/api/enforcer/tickets/1", "MarketEnforcer")]
    public async Task Routes_return_snake_case_options_and_change_results(string baseRoute, string role)
    {
        var fixture = new Fixture();
        await using var host = await fixture.CreateHostAsync();

        using var optionsResponse = await host.SendAsync(HttpMethod.Get, $"{baseRoute}/penalty-options", role);
        using var changeResponse = await host.SendAsync(HttpMethod.Patch, $"{baseRoute}/penalty", role, ValidBody);

        Assert.Equal(HttpStatusCode.OK, optionsResponse.StatusCode);
        using var options = JsonDocument.Parse(await optionsResponse.Content.ReadAsStringAsync());
        Assert.Equal(1, options.RootElement.GetProperty("ticket_id").GetInt32());
        Assert.Equal("CashFine", options.RootElement.GetProperty("current_penalty_type").GetString());
        Assert.Equal(["CashFine", "CommunityService", "BloodDonation"], options.RootElement
            .GetProperty("allowed_penalty_types").EnumerateArray().Select(item => item.GetString()));
        Assert.Equal(1500m, options.RootElement.GetProperty("cash_fine_amount").GetDecimal());
        Assert.Equal(JsonValueKind.Null, options.RootElement.GetProperty("community_service_hours").ValueKind);
        Assert.Equal(7, options.RootElement.GetProperty("version").GetInt32());

        Assert.Equal(HttpStatusCode.OK, changeResponse.StatusCode);
        using var change = JsonDocument.Parse(await changeResponse.Content.ReadAsStringAsync());
        Assert.Equal(1, change.RootElement.GetProperty("ticket_id").GetInt32());
        Assert.Equal("CommunityService", change.RootElement.GetProperty("penalty_type").GetString());
        Assert.Equal(10, change.RootElement.GetProperty("community_service_hours").GetInt32());
        Assert.Equal(JsonValueKind.Null, change.RootElement.GetProperty("total_fine_amount").ValueKind);
        Assert.True(change.RootElement.TryGetProperty("updated_at", out _));
        Assert.Equal(8, change.RootElement.GetProperty("version").GetInt32());
    }

    [Theory]
    [InlineData("{\"penalty_type\":\"CommunityService\",\"community_service_hours\":10,\"version\":7}", "Select a reason for the change.")]
    [InlineData("{\"community_service_hours\":10,\"reason\":\"CannotPayCashFine\",\"version\":7}", "Invalid penalty type value.")]
    public async Task Missing_reason_or_penalty_type_is_a_bad_request(string body, string message)
    {
        var fixture = new Fixture();
        await using var host = await fixture.CreateHostAsync();

        using var response = await host.SendAsync(HttpMethod.Patch, "/api/admin/tickets/1/penalty", "HeadAdmin", body);

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
        Assert.Contains(message, await response.Content.ReadAsStringAsync());
        Assert.Equal(PenaltyType.CashFine, fixture.Ticket.PenaltyType);
        Assert.Empty(fixture.Calls);
    }

    [Theory]
    [InlineData("\"reason\":\"SomethingElse\"")]
    [InlineData("\"penalty_type\":\"Jail\"")]
    public async Task Unknown_reason_or_penalty_type_text_is_a_bad_request(string field)
    {
        var fixture = new Fixture();
        await using var host = await fixture.CreateHostAsync();
        var body = field.StartsWith("\"reason\"")
            ? $"{{\"penalty_type\":\"BloodDonation\",{field},\"version\":7}}"
            : $"{{{field},\"reason\":\"CannotPayCashFine\",\"version\":7}}";

        using var response = await host.SendAsync(HttpMethod.Patch, "/api/admin/tickets/1/penalty", "HeadAdmin", body);

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
        Assert.Equal(PenaltyType.CashFine, fixture.Ticket.PenaltyType);
        Assert.Empty(fixture.Calls);
    }

    [Fact]
    public async Task Enforcer_route_returns_the_ownership_message_for_another_enforcers_ticket()
    {
        var fixture = new Fixture();
        fixture.Ticket.EnforcerId = 9;
        await using var host = await fixture.CreateHostAsync();

        using var options = await host.SendAsync(HttpMethod.Get, "/api/enforcer/tickets/1/penalty-options", "MarketEnforcer");
        using var change = await host.SendAsync(HttpMethod.Patch, "/api/enforcer/tickets/1/penalty", "MarketEnforcer", ValidBody);

        Assert.Equal(HttpStatusCode.Forbidden, options.StatusCode);
        Assert.Equal(HttpStatusCode.Forbidden, change.StatusCode);
        using var error = JsonDocument.Parse(await change.Content.ReadAsStringAsync());
        Assert.Equal(OwnershipMessage, error.RootElement.GetProperty("message").GetString());
        Assert.Equal(PenaltyType.CashFine, fixture.Ticket.PenaltyType);
    }

    private const string ValidBody =
        "{\"penalty_type\":\"CommunityService\",\"community_service_hours\":10,\"reason\":\"CannotPayCashFine\",\"version\":7}";

    private static AuditLog Log(int id, string action, LogResult result, string details) => new()
    {
        Id = id, Action = action, Module = Module.Tickets, TargetId = "1", Result = result, UserId = 7,
        Role = Role.HeadAdmin, Timestamp = new DateTime(2026, 11, 21, 3, 0, 0, DateTimeKind.Utc).AddMinutes(id),
        Details = details
    };

    private sealed class Fixture
    {
        public Ticket Ticket { get; }
        public List<PenaltyTierSummary> Tiers { get; }
        public List<string> Calls { get; } = [];
        public List<string> NotificationCalls { get; } = [];
        public List<int> RefreshedVendorIds { get; } = [];
        public List<int> RequestedOrdinanceIds { get; } = [];
        public AuditLogContext Audit { get; } = new()
        {
            Entry = new AuditLog { Action = "ChangePenalty", Details = "Ticket penalty change completed successfully." }
        };
        public TicketService Service { get; }

        public Fixture()
        {
            Ticket = new Ticket
            {
                Id = 1, ControlNumber = "VIO-0001", PaperReference = "MM-1001", VendorId = 3, EnforcerId = 7,
                Description = "Violation", Type = ViolationType.Ticket, Status = TicketStatus.Pending,
                PenaltyType = PenaltyType.CashFine, TotalPaymentAmount = 1500m, Version = 7,
                IssuedAt = new DateTime(2026, 11, 20, 1, 0, 0, DateTimeKind.Utc), UpdatedAt = DateTime.UnixEpoch,
                TicketViolations =
                [
                    new TicketViolation { Id = 1, TicketId = 1, OrdinanceId = 11, OffenseCount = 1, PenaltyAmount = 500m },
                    new TicketViolation { Id = 2, TicketId = 1, OrdinanceId = 12, OffenseCount = 1, PenaltyAmount = 1000m }
                ]
            };
            // Second-offense tiers allow alternatives too, so only the first-offense rule can remove them.
            Tiers =
            [
                new() { OrdinanceId = 11, OffenseNumber = 1, FineKind = FineKind.Fixed, PenaltyAmount = 500m,
                    AllowBloodDonation = true, AllowCommunityService = true },
                new() { OrdinanceId = 11, OffenseNumber = 2, FineKind = FineKind.Fixed, PenaltyAmount = 1000m,
                    AllowBloodDonation = true, AllowCommunityService = true },
                new() { OrdinanceId = 12, OffenseNumber = 1, FineKind = FineKind.UpTo, MaximumFine = 1000m,
                    AllowBloodDonation = true, AllowCommunityService = true },
                new() { OrdinanceId = 12, OffenseNumber = 2, FineKind = FineKind.UpTo, MaximumFine = 2000m,
                    AllowBloodDonation = true, AllowCommunityService = true }
            ];
            Service = CreateService(Audit, null);
        }

        public PenaltyTierSummary Tier(int ordinanceId, int offenseNumber)
            => Tiers.Single(tier => tier.OrdinanceId == ordinanceId && tier.OffenseNumber == offenseNumber);

        public void MakeCommunityService(int hours)
        {
            Ticket.PenaltyType = PenaltyType.CommunityService;
            Ticket.CommunityServiceHours = hours;
            Ticket.TotalPaymentAmount = null;
        }

        public Task<MarikinaMarket.API.Application.DTOs.Tickets.Response.ChangePenaltyResponse> ChangeAsync(
            PenaltyType penalty, int? hours, PenaltyChangeReason? reason = PenaltyChangeReason.CannotPayCashFine,
            int? enforcerId = null, uint version = 7, int ticketId = 1, bool useDefaultReason = true)
            => Service.ChangePenaltyAsync(ticketId, new ChangePenaltyRequest
            {
                PenaltyType = penalty, CommunityServiceHours = hours,
                Reason = useDefaultReason ? reason ?? PenaltyChangeReason.CannotPayCashFine : reason,
                Version = version
            }, enforcerId);

        // Rejected after the ticket was loaded: rolled back, nothing saved, ticket as it was.
        public void AssertRejectedInsideTransaction()
        {
            Assert.Contains("RollbackAsync", Calls);
            AssertUnchanged(expectedCalls: null);
        }

        public void AssertUnchanged(List<string>? expectedCalls)
        {
            if (expectedCalls is not null) Assert.Equal(expectedCalls, Calls);
            Assert.DoesNotContain("SetOriginalVersion", Calls);
            Assert.DoesNotContain("SaveChangesAsync", Calls);
            Assert.DoesNotContain("CommitAsync", Calls);
            Assert.Equal(PenaltyType.CashFine, Ticket.PenaltyType);
            Assert.Equal(1500m, Ticket.TotalPaymentAmount);
            Assert.Null(Ticket.CommunityServiceHours);
            Assert.Equal(DateTime.UnixEpoch, Ticket.UpdatedAt);
            Assert.Equal(7u, Ticket.Version);
            Assert.Equal("Ticket penalty change completed successfully.", Audit.Entry!.Details);
        }

        public Task<AuditHost> CreateHostAsync() => AuditHost.CreateAsync(services =>
            services.AddScoped<ITicketService>(provider =>
                CreateService(provider.GetRequiredService<AuditLogContext>(), provider.GetRequiredService<IAuditLogService>())));

        private TicketService CreateService(AuditLogContext audit, IAuditLogService? auditService)
        {
            var repository = Proxy<ITicketRepository>((method, args) =>
            {
                Calls.Add(method.Name);
                return method.Name switch
                {
                    nameof(ITicketRepository.GetTicketWithViolationsAsync) or nameof(ITicketRepository.GetTicketByIdAsync)
                        => Task.FromResult<Ticket?>((int)args![0]! == 1 ? Ticket : null),
                    nameof(ITicketRepository.SetOriginalVersion) => null,
                    nameof(ITicketRepository.SaveChangesAsync) => SaveAsync(),
                    _ => throw new InvalidOperationException("Unexpected repository method: " + method.Name)
                };
            });
            var ordinances = Proxy<IOrdinanceRepository>((method, args) =>
            {
                if (method.Name != nameof(IOrdinanceRepository.GetPenaltyTiersAsync))
                    throw new InvalidOperationException("Unexpected ordinance method: " + method.Name);
                var ids = (List<int>)args![0]!;
                RequestedOrdinanceIds.Clear();
                RequestedOrdinanceIds.AddRange(ids);
                return Task.FromResult(Tiers.Where(tier => ids.Contains(tier.OrdinanceId)).ToList());
            });
            // Like the real unit of work, a commit marks the staged audit entry as stored.
            var unitOfWork = Proxy<IUnitOfWork>((method, _) =>
            {
                Calls.Add(method.Name);
                if (method.Name == nameof(IUnitOfWork.CommitAsync) && audit.Staged) audit.Stored = true;
                return Task.CompletedTask;
            });
            var notification = Proxy<INotificationService>((method, _) =>
            {
                NotificationCalls.Add(method.Name);
                return method.Name is nameof(INotificationService.SendPushNotificationAsync)
                    or nameof(INotificationService.SendPushNotificationToVendorAsync) ? Task.FromResult(true) : Task.CompletedTask;
            });
            var compliance = Proxy<IVendorComplianceScoreService>((method, args) =>
            {
                Calls.Add(method.Name);
                RefreshedVendorIds.Add((int)args![0]!);
                return Task.FromResult(new VendorComplianceScoreResponse
                {
                    Standing = "Good", ViolationFrequencyLevel = "Low", CategorySeverityLevel = "Low"
                });
            });
            return new TicketService(repository, ordinances, null!, unitOfWork, null!, notification, compliance,
                audit, auditService);
        }

        private Task SaveAsync()
        {
            Ticket.Version = 8;
            return Task.CompletedTask;
        }
    }

    private static T Proxy<T>(Func<MethodInfo, object?[]?, object?> handler) where T : class
    {
        var proxy = DispatchProxy.Create<T, PenaltyChangeProxy>();
        ((PenaltyChangeProxy)(object)proxy).Handler = handler;
        return proxy;
    }

    public class PenaltyChangeProxy : DispatchProxy
    {
        public Func<MethodInfo, object?[]?, object?> Handler { get; set; } = null!;
        protected override object? Invoke(MethodInfo? method, object?[]? args) => Handler(method!, args);
    }
}
