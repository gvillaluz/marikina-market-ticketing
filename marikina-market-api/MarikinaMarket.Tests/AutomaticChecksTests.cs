using System.ComponentModel.DataAnnotations;
using MarikinaMarket.API.Application;
using MarikinaMarket.API.Domain.Enums;
using Xunit;

namespace MarikinaMarket.Tests;

// Automatic checks (criterion 3): what the server repeats when the enforcer presses Submit.
// The phone checks the same things first; the server never trusts it.
public class AutomaticChecksTests
{
    [Fact]
    public async Task Submitting_a_citation_repeats_the_same_day_duplicate_check()
    {
        using var fixture = new InspectionNotificationTests.Fixture { PersonHasDuplicate = true };

        await Assert.ThrowsAsync<DuplicateOrdinanceException>(
            () => fixture.Service.CreateTicketAsync(fixture.Request(ViolationType.Ticket)));

        Assert.Null(fixture.CreatedTicket);
        Assert.Equal(0, fixture.UploadCalls);
    }

    [Theory]
    [InlineData(null, "Juan Cruz")]
    [InlineData(0, "Juan Cruz")]
    [InlineData(31, null)]
    [InlineData(31, "   ")]
    public async Task A_citation_needs_a_confirmed_person_and_a_paper_name(int? personId, string? paperName)
    {
        using var fixture = new InspectionNotificationTests.Fixture();
        var request = fixture.Request(ViolationType.Ticket);
        request.PersonId = personId;
        request.PaperViolatorName = paperName;

        await Assert.ThrowsAsync<ValidationException>(() => fixture.Service.CreateTicketAsync(request));

        Assert.Null(fixture.CreatedTicket);
        Assert.Equal(0, fixture.UploadCalls);
    }

    [Fact]
    public async Task An_unknown_person_is_refused_and_nobody_is_created_for_the_typed_name()
    {
        using var fixture = new InspectionNotificationTests.Fixture();
        var request = fixture.Request(ViolationType.Ticket);
        request.PersonId = 999;
        request.PaperViolatorName = "A Name Nobody Has Registered";

        await Assert.ThrowsAsync<RecordNotFoundException>(() => fixture.Service.CreateTicketAsync(request));

        Assert.Null(fixture.CreatedTicket);
        Assert.Equal(0, fixture.UploadCalls);
        Assert.Single(fixture.Persons);
    }
}
