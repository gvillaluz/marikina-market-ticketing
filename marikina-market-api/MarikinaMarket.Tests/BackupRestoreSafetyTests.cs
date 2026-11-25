using MarikinaMarket.API.Application.DTOs.Audits.Internal;
using MarikinaMarket.API.Application.Interfaces.Repositories;
using MarikinaMarket.API.Application.Interfaces.Services;
using MarikinaMarket.API.Application.Services;
using MarikinaMarket.API.Domain.Entities;
using MarikinaMarket.API.Domain.Enums;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging.Abstractions;
using Xunit;

namespace MarikinaMarket.Tests;

[Collection("Backup scheduler")]
public class BackupRestoreSafetyTests
{
    public BackupRestoreSafetyTests()
    {
        var expectedTemp = Environment.GetEnvironmentVariable("BACKUP_TEST_TEMP_ROOT");
        Assert.False(string.IsNullOrWhiteSpace(expectedTemp));
        Assert.Equal(Path.GetFullPath(expectedTemp!), Path.GetFullPath(Path.GetTempPath()).TrimEnd(Path.DirectorySeparatorChar));
    }

    // A system restored from a backup must not find that backup's own record marked "delete its file".
    // The database copy is taken before the flag is set, so the copy never contains the flag.
    [Fact]
    public async Task CleanupFlagIsSavedAfterTheDatabaseCopyAndBeforeTheUpload()
    {
        var tempRoot = Path.Combine(Path.GetTempPath(), "MarikinaMarket-backups");
        var fakeDumpFolder = Path.Combine(Path.GetTempPath(), "fake-pg-dump-" + Guid.NewGuid().ToString("N"));
        Directory.CreateDirectory(fakeDumpFolder);
        try
        {
            Backup? backup = null;
            var saves = new List<(bool CleanupPending, bool DatabaseCopyTaken, BackupStatus Status)>();
            bool? pendingWhenUploadStarted = null;
            var repository = BackupTestBoundary.Create<IBackupRepository>((name, args) => name switch
            {
                "TryAcquireOperationLockAsync" => Task.FromResult<IBackupOperationLock?>(new BackupTestLock()),
                "AcquireSettingsLockAsync" => Task.FromResult<IBackupOperationLock>(new BackupTestLock()),
                "RecoverInterruptedAsync" => Task.CompletedTask,
                "GetScheduleAsync" => Task.FromResult<BackupSchedule?>(new BackupSchedule { UpdatedAt = DateTime.UtcNow.AddDays(-2) }),
                "GetLatestAutomaticAsync" => Task.FromResult<Backup?>(null),
                "AddBackup" => AddBackup((Backup)args![0]!),
                "SaveChangesAsync" => Save(),
                _ => throw new InvalidOperationException($"Unexpected repository call: {name}")
            });
            var storage = BackupTestBoundary.Create<IStorageService>((name, _) =>
            {
                if (name != "UploadStreamAsync") throw new InvalidOperationException($"Unexpected storage call: {name}");
                pendingWhenUploadStarted = backup!.StorageCleanupPending;
                return Task.CompletedTask;
            });
            var configuration = new ConfigurationBuilder().AddInMemoryCollection(new Dictionary<string, string?>
            {
                ["Backups:EncryptionKey"] = Convert.ToBase64String(new byte[32]),
                ["Backups:PgDumpPath"] = WriteFakePgDump(fakeDumpFolder),
                ["ConnectionStrings:DefaultConnection"] = "Host=localhost;Database=synthetic;Username=synthetic;Password=synthetic"
            }).Build();
            var service = new BackupService(repository, new ReportUnitOfWork(), storage, configuration,
                BackupTestBoundary.Create<IHostApplicationLifetime>((_, _) => CancellationToken.None),
                NullLogger<BackupService>.Instance,
                BackupTestBoundary.Create<IAuditLogService>((_, _) => Task.CompletedTask), new AuditLogContext(),
                BackupTestBoundary.Create<IUserRepository>((name, _) => throw new InvalidOperationException(name)), new BackupRestoreState(),
                BackupTestBoundary.Create<Microsoft.Extensions.DependencyInjection.IServiceScopeFactory>((name, _) => throw new InvalidOperationException(name)));

            await service.CreateManualAsync(default);

            Assert.Equal(3, saves.Count);
            // Saved when the attempt starts, before the database copy exists: no cleanup flag.
            Assert.Equal((false, false, BackupStatus.Failed), saves[0]);
            // Saved after the database copy was taken (its encrypted file exists) and before the upload.
            Assert.Equal((true, true, BackupStatus.Failed), saves[1]);
            Assert.True(pendingWhenUploadStarted);
            // Saved when the backup finishes: flag cleared, backup completed.
            Assert.Equal((false, true, BackupStatus.Completed), saves[2]);

            Task AddBackup(Backup added) { backup = added; return Task.CompletedTask; }
            Task Save()
            {
                saves.Add((backup!.StorageCleanupPending, Directory.Exists(tempRoot) &&
                    Directory.GetFiles(tempRoot, "*.encrypted.tmp").Length > 0, backup.Status));
                return Task.CompletedTask;
            }
        }
        finally { Directory.Delete(fakeDumpFolder, recursive: true); }
    }

    // Stands in for pg_dump: finds "--file <path>" in its arguments and writes a small file there.
    private static string WriteFakePgDump(string folder)
    {
        if (OperatingSystem.IsWindows())
        {
            var path = Path.Combine(folder, "pg_dump.cmd");
            File.WriteAllText(path, "@echo off\r\n:next\r\nif \"%~1\"==\"--file\" goto write\r\nshift\r\ngoto next\r\n:write\r\necho synthetic dump> \"%~2\"\r\nexit /b 0\r\n");
            return path;
        }
        var script = Path.Combine(folder, "pg_dump.sh");
        File.WriteAllText(script, "#!/bin/sh\nwhile [ \"$1\" != \"--file\" ]; do shift; done\necho synthetic dump > \"$2\"\n");
        File.SetUnixFileMode(script, UnixFileMode.UserRead | UnixFileMode.UserWrite | UnixFileMode.UserExecute);
        return script;
    }
}
