import './inspection_event.dart';

class BusinessPeopleRequested extends InspectionEvent {
  final int businessId;
  BusinessPeopleRequested(this.businessId);
}
