import 'dart:io';

class SubmitCommunityServiceLogParams {
  final int ticketId;
  final File proofFile;
  final DateTime serviceDate;
  final double hoursWorked;

  const SubmitCommunityServiceLogParams({
    required this.ticketId,
    required this.proofFile,
    required this.serviceDate,
    required this.hoursWorked,
  });
}
