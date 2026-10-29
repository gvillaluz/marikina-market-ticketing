using System.Text.Json;
using MarikinaMarket.API.Application.Services;
using MarikinaMarket.API.Domain.Entities;
using MarikinaMarket.API.Domain.Enums;
using MarikinaMarket.API.Infrastructure.Persistence;
using MarikinaMarket.API.Infrastructure.Repositories;
using Microsoft.EntityFrameworkCore;
using Xunit;

namespace MarikinaMarket.Tests;

public class EnforcerSummaryTests
{
    [Theory]
    [InlineData(ViolationType.Warning)]
    [InlineData(ViolationType.Ticket)]
    public async Task Inspection_list_formats_ordinance_number_and_series(ViolationType type)
    {
        using var context = Context();
        var service = new TicketService(new TicketRepository(context), null!, null!, null!, null!, null!, null!);

        var response = await service.GetInspectionsByEnforcerIdAsync(8, 0, type, "");

        Assert.NotEmpty(response.Items);
        Assert.All(response.Items, item =>
        {
            Assert.Equal(8, item.EnforcerId);
            Assert.Equal(new[] { "Ord No. 011, Series of 2014", "Ord No. 145, Series of 2006" }, item.OrdinanceNames);
        });
    }

    [Fact]
    public async Task Ticket_list_includes_formatted_ordinances_and_preserves_null_private_stall()
    {
        using var context = Context();
        var service = new TicketService(new TicketRepository(context), null!, null!, null!, null!, null!, null!);

        var response = await service.GetTicketsByEnforcerIdAsync(8, 0, TicketStatus.Pending, "");

        Assert.Equal(2, response.Items.Count);
        Assert.All(response.Items, item => Assert.Equal(8, item.EnforcerId));
        var privateVendor = Assert.Single(response.Items, item => item.BusinessType == BusinessType.Private);
        Assert.Null(privateVendor.StallNumber);
        using var json = JsonDocument.Parse(JsonSerializer.Serialize(response.Items,
            new JsonSerializerOptions { PropertyNamingPolicy = JsonNamingPolicy.SnakeCaseLower }));
        foreach (var item in json.RootElement.EnumerateArray())
            Assert.Equal(new[] { "Ord No. 011, Series of 2014", "Ord No. 145, Series of 2006" },
                item.GetProperty("ordinance_names").EnumerateArray().Select(value => value.GetString()));
    }

    [Fact]
    public async Task Ordinance_lookup_preserves_series_for_new_inspection_summaries()
    {
        using var context = Context();
        var ordinances = await new OrdinanceRepository(context).GetByIdsAsync([11], 17);
        var json = JsonSerializer.SerializeToElement(Assert.Single(ordinances));
        Assert.Equal("2014", json.GetProperty("Series").GetString());
    }

    private static AppDbContext Context()
    {
        var user = new User { FirstName = "Juan", LastName = "Santos", DateOfBirth = new DateOnly(1990, 1, 1),
            HouseNumber = "1", Street = "Test Street", Barangay = "Test Barangay", City = "Marikina" };
        var ordinances = new[] {
            new Ordinance { Id = 11, OrdinanceNo = "011", Series = "2014", MarketCode = "SEC-8", Title = "Market walkway", Category = ViolationCategory.Obstruction },
            new Ordinance { Id = 145, OrdinanceNo = "145", Series = "2006", MarketCode = "SEC-9", Title = "Market access", Category = ViolationCategory.Obstruction }
        };
        Ticket Record(int id, ViolationType type, BusinessType businessType, int enforcerId = 8) => new()
        {
            Id = id, ControlNumber = id.ToString(), EnforcerId = enforcerId, VendorId = 17,
            Type = type, Status = type == ViolationType.Ticket ? TicketStatus.Pending : null,
            Description = "Blocked market walkway", IssuedAt = new DateTime(2026, 10, 21, 2, 0, 0, DateTimeKind.Utc),
            Vendor = new Business { Id = 17, BusinessAccountNumber = "BUS-17", BusinessName = "Market Goods",
                Type = businessType, StallNumber = businessType == BusinessType.Public ? "A-12" : null, QrCodeValue = "synthetic-17", OwnerFirstName = user.FirstName, OwnerLastName = user.LastName, Email = user.Email },
            MarketSection = new MarketSection { Name = "Dry Goods", Description = "Dry goods section" },
            TicketViolations = ordinances.Select((ordinance, index) => new TicketViolation { Id = index + 1, OrdinanceId = ordinance.Id, Ordinance = ordinance }).ToList()
        };
        var context = new AppDbContext(new DbContextOptionsBuilder<AppDbContext>().Options);
        context.Tickets = new AccountDatabaseSet<Ticket>([
            Record(42, ViolationType.Ticket, BusinessType.Public), Record(43, ViolationType.Ticket, BusinessType.Private),
            Record(44, ViolationType.Warning, BusinessType.Public), Record(45, ViolationType.Ticket, BusinessType.Public, 9)]);
        context.Ordinances = new AccountDatabaseSet<Ordinance>(ordinances);
        return context;
    }
}
