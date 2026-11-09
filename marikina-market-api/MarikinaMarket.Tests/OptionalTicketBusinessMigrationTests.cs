using MarikinaMarket.API.Domain.Entities;
using MarikinaMarket.API.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;
using Microsoft.EntityFrameworkCore.Migrations.Operations;
using Xunit;

namespace MarikinaMarket.Tests;

// Slice B1: a ticket's business becomes optional (an unregistered vendor has none).
public class OptionalTicketBusinessMigrationTests
{
    private const string MigrationId = "20261109090000_OptionalTicketBusiness";

    [Fact]
    public void A_ticket_may_have_no_business_and_the_snapshot_matches_the_model()
    {
        using var context = Context();
        Assert.False(context.Database.HasPendingModelChanges());
        var ticket = context.Model.FindEntityType(typeof(Ticket))!;
        Assert.True(ticket.FindProperty("VendorId")!.IsNullable);
        Assert.False(ticket.FindNavigation("Vendor")!.ForeignKey.IsRequired);
    }

    [Fact]
    public void Migration_only_lets_ticket_business_be_empty_and_keeps_existing_rows()
    {
        using var context = Context();
        var assembly = context.GetService<IMigrationsAssembly>();
        var migration = assembly.CreateMigration(assembly.Migrations[MigrationId], context.Database.ProviderName!);

        var up = Assert.IsType<AlterColumnOperation>(Assert.Single(migration.UpOperations));
        Assert.Equal("tickets", up.Table);
        Assert.Equal("vendor_id", up.Name);
        Assert.True(up.IsNullable);

        var down = Assert.IsType<AlterColumnOperation>(Assert.Single(migration.DownOperations));
        Assert.Equal("vendor_id", down.Name);
        Assert.False(down.IsNullable);

        var sql = context.GetService<IMigrator>().GenerateScript("20261101090000_OrdinanceWorkbookCatalog", MigrationId);
        Assert.Contains("ALTER COLUMN vendor_id DROP NOT NULL", sql);
        Assert.DoesNotContain("DELETE FROM", sql);
        Assert.DoesNotContain("UPDATE", sql);
    }

    private static AppDbContext Context() => new(new DbContextOptionsBuilder<AppDbContext>()
        .UseNpgsql("Host=localhost;Database=unused;Username=unused").UseSnakeCaseNamingConvention().Options);
}
