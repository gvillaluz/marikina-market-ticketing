import './inspection_state.dart';

class OwnerPersonError extends InspectionState {
  final int businessId;
  final String message;
  OwnerPersonError(this.businessId, this.message);
}
