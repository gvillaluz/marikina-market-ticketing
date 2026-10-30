using System.Net;
using System.Net.Http.Headers;
using System.Text.Json;
using MarikinaMarket.API.Domain.Entities;
using MarikinaMarket.API.Domain.Enums;
using MarikinaMarket.API.Infrastructure.Persistence;
using MarikinaMarket.API.Infrastructure.Repositories;
using Microsoft.EntityFrameworkCore;
using Xunit;

namespace MarikinaMarket.Tests;

public class VendorSettlementTests
{
    private const string Receipt = "/api/vendor/tickets/101/settlement/receipt";
    private const string Community = "/api/vendor/tickets/101/settlement/community-service";

    [Theory]
    [InlineData(PenaltyType.CashFine)]
    [InlineData(PenaltyType.BloodDonation)]
    public async Task Settlement_receipt_rejects_changed_image_for_used_submission_id(PenaltyType penalty)
    {
        await using var host = await VendorTicketHost.CreateAsync(configureTickets: tickets => tickets[0].PenaltyType = penalty);
        var id = Guid.NewGuid().ToString();
        foreach (var (filename, mime, expected) in new[]
        {
            ("proof.png", "image/png", HttpStatusCode.OK),
            ("proof.jpg", "image/jpeg", HttpStatusCode.Conflict)
        })
        {
            using var form = Proof(filename, mime, submissionId: id);
            using var response = await host.SendAsync(HttpMethod.Post,
                "/api/enforcer/tickets/101/settlement/receipt", form, "MarketEnforcer", "12");
            Assert.Equal(expected, response.StatusCode);
        }
        Assert.Single(host.Tickets[0].ProofUrls!);
        Assert.Single(host.Storage.UploadedKeys);
    }

    [Fact]
    public void Settlement_model_matches_checked_in_snapshot()
    {
        using var context = new AppDbContext(new DbContextOptionsBuilder<AppDbContext>()
            .UseNpgsql("Host=localhost;Database=unused;Username=unused;Password=unused")
            .UseSnakeCaseNamingConvention().Options);
        var snapshot = Microsoft.EntityFrameworkCore.Infrastructure.AccessorExtensions.GetService<Microsoft.EntityFrameworkCore.Migrations.IMigrationsAssembly>(context).ModelSnapshot!.Model;
        var initialized = Microsoft.EntityFrameworkCore.Infrastructure.AccessorExtensions.GetService<Microsoft.EntityFrameworkCore.Infrastructure.IModelRuntimeInitializer>(context).Initialize(snapshot, designTime: true);
        var current = Microsoft.EntityFrameworkCore.Infrastructure.AccessorExtensions.GetService<Microsoft.EntityFrameworkCore.Metadata.IDesignTimeModel>(context).Model;
        var differences = Microsoft.EntityFrameworkCore.Infrastructure.AccessorExtensions.GetService<Microsoft.EntityFrameworkCore.Migrations.IMigrationsModelDiffer>(context)
            .GetDifferences(initialized.GetRelationalModel(), current.GetRelationalModel());
        Assert.True(differences.Count == 0, string.Join("\n", differences.Select(operation => JsonSerializer.Serialize(operation, operation.GetType()))));
    }

    [Fact]
    public async Task Settlement_service_rejects_changed_payload_for_used_id_but_allows_new_identical_entry()
    {
        await using var host = await VendorTicketHost.CreateAsync(configureTickets: tickets =>
        {
            tickets[0].PenaltyType = PenaltyType.CommunityService;
            tickets[0].CommunityServiceHours = 8;
        });
        var id = Guid.NewGuid().ToString();
        foreach (var (submission, hours, expected) in new[]
        {
            (id, "1", HttpStatusCode.OK),
            (id, "2", HttpStatusCode.Conflict),
            (Guid.NewGuid().ToString(), "1", HttpStatusCode.OK)
        })
        {
            using var form = Proof("proof.png", "image/png", submissionId: submission);
            form.Add(new StringContent("2026-10-01"), "service_date");
            form.Add(new StringContent(hours), "hours_worked");
            using var response = await host.SendAsync(HttpMethod.Post,
                "/api/enforcer/tickets/101/settlement/community-service", form, "MarketEnforcer", "12");
            Assert.Equal(expected, response.StatusCode);
        }
        Assert.Equal(2, host.Tickets[0].CommunityServiceLogs.Count);
        Assert.Equal(2m, host.Tickets[0].CommunityServiceLogs.Sum(log => log.HoursWorked));
        Assert.Equal(2, host.Storage.UploadedKeys.Count);
    }

