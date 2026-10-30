import 'package:marikina_market_mobile/features/tickets/domain/entities/business_snapshot.dart';

class BusinessSnapshotModel {
  final Map<String, Object?> _json;
  const BusinessSnapshotModel._(this._json);
  factory BusinessSnapshotModel.fromJson(Map<String, Object?> json) =>
      BusinessSnapshotModel._(json);
  BusinessSnapshot toEntity() => BusinessSnapshot(
    businessAccountNumber: _json['business_account_number'] as String?,
    businessName: _json['business_name'] as String?,
    registeredOwnerName: _json['registered_owner_name'] as String?,
    businessType: _json['business_type'] as String?,
    stallNumber: _json['stall_number'] as String?,
    marketSectionName: _json['market_section_name'] as String?,
    businessAddress: _json['business_address'] as String?,
  );
}
