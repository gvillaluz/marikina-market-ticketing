using System.Data.Common;
using MarikinaMarket.API.Infrastructure.Persistence;
using MarikinaMarket.API.Infrastructure.Repositories;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Diagnostics;
using Xunit;

namespace MarikinaMarket.Tests;

// Phase 4 line 3 finding: a ticket loaded outside the app (demo script, import) can have no hidden running
// number. The next number must come from the highest whole number already used by a ticket, skipping empty
// or non-number values, so such a record neither crashes the submit nor causes a repeated number
// (control_number is unique). The lookup is PostgreSQL text, so this test records the query the server
// would send instead of running it; the live check runs it against the disposable database.
public class NextControlNumberTests
{
    [Fact]
    public async Task Next_number_reads_the_highest_whole_number_and_skips_empty_values()
    {
        var recorder = new RecordCommand();
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseNpgsql("Host=unused;Database=model_only;Username=model_only")
            .UseSnakeCaseNamingConvention()
            .AddInterceptors(new SuppressConnection(), recorder).Options;
        await using var context = new AppDbContext(options);

        await Assert.ThrowsAsync<CommandReachedException>(() => new TicketRepository(context).GetNewControlNumber());

        var sql = recorder.Text!;
        Assert.Contains("type = 'Ticket'", sql);
        Assert.Contains("control_number ~ '^[0-9]+$'", sql);
        Assert.Contains("ORDER BY control_number::int DESC", sql);
        Assert.Contains("FOR UPDATE", sql);
        Assert.DoesNotContain("ORDER BY id DESC", sql);
    }

    private sealed class SuppressConnection : DbConnectionInterceptor
    {
        public override ValueTask<InterceptionResult> ConnectionOpeningAsync(DbConnection connection,
            ConnectionEventData eventData, InterceptionResult result, CancellationToken cancellationToken = default)
            => ValueTask.FromResult(InterceptionResult.Suppress());
    }

    private sealed class CommandReachedException : Exception { }

    private sealed class RecordCommand : DbCommandInterceptor
    {
        public string? Text { get; private set; }

        public override ValueTask<InterceptionResult<DbDataReader>> ReaderExecutingAsync(DbCommand command,
            CommandEventData eventData, InterceptionResult<DbDataReader> result, CancellationToken cancellationToken = default)
        {
            Text = command.CommandText;
            throw new CommandReachedException();
        }
    }
}
