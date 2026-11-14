using System.Net;
using MarikinaMarket.API.Presentation;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.TestHost;
using Microsoft.Extensions.Logging;
using Xunit;

namespace MarikinaMarket.Tests;

public class WebsiteFallbackTests
{
    private const string StartPage = "<!doctype html><title>Marikina website</title>";
    private const string Script = "console.log('website script');";

    [Theory]
    [InlineData("/")]
    [InlineData("/dashboard")]
    [InlineData("/admin/login")]
    [InlineData("/auth/verify-login")]
    [InlineData("/tickets/42?tab=history")]
    public async Task Website_page_addresses_load_the_website_start_page(string address)
    {
        await using var site = await WebsiteHost.CreateAsync();
        var response = await site.Client.GetAsync(address);
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.Equal("text/html", response.Content.Headers.ContentType?.MediaType);
        Assert.Equal(StartPage, await response.Content.ReadAsStringAsync());
    }

    [Theory]
    [InlineData("/api")]
    [InlineData("/api/does-not-exist")]
    [InlineData("/API/Auth/unknown")]
    [InlineData("/assets/missing.js")]
    public async Task Server_addresses_and_missing_files_never_load_the_website(string address)
    {
        await using var site = await WebsiteHost.CreateAsync();
        var response = await site.Client.GetAsync(address);
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
        Assert.DoesNotContain("Marikina website", await response.Content.ReadAsStringAsync());
    }

    [Fact]
    public async Task Website_files_are_served_as_themselves()
    {
        await using var site = await WebsiteHost.CreateAsync();
        var response = await site.Client.GetAsync("/assets/app.js");
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.Equal(Script, await response.Content.ReadAsStringAsync());
    }

    private sealed class WebsiteHost : IAsyncDisposable
    {
        private readonly string _webRoot;
        private readonly WebApplication _app;
        public HttpClient Client { get; }

        private WebsiteHost(string webRoot, WebApplication app)
        {
            _webRoot = webRoot;
            _app = app;
            Client = app.GetTestClient();
        }

        public static async Task<WebsiteHost> CreateAsync()
        {
            var webRoot = Path.Combine(Path.GetTempPath(), "website-fallback-" + Guid.NewGuid().ToString("N"));
            Directory.CreateDirectory(Path.Combine(webRoot, "assets"));
            await File.WriteAllTextAsync(Path.Combine(webRoot, "index.html"), StartPage);
            await File.WriteAllTextAsync(Path.Combine(webRoot, "assets", "app.js"), Script);

            var builder = WebApplication.CreateBuilder(new WebApplicationOptions { WebRootPath = webRoot });
            builder.WebHost.UseTestServer();
            builder.Logging.ClearProviders();
            var app = builder.Build();
            app.UseRouting();
            app.UseStaticFiles();
            app.MapWebsiteFallback();
            await app.StartAsync();
            return new WebsiteHost(webRoot, app);
        }

        public async ValueTask DisposeAsync()
        {
            Client.Dispose();
            await _app.DisposeAsync();
            Directory.Delete(_webRoot, recursive: true);
        }
    }
}
