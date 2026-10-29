import './inspection_event.dart';

class PersonMatchesRequested extends InspectionEvent {
  final String name;
  final String? address, phone;
  final int offset;
  PersonMatchesRequested(
    this.name,
    this.address,
    this.phone, {
    this.offset = 0,
  });
}
