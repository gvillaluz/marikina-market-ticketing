import './inspection_state.dart';
import 'package:marikina_market_mobile/features/tickets/domain/entities/market_section.dart';

class MarketSectionsLoading extends InspectionState {}

class MarketSectionsLoaded extends InspectionState {
  final List<MarketSection> sections;
  MarketSectionsLoaded(this.sections);
}
