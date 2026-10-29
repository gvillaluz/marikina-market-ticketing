using System.Net;
using System.Text.Json;
using MarikinaMarket.API.Infrastructure.Persistence;
using MarikinaMarket.API.Infrastructure.Repositories;
using Microsoft.EntityFrameworkCore;
using Xunit;

namespace MarikinaMarket.Tests;

public class VendorTicketDetailTests
{
    [Fact]
    public async Task Former_account_cannot_read_a_ticket_or_sign_evidence()
    {
        await using var host = await VendorTicketHost.CreateAsync();
        using var response = await host.GetAsync("/api/vendor/tickets/101?user_id=88&vendor_id=7");
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
        Assert.Equal(0, host.Storage.Calls);
    }

    [Fact]
    public async Task Former_account_cannot_read_a_warning()
    {
        await using var host = await VendorTicketHost.CreateAsync();
        using var response = await host.GetAsync("/api/vendor/tickets/200");
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
        Assert.Equal(0, host.Storage.Calls);
    }

    [Theory]
    [InlineData(901, "7")]
    [InlineData(101, "88")]
    [InlineData(99999, "7")]
    [InlineData(101, "999")]
    public async Task MissingOrOtherVendorsTicket_Returns404BeforeSigningEvidence(int ticketId, string userId)
    {
        await using var host = await VendorTicketHost.CreateAsync();
        using var response = await host.GetAsync($"/api/vendor/tickets/{ticketId}?user_id=88&vendor_id=7", userId: userId);
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
        using var json = JsonDocument.Parse(await response.Content.ReadAsStringAsync());
        Assert.Equal("Ticket not found.", json.RootElement.GetProperty("message").GetString());
        Assert.Equal(0, host.Storage.Calls);
        Assert.Empty(host.Storage.SignedKeys);
    }

    [Fact]
    public async Task Former_account_cannot_claim_a_private_business_ticket()
    {
        await using var host = await VendorTicketHost.CreateAsync();
        using var response = await host.GetAsync("/api/vendor/tickets/901");
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
        Assert.Equal(0, host.Storage.Calls);
    }

    [Theory]
    [InlineData("0")]
    [InlineData("-1")]
    [InlineData("invalid")]
    [InlineData("2147483648")]
    public async Task InvalidTicketId_Returns400(string ticketId)
    {
        await using var host = await VendorTicketHost.CreateAsync();
        using var response = await host.GetAsync($"/api/vendor/tickets/{ticketId}");
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
        Assert.Equal(0, host.Storage.Calls);
    }

    [Theory]
    [InlineData(null, "7", 401)]
    [InlineData("MarketEnforcer", "7", 403)]
    [InlineData("AdminOfficer", "7", 403)]
    [InlineData("HeadAdmin", "7", 403)]
    [InlineData("MarketVendor", null, 401)]
    [InlineData("MarketVendor", "invalid", 401)]
    [InlineData("MarketVendor", "0", 401)]
    [InlineData("MarketVendor", "-1", 401)]
    public async Task InvalidRoleOrClaims_ReturnExpectedStatus(string? role, string? userId, int status)
    {
        await using var host = await VendorTicketHost.CreateAsync();
        using var response = await host.GetAsync("/api/vendor/tickets/101", role, userId);
        Assert.Equal(status, (int)response.StatusCode);
        Assert.Equal(0, host.Storage.Calls);
    }

    [Fact]
    public async Task ExpiredJwt_Returns401()
    {
        await using var host = await VendorTicketHost.CreateAsync();
        using var response = await host.GetAsync("/api/vendor/tickets/101", expired: true);
        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
        Assert.Equal(0, host.Storage.Calls);
    }

    [Fact]
    public async Task Retired_detail_query_has_no_account_join()
    {
        using var context = new AppDbContext(new DbContextOptionsBuilder<AppDbContext>().Options);
        var fixture = new VendorTicketDbSet<MarikinaMarket.API.Domain.Entities.Ticket>(VendorTicketHost.Records());
        context.Tickets = fixture;
        var repository = new TicketRepository(context);
        var method = typeof(TicketRepository).GetMethod("GetVendorTicketDetailAsync");
        Assert.NotNull(method);
        await (Task)method.Invoke(repository, [101, 7])!;
        using var postgres = new AppDbContext(new DbContextOptionsBuilder<AppDbContext>()
            .UseNpgsql("Host=localhost;Database=unused;Username=unused;Password=unused").UseSnakeCaseNamingConvention().Options);
        var expression = new ReplaceReportQueryRoot(fixture.RootExpression,
            ((IQueryable<MarikinaMarket.API.Domain.Entities.Ticket>)postgres.Tickets).Expression).Visit(fixture.State.LastExpression!);
        var sql = ((IQueryable<MarikinaMarket.API.Domain.Entities.Ticket>)postgres.Tickets).Provider.CreateQuery(expression!).ToQueryString();
        Assert.DoesNotContain("user_id", sql);
        Assert.Contains("FALSE", sql, StringComparison.OrdinalIgnoreCase);
        Assert.Contains("penalty_amount", sql);
        Assert.Contains("file_key", sql);
        Assert.Contains("WHERE", sql);
    }
}
