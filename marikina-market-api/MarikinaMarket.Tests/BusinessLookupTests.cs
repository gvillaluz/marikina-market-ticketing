using MarikinaMarket.API.Domain.Entities;
using MarikinaMarket.API.Domain.Enums;
using MarikinaMarket.API.Infrastructure.Persistence;
using MarikinaMarket.API.Infrastructure.Repositories;
using Microsoft.EntityFrameworkCore;
using Npgsql;
using MarikinaMarket.API.Application;
using Xunit;

namespace MarikinaMarket.Tests;

public class BusinessLookupTests
{
    [Theory]
    [InlineData("ix_businesses_account_number_key")]
    [InlineData("ix_businesses_business_account_number")]
    public async Task Both_account_number_constraints_report_a_duplicate_instead_of_a_server_error(string constraint)
    {
        using var context = new DuplicateSaveContext(constraint);
        var error = await Assert.ThrowsAsync<InvalidRequestException>(() => new VendorRepository(context).SaveBusinessChangesAsync());
        Assert.Equal("Business account number is already in use.", error.Message);
    }

    [Fact]
    public async Task Lookup_uses_business_owner_fields_without_a_login_or_username()
    {
        using var context = new AppDbContext(new DbContextOptionsBuilder<AppDbContext>().Options);
        context.Businesses = new AccountDatabaseSet<Business>([new Business
        {
            Id = 70, BusinessAccountNumber = "0001842-Ab", BusinessName = "Reyes Fish Store",
            OwnerFirstName = "Juan", OwnerLastName = "Reyes", HouseNumber = "12", Street = "J. P. Rizal",
            Barangay = "Sta. Elena", City = "Marikina City", QrCodeValue = "business-only-70",
            Status = VendorStatus.Active, MarketSectionId = 1,
            MarketSection = new() { Id = 1, Name = "Fish", Description = "Fish section" }
        }]);
        var repository = new VendorRepository(context);
        var lookup = Assert.Single(await repository.GetVendorByBusinessAccountNumber("1842-aB"));
        Assert.Equal("0001842-Ab", lookup.BusinessAccountNumber);
        Assert.Equal("Juan", lookup.FirstName); Assert.Equal("Reyes", lookup.LastName);
        Assert.Null(lookup.Username);
        Assert.Contains("Sta. Elena", lookup.Address);
        var qr = await repository.GetVendorByQrCode("business-only-70");
        Assert.Equal(lookup.VendorId, qr!.VendorId);
        Assert.Null(await repository.GetVendorIdByUserIdAsync(70));
        Assert.Null(await repository.GetVendorUserIdAsync(70));
    }

    private sealed class DuplicateSaveContext(string constraint) : AppDbContext(new DbContextOptionsBuilder<AppDbContext>().Options)
    {
        public override Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
            => Task.FromException<int>(new DbUpdateException("Synthetic duplicate", new PostgresException(
                "Synthetic duplicate", "ERROR", "ERROR", PostgresErrorCodes.UniqueViolation, constraintName: constraint)));
    }
}
