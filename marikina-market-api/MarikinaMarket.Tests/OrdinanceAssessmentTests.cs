using System.ComponentModel.DataAnnotations;
using System.Text.Json;
using MarikinaMarket.API.Application;
using MarikinaMarket.API.Application.DTOs.Tickets.Request;
using MarikinaMarket.API.Domain.Enums;
using Xunit;

namespace MarikinaMarket.Tests;

public class OrdinanceAssessmentTests
{
    [Theory]
    [InlineData(100)]
    [InlineData(1000)]
    public async Task Up_to_inclusive_boundaries_are_verified_and_saved_as_paper_assessed(decimal amount)
    {
        using var fixture = UpTo();
        var input = Verify(); input.FineAssessments = [new() { OrdinanceId = 1, AssessedAmount = amount }];
        var verified = await fixture.Service.VerifyInspectionAsync(input);
        Assert.Equal(amount, verified.Calculation.TotalPaymentAmount);
        Assert.Null(fixture.CreatedTicket);
        var submit = fixture.Request(ViolationType.Ticket);
        submit.FineAssessments = Assessments(amount);
        submit.ReviewedCalculation = verified.ReviewedCalculation;
        await fixture.Service.CreateTicketAsync(submit);
        Assert.Equal(amount, fixture.CreatedTicket!.TotalPaymentAmount);
        Assert.Equal(amount, Assert.Single(fixture.CreatedTicket.TicketViolations).PenaltyAmount);
    }

    [Theory]
    [InlineData(99.99)]
    [InlineData(1000.01)]
    [InlineData(100.001)]
    public async Task Both_verify_and_submit_reject_outside_bounds_or_extra_precision_before_upload(decimal amount)
    {
        using var fixture = UpTo();
        var input = Verify(); input.FineAssessments = [new() { OrdinanceId = 1, AssessedAmount = amount }];
        var error = await Assert.ThrowsAsync<ValidationException>(() => fixture.Service.VerifyInspectionAsync(input));
        Assert.Contains("100 to 1000", error.Message);
        var submit = fixture.Request(ViolationType.Ticket); submit.FineAssessments = Assessments(amount);
        await Assert.ThrowsAsync<ValidationException>(() => fixture.Service.CreateTicketAsync(submit));
        Assert.Null(fixture.CreatedTicket); Assert.Equal(0, fixture.UploadCalls);
    }

    [Fact]
    public async Task Provisional_up_to_summary_shows_bounds_and_no_invented_amount()
    {
        using var fixture = UpTo();
        var result = await fixture.Service.GetPersonFineSummaryAsync([1], 31);
        Assert.Null(result.TotalPaymentAmount);
        var item = Assert.Single(result.Breakdown);
        Assert.Null(item.PaymentAmount); Assert.Equal(100m, item.MinimumFine); Assert.Equal(1000m, item.MaximumFine);
        Assert.True(result.AllowBloodDonation);
        await Assert.ThrowsAsync<ValidationException>(() => fixture.Service.VerifyInspectionAsync(Verify()));
    }

    [Theory]
    [InlineData(PenaltyType.BloodDonation)]
    [InlineData(PenaltyType.CommunityService)]
    public async Task High_scoring_classification_does_not_prevent_enabled_first_offense_alternative(PenaltyType penalty)
    {
        using var fixture = new InspectionNotificationTests.Fixture { HighSeverity = true };
        var input = Verify(); input.PenaltyType = penalty; input.CommunityServiceHours = 3;
        var verified = await fixture.Service.VerifyInspectionAsync(input);
        Assert.Equal(Severity.High, verified.Calculation.HighestSeverity);
        var submit = fixture.Request(ViolationType.Ticket); submit.PenaltyType = penalty; submit.CommunityServiceHours = 3;
        submit.ReviewedCalculation = verified.ReviewedCalculation;
        await fixture.Service.CreateTicketAsync(submit);
        Assert.Equal(Severity.High, fixture.CreatedTicket!.HighestSeverity);
        Assert.Equal(penalty, fixture.CreatedTicket.PenaltyType);
        Assert.Null(fixture.CreatedTicket.TotalPaymentAmount);
        Assert.Equal(500m, Assert.Single(fixture.CreatedTicket.TicketViolations).PenaltyAmount);
    }

    [Theory]
    [InlineData(PenaltyType.BloodDonation)]
    [InlineData(PenaltyType.CommunityService)]
    public async Task Later_offense_cannot_use_alternatives_even_if_stored_tier_flags_are_true(PenaltyType penalty)
    {
        using var fixture = new InspectionNotificationTests.Fixture { OffenseCount = 1, TierOffense = 2 };
        var input = Verify(); input.PenaltyType = penalty; input.CommunityServiceHours = 3;
        await Assert.ThrowsAsync<ValidationException>(() => fixture.Service.VerifyInspectionAsync(input));
        var submit = fixture.Request(ViolationType.Ticket); submit.PenaltyType = penalty; submit.CommunityServiceHours = 3;
        await Assert.ThrowsAsync<ValidationException>(() => fixture.Service.CreateTicketAsync(submit));
        Assert.Equal(0, fixture.UploadCalls);
    }

    [Theory]
    [InlineData(PenaltyType.BloodDonation)]
    [InlineData(PenaltyType.CommunityService)]
    public async Task Every_selected_ordinance_must_allow_the_first_offense_alternative(PenaltyType penalty)
    {
        using var fixture = new InspectionNotificationTests.Fixture { AdditionalOrdinance = true };
        var input = Verify(); input.OrdinanceIds = [1, 2]; input.PenaltyType = penalty; input.CommunityServiceHours = 3;
        var provisional = await fixture.Service.GetPersonFineSummaryAsync([1, 2], 31);
        Assert.False(provisional.AllowBloodDonation); Assert.False(provisional.AllowCommunityService);
        await Assert.ThrowsAsync<ValidationException>(() => fixture.Service.VerifyInspectionAsync(input));
    }

