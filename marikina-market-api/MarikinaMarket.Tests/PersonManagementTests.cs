using System.ComponentModel.DataAnnotations;
using System.IdentityModel.Tokens.Jwt;
using System.Net;
using System.Net.Http.Json;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text.Json;
using MarikinaMarket.API.Application;
using MarikinaMarket.API.Application.DTOs.Person.Request;
using MarikinaMarket.API.Application.Interfaces.Repositories;
using MarikinaMarket.API.Application.Services;
using MarikinaMarket.API.Application.Interfaces.Services;
using MarikinaMarket.API.Domain.Entities;
using MarikinaMarket.API.Infrastructure.Json;
using MarikinaMarket.API.Presentation.Controllers;
using MarikinaMarket.API.Presentation.Middleware;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.TestHost;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using Microsoft.IdentityModel.Tokens;
using Xunit;

namespace MarikinaMarket.Tests;

public class PersonManagementTests
{
    [Theory]
    [InlineData("HeadAdmin", 200, 201)]
    [InlineData("AdminOfficer", 200, 201)]
    [InlineData("MarketEnforcer", 200, 403)]
    [InlineData("MarketVendor", 403, 403)]
    [InlineData(null, 401, 401)]
    public async Task Http_roles_enforce_read_create_and_edit(string? role, int read, int write)
    {
        await using var host = await Host.Create();
        Assert.Equal(read, (int)(await host.Send(HttpMethod.Get, "/api/persons", role)).StatusCode);
        Assert.Equal(write, (int)(await host.Send(HttpMethod.Post, "/api/admin/persons", role, ValidBody())).StatusCode);
        var edit = await host.Send(HttpMethod.Put, "/api/admin/persons/1", role, ValidBody());
        Assert.Equal(write == 201 ? 200 : write, (int)edit.StatusCode);
        if (write != 201) Assert.Equal(0, host.Repository.Writes);
    }

    [Fact]
    public async Task Http_contract_location_validation_paging_and_missing_records()
    {
        await using var host = await Host.Create();
        var created = await host.Send(HttpMethod.Post, "/api/admin/persons", "HeadAdmin", ValidBody());
        Assert.Equal(HttpStatusCode.Created, created.StatusCode);
        Assert.EndsWith("/api/persons/1", created.Headers.Location!.ToString());
        var record = await (await host.Send(HttpMethod.Get, "/api/persons/1", "MarketEnforcer")).Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal("E2E Elena Reyes", record.GetProperty("full_name").GetString());
        Assert.Equal(JsonValueKind.Null, record.GetProperty("phone_number").ValueKind);
        Assert.True(record.TryGetProperty("created_at", out _));
        for (var i = 0; i < 10; i++) await host.Send(HttpMethod.Post, "/api/admin/persons", "HeadAdmin", ValidBody());
        var page = await (await host.Send(HttpMethod.Get, "/api/persons?offset=10", "MarketEnforcer")).Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal(11, page.GetProperty("total").GetInt32());
        Assert.Single(page.GetProperty("items").EnumerateArray());
        Assert.False(page.GetProperty("has_more").GetBoolean());
        foreach (var route in new[] { "/api/persons?offset=-1", "/api/persons/0", "/api/persons?search=" + new string('x', 501) })
            Assert.Equal(HttpStatusCode.BadRequest, (await host.Send(HttpMethod.Get, route, "HeadAdmin")).StatusCode);
        Assert.Equal(HttpStatusCode.NotFound, (await host.Send(HttpMethod.Get, "/api/persons/999", "HeadAdmin")).StatusCode);
        Assert.Equal(HttpStatusCode.NotFound, (await host.Send(HttpMethod.Put, "/api/admin/persons/999", "HeadAdmin", ValidBody())).StatusCode);
        Assert.Equal(HttpStatusCode.BadRequest, (await host.Send(HttpMethod.Post, "/api/admin/persons", "HeadAdmin", new { full_name = " ", address = "Market Lane" })).StatusCode);
        Assert.Equal(HttpStatusCode.BadRequest, (await host.Send(HttpMethod.Post, "/api/admin/persons", "HeadAdmin", new { full_name = "Name", address = "Market Lane", phone_number = "invalid" })).StatusCode);
        Assert.Equal(11, host.Repository.Writes);
    }

    private static object ValidBody() => new { full_name = "E2E Elena Reyes", address = "12 Market Lane, Marikina City", phone_number = " " };

    [Fact]
    public async Task Create_trims_fields_and_allows_identical_people_without_accounts()
    {
        var repository = new MemoryRepository();
        var service = new PersonService(repository);
        var first = await service.SaveAsync(null, Request());
        var second = await service.SaveAsync(null, Request());
        Assert.Equal("E2E Elena Reyes", first.FullName);
        Assert.Equal("12 Market Lane, Marikina City", first.Address);
        Assert.Null(first.PhoneNumber);
        Assert.NotEqual(first.Id, second.Id);
        Assert.Equal(2, repository.Records.Count);
        Assert.InRange(first.CreatedAt, DateTime.UtcNow.AddMinutes(-1), DateTime.UtcNow);
    }

