using System.Diagnostics;
using System.Net;
using System.Net.Sockets;
using System.Reflection;
using System.Text.Json;
using System.Text.RegularExpressions;
using MailKit.Net.Smtp;
using MarikinaMarket.API.Application.DTOs.Audits.Internal;
using MarikinaMarket.API.Application.Interfaces.Repositories;
using MarikinaMarket.API.Application.Interfaces.Services;
using MarikinaMarket.API.Application.Services;
using MarikinaMarket.API.Domain.Entities;
using MarikinaMarket.API.Domain.Enums;
using MarikinaMarket.API.Infrastructure.Persistence;
using MarikinaMarket.API.Infrastructure.Repositories;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Xunit;

namespace MarikinaMarket.Tests;

public class MobileLoginEmailFailureTests
{
    private const string LoginBody = "{\"username\":\"synthetic-enforcer\",\"password\":\"valid-test-password\"}";
    private const string DeliveryMessage = "Unable to send your sign-in code. Please try again shortly.";

    [Theory]
    [InlineData("socket")]
    [InlineData("io")]
    [InlineData("timeout")]
    [InlineData("cancellation")]
    [InlineData("smtp-command")]
    [InlineData("smtp-protocol")]
    [InlineData("authentication")]
    public async Task Mobile_delivery_failure_is_safe_503_and_invalidates_only_the_failed_code(string failure)
    {
        var fixture = new LoginFixture();
        fixture.Mail.Send = _ => throw DeliveryFailure(failure);
        await using var host = await fixture.HostAsync();
        using var response = await host.SendAsync(HttpMethod.Post, "/api/Auth/login-mobile", null, LoginBody);
        Assert.Equal(HttpStatusCode.ServiceUnavailable, response.StatusCode);
        var body = await response.Content.ReadAsStringAsync();
        Assert.Equal(DeliveryMessage, JsonDocument.Parse(body).RootElement.GetProperty("message").GetString());
        Assert.DoesNotContain("provider-detail", body);
        Assert.DoesNotContain("access_token", body);
        Assert.DoesNotContain("refresh_token", body);
        Assert.True(Assert.Single(fixture.Store.Records).IsUsed);
        Assert.Equal(new[] { 1 }, fixture.Store.InvalidatedIds);
        Assert.Equal(0, fixture.TokensIssued);
        Assert.True(fixture.Mail.LastToken.CanBeCanceled);
        var audit = Assert.Single(host.Repository.Logs);
        Assert.Equal(LogResult.Failed, audit.Result);
        Assert.Equal(8, audit.UserId);
        Assert.DoesNotContain(fixture.Mail.LastCode, JsonSerializer.Serialize(audit));
    }

    [Fact]
    public async Task Failed_delivery_does_not_invalidate_a_newer_concurrent_or_unrelated_code()
    {
        var fixture = new LoginFixture();
        fixture.Mail.Send = _ =>
        {
            fixture.Store.Records.Add(Code(99, 8, OtpPurpose.TwoFactorAuthentication));
            fixture.Store.Records.Add(Code(100, 9, OtpPurpose.TwoFactorAuthentication));
            fixture.Store.Records.Add(Code(101, 8, OtpPurpose.ResetPassword));
            throw new SocketException((int)SocketError.TimedOut);
        };
        await using var host = await fixture.HostAsync();
        using var response = await host.SendAsync(HttpMethod.Post, "/api/Auth/login-mobile", null, LoginBody);
        Assert.Equal(HttpStatusCode.ServiceUnavailable, response.StatusCode);
        Assert.True(fixture.Store.Records.Single(code => code.Id == 1).IsUsed);
        Assert.All(fixture.Store.Records.Where(code => code.Id != 1), code => Assert.False(code.IsUsed));
        Assert.Equal(new[] { 1 }, fixture.Store.InvalidatedIds);
    }

