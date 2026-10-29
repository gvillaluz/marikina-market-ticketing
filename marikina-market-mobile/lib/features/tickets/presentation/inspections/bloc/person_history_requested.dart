import './inspection_event.dart';

class PersonHistoryRequested extends InspectionEvent {
  final int personId, offset;
  PersonHistoryRequested(this.personId, {this.offset = 0});
}
