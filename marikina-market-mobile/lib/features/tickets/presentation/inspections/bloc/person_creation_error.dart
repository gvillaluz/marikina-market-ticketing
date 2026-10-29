import './inspection_state.dart';

class PersonCreationError extends InspectionState {
  final String message;
  PersonCreationError(this.message);
}
