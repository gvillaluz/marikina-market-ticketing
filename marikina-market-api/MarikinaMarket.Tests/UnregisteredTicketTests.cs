using MarikinaMarket.API.Application;
using MarikinaMarket.API.Application.DTOs.Tickets.Request;
using MarikinaMarket.API.Application.Services;
using MarikinaMarket.API.Domain.Entities;
using MarikinaMarket.API.Domain.Enums;
using MarikinaMarket.API.Infrastructure.Persistence;
using MarikinaMarket.API.Infrastructure.Repositories;
using Microsoft.EntityFrameworkCore;
using Xunit;
using DataValidation = System.ComponentModel.DataAnnotations;

namespace MarikinaMarket.Tests;

// Slice B1: tickets and warnings for an unregistered vendor (no business, a market section instead).
// All data is synthetic.
public class UnregisteredTicketTests
{
    // Section 3 is active, section 9 is switched off, any other number does not exist (see the fixture).
    private const int ActiveSection = 3;

    private static CreateTicketRequest Unregistered(InspectionNotificationTests.Fixture fixture, ViolationType type)
    {
        var request = fixture.Request(type);
        request.VendorId = null;
        request.MarketSectionId = ActiveSection;
        request.ReviewedBusinessSnapshot = null;
        return request;
    }

    [Theory]
    [InlineData(ViolationType.Ticket)]
    [InlineData(ViolationType.Warning)]
    public async Task Unregistered_citation_is_saved_with_a_section_and_no_business(ViolationType type)
    {
        using var fixture = new InspectionNotificationTests.Fixture();

        var saved = await fixture.Service.CreateTicketAsync(Unregistered(fixture, type));

        var ticket = fixture.CreatedTicket!;
        Assert.Null(ticket.VendorId);
        Assert.Equal(ActiveSection, ticket.MarketSectionId);
        Assert.Equal("Fish aisle near F-014", ticket.IssuePlace);
        Assert.Equal(31, ticket.PersonId);
        // No business details are kept on the ticket; only the section name is.
        Assert.Null(ticket.SnapshotBusinessName);
        Assert.Null(ticket.SnapshotBusinessAccountNumber);
        Assert.Null(ticket.SnapshotRegisteredOwnerName);
        if (type == ViolationType.Ticket) Assert.Equal("Meat and Poultry", ticket.SnapshotMarketSectionName);
        Assert.Null(saved.VendorId);
        Assert.Null(saved.BusinessName);
        Assert.Null(saved.RegisteredOwnerName);
        Assert.Equal(ActiveSection, saved.MarketSectionId);
        Assert.Equal("Meat and Poultry", saved.MarketSectionName);
    }

    [Fact]
    public async Task A_registered_ticket_ignores_the_section_sent_with_it()
    {
        using var fixture = new InspectionNotificationTests.Fixture();
        var request = fixture.Request(ViolationType.Ticket);
        request.MarketSectionId = ActiveSection;

        await fixture.Service.CreateTicketAsync(request);

        // The registered business still brings its own section (1 in the fixture), as before.
        Assert.Equal(17, fixture.CreatedTicket!.VendorId);
        Assert.Equal(1, fixture.CreatedTicket.MarketSectionId);
    }

    [Theory]
    [InlineData(null, typeof(DataValidation.ValidationException))]
    [InlineData(99, typeof(RecordNotFoundException))]
    [InlineData(9, typeof(DataValidation.ValidationException))]
    public async Task Without_a_business_a_valid_active_section_is_required_before_any_upload(int? section, Type expected)
    {
        using var fixture = new InspectionNotificationTests.Fixture();
        var request = Unregistered(fixture, ViolationType.Ticket);
        request.MarketSectionId = section;

        var error = await Assert.ThrowsAsync(expected, () => fixture.Service.CreateTicketAsync(request));

        // The message proves it is the section check, not some other rule that throws the same kind of error.
        Assert.Contains("market section", error.Message, StringComparison.OrdinalIgnoreCase);
        Assert.Null(fixture.CreatedTicket);
        Assert.Equal(0, fixture.UploadCalls);
    }

