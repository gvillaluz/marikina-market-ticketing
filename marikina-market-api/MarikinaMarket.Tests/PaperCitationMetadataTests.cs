using System.ComponentModel.DataAnnotations;
using MarikinaMarket.API.Application.DTOs.Tickets.Request;
using MarikinaMarket.API.Domain.Entities;
using MarikinaMarket.API.Infrastructure.Persistence;
using MarikinaMarket.API.Infrastructure.Repositories;
using MarikinaMarket.API.Domain.Enums;
using Microsoft.EntityFrameworkCore;
using Xunit;

namespace MarikinaMarket.Tests;

public class PaperCitationMetadataTests
{
    [Fact]
    public void Legacy_rows_can_omit_metadata_but_new_reference_is_database_unique()
    {
        using var context = new AppDbContext(new DbContextOptionsBuilder<AppDbContext>()
            .UseNpgsql("Host=localhost;Database=unused;Username=unused").Options);
        var ticket = context.Model.FindEntityType(typeof(Ticket))!;
        var reference = ticket.FindProperty("PaperReference");
        var place = ticket.FindProperty("IssuePlace");
        Assert.NotNull(reference);
        Assert.NotNull(place);
        Assert.True(reference.IsNullable);
        Assert.True(place.IsNullable);
        Assert.Equal(200, reference.GetMaxLength());
        Assert.Equal(500, place.GetMaxLength());
        var index = Assert.Single(ticket.GetIndexes(), index => index.GetDatabaseName() == "ix_tickets_paper_reference");
        Assert.True(index.IsUnique);
        Assert.Equal("PaperReference", Assert.Single(index.Properties).Name);
        Assert.Equal("\"type\" = 'Ticket' AND paper_reference IS NOT NULL", index.GetFilter());
    }

    [Theory]
    [InlineData(typeof(CreateTicketRequest))]
    [InlineData(typeof(VerifyInspectionRequest))]
    public void Both_review_and_submit_contracts_bound_the_same_paper_fields(Type requestType)
    {
        foreach (var (name, limit) in new[] { ("PaperReference", 200), ("IssuePlace", 500) })
        {
            var property = requestType.GetProperty(name);
            Assert.NotNull(property);
            Assert.Equal(typeof(string), property.PropertyType);
            var length = Assert.Single(property.GetCustomAttributes(typeof(StringLengthAttribute), true));
            Assert.Equal(limit, ((StringLengthAttribute)length).MaximumLength);
        }
    }

    [Theory]
    [InlineData("000456", true)]
    [InlineData("456", false)]
    [InlineData("AbC-1", true)]
    [InlineData("abc-1", false)]
    [InlineData("WARN-1", false)]
    public async Task Paper_reference_lookup_is_global_exact_and_citation_only(string reference, bool exists)
    {
        using var context = new AppDbContext(new DbContextOptionsBuilder<AppDbContext>().Options);
        context.Tickets = new AccountDatabaseSet<Ticket>([
            new() { Id = 1, VendorId = 88, PersonId = 99, Description = "Synthetic", Type = ViolationType.Ticket,
                PaperReference = "000456", Status = TicketStatus.Paid, IssuedAt = DateTime.UtcNow.AddYears(-1) },
            new() { Id = 2, Description = "Synthetic", Type = ViolationType.Ticket, PaperReference = "AbC-1", Status = TicketStatus.Cleared },
            new() { Id = 3, Description = "Synthetic", Type = ViolationType.Warning, PaperReference = "WARN-1" },
            new() { Id = 4, Description = "Legacy", Type = ViolationType.Ticket }
        ]);
        Assert.Equal(exists, await new TicketRepository(context).PaperReferenceExistsAsync(reference));
    }
}
