using System.Security.Claims;
using MarikinaMarket.API.Application;
using MarikinaMarket.API.Application.DTOs.Ordinance.Internal;
using MarikinaMarket.API.Application.DTOs.Tickets.Internal;
using MarikinaMarket.API.Application.DTOs.Tickets.Request;
using MarikinaMarket.API.Application.DTOs.Vendor.Internal;
using MarikinaMarket.API.Application.DTOs.Vendor.Response;
using MarikinaMarket.API.Application.Interfaces.Repositories;
using MarikinaMarket.API.Application.Interfaces.Services;
using MarikinaMarket.API.Application.Services;
using MarikinaMarket.API.Domain.Entities;
using MarikinaMarket.API.Domain.Enums;
using MarikinaMarket.API.Infrastructure.Persistence;
using MarikinaMarket.API.Infrastructure.Repositories;
using MarikinaMarket.API.Presentation.Controllers;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Xunit;

namespace MarikinaMarket.Tests;

public class InspectionNotificationTests
{
    [Fact]
    public async Task Noncash_high_severity_is_rejected_before_evidence_upload()
    {
        using var fixture = new Fixture { HighSeverity = true };
        var request = fixture.Request(ViolationType.Ticket);
        request.PenaltyType = PenaltyType.CommunityService;
        request.CommunityServiceHours = 3;
        request.ReviewedCalculation = request.ReviewedCalculation!.Replace("Minor", "High");
        await Assert.ThrowsAsync<System.ComponentModel.DataAnnotations.ValidationException>(() => fixture.Service.CreateTicketAsync(request));
        Assert.Equal(0, fixture.UploadCalls);
        Assert.Null(fixture.CreatedTicket);
    }
    [Fact]
    public async Task Stale_review_requires_verification_before_upload_or_save()
    {
        using var fixture = new Fixture();
        var request = fixture.Request(ViolationType.Ticket);
        request.ReviewedCalculation = request.ReviewedCalculation!.Replace("\"offense_number\":1", "\"offense_number\":2");
        await Assert.ThrowsAsync<ConcurrencyConflictException>(() => fixture.Service.CreateTicketAsync(request));
        Assert.Null(fixture.CreatedTicket);
        Assert.Equal(0, fixture.UploadCalls);
    }

    [Fact]
    public async Task Concurrent_citation_collision_is_a_controlled_conflict()
    {
        using var fixture = new Fixture { FailConcurrentSave = true };
        await Assert.ThrowsAsync<ConcurrencyConflictException>(() => fixture.Service.CreateTicketAsync(fixture.Request(ViolationType.Ticket)));
        Assert.True(fixture.RolledBack);
        Assert.False(fixture.Committed);
    }
    [Fact]
    public async Task Verify_does_not_save_and_submission_preserves_paper_and_confirmed_identity()
    {
        using var fixture = new Fixture();
        var verified = await fixture.Service.VerifyInspectionAsync(new()
        {
            VendorId = 17, PersonId = 31, PaperViolatorName = "Juan Cruz",
            OrdinanceIds = [1], Description = "Market identification card not displayed",
            PenaltyType = PenaltyType.CashFine, EvidenceCount = 1
        });
        Assert.Null(fixture.CreatedTicket);
        Assert.Equal(0, fixture.UploadCalls);
        Assert.Equal(500m, verified.Calculation.TotalPaymentAmount);
        Assert.Equal(1, Assert.Single(verified.Calculation.Breakdown).OffenseNumber);
        var request = fixture.Request(ViolationType.Ticket);
        request.ReviewedCalculation = verified.ReviewedCalculation;
        var saved = await fixture.Service.CreateTicketAsync(request);
        Assert.Equal(31, saved.PersonId);
        Assert.Equal("Juan Dela Cruz", saved.PersonFullName);
        Assert.Equal("Juan Cruz", saved.PaperViolatorName);
        Assert.Equal(17, saved.VendorId);
    }

