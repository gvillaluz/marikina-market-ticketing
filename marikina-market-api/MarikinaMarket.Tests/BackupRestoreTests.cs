using System.ComponentModel.DataAnnotations;
using System.Reflection;
using System.Text.Json;
using MarikinaMarket.API.Application;
using MarikinaMarket.API.Application.DTOs.Audits.Internal;
using MarikinaMarket.API.Application.DTOs.Backups.Request;
using MarikinaMarket.API.Application.Interfaces.Repositories;
using MarikinaMarket.API.Application.Interfaces.Services;
using MarikinaMarket.API.Application.Services;
using MarikinaMarket.API.Domain.Entities;
using MarikinaMarket.API.Domain.Enums;
using MarikinaMarket.API.Presentation.Controllers;
using MarikinaMarket.API.Presentation.Middleware;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Http.Metadata;
using Microsoft.AspNetCore.Identity;
using RequestFormLimitsAttribute = Microsoft.AspNetCore.Mvc.RequestFormLimitsAttribute;
using Microsoft.AspNetCore.Mvc.Controllers;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging.Abstractions;
using Xunit;

namespace MarikinaMarket.Tests;

// Restoring a backup from the Backups page: who may start it, what it checks first,
// and how the system pauses everyone else while it runs.
[Collection("Backup scheduler")]
public class BackupRestoreTests
{
    private static readonly Backup Downloadable = new()
    {
        Id = 7, DateTime = DateTime.UtcNow.AddDays(-1), Type = BackupType.Manual, Status = BackupStatus.Completed,
        IsFinalized = true, ExpiresAt = DateTime.UtcNow.AddDays(20), B2Key = "backups/x.mmbak", Size = 10
    };

    [Fact]
    public void OnlyHeadAdminMayStartARestore()
    {
        var method = typeof(AdminBackupController).GetMethod(nameof(AdminBackupController.Restore))!;
        var roles = method.GetCustomAttributes<AuthorizeAttribute>().Select(a => a.Roles).ToList();
        Assert.Equal([nameof(Role.HeadAdmin)], roles);
    }

    [Theory]
    [InlineData(null)]
    [InlineData("")]
    [InlineData("restore")]
    [InlineData("RESTORE ")]
    public async Task WithoutTypingRestoreNothingIsCheckedOrStarted(string? confirmation)
    {
        var state = new BackupRestoreState();
        var service = Service(state, Users(_ => throw new InvalidOperationException("The password must not be checked.")),
            Repository(_ => throw new InvalidOperationException("No backup may be looked up.")));

        var error = await Assert.ThrowsAsync<ValidationException>(() => service.StartRestoreAsync(7,
            new RestoreBackupRequest { Confirmation = confirmation, Password = "secret-password" }, 1, default));

        Assert.Equal("Type RESTORE to confirm.", error.Message);
        Assert.False(state.IsPaused);
    }

    [Fact]
    public async Task AWrongPasswordIsRefusedAndNothingStarts()
    {
        var state = new BackupRestoreState();
        var service = Service(state, Users(_ => SignInResult.Failed),
            Repository(_ => throw new InvalidOperationException("No backup may be looked up.")));

        var error = await Assert.ThrowsAsync<InvalidCredentialsException>(() => service.StartRestoreAsync(7,
            new RestoreBackupRequest { Confirmation = "RESTORE", Password = "wrong" }, 1, default));

        Assert.Equal("Password is incorrect.", error.Message);
        Assert.False(state.IsPaused);
    }

    [Fact]
    public async Task ALockedAccountIsRefused()
    {
        var service = Service(new BackupRestoreState(), Users(_ => SignInResult.LockedOut),
            Repository(_ => throw new InvalidOperationException("No backup may be looked up.")));

        await Assert.ThrowsAsync<AccountLockedException>(() => service.StartRestoreAsync(7,
            new RestoreBackupRequest { Confirmation = "RESTORE", Password = "secret-password" }, 1, default));
    }

