import 'dart:io';

class SubmitTicketReceiptProofParams {
  final int ticketId;
  final File proofFile;

  const SubmitTicketReceiptProofParams({
    required this.ticketId,
    required this.proofFile,
  });
}
