using System.Net;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text.Json;
using MarikinaMarket.API.Domain.Enums;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.IdentityModel.Tokens;
using Xunit;

namespace MarikinaMarket.Tests;

public class AuditHttpTests
{
    [Theory]
    [InlineData("missing", 401, "Authentication credentials missing.")]
    [InlineData("invalid", 401, "Authentication credentials invalid.")]
    [InlineData("expired", 401, "Authentication token expired.")]
    [InlineData("unsupported", 401, "Authentication required.")]
    [InlineData("forbidden", 403, "Access denied.")]
    public async Task Authorization_details_describe_confirmed_authentication_failure_without_credentials(
        string scenario, int status, string reason)
    {
        var key = new SymmetricSecurityKey(RandomNumberGenerator.GetBytes(64));
        await using var host = await AuditHost.CreateAsync(configureAuthentication: authentication =>
            authentication.AddJwtBearer("Test", options =>
            {
                options.MapInboundClaims = false;
                options.TokenValidationParameters = new TokenValidationParameters
                {
                    ValidateIssuer = true, ValidIssuer = "audit-tests",
                    ValidateAudience = true, ValidAudience = "audit-tests",
                    ValidateLifetime = true, ClockSkew = TimeSpan.Zero,
                    ValidateIssuerSigningKey = true, IssuerSigningKey = key,
                    RoleClaimType = "role"
                };
            }));
        var now = DateTime.UtcNow;
        var signingKey = scenario == "invalid"
            ? new SymmetricSecurityKey(RandomNumberGenerator.GetBytes(64)) : key;
        var token = new JwtSecurityTokenHandler().WriteToken(new JwtSecurityToken(
            "audit-tests", "audit-tests",
            [new Claim(ClaimTypes.NameIdentifier, "7"), new Claim("role", "MarketVendor")],
            now.AddMinutes(-10), scenario == "expired" ? now.AddMinutes(-5) : now.AddMinutes(5),
            new SigningCredentials(signingKey, SecurityAlgorithms.HmacSha256)));
        using var request = new HttpRequestMessage(HttpMethod.Get, "/api/admin/audit-logs?search=private-query");
        if (scenario != "missing")
            request.Headers.Authorization = new(scenario == "unsupported" ? "Basic" : "Bearer", token);
        using var response = await host.Client.SendAsync(request);
        Assert.Equal(status, (int)response.StatusCode);
        var log = Assert.Single(host.Repository.Logs);
        Assert.Equal("AuthorizationFailed", log.Action);
        Assert.Equal(Module.Security, log.Module);
        Assert.Equal(LogResult.Failed, log.Result);
        Assert.Equal(scenario == "forbidden" ? 7 : (int?)null, log.UserId);
        Assert.Equal(scenario == "forbidden" ? Role.MarketVendor : (Role?)null, log.Role);
        Assert.Contains($"HTTP {status}", log.Details);
        Assert.Contains($"Reason: {reason}", log.Details);
        Assert.Contains($"Authenticated: {(scenario == "forbidden" ? "yes" : "no")}", log.Details);
        Assert.Contains("GET", log.Details);
        Assert.Contains("Route: api/admin/audit-logs", log.Details);
        Assert.Contains("Endpoint: AdminAuditLog.GetSummaries", log.Details);
        Assert.Contains("Requested module: AuditLogs", log.Details);
        Assert.Contains("Declared roles: HeadAdmin or AdminOfficer", log.Details);
        Assert.Matches(@"Request ID: \S+", log.Details);
        Assert.InRange(log.Details.Length, 1, 500);
        Assert.DoesNotContain(token, log.Details);
        Assert.DoesNotContain("private-query", log.Details);
        Assert.DoesNotContain("IDX", log.Details);
        Assert.DoesNotContain("SecurityToken", log.Details);
    }

    [Fact]
    public async Task Authorization_details_do_not_guess_a_credential_reason_for_other_authentication_failures()
    {
        await using var host = await AuditHost.CreateAsync();
        host.Client.DefaultRequestHeaders.Add("X-Test-Authentication-Failure", "unavailable");
        using var response = await host.Client.GetAsync("/api/admin/audit-logs");
        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
        var log = Assert.Single(host.Repository.Logs);
        Assert.Null(log.UserId);
        Assert.Null(log.Role);
        Assert.Contains("Reason: Authentication failed.", log.Details);
        Assert.DoesNotContain("credentials invalid", log.Details);
        Assert.DoesNotContain("private-authentication-message", log.Details);
        Assert.DoesNotContain("InvalidOperationException", log.Details);
    }

