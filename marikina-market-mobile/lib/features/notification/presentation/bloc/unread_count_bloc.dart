import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marikina_market_mobile/core/errors/result.dart';
import 'package:marikina_market_mobile/features/notification/domain/use_cases/load_unread_count_use_case.dart';
import 'package:marikina_market_mobile/features/notification/presentation/bloc/unread_count_event.dart';
import 'package:marikina_market_mobile/features/notification/presentation/bloc/unread_count_state.dart';

class UnreadCountBloc extends Bloc<UnreadCountEvent, UnreadCountState> {
  final LoadUnreadCountUseCase loadUnreadCountUseCase;
  late final StreamSubscription<void> _arrivals;
  int _requestId = 0;

  UnreadCountBloc({
    required this.loadUnreadCountUseCase,
    required Stream<void> notificationArrivals,
  }) : super(const UnreadCountState(null)) {
    on<LoadUnreadCount>(_onLoadUnreadCount);
    _arrivals = notificationArrivals.listen((_) => add(LoadUnreadCount()));
  }

  Future<void> _onLoadUnreadCount(
    LoadUnreadCount event,
    Emitter<UnreadCountState> emit,
  ) async {
    // Only the newest request may update the badge.
    final requestId = ++_requestId;
    final result = await loadUnreadCountUseCase();
    if (requestId != _requestId || emit.isDone) return;
    emit(
      UnreadCountState(switch (result) {
        Success(:final data) => data,
        ResultFailure() => null,
      }),
    );
  }

  @override
  Future<void> close() async {
    await _arrivals.cancel();
    return super.close();
  }
}