    [Fact]
    public async Task Malformed_review_is_rejected_before_upload_or_save()
    {
        using var fixture = new Fixture();
        var request = fixture.Request(ViolationType.Ticket);
        request.ReviewedCalculation = "{\"breakdown\":null}";
        await Assert.ThrowsAsync<System.ComponentModel.DataAnnotations.ValidationException>(
            () => fixture.Service.CreateTicketAsync(request));
        Assert.Null(fixture.CreatedTicket);
        Assert.Equal(0, fixture.UploadCalls);
    }
    [Theory]
    [InlineData(ViolationType.Warning)]
    [InlineData(ViolationType.Ticket)]
    public async Task Newly_created_inspection_returns_number_and_series_labels(ViolationType type)
    {
        using var fixture = new Fixture();
        var response = await fixture.Service.CreateTicketAsync(fixture.Request(type));
        Assert.Equal(new[] { "Ord No. 011, Series of 2014" }, response.OrdinanceNames);
    }

    [Theory]
    [InlineData(ViolationType.Warning, false)]
    [InlineData(ViolationType.Ticket, false)]
    [InlineData(ViolationType.Warning, true)]
    [InlineData(ViolationType.Ticket, true)]
    public async Task Inspection_keeps_staff_notification_without_pushing_to_a_business_account(ViolationType type, bool pushFails)
    {
        using var fixture = new Fixture { FailPush = pushFails };
        var response = await fixture.Service.CreateTicketAsync(fixture.Request(type));
        var record = Assert.Single(fixture.NotificationsSaved);
        Assert.Equal(response.Id, record.TicketId);
        Assert.Equal(8, record.EnforcerId);
        Assert.Equal(17, record.VendorId);
        Assert.False(record.IsRead);
        Assert.False(record.VendorIsRead);
        Assert.True(fixture.Committed);
        Assert.Equal(0, fixture.PushCalls);
        Assert.Null(fixture.PushData);
        if (type == ViolationType.Warning)
        {
            Assert.Null(fixture.CreatedTicket!.Status);
            Assert.Null(fixture.CreatedTicket.PenaltyType);
        }
        Assert.False(fixture.RolledBack);
    }

    [Theory]
    [InlineData(ViolationType.Warning)]
    [InlineData(ViolationType.Ticket)]
    public async Task Issuance_email_failure_after_commit_still_returns_the_saved_inspection(ViolationType type)
    {
        using var fixture = new Fixture { VendorEmail = "vendor@example.test", FailEmail = true };

        var response = await fixture.Service.CreateTicketAsync(fixture.Request(type));

        Assert.Equal(type == ViolationType.Warning ? "WRN-0011" : "11", response.ControlNumber);
        Assert.Equal(type, response.Type);
        Assert.True(fixture.Committed);
        Assert.False(fixture.RolledBack);
        Assert.Single(fixture.NotificationsSaved);
        Assert.Equal(0, fixture.PushCalls);
        Assert.Equal(1, fixture.EmailCalls);
    }

    [Theory]
    [InlineData(false)]
    [InlineData(true)]
    public async Task Ticket_requires_nonempty_photo_evidence_before_upload_or_save(bool emptyFile)
    {
        using var fixture = new Fixture();
        var request = fixture.Request(ViolationType.Ticket);
        request.TicketEvidenceFiles = emptyFile
            ? [new FormFile(Stream.Null, 0, 0, "ticket_evidence_files", "stall.jpg")]
            : [];

        var error = await Assert.ThrowsAsync<InvalidRequestException>(() => fixture.Service.CreateTicketAsync(request));

        Assert.Equal("Photo evidence is required for tickets.", error.Message);
        Assert.Null(fixture.CreatedTicket);
        Assert.Equal(0, fixture.UploadCalls);
        Assert.False(fixture.Committed);
    }

