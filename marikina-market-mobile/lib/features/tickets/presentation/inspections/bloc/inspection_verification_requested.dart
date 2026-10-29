import './inspection_event.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/verify_inspection_input.dart';

class InspectionVerificationRequested extends InspectionEvent {
  final VerifyInspectionInput input;
  InspectionVerificationRequested(this.input);
}
