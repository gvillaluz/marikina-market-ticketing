import 'package:marikina_market_mobile/features/tickets/domain/entities/person_ticket_totals.dart';

class PersonTicketTotalsModel {
  final int offenseCount, warningCount;
  final double outstandingFine;
  final DateTime? lastTicketAt;
  final String? lastBusinessName;
  final List<String> businessNames;
  const PersonTicketTotalsModel({
    required this.offenseCount,
    required this.warningCount,
    required this.outstandingFine,
    required this.lastTicketAt,
    required this.lastBusinessName,
    required this.businessNames,
  });
  factory PersonTicketTotalsModel.fromJson(Map<String, Object?> json) =>
      PersonTicketTotalsModel(
        offenseCount: json['offense_count'] as int,
        warningCount: json['warning_count'] as int,
        outstandingFine: (json['outstanding_fine'] as num).toDouble(),
        lastTicketAt: json['last_ticket_at'] == null
            ? null
            : DateTime.parse(json['last_ticket_at'] as String),
        lastBusinessName: json['last_business_name'] as String?,
        businessNames: (json['business_names'] as List<Object?>).cast<String>(),
      );
  PersonTicketTotals toEntity() => PersonTicketTotals(
    offenseCount: offenseCount,
    warningCount: warningCount,
    outstandingFine: outstandingFine,
    lastTicketAt: lastTicketAt,
    lastBusinessName: lastBusinessName,
    businessNames: businessNames,
  );
}