    [Theory]
    [InlineData(null)]
    [InlineData(0)]
    [InlineData(2)]
    public async Task Community_service_issuance_requires_at_least_three_hours(int? hours)
    {
        using var fixture = new Fixture();
        var request = fixture.Request(ViolationType.Ticket);
        request.PenaltyType = PenaltyType.CommunityService;
        request.CommunityServiceHours = hours;

        var error = await Assert.ThrowsAsync<InvalidRequestException>(() => fixture.Service.CreateTicketAsync(request));

        Assert.Equal("Community service requires a minimum of 3 hours.", error.Message);
        Assert.Null(fixture.CreatedTicket);
        Assert.Equal(0, fixture.UploadCalls);
        Assert.False(fixture.Committed);
    }

    [Fact]
    public async Task Ticket_email_uses_the_five_day_deadline_in_Manila()
    {
        using var fixture = new Fixture { VendorEmail = "vendor@example.test" };

        await fixture.Service.CreateTicketAsync(fixture.Request(ViolationType.Ticket));

        var dueDate = TimeZoneInfo.ConvertTimeBySystemTimeZoneId(fixture.CreatedTicket!.IssuedAt.AddDays(5), "Asia/Manila");
        Assert.Contains(dueDate.ToString("MMMM dd, yyyy"), fixture.EmailBody);
        Assert.Contains("within 5 days of the issue date", fixture.EmailBody);
        Assert.DoesNotContain("15 days", fixture.EmailBody);
    }

    [Theory]
    [InlineData("stall.png", "image/png", false, false)]
    [InlineData("stall.jpg", "application/octet-stream", false, false)]
    [InlineData("stall.jpg", "image/jpeg", true, false)]
    [InlineData("stall.jpg", "image/jpeg", false, true)]
    public async Task Ticket_rejects_invalid_photo_before_upload_or_save(string name, string contentType, bool invalidSignature, bool oversized)
    {
        using var fixture = new Fixture();
        var request = fixture.Request(ViolationType.Ticket);
        byte[] bytes = invalidSignature ? [0x25, 0x50, 0x44, 0x46] : [0xff, 0xd8, 0xff, 0xd9];
        request.TicketEvidenceFiles = [new FormFile(new MemoryStream(bytes), 0, oversized ? 5 * 1024 * 1024 + 1 : bytes.Length, "ticket_evidence_files", name)
            { Headers = new HeaderDictionary(), ContentType = contentType }];

        await Assert.ThrowsAsync<InvalidRequestException>(() => fixture.Service.CreateTicketAsync(request));

        Assert.Null(fixture.CreatedTicket);
        Assert.Equal(0, fixture.UploadCalls);
        Assert.False(fixture.Committed);
    }

    [Theory]
    [InlineData(ViolationType.Warning)]
    [InlineData(ViolationType.Ticket)]
    public async Task Notification_save_failure_rolls_back_inspection_without_push(ViolationType type)
    {
        using var fixture = new Fixture { FailNotificationSave = true };
        await Assert.ThrowsAsync<InvalidOperationException>(() => fixture.Service.CreateTicketAsync(fixture.Request(type)));
        Assert.True(fixture.RolledBack);
        Assert.False(fixture.Committed);
        Assert.Empty(fixture.NotificationsSaved);
        Assert.Equal(0, fixture.PushCalls);
    }

    [Fact]
    public async Task Inspection_uses_the_authenticated_enforcer_instead_of_the_submitted_id()
    {
        using var fixture = new Fixture();
        var controller = new EnforcerTicketController(fixture.Service)
        {
            ControllerContext = new ControllerContext
            {
                HttpContext = new DefaultHttpContext
                {
                    User = new ClaimsPrincipal(new ClaimsIdentity([new Claim(ClaimTypes.NameIdentifier, "8")], "test"))
                }
            }
        };
        var request = fixture.Request(ViolationType.Warning);
        request.EnforcerId = 999;
        await controller.SaveNewInspection(request);
        Assert.Equal(8, fixture.CreatedTicket!.EnforcerId);
    }

