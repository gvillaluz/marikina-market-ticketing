import './inspection_state.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/person_candidate.dart';

class PersonCreationLoading extends InspectionState {}

class PersonCreated extends InspectionState {
  final PersonCandidate person;
  PersonCreated(this.person);
}
