namespace MarikinaMarket.API.Domain.Enums
{
    // In the order a restore goes through them.
    public enum RestoreStep { CheckBackup, SafetyBackup, LoadBackup, SignEveryoneOut, CountRecords }
}
