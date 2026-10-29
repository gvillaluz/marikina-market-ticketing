namespace MarikinaMarket.API.Application.Interfaces.Repositories
{
    public interface IBackupOperationLock : IAsyncDisposable
    {
        CancellationToken ConnectionLost { get; }
    }
}
