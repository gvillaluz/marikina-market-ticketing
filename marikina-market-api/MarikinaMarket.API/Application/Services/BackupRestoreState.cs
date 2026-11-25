using System.Text.Json;
using MarikinaMarket.API.Application.DTOs.Backups.Response;
using MarikinaMarket.API.Domain.Entities;
using MarikinaMarket.API.Domain.Enums;

namespace MarikinaMarket.API.Application.Services
{
    // Shared by the whole server (one instance, as for the backup scheduler): the latest restore's
    // progress, and whether everyone else is paused while it replaces the data.
    public class BackupRestoreState
    {
        private readonly object _lock = new();
        private BackupRestoreResponse? _current;
        private int _adminId;
        private string? _uploadPath;
        private long _uploadSize;
        private bool _paused;
        private int _requests;

        public bool IsPaused { get { lock (_lock) return _paused; } }

        public BackupRestoreResponse Begin(Backup backup, int adminId)
            => Start(backup.Id, backup.DateTime, null, null, 0, adminId);

        // An uploaded file has no listed backup; its bytes wait in a temporary file until the restore reads them.
        public BackupRestoreResponse BeginUpload(string fileName, long size, string path, int adminId)
            => Start(null, null, fileName, path, size, adminId);

        private BackupRestoreResponse Start(int? backupId, DateTime? backupDateTime, string? fileName,
            string? uploadPath, long uploadSize, int adminId)
        {
            lock (_lock)
            {
                _adminId = adminId;
                _uploadPath = uploadPath;
                _uploadSize = uploadSize;
                _current = new BackupRestoreResponse
                {
                    RestoreId = Guid.NewGuid().ToString("N"),
                    BackupId = backupId,
                    BackupDateTime = backupDateTime,
                    FileName = fileName,
                    State = RestoreState.Running,
                    Steps = Enum.GetValues<RestoreStep>()
                        .Select(step => new RestoreStepResponse { Step = step, State = RestoreStepState.Waiting }).ToList(),
                    StartedAt = DateTime.UtcNow
                };
                return Copy(_current);
            }
        }

        public BackupRestoreResponse? Get(string restoreId)
        {
            lock (_lock) return _current?.RestoreId == restoreId ? Copy(_current) : null;
        }

        public int AdminId { get { lock (_lock) return _adminId; } }

        // Null when the latest restore is of a listed backup.
        public string? UploadPath { get { lock (_lock) return _uploadPath; } }

        public long UploadSize { get { lock (_lock) return _uploadSize; } }

        public void Update(Action<BackupRestoreResponse> change)
        {
            lock (_lock) change(_current!);
        }

        // A request may run only while the system is not paused. Every admitted request must call ExitRequest.
        public bool TryEnterRequest()
        {
            lock (_lock)
            {
                if (_paused) return false;
                _requests++;
                return true;
            }
        }

        public void ExitRequest()
        {
            lock (_lock) _requests--;
        }

        // Stops new requests, then waits until the requests already running have finished.
        // Returns false if they did not finish in time; the system then stays paused until Resume.
        public async Task<bool> PauseAsync(TimeSpan wait, CancellationToken cancellationToken)
        {
            lock (_lock) _paused = true;
            var until = DateTime.UtcNow + wait;
            while (true)
            {
                lock (_lock) if (_requests == 0) return true;
                if (DateTime.UtcNow >= until) return false;
                await Task.Delay(100, cancellationToken);
            }
        }

        public void Resume()
        {
            lock (_lock) _paused = false;
        }

        private static BackupRestoreResponse Copy(BackupRestoreResponse response)
            => JsonSerializer.Deserialize<BackupRestoreResponse>(JsonSerializer.Serialize(response))!;
    }
}
