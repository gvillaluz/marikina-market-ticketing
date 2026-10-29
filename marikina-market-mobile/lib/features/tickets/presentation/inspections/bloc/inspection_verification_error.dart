import './inspection_state.dart';

class InspectionVerificationError extends InspectionState {
  final String message;
  InspectionVerificationError(this.message);
}