    [Fact]
    public async Task Failure_targets_the_generated_record_even_if_a_newer_code_exists_before_sending()
    {
        var fixture = new LoginFixture();
        fixture.Store.AfterAdd = () => fixture.Store.Records.Add(Code(99, 8, OtpPurpose.TwoFactorAuthentication));
        fixture.Mail.Send = _ => throw new SocketException((int)SocketError.TimedOut);
        await using var host = await fixture.HostAsync();
        using var response = await host.SendAsync(HttpMethod.Post, "/api/Auth/login-mobile", null, LoginBody);
        Assert.Equal(HttpStatusCode.ServiceUnavailable, response.StatusCode);
        Assert.True(fixture.Store.Records.Single(code => code.Id == 1).IsUsed);
        Assert.False(fixture.Store.Records.Single(code => code.Id == 99).IsUsed);
        Assert.Equal(new[] { 1 }, fixture.Store.InvalidatedIds);
    }

    [Theory]
    [InlineData(Role.MarketEnforcer)]
    public async Task Retry_after_failure_sends_a_fresh_code_and_only_verification_issues_tokens(Role role)
    {
        var fixture = new LoginFixture(role);
        fixture.Mail.Send = _ => throw new SocketException((int)SocketError.TimedOut);
        await using var host = await fixture.HostAsync();
        using var failed = await host.SendAsync(HttpMethod.Post, "/api/Auth/login-mobile", null, LoginBody);
        Assert.Equal(HttpStatusCode.ServiceUnavailable, failed.StatusCode);
        var failedCode = fixture.Mail.LastCode;
        using var denied = await host.SendAsync(HttpMethod.Post, "/api/Auth/verify-login-mobile", null, VerifyBody(failedCode));
        Assert.Equal(HttpStatusCode.BadRequest, denied.StatusCode);
        Assert.Equal(0, fixture.TokensIssued);

        fixture.Mail.Send = _ => Task.CompletedTask;
        using var retry = await host.SendAsync(HttpMethod.Post, "/api/Auth/login-mobile", null, LoginBody);
        Assert.Equal(HttpStatusCode.OK, retry.StatusCode);
        using var body = JsonDocument.Parse(await retry.Content.ReadAsStringAsync());
        Assert.Equal("Code sent.", body.RootElement.GetProperty("message").GetString());
        Assert.True(body.RootElement.GetProperty("masked_email").GetString()!.Contains('*'));
        Assert.InRange(body.RootElement.GetProperty("resend_cooldown_seconds").GetInt32(), 28, 30);
        Assert.InRange(body.RootElement.GetProperty("code_expiry_seconds").GetInt32(), 598, 600);
        Assert.Equal(2, fixture.Mail.Calls);
        Assert.Equal(2, Assert.Single(fixture.Store.Records).Id);
        Assert.Equal(0, fixture.TokensIssued);

        using var verified = await host.SendAsync(HttpMethod.Post, "/api/Auth/verify-login-mobile", null, VerifyBody(fixture.Mail.LastCode));
        Assert.Equal(HttpStatusCode.OK, verified.StatusCode);
        Assert.Equal(1, fixture.TokensIssued);
        Assert.True(Assert.Single(fixture.Store.Records).IsUsed);
    }

    [Fact]
    public async Task Successful_mobile_delivery_keeps_the_existing_cooldown_response()
    {
        var fixture = new LoginFixture();
        await using var host = await fixture.HostAsync();
        using var first = await host.SendAsync(HttpMethod.Post, "/api/Auth/login-mobile", null, LoginBody);
        using var second = await host.SendAsync(HttpMethod.Post, "/api/Auth/login-mobile", null, LoginBody);
        Assert.Equal(HttpStatusCode.OK, first.StatusCode);
        Assert.Equal(HttpStatusCode.OK, second.StatusCode);
        Assert.Equal("Code already sent.", JsonDocument.Parse(await second.Content.ReadAsStringAsync()).RootElement.GetProperty("message").GetString());
        Assert.Equal(1, fixture.Mail.Calls);
        Assert.False(Assert.Single(fixture.Store.Records).IsUsed);
        Assert.Equal(0, fixture.TokensIssued);
    }

