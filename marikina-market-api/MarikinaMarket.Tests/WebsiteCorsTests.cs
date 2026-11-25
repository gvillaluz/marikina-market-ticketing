using MarikinaMarket.API.Presentation;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.TestHost;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Xunit;

namespace MarikinaMarket.Tests;

public class WebsiteCorsTests
{
    private const string Website = "https://website.example";
    private const string OtherSite = "https://other-site.example";

    [Theory]
    [InlineData("OPTIONS")]
    [InlineData("POST")]
    public async Task The_website_address_may_read_answers_and_send_the_sign_in_cookie(string method)
    {
        await using var host = await CorsHost.CreateAsync(Website);
        var response = await host.SendAsync(method, Website);
        Assert.Equal(Website, Header(response, "Access-Control-Allow-Origin"));
        Assert.Equal("true", Header(response, "Access-Control-Allow-Credentials"));
    }

    // The browser hides a download's file name from the website unless the server allows it. Without this the
    // website saved backups as backup-<id>.enc, which restore-from-file turns away.
    [Fact]
    public async Task The_website_address_may_read_the_file_name_of_a_download()
    {
        await using var host = await CorsHost.CreateAsync(Website);
        var response = await host.SendAsync("POST", Website);
        Assert.Equal("Content-Disposition", Header(response, "Access-Control-Expose-Headers"));
    }

    [Theory]
    [InlineData("OPTIONS", OtherSite, Website)]
    [InlineData("POST", OtherSite, Website)]
    [InlineData("OPTIONS", Website, null)]
    [InlineData("POST", Website, null)]
    public async Task Any_other_address_gets_no_permission(string method, string origin, string? allowedOrigin)
    {
        await using var host = await CorsHost.CreateAsync(allowedOrigin);
        var response = await host.SendAsync(method, origin);
        Assert.Null(Header(response, "Access-Control-Allow-Origin"));
        Assert.Null(Header(response, "Access-Control-Allow-Credentials"));
    }

    private static string? Header(HttpResponseMessage response, string name)
        => response.Headers.TryGetValues(name, out var values) ? string.Join(",", values) : null;

    private sealed class CorsHost : IAsyncDisposable
    {
        private readonly WebApplication _app;
        private readonly HttpClient _client;

        private CorsHost(WebApplication app)
        {
            _app = app;
            _client = app.GetTestClient();
        }

        public static async Task<CorsHost> CreateAsync(string? allowedOrigin)
        {
            var builder = WebApplication.CreateBuilder();
            builder.WebHost.UseTestServer();
            builder.Logging.ClearProviders();
            builder.Configuration.Sources.Clear();
            if (allowedOrigin is not null)
                builder.Configuration.AddInMemoryCollection(
                    new Dictionary<string, string?> { ["Cors:AllowedOrigins:0"] = allowedOrigin });
            builder.Services.AddWebsiteCors(builder.Configuration);
            var app = builder.Build();
            app.UseRouting();
            app.UseCors(WebsiteCors.PolicyName);
            app.MapPost("/api/auth/refresh-web", () => Results.Ok());
            await app.StartAsync();
            return new CorsHost(app);
        }

        public async Task<HttpResponseMessage> SendAsync(string method, string origin)
        {
            using var request = new HttpRequestMessage(new HttpMethod(method), "/api/auth/refresh-web");
            request.Headers.Add("Origin", origin);
            if (method == "OPTIONS")
            {
                request.Headers.Add("Access-Control-Request-Method", "POST");
                request.Headers.Add("Access-Control-Request-Headers", "content-type");
            }
            return await _client.SendAsync(request);
        }

        public async ValueTask DisposeAsync()
        {
            _client.Dispose();
            await _app.DisposeAsync();
        }
    }
}
