import './inspection_state.dart';

class PersonMatchesError extends InspectionState {
  final String message;
  PersonMatchesError(this.message);
}
