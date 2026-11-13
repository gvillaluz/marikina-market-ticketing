import 'package:marikina_market_mobile/features/dashboard/domain/entities/dashboard_summary.dart';

class DashboardSummaryModel {
  final int ticketsRecorded;
  final int warningsRecorded;
  final int totalRecorded;

  DashboardSummaryModel({required this.ticketsRecorded, required this.warningsRecorded, required this.totalRecorded});

  factory DashboardSummaryModel.fromJson(Map<String, dynamic> json) {
    return DashboardSummaryModel(
      ticketsRecorded: json['ticket_recorded'], 
      warningsRecorded: json['warning_recorded'], 
      totalRecorded: json['total_recorded']
    );
  }

  DashboardSummary toEntity() {
    return DashboardSummary(
      ticketsRecorded: ticketsRecorded, 
      warningsRecorded: warningsRecorded, 
      totalRecorded: totalRecorded
    );
  }
}