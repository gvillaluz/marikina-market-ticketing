import 'package:flutter_bloc/flutter_bloc.dart';

// Whether the server's last answer said a backup restore has paused it.
class RestorePauseCubit extends Cubit<bool> {
  RestorePauseCubit() : super(false);

  void setPaused(bool paused) => emit(paused);
}
