using MarikinaMarket.API.Application.DTOs.Audits.Request;
using MarikinaMarket.API.Application.DTOs.Enforcers.Request;
using MarikinaMarket.API.Application.DTOs.User.Request;
using MarikinaMarket.API.Domain.Entities;
using MarikinaMarket.API.Domain.Enums;
using MarikinaMarket.API.Infrastructure.Persistence;
using MarikinaMarket.API.Infrastructure.Repositories;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Xunit;

namespace MarikinaMarket.Tests;

// Slice 2b of the exact-first search: Accounts, Enforcers and Audit logs. When something is typed, rows where the
// typed text is a whole word come first, then the rest, each group in the order the list already uses. Expected ids
// are worked out by hand from the records in each test (synthetic names). The data is in memory, so these tests
// cannot prove that the database runs the whole-word rule the same way; the live check does.
public class ExactSearchFirstAdminListsTests
{
    private static User NewUser(int id, string first, string last, string? email = null) => new()
    {
        Id = id, UserName = $"HAD{id:D4}-test", FirstName = first, LastName = last,
        Email = email ?? $"user{id}@example.invalid", PhoneNumber = "09171234567", DateOfBirth = new(1990, 1, 1),
        HouseNumber = "1", Street = "Market Lane", Barangay = "Synthetic", City = "Marikina"
    };

    // ---- Accounts (A to Z by last name, then first name) ----

    private static UserRepository AccountsRepository(params User[] users)
    {
        var context = new AppDbContext(new DbContextOptionsBuilder<AppDbContext>().Options)
        {
            Users = new AccountDatabaseSet<User>(users),
            Roles = new AccountDatabaseSet<IdentityRole<int>>([]),
            UserRoles = new AccountDatabaseSet<IdentityUserRole<int>>([])
        };
        return new UserRepository(null!, null!, context);
    }

    private static async Task<List<int>> AccountIds(UserRepository repository, string? search, int limit = 10) =>
        (await repository.GetUserSummariesAsync(0, limit, new UserSummaryFilter { Search = search }, 999))
            .Take(limit).Select(u => u.Id).ToList();

    // 1 "Ana Cruzado" is only part of a word; 2 "Ben Dela-Cruz" and 3 "Cruz Zamora" are whole words.
    private static User[] CruzAccounts() =>
    [
        NewUser(1, "Ana", "Cruzado"), NewUser(2, "Ben", "Dela-Cruz"), NewUser(3, "Cruz", "Zamora"),
    ];

    [Fact]
    public async Task Accounts_with_the_search_as_a_whole_word_come_first()
    {
        var ids = await AccountIds(AccountsRepository(CruzAccounts()), "CRUZ");
        Assert.Equal([2, 3, 1], ids);
    }

    [Fact]
    public async Task Accounts_without_a_search_keep_last_name_order()
    {
        var ids = await AccountIds(AccountsRepository(CruzAccounts()), null);
        Assert.Equal([1, 2, 3], ids);
    }

    [Fact]
    public async Task Accounts_count_the_email_as_a_whole_word_field()
    {
        // 4 "Abad" has email cruzado@..., only part of a word; 5 "Bautista" has email cruz@..., a whole word.
        var repository = AccountsRepository(NewUser(4, "Dan", "Abad", "cruzado@mail.invalid"),
            NewUser(5, "Eli", "Bautista", "cruz@mail.invalid"));
        Assert.Equal([5, 4], await AccountIds(repository, "cruz"));
    }

    [Fact]
    public async Task An_account_whole_word_match_on_a_later_page_moves_to_the_first_page()
    {
        // Ids 1-11 "Cruzado01".."Cruzado11" are only part of a word and sort first by last name; 12 "Cruz Zamora" is last.
        var users = Enumerable.Range(1, 11).Select(id => NewUser(id, "Ana", $"Cruzado{id:D2}"))
            .Append(NewUser(12, "Cruz", "Zamora")).ToArray();
        var repository = AccountsRepository(users);
        var ids = await AccountIds(repository, "cruz", limit: 10);
        Assert.Equal(12, ids.First());
        Assert.Equal(10, ids.Count);
        Assert.Equal(12, await repository.GetUserSummariesCountAsync(new UserSummaryFilter { Search = "cruz" }, 999));
    }