    [Theory]
    [InlineData(BackupStatus.Failed, 20)]
    [InlineData(BackupStatus.Completed, -1)]
    public async Task ABackupThatCannotBeDownloadedCannotBeRestored(BackupStatus status, int expiresInDays)
    {
        var backup = new Backup
        {
            Id = 7, DateTime = DateTime.UtcNow.AddDays(-30), Type = BackupType.Manual, Status = status,
            IsFinalized = true, ExpiresAt = DateTime.UtcNow.AddDays(expiresInDays), B2Key = "backups/x.mmbak"
        };
        var state = new BackupRestoreState();
        var service = Service(state, Users(_ => SignInResult.Success), Repository(_ => backup));

        var error = await Assert.ThrowsAsync<InvalidRequestException>(() => service.StartRestoreAsync(7,
            new RestoreBackupRequest { Confirmation = "RESTORE", Password = "secret-password" }, 1, default));

        Assert.Equal("This backup cannot be restored.", error.Message);
        Assert.False(state.IsPaused);
    }

    [Fact]
    public async Task AMissingBackupIsNotFound()
    {
        var service = Service(new BackupRestoreState(), Users(_ => SignInResult.Success), Repository(_ => null));
        await Assert.ThrowsAsync<RecordNotFoundException>(() => service.StartRestoreAsync(7,
            new RestoreBackupRequest { Confirmation = "RESTORE", Password = "secret-password" }, 1, default));
    }

    [Fact]
    public async Task AStartedRestoreCanBeFollowedByItsId()
    {
        var state = new BackupRestoreState();
        var ran = new TaskCompletionSource<string>(TaskCreationOptions.RunContinuationsAsynchronously);
        var service = Service(state, Users(_ => SignInResult.Success), Repository(_ => Downloadable),
            run: id => { ran.TrySetResult(id); return Task.CompletedTask; });

        var started = await service.StartRestoreAsync(7,
            new RestoreBackupRequest { Confirmation = "RESTORE", Password = "secret-password" }, 1, default);

        Assert.Equal(32, started.RestoreId.Length);
        Assert.Equal(7, started.BackupId);
        Assert.Equal(RestoreState.Running, started.State);
        Assert.Equal([RestoreStep.CheckBackup, RestoreStep.SafetyBackup, RestoreStep.LoadBackup,
            RestoreStep.SignEveryoneOut, RestoreStep.CountRecords], started.Steps.Select(s => s.Step));
        Assert.All(started.Steps, s => Assert.Equal(RestoreStepState.Waiting, s.State));
        // The restore itself runs in the background, in its own scope.
        Assert.Equal(started.RestoreId, await ran.Task.WaitAsync(TimeSpan.FromSeconds(10)));
        Assert.Equal(started.RestoreId, service.GetRestoreProgress(started.RestoreId).RestoreId);
        Assert.Throws<RecordNotFoundException>(() => service.GetRestoreProgress(Guid.NewGuid().ToString("N")));
    }

    [Fact]
    public async Task WhilePausedOtherRequestsAreRefusedWithAPlainMessage()
    {
        var state = new BackupRestoreState();
        Assert.True(await state.PauseAsync(TimeSpan.FromSeconds(1), default));
        try
        {
            var reached = false;
            var middleware = new RestorePauseMiddleware(_ => { reached = true; return Task.CompletedTask; });
            var context = Request("AdminTicket", "UpdateTicketStatus");

            await middleware.InvokeAsync(context, state);

            Assert.False(reached);
            Assert.Equal(StatusCodes.Status503ServiceUnavailable, context.Response.StatusCode);
            context.Response.Body.Position = 0;
            using var body = await JsonDocument.ParseAsync(context.Response.Body);
            Assert.Equal("The system is being restored. Try again in a few minutes.",
                body.RootElement.GetProperty("message").GetString());
        }
        finally { state.Resume(); }
    }

    [Fact]
    public async Task WhilePausedTheRestoreProgressCanStillBeRead()
    {
        var state = new BackupRestoreState();
        Assert.True(await state.PauseAsync(TimeSpan.FromSeconds(1), default));
        try
        {
            var reached = false;
            var middleware = new RestorePauseMiddleware(_ => { reached = true; return Task.CompletedTask; });
            await middleware.InvokeAsync(Request("AdminBackup", nameof(AdminBackupController.RestoreProgress)), state);
            Assert.True(reached);
        }
        finally { state.Resume(); }
    }

