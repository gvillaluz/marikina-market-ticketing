using System.Collections.Concurrent;
using MarikinaMarket.API.Application.DTOs.Audits.Internal;
using MarikinaMarket.API.Application.Interfaces.Repositories;
using MarikinaMarket.API.Application.Interfaces.Services;
using MarikinaMarket.API.Application.Services;
using MarikinaMarket.API.Domain.Entities;
using MarikinaMarket.API.Infrastructure.BackgroundServices;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Logging.Abstractions;
using Xunit;

namespace MarikinaMarket.Tests;

[CollectionDefinition("Backup scheduler", DisableParallelization = true)]
public sealed class BackupSchedulerCollection { }

[Collection("Backup scheduler")]
public class AutomaticBackupServiceTests
{
    [Theory]
    [InlineData(false, "scope")]
    [InlineData(false, "resolution")]
    [InlineData(false, "write")]
    [InlineData(true, "scope")]
    [InlineData(true, "resolution")]
    [InlineData(true, "write")]
    public async Task ReportingFailureDoesNotStopPollingOrCleanupRetry(bool cleanupFailure, string reportingFailure)
        => await VerifyRecovery(cleanupFailure, reportingFailure);

    [Theory]
    [InlineData(false)]
    [InlineData(true)]
    public async Task RealAuditServiceContainsRepositoryFailure(bool cleanupFailure)
        => await VerifyRecovery(cleanupFailure, "persistence");

    private static async Task VerifyRecovery(bool cleanupFailure, string reportingFailure)
    {
        using var fixture = new SchedulerFixture(cleanupFailure, reportingFailure);
        using var worker = new AutomaticBackupService(fixture, fixture.Logger);
        await worker.StartAsync(default);
        try
        {
            // A later real 30-second poll must reach the real backup service/repository.
            var recovered = Task.WhenAll(fixture.ScheduledRecovered.Task, fixture.CleanupRecovered.Task);
            var finished = await Task.WhenAny(recovered, worker.ExecuteTask!).WaitAsync(TimeSpan.FromSeconds(45));
            if (finished == worker.ExecuteTask) await worker.ExecuteTask!;
            Assert.Same(recovered, finished);
            Assert.Equal(1, fixture.ProcessingFailures);
            Assert.Equal(1, fixture.ReportingAttempts);
            Assert.Equal(reportingFailure == "persistence" ? 1 : 0, fixture.AuditRepositoryCalls);
            Assert.Contains(fixture.Logger.Messages, message => message.Contains(cleanupFailure
                ? "Backup maintenance will be retried" : "Automatic backup check failed"));
            Assert.Equal(reportingFailure == "persistence" ? 0 : 1,
                fixture.Logger.Messages.Count(message => message.Contains("Backup failure audit could not be recorded")));
            Assert.DoesNotContain(fixture.Logger.Messages, message => message.Contains(SchedulerFixture.PrivateDiagnostic));
        }
        finally { await worker.StopAsync(default).WaitAsync(TimeSpan.FromSeconds(5)); }
        Assert.True(worker.ExecuteTask!.IsCompletedSuccessfully);
    }

    [Fact]
    public async Task ShutdownDuringProcessingDoesNotReportFailureOrRunCleanup()
    {
        using var fixture = new SchedulerFixture(false, "shutdown");
        using var worker = new AutomaticBackupService(fixture, fixture.Logger);
        await worker.StartAsync(default);
        await fixture.ProcessingStarted.Task.WaitAsync(TimeSpan.FromSeconds(5));
        await worker.StopAsync(default).WaitAsync(TimeSpan.FromSeconds(5));
        Assert.True(worker.ExecuteTask!.IsCompletedSuccessfully);
        Assert.Equal(0, fixture.ReportingAttempts);
        Assert.Equal(0, fixture.CleanupCalls);
        Assert.Empty(fixture.Logger.Messages);
    }

    [Fact]
    public async Task ShutdownDuringPollDelayExitsWithoutFailureAudit()
    {
        using var fixture = new SchedulerFixture(false, "none");
        using var worker = new AutomaticBackupService(fixture, fixture.Logger);
        await worker.StartAsync(default);
        await fixture.CleanupRecovered.Task.WaitAsync(TimeSpan.FromSeconds(5));
        await worker.StopAsync(default).WaitAsync(TimeSpan.FromSeconds(5));
        Assert.True(worker.ExecuteTask!.IsCompletedSuccessfully);
        Assert.Equal(0, fixture.ReportingAttempts);
        Assert.Empty(fixture.Logger.Messages);
    }

    // Production scheduler, BackupService and AuditLogService are exercised. Only
    // repositories, forbidden storage operations and DI failure boundaries are controlled.
    private sealed class SchedulerFixture : IServiceProvider, IServiceScopeFactory, IDisposable
    {
        internal const string PrivateDiagnostic = "synthetic-private-provider-diagnostic";
        private readonly ServiceProvider _provider;
        private readonly bool _cleanupFailure;
        private readonly string _reportingFailure;
        private bool _reportingPending;
        private int _backupScopes;
        internal int ProcessingFailures, ReportingAttempts, CleanupCalls, AuditRepositoryCalls;
        internal TaskCompletionSource ScheduledRecovered { get; } = new(TaskCreationOptions.RunContinuationsAsynchronously);
        internal TaskCompletionSource CleanupRecovered { get; } = new(TaskCreationOptions.RunContinuationsAsynchronously);
        internal TaskCompletionSource ProcessingStarted { get; } = new(TaskCreationOptions.RunContinuationsAsynchronously);
        internal CaptureLogger Logger { get; } = new();