    [Fact]
    public async Task Authorization_details_preserve_separate_declared_role_requirements()
    {
        await using var host = await AuditHost.CreateAsync();
        using var response = await host.SendAsync(HttpMethod.Get, "/api/audit-probe/role-groups", "AdminOfficer");
        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
        var log = Assert.Single(host.Repository.Logs);
        Assert.Equal(7, log.UserId);
        Assert.Equal(Role.AdminOfficer, log.Role);
        Assert.Contains("Declared roles: (HeadAdmin or AdminOfficer) and (HeadAdmin or MarketEnforcer)", log.Details);
    }

    [Fact]
    public async Task Authorization_details_use_route_templates_bound_metadata_and_preserve_verified_actor()
    {
        await using var host = await AuditHost.CreateAsync();
        using var request = new HttpRequestMessage(HttpMethod.Post,
            "/api/audit-probe/denied/private-path-value?password=private-query-value");
        request.Headers.Add("X-Test-Role", "HeadAdmin");
        request.Headers.Authorization = new("Bearer", "private-header-value");
        request.Content = new StringContent("{\"password\":\"private-body-value\"}",
            System.Text.Encoding.UTF8, "application/json");
        using var response = await host.Client.SendAsync(request);
        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
        var log = Assert.Single(host.Repository.Logs);
        Assert.Equal(7, log.UserId);
        Assert.Equal(Role.HeadAdmin, log.Role);
        Assert.Null(log.TargetId);
        Assert.Contains("Reason: Access denied.", log.Details);
        Assert.Contains("Authenticated: yes", log.Details);
        Assert.Contains("POST", log.Details);
        Assert.Contains("Route: api/audit-probe/denied/{target}", log.Details);
        Assert.Contains("Endpoint: AuditProbe.Denied", log.Details);
        Assert.Contains("Requested module: Reports", log.Details);
        Assert.Contains("Declared roles: HeadAdmin or AdminOfficer", log.Details);
        Assert.Contains("Request ID: " + new string('x', 47) + "…", log.Details);
        Assert.InRange(log.Details.Length, 1, 500);
        Assert.DoesNotContain("private-", JsonSerializer.Serialize(log));
        Assert.DoesNotContain(new string('x', 49), log.Details);
        using var detailResponse = await host.SendAsync(HttpMethod.Get, $"/api/admin/audit-logs/{log.Id}");
        Assert.Equal(HttpStatusCode.OK, detailResponse.StatusCode);
        using var detail = JsonDocument.Parse(await detailResponse.Content.ReadAsStringAsync());
        Assert.Equal(log.Details, detail.RootElement.GetProperty("details").GetString());
        Assert.Single(host.Repository.Logs);
    }

    [Theory]
    [InlineData("HeadAdmin")]
    [InlineData("AdminOfficer")]
    public async Task Mutation_records_verified_actor_and_generated_target_without_request_secrets(string role)
    {
        await using var host = await AuditHost.CreateAsync();
        var response = await host.SendAsync(HttpMethod.Post, "/api/audit-probe/mutate", role,
            "{\"name\":\"updated\",\"user_id\":999,\"role\":\"MarketVendor\",\"password\":\"secret-password\"}");
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var log = Assert.Single(host.Repository.Logs);
        Assert.Equal(7, log.UserId);
        Assert.Equal(Enum.Parse<Role>(role), log.Role);
        Assert.Equal("42", log.TargetId);
        Assert.Equal(LogResult.Success, log.Result);
        Assert.Equal(DateTimeKind.Utc, log.Timestamp.Kind);
        Assert.DoesNotContain("secret-password", log.Details);
        Assert.DoesNotContain("999", log.Details);
    }

    [Theory]
    [InlineData("GET", "/api/audit-probe/read")]
    [InlineData("POST", "/api/audit-probe/read-only")]
    [InlineData("GET", "/api/admin/audit-logs")]
    [InlineData("GET", "/api/admin/audit-logs/counts")]
    public async Task Successful_reads_do_not_create_audit_records(string method, string route)
    {
        await using var host = await AuditHost.CreateAsync();
        var response = await host.SendAsync(new HttpMethod(method), route);
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.Empty(host.Repository.Logs);
    }

