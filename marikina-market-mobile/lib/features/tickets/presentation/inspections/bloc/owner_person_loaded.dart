import './inspection_state.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/person_candidate.dart';

// [person] is null when the owner has no person record yet.
class OwnerPersonLoaded extends InspectionState {
  final int businessId;
  final PersonCandidate? person;
  OwnerPersonLoaded(this.businessId, this.person);
}
