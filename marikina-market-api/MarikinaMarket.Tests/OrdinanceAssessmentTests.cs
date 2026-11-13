using System.ComponentModel.DataAnnotations;
using System.Text.Json;
using MarikinaMarket.API.Domain.Enums;
using Xunit;

namespace MarikinaMarket.Tests;

public class OrdinanceAssessmentTests
{
    [Theory]
    [InlineData(100)]
    [InlineData(1000)]
    public async Task Up_to_inclusive_boundaries_are_saved_as_paper_assessed(decimal amount)
    {
        using var fixture = UpTo();
        var submit = fixture.Request(ViolationType.Ticket);
        submit.FineAssessments = Assessments(amount);
        await fixture.Service.CreateTicketAsync(submit);
        Assert.Equal(amount, fixture.CreatedTicket!.TotalPaymentAmount);
        Assert.Equal(amount, Assert.Single(fixture.CreatedTicket.TicketViolations).PenaltyAmount);
    }

    [Theory]
    [InlineData(99.99)]
    [InlineData(1000.01)]
    [InlineData(100.001)]
    public async Task Submit_rejects_outside_bounds_or_extra_precision_before_upload(decimal amount)
    {
        using var fixture = UpTo();
        var submit = fixture.Request(ViolationType.Ticket); submit.FineAssessments = Assessments(amount);
        var error = await Assert.ThrowsAsync<ValidationException>(() => fixture.Service.CreateTicketAsync(submit));
        Assert.Contains("100 to 1000", error.Message);
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
        var error = await Assert.ThrowsAsync<ValidationException>(() => fixture.Service.CreateTicketAsync(fixture.Request(ViolationType.Ticket)));
        Assert.Equal("Enter the paper-assessed amount for each up-to fine before submitting.", error.Message);
        Assert.Equal(0, fixture.UploadCalls);
    }

    [Theory]
    [InlineData(PenaltyType.BloodDonation)]
    [InlineData(PenaltyType.CommunityService)]
    public async Task High_scoring_classification_does_not_prevent_enabled_first_offense_alternative(PenaltyType penalty)
    {
        using var fixture = new InspectionNotificationTests.Fixture { HighSeverity = true };
        var submit = fixture.Request(ViolationType.Ticket); submit.PenaltyType = penalty; submit.CommunityServiceHours = 3;
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
        var provisional = await fixture.Service.GetPersonFineSummaryAsync([1, 2], 31);
        Assert.False(provisional.AllowBloodDonation); Assert.False(provisional.AllowCommunityService);
        var submit = fixture.Request(ViolationType.Ticket);
        submit.Ordinances = [1, 2]; submit.PenaltyType = penalty; submit.CommunityServiceHours = 3;
        await Assert.ThrowsAsync<ValidationException>(() => fixture.Service.CreateTicketAsync(submit));
        Assert.Equal(0, fixture.UploadCalls);
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
        await Assert.ThrowsAsync<ValidationException>(() => fixture.Service.CreateTicketAsync(fixture.Request(ViolationType.Ticket)));
        Assert.Equal(0, fixture.UploadCalls);
    }

    [Fact]
    public async Task Unconfirmed_terms_are_visible_and_cannot_be_assessed_as_zero()
    {
        using var fixture = new InspectionNotificationTests.Fixture { FineKind = FineKind.Unconfirmed, PenaltyTerms = "N/A; rule requires confirmation" };
        var result = await fixture.Service.GetPersonFineSummaryAsync([1], 31);
        Assert.Null(result.TotalPaymentAmount); Assert.Equal("N/A; rule requires confirmation", result.Breakdown[0].PenaltyTerms);
        await Assert.ThrowsAsync<ValidationException>(() => fixture.Service.CreateTicketAsync(fixture.Request(ViolationType.Ticket)));
        Assert.Equal(0, fixture.UploadCalls);
    }

    [Fact]
    public async Task Missing_scoring_classification_is_not_silently_minor()
    {
        using var fixture = new InspectionNotificationTests.Fixture { MissingSeverity = true };
        var result = await fixture.Service.GetPersonFineSummaryAsync([1], 31);
        Assert.Null(result.HighestSeverity); Assert.Null(result.TotalPaymentAmount);
        var error = await Assert.ThrowsAsync<ValidationException>(() => fixture.Service.CreateTicketAsync(fixture.Request(ViolationType.Ticket)));
        Assert.Contains("classification", error.Message);
        Assert.Equal(0, fixture.UploadCalls);
    }

    [Theory]
    [InlineData("fixed")]
    [InlineData("unselected")]
    [InlineData("duplicate")]
    [InlineData("null-amount")]
    public async Task Forged_assessment_selection_is_rejected(string kind)
    {
        using var fixture = kind == "fixed" ? new InspectionNotificationTests.Fixture() : UpTo();
        var submit = fixture.Request(ViolationType.Ticket);
        var assessments = new List<object> { new { ordinance_id = kind == "unselected" ? 2 : 1,
            assessed_amount = kind == "null-amount" ? (decimal?)null : 500m } };
        if (kind == "duplicate") assessments.Add(new { ordinance_id = 1, assessed_amount = (decimal?)600m });
        submit.FineAssessments = JsonSerializer.Serialize(assessments);
        await Assert.ThrowsAsync<ValidationException>(() => fixture.Service.CreateTicketAsync(submit));
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
}