    [Theory]
    [InlineData(ViolationType.Ticket)]
    [InlineData(ViolationType.Warning)]
    public async Task Nothing_is_sent_to_a_business_owner_for_an_unregistered_citation(ViolationType type)
    {
        using var fixture = new InspectionNotificationTests.Fixture { VendorEmail = "owner@example.invalid" };

        await fixture.Service.CreateTicketAsync(Unregistered(fixture, type));

        Assert.Equal(0, fixture.PushCalls);
        Assert.Equal(0, fixture.EmailCalls);
        Assert.Empty(fixture.NotificationsSaved);
        Assert.Equal(0, fixture.ComplianceCalls);
    }

    [Fact]
    public async Task A_registered_ticket_still_notifies_the_owner_and_updates_the_score()
    {
        using var fixture = new InspectionNotificationTests.Fixture { VendorEmail = "owner@example.invalid" };

        await fixture.Service.CreateTicketAsync(fixture.Request(ViolationType.Ticket));

        // Vendor push never reaches the sender (vendor logins were removed), so it is not counted here.
        Assert.Equal(1, fixture.EmailCalls);
        Assert.Single(fixture.NotificationsSaved);
        Assert.Equal(1, fixture.ComplianceCalls);
    }

    private static VerifyInspectionRequest VerifyRequest(int? business, int? section) => new()
    {
        VendorId = business, MarketSectionId = section, PersonId = 31, PaperViolatorName = "Juan Cruz",
        PaperReference = "000456", IssuePlace = "Palengke gate 2", OrdinanceIds = [1],
        Description = "Market identification card not displayed", PenaltyType = PenaltyType.CashFine,
        EvidenceCount = 2, PaperTicketPhotoCount = 1, SupportingEvidenceCount = 1
    };

    [Fact]
    public async Task Verify_works_for_an_unregistered_vendor_and_the_result_can_be_submitted()
    {
        using var fixture = new InspectionNotificationTests.Fixture();

        var verified = await fixture.Service.VerifyInspectionAsync(VerifyRequest(null, ActiveSection));

        Assert.Null(fixture.CreatedTicket);
        Assert.Null(verified.BusinessSnapshot);
        Assert.Null(verified.ReviewedBusinessSnapshot);
        Assert.Equal(500m, verified.Calculation.TotalPaymentAmount);
        var request = Unregistered(fixture, ViolationType.Ticket);
        request.ReviewedCalculation = verified.ReviewedCalculation;
        var saved = await fixture.Service.CreateTicketAsync(request);
        Assert.Null(saved.VendorId);
    }

