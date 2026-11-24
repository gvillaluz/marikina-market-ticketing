class UnreadCountState {
  /// Null when the count could not be loaded; the badge is then hidden.
  final int? count;
  const UnreadCountState(this.count);
}
