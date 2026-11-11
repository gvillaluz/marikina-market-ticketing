import './inspection_event.dart';

class PersonMatchesRequested extends InspectionEvent {
  final String name;
  final int offset;
  PersonMatchesRequested(this.name, {this.offset = 0});
}
