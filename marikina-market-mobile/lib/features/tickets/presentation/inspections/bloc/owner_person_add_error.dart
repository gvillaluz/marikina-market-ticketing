import './inspection_state.dart';

class OwnerPersonAddError extends InspectionState {
  final int businessId;
  final String message;
  OwnerPersonAddError(this.businessId, this.message);
}
