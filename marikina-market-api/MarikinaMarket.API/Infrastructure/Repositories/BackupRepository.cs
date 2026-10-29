using MarikinaMarket.API.Application.Interfaces.Repositories;
using MarikinaMarket.API.Domain.Entities;
using MarikinaMarket.API.Domain.Enums;
using MarikinaMarket.API.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Storage;
using Npgsql;
using System.Data;

namespace MarikinaMarket.API.Infrastructure.Repositories
{
    public class BackupRepository : IBackupRepository, IDisposable
    {
        private const int LockNamespace = 0x4D4D424B;
        private const int OperationLock = 1;
        private const int SettingsLock = 2;
        private readonly AppDbContext _context;
        private readonly CancellationTokenSource _connectionLost = new();
        private NpgsqlConnection? _connection;
        private string? _connectionString;
        private int _pins;
        private bool _closing;
        public BackupRepository(AppDbContext context) => _context = context;

        public async Task<IBackupOperationLock?> TryAcquireOperationLockAsync(CancellationToken cancellationToken)
        {
            using var linked = Link(cancellationToken);
            await PinAsync(linked.Token);
            try
            {
                if ((bool)(await LockCommandAsync("SELECT pg_try_advisory_lock(@namespace,@key)", OperationLock, linked.Token))!)
                    return new HeldLock(this, OperationLock);
            }
            catch
            {
                // The server may have granted the lock before a canceled or
                // failed response reached us. Explicitly release that possibility.
                await ReleaseAsync(OperationLock);
                throw;
            }
            await UnpinAsync();
            return null;
        }

        public async Task<IBackupOperationLock> AcquireSettingsLockAsync(CancellationToken cancellationToken)
        {
            using var linked = Link(cancellationToken);
            await PinAsync(linked.Token);
            try
            {
                await LockCommandAsync("SELECT pg_advisory_lock(@namespace,@key)", SettingsLock, linked.Token);
                return new HeldLock(this, SettingsLock);
            }
            catch
            {
                await ReleaseAsync(SettingsLock);
                throw;
            }
        }

        private async Task PinAsync(CancellationToken cancellationToken)
        {
            _connectionLost.Token.ThrowIfCancellationRequested();
            if (_connection is null)
            {
                _connection = (NpgsqlConnection)_context.Database.GetDbConnection();
                _connectionString = _connection.ConnectionString;
                _connection.StateChange += ConnectionStateChanged;
            }
            if (_pins == 0)
            {
                if (_connection.State != ConnectionState.Closed)
                    throw new InvalidOperationException("Backup coordination requires an unopened scoped connection.");
                // Keep the same physical session throughout dump/upload and short EF
                // transactions. Idle keepalive detects loss while external work runs.
                _connection.ConnectionString = new NpgsqlConnectionStringBuilder(_connectionString) { KeepAlive = 2 }.ConnectionString;
            }
            await _context.Database.OpenConnectionAsync(cancellationToken);
            _pins++;
        }

        private void ConnectionStateChanged(object? sender, StateChangeEventArgs change)
        {
            if (!_closing && _pins > 0 && change.OriginalState == ConnectionState.Open && change.CurrentState != ConnectionState.Open)
                _connectionLost.Cancel();
        }

        private async Task<object?> LockCommandAsync(string sql, int key, CancellationToken cancellationToken)
        {
            await using var command = new NpgsqlCommand(sql, _connection,
                (NpgsqlTransaction?)_context.Database.CurrentTransaction?.GetDbTransaction());
            command.CommandTimeout = 0;
            command.Parameters.AddWithValue("namespace", LockNamespace);
            command.Parameters.AddWithValue("key", key);
            return await command.ExecuteScalarAsync(cancellationToken);
        }

        private async Task UnpinAsync()
        {
            // A nested settings guard does not close the operation's session;
            // unexpected loss during that release must still cancel its owner.
            _closing = _pins == 1;
            try { await _context.Database.CloseConnectionAsync(); }
            finally { _pins--; _closing = false; }
        }

        private async ValueTask ReleaseAsync(int key)
        {
            try
            {
                if (!_connectionLost.IsCancellationRequested && _connection!.State == ConnectionState.Open)
                {
                    using var timeout = new CancellationTokenSource(TimeSpan.FromSeconds(5));
                    await LockCommandAsync("SELECT pg_advisory_unlock(@namespace,@key)", key, timeout.Token);
                }
            }
            catch
            {
                _connectionLost.Cancel();
                // Do not return a session with uncertain ownership to the pool.
                NpgsqlConnection.ClearPool(_connection!);
            }
            finally { await UnpinAsync(); }
        }

        private CancellationTokenSource Link(CancellationToken cancellationToken)
            => CancellationTokenSource.CreateLinkedTokenSource(cancellationToken, _connectionLost.Token);

        private sealed class HeldLock(BackupRepository repository, int key) : IBackupOperationLock
        {
            private bool _disposed;
            public CancellationToken ConnectionLost => repository._connectionLost.Token;
            public async ValueTask DisposeAsync()
            {
                if (_disposed) return;
                _disposed = true;
                await repository.ReleaseAsync(key);
            }
        }

