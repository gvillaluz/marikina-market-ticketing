using System.Net;
using System.Text.Json;
using MarikinaMarket.API.Domain.Enums;
using Xunit;

namespace MarikinaMarket.Tests;

public class WebSessionCookieTests
{
    private const string VerificationBody = "{\"username\":\"user8\",\"password\":\"valid-password-123\",\"code\":\"123456\"}";
    private const string ExpectedCookie = "mmt_web_session=opaque-access-token; path=/api/auth; secure; samesite=strict; httponly";

    [Theory]
    [InlineData(Role.AdminOfficer)]
    [InlineData(Role.HeadAdmin)]
    public async Task Website_sign_in_sets_the_hidden_session_cookie_and_still_returns_the_pass(Role role)
    {
        var fixture = new AuthAuditFixture(role);
        await using var host = await fixture.HostAsync();
        var response = await SendAsync(host, "verify-login", body: VerificationBody);
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.Equal(ExpectedCookie, Assert.Single(SetCookies(response)));
        Assert.Equal("opaque-access-token", await AccessToken(response));
    }

    [Fact]
    public async Task Phone_sign_in_sets_no_cookie()
    {
        var fixture = new AuthAuditFixture(Role.MarketEnforcer);
        await using var host = await fixture.HostAsync();
        var response = await SendAsync(host, "verify-login-mobile", body: VerificationBody);
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.Empty(SetCookies(response));
    }

    [Fact]
    public async Task Renewal_uses_the_pass_from_the_cookie_and_updates_the_cookie()
    {
        var fixture = new AuthAuditFixture(Role.AdminOfficer);
        await using var host = await fixture.HostAsync();
        var response = await SendAsync(host, "refresh-web", cookie: "mmt_web_session=pass-from-cookie");
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.Equal(["pass-from-cookie"], fixture.ValidatedTokens);
        Assert.Equal(ExpectedCookie, Assert.Single(SetCookies(response)));
        Assert.Equal("opaque-access-token", await AccessToken(response));
    }

    [Theory]
    [InlineData(Role.AdminOfficer, null, 401)]
    [InlineData(Role.AdminOfficer, "mmt_web_session=", 401)]
    [InlineData(Role.AdminOfficer, "mmt_web_session=expired-token", 401)]
    [InlineData(Role.AdminOfficer, "mmt_web_session=old-password-token", 401)]
    [InlineData(Role.MarketEnforcer, "mmt_web_session=opaque-access-token", 403)]
    public async Task Refused_renewal_deletes_the_cookie_and_issues_no_pass(Role role, string? cookie, int status)
    {
        var fixture = new AuthAuditFixture(role);
        await using var host = await fixture.HostAsync();
        var response = await SendAsync(host, "refresh-web", cookie: cookie);
        Assert.Equal(status, (int)response.StatusCode);
        Assert.Equal(0, fixture.TokensIssued);
        AssertCookieDeleted(response);
    }

    [Theory]
    [InlineData(null)]
    [InlineData("mmt_web_session=opaque-access-token")]
    public async Task Website_sign_out_deletes_the_cookie(string? cookie)
    {
        var fixture = new AuthAuditFixture(Role.AdminOfficer);
        await using var host = await fixture.HostAsync();
        var response = await SendAsync(host, "logout-web", cookie: cookie);
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        AssertCookieDeleted(response);
    }

    private static async Task<HttpResponseMessage> SendAsync(AuditHost host, string route,
        string? cookie = null, string? body = null)
    {
        using var request = new HttpRequestMessage(HttpMethod.Post, "/api/auth/" + route);
        if (cookie is not null) request.Headers.Add("Cookie", cookie);
        if (body is not null) request.Content = new StringContent(body, System.Text.Encoding.UTF8, "application/json");
        return await host.Client.SendAsync(request);
    }

    private static string[] SetCookies(HttpResponseMessage response)
        => response.Headers.TryGetValues("Set-Cookie", out var values) ? values.ToArray() : [];

    private static void AssertCookieDeleted(HttpResponseMessage response)
    {
        var cookie = Assert.Single(SetCookies(response));
        Assert.StartsWith("mmt_web_session=; expires=Thu, 01 Jan 1970 00:00:00 GMT;", cookie);
        Assert.Contains("path=/api/auth", cookie);
    }

    private static async Task<string?> AccessToken(HttpResponseMessage response)
    {
        using var body = JsonDocument.Parse(await response.Content.ReadAsStringAsync());
        return body.RootElement.GetProperty("access_token").GetString();
    }
}
