import './inspection_state.dart';

class PersonCreationError extends InspectionState {
  // Null when the server did not reply: the person may have been saved.
  final String? message;
  PersonCreationError(this.message);
}
