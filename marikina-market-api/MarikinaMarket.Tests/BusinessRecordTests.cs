using MarikinaMarket.API.Domain.Entities;
using MarikinaMarket.API.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;
using Xunit;

namespace MarikinaMarket.Tests;

public class BusinessRecordTests
{
    [Fact]
    public void Business_is_account_independent_and_preserves_business_metadata()
    {
        var type = typeof(User).Assembly.GetType("MarikinaMarket.API.Domain.Entities.Business");
        Assert.NotNull(type);
        foreach (var field in new[] { "Id", "BusinessAccountNumber", "BusinessName", "OwnerFirstName", "OwnerLastName",
            "HouseNumber", "Street", "Barangay", "City", "PhoneNumber", "Email", "MarketSectionId", "StallNumber",
            "Type", "Status", "CreatedAt", "QrCodeValue", "ComplianceScore", "ScoreUpdatedAt" })
            Assert.NotNull(type.GetProperty(field));
        Assert.Null(type.GetProperty("UserId"));
        Assert.Null(type.GetProperty("User"));
    }

    [Fact]
    public void Business_mapping_uses_businesses_table_and_unique_account_number()
    {
        using var context = new AppDbContext(new DbContextOptionsBuilder<AppDbContext>()
            .UseNpgsql("Host=localhost;Database=model_inspection_only").Options);
        var entity = context.Model.GetEntityTypes().SingleOrDefault(entity => entity.ClrType.Name == "Business");
        Assert.NotNull(entity);
        Assert.Equal("businesses", entity.GetTableName());
        Assert.Contains(entity.GetIndexes(), index => index.IsUnique &&
            index.Properties.Select(property => property.Name).SequenceEqual(new[] { "BusinessAccountNumber" }));
        Assert.DoesNotContain(entity.GetForeignKeys(), key => key.PrincipalEntityType.ClrType == typeof(User));
    }

    [Fact]
    public void Migration_is_reviewable_offline_and_guards_the_approved_disposable_reset()
    {
        using var context = new AppDbContext(new DbContextOptionsBuilder<AppDbContext>()
            .UseNpgsql("Host=localhost;Database=model_inspection_only").UseSnakeCaseNamingConvention().Options);
        Assert.False(context.Database.HasPendingModelChanges());
        var sql = context.GetService<IMigrator>().GenerateScript("20261014120000_AddVendorNotifications", "20261027142714_BusinessRecords");
        Assert.Contains("current_database() <> 'marikina_market_e2e'", sql);
        Assert.Contains("role.name <> 'MarketVendor'", sql);
        Assert.Contains("DELETE FROM \"AspNetUsers\" WHERE id IN (SELECT id FROM retired_vendor_users)", sql);
        Assert.Contains("DELETE FROM tickets WHERE id IN (SELECT id FROM retired_vendor_tickets)", sql);
        Assert.True(sql.IndexOf("DELETE FROM ticket_violations", StringComparison.Ordinal) < sql.IndexOf("DELETE FROM tickets", StringComparison.Ordinal));
        Assert.Contains("CREATE TABLE businesses", sql);
        Assert.Contains("lower(btrim(\"business_account_number\"))", sql);
        Assert.Contains("CREATE UNIQUE INDEX ix_businesses_account_number_key", sql);
        Assert.DoesNotContain("INSERT INTO businesses", sql);
    }
}
