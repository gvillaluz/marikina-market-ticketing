import './inspection_event.dart';

class PersonCreationRequested extends InspectionEvent {
  final String name, address;
  final String? phone;
  PersonCreationRequested(this.name, this.address, this.phone);
}
