using MarikinaMarket.API.Domain.Entities;
using MarikinaMarket.API.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;
using Microsoft.EntityFrameworkCore.Migrations.Operations;
using Xunit;

namespace MarikinaMarket.Tests;

public class OrdinancePenaltyMigrationTests
{
    [Fact]
    public void Model_has_ordinance_classification_and_recovery_only_legacy_tier_severity()
    {
        using var context = Context();
        Assert.False(context.Database.HasPendingModelChanges());
        var ordinance = context.Model.FindEntityType(typeof(Ordinance))!;
        Assert.True(ordinance.FindProperty("Severity")!.IsNullable);
        var tier = context.Model.FindEntityType(typeof(OrdinancePenaltyTier))!;
        Assert.Null(tier.FindProperty("Severity"));
        Assert.True(tier.FindProperty("LegacySeverity")!.IsShadowProperty());
        Assert.True(tier.FindProperty("LegacySeverity")!.IsNullable);
        Assert.True(tier.FindProperty("PenaltyAmount")!.IsNullable);
        Assert.Equal(1000, tier.FindProperty("PenaltyTerms")!.GetMaxLength());
    }

    [Fact]
    public void Migration_preserves_catalog_ids_fines_and_old_severity_without_touching_ticket_history()
    {
        using var context = Context();
        var assembly = context.GetService<IMigrationsAssembly>();
        var entry = assembly.Migrations.Single(pair => pair.Key == "20261031112520_OrdinancePenaltyRules");
        var migration = assembly.CreateMigration(entry.Value, context.Database.ProviderName!);
        Assert.DoesNotContain(migration.UpOperations, operation => operation is DropColumnOperation or DeleteDataOperation or DropTableOperation);
        foreach (var operation in migration.UpOperations)
        {
            if (operation.GetType().GetProperty("Table")?.GetValue(operation) is string table)
                Assert.Contains(table, new[] { "ordinances", "ordinance_penalty_tiers" });
        }
        var sql = context.GetService<IMigrator>().GenerateScript("20261030163743_OrdinanceSectionAndSpecificCategory", entry.Key);
        foreach (var table in new[] { "tickets", "ticket_violations", "businesses", "persons", "ticket_evidences", "community_service_logs" })
            Assert.DoesNotContain(table, sql);
        Assert.Contains("SET severity = first_tier.severity", sql);
        Assert.Contains("fine_kind = 'Fixed'", sql);
        Assert.Contains("legacy.offense_number = 0", sql);
        Assert.Contains("explicit_first.offense_number = 1", sql);
        Assert.DoesNotContain("SET penalty_amount", sql);
        Assert.DoesNotContain("DELETE FROM", sql);
        var rollback = Assert.IsType<SqlOperation>(migration.DownOperations.First()).Sql;
        Assert.Contains("Rollback blocked", rollback);
        Assert.Contains("severity IS NULL", rollback);
        Assert.Contains("fine_kind <> 'Fixed'", rollback);
        Assert.Contains("IS DISTINCT FROM", rollback);
    }

    private static AppDbContext Context() => new(new DbContextOptionsBuilder<AppDbContext>()
        .UseNpgsql("Host=localhost;Database=unused;Username=unused").UseSnakeCaseNamingConvention().Options);
}
