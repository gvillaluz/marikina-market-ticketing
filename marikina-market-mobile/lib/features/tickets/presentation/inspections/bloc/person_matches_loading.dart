import './inspection_state.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/person_candidate.dart';
import 'package:marikina_market_mobile/core/shared/domain/entities/page_result.dart';

class PersonMatchesLoading extends InspectionState {}

class PersonMatchesLoaded extends InspectionState {
  final PageResult<PersonCandidate> page;
  final String name;
  final int offset;
  PersonMatchesLoaded(this.page, this.name, this.offset);
}
