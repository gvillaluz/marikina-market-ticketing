using System.Collections;
using System.Linq.Expressions;
using System.ComponentModel.DataAnnotations;
using MarikinaMarket.API.Application.DTOs.User.Request;
using MarikinaMarket.API.Application.DTOs.Vendor.Request;
using MarikinaMarket.API.Application.Interfaces.Repositories;
using MarikinaMarket.API.Application.Interfaces.Services;
using MarikinaMarket.API.Application.Services;
using MarikinaMarket.API.Domain.Entities;
using MarikinaMarket.API.Domain.Enums;
using MarikinaMarket.API.Infrastructure.Persistence;
using MarikinaMarket.API.Infrastructure.Repositories;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.ChangeTracking;
using Microsoft.Extensions.Logging.Abstractions;
using Xunit;

namespace MarikinaMarket.Tests;

public class VendorRegistrationTests
{
    [Theory]
    [InlineData("public")]
    [InlineData("admin")]
    [InlineData("approval")]
    public async Task Retired_registration_paths_cannot_create_vendor_accounts(string path)
    {
        using var fixture = new Fixture();
        var error = await Assert.ThrowsAsync<MarikinaMarket.API.Application.InvalidRequestException>(async () =>
        {
            if (path == "public") await fixture.Service.CreateVendorRegistryAsync(fixture.Request);
            else if (path == "admin") await fixture.Service.CreateAdminVendorRegistrationAsync(fixture.AdminRequest(), 7);
            else await fixture.Service.ApproveVendorRegistration(42, new()
                { RequestStatus = RequestStatus.Approved, Version = 1200, AdminId = 7 });
        });
        Assert.Contains("no longer supported", error.Message);
        Assert.Empty(fixture.CreatedUsers);
        Assert.Empty(fixture.Profiles);
        Assert.Empty(fixture.Registrations);
        Assert.Empty(fixture.EmailBodies);
        Assert.Equal(0, fixture.Uploads);
        Assert.Equal(0, fixture.Saves);
    }

    private sealed class Fixture : AppDbContext
    {
        public List<VendorRegistrationRequest> Registrations { get; } = [];
        public List<Business> Profiles { get; } = [];
        public List<User> CreatedUsers { get; } = [];
        public List<string> EmailBodies { get; } = [];
        public string Sequence = "0010";
        public string? LastEmailLookup;
        public bool FailEmail = false, AccountExists = false;
        public int Saves, Uploads;
        public VendorService Service { get; }
        public RegisterVendorRequest Request { get; } = new()
        {
            FirstName = "Juan", LastName = "Reyes", DateOfBirth = new(1990, 1, 1),
            HouseNumber = "12", Street = "Sampaguita", Barangay = "Santa Elena", City = "Marikina",
            PhoneNumber = "09171234567", Email = "juan@example.invalid", BusinessAccountNumber = "MM-2026-0010",
            BusinessName = "Reyes Fresh Fish", NatureOfBusiness = "Fish retail", MarketSectionId = 1,
            StallNumber = "F-010",
            BusinessType = BusinessType.Public, GovernmentIdType = GovernmentIdType.NationalId,
            Password = "Registration-password-123", ConfirmPassword = "Registration-password-123",
            GovernmentIdPhoto = Photo("government.png"), BusinessDocumentPhoto = Photo("business.png")
        };