    [Theory]
    [InlineData(PenaltyType.CashFine)]
    [InlineData(PenaltyType.BloodDonation)]
    public async Task Settlement_saved_receipt_rejects_a_new_submission_id(PenaltyType penalty)
    {
        await using var host = await VendorTicketHost.CreateAsync(configureTickets: tickets => tickets[0].PenaltyType = penalty);
        foreach (var expected in new[] { HttpStatusCode.OK, HttpStatusCode.Conflict })
        {
            using var form = Proof("proof.png", "image/png");
            using var response = await host.SendAsync(HttpMethod.Post,
                "/api/enforcer/tickets/101/settlement/receipt", form, "MarketEnforcer", "12");
            Assert.Equal(expected, response.StatusCode);
        }
        Assert.Single(host.Tickets[0].ProofUrls!);
        Assert.Single(host.Storage.UploadedKeys);
    }

    [Theory]
    [InlineData(PenaltyType.CashFine)]
    [InlineData(PenaltyType.BloodDonation)]
    public async Task Settlement_receipt_retry_with_same_submission_id_saves_one_proof(PenaltyType penalty)
    {
        await using var host = await VendorTicketHost.CreateAsync(configureTickets: tickets => tickets[0].PenaltyType = penalty);
        foreach (var attempt in Enumerable.Range(0, 2))
        {
            using var form = Proof("proof.png", "image/png", submissionId: "049687a9-45dd-4b96-b2a3-a38f7d946c56");
            using var response = await host.SendAsync(HttpMethod.Post,
                "/api/enforcer/tickets/101/settlement/receipt", form, "MarketEnforcer", "12");
            Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        }
        Assert.Single(host.Tickets[0].ProofUrls!);
        Assert.Single(host.Storage.UploadedKeys);
        Assert.Equal(1, host.UnitOfWork.SaveCalls);
        Assert.Equal(TicketStatus.Pending, host.Tickets[0].Status);
    }

    [Fact]
    public async Task Settlement_service_retry_with_same_submission_id_counts_hours_once()
    {
        await using var host = await VendorTicketHost.CreateAsync(configureTickets: tickets =>
        {
            tickets[0].PenaltyType = PenaltyType.CommunityService;
            tickets[0].CommunityServiceHours = 8;
        });
        foreach (var attempt in Enumerable.Range(0, 2))
        {
            using var form = Proof("proof.png", "image/png", submissionId: "5fceba1f-4dbc-4e5e-a964-f1a1df3f5ec7");
            form.Add(new StringContent("2026-10-01"), "service_date");
            form.Add(new StringContent("1"), "hours_worked");
            using var response = await host.SendAsync(HttpMethod.Post,
                "/api/enforcer/tickets/101/settlement/community-service", form, "MarketEnforcer", "12");
            Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        }
        Assert.Single(host.Tickets[0].CommunityServiceLogs);
        Assert.Equal(1m, host.Tickets[0].CommunityServiceLogs.Sum(log => log.HoursWorked));
        Assert.Single(host.Storage.UploadedKeys);
        Assert.Equal(1, host.UnitOfWork.SaveCalls);
        Assert.Equal(TicketStatus.InProgress, host.Tickets[0].Status);
    }

    [Theory]
    [InlineData(PenaltyType.CashFine)]
    [InlineData(PenaltyType.BloodDonation)]
    public async Task Vendor_receipt_submission_is_not_available(PenaltyType penalty)
    {
        await using var host = await VendorTicketHost.CreateAsync(configureTickets: tickets => tickets[0].PenaltyType = penalty);
        using var form = Proof("proof.png", "image/png");
        using var response = await host.SendAsync(HttpMethod.Post, Receipt, form);
        Assert.Equal(HttpStatusCode.MethodNotAllowed, response.StatusCode);
        Assert.Empty(host.Storage.UploadedKeys);
        Assert.Equal(0, host.UnitOfWork.SaveCalls);
        Assert.Equal(TicketStatus.Pending, host.Tickets[0].Status);
    }

    public static IEnumerable<object[]> SettlementConsumers()
    {
        yield return ["vendor", PenaltyType.CashFine];
        yield return ["vendor", PenaltyType.BloodDonation];
        yield return ["enforcer", PenaltyType.CashFine];
        yield return ["enforcer", PenaltyType.BloodDonation];
        yield return ["enforcer", PenaltyType.CommunityService];
    }

