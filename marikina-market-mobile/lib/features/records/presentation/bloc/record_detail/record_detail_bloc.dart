import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marikina_market_mobile/core/errors/result.dart';
import '../../../domain/entities/vendor_ticket_detail.dart';
import '../../../domain/use_cases/load_record_detail_use_case.dart';
import 'load_record_detail.dart';
import 'record_detail_state.dart';

class RecordDetailBloc extends Bloc<LoadRecordDetail, RecordDetailState> {
  final LoadRecordDetailUseCase loadDetail;
  bool _pending = false;
  RecordDetailBloc(this.loadDetail) : super(const RecordDetailState()) {
    on<LoadRecordDetail>(_load);
  }
  Future<void> _load(
    LoadRecordDetail event,
    Emitter<RecordDetailState> emit,
  ) async {
    if (_pending) return;
    _pending = true;
    emit(const RecordDetailState());
    final result = await loadDetail(event.ticketId);
    _pending = false;
    if (emit.isDone) return;
    switch (result) {
      case Success<VendorTicketDetail>(data: final detail):
        emit(RecordDetailState(detail: detail, isLoading: false));
      case ResultFailure<VendorTicketDetail>(failure: final failure):
        emit(RecordDetailState(error: failure.message, isLoading: false));
    }
  }
}
