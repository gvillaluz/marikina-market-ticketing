import './inspection_state.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/inspection_verification.dart';

class InspectionVerificationLoading extends InspectionState {}

class InspectionVerified extends InspectionState {
  final InspectionVerification verification;
  InspectionVerified(this.verification);
}
