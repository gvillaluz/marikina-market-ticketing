using MarikinaMarket.API.Application.DTOs.Tickets.Response;
using System.Text.Json;
using System.Text.Json.Serialization;
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
    [Theory]
    [InlineData("BusinessAccountNumber")]
    [InlineData("BusinessName")]
    [InlineData("RegisteredOwnerName")]
    [InlineData("BusinessType")]
    [InlineData("StallNumber")]
    [InlineData("MarketSectionName")]
    [InlineData("BusinessAddress")]
    public async Task Registry_change_requires_review_without_upload_or_save(string field)
    {
        using var fixture = new Fixture();
        var request = fixture.Request(ViolationType.Ticket);
        typeof(BusinessSnapshotResponse).GetProperty(field)!.SetValue(fixture.Snapshot, field == "BusinessType" ? "Private" : "Changed synthetic value");
        await Assert.ThrowsAsync<ConcurrencyConflictException>(() => fixture.Service.CreateTicketAsync(request));
        Assert.Null(fixture.CreatedTicket);
        Assert.Equal(0, fixture.UploadCalls);
        Assert.True(fixture.RolledBack);
    }

    [Theory]
    [InlineData("{")]
    [InlineData("{}")]
    [InlineData("null")]
    public async Task Malformed_snapshot_review_is_rejected_without_upload(string review)
    {
        using var fixture = new Fixture();
        var request = fixture.Request(ViolationType.Ticket);
        request.ReviewedBusinessSnapshot = review;
        await Assert.ThrowsAsync<System.ComponentModel.DataAnnotations.ValidationException>(() => fixture.Service.CreateTicketAsync(request));
        Assert.Null(fixture.CreatedTicket);
        Assert.Equal(0, fixture.UploadCalls);
    }

    [Fact]
    public async Task Saved_snapshot_is_independent_of_later_registry_values()
    {
        using var fixture = new Fixture();
        var saved = await fixture.Service.CreateTicketAsync(fixture.Request(ViolationType.Ticket));
        fixture.Snapshot.BusinessName = "New synthetic business";
        fixture.Snapshot.RegisteredOwnerName = "New Owner";
        Assert.Equal("Reyes Fresh Fish", fixture.CreatedTicket!.SnapshotBusinessName);
        Assert.Equal("Juan Reyes", fixture.CreatedTicket.SnapshotRegisteredOwnerName);
        Assert.Equal("MM-17", fixture.CreatedTicket.SnapshotBusinessAccountNumber);
        Assert.Equal("F-014", fixture.CreatedTicket.SnapshotStallNumber);
        Assert.Equal("Fish and Seafood", fixture.CreatedTicket.SnapshotMarketSectionName);
        Assert.Equal("14 Market Street Santo Nino Marikina", fixture.CreatedTicket.SnapshotBusinessAddress);
        Assert.Equal("Public", fixture.CreatedTicket.SnapshotBusinessType);
        Assert.Equal("Reyes Fresh Fish", saved.BusinessSnapshot!.BusinessName);
    }

    [Fact]
    public async Task Snapshot_review_is_required_before_any_upload_or_save()
    {
        using var fixture = new Fixture();
        var request = fixture.Request(ViolationType.Ticket);
        request.ReviewedBusinessSnapshot = null;
        await Assert.ThrowsAsync<System.ComponentModel.DataAnnotations.ValidationException>(
            () => fixture.Service.CreateTicketAsync(request));
        Assert.Equal(0, fixture.UploadCalls);
        Assert.Null(fixture.CreatedTicket);
    }

    [Fact]
    public async Task Paper_metadata_is_required_before_any_upload_or_save()
    {
        using var fixture = new Fixture();
        var request = fixture.Request(ViolationType.Ticket);
        request.PaperReference = null;
        request.IssuePlace = null;
        await Assert.ThrowsAsync<System.ComponentModel.DataAnnotations.ValidationException>(
            () => fixture.Service.CreateTicketAsync(request));
        Assert.Equal(0, fixture.UploadCalls);
        Assert.Null(fixture.CreatedTicket);
    }

    [Fact]
    public async Task Paper_metadata_is_required_when_verifying_without_writing()
    {
        using var fixture = new Fixture();
        await Assert.ThrowsAsync<System.ComponentModel.DataAnnotations.ValidationException>(
            () => fixture.Service.VerifyInspectionAsync(new()
            {
                VendorId = 17, PersonId = 31, PaperViolatorName = "Juan Cruz",
                OrdinanceIds = [1], Description = "Market identification card not displayed",
                PenaltyType = PenaltyType.CashFine, EvidenceCount = 2, PaperTicketPhotoCount = 1, SupportingEvidenceCount = 1
            }));
        Assert.Null(fixture.CreatedTicket);
        Assert.Equal(0, fixture.UploadCalls);
    }

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
            PaperReference = "000456", IssuePlace = "Fish aisle near F-014",
            OrdinanceIds = [1], Description = "Market identification card not displayed",
            PenaltyType = PenaltyType.CashFine, EvidenceCount = 2, PaperTicketPhotoCount = 1, SupportingEvidenceCount = 1
        });
        Assert.Null(fixture.CreatedTicket);
        Assert.Equal(0, fixture.UploadCalls);
        Assert.Equal(500m, verified.Calculation.TotalPaymentAmount);
        Assert.Equal(1, Assert.Single(verified.Calculation.Breakdown).OffenseNumber);
        var request = fixture.Request(ViolationType.Ticket);
        request.ReviewedCalculation = verified.ReviewedCalculation;
        request.ReviewedBusinessSnapshot = verified.ReviewedBusinessSnapshot;
        var saved = await fixture.Service.CreateTicketAsync(request);
        Assert.Equal(31, saved.PersonId);
        Assert.Equal("Juan Dela Cruz", saved.PersonFullName);
        Assert.Equal("Juan Cruz", saved.PaperViolatorName);
        Assert.Equal(17, saved.VendorId);
        Assert.Equal("000456", saved.PaperReference);
        Assert.Equal("Fish aisle near F-014", saved.IssuePlace);
    }

    [Theory]
    [InlineData(null, "Fish aisle")]
    [InlineData("   ", "Fish aisle")]
    [InlineData("000456", null)]
    [InlineData("000456", "  ")]
    public async Task Missing_reviewed_field_is_rejected_before_upload(string? reference, string? place)
    {
        using var fixture = new Fixture();
        var request = fixture.Request(ViolationType.Ticket);
        request.PaperReference = reference;
        request.IssuePlace = place;
        await Assert.ThrowsAsync<System.ComponentModel.DataAnnotations.ValidationException>(() => fixture.Service.CreateTicketAsync(request));
        Assert.Null(fixture.CreatedTicket);
        Assert.Equal(0, fixture.UploadCalls);
    }

    [Fact]
    public async Task Overlong_metadata_is_rejected_and_trimmed_text_keeps_leading_zeros()
    {
        using var fixture = new Fixture();
        var request = fixture.Request(ViolationType.Ticket);
        request.PaperReference = new string('1', 201);
        await Assert.ThrowsAsync<System.ComponentModel.DataAnnotations.ValidationException>(() => fixture.Service.CreateTicketAsync(request));
        request.PaperReference = " 000456 ";
        request.IssuePlace = new string('x', 501);
        await Assert.ThrowsAsync<System.ComponentModel.DataAnnotations.ValidationException>(() => fixture.Service.CreateTicketAsync(request));
        Assert.Equal(0, fixture.UploadCalls);
        request.IssuePlace = " Fish aisle near F-014 ";
        var saved = await fixture.Service.CreateTicketAsync(request);
        Assert.Equal("000456", saved.PaperReference);
        Assert.Equal("Fish aisle near F-014", saved.IssuePlace);
        Assert.Equal("11", saved.ControlNumber);
    }

    [Fact]
    public async Task Existing_paper_reference_blocks_verify_and_save_without_upload()
    {
        using var fixture = new Fixture { ExistingPaperReference = true };
        await Assert.ThrowsAsync<ConcurrencyConflictException>(() => fixture.Service.VerifyInspectionAsync(new()
        {
            VendorId = 17, PersonId = 31, PaperViolatorName = "Juan Cruz",
            PaperReference = "000456", IssuePlace = "Fish aisle near F-014",
            OrdinanceIds = [1], Description = "Synthetic citation",
            PenaltyType = PenaltyType.CashFine, EvidenceCount = 2, PaperTicketPhotoCount = 1, SupportingEvidenceCount = 1
        }));
        await Assert.ThrowsAsync<ConcurrencyConflictException>(() => fixture.Service.CreateTicketAsync(fixture.Request(ViolationType.Ticket)));
        Assert.Null(fixture.CreatedTicket);
        Assert.Equal(0, fixture.UploadCalls);
    }

    [Theory]
    [InlineData("ix_tickets_paper_reference", true)]
    [InlineData("unrelated_constraint", false)]
    public async Task Only_the_paper_reference_constraint_is_converted_to_its_conflict(string constraint, bool controlled)
    {
        using var fixture = new Fixture { UniqueConstraint = constraint };
        var action = () => fixture.Service.CreateTicketAsync(fixture.Request(ViolationType.Ticket));
        if (controlled)
        {
            var error = await Assert.ThrowsAsync<ConcurrencyConflictException>(action);
            Assert.Contains("paper reference", error.Message);
        }
        else await Assert.ThrowsAsync<DbUpdateException>(action);
        Assert.True(fixture.RolledBack);
        Assert.False(fixture.Committed);
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
        request.PaperTicketPhoto = emptyFile
            ? [new FormFile(Stream.Null, 0, 0, "ticket_evidence_files", "stall.jpg")]
            : [];

        var error = await Assert.ThrowsAsync<InvalidRequestException>(() => fixture.Service.CreateTicketAsync(request));

        Assert.Contains(emptyFile ? "must not be empty" : "Exactly one paper ticket", error.Message);
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
        request.SupportingEvidenceFiles = [new FormFile(new MemoryStream(bytes), 0, oversized ? 5 * 1024 * 1024 + 1 : bytes.Length, "ticket_evidence_files", name)
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

    [Fact]
    public async Task Citation_requires_explicit_photo_categories_before_upload()
    {
        using var fixture = new Fixture();
        var request = fixture.Request(ViolationType.Ticket);
        request.TicketEvidenceFiles = [Photo("unclassified.jpg")];
        await Assert.ThrowsAsync<InvalidRequestException>(() => fixture.Service.CreateTicketAsync(request));
        Assert.Equal(0, fixture.UploadCalls);
        Assert.Null(fixture.CreatedTicket);
    }

    [Fact]
    public async Task Citation_persists_photo_roles_and_supporting_order()
    {
        using var fixture = new Fixture();
        var request = fixture.Request(ViolationType.Ticket);
        var paper = typeof(CreateTicketRequest).GetProperty("PaperTicketPhoto");
        var supporting = typeof(CreateTicketRequest).GetProperty("SupportingEvidenceFiles");
        Assert.NotNull(paper);
        Assert.NotNull(supporting);
        request.TicketEvidenceFiles = [];
        paper.SetValue(request, new List<IFormFile> { Photo("paper.jpg") });
        supporting.SetValue(request, new List<IFormFile> { Photo("stall.jpg"), Photo("aisle.jpg") });
        await fixture.Service.CreateTicketAsync(request);
        var saved = fixture.CreatedTicket!.TicketEvidences!.ToList();
        Assert.Equal(3, saved.Count);
        Assert.Equal(new[] { "PaperTicket", "Supporting", "Supporting" },
            saved.Select(e => e.GetType().GetProperty("Role")!.GetValue(e)!.ToString()));
        Assert.Equal(new[] { 0, 0, 1 }, saved.Select(e => (int)e.GetType().GetProperty("SortOrder")!.GetValue(e)!));
        Assert.Equal(1, fixture.UploadCalls);
        Assert.Equal(fixture.UploadedFiles["paper.jpg"], saved[0].FileKey);
        Assert.Equal(fixture.UploadedFiles["stall.jpg"], saved[1].FileKey);
        Assert.Equal(fixture.UploadedFiles["aisle.jpg"], saved[2].FileKey);
    }

    [Theory]
    [InlineData(0, 1)]
    [InlineData(2, 1)]
    [InlineData(1, 0)]
    public async Task Invalid_citation_categories_never_upload_or_save(int papers, int supporting)
    {
        using var fixture = new Fixture();
        var request = fixture.Request(ViolationType.Ticket);
        request.PaperTicketPhoto = Enumerable.Range(0, papers).Select(i => Photo($"paper{i}.jpg")).ToList();
        request.SupportingEvidenceFiles = Enumerable.Range(0, supporting).Select(i => Photo($"support{i}.jpg")).ToList();
        await Assert.ThrowsAsync<InvalidRequestException>(() => fixture.Service.CreateTicketAsync(request));
        Assert.Equal(0, fixture.UploadCalls);
        Assert.Null(fixture.CreatedTicket);
    }

    [Theory]
    [InlineData(0, 1, 1)]
    [InlineData(2, 1, 3)]
    [InlineData(1, 0, 1)]
    [InlineData(1, 1, 3)]
    public async Task Verify_rejects_invalid_category_counts_without_writing(int papers, int supporting, int total)
    {
        using var fixture = new Fixture();
        await Assert.ThrowsAsync<InvalidRequestException>(() => fixture.Service.VerifyInspectionAsync(new()
        {
            VendorId = 17, PersonId = 31, PaperViolatorName = "Juan Cruz", PaperReference = "000456",
            IssuePlace = "Fish aisle", OrdinanceIds = [1], Description = "Market ID not displayed",
            PenaltyType = PenaltyType.CashFine, EvidenceCount = total, PaperTicketPhotoCount = papers, SupportingEvidenceCount = supporting
        }));
        Assert.Equal(0, fixture.UploadCalls);
        Assert.Null(fixture.CreatedTicket);
    }

    [Fact]
    public async Task Upload_failure_rolls_back_citation_without_creating_evidence_rows()
    {
        using var fixture = new Fixture { FailUpload = true };
        await Assert.ThrowsAsync<IOException>(() => fixture.Service.CreateTicketAsync(fixture.Request(ViolationType.Ticket)));
        Assert.Null(fixture.CreatedTicket);
        Assert.True(fixture.RolledBack);
        Assert.False(fixture.Committed);
    }

    [Fact]
    public async Task Warning_saves_confirmed_person_place_and_exactly_one_paper_photo()
    {
        using var fixture = new Fixture();
        var request = fixture.Request(ViolationType.Warning);
        request.IssuePlace = "  Fish aisle near F-014  ";
        var before = DateTime.UtcNow;
        var response = await fixture.Service.CreateTicketAsync(request);
        var warning = fixture.CreatedTicket!;
        Assert.Equal(31, warning.PersonId);
        Assert.Equal("Fish aisle near F-014", warning.IssuePlace);
        Assert.InRange(warning.IssuedAt, before, DateTime.UtcNow);
        var paper = Assert.Single(warning.TicketEvidences!);
        Assert.Equal(TicketEvidenceRole.PaperTicket, paper.Role);
        Assert.Equal(0, paper.SortOrder);
        Assert.Equal(fixture.UploadedFiles["paper.jpg"], paper.FileKey);
        Assert.Equal(31, response.PersonId);
        Assert.Equal("Juan Dela Cruz", response.PersonFullName);
        Assert.Equal(warning.IssuePlace, response.IssuePlace);
        Assert.Null(warning.PenaltyType);
        Assert.Null(warning.TotalPaymentAmount);
        Assert.Null(warning.Status);
        Assert.Null(Assert.Single(warning.TicketViolations).PenaltyAmount);
        Assert.Equal("WRN-0011", response.ControlNumber);
    }

    [Theory]
    [InlineData("person")]
    [InlineData("place")]
    [InlineData("photo")]
    [InlineData("two-photos")]
    [InlineData("supporting")]
    [InlineData("legacy-evidence")]
    [InlineData("two-ordinances")]
    [InlineData("description")]
    public async Task Warning_rejects_invalid_required_fields_without_upload_or_record(string invalid)
    {
        using var fixture = new Fixture();
        var request = fixture.Request(ViolationType.Warning);
        switch (invalid)
        {
            case "person": request.PersonId = null; break;
            case "place": request.IssuePlace = " "; break;
            case "photo": request.PaperTicketPhoto = []; break;
            case "two-photos": request.PaperTicketPhoto.Add(Photo("second.jpg")); break;
            case "supporting": request.SupportingEvidenceFiles = [Photo("stall.jpg")]; break;
            case "legacy-evidence": request.TicketEvidenceFiles = [Photo("legacy.jpg")]; break;
            case "two-ordinances": request.Ordinances = [1, 2]; break;
            case "description": request.Description = new string('x', 1001); break;
        }
        var error = await Record.ExceptionAsync(() => fixture.Service.CreateTicketAsync(request));
        Assert.True(error is System.ComponentModel.DataAnnotations.ValidationException or InvalidRequestException,
            $"Expected validation error for {invalid}, got {error?.GetType().Name ?? "success"}.");
        Assert.Null(fixture.CreatedTicket);
        Assert.Equal(0, fixture.UploadCalls);
    }

    [Fact]
    public async Task Warning_rejects_nonminor_ordinance_without_upload_or_record()
    {
        using var fixture = new Fixture { HighSeverity = true };
        var error = await Record.ExceptionAsync(() => fixture.Service.CreateTicketAsync(fixture.Request(ViolationType.Warning)));
        Assert.True(error is System.ComponentModel.DataAnnotations.ValidationException or InvalidRequestException);
        Assert.Null(fixture.CreatedTicket);
        Assert.Equal(0, fixture.UploadCalls);
    }

    [Theory]
    [InlineData(false)]
    [InlineData(true)]
    public async Task Warning_denies_person_history_conflict_before_upload(bool citation)
    {
        using var fixture = new Fixture { PreviousWarning = !citation, PendingWarningCitation = citation };
        var request = fixture.Request(ViolationType.Warning);
        var error = await Record.ExceptionAsync(() => fixture.Service.CreateTicketAsync(request));
        if (citation) Assert.IsType<DuplicateOrdinanceException>(error);
        else Assert.IsType<DuplicateWarningException>(error);
        Assert.Equal(31, fixture.WarningLookupPersonId);
        Assert.Null(fixture.CreatedTicket);
        Assert.Equal(0, fixture.UploadCalls);
        Assert.True(fixture.RolledBack);
    }

    [Fact]
    public async Task Warning_serialization_failure_returns_conflict_and_rolls_back()
    {
        using var fixture = new Fixture { FailConcurrentSave = true };
        await Assert.ThrowsAsync<ConcurrencyConflictException>(() => fixture.Service.CreateTicketAsync(fixture.Request(ViolationType.Warning)));
        Assert.True(fixture.RolledBack);
        Assert.False(fixture.Committed);
    }

    [Fact]
    public async Task Warning_upload_failure_rolls_back_without_creating_record()
    {
        using var fixture = new Fixture { FailUpload = true };
        await Assert.ThrowsAsync<IOException>(() => fixture.Service.CreateTicketAsync(fixture.Request(ViolationType.Warning)));
        Assert.Null(fixture.CreatedTicket);
        Assert.True(fixture.RolledBack);
        Assert.False(fixture.Committed);
    }

    private static IFormFile Photo(string name) => new FormFile(new MemoryStream([0xff, 0xd8, 0xff, 0xd9]), 0, 4, "photo", name)
        { Headers = new HeaderDictionary(), ContentType = "image/jpeg" };

    private sealed class Fixture : AppDbContext
    {
        public List<Notification> NotificationsSaved { get; } = [];
        public TicketService Service { get; }
        public Ticket? CreatedTicket;
        public bool Committed, RolledBack, FailPush, FailNotificationSave, FailConcurrentSave;
        public bool HighSeverity;
        public bool PreviousWarning, PendingWarningCitation;
        public int? WarningLookupPersonId;
        public BusinessSnapshotResponse Snapshot { get; set; } = new()
        {
            BusinessAccountNumber = "MM-17", BusinessName = "Reyes Fresh Fish", RegisteredOwnerName = "Juan Reyes",
            BusinessType = "Public", StallNumber = "F-014", MarketSectionName = "Fish and Seafood",
            BusinessAddress = "14 Market Street Santo Nino Marikina"
        };
        public bool ExistingPaperReference;
        public string? UniqueConstraint;
        public int PushCalls;
        public int EmailCalls;
        public string EmailBody = "";
        public int UploadCalls;
        public bool FailUpload;
        public Dictionary<string, string> UploadedFiles = [];
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
                "GetWarningOrdinancesForPerson" => WarningLookup((int)args[0]!),
                "GetPersonPendingWarningConflictsAsync" => WarningCitationLookup((int)args[0]!),
                "GetNewControlNumber" => Task.FromResult(11),
                "PaperReferenceExistsAsync" => Task.FromResult(ExistingPaperReference),
                "AddTicketAsync" => AddTicket((Ticket)args[0]!),
                "GetTicketByIdAsync" => Task.FromResult(CreatedTicket),
                "GetNewlyOverdueTicketsAsync" => Task.FromResult(new List<Ticket> { CreatedTicket! }),
                "SetOriginalVersion" => null,
                "SaveChangesAsync" => SaveChangesAsync(),
                _ => throw new InvalidOperationException(method.Name)
            });
            var vendorLookup = ReviewBoundaryProxy.Create<IVendorRepository>((method, args) => Task.FromResult<VendorTicketSummary?>(new()
            {
                Id = 17, FirstName = Snapshot.RegisteredOwnerName![..Snapshot.RegisteredOwnerName.LastIndexOf(' ')],
                LastName = Snapshot.RegisteredOwnerName[(Snapshot.RegisteredOwnerName.LastIndexOf(' ') + 1)..],
                Email = VendorEmail, BusinessAccountNumber = Snapshot.BusinessAccountNumber!,
                BusinessName = Snapshot.BusinessName!, MarketSectionId = 1, MarketSectionName = Snapshot.MarketSectionName!,
                BusinessAddress = Snapshot.BusinessAddress ?? "", StallNumber = Snapshot.StallNumber,
                Type = Enum.Parse<BusinessType>(Snapshot.BusinessType!)
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
                var uploads = (Dictionary<IFormFile, string>)args[0]!;
                UploadedFiles = uploads.ToDictionary(pair => pair.Key.FileName, pair => pair.Value);
                return FailUpload ? Task.FromException<List<string>>(new IOException("Storage unavailable"))
                    : Task.FromResult(uploads.Values.Reverse().ToList());
            });
            Service = new TicketService(tickets, ordinances, vendorLookup, unit, storage, notifications, compliance,
                personRepository: new PersonRepository(this));
        }
        private Task<Ticket> AddTicket(Ticket ticket) { ticket.Id = 11; ticket.Version = 7; CreatedTicket = ticket; return Task.FromResult(ticket); }
        private Task<List<WarningOrdinance>> WarningLookup(int personId)
        {
            WarningLookupPersonId = personId;
            return Task.FromResult(PreviousWarning ? new List<WarningOrdinance> { new() { OrdinanceId = 1, OrdinanceNo = "011", OrdinanceCode = "MKT-001" } } : []);
        }
        private Task<List<DuplicateOrdinance>> WarningCitationLookup(int personId)
        {
            WarningLookupPersonId = personId;
            return Task.FromResult(PendingWarningCitation ? new List<DuplicateOrdinance> { new() { OrdinanceId = 1, OrdinanceNo = "011", OrdinanceCode = "MKT-001" } } : []);
        }
        public override Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
            => UniqueConstraint is not null
                ? Task.FromException<int>(new DbUpdateException("Synthetic collision", new Npgsql.PostgresException("Synthetic collision", "ERROR", "ERROR", "23505", constraintName: UniqueConstraint)))
                : FailConcurrentSave
                ? Task.FromException<int>(new DbUpdateException("Synthetic concurrent collision", new Npgsql.PostgresException("Synthetic collision", "ERROR", "ERROR", "40001")))
                : FailNotificationSave && NotificationsSaved.Count > 0
                ? Task.FromException<int>(new InvalidOperationException("Notification save failed")) : Task.FromResult(1);
        public CreateTicketRequest Request(ViolationType type) => new()
        {
            VendorId = 17, EnforcerId = 8, MarketSectionId = 1, Type = type,
            PersonId = 31,
            PaperViolatorName = type == ViolationType.Ticket ? "Juan Cruz" : null,
            PaperReference = type == ViolationType.Ticket ? "000456" : null,
            IssuePlace = "Fish aisle near F-014",
            ReviewedBusinessSnapshot = JsonSerializer.Serialize(Snapshot,
                new JsonSerializerOptions { PropertyNamingPolicy = JsonNamingPolicy.SnakeCaseLower }),
            ReviewedCalculation = "{\"total_payment_amount\":500,\"highest_severity\":\"Minor\",\"breakdown\":[{\"ordinance_id\":1,\"ordinance_no\":\"011\",\"ordinance_code\":\"MKT-001\",\"offense_number\":1,\"payment_amount\":500,\"severity\":\"Minor\"}]}",
            Description = "Market identification card not displayed", PenaltyType = PenaltyType.CashFine,
            Ordinances = [1], PaperTicketPhoto = [Photo("paper.jpg")],
            SupportingEvidenceFiles = type == ViolationType.Ticket ? [Photo("stall.jpg")] : []
        };
    }
}