    [Theory]
    [InlineData(null, 401)]
    [InlineData("MarketVendor", 403)]
    [InlineData("MarketEnforcer", 403)]
    public async Task Authorization_failures_are_logged_even_on_read_endpoints(string? role, int status)
    {
        await using var host = await AuditHost.CreateAsync();
        var response = await host.SendAsync(HttpMethod.Get, "/api/admin/audit-logs", role);
        Assert.Equal(status, (int)response.StatusCode);
        var log = Assert.Single(host.Repository.Logs);
        Assert.Equal("AuthorizationFailed", log.Action);
        Assert.Equal(Module.Security, log.Module);
        Assert.Equal(LogResult.Failed, log.Result);
        Assert.Equal(role is null ? null : 7, log.UserId);
        Assert.Contains("was denied", log.Details);
    }

    [Theory]
    [InlineData("/api/audit-probe/mutate", "{\"name\":\"\"}")]
    [InlineData("/api/audit-probe/mutate", "not-json")]
    [InlineData("/api/audit-probe/validation-exception", null)]
    public async Task Validation_failures_are_excluded(string route, string? body)
    {
        await using var host = await AuditHost.CreateAsync();
        var response = await host.SendAsync(HttpMethod.Post, route, body: body);
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
        Assert.Empty(host.Repository.Logs);
    }

    [Theory]
    [InlineData("business-failure", 400)]
    [InlineData("business-failure-200", 200)]
    [InlineData("password-failure", 400)]
    [InlineData("unexpected-error", 500)]
    public async Task Business_failures_are_logged_without_exception_or_response_secrets(string action, int status)
    {
        await using var host = await AuditHost.CreateAsync();
        var response = await host.SendAsync(HttpMethod.Post, "/api/audit-probe/" + action);
        Assert.Equal(status, (int)response.StatusCode);
        var log = Assert.Single(host.Repository.Logs);
        Assert.Equal(LogResult.Failed, log.Result);
        Assert.DoesNotContain("sensitive", JsonSerializer.Serialize(log));
    }

    [Fact]
    public async Task Audit_outage_does_not_change_a_successful_operation_response()
    {
        await using var host = await AuditHost.CreateAsync();
        host.Repository.FailWrites = true;
        var response = await host.SendAsync(HttpMethod.Post, "/api/audit-probe/mutate", body: "{\"name\":\"updated\"}");
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.Empty(host.Repository.Logs);
    }

    [Fact]
    public async Task Empty_success_response_is_logged()
    {
        await using var host = await AuditHost.CreateAsync();
        var response = await host.SendAsync(HttpMethod.Post, "/api/audit-probe/no-content");
        Assert.Equal(HttpStatusCode.NoContent, response.StatusCode);
        Assert.Equal(LogResult.Success, Assert.Single(host.Repository.Logs).Result);
    }

    [Fact]
    public async Task Committed_mutation_is_not_logged_twice_by_request_capture()
    {
        await using var host = await AuditHost.CreateAsync();
        var response = await host.SendAsync(HttpMethod.Post, "/api/audit-probe/committed");
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.Equal("42", Assert.Single(host.Repository.Logs).TargetId);
    }

    [Fact]
    public async Task Failure_after_commit_is_distinguished_from_the_successful_mutation()
    {
        await using var host = await AuditHost.CreateAsync();
        var response = await host.SendAsync(HttpMethod.Post, "/api/audit-probe/after-commit-error");
        Assert.Equal(HttpStatusCode.InternalServerError, response.StatusCode);
        Assert.Equal(2, host.Repository.Logs.Count);
        Assert.Equal(LogResult.Success, host.Repository.Logs[0].Result);
        Assert.Equal("RequestFailedAfterCommit", host.Repository.Logs[1].Action);
        Assert.Equal(LogResult.Failed, host.Repository.Logs[1].Result);
        Assert.DoesNotContain("sensitive", JsonSerializer.Serialize(host.Repository.Logs));
    }