    [Theory]
    [InlineData(null, null, typeof(DataValidation.ValidationException))]
    [InlineData(null, 99, typeof(RecordNotFoundException))]
    [InlineData(null, 9, typeof(DataValidation.ValidationException))]
    public async Task Verify_needs_a_business_or_a_valid_active_section(int? business, int? section, Type expected)
    {
        using var fixture = new InspectionNotificationTests.Fixture();

        var error = await Assert.ThrowsAsync(expected, () => fixture.Service.VerifyInspectionAsync(VerifyRequest(business, section)));

        Assert.Contains("market section", error.Message, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public async Task Verify_still_catches_a_same_day_duplicate_for_an_unregistered_vendor()
    {
        using var fixture = new InspectionNotificationTests.Fixture { PersonHasDuplicate = true };

        await Assert.ThrowsAsync<DuplicateOrdinanceException>(
            () => fixture.Service.VerifyInspectionAsync(VerifyRequest(null, ActiveSection)));
    }

    [Fact]
    public async Task Warning_check_works_without_a_business()
    {
        using var fixture = new InspectionNotificationTests.Fixture();

        var warned = await fixture.Service.GetWarningOrdinancesForPersonAsync([1], null, 31);

        Assert.Empty(warned);
    }

    [Fact]
    public async Task Warning_check_still_requires_a_known_person()
    {
        using var fixture = new InspectionNotificationTests.Fixture();
        await Assert.ThrowsAsync<RecordNotFoundException>(() => fixture.Service.GetWarningOrdinancesForPersonAsync([1], null, 999));
    }

    [Fact]
    public async Task Status_change_on_an_unregistered_ticket_sends_nothing_to_an_owner()
    {
        using var fixture = new InspectionNotificationTests.Fixture { VendorEmail = "owner@example.invalid" };
        await fixture.Service.CreateTicketAsync(Unregistered(fixture, ViolationType.Ticket));

        var updated = await fixture.Service.UpdateTicketStatusAsync(11,
            new UpdateStatusRequest { NewStatus = TicketStatus.Contested, Version = 7 });

        Assert.Equal(TicketStatus.Contested, updated.Status);
        Assert.Equal(0, fixture.PushCalls);
        Assert.Equal(0, fixture.EmailCalls);
        Assert.Empty(fixture.NotificationsSaved);
        Assert.Equal(0, fixture.ComplianceCalls);
    }

    [Fact]
    public async Task The_overdue_job_marks_an_unregistered_ticket_overdue_without_owner_messages()
    {
        using var fixture = new InspectionNotificationTests.Fixture { VendorEmail = "owner@example.invalid" };
        await fixture.Service.CreateTicketAsync(Unregistered(fixture, ViolationType.Ticket));

        var count = await fixture.Service.CheckAndNotifyOverdueTicketsAsync();

        Assert.Equal(1, count);
        Assert.Equal(TicketStatus.Overdue, fixture.CreatedTicket!.Status);
        Assert.Equal(0, fixture.PushCalls);
        Assert.Equal(0, fixture.EmailCalls);
        Assert.Empty(fixture.NotificationsSaved);
        Assert.Equal(0, fixture.ComplianceCalls);
    }

    // ---- Reading an unregistered ticket back through every ticket list, detail and history query ----

    private static Ticket UnregisteredRow()
    {
        var now = DateTime.UtcNow;
        var ordinance = new Ordinance
        {
            Id = 1, OrdinanceNo = "011", Series = "2014", Section = "12", Title = "Market ID", IsActive = true
        };
        var ticket = new Ticket
        {
            Id = 11, VendorId = null, Vendor = null, PersonId = 31,
            Person = new Person { Id = 31, FullName = "Juan Dela Cruz", Address = "12 Market Lane" },
            PaperViolatorName = "Juan Cruz", PaperReference = "000456", ControlNumber = "5",
            IssuePlace = "Palengke gate 2", MarketSectionId = 3, SnapshotMarketSectionName = "Meat and Poultry",
            MarketSection = new MarketSection { Id = 3, Name = "Meat and Poultry", Description = "Synthetic" },
            EnforcerId = 8,
            Enforcer = new User
            {
                Id = 8, FirstName = "Ana", LastName = "Cruz", DateOfBirth = new DateOnly(1990, 1, 1),
                HouseNumber = "1", Street = "Synthetic St", Barangay = "Synthetic", City = "Marikina"
            },
            Type = ViolationType.Ticket, Status = TicketStatus.Pending, Description = "Synthetic",
            TotalPaymentAmount = 500m, HighestSeverity = Severity.Minor, PenaltyType = PenaltyType.CommunityService,
            CommunityServiceHours = 3, IssuedAt = now.AddDays(-1), UpdatedAt = now.AddDays(-1)
        };
        ticket.TicketViolations.Add(new TicketViolation
        {
            TicketId = 11, Ticket = ticket, OrdinanceId = 1, Ordinance = ordinance, OffenseCount = 1, PenaltyAmount = 500m
        });
        return ticket;
    }

    private static TicketRepository RepositoryWithUnregisteredTicket(out AppDbContext context)
    {
        context = new AppDbContext(new DbContextOptionsBuilder<AppDbContext>().Options);
        context.Tickets = new AccountDatabaseSet<Ticket>([UnregisteredRow()]);
        return new TicketRepository(context);
    }

    [Fact]
    public async Task Ticket_detail_and_person_history_show_the_section_and_place_with_no_business()
    {
        var repository = RepositoryWithUnregisteredTicket(out var context);
        using var _ = context;

        var detail = await repository.GetTicketDetailAsync(11);
        var (history, total) = await repository.GetPersonHistoryAsync(31, 0, 10);

        Assert.NotNull(detail);
        Assert.Null(detail.VendorId);
        Assert.Null(detail.BusinessName);
        Assert.Null(detail.RegisteredOwnerName);
        Assert.Equal("Meat and Poultry", detail.MarketSectionName);
        Assert.Equal("Palengke gate 2", detail.IssuePlace);
        Assert.Equal(1, total);
        Assert.Null(Assert.Single(history).BusinessName);
        Assert.Null(history[0].RegisteredOwnerName);
    }

    [Fact]
    public async Task Person_totals_count_the_unregistered_ticket_but_name_no_business()
    {
        var repository = RepositoryWithUnregisteredTicket(out var context);
        using var _ = context;

        var totals = (await repository.GetPersonTicketTotalsAsync([31]))[31];

        Assert.Equal(1, totals.OffenseCount);
        Assert.Equal(0m, totals.OutstandingFine); // community service, so no cash fine is owed
        Assert.Null(totals.LastBusinessName);
        Assert.Empty(totals.BusinessNames);
    }

    [Fact]
    public async Task Enforcer_lists_and_history_include_the_unregistered_ticket()
    {
        var repository = RepositoryWithUnregisteredTicket(out var context);
        using var _ = context;

        var inspections = await repository.GetInspectionsAsync(8, 0, 10, null, "");
        var tickets = await repository.GetTicketsAsync(8, 0, 10, null, "");
        var history = await repository.GetEnforcerInspectionHistory(8, 0, 10);

        Assert.Null(Assert.Single(inspections).VendorId);
        Assert.Null(Assert.Single(tickets).VendorId);
        Assert.Null(Assert.Single(history).VendorId);
        Assert.Equal("Meat and Poultry", inspections[0].MarketSectionName);
    }

    [Fact]
    public async Task The_enforcer_history_response_tells_a_registered_ticket_from_an_unregistered_one()
    {
        var registered = UnregisteredRow();
        registered.Id = 12;
        registered.VendorId = 17;
        using var context = new AppDbContext(new DbContextOptionsBuilder<AppDbContext>().Options);
        context.Tickets = new AccountDatabaseSet<Ticket>([UnregisteredRow(), registered]);

        var page = await new EnforcerService(null!, new TicketRepository(context), null!).GetInspectionHistoryAsync(8, 0);

        var unregisteredItem = page.Items.Single(item => item.TicketId == 11);
        Assert.Null(unregisteredItem.VendorId);
        Assert.Null(unregisteredItem.VendorFirstName);
        Assert.Null(unregisteredItem.VendorLastName);
        Assert.Equal("Meat and Poultry", unregisteredItem.MarketSectionName);
        Assert.Equal(17, page.Items.Single(item => item.TicketId == 12).VendorId);
    }

    [Theory]
    [InlineData("000456", 1)]  // the control number still finds it
    [InlineData("fish", 0)]    // a business name cannot match a ticket that has no business
    public async Task Enforcer_search_does_not_fail_on_an_unregistered_ticket(string search, int expected)
    {
        var repository = RepositoryWithUnregisteredTicket(out var context);
        using var _ = context;

        Assert.Equal(expected, (await repository.GetInspectionsAsync(8, 0, 10, null, search)).Count);
        Assert.Equal(expected, (await repository.GetTicketsAsync(8, 0, 10, null, search)).Count);
    }

    [Fact]
    public async Task Admin_lists_and_detail_include_the_unregistered_ticket()
    {
        var repository = RepositoryWithUnregisteredTicket(out var context);
        using var _ = context;

        var inspections = await repository.GetAdminInspectionAsync(0, 10, new InspectionSummaryFilters());
        var tickets = await repository.GetAdminTicketAsync(0, 10, new TicketSummaryFilters());
        var detail = await repository.GetAdminTicketDetailAsync(11);

        Assert.Null(Assert.Single(inspections).VendorId);
        Assert.Null(Assert.Single(tickets).VendorId);
        Assert.NotNull(detail);
        Assert.Null(detail.BusinessName);
        Assert.Equal("Palengke gate 2", detail.IssuePlace);
    }

    [Theory]
    [InlineData("000456", 1)]
    [InlineData("fish", 0)]
    public async Task Admin_search_does_not_fail_on_an_unregistered_ticket(string search, int expected)
    {
        var repository = RepositoryWithUnregisteredTicket(out var context);
        using var _ = context;

        Assert.Equal(expected, (await repository.GetAdminInspectionAsync(0, 10, new InspectionSummaryFilters { Search = search })).Count);
        Assert.Equal(expected, await repository.GetAdminInspectionCountAsync(new InspectionSummaryFilters { Search = search }));
        Assert.Equal(expected, (await repository.GetAdminTicketAsync(0, 10, new TicketSummaryFilters { Search = search })).Count);
    }

    [Fact]
    public async Task The_community_service_log_lists_the_unregistered_ticket_with_no_business_name()
    {
        var repository = RepositoryWithUnregisteredTicket(out var context);
        using var _ = context;

        var logs = await repository.GetCommunityServiceLogsAsync(0, 10, null);

        var log = Assert.Single(logs);
        Assert.Null(log.BusinessAccountNumber);
        Assert.Null(log.VendorName);
        Assert.Equal(3, log.TotalHours);
    }

    // ---- Vendor-side counts, activity feed and settlement list ----

    private static Ticket VendorSideTicket(int id, int? business, ViolationType type, TicketStatus status, int daysAgo) => new()
    {
        Id = id, VendorId = business, Type = type, Status = status, Description = "Synthetic", PaperReference = $"P-{id}",
        Vendor = business is null ? null : new Business
        {
            Id = business.Value, BusinessAccountNumber = $"MM-{business}", BusinessName = $"Synthetic business {business}",
            QrCodeValue = "sample", OwnerFirstName = "Juan", OwnerLastName = "Reyes"
        },
        MarketSectionId = 3, MarketSection = new MarketSection { Id = 3, Name = "Meat and Poultry", Description = "Synthetic" },
        IssuedAt = DateTime.UtcNow.AddDays(-daysAgo), UpdatedAt = DateTime.UtcNow.AddDays(-daysAgo)
    };

    private static VendorRepository VendorRepositoryWith(params Ticket[] tickets)
    {
        var context = new AppDbContext(new DbContextOptionsBuilder<AppDbContext>().Options);
        context.Tickets = new AccountDatabaseSet<Ticket>(tickets);
        return new VendorRepository(context);
    }

    [Fact]
    public async Task Weekly_vendor_counts_count_registered_businesses_only()
    {
        // Warnings this week: business 17 twice, plus an unregistered one. Tickets: business 18 once, plus an unregistered one.
        var repository = VendorRepositoryWith(
            VendorSideTicket(1, 17, ViolationType.Warning, TicketStatus.Pending, 1),
            VendorSideTicket(2, 17, ViolationType.Warning, TicketStatus.Pending, 2),
            VendorSideTicket(3, null, ViolationType.Warning, TicketStatus.Pending, 1),
            VendorSideTicket(4, 18, ViolationType.Ticket, TicketStatus.Pending, 1),
            VendorSideTicket(5, null, ViolationType.Ticket, TicketStatus.Pending, 1));
        var weekStart = DateTime.UtcNow.AddDays(-7);

        // One business had a warning and one had a ticket; the unregistered vendor is not a business.
        Assert.Equal(1, await repository.GetVendorWarningCountThisWeekAsync(weekStart));
        Assert.Equal(1, await repository.GetVendorTicketCountThisWeekAsync(weekStart));
    }

    [Fact]
    public async Task Recent_vendor_activity_lists_registered_businesses_only()
    {
        var repository = VendorRepositoryWith(
            VendorSideTicket(1, 17, ViolationType.Ticket, TicketStatus.Pending, 2),
            VendorSideTicket(2, null, ViolationType.Ticket, TicketStatus.Pending, 1));

        var activity = await repository.GetRecentVendorActivitiesAsync(10);

        Assert.Equal(1, Assert.Single(activity).TicketId);
    }

    [Fact]
    public async Task Pending_settlements_still_list_an_unregistered_ticket_with_no_business()
    {
        var repository = VendorRepositoryWith(
            VendorSideTicket(1, 17, ViolationType.Ticket, TicketStatus.Pending, 2),
            VendorSideTicket(2, null, ViolationType.Ticket, TicketStatus.Overdue, 1),
            VendorSideTicket(3, null, ViolationType.Ticket, TicketStatus.Paid, 1));

        var pending = await repository.GetPendingTicketSettlementsAsync(0, 10);

        // Newest first: the unregistered overdue ticket (1 day ago), then business 17's (2 days ago). The paid one is not pending.
        Assert.Equal([2, 1], pending.Select(p => p.TicketId));
        Assert.Null(pending[0].BusinessAccountNumber);
        Assert.Null(pending[0].VendorName);
        Assert.Equal("MM-17", pending[1].BusinessAccountNumber);
        Assert.Equal("Reyes, Juan", pending[1].VendorName);
        Assert.Equal(2, await repository.GetPendingTicketSettlementCountAsync());
    }
}
