using MarikinaMarket.API.Domain.Entities;
using MarikinaMarket.API.Infrastructure.Persistence;
using MarikinaMarket.API.Infrastructure.Repositories;
using Microsoft.EntityFrameworkCore;
using Xunit;

namespace MarikinaMarket.Tests;

// Enforcement lookups (fine summary, warning check, Verify, submission) must not offer
// deactivated ordinances; the admin catalog still lists them.
public class OrdinanceActiveFilterTests
{
    private static AppDbContext Context(params Ordinance[] ordinances)
    {
        var context = new AppDbContext(new DbContextOptionsBuilder<AppDbContext>().Options);
        context.Ordinances = new AccountDatabaseSet<Ordinance>(ordinances);
        return context;
    }

    private static Ordinance Active() => new() { Id = 2, OrdinanceNo = "011", Series = "2014", Section = "12", Title = "Market Identification Card", IsActive = true };
    private static Ordinance Retired() => new() { Id = 1, OrdinanceNo = "145", Series = "2006", Title = "Peace & Order Code", IsActive = false };

    [Fact]
    public async Task Person_lookup_returns_only_active_ordinances()
    {
        using var context = Context(Active(), Retired());
        var result = await new OrdinanceRepository(context).GetByPersonIdsAsync([1, 2], 33);
        Assert.Equal(2, Assert.Single(result).OrdinanceId);
    }

    [Fact]
    public async Task Vendor_lookup_returns_only_active_ordinances()
    {
        using var context = Context(Active(), Retired());
        var result = await new OrdinanceRepository(context).GetByIdsAsync([1, 2], 6);
        Assert.Equal(2, Assert.Single(result).OrdinanceId);
    }

    [Fact]
    public async Task Admin_catalog_still_lists_inactive_ordinances()
    {
        using var context = Context(Active(), Retired());
        var all = await new OrdinanceRepository(context).GetOrdinances();
        Assert.Equal([1, 2], all.Select(o => o.Id).Order());
        Assert.False(all.Single(o => o.Id == 1).IsActive);
    }
}
