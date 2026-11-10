using System.Reflection;
using MarikinaMarket.API.Application.Interfaces.Services;
using MarikinaMarket.API.Presentation.Controllers;
using Microsoft.AspNetCore.Mvc.Routing;
using Xunit;

namespace MarikinaMarket.Tests;

// The old vendor sign-up and application review routes are removed. These tests list the routes each
// controller still has, so a removed route cannot come back and a kept route cannot be dropped by mistake.
public class VendorSignUpRemovalTests
{
    private static List<string> Routes(Type controller) => controller
        .GetMethods(BindingFlags.Public | BindingFlags.Instance | BindingFlags.DeclaredOnly)
        .SelectMany(method => method.GetCustomAttributes<HttpMethodAttribute>())
        .Select(route => $"{route.HttpMethods.Single()} {route.Template}")
        .OrderBy(route => route, StringComparer.Ordinal)
        .ToList();

    [Fact]
    public void Vendor_controller_keeps_only_the_vendor_own_and_enforcer_lookup_routes()
    {
        Assert.Equal(
            new[]
            {
                "GET dashboard",
                "GET lookup",
                "GET profile",
                "GET {businessId:int}/people",
                "PUT profile",
            },
            Routes(typeof(VendorController)));
    }

    [Fact]
    public void Admin_vendor_controller_keeps_only_the_business_list_and_compliance_routes()
    {
        Assert.Equal(
            new[]
            {
                "GET ",
                "GET community-service-logs",
                "GET compliance-overview",
                "GET pending-settlements",
                "GET {vendorId:int}/compliance-score",
                "GET {vendorId:int}/inspections",
                "GET {vendorId:int}/profile",
            },
            Routes(typeof(AdminVendorController)));
    }

    [Fact]
    public void Vendor_service_has_no_sign_up_or_application_review_methods()
    {
        var names = typeof(IVendorService).GetMethods().Select(method => method.Name).ToList();
        Assert.DoesNotContain(names, name =>
            name.Contains("Registry") || name.Contains("Registration") || name == "RequestMoreInformation");
    }
}
