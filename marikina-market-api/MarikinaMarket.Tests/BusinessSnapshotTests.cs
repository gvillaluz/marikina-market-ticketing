using MarikinaMarket.API.Domain.Enums;
using MarikinaMarket.API.Infrastructure.Repositories;
using MarikinaMarket.API.Domain.Entities;
using MarikinaMarket.API.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;
using Xunit;

namespace MarikinaMarket.Tests;

public class BusinessSnapshotTests
{
    [Fact]
    public async Task Detail_and_person_history_keep_snapshots_after_registry_edits_and_leave_legacy_absent()
    {
        var business = new Business { Id = 1, BusinessAccountNumber = "CURRENT-B", BusinessName = "Current B",
            QrCodeValue = "synthetic", OwnerFirstName = "New", OwnerLastName = "Owner", Type = BusinessType.Private,
            MarketSection = new() { Name = "Current section", Description = "Synthetic" } };
        var officer = new User { FirstName = "Test", LastName = "Officer", DateOfBirth = new(1990, 1, 1), HouseNumber = "1", Street = "Market Lane", Barangay = "Synthetic", City = "Marikina" };
        var ticket = new Ticket { Id = 1, VendorId = 1, Vendor = business, Enforcer = officer, PersonId = 31,
            Description = "Synthetic", Type = ViolationType.Ticket, MarketSection = business.MarketSection,
            SnapshotBusinessAccountNumber = "OLD-001", SnapshotBusinessName = "Historical A",
            SnapshotRegisteredOwnerName = "Original Owner", SnapshotBusinessType = "Public", SnapshotStallNumber = null,
            SnapshotMarketSectionName = "Old section", SnapshotBusinessAddress = "14 Market Lane",
            TicketEvidences = [new() { Id = 3, FileKey = "support-2", Role = TicketEvidenceRole.Supporting, SortOrder = 1 },
                new() { Id = 1, FileKey = "paper", Role = TicketEvidenceRole.PaperTicket, SortOrder = 0 },
                new() { Id = 2, FileKey = "support-1", Role = TicketEvidenceRole.Supporting, SortOrder = 0 }] };
        var legacy = new Ticket { Id = 2, VendorId = 1, Vendor = business, Enforcer = officer, PersonId = 31,
            Description = "Synthetic legacy", Type = ViolationType.Ticket, MarketSection = business.MarketSection };
        using var context = new AppDbContext(new DbContextOptionsBuilder<AppDbContext>().Options);
        context.Tickets = new AccountDatabaseSet<Ticket>([ticket, legacy]);
        var repository = new TicketRepository(context);
        var detail = await repository.GetTicketDetailAsync(1);
        var admin = await repository.GetAdminTicketDetailAsync(1);
        var history = await repository.GetPersonHistoryAsync(31, 0, 10);
        foreach (var items in new[] { detail!.EvidenceItems, admin!.EvidenceItems })
        {
            Assert.Equal(new[] { "paper", "support-1", "support-2" }, items.Select(e => e.Url));
            Assert.Equal(new[] { TicketEvidenceRole.PaperTicket, TicketEvidenceRole.Supporting, TicketEvidenceRole.Supporting }, items.Select(e => e.Role!.Value));
        }
        foreach (var snapshot in new[] { detail!.BusinessSnapshot, admin!.BusinessSnapshot, history.Items.Single(i => i.TicketId == 1).BusinessSnapshot })
        {
            Assert.NotNull(snapshot);
            Assert.Equal("OLD-001", snapshot.BusinessAccountNumber);
            Assert.Equal("Historical A", snapshot.BusinessName);
            Assert.Equal("Original Owner", snapshot.RegisteredOwnerName);
            Assert.Equal("Public", snapshot.BusinessType);
            Assert.Null(snapshot.StallNumber);
            Assert.Equal("Old section", snapshot.MarketSectionName);
            Assert.Equal("14 Market Lane", snapshot.BusinessAddress);
        }
        Assert.Null((await repository.GetTicketDetailAsync(2))!.BusinessSnapshot);
        Assert.Null(history.Items.Single(i => i.TicketId == 2).BusinessSnapshot);
    }

    [Fact]
    public void Migration_target_matches_the_current_model()
    {
        using var context = new AppDbContext(new DbContextOptionsBuilder<AppDbContext>()
            .UseNpgsql("Host=localhost;Database=unused;Username=unused").UseSnakeCaseNamingConvention().Options);
        Assert.False(context.Database.HasPendingModelChanges());
    }

    [Fact]
    public void Historical_columns_are_nullable_without_legacy_backfill()
    {
        using var context = new AppDbContext(new DbContextOptionsBuilder<AppDbContext>()
            .UseNpgsql("Host=localhost;Database=unused;Username=unused").UseSnakeCaseNamingConvention().Options);
        var ticket = context.Model.FindEntityType(typeof(Ticket))!;
        foreach (var name in new[] { "SnapshotBusinessAccountNumber", "SnapshotBusinessName",
            "SnapshotRegisteredOwnerName", "SnapshotBusinessType", "SnapshotStallNumber",
            "SnapshotMarketSectionName", "SnapshotBusinessAddress" })
        {
            var property = ticket.FindProperty(name);
            Assert.NotNull(property);
            Assert.True(property.IsNullable);
            Assert.Null(property.GetDefaultValueSql());
        }
    }
}
