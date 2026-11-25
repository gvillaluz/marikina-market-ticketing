using MarikinaMarket.API.Application.DTOs.Backups.Request;
using MarikinaMarket.API.Application.DTOs.Backups.Response;
using MarikinaMarket.API.Application.DTOs.Tickets.Response;
using MarikinaMarket.API.Application.Interfaces.Services;
using MarikinaMarket.API.Domain.Enums;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace MarikinaMarket.API.Presentation.Controllers
{
    [ApiController]
    [Route("api/admin/backups")]
    [Authorize(Roles = $"{nameof(Role.HeadAdmin)},{nameof(Role.AdminOfficer)}")]
    public class AdminBackupController : ControllerBase
    {
        private readonly IBackupService _service;
        public AdminBackupController(IBackupService service) => _service = service;

        [HttpPost]
        public async Task<ActionResult<BackupResponse>> Create(CancellationToken cancellationToken)
            => Ok(await _service.CreateManualAsync(cancellationToken));

        [HttpGet]
        public async Task<ActionResult<PageResponse<BackupResponse>>> History(CancellationToken cancellationToken, [FromQuery] int offset = 0)
            => Ok(await _service.GetHistoryAsync(offset, cancellationToken));

        [HttpGet("schedule")]
        public async Task<ActionResult<BackupScheduleResponse>> Schedule(CancellationToken cancellationToken)
            => Ok(await _service.GetScheduleAsync(cancellationToken));

        [HttpPut("schedule")]
        public async Task<ActionResult<BackupScheduleResponse>> UpdateSchedule(
            [FromBody] UpdateBackupScheduleRequest request, CancellationToken cancellationToken)
            => Ok(await _service.UpdateScheduleAsync(request, cancellationToken));

        [HttpGet("health")]
        public async Task<ActionResult<BackupHealthResponse>> Health(CancellationToken cancellationToken)
            => Ok(await _service.GetHealthAsync(cancellationToken));

        // Starts replacing today's data with this backup. Its progress is read from RestoreProgress.
        [HttpPost("{id}/restore")]
        [Authorize(Roles = nameof(Role.HeadAdmin))]
        public async Task<ActionResult<BackupRestoreResponse>> Restore([FromRoute] int id,
            [FromBody] RestoreBackupRequest request, CancellationToken cancellationToken)
        {
            if (!int.TryParse(User.FindFirstValue(ClaimTypes.NameIdentifier), out var adminId) || adminId <= 0)
                return Unauthorized();
            return Accepted(await _service.StartRestoreAsync(id, request, adminId, cancellationToken));
        }

        // A backup file may hold up to 256 MB of data; the rest leaves room for the other form fields.
        private const long UploadLimit = 257L * 1024 * 1024;

        // Same as Restore, but the backup is a .mmbak file sent with the request instead of a listed backup.
        [HttpPost("restore-upload")]
        [Authorize(Roles = nameof(Role.HeadAdmin))]
        [Consumes("multipart/form-data")]
        [RequestSizeLimit(UploadLimit)]
        [RequestFormLimits(MultipartBodyLengthLimit = UploadLimit)]
        public async Task<ActionResult<BackupRestoreResponse>> RestoreUpload([FromForm] RestoreUploadRequest request,
            CancellationToken cancellationToken)
        {
            if (!int.TryParse(User.FindFirstValue(ClaimTypes.NameIdentifier), out var adminId) || adminId <= 0)
                return Unauthorized();
            return Accepted(await _service.StartUploadRestoreAsync(request, adminId, cancellationToken));
        }

        // No sign-in: it must keep working while the accounts are being replaced and after everyone is
        // signed out. The restore ID is a random 128-bit value known only to whoever started the restore,
        // and the answer holds only progress and record counts.
        [HttpGet("restores/{restoreId}")]
        [AllowAnonymous]
        public ActionResult<BackupRestoreResponse> RestoreProgress([FromRoute] string restoreId)
            => Ok(_service.GetRestoreProgress(restoreId));

        [HttpGet("{id}/download")]
        public async Task<IActionResult> Download([FromRoute] int id, CancellationToken cancellationToken)
        {
            var file = await _service.DownloadAsync(id, cancellationToken);
            Response.RegisterForDispose(file.Owner);
            Response.Headers.CacheControl = "no-store";
            return File(file.Stream, "application/octet-stream", file.FileName);
        }
    }
}
