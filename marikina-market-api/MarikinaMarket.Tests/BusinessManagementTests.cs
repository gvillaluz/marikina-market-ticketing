using System.ComponentModel.DataAnnotations;
using MarikinaMarket.API.Application;
using MarikinaMarket.API.Application.DTOs.Vendor.Request;
using MarikinaMarket.API.Application.Interfaces.Repositories;
using MarikinaMarket.API.Application.Interfaces.Services;
using MarikinaMarket.API.Application.Services;
using MarikinaMarket.API.Domain.Entities;
using MarikinaMarket.API.Domain.Enums;
using Microsoft.Extensions.Logging.Abstractions;
using Xunit;

namespace MarikinaMarket.Tests;

public class BusinessManagementTests
{
    [Fact]
    public async Task Create_preserves_license_number_and_saves_owner_without_account_operations()
    {
        var fixture = new Fixture();
        var request = Request();
        request.BusinessAccountNumber = " 0012-Ab ";
        var response = await fixture.Service.SaveBusinessAsync(null, request);
        Assert.Equal("0012-Ab", response.BusinessAccountNumber);
        Assert.Equal("Reyes", response.OwnerLastName);
        Assert.Null(response.Email);
        Assert.Equal(1, fixture.Saves);
        Assert.True(response.CreatedAt > DateTime.UtcNow.AddMinutes(-1));
    }

    [Theory]
    [InlineData(null)] [InlineData("")] [InlineData(" ")]
    public async Task Public_requires_stall_before_any_writes(string? stall)
    {
        var fixture = new Fixture(); var request = Request(); request.StallNumber = stall;
        await Assert.ThrowsAsync<ValidationException>(() => fixture.Service.SaveBusinessAsync(null, request));
        Assert.Null(fixture.Saved); Assert.Equal(0, fixture.Saves);
    }

    [Fact]
    public async Task Private_can_be_saved_without_stall_or_contact_details()
    {
        var fixture = new Fixture(); var request = Request();
        request.BusinessType = BusinessType.Private; request.StallNumber = null;
        var saved = await fixture.Service.SaveBusinessAsync(null, request);
        Assert.Null(saved.StallNumber); Assert.Null(saved.PhoneNumber); Assert.Null(saved.Email);
    }

    [Fact]
    public async Task Duplicate_is_rejected_without_saving()
    {
        var fixture = new Fixture { Duplicate = true };
        await Assert.ThrowsAsync<InvalidRequestException>(() => fixture.Service.SaveBusinessAsync(null, Request()));
        Assert.Null(fixture.Saved); Assert.Equal(0, fixture.Saves);
    }

    [Fact]
    public async Task Edit_preserves_id_creation_status_qr_and_compliance_metadata()
    {
        var fixture = new Fixture();
        var created = await fixture.Service.SaveBusinessAsync(null, Request());
        fixture.Saved!.CreatedAt = new DateTime(2025, 1, 2, 0, 0, 0, DateTimeKind.Utc);
        fixture.Saved.ComplianceScore = 73;
        var qr = fixture.Saved.QrCodeValue;
        var request = Request(); request.BusinessName = "Reyes Fresh Fish";
        var edited = await fixture.Service.SaveBusinessAsync(created.Id, request);
        Assert.Equal(created.Id, edited.Id);
        Assert.Equal(2025, edited.CreatedAt.Year);
        Assert.Equal("Reyes Fresh Fish", edited.BusinessName);
        Assert.Equal(73, fixture.Saved.ComplianceScore); Assert.Equal(qr, fixture.Saved.QrCodeValue);
    }

    [Fact]
    public async Task Missing_record_and_invalid_section_do_not_write()
    {
        var fixture = new Fixture();
        await Assert.ThrowsAsync<RecordNotFoundException>(() => fixture.Service.SaveBusinessAsync(99, Request()));
        fixture.SectionExists = false;
        await Assert.ThrowsAsync<ValidationException>(() => fixture.Service.SaveBusinessAsync(null, Request()));
        Assert.Equal(0, fixture.Saves);
    }

    internal static SaveBusinessRequest Request() => new()
    {
        BusinessAccountNumber = "0012", BusinessName = "Reyes Fish Store", OwnerFirstName = "Juan",
        OwnerLastName = "Reyes", HouseNumber = "12", Street = "J. P. Rizal", Barangay = "Sta. Elena",
        City = "Marikina City", BusinessType = BusinessType.Public, MarketSectionId = 1, StallNumber = "F-12"
    };

    private sealed class Fixture
    {
        public Business? Saved;
        public bool Duplicate, SectionExists = true;
        public int Saves;
        public VendorService Service { get; }
        public Fixture()
        {
            // Only persistence and delivery boundaries are substituted. The actual service validates and maps records.
            var vendors = ReviewBoundaryProxy.Create<IVendorRepository>((method, args) => method.Name switch
            {
                "BusinessAccountNumberExistsAsync" => Task.FromResult(Duplicate),
                "GetVendorProfileForUpdateAsync" => Task.FromResult(Saved),
                "CreateVendorAsync" => Task.FromResult(Saved = (Business)args![0]!),
                "SaveBusinessChangesAsync" => Save(),
                _ => throw new InvalidOperationException(method.Name)
            });
            var sections = ReviewBoundaryProxy.Create<IMarketSectionRepository>((_, _) => Task.FromResult<MarketSection?>(
                SectionExists ? new() { Id = 1, Name = "Fish", Description = "Fish section", IsActive = true } : null));
            var unit = ReviewBoundaryProxy.Create<IUnitOfWork>((method, _) => method.Name == "SaveChangesAsync"
                ? Task.FromResult(1) : Task.CompletedTask);
            Service = new VendorService(Reject<IUserRepository>(), vendors, unit, sections,
                Reject<IVendorComplianceScoreService>(), Reject<IStorageService>(), Reject<IEmailService>(),
                Reject<INotificationService>(), NullLogger<VendorService>.Instance);
        }
        private Task Save() { Saves++; if (Saved is not null && Saved.Id == 0) Saved.Id = 12; return Task.CompletedTask; }
        private static T Reject<T>() where T : class => ReviewBoundaryProxy.Create<T>((method, _) =>
            throw new InvalidOperationException($"Unexpected account/delivery operation: {method.Name}"));
    }
}