    [Fact]
    public async Task WhenNotPausedRequestsPassThrough()
    {
        var reached = false;
        var middleware = new RestorePauseMiddleware(_ => { reached = true; return Task.CompletedTask; });
        await middleware.InvokeAsync(Request("AdminTicket", "UpdateTicketStatus"), new BackupRestoreState());
        Assert.True(reached);
    }

    // Work that was already being saved when the pause started must finish before the safety backup,
    // or it would be in neither the safety backup nor the restored data.
    [Fact]
    public async Task ThePauseWaitsForWorkAlreadyBeingSaved()
    {
        var state = new BackupRestoreState();
        var saving = new TaskCompletionSource(TaskCreationOptions.RunContinuationsAsynchronously);
        var middleware = new RestorePauseMiddleware(_ => saving.Task);
        var request = middleware.InvokeAsync(Request("EnforcerTicket", "SaveNewInspection"), state);

        var pause = state.PauseAsync(TimeSpan.FromSeconds(10), default);
        await Task.Delay(300);
        Assert.False(pause.IsCompleted);
        Assert.True(state.IsPaused);

        saving.SetResult();
        await request;
        Assert.True(await pause.WaitAsync(TimeSpan.FromSeconds(10)));
        state.Resume();
    }

    [Fact]
    public async Task ThePauseGivesUpWhenWorkDoesNotFinish()
    {
        var state = new BackupRestoreState();
        var saving = new TaskCompletionSource(TaskCreationOptions.RunContinuationsAsynchronously);
        var request = new RestorePauseMiddleware(_ => saving.Task).InvokeAsync(Request("EnforcerTicket", "SaveNewInspection"), state);

        Assert.False(await state.PauseAsync(TimeSpan.FromMilliseconds(300), default));

        state.Resume();
        saving.SetResult();
        await request;
    }

    // The restore replaces everything except today's audit log, backup list and backup schedule.
    [Fact]
    public void TheRestoreListLeavesOutTheKeptTablesAndTheirParts()
    {
        string[] list =
        [
            ";",
            "; Archive created at 2026-11-25 10:00:00 PST",
            "6; 2615 18770 SCHEMA - shared postgres",
            "232; 1259 18848 TABLE public audit_logs postgres",
            "233; 1259 18860 SEQUENCE public audit_logs_id_seq postgres",
            "234; 1259 18861 TABLE public backup_schedules postgres",
            "235; 1259 18873 TABLE public backups postgres",
            "240; 1259 18900 TABLE public tickets postgres",
            "5303; 0 18848 TABLE DATA public audit_logs postgres",
            "5306; 0 18873 TABLE DATA public backups postgres",
            "5310; 0 18900 TABLE DATA public tickets postgres",
            "5356; 0 0 SEQUENCE SET public audit_logs_id_seq postgres",
            "5026; 2606 19198 CONSTRAINT public audit_logs pk_audit_logs postgres",
            "5040; 2606 19300 CONSTRAINT public tickets pk_tickets postgres",
            "5024; 1259 19252 INDEX public ix_audit_logs_user_id_timestamp postgres",
            "5029; 1259 19253 INDEX public ix_backups_b2key postgres",
            "5050; 1259 19400 INDEX public ix_tickets_issued_at postgres",
            "5100; 2606 19500 FK CONSTRAINT public tickets fk_tickets_businesses_business_id postgres"
        ];
        var kept = new HashSet<string> { "audit_logs", "audit_logs_id_seq", "backup_schedules", "backups",
            "ix_audit_logs_user_id_timestamp", "ix_backups_b2key" };

        var result = BackupService.RestoreListWithout(list, kept);

        Assert.Equal(
        [
            ";",
            "; Archive created at 2026-11-25 10:00:00 PST",
            "6; 2615 18770 SCHEMA - shared postgres",
            "240; 1259 18900 TABLE public tickets postgres",
            "5310; 0 18900 TABLE DATA public tickets postgres",
            "5040; 2606 19300 CONSTRAINT public tickets pk_tickets postgres",
            "5050; 1259 19400 INDEX public ix_tickets_issued_at postgres",
            "5100; 2606 19500 FK CONSTRAINT public tickets fk_tickets_businesses_business_id postgres"
        ], result);
    }

