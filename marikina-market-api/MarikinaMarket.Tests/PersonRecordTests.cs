using MarikinaMarket.API.Domain.Entities;
using MarikinaMarket.API.Infrastructure.Persistence;
using MarikinaMarket.API.Infrastructure.Repositories;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;
using Xunit;

namespace MarikinaMarket.Tests;

public class PersonRecordTests
{
    [Fact]
    public async Task Repository_searches_candidate_fields_and_pages_same_name_records_stably()
    {
        using var context = new AppDbContext(new DbContextOptionsBuilder<AppDbContext>().Options);
        context.Persons = new AccountDatabaseSet<Person>(Enumerable.Range(1, 12).Reverse().Select(id => new Person
        {
            Id = id, FullName = "E2E Elena Reyes", Address = id == 12 ? "River Lane" : "Market Lane",
            PhoneNumber = id == 12 ? "09171234567" : null
        }));
        var repository = new PersonRepository(context);
        var (first, total) = await repository.SearchAsync("ELENA", 0, 10);
        Assert.Equal(12, total);
        Assert.Equal(Enumerable.Range(1, 10), first.Select(p => p.Id));
        var (second, _) = await repository.SearchAsync("Elena", 10, 10);
        Assert.Equal(new[] { 11, 12 }, second.Select(p => p.Id));
        foreach (var term in new[] { "river", "09171234567" })
            Assert.Equal(12, Assert.Single((await repository.SearchAsync(term, 0, 10)).Items).Id);
        Assert.Empty((await repository.SearchAsync("absent", 0, 10)).Items);
    }

    [Fact]
    public void Schema_source_matches_current_model_and_only_adds_persons()
    {
        using var context = new AppDbContext(new DbContextOptionsBuilder<AppDbContext>()
            .UseNpgsql("Host=localhost;Database=model_inspection_only").UseSnakeCaseNamingConvention().Options);
        Assert.False(context.Database.HasPendingModelChanges());
        var migration = context.GetService<IMigrationsAssembly>().CreateMigration(
            context.GetService<IMigrationsAssembly>().Migrations["20261028080000_PersonRegistry"], context.Database.ProviderName!);
        var operation = Assert.IsType<Microsoft.EntityFrameworkCore.Migrations.Operations.CreateTableOperation>(Assert.Single(migration.UpOperations));
        Assert.Equal("persons", operation.Name);
        Assert.Empty(operation.ForeignKeys);
        var sql = context.GetService<IMigrator>().GenerateScript("20261027142714_BusinessRecords", "20261028080000_PersonRegistry");
        Assert.Contains("CREATE TABLE persons", sql);
        Assert.DoesNotContain("DELETE FROM", sql);
        Assert.DoesNotContain("DROP TABLE", sql);
    }

    [Fact]
    public void Person_is_independent_and_has_no_unique_name_or_contact_constraint()
    {
        using var context = new AppDbContext(new DbContextOptionsBuilder<AppDbContext>()
            .UseNpgsql("Host=localhost;Database=model_inspection_only").UseSnakeCaseNamingConvention().Options);
        var entity = context.Model.FindEntityType(typeof(Person));
        Assert.NotNull(entity);
        Assert.Equal("persons", entity.GetTableName());
        Assert.Empty(entity.GetForeignKeys());
        Assert.DoesNotContain(entity.GetIndexes(), index => index.IsUnique);
        Assert.Null(typeof(Person).GetProperty("UserId"));
        Assert.Null(typeof(Person).GetProperty("BusinessId"));
        Assert.Equal(200, entity.FindProperty("FullName")!.GetMaxLength());
        Assert.Equal(500, entity.FindProperty("Address")!.GetMaxLength());
    }
}