    [Theory]
    [MemberData(nameof(SettlementConsumers))]
    public async Task SettlementPost_RejectsSpoofedAndTruncatedImageBytesBeforeStorage(
        string actor, PenaltyType penalty)
    {
        foreach (var (filename, mime, bytes) in new[]
        {
            ("invalid.png", "image/png", System.Text.Encoding.UTF8.GetBytes("THIS IS NOT AN IMAGE")),
            ("invalid.jpg", "image/jpeg", System.Text.Encoding.UTF8.GetBytes("THIS IS NOT AN IMAGE")),
            ("wrong.png", "image/png", ImageBytes("proof.jpg")),
            ("wrong.jpeg", "image/jpeg", ImageBytes("proof.png")),
            ("short.png", "image/png", ImageBytes("proof.png")[..7]),
            ("short.jpg", "image/jpeg", ImageBytes("proof.jpg")[..2])
        })
        {
            await using var host = await VendorTicketHost.CreateAsync(configureTickets: tickets =>
            {
                tickets[0].PenaltyType = penalty;
                tickets[0].CommunityServiceHours = penalty == PenaltyType.CommunityService ? 8 : null;
            });
            var before = host.Tickets[0].UpdatedAt;
            using var form = Proof(filename, mime, bytes: bytes);
            var action = penalty == PenaltyType.CommunityService ? "community-service" : "receipt";
            if (penalty == PenaltyType.CommunityService)
            {
                form.Add(new StringContent("2026-10-01"), "service_date");
                form.Add(new StringContent("1"), "hours_worked");
            }
            using var response = await host.SendAsync(HttpMethod.Post,
                $"/api/{actor}/tickets/101/settlement/{action}", form,
                actor == "vendor" ? "MarketVendor" : "MarketEnforcer", actor == "vendor" ? "7" : "12");
            if (actor == "vendor")
            {
                Assert.Equal(HttpStatusCode.MethodNotAllowed, response.StatusCode);
                Assert.Empty(host.Storage.UploadedKeys);
                Assert.Equal(0, host.UnitOfWork.SaveCalls);
                continue;
            }
            Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
            Assert.Empty(host.Storage.UploadedKeys);
            Assert.Equal(0, host.UnitOfWork.SaveCalls);
            Assert.Null(host.Tickets[0].ProofUrls);
            Assert.Empty(host.Tickets[0].CommunityServiceLogs);
            Assert.Equal(TicketStatus.Pending, host.Tickets[0].Status);
            Assert.Equal(before, host.Tickets[0].UpdatedAt);
        }
    }

    [Theory]
    [MemberData(nameof(SettlementConsumers))]
    public async Task SettlementPost_AcceptsMatchingPngAndJpegForEveryConsumer(string actor, PenaltyType penalty)
    {
        foreach (var (filename, mime) in new[] { ("proof.png", "image/png"), ("proof.jpg", "image/jpeg"), ("proof.jpeg", "image/jpeg") })
        {
            await using var host = await VendorTicketHost.CreateAsync(configureTickets: tickets =>
            {
                tickets[0].PenaltyType = penalty;
                tickets[0].CommunityServiceHours = penalty == PenaltyType.CommunityService ? 8 : null;
            });
            using var form = Proof(filename, mime);
            var action = penalty == PenaltyType.CommunityService ? "community-service" : "receipt";
            if (penalty == PenaltyType.CommunityService)
            {
                form.Add(new StringContent("2026-10-01"), "service_date");
                form.Add(new StringContent("1"), "hours_worked");
            }
            using var response = await host.SendAsync(HttpMethod.Post,
                $"/api/{actor}/tickets/101/settlement/{action}", form,
                actor == "vendor" ? "MarketVendor" : "MarketEnforcer", actor == "vendor" ? "7" : "12");
            if (actor == "vendor")
            {
                Assert.Equal(HttpStatusCode.MethodNotAllowed, response.StatusCode);
                Assert.Empty(host.Storage.UploadedKeys);
                Assert.Equal(0, host.UnitOfWork.SaveCalls);
                continue;
            }
            Assert.Equal(HttpStatusCode.OK, response.StatusCode);
            Assert.Single(host.Storage.UploadedKeys);
            Assert.Equal(1, host.UnitOfWork.SaveCalls);
            Assert.Equal(penalty == PenaltyType.CommunityService ? TicketStatus.InProgress : TicketStatus.Pending,
                host.Tickets[0].Status);
        }
    }

