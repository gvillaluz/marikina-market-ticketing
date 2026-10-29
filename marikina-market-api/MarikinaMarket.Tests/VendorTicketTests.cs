using System.IdentityModel.Tokens.Jwt;
using System.Linq.Expressions;
using System.Net;
using System.Reflection;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text.Json;
using System.Text.Json.Serialization;
using MarikinaMarket.API.Application.Interfaces.Repositories;
using MarikinaMarket.API.Application.DTOs.Tickets.Response;
using MarikinaMarket.API.Application.Interfaces.Services;
using MarikinaMarket.API.Application.Services;
using MarikinaMarket.API.Domain.Entities;
using MarikinaMarket.API.Domain.Enums;
using MarikinaMarket.API.Infrastructure.Json;
using MarikinaMarket.API.Infrastructure.Persistence;
using MarikinaMarket.API.Infrastructure.Repositories;
using MarikinaMarket.API.Presentation.Controllers;
using MarikinaMarket.API.Presentation.Middleware;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.TestHost;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Query;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using Microsoft.IdentityModel.Tokens;
using Xunit;

namespace MarikinaMarket.Tests;

public class VendorTicketTests
{
    private const string Route = "/api/vendor/tickets/inspections";

    [Fact]
    public async Task Former_account_cannot_claim_business_tickets_using_supplied_ids()
    {
        await using var host = await VendorTicketHost.CreateAsync();
        using var response = await host.GetAsync(Route + "?vendor_id=7&user_id=88");
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        using var json = JsonDocument.Parse(await response.Content.ReadAsStringAsync());
        Assert.Equal(0, json.RootElement.GetProperty("total").GetInt32());
        Assert.Empty(json.RootElement.GetProperty("items").EnumerateArray());
        Assert.False(json.RootElement.GetProperty("has_more").GetBoolean());
    }

    [Fact]
    public async Task Pagination_does_not_reveal_business_history_to_former_accounts()
    {
        await using var host = await VendorTicketHost.CreateAsync();
        using var response = await host.GetAsync(Route + "?offset=10");
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        using var json = JsonDocument.Parse(await response.Content.ReadAsStringAsync());
        Assert.Equal(0, json.RootElement.GetProperty("total").GetInt32());
        Assert.Empty(json.RootElement.GetProperty("items").EnumerateArray());
        Assert.False(json.RootElement.GetProperty("has_more").GetBoolean());
    }

    [Theory]
    [InlineData("?type=Warning")]
    [InlineData("?type=Ticket")]
    [InlineData("?search=101")]
    [InlineData("?search=123")]
    [InlineData("?search=%20mArKeT%20identification%20%20")]
    [InlineData("?type=Warning&search=market")]
    [InlineData("?search=missing")]
    public async Task Filters_cannot_recover_tickets_for_an_account_independent_business(
        string query)
    {
        await using var host = await VendorTicketHost.CreateAsync();
        using var response = await host.GetAsync(Route + query);
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        using var json = JsonDocument.Parse(await response.Content.ReadAsStringAsync());
        Assert.Equal(0, json.RootElement.GetProperty("total").GetInt32());
        Assert.Empty(json.RootElement.GetProperty("items").EnumerateArray());
    }

    [Fact]
    public async Task EmptyVendor_ReturnsAnEmptyPage()
    {
        await using var host = await VendorTicketHost.CreateAsync();
        using var response = await host.GetAsync(Route, userId: "999");
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        using var json = JsonDocument.Parse(await response.Content.ReadAsStringAsync());
        Assert.Equal(0, json.RootElement.GetProperty("items").GetArrayLength());
        Assert.Equal(0, json.RootElement.GetProperty("total").GetInt32());
        Assert.False(json.RootElement.GetProperty("has_more").GetBoolean());
    }

