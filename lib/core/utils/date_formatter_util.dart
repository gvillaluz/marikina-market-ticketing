import 'package:intl/intl.dart';

class DateTimeFormatter {
  static String getDate(DateTime dateTime) {
    return DateFormat('MMMM d, y').format(dateTime.toLocal());
  }

  static String getShortDate(DateTime dateTime) {
    return DateFormat('MMM d, y').format(dateTime.toLocal());
  }

  static String getTime(DateTime dateTime) {
    return DateFormat('h:mm a').format(dateTime.toLocal());
  }

  static String getDateTime(DateTime dateTime) {
    return '${getDate(dateTime)} \u2022 ${getTime(dateTime)}';
  }

  static String getShortDateTime(DateTime dateTime) {
    return '${getShortDate(dateTime)} \u2022 ${getTime(dateTime)}';
  }

  static DateTime fromJsonDate(String jsonDate) {
    final parts = jsonDate.split('-');
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final day = int.parse(parts[2]);

    return DateTime(year, month, day);
  }
}