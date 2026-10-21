enum RecordsFilter {
  all('All', null),
  warning('Warnings', 'Warning'),
  ticket('Tickets', 'Ticket');

  final String label;
  final String? apiValue;
  const RecordsFilter(this.label, this.apiValue);
  static RecordsFilter fromType(String type) => switch (type) {
    'Warning' => warning,
    'Ticket' => ticket,
    _ => throw FormatException('Invalid record type.'),
  };
}
