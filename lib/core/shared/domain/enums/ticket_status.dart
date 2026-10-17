enum TicketStatus {
  pending('Pending'),
  paid('Paid'),
  waived('Waived'),
  contested('Contested'),
  overdue('Overdue'),
  cleared('Cleared'),
  inProgress('InProgress');

  final String value;
  const TicketStatus(this.value);

  String get label => this == TicketStatus.inProgress ? 'In Progress' : value;

  static TicketStatus fromValue(String value) {
    return TicketStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => throw ArgumentError('Unknown status: $value'),
    );
  }
}