    [Fact]
    public void OnlyHeadAdminMayRestoreAnUploadedFile()
    {
        var method = typeof(AdminBackupController).GetMethod(nameof(AdminBackupController.RestoreUpload))!;
        var roles = method.GetCustomAttributes<AuthorizeAttribute>().Select(a => a.Roles).ToList();
        Assert.Equal([nameof(Role.HeadAdmin)], roles);
    }

    // The server normally refuses anything over about 28 MB. A backup file may hold up to 256 MB of data
    // (268,435,456 bytes) plus 33 bytes of lock information, so the upload route must accept at least that.
    [Fact]
    public void TheUploadRouteAcceptsAFileAsLargeAsTheLargestBackup()
    {
        var method = typeof(AdminBackupController).GetMethod(nameof(AdminBackupController.RestoreUpload))!;
        var request = method.GetCustomAttributes().OfType<IRequestSizeLimitMetadata>().Single().MaxRequestBodySize;
        var form = method.GetCustomAttribute<RequestFormLimitsAttribute>()!.MultipartBodyLengthLimit;
        Assert.NotNull(request);
        Assert.InRange(request!.Value, 268_435_489L, 300_000_000L);
        Assert.InRange(form, 268_435_489L, 300_000_000L);
    }

    [Fact]
    public async Task WithoutTypingRestoreAnUploadIsRefusedBeforeThePasswordIsChecked()
    {
        var state = new BackupRestoreState();
        var service = Service(state, Users(_ => throw new InvalidOperationException("The password must not be checked.")),
            Repository(_ => throw new InvalidOperationException("No backup may be looked up.")));

        var error = await Assert.ThrowsAsync<ValidationException>(() => service.StartUploadRestoreAsync(
            Upload("restore", "backup.mmbak", 40), 1, default));

        Assert.Equal("Type RESTORE to confirm.", error.Message);
        Assert.False(state.IsPaused);
    }

    [Fact]
    public async Task AWrongPasswordRefusesAnUpload()
    {
        var service = Service(new BackupRestoreState(), Users(_ => SignInResult.Failed),
            Repository(_ => throw new InvalidOperationException("No backup may be looked up.")));

        var error = await Assert.ThrowsAsync<InvalidCredentialsException>(() => service.StartUploadRestoreAsync(
            Upload("RESTORE", "backup.mmbak", 40, password: "wrong"), 1, default));

        Assert.Equal("Password is incorrect.", error.Message);
    }

    [Theory]
    [InlineData(null, 0L, "Choose a backup file to restore.")]
    [InlineData("backup.mmbak", 0L, "Choose a backup file to restore.")]
    [InlineData("backup.zip", 40L, "Choose a .mmbak backup file.")]
    [InlineData("backup.mmbak", 268_435_490L, "This file is too large to be a backup.")]
    public async Task AnUploadThatCannotBeABackupIsRefusedAndNothingStarts(string? fileName, long length, string message)
    {
        var state = new BackupRestoreState();
        var service = Service(state, Users(_ => SignInResult.Success),
            Repository(_ => throw new InvalidOperationException("No backup may be looked up.")),
            run: _ => throw new InvalidOperationException("No restore may start."));

        var error = await Assert.ThrowsAsync<ValidationException>(() => service.StartUploadRestoreAsync(
            Upload("RESTORE", fileName, length), 1, default));

        Assert.Equal(message, error.Message);
        Assert.False(state.IsPaused);
    }

