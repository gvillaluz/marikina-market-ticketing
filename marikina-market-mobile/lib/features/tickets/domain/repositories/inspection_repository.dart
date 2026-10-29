import 'package:marikina_market_mobile/features/tickets/domain/entities/person_candidate.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/person_ticket_history.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/inspection_verification.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/verify_inspection_input.dart';
import 'package:marikina_market_mobile/core/errors/result.dart';
import 'package:marikina_market_mobile/features/tickets/data/models/params/save_inspection_params.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/fine_summary.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/inspection_ticket_summary.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/ordinance.dart';
import 'package:marikina_market_mobile/core/shared/domain/entities/page_result.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/save_inspection_result.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/vendor_summary.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/warning_ordinance.dart';
import 'package:marikina_market_mobile/features/tickets/domain/enums/violation_type.dart';

abstract class InspectionRepository {
  Future<Result<PageResult<PersonCandidate>>> matchPeople(
    String name,
    String? address,
    String? phone,
    int offset,
  );
  Future<Result<PersonCandidate>> createPerson(
    String name,
    String address,
    String? phone,
  );
  Future<Result<PageResult<PersonTicketHistory>>> getPersonHistory(
    int personId,
    int offset,
  );
  Future<Result<InspectionVerification>> verifyInspection(
    VerifyInspectionInput input,
  );

  Future<Result<PageResult<InspectionTicketSummary>>> loadInspections(
    String search,
    int offset,
    ViolationType? type,
  );
  Future<Result<List<Ordinance>>> loadCacheOrdinances();
  Future<Result<List<Ordinance>>> loadOrdinances();
  Future<Result<VendorSummary>> getVendorByCode(String codeValue);
  Future<Result<List<VendorSummary>>> getVendorByStall(String stallNumber);
  Future<Result<FineSummary>> getTicketFineSummary(
    List<int> ordinanceIds,
    int vendorId, {
    int? personId,
  });
  Future<Result<List<WarningOrdinance>>> checkWarningOrdinances(
    List<int> ordinanceIds,
    int vendorId,
  );
  Future<Result<SaveInspectionResult>> saveNewInspection(
    SaveInspectionParams params,
  );
}
