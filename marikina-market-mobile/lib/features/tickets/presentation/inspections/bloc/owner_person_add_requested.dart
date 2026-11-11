import './inspection_event.dart';

class OwnerPersonAddRequested extends InspectionEvent {
  final int businessId;
  OwnerPersonAddRequested(this.businessId);
}