    [Theory]
    [InlineData(false, TicketStatus.Contested)]
    [InlineData(true, TicketStatus.Overdue)]
    public async Task Status_and_overdue_automation_keep_staff_notifications_without_business_login(
        bool overdue, TicketStatus status)
    {
        using var fixture = new Fixture();
        await fixture.Service.CreateTicketAsync(fixture.Request(ViolationType.Ticket));
        if (overdue)
        {
            fixture.CreatedTicket!.IssuedAt = DateTime.UtcNow.AddDays(-6);
            Assert.Equal(1, await fixture.Service.CheckAndNotifyOverdueTicketsAsync());
        }
        else
            await fixture.Service.UpdateTicketStatusAsync(11, new() { NewStatus = status, Version = 7 });
        Assert.Equal(2, fixture.NotificationsSaved.Count);
        Assert.All(fixture.NotificationsSaved, notification => Assert.Equal(17, notification.VendorId));
        Assert.Equal(status, fixture.NotificationsSaved.Last().Status);
        Assert.Equal(0, fixture.PushCalls);
        Assert.Null(fixture.PushData);
    }

    private sealed class Fixture : AppDbContext
    {
        public List<Notification> NotificationsSaved { get; } = [];
        public TicketService Service { get; }
        public Ticket? CreatedTicket;
        public bool Committed, RolledBack, FailPush, FailNotificationSave, FailConcurrentSave;
        public bool HighSeverity;
        public int PushCalls;
        public int EmailCalls;
        public string EmailBody = "";
        public int UploadCalls;
        public bool FailEmail;
        public string VendorEmail = "";
        public Dictionary<string, string>? PushData;