    [Theory]
    [InlineData(PenaltyType.CashFine)]
    [InlineData(PenaltyType.BloodDonation)]
    public async Task Former_account_cannot_retrieve_receipt_proofs(PenaltyType penalty)
    {
        await using var host = await VendorTicketHost.CreateAsync(configureTickets: tickets => tickets[0].PenaltyType = penalty);
        using var response = await host.GetAsync(Receipt);
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
        Assert.Equal(0, host.Storage.Calls);
        Assert.Equal(0, host.UnitOfWork.SaveCalls);
    }

    [Fact]
    public async Task Former_account_cannot_retrieve_service_history()
    {
        await using var host = await VendorTicketHost.CreateAsync();
        using var response = await host.GetAsync(Community);
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
        Assert.Equal(0, host.Storage.Calls);
        Assert.Equal(0, host.UnitOfWork.SaveCalls);
    }

    [Fact]
    public async Task CommunityPost_IsNotAllowed()
    {
        await using var host = await VendorTicketHost.CreateAsync();
        using var response = await host.SendAsync(HttpMethod.Post, Community);
        Assert.Equal(HttpStatusCode.MethodNotAllowed, response.StatusCode);
        Assert.Empty(host.Storage.UploadedKeys);
        Assert.Equal(0, host.UnitOfWork.SaveCalls);
    }

    [Theory]
    [InlineData(0)]
    [InlineData(-1)]
    [InlineData(null)]
    public async Task Former_account_cannot_retrieve_service_with_any_hours(int? hours)
    {
        await using var host = await VendorTicketHost.CreateAsync(configureTickets: tickets =>
        {
            tickets[0].PenaltyType = PenaltyType.CommunityService;
            tickets[0].CommunityServiceHours = hours;
        });
        using var response = await host.GetAsync(Community);
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
        Assert.Equal(0, host.Storage.Calls);
    }

    [Theory]
    [InlineData("receipt", false, "901", 404)]
    [InlineData("community-service", false, "901", 404)]
    [InlineData("receipt", false, "99999", 404)]
    [InlineData("community-service", false, "99999", 404)]
    [InlineData("receipt", false, "0", 400)]
    [InlineData("community-service", false, "0", 400)]
    public async Task OwnershipAndIds_AreValidatedBeforeStorageAccess(string action, bool post, string id, int expected)
    {
        await using var host = await VendorTicketHost.CreateAsync();
        using var form = Proof("proof.png", "image/png");
        using var response = await host.SendAsync(post ? HttpMethod.Post : HttpMethod.Get,
            $"/api/vendor/tickets/{id}/settlement/{action}?user_id=88&vendor_id=7", post ? form : null);
        Assert.Equal(expected, (int)response.StatusCode);
        if (expected == 404)
        {
            using var json = JsonDocument.Parse(await response.Content.ReadAsStringAsync());
            Assert.Equal("Ticket not found.", json.RootElement.GetProperty("message").GetString());
        }
        Assert.Equal(0, host.Storage.Calls);
        Assert.Empty(host.Storage.UploadedKeys);
        Assert.Equal(0, host.UnitOfWork.SaveCalls);
    }

    [Theory]
    [InlineData("receipt", false)]
    [InlineData("community-service", false)]
    public async Task AllRoutes_RejectInvalidClaimsAndWrongRoles(string action, bool post)
    {
        await using var host = await VendorTicketHost.CreateAsync();
        foreach (var (role, userId, expected) in new (string?, string?, int)[]
            { (null, "7", 401), ("MarketEnforcer", "7", 403), ("AdminOfficer", "7", 403), ("MarketVendor", null, 401), ("MarketVendor", "invalid", 401) })
        {
            using var form = Proof("proof.png", "image/png");
            using var response = await host.SendAsync(post ? HttpMethod.Post : HttpMethod.Get,
                $"/api/vendor/tickets/101/settlement/{action}", post ? form : null, role, userId);
            Assert.Equal(expected, (int)response.StatusCode);
        }
        Assert.Equal(0, host.Storage.Calls);
        Assert.Empty(host.Storage.UploadedKeys);
        Assert.Equal(0, host.UnitOfWork.SaveCalls);
    }

    [Theory]
    [InlineData("receipt", false)]
    [InlineData("community-service", false)]
    public async Task Former_account_cannot_access_any_settlement_type(string action, bool post)
    {
        foreach (var scenario in new[] { "warning", "missing", "wrong" })
        {
            await using var host = await VendorTicketHost.CreateAsync(configureTickets: tickets =>
            {
                var ticket = tickets[0];
                if (scenario == "warning") ticket.Type = ViolationType.Warning;
                if (scenario == "missing") ticket.PenaltyType = null;
                if (scenario == "wrong") ticket.PenaltyType = action == "receipt" ? PenaltyType.CommunityService : PenaltyType.CashFine;
            });
            using var form = Proof("proof.png", "image/png");
            using var response = await host.SendAsync(post ? HttpMethod.Post : HttpMethod.Get,
                $"/api/vendor/tickets/101/settlement/{action}", post ? form : null);
            Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
            Assert.Empty(host.Storage.UploadedKeys);
            Assert.Equal(0, host.Storage.Calls);
            Assert.Equal(0, host.UnitOfWork.SaveCalls);
        }
    }