    [Fact]
    public async Task Mobile_login_cancels_stalled_delivery_after_15_seconds_and_waits_for_it_to_stop()
    {
        var fixture = new LoginFixture();
        var stopped = false;
        fixture.Mail.Send = async cancellationToken =>
        {
            if (!cancellationToken.CanBeCanceled) throw new TimeoutException("Missing mobile cancellation budget.");
            try { await Task.Delay(Timeout.InfiniteTimeSpan, cancellationToken); }
            finally { stopped = true; }
        };
        await using var host = await fixture.HostAsync();
        var timer = Stopwatch.StartNew();
        using var response = await host.SendAsync(HttpMethod.Post, "/api/Auth/login-mobile", null, LoginBody).WaitAsync(TimeSpan.FromSeconds(25));
        Assert.Equal(HttpStatusCode.ServiceUnavailable, response.StatusCode);
        Assert.InRange(timer.Elapsed.TotalSeconds, 14, 25);
        Assert.True(stopped);
        Assert.True(fixture.Mail.LastToken.IsCancellationRequested);
        Assert.True(Assert.Single(fixture.Store.Records).IsUsed);
        Assert.Equal(0, fixture.TokensIssued);
    }

    [Fact]
    public async Task Web_login_preserves_its_existing_email_failure_and_timeout_behavior()
    {
        var fixture = new LoginFixture(Role.AdminOfficer);
        fixture.Mail.Send = _ => throw new SocketException((int)SocketError.TimedOut);
        await using var host = await fixture.HostAsync();
        using var response = await host.SendAsync(HttpMethod.Post, "/api/Auth/login", null, LoginBody);
        Assert.Equal(HttpStatusCode.InternalServerError, response.StatusCode);
        Assert.False(fixture.Mail.LastToken.CanBeCanceled);
        Assert.False(Assert.Single(fixture.Store.Records).IsUsed);
        Assert.Empty(fixture.Store.InvalidatedIds);
        Assert.Equal(0, fixture.TokensIssued);
    }

    [Fact]
    public async Task Actual_email_service_cancels_a_stalled_local_SMTP_connection_and_closes_the_socket()
    {
        var send = typeof(EmailService).GetMethod(nameof(EmailService.SendEmailAsync),
            [typeof(string), typeof(string), typeof(string), typeof(string), typeof(CancellationToken)]);
        Assert.NotNull(send);
        var listener = new TcpListener(IPAddress.Loopback, 0);
        listener.Start();
        try
        {
            await using var host = await AuditHost.CreateAsync();
            using var scope = host.App.Services.CreateScope();
            var config = new ConfigurationBuilder().AddInMemoryCollection(new Dictionary<string, string?>
            {
                ["Email:FromAddress"] = "sender@example.invalid", ["Email:AppPassword"] = "synthetic-password",
                ["Email:SmtpHost"] = "127.0.0.1", ["Email:SmtpPort"] = ((IPEndPoint)listener.LocalEndpoint).Port.ToString()
            }).Build();
            var mail = new EmailService(config, scope.ServiceProvider.GetRequiredService<IAuditLogService>(),
                scope.ServiceProvider.GetRequiredService<AuditLogContext>());
            using var timeout = new CancellationTokenSource(TimeSpan.FromSeconds(1));
            var accepted = listener.AcceptTcpClientAsync();
            var sending = (Task)send.Invoke(mail, ["recipient@example.invalid", "Synthetic test", "No message will be sent.", "#0B2D5B", timeout.Token])!;
            using var peer = await accepted.WaitAsync(TimeSpan.FromSeconds(3));
            await Assert.ThrowsAnyAsync<OperationCanceledException>(() => sending.WaitAsync(TimeSpan.FromSeconds(4)));
            var read = await peer.GetStream().ReadAsync(new byte[1]).AsTask().WaitAsync(TimeSpan.FromSeconds(3));
            Assert.Equal(0, read);
            var audit = Assert.Single(host.Repository.Logs);
            Assert.Equal(LogResult.Failed, audit.Result);
            Assert.DoesNotContain("synthetic-password", JsonSerializer.Serialize(audit));
            Assert.DoesNotContain("recipient@example.invalid", JsonSerializer.Serialize(audit));
        }
        finally { listener.Stop(); }
    }