        public Fixture() : base(new DbContextOptionsBuilder<AppDbContext>()
            .UseNpgsql("Host=localhost;Database=unused;Username=unused").Options)
        {
            Notifications = new RegistrationDbSet<Notification>(NotificationsSaved);
            Businesses = new RegistrationDbSet<Business>(
                [new() { Id = 17, BusinessAccountNumber = "MM-17", BusinessName = "Reyes Fresh Fish", QrCodeValue = "sample" }]);
            Persons = new AccountDatabaseSet<Person>([new() { Id = 31, FullName = "Juan Dela Cruz", Address = "12 Market Lane" }]);
            var vendor = new VendorRepository(this);
            var users = ReviewBoundaryProxy.Create<IUserRepository>((method, args) =>
            {
                return Task.FromResult((int)args[0]! == 7 ? new List<string> { "sample-token" } : []);
            });
            var sender = ReviewBoundaryProxy.Create<IPushNotificationService>((method, args) =>
            {
                Assert.True(Committed);
                Assert.NotEmpty(NotificationsSaved);
                PushCalls++;
                PushData = (Dictionary<string, string>)args[3]!;
                return FailPush ? Task.FromException<bool>(new InvalidOperationException("Push unavailable")) : Task.FromResult(true);
            });
            var email = ReviewBoundaryProxy.Create<IEmailService>((method, args) =>
            {
                Assert.True(Committed);
                EmailCalls++;
                EmailBody = (string)args[2]!;
                return FailEmail ? Task.FromException(new InvalidOperationException("Email unavailable")) : Task.CompletedTask;
            });
            var notifications = new NotificationService(sender, email, users, new NotificationRepository(this), vendor);
            var tickets = ReviewBoundaryProxy.Create<ITicketRepository>((method, args) => method.Name switch
            {
                "GetDuplicatedTickets" => Task.FromResult(new List<DuplicateOrdinance>()),
                "GetPersonDuplicatesAsync" => Task.FromResult(new List<DuplicateOrdinance>()),
                "GetWarningOrdinancesForVendor" => Task.FromResult(new List<WarningOrdinance>()),
                "GetNewControlNumber" => Task.FromResult(11),
                "AddTicketAsync" => AddTicket((Ticket)args[0]!),
                "GetTicketByIdAsync" => Task.FromResult(CreatedTicket),
                "GetNewlyOverdueTicketsAsync" => Task.FromResult(new List<Ticket> { CreatedTicket! }),
                "SetOriginalVersion" => null,
                "SaveChangesAsync" => SaveChangesAsync(),
                _ => throw new InvalidOperationException(method.Name)
            });
            var vendorLookup = ReviewBoundaryProxy.Create<IVendorRepository>((method, args) => Task.FromResult<VendorTicketSummary?>(new()
            {
                Id = 17, FirstName = "Juan", LastName = "Reyes", Email = VendorEmail, BusinessAccountNumber = "MM-17",
                BusinessName = "Reyes Fresh Fish", MarketSectionId = 1, MarketSectionName = "Fish and Seafood"
            }));
            var ordinances = ReviewBoundaryProxy.Create<IOrdinanceRepository>((method, args) => Task.FromResult(new List<OrdinanceOffenseSummary>
            {
                new() { OrdinanceId = 1, OrdinanceNo = "011", Series = "2014", Code = "MKT-001", Title = "Market ID",
                    Category = ViolationCategory.Licensing, PenaltyTiers = [new() { OffenseNumber = 1, Severity = HighSeverity ? Severity.High : Severity.Minor, PenaltyAmount = 500m }] }
            }));
            var unit = ReviewBoundaryProxy.Create<IUnitOfWork>((method, args) =>
            {
                if (method.Name == "SaveChangesAsync") return SaveChangesAsync();
                if (method.Name == "BeginTransactionAsync") { Committed = false; return Task.CompletedTask; }
                if (method.Name == "CommitAsync") { Committed = true; return Task.CompletedTask; }
                if (method.Name == "RollbackAsync") { RolledBack = true; NotificationsSaved.Clear(); return Task.CompletedTask; }
                return Task.CompletedTask;
            });
            var compliance = ReviewBoundaryProxy.Create<IVendorComplianceScoreService>((method, args) => Task.FromResult(new VendorComplianceScoreResponse
            {
                Standing = "Good", ViolationFrequencyLevel = "Low", CategorySeverityLevel = "Low"
            }));
            var storage = ReviewBoundaryProxy.Create<IStorageService>((method, args) =>
            {
                if (method.Name != "UploadEvidencesAsync") throw new InvalidOperationException(method.Name);
                UploadCalls++;
                return Task.FromResult(((Dictionary<IFormFile, string>)args[0]!).Values.ToList());
            });
            Service = new TicketService(tickets, ordinances, vendorLookup, unit, storage, notifications, compliance,
                personRepository: new PersonRepository(this));
        }
        private Task<Ticket> AddTicket(Ticket ticket) { ticket.Id = 11; ticket.Version = 7; CreatedTicket = ticket; return Task.FromResult(ticket); }
        public override Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
            => FailConcurrentSave
                ? Task.FromException<int>(new DbUpdateException("Synthetic concurrent collision", new Npgsql.PostgresException("Synthetic collision", "ERROR", "ERROR", "40001")))
                : FailNotificationSave && NotificationsSaved.Count > 0
                ? Task.FromException<int>(new InvalidOperationException("Notification save failed")) : Task.FromResult(1);
        public CreateTicketRequest Request(ViolationType type) => new()
        {
            VendorId = 17, EnforcerId = 8, MarketSectionId = 1, Type = type,
            PersonId = type == ViolationType.Ticket ? 31 : null,
            PaperViolatorName = type == ViolationType.Ticket ? "Juan Cruz" : null,
            ReviewedCalculation = "{\"total_payment_amount\":500,\"highest_severity\":\"Minor\",\"breakdown\":[{\"ordinance_id\":1,\"ordinance_no\":\"011\",\"ordinance_code\":\"MKT-001\",\"offense_number\":1,\"payment_amount\":500,\"severity\":\"Minor\"}]}",
            Description = "Market identification card not displayed", PenaltyType = PenaltyType.CashFine,
            Ordinances = [1], TicketEvidenceFiles = type == ViolationType.Ticket
                ? [new FormFile(new MemoryStream([0xff, 0xd8, 0xff, 0xd9]), 0, 4, "ticket_evidence_files", "stall.jpg")
                    { Headers = new HeaderDictionary(), ContentType = "image/jpeg" }]
                : []
        };
    }
}