    [Fact]
    public async Task Retired_settlement_query_has_no_account_join()
    {
        using var context = new AppDbContext(new DbContextOptionsBuilder<AppDbContext>().Options);
        var fixture = new VendorTicketDbSet<Ticket>(VendorTicketHost.Records());
        context.Tickets = fixture;
        var repository = new TicketRepository(context);
        var method = typeof(TicketRepository).GetMethod("GetVendorTicketByIdAsync");
        Assert.NotNull(method);
        await (Task)method.Invoke(repository, [101, 7])!;
        using var postgres = new AppDbContext(new DbContextOptionsBuilder<AppDbContext>()
            .UseNpgsql("Host=localhost;Database=unused;Username=unused;Password=unused").UseSnakeCaseNamingConvention().Options);
        var expression = new ReplaceReportQueryRoot(fixture.RootExpression,
            ((IQueryable<Ticket>)postgres.Tickets).Expression).Visit(fixture.State.LastExpression!);
        var sql = ((IQueryable<Ticket>)postgres.Tickets).Provider.CreateQuery(expression!).ToQueryString();
        Assert.DoesNotContain("user_id", sql);
        Assert.Contains("FALSE", sql, StringComparison.OrdinalIgnoreCase);
        Assert.Contains("WHERE", sql);
    }

    private static byte[] ImageBytes(string filename) => Convert.FromBase64String(
        filename.EndsWith(".png", StringComparison.OrdinalIgnoreCase)
            ? "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aS1sAAAAASUVORK5CYII="
            : "/9j/4AAQSkZJRgABAQEAYABgAAD/2wBDAAMCAgMCAgMDAwMEAwMEBQgFBQQEBQoHBwYIDAoMDAsKCwsNDhIQDQ4RDgsLEBYQERMUFRUVDA8XGBYUGBIUFRT/2wBDAQMEBAUEBQkFBQkUDQsNFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBT/wAARCAABAAEDASIAAhEBAxEB/8QAHwAAAQUBAQEBAQEAAAAAAAAAAAECAwQFBgcICQoL/8QAtRAAAgEDAwIEAwUFBAQAAAF9AQIDAAQRBRIhMUEGE1FhByJxFDKBkaEII0KxwRVS0fAkM2JyggkKFhcYGRolJicoKSo0NTY3ODk6Q0RFRkdISUpTVFVWV1hZWmNkZWZnaGlqc3R1dnd4eXqDhIWGh4iJipKTlJWWl5iZmqKjpKWmp6ipqrKztLW2t7i5usLDxMXGx8jJytLT1NXW19jZ2uHi4+Tl5ufo6erx8vP09fb3+Pn6/8QAHwEAAwEBAQEBAQEBAQAAAAAAAAECAwQFBgcICQoL/8QAtREAAgECBAQDBAcFBAQAAQJ3AAECAxEEBSExBhJBUQdhcRMiMoEIFEKRobHBCSMzUvAVYnLRChYkNOEl8RcYGRomJygpKjU2Nzg5OkNERUZHSElKU1RVVldYWVpjZGVmZ2hpanN0dXZ3eHl6goOEhYaHiImKkpOUlZaXmJmaoqOkpaanqKmqsrO0tba3uLm6wsPExcbHyMnK0tPU1dbX2Nna4uPk5ebn6Onq8vP09fb3+Pn6/9oADAMBAAIRAxEAPwD9U6KKKAP/2Q==");

    private static MultipartFormDataContent Proof(string filename, string mime, int? length = null, byte[]? bytes = null, string? submissionId = null)
    {
        var form = new MultipartFormDataContent();
        form.Add(new StringContent(submissionId ?? Guid.NewGuid().ToString()), "submission_id");
        var image = bytes ?? ImageBytes(filename);
        if (length.HasValue) Array.Resize(ref image, length.Value);
        var content = new ByteArrayContent(image);
        content.Headers.ContentType = new MediaTypeHeaderValue(mime);
        form.Add(content, "proof_file", filename);
        return form;
    }
}
