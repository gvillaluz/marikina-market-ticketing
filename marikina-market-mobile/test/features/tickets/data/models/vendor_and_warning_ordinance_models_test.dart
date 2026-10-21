import 'package:flutter_test/flutter_test.dart';
import 'package:marikina_market_mobile/features/tickets/data/models/vendor_summary_model.dart';
import 'package:marikina_market_mobile/features/tickets/data/models/warning_ordinance_model.dart';
import 'package:marikina_market_mobile/features/tickets/domain/enums/vendor_type.dart';

void main() {
  group('VendorSummaryModel', () {
    test('parses the current vendor response DTO', () {
      final vendor = VendorSummaryModel.fromJson({
        'vendor_id': 42,
        'username': 'vendor42',
        'type': 'Public',
        'business_id': 'BUS-42',
        'stall_number': 'A-12',
        'trade_name': 'Market Goods',
        'last_name': 'Vendor',
        'first_name': 'Val',
        'middle_name': 'M',
        'address': 'Marikina',
        'market_section_id': 3,
        'market_section_name': 'Section A',
      });

      expect(vendor.id, 42);
      expect(vendor.type, VendorType.public);
      expect(vendor.businessId, 'BUS-42');
      expect(vendor.toEntity().stallNumber, 'A-12');
    });

    test('accepts optional stall and middle name values', () {
      final vendor = VendorSummaryModel.fromJson({
        'vendor_id': 42,
        'username': 'vendor42',
        'type': 0,
        'business_id': 'BUS-42',
        'stall_number': null,
        'trade_name': 'Market Goods',
        'last_name': 'Vendor',
        'first_name': 'Val',
        'middle_name': null,
        'address': 'Marikina',
        'market_section_id': 3,
        'market_section_name': 'Section A',
      });

      expect(vendor.type, VendorType.public);
      expect(vendor.stallNumber, isNull);
      expect(vendor.middleName, isNull);
    });
  });

  test('WarningOrdinanceModel parses warning-check response', () {
    final ordinance = WarningOrdinanceModel.fromJson({
      'ordinance_id': 10,
      'ordinance_no': 'ORD-10',
      'ordinance_code': 'CODE-10',
    }).toEntity();

    expect(ordinance.ordinanceId, 10);
    expect(ordinance.ordinanceNo, 'ORD-10');
    expect(ordinance.ordinanceCode, 'CODE-10');
  });
}
