namespace MarikinaMarket.API.Application.DTOs.Backups.Request
{
    public class RestoreBackupRequest
    {
        // Must be exactly RESTORE.
        public string? Confirmation { get; set; }
        // The Head Admin's own password, checked again.
        public string? Password { get; set; }
    }
}
