using MarikinaMarket.API.Domain.Enums;

namespace MarikinaMarket.API.Application.DTOs.Backups.Response
{
    public class BackupRestoreResponse
    {
        public string RestoreId { get; set; } = "";
        // Both null when the backup is an uploaded file; FileName is then its name.
        public int? BackupId { get; set; }
        public DateTime? BackupDateTime { get; set; }
        public string? FileName { get; set; }
        public RestoreState State { get; set; }
        public List<RestoreStepResponse> Steps { get; set; } = [];
        // Filled once the system is paused (before) and once the backup is loaded (after).
        public List<RestoreCountResponse> Counts { get; set; } = [];
        public int? SafetyBackupId { get; set; }
        public string? Message { get; set; }
        public DateTime StartedAt { get; set; }
        public DateTime? FinishedAt { get; set; }
    }

    public class RestoreStepResponse
    {
        public RestoreStep Step { get; set; }
        public RestoreStepState State { get; set; }
    }

    public class RestoreCountResponse
    {
        public RestoreCount Records { get; set; }
        public int Before { get; set; }
        public int? After { get; set; }
    }
}