    // ---- Enforcers (by name, tickets or warnings, up or down) ----

    private static UserRepository EnforcersRepository(params User[] enforcers)
    {
        var store = ReviewBoundaryProxy.Create<IQueryableUserStore<User>>((method, _) =>
            method.Name == "get_Users" ? new AccountDatabaseSet<User>(enforcers) : throw new InvalidOperationException(method.Name));
        var manager = new UserManager<User>(store, Microsoft.Extensions.Options.Options.Create(new IdentityOptions()),
            new PasswordHasher<User>(), [], [], new UpperInvariantLookupNormalizer(), new IdentityErrorDescriber(), null!,
            Microsoft.Extensions.Logging.Abstractions.NullLogger<UserManager<User>>.Instance);
        var context = new AppDbContext(new DbContextOptionsBuilder<AppDbContext>().Options)
        {
            Users = new AccountDatabaseSet<User>(enforcers),
            Roles = new AccountDatabaseSet<IdentityRole<int>>([new("MarketEnforcer") { Id = 3 }]),
            UserRoles = new AccountDatabaseSet<IdentityUserRole<int>>(
                enforcers.Select(e => new IdentityUserRole<int> { UserId = e.Id, RoleId = 3 }).ToList())
        };
        return new UserRepository(manager, null!, context);
    }

    private static User NewEnforcer(int id, string first, string last, int tickets = 0, int warnings = 0)
    {
        var enforcer = NewUser(id, first, last);
        enforcer.IssuedTickets = Enumerable.Range(0, tickets).Select(_ => new Ticket { Type = ViolationType.Ticket, Description = "Synthetic" })
            .Concat(Enumerable.Range(0, warnings).Select(_ => new Ticket { Type = ViolationType.Warning, Description = "Synthetic" }))
            .ToList();
        return enforcer;
    }

    private static async Task<List<int>> EnforcerIds(UserRepository repository, string? search, string? sortBy = null,
        string? direction = null, int limit = 10) =>
        (await repository.GetEnforcersAsync(0, limit,
            new EnforcerSummaryFilter { Search = search, SortBy = sortBy, SortDirection = direction }))
            .Take(limit).Select(e => e.Id).ToList();

    // 1 "Ana Santa Cruzan" is only part of a word (2 tickets, 2 warnings); 2 "Ben Dela-Cruz" (3 tickets, 1 warning)
    // and 3 "Cruz Zamora" (1 ticket, 4 warnings) are whole words. Last names run Dela-Cruz, Santa Cruzan, Zamora.
    private static User[] CruzEnforcers() =>
    [
        NewEnforcer(1, "Ana", "Santa Cruzan", tickets: 2, warnings: 2),
        NewEnforcer(2, "Ben", "Dela-Cruz", tickets: 3, warnings: 1),
        NewEnforcer(3, "Cruz", "Zamora", tickets: 1, warnings: 4),
    ];

    // Each sort the user can pick keeps whole-word matches first and then applies the picked sort inside each group.
    // Without the change, enforcer 1 would sit in the middle under every sort.
    [Theory]
    [InlineData(null, null, new[] { 2, 3, 1 })]            // name A-Z: Dela-Cruz, Zamora | Santa Cruzan
    [InlineData("name", "desc", new[] { 3, 2, 1 })]        // name Z-A: Zamora, Dela-Cruz | Santa Cruzan
    [InlineData("tickets", "desc", new[] { 2, 3, 1 })]     // 3 tickets, 1 ticket | 2 tickets
    [InlineData("tickets", "asc", new[] { 3, 2, 1 })]      // 1 ticket, 3 tickets | 2 tickets
    [InlineData("warnings", "desc", new[] { 3, 2, 1 })]    // 4 warnings, 1 warning | 2 warnings
    [InlineData("warnings", "asc", new[] { 2, 3, 1 })]     // 1 warning, 4 warnings | 2 warnings
    public async Task Enforcers_with_the_search_as_a_whole_word_come_first_under_every_sort(
        string? sortBy, string? direction, int[] expected)
    {
        var ids = await EnforcerIds(EnforcersRepository(CruzEnforcers()), "cruz", sortBy, direction);
        Assert.Equal(expected, ids);
    }

