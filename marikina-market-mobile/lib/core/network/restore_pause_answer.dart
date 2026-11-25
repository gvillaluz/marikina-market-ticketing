import 'package:dio/dio.dart';

// The server's answer while a backup restore has paused the system
// (marikina-market-api BACKUPS.md). Other 503 answers, such as an email
// problem, have no such title.
class RestorePauseAnswer {
  RestorePauseAnswer._();

  static const message =
      'The system is being restored. Try again in a few minutes.';

  static bool matches(Response<Object?>? response) {
    final data = response?.data;
    return response?.statusCode == 503 &&
        data is Map<String, Object?> &&
        data['title'] == 'System restore in progress';
  }
}
