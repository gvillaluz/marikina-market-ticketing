import './inspection_event.dart';

class OwnerPersonRequested extends InspectionEvent {
  final int businessId;
  OwnerPersonRequested(this.businessId);
}
