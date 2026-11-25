using MarikinaMarket.API.Application.Services;
using MarikinaMarket.API.Presentation.Controllers;
using Microsoft.AspNetCore.Mvc.Controllers;

namespace MarikinaMarket.API.Presentation.Middleware
{
    // While a restore replaces the data, every request except the restore's own progress is refused,
    // so nothing is saved into data that is about to be replaced.
    public class RestorePauseMiddleware
    {
        private readonly RequestDelegate _next;
        public RestorePauseMiddleware(RequestDelegate next) => _next = next;

        public async Task InvokeAsync(HttpContext context, BackupRestoreState restore)
        {
            if (IsRestoreProgress(context))
            {
                await _next(context);
                return;
            }
            if (!restore.TryEnterRequest())
            {
                context.Response.StatusCode = StatusCodes.Status503ServiceUnavailable;
                context.Response.Headers.RetryAfter = "60";
                await context.Response.WriteAsJsonAsync(new
                {
                    title = "System restore in progress",
                    message = "The system is being restored. Try again in a few minutes."
                });
                return;
            }
            try { await _next(context); }
            finally { restore.ExitRequest(); }
        }

        public static bool IsRestoreProgress(HttpContext context)
        {
            var action = context.GetEndpoint()?.Metadata.GetMetadata<ControllerActionDescriptor>();
            return action is { ControllerName: "AdminBackup", ActionName: nameof(AdminBackupController.RestoreProgress) };
        }
    }
}
