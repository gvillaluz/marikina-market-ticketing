import './inspection_state.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/person_ticket_history.dart';
import 'package:marikina_market_mobile/core/shared/domain/entities/page_result.dart';

class PersonHistoryLoading extends InspectionState {}

class PersonHistoryLoaded extends InspectionState {
  final PageResult<PersonTicketHistory> page;
  final int personId, offset;
  PersonHistoryLoaded(this.page, this.personId, this.offset);
}