    [Fact]
    public async Task Summary_and_detail_endpoints_return_stored_data_without_recursive_logging()
    {
        await using var host = await AuditHost.CreateAsync();
        await host.SendAsync(HttpMethod.Post, "/api/audit-probe/mutate", body: "{\"name\":\"updated\"}");
        var summary = await host.SendAsync(HttpMethod.Get, "/api/admin/audit-logs?offset=0&module=Reports&result=Success&userId=7");
        using var page = JsonDocument.Parse(await summary.Content.ReadAsStringAsync());
        Assert.Equal(HttpStatusCode.OK, summary.StatusCode);
        Assert.Equal(1, page.RootElement.GetProperty("total").GetInt32());
        Assert.False(page.RootElement.GetProperty("has_more").GetBoolean());
        var item = page.RootElement.GetProperty("items")[0];
        Assert.Equal("Mutate", item.GetProperty("action").GetString());
        Assert.Equal("Juan", item.GetProperty("first_name").GetString());
        Assert.Equal("Dela Cruz", item.GetProperty("last_name").GetString());
        Assert.False(item.TryGetProperty("details", out _));
        var detail = await host.SendAsync(HttpMethod.Get, "/api/admin/audit-logs/1");
        using var data = JsonDocument.Parse(await detail.Content.ReadAsStringAsync());
        Assert.Equal("42", data.RootElement.GetProperty("target_id").GetString());
        Assert.Equal("Juan", data.RootElement.GetProperty("first_name").GetString());
        Assert.Equal("Dela Cruz", data.RootElement.GetProperty("last_name").GetString());
        Assert.Contains("completed successfully", data.RootElement.GetProperty("details").GetString());
        Assert.Single(host.Repository.Logs);
    }

    [Fact]
    public async Task Configuration_history_filters_before_paging_and_keeps_failed_and_system_events_in_order()
    {
        await using var host = await AuditHost.CreateAsync();
        var timestamp = new DateTime(2026, 10, 21, 1, 0, 0, DateTimeKind.Utc);
        var modules = new[] { Module.MarketSections, Module.Ordinances, Module.Backups, Module.Users,
            Module.Security, Module.Vendors, Module.Tickets, Module.Reports, Module.Notifications, Module.AuditLogs };
        for (var id = 1; id <= 30; id++)
        {
            host.Repository.Logs.Add(new()
            {
                Id = id, Timestamp = timestamp, Module = modules[(id - 1) % modules.Length],
                UserId = id % 10 == 3 ? null : 7, Role = id % 10 == 3 ? null : Role.HeadAdmin,
                Action = "Update", Result = id % 10 == 2 ? LogResult.Failed : LogResult.Success,
                Details = "Synthetic configuration history."
            });
        }
        // More than one page of newer, unrelated events must not displace matching entries.
        for (var id = 31; id <= 45; id++)
            host.Repository.Logs.Add(new()
            {
                Id = id, Timestamp = timestamp.AddMinutes(1), Module = Module.Users,
                UserId = 7, Role = Role.HeadAdmin, Action = "Update", Result = LogResult.Success,
                Details = "Synthetic account history."
            });
        const string filters = "modules=MarketSections&modules=Ordinances&modules=Backups";
        foreach (var role in new[] { "HeadAdmin", "AdminOfficer" })
        {
            var response = await host.SendAsync(HttpMethod.Get, "/api/admin/audit-logs?offset=0&" + filters, role);
            Assert.Equal(HttpStatusCode.OK, response.StatusCode);
            using var page = JsonDocument.Parse(await response.Content.ReadAsStringAsync());
            Assert.Equal(9, page.RootElement.GetProperty("total").GetInt32());
            Assert.False(page.RootElement.GetProperty("has_more").GetBoolean());
            var items = page.RootElement.GetProperty("items").EnumerateArray().ToArray();
            Assert.Equal(new[] { 23, 22, 21, 13, 12, 11, 3, 2, 1 }, items.Select(x => x.GetProperty("id").GetInt32()));
            Assert.Equal("Backups", items[0].GetProperty("module").GetString());
            Assert.Equal(JsonValueKind.Null, items[0].GetProperty("user_id").ValueKind);
            Assert.Equal("Failed", items[1].GetProperty("result").GetString());
            Assert.Equal("Juan", items[1].GetProperty("first_name").GetString());
            Assert.Equal("Dela Cruz", items[1].GetProperty("last_name").GetString());
            var counts = await host.SendAsync(HttpMethod.Get, "/api/admin/audit-logs/counts?" + filters, role);
            using var totals = JsonDocument.Parse(await counts.Content.ReadAsStringAsync());
            Assert.Equal(9, totals.RootElement.GetProperty("recorded_activities").GetInt32());
            Assert.Equal(6, totals.RootElement.GetProperty("successful_actions").GetInt32());
            Assert.Equal(0, totals.RootElement.GetProperty("security_events").GetInt32());
        }
        Assert.Equal(45, host.Repository.Logs.Count);
    }

