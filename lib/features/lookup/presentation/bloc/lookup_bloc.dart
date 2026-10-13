import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marikina_market_mobile/features/lookup/presentation/bloc/lookup_event.dart';
import 'package:marikina_market_mobile/features/lookup/presentation/bloc/lookup_state.dart';

class LookupBloc extends Bloc<LookupEvent, LookupState> {
  LookupBloc() : super(LookupInitial()) {
    
  }
}