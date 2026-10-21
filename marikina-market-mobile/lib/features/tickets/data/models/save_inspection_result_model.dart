import 'package:marikina_market_mobile/features/tickets/data/models/duplicate_info_model.dart';
import 'package:marikina_market_mobile/features/tickets/data/models/inspection_summary_model.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/save_inspection_result.dart';

class SaveInspectionResultModel {
  final InspectionSummaryModel inspectionSummary;
  final List<DuplicateInfoModel>? duplicateOrdinances; 
  final String? warningMessageForDuplicates;

  SaveInspectionResultModel({required this.inspectionSummary, this.duplicateOrdinances, this.warningMessageForDuplicates});

  factory SaveInspectionResultModel.fromJson(Map<String, dynamic> json) {
    return SaveInspectionResultModel(
      inspectionSummary: InspectionSummaryModel.fromJson(json), 
      duplicateOrdinances: (json['duplicate_ordinances'] as List<dynamic>?)
        ?.map((e) => DuplicateInfoModel.fromJson(e as Map<String, dynamic>))
        .toList(),
      warningMessageForDuplicates: json['warning_message_for_duplicates'] != null
        ? json['warning_message_for_duplicates'] as String
        : null
    );
  }

  SaveInspectionResult toEntity() {
    return SaveInspectionResult(
      inspectionSummary: inspectionSummary.toEntity(),
      duplicateOrdinances: duplicateOrdinances?.map((d) => d.toEntity()).toList(),
      warningMessageForDuplicates: warningMessageForDuplicates
    );
  }
}