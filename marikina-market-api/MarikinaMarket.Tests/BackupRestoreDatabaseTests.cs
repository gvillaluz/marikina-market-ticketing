using System.Collections.Concurrent;
using System.Security.Cryptography;
using MarikinaMarket.API.Application.DTOs.Audits.Internal;
using MarikinaMarket.API.Application.DTOs.Backups.Request;
using MarikinaMarket.API.Application.DTOs.Backups.Response;
using MarikinaMarket.API.Application.Interfaces.Repositories;
using MarikinaMarket.API.Application.Interfaces.Services;
using MarikinaMarket.API.Application.Services;
using MarikinaMarket.API.Domain.Entities;
using MarikinaMarket.API.Domain.Enums;
using MarikinaMarket.API.Infrastructure.Persistence;
using MarikinaMarket.API.Infrastructure.Repositories;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Npgsql;
using Xunit;

namespace MarikinaMarket.Tests;

// Runs a real restore on a throwaway local database (marikina_market_restore_test or
// marikina_market_restore_upload_test) with the real pg_dump, pg_restore and psql.
// Backup files are kept in memory instead of cloud storage.
// Run with RESTORE_TEST_DATABASE set to one of them (and the usual BACKUP_TEST_TEMP_ROOT/TEMP/TMP).
[Collection("Backup scheduler")]
public class BackupRestoreDatabaseTests
{
    private static readonly string[] Databases = ["marikina_market_restore_test", "marikina_market_restore_upload_test"];
    private const string Password = "Restore-Test-Password-1";

    [RestoreDatabaseFact]
    public async Task RestoreBringsBackTheBackupKeepsTodaysHistoryAndSignsEveryoneOut()
    {
        await using var system = await TestSystem.StartAsync();
        var adminId = await system.CreateHeadAdminAsync("restore-admin");
        await system.AddStreetAsync("Street from before");
        await system.AddSignInAsync(adminId, "before");
        var backup = await system.BackupAsync();

        // Work done after the backup was made.
        await system.AddStreetAsync("Street from after");
        await system.CreateHeadAdminAsync("restore-admin-later");
        await system.AddSignInAsync(adminId, "after");
        await system.AddAuditAsync("Recorded after the backup");
        await system.SetRetentionAsync(45);
        var later = await system.BackupAsync();
        var stampBefore = await system.ScalarAsync<string>($"SELECT security_stamp FROM \"AspNetUsers\" WHERE id = {adminId}");

        var result = await system.RestoreAsync(backup.Id, adminId);

        Assert.Equal((RestoreState.Finished, "The backup was restored. Everyone has been signed out and must sign in again."),
            (result.State, result.Message));
        Assert.All(result.Steps, step => Assert.Equal(RestoreStepState.Done, step.State));
        Assert.Equal((2, 1), Count(result, RestoreCount.Accounts));
        Assert.Equal((0, 0), Count(result, RestoreCount.Tickets));
        // The data is the backup's.
        Assert.Equal(["Street from before"], await system.StreetsAsync());
        Assert.Equal(1, await system.ScalarAsync<long>("SELECT count(*) FROM \"AspNetUsers\""));
        // Today's audit log, backup list and backup schedule are kept.
        Assert.Equal(1, await system.ScalarAsync<long>("SELECT count(*) FROM audit_logs WHERE details = 'Recorded after the backup'"));
        Assert.Equal(1, await system.ScalarAsync<long>(
            "SELECT count(*) FROM audit_logs WHERE action = 'RestoreBackup' AND result = 'Success' AND user_id = " + adminId));
        Assert.Equal(45, await system.ScalarAsync<int>("SELECT retention_days FROM backup_schedules"));
        Assert.Equal(1, await system.ScalarAsync<long>($"SELECT count(*) FROM backups WHERE id = {later.Id} AND status = 'Completed'"));
        Assert.NotNull(result.SafetyBackupId);
        Assert.Equal("BeforeRestore", await system.ScalarAsync<string>($"SELECT type FROM backups WHERE id = {result.SafetyBackupId}"));
        Assert.Equal("Completed", await system.ScalarAsync<string>($"SELECT status FROM backups WHERE id = {result.SafetyBackupId}"));
        Assert.Equal(0, await system.ScalarAsync<long>("SELECT count(*) FROM backups WHERE NOT is_finalized"));
        // Everyone is signed out: stored sign-ins and phones are removed, and every sign-in check changes.
        Assert.Equal(0, await system.ScalarAsync<long>("SELECT count(*) FROM refresh_tokens"));
        Assert.Equal(0, await system.ScalarAsync<long>("SELECT count(*) FROM user_device_tokens"));
        Assert.NotEqual(stampBefore, await system.ScalarAsync<string>($"SELECT security_stamp FROM \"AspNetUsers\" WHERE id = {adminId}"));
        Assert.False(system.State.IsPaused);
    }