    [Fact]
    public async Task Missing_later_tier_is_unconfirmed_instead_of_reusing_highest_fine()
    {
        using var fixture = new InspectionNotificationTests.Fixture { OffenseCount = 2 };
        var result = await fixture.Service.GetPersonFineSummaryAsync([1], 31);
        Assert.Null(result.TotalPaymentAmount);
        var item = Assert.Single(result.Breakdown);
        Assert.Equal(3, item.OffenseNumber); Assert.Equal(FineKind.Unconfirmed, item.FineKind);
        Assert.Contains("No confirmed", item.PenaltyTerms); Assert.Null(item.PaymentAmount);
        await Assert.ThrowsAsync<ValidationException>(() => fixture.Service.VerifyInspectionAsync(Verify()));
    }

    [Fact]
    public async Task Unconfirmed_terms_are_visible_and_cannot_be_assessed_as_zero()
    {
        using var fixture = new InspectionNotificationTests.Fixture { FineKind = FineKind.Unconfirmed, PenaltyTerms = "N/A; rule requires confirmation" };
        var result = await fixture.Service.GetPersonFineSummaryAsync([1], 31);
        Assert.Null(result.TotalPaymentAmount); Assert.Equal("N/A; rule requires confirmation", result.Breakdown[0].PenaltyTerms);
        await Assert.ThrowsAsync<ValidationException>(() => fixture.Service.VerifyInspectionAsync(Verify()));
    }

    [Fact]
    public async Task Missing_scoring_classification_is_not_silently_minor()
    {
        using var fixture = new InspectionNotificationTests.Fixture { MissingSeverity = true };
        var result = await fixture.Service.GetPersonFineSummaryAsync([1], 31);
        Assert.Null(result.HighestSeverity); Assert.Null(result.TotalPaymentAmount);
        var error = await Assert.ThrowsAsync<ValidationException>(() => fixture.Service.VerifyInspectionAsync(Verify()));
        Assert.Contains("classification", error.Message);
    }

    [Theory]
    [InlineData("maximum")]
    [InlineData("terms")]
    [InlineData("eligibility")]
    [InlineData("severity")]
    public async Task Changed_configuration_after_verify_requires_review_before_upload(string change)
    {
        using var fixture = UpTo();
        var input = Verify(); input.FineAssessments = [new() { OrdinanceId = 1, AssessedAmount = 500m }];
        var verified = await fixture.Service.VerifyInspectionAsync(input);
        switch (change)
        {
            case "maximum": fixture.MaximumFine = 1100m; break;
            case "terms": fixture.PenaltyTerms = "Updated condition"; break;
            case "eligibility": fixture.AllowBloodDonation = false; break;
            case "severity": fixture.HighSeverity = true; break;
        }
        var submit = fixture.Request(ViolationType.Ticket); submit.FineAssessments = Assessments(500m);
        submit.ReviewedCalculation = verified.ReviewedCalculation;
        await Assert.ThrowsAsync<ConcurrencyConflictException>(() => fixture.Service.CreateTicketAsync(submit));
        Assert.Null(fixture.CreatedTicket); Assert.Equal(0, fixture.UploadCalls);
    }

    [Theory]
    [InlineData("fixed")]
    [InlineData("unselected")]
    [InlineData("duplicate")]
    [InlineData("null-amount")]
    public async Task Forged_assessment_selection_is_rejected(string kind)
    {
        using var fixture = kind == "fixed" ? new InspectionNotificationTests.Fixture() : UpTo();
        var input = Verify(); input.FineAssessments = [new() { OrdinanceId = kind == "unselected" ? 2 : 1,
            AssessedAmount = kind == "null-amount" ? null : 500m }];
        if (kind == "duplicate") input.FineAssessments.Add(new() { OrdinanceId = 1, AssessedAmount = 600m });
        await Assert.ThrowsAsync<ValidationException>(() => fixture.Service.VerifyInspectionAsync(input));
        Assert.Equal(0, fixture.UploadCalls);
    }

    [Fact]
    public async Task High_ordinance_can_issue_warning_when_independently_enabled()
    {
        using var fixture = new InspectionNotificationTests.Fixture { HighSeverity = true, WarningEligible = true, FineKind = FineKind.Unconfirmed };
        await fixture.Service.CreateTicketAsync(fixture.Request(ViolationType.Warning));
        Assert.Equal(ViolationType.Warning, fixture.CreatedTicket!.Type);
        Assert.Null(fixture.CreatedTicket.HighestSeverity); Assert.Null(fixture.CreatedTicket.TotalPaymentAmount);
    }

    private static InspectionNotificationTests.Fixture UpTo() => new() { FineKind = FineKind.UpTo, MaximumFine = 1000m, PenaltyTerms = "Up to PHP 1,000" };
    private static string Assessments(decimal amount) => JsonSerializer.Serialize(new[] { new { ordinance_id = 1, assessed_amount = amount } });
    private static VerifyInspectionRequest Verify() => new()
    {
        VendorId = 17, PersonId = 31, PaperViolatorName = "Juan Cruz", PaperReference = "000456", IssuePlace = "Fish aisle near F-014",
        OrdinanceIds = [1], Description = "Reviewed paper citation", PenaltyType = PenaltyType.CashFine,
        EvidenceCount = 2, PaperTicketPhotoCount = 1, SupportingEvidenceCount = 1
    };
}