    [Fact]
    public async Task Edit_preserves_identity_and_creation_time()
    {
        var repository = new MemoryRepository();
        var service = new PersonService(repository);
        var original = await service.SaveAsync(null, Request());
        var request = Request(); request.FullName = "E2E Elena Santos"; request.PhoneNumber = "09171234567";
        var edited = await service.SaveAsync(original.Id, request);
        Assert.Equal(original.Id, edited.Id);
        Assert.Equal(original.CreatedAt, edited.CreatedAt);
        Assert.Equal("E2E Elena Santos", edited.FullName);
        Assert.Equal("09171234567", edited.PhoneNumber);
        Assert.Single(repository.Records);
    }

    [Theory]
    [InlineData("", "Address", null)]
    [InlineData(" ", "Address", null)]
    [InlineData("Name", " ", null)]
    [InlineData("Name", "Address", "invalid")]
    [InlineData("Name", "Address", "09171234567\n")]
    public async Task Invalid_fields_do_not_write(string name, string address, string? phone)
    {
        var repository = new MemoryRepository();
        await Assert.ThrowsAsync<ValidationException>(() => new PersonService(repository).SaveAsync(null,
            new() { FullName = name, Address = address, PhoneNumber = phone }));
        Assert.Empty(repository.Records);
    }

    [Fact]
    public async Task Length_limits_missing_records_and_invalid_keys_do_not_write()
    {
        var repository = new MemoryRepository(); var service = new PersonService(repository);
        var request = Request(); request.FullName = new string('a', 201);
        await Assert.ThrowsAsync<ValidationException>(() => service.SaveAsync(null, request));
        request = Request(); request.Address = new string('a', 501);
        await Assert.ThrowsAsync<ValidationException>(() => service.SaveAsync(null, request));
        await Assert.ThrowsAsync<RecordNotFoundException>(() => service.SaveAsync(99, Request()));
        await Assert.ThrowsAsync<InvalidRequestException>(() => service.GetAsync(0));
        await Assert.ThrowsAsync<InvalidRequestException>(() => service.SaveAsync(-1, Request()));
        await Assert.ThrowsAsync<ValidationException>(() => service.SearchAsync(new(), -1));
        Assert.Empty(repository.Records);
    }

    private static SavePersonRequest Request() => new()
    { FullName = " E2E Elena Reyes ", Address = " 12 Market Lane, Marikina City ", PhoneNumber = " " };

    // Persistence boundary only; production service validation and mapping execute unchanged.
    private sealed class MemoryRepository : IPersonRepository
    {
        public List<Person> Records { get; } = new();
        public int Writes;
        public Task<Person?> GetAsync(int id) => Task.FromResult(Records.SingleOrDefault(p => p.Id == id));
        public Task<(List<Person> Items, int Total)> MatchAsync(string[] tokens, string? address, string? phone, int offset, int limit)
            => SearchAsync(null, offset, limit);
        public Task AddAsync(Person person) { person.Id = Records.Count + 1; Records.Add(person); return Task.CompletedTask; }
        public Task SaveChangesAsync() { Writes++; return Task.CompletedTask; }
        public Task<(List<Person> Items, int Total)> SearchAsync(string? search, int offset, int limit)
            => Task.FromResult((Records.Skip(offset).Take(limit).ToList(), Records.Count));
    }

    private sealed class Host : IAsyncDisposable
    {
        private WebApplication app = null!;
        private HttpClient client = null!;
        private readonly SymmetricSecurityKey key = new(RandomNumberGenerator.GetBytes(32));
        public MemoryRepository Repository { get; } = new();

        public static async Task<Host> Create()
        {
            var host = new Host(); var builder = WebApplication.CreateBuilder();
            builder.WebHost.UseTestServer(); builder.Logging.ClearProviders();
            builder.Services.AddSingleton<IPersonService>(new PersonService(host.Repository));
            builder.Services.AddTransient<ExceptionHandlingMiddleware>();
            builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme).AddJwtBearer(options =>
                options.TokenValidationParameters = new() {
                    ValidateIssuer = true, ValidIssuer = "person-tests", ValidateAudience = true, ValidAudience = "person-tests",
                    ValidateIssuerSigningKey = true, IssuerSigningKey = host.key, ValidateLifetime = true, ClockSkew = TimeSpan.Zero });
            builder.Services.AddAuthorization();
            builder.Services.AddControllers().AddApplicationPart(typeof(PersonController).Assembly).AddJsonOptions(options =>
                options.JsonSerializerOptions.PropertyNamingPolicy = new SnakeCaseNamingPolicy());
            host.app = builder.Build(); host.app.UseMiddleware<ExceptionHandlingMiddleware>();
            host.app.UseAuthentication(); host.app.UseAuthorization(); host.app.MapControllers();
            await host.app.StartAsync(); host.client = host.app.GetTestClient(); return host;
        }

        public Task<HttpResponseMessage> Send(HttpMethod method, string route, string? role, object? body = null)
        {
            var request = new HttpRequestMessage(method, route);
            if (body is not null) request.Content = JsonContent.Create(body);
            if (role is not null) {
                var token = new JwtSecurityToken("person-tests", "person-tests", [new(ClaimTypes.Role, role)],
                    expires: DateTime.UtcNow.AddMinutes(5), signingCredentials: new(key, SecurityAlgorithms.HmacSha256));
                request.Headers.Authorization = new("Bearer", new JwtSecurityTokenHandler().WriteToken(token));
            }
            return client.SendAsync(request);
        }
        public async ValueTask DisposeAsync() { client.Dispose(); await app.DisposeAsync(); }
    }
}
