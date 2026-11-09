using System.Reflection;
using MarikinaMarket.API.Application.Interfaces.Repositories;
using MarikinaMarket.API.Application.Interfaces.Services;
using MarikinaMarket.API.Presentation.Controllers;
using Microsoft.AspNetCore.Mvc.Routing;
using Xunit;

namespace MarikinaMarket.Tests;

// B2: enforcers no longer scan a business QR code, so the lookup by QR code is gone.
public class QrLookupRemovedTests
{
    [Fact]
    public void The_vendor_controller_has_no_lookup_by_qr_code_route()
    {
        var templates = typeof(VendorController)
            .GetMethods(BindingFlags.Public | BindingFlags.Instance | BindingFlags.DeclaredOnly)
            .SelectMany(method => method.GetCustomAttributes<HttpMethodAttribute>())
            .Select(attribute => attribute.Template ?? "")
            .ToList();

        Assert.DoesNotContain(templates, template => template.StartsWith("code", StringComparison.OrdinalIgnoreCase));
    }

    [Fact]
    public void The_vendor_service_and_repository_no_longer_offer_a_qr_code_lookup()
    {
        Assert.Null(typeof(IVendorService).GetMethod("GetVendorByQrCode"));
        Assert.Null(typeof(IVendorRepository).GetMethod("GetVendorByQrCode"));
    }
}
