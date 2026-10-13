import 'package:marikina_market_mobile/features/tickets/domain/entities/duplicate_ordinance.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/inspection_ticket_summary.dart';

class SaveInspectionResult {
  final InspectionTicketSummary inspectionSummary;
  final List<DuplicateOrdinance>? duplicateOrdinances;
  final String? warningMessageForDuplicates;

  SaveInspectionResult({required this.inspectionSummary, this.duplicateOrdinances, this.warningMessageForDuplicates});
}