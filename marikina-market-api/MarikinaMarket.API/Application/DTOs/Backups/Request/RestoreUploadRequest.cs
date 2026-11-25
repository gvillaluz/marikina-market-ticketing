namespace MarikinaMarket.API.Application.DTOs.Backups.Request
{
    public class RestoreUploadRequest : RestoreBackupRequest
    {
        // A .mmbak file downloaded from the Backups page.
        public IFormFile? File { get; set; }
    }
}