        internal SchedulerFixture(bool cleanupFailure, string reportingFailure)
        {
            var expectedTemp = Environment.GetEnvironmentVariable("BACKUP_TEST_TEMP_ROOT");
            Assert.False(string.IsNullOrWhiteSpace(expectedTemp));
            Assert.Equal(Path.GetFullPath(expectedTemp!), Path.GetFullPath(Path.GetTempPath()).TrimEnd(Path.DirectorySeparatorChar));
            _cleanupFailure = cleanupFailure;
            _reportingFailure = reportingFailure;
            var services = new ServiceCollection().AddLogging();
            services.AddScoped<AuditLogContext>();
            services.AddSingleton(AuditUserRepositoryStub.Create());
            services.AddScoped<IAuditLogRepository>(_ => BackupTestBoundary.Create<IAuditLogRepository>((name, args) =>
            {
                Assert.Equal("AddAsync", name);
                var log = Assert.IsType<AuditLog>(args![0]);
                Assert.Equal(cleanupFailure ? "BackupMaintenance" : "CheckAutomaticBackups", log.Action);
                AuditRepositoryCalls++;
                return Task.FromException(new IOException(PrivateDiagnostic));
            }));
            services.AddScoped<IAuditLogService, AuditLogService>();
            services.AddScoped<IBackupService>(provider =>
            {
                var scopeNumber = ++_backupScopes;
                var schedule = new BackupSchedule { Enabled = false, UpdatedAt = DateTime.UtcNow.AddDays(-1) };
                var repository = BackupTestBoundary.Create<IBackupRepository>((name, args) => name switch
                {
                    "TryAcquireOperationLockAsync" => Task.FromResult<IBackupOperationLock?>(new BackupTestLock()),
                    "AcquireSettingsLockAsync" => Task.FromResult<IBackupOperationLock>(new BackupTestLock()),
                    "RecoverInterruptedAsync" => Task.CompletedTask,
                    "GetScheduleAsync" => ReadSchedule(scopeNumber, schedule, (CancellationToken)args![0]!),
                    "GetCleanupCandidatesAsync" => ReadCleanup(),
                    _ => throw new InvalidOperationException($"Unexpected backup repository call: {name}")
                });
                return new BackupService(repository, new ReportUnitOfWork(),
                    BackupTestBoundary.Create<IStorageService>((_, _) => throw new InvalidOperationException("Storage must not be used.")),
                    new ConfigurationBuilder().Build(),
                    BackupTestBoundary.Create<IHostApplicationLifetime>((_, _) => CancellationToken.None),
                    NullLogger<BackupService>.Instance, provider.GetRequiredService<IAuditLogService>(), new AuditLogContext());
            });
            _provider = services.BuildServiceProvider();
        }

        private async Task<BackupSchedule?> ReadSchedule(int scopeNumber, BackupSchedule schedule, CancellationToken token)
        {
            if (_reportingFailure == "shutdown")
            {
                ProcessingStarted.TrySetResult();
                await Task.Delay(Timeout.InfiniteTimeSpan, token);
            }
            if (!_cleanupFailure && ProcessingFailures == 0 && _reportingFailure != "none") FailProcessing();
            // Scope 1 is the first check; scope 2 is first cleanup. Scope 3 is
            // the next scheduled check, independent of process-wide initialization.
            if (scopeNumber >= 3) ScheduledRecovered.TrySetResult();
            return schedule;
        }

        private Task<List<Backup>> ReadCleanup()
        {
            CleanupCalls++;
            if (_cleanupFailure && ProcessingFailures == 0) FailProcessing();
            CleanupRecovered.TrySetResult();
            return Task.FromResult(new List<Backup>());
        }

        private void FailProcessing()
        {
            ProcessingFailures++;
            _reportingPending = true;
            throw new IOException(PrivateDiagnostic);
        }

        public object? GetService(Type type) => type == typeof(IServiceScopeFactory) ? this : _provider.GetService(type);

        public IServiceScope CreateScope()
        {
            var reporting = _reportingPending;
            _reportingPending = false;
            if (reporting)
            {
                ReportingAttempts++;
                if (_reportingFailure == "scope") throw new IOException(PrivateDiagnostic);
            }
            return new ReportingScope(_provider.CreateScope(), reporting ? _reportingFailure : "none");
        }

        public void Dispose() => _provider.Dispose();

        private sealed class ReportingScope(IServiceScope inner, string failure) : IServiceScope, IServiceProvider
        {
            public IServiceProvider ServiceProvider => this;
            public object? GetService(Type type)
            {
                if (type == typeof(IAuditLogService))
                {
                    if (failure == "resolution") throw new IOException(PrivateDiagnostic);
                    if (failure == "write") return BackupTestBoundary.Create<IAuditLogService>((_, _) =>
                        Task.FromException(new IOException(PrivateDiagnostic)));
                }
                return inner.ServiceProvider.GetService(type);
            }
            public void Dispose() => inner.Dispose();
        }
    }

    private sealed class CaptureLogger : ILogger<AutomaticBackupService>
    {
        internal ConcurrentQueue<string> Messages { get; } = new();
        public IDisposable? BeginScope<TState>(TState state) where TState : notnull => null;
        public bool IsEnabled(LogLevel logLevel) => true;
        public void Log<TState>(LogLevel logLevel, EventId eventId, TState state, Exception? exception,
            Func<TState, Exception?, string> formatter)
        {
            Assert.Null(exception);
            Messages.Enqueue(formatter(state, exception));
        }
    }
}
