using MarikinaMarket.API.Application.Interfaces.Services;
using MarikinaMarket.API.Domain.Entities;
using MarikinaMarket.API.Domain.Enums;

namespace MarikinaMarket.API.Infrastructure.BackgroundServices
{
    // Runs at start and hourly, so a server that slept past midnight catches up when it wakes.
    public class ComplianceScoreUpdateService : BackgroundService
    {
        private readonly IServiceProvider _serviceProvider;
        private readonly ILogger<ComplianceScoreUpdateService> _logger;

        public ComplianceScoreUpdateService(IServiceProvider serviceProvider, ILogger<ComplianceScoreUpdateService> logger)
        {
            _serviceProvider = serviceProvider;
            _logger = logger;
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            while (!stoppingToken.IsCancellationRequested)
            {
                await RunOnceAsync();

                try { await Task.Delay(TimeSpan.FromHours(1), stoppingToken); }
                catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested) { break; }
            }
        }

        public async Task RunOnceAsync()
        {
            using var scope = _serviceProvider.CreateScope();
            try
            {
                await scope.ServiceProvider.GetRequiredService<IVendorComplianceScoreService>()
                    .RefreshDueAsync(DateTime.UtcNow);
            }
            catch (Exception ex)
            {
                _logger.LogWarning("Compliance score update failed ({ExceptionType}).", ex.GetType().Name);
                await scope.ServiceProvider.GetRequiredService<IAuditLogService>().RecordAsync(new AuditLog
                {
                    Action = "UpdateComplianceScores", Module = Module.Vendors, Result = LogResult.Failed,
                    Details = "System compliance score update failed and will be retried."
                });
            }
        }
    }
}