    [RestoreDatabaseFact]
    public async Task ARestoreThatFailsWhileLoadingLeavesTodaysDataUnchanged()
    {
        await using var system = await TestSystem.StartAsync();
        var adminId = await system.CreateHeadAdminAsync("restore-admin");
        await system.AddStreetAsync("Street from before");
        var backup = await system.BackupAsync();
        await system.AddStreetAsync("Street from after");
        await system.AddSignInAsync(adminId, "after");
        // Something the restore cannot replace, so loading fails part-way.
        await system.ExecuteAsync("CREATE VIEW restore_test_blocker AS SELECT id FROM market_sections");
        try
        {
            var result = await system.RestoreAsync(backup.Id, adminId);

            Assert.Equal(RestoreState.Failed, result.State);
            Assert.Equal("The backup could not be loaded. Today's data is unchanged.", result.Message);
            Assert.Equal(RestoreStepState.Done, result.Steps.Single(s => s.Step == RestoreStep.SafetyBackup).State);
            Assert.Equal(RestoreStepState.Failed, result.Steps.Single(s => s.Step == RestoreStep.LoadBackup).State);
            Assert.Equal(["Street from after", "Street from before"], await system.StreetsAsync());
            Assert.Equal(1, await system.ScalarAsync<long>("SELECT count(*) FROM refresh_tokens"));
            Assert.Equal(1, await system.ScalarAsync<long>(
                "SELECT count(*) FROM audit_logs WHERE action = 'RestoreBackup' AND result = 'Failed'"));
            Assert.False(system.State.IsPaused);
        }
        finally { await system.ExecuteAsync("DROP VIEW IF EXISTS restore_test_blocker"); }
    }

    [RestoreDatabaseFact]
    public async Task ABackupFromAnotherVersionIsRefusedBeforeAnythingIsPaused()
    {
        await using var system = await TestSystem.StartAsync();
        var adminId = await system.CreateHeadAdminAsync("restore-admin");
        var backup = await system.BackupAsync();
        // Today's database has a change the backup does not have.
        await system.ExecuteAsync("INSERT INTO \"__EFMigrationsHistory\" VALUES ('29990101000000_RestoreTestOnly', '10.0.0')");
        try
        {
            var result = await system.RestoreAsync(backup.Id, adminId);

            Assert.Equal(RestoreState.Failed, result.State);
            Assert.Equal("This backup is from a different version of the system, so it cannot be restored here. " +
                "Ask the technical person to restore it with the recovery guide.", result.Message);
            Assert.Equal(RestoreStepState.Failed, result.Steps.Single(s => s.Step == RestoreStep.CheckBackup).State);
            Assert.Null(result.SafetyBackupId);
            Assert.Equal(0, await system.ScalarAsync<long>("SELECT count(*) FROM backups WHERE type = 'BeforeRestore'"));
            Assert.Empty(result.Counts);
            Assert.False(system.State.IsPaused);
        }
        finally { await system.ExecuteAsync("DELETE FROM \"__EFMigrationsHistory\" WHERE migration_id = '29990101000000_RestoreTestOnly'"); }
    }

