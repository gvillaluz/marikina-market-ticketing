using MarikinaMarket.API.Presentation.Controllers;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Xunit;
using System.Security.Claims;
using MarikinaMarket.API.Application;
using MarikinaMarket.API.Application.Interfaces.Repositories;
using MarikinaMarket.API.Application.Services;
using MarikinaMarket.API.Domain.Entities;
using MarikinaMarket.API.Domain.Enums;
using MarikinaMarket.API.Infrastructure.Persistence;
using MarikinaMarket.API.Infrastructure.Repositories;
using Microsoft.AspNetCore.Http;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging.Abstractions;

namespace MarikinaMarket.Tests;

public class VendorDashboardTests
{
    [Fact]
    public async Task Account_ID_cannot_claim_a_business_dashboard()
    {
        using var context = new AppDbContext(new DbContextOptionsBuilder<AppDbContext>().Options);
        var repository = new VendorRepository(context);
        var service = new VendorService(null!, repository, null!, null!, null!, null!, null!, null!, NullLogger<VendorService>.Instance);
        await Assert.ThrowsAsync<RecordNotFoundException>(() => service.GetOwnDashboardAsync(7));
        await Assert.ThrowsAsync<RecordNotFoundException>(() => service.GetOwnDashboardAsync(70));
    }

    [Theory]
    [InlineData(null)]
    [InlineData("invalid")]
    [InlineData("0")]
    public async Task Dashboard_rejects_missing_or_invalid_identity(string? id)
    {
        var controller = new VendorController(null!)
        {
            ControllerContext = new ControllerContext { HttpContext = new DefaultHttpContext() }
        };
        if (id is not null)
            controller.HttpContext.User = new ClaimsPrincipal(new ClaimsIdentity([new Claim(ClaimTypes.NameIdentifier, id)]));
        Assert.IsType<UnauthorizedObjectResult>((await controller.GetOwnDashboard()).Result);
    }

    [Fact]
    public void Dashboard_is_a_vendor_only_get_endpoint()
    {
        var action = typeof(VendorController).GetMethods().SingleOrDefault(method =>
            method.GetCustomAttributes(typeof(HttpGetAttribute), false)
                .Cast<HttpGetAttribute>().Any(attribute => attribute.Template == "dashboard"));
        Assert.NotNull(action);
        Assert.Equal("MarketVendor", action.GetCustomAttributes(typeof(AuthorizeAttribute), false)
            .Cast<AuthorizeAttribute>().Single().Roles);
    }
}