    [Fact]
    public async Task AnUploadedFileIsKeptOnlyForItsRestoreAndNeedsNoListedBackup()
    {
        var state = new BackupRestoreState();
        var ran = new TaskCompletionSource<string>(TaskCreationOptions.RunContinuationsAsynchronously);
        // The repository and the cloud storage are not used: the file comes with the request.
        var service = Service(state, Users(_ => SignInResult.Success),
            Repository(_ => throw new InvalidOperationException("No backup may be looked up.")),
            run: id => { ran.TrySetResult(id); return Task.CompletedTask; });
        var request = Upload("RESTORE", new string('a', 300) + ".mmbak", 40);

        var started = await service.StartUploadRestoreAsync(request, 1, default);
        try
        {
            Assert.Equal(32, started.RestoreId.Length);
            Assert.Null(started.BackupId);
            Assert.Null(started.BackupDateTime);
            // Long names are shortened so they fit in the audit log.
            Assert.Equal(new string('a', 100), started.FileName);
            Assert.Equal(RestoreState.Running, started.State);
            Assert.Equal(started.RestoreId, await ran.Task.WaitAsync(TimeSpan.FromSeconds(10)));
            // The background restore finds the uploaded bytes in a temporary file.
            Assert.Equal(Enumerable.Range(0, 40).Select(i => (byte)i), await File.ReadAllBytesAsync(state.UploadPath!));
        }
        finally { File.Delete(state.UploadPath!); }
    }

    private static RestoreUploadRequest Upload(string confirmation, string? fileName, long length, string password = "secret-password")
        => new()
        {
            Confirmation = confirmation, Password = password,
            File = fileName is null ? null : new FormFile(new MemoryStream(Enumerable.Range(0, 40).Select(i => (byte)i).ToArray()),
                0, length, "file", fileName)
        };

    private static DefaultHttpContext Request(string controller, string action)
    {
        var context = new DefaultHttpContext();
        context.Response.Body = new MemoryStream();
        context.SetEndpoint(new Endpoint(null, new EndpointMetadataCollection(
            new ControllerActionDescriptor { ControllerName = controller, ActionName = action }), action));
        return context;
    }

    private static IUserRepository Users(Func<string, SignInResult> check) =>
        BackupTestBoundary.Create<IUserRepository>((name, args) => name switch
        {
            "GetUserAsync" => Task.FromResult<User?>(new User
            {
                Id = (int)args![0]!, UserName = "head-admin", FirstName = "Head", LastName = "Admin",
                DateOfBirth = new DateOnly(1990, 1, 1), HouseNumber = "1", Street = "Test Street", Barangay = "Test", City = "Marikina"
            }),
            "CheckPasswordAsync" => Task.FromResult(check((string)args![1]!)),
            _ => throw new InvalidOperationException($"Unexpected user repository call: {name}")
        });

    private static IBackupRepository Repository(Func<int, Backup?> find) =>
        BackupTestBoundary.Create<IBackupRepository>((name, args) => name switch
        {
            "GetByIdAsync" => Task.FromResult(find((int)args![0]!)),
            _ => throw new InvalidOperationException($"Unexpected repository call: {name}")
        });

    private static BackupService Service(BackupRestoreState state, IUserRepository users, IBackupRepository repository,
        Func<string, Task>? run = null)
    {
        var scopes = new ServiceCollection()
            .AddScoped<IBackupService>(_ => BackupTestBoundary.Create<IBackupService>((name, args) => name == "RunRestoreAsync"
                ? (run ?? (_ => Task.CompletedTask))((string)args![0]!)
                : throw new InvalidOperationException($"Unexpected background call: {name}")))
            .BuildServiceProvider().GetRequiredService<IServiceScopeFactory>();
        return new BackupService(repository, new ReportUnitOfWork(),
            BackupTestBoundary.Create<IStorageService>((name, _) => throw new InvalidOperationException($"Unexpected storage call: {name}")),
            new ConfigurationBuilder().Build(),
            BackupTestBoundary.Create<IHostApplicationLifetime>((_, _) => CancellationToken.None),
            NullLogger<BackupService>.Instance,
            BackupTestBoundary.Create<IAuditLogService>((_, _) => Task.CompletedTask), new AuditLogContext(),
            users, state, scopes);
    }
}