        public Fixture() : base(new DbContextOptionsBuilder<AppDbContext>()
            .UseNpgsql("Host=localhost;Database=unused;Username=unused").Options)
        {
            VendorRegistrationRequests = new RegistrationDbSet<VendorRegistrationRequest>(Registrations);
            Businesses = new RegistrationDbSet<Business>(Profiles);
            var users = ReviewBoundaryProxy.Create<IUserRepository>((method, args) => method.Name switch
            {
                "FindByEmailAsync" => FindEmail((string)args[0]!),
                "GetNextUserNameAsync" => Task.FromResult(Sequence),
                "CreateUserWithPassAsync" => CreateUser((User)args[0]!),
                "AddToRoleAsync" => Task.FromResult(IdentityResult.Success),
                _ => throw new InvalidOperationException(method.Name)
            });
            var section = new MarketSection { Id = 1, Name = "Fish and Seafood", Description = "Fish retail" };
            var unit = ReviewBoundaryProxy.Create<IUnitOfWork>((method, args) => method.Name == "SaveChangesAsync"
                ? SaveChangesAsync() : Task.CompletedTask);
            Service = new VendorService(users, new VendorRepository(this), unit,
                ReviewBoundaryProxy.Create<IMarketSectionRepository>((method, args) => Task.FromResult<MarketSection?>(section)),
                null!, ReviewBoundaryProxy.Create<IStorageService>((method, args) =>
                {
                    Uploads++;
                    return Task.FromResult((string)args[2]!);
                }), ReviewBoundaryProxy.Create<IEmailService>((method, args) =>
                {
                    EmailBodies.Add((string)args[2]!);
                    return FailEmail ? Task.FromException(new InvalidOperationException("Email unavailable")) : Task.CompletedTask;
                }), ReviewBoundaryProxy.Create<INotificationService>((method, args) => Task.FromResult(false)),
                NullLogger<VendorService>.Instance);
        }

        private Task<User?> FindEmail(string email)
        {
            LastEmailLookup = email;
            return Task.FromResult<User?>(AccountExists ? SampleUser() : null);
        }

        private static User SampleUser() => new()
        {
            FirstName = "Juan", LastName = "Reyes", DateOfBirth = new(1990, 1, 1),
            HouseNumber = "12", Street = "Sampaguita", Barangay = "Santa Elena", City = "Marikina"
        };

        private Task<IdentityResult> CreateUser(User user)
        {
            user.Id = 7;
            CreatedUsers.Add(user);
            return Task.FromResult(IdentityResult.Success);
        }

        public override Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
        {
            Saves++;
            foreach (var registration in Registrations)
            {
                if (registration.Id == 0) registration.Id = 42;
                if (registration.Version == 0) registration.Version = 1200;
            }
            return Task.FromResult(1);
        }

        public AdminRegisterVendorRequest AdminRequest() => new()
        {
            FirstName = Request.FirstName, LastName = Request.LastName, DateOfBirth = Request.DateOfBirth,
            HouseNumber = Request.HouseNumber, Street = Request.Street, Barangay = Request.Barangay, City = Request.City,
            PhoneNumber = Request.PhoneNumber, Email = Request.Email, BusinessAccountNumber = Request.BusinessAccountNumber,
            BusinessName = Request.BusinessName, NatureOfBusiness = Request.NatureOfBusiness,
            MarketSectionId = Request.MarketSectionId, BusinessType = Request.BusinessType,
            Password = Request.Password, ConfirmPassword = Request.ConfirmPassword
        };

        private static IFormFile Photo(string name) => new FormFile(new MemoryStream([137, 80, 78, 71]), 0, 4, "file", name)
        {
            Headers = new HeaderDictionary(), ContentType = "image/png"
        };
    }
}

internal sealed class RegistrationDbSet<T>(List<T> records) : DbSet<T>, IQueryable<T> where T : class
{
    private readonly IQueryable<T> _source = records.AsQueryable();
    public override Microsoft.EntityFrameworkCore.Metadata.IEntityType EntityType => throw new NotSupportedException();
    Type IQueryable.ElementType => typeof(T);
    Expression IQueryable.Expression => _source.Expression;
    IQueryProvider IQueryable.Provider => new VendorTicketQueryProvider(_source.Provider, new());
    IEnumerator<T> IEnumerable<T>.GetEnumerator() => _source.GetEnumerator();
    public override ValueTask<EntityEntry<T>> AddAsync(T entity, CancellationToken cancellationToken = default)
    {
        records.Add(entity);
        return ValueTask.FromResult<EntityEntry<T>>(null!);
    }
}