    // A file downloaded from the Backups page earlier, uploaded again: no listed backup, nothing from cloud storage.
    [RestoreDatabaseFact]
    public async Task AnUploadedBackupFileIsRestoredAndNotKept()
    {
        await using var system = await TestSystem.StartAsync();
        var adminId = await system.CreateHeadAdminAsync("restore-admin");
        await system.AddStreetAsync("Street from before");
        var backup = await system.BackupAsync();
        var file = await system.DownloadAsync(backup.Id);

        await system.AddStreetAsync("Street from after");
        await system.CreateHeadAdminAsync("restore-admin-later");
        await system.AddSignInAsync(adminId, "after");
        var downloads = system.Downloads;

        var result = await system.RestoreUploadAsync(file, "marikina-backup.mmbak", adminId);

        Assert.Equal((RestoreState.Finished, "The backup was restored. Everyone has been signed out and must sign in again."),
            (result.State, result.Message));
        Assert.All(result.Steps, step => Assert.Equal(RestoreStepState.Done, step.State));
        Assert.Equal((null, null, "marikina-backup.mmbak"), (result.BackupId, result.BackupDateTime, result.FileName));
        Assert.Equal((2, 1), Count(result, RestoreCount.Accounts));
        Assert.Equal(["Street from before"], await system.StreetsAsync());
        Assert.Equal(0, await system.ScalarAsync<long>("SELECT count(*) FROM refresh_tokens"));
        // Nothing was read from cloud storage, and the backup list only gained the safety backup.
        Assert.Equal(downloads, system.Downloads);
        Assert.Equal(2, await system.ScalarAsync<long>("SELECT count(*) FROM backups"));
        Assert.Equal("BeforeRestore", await system.ScalarAsync<string>($"SELECT type FROM backups WHERE id = {result.SafetyBackupId}"));
        Assert.Equal(1, await system.ScalarAsync<long>(
            "SELECT count(*) FROM audit_logs WHERE action = 'RestoreBackup' AND result = 'Success' AND target_id IS NULL " +
            $"AND details LIKE 'Uploaded backup file marikina-backup.mmbak (%) was restored.%' AND user_id = {adminId}"));
        // The uploaded file was used once and is gone.
        Assert.False(File.Exists(system.State.UploadPath));
        Assert.False(system.State.IsPaused);
    }

    [RestoreDatabaseFact]
    public async Task ADamagedUploadedFileIsRefusedBeforeAnythingIsPaused()
    {
        await using var system = await TestSystem.StartAsync();
        var adminId = await system.CreateHeadAdminAsync("restore-admin");
        await system.AddStreetAsync("Street from before");
        var file = await system.DownloadAsync((await system.BackupAsync()).Id);
        file[^1] ^= 0xFF; // one changed byte, as from a damaged copy or another system's key

        var result = await system.RestoreUploadAsync(file, "damaged.mmbak", adminId);

        Assert.Equal(RestoreState.Failed, result.State);
        Assert.Equal("This backup could not be unlocked. It may be damaged, or it was made by another copy of the system. " +
            "Nothing was changed.", result.Message);
        Assert.Equal(RestoreStepState.Failed, result.Steps.Single(s => s.Step == RestoreStep.CheckBackup).State);
        Assert.Null(result.SafetyBackupId);
        Assert.Empty(result.Counts);
        Assert.Equal(1, await system.ScalarAsync<long>("SELECT count(*) FROM backups"));
        Assert.Equal(1, await system.ScalarAsync<long>(
            "SELECT count(*) FROM audit_logs WHERE action = 'RestoreBackup' AND result = 'Failed' " +
            "AND details LIKE 'Restore of uploaded backup file damaged.mmbak (%) failed: This backup could not be unlocked.%'"));
        Assert.False(File.Exists(system.State.UploadPath));
        Assert.False(system.State.IsPaused);
    }

    private static (int Before, int? After) Count(BackupRestoreResponse result, RestoreCount records)
    {
        var count = result.Counts.Single(c => c.Records == records);
        return (count.Before, count.After);
    }

    private sealed class TestSystem : IAsyncDisposable
    {
        private readonly ServiceProvider _provider;
        private readonly string _connection;
        public BackupRestoreState State { get; }

        private readonly ConcurrentBag<string> _downloads;

        private TestSystem(ServiceProvider provider, string connection, ConcurrentBag<string> downloads)
        {
            _provider = provider;
            _connection = connection;
            _downloads = downloads;
            State = provider.GetRequiredService<BackupRestoreState>();
        }