        public async Task<bool> IsRunningAsync(CancellationToken cancellationToken)
        {
            using var linked = Link(cancellationToken);
            return await _context.Database.SqlQueryRaw<bool>("""
                SELECT EXISTS (
                    SELECT 1 FROM pg_locks WHERE locktype='advisory' AND granted
                    AND database=(SELECT oid FROM pg_database WHERE datname=current_database())
                    AND classid=CAST(@namespace AS oid) AND objid=1::oid AND objsubid=2
                ) AND EXISTS (SELECT 1 FROM backups WHERE NOT is_finalized) AS "Value"
                """, new NpgsqlParameter("namespace", LockNamespace)).SingleAsync(linked.Token);
        }

        public async Task<BackupSchedule?> GetScheduleAsync(CancellationToken cancellationToken)
        {
            using var linked = Link(cancellationToken);
            var tracked = _context.BackupSchedules.Local.SingleOrDefault(x => x.Id == 1);
            if (tracked != null)
            {
                // A backup can outlive a schedule edit made by another request scope.
                await _context.Entry(tracked).ReloadAsync(linked.Token);
                return tracked;
            }
            return await _context.BackupSchedules.SingleOrDefaultAsync(x => x.Id == 1, linked.Token);
        }

        public void AddSchedule(BackupSchedule schedule)
        {
            _connectionLost.Token.ThrowIfCancellationRequested();
            _context.BackupSchedules.Add(schedule);
        }
        public void AddBackup(Backup backup)
        {
            _connectionLost.Token.ThrowIfCancellationRequested();
            _context.Backups.Add(backup);
        }
        public async Task<Backup?> GetByIdAsync(int id, CancellationToken cancellationToken)
        {
            using var linked = Link(cancellationToken);
            return await _context.Backups.SingleOrDefaultAsync(x => x.Id == id, linked.Token);
        }

        public async Task<List<Backup>> GetHistoryAsync(int offset, int limit, CancellationToken cancellationToken)
        {
            using var linked = Link(cancellationToken);
            return await _context.Backups.AsNoTracking().Where(x => x.IsFinalized)
                .OrderByDescending(x => x.DateTime).ThenByDescending(x => x.Id)
                .Skip(offset).Take(limit + 1).ToListAsync(linked.Token);
        }

        public async Task<int> GetHistoryCountAsync(CancellationToken cancellationToken)
        {
            using var linked = Link(cancellationToken);
            return await _context.Backups.CountAsync(x => x.IsFinalized, linked.Token);
        }

        public async Task<Backup?> GetLatestAsync(bool completedOnly, CancellationToken cancellationToken)
        {
            using var linked = Link(cancellationToken);
            return await _context.Backups.AsNoTracking().Where(x => x.IsFinalized &&
                    (!completedOnly || x.Status == BackupStatus.Completed))
                .OrderByDescending(x => x.DateTime).ThenByDescending(x => x.Id)
                .FirstOrDefaultAsync(linked.Token);
        }

        public async Task RecoverInterruptedAsync(CancellationToken cancellationToken)
        {
            using var linked = Link(cancellationToken);
            await _context.Backups.Where(x => !x.IsFinalized).ExecuteUpdateAsync(update => update
                .SetProperty(x => x.Status, BackupStatus.Failed)
                .SetProperty(x => x.IsFinalized, true)
                .SetProperty(x => x.ErrorMessage, "Backup was interrupted before completion."), linked.Token);
        }

        public async Task<Backup?> GetLatestAutomaticAsync(CancellationToken cancellationToken)
        {
            using var linked = Link(cancellationToken);
            return await _context.Backups.AsNoTracking().Where(x => x.Type == BackupType.Automatic && x.IsFinalized)
                .OrderByDescending(x => x.DateTime).ThenByDescending(x => x.Id)
                .FirstOrDefaultAsync(linked.Token);
        }

        public async Task UpdateExpirationAsync(int retentionDays, CancellationToken cancellationToken)
        {
            using var linked = Link(cancellationToken);
            await _context.Backups.Where(x => x.Status == BackupStatus.Completed && x.DeletedAt == null)
                .ExecuteUpdateAsync(update => update.SetProperty(x => x.ExpiresAt,
                    x => x.CompletedAt!.Value.AddDays(retentionDays)), linked.Token);
        }

        public async Task<List<Backup>> GetCleanupCandidatesAsync(DateTime now, CancellationToken cancellationToken)
        {
            using var linked = Link(cancellationToken);
            return await _context.Backups.Where(x => x.IsFinalized && x.DeletedAt == null &&
                (x.StorageCleanupPending || (x.Status == BackupStatus.Completed && x.ExpiresAt <= now)))
                .OrderBy(x => x.Id).ToListAsync(linked.Token);
        }

        public async Task SaveChangesAsync(CancellationToken cancellationToken)
        {
            using var linked = Link(cancellationToken);
            await _context.SaveChangesAsync(linked.Token);
        }

        public void Dispose()
        {
            if (_connection is not null) _connection.StateChange -= ConnectionStateChanged;
            _connectionLost.Dispose();
        }
    }
}