    [Fact]
    public async Task System_and_deleted_actor_names_are_null_in_summary_and_detail_JSON()
    {
        await using var host = await AuditHost.CreateAsync();
        await host.SendAsync(HttpMethod.Post, "/api/audit-probe/mutate", body: "{\"name\":\"updated\"}");
        ((AuditUserRepositoryStub)(object)host.Users).Users.Remove(7);
        var summary = await host.SendAsync(HttpMethod.Get, "/api/admin/audit-logs");
        using var page = JsonDocument.Parse(await summary.Content.ReadAsStringAsync());
        var item = page.RootElement.GetProperty("items")[0];
        Assert.Equal(7, item.GetProperty("user_id").GetInt32());
        Assert.Equal("HeadAdmin", item.GetProperty("role").GetString());
        Assert.Equal(JsonValueKind.Null, item.GetProperty("first_name").ValueKind);
        Assert.Equal(JsonValueKind.Null, item.GetProperty("last_name").ValueKind);
        host.Repository.Logs[0].UserId = null;
        host.Repository.Logs[0].Role = null;
        var detail = await host.SendAsync(HttpMethod.Get, "/api/admin/audit-logs/1");
        using var data = JsonDocument.Parse(await detail.Content.ReadAsStringAsync());
        Assert.Equal(JsonValueKind.Null, data.RootElement.GetProperty("user_id").ValueKind);
        Assert.Equal(JsonValueKind.Null, data.RootElement.GetProperty("first_name").ValueKind);
        Assert.Equal(JsonValueKind.Null, data.RootElement.GetProperty("last_name").ValueKind);
        Assert.Single(host.Repository.Logs);
    }

    [Theory]
    [InlineData("HeadAdmin")]
    [InlineData("AdminOfficer")]
    public async Task Counts_return_all_activity_success_and_security_totals_without_logging_the_read(string role)
    {
        await using var host = await AuditHost.CreateAsync();
        await host.SendAsync(HttpMethod.Post, "/api/audit-probe/mutate", body: "{\"name\":\"updated\"}");
        await host.SendAsync(HttpMethod.Post, "/api/audit-probe/business-failure");
        await host.SendAsync(HttpMethod.Get, "/api/admin/audit-logs", "MarketVendor");
        var response = await host.SendAsync(HttpMethod.Get, "/api/admin/audit-logs/counts", role);
        using var json = JsonDocument.Parse(await response.Content.ReadAsStringAsync());
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.Equal(3, json.RootElement.GetProperty("recorded_activities").GetInt32());
        Assert.Equal(1, json.RootElement.GetProperty("successful_actions").GetInt32());
        Assert.Equal(1, json.RootElement.GetProperty("security_events").GetInt32());
        Assert.Equal(3, host.Repository.Logs.Count);
        var filtered = await host.SendAsync(HttpMethod.Get, "/api/admin/audit-logs/counts?module=Security&result=Failed", role);
        using var selected = JsonDocument.Parse(await filtered.Content.ReadAsStringAsync());
        Assert.Equal(1, selected.RootElement.GetProperty("recorded_activities").GetInt32());
        Assert.Equal(0, selected.RootElement.GetProperty("successful_actions").GetInt32());
        Assert.Equal(1, selected.RootElement.GetProperty("security_events").GetInt32());
        Assert.Equal(3, host.Repository.Logs.Count);
    }

    [Theory]
    [InlineData(null, 401)]
    [InlineData("MarketVendor", 403)]
    [InlineData("MarketEnforcer", 403)]
    public async Task Counts_enforce_admin_authorization_and_audit_denied_access(string? role, int status)
    {
        await using var host = await AuditHost.CreateAsync();
        var response = await host.SendAsync(HttpMethod.Get, "/api/admin/audit-logs/counts", role);
        Assert.Equal(status, (int)response.StatusCode);
        Assert.Equal("AuthorizationFailed", Assert.Single(host.Repository.Logs).Action);
    }

