enum SyncStatusFilter {
  all('All'),
  pending('Pending'),
  synced('Synced');

  final String value;
  const SyncStatusFilter(this.value);
}