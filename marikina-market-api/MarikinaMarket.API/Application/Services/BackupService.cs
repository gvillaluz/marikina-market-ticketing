using System.ComponentModel.DataAnnotations;
using System.Diagnostics;
using System.Globalization;
using System.Security.Cryptography;
using MarikinaMarket.API.Application.DTOs.Backups.Internal;
using MarikinaMarket.API.Application.DTOs.Backups.Request;
using MarikinaMarket.API.Application.DTOs.Backups.Response;
using MarikinaMarket.API.Application.DTOs.Tickets.Response;
using MarikinaMarket.API.Application.Interfaces.Repositories;
using MarikinaMarket.API.Application.Interfaces.Services;
using MarikinaMarket.API.Domain.Entities;
using MarikinaMarket.API.Domain.Enums;
using Microsoft.AspNetCore.Identity;
using Npgsql;
using MarikinaMarket.API.Application.DTOs.Audits.Internal;

namespace MarikinaMarket.API.Application.Services
{
    public class BackupService : IBackupService
    {
        private const int PAGE_SIZE = 10;
        private static readonly TimeSpan RetryDelay = TimeSpan.FromMinutes(5);
        private const long MaxDumpSize = 256L * 1024 * 1024;
        private static readonly byte[] EnvelopeHeader = [(byte)'M', (byte)'M', (byte)'B', (byte)'K', 1];
        private static readonly SemaphoreSlim ExecutionGate = new(1, 1);
        private static readonly SemaphoreSlim SettingsGate = new(1, 1);
        private static readonly TimeZoneInfo Manila = TimeZoneInfo.FindSystemTimeZoneById("Asia/Manila");
        private static readonly string TempRoot = Path.Combine(Path.GetTempPath(), "MarikinaMarket-backups");
        private readonly IBackupRepository _repository;
        private readonly IUnitOfWork _unitOfWork;
        private readonly IStorageService _storage;
        private readonly IConfiguration _configuration;
        private readonly IHostApplicationLifetime _lifetime;
        private readonly ILogger<BackupService> _logger;
        private readonly IAuditLogService _auditService;
        private readonly AuditLogContext _audit;
        private readonly IUserRepository _users;
        private readonly BackupRestoreState _restore;
        private readonly IServiceScopeFactory _scopes;

        public BackupService(IBackupRepository repository, IUnitOfWork unitOfWork,
            IStorageService storage, IConfiguration configuration, IHostApplicationLifetime lifetime,
            ILogger<BackupService> logger, IAuditLogService auditService, AuditLogContext audit,
            IUserRepository users, BackupRestoreState restore, IServiceScopeFactory scopes)
        {
            _repository = repository;
            _unitOfWork = unitOfWork;
            _storage = storage;
            _configuration = configuration;
            _lifetime = lifetime;
            _logger = logger;
            _auditService = auditService;
            _audit = audit;
            _users = users;
            _restore = restore;
            _scopes = scopes;
        }

        public async Task<BackupResponse> CreateManualAsync(CancellationToken cancellationToken)
        {
            if (!await ExecutionGate.WaitAsync(0, cancellationToken))
                throw new ConcurrencyConflictException("A backup or backup maintenance operation is already running.");
            try
            {
                await using var operation = await _repository.TryAcquireOperationLockAsync(cancellationToken);
                if (operation is null)
                    throw new ConcurrencyConflictException("A backup or backup maintenance operation is already running.");
                using var owned = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken, operation.ConnectionLost);
                cancellationToken = owned.Token;
                await InitializeCoreAsync(cancellationToken);
                var attempt = (await StartAttemptAsync(BackupType.Manual, cancellationToken))!.Value;
                return await ExecuteBackupAsync(attempt.Backup, attempt.Occurrence, attempt.ScheduleUpdatedAt, cancellationToken, operation.ConnectionLost);
            }
            finally { ExecutionGate.Release(); }
        }

