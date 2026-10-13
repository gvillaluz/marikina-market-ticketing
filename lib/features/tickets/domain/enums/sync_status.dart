enum SyncStatus {
  pending('Pending'),
  synced('Synced');

  final String value;
  const SyncStatus(this.value);
}