    [Fact]
    public async Task Equal_dates_do_not_reveal_business_history_to_former_accounts()
    {
        await using var host = await VendorTicketHost.CreateAsync();
        using var response = await host.GetAsync(Route + "?search=weights");
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        using var json = JsonDocument.Parse(await response.Content.ReadAsStringAsync());
        Assert.Equal(0, json.RootElement.GetProperty("total").GetInt32());
        Assert.Empty(json.RootElement.GetProperty("items").EnumerateArray());
        Assert.False(json.RootElement.GetProperty("has_more").GetBoolean());
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
    [InlineData("MarketVendor", "2147483648", 401)]
    public async Task Authorization_RejectsMissingWrongRoleOrInvalidAccountClaims(string? role, string? userId, int status)
    {
        await using var host = await VendorTicketHost.CreateAsync();
        using var response = await host.GetAsync(Route, role, userId);
        Assert.Equal(status, (int)response.StatusCode);
    }

    [Fact]
    public async Task Authorization_RejectsExpiredJwt()
    {
        await using var host = await VendorTicketHost.CreateAsync();
        using var response = await host.GetAsync(Route, expired: true);
        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Theory]
    [InlineData("?offset=-1")]
    [InlineData("?offset=invalid")]
    [InlineData("?type=Unknown")]
    [InlineData("?type=99")]
    [InlineData("?type=-1")]
    public async Task Validation_RejectsInvalidQueryValues(string query)
    {
        await using var host = await VendorTicketHost.CreateAsync();
        using var response = await host.GetAsync(Route + query);
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task Validation_RejectsSearchLongerThan200Characters()
    {
        await using var host = await VendorTicketHost.CreateAsync();
        using var response = await host.GetAsync(Route + "?search=" + new string('x', 201));
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task RepositoryQuery_TranslatesForPostgresWithoutOpeningAConnection()
    {
        using var context = new AppDbContext(new DbContextOptionsBuilder<AppDbContext>().Options);
        var fixture = new VendorTicketDbSet<Ticket>(VendorTicketHost.Records());
        context.Tickets = fixture;
        var repository = new TicketRepository(context);
        var method = typeof(TicketRepository).GetMethod("GetVendorInspectionsAsync");
        Assert.NotNull(method);
        var filterType = typeof(TicketRepository).Assembly.GetType("MarikinaMarket.API.Application.DTOs.Tickets.Request.VendorInspectionFilters");
        Assert.NotNull(filterType);
        var filters = Activator.CreateInstance(filterType);
        filterType.GetProperty("Search")!.SetValue(filters, "market");
        await (Task)method.Invoke(repository, [7, 0, 10, filters])!;
        using var postgres = new AppDbContext(new DbContextOptionsBuilder<AppDbContext>()
            .UseNpgsql("Host=localhost;Database=unused;Username=unused;Password=unused")
            .UseSnakeCaseNamingConvention().Options);
        var expression = new ReplaceReportQueryRoot(fixture.RootExpression,
            ((IQueryable<Ticket>)postgres.Tickets).Expression).Visit(fixture.State.LastExpression!);
        var sql = ((IQueryable<Ticket>)postgres.Tickets).Provider.CreateQuery(expression!).ToQueryString();
        Assert.DoesNotContain("user_id", sql);
        Assert.Contains("FALSE", sql, StringComparison.OrdinalIgnoreCase);
        Assert.Contains("LIMIT", sql);
        Assert.Contains("OFFSET", sql);
        Assert.Contains("issued_at DESC", sql);
        Assert.Contains("title", sql);
    }

    private static int[] Ids(IEnumerable<JsonElement> items) => items.Select(item => item.GetProperty("ticket_id").GetInt32()).ToArray();
}

internal sealed class VendorTicketHost : IAsyncDisposable
{
    public VendorTicketStorageBoundary Storage { get; private set; } = null!;
    public VendorTicketUnitOfWorkBoundary UnitOfWork { get; private set; } = null!;
    public List<Ticket> Tickets { get; private set; } = [];
    private readonly SymmetricSecurityKey _key = new(RandomNumberGenerator.GetBytes(32));
    private WebApplication _app = null!;
    private HttpClient _client = null!;
    private AppDbContext _context = null!;

    public static async Task<VendorTicketHost> CreateAsync(bool tieDates = false, Action<List<Ticket>>? configureTickets = null)
    {
        var host = new VendorTicketHost();
        host._context = new AppDbContext(new DbContextOptionsBuilder<AppDbContext>().Options);
        host.Tickets = Records(tieDates);
        configureTickets?.Invoke(host.Tickets);
        host._context.Tickets = new VendorTicketDbSet<Ticket>(host.Tickets);
        var builder = WebApplication.CreateBuilder();
        builder.WebHost.UseTestServer();
        builder.Logging.ClearProviders();
        builder.Services.AddSingleton<ITicketRepository>(new TicketRepository(host._context));
        var storage = DispatchProxy.Create<IStorageService, VendorTicketStorageBoundary>();
        host.Storage = (VendorTicketStorageBoundary)(object)storage;
        var unitOfWork = DispatchProxy.Create<IUnitOfWork, VendorTicketUnitOfWorkBoundary>();
        host.UnitOfWork = (VendorTicketUnitOfWorkBoundary)(object)unitOfWork;
        builder.Services.AddSingleton<ITicketService>(services => new TicketService(
            services.GetRequiredService<ITicketRepository>(), null!, null!, unitOfWork, storage, null!, null!));
        builder.Services.AddTransient<ExceptionHandlingMiddleware>();
        builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme).AddJwtBearer(options =>
        {
            options.MapInboundClaims = true;
            options.TokenValidationParameters = new TokenValidationParameters
            {
                ValidateIssuer = true, ValidIssuer = "vendor-tests", ValidateAudience = true, ValidAudience = "vendor-tests",
                ValidateIssuerSigningKey = true, IssuerSigningKey = host._key, ValidateLifetime = true, ClockSkew = TimeSpan.Zero
            };
        });
        builder.Services.AddAuthorization();
        builder.Services.AddControllers().AddApplicationPart(typeof(EnforcerTicketController).Assembly)
            .AddJsonOptions(options =>
            {
                options.JsonSerializerOptions.PropertyNamingPolicy = new SnakeCaseNamingPolicy();
                options.JsonSerializerOptions.Converters.Add(new JsonStringEnumConverter());
            });
        host._app = builder.Build();
        host._app.UseMiddleware<ExceptionHandlingMiddleware>();
        host._app.UseAuthentication();
        host._app.UseAuthorization();
        host._app.MapControllers();
        await host._app.StartAsync();
        host._client = host._app.GetTestClient();
        return host;
    }

    public Task<HttpResponseMessage> GetAsync(string path, string? role = "MarketVendor", string? userId = "7", bool expired = false)
        => SendAsync(HttpMethod.Get, path, role: role, userId: userId, expired: expired);

    public Task<HttpResponseMessage> SendAsync(HttpMethod method, string path, HttpContent? content = null,
        string? role = "MarketVendor", string? userId = "7", bool expired = false)
    {
        var request = new HttpRequestMessage(method, path) { Content = content };
        if (role is not null)
        {
            var claims = new List<Claim> { new(ClaimTypes.Role, role) };
            if (userId is not null) claims.Add(new(JwtRegisteredClaimNames.Sub, userId));
            var jwt = new JwtSecurityToken("vendor-tests", "vendor-tests", claims,
                expires: DateTime.UtcNow.AddMinutes(expired ? -1 : 5),
                signingCredentials: new SigningCredentials(_key, SecurityAlgorithms.HmacSha256));
            request.Headers.Authorization = new("Bearer", new JwtSecurityTokenHandler().WriteToken(jwt));
        }
        return _client.SendAsync(request);
    }

    internal static List<Ticket> Records(bool tieDates = false)
    {
        var vendor = new Business { Id = 70, BusinessAccountNumber = "2026-0001842", BusinessName = "Reyes Fresh Seafood", QrCodeValue = "test-vendor-70" };
        // Vendor ID intentionally equals the authenticated account ID; its owner is someone else.
        var other = new Business { Id = 7, BusinessAccountNumber = "2026-0001905", BusinessName = "Santos Meat Shop", QrCodeValue = "test-vendor-7" };
        vendor.OwnerFirstName = "Juan"; vendor.OwnerLastName = "Reyes";
        other.OwnerFirstName = "Maria"; other.OwnerLastName = "Santos";
        vendor.StallNumber = "F-014";
        other.Type = BusinessType.Private;
        var section = new MarketSection { Id = 1, Name = "Fish and Seafood Section", Description = "Fish vendors" };
        var market = Ordinance(2, "104", "Market Identification Card");
        var posting = Ordinance(3, "123", "Posting of \"Pahihintuloy sa Paghahanapbuhay\"");
        var weights = Ordinance(5, "160", "Weights and Measures");
        var attire = Ordinance(8, "011", "Inadequate Attire in the Market");
        var date = new DateTime(2026, 10, 13, 0, 0, 0, DateTimeKind.Utc);
        var records = Enumerable.Range(1, 12).Select(i => new Ticket
        {
            Id = 100 + i, ControlNumber = (100 + i).ToString(), VendorId = vendor.Id, Vendor = vendor,
            EnforcerId = 12, MarketSectionId = section.Id, MarketSection = section,
            Type = ViolationType.Ticket, Status = TicketStatus.Pending, Description = "Market inspection",
            HighestSeverity = Severity.Minor, PenaltyType = PenaltyType.CashFine, TotalPaymentAmount = i == 1 ? 1000m : 500m,
            Categories = [ViolationCategory.Licensing],
            IssuedAt = date.AddMinutes(tieDates ? 1 : i),
            TicketViolations = new List<TicketViolation> { new() { Id = i, OrdinanceId = i <= 6 ? market.Id : weights.Id, Ordinance = i <= 6 ? market : weights, OffenseCount = 1, PenaltyAmount = 500m } }
        }).ToList();
        records[0].TicketViolations.Add(new() { Id = 30, OrdinanceId = posting.Id, Ordinance = posting, OffenseCount = 1, PenaltyAmount = 500m });
        records[0].TicketEvidences = [new() { FileKey = "tickets/2026/10/101-a.jpg" }, new() { FileKey = "tickets/2026/10/101-b.jpg" }];
        records.Add(new Ticket
        {
            Id = 200, VendorId = vendor.Id, Vendor = vendor, Type = ViolationType.Warning, Description = "Attire warning",
            MarketSectionId = section.Id, MarketSection = section, EnforcerId = 12,
            IssuedAt = date.AddMinutes(13), TicketViolations = [new() { Id = 31, OrdinanceId = attire.Id, Ordinance = attire }]
        });
        records.Add(new Ticket
        {
            Id = 901, ControlNumber = "9101", VendorId = other.Id, Vendor = other, Type = ViolationType.Ticket,
            MarketSectionId = section.Id, MarketSection = section, EnforcerId = 12,
            TicketEvidences = [new() { FileKey = "tickets/private/901.jpg" }],
            Status = TicketStatus.Pending, Description = "Other vendor's inspection", IssuedAt = date.AddMinutes(20),
            TicketViolations = [new() { Id = 32, OrdinanceId = market.Id, Ordinance = market }]
        });
        return records;
    }

    private static Ordinance Ordinance(int id, string number, string title) => new()
    {
        Id = id, OrdinanceNo = number, Series = "2014", MarketCode = "MKT-" + id, Title = title
    };

    public async ValueTask DisposeAsync()
    {
        _client.Dispose();
        await _app.DisposeAsync();
        await _context.DisposeAsync();
    }
}

internal sealed class VendorTicketQueryState
{
    public Expression? LastExpression { get; set; }
}

// Replace only the database boundary; execute the repository's real LINQ and projections.
internal sealed class VendorTicketDbSet<T>(IEnumerable<T> records) : DbSet<T>, IQueryable<T> where T : class
{
    private readonly IQueryable<T> _source = records.AsQueryable();
    public VendorTicketQueryState State { get; } = new();
    public Expression RootExpression => _source.Expression;
    public override Microsoft.EntityFrameworkCore.Metadata.IEntityType EntityType => throw new NotSupportedException();
    Type IQueryable.ElementType => typeof(T);
    Expression IQueryable.Expression => _source.Expression;
    IQueryProvider IQueryable.Provider => new VendorTicketQueryProvider(_source.Provider, State);
    IEnumerator<T> IEnumerable<T>.GetEnumerator() => _source.GetEnumerator();
}

internal sealed class VendorTicketQueryProvider(IQueryProvider inner, VendorTicketQueryState state) : IAsyncQueryProvider
{
    public IQueryable CreateQuery(Expression expression) => throw new NotSupportedException();
    public IQueryable<TElement> CreateQuery<TElement>(Expression expression)
    {
        state.LastExpression = expression;
        return new VendorTicketAsyncQuery<TElement>(expression, state);
    }
    public object? Execute(Expression expression) => inner.Execute(expression);
    public TResult Execute<TResult>(Expression expression) => inner.Execute<TResult>(expression);
    public TResult ExecuteAsync<TResult>(Expression expression, CancellationToken cancellationToken = default)
    {
        cancellationToken.ThrowIfCancellationRequested();
        if (typeof(TResult) == typeof(Task<int>)) return (TResult)(object)Task.FromResult(inner.Execute<int>(expression));
        if (typeof(TResult) == typeof(Task<bool>)) return (TResult)(object)Task.FromResult(inner.Execute<bool>(expression));
        if (typeof(TResult) == typeof(Task<int?>)) return (TResult)(object)Task.FromResult(inner.Execute<int?>(expression));
        if (typeof(TResult) == typeof(Task<Notification>))
            return (TResult)(object)Task.FromResult(inner.Execute<Notification?>(expression));
        if (typeof(TResult) == typeof(Task<VendorRegistrationRequest>))
            return (TResult)(object)Task.FromResult(inner.Execute<VendorRegistrationRequest?>(expression));
        if (typeof(TResult) == typeof(Task<TicketDetailResponse>))
            return (TResult)(object)Task.FromResult(inner.Execute<TicketDetailResponse?>(expression));
        if (typeof(TResult) == typeof(Task<Ticket>))
            return (TResult)(object)Task.FromResult(inner.Execute<Ticket?>(expression));
        throw new NotSupportedException(typeof(TResult).Name);
    }
}

public class VendorTicketStorageBoundary : DispatchProxy
{
    public int Calls { get; private set; }
    public List<string> SignedKeys { get; } = [];
    public List<string> UploadedKeys { get; } = [];
    public static string Signed(string key) => $"https://evidence.example.invalid/{key}?test-signature=valid";

    protected override object? Invoke(MethodInfo? method, object?[]? args)
    {
        if (method!.Name == nameof(IStorageService.UploadEvidenceAsync))
        {
            UploadedKeys.Add((string)args![1]!);
            return Task.FromResult((string)args[1]!);
        }
        Assert.Equal(nameof(IStorageService.GetPresignedUrlsAsync), method!.Name);
        Assert.Equal(B2BucketType.Evidence, args![0]);
        var keys = ((IEnumerable<string>)args[1]!).ToList();
        Calls++;
        SignedKeys.AddRange(keys);
        return Task.FromResult(keys.ToDictionary(key => key, Signed));
    }
}

public class VendorTicketUnitOfWorkBoundary : DispatchProxy
{
    public int SaveCalls { get; private set; }
    protected override object? Invoke(MethodInfo? method, object?[]? args)
    {
        Assert.Equal(nameof(IUnitOfWork.SaveChangesAsync), method!.Name);
        SaveCalls++;
        return Task.FromResult(1);
    }
}

internal sealed class VendorTicketAsyncQuery<T>(Expression expression, VendorTicketQueryState state)
    : EnumerableQuery<T>(expression), IQueryable<T>, IAsyncEnumerable<T>
{
    IQueryProvider IQueryable.Provider => new VendorTicketQueryProvider(
        ((IQueryable<T>)new EnumerableQuery<T>(((IQueryable<T>)this).Expression)).Provider, state);
    public IAsyncEnumerator<T> GetAsyncEnumerator(CancellationToken cancellationToken = default)
        => new ReportTestAsyncEnumerator<T>(this.AsEnumerable().GetEnumerator());
}