        public static async Task<TestSystem> StartAsync()
        {
            var database = Environment.GetEnvironmentVariable("RESTORE_TEST_DATABASE");
            Assert.Contains(database, Databases);
            var source = Path.GetFullPath(Path.Combine(AppContext.BaseDirectory, "..", "..", "..", "..", "MarikinaMarket.API"));
            var secrets = new ConfigurationBuilder().AddJsonFile(Path.Combine(source, "appsettings.json"))
                .AddUserSecrets("bfa5ed50-9a8a-49ec-954c-52201336ac24").Build();
            var connection = new NpgsqlConnectionStringBuilder(secrets.GetConnectionString("DefaultConnection"));
            Assert.Contains(connection.Host, new[] { "localhost", "127.0.0.1", "::1" });
            connection.Database = database;
            var configuration = new ConfigurationBuilder().AddInMemoryCollection(new Dictionary<string, string?>
            {
                ["ConnectionStrings:DefaultConnection"] = connection.ConnectionString,
                ["Backups:EncryptionKey"] = Convert.ToBase64String(RandomNumberGenerator.GetBytes(32)),
                ["Backups:PgDumpPath"] = secrets["Backups:PgDumpPath"] ?? @"C:\Program Files\PostgreSQL\18\bin\pg_dump.exe"
            }).Build();

            var services = new ServiceCollection();
            services.AddSingleton<IConfiguration>(configuration);
            services.AddLogging();
            services.AddDbContext<AppDbContext>(options => options.UseNpgsql(connection.ConnectionString).UseSnakeCaseNamingConvention());
            services.AddIdentityCore<User>(options =>
            {
                options.User.RequireUniqueEmail = true;
                options.Password.RequireNonAlphanumeric = false;
            }).AddRoles<IdentityRole<int>>().AddEntityFrameworkStores<AppDbContext>().AddSignInManager();
            services.AddAuthentication();
            services.AddHttpContextAccessor();
            services.AddSingleton(BackupTestBoundary.Create<IHostApplicationLifetime>((_, _) => CancellationToken.None));
            var downloads = new ConcurrentBag<string>();
            services.AddSingleton(MemoryStorage(downloads));
            services.AddSingleton<BackupRestoreState>();
            services.AddScoped<AuditLogContext>();
            services.AddScoped<IAuditLogRepository, AuditLogRepository>();
            services.AddScoped<IAuditLogService, AuditLogService>();
            services.AddScoped<IUserRepository, UserRepository>();
            services.AddScoped<IUnitOfWork, UnitOfWork>();
            services.AddScoped<IBackupRepository, BackupRepository>();
            services.AddScoped<IBackupService, BackupService>();
            var system = new TestSystem(services.BuildServiceProvider(), connection.ConnectionString, downloads);

            // Start from empty tables; the table layout and its version list stay.
            await system.ExecuteAsync("""
                DO $$ DECLARE tables text;
                BEGIN
                  SELECT string_agg(format('%I.%I', schemaname, tablename), ', ') INTO tables FROM pg_tables
                  WHERE schemaname = 'public' AND tablename NOT IN ('__EFMigrationsHistory', 'AspNetRoles');
                  EXECUTE 'TRUNCATE ' || tables || ' RESTART IDENTITY CASCADE';
                END $$;
                DROP VIEW IF EXISTS restore_test_blocker;
                """);
            return system;
        }

        public async Task<int> CreateHeadAdminAsync(string userName)
        {
            using var scope = _provider.CreateScope();
            var users = scope.ServiceProvider.GetRequiredService<UserManager<User>>();
            var user = new User
            {
                UserName = userName, Email = userName + "@example.invalid", FirstName = "Restore", LastName = "Test",
                DateOfBirth = new DateOnly(1990, 1, 1), HouseNumber = "1", Street = "Test Street", Barangay = "Test",
                City = "Marikina", Status = AccountStatus.Active, EmailConfirmed = true
            };
            Assert.True((await users.CreateAsync(user, Password)).Succeeded);
            Assert.True((await users.AddToRoleAsync(user, nameof(Role.HeadAdmin))).Succeeded);
            return user.Id;
        }

        public Task AddStreetAsync(string name) => WithContextAsync(db =>
            db.MarketSections.Add(new MarketSection { Name = name, CreatedAt = DateTime.UtcNow }));

        public Task AddSignInAsync(int userId, string token) => WithContextAsync(db =>
        {
            db.RefreshTokens.Add(new RefreshToken { Token = "restore-test-" + token, UserId = userId, ExpiresAt = DateTime.UtcNow.AddDays(7) });
            db.UserDeviceTokens.Add(new UserDeviceToken { DeviceToken = "restore-test-" + token, UserId = userId,
                CreatedAt = DateTime.UtcNow, LastUsedAt = DateTime.UtcNow });
        });

        public Task AddAuditAsync(string details) => WithContextAsync(db =>
            db.AuditLogs.Add(new AuditLog { Action = "RestoreTest", Module = Module.Backups, Result = LogResult.Success, Details = details }));

        public Task SetRetentionAsync(int days) => ExecuteAsync($"UPDATE backup_schedules SET retention_days = {days}");

        public async Task<BackupResponse> BackupAsync()
        {
            using var scope = _provider.CreateScope();
            var backup = await scope.ServiceProvider.GetRequiredService<IBackupService>().CreateManualAsync(default);
            Assert.Equal(BackupStatus.Completed, backup.Status);
            return backup;
        }

        public int Downloads => _downloads.Count;