    [Fact]
    public async Task Production_OTP_repository_invalidates_only_the_requested_row_through_OTP_service()
    {
        var invalidate = typeof(OtpService).GetMethod("InvalidateOtpAsync", [typeof(int)]);
        Assert.NotNull(invalidate);
        var records = new List<OtpVerification> { Code(1, 8, OtpPurpose.TwoFactorAuthentication),
            Code(2, 8, OtpPurpose.TwoFactorAuthentication), Code(3, 9, OtpPurpose.TwoFactorAuthentication),
            Code(4, 8, OtpPurpose.ResetPassword) };
        await using var context = new OtpContext(records);
        var service = new OtpService(new OtpRepository(context), UnitOfWork());
        await (Task)invalidate.Invoke(service, [1])!;
        await (Task)invalidate.Invoke(service, [999])!;
        Assert.True(records[0].IsUsed);
        Assert.All(records.Skip(1), code => Assert.False(code.IsUsed));
    }

    private static Exception DeliveryFailure(string type) => type switch
    {
        "socket" => new SocketException((int)SocketError.TimedOut),
        "io" => new IOException("provider-detail"),
        "timeout" => new TimeoutException("provider-detail"),
        "cancellation" => new OperationCanceledException("provider-detail"),
        "smtp-command" => new SmtpCommandException(SmtpErrorCode.RecipientNotAccepted, SmtpStatusCode.MailboxUnavailable, "provider-detail"),
        "smtp-protocol" => new SmtpProtocolException("provider-detail"),
        "authentication" => new MailKit.Security.AuthenticationException("provider-detail"),
        _ => throw new ArgumentOutOfRangeException(nameof(type))
    };

    private static string VerifyBody(string code) => JsonSerializer.Serialize(new { username = "synthetic-enforcer", password = "valid-test-password", code });
    private static OtpVerification Code(int id, int user, OtpPurpose purpose) => new()
    {
        Id = id, UserId = user, CodeHash = "synthetic-hash", Purpose = purpose,
        CreatedAt = DateTime.UtcNow, ExpiresAt = DateTime.UtcNow.AddMinutes(10)
    };
    private static IUnitOfWork UnitOfWork() => Proxy<IUnitOfWork>((method, _) => method.Name == "SaveChangesAsync" ? Task.FromResult(1) : Task.CompletedTask);
    private static T Proxy<T>(Func<MethodInfo, object?[]?, object?> handler) where T : class
    {
        var proxy = DispatchProxy.Create<T, AuthAuditProxy>();
        ((AuthAuditProxy)(object)proxy).Handler = handler;
        return proxy;
    }

    private sealed class OtpContext : AppDbContext
    {
        public OtpContext(List<OtpVerification> records) : base(new DbContextOptionsBuilder<AppDbContext>().Options)
            => OtpVerifications = new AccountDatabaseSet<OtpVerification>(records);
        public override Task<int> SaveChangesAsync(CancellationToken cancellationToken = default) => Task.FromResult(1);
    }