        public async Task RunScheduledAsync(CancellationToken cancellationToken)
        {
            if (!await ExecutionGate.WaitAsync(0, cancellationToken)) return;
            try
            {
                await using var operation = await _repository.TryAcquireOperationLockAsync(cancellationToken);
                if (operation is null) return;
                using var owned = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken, operation.ConnectionLost);
                cancellationToken = owned.Token;
                await InitializeCoreAsync(cancellationToken);
                var attempt = await StartAttemptAsync(BackupType.Automatic, cancellationToken);
                if (attempt.HasValue)
                    await ExecuteBackupAsync(attempt.Value.Backup, attempt.Value.Occurrence, attempt.Value.ScheduleUpdatedAt, cancellationToken, operation.ConnectionLost);
            }
            finally { ExecutionGate.Release(); }
        }

        public async Task InitializeAsync(CancellationToken cancellationToken)
        {
            await ExecutionGate.WaitAsync(cancellationToken);
            try
            {
                await using var operation = await _repository.TryAcquireOperationLockAsync(cancellationToken);
                if (operation is null) return;
                using var owned = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken, operation.ConnectionLost);
                await InitializeCoreAsync(owned.Token);
            }
            finally { ExecutionGate.Release(); }
        }

        private async Task InitializeCoreAsync(CancellationToken cancellationToken)
        {
            // A surviving instance must also recover attempts abandoned after its
            // own startup. The shared operation lock excludes every active owner.
            await _repository.RecoverInterruptedAsync(cancellationToken);
            await SettingsGate.WaitAsync(cancellationToken);
            try
            {
                await using var settings = await _repository.AcquireSettingsLockAsync(cancellationToken);
                var schedule = await _repository.GetScheduleAsync(cancellationToken);
                if (schedule != null && schedule.Enabled && schedule.NextRetryAt == null &&
                    schedule.LastAttemptScheduledAt >= schedule.UpdatedAt)
                {
                    var latest = await _repository.GetLatestAutomaticAsync(cancellationToken);
                    if (latest != null && latest.Status == BackupStatus.Failed &&
                        latest.DateTime >= schedule.LastAttemptScheduledAt && latest.DateTime >= schedule.UpdatedAt)
                    {
                        schedule.NextRetryAt = DateTime.UtcNow.Add(RetryDelay);
                        await _repository.SaveChangesAsync(cancellationToken);
                    }
                }
            }
            finally { SettingsGate.Release(); }
            // Only our application's temporary dump files are recovered; never recurse into other directories.
            CleanupTemporaryFiles();
        }

        private static void CleanupTemporaryFiles()
        {
            if (!Directory.Exists(TempRoot)) return;
            foreach (var path in Directory.EnumerateFiles(TempRoot, "*.tmp", SearchOption.TopDirectoryOnly))
                File.Delete(path);
        }

        private async Task<BackupSchedule> GetOrCreateScheduleAsync(CancellationToken cancellationToken)
        {
            var schedule = await _repository.GetScheduleAsync(cancellationToken);
            if (schedule != null) return schedule;
            schedule = new BackupSchedule { UpdatedAt = DateTime.UtcNow };
            _repository.AddSchedule(schedule);
            await _repository.SaveChangesAsync(cancellationToken);
            return schedule;
        }

        private async Task<(Backup Backup, DateTime? Occurrence, DateTime ScheduleUpdatedAt)?> StartAttemptAsync(
            BackupType type, CancellationToken cancellationToken)
        {
            await SettingsGate.WaitAsync(cancellationToken);
            try
            {
                await using var settings = await _repository.AcquireSettingsLockAsync(cancellationToken);
                var schedule = await GetOrCreateScheduleAsync(cancellationToken);
                var now = DateTime.UtcNow;
                var occurrence = LatestOccurrence(schedule, now);
                if (type == BackupType.Automatic && (!schedule.Enabled || occurrence < schedule.UpdatedAt ||
                    (schedule.LastAttemptScheduledAt.HasValue && occurrence < schedule.LastAttemptScheduledAt) ||
                    (occurrence == schedule.LastAttemptScheduledAt &&
                        (!schedule.NextRetryAt.HasValue || schedule.NextRetryAt > now))))
                    return null;

                var backup = new Backup
                {
                    DateTime = now,
                    Type = type,
                    Status = BackupStatus.Failed,
                    B2Key = $"backups/{now:yyyy/MM/dd}/{Guid.NewGuid():N}.mmbak"
                };
                await _unitOfWork.BeginTransactionAsync();
                try
                {
                    if (type == BackupType.Automatic)
                    {
                        schedule.LastAttemptScheduledAt = occurrence;
                        schedule.NextRetryAt = now.Add(RetryDelay);
                    }
                    _repository.AddBackup(backup);
                    await _repository.SaveChangesAsync(cancellationToken);
                    await _unitOfWork.CommitAsync();
                }
                catch
                {
                    await _unitOfWork.RollbackAsync();
                    throw;
                }
                return (backup, type == BackupType.Automatic ? occurrence : null, schedule.UpdatedAt);
            }
            finally { SettingsGate.Release(); }
        }

        private async Task<BackupResponse> ExecuteBackupAsync(Backup backup, DateTime? occurrence,
            DateTime scheduleUpdatedAt, CancellationToken cancellationToken, CancellationToken connectionLost)
        {
            var tempId = Guid.NewGuid().ToString("N");
            var dumpPath = Path.Combine(TempRoot, tempId + ".dump.tmp");
            var encryptedPath = Path.Combine(TempRoot, tempId + ".encrypted.tmp");
            string stage = "configuration";
            byte[]? key = null;
            using var timeout = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken, _lifetime.ApplicationStopping);
            try
            {
                key = ReadEncryptionKey();
                timeout.CancelAfter(ReadTimeout());
                PrepareTempRoot();

                stage = "database dump";
                await CreateDumpAsync(dumpPath, timeout.Token);
                stage = "encryption";
                await EncryptDumpAsync(dumpPath, encryptedPath, key, timeout.Token);
                // A failure to remove plaintext prevents upload.
                File.Delete(dumpPath);
                stage = "storage upload";
                // Persist before upload so interrupted/ambiguous uploads can be removed on restart.
                // This is set only after the dump is taken: the dump must not contain this flag,
                // or a system restored from this backup would delete the backup file it came from.
                backup.StorageCleanupPending = true;
                await _repository.SaveChangesAsync(timeout.Token);
                await using (var encrypted = File.OpenRead(encryptedPath))
                    await _storage.UploadStreamAsync(B2BucketType.Backups, encrypted, backup.B2Key, timeout.Token);

                stage = "history persistence";
                await SettingsGate.WaitAsync(timeout.Token);
                try
                {
                    await using var settings = await _repository.AcquireSettingsLockAsync(timeout.Token);
                    var schedule = await _repository.GetScheduleAsync(timeout.Token)
                        ?? throw new InvalidOperationException("Backup schedule is missing.");
                    backup.Size = new FileInfo(encryptedPath).Length;
                    backup.CompletedAt = DateTime.UtcNow;
                    backup.ExpiresAt = backup.CompletedAt.Value.AddDays(schedule.RetentionDays);
                    backup.Status = BackupStatus.Completed;
                    backup.IsFinalized = true;
                    backup.StorageCleanupPending = false;
                    backup.ErrorMessage = null;
                    if (occurrence.HasValue && schedule.UpdatedAt == scheduleUpdatedAt &&
                        schedule.LastAttemptScheduledAt == occurrence)
                        schedule.NextRetryAt = null;
                    await _repository.SaveChangesAsync(timeout.Token);
                }
                finally { SettingsGate.Release(); }
            }
            catch (Exception ex)
            {
                if (connectionLost.IsCancellationRequested)
                {
                    _logger.LogWarning("Backup {BackupId} stopped after losing database ownership.", backup.Id);
                    throw new OperationCanceledException("Backup lost database ownership.", connectionLost);
                }
                var error = ex is OperationCanceledException
                    ? "Backup was cancelled or exceeded its time limit."
                    : $"Backup failed during {stage}.";
                await RecordFailureAsync(backup, error, occurrence, scheduleUpdatedAt, connectionLost);
                connectionLost.ThrowIfCancellationRequested();
                if (backup.Type == BackupType.Automatic)
                    await RecordBackupAuditAsync(backup.Id, "CreateAutomaticBackup", LogResult.Failed, "System automatic backup failed.");
                // Do not attach provider exceptions: they can include credentials or database diagnostics.
                _logger.LogWarning("Backup {BackupId} failed during {Stage} ({ExceptionType}).", backup.Id, stage, ex.GetType().Name);
                if (ex is OperationCanceledException && cancellationToken.IsCancellationRequested)
                    throw new OperationCanceledException("Backup was cancelled.", cancellationToken);
                throw new InvalidOperationException(error);
            }
            finally
            {
                if (key != null) CryptographicOperations.ZeroMemory(key);
                DeleteTemporaryFile(dumpPath);
                DeleteTemporaryFile(encryptedPath);
            }

            if (backup.Type == BackupType.Automatic)
                await RecordBackupAuditAsync(backup.Id, "CreateAutomaticBackup", LogResult.Success, "System automatic backup completed.");
            return ToResponse(backup);
        }

        private TimeSpan ReadTimeout()
        {
            var timeoutMinutes = _configuration.GetValue<int?>("Backups:TimeoutMinutes") ?? 15;
            if (timeoutMinutes is < 1 or > 120) throw new InvalidOperationException("Invalid backup timeout.");
            return TimeSpan.FromMinutes(timeoutMinutes);
        }

        private static void PrepareTempRoot()
        {
            Directory.CreateDirectory(TempRoot);
            if (!OperatingSystem.IsWindows())
                File.SetUnixFileMode(TempRoot, UnixFileMode.UserRead | UnixFileMode.UserWrite | UnixFileMode.UserExecute);
        }

        private byte[] ReadEncryptionKey()
        {
            var encoded = _configuration["Backups:EncryptionKey"];
            if (string.IsNullOrWhiteSpace(encoded)) throw new InvalidOperationException("Backup encryption key is missing.");
            var key = Convert.FromBase64String(encoded);
            if (key.Length == 32) return key;
            CryptographicOperations.ZeroMemory(key);
            throw new InvalidOperationException("Backup encryption key must contain 32 bytes.");
        }

        private async Task CreateDumpAsync(string path, CancellationToken cancellationToken)
        {
            await RunPostgresToolAsync("pg_dump", ["--format=custom", "--no-password", "--file", path], cancellationToken);
            var size = new FileInfo(path).Length;
            if (size <= 0 || size > MaxDumpSize) throw new InvalidOperationException("Database dump is empty or exceeds 256 MiB.");
        }

        // pg_restore and psql are expected next to pg_dump (Backups:PgDumpPath), or on PATH like pg_dump.
        private string ToolPath(string tool)
        {
            var dump = _configuration["Backups:PgDumpPath"] ?? "pg_dump";
            if (tool == "pg_dump") return dump;
            var folder = Path.GetDirectoryName(dump);
            var name = tool + Path.GetExtension(dump);
            return string.IsNullOrEmpty(folder) ? name : Path.Combine(folder, name);
        }

        private async Task RunPostgresToolAsync(string tool, IEnumerable<string> arguments, CancellationToken cancellationToken)
        {
            var connection = new NpgsqlConnectionStringBuilder(_configuration.GetConnectionString("DefaultConnection"));
            var start = new ProcessStartInfo
            {
                FileName = ToolPath(tool),
                UseShellExecute = false,
                CreateNoWindow = true,
                RedirectStandardError = true,
                RedirectStandardOutput = true
            };
            foreach (var argument in arguments) start.ArgumentList.Add(argument);
            start.Environment["PGHOST"] = connection.Host;
            start.Environment["PGPORT"] = connection.Port.ToString(CultureInfo.InvariantCulture);
            start.Environment["PGDATABASE"] = connection.Database;
            start.Environment["PGUSER"] = connection.Username;
            start.Environment["PGPASSWORD"] = connection.Password;
            start.Environment["PGSSLMODE"] = connection.SslMode switch
            {
                SslMode.VerifyCA => "verify-ca",
                SslMode.VerifyFull => "verify-full",
                _ => connection.SslMode.ToString().ToLowerInvariant()
            };
            if (!string.IsNullOrWhiteSpace(connection.RootCertificate)) start.Environment["PGSSLROOTCERT"] = connection.RootCertificate;
            using var process = new Process { StartInfo = start };
            var started = false;
            Task? stderr = null;
            Task? stdout = null;
            try
            {
                if (!process.Start()) throw new InvalidOperationException($"{tool} could not start.");
                started = true;
                // Drain without retaining diagnostics in memory or exposing them in logs.
                stderr = process.StandardError.BaseStream.CopyToAsync(Stream.Null, cancellationToken);
                stdout = process.StandardOutput.BaseStream.CopyToAsync(Stream.Null, cancellationToken);
                await process.WaitForExitAsync(cancellationToken);
                await Task.WhenAll(stderr, stdout);
                if (process.ExitCode != 0) throw new InvalidOperationException($"{tool} failed.");
            }
            finally
            {
                if (started && !process.HasExited)
                {
                    try { process.Kill(entireProcessTree: true); }
                    catch (InvalidOperationException) when (process.HasExited) { }
                    await process.WaitForExitAsync(CancellationToken.None);
                }
                if (stderr != null && stdout != null)
                {
                    try { await Task.WhenAll(stderr, stdout); }
                    catch (OperationCanceledException) when (cancellationToken.IsCancellationRequested) { }
                }
                // Remove the password from the managed process configuration as soon as possible.
                start.Environment.Remove("PGPASSWORD");
            }
        }

        private static async Task EncryptDumpAsync(string dumpPath, string encryptedPath, byte[] key, CancellationToken cancellationToken)
        {
            // Validate again before allocating either whole-file buffer.
            var length = new FileInfo(dumpPath).Length;
            if (length <= 0 || length > MaxDumpSize) throw new InvalidOperationException("Invalid database dump size.");
            byte[]? plaintext = null;
            byte[]? ciphertext = null;
            try
            {
                plaintext = await File.ReadAllBytesAsync(dumpPath, cancellationToken);
                ciphertext = new byte[plaintext.Length];
                var nonce = RandomNumberGenerator.GetBytes(12);
                var tag = new byte[16];
                using (var aes = new AesGcm(key, 16))
                    aes.Encrypt(nonce, plaintext, ciphertext, tag, EnvelopeHeader);
                cancellationToken.ThrowIfCancellationRequested();
                await using var output = new FileStream(encryptedPath, FileMode.CreateNew, FileAccess.Write, FileShare.None,
                    81920, FileOptions.Asynchronous);
                await output.WriteAsync(EnvelopeHeader, cancellationToken);
                await output.WriteAsync(nonce, cancellationToken);
                await output.WriteAsync(tag, cancellationToken);
                await output.WriteAsync(ciphertext, cancellationToken);
            }
            finally
            {
                if (plaintext != null) CryptographicOperations.ZeroMemory(plaintext);
                if (ciphertext != null) CryptographicOperations.ZeroMemory(ciphertext);
            }
        }

        private async Task RecordFailureAsync(Backup backup, string error, DateTime? occurrence, DateTime scheduleUpdatedAt,
            CancellationToken connectionLost)
        {
            using var storageRecovery = CancellationTokenSource.CreateLinkedTokenSource(connectionLost);
            storageRecovery.CancelAfter(TimeSpan.FromSeconds(15));
            backup.Status = BackupStatus.Failed;
            backup.IsFinalized = true;
            backup.CompletedAt = null;
            backup.ExpiresAt = null;
            backup.Size = 0;
            backup.ErrorMessage = error;
            backup.StorageCleanupPending = true;
            try
            {
                await _storage.DeleteAllVersionsAsync(B2BucketType.Backups, backup.B2Key, storageRecovery.Token);
                backup.StorageCleanupPending = false;
                backup.DeletedAt = DateTime.UtcNow;
            }
            catch (Exception ex)
            {
                _logger.LogWarning("Backup {BackupId} storage cleanup will be retried ({ExceptionType}).", backup.Id, ex.GetType().Name);
            }
            using var historyRecovery = CancellationTokenSource.CreateLinkedTokenSource(connectionLost);
            historyRecovery.CancelAfter(TimeSpan.FromSeconds(15));
            try
            {
                await SettingsGate.WaitAsync(historyRecovery.Token);
                try
                {
                    await using var settings = await _repository.AcquireSettingsLockAsync(historyRecovery.Token);
                    if (occurrence.HasValue)
                    {
                        var schedule = await _repository.GetScheduleAsync(historyRecovery.Token);
                        if (schedule != null && schedule.Enabled && schedule.UpdatedAt == scheduleUpdatedAt &&
                            schedule.LastAttemptScheduledAt == occurrence)
                            schedule.NextRetryAt = DateTime.UtcNow.Add(RetryDelay);
                    }
                    await _repository.SaveChangesAsync(historyRecovery.Token);
                }
                finally { SettingsGate.Release(); }
            }
            catch (Exception ex)
            {
                _logger.LogWarning("Backup {BackupId} failure recording requires recovery ({ExceptionType}).", backup.Id, ex.GetType().Name);
            }
        }

        private void DeleteTemporaryFile(string path)
        {
            try { File.Delete(path); }
            catch (Exception ex)
            {
                _logger.LogWarning("A backup temporary file could not be removed; startup cleanup will retry ({ExceptionType}).", ex.GetType().Name);
            }
        }

        public async Task CleanupAsync(CancellationToken cancellationToken)
        {
            if (!await ExecutionGate.WaitAsync(0, cancellationToken)) return;
            try
            {
                await using var operation = await _repository.TryAcquireOperationLockAsync(cancellationToken);
                if (operation is null) return;
                using var owned = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken, operation.ConnectionLost);
                cancellationToken = owned.Token;
                await InitializeCoreAsync(cancellationToken);
                await CleanupCoreAsync(cancellationToken);
            }
            finally { ExecutionGate.Release(); }
        }

        private async Task CleanupCoreAsync(CancellationToken cancellationToken)
        {
            CleanupTemporaryFiles();
            await SettingsGate.WaitAsync(cancellationToken);
            try
            {
                await using var settings = await _repository.AcquireSettingsLockAsync(cancellationToken);
                // Keep retention changes atomic with selecting and deleting expired objects.
                foreach (var backup in await _repository.GetCleanupCandidatesAsync(DateTime.UtcNow, cancellationToken))
                {
                    var previousCleanupPending = backup.StorageCleanupPending;
                    try
                    {
                        using var timeout = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken);
                        timeout.CancelAfter(TimeSpan.FromSeconds(30));
                        await _storage.DeleteAllVersionsAsync(B2BucketType.Backups, backup.B2Key, timeout.Token);
                        backup.DeletedAt = DateTime.UtcNow;
                        backup.StorageCleanupPending = false;
                        await _repository.SaveChangesAsync(timeout.Token);
                        await RecordBackupAuditAsync(backup.Id, "CleanupBackup", LogResult.Success, "Expired backup was removed from storage.");
                    }
                    catch (Exception ex) when (!cancellationToken.IsCancellationRequested)
                    {
                        backup.DeletedAt = null;
                        backup.StorageCleanupPending = previousCleanupPending;
                        await RecordBackupAuditAsync(backup.Id, "CleanupBackup", LogResult.Failed, "Backup storage cleanup failed and will be retried.");
                        _logger.LogWarning("Backup {BackupId} retention cleanup will be retried ({ExceptionType}).", backup.Id, ex.GetType().Name);
                    }
                }
            }
            finally { SettingsGate.Release(); }
        }

        private Task RecordBackupAuditAsync(int id, string action, LogResult result, string details)
            => _auditService.RecordAsync(new AuditLog
            {
                UserId = _audit.Entry?.UserId, Role = _audit.Entry?.Role,
                Action = action, Module = Module.Backups,
                TargetId = id.ToString(CultureInfo.InvariantCulture), Result = result, Details = details
            });

        public async Task<BackupScheduleResponse> GetScheduleAsync(CancellationToken cancellationToken)
        {
            await SettingsGate.WaitAsync(cancellationToken);
            try
            {
                await using var settings = await _repository.AcquireSettingsLockAsync(cancellationToken);
                return ToScheduleResponse(await GetOrCreateScheduleAsync(cancellationToken));
            }
            finally { SettingsGate.Release(); }
        }

        public async Task<BackupScheduleResponse> UpdateScheduleAsync(UpdateBackupScheduleRequest request, CancellationToken cancellationToken)
        {
            var time = ValidateSchedule(request);
            await SettingsGate.WaitAsync(cancellationToken);
            try
            {
                await using var settings = await _repository.AcquireSettingsLockAsync(cancellationToken);
                var schedule = await GetOrCreateScheduleAsync(cancellationToken);
                await _unitOfWork.BeginTransactionAsync();
                try
                {
                    var schedulingChanged = schedule.Enabled != request.Enabled || schedule.Frequency != request.Frequency ||
                        schedule.DayOfWeek != request.DayOfWeek || schedule.Time != time;
                    schedule.Enabled = request.Enabled!.Value;
                    schedule.Frequency = request.Frequency!.Value;
                    schedule.DayOfWeek = request.DayOfWeek;
                    schedule.Time = time;
                    schedule.RetentionDays = request.RetentionDays!.Value;
                    // Retention-only edits must not erase a pending scheduled occurrence.
                    if (schedulingChanged)
                    {
                        schedule.UpdatedAt = DateTime.UtcNow;
                        schedule.LastAttemptScheduledAt = null;
                        schedule.NextRetryAt = null;
                    }
                    await _repository.UpdateExpirationAsync(schedule.RetentionDays, cancellationToken);
                    await _repository.SaveChangesAsync(cancellationToken);
                    await _unitOfWork.CommitAsync();
                }
                catch
                {
                    await _unitOfWork.RollbackAsync();
                    throw;
                }
                return ToScheduleResponse(schedule);
            }
            finally { SettingsGate.Release(); }
        }

        private static TimeOnly ValidateSchedule(UpdateBackupScheduleRequest request)
        {
            if (!request.Enabled.HasValue || !request.Frequency.HasValue || !Enum.IsDefined(request.Frequency.Value))
                throw new ValidationException("Enabled and a valid Daily or Weekly frequency are required.");
            if (request.Frequency == BackupFrequency.Weekly &&
                (!request.DayOfWeek.HasValue || !Enum.IsDefined(request.DayOfWeek.Value)))
                throw new ValidationException("A valid day of week is required for weekly backups.");
            if (request.Frequency == BackupFrequency.Daily && request.DayOfWeek.HasValue)
                throw new ValidationException("Day of week must be omitted for daily backups.");
            if (request.Time == null || request.Time.Length != 5 ||
                !TimeOnly.TryParseExact(request.Time, "HH:mm", CultureInfo.InvariantCulture, DateTimeStyles.None, out var time))
                throw new ValidationException("Time must use HH:mm in Philippine Time.");
            if (!request.RetentionDays.HasValue || request.RetentionDays is < 1 or > 365)
                throw new ValidationException("Retention must be between 1 and 365 days.");
            return time;
        }

        private static DateTime LatestOccurrence(BackupSchedule schedule, DateTime now)
        {
            var localNow = TimeZoneInfo.ConvertTimeFromUtc(now, Manila);
            var candidate = DateTime.SpecifyKind(localNow.Date.Add(schedule.Time.ToTimeSpan()), DateTimeKind.Unspecified);
            if (schedule.Frequency == BackupFrequency.Weekly)
            {
                var days = ((int)candidate.DayOfWeek - (int)schedule.DayOfWeek!.Value + 7) % 7;
                candidate = candidate.AddDays(-days);
                if (candidate > localNow) candidate = candidate.AddDays(-7);
            }
            else if (candidate > localNow) candidate = candidate.AddDays(-1);
            return TimeZoneInfo.ConvertTimeToUtc(candidate, Manila);
        }

        private static DateTime? NextOccurrence(BackupSchedule schedule, DateTime now)
        {
            if (!schedule.Enabled) return null;
            var latest = LatestOccurrence(schedule, now);
            if (latest >= schedule.UpdatedAt &&
                (!schedule.LastAttemptScheduledAt.HasValue || latest > schedule.LastAttemptScheduledAt))
                return latest; // Overdue work is still the next backup, including a catch-up after downtime.
            var next = latest.AddDays(schedule.Frequency == BackupFrequency.Daily ? 1 : 7);
            if (latest >= schedule.UpdatedAt && latest == schedule.LastAttemptScheduledAt &&
                schedule.NextRetryAt.HasValue && schedule.NextRetryAt.Value < next)
                return schedule.NextRetryAt.Value;
            return next;
        }

        public async Task<PageResponse<BackupResponse>> GetHistoryAsync(int offset, CancellationToken cancellationToken)
        {
            if (offset < 0) throw new ValidationException("Offset cannot be negative.");
            var backups = await _repository.GetHistoryAsync(offset, PAGE_SIZE, cancellationToken);
            return new PageResponse<BackupResponse>
            {
                Items = backups.Take(PAGE_SIZE).Select(ToResponse).ToList(),
                HasMore = backups.Count > PAGE_SIZE,
                Total = await _repository.GetHistoryCountAsync(cancellationToken)
            };
        }

        public async Task<BackupHealthResponse> GetHealthAsync(CancellationToken cancellationToken)
        {
            await SettingsGate.WaitAsync(cancellationToken);
            try
            {
                await using var settings = await _repository.AcquireSettingsLockAsync(cancellationToken);
                var schedule = await GetOrCreateScheduleAsync(cancellationToken);
                var latest = await _repository.GetLatestAsync(false, cancellationToken);
                var completed = await _repository.GetLatestAsync(true, cancellationToken);
                return new BackupHealthResponse
                {
                    LatestAttempt = latest == null ? null : ToResponse(latest),
                    LatestSuccessfulBackup = completed == null ? null : ToResponse(completed),
                    IsRunning = await _repository.IsRunningAsync(cancellationToken),
                    Enabled = schedule.Enabled,
                    RetentionDays = schedule.RetentionDays,
                    NextScheduledAt = NextOccurrence(schedule, DateTime.UtcNow)
                };
            }
            finally { SettingsGate.Release(); }
        }

        public async Task<(Stream Stream, string FileName, IDisposable Owner)> DownloadAsync(int id, CancellationToken cancellationToken)
        {
            if (id <= 0) throw new ValidationException("Backup ID must be positive.");
            var backup = await _repository.GetByIdAsync(id, cancellationToken)
                ?? throw new RecordNotFoundException("Backup was not found.");
            if (!ToResponse(backup).CanDownload) throw new InvalidRequestException("This backup is not available for download.");
            var file = await _storage.DownloadStreamAsync(B2BucketType.Backups, backup.B2Key, cancellationToken);
            return (file.Stream, $"marikina-market-{backup.Id}-{backup.DateTime:yyyyMMdd-HHmmss}.mmbak", file.Owner);
        }

        private const string RestoreConfirmation = "RESTORE";
        // How long a restore waits for requests already running (for example a ticket being saved) to finish.
        private static readonly TimeSpan RestorePauseWait = TimeSpan.FromSeconds(30);
        private const int EnvelopeLength = 33; // header 5, nonce 12, tag 16
        private const int MaxUploadNameLength = 100;
        private const string RestoredMessage = "The backup was restored. Everyone has been signed out and must sign in again.";
        private const string NotFoundMessage = "This backup is no longer available. Nothing was changed.";
        private const string DownloadMessage = "This backup could not be downloaded from storage. Nothing was changed.";
        private const string UnlockMessage = "This backup could not be unlocked. It may be damaged, or it was made by another copy of the system. Nothing was changed.";
        private const string VersionMessage = "This backup is from a different version of the system, so it cannot be restored here. " +
            "Ask the technical person to restore it with the recovery guide.";
        private const string BusyMessage = "Some work was still being saved, so the restore did not start. Nothing was changed. Try again in a moment.";
        private const string SafetyMessage = "The safety backup of today's data could not be made, so nothing was restored.";
        private const string LoadMessage = "The backup could not be loaded. Today's data is unchanged.";
        private const string CountMessage = "The backup was restored and everyone has been signed out, but the records could not be counted.";
        private const string UnexpectedMessage = "The restore stopped because of an unexpected problem. Today's data is unchanged.";

        // A restore step that failed in a way the Head Admin is told about in plain words.
        private sealed class RestoreFailure(string message) : Exception(message);

        public async Task<BackupRestoreResponse> StartRestoreAsync(int id, RestoreBackupRequest request, int adminId,
            CancellationToken cancellationToken)
        {
            if (id <= 0) throw new ValidationException("Backup ID must be positive.");
            await CheckRestoreConfirmationAsync(request, adminId);
            var backup = await _repository.GetByIdAsync(id, cancellationToken)
                ?? throw new RecordNotFoundException("Backup was not found.");
            if (!ToResponse(backup).CanDownload) throw new InvalidRequestException("This backup cannot be restored.");
            if (!await ExecutionGate.WaitAsync(0, cancellationToken))
                throw new ConcurrencyConflictException("A backup or restore is already running.");

            var started = _restore.Begin(backup, adminId);
            RunRestoreInBackground(started.RestoreId);
            return started;
        }

        // The uploaded file is kept only in the server's temporary folder, and only until its restore ends.
        public async Task<BackupRestoreResponse> StartUploadRestoreAsync(RestoreUploadRequest request, int adminId,
            CancellationToken cancellationToken)
        {
            await CheckRestoreConfirmationAsync(request, adminId);
            var file = request.File;
            if (file is null || file.Length == 0) throw new ValidationException("Choose a backup file to restore.");
            if (!file.FileName.EndsWith(".mmbak", StringComparison.OrdinalIgnoreCase))
                throw new ValidationException("Choose a .mmbak backup file.");
            if (file.Length > MaxDumpSize + EnvelopeLength) throw new ValidationException("This file is too large to be a backup.");
            if (!await ExecutionGate.WaitAsync(0, cancellationToken))
                throw new ConcurrencyConflictException("A backup or restore is already running.");

            string? path = null;
            try
            {
                PrepareTempRoot();
                path = Path.Combine(TempRoot, Guid.NewGuid().ToString("N") + ".restore-upload.tmp");
                await using var output = new FileStream(path, FileMode.CreateNew, FileAccess.Write, FileShare.None, 81920, FileOptions.Asynchronous);
                await file.CopyToAsync(output, cancellationToken);
            }
            catch
            {
                if (path != null) DeleteTemporaryFile(path);
                ExecutionGate.Release();
                throw;
            }
            var name = Path.GetFileName(file.FileName);
            // Short enough for the audit log entry that names it.
            if (name.Length > MaxUploadNameLength) name = name[..MaxUploadNameLength];
            var started = _restore.BeginUpload(name, file.Length, path, adminId);
            RunRestoreInBackground(started.RestoreId);
            return started;
        }

        private async Task CheckRestoreConfirmationAsync(RestoreBackupRequest request, int adminId)
        {
            if (request.Confirmation != RestoreConfirmation) throw new ValidationException("Type RESTORE to confirm.");
            if (string.IsNullOrEmpty(request.Password)) throw new ValidationException("Enter your password to confirm.");
            var admin = await _users.GetUserAsync(adminId) ?? throw new UnauthorizedAccessException("Your account was not found.");
            var password = await _users.CheckPasswordAsync(admin, request.Password);
            if (password.IsLockedOut) throw new AccountLockedException("Too many attempts. Please try again later.");
            if (!password.Succeeded) throw new InvalidCredentialsException("Password is incorrect.");
        }

        // Called with the execution gate held. The gate stays held until the restore ends, so no backup
        // or clean-up runs in the meantime.
        private void RunRestoreInBackground(string restoreId) => _ = Task.Run(async () =>
        {
            try
            {
                using var scope = _scopes.CreateScope();
                await scope.ServiceProvider.GetRequiredService<IBackupService>().RunRestoreAsync(restoreId);
            }
            catch (Exception ex)
            {
                _restore.Resume();
                _logger.LogWarning("Restore {RestoreId} could not run ({ExceptionType}).", restoreId, ex.GetType().Name);
            }
            finally { ExecutionGate.Release(); }
        });

        public BackupRestoreResponse GetRestoreProgress(string restoreId)
            => _restore.Get(restoreId) ?? throw new RecordNotFoundException("Restore was not found.");

        public async Task RunRestoreAsync(string restoreId)
        {
            var progress = _restore.Get(restoreId) ?? throw new RecordNotFoundException("Restore was not found.");
            var adminId = _restore.AdminId;
            var uploadPath = _restore.UploadPath;
            var source = uploadPath is null ? $"backup {progress.BackupId}"
                : $"uploaded backup file {progress.FileName} ({_restore.UploadSize.ToString("N0", CultureInfo.InvariantCulture)} bytes)";
            var tempId = Guid.NewGuid().ToString("N");
            var encryptedPath = uploadPath ?? Path.Combine(TempRoot, tempId + ".restore-encrypted.tmp");
            var dumpPath = Path.Combine(TempRoot, tempId + ".restore-dump.tmp");
            var listPath = Path.Combine(TempRoot, tempId + ".restore-list.tmp");
            var scriptPath = Path.Combine(TempRoot, tempId + ".restore-script.tmp");
            var step = RestoreStep.CheckBackup;
            byte[]? key = null;
            try
            {
                key = ReadEncryptionKey();
                PrepareTempRoot();
                await using var operation = await _repository.TryAcquireOperationLockAsync(_lifetime.ApplicationStopping)
                    ?? throw new RestoreFailure("A backup is already running on another server. Nothing was changed.");
                using var owned = CancellationTokenSource.CreateLinkedTokenSource(_lifetime.ApplicationStopping, operation.ConnectionLost);
                var cancellationToken = owned.Token;

                SetStep(step, RestoreStepState.Running);
                if (uploadPath is null)
                {
                    var backup = await _repository.GetByIdAsync(progress.BackupId!.Value, cancellationToken);
                    if (backup is null || !ToResponse(backup).CanDownload) throw new RestoreFailure(NotFoundMessage);
                    using var download = Timeout(cancellationToken);
                    await DownloadBackupAsync(backup.B2Key, encryptedPath, download.Token);
                }
                using (var timeout = Timeout(cancellationToken))
                {
                    await DecryptBackupAsync(encryptedPath, dumpPath, key, timeout.Token);
                    File.Delete(encryptedPath);
                    if (!await HasTodaysVersionAsync(dumpPath, listPath, timeout.Token)) throw new RestoreFailure(VersionMessage);
                }
                SetStep(step, RestoreStepState.Done);

                if (!await _restore.PauseAsync(RestorePauseWait, cancellationToken)) throw new RestoreFailure(BusyMessage);
                var before = await _repository.CountRestoreRecordsAsync(cancellationToken);
                _restore.Update(restore => restore.Counts = Counts(before).Select(count =>
                    new RestoreCountResponse { Records = count.Records, Before = count.Value }).ToList());

                step = RestoreStep.SafetyBackup;
                SetStep(step, RestoreStepState.Running);
                var safety = await MakeSafetyBackupAsync(cancellationToken, operation.ConnectionLost);
                _restore.Update(restore => restore.SafetyBackupId = safety.Id);
                SetStep(step, RestoreStepState.Done);

                step = RestoreStep.LoadBackup;
                SetStep(step, RestoreStepState.Running);
                SetStep(RestoreStep.SignEveryoneOut, RestoreStepState.Running);
                using (var timeout = Timeout(cancellationToken))
                    await LoadBackupAsync(dumpPath, listPath, scriptPath, timeout.Token);
                SetStep(step, RestoreStepState.Done);
                SetStep(RestoreStep.SignEveryoneOut, RestoreStepState.Done);

                step = RestoreStep.CountRecords;
                SetStep(step, RestoreStepState.Running);
                var message = RestoredMessage;
                try
                {
                    var after = Counts(await _repository.CountRestoreRecordsAsync(cancellationToken)).ToDictionary(c => c.Records, c => c.Value);
                    _restore.Update(restore => restore.Counts.ForEach(count => count.After = after[count.Records]));
                    SetStep(step, RestoreStepState.Done);
                }
                catch (Exception ex)
                {
                    _logger.LogWarning("Restore {RestoreId} could not count records ({ExceptionType}).", restoreId, ex.GetType().Name);
                    SetStep(step, RestoreStepState.Failed);
                    message = CountMessage;
                }
                _restore.Resume();
                await RecordRestoreAuditAsync(progress.BackupId, adminId, LogResult.Success,
                    $"{char.ToUpperInvariant(source[0])}{source[1..]} was restored. Safety backup {safety.Id} holds the data from before the restore.");
                Finish(RestoreState.Finished, message);
            }
            catch (Exception ex)
            {
                var message = ex is RestoreFailure ? ex.Message : UnexpectedMessage;
                if (ex is not RestoreFailure)
                    _logger.LogWarning("Restore {RestoreId} failed during {Step} ({ExceptionType}).", restoreId, step, ex.GetType().Name);
                SetStep(step, RestoreStepState.Failed);
                _restore.Resume();
                await RecordRestoreAuditAsync(progress.BackupId, adminId, LogResult.Failed, $"Restore of {source} failed: {message}");
                Finish(RestoreState.Failed, message);
            }
            finally
            {
                _restore.Resume();
                if (key != null) CryptographicOperations.ZeroMemory(key);
                foreach (var path in new[] { encryptedPath, dumpPath, listPath, scriptPath }) DeleteTemporaryFile(path);
            }
        }

        private CancellationTokenSource Timeout(CancellationToken cancellationToken)
        {
            var timeout = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken);
            timeout.CancelAfter(ReadTimeout());
            return timeout;
        }

        private async Task DownloadBackupAsync(string b2Key, string path, CancellationToken cancellationToken)
        {
            try
            {
                var file = await _storage.DownloadStreamAsync(B2BucketType.Backups, b2Key, cancellationToken);
                using var owner = file.Owner;
                await using var stream = file.Stream;
                await using var output = new FileStream(path, FileMode.CreateNew, FileAccess.Write, FileShare.None, 81920, FileOptions.Asynchronous);
                await stream.CopyToAsync(output, cancellationToken);
            }
            catch (Exception ex) when (!cancellationToken.IsCancellationRequested)
            {
                _logger.LogWarning("A backup could not be downloaded for a restore ({ExceptionType}).", ex.GetType().Name);
                throw new RestoreFailure(DownloadMessage);
            }
        }

        private static async Task DecryptBackupAsync(string encryptedPath, string dumpPath, byte[] key, CancellationToken cancellationToken)
        {
            var length = new FileInfo(encryptedPath).Length;
            if (length <= EnvelopeLength || length > MaxDumpSize + EnvelopeLength) throw new RestoreFailure(UnlockMessage);
            byte[]? file = null;
            byte[]? plaintext = null;
            try
            {
                file = await File.ReadAllBytesAsync(encryptedPath, cancellationToken);
                if (!file.AsSpan(0, EnvelopeHeader.Length).SequenceEqual(EnvelopeHeader)) throw new RestoreFailure(UnlockMessage);
                plaintext = new byte[file.Length - EnvelopeLength];
                try
                {
                    using var aes = new AesGcm(key, 16);
                    aes.Decrypt(file.AsSpan(5, 12), file.AsSpan(EnvelopeLength), file.AsSpan(17, 16), plaintext, EnvelopeHeader);
                }
                catch (CryptographicException) { throw new RestoreFailure(UnlockMessage); }
                await using var output = new FileStream(dumpPath, FileMode.CreateNew, FileAccess.Write, FileShare.None, 81920, FileOptions.Asynchronous);
                await output.WriteAsync(plaintext, cancellationToken);
            }
            finally
            {
                if (file != null) CryptographicOperations.ZeroMemory(file);
                if (plaintext != null) CryptographicOperations.ZeroMemory(plaintext);
            }
        }

        // The backup must have exactly the database changes (migrations) today's database has.
        private async Task<bool> HasTodaysVersionAsync(string dumpPath, string outputPath, CancellationToken cancellationToken)
        {
            await RunPostgresToolAsync("pg_restore",
                ["--data-only", "--table=__EFMigrationsHistory", "--file", outputPath, dumpPath], cancellationToken);
            var inBackup = (await File.ReadAllLinesAsync(outputPath, cancellationToken))
                .SkipWhile(line => !line.StartsWith("COPY ", StringComparison.Ordinal)).Skip(1)
                .TakeWhile(line => line != "\\.")
                .Select(line => line.Split('\t')[0]).ToHashSet();
            File.Delete(outputPath);
            return inBackup.SetEquals(await _repository.GetAppliedMigrationsAsync(cancellationToken));
        }

        private async Task<BackupResponse> MakeSafetyBackupAsync(CancellationToken cancellationToken, CancellationToken connectionLost)
        {
            try
            {
                var attempt = (await StartAttemptAsync(BackupType.BeforeRestore, cancellationToken))!.Value;
                return await ExecuteBackupAsync(attempt.Backup, null, attempt.ScheduleUpdatedAt, cancellationToken, connectionLost);
            }
            catch (Exception ex) when (!cancellationToken.IsCancellationRequested)
            {
                _logger.LogWarning("The safety backup before a restore failed ({ExceptionType}).", ex.GetType().Name);
                throw new RestoreFailure(SafetyMessage);
            }
        }

        // Replaces everything except the kept tables, and signs everyone out, in one transaction:
        // if anything fails, PostgreSQL undoes all of it and today's data stays as it was.
        private async Task LoadBackupAsync(string dumpPath, string listPath, string scriptPath, CancellationToken cancellationToken)
        {
            try
            {
                await RunPostgresToolAsync("pg_restore", ["--list", "--file", listPath, dumpPath], cancellationToken);
                var kept = await _repository.GetRestoreKeptNamesAsync(cancellationToken);
                await File.WriteAllLinesAsync(listPath,
                    RestoreListWithout(await File.ReadAllLinesAsync(listPath, cancellationToken), kept), cancellationToken);
                await RunPostgresToolAsync("pg_restore", ["--clean", "--if-exists", "--no-owner", "--no-privileges",
                    "--use-list", listPath, "--file", scriptPath, dumpPath], cancellationToken);
                await File.AppendAllTextAsync(scriptPath, Environment.NewLine + _repository.SignOutEveryoneSql, cancellationToken);
                await RunPostgresToolAsync("psql", ["--no-psqlrc", "--quiet", "--single-transaction",
                    "--set", "ON_ERROR_STOP=1", "--file", scriptPath], cancellationToken);
            }
            catch (Exception ex) when (!cancellationToken.IsCancellationRequested)
            {
                _logger.LogWarning("A backup could not be loaded ({ExceptionType}).", ex.GetType().Name);
                throw new RestoreFailure(LoadMessage);
            }
        }

        // Drops every entry of the backup's contents list that belongs to a kept table: the table, its data,
        // constraints, indexes and sequences. Entry lines read "id; oid oid TYPE schema name [name] owner".
        public static List<string> RestoreListWithout(IEnumerable<string> list, IReadOnlySet<string> kept)
            => list.Where(line =>
            {
                if (line.StartsWith(';')) return true;
                var words = line.Split(' ', StringSplitOptions.RemoveEmptyEntries);
                var schema = Array.IndexOf(words, "public", Math.Min(3, words.Length));
                return schema < 0 || schema + 1 >= words.Length || !kept.Contains(words[schema + 1]);
            }).ToList();

        private static IEnumerable<(RestoreCount Records, int Value)> Counts(RestoreRecordCounts counts) =>
        [
            (RestoreCount.Tickets, counts.Tickets), (RestoreCount.Businesses, counts.Businesses),
            (RestoreCount.People, counts.People), (RestoreCount.Accounts, counts.Accounts)
        ];

        private void SetStep(RestoreStep step, RestoreStepState state)
            => _restore.Update(restore => restore.Steps.Single(s => s.Step == step).State = state);

        private void Finish(RestoreState state, string message) => _restore.Update(restore =>
        {
            restore.State = state;
            restore.Message = message;
            restore.FinishedAt = DateTime.UtcNow;
        });

        // Runs outside a request, so the Head Admin who started the restore is named explicitly.
        private Task RecordRestoreAuditAsync(int? backupId, int adminId, LogResult result, string details)
            => _auditService.RecordAsync(new AuditLog
            {
                UserId = adminId, Role = Role.HeadAdmin, Action = "RestoreBackup", Module = Module.Backups,
                TargetId = backupId?.ToString(CultureInfo.InvariantCulture), Result = result, Details = details
            });

        private static BackupResponse ToResponse(Backup backup)
        {
            var canDownload = backup.IsFinalized && backup.Status == BackupStatus.Completed &&
                backup.DeletedAt == null && backup.ExpiresAt > DateTime.UtcNow;
            return new BackupResponse
            {
                Id = backup.Id, DateTime = backup.DateTime, Type = backup.Type, Size = backup.Size,
                Status = backup.Status, CompletedAt = backup.CompletedAt, ExpiresAt = backup.ExpiresAt,
                ErrorMessage = backup.ErrorMessage, CanDownload = canDownload,
                DownloadRoute = canDownload ? $"/api/admin/backups/{backup.Id}/download" : null
            };
        }

        private static BackupScheduleResponse ToScheduleResponse(BackupSchedule schedule) => new()
        {
            Enabled = schedule.Enabled, Frequency = schedule.Frequency, DayOfWeek = schedule.DayOfWeek,
            Time = schedule.Time.ToString("HH:mm", CultureInfo.InvariantCulture), RetentionDays = schedule.RetentionDays
        };
    }
}