    // Without a search, the picked sort alone decides (enforcer 1 sits in the middle of each).
    [Theory]
    [InlineData(null, null, new[] { 2, 1, 3 })]            // name A-Z: Dela-Cruz, Santa Cruzan, Zamora
    [InlineData("tickets", "desc", new[] { 2, 1, 3 })]     // 3, 2, 1 tickets
    [InlineData("warnings", "asc", new[] { 2, 1, 3 })]     // 1, 2, 4 warnings
    public async Task Enforcers_without_a_search_keep_the_picked_sort(string? sortBy, string? direction, int[] expected)
    {
        var ids = await EnforcerIds(EnforcersRepository(CruzEnforcers()), null, sortBy, direction);
        Assert.Equal(expected, ids);
    }

    [Fact]
    public async Task An_enforcer_whole_word_match_on_a_later_page_moves_to_the_first_page()
    {
        var enforcers = Enumerable.Range(1, 11).Select(id => NewEnforcer(id, "Ana", $"Cruzado{id:D2}"))
            .Append(NewEnforcer(12, "Cruz", "Zamora")).ToArray();
        var repository = EnforcersRepository(enforcers);
        var ids = await EnforcerIds(repository, "cruz", limit: 10);
        Assert.Equal(12, ids.First());
        Assert.Equal(10, ids.Count);
        Assert.Equal(12, await repository.GetEnforcersCountAsync(new EnforcerSummaryFilter { Search = "cruz" }));
    }

    // ---- Audit logs (newest first) ----

    private static AuditLog NewLog(int id, int daysAgo, string action, string details = "Synthetic", string? target = null) => new()
    {
        Id = id, Timestamp = DateTime.UtcNow.Date.AddDays(-daysAgo), Action = action, Details = details, TargetId = target,
        Module = Module.Security, Result = LogResult.Success
    };

    private static AuditLogRepository AuditRepository(params AuditLog[] logs) =>
        new(new AppDbContext(new DbContextOptionsBuilder<AppDbContext>().Options)
        {
            AuditLogs = new AccountDatabaseSet<AuditLog>(logs)
        });

    private static async Task<List<int>> AuditIds(AuditLogRepository repository, string? search, int limit = 10) =>
        (await repository.GetSummariesAsync(0, limit, new AuditLogFilter { Search = search }, null, null))
            .Take(limit).Select(l => l.Id).ToList();

    // 1 (newest) "LoginFailed" is only part of a word; 2 "Login" is a whole word; 3 "SignOut" has "login" as a whole
    // word in its details.
    private static AuditLog[] LoginLogs() =>
    [
        NewLog(1, 1, "LoginFailed"), NewLog(2, 2, "Login"), NewLog(3, 3, "SignOut", details: "Return to login page"),
    ];

    [Fact]
    public async Task Audit_logs_with_the_search_as_a_whole_word_come_first()
    {
        Assert.Equal([2, 3, 1], await AuditIds(AuditRepository(LoginLogs()), "LOGIN"));
    }

    [Fact]
    public async Task Audit_logs_without_a_search_keep_newest_first()
    {
        Assert.Equal([1, 2, 3], await AuditIds(AuditRepository(LoginLogs()), null));
    }

    [Fact]
    public async Task Audit_logs_count_the_record_number_as_a_whole_word_field()
    {
        // 4 (newer) has record number 1010, only part of a number; 5 (older) has record number 101.
        var repository = AuditRepository(NewLog(4, 1, "OpenRecord", target: "1010"), NewLog(5, 2, "OpenRecord", target: "101"));
        Assert.Equal([5, 4], await AuditIds(repository, "101"));
    }

    [Fact]
    public async Task An_audit_log_whole_word_match_on_a_later_page_moves_to_the_first_page()
    {
        // Ids 1-11 (newest) are only part of a word; 12 (oldest) is the whole word.
        var logs = Enumerable.Range(1, 11).Select(id => NewLog(id, id, "LoginFailed"))
            .Append(NewLog(12, 12, "Login")).ToArray();
        var repository = AuditRepository(logs);
        var ids = await AuditIds(repository, "login", limit: 10);
        Assert.Equal(12, ids.First());
        Assert.Equal(10, ids.Count);
        Assert.Equal(12, await repository.GetCountAsync(new AuditLogFilter { Search = "login" }, null, null));
    }
}