    [Fact]
    public async Task Counts_return_zero_for_an_empty_table()
    {
        await using var host = await AuditHost.CreateAsync();
        var response = await host.SendAsync(HttpMethod.Get, "/api/admin/audit-logs/counts");
        using var json = JsonDocument.Parse(await response.Content.ReadAsStringAsync());
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.Equal(0, json.RootElement.GetProperty("recorded_activities").GetInt32());
        Assert.Equal(0, json.RootElement.GetProperty("successful_actions").GetInt32());
        Assert.Equal(0, json.RootElement.GetProperty("security_events").GetInt32());
        Assert.Empty(host.Repository.Logs);
    }

    [Fact]
    public async Task Table_and_counts_accept_repeated_selections_and_date_presets()
    {
        await using var host = await AuditHost.CreateAsync();
        await host.SendAsync(HttpMethod.Post, "/api/audit-probe/mutate", body: "{\"name\":\"updated\"}");
        await host.SendAsync(HttpMethod.Post, "/api/audit-probe/business-failure");
        await host.SendAsync(HttpMethod.Get, "/api/admin/audit-logs", "MarketVendor");
        const string filters = "modules=Reports&modules=Security&results=Success&results=Failed&dateRange=Last7Days";
        var response = await host.SendAsync(HttpMethod.Get, "/api/admin/audit-logs?offset=0&" + filters);
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        using var page = JsonDocument.Parse(await response.Content.ReadAsStringAsync());
        Assert.Equal(3, page.RootElement.GetProperty("total").GetInt32());
        Assert.Equal(3, page.RootElement.GetProperty("items").GetArrayLength());
        Assert.False(page.RootElement.GetProperty("has_more").GetBoolean());
        var counts = await host.SendAsync(HttpMethod.Get, "/api/admin/audit-logs/counts?" + filters);
        Assert.Equal(HttpStatusCode.OK, counts.StatusCode);
        using var data = JsonDocument.Parse(await counts.Content.ReadAsStringAsync());
        Assert.Equal(3, data.RootElement.GetProperty("recorded_activities").GetInt32());
        Assert.Equal(1, data.RootElement.GetProperty("successful_actions").GetInt32());
        Assert.Equal(1, data.RootElement.GetProperty("security_events").GetInt32());
        Assert.Equal(3, host.Repository.Logs.Count);
        var searched = await host.SendAsync(HttpMethod.Get, "/api/admin/audit-logs?" + filters + "&search=denied");
        using var searchPage = JsonDocument.Parse(await searched.Content.ReadAsStringAsync());
        Assert.Equal(1, searchPage.RootElement.GetProperty("total").GetInt32());
    }

    [Theory]
    [InlineData("/api/admin/audit-logs?offset=-1", 400)]
    [InlineData("/api/admin/audit-logs?module=999", 400)]
    [InlineData("/api/admin/audit-logs?fromDate=2026-10-11&toDate=2026-10-10", 400)]
    [InlineData("/api/admin/audit-logs/0", 400)]
    [InlineData("/api/admin/audit-logs/999", 404)]
    [InlineData("/api/admin/audit-logs/counts?module=999", 400)]
    [InlineData("/api/admin/audit-logs/counts?userId=0", 400)]
    [InlineData("/api/admin/audit-logs/counts?fromDate=2026-10-11&toDate=2026-10-10", 400)]
    [InlineData("/api/admin/audit-logs?dateRange=Custom", 400)]
    [InlineData("/api/admin/audit-logs?dateRange=999", 400)]
    [InlineData("/api/admin/audit-logs?modules=Users&modules=999", 400)]
    [InlineData("/api/admin/audit-logs?results=Unknown", 400)]
    [InlineData("/api/admin/audit-logs?module=Users&modules=Security", 400)]
    [InlineData("/api/admin/audit-logs?dateRange=Last7Days&fromDate=2026-10-10", 400)]
    [InlineData("/api/admin/audit-logs/counts?dateRange=Custom", 400)]
    [InlineData("/api/admin/audit-logs/counts?results=Failed&result=Success", 400)]
    public async Task Read_endpoints_validate_filters_and_missing_records(string route, int status)
    {
        await using var host = await AuditHost.CreateAsync();
        var response = await host.SendAsync(HttpMethod.Get, route);
        Assert.Equal(status, (int)response.StatusCode);
        Assert.Empty(host.Repository.Logs);
    }
}