    private sealed class LoginFixture(Role role = Role.MarketEnforcer)
    {
        public OtpStore Store { get; } = new();
        public MailBoundary Mail { get; } = new();
        public int TokensIssued { get; private set; }
        private readonly User _user = new()
        {
            Id = 8, UserName = "synthetic-enforcer", Email = "synthetic@example.invalid", Status = AccountStatus.Active,
            FirstName = "Synthetic", LastName = "Enforcer", DateOfBirth = new(1995, 1, 1),
            HouseNumber = "12", Street = "Synthetic Street", Barangay = "Sto. Nino", City = "Marikina"
        };
        public Task<AuditHost> HostAsync() => AuditHost.CreateAsync(services =>
        {
            services.AddSingleton(Proxy<IUserRepository>((method, args) => method.Name switch
            {
                "FindByUserNameAsync" => Task.FromResult<User?>(_user),
                "CheckPasswordAsync" => Task.FromResult(SignInResult.Success),
                "GetRoleAsync" => Task.FromResult<Role?>(role),
                "AddRefreshTokenAsync" => Task.FromResult((RefreshToken)args![0]!),
                "SaveChangesAsync" => Task.CompletedTask,
                "GetNamesByIdsAsync" => Task.FromResult(new Dictionary<int, MarikinaMarket.API.Application.DTOs.User.Response.UserNamesResponse>()),
                _ => throw new InvalidOperationException("Unexpected user persistence operation: " + method.Name)
            }));
            services.AddSingleton<IOtpRepository>(Store);
            services.AddSingleton(UnitOfWork());
            services.AddScoped<IOtpService, OtpService>();
            services.AddSingleton<IEmailService>(Mail);
            services.AddSingleton(Proxy<ITokenService>((method, _) => method.Name switch
            {
                "GenerateAccessToken" => Token(),
                "GenerateRefreshToken" => new RefreshToken { UserId = 8, Token = "synthetic-refresh", ExpiresAt = DateTime.UtcNow.AddDays(1) },
                _ => throw new InvalidOperationException("Unexpected token operation: " + method.Name)
            }));
            services.AddScoped<IAuthService, AuthService>();
        });
        private Task<string> Token() { TokensIssued++; return Task.FromResult("synthetic-access"); }
    }

    // Persistence and SMTP are the outer boundaries; AuthService and OtpService run unchanged.
    private sealed class OtpStore : IOtpRepository
    {
        public List<OtpVerification> Records { get; } = [];
        public List<int> InvalidatedIds { get; } = [];
        public Action? AfterAdd { get; set; }
        private int _nextId;
        public Task<OtpVerification> AddOtpAsync(OtpVerification otp) { otp.Id = ++_nextId; Records.Add(otp); AfterAdd?.Invoke(); return Task.FromResult(otp); }
        public Task<OtpVerification?> GetLatestOtpAsync(int userId, OtpPurpose purpose)
            => Task.FromResult(Records.Where(code => code.UserId == userId && code.Purpose == purpose).OrderByDescending(code => code.CreatedAt).ThenByDescending(code => code.Id).FirstOrDefault());
        public Task InvalidatePriorOtpsAsync(int userId, OtpPurpose purpose) { Records.RemoveAll(code => code.UserId == userId && code.Purpose == purpose); return Task.CompletedTask; }
        public Task InvalidateOtpAsync(int otpId) { InvalidatedIds.Add(otpId); var code = Records.SingleOrDefault(code => code.Id == otpId); if (code is not null) code.IsUsed = true; return Task.CompletedTask; }
        public Task<bool> TryUseOtpAsync(int otpId, int maxAttempts)
        {
            var code = Records.Single(item => item.Id == otpId);
            if (code.IsUsed || code.Attempts >= maxAttempts || code.ExpiresAt <= DateTime.UtcNow) return Task.FromResult(false);
            code.IsUsed = true; return Task.FromResult(true);
        }
        public Task IncrementAttemptsAsync(int otpId, int maxAttempts) { Records.Single(code => code.Id == otpId).Attempts++; return Task.CompletedTask; }
        public Task SaveChangesAsync() => Task.CompletedTask;
    }

    private sealed class MailBoundary : IEmailService
    {
        public Func<CancellationToken, Task> Send { get; set; } = _ => Task.CompletedTask;
        public int Calls { get; private set; }
        public CancellationToken LastToken { get; private set; }
        public string LastCode { get; private set; } = "";
        public Task SendEmailAsync(string toEmail, string subject, string body, string accentColor = "#0B2D5B")
            => SendEmailAsync(toEmail, subject, body, accentColor, CancellationToken.None);
        public Task SendEmailAsync(string toEmail, string subject, string body, string accentColor, CancellationToken cancellationToken)
        {
            Calls++; LastToken = cancellationToken;
            LastCode = Regex.Match(body, @">([0-9]{6})</strong>").Groups[1].Value;
            return Send(cancellationToken);
        }
    }
}
