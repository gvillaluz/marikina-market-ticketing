using System.Net;
using System.Reflection;
using System.Text.Json;
using MarikinaMarket.API.Application.DTOs.User.Response;
using MarikinaMarket.API.Application.Interfaces.Repositories;
using MarikinaMarket.API.Application.Interfaces.Services;
using MarikinaMarket.API.Application.Services;
using MarikinaMarket.API.Domain.Entities;
using MarikinaMarket.API.Domain.Enums;
using Microsoft.AspNetCore.Identity;
using Microsoft.Extensions.DependencyInjection;
using Xunit;

namespace MarikinaMarket.Tests;

public class ResetPasswordTests
{
    private const string RuleText = "Use at least 8 characters, with a number and a capital letter.";
    private const string ExpiredText = "Your reset session has expired. Please start again.";

    [Fact]
    public async Task A_password_that_meets_the_rule_is_accepted()
    {
        var fixture = new ResetPasswordFixture();
        await using var host = await fixture.HostAsync();
        var (status, body) = await Reset(host, "Abcdefg1");
        Assert.Equal(HttpStatusCode.OK, status);
        Assert.True(body.GetProperty("success").GetBoolean());
        Assert.Equal("Password reset successfully.", body.GetProperty("message").GetString());
    }

    [Theory]
    [InlineData("abcdefg1")] // no capital letter
    [InlineData("Abcdefgh")] // no number
    [InlineData("Abc1")] // too short
    public async Task A_password_that_breaks_the_rule_is_refused_with_the_rule_text_and_never_reaches_Identity(string password)
    {
        var fixture = new ResetPasswordFixture();
        await using var host = await fixture.HostAsync();
        var response = await host.SendAsync(HttpMethod.Post, "/api/Auth/reset-password", null, RequestBody(password));
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
        Assert.Contains(RuleText, await response.Content.ReadAsStringAsync());
        Assert.DoesNotContain("ResetPasswordByUsernameAsync", fixture.Calls);
    }

    [Fact]
    public async Task A_wrong_or_used_up_reset_token_says_the_reset_session_has_expired()
    {
        var fixture = new ResetPasswordFixture();
        await using var host = await fixture.HostAsync();
        var (status, body) = await Reset(host, "Abcdefg1", "used-up-token");
        Assert.Equal(HttpStatusCode.OK, status);
        Assert.False(body.GetProperty("success").GetBoolean());
        Assert.Equal(ExpiredText, body.GetProperty("message").GetString());
    }

    [Theory]
    [InlineData("PasswordTooShort")]
    [InlineData("PasswordRequiresDigit")]
    [InlineData("PasswordRequiresUpper")]
    public async Task A_password_rule_refusal_from_Identity_says_the_rule(string code)
    {
        var fixture = new ResetPasswordFixture { Refusal = IdentityResult.Failed(new IdentityError { Code = code }) };
        await using var host = await fixture.HostAsync();
        var (status, body) = await Reset(host, "Abcdefg1");
        Assert.Equal(HttpStatusCode.OK, status);
        Assert.False(body.GetProperty("success").GetBoolean());
        Assert.Equal(RuleText, body.GetProperty("message").GetString());
    }

    [Fact]
    public async Task Any_other_refusal_keeps_the_generic_message()
    {
        var fixture = new ResetPasswordFixture { Refusal = IdentityResult.Failed(new IdentityError { Code = "ConcurrencyFailure" }) };
        await using var host = await fixture.HostAsync();
        var (status, body) = await Reset(host, "Abcdefg1");
        Assert.Equal(HttpStatusCode.OK, status);
        Assert.False(body.GetProperty("success").GetBoolean());
        Assert.Equal("Failed to reset password.", body.GetProperty("message").GetString());
    }

    [Fact]
    public async Task An_unknown_username_is_reported_as_not_found()
    {
        var fixture = new ResetPasswordFixture();
        await using var host = await fixture.HostAsync();
        var response = await host.SendAsync(HttpMethod.Post, "/api/Auth/reset-password", null,
            "{\"username\":\"nobody\",\"new_password\":\"Abcdefg1\",\"reset_token\":\"valid-reset-token\"}");
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        using var body = JsonDocument.Parse(await response.Content.ReadAsStringAsync());
        Assert.False(body.RootElement.GetProperty("success").GetBoolean());
        Assert.Equal("User not found.", body.RootElement.GetProperty("message").GetString());
    }