        public async Task<byte[]> DownloadAsync(int backupId)
        {
            using var scope = _provider.CreateScope();
            var file = await scope.ServiceProvider.GetRequiredService<IBackupService>().DownloadAsync(backupId, default);
            using var owner = file.Owner;
            using var copy = new MemoryStream();
            await file.Stream.CopyToAsync(copy);
            return copy.ToArray();
        }

        public async Task<BackupRestoreResponse> RestoreAsync(int backupId, int adminId)
        {
            using var scope = _provider.CreateScope();
            return await WaitAsync(await scope.ServiceProvider.GetRequiredService<IBackupService>().StartRestoreAsync(backupId,
                new RestoreBackupRequest { Confirmation = "RESTORE", Password = Password }, adminId, default));
        }

        public async Task<BackupRestoreResponse> RestoreUploadAsync(byte[] file, string fileName, int adminId)
        {
            using var scope = _provider.CreateScope();
            return await WaitAsync(await scope.ServiceProvider.GetRequiredService<IBackupService>().StartUploadRestoreAsync(
                new RestoreUploadRequest
                {
                    Confirmation = "RESTORE", Password = Password,
                    File = new FormFile(new MemoryStream(file), 0, file.Length, "file", fileName)
                }, adminId, default));
        }

        private async Task<BackupRestoreResponse> WaitAsync(BackupRestoreResponse started)
        {
            var waited = System.Diagnostics.Stopwatch.StartNew();
            while (true)
            {
                using var scope = _provider.CreateScope();
                var progress = scope.ServiceProvider.GetRequiredService<IBackupService>().GetRestoreProgress(started.RestoreId);
                if (progress.State != RestoreState.Running)
                {
                    // The background work finishes its clean-up right after the result is published.
                    await Task.Delay(500);
                    return progress;
                }
                Assert.True(waited.Elapsed < TimeSpan.FromMinutes(5), "The restore did not finish within 5 minutes.");
                await Task.Delay(250);
            }
        }

        public async Task<List<string>> StreetsAsync()
        {
            using var scope = _provider.CreateScope();
            return await scope.ServiceProvider.GetRequiredService<AppDbContext>().MarketSections
                .OrderBy(s => s.Name).Select(s => s.Name).ToListAsync();
        }

        public async Task<T> ScalarAsync<T>(string sql)
        {
            await using var connection = new NpgsqlConnection(_connection);
            await connection.OpenAsync();
            await using var command = new NpgsqlCommand(sql, connection);
            return (T)Convert.ChangeType((await command.ExecuteScalarAsync())!, typeof(T));
        }

        public async Task ExecuteAsync(string sql)
        {
            await using var connection = new NpgsqlConnection(_connection);
            await connection.OpenAsync();
            await using var command = new NpgsqlCommand(sql, connection);
            await command.ExecuteNonQueryAsync();
        }

        private async Task WithContextAsync(Action<AppDbContext> change)
        {
            using var scope = _provider.CreateScope();
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            change(db);
            await db.SaveChangesAsync();
        }

        public async ValueTask DisposeAsync()
        {
            await _provider.DisposeAsync();
            NpgsqlConnection.ClearAllPools();
        }

        private static IStorageService MemoryStorage(ConcurrentBag<string> downloads)
        {
            var files = new ConcurrentDictionary<string, byte[]>();
            return BackupTestBoundary.Create<IStorageService>((name, args) =>
            {
                switch (name)
                {
                    case "UploadStreamAsync":
                        using (var copy = new MemoryStream())
                        {
                            ((Stream)args![1]!).CopyTo(copy);
                            files[(string)args[2]!] = copy.ToArray();
                        }
                        return Task.CompletedTask;
                    case "DownloadStreamAsync":
                        downloads.Add((string)args![1]!);
                        var stream = new MemoryStream(files[(string)args![1]!]);
                        return Task.FromResult<(Stream, IDisposable)>((stream, stream));
                    case "DeleteAllVersionsAsync":
                        files.TryRemove((string)args![1]!, out _);
                        return Task.CompletedTask;
                    default:
                        throw new InvalidOperationException($"Unexpected storage call: {name}");
                }
            });
        }
    }
}

public sealed class RestoreDatabaseFactAttribute : FactAttribute
{
    public RestoreDatabaseFactAttribute()
    {
        if (string.IsNullOrWhiteSpace(Environment.GetEnvironmentVariable("RESTORE_TEST_DATABASE")))
            Skip = "Set RESTORE_TEST_DATABASE=marikina_market_restore_test (or marikina_market_restore_upload_test) to run restores on a throwaway local database.";
    }
}
