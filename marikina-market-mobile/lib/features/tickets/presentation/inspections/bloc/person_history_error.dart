import './inspection_state.dart';

class PersonHistoryError extends InspectionState {
  final String message;
  PersonHistoryError(this.message);
}