    [Fact]
    public async Task A_successful_reset_clears_the_must_change_password_mark_and_saves_it_in_one_transaction()
    {
        var fixture = new ResetPasswordFixture();
        Assert.True(fixture.User.MustChangePassword);
        await using var host = await fixture.HostAsync();
        var (_, body) = await Reset(host, "Abcdefg1");
        Assert.True(body.GetProperty("success").GetBoolean());
        Assert.False(fixture.User.MustChangePassword);
        Assert.Contains("UpdateUserAsync", fixture.Calls);
        Assert.Equal(["BeginTransactionAsync", "CommitAsync"], fixture.TransactionCalls);
    }

    [Fact]
    public async Task A_refused_reset_leaves_the_must_change_password_mark_alone()
    {
        var fixture = new ResetPasswordFixture();
        await using var host = await fixture.HostAsync();
        var (_, body) = await Reset(host, "Abcdefg1", "used-up-token");
        Assert.False(body.GetProperty("success").GetBoolean());
        Assert.True(fixture.User.MustChangePassword);
        Assert.DoesNotContain("UpdateUserAsync", fixture.Calls);
    }

    private static string RequestBody(string password, string token = "valid-reset-token")
        => "{\"username\":\"user8\",\"new_password\":\"" + password + "\",\"reset_token\":\"" + token + "\"}";

    private static async Task<(HttpStatusCode Status, JsonElement Body)> Reset(AuditHost host, string password,
        string token = "valid-reset-token")
    {
        var response = await host.SendAsync(HttpMethod.Post, "/api/Auth/reset-password", null, RequestBody(password, token));
        var text = await response.Content.ReadAsStringAsync();
        return (response.StatusCode, JsonDocument.Parse(text).RootElement.Clone());
    }
}

internal sealed class ResetPasswordFixture
{
    public User User { get; } = new()
    {
        Id = 8, UserName = "user8", FirstName = "Maria", LastName = "Santos", Email = "user8@example.com",
        DateOfBirth = new(1995, 1, 1), HouseNumber = "12", Street = "Rizal", Barangay = "Sto. Nino", City = "Marikina",
        SecurityStamp = "user-8-stamp", Status = AccountStatus.Active, MustChangePassword = true
    };
    // What Identity answers when the reset token is accepted.
    public IdentityResult Refusal { get; set; } = IdentityResult.Success;
    public List<string> Calls { get; } = [];
    public List<string> TransactionCalls { get; } = [];

    public Task<AuditHost> HostAsync() => AuditHost.CreateAsync(services =>
    {
        services.AddSingleton(Proxy<IUserRepository>((method, args) =>
        {
            Calls.Add(method.Name);
            return method.Name switch
            {
                "FindByUserNameAsync" => Task.FromResult<User?>((string)args![0]! == User.UserName ? User : null),
                "ResetPasswordByUsernameAsync" => Task.FromResult((string)args![1]! == "valid-reset-token"
                    ? Refusal : IdentityResult.Failed(new IdentityError { Code = "InvalidToken" })),
                "UpdateUserAsync" => Task.FromResult(IdentityResult.Success),
                "GetRoleAsync" => Task.FromResult<Role?>(Role.MarketEnforcer),
                "GetNamesByIdsAsync" => Task.FromResult(new Dictionary<int, UserNamesResponse>
                {
                    [8] = new() { Id = 8, FirstName = "Maria", LastName = "Santos" }
                }),
                "SaveChangesAsync" => Task.CompletedTask,
                _ => throw new InvalidOperationException("Unexpected user repository call: " + method.Name)
            };
        }));
        services.AddSingleton(Proxy<IUnitOfWork>((method, args) =>
        {
            if (method.Name is "BeginTransactionAsync" or "CommitAsync" or "RollbackAsync") TransactionCalls.Add(method.Name);
            return method.Name == "SaveChangesAsync" ? Task.FromResult(1) : Task.CompletedTask;
        }));
        services.AddSingleton(Proxy<ITokenService>((method, args) => throw new InvalidOperationException("Unexpected token operation.")));
        services.AddSingleton(Proxy<IOtpService>((method, args) => throw new InvalidOperationException("Unexpected OTP operation.")));
        services.AddScoped<IEmailService>(_ => Proxy<IEmailService>((method, args) => throw new InvalidOperationException("Unexpected email operation.")));
        services.AddScoped<IAuthService, AuthService>();
    });

    private static T Proxy<T>(Func<MethodInfo, object?[]?, object?> handler) where T : class
    {
        var proxy = DispatchProxy.Create<T, AuthAuditProxy>();
        ((AuthAuditProxy)(object)proxy).Handler = handler;
        return proxy;
    }
}
