import './inspection_state.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/person_candidate.dart';

class OwnerPersonAdded extends InspectionState {
  final int businessId;
  final PersonCandidate person;
  OwnerPersonAdded(this.businessId, this.person);
}
