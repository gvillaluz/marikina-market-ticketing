using System.Reflection;
using MarikinaMarket.API.Presentation;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Server.Kestrel.Core;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using Xunit;

namespace MarikinaMarket.Tests;

public class LocalPortsTests
{
    // On a developer computer (Development) the server keeps its fixed ports: 5000 plain, 5001 HTTPS with the
    // development certificate, used by the phone app and the live checks.
    [Fact]
    public async Task On_a_developer_computer_the_server_keeps_ports_5000_and_5001()
    {
        await using var app = Build("Development");
        Assert.Equal([(5000, false), (5001, true)], CodeEndpoints(app));
    }

    // On Azure (not Development) the host chooses the port (8080 on App Service for Linux) and provides HTTPS
    // itself. The server must not demand a development certificate there: that stopped the demo server at start-up.
    [Theory]
    [InlineData("Production")]
    [InlineData("Staging")]
    public async Task On_Azure_the_server_opens_no_fixed_ports_and_needs_no_certificate(string environment)
    {
        await using var app = Build(environment);
        Assert.Empty(CodeEndpoints(app));
    }

    private static WebApplication Build(string environment)
    {
        var builder = WebApplication.CreateBuilder(new WebApplicationOptions { EnvironmentName = environment });
        builder.Logging.ClearProviders();
        builder.UseLocalPorts();
        return builder.Build();
    }

    // Reads the endpoints the start-up code asked Kestrel for, without opening them (ports may be in use).
    // KestrelServerOptions keeps them in an internal list; reading it is the only way short of binding the ports.
    private static (int Port, bool Https)[] CodeEndpoints(WebApplication app)
    {
        var options = app.Services.GetRequiredService<IOptions<KestrelServerOptions>>().Value;
        var list = (IEnumerable<ListenOptions>)typeof(KestrelServerOptions)
            .GetProperty("CodeBackedListenOptions", BindingFlags.Instance | BindingFlags.NonPublic)!
            .GetValue(options)!;
        var isTls = typeof(ListenOptions).GetProperty("IsTls", BindingFlags.Instance | BindingFlags.NonPublic)!;
        return list.Select(endpoint => (endpoint.IPEndPoint!.Port, (bool)isTls.GetValue(endpoint)!)).ToArray();
    }
}
