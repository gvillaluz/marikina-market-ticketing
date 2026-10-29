using MarikinaMarket.API.Application.DTOs.Audits.Internal;
using MarikinaMarket.API.Application;
using MarikinaMarket.API.Application.Interfaces.Repositories;
using MarikinaMarket.API.Application.Interfaces.Services;
using MarikinaMarket.API.Application.Services;
using MarikinaMarket.API.Domain.Entities;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging.Abstractions;
using Xunit;

namespace MarikinaMarket.Tests;

[Collection("Backup scheduler")]
public class BackupCoordinationTests
{
    public BackupCoordinationTests()
    {
        var expectedTemp = Environment.GetEnvironmentVariable("BACKUP_TEST_TEMP_ROOT");
        Assert.False(string.IsNullOrWhiteSpace(expectedTemp));
        Assert.Equal(Path.GetFullPath(expectedTemp!), Path.GetFullPath(Path.GetTempPath()).TrimEnd(Path.DirectorySeparatorChar));
    }

    [Fact]
    public async Task HealthReportsAnActiveBackupOwnedByAnotherInstance()
    {
        var repository = BackupTestBoundary.Create<IBackupRepository>((name, args) => name switch
        {
            "AcquireSettingsLockAsync" => Task.FromResult<IBackupOperationLock>(new BackupTestLock()),
            "GetScheduleAsync" => Task.FromResult<BackupSchedule?>(new BackupSchedule { Enabled = false }),
            "GetLatestAsync" => Task.FromResult<Backup?>(null),
            "IsRunningAsync" => Task.FromResult(true),
            _ => throw new InvalidOperationException($"Unexpected repository call: {name}")
        });
        var service = Service(repository);
        var health = await service.GetHealthAsync(default);
        Assert.True(health.IsRunning);
    }

    [Theory]
    [InlineData("manual")]
    [InlineData("scheduled")]
    [InlineData("cleanup")]
    [InlineData("initialize")]
    public async Task BusySharedOperationDoesNotTouchRecoveryScheduleOrStorage(string action)
    {
        int attempts = 0;
        var repository = BackupTestBoundary.Create<IBackupRepository>((name, _) =>
        {
            Assert.Equal("TryAcquireOperationLockAsync", name);
            attempts++;
            return Task.FromResult<IBackupOperationLock?>(null);
        });
        var service = Service(repository);
        if (action == "manual")
            await Assert.ThrowsAsync<ConcurrencyConflictException>(() => Invoke(service, action));
        else
            await Invoke(service, action);
        Assert.Equal(1, attempts);
    }

    [Theory]
    [InlineData("manual")]
    [InlineData("scheduled")]
    [InlineData("cleanup")]
    [InlineData("initialize")]
    public async Task LostConnectionCancelsTheOwnerEvenWhenTheRequestWasNotCanceled(string action)
    {
        using var lost = new CancellationTokenSource();
        lost.Cancel();
        var operation = new BackupTestLock(lost.Token);
        int recoveries = 0;
        var repository = BackupTestBoundary.Create<IBackupRepository>((name, args) =>
        {
            if (name == "TryAcquireOperationLockAsync") return Task.FromResult<IBackupOperationLock?>(operation);
            Assert.Equal("RecoverInterruptedAsync", name);
            recoveries++;
            ((CancellationToken)args![0]!).ThrowIfCancellationRequested();
            throw new InvalidOperationException("Recovery must receive the lost-ownership cancellation.");
        });
        await Assert.ThrowsAnyAsync<OperationCanceledException>(() => Invoke(Service(repository), action));
        Assert.Equal(1, recoveries);
        Assert.True(operation.Disposed);
    }

    [Fact]
    public async Task AnAlreadyRunningInstanceRecoversNewlyAbandonedAttemptsOnItsNextOwnership()
    {
        int recoveries = 0;
        var repository = BackupTestBoundary.Create<IBackupRepository>((name, _) => name switch
        {
            "TryAcquireOperationLockAsync" => Task.FromResult<IBackupOperationLock?>(new BackupTestLock()),
            "AcquireSettingsLockAsync" => Task.FromResult<IBackupOperationLock>(new BackupTestLock()),
            "RecoverInterruptedAsync" => Recover(),
            "GetScheduleAsync" => Task.FromResult<BackupSchedule?>(new BackupSchedule { Enabled = false }),
            _ => throw new InvalidOperationException($"Unexpected repository call: {name}")
        });
        var service = Service(repository);
        await service.InitializeAsync(default);
        await service.InitializeAsync(default);
        Assert.Equal(2, recoveries);
        Task Recover() { recoveries++; return Task.CompletedTask; }
    }

    [Fact]
    public async Task FailedScheduleReadReleasesTheSharedSettingsGuard()
    {
        var settings = new BackupTestLock();
        var repository = BackupTestBoundary.Create<IBackupRepository>((name, _) => name switch
        {
            "AcquireSettingsLockAsync" => Task.FromResult<IBackupOperationLock>(settings),
            "GetScheduleAsync" => Task.FromException<BackupSchedule?>(new IOException("Synthetic database read failure.")),
            _ => throw new InvalidOperationException($"Unexpected repository call: {name}")
        });
        await Assert.ThrowsAsync<IOException>(() => Service(repository).GetScheduleAsync(default));
        Assert.True(settings.Disposed);
    }

    private static Task Invoke(BackupService service, string action) => action switch
    {
        "manual" => service.CreateManualAsync(default),
        "scheduled" => service.RunScheduledAsync(default),
        "cleanup" => service.CleanupAsync(default),
        "initialize" => service.InitializeAsync(default),
        _ => throw new InvalidOperationException("Unknown test action.")
    };

    private static BackupService Service(IBackupRepository repository)
        => new(repository, new ReportUnitOfWork(),
            BackupTestBoundary.Create<IStorageService>((_, _) => throw new InvalidOperationException("Storage is forbidden.")),
            new ConfigurationBuilder().Build(),
            BackupTestBoundary.Create<IHostApplicationLifetime>((_, _) => CancellationToken.None),
            NullLogger<BackupService>.Instance,
            BackupTestBoundary.Create<IAuditLogService>((_, _) => Task.CompletedTask), new AuditLogContext());
}

internal sealed class BackupTestLock(CancellationToken connectionLost = default) : IBackupOperationLock
{
    public CancellationToken ConnectionLost => connectionLost;
    internal bool Disposed { get; private set; }
    public ValueTask DisposeAsync() { Disposed = true; return ValueTask.CompletedTask; }
}